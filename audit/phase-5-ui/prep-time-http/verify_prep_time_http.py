#!/usr/bin/env python3
"""HTTP Merchant preparation-estimate proof on Dar El Bahja (isolated orders)."""
from __future__ import annotations

import json
import subprocess
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

BASE = "http://127.0.0.1:3000/api/v1"
OTP_FILE = Path("/Users/mac/.speedygo/dev/otp-last")
MERCHANT_PHONE = "+213550000071"  # Dar El Bahja
CUSTOMER_PHONE = "+213550000099"  # synthetic fixture customer
OUT = Path(
    "/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-5-ui/prep-time-http"
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
    subprocess.run(
        [
            "bash",
            "-lc",
            "redis-cli -p 6381 --scan --pattern 'auth:otp:*' | while read k; do redis-cli -p 6381 DEL \"$k\" >/dev/null; done",
        ],
        check=False,
    )


def login(phone: str, device: str) -> str:
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
    assert otp, f"OTP missing for {phone}"
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
            "deviceName": device,
        },
    )
    assert status == 200, body
    return body["accessToken"]


def ensure_customer(token: str) -> str:
    status, me = req("GET", "/customer/me", token=token)
    assert status == 200, me
    if not me.get("customerProfileExists"):
        status, _ = req(
            "POST",
            "/customer/profile",
            token=token,
            data={"fullName": "TEST FIXTURE PrepTime Customer"},
        )
        assert status in (200, 201), _
    status, addrs = req("GET", "/customer/addresses", token=token)
    assert status == 200, addrs
    items = (
        (addrs.get("addresses") or addrs.get("items") or [])
        if isinstance(addrs, dict)
        else addrs
    )
    # Prefer in-zone coords near Dar El Bahja
    for it in items or []:
        lat = float(it.get("latitude") or 0)
        lng = float(it.get("longitude") or 0)
        if abs(lat - 36.78512) < 0.02 and abs(lng - 3.06041) < 0.02:
            return it["id"]
    status, created = req(
        "POST",
        "/customer/addresses",
        token=token,
        data={
            "label": "TEST FIXTURE PrepTime",
            "addressText": "Dar El Bahja PrepTime",
            "latitude": 36.78512,
            "longitude": 3.06041,
        },
    )
    assert status in (200, 201), created
    return created["id"]


def clear_cart(token: str):
    status, cart = req("GET", "/customer/cart", token=token)
    if status != 200:
        return
    c = cart.get("cart") or cart
    for it in c.get("items") or []:
        req("DELETE", f"/customer/cart/items/{it['id']}", token=token)


def create_order(token: str, address_id: str, product_id: str) -> str:
    clear_cart(token)
    status, _ = req(
        "POST",
        "/customer/cart/items",
        token=token,
        data={"productId": product_id, "quantity": 1},
    )
    assert status in (200, 201), _
    status, preview = req(
        "POST",
        "/customer/checkout/preview",
        token=token,
        data={"addressId": address_id},
    )
    assert status == 200, preview
    status, order = req(
        "POST",
        "/customer/orders",
        token=token,
        data={
            "addressId": address_id,
            "paymentMethod": "COD",
            "expectedMerchandiseSubtotalMinor": int(
                preview["merchandiseSubtotalMinor"]
            ),
            "expectedDeliveryFeeMinor": int(preview["deliveryFeeMinor"]),
            "expectedCustomerTotalMinor": int(preview["customerTotalMinor"]),
        },
    )
    assert status in (200, 201), order
    return order["id"]


def err_code(body) -> str | None:
    if not isinstance(body, dict):
        return None
    err = body.get("error") or body
    if isinstance(err, dict):
        return err.get("code")
    return body.get("code")


