#!/usr/bin/env bash
# Phase 2 Merchant order ops — synthetic API fixture preparation (speedygo_dev only).
# Merchant UI mutations are exercised separately. This script prepares catalog + two COD orders.
# Does NOT touch Finjan / Customer Revue / real payments. Does NOT broaden Admin permissions.
set -euo pipefail

AUDIT_DIR="$(cd "$(dirname "$0")" && pwd)"
API="${API_BASE_URL:-http://127.0.0.1:3000/api/v1}"
OTP_FILE="${HOME}/.speedygo/dev/otp-last"
MERCHANT_ID="01a0b4e7-83a0-7742-8ac0-03fcb5e9b056"
BRANCH_ID="01a0b4ec-f8e2-751e-8129-f1d5322ea68d"
MERCHANT_PHONE_ID="0559907701"
# Synthetic customer for order create only (API-only actor).
CUSTOMER_PHONE_ID="${PHASE2_CUSTOMER_PHONE:-0559907702}"

mkdir -p "$AUDIT_DIR/fixtures" "$AUDIT_DIR/screenshots"
RESULTS="$AUDIT_DIR/fixtures/live_api_results.json"
LOG="$AUDIT_DIR/fixtures/live_api_log.txt"
: > "$LOG"

log() { echo "[$(date -u +%H:%M:%S)] $*" | tee -a "$LOG" >&2; }

json_get() {
  python3 -c "import json,sys; d=json.load(sys.stdin); print(d$1)"
}

auth() {
  local phone="$1"
  curl -sf -X POST "$API/auth/otp/request" \
    -H 'Content-Type: application/json' \
    -d "{\"channel\":\"PHONE\",\"identifier\":\"$phone\",\"purpose\":\"AUTHENTICATE\"}" >/dev/null
  sleep 1.5
  local otp
  otp=$(tr -d ' \n\r' < "$OTP_FILE")
  local raw
  raw=$(curl -s -w "\n%{http_code}" -X POST "$API/auth/otp/verify" \
    -H 'Content-Type: application/json' \
    -d "{\"channel\":\"PHONE\",\"identifier\":\"$phone\",\"purpose\":\"AUTHENTICATE\",\"code\":\"$otp\",\"platform\":\"ios\",\"appVersion\":\"1.0.0\"}")
  local code="${raw##*$'\n'}"
  local body="${raw%$'\n'*}"
  if [[ "$code" != "200" && "$code" != "201" ]]; then
    log "auth_fail phone=$phone http=$code body=$(echo "$body" | head -c 200)"
    return 1
  fi
  echo "$body" | python3 -c "import json,sys; print(json.load(sys.stdin)['accessToken'])"
}

require_api() {
  curl -sf "http://127.0.0.1:3000/health" >/dev/null
  PGPASSWORD=speedygo psql -h 127.0.0.1 -p 5433 -U speedygo -d speedygo_dev -tAc "SELECT current_database();" | grep -qx speedygo_dev
}

require_api
log "api_ok db=speedygo_dev merchant=$MERCHANT_ID branch=$BRANCH_ID"

MT=$(auth "$MERCHANT_PHONE_ID")
log "merchant_auth_ok"

# Opening hours — 24h all week (expectedVersion 0 create)
HOURS_BODY=$(python3 - <<'PY'
import json
days=[{"dayOfWeek":d,"intervals":[{"opens":"00:00","closes":"00:00"}]} for d in range(1,8)]
print(json.dumps({"expectedVersion":0,"days":days}))
PY
)
HOURS_HTTP=$(curl -s -o /tmp/p2_hours.json -w "%{http_code}" -X PUT \
  "$API/merchant/$MERCHANT_ID/branches/$BRANCH_ID/opening-hours" \
  -H "Authorization: Bearer $MT" -H 'Content-Type: application/json' \
  -d "$HOURS_BODY")
log "opening_hours http=$HOURS_HTTP"
if [[ "$HOURS_HTTP" == "409" ]]; then
  # Already configured — fetch version and rewrite
  VER=$(curl -sf "$API/merchant/$MERCHANT_ID/branches/$BRANCH_ID/opening-hours" \
    -H "Authorization: Bearer $MT" | json_get "['version']")
  HOURS_BODY=$(python3 - <<PY
import json
days=[{"dayOfWeek":d,"intervals":[{"opens":"00:00","closes":"00:00"}]} for d in range(1,8)]
print(json.dumps({"expectedVersion":int("$VER"),"days":days}))
PY
)
  HOURS_HTTP=$(curl -s -o /tmp/p2_hours.json -w "%{http_code}" -X PUT \
    "$API/merchant/$MERCHANT_ID/branches/$BRANCH_ID/opening-hours" \
    -H "Authorization: Bearer $MT" -H 'Content-Type: application/json' \
    -d "$HOURS_BODY")
  log "opening_hours_retry http=$HOURS_HTTP ver=$VER"
