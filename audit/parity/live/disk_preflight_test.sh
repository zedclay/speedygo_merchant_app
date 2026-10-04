#!/usr/bin/env bash
# Lightweight test for disk_preflight.sh and its use by the live runners.
# Stub flutter / xcrun / psql / df executables are put first on PATH; they only
# log their invocation, so no build, simulator, database or real disk check is
# touched. Usage: bash disk_preflight_test.sh
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d /tmp/parity_preflight_test.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
STUBS="$TMP/bin"; LOG="$TMP/calls.log"; mkdir -p "$STUBS"; : > "$LOG"
PASS=0; FAIL=0

for cmd in flutter xcrun psql; do
  cat > "$STUBS/$cmd" <<EOF
#!/usr/bin/env bash
echo "$cmd \$*" >> "$LOG"
case "$cmd \$*" in
  *current_database*) echo speedygo_dev ;;
  *count\(\*\)*) echo 0 ;;
  *content_size) echo large ;;
esac
EOF
  chmod +x "$STUBS/$cmd"
done
# df stub: free KB for successive calls come from $TMP/df_values (one per line;
# the last value repeats).
cat > "$STUBS/df" <<EOF
#!/usr/bin/env bash
n=\$(cat "$TMP/df_calls" 2>/dev/null || echo 0); n=\$((n + 1)); echo \$n > "$TMP/df_calls"
v=\$(sed -n "\${n}p" "$TMP/df_values"); [[ -z "\$v" ]] && v=\$(tail -1 "$TMP/df_values")
echo "Filesystem 1024-blocks Used Available Capacity Mounted"
echo "/dev/stub 100 1 \$v 1% /"
EOF
chmod +x "$STUBS/df"

set_df() { printf '%s\n' "$@" > "$TMP/df_values"; rm -f "$TMP/df_calls"; : > "$LOG"; }
check() {
  local name="$1" cond="$2"
  if eval "$cond"; then PASS=$((PASS + 1)); echo "ok   - $name"; else FAIL=$((FAIL + 1)); echo "FAIL - $name"; fi
}
GB=$((1024 * 1024))
export PATH="$STUBS:$PATH"

# 1. The function itself.
set_df $((6 * GB))
out=$(PARITY_MIN_FREE_GB=5 bash -c ". '$HERE/disk_preflight.sh'; require_free_disk unit" 2>&1); rc=$?
check "6 GB free, minimum 5: allowed" '[[ $rc -eq 0 && "$out" == *DISK_PREFLIGHT_OK* ]]'
set_df $((4 * GB))
out=$(PARITY_MIN_FREE_GB=5 bash -c ". '$HERE/disk_preflight.sh'; require_free_disk unit" 2>&1); rc=$?
check "4 GB free, minimum 5: blocked (75)" '[[ $rc -eq 75 && "$out" == *DISK_PREFLIGHT_BLOCKED*free_gb=4*min_gb=5* ]]'
set_df $((5 * GB - 1))
out=$(bash -c ". '$HERE/disk_preflight.sh'; require_free_disk unit" 2>&1); rc=$?
check "just under the default 5 GB: blocked" '[[ $rc -eq 75 ]]'
set_df $((50 * GB))
out=$(PARITY_MIN_FREE_GB=abc bash -c ". '$HERE/disk_preflight.sh'; require_free_disk unit" 2>&1); rc=$?
check "invalid minimum: blocked, not ignored" '[[ $rc -eq 75 && "$out" == *invalid* ]]'
set_df "garbage"
out=$(bash -c ". '$HERE/disk_preflight.sh'; require_free_disk unit" 2>&1); rc=$?
check "unreadable free space: blocked, not ignored" '[[ $rc -eq 75 && "$out" == *cannot\ read* ]]'

# 2. Runners stop before any simulator, build or database step.
UDID=00000000-0000-0000-0000-000000000000
set_df $((3 * GB))
PARITY_MIN_FREE_GB=5 bash "$HERE/run_parity_live.sh" "$UDID" preflight_test large o p c dedicated > "$TMP/o1" 2>&1; rc=$?
check "run_parity_live.sh below minimum: exit 75" '[[ $rc -eq 75 ]]'
check "run_parity_live.sh below minimum: no xcrun/flutter call" '[[ ! -s "$LOG" ]]'

set_df $((3 * GB))
PARITY_MIN_FREE_GB=5 bash "$HERE/run_parity_b7_approval_live.sh" "$UDID" preflight_test large 550000000 pending > "$TMP/o2" 2>&1; rc=$?
check "b7 approval runner below minimum: exit 75" '[[ $rc -eq 75 ]]'
check "b7 approval runner below minimum: no psql/xcrun/flutter call" '[[ ! -s "$LOG" ]]'

set_df $((3 * GB))
PARITY_MIN_FREE_GB=5 bash "$HERE/run_parity_b7_live.sh" "$UDID" preflight_test large 550000000 > "$TMP/o3" 2>&1; rc=$?
check "b7 runner below minimum: exit 75" '[[ $rc -eq 75 ]]'
check "b7 runner below minimum: no psql/xcrun/flutter call" '[[ ! -s "$LOG" ]]'

set_df $((3 * GB))
PARITY_MIN_FREE_GB=5 bash "$HERE/.run/run_guard.sh" preflight_test 00000000-0000-0000-0000-000000000000 -- touch "$TMP/marker" > "$TMP/o4" 2>&1; rc=$?
check "run_guard below minimum: exit 75" '[[ $rc -eq 75 ]]'
check "run_guard below minimum: wrapped command not started" '[[ ! -e "$TMP/marker" ]]'
check "run_guard below minimum: no database snapshot" '[[ ! -s "$LOG" ]]'

# 3. Space drops after the start check: the next build (register phase) is prevented.
set_df $((8 * GB)) $((3 * GB))
PARITY_MIN_FREE_GB=5 bash "$HERE/run_parity_b7_approval_live.sh" "$UDID" preflight_test large 550000000 pending > "$TMP/o5" 2>&1; rc=$?
check "b7 approval: drop before the register build: exit 75" '[[ $rc -eq 75 ]]'
check "b7 approval: drop before the register build: flutter never called" '! grep -q "^flutter" "$LOG"'
check "b7 approval: content size set, then restored on exit" '[[ $(grep -c "content_size large" "$LOG") -ge 2 ]]'

# 4. Enough space: the runner proceeds to the build (stubbed flutter is reached).
set_df $((8 * GB))
PARITY_MIN_FREE_GB=5 bash "$HERE/run_parity_live.sh" "$UDID" preflight_test large o p c dedicated > "$TMP/o6" 2>&1; rc=$?
check "run_parity_live.sh with enough space: reaches flutter" 'grep -q "^flutter test" "$LOG"'

rm -f "$HERE/BUNDLE_preflight_test.txt" /tmp/parity_live_shots_preflight_test.log /tmp/parity_live_flutter_preflight_test.log
echo "passed=$PASS failed=$FAIL"
[[ $FAIL -eq 0 ]]
