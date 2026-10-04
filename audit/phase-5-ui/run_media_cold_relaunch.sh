#!/usr/bin/env bash
# Cold-relaunch Merchant media UI proof on iPhone 16e / Dar El Bahja.
# Does not uninstall, does not clear Keychain, does not touch Finjan (17 Pro).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
AUDIT="$(cd "$(dirname "$0")" && pwd)"
OUT="$AUDIT/media-live"
UDID="${UDID:-8DB9007A-B816-4EC5-86ED-C627AC60F2C5}"
BUNDLE=com.speedygo.speedygoMerchantApp
PHASE=/tmp/media_cold_phase.txt
LOG="$OUT/media_cold_relaunch.log"
PID_COUSCOUS=0d00c071-d000-7000-8000-000000030101
MID=0d00c071-d000-7000-8000-000000010001
BID=0d00c071-d000-7000-8000-000000011001
API="${API_BASE_URL:-http://127.0.0.1:3000/api/v1}"

mkdir -p "$OUT"
: > "$LOG"
: > "$PHASE"

log() { echo "[$(date -u +%H:%M:%S)] $*" | tee -a "$LOG"; }

FINJAN=4A1C3481-8B8E-48BD-983D-03896884EF09
log "target_udid=$UDID finjan_udid=$FINJAN (untouched)"

bind_fixture() {
  local product_png="$1"
  local cover_png="$2"
  python3 - <<PY >>"$LOG" 2>&1
import json,sys,hashlib
sys.path.insert(0,"$AUDIT/media-http")
from verify_media_http import login, req, multipart, PHONE
from pathlib import Path
token=login(PHONE)
mid="$MID"; bid="$BID"; pid="$PID_COUSCOUS"
product=Path("$product_png"); cover=Path("$cover_png")
body,ct=multipart(product)
s,_,r=req("POST",f"/merchant/{mid}/branches/{bid}/products/{pid}/image/content",token=token,data=body,headers={"Content-Type":ct})
assert s==200, r
ref=json.loads(r)["uploadReference"]
s,_,r=req("PUT",f"/merchant/{mid}/branches/{bid}/products/{pid}/image",token=token,data={"uploadReference":ref})
assert s==200, r
body,ct=multipart(cover)
s,_,r=req("POST",f"/merchant/{mid}/branches/{bid}/cover/content",token=token,data=body,headers={"Content-Type":ct})
assert s==200, r
ref=json.loads(r)["uploadReference"]
s,_,r=req("PUT",f"/merchant/{mid}/branches/{bid}/cover",token=token,data={"uploadReference":ref})
assert s==200, r
s,_,b=req("GET",f"/merchant/{mid}/branches/{bid}/products/{pid}/image",token=token)
print("product_get", s, len(b), hashlib.sha256(b).hexdigest()[:12])
s,_,b=req("GET",f"/merchant/{mid}/branches/{bid}/cover",token=token)
print("cover_get", s, len(b), hashlib.sha256(b).hexdigest()[:12])
PY
}

bind_fixture "$OUT/fixture_blue.png" "$OUT/cover_green.png"
log "fixture_http_ready blue+green"

watch_phases() {
  local pass="$1"
  local last=""
  while true; do
    local tag
    tag=$(head -1 "$PHASE" 2>/dev/null | tr -d '\n' || true)
    if [[ -n "$tag" && "$tag" != "$last" ]]; then
      log "phase=$tag pass=$pass"
      case "$tag" in
        product-ready)
          sleep 1.2
          xcrun simctl io "$UDID" screenshot "$OUT/media-product-${pass}.png"
          log "shot=media-product-${pass}.png"
          ;;
        cover-ready)
          sleep 1.2
          xcrun simctl io "$UDID" screenshot "$OUT/media-cover-${pass}.png"
          log "shot=media-cover-${pass}.png"
          ;;
        done)
          break
          ;;
      esac
      last="$tag"
    fi
    sleep 0.4
  done
}

wait_done() {
  local seconds="${1:-180}"
  for _ in $(seq 1 "$seconds"); do
    tag=$(head -1 "$PHASE" 2>/dev/null | tr -d '\n' || true)
    [[ "$tag" == "done" ]] && return 0
    sleep 1
  done
  return 1
}

