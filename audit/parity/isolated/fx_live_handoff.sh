#!/usr/bin/env bash
# Sequential live Merchant→Driver pickup handoff on one existing simulator.
# Requires: fx_start already healthy on :3100 / speedygo_parity_fx / Redis 9.
# Usage: fx_live_handoff.sh [simulator-udid]
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/fx_common.sh"
. "$FX_APP/audit/parity/live/disk_preflight.sh"

ALLOWED_UDID=8DB9007A-B816-4EC5-86ED-C627AC60F2C5
UDID="${1:-$ALLOWED_UDID}"
MERCHANT_BUNDLE=com.speedygo.speedygoMerchantApp
DRIVER_BUNDLE=com.speedygo.speedygoDriverApp
DRIVER_APP="$FX_PROJECT/apps/driver_app"
SHOT=/tmp/parity_fx_isolated_shot.txt
PREFIX=fxlive

[[ "$UDID" == "$ALLOWED_UDID" ]] || fx_die "only the iPhone 16e $ALLOWED_UDID is allowed"
require_free_disk "fx-live-handoff" || exit $?
fx_load_targets
RUN_ID=$(cat "$FX_HOME/run_id" 2>/dev/null) || fx_die "no environment; run fx_start.sh first"
[[ "$(fx_db_marker)" == "speedygo-parity-fx disposable run=$RUN_ID" ]] || fx_die "database marker mismatch"
API_PID=$(fx_api_pid)
fx_is_fx_api "$API_PID" || fx_die "isolated API is not running on $FX_API_PORT"
curl -sf "http://127.0.0.1:$FX_API_PORT/health" >/dev/null || fx_die "isolated API not healthy"

LIVE_ROOT="$FX_APP/audit/parity/captures/merchant_driver_live_2026-10-09"
EVIDENCE="$LIVE_ROOT"
SCREENS="$EVIDENCE/screens"
mkdir -p "$SCREENS" "$EVIDENCE"
META="$EVIDENCE/fixture_meta.json"
MANIFEST="$EVIDENCE/MANIFEST.json"
SECRETS="$HOME/.speedygo/parity_fx/live_handoff/secrets.json"

clear_otp_keys() {
  redis-cli -p 6381 -n 9 --scan --pattern 'auth:parityfx:*' 2>/dev/null \
    | while read -r k; do redis-cli -p 6381 -n 9 DEL "$k" >/dev/null; done || true
}

# --- Boot single existing simulator ---
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

watch_shots() {
  local phase="$1"
  (
    last="" verified=0
    while true; do
      tag=$(tail -1 "$SHOT" 2>/dev/null | tr -d '\n' || true)
      if [[ -n "$tag" && "$tag" != "$last" ]]; then
        if [[ "$tag" == "${PREFIX}_clear_otp" ]]; then
          clear_otp_keys
          echo "OTP_CLEARED $tag"
          last="$tag"
          continue
        fi
        [[ "$tag" == "${PREFIX}_99_done" ]] && break
        xcrun simctl io "$UDID" screenshot "$SCREENS/${tag}.png" >/dev/null 2>&1 || true
        echo "SHOT $tag $(stat -f%z "$SCREENS/${tag}.png" 2>/dev/null || echo 0)"
        last="$tag"
      fi
      sleep 0.3
    done
  ) > "$EVIDENCE/shots_${phase}.log" 2>&1 &
  echo $!
}

run_merchant_phase() {
  local phase="$1" order_id="$2" rc=1
  : > "$SHOT"
  WATCH=$(watch_shots "$phase")
  set +e
  (cd "$FX_APP" && flutter test integration_test/live_pickup_handoff_merchant_test.dart \
    -d "$UDID" \
    --dart-define=API_BASE_URL="$FX_API_BASE" \
    --dart-define=FX_OTP_FILE="$FX_OTP_FILE" \
    --dart-define=FX_EVIDENCE_DIR="$EVIDENCE" \
    --dart-define=PARITY_PREFIX="$PREFIX" \
    --dart-define=LIVE_HANDOFF_PHASE="$phase" \
    --dart-define=FX_ORDER_ID="$order_id" \
    --dart-define=FX_SECRETS_PATH="$SECRETS" \
    > "$EVIDENCE/flutter_merchant_${phase}.log" 2>&1)
  rc=$?
  set +e
  sleep 2
  kill "$WATCH" 2>/dev/null || true
  wait "$WATCH" 2>/dev/null || true
  xcrun simctl terminate "$UDID" "$MERCHANT_BUNDLE" >/dev/null 2>&1 || true
  # Mask OTPs only (6+ digits); do not blanket-mask 4-digit runs (corrupts paths/UUIDs).
  sed -E 's/\b[0-9]{6,8}\b/<otp>/g' -i '' \
    "$EVIDENCE/flutter_merchant_${phase}.log" 2>/dev/null || true
  return "$rc"
}

run_driver_phase() {
  local rc=1
  : > "$SHOT"
  WATCH=$(watch_shots driver)
  set +e
  (cd "$DRIVER_APP" && flutter test integration_test/live_pickup_handoff_driver_test.dart \
    -d "$UDID" \
    --dart-define=API_BASE_URL="$FX_API_BASE" \
    --dart-define=FX_OTP_FILE="$FX_OTP_FILE" \
    --dart-define=FX_EVIDENCE_DIR="$EVIDENCE" \
    --dart-define=PARITY_PREFIX="$PREFIX" \
    --dart-define=FX_SECRETS_PATH="$SECRETS" \
    > "$EVIDENCE/flutter_driver.log" 2>&1)
  rc=$?
  set +e
  sleep 2
  kill "$WATCH" 2>/dev/null || true
  wait "$WATCH" 2>/dev/null || true
  xcrun simctl terminate "$UDID" "$DRIVER_BUNDLE" >/dev/null 2>&1 || true
  sed -E 's/\b[0-9]{6,8}\b/<otp>/g' -i '' \
    "$EVIDENCE/flutter_driver.log" 2>/dev/null || true
  return "$rc"
}