fi

# Category
CAT_HTTP=$(curl -s -o /tmp/p2_cat.json -w "%{http_code}" -X POST \
  "$API/merchant/$MERCHANT_ID/categories" \
  -H "Authorization: Bearer $MT" -H 'Content-Type: application/json' \
  -d "{\"branchId\":\"$BRANCH_ID\",\"name\":\"TEST FIXTURE Phase2 Category\",\"active\":true}")
log "category http=$CAT_HTTP"
CAT_ID=$(python3 -c "import json; print(json.load(open('/tmp/p2_cat.json')).get('id',''))" 2>/dev/null || true)
if [[ -z "$CAT_ID" && "$CAT_HTTP" != "201" ]]; then
  # list existing
  CAT_ID=$(curl -sf "$API/merchant/$MERCHANT_ID/categories?branchId=$BRANCH_ID" \
    -H "Authorization: Bearer $MT" | python3 -c "import json,sys; items=json.load(sys.stdin).get('items') or json.load(open('/dev/stdin')) if False else json.load(sys.stdin); print((items.get('items') if isinstance(items,dict) else items)[0]['id'] if items else '')" 2>/dev/null || true)
  # simpler list parse
  CAT_ID=$(curl -sf "$API/merchant/$MERCHANT_ID/categories?branchId=$BRANCH_ID" \
    -H "Authorization: Bearer $MT" | python3 - <<'PY'
import json,sys
d=json.load(sys.stdin)
items=d.get('items') if isinstance(d,dict) else d
print(items[0]['id'] if items else '')
PY
)
fi
log "category_id=$CAT_ID"

# Product
PROD_HTTP=$(curl -s -o /tmp/p2_prod.json -w "%{http_code}" -X POST \
  "$API/merchant/$MERCHANT_ID/products" \
  -H "Authorization: Bearer $MT" -H 'Content-Type: application/json' \
  -d "{\"branchId\":\"$BRANCH_ID\",\"categoryId\":\"$CAT_ID\",\"name\":\"TEST FIXTURE Phase2 Café\",\"priceMinor\":1200,\"available\":true}")
log "product http=$PROD_HTTP"
PROD_ID=$(python3 -c "import json; print(json.load(open('/tmp/p2_prod.json')).get('id',''))" 2>/dev/null || true)
if [[ -z "$PROD_ID" ]]; then
  PROD_ID=$(curl -sf "$API/merchant/$MERCHANT_ID/products?branchId=$BRANCH_ID&limit=5" \
    -H "Authorization: Bearer $MT" | python3 -c "import json,sys; d=json.load(sys.stdin); items=d.get('items',d); print(items[0]['id'] if items else '')")
fi
log "product_id=$PROD_ID"

# Customer auth + profile + address + cart + 2 orders
CT=$(auth "$CUSTOMER_PHONE_ID")
log "customer_auth_ok phone=$CUSTOMER_PHONE_ID"

curl -sf "$API/customer/me" -H "Authorization: Bearer $CT" >/tmp/p2_cme.json
EXISTS=$(python3 -c "import json; print(json.load(open('/tmp/p2_cme.json')).get('customerProfileExists'))")
log "customer_profile_exists=$EXISTS"
if [[ "$EXISTS" != "True" && "$EXISTS" != "true" ]]; then
  PROF_HTTP=$(curl -s -o /tmp/p2_cprof.json -w "%{http_code}" -X POST "$API/customer/profile" \
    -H "Authorization: Bearer $CT" -H 'Content-Type: application/json' \
    -d '{"fullName":"TEST FIXTURE Phase2 Customer"}')
  log "customer_profile_create http=$PROF_HTTP"
fi

ADDR_HTTP=$(curl -s -o /tmp/p2_addr.json -w "%{http_code}" -X POST \
  "$API/customer/addresses" \
  -H "Authorization: Bearer $CT" -H 'Content-Type: application/json' \
  -d '{"label":"TEST FIXTURE Phase2 Addr","addressText":"Hydra TEST FIXTURE","latitude":36.747,"longitude":3.034}')
log "address http=$ADDR_HTTP"
ADDR_ID=$(python3 -c "import json; print(json.load(open('/tmp/p2_addr.json')).get('id',''))" 2>/dev/null || true)
if [[ -z "$ADDR_ID" ]]; then
  ADDR_ID=$(curl -sf "$API/customer/addresses" -H "Authorization: Bearer $CT" | python3 -c "import json,sys; d=json.load(sys.stdin); items=d.get('items',d) if isinstance(d,dict) else d; print(items[0]['id'] if items else '')")
