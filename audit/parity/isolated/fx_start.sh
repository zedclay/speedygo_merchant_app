#!/usr/bin/env bash
# Creates the disposable Merchant write-test environment:
#   1. 5 GB disk preflight (shared live/disk_preflight.sh, threshold unchanged);
#   2. target guards (fx_guard.py) and preconditions: port 3100 free,
#      speedygo_parity_fx absent, Redis index 9 empty, no leftover state dir;
#   3. read-only speedygo_dev / Redis baseline snapshot;
#   4. CREATE DATABASE speedygo_parity_fx (marked by a database comment),
#      existing migrations via `prisma db migrate`, explicit fixture seed;
#   5. private compile of the backend into ~/.speedygo/parity_fx/dist and an
#      API on 127.0.0.1:3100 started with `env -i` and an explicit variable
#      list (dedicated Redis index and prefixes, push disabled, payment test
#      provider, no maps key, console OTP into a private directory);
#   6. checks that every API Postgres connection is on speedygo_parity_fx and
#      every API Redis connection is on index 9.
# It never resets, migrates, truncates or drops a shared database.
# Usage: fx_start.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/fx_common.sh"
. "$FX_APP/audit/parity/live/disk_preflight.sh"

require_free_disk "fx-start" || exit $?
fx_load_targets

trap 'echo "FX_START_FAILED at line $LINENO; state kept for fx_cleanup.sh" >&2' ERR

[[ -z "$(lsof -nP -tiTCP:$FX_API_PORT -sTCP:LISTEN 2>/dev/null || true)" ]] \
  || fx_die "port $FX_API_PORT is already in use; refusing to start (nothing stopped)"
if fx_db_exists; then
  fx_die "$FX_DB_NAME already exists; run fx_cleanup.sh first (start never resets a database)"
fi
[[ "$(fx_redis DBSIZE)" == "0" ]] || fx_die "Redis index $FX_REDIS_INDEX is not empty; run fx_cleanup.sh or inspect it"
[[ ! -e "$FX_HOME" ]] || fx_die "$FX_HOME exists; run fx_cleanup.sh first"

RUN_ID="fxenv_$(date -u +%Y%m%dT%H%M%SZ)"
START_ISO="$(date -u +%FT%TZ)"
mkdir -p "$FX_HOME"/{otp,storage,logs}
chmod 700 "$FX_HOME" "$FX_HOME"/{otp,storage,logs}
EVIDENCE="$FX_EVIDENCE_ROOT/$RUN_ID"
mkdir -p "$EVIDENCE"
echo "$RUN_ID" > "$FX_HOME/run_id"
echo "$START_ISO" > "$EVIDENCE/started_at"
echo "FX_RUN_ID $RUN_ID"

bash "$HERE/fx_snapshot.sh" "$EVIDENCE/isolation_before.json" "$START_ISO" >/dev/null

# --- database -----------------------------------------------------------------
python3 "$FX_GUARD" check-name "$FX_DB_NAME"
fx_psql_admin -c "CREATE DATABASE speedygo_parity_fx"
fx_psql_admin -c "COMMENT ON DATABASE speedygo_parity_fx IS 'speedygo-parity-fx disposable run=$RUN_ID'"
[[ "$(fx_db_marker)" == "speedygo-parity-fx disposable run=$RUN_ID" ]] || fx_die "database marker not set"

redact() { sed -E 's#postgres(ql)?://[^[:space:]"]+#<redacted-db-url>#g; s#redis://[^[:space:]"]+#<redacted-redis-url>#g'; }

