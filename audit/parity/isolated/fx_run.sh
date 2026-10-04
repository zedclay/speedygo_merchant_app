#!/usr/bin/env bash
# One live run of the isolated Merchant write test at one content size.
#   - disk preflight; the environment from fx_start.sh must be up (marker,
#     API PID on 3100, Redis index 9);
#   - simulator: only the iPhone 16e 8DB9007A-…; the Finjan iPhone 17 Pro is
#     refused; boots it only if no other simulator is booted, and records that
#     so fx_cleanup.sh shuts down only what this run booted;
#   - parity_isolated_fx_live_test only: two COD orders placed through the
#     real checkout on the isolated API;
#   - flutter test integration_test/<test>.dart with
#     API_BASE_URL=http://127.0.0.1:3100/api/v1 and the isolated OTP file;
#   - host screenshots into evidence/<run>/screens, isolation snapshot after.
# Usage: fx_run.sh <simulator-udid> <prefix> <content-size> [test]
#   content-size: large (1.0) or extra-extra-extra-large (1.35)
#   test: parity_isolated_fx_live_test (default), contract_batch_fx_live_test
#         or polish_fx_live_test
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/fx_common.sh"
. "$FX_APP/audit/parity/live/disk_preflight.sh"

UDID="$1"
PREFIX="$2"
SIZE="$3"
ALLOWED_UDID=8DB9007A-B816-4EC5-86ED-C627AC60F2C5
FINJAN_UDID=4A1C3481
BUNDLE=com.speedygo.speedygoMerchantApp
SHOT=/tmp/parity_fx_isolated_shot.txt

[[ "$UDID" != "$FINJAN_UDID"* ]] || fx_die "the Finjan simulator is never used"
[[ "$UDID" == "$ALLOWED_UDID" ]] || fx_die "only the iPhone 16e $ALLOWED_UDID is allowed"
[[ "$PREFIX" =~ ^[a-z0-9_]+$ ]] || fx_die "prefix must be [a-z0-9_]+"
case "$SIZE" in large|extra-extra-extra-large) ;; *) fx_die "unsupported content size $SIZE" ;; esac
TEST="${4:-parity_isolated_fx_live_test}"
case "$TEST" in
  parity_isolated_fx_live_test|contract_batch_fx_live_test|polish_fx_live_test) ;;
  *) fx_die "integration test $TEST is not allowlisted" ;;
esac

require_free_disk "fx-run:$PREFIX" || exit $?
fx_load_targets
RUN_ID=$(cat "$FX_HOME/run_id" 2>/dev/null) || fx_die "no environment; run fx_start.sh first"
[[ "$(fx_db_marker)" == "speedygo-parity-fx disposable run=$RUN_ID" ]] || fx_die "database marker does not match run $RUN_ID"
API_PID=$(fx_api_pid)
fx_is_fx_api "$API_PID" || fx_die "isolated API is not running on $FX_API_PORT"
curl -sf "http://127.0.0.1:$FX_API_PORT/health" >/dev/null || fx_die "isolated API not healthy"
EVIDENCE="$FX_EVIDENCE_ROOT/$RUN_ID"
SCREENS="$EVIDENCE/screens"
mkdir -p "$SCREENS"
RUN_START="$(date -u +%FT%TZ)"

