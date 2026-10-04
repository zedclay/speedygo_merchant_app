#!/usr/bin/env bash
# Host orchestrator for the live D-G2 approval flow on one isolated fixture.
# Usage: run_parity_b7_approval_live.sh <simulator-udid> <prefix> <content-size> <phone-local-9-digits> <pending|rejected>
#
# 1. Refuses unless speedygo_dev and the fixture phone has no account yet.
# 2. Register phase through the Merchant UI (no screenshots) → pending.
# 3. Records the created account / merchant / branch IDs (FIXTURE_IDS_<prefix>.json).
# 4. For the rejected path, rejects the dossier through the dev admin API.
# 5. Approval phase: the test observes the dossier (resubmitting a rejected
#    one), signals; the host approves through the admin API and signals back;
#    the test checks the approval screen, cold restart, acknowledgement and
#    routing, then revokes its session.
# Each admin session is revoked right after its call. OTP codes and tokens
# stay in shell variables; they are never printed or saved.
set -euo pipefail

UDID="$1"
PREFIX="$2"
SIZE="$3"
PHONE_LOCAL="$4"
START_STATE="$5"
PHONE_E164="+213$PHONE_LOCAL"
BUNDLE=com.speedygo.speedygoMerchantApp
ROOT=/Users/mac/Downloads/speedygo_project/apps/merchant_app
BACKEND=/Users/mac/Downloads/speedygo_project/apps/backend
OUT="$ROOT/audit/parity/live"
SHOT=/tmp/parity_live_shot.txt
SIGNAL=/tmp/parity_b7_signal.txt
API=http://127.0.0.1:3000/api/v1
ADMIN_PHONE=0550000099
OTP_FILE="$HOME/.speedygo/dev/otp-last"

[[ "$START_STATE" == "pending" || "$START_STATE" == "rejected" ]] || { echo "start state must be pending or rejected"; exit 1; }
. "$OUT/disk_preflight.sh"
require_free_disk "b7-approval:$PREFIX" || exit $?
mkdir -p "$OUT"

db() {
  (cd "$BACKEND" && set -a && . ./.env && set +a && psql "${DATABASE_URL%%\?*}" -X -q -A -t -v ON_ERROR_STOP=1 "$@")
}

[[ "$(db -c 'select current_database()')" == "speedygo_dev" ]] || { echo "not speedygo_dev"; exit 1; }
[[ "$(db -c "select count(*) from accounts where phone = '$PHONE_E164'")" == "0" ]] \
  || { echo "fixture phone already has an account; refusing"; exit 1; }

PREVIOUS_SIZE=$(xcrun simctl ui "$UDID" content_size)
xcrun simctl ui "$UDID" content_size "$SIZE"
restore_size() { xcrun simctl ui "$UDID" content_size "$PREVIOUS_SIZE" || true; }
trap restore_size EXIT

verify_bundle() {
  local app id running
  app=$(xcrun simctl get_app_container "$UDID" "$BUNDLE" app 2>/dev/null || true)
  id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Info.plist" 2>/dev/null || echo missing)
  running=$(xcrun simctl spawn "$UDID" launchctl list 2>/dev/null | grep -c "UIKitApplication:$BUNDLE" || true)
  printf 'bundleId=%s\nrunningProcesses=%s\ncontentSize=%s\nudid=%s\nat=%s\n' \
    "$id" "$running" "$SIZE" "$UDID" "$(date -u +%FT%TZ)" > "$OUT/BUNDLE_${PREFIX}_b7_$1.txt"
  [[ "$id" == "$BUNDLE" && "$running" -ge 1 ]]
}

admin_action() {
  local action="$1" merchant_id="$2" before otp body token code
  before=$(stat -f %m "$OTP_FILE" 2>/dev/null || echo 0)
  curl -s -o /dev/null -X POST "$API/auth/otp/request" -H 'Content-Type: application/json' \
    -d "{\"channel\":\"PHONE\",\"identifier\":\"$ADMIN_PHONE\",\"purpose\":\"AUTHENTICATE\"}"
  for _ in $(seq 1 40); do
    [[ "$(stat -f %m "$OTP_FILE" 2>/dev/null || echo 0)" -gt "$before" ]] && break
    sleep 0.25
  done
  otp=$(tr -d ' \n\r' < "$OTP_FILE")
  body=$(curl -s -X POST "$API/auth/otp/verify" -H 'Content-Type: application/json' \
    -d "{\"channel\":\"PHONE\",\"identifier\":\"$ADMIN_PHONE\",\"purpose\":\"AUTHENTICATE\",\"code\":\"$otp\",\"platform\":\"ios\",\"appVersion\":\"1.0.0\"}")
  unset otp
  token=$(python3 -c "import json,sys; print(json.loads(sys.argv[1]).get('accessToken',''))" "$body")
  unset body
  [[ -n "$token" ]] || { echo "admin login failed"; return 1; }
  code=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/admin/merchants/$merchant_id/verification/$action" \
    -H "Authorization: Bearer $token" -H 'Content-Type: application/json' -d '{}')
  echo "admin_${action}_http=$code"
  curl -s -o /dev/null -w 'admin_logout_http=%{http_code}\n' -X POST "$API/auth/logout" \
    -H "Authorization: Bearer $token"
  unset token
  [[ "$code" == 2* ]]
}

