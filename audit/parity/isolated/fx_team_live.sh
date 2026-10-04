#!/usr/bin/env bash
# Isolated live captures for Merchant Team Management (row 64).
# Requires fx_start.sh (+ preferably fx_team_e2e.sh).
# Never touches speedygo_dev or :3000.
#
# Usage: fx_team_live.sh <simulator-udid> <prefix> <content-size>
#   content-size: large (1.0) or extra-extra-extra-large (1.35)
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
OWNER_PHONE=550009101
STAFF_PHONE=550009103

[[ "$UDID" != "$FINJAN_UDID"* ]] || fx_die "the Finjan simulator is never used"
[[ "$UDID" == "$ALLOWED_UDID" ]] || fx_die "only the iPhone 16e $ALLOWED_UDID is allowed"
[[ "$PREFIX" =~ ^[a-z0-9_]+$ ]] || fx_die "prefix must be [a-z0-9_]+"
case "$SIZE" in large|extra-extra-extra-large) ;; *) fx_die "unsupported content size $SIZE" ;; esac

require_free_disk "fx-team:$PREFIX" || exit $?
fx_load_targets
RUN_ID=$(cat "$FX_HOME/run_id" 2>/dev/null) || fx_die "no environment; run fx_start.sh first"
[[ "$(fx_db_marker)" == "speedygo-parity-fx disposable run=$RUN_ID" ]] || fx_die "database marker mismatch"
API_PID=$(fx_api_pid)
fx_is_fx_api "$API_PID" || fx_die "isolated API is not running on $FX_API_PORT"
curl -sf "http://127.0.0.1:$FX_API_PORT/health" >/dev/null || fx_die "isolated API not healthy"

EVIDENCE="$FX_EVIDENCE_ROOT/$RUN_ID/team_visual"
SCREENS="$EVIDENCE/screens"
mkdir -p "$SCREENS" "$EVIDENCE"

clear_otp_keys() {
  redis-cli -p 6381 -n 9 --scan --pattern 'auth:parityfx:*' 2>/dev/null \
    | while read -r k; do redis-cli -p 6381 -n 9 DEL "$k" >/dev/null; done || true
}

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
  [[ "$OTHERS" == "0" ]] || fx_die "another simulator is booted; one simulator at a time"
  xcrun simctl boot "$UDID"
  echo "$UDID" > "$FX_HOME/booted_simulator"
  sleep 8
fi

verify_bundle() {
  local app id running
  app=$(xcrun simctl get_app_container "$UDID" "$BUNDLE" app 2>/dev/null || true)
  id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Info.plist" 2>/dev/null || echo missing)
  running=$(xcrun simctl spawn "$UDID" launchctl list 2>/dev/null | grep -c "UIKitApplication:$BUNDLE" || true)
  printf 'bundleId=%s\nrunningProcesses=%s\ncontentSize=%s\nudid=%s\napiBase=%s\nat=%s\n' \
    "$id" "$running" "$SIZE" "$UDID" "$FX_API_BASE" "$(date -u +%FT%TZ)" \
    > "$EVIDENCE/BUNDLE_${PREFIX}.txt"
  [[ "$id" == "$BUNDLE" && "$running" -ge 1 ]]
}

PREVIOUS_SIZE=$(xcrun simctl ui "$UDID" content_size)
xcrun simctl ui "$UDID" content_size "$SIZE"
restore_size() { xcrun simctl ui "$UDID" content_size "$PREVIOUS_SIZE" || true; }
trap restore_size EXIT

clear_otp_keys
: > "$SHOT"

(
  last="" verified=0
  while true; do
    tag=$(tail -1 "$SHOT" 2>/dev/null | tr -d '\n' || true)
    if [[ -n "$tag" && "$tag" != "$last" ]]; then
      if [[ $verified -eq 0 ]]; then
        if verify_bundle; then verified=1; echo BUNDLE_OK; else echo BUNDLE_MISMATCH; break; fi
      fi
      [[ "$tag" == "${PREFIX}_99_done" ]] && break
      if [[ "$tag" == "${PREFIX}_clear_otp" ]]; then
        clear_otp_keys
        echo "OTP_CLEARED $tag"
        last="$tag"
        continue
      fi
      xcrun simctl io "$UDID" screenshot "$SCREENS/${tag}.png" >/dev/null 2>&1 || true
      echo "SHOT $tag $(stat -f%z "$SCREENS/${tag}.png" 2>/dev/null || echo 0)"
      last="$tag"
    fi
    sleep 0.3
  done
) > "$EVIDENCE/shots_${PREFIX}.log" 2>&1 &
WATCH=$!
echo "$WATCH" >> "$FX_HOME/run_pids"

set +e
(cd "$FX_APP" && flutter test integration_test/parity_team_fx_live_capture_test.dart \
  -d "$UDID" \
  --dart-define=API_BASE_URL="$FX_API_BASE" \
  --dart-define=FX_OTP_FILE="$FX_OTP_FILE" \
  --dart-define=FX_EVIDENCE_DIR="$EVIDENCE" \
  --dart-define=PARITY_PREFIX="$PREFIX" \
  --dart-define=FX_OWNER_PHONE="$OWNER_PHONE" \
  --dart-define=FX_STAFF_PHONE="$STAFF_PHONE" \
  > "$EVIDENCE/flutter_${PREFIX}.log" 2>&1)
RC=$?
set -e
sleep 2
kill "$WATCH" 2>/dev/null || true
wait "$WATCH" 2>/dev/null || true
xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
sed -E 's/[0-9]{6}/<masked>/g' -i '' "$EVIDENCE/flutter_${PREFIX}.log" 2>/dev/null || true
# Mask accept-code-like hex blobs if any leaked
sed -E 's/[0-9a-f]{64}/<code>/g' -i '' "$EVIDENCE/flutter_${PREFIX}.log" 2>/dev/null || true
cat "$EVIDENCE/shots_${PREFIX}.log"
echo "FX_TEAM_LIVE prefix=$PREFIX size=$SIZE exit=$RC"

LIVE="$FX_APP/audit/parity/live"
mkdir -p "$LIVE"
for tag in settings_owner team_top team_end team_invite_sheet team_cold \
           settings_staff team_staff_denied; do
  src="$SCREENS/${PREFIX}_${tag}.png"
  [[ -f "$src" ]] && cp "$src" "$LIVE/${PREFIX}_${tag}.png"
done

bash "$HERE/fx_snapshot.sh" "$EVIDENCE/isolation_after_${PREFIX}.json" "$(cat "$FX_EVIDENCE_ROOT/$RUN_ID/started_at")" >/dev/null
exit "$RC"