STATE=$(xcrun simctl list devices -j | python3 -c '
import json, sys
udid = sys.argv[1]
booted, target = [], "missing"
for devs in json.load(sys.stdin)["devices"].values():
    for d in devs:
        if d["state"] == "Booted":
            booted.append(d["udid"])
        if d["udid"] == udid:
            target = d["state"]
others = [b for b in booted if b != udid]
print(target, len(others))' "$UDID")
read -r TARGET_STATE OTHERS <<<"$STATE"
if [[ "$TARGET_STATE" != "Booted" ]]; then
  [[ "$OTHERS" == "0" ]] || fx_die "another simulator is booted; one simulator at a time (nothing shut down)"
  xcrun simctl boot "$UDID"
  echo "$UDID" > "$FX_HOME/booted_simulator"
  sleep 8
fi

ACCEPT_ID=""
REJECT_ID=""
if [[ "$TEST" == parity_isolated_fx_live_test ]]; then
  ORDERS="$EVIDENCE/incoming_orders_${PREFIX}.json"
  python3 "$HERE/fx_create_incoming.py" "$ORDERS" 2
  read -r ACCEPT_ID REJECT_ID < <(python3 -c '
import json, sys
o = json.load(open(sys.argv[1]))["orders"]
print(o[0]["id"], o[1]["id"])' "$ORDERS")
fi

: > "$SHOT"
PREVIOUS_SIZE=$(xcrun simctl ui "$UDID" content_size)
xcrun simctl ui "$UDID" content_size "$SIZE"
restore_size() { xcrun simctl ui "$UDID" content_size "$PREVIOUS_SIZE" || true; }
trap restore_size EXIT

verify_bundle() {
  local app id running
  app=$(xcrun simctl get_app_container "$UDID" "$BUNDLE" app 2>/dev/null || true)
  id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Info.plist" 2>/dev/null || echo missing)
  running=$(xcrun simctl spawn "$UDID" launchctl list 2>/dev/null | grep -c "UIKitApplication:$BUNDLE" || true)
  printf 'bundleId=%s\nrunningProcesses=%s\ncontentSize=%s\nudid=%s\napiBase=%s\nat=%s\n' \
    "$id" "$running" "$SIZE" "$UDID" "$FX_API_BASE" "$(date -u +%FT%TZ)" > "$EVIDENCE/BUNDLE_${PREFIX}.txt"
  [[ "$id" == "$BUNDLE" && "$running" -ge 1 ]]
}

watch_shots() {
  local last="" verified=0 tag
  while true; do
    tag=$(tail -1 "$SHOT" 2>/dev/null | tr -d '\n' || true)
    if [[ -n "$tag" && "$tag" != "$last" ]]; then
      if [[ $verified -eq 0 ]]; then
        if verify_bundle; then verified=1; echo "BUNDLE_OK"; else echo "BUNDLE_MISMATCH"; break; fi
      fi
      [[ "$tag" == "${PREFIX}_99_done" ]] && break
      xcrun simctl io "$UDID" screenshot "$SCREENS/${tag}.png" >/dev/null 2>&1 || true
      echo "SHOT $tag $(stat -f%z "$SCREENS/${tag}.png" 2>/dev/null || echo 0)"
      last="$tag"
    fi
    sleep 0.3
  done
}

watch_shots > "$EVIDENCE/shots_${PREFIX}.log" 2>&1 &
WATCH=$!
echo "$WATCH" >> "$FX_HOME/run_pids"

cd "$FX_APP"
set +e
flutter test "integration_test/$TEST.dart" \
  -d "$UDID" \
  --dart-define=API_BASE_URL="$FX_API_BASE" \
  --dart-define=FX_OTP_FILE="$FX_OTP_FILE" \
  --dart-define=FX_EVIDENCE_DIR="$EVIDENCE" \
  --dart-define=PARITY_PREFIX="$PREFIX" \
  --dart-define=FX_ACCEPT_ORDER_ID="$ACCEPT_ID" \
  --dart-define=FX_REJECT_ORDER_ID="$REJECT_ID" \
  > "$EVIDENCE/flutter_${PREFIX}.log" 2>&1 &
FLUTTER=$!
echo "$FLUTTER" >> "$FX_HOME/run_pids"
wait "$FLUTTER"
RC=$?
set -e

sleep 2
kill "$WATCH" 2>/dev/null || true
wait "$WATCH" 2>/dev/null || true
xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
sed -E 's/[0-9]{6}/<masked>/g' -i '' "$EVIDENCE/flutter_${PREFIX}.log" 2>/dev/null || true

bash "$HERE/fx_snapshot.sh" "$EVIDENCE/isolation_after_${PREFIX}.json" "$(cat "$EVIDENCE/started_at")" >/dev/null
cat "$EVIDENCE/shots_${PREFIX}.log"
echo "FX_RUN test=$TEST prefix=$PREFIX size=$SIZE accept=$ACCEPT_ID reject=$REJECT_ID exit=$RC started=$RUN_START"
exit "$RC"
