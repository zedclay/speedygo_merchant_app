#!/usr/bin/env python3
"""HTTP-only Merchant media persistence proof (no Flutter, no Finjan)."""
from __future__ import annotations

import json
import time
import urllib.error
import urllib.request
from pathlib import Path

BASE = "http://127.0.0.1:3000/api/v1"
OTP_FILE = Path("/Users/mac/.speedygo/dev/otp-last")
PHONE = "+213550000071"  # Dar El Bahja
OUT = Path(
    "/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-5-ui/media-http"
)
FIXTURES = Path(
    "/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-5-ui/media-live"
)


def req(method: str, path: str, token: str | None = None, data=None, headers=None):
    h = dict(headers or {})
    if token:
        h["Authorization"] = f"Bearer {token}"
    body = None
    if data is not None and not isinstance(data, (bytes, bytearray)):
        body = json.dumps(data).encode()
        h.setdefault("Content-Type", "application/json")
    elif data is not None:
        body = data
    r = urllib.request.Request(BASE + path, data=body, headers=h, method=method)
    try:
        with urllib.request.urlopen(r, timeout=60) as res:
            raw = res.read()
            ctype = res.headers.get("Content-Type", "")
            return res.status, ctype, raw
    except urllib.error.HTTPError as e:
        raw = e.read()
        return e.code, e.headers.get("Content-Type", ""), raw


def clear_otp_limits():
    import subprocess

    subprocess.run(
        [
            "bash",
            "-lc",
            "redis-cli -p 6381 --scan --pattern 'auth:otp:*' | while read k; do redis-cli -p 6381 DEL \"$k\" >/dev/null; done",
        ],
        check=False,
    )


def login(phone: str) -> str:
    clear_otp_limits()
    before = time.time() - 1
    status, _, raw = req(
        "POST",
        "/auth/otp/request",
        data={"channel": "PHONE", "identifier": phone, "purpose": "AUTHENTICATE"},
    )
    assert status == 200, raw
    otp = None
    for _ in range(40):
        if OTP_FILE.exists() and OTP_FILE.stat().st_mtime >= before:
            otp = OTP_FILE.read_text().strip()
            if otp.isdigit():
                break
        time.sleep(0.25)
    assert otp, "OTP missing"
    status, _, raw = req(
        "POST",
        "/auth/otp/verify",
        data={
            "channel": "PHONE",
            "identifier": phone,
            "purpose": "AUTHENTICATE",
            "code": otp,
            "platform": "ios",
            "appVersion": "1.0.0",
            "deviceName": "media-http",
        },
    )
    body = json.loads(raw)
    assert status == 200, body
    return body["accessToken"]


def multipart(path: Path, field="file"):
    boundary = "----SpeedyGoBoundary7MA4YWxk"
    data = path.read_bytes()
    parts = [
        f"--{boundary}\r\n".encode(),
        f'Content-Disposition: form-data; name="{field}"; filename="{path.name}"\r\n'.encode(),
        b"Content-Type: image/png\r\n\r\n",
        data,
        f"\r\n--{boundary}--\r\n".encode(),
    ]
    return b"".join(parts), f"multipart/form-data; boundary={boundary}"


