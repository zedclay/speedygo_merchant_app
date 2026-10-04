#!/usr/bin/env bash
# Prep-time verification gap close: harness accept → terminate/relaunch cold → a11y.
# Dar El Bahja on iPhone 16e only. Does not touch Finjan / Customer / Driver Keychain.
set -euo pipefail

UDID="${PREP_UDID:-8DB9007A-B816-4EC5-86ED-C627AC60F2C5}"
BUNDLE=com.speedygo.speedygoMerchantApp
API="${API_BASE_URL:-http://127.0.0.1:3000/api/v1}"
ROOT="/Users/mac/Downloads/speedygo_project/apps/merchant_app"
OUT="$ROOT/audit/phase-5-ui/prep-time-live"
HTTP="$ROOT/audit/phase-5-ui/prep-time-http"
REVIEW="$ROOT/audit/phase-5-ui/prep-time-review"
SHOT=/tmp/prep_host_shot.txt
MID=0d00c071-d000-7000-8000-000000010001
BID=0d00c071-d000-7000-8000-000000011001

mkdir -p "$OUT" "$REVIEW"
: > "$SHOT"

watch_shots() {
  local stop_tag="$1"
  (
    last=""
    while true; do
      tag=$(tail -1 "$SHOT" 2>/dev/null | tr -d '\n' || true)
      if [[ -n "$tag" && "$tag" != "$last" ]]; then
        sleep 1.5
        xcrun simctl io "$UDID" screenshot "$OUT/${tag}.png" || true
        echo "SHOT $tag $(stat -f%z "$OUT/${tag}.png" 2>/dev/null || echo 0)"
        last="$tag"
        [[ "$tag" == "$stop_tag" ]] && break
      fi
      sleep 0.4
    done
  ) >> /tmp/prep_shot_watch.log 2>&1 &
  echo $!
}

ensure_backend() {
  curl -sf http://127.0.0.1:3000/health >/dev/null
}

create_pending_order() {
  python3 <<'PY'
import json, time, urllib.request, urllib.error, subprocess
from pathlib import Path
BASE="http://127.0.0.1:3000/api/v1"
OTP=Path("/Users/mac/.speedygo/dev/otp-last")
MID="0d00c071-d000-7000-8000-000000010001"
BID="0d00c071-d000-7000-8000-000000011001"
OUT=Path("/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/phase-5-ui/prep-time-http")

def req(method,path,token=None,data=None):
  h={}
  if token: h["Authorization"]=f"Bearer {token}"
  body=None
  if data is not None:
    body=json.dumps(data).encode(); h["Content-Type"]="application/json"
  r=urllib.request.Request(BASE+path,data=body,headers=h,method=method)
  try:
    with urllib.request.urlopen(r,timeout=60) as res:
      return res.status, json.loads(res.read().decode() or "{}")
  except urllib.error.HTTPError as e:
    return e.code, json.loads(e.read().decode() or "{}")

def login(phone,device):
  subprocess.run(
    [
      "bash",
      "-lc",
      "set +u; redis-cli -p 6381 --scan --pattern 'auth:otp:*' 2>/dev/null | while IFS= read -r k; do [ -n \"$k\" ] && redis-cli -p 6381 DEL \"$k\" >/dev/null; done",
    ],
    check=False,
  )
  before=time.time()-1
  req("POST","/auth/otp/request",data={"channel":"PHONE","identifier":phone,"purpose":"AUTHENTICATE"})
  otp=None
  for _ in range(40):
    if OTP.exists() and OTP.stat().st_mtime>=before:
      otp=OTP.read_text().strip()
      if otp.isdigit(): break
    time.sleep(0.2)
  return req("POST","/auth/otp/verify",data={"channel":"PHONE","identifier":phone,"purpose":"AUTHENTICATE","code":otp,"platform":"ios","appVersion":"1.0.0","deviceName":device})[1]["accessToken"]

def clear_cart(token):
  s,cart=req("GET","/customer/cart",token=token)
  if s!=200: return
  c=cart.get("cart") or cart
  for it in c.get("items") or []:
    req("DELETE",f"/customer/cart/items/{it['id']}",token=token)

mt=login("+213550000071","prep-gap-m")
ct=login("+213550000099","prep-gap-c")
addrs=req("GET","/customer/addresses",token=ct)[1].get("addresses") or []
addr=next(a["id"] for a in addrs if abs(float(a.get("latitude") or 0)-36.78512)<0.02)
products=req("GET",f"/merchant/{MID}/products?branchId={BID}&limit=20",token=mt)[1].get("items",[])
product_id=None
for p in products:
  d=req("GET",f"/merchant/{MID}/products/{p['id']}",token=mt)[1]
  if not [g for g in (d.get("optionGroups") or []) if g.get("required")] and d.get("available", True):
    product_id=p["id"]; break
assert product_id and addr
clear_cart(ct)
req("POST","/customer/cart/items",token=ct,data={"productId":product_id,"quantity":1})
s,preview=req("POST","/customer/checkout/preview",token=ct,data={"addressId":addr})
assert s==200, preview
s,order=req("POST","/customer/orders",token=ct,data={
  "addressId":addr,"paymentMethod":"COD",
  "expectedMerchandiseSubtotalMinor":int(preview["merchandiseSubtotalMinor"]),
  "expectedDeliveryFeeMinor":int(preview["deliveryFeeMinor"]),
  "expectedCustomerTotalMinor":int(preview["customerTotalMinor"]),
})
assert s in (200,201), order
oid=order["id"]
(OUT/"PREP_TIME_UI_ORDERS.json").write_text(json.dumps({"acceptOrderId":oid,"coldOrderId":oid}, indent=2)+"\n")
print(oid)
PY
}

