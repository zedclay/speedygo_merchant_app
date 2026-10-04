#!/usr/bin/env bash
# Black-box e2e for Merchant Team Management (row 64) against isolated :3100.
# Usage: fx_team_e2e.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/fx_common.sh"
fx_load_targets
RUN_ID=$(cat "$FX_HOME/run_id" 2>/dev/null || true)
[[ "$RUN_ID" == fxenv_* ]] || fx_die "no isolated environment (run fx_start.sh first)"
API_PID=$(fx_api_pid || true)
fx_is_fx_api "${API_PID:-}" || fx_die "recorded API is not the isolated build on $FX_API_PORT"
[[ "$(fx_db_marker)" == "speedygo-parity-fx disposable run=$RUN_ID" ]] || FX_EXIT=3 fx_die "database marker mismatch; refused"
OUT="$FX_EVIDENCE_ROOT/$RUN_ID/team_management"
mkdir -p "$OUT"
python3 "$HERE/fx_team_e2e.py" "$OUT" "$HERE/fx_sql.sh" 2>&1 | tee "$OUT/e2e.log"
