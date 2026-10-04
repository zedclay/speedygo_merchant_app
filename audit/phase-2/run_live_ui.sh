#!/usr/bin/env bash
# Live Merchant UI order mutations on SE with screenshot watcher.
set -euo pipefail

AUDIT="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$AUDIT/../.." && pwd)"
SE_UDID="${SE_UDID:-E342AC62-65EB-4786-87D1-292AF132E1CF}"
API="${API_BASE_URL:-http://127.0.0.1:3000/api/v1}"
RESULTS="$AUDIT/fixtures/live_api_results.json"
LOG="$AUDIT/fixtures/live_ui_log.txt"
SHOT_MARKER=/tmp/phase2_host_shot.txt
: > "$LOG"
: > "$SHOT_MARKER"
mkdir -p "$AUDIT/screenshots"

log() { echo "[$(date -u +%H:%M:%S)] $*" | tee -a "$LOG"; }

OA=$(python3 -c "import json; print(json.load(open('$RESULTS'))['orderAcceptId'])")
OR=$(python3 -c "import json; print(json.load(open('$RESULTS'))['orderRejectId'])")
log "orders accept=$OA reject=$OR"

curl -sf "http://127.0.0.1:3000/health" >/dev/null
log "api_ok"

# Ensure orders still PENDING (recreate note if already mutated)
docker exec speedygo-redis redis-cli --scan --pattern 'auth:otp:*' | while read -r k; do
  docker exec speedygo-redis redis-cli DEL "$k" >/dev/null
done

xcrun simctl boot "$SE_UDID" 2>/dev/null || true
# Isolated Merchant session on SE only
xcrun simctl uninstall "$SE_UDID" com.speedygo.speedygoMerchantApp 2>/dev/null || true
xcrun simctl keychain "$SE_UDID" reset 2>/dev/null || true
log "se_reset_done"

watch_shots() {
  local last=""
  while true; do
    local tag
    tag=$(tail -1 "$SHOT_MARKER" 2>/dev/null | tr -d '\n' || true)
    if [[ -n "$tag" && "$tag" != "$last" ]]; then
      sleep 2
      xcrun simctl io "$SE_UDID" screenshot "$AUDIT/screenshots/live-$tag.png" || true
      log "shot=$tag"
      last="$tag"
      [[ "$tag" == "rejected" ]] && break
    fi
    sleep 0.4
  done
}

watch_shots &
WATCH=$!

cd "$ROOT"
set +e
flutter test integration_test/phase2_order_ops_test.dart \
  -d "$SE_UDID" \
  --dart-define=API_BASE_URL="$API" \
  --dart-define=PHASE2_PHONE=559907701 \
  --dart-define=PHASE2_ACCEPT_ORDER_ID="$OA" \
  --dart-define=PHASE2_REJECT_ORDER_ID="$OR" \
  2>&1 | tee "$AUDIT/fixtures/flutter_phase2_ui.log"
FT_EXIT=${PIPESTATUS[0]}
set -e
log "flutter_test_exit=$FT_EXIT"
kill "$WATCH" 2>/dev/null || true
wait "$WATCH" 2>/dev/null || true
exit "$FT_EXIT"
