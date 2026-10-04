#!/usr/bin/env bash
# Host orchestrator for the tracked fixture writes (list-card accept / reject,
# branch-name persistence). Same watcher and content-size handling as
# run_parity_live.sh.
# Usage: run_parity_fixture_live.sh <simulator-udid> <prefix> <content-size> <accept-order-id> <reject-order-id>
set -euo pipefail

UDID="$1"
PREFIX="$2"
SIZE="$3"
ACCEPT_ID="$4"
REJECT_ID="$5"
BUNDLE=com.speedygo.speedygoMerchantApp
ROOT=/Users/mac/Downloads/speedygo_project/apps/merchant_app
OUT="$ROOT/audit/parity/live"
SHOT=/tmp/parity_live_shot.txt

. "$OUT/disk_preflight.sh"
require_free_disk "fixture:$PREFIX" || exit $?
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
  printf 'bundleId=%s\nrunningProcesses=%s\ncontentSize=%s\nudid=%s\nat=%s\n' \
    "$id" "$running" "$SIZE" "$UDID" "$(date -u +%FT%TZ)" > "$OUT/BUNDLE_FIXTURE_${PREFIX}.txt"
  [[ "$id" == "$BUNDLE" && "$running" -ge 1 ]]
}

watch_shots() {
  local last="" verified=0
  while true; do
    tag=$(tail -1 "$SHOT" 2>/dev/null | tr -d '\n' || true)
    if [[ -n "$tag" && "$tag" != "$last" ]]; then
      if [[ $verified -eq 0 ]]; then
        if verify_bundle; then verified=1; echo "BUNDLE_OK"; else echo "BUNDLE_MISMATCH"; break; fi
      fi
      [[ "$tag" == "${PREFIX}_99_done" ]] && break
      xcrun simctl io "$UDID" screenshot "$OUT/${tag}.png" >/dev/null 2>&1 || true
      echo "SHOT $tag $(stat -f%z "$OUT/${tag}.png" 2>/dev/null || echo 0)"
      last="$tag"
    fi
    sleep 0.3
  done
}

watch_shots > "/tmp/parity_fixture_shots_${PREFIX}.log" 2>&1 &
WATCH=$!

cd "$ROOT"
set +e
flutter test integration_test/parity_fixture_writes_live_test.dart \
  -d "$UDID" \
  --dart-define=PARITY_PREFIX="$PREFIX" \
  --dart-define=FX_ACCEPT_ORDER_ID="$ACCEPT_ID" \
  --dart-define=FX_REJECT_ORDER_ID="$REJECT_ID" \
  > "/tmp/parity_fixture_flutter_${PREFIX}.log" 2>&1
RC=$?
set -e

sleep 2
kill "$WATCH" 2>/dev/null || true
wait "$WATCH" 2>/dev/null || true
cat "/tmp/parity_fixture_shots_${PREFIX}.log"
echo "PARITY_FIXTURE prefix=$PREFIX exit=$RC"
exit "$RC"
