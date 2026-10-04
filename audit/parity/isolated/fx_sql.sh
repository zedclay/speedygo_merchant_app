#!/usr/bin/env bash
# Runs SQL read from stdin against the disposable speedygo_parity_fx database
# only (same guards as fx_psql, plus the disposable-marker check). Used by the
# contract-completion e2e for row assertions and for the temporary rollback
# trigger, which exists only in the isolated database.
# Usage: fx_sql.sh < statement.sql   (prints unaligned, tuples-only output)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/fx_common.sh"
fx_load_targets
fx_db_exists || FX_EXIT=3 fx_die "$FX_DB_NAME does not exist"
[[ "$(fx_db_marker)" == "speedygo-parity-fx disposable run="* ]] \
  || FX_EXIT=3 fx_die "database lacks the disposable marker; refused"
fx_psql -f -