def main():
    steps = []
    mt = login(MERCHANT_PHONE, "prep-time-merchant")
    steps.append({"id": "merchant_login", "status": "PASS"})

    status, me = req("GET", "/merchant/me", token=mt)
    assert status == 200, me
    membership = me["memberships"][0]
    merchant_id = membership["merchantId"]
    branch_id = membership["branches"][0]["id"]
    steps.append(
        {
            "id": "resolve_branch",
            "status": "PASS",
            "merchantId": merchant_id,
            "branchId": branch_id,
            "branchName": membership["branches"][0].get("name"),
        }
    )

    status, products = req(
        "GET",
        f"/merchant/{merchant_id}/products?branchId={branch_id}&limit=20",
        token=mt,
    )
    assert status == 200, products
    items = products.get("items") if isinstance(products, dict) else products
    assert items, "Dar El Bahja needs at least one product"
    product_id = None
    for p in items:
        detail_status, detail = req(
            "GET",
            f"/merchant/{merchant_id}/products/{p['id']}",
            token=mt,
        )
        if detail_status != 200:
            continue
        groups = detail.get("optionGroups") or []
        required = [g for g in groups if g.get("required")]
        if not required and detail.get("available", True):
            product_id = p["id"]
            break
    assert product_id, "No available product without required options"
    steps.append({"id": "pick_product", "status": "PASS", "productId": product_id})

    ct = login(CUSTOMER_PHONE, "prep-time-customer")
    steps.append({"id": "customer_login", "status": "PASS"})
    address_id = ensure_customer(ct)

    order_a = create_order(ct, address_id, product_id)
    order_b = create_order(ct, address_id, product_id)
    order_ready = create_order(ct, address_id, product_id)
    order_cancel = create_order(ct, address_id, product_id)
    steps.append(
        {
            "id": "create_orders",
            "status": "PASS",
            "orderIds": [order_a, order_b, order_ready, order_cancel],
        }
    )

    # Invalid minutes
    status, body = req(
        "POST",
        f"/merchant/{merchant_id}/orders/{order_a}/accept",
        token=mt,
        data={"preparationMinutes": 3},
    )
    assert status == 400, body
    assert err_code(body) in (
        "MERCHANT_ORDER_PREP_ESTIMATE_INVALID",
        "VALIDATION_ERROR",
    ), body
    steps.append({"id": "reject_invalid_minutes", "status": "PASS", "http": status, "code": err_code(body)})

    # Accept with estimate
    status, accepted = req(
        "POST",
        f"/merchant/{merchant_id}/orders/{order_a}/accept",
        token=mt,
        data={"preparationMinutes": 25},
    )
    assert status == 200, accepted
    assert accepted["preparationMinutes"] == 25
    assert accepted["estimatedReadyAt"]
    assert accepted["originalEstimatedReadyAt"] == accepted["estimatedReadyAt"]
    assert accepted["preparationEstimateVersion"] == 1
    assert accepted["isPreparationLate"] is False
    original_ready = accepted["estimatedReadyAt"]
    steps.append(
        {
            "id": "accept_with_estimate",
            "status": "PASS",
            "orderId": order_a,
            "estimatedReadyAt": original_ready,
            "confirmedAt": accepted.get("confirmedAt"),
        }
    )

    # Re-GET (reopen)
    status, again = req(
        "GET", f"/merchant/{merchant_id}/orders/{order_a}", token=mt
    )
    assert status == 200, again
    assert again["estimatedReadyAt"] == original_ready
    assert again["preparationEstimateVersion"] == 1
    steps.append({"id": "reget_estimate_persisted", "status": "PASS"})

    # Update estimate
    status, updated = req(
        "POST",
        f"/merchant/{merchant_id}/orders/{order_a}/preparation-estimate",
        token=mt,
        data={
            "addMinutes": 10,
            "expectedEstimateVersion": 1,
            "reason": "Forte affluence",
        },
    )
    assert status == 200, updated
    assert updated["preparationEstimateVersion"] == 2
    assert updated["originalEstimatedReadyAt"] == original_ready
    assert updated["estimatedReadyAt"] != original_ready
    assert updated["originalPreparationMinutes"] == 25
    assert updated["preparationMinutes"] == 25  # accept duration; clock advances via estimatedReadyAt
    steps.append(
        {
            "id": "update_estimate",
            "status": "PASS",
            "estimatedReadyAt": updated["estimatedReadyAt"],
            "version": 2,
        }
    )

    # Stale version conflict
    status, conflict = req(
        "POST",
        f"/merchant/{merchant_id}/orders/{order_a}/preparation-estimate",
        token=mt,
        data={"addMinutes": 5, "expectedEstimateVersion": 1},
    )
    assert status == 409, conflict
    assert err_code(conflict) == "MERCHANT_ORDER_PREP_ESTIMATE_CONFLICT"
    steps.append({"id": "stale_version_conflict", "status": "PASS", "http": status})

    # Unauthorized (customer token)
    status, forbidden = req(
        "POST",
        f"/merchant/{merchant_id}/orders/{order_a}/preparation-estimate",
        token=ct,
        data={"addMinutes": 5, "expectedEstimateVersion": 2},
    )
    assert status in (401, 403, 404), forbidden
    steps.append(
        {
            "id": "unauthorized_update",
            "status": "PASS",
            "http": status,
            "code": err_code(forbidden),
        }
    )

    # READY rejects update
    status, _ = req(
        "POST",
        f"/merchant/{merchant_id}/orders/{order_ready}/accept",
        token=mt,
        data={"preparationMinutes": 15},
    )
    assert status == 200, _
    status, _ = req(
        "POST",
        f"/merchant/{merchant_id}/orders/{order_ready}/start-preparation",
        token=mt,
        data={},
    )
    assert status == 200, _
    status, ready = req(
        "POST",
        f"/merchant/{merchant_id}/orders/{order_ready}/mark-ready",
        token=mt,
        data={},
    )
    assert status == 200, ready
    status, not_allowed = req(
        "POST",
        f"/merchant/{merchant_id}/orders/{order_ready}/preparation-estimate",
        token=mt,
        data={"addMinutes": 5, "expectedEstimateVersion": 1},
    )
    assert status == 409, not_allowed
    assert err_code(not_allowed) == "MERCHANT_ORDER_PREP_ESTIMATE_NOT_ALLOWED"
    steps.append({"id": "ready_rejects_update", "status": "PASS"})

    # Cancelled rejects update
    status, _ = req(
        "POST",
        f"/merchant/{merchant_id}/orders/{order_cancel}/accept",
        token=mt,
        data={"preparationMinutes": 15},
    )
    assert status == 200, _
    # Cancel via customer if available, else reject a different path:
    # use mark after we reject order_b then... For cancel we reject before accept on order_b
    # Actually order_cancel was accepted — use DB-free path: reject only works pre-accept.
    # Create fresh and reject:
    order_rej = create_order(ct, address_id, product_id)
    status, _ = req(
        "POST",
        f"/merchant/{merchant_id}/orders/{order_rej}/reject",
        token=mt,
        data={"reason": "TEST FIXTURE prep cancel"},
    )
    assert status == 200, _
    status, cancel_upd = req(
        "POST",
        f"/merchant/{merchant_id}/orders/{order_rej}/preparation-estimate",
        token=mt,
        data={"addMinutes": 5, "expectedEstimateVersion": 1},
    )
    assert status == 409, cancel_upd
    steps.append({"id": "cancelled_rejects_update", "status": "PASS", "http": status})

    # Late derived: set estimate in past via short accept on order_b then wait — use 5 min
    # and force late check by accepting with 5 and backdating via SQL if needed.
    # Prefer SQL on speedygo_dev only for isolated fixture:
    status, short = req(
        "POST",
        f"/merchant/{merchant_id}/orders/{order_b}/accept",
        token=mt,
        data={"preparationMinutes": 5},
    )
    assert status == 200, short
    oid = order_b
    subprocess.run(
        [
            "bash",
            "-lc",
            f"PGPASSWORD=speedygo psql -h 127.0.0.1 -p 5433 -U speedygo -d speedygo_dev -c "
            f"\"UPDATE orders SET estimated_ready_at = NOW() - INTERVAL '2 minutes', "
            f"original_estimated_ready_at = NOW() - INTERVAL '2 minutes' "
            f"WHERE id = '{oid}';\"",
        ],
        check=True,
    )
    status, late = req("GET", f"/merchant/{merchant_id}/orders/{oid}", token=mt)
    assert status == 200, late
    assert late["isPreparationLate"] is True
    assert late["fulfillmentStatus"] in ("ACCEPTED", "PREPARING")
    fs_before = late["fulfillmentStatus"]
    status, late2 = req("GET", f"/merchant/{merchant_id}/orders/{oid}", token=mt)
    assert late2["fulfillmentStatus"] == fs_before
    assert late2["status"] == late["status"]
    steps.append(
        {
            "id": "late_does_not_mutate_fulfillment",
            "status": "PASS",
            "fulfillmentStatus": fs_before,
            "isPreparationLate": True,
        }
    )

    # Revisions table row exists
    rev = subprocess.check_output(
        [
            "bash",
            "-lc",
            f"PGPASSWORD=speedygo psql -h 127.0.0.1 -p 5433 -U speedygo -d speedygo_dev -tAc "
            f"\"SELECT count(*) FROM order_preparation_estimate_revisions WHERE order_id = '{order_a}';\"",
        ],
        text=True,
    ).strip()
    assert int(rev) >= 2, rev  # accept + update
    steps.append({"id": "revisions_recorded", "status": "PASS", "count": int(rev)})

    evidence = {
        "fixture": "Dar El Bahja",
        "phone": MERCHANT_PHONE,
        "merchantId": merchant_id,
        "branchId": branch_id,
        "customerPhone": CUSTOMER_PHONE,
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "steps": steps,
        "notificationsClaimed": False,
    }
    (OUT / "PREP_TIME_HTTP_EVIDENCE.json").write_text(
        json.dumps(evidence, indent=2) + "\n"
    )
    print(json.dumps({"ok": True, "steps": len(steps)}, indent=2))


if __name__ == "__main__":
    main()