(
  cd "$FX_BACKEND"
  env -i PATH="$PATH" HOME="$HOME" DATABASE_URL="$FX_DB_URL" \
    pnpm exec prisma db migrate --db "$FX_DB_URL" --yes
) 2>&1 | redact > "$FX_HOME/logs/migrate.log"
(
  cd "$FX_BACKEND"
  env -i PATH="$PATH" HOME="$HOME" DATABASE_URL="$FX_DB_URL" \
    pnpm exec prisma db verify --db "$FX_DB_URL"
) 2>&1 | redact > "$FX_HOME/logs/verify.log" || true
APPLIED=$(fx_psql -c "select count(*) from information_schema.tables where table_schema = 'public' and table_name in ('orders','merchant_branches','merchant_branch_availability_overrides','order_preparation_estimate_revisions','communes','merchant_branch_logos','merchant_branch_hours_exceptions','merchant_branch_hours_exception_intervals','legal_document_versions','merchant_verification_submissions','merchant_legal_acceptances','merchant_verification_issues','support_topics','support_faq_articles','merchant_member_invitations','delivery_pickup_handoffs')")
[[ "$APPLIED" == "16" ]] || fx_die "migrations incomplete (found $APPLIED of 16 probe tables)"
MEMBER_VER=$(fx_psql -c "select count(*) from information_schema.columns where table_schema='public' and table_name='merchant_members' and column_name in ('version','updated_at')")
[[ "$MEMBER_VER" == "2" ]] || fx_die "merchant_members version/updated_at missing (found $MEMBER_VER of 2)"
ASSIGN_VER=$(fx_psql -c "select count(*) from information_schema.columns where table_schema='public' and table_name='driver_assignments' and column_name='version'")
[[ "$ASSIGN_VER" == "1" ]] || fx_die "driver_assignments.version missing"
# Catalogue/store contract columns (nullable additive)
COL_PROBE=$(fx_psql -c "select count(*) from information_schema.columns where table_schema='public' and ((table_name='products' and column_name='selling_unit_code') or (table_name='merchant_branches' and column_name in ('description','name_ar','public_email')) or (table_name='support_tickets' and column_name in ('topic_code','subject')))")
[[ "$COL_PROBE" == "6" ]] || fx_die "catalogue/store columns missing (found $COL_PROBE of 6)"
# Daily-summary / cancel reasonCode (nullable additive)
REASON_COL=$(fx_psql -c "select count(*) from information_schema.columns where table_schema='public' and table_name='order_cancellations' and column_name='reason_code'")
[[ "$REASON_COL" == "1" ]] || fx_die "order_cancellations.reason_code missing"
fx_psql -f "$HERE/fx_seed.sql" | tee "$FX_HOME/logs/seed.log"

# --- API build and environment -----------------------------------------------
(
  cd "$FX_BACKEND"
  pnpm exec tsc -p tsconfig.build.json --outDir "$FX_HOME/dist" --tsBuildInfoFile "$FX_HOME/dist/.tsbuildinfo"
) > "$FX_HOME/logs/build.log" 2>&1 || fx_die "backend compile failed (see $FX_HOME/logs/build.log)"
[[ -f "$FX_HOME/dist/src/main.js" ]] || fx_die "compiled entry point missing"
ln -s "$FX_BACKEND/node_modules" "$FX_HOME/node_modules"

