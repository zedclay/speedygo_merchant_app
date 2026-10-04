#!/usr/bin/env bash
# Host orchestration for Merchant registration lifecycle acceptance.
# Does NOT reset DB/Redis/volumes. Does NOT touch Finjan.
# Does NOT grant Admin permissions (merchants.verify absent → BLOCKED).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
AUDIT="$ROOT/audit/registration-lifecycle-acceptance"
SE_UDID="${SE_UDID:-E342AC62-65EB-4786-87D1-292AF132E1CF}"
API="${API_BASE_URL:-http://127.0.0.1:3000/api/v1}"
# App PhoneInput.toIdentifier → 0 + 9 local digits
# Fresh synthetic local digits (prior fixtures left labeled TEST FIXTURE).
PHONE_LOCAL="${ACCEPTANCE_PHONE_LOCAL:-559907701}"
PHONE_ID="0${PHONE_LOCAL}"
MERCHANT_NAME='TEST FIXTURE — Lifecycle Acceptance Shop'
OTP_FILE="${HOME}/.speedygo/dev/otp-last"
SHOT_MARKER=/tmp/lifecycle_host_shot.txt

mkdir -p "$AUDIT/screenshots" "$AUDIT/fixtures"
: > "$AUDIT/host_log.txt"
: > "$SHOT_MARKER"

log() { echo "[$(date -u +%H:%M:%S)] $*" | tee -a "$AUDIT/host_log.txt"; }

require_api() {
  curl -sf "http://127.0.0.1:3000/health" >/dev/null
}

request_otp() {
  local body code
  body=$(curl -s -w "\n%{http_code}" -X POST "$API/auth/otp/request" \
    -H 'Content-Type: application/json' \
    -d "{\"channel\":\"PHONE\",\"identifier\":\"$PHONE_ID\",\"purpose\":\"AUTHENTICATE\"}")
  code="${body##*$'\n'}"
  log "otp_request identifier=$PHONE_ID http=$code"
  [[ "$code" == "200" || "$code" == "201" || "$code" == "204" ]] || return 1
  sleep 1
  OTP=$(tr -d ' \n\r' < "$OTP_FILE")
  log "otp_captured_len=${#OTP}"
  [[ ${#OTP} -ge 4 ]]
}

# Attempt admin reject using existing fixture admin phones — expect AUTH_FORBIDDEN
# without merchants.verify (do not seed permissions).
probe_admin_verify() {
  local admin_phone="$1"
  local label="$2"
  log "admin_probe start=$label"
  curl -s -X POST "$API/auth/otp/request" \
    -H 'Content-Type: application/json' \
    -d "{\"channel\":\"PHONE\",\"identifier\":\"$admin_phone\",\"purpose\":\"AUTHENTICATE\"}" >/dev/null || true
  sleep 1
  local admin_otp
  admin_otp=$(tr -d ' \n\r' < "$OTP_FILE")
  local verify
  verify=$(curl -s -w "\n%{http_code}" -X POST "$API/auth/otp/verify" \
    -H 'Content-Type: application/json' \
    -d "{\"channel\":\"PHONE\",\"identifier\":\"$admin_phone\",\"purpose\":\"AUTHENTICATE\",\"code\":\"$admin_otp\",\"platform\":\"ios\",\"appVersion\":\"1.0.0\"}")
  local vcode="${verify##*$'\n'}"
  local vbody="${verify%$'\n'*}"
  log "admin_otp_verify http=$vcode"
  if [[ "$vcode" != "200" && "$vcode" != "201" ]]; then
    echo "BLOCKED admin_login_$label http=$vcode"
    return 0
  fi
  local token
  token=$(python3 - <<PY
import json
print(json.loads('''$vbody''').get('accessToken',''))
PY
)
  local me
  me=$(curl -s -w "\n%{http_code}" "$API/admin/me" -H "Authorization: Bearer $token")
  log "admin_me http=${me##*$'\n'} body_redacted"
  local rej
  rej=$(curl -s -w "\n%{http_code}" -X POST \
    "$API/admin/merchants/00000000-0000-0000-0000-000000000001/verification/reject" \
    -H "Authorization: Bearer $token" \
    -H 'Content-Type: application/json' \
    -d '{}')
  log "admin_reject_probe http=${rej##*$'\n'} (expect 403 without merchants.verify)"
  echo "${rej##*$'\n'}" > "$AUDIT/admin_reject_probe_http.txt"
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
      [[ "$tag" == "pending" ]] && break
    fi
    sleep 0.4
  done
}

main() {
  log "env db=speedygo_dev api=$API phone_id=$PHONE_ID se=$SE_UDID"
  require_api || { log "BLOCKED: API health failed"; exit 2; }
  log "API health OK storage=~/.speedygo/dev/storage"
  xcrun simctl boot "$SE_UDID" 2>/dev/null || true
  xcrun simctl location "$SE_UDID" set 36.7538,3.0588 2>/dev/null || true
  # SE-only: wipe merchant install + keychain so prior SecureStorage session
  # cannot skip phone OTP. Never target Finjan / 17 Pro.
  xcrun simctl uninstall "$SE_UDID" com.speedygo.speedygoMerchantApp 2>/dev/null || true
  xcrun simctl keychain "$SE_UDID" reset 2>/dev/null || true
  log "se_reset_merchant_session attempted (SE uninstall+keychain only)"

  # Admin verify capability probe — skip once we already recorded 403 so we
  # do not burn the shared OTP IP hourly budget before Merchant UI OTP.
  if [[ -f "$AUDIT/admin_reject_probe_http.txt" ]] &&
    [[ "$(tr -d ' \n\r' <"$AUDIT/admin_reject_probe_http.txt")" == "403" ]]; then
    log "admin_probe skipped (cached 403 without merchants.verify)"
  else
    probe_admin_verify "0550000098" "checkout_fixtures_alt" || true
    sleep 8
  fi

  watch_shots &
  WATCH=$!

  cd "$ROOT"
  set +e
  flutter test integration_test/registration_lifecycle_acceptance_test.dart \
    -d "$SE_UDID" \
    --dart-define=API_BASE_URL="$API" \
    --dart-define=ACCEPTANCE_EVIDENCE_PICKER=true \
    --dart-define=ACCEPTANCE_PHONE="$PHONE_LOCAL" \
    --dart-define="ACCEPTANCE_MERCHANT_NAME=$MERCHANT_NAME" \
    2>&1 | tee "$AUDIT/flutter_test.log"
  FT_EXIT=${PIPESTATUS[0]}
  set -e
  log "flutter_test_exit=$FT_EXIT"
  kill "$WATCH" 2>/dev/null || true
  wait "$WATCH" 2>/dev/null || true
  exit "$FT_EXIT"
}

main "$@"
