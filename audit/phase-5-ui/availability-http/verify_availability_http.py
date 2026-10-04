#!/usr/bin/env python3
"""HTTP Merchant availability proof on Dar El Bahja (no Flutter, no Finjan)."""
from __future__ import annotations

import json
import time
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

BASE = "http://127.0.0.1:3000/api/v1"
OTP_FILE = Path("/Users/mac/.speedygo/dev/otp-last")
PHONE = "+213550000071"  # Dar El Bahja
OUT = Path(
    "/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-5-ui/availability-http"
)
OUT.mkdir(parents=True, exist_ok=True)


def req(method: str, path: str, token: str | None = None, data=None):
    h = {}
    if token:
        h["Authorization"] = f"Bearer {token}"
    body = None
    if data is not None:
        body = json.dumps(data).encode()
        h["Content-Type"] = "application/json"
    r = urllib.request.Request(BASE + path, data=body, headers=h, method=method)
    try:
        with urllib.request.urlopen(r, timeout=60) as res:
            raw = res.read()
            return res.status, json.loads(raw.decode() or "{}")
    except urllib.error.HTTPError as e:
        raw = e.read()
        try:
            parsed = json.loads(raw.decode() or "{}")
        except Exception:
            parsed = {"raw": raw.decode(errors="replace")}
        return e.code, parsed


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
    status, body = req(
        "POST",
        "/auth/otp/request",
        data={"channel": "PHONE", "identifier": phone, "purpose": "AUTHENTICATE"},
    )
    assert status == 200, body
    otp = None
    for _ in range(40):
        if OTP_FILE.exists() and OTP_FILE.stat().st_mtime >= before:
            otp = OTP_FILE.read_text().strip()
            if otp.isdigit():
                break
        time.sleep(0.25)
    assert otp, "OTP missing"
    status, body = req(
        "POST",
        "/auth/otp/verify",
        data={
            "channel": "PHONE",
            "identifier": phone,
            "purpose": "AUTHENTICATE",
            "code": otp,
            "platform": "ios",
            "appVersion": "1.0.0",
            "deviceName": "availability-http",
        },
    )
    assert status == 200, body
    return body["accessToken"]


def main():
    steps = []
    token = login(PHONE)
    steps.append({"id": "login", "status": "PASS"})

    status, me = req("GET", "/merchant/me", token=token)
    assert status == 200, me
    membership = me["memberships"][0]
    merchant_id = membership["merchantId"]
    branch = membership["branches"][0]
    branch_id = branch["id"]
    assert membership.get("merchant", {}).get("name") == "Dar El Bahja" or (
        "Bahja" in (branch.get("name") or "")
    ), me
    steps.append(
        {
            "id": "resolve_branch",
            "status": "PASS",
            "merchantId": merchant_id,
            "branchId": branch_id,
            "branchName": branch.get("name"),
            "merchantName": membership.get("merchant", {}).get("name"),
        }
    )

    path = f"/merchant/{merchant_id}/branches/{branch_id}/availability"

    status, get0 = req("GET", path, token=token)
    assert status == 200, get0
    assert "isOpenNow" in get0 and "availabilityMode" in get0
    steps.append({"id": "get_initial", "status": "PASS", "body": get0})

    version = get0.get("version") or 0
    # Force closed
    status, closed = req(
        "PUT",
        path,
        token=token,
        data={
            "expectedVersion": version,
            "mode": "FORCE_CLOSED",
            "reasonCode": "TECHNICAL",
        },
    )
    assert status == 200, closed
    assert closed["availabilityMode"] == "FORCE_CLOSED"
    assert closed["isOpenNow"] is False
    assert closed["nextOpenAt"] is None
    steps.append({"id": "put_force_closed", "status": "PASS", "body": closed})

    # Conflict
    status, conflict = req(
        "PUT",
        path,
        token=token,
        data={"expectedVersion": version, "mode": "FOLLOW_SCHEDULE"},
    )
    assert status == 409, conflict
    assert conflict.get("error", {}).get("code") == "AVAILABILITY_VERSION_CONFLICT"
    steps.append({"id": "put_conflict", "status": "PASS", "body": conflict})

    v2 = closed["version"]
    until = (datetime.now(timezone.utc) + timedelta(minutes=30)).strftime(
        "%Y-%m-%dT%H:%M:%S.000Z"
    )
    status, temp = req(
        "PUT",
        path,
        token=token,
        data={
            "expectedVersion": v2,
            "mode": "TEMPORARY_CLOSED",
            "reasonCode": "PEAK_KITCHEN",
            "closedUntil": until,
            "customerMessage": "Pause 30 min (live verify)",
        },
    )
    assert status == 200, temp
    assert temp["availabilityMode"] == "TEMPORARY_CLOSED"
    assert temp["isOpenNow"] is False
    assert temp["closedUntil"] is not None
    steps.append({"id": "put_temporary", "status": "PASS", "body": temp})

    # Restore follow schedule
    status, follow = req(
        "PUT",
        path,
        token=token,
        data={
            "expectedVersion": temp["version"],
            "mode": "FOLLOW_SCHEDULE",
        },
    )
    assert status == 200, follow
    assert follow["availabilityMode"] == "FOLLOW_SCHEDULE"
    steps.append({"id": "put_follow_schedule", "status": "PASS", "body": follow})

    # Past closedUntil rejected
    past = (datetime.now(timezone.utc) - timedelta(minutes=5)).strftime(
        "%Y-%m-%dT%H:%M:%S.000Z"
    )
    status, bad = req(
        "PUT",
        path,
        token=token,
        data={
            "expectedVersion": follow["version"],
            "mode": "TEMPORARY_CLOSED",
            "closedUntil": past,
        },
    )
    assert status == 400, bad
    assert bad.get("error", {}).get("code") == "AVAILABILITY_INVALID"
    steps.append({"id": "reject_past_until", "status": "PASS", "body": bad})

    evidence = {
        "fixture": "Dar El Bahja",
        "phone": PHONE,
        "merchantId": merchant_id,
        "branchId": branch_id,
        "steps": steps,
        "at": datetime.now(timezone.utc).isoformat(),
    }
    (OUT / "AVAILABILITY_HTTP_EVIDENCE.json").write_text(
        json.dumps(evidence, indent=2)
    )
    print(json.dumps({"ok": True, "steps": [s["id"] for s in steps]}, indent=2))


if __name__ == "__main__":
    main()
