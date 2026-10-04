#!/usr/bin/env bash
# Guard tests for the disposable Merchant write-test environment.
# Proves that shared and production-like targets are refused, and that the
# scripts stop before any database, Redis, API or simulator command when a
# guard fails. Script-level cases run with stub psql / redis-cli / pnpm /
# node / xcrun / createdb / dropdb on PATH that record every call; a refused
# case must leave the stub log empty. No real database or Redis is touched.
# Usage: fx_guard_test.sh
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
GUARD="$HERE/fx_guard.py"
PASS=0
FAIL=0
ok() { PASS=$((PASS + 1)); echo "PASS  $*"; }
ko() { FAIL=$((FAIL + 1)); echo "FAIL  $*"; }

expect_rc() { # <expected-rc> <label> <cmd...>
  local want="$1" label="$2"; shift 2
  "$@" >/dev/null 2>&1
  local got=$?
  [[ "$got" == "$want" ]] && ok "$label (rc=$got)" || ko "$label (want rc=$want, got $got)"
}

P='postgresql://user:pw'
# --- database URL guard ----------------------------------------------------
expect_rc 0 "db: isolated URL on 127.0.0.1:5433"  python3 "$GUARD" check-db "$P@127.0.0.1:5433/speedygo_parity_fx?schema=public"
expect_rc 0 "db: isolated URL on localhost:5433"  python3 "$GUARD" check-db "$P@localhost:5433/speedygo_parity_fx"
expect_rc 3 "db: speedygo_dev refused"            python3 "$GUARD" check-db "$P@127.0.0.1:5433/speedygo_dev?schema=public"
expect_rc 3 "db: speedygo_test refused"           python3 "$GUARD" check-db "$P@127.0.0.1:5433/speedygo_test"
expect_rc 3 "db: postgres refused"                python3 "$GUARD" check-db "$P@127.0.0.1:5433/postgres"
expect_rc 3 "db: template1 refused"               python3 "$GUARD" check-db "$P@127.0.0.1:5433/template1"
expect_rc 3 "db: speedygo refused"                python3 "$GUARD" check-db "$P@127.0.0.1:5433/speedygo"
expect_rc 3 "db: speedygo_prod refused"           python3 "$GUARD" check-db "$P@127.0.0.1:5433/speedygo_prod"
expect_rc 3 "db: speedygo_production refused"     python3 "$GUARD" check-db "$P@127.0.0.1:5433/speedygo_production"
expect_rc 3 "db: speedygo_staging refused"        python3 "$GUARD" check-db "$P@127.0.0.1:5433/speedygo_staging"
expect_rc 3 "db: speedygo_live refused"           python3 "$GUARD" check-db "$P@127.0.0.1:5433/speedygo_live"
expect_rc 3 "db: speedygo_parity_fx_prod refused" python3 "$GUARD" check-db "$P@127.0.0.1:5433/speedygo_parity_fx_prod"
expect_rc 3 "db: near-miss name refused"          python3 "$GUARD" check-db "$P@127.0.0.1:5433/speedygo_parity_fx2"
expect_rc 3 "db: upper-case variant refused"      python3 "$GUARD" check-db "$P@127.0.0.1:5433/SPEEDYGO_PARITY_FX"
expect_rc 3 "db: port 5432 refused"               python3 "$GUARD" check-db "$P@127.0.0.1:5432/speedygo_parity_fx"
expect_rc 3 "db: implicit port refused"           python3 "$GUARD" check-db "$P@127.0.0.1/speedygo_parity_fx"
expect_rc 3 "db: remote host refused"             python3 "$GUARD" check-db "$P@db.example.com:5433/speedygo_parity_fx"
expect_rc 3 "db: LAN address refused"             python3 "$GUARD" check-db "$P@10.0.0.5:5433/speedygo_parity_fx"
expect_rc 3 "db: 0.0.0.0 refused"                 python3 "$GUARD" check-db "$P@0.0.0.0:5433/speedygo_parity_fx"
expect_rc 3 "db: ?host= override refused"         python3 "$GUARD" check-db "$P@127.0.0.1:5433/speedygo_parity_fx?host=db.example.com"
expect_rc 3 "db: ?dbname= override refused"       python3 "$GUARD" check-db "$P@127.0.0.1:5433/speedygo_parity_fx?dbname=speedygo_dev"
expect_rc 3 "db: ?port= override refused"         python3 "$GUARD" check-db "$P@127.0.0.1:5433/speedygo_parity_fx?port=5432"
expect_rc 3 "db: ?service= refused"               python3 "$GUARD" check-db "$P@127.0.0.1:5433/speedygo_parity_fx?service=prod"
expect_rc 3 "db: ?schema=other refused"           python3 "$GUARD" check-db "$P@127.0.0.1:5433/speedygo_parity_fx?schema=prod"
expect_rc 3 "db: nested path refused"             python3 "$GUARD" check-db "$P@127.0.0.1:5433/speedygo_parity_fx/x"
expect_rc 3 "db: other scheme refused"            python3 "$GUARD" check-db "mysql://u:p@127.0.0.1:5433/speedygo_parity_fx"
expect_rc 3 "db: socket host refused"             python3 "$GUARD" check-db "postgresql://u:p@%2Ftmp:5433/speedygo_parity_fx"

