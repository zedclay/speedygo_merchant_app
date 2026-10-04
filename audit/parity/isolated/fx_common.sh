# shellcheck shell=bash
# Shared constants and guarded helpers for the disposable Merchant write-test
# environment. Source it; never execute it directly.
#
# Fixed targets (no environment override is honoured):
#   PostgreSQL  speedygo_parity_fx on 127.0.0.1/localhost:5433
#   Redis       index 9 on 127.0.0.1/localhost:6381, prefixes "*parityfx*"
#   API         http://127.0.0.1:3100/api/v1
# Connection credentials are derived from apps/backend/.env (the approved
# configuration mechanism) and are never printed.

FX_DB_NAME=speedygo_parity_fx
FX_API_PORT=3100
FX_REDIS_INDEX=9
FX_PROJECT=/Users/mac/Downloads/speedygo_project
FX_BACKEND="$FX_PROJECT/apps/backend"
FX_APP="$FX_PROJECT/apps/merchant_app"
FX_DIR="$FX_APP/audit/parity/isolated"
FX_HOME="$HOME/.speedygo/parity_fx"
FX_EVIDENCE_ROOT="$FX_DIR/evidence"
FX_API_BASE="http://127.0.0.1:$FX_API_PORT/api/v1"
FX_OTP_FILE="$FX_HOME/otp/otp-last"
FX_GUARD="$FX_DIR/fx_guard.py"
FX_REDIS_PREFIXES=(auth:parityfx: matching:parityfx: bull:matching:parityfx: tracking:parityfx: storage:parityfx:)

for _fx_var in FX_DB_NAME_OVERRIDE PARITY_FX_DB PARITY_FX_REDIS_INDEX PARITY_FX_API_PORT; do
  if [[ -n "${!_fx_var:-}" ]]; then
    echo "FX_GUARD_REFUSED env: $_fx_var is set; targets are fixed and cannot be overridden" >&2
    return 3 2>/dev/null || exit 3
  fi
done
unset _fx_var PGHOST PGHOSTADDR PGPORT PGDATABASE PGSERVICE PGSERVICEFILE PGOPTIONS

fx_die() { echo "FX_ERROR $*" >&2; exit "${FX_EXIT:-1}"; }

# Derive and guard the three URLs. Sets FX_DB_URL, FX_ADMIN_URL, FX_REDIS_URL,
# FX_DEV_URL (read-only use) in this shell only.
fx_load_targets() {
  local dev_env
  dev_env=$(cd "$FX_BACKEND" && set -a && . ./.env && set +a && \
    python3 - <<'PY'
import os, shlex
for k in ('DATABASE_URL', 'REDIS_URL'):
    print(f'{k}={shlex.quote(os.environ.get(k, ""))}')
PY
  ) || fx_die "cannot read apps/backend/.env"
  local DATABASE_URL REDIS_URL
  eval "$dev_env"
  FX_DEV_URL="$DATABASE_URL"
  [[ "$(python3 -c 'import sys,urllib.parse as u; print(u.urlsplit(sys.argv[1]).path)' "$FX_DEV_URL")" == "/speedygo_dev" ]] \
    || fx_die "dev DATABASE_URL does not point at speedygo_dev; refusing to derive"
  FX_DB_URL=$(DATABASE_URL="$DATABASE_URL" python3 "$FX_GUARD" derive-db) || FX_EXIT=3 fx_die "isolated DB URL refused"
  FX_ADMIN_URL=$(DATABASE_URL="$DATABASE_URL" python3 "$FX_GUARD" derive-admin-db) || FX_EXIT=3 fx_die "maintenance URL refused"
  FX_REDIS_URL=$(REDIS_URL="$REDIS_URL" python3 "$FX_GUARD" derive-redis) || FX_EXIT=3 fx_die "isolated Redis URL refused"
  python3 "$FX_GUARD" check-db "$FX_DB_URL" || FX_EXIT=3 fx_die "isolated DB URL refused"
  python3 "$FX_GUARD" check-redis "$FX_REDIS_URL" || FX_EXIT=3 fx_die "isolated Redis URL refused"
}

# psql against the isolated database, after a server-side identity check.
fx_psql() {
  python3 "$FX_GUARD" check-db "$FX_DB_URL" || FX_EXIT=3 fx_die "isolated DB URL refused"
  local ident
  ident=$(psql "${FX_DB_URL%%\?*}" -X -q -A -t -v ON_ERROR_STOP=1 \
    -c "select current_database() || '|' || inet_server_port() || '|' || coalesce(host(inet_server_addr()), 'local')") \
    || fx_die "cannot connect to $FX_DB_NAME"
  case "$ident" in
    "$FX_DB_NAME|5433|127.0.0.1"|"$FX_DB_NAME|5433|::1"|"$FX_DB_NAME|5433|local") ;;
    *) FX_EXIT=3 fx_die "server identity mismatch ($ident)" ;;
  esac
  psql "${FX_DB_URL%%\?*}" -X -q -A -t -v ON_ERROR_STOP=1 "$@"
}

# Read-only queries against speedygo_dev (isolation evidence only).
fx_psql_dev_ro() {
  PGOPTIONS='-c default_transaction_read_only=on' \
    psql "${FX_DEV_URL%%\?*}" -X -q -A -t -v ON_ERROR_STOP=1 "$@"
}

# Maintenance database: existence checks and CREATE/DROP of the fixed name only.
fx_psql_admin() {
  python3 "$FX_GUARD" check-admin-db "$FX_ADMIN_URL" || FX_EXIT=3 fx_die "maintenance URL refused"
  psql "${FX_ADMIN_URL%%\?*}" -X -q -A -t -v ON_ERROR_STOP=1 "$@"
}

fx_db_exists() {
  [[ "$(fx_psql_admin -c "select count(*) from pg_database where datname = '$FX_DB_NAME'")" == "1" ]]
}

fx_db_marker() {
  fx_psql_admin -c "select coalesce(shobj_description(oid, 'pg_database'), '') from pg_database where datname = '$FX_DB_NAME'"
}

# redis-cli on the dedicated index only.
fx_redis() {
  python3 "$FX_GUARD" check-redis "$FX_REDIS_URL" || FX_EXIT=3 fx_die "isolated Redis URL refused"
  redis-cli -u "$FX_REDIS_URL" "$@"
}

# Keys on the dedicated index that do not carry an isolated prefix.
fx_redis_foreign_keys() {
  local key prefix ok
  while IFS= read -r key; do
    [[ -z "$key" ]] && continue
    ok=0
    for prefix in "${FX_REDIS_PREFIXES[@]}"; do
      [[ "$key" == "$prefix"* ]] && { ok=1; break; }
    done
    if [[ $ok -eq 0 ]]; then echo "$key"; fi
  done < <(fx_redis --scan --count 1000)
  return 0
}

fx_api_pid() { [[ -f "$FX_HOME/api.pid" ]] && cat "$FX_HOME/api.pid"; }

# True when PID is the isolated API: right binary path and listening on 3100.
fx_is_fx_api() {
  local pid="$1" cmd listener
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  cmd=$(ps -o command= -p "$pid" 2>/dev/null || true)
  [[ "$cmd" == *"$FX_HOME/dist/src/main.js"* ]] || return 1
  listener=$(lsof -nP -tiTCP:"$FX_API_PORT" -sTCP:LISTEN 2>/dev/null | head -1 || true)
  [[ -z "$listener" || "$listener" == "$pid" ]]
}
