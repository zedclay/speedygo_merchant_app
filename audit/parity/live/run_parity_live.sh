#!/usr/bin/env bash
# Host orchestrator for the Merchant parity live captures (Batches 1–6).
# Usage: run_parity_live.sh <simulator-udid> <prefix> <content-size> <order-id> <product-id> <category-id> [session]
#   content-size: iOS Dynamic Type category, e.g. large (1.0) or
#   extra-extra-extra-large (≈1.35). The previous value is restored at the end.
#   session: dedicated (default; OTP login, revoked at the end) or restored
#   (the session already on the device; preserved, never revoked).
#   PARITY_ONLY (env, optional): comma-separated tags to capture; empty = all.
# Screenshots are simctl captures of the real simulator, triggered by the test.
set -euo pipefail

UDID="$1"
PREFIX="$2"
SIZE="$3"
ORDER_ID="$4"
PRODUCT_ID="$5"
CATEGORY_ID="$6"
SESSION_MODE="${7:-dedicated}"
BUNDLE=com.speedygo.speedygoMerchantApp
ROOT=/Users/mac/Downloads/speedygo_project/apps/merchant_app
OUT="$ROOT/audit/parity/live"
SHOT=/tmp/parity_live_shot.txt

. "$OUT/disk_preflight.sh"
require_free_disk "live:$PREFIX" || exit $?

mkdir -p "$OUT"
: > "$SHOT"

PREVIOUS_SIZE=$(xcrun simctl ui "$UDID" content_size)
xcrun simctl ui "$UDID" content_size "$SIZE"
restore_size() { xcrun simctl ui "$UDID" content_size "$PREVIOUS_SIZE" || true; }
trap restore_size EXIT

verify_bundle() {
  local app plist id name running
  app=$(xcrun simctl get_app_container "$UDID" "$BUNDLE" app 2>/dev/null || true)
  plist="$app/Info.plist"
  id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$plist" 2>/dev/null || echo missing)
  name=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$plist" 2>/dev/null || echo missing)
  running=$(xcrun simctl spawn "$UDID" launchctl list 2>/dev/null | grep -c "UIKitApplication:$BUNDLE" || true)
  printf 'bundleId=%s\ndisplayName=%s\nrunningProcesses=%s\ncontentSize=%s\nudid=%s\nat=%s\n' \
    "$id" "$name" "$running" "$SIZE" "$UDID" "$(date -u +%FT%TZ)" > "$OUT/BUNDLE_${PREFIX}.txt"
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

watch_shots > "/tmp/parity_live_shots_${PREFIX}.log" 2>&1 &
WATCH=$!

cd "$ROOT"
set +e
flutter test integration_test/parity_live_capture_test.dart \
  -d "$UDID" \
  --dart-define=PARITY_PREFIX="$PREFIX" \
  --dart-define=PARITY_ORDER_ID="$ORDER_ID" \
  --dart-define=PARITY_PRODUCT_ID="$PRODUCT_ID" \
  --dart-define=PARITY_CATEGORY_ID="$CATEGORY_ID" \
  --dart-define=PARITY_SESSION="$SESSION_MODE" \
  --dart-define=PARITY_ONLY="${PARITY_ONLY:-}" \
  > "/tmp/parity_live_flutter_${PREFIX}.log" 2>&1
RC=$?
set -e

sleep 2
kill "$WATCH" 2>/dev/null || true
wait "$WATCH" 2>/dev/null || true
cat "/tmp/parity_live_shots_${PREFIX}.log"
echo "PARITY_LIVE prefix=$PREFIX exit=$RC"
exit "$RC"
