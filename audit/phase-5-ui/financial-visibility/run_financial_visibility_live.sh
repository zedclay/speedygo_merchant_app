#!/usr/bin/env bash
# Host orchestrator for the Merchant financial-visibility live run.
# Usage: run_financial_visibility_live.sh <simulator-udid> <shot-prefix> <device-label> <order-id>
# Screenshots: simctl captures of the real simulator, triggered by the test.
set -euo pipefail

UDID="$1"
PREFIX="$2"
DEVICE_LABEL="$3"
ORDER_ID="$4"
ROOT=/Users/mac/Downloads/speedygo_project/apps/merchant_app
OUT="$ROOT/audit/phase-5-ui/financial-visibility/live"
SHOT=/tmp/finvis_live_shot.txt
OTP_FILE=/Users/mac/.speedygo/dev/otp-last

mkdir -p "$OUT"
: > "$SHOT"

watch_shots() {
  local last=""
  while true; do
    tag=$(tail -1 "$SHOT" 2>/dev/null | tr -d '\n' || true)
    if [[ -n "$tag" && "$tag" != "$last" ]]; then
      xcrun simctl io "$UDID" screenshot "$OUT/${tag}.png" >/dev/null 2>&1 || true
      echo "SHOT $tag $(stat -f%z "$OUT/${tag}.png" 2>/dev/null || echo 0)"
      last="$tag"
      [[ "$tag" == "${PREFIX}_99_done" ]] && break
    fi
    sleep 0.3
  done
}

watch_shots > "/tmp/finvis_live_shots_${PREFIX}.log" 2>&1 &
WATCH=$!

cd "$ROOT"
set +e
flutter test integration_test/financial_visibility_live_test.dart \
  -d "$UDID" \
  --dart-define=FINVIS_ORDER_ID="$ORDER_ID" \
  --dart-define=FINVIS_OTP_FILE="$OTP_FILE" \
  --dart-define=FINVIS_SHOT_PREFIX="$PREFIX" \
  --dart-define=FINVIS_DEVICE="$DEVICE_LABEL" \
  2>&1 | tee "/tmp/finvis_live_flutter_${PREFIX}.log"
RC=${PIPESTATUS[0]}
set -e

sleep 2
kill "$WATCH" 2>/dev/null || true
wait "$WATCH" 2>/dev/null || true
cat "/tmp/finvis_live_shots_${PREFIX}.log"
echo "FINVIS_LIVE prefix=$PREFIX exit=$RC"
exit "$RC"