echo "LIVE_HANDOFF_START udid=$UDID api=$FX_API_BASE run=$RUN_ID"
clear_otp_keys

# Phase A — fixture
python3 "$HERE/fx_live_handoff_setup.py" "$META"
ORDER_ID=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["orderId"])' "$META")
ORDER_SUFFIX=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["orderIdSuffix"])' "$META")
echo "FIXTURE_OK orderSuffix=$ORDER_SUFFIX"

MERCHANT_CODE_RC=1
DRIVER_RC=1
MERCHANT_RECHECK_RC=1
VERIFY_RC=1
CLEANUP_RC=1

# Phase B — Merchant code UI
set +e
run_merchant_phase code "$ORDER_ID"
MERCHANT_CODE_RC=$?
set -e
echo "MERCHANT_CODE_EXIT=$MERCHANT_CODE_RC"

# Phase C — Driver confirm UI
if [[ "$MERCHANT_CODE_RC" -eq 0 ]]; then
  set +e
  run_driver_phase
  DRIVER_RC=$?
  set -e
fi
echo "DRIVER_EXIT=$DRIVER_RC"

# Phase D — Merchant recheck
if [[ "$DRIVER_RC" -eq 0 ]]; then
  set +e
  run_merchant_phase recheck "$ORDER_ID"
  MERCHANT_RECHECK_RC=$?
  set -e
fi
echo "MERCHANT_RECHECK_EXIT=$MERCHANT_RECHECK_RC"

# Phase E — Backend verify
set +e
python3 "$HERE/fx_live_handoff_verify.py" "$META" "$EVIDENCE/backend_verify.json"
VERIFY_RC=$?
set -e
echo "VERIFY_EXIT=$VERIFY_RC"

# Cleanup fixture + secrets
set +e
python3 "$HERE/fx_live_handoff_cleanup.py" "$META"
CLEANUP_RC=$?
set -e
echo "CLEANUP_EXIT=$CLEANUP_RC"

# Disk after
FREE_GB=$(df -k /System/Volumes/Data | awk 'NR==2 {printf "%.1f", $4/1024/1024}')

python3 - <<PY
import json, pathlib, datetime, subprocess, os
ev = pathlib.Path("$EVIDENCE")
screens = sorted(p.name for p in (ev / "screens").glob("*.png"))
gates = {
  "merchant_code_ui": "PASS" if $MERCHANT_CODE_RC == 0 else "FAIL",
  "driver_confirm_ui": "PASS" if $DRIVER_RC == 0 else "FAIL",
  "merchant_recheck_ui": "PASS" if $MERCHANT_RECHECK_RC == 0 else "FAIL",
  "backend_verify": "PASS" if $VERIFY_RC == 0 else "FAIL",
  "fixture_cleanup": "PASS" if $CLEANUP_RC == 0 else "FAIL",
}
all_pass = all(v == "PASS" for v in gates.values())
required_shots = [
  "fxlive_merchant_pickup_code.png",
  "fxlive_driver_code_entry.png",
  "fxlive_driver_picked_up.png",
  "fxlive_merchant_post_confirm.png",
]
shots_ok = all((ev / "screens" / s).exists() for s in required_shots)
meta = json.loads((ev / "fixture_meta.json").read_text()) if (ev / "fixture_meta.json").exists() else {}
manifest = {
  "runId": "$RUN_ID",
  "liveRunTag": meta.get("runTag"),
  "dateTime": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
  "git": {
    "backend": subprocess.check_output(["git","-C","$FX_PROJECT/apps/backend","rev-parse","HEAD"], text=True).strip(),
    "merchant": subprocess.check_output(["git","-C","$FX_APP","rev-parse","HEAD"], text=True).strip(),
    "driver": subprocess.check_output(["git","-C","$DRIVER_APP","rev-parse","HEAD"], text=True).strip(),
  },
  "simulator": {"udid": "$UDID", "model": "iPhone 16e"},
  "apiPort": 3100,
  "dbAlias": "speedygo_parity_fx",
  "redisIndex": 9,
  "fixture": {
    "orderIdSuffix": meta.get("orderIdSuffix"),
    "deliveryIdSuffix": meta.get("deliveryIdSuffix"),
    "assignmentId": meta.get("assignmentId"),
    "assignmentVersion": meta.get("assignmentVersion"),
  },
  "evidenceClassification": "live_ui_sequential_single_simulator",
  "screenshots": screens,
  "requiredScreenshotsPresent": shots_ok,
  "gates": gates,
  "allGatesPass": all_pass and shots_ok,
  "diskFreeGbAfter": float("$FREE_GB"),
  "row23Decision": "close_implementer_reviewed" if (all_pass and shots_ok) else "remain_open",
}
(ev / "MANIFEST.json").write_text(json.dumps(manifest, indent=2) + "\n")
print("MANIFEST_ALL_PASS" if manifest["allGatesPass"] else "MANIFEST_BLOCKED")
print(json.dumps(gates))
PY

# Mask OTP-length tokens in logs only (avoid mangling timestamps/UUIDs/paths).
find "$EVIDENCE" -name '*.log' -print0 2>/dev/null | while IFS= read -r -d '' f; do
  sed -E 's/\b[0-9]{6,8}\b/<otp>/g' -i '' "$f" 2>/dev/null || true
done

if [[ -f "$SECRETS" ]]; then
  rm -f "$SECRETS"
fi

echo "LIVE_HANDOFF_DONE evidence=$EVIDENCE free_gb=$FREE_GB"
exit 0