get_order_estimate() {
  local oid="$1"
  python3 <<PY
import json, time, urllib.request, urllib.error, subprocess
from pathlib import Path
BASE="http://127.0.0.1:3000/api/v1"
OTP=Path("/Users/mac/.speedygo/dev/otp-last")
MID="0d00c071-d000-7000-8000-000000010001"
OID="$oid"

def req(method,path,token=None,data=None):
  h={}
  if token: h["Authorization"]=f"Bearer {token}"
  body=None
  if data is not None:
    body=json.dumps(data).encode(); h["Content-Type"]="application/json"
  r=urllib.request.Request(BASE+path,data=body,headers=h,method=method)
  try:
    with urllib.request.urlopen(r,timeout=60) as res:
      return res.status, json.loads(res.read().decode() or "{}")
  except urllib.error.HTTPError as e:
    return e.code, json.loads(e.read().decode() or "{}")

def login(phone):
  subprocess.run(
    [
      "bash",
      "-lc",
      "set +u; redis-cli -p 6381 --scan --pattern 'auth:otp:*' 2>/dev/null | while IFS= read -r k; do [ -n \"$k\" ] && redis-cli -p 6381 DEL \"$k\" >/dev/null; done",
    ],
    check=False,
  )
  before=time.time()-1
  req("POST","/auth/otp/request",data={"channel":"PHONE","identifier":phone,"purpose":"AUTHENTICATE"})
  otp=None
  for _ in range(40):
    if OTP.exists() and OTP.stat().st_mtime>=before:
      otp=OTP.read_text().strip()
      if otp.isdigit(): break
    time.sleep(0.2)
  return req("POST","/auth/otp/verify",data={"channel":"PHONE","identifier":phone,"purpose":"AUTHENTICATE","code":otp,"platform":"ios","appVersion":"1.0.0","deviceName":"prep-gap-get"})[1]["accessToken"]

mt=login("+213550000071")
s,o=req("GET",f"/merchant/{MID}/orders/{OID}",token=mt)
assert s==200, o
print(json.dumps({
  "id": o["id"],
  "fulfillmentStatus": o["fulfillmentStatus"],
  "preparationMinutes": o.get("preparationMinutes"),
  "estimatedReadyAt": o.get("estimatedReadyAt"),
  "originalEstimatedReadyAt": o.get("originalEstimatedReadyAt"),
  "preparationEstimateVersion": o.get("preparationEstimateVersion"),
  "isPreparationLate": o.get("isPreparationLate"),
}))
PY
}

run_flutter_mode() {
  local mode="$1"
  local accept_id="$2"
  local cold_id="$3"
  local stop_tag="$4"
  : > "$SHOT"
  : > /tmp/prep_shot_watch.log
  WATCH=$(watch_shots "$stop_tag")
  set +e
  (
    cd "$ROOT"
    flutter test integration_test/prep_time_live_test.dart \
      -d "$UDID" \
      --dart-define=API_BASE_URL="$API" \
      --dart-define=PREP_LIVE_PHONE=550000071 \
      --dart-define=PREP_LIVE_MODE="$mode" \
      --dart-define=PREP_ACCEPT_ORDER_ID="$accept_id" \
      --dart-define=PREP_COLD_ORDER_ID="$cold_id"
  ) > "/tmp/prep_live_${mode}.txt" 2>&1
  FT=$?
  set -e
  kill "$WATCH" 2>/dev/null || true
  wait "$WATCH" 2>/dev/null || true
  echo "MODE=$mode FLUTTER_EXIT=$FT"
  return "$FT"
}