run_phase() {
  local phase="$1" only="$2"
  require_free_disk "b7-$phase:$PREFIX" || exit $?
  : > "$SHOT"
  (
    last="" verified=0
    while true; do
      tag=$(tail -1 "$SHOT" 2>/dev/null | tr -d '\n' || true)
      if [[ -n "$tag" && "$tag" != "$last" ]]; then
        if [[ $verified -eq 0 ]]; then
          if verify_bundle "$phase"; then verified=1; echo BUNDLE_OK; else echo BUNDLE_MISMATCH; break; fi
        fi
        [[ "$tag" == "${PREFIX}_99_done" ]] && break
        xcrun simctl io "$UDID" screenshot "$OUT/${tag}.png" >/dev/null 2>&1 || true
        echo "SHOT $tag"
        last="$tag"
      fi
      sleep 0.3
    done
  ) > "/tmp/parity_b7_shots_${PREFIX}_$phase.log" 2>&1 &
  local watch=$!
  (cd "$ROOT" && flutter test integration_test/parity_b7_live_capture_test.dart \
    -d "$UDID" \
    --dart-define=ACCEPTANCE_EVIDENCE_PICKER=true \
    --dart-define=B7_PHONE="$PHONE_LOCAL" \
    --dart-define=B7_PHASE="$phase" \
    --dart-define=B7_ONLY="$only" \
    --dart-define=PARITY_PREFIX="$PREFIX" \
    > "/tmp/parity_b7_flutter_${PREFIX}_$phase.log" 2>&1) &
  FLUTTER_PID=$!
  WATCH_PID=$watch
}

finish_phase() {
  local phase="$1" rc
  set +e
  wait "$FLUTTER_PID"; rc=$?
  set -e
  sleep 2
  kill "$WATCH_PID" 2>/dev/null || true
  wait "$WATCH_PID" 2>/dev/null || true
  cat "/tmp/parity_b7_shots_${PREFIX}_$phase.log"
  echo "PHASE $phase exit=$rc"
  return $rc
}

record_ids() {
  db -c "
    select json_build_object(
      'phone', '$PHONE_E164',
      'accountId', a.id,
      'merchantId', m.id,
      'merchantStatus', m.status,
      'branchIds', (select json_agg(b.id) from merchant_branches b where b.merchant_id = m.id)
    )
    from accounts a
    join merchant_members mm on mm.account_id = a.id
    join merchants m on m.id = mm.merchant_id
    where a.phone = '$PHONE_E164'" > "$OUT/FIXTURE_IDS_${PREFIX}.json"
  cat "$OUT/FIXTURE_IDS_${PREFIX}.json"
}

run_phase register none
finish_phase register
record_ids
MERCHANT_ID=$(python3 -c "import json;print(json.load(open('$OUT/FIXTURE_IDS_${PREFIX}.json'))['merchantId'])")
[[ "$START_STATE" == "rejected" ]] && admin_action reject "$MERCHANT_ID"

: > "$SIGNAL"
run_phase approval ""
APPROVED=0
while kill -0 "$FLUTTER_PID" 2>/dev/null; do
  if [[ $APPROVED -eq 0 && "$(tr -d '\n' < "$SIGNAL" 2>/dev/null)" == "awaiting_approval" ]]; then
    echo "merchant_status_before_approve=$(db -c "select status from merchants where id = '$MERCHANT_ID'")"
    admin_action approve "$MERCHANT_ID"
    echo approved > "$SIGNAL"
    APPROVED=1
  fi
  sleep 0.5
done
finish_phase approval
echo "merchant_status_after=$(db -c "select status from merchants where id = '$MERCHANT_ID'")"
echo "PARITY_B7_APPROVAL_LIVE prefix=$PREFIX start=$START_STATE done"
