#!/usr/bin/env bash
# Host orchestrator for the Merchant reports live smoke.
# Usage: run_reports_live_smoke.sh <simulator-udid> <shot-prefix> <device-label>
# Screenshots: simctl captures of the real simulator, triggered by the test.
set -euo pipefail

UDID="$1"
PREFIX="$2"
DEVICE_LABEL="$3"
ROOT=/Users/mac/Downloads/speedygo_project/apps/merchant_app
OUT="$ROOT/audit/phase-5-ui/reports-live"
SHOT=/tmp/reports_live_shot.txt
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

watch_shots > "/tmp/reports_live_shots_${PREFIX}.log" 2>&1 &
WATCH=$!

cd "$ROOT"
set +e
flutter test integration_test/reports_live_smoke_test.dart \
  -d "$UDID" \
  --dart-define=REPORTS_LIVE_PHONE=550000071 \
  --dart-define=REPORTS_OTP_FILE="$OTP_FILE" \
  --dart-define=REPORTS_SHOT_PREFIX="$PREFIX" \
  --dart-define=REPORTS_DEVICE="$DEVICE_LABEL" \
  2>&1 | tee "/tmp/reports_live_flutter_${PREFIX}.log"
RC=${PIPESTATUS[0]}
set -e

sleep 2
kill "$WATCH" 2>/dev/null || true
wait "$WATCH" 2>/dev/null || true
cat "/tmp/reports_live_shots_${PREFIX}.log"
echo "REPORTS_LIVE_SMOKE prefix=$PREFIX exit=$RC"
exit "$RC"
