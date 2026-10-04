#!/usr/bin/env bash
# Creates <count> CREATED COD orders on Dar El Bahja for the list-card
# accept / reject fixture, as the synthetic customer +213550000099 (dev only).
# The customer session opened here is logged out at the end; if it is still
# active it is revoked by ID. Writes .run/fixture_orders_<label>.json with
# every created ID. Never prints tokens or OTPs.
# Usage: create_fixture_orders.sh <label> <count>
set -euo pipefail
LABEL="$1"; COUNT="$2"
RUN=/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/parity/live/.run
BACKEND=/Users/mac/Downloads/speedygo_project/apps/backend
CUSTOMER_ACCOUNT=0d00c074-d000-7000-8000-000000000001
mkdir -p "$RUN"

db() { (cd "$BACKEND" && set -a && . ./.env && set +a && psql "${DATABASE_URL%%\?*}" -X -q -A -t -v ON_ERROR_STOP=1 "$@"); }
[[ "$(db -c 'select current_database()')" == "speedygo_dev" ]] || { echo "not speedygo_dev"; exit 1; }
curl -sf http://127.0.0.1:3000/health >/dev/null

S0=$(db -c "select coalesce(string_agg(quote_literal(id::text), ','), '''-''') from sessions where account_id = '$CUSTOMER_ACCOUNT'")
OUT="$RUN/fixture_orders_$LABEL.json"

LABEL="$LABEL" COUNT="$COUNT" OUT="$OUT" python3 <<'PY'
import json, os, time, urllib.request, urllib.error
from pathlib import Path

BASE = "http://127.0.0.1:3000/api/v1"
OTP = Path("/Users/mac/.speedygo/dev/otp-last")
BRANCH = "0d00c071-d000-7000-8000-000000011001"
PRODUCT = "0d00c071-d000-7000-8000-000000030121"
count = int(os.environ["COUNT"])
out = Path(os.environ["OUT"])

def req(method, path, token=None, data=None):
    headers = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    body = None
    if data is not None:
        body = json.dumps(data).encode()
        headers["Content-Type"] = "application/json"
    r = urllib.request.Request(BASE + path, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(r, timeout=60) as res:
            return res.status, json.loads(res.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode() or "{}")

def login():
    for attempt in range(6):
        before = time.time() - 1
        s, _ = req("POST", "/auth/otp/request",
                   data={"channel": "PHONE", "identifier": "+213550000099", "purpose": "AUTHENTICATE"})
        if s in (200, 201, 202):
            break
        time.sleep(15)
    else:
        raise SystemExit(f"otp request refused http={s}")
    otp = None
    for _ in range(60):
        if OTP.exists() and OTP.stat().st_mtime >= before:
            otp = OTP.read_text().strip()
            if otp.isdigit():
                break
        time.sleep(0.25)
    s, body = req("POST", "/auth/otp/verify", data={
        "channel": "PHONE", "identifier": "+213550000099", "purpose": "AUTHENTICATE",
        "code": otp, "platform": "ios", "appVersion": "1.0.0", "deviceName": "parity-fixture-orders"})
    if s not in (200, 201):
        raise SystemExit(f"otp verify failed http={s}")
    return body["accessToken"]

def clear_cart(token):
    s, cart = req("GET", "/customer/cart", token=token)
    if s != 200:
        return
    c = cart.get("cart") or cart
    for it in (c.get("items") or []) if isinstance(c, dict) else []:
        req("DELETE", f"/customer/cart/items/{it['id']}", token=token)

token = login()
result = {"label": os.environ["LABEL"], "branchId": BRANCH, "productId": PRODUCT,
          "customerAccountId": "0d00c074-d000-7000-8000-000000000001", "orders": [], "errors": []}
try:
    s, addrs = req("GET", "/customer/addresses", token=token)
    items = addrs.get("addresses") or addrs.get("items") or [] if isinstance(addrs, dict) else addrs
    addr = next(a["id"] for a in items if abs(float(a.get("latitude") or 0) - 36.78512) < 0.02)
    result["addressId"] = addr
    for i in range(count):
        clear_cart(token)
        s, _ = req("POST", "/customer/cart/items", token=token, data={"productId": PRODUCT, "quantity": 1})
        if s not in (200, 201):
            result["errors"].append(f"cart_add http={s}"); break
        s, preview = req("POST", "/customer/checkout/preview", token=token, data={"addressId": addr})
        if s != 200:
            result["errors"].append(f"preview http={s} code={preview.get('code')}"); break
        s, order = req("POST", "/customer/orders", token=token, data={
            "addressId": addr, "paymentMethod": "COD",
            "expectedMerchandiseSubtotalMinor": int(preview["merchandiseSubtotalMinor"]),
            "expectedDeliveryFeeMinor": int(preview["deliveryFeeMinor"]),
            "expectedCustomerTotalMinor": int(preview["customerTotalMinor"])})
        if s not in (200, 201):
            result["errors"].append(f"order http={s} code={order.get('code')}"); break
        result["orders"].append({"id": order["id"], "publicReference": order.get("publicReference")})
finally:
    clear_cart(token)
    s, _ = req("POST", "/auth/logout", token=token)
    result["customerLogoutHttp"] = s
    out.write_text(json.dumps(result, indent=2) + "\n")
PY

NEW_S=$(db -c "select coalesce(json_agg(json_build_object('id', id, 'revoked', revoked_at is not null)), '[]') from sessions where account_id = '$CUSTOMER_ACCOUNT' and id::text not in ($S0)")
ACTIVE=$(db -c "select count(*) from sessions where account_id = '$CUSTOMER_ACCOUNT' and id::text not in ($S0) and revoked_at is null")
if [[ "$ACTIVE" != "0" ]]; then
  db -c "update sessions set revoked_at = now() where account_id = '$CUSTOMER_ACCOUNT' and id::text not in ($S0) and revoked_at is null" >/dev/null
fi
python3 - "$OUT" "$NEW_S" "$ACTIVE" <<'PY'
import json, sys
p, sessions, active = sys.argv[1], json.loads(sys.argv[2]), int(sys.argv[3])
d = json.load(open(p))
d["customerSessions"] = sessions
d["customerFallbackRevoked"] = active
open(p, "w").write(json.dumps(d, indent=2) + "\n")
print(json.dumps(d, indent=2))
PY
