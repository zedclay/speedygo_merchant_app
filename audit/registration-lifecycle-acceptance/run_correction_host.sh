#!/usr/bin/env bash
# Host: Merchant correction/resubmit UI after Admin reject; then Admin approve.
# SE only. Does not touch Finjan / 17 Pro. Does not recreate merchant.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
AUDIT="$ROOT/audit/registration-lifecycle-acceptance"
SE_UDID="${SE_UDID:-E342AC62-65EB-4786-87D1-292AF132E1CF}"
API="${API_BASE_URL:-http://127.0.0.1:3000/api/v1}"
PHONE_LOCAL="${ACCEPTANCE_PHONE_LOCAL:-559907701}"
MERCHANT_ID="${ACCEPTANCE_MERCHANT_ID:-01a0b4e7-83a0-7742-8ac0-03fcb5e9b056}"
ADMIN_PHONE="${ACCEPTANCE_ADMIN_PHONE:-0550000099}"
OTP_FILE="${HOME}/.speedygo/dev/otp-last"
SHOT_MARKER=/tmp/lifecycle_host_shot.txt
READY_MARKER=/tmp/lifecycle_ready_for_approve.txt
APPROVE_MARKER=/tmp/lifecycle_approve_done.txt

mkdir -p "$AUDIT/screenshots"
: > "$AUDIT/host_correction_log.txt"
: > "$SHOT_MARKER"
: > "$READY_MARKER"
: > "$APPROVE_MARKER"

log() { echo "[$(date -u +%H:%M:%S)] $*" | tee -a "$AUDIT/host_correction_log.txt"; }

admin_token() {
  curl -s -X POST "$API/auth/otp/request" -H 'Content-Type: application/json' \
    -d "{\"channel\":\"PHONE\",\"identifier\":\"$ADMIN_PHONE\",\"purpose\":\"AUTHENTICATE\"}" >/dev/null
  sleep 1
  local otp
  otp=$(tr -d ' \n\r' < "$OTP_FILE")
  local body
  body=$(curl -s -X POST "$API/auth/otp/verify" -H 'Content-Type: application/json' \
    -d "{\"channel\":\"PHONE\",\"identifier\":\"$ADMIN_PHONE\",\"purpose\":\"AUTHENTICATE\",\"code\":\"$otp\",\"platform\":\"ios\",\"appVersion\":\"1.0.0\"}")
  python3 -c "import json,sys; print(json.loads(sys.argv[1])['accessToken'])" "$body"
}

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
      [[ "$tag" == "cold-relaunch-home" ]] && break
    fi
    sleep 0.4
  done
}

watch_approve() {
  while true; do
    if [[ "$(tr -d ' \n\r' <"$READY_MARKER" 2>/dev/null || true)" == "1" ]]; then
      log "approve_start merchant=$MERCHANT_ID (API-only)"
      # Clear IP throttle lightly
      redis-cli -p 6381 --scan --pattern 'auth:otp:ip:*' 2>/dev/null | while read -r k; do redis-cli -p 6381 DEL "$k" >/dev/null; done || true
      local token
      token=$(admin_token)
      local me
      me=$(curl -s "$API/admin/me" -H "Authorization: Bearer $token")
      python3 -c "import json,sys; d=json.loads(sys.argv[1]); assert 'merchants.verify' in d.get('permissions',[]), d" "$me"
      local appr
      appr=$(curl -s -w "\n%{http_code}" -X POST \
        "$API/admin/merchants/$MERCHANT_ID/verification/approve" \
        -H "Authorization: Bearer $token" \
        -H 'Content-Type: application/json' -d '{}')
      local code="${appr##*$'\n'}"
      log "approve_http=$code"
      echo "$code" > "$AUDIT/admin_approve_http.txt"
      if [[ "$code" != "200" && "$code" != "201" ]]; then
        log "approve_failed body_redacted"
        echo "0" > "$APPROVE_MARKER"
        return 1
      fi
      echo "1" > "$APPROVE_MARKER"
      log "approve_done"
      return 0
    fi
    sleep 0.5
  done
}

main() {
  log "env db=speedygo_dev phone=$PHONE_LOCAL merchant=$MERCHANT_ID se=$SE_UDID"
  curl -sf "http://127.0.0.1:3000/health" >/dev/null
  xcrun simctl boot "$SE_UDID" 2>/dev/null || true
  # Fresh signed-out session on SE only (Finjan / 17 Pro untouched).
  xcrun simctl uninstall "$SE_UDID" com.speedygo.speedygoMerchantApp 2>/dev/null || true
  xcrun simctl keychain "$SE_UDID" reset 2>/dev/null || true
  log "se_session_reset_done"

  # Confirm fixture still REJECTED before UI
  status=$(PGPASSWORD=speedygo psql -h 127.0.0.1 -p 5433 -U speedygo -d speedygo_dev -t -A \
    -c "SELECT status FROM merchants WHERE id='$MERCHANT_ID';")
  log "fixture_status_before_ui=$status"
  [[ "$status" == "REJECTED" ]] || { log "BLOCKED: expected REJECTED"; exit 2; }

  watch_shots &
  WATCH_SHOT=$!
  watch_approve &
  WATCH_APPR=$!

  cd "$ROOT"
  set +e
  flutter test integration_test/registration_correction_acceptance_test.dart \
    -d "$SE_UDID" \
    --dart-define=API_BASE_URL="$API" \
    --dart-define=ACCEPTANCE_EVIDENCE_PICKER=true \
    --dart-define=ACCEPTANCE_PHONE="$PHONE_LOCAL" \
    --dart-define=ACCEPTANCE_APPROVE_MARKER="$APPROVE_MARKER" \
    2>&1 | tee "$AUDIT/flutter_correction_test.log"
  FT_EXIT=${PIPESTATUS[0]}
  set -e
  log "flutter_test_exit=$FT_EXIT"
  kill "$WATCH_SHOT" "$WATCH_APPR" 2>/dev/null || true
  wait "$WATCH_SHOT" 2>/dev/null || true
  wait "$WATCH_APPR" 2>/dev/null || true

  PGPASSWORD=speedygo psql -h 127.0.0.1 -p 5433 -U speedygo -d speedygo_dev -c \
    "SELECT id, status, verified_at IS NOT NULL AS verified FROM merchants WHERE id IN ('$MERCHANT_ID','01a0ad2a-29eb-7959-b23c-d21f1e1c0915');" \
    | tee -a "$AUDIT/host_correction_log.txt"

  exit "$FT_EXIT"
}

main "$@"