stop_flutter() {
  if [[ -f /tmp/media_cold_flutter.pid ]]; then
    kill "$(cat /tmp/media_cold_flutter.pid)" 2>/dev/null || true
    rm -f /tmp/media_cold_flutter.pid
  fi
  pkill -f "main_media_cold_verify.dart" 2>/dev/null || true
}

run_flutter() {
  local label="$1"
  : > "$PHASE"
  stop_flutter
  cd "$ROOT"
  log "flutter_run_start=$label"
  # --no-resident exits after install+launch when combined poorly; keep resident for phase writes
  flutter run -d "$UDID" \
    -t lib/main_media_cold_verify.dart \
    --dart-define=API_BASE_URL="$API" \
    --dart-define=MEDIA_VERIFY_PRODUCT_ID="$PID_COUSCOUS" \
    --dart-define=MEDIA_VERIFY_OPEN_COVER=true \
    --dart-define=MEDIA_VERIFY_PHASE_FILE="$PHASE" \
    >>"$LOG" 2>&1 &
  echo $! > /tmp/media_cold_flutter.pid
}

# --- Pass 1: reopen on running flutter run ---
run_flutter "pass1-reopen"
watch_phases "reopen" &
WATCH=$!
if ! wait_done 240; then
  log "PASS1_TIMEOUT phase=$(head -1 "$PHASE" 2>/dev/null | tr -d '\n')"
fi
wait "$WATCH" 2>/dev/null || true
log "pass1_final=$(head -1 "$PHASE" 2>/dev/null | tr -d '\n')"

# --- Cold relaunch: terminate app process, leave install + Keychain ---
log "cold_terminate_bundle"
xcrun simctl terminate "$UDID" "$BUNDLE" || true
sleep 2
stop_flutter
sleep 1

: > "$PHASE"
# Relaunch installed binary via flutter run again (same data; no uninstall)
run_flutter "pass2-cold"
watch_phases "cold" &
WATCH2=$!
if ! wait_done 240; then
  log "PASS2_TIMEOUT phase=$(head -1 "$PHASE" 2>/dev/null | tr -d '\n')"
fi
wait "$WATCH2" 2>/dev/null || true
log "pass2_final=$(head -1 "$PHASE" 2>/dev/null | tr -d '\n')"

# --- Replace product with red, cold again ---
bind_fixture "$OUT/fixture_red.png" "$OUT/cover_green.png"
log "fixture_http_ready red+green"

xcrun simctl terminate "$UDID" "$BUNDLE" || true
sleep 2
stop_flutter
sleep 1
: > "$PHASE"
run_flutter "pass3-replace"
watch_phases "replace" &
WATCH3=$!
if ! wait_done 240; then
  log "PASS3_TIMEOUT phase=$(head -1 "$PHASE" 2>/dev/null | tr -d '\n')"
fi
wait "$WATCH3" 2>/dev/null || true
log "pass3_final=$(head -1 "$PHASE" 2>/dev/null | tr -d '\n')"
stop_flutter

python3 - <<PY
import json
from pathlib import Path
from datetime import datetime, timezone
out = Path("$OUT")
required = [
  "media-product-reopen.png", "media-cover-reopen.png",
  "media-product-cold.png", "media-cover-cold.png",
  "media-product-replace.png",
]
shots = {p.name: p.stat().st_size for p in out.glob("media-*.png")}
prov = {
  "ok": all((out / f).exists() and (out / f).stat().st_size > 50_000 for f in required),
  "layer": "flutter_run_cold_relaunch",
  "bundleId": "$BUNDLE",
  "fixture": "Dar El Bahja",
  "phone": "+213550000071",
  "merchantId": "$MID",
  "branchId": "$BID",
  "productId": "$PID_COUSCOUS",
  "simulator": "iPhone 16e",
  "simulatorUdid": "$UDID",
  "finjanUntouched": True,
  "required": {f: (out / f).exists() for f in required},
  "screenshots": shots,
  "at": datetime.now(timezone.utc).isoformat(),
}
(out / "MEDIA_COLD_PROVENANCE.json").write_text(json.dumps(prov, indent=2))
print(json.dumps(prov, indent=2))
PY

log "done"
ls -la "$OUT"/media-product-*.png "$OUT"/media-cover-*.png 2>/dev/null || true