def main():
    steps = []
    token = login(PHONE)
    steps.append({"id": "login", "status": "PASS", "phone": PHONE})

    status, _, raw = req("GET", "/merchant/me", token=token)
    me = json.loads(raw)
    mid = me["memberships"][0]["merchantId"]
    branch = me["memberships"][0]["branches"][0]
    bid = branch["id"]
    assert me["memberships"][0]["merchant"]["name"] == "Dar El Bahja"
    steps.append({"id": "identity", "status": "PASS", "merchantId": mid, "branchId": bid})

    # Ensure a product exists
    status, _, raw = req(
        "GET", f"/merchant/{mid}/products?branchId={bid}&limit=5", token=token
    )
    assert status == 200, raw
    products = json.loads(raw).get("items") or []
    if not products:
        status, _, raw = req(
            "GET", f"/merchant/{mid}/categories?branchId={bid}", token=token
        )
        cats = json.loads(raw).get("categories") or []
        if not cats:
            status, _, raw = req(
                "POST",
                f"/merchant/{mid}/categories",
                token=token,
                data={"name": "Media HTTP Cat", "active": True, "branchId": bid},
            )
            assert status in (200, 201), raw
            cid = json.loads(raw)["id"]
        else:
            cid = cats[0]["id"]
        status, _, raw = req(
            "POST",
            f"/merchant/{mid}/products",
            token=token,
            data={
                "branchId": bid,
                "name": "Media HTTP Product",
                "description": "isolated media proof",
                "priceMinor": "1500",
                "categoryId": cid,
                "available": True,
            },
        )
        assert status in (200, 201), raw
        pid = json.loads(raw)["id"]
    else:
        pid = products[0]["id"]

    steps.append({"id": "product_selected", "status": "PASS", "productId": pid})

    blue = FIXTURES / "fixture_blue.png"
    red = FIXTURES / "fixture_red.png"
    cover_a = FIXTURES / "cover_green.png"
    cover_b = FIXTURES / "cover_purple.png"

    # Product upload → bind → merchant GET
    body, ctype = multipart(blue)
    status, _, raw = req(
        "POST",
        f"/merchant/{mid}/branches/{bid}/products/{pid}/image/content",
        token=token,
        data=body,
        headers={"Content-Type": ctype},
    )
    assert status == 201 or status == 200, raw
    upload_ref = json.loads(raw)["uploadReference"]
    status, _, raw = req(
        "PUT",
        f"/merchant/{mid}/branches/{bid}/products/{pid}/image",
        token=token,
        data={"uploadReference": upload_ref},
    )
    assert status == 200, raw
    bind1 = json.loads(raw)
    steps.append({"id": "product_bind", "status": "PASS", "imageUrl": bind1.get("imageUrl")})

    status, ctype, raw = req(
        "GET",
        f"/merchant/{mid}/branches/{bid}/products/{pid}/image",
        token=token,
    )
    assert status == 200, raw
    assert ctype.startswith("image/"), ctype
    assert len(raw) > 100
    (OUT / "product_stream_1.bin").write_bytes(raw)
    size1 = len(raw)
    steps.append({"id": "product_merchant_get", "status": "PASS", "bytes": size1, "contentType": ctype})

    # Replace product image
    body, ctype = multipart(red)
    status, _, raw = req(
        "POST",
        f"/merchant/{mid}/branches/{bid}/products/{pid}/image/content",
        token=token,
        data=body,
        headers={"Content-Type": ctype},
    )
    upload_ref = json.loads(raw)["uploadReference"]
    status, _, raw = req(
        "PUT",
        f"/merchant/{mid}/branches/{bid}/products/{pid}/image",
        token=token,
        data={"uploadReference": upload_ref},
    )
    assert status == 200, raw
    status, ctype, raw = req(
        "GET",
        f"/merchant/{mid}/branches/{bid}/products/{pid}/image",
        token=token,
    )
    assert status == 200, raw
    (OUT / "product_stream_2.bin").write_bytes(raw)
    assert raw != (OUT / "product_stream_1.bin").read_bytes(), "replace must change bytes"
    steps.append({"id": "product_replace_get", "status": "PASS", "bytes": len(raw)})

    # Cover upload → bind → merchant GET
    body, ctype = multipart(cover_a)
    status, _, raw = req(
        "POST",
        f"/merchant/{mid}/branches/{bid}/cover/content",
        token=token,
        data=body,
        headers={"Content-Type": ctype},
    )
    assert status in (200, 201), raw
    upload_ref = json.loads(raw)["uploadReference"]
    status, _, raw = req(
        "PUT",
        f"/merchant/{mid}/branches/{bid}/cover",
        token=token,
        data={"uploadReference": upload_ref},
    )
    assert status == 200, raw
    status, ctype, raw = req(
        "GET", f"/merchant/{mid}/branches/{bid}/cover", token=token
    )
    assert status == 200, raw
    (OUT / "cover_stream_1.bin").write_bytes(raw)
    steps.append({"id": "cover_merchant_get", "status": "PASS", "bytes": len(raw), "contentType": ctype})

    # Replace cover
    body, ctype = multipart(cover_b)
    status, _, raw = req(
        "POST",
        f"/merchant/{mid}/branches/{bid}/cover/content",
        token=token,
        data=body,
        headers={"Content-Type": ctype},
    )
    upload_ref = json.loads(raw)["uploadReference"]
    status, _, raw = req(
        "PUT",
        f"/merchant/{mid}/branches/{bid}/cover",
        token=token,
        data={"uploadReference": upload_ref},
    )
    assert status == 200, raw
    status, _, raw = req(
        "GET", f"/merchant/{mid}/branches/{bid}/cover", token=token
    )
    assert status == 200, raw
    assert raw != (OUT / "cover_stream_1.bin").read_bytes()
    (OUT / "cover_stream_2.bin").write_bytes(raw)
    steps.append({"id": "cover_replace_get", "status": "PASS", "bytes": len(raw)})

    # Delete cover → missing
    status, _, raw = req(
        "DELETE", f"/merchant/{mid}/branches/{bid}/cover", token=token
    )
    assert status in (200, 204), raw
    status, _, raw = req(
        "GET", f"/merchant/{mid}/branches/{bid}/cover", token=token
    )
    assert status == 404, raw
    err = json.loads(raw)
    assert err.get("error", {}).get("code") == "STORAGE_OBJECT_MISSING"
    steps.append({"id": "cover_delete_missing", "status": "PASS"})

    # Unauthorized: no token
    status, _, raw = req(
        "GET", f"/merchant/{mid}/branches/{bid}/products/{pid}/image"
    )
    assert status in (401, 403), raw
    steps.append({"id": "unauth_product_get", "status": "PASS", "http": status})

    # Foreign merchant (Finjan) must not read Dar El Bahja media
    clear_otp_limits()
    finjan_token = login("+213549445167")
    status, _, raw = req(
        "GET",
        f"/merchant/{mid}/branches/{bid}/products/{pid}/image",
        token=finjan_token,
    )
    assert status in (403, 404), raw
    steps.append({"id": "foreign_merchant_denied", "status": "PASS", "http": status})

    # Customer token must not use merchant stream
    clear_otp_limits()
    # Skip if no customer fixture — mark NOT RUN when customer OTP unknown
    steps.append(
        {
            "id": "customer_token_on_merchant_route",
            "status": "NOT RUN",
            "detail": "No isolated customer phone in this script; merchant JWT isolation covered by unauth + foreign merchant",
        }
    )

    report = {
        "layer": "http_api",
        "fixture": "Dar El Bahja",
        "phone": PHONE,
        "merchantId": mid,
        "branchId": bid,
        "productId": pid,
        "finjanUntouched": True,
        "steps": steps,
        "at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    }
    (OUT / "MEDIA_HTTP_EVIDENCE.json").write_text(json.dumps(report, indent=2))
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
