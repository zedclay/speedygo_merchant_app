#!/usr/bin/env bash
# Wraps one live run: snapshots the account's sessions/devices/device tokens,
# runs the command with a disk watchdog, then records the rows the run created
# and revokes (by ID) any session it created that is still active.
# Usage: run_guard.sh <label> <account-id> -- <command...>
set -uo pipefail
LABEL="$1"; ACCOUNT="$2"; shift 3
RUN=/Users/mac/Downloads/speedygo_project/apps/merchant_app/audit/parity/live/.run
BACKEND=/Users/mac/Downloads/speedygo_project/apps/backend
MIN_FREE_KB=$((2 * 1024 * 1024))
. "$RUN/../disk_preflight.sh"
require_free_disk "guard:$LABEL" || exit $?

db() { (cd "$BACKEND" && set -a && . ./.env && set +a && psql "${DATABASE_URL%%\?*}" -X -q -A -t -v ON_ERROR_STOP=1 "$@"); }
ids() { db -c "select coalesce(string_agg(quote_literal(id::text), ','), '''-''') from $1 where account_id = '$ACCOUNT'"; }

[[ "$(db -c 'select current_database()')" == "speedygo_dev" ]] || { echo "not speedygo_dev"; exit 1; }
S0=$(ids sessions); D0=$(ids devices); T0=$(ids device_tokens)
START=$(date -u +%FT%TZ)

"$@" &
CMD=$!
(
  while kill -0 "$CMD" 2>/dev/null; do
    free=$(df -k /System/Volumes/Data | awk 'NR==2 {print $4}')
    if (( free < MIN_FREE_KB )); then
      echo "DISK_WATCHDOG free_kb=$free at $(date -u +%FT%TZ); stopping run" > "$RUN/watchdog_$LABEL.txt"
      pkill -TERM -f "flutter_tools.*integration_test/parity_" 2>/dev/null
      kill -TERM "$CMD" 2>/dev/null
      break
    fi
    sleep 5
  done
) &
WATCH=$!
wait "$CMD"; RC=$?
kill "$WATCH" 2>/dev/null; wait "$WATCH" 2>/dev/null

NEW_S=$(db -c "select coalesce(json_agg(json_build_object('id', id, 'revoked', revoked_at is not null)), '[]') from sessions where account_id = '$ACCOUNT' and id::text not in ($S0)")
ACTIVE=$(db -c "select count(*) from sessions where account_id = '$ACCOUNT' and id::text not in ($S0) and revoked_at is null")
FALLBACK=0
if [[ "$ACTIVE" != "0" ]]; then
  db -c "update sessions set revoked_at = now() where account_id = '$ACCOUNT' and id::text not in ($S0) and revoked_at is null" >/dev/null
  FALLBACK=$ACTIVE
fi
NEW_D=$(db -c "select coalesce(json_agg(id), '[]') from devices where account_id = '$ACCOUNT' and id::text not in ($D0)")
NEW_T=$(db -c "select coalesce(json_agg(json_build_object('id', id, 'active', active)), '[]') from device_tokens where account_id = '$ACCOUNT' and id::text not in ($T0)")
cat > "$RUN/created_$LABEL.json" <<EOF
{"label": "$LABEL", "accountId": "$ACCOUNT", "start": "$START", "exit": $RC,
 "sessions": $NEW_S, "fallbackRevoked": $FALLBACK, "devices": $NEW_D, "deviceTokens": $NEW_T}
EOF
cat "$RUN/created_$LABEL.json"
[[ -f "$RUN/watchdog_$LABEL.txt" ]] && cat "$RUN/watchdog_$LABEL.txt"
exit "$RC"