ensure_backend
echo "=== create pending order ==="
OID=$(create_pending_order)
echo "ORDER=$OID"

echo "=== accept mode (card navigation) ==="
set +e
run_flutter_mode accept "$OID" "$OID" prep-after-update
ACCEPT_EXIT=$?
set -e
AFTER_ACCEPT=$(get_order_estimate "$OID")
echo "AFTER_ACCEPT=$AFTER_ACCEPT"
echo "$AFTER_ACCEPT" > "$OUT/PREP_AFTER_ACCEPT.json"

echo "=== terminate Merchant (no uninstall) ==="
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
sleep 2
# confirm still installed
xcrun simctl get_app_container "$UDID" "$BUNDLE" data >/dev/null
echo "APP_STILL_INSTALLED=yes"

echo "=== cold relaunch mode ==="
set +e
run_flutter_mode cold "$OID" "$OID" prep-cold-reopen
COLD_EXIT=$?
set -e
AFTER_COLD=$(get_order_estimate "$OID")
echo "AFTER_COLD=$AFTER_COLD"
echo "$AFTER_COLD" > "$OUT/PREP_AFTER_COLD.json"

python3 <<PY
import json
from pathlib import Path
OUT=Path("$OUT")
a=json.loads((OUT/"PREP_AFTER_ACCEPT.json").read_text())
c=json.loads((OUT/"PREP_AFTER_COLD.json").read_text())
ok = (
  a.get("estimatedReadyAt") == c.get("estimatedReadyAt")
  and a.get("preparationEstimateVersion") == c.get("preparationEstimateVersion")
  and a.get("originalEstimatedReadyAt") == c.get("originalEstimatedReadyAt")
  and int(c.get("preparationEstimateVersion") or 0) >= 2
)
print(json.dumps({"coldPersistOk": ok, "accept": a, "cold": c}, indent=2))
(OUT/"PREP_COLD_COMPARE.json").write_text(json.dumps({"coldPersistOk": ok, "accept": a, "cold": c}, indent=2)+"\n")
PY

echo "=== a11y order (enlarged text on 16e) ==="
OID2=$(create_pending_order)
echo "A11Y_ORDER=$OID2"
set +e
run_flutter_mode a11y "$OID2" "$OID2" prep-a11y-after-update
A11Y_EXIT=$?
set -e

# Build compact review ZIP
python3 <<PY
import json, zipfile
from pathlib import Path
from datetime import datetime, timezone
OUT=Path("$OUT")
REVIEW=Path("$REVIEW")
REVIEW.mkdir(parents=True, exist_ok=True)
shots=[
  "prep-accept-sheet.png","prep-countdown.png","prep-reopen.png",
  "prep-update-sheet.png","prep-after-update.png","prep-cold-reopen.png",
  "prep-a11y-accept-sheet.png","prep-a11y-update-sheet.png","prep-a11y-after-update.png",
]
zip_path=REVIEW/"prep_time_review.zip"
with zipfile.ZipFile(zip_path,"w",compression=zipfile.ZIP_DEFLATED) as z:
  for name in shots:
    p=OUT/name
    if p.exists() and p.stat().st_size>1000:
      z.write(p, arcname=f"screenshots/{name}")
  for name in [
    "PREP_TIME_LIVE_PROVENANCE_accept.json",
    "PREP_TIME_LIVE_PROVENANCE_cold.json",
    "PREP_TIME_LIVE_PROVENANCE_a11y.json",
    "PREP_AFTER_ACCEPT.json","PREP_AFTER_COLD.json","PREP_COLD_COMPARE.json",
  ]:
    p=OUT/name
    if p.exists():
      z.write(p, arcname=f"provenance/{name}")
  report=Path("$ROOT/audit/phase-5-ui/PREP_TIME_LIVE_REPORT.md")
  if report.exists():
    z.write(report, arcname="PREP_TIME_LIVE_REPORT.md")
  http=Path("$HTTP/PREP_TIME_HTTP_EVIDENCE.json")
  if http.exists():
    z.write(http, arcname="http/PREP_TIME_HTTP_EVIDENCE.json")
print("ZIP", zip_path, "bytes", zip_path.stat().st_size)
print(json.dumps({
  "acceptExit": int("$ACCEPT_EXIT"),
  "coldExit": int("$COLD_EXIT"),
  "a11yExit": int("$A11Y_EXIT"),
  "at": datetime.now(timezone.utc).isoformat(),
}))
PY

echo "DONE accept=$ACCEPT_EXIT cold=$COLD_EXIT a11y=$A11Y_EXIT"
exit 0