# --- exact name guard (CREATE / DROP) ------------------------------------------
expect_rc 0 "name: speedygo_parity_fx allowed"    python3 "$GUARD" check-name speedygo_parity_fx
for n in speedygo_dev speedygo_test postgres template0 speedygo speedygo_prod production "speedygo_parity_fx " speedygo_parity_fx_old; do
  expect_rc 3 "name: '$n' refused" python3 "$GUARD" check-name "$n"
done

# --- maintenance URL guard -------------------------------------------------------
expect_rc 0 "admin: postgres on 127.0.0.1:5433"   python3 "$GUARD" check-admin-db "$P@127.0.0.1:5433/postgres?schema=public"
expect_rc 3 "admin: speedygo_dev refused"         python3 "$GUARD" check-admin-db "$P@127.0.0.1:5433/speedygo_dev"
expect_rc 3 "admin: port 5432 refused"            python3 "$GUARD" check-admin-db "$P@127.0.0.1:5432/postgres"
expect_rc 3 "admin: remote host refused"          python3 "$GUARD" check-admin-db "$P@db.example.com:5433/postgres"

# --- Redis guard -------------------------------------------------------------------
expect_rc 0 "redis: index 9 on 127.0.0.1:6381"    python3 "$GUARD" check-redis "redis://127.0.0.1:6381/9"
expect_rc 0 "redis: index 9 on localhost:6381"    python3 "$GUARD" check-redis "redis://localhost:6381/9"
expect_rc 3 "redis: no index (dev 0) refused"     python3 "$GUARD" check-redis "redis://localhost:6381"
expect_rc 3 "redis: index 0 refused"              python3 "$GUARD" check-redis "redis://localhost:6381/0"
expect_rc 3 "redis: index 15 (e2e) refused"       python3 "$GUARD" check-redis "redis://localhost:6381/15"
expect_rc 3 "redis: index 8 refused"              python3 "$GUARD" check-redis "redis://localhost:6381/8"
expect_rc 3 "redis: port 6379 refused"            python3 "$GUARD" check-redis "redis://localhost:6379/9"
expect_rc 3 "redis: remote host refused"          python3 "$GUARD" check-redis "redis://cache.example.com:6381/9"
expect_rc 3 "redis: TLS scheme refused"           python3 "$GUARD" check-redis "rediss://localhost:6381/9"
expect_rc 3 "redis: query refused"                python3 "$GUARD" check-redis "redis://localhost:6381/9?db=0"