umask 077
{
  cat <<ENV
NODE_ENV=development
PORT=$FX_API_PORT
API_GLOBAL_PREFIX=api/v1
CORS_ALLOWED_ORIGINS=http://127.0.0.1:5173
DATABASE_URL=$FX_DB_URL
SPEEDYGO_POSTGRES_HOST_PORT=5433
REDIS_URL=$FX_REDIS_URL
SPEEDYGO_REDIS_HOST_PORT=6381
JWT_ACCESS_SECRET=$(openssl rand -hex 32)
JWT_ACCESS_TTL_SECONDS=900
AUTH_SESSION_TTL_DAYS=1
OTP_HMAC_SECRET=$(openssl rand -hex 32)
OTP_TTL_SECONDS=300
OTP_MAX_ATTEMPTS=5
OTP_RESEND_COOLDOWN_SECONDS=60
OTP_MAX_REQUESTS_PER_HOUR=5
OTP_MAX_REQUESTS_PER_IP_PER_HOUR=20
AUTH_DEFAULT_COUNTRY=DZ
OTP_TRANSPORT=console
SPEEDYGO_DEV_OTP_DIR=$FX_HOME/otp
AUTH_TRUST_PROXY=false
AUTH_REDIS_PREFIX=auth:parityfx:
MATCHING_OFFER_TIMEOUT_MS=30000
MATCHING_LOCATION_MAX_AGE_MS=45000
MATCHING_PICKUP_RADIUS_METERS=5000
MATCHING_CANDIDATE_LIMIT=20
MATCHING_RETRY_DELAY_MS=15000
MATCHING_RECOVERY_INTERVAL_MS=86400000
MATCHING_RECOVERY_BATCH_SIZE=50
MATCHING_REDIS_PREFIX=matching:parityfx:
MATCHING_BULL_PREFIX=bull:matching:parityfx
NOTIFICATIONS_RECOVERY_INTERVAL_MS=86400000
NOTIFICATIONS_RECOVERY_BATCH_SIZE=50
NOTIFICATIONS_RECOVERY_LOOKBACK_MS=86400000
DRIVER_DELIVERY_PICKUP_RADIUS_METERS=300
DRIVER_DELIVERY_DROPOFF_RADIUS_METERS=300
TRACKING_LOCATION_TTL_MS=600000
TRACKING_STALE_CLEANUP_INTERVAL_MS=86400000
TRACKING_STALE_CLEANUP_MAX_AGE_MS=300000
TRACKING_STALE_CLEANUP_BATCH_SIZE=100
TRACKING_MIN_UPDATE_INTERVAL_MS=1000
TRACKING_AUTH_REVALIDATION_INTERVAL_MS=15000
TRACKING_REDIS_PREFIX=tracking:parityfx:
TRACKING_SOCKET_ADAPTER_PREFIX=socket.io:tracking:parityfx
STORAGE_DRIVER=local
STORAGE_LOCAL_ROOT=$FX_HOME/storage
STORAGE_UPLOADS_ENABLED=true
STORAGE_REDIS_PREFIX=storage:parityfx:
STORAGE_PENDING_UPLOAD_TTL_SECONDS=3600
STORAGE_MALWARE_SCAN_REQUIRED=false
STORAGE_MALWARE_SCANNER_DRIVER=unavailable
STORAGE_CLAMAV_HOST=127.0.0.1
STORAGE_CLAMAV_PORT=3311
STORAGE_CLAMAV_CONNECT_TIMEOUT_MS=3000
STORAGE_CLAMAV_SCAN_TIMEOUT_MS=30000
STORAGE_PENDING_CLEANUP_INTERVAL_MS=86400000
STORAGE_PENDING_CLEANUP_BATCH_SIZE=50
STORAGE_S3_ENDPOINT=
STORAGE_S3_REGION=
STORAGE_S3_BUCKET=
STORAGE_S3_ACCESS_KEY_ID=
STORAGE_S3_SECRET_ACCESS_KEY=
STORAGE_S3_FORCE_PATH_STYLE=true
S3_ENDPOINT=
S3_REGION=
S3_BUCKET=
S3_ACCESS_KEY_ID=
S3_SECRET_ACCESS_KEY=
PUSH_PROVIDER=disabled
FCM_PROJECT_ID=
FCM_SERVICE_ACCOUNT_FILE=
FCM_API_BASE_URL=
PUSH_SEND_MAX_ATTEMPTS=5
PUSH_SEND_BACKOFF_MS=2000
PUSH_REQUEST_TIMEOUT_MS=10000
PUSH_PENDING_SWEEP_MIN_AGE_MS=60000
GOOGLE_MAPS_API_KEY=
PAYMENT_PROVIDER=test
CHARGILY_SECRET_KEY=
CHARGILY_MODE=test
PAYMENT_RETURN_URL=
PAYMENT_CANCEL_URL=
PAYMENT_WEBHOOK_URL=
PAYMENT_TEST_WEBHOOK_SECRET=$(openssl rand -hex 16)
ENV
} > "$FX_HOME/api.env"
chmod 600 "$FX_HOME/api.env"
umask 022

# Every key of the dev .env must be set explicitly, so ConfigModule never
# fills a value (provider key, secret, prefix) from the shared file.
MISSING=$(python3 - "$FX_BACKEND/.env" "$FX_HOME/api.env" <<'PY'
import re, sys
names = lambda p: {m.group(1) for m in re.finditer(r'^\s*(?:export\s+)?([A-Z_][A-Z0-9_]*)\s*=', open(p).read(), re.M)}
print(' '.join(sorted(names(sys.argv[1]) - names(sys.argv[2]))))
PY
)
[[ -z "$MISSING" ]] || fx_die "dev .env keys not set explicitly for the isolated API: $MISSING"

