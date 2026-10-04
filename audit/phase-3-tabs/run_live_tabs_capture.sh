#!/usr/bin/env bash
# Live Finjan five-tab screenshots on Pro simulator (preserves session unless reset).
set -euo pipefail

AUDIT="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$AUDIT/../.." && pwd)"
UDID="${UDID:-4A1C3481-8B8E-48BD-983D-03896884EF09}"
API="${API_BASE_URL:-http://127.0.0.1:3000/api/v1}"
PHONE="${PHASE3_PHONE:-559907701}"
SHOT_MARKER=/tmp/phase3_host_shot.txt
LIVE_DIR="$AUDIT/live"
LOG="$AUDIT/live_capture_log.txt"
: > "$LOG"
: > "$SHOT_MARKER"
mkdir -p "$LIVE_DIR"

log() { echo "[$(date -u +%H:%M:%S)] $*" | tee -a "$LOG"; }

curl -sf "http://127.0.0.1:3000/health" >/dev/null
log "api_ok"

xcrun simctl boot "$UDID" 2>/dev/null || true

watch_shots() {
  local last=""
  while true; do
    local tag
    tag=$(tail -1 "$SHOT_MARKER" 2>/dev/null | tr -d '\n' || true)
    if [[ -n "$tag" && "$tag" != "$last" ]]; then
      sleep 1.5
      xcrun simctl io "$UDID" screenshot "$LIVE_DIR/$tag.png" || true
      log "shot=$tag"
      last="$tag"
      [[ "$tag" == "live-profile-pro" ]] && break
    fi
    sleep 0.4
  done
}

watch_shots &
WATCH=$!

cd "$ROOT"
# Stop any stray flutter run holding the device
pkill -f "flutter_tools.snapshot run -d $UDID" 2>/dev/null || true
sleep 2

set +e
flutter test integration_test/phase3_tabs_live_capture_test.dart \
  -d "$UDID" \
  --dart-define=API_BASE_URL="$API" \
  --dart-define=PHASE3_PHONE="$PHONE" \
  2>&1 | tee "$AUDIT/flutter_live_capture.log"
FT_EXIT=${PIPESTATUS[0]}
set -e
log "flutter_test_exit=$FT_EXIT"
kill "$WATCH" 2>/dev/null || true
wait "$WATCH" 2>/dev/null || true
exit "$FT_EXIT"