# --- derivation from the dev configuration ---------------------------------------
expect_rc 3 "derive: remote source refused"       env DATABASE_URL="$P@db.example.com:5433/speedygo_dev" python3 "$GUARD" derive-db
expect_rc 3 "derive: port 5432 source refused"    env DATABASE_URL="$P@localhost:5432/speedygo_dev" python3 "$GUARD" derive-db
expect_rc 3 "derive: empty source refused"        env DATABASE_URL= python3 "$GUARD" derive-db
expect_rc 3 "derive: redis 6379 source refused"   env REDIS_URL="redis://localhost:6379" python3 "$GUARD" derive-redis
DERIVED=$(env DATABASE_URL="$P@localhost:5433/speedygo_dev?schema=public" python3 "$GUARD" derive-db 2>/dev/null \
  | python3 -c 'import sys,urllib.parse as u; p=u.urlsplit(sys.stdin.read().strip()); print(p.hostname, p.port, p.path, p.query)')
[[ "$DERIVED" == "localhost 5433 /speedygo_parity_fx schema=public" ]] \
  && ok "derive: dev URL becomes speedygo_parity_fx on the same host/port" || ko "derive: got '$DERIVED'"
RDERIVED=$(env REDIS_URL="redis://localhost:6381" python3 "$GUARD" derive-redis 2>/dev/null)
[[ "$RDERIVED" == "redis://localhost:6381/9" ]] && ok "derive: Redis becomes index 9" || ko "derive: got '$RDERIVED'"

# --- script-level refusals with stub binaries ------------------------------------
STUB=$(mktemp -d)
CALLS="$STUB/calls.log"
: > "$CALLS"
for bin in psql redis-cli pnpm node createdb dropdb xcrun flutter curl; do
  printf '#!/usr/bin/env bash\necho "%s $*" >> "%s"\nexit 99\n' "$bin" "$CALLS" > "$STUB/$bin"
  chmod +x "$STUB/$bin"
done
run_stubbed() { # <expected-rc> <label> <env...> -- <script> [args]
  local want="$1" label="$2"; shift 2
  local envs=()
  while [[ "$1" != "--" ]]; do envs+=("$1"); shift; done
  shift
  : > "$CALLS"
  env "${envs[@]}" PATH="$STUB:$PATH" bash "$@" >/dev/null 2>&1
  local got=$?
  if [[ "$got" == "$want" && ! -s "$CALLS" ]]; then
    ok "$label (rc=$got, no command reached)"
  else
    ko "$label (want rc=$want got $got; calls: $(tr '\n' ';' < "$CALLS"))"
  fi
}
for s in fx_start.sh fx_cleanup.sh fx_snapshot.sh fx_sql.sh; do
  run_stubbed 3 "$s refuses PARITY_FX_DB=speedygo_dev" PARITY_FX_DB=speedygo_dev -- "$HERE/$s" /dev/null
  run_stubbed 3 "$s refuses FX_DB_NAME_OVERRIDE=speedygo_test" FX_DB_NAME_OVERRIDE=speedygo_test -- "$HERE/$s" /dev/null
  run_stubbed 3 "$s refuses PARITY_FX_REDIS_INDEX=0" PARITY_FX_REDIS_INDEX=0 -- "$HERE/$s" /dev/null