# --- API start ----------------------------------------------------------------
cd "$FX_BACKEND"
REDIS_CLIENTS_BEFORE=$(redis-cli -h 127.0.0.1 -p 6381 CLIENT LIST | python3 -c '
import collections, sys
c = collections.Counter(dict(kv.split("=", 1) for kv in l.split() if "=" in kv).get("db") for l in sys.stdin)
print(" ".join(f"{k}:{v}" for k, v in sorted(c.items())))')
nohup python3 -c 'import os, sys; os.setsid(); os.execvp(sys.argv[1], sys.argv[1:])' \
  env -i PATH="$PATH" HOME="$HOME" LANG=en_US.UTF-8 \
  bash -c 'set -a; . "$1"; set +a; exec node "$2"' fx-api "$FX_HOME/api.env" "$FX_HOME/dist/src/main.js" \
  > "$FX_HOME/logs/api.log" 2>&1 < /dev/null &
API_PID=$!
echo "$API_PID" > "$FX_HOME/api.pid"
cd "$HERE"

for _ in $(seq 1 120); do
  curl -sf "http://127.0.0.1:$FX_API_PORT/health" >/dev/null 2>&1 && break
  kill -0 "$API_PID" 2>/dev/null || fx_die "isolated API exited during boot (see $FX_HOME/logs/api.log)"
  sleep 1
done
curl -sf "http://127.0.0.1:$FX_API_PORT/health" >/dev/null || fx_die "isolated API not healthy on $FX_API_PORT"
fx_is_fx_api "$API_PID" || fx_die "port $FX_API_PORT listener is not the isolated API"

# --- connection isolation -----------------------------------------------------
sleep 2
API_PORTS_PG=$(lsof -nP -a -p "$API_PID" -iTCP:5433 -sTCP:ESTABLISHED -Fn 2>/dev/null | sed -nE 's/^n.*:([0-9]+)->.*/\1/p' | sort -u | tr '\n' ' ')
PG_DBS=$(fx_psql_admin -c "select coalesce(string_agg(distinct datname, ','), '') from pg_stat_activity where client_port in ($(echo "${API_PORTS_PG:-0}" | sed 's/ $//; s/ /,/g'))")
REDIS_CLIENTS_AFTER=$(redis-cli -h 127.0.0.1 -p 6381 CLIENT LIST | python3 -c '
import collections, sys
c = collections.Counter(dict(kv.split("=", 1) for kv in l.split() if "=" in kv).get("db") for l in sys.stdin)
print(" ".join(f"{k}:{v}" for k, v in sorted(c.items())))')
db_clients() { tr ' ' '\n' <<<"$1" | sed -n "s/^$2://p" | head -1; }
FX_CLIENTS=$(db_clients "$REDIS_CLIENTS_AFTER" "$FX_REDIS_INDEX"); FX_CLIENTS=${FX_CLIENTS:-0}
FX_BEFORE=$(db_clients "$REDIS_CLIENTS_BEFORE" "$FX_REDIS_INDEX"); FX_BEFORE=${FX_BEFORE:-0}
FOREIGN_KEYS=$(fx_redis_foreign_keys | wc -l | tr -d ' ')
REDIS_DBS="index $FX_REDIS_INDEX clients $FX_BEFORE -> $FX_CLIENTS; all clients before [$REDIS_CLIENTS_BEFORE] after [$REDIS_CLIENTS_AFTER]; keys without isolated prefix on index $FX_REDIS_INDEX: $FOREIGN_KEYS"
[[ "$FX_BEFORE" == "0" && "$FX_CLIENTS" -gt 0 && "$FOREIGN_KEYS" == "0" ]] || fx_die "Redis isolation not proven ($REDIS_DBS)"
[[ "$PG_DBS" == "$FX_DB_NAME" ]] || fx_die "API Postgres connections not exclusively on $FX_DB_NAME ($PG_DBS)"

python3 - "$EVIDENCE/environment.json" <<PY
import json, sys
json.dump({
  "runId": "$RUN_ID",
  "startedAt": "$START_ISO",
  "database": "$FX_DB_NAME",
  "databaseMarker": "speedygo-parity-fx disposable run=$RUN_ID",
  "postgres": "127.0.0.1/localhost:5433 (native Homebrew)",
  "redis": {"index": $FX_REDIS_INDEX, "port": 6381,
            "prefixes": ["auth:parityfx:", "matching:parityfx:", "bull:matching:parityfx",
                         "tracking:parityfx:", "socket.io:tracking:parityfx", "storage:parityfx:"]},
  "api": {"base": "$FX_API_BASE", "pid": $API_PID, "entry": "~/.speedygo/parity_fx/dist/src/main.js",
          "envMode": "env -i + explicit variable list; every dev .env key overridden"},
  "providers": {"push": "disabled", "payment": "test", "googleMaps": "empty key",
                "otp": "console, capture in ~/.speedygo/parity_fx/otp", "storage": "local, ~/.speedygo/parity_fx/storage",
                "s3": "empty", "chargily": "empty secret", "fcm": "empty"},
  "connections": {"postgresDatabasesOfApiSockets": "$PG_DBS", "apiPostgresClientPorts": "$API_PORTS_PG", "redis": "$REDIS_DBS"},
}, open(sys.argv[1], "w"), indent=2)
PY
redact < "$FX_HOME/logs/migrate.log" > "$EVIDENCE/migrate.log"
redact < "$FX_HOME/logs/verify.log" > "$EVIDENCE/verify.log"
cp "$FX_HOME/logs/seed.log" "$EVIDENCE/seed.log"
trap - ERR
echo "FX_START_OK run=$RUN_ID api=$FX_API_BASE pid=$API_PID postgres=$PG_DBS"
echo "FX_REDIS $REDIS_DBS"