fi
log "address_id=$ADDR_ID"

create_order() {
  local label="$1"
  # Clear prior cart items if any
  local cart
  cart=$(curl -sf "$API/customer/cart" -H "Authorization: Bearer $CT" || echo '{}')
  echo "$cart" | python3 - <<'PY' > /tmp/p2_clear_ids.txt
import json,sys
d=json.load(sys.stdin)
cart=d.get('cart') or d
items=cart.get('items') if isinstance(cart,dict) else []
for it in items or []:
  print(it.get('id',''))
PY
  while read -r iid; do
    [[ -z "$iid" ]] && continue
    curl -sf -X DELETE "$API/customer/cart/items/$iid" -H "Authorization: Bearer $CT" >/dev/null || true
  done < /tmp/p2_clear_ids.txt

  local add_http
  add_http=$(curl -s -o /tmp/p2_cart_$label.json -w "%{http_code}" -X POST "$API/customer/cart/items" \
    -H "Authorization: Bearer $CT" -H 'Content-Type: application/json' \
    -d "{\"productId\":\"$PROD_ID\",\"quantity\":1}")
  log "cart_add_$label http=$add_http"

  local prev_http
  prev_http=$(curl -s -o /tmp/p2_prev_$label.json -w "%{http_code}" -X POST "$API/customer/checkout/preview" \
    -H "Authorization: Bearer $CT" -H 'Content-Type: application/json' \
    -d "{\"addressId\":\"$ADDR_ID\"}")
  log "checkout_preview_$label http=$prev_http"
  if [[ "$prev_http" != "200" ]]; then
    head -c 400 /tmp/p2_prev_$label.json | tee -a "$LOG"; echo >> "$LOG"
    echo ""
    return 0
  fi
  local body
  body=$(python3 - <<PY
import json
p=json.load(open('/tmp/p2_prev_$label.json'))
print(json.dumps({
  "addressId": "$ADDR_ID",
  "paymentMethod": "COD",
  "expectedMerchandiseSubtotalMinor": int(p["merchandiseSubtotalMinor"]),
  "expectedDeliveryFeeMinor": int(p["deliveryFeeMinor"]),
  "expectedCustomerTotalMinor": int(p["customerTotalMinor"]),
}))
PY
)
  local oh
  oh=$(curl -s -o /tmp/p2_order_$label.json -w "%{http_code}" -X POST "$API/customer/orders" \
    -H "Authorization: Bearer $CT" -H 'Content-Type: application/json' \
    -d "$body")
  log "order_$label http=$oh"
  if [[ "$oh" != "201" && "$oh" != "200" ]]; then
    head -c 400 /tmp/p2_order_$label.json | tee -a "$LOG"; echo >> "$LOG"
  fi
  python3 -c "import json; d=json.load(open('/tmp/p2_order_$label.json')); print(d.get('id',''))" 2>/dev/null || true
}

ORDER_ACCEPT=$(create_order accept)
ORDER_REJECT=$(create_order reject)
log "order_accept_id=$ORDER_ACCEPT order_reject_id=$ORDER_REJECT"

# Merchant list confirm
LIST=$(curl -sf "$API/merchant/$MERCHANT_ID/orders?branchId=$BRANCH_ID&limit=10" \
  -H "Authorization: Bearer $MT")
echo "$LIST" > "$AUDIT_DIR/fixtures/merchant_orders_list.json"
TOTAL=$(echo "$LIST" | json_get "['total']")
log "merchant_list_total=$TOTAL"

python3 - <<PY
import json, pathlib
out = {
  "merchantId": "$MERCHANT_ID",
  "branchId": "$BRANCH_ID",
  "categoryId": "$CAT_ID",
  "productId": "$PROD_ID",
  "customerPhone": "+213${CUSTOMER_PHONE_ID#0}",
  "addressId": "$ADDR_ID",
  "orderAcceptId": "$ORDER_ACCEPT",
  "orderRejectId": "$ORDER_REJECT",
  "openingHoursHttp": "$HOURS_HTTP",
  "listTotal": int("$TOTAL" or 0),
  "note": "Synthetic Phase 2 fixture. API-only customer/order create. Merchant UI mutations separate.",
}
pathlib.Path("$RESULTS").write_text(json.dumps(out, indent=2) + "\n")
print(json.dumps(out, indent=2))
PY

log "done results=$RESULTS"