done
run_stubbed 3 "fx_contract_e2e.sh refuses PARITY_FX_DB=speedygo_dev" PARITY_FX_DB=speedygo_dev -- "$HERE/fx_contract_e2e.sh" /dev/null
run_stubbed 75 "fx_start.sh runs the disk preflight first" PARITY_MIN_FREE_GB=999999 -- "$HERE/fx_start.sh"
run_stubbed 1 "fx_run.sh refuses the Finjan simulator" X=1 -- "$HERE/fx_run.sh" 4A1C3481-0000-0000-0000-000000000000 fxi_t100 large
run_stubbed 1 "fx_run.sh refuses any other simulator" X=1 -- "$HERE/fx_run.sh" 11111111-2222-3333-4444-555555555555 fxi_t100 large
run_stubbed 1 "fx_run.sh refuses an unknown content size" X=1 -- "$HERE/fx_run.sh" 8DB9007A-B816-4EC5-86ED-C627AC60F2C5 fxi_t100 huge
run_stubbed 1 "fx_run.sh refuses a test outside the allowlist" X=1 -- "$HERE/fx_run.sh" 8DB9007A-B816-4EC5-86ED-C627AC60F2C5 fxi_t100 large ../evil_test
run_stubbed 1 "fx_run.sh still refuses the Finjan simulator for the batch test" X=1 -- "$HERE/fx_run.sh" 4A1C3481-0000-0000-0000-000000000000 fxc_t100 large contract_batch_fx_live_test
run_stubbed 1 "fx_run.sh still refuses the Finjan simulator for the polish test" X=1 -- "$HERE/fx_run.sh" 4A1C3481-0000-0000-0000-000000000000 fxp_t100 large polish_fx_live_test

FIXED=$(env FX_DB_NAME=speedygo_dev FX_REDIS_INDEX=0 FX_API_PORT=3000 bash -c ". '$HERE/fx_common.sh'; echo \$FX_DB_NAME \$FX_REDIS_INDEX \$FX_API_PORT \$FX_API_BASE")
[[ "$FIXED" == "speedygo_parity_fx 9 3100 http://127.0.0.1:3100/api/v1" ]] \
  && ok "constants: environment cannot redirect name, index or port" || ko "constants: got '$FIXED'"
rm -rf "$STUB"

# --- static checks on the scripts and the seed -------------------------------------
grep -q "current_database() <> 'speedygo_parity_fx' OR inet_server_port() <> 5433" "$HERE/fx_seed.sql" \
  && ok "seed: refuses outside speedygo_parity_fx:5433" || ko "seed: database guard missing"
grep -q "NOT LIKE 'speedygo-parity-fx disposable%'" "$HERE/fx_seed.sql" \
  && ok "seed: requires the disposable marker" || ko "seed: marker guard missing"
DROPS=$(grep -hvE '^\s*#' "$HERE"/fx_start.sh "$HERE"/fx_run.sh "$HERE"/fx_cleanup.sh "$HERE"/fx_common.sh "$HERE"/fx_snapshot.sh \
  | grep -oE 'DROP DATABASE [A-Za-z_$]+' | sort -u | tr '\n' ';')
[[ "$DROPS" == "DROP DATABASE speedygo_parity_fx;" ]] \
  && ok "scripts: the only DROP DATABASE is the literal speedygo_parity_fx" || ko "scripts: DROP statements '$DROPS'"
if grep -nE 'TRUNCATE|migrate reset|db init|db push|DROP (TABLE|SCHEMA)|FLUSHALL' "$HERE"/fx_*.sh "$HERE"/fx_*.py "$HERE/fx_seed.sql" | grep -v '^.*fx_guard_test.sh' >/dev/null; then
  ko "scripts: destructive statement found"
else
  ok "scripts: no TRUNCATE, reset, init, push, DROP TABLE/SCHEMA or FLUSHALL"
fi
if grep -nE 'FX_DEV_URL|fx_psql_dev_ro' "$HERE/fx_start.sh" "$HERE/fx_cleanup.sh" "$HERE/fx_run.sh" >/dev/null; then
  ko "scripts: start/run/cleanup connect to speedygo_dev"
else
  ok "scripts: start/run/cleanup never connect to speedygo_dev (read-only access lives in fx_snapshot.sh)"
fi
grep -q "default_transaction_read_only=on" "$HERE/fx_common.sh" \
  && ok "snapshot: speedygo_dev queries run read-only" || ko "snapshot: read-only option missing"

echo "FX_GUARD_TESTS pass=$PASS fail=$FAIL"
[[ $FAIL -eq 0 ]]
