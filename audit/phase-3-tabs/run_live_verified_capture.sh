#!/usr/bin/env bash
# Capture five Merchant tabs on Pro; write to live-verified/ with provenance.
set -euo pipefail

AUDIT="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$AUDIT/../.." && pwd)"
UDID="${UDID:-4A1C3481-8B8E-48BD-983D-03896884EF09}"
API="${API_BASE_URL:-http://127.0.0.1:3000/api/v1}"
PHONE="${PHASE3_PHONE:-559907701}"
SHOT_MARKER=/tmp/phase3_host_shot.txt
LIVE_DIR="$AUDIT/live-verified"
LOG="$AUDIT/live_verified_capture_log.txt"
: > "$LOG"
: > "$SHOT_MARKER"
mkdir -p "$LIVE_DIR"

log() { echo "[$(date -u +%H:%M:%S)] $*" | tee -a "$LOG"; }

# Record pre-state: both apps must remain
CUST=$(xcrun simctl get_app_container "$UDID" com.speedygo.speedygoCustomerApp 2>/dev/null || true)
log "customer_container=${CUST:-MISSING}"
MERCH=$(xcrun simctl get_app_container "$UDID" com.speedygo.speedygoMerchantApp 2>/dev/null || true)
log "merchant_container_before=${MERCH:-MISSING}"

curl -sf "http://127.0.0.1:3000/health" >/dev/null
log "api_ok"

xcrun simctl boot "$UDID" 2>/dev/null || true

watch_shots() {
  local last=""
  while true; do
    local tag
    tag=$(tail -1 "$SHOT_MARKER" 2>/dev/null | tr -d '\n' || true)
    if [[ -n "$tag" && "$tag" != "$last" ]]; then
      sleep 1.5
      xcrun simctl io "$UDID" screenshot "$LIVE_DIR/$tag.png" || true
      log "shot=$tag"
      last="$tag"
      [[ "$tag" == "live-profile-pro" ]] && break
    fi
    sleep 0.4
  done
}

watch_shots &
WATCH=$!

cd "$ROOT"
# Do not uninstall either app; flutter test will reinstall Merchant only.
set +e
flutter test integration_test/phase3_tabs_live_capture_test.dart \
  -d "$UDID" \
  --dart-define=API_BASE_URL="$API" \
  --dart-define=PHASE3_PHONE="$PHONE" \
  2>&1 | tee "$AUDIT/flutter_live_verified_capture.log"
FT_EXIT=${PIPESTATUS[0]}
set -e
log "flutter_test_exit=$FT_EXIT"

# Post-state: Customer must still be present
CUST2=$(xcrun simctl get_app_container "$UDID" com.speedygo.speedygoCustomerApp 2>/dev/null || true)
log "customer_container_after=${CUST2:-MISSING}"
MERCH2=$(xcrun simctl get_app_container "$UDID" com.speedygo.speedygoMerchantApp 2>/dev/null || true)
log "merchant_container_after=${MERCH2:-MISSING}"

# Bundle identity of installed Merchant
python3 - <<'PY' | tee -a "$LOG"
import json,subprocess,os
udid=os.environ.get("UDID","4A1C3481-8B8E-48BD-983D-03896884EF09")
raw=subprocess.check_output(["xcrun","simctl","listapps",udid], text=True)
# convert via plutil
import tempfile
p=subprocess.run(["plutil","-convert","json","-o","-","-"], input=raw, text=True, capture_output=True)
d=json.loads(p.stdout)
for k in ("com.speedygo.speedygoMerchantApp","com.speedygo.speedygoCustomerApp"):
  v=d.get(k,{})
  print(f"identity {k} display={v.get('CFBundleDisplayName')} name={v.get('CFBundleName')}")
PY

kill "$WATCH" 2>/dev/null || true
wait "$WATCH" 2>/dev/null || true
exit "$FT_EXIT"
