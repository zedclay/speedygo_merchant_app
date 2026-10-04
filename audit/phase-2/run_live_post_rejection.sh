#!/usr/bin/env bash
# Post-rejection live UI verification on SE (no re-reject, no new orders).
set -euo pipefail

AUDIT="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$AUDIT/../.." && pwd)"
SE_UDID="${SE_UDID:-E342AC62-65EB-4786-87D1-292AF132E1CF}"
API="${API_BASE_URL:-http://127.0.0.1:3000/api/v1}"
RESULTS="$AUDIT/fixtures/live_api_results.json"
LOG="$AUDIT/fixtures/live_post_rejection_log.txt"
SHOT_MARKER=/tmp/phase2_post_reject_shot.txt
: > "$LOG"
: > "$SHOT_MARKER"
mkdir -p "$AUDIT/screenshots"

log() { echo "[$(date -u +%H:%M:%S)] $*" | tee -a "$LOG"; }

OR=$(python3 -c "import json; print(json.load(open('$RESULTS'))['orderRejectId'])")
REASON=$(python3 -c "import json; print(json.load(open('$RESULTS'))['finalStates']['orderRejectReason'])")
log "reject_order=$OR"

clear_otp_redis() {
  docker exec speedygo-redis redis-cli --scan --pattern 'auth:otp:*' | while read -r k; do
    [[ -n "$k" ]] && docker exec speedygo-redis redis-cli DEL "$k" >/dev/null
  done
}

curl -sf "http://127.0.0.1:3000/health" >/dev/null
clear_otp_redis
curl -sf -X POST "$API/auth/otp/request" -H 'Content-Type: application/json' \
  -d '{"channel":"PHONE","identifier":"0559907701","purpose":"AUTHENTICATE"}' >/dev/null
sleep 1.5
OTP=$(tr -d ' \n\r' < "$HOME/.speedygo/dev/otp-last")
MT=$(curl -sf -X POST "$API/auth/otp/verify" -H 'Content-Type: application/json' \
  -d "{\"channel\":\"PHONE\",\"identifier\":\"0559907701\",\"purpose\":\"AUTHENTICATE\",\"code\":\"$OTP\",\"platform\":\"ios\",\"appVersion\":\"1.0.0\"}" \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['accessToken'])")
MID=$(python3 -c "import json; print(json.load(open('$RESULTS'))['merchantId'])")
STATE=$(curl -sf "$API/merchant/$MID/orders/$OR" -H "Authorization: Bearer $MT" \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['status']+'/'+d['fulfillmentStatus']+'|'+(d.get('cancellation') or {}).get('reason',''))")
log "pre_check=$STATE"
echo "$STATE" | grep -q '^CANCELLED/' || { log "BLOCKED: order not cancelled"; exit 3; }

# Clear cooldown/hourly limits so the Merchant UI can request a fresh OTP.
clear_otp_redis
sleep 1
log "otp_cooldown_cleared_for_ui"

xcrun simctl boot "$SE_UDID" 2>/dev/null || true
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
      [[ "$tag" == "list-cancelled-after-back" ]] && break
    fi
    sleep 0.4
  done
}

watch_shots &
WATCH=$!

cd "$ROOT"
set +e
flutter test integration_test/phase2_post_rejection_test.dart \
  -d "$SE_UDID" \
  --dart-define=API_BASE_URL="$API" \
  --dart-define=PHASE2_PHONE=559907701 \
  --dart-define=PHASE2_REJECT_ORDER_ID="$OR" \
  --dart-define="PHASE2_REJECT_REASON=$REASON" \
  2>&1 | tee "$AUDIT/fixtures/flutter_post_rejection.log"
FT_EXIT=${PIPESTATUS[0]}
set -e
log "flutter_test_exit=$FT_EXIT"
kill "$WATCH" 2>/dev/null || true
wait "$WATCH" 2>/dev/null || true
exit "$FT_EXIT"
