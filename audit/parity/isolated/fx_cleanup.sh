#!/usr/bin/env bash
# Tears down the disposable Merchant write-test environment, in this order:
#   1. copy evidence (pre-cleanup snapshot, masked API log summary);
#   2. stop the isolated API (only the recorded PID, only if it is the
#      ~/.speedygo/parity_fx build listening on 3100); its BullMQ workers run
#      in-process, so no Redis client may remain on index 9 afterwards;
#   3. end only processes recorded by fx_run.sh, and shut down the simulator
#      only if fx_run.sh booted it;
#   4. FLUSHDB on Redis index 9 only, refused if any key lacks an isolated
#      prefix;
#   5. DROP DATABASE speedygo_parity_fx only after the exact-name, host/port
#      and disposable-marker guards;
#   6. compare speedygo_dev and Redis 0/15 with the baseline from fx_start.sh;
#   7. remove ~/.speedygo/parity_fx (this environment's own files only).
# Safe to re-run on a partial environment.
# Usage: fx_cleanup.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/fx_common.sh"
fx_load_targets

RUN_ID=$(cat "$FX_HOME/run_id" 2>/dev/null || echo "fxenv_unknown_$(date -u +%Y%m%dT%H%M%SZ)")
EVIDENCE="$FX_EVIDENCE_ROOT/$RUN_ID"
mkdir -p "$EVIDENCE"
LOG="$EVIDENCE/cleanup.log"
: > "$LOG"
say() { echo "$*" | tee -a "$LOG"; }
SINCE=$(cat "$EVIDENCE/started_at" 2>/dev/null || true)
[[ -n "$SINCE" ]] || fx_die "no started_at for $RUN_ID; refusing to compare against an unknown baseline"

# 1. evidence ------------------------------------------------------------------
bash "$HERE/fx_snapshot.sh" "$EVIDENCE/isolation_pre_cleanup.json" \
  "$SINCE" >/dev/null \
  && say "evidence: isolation_pre_cleanup.json"
if fx_db_exists; then
  fx_psql -c "select json_build_object(
    'orders', (select coalesce(json_agg(id), '[]') from orders),
    'notifications', (select coalesce(json_agg(id), '[]') from notifications),
    'sessions', (select coalesce(json_agg(id), '[]') from sessions),
    'deliveries', (select coalesce(json_agg(id), '[]') from deliveries),
    'accounts', (select coalesce(json_agg(id), '[]') from accounts))" > "$EVIDENCE/fx_row_ids.json"
  say "evidence: fx_row_ids.json (row IDs of the isolated database)"
fi
if [[ -f "$FX_HOME/logs/api.log" ]]; then
  python3 - "$FX_HOME/logs/api.log" "$EVIDENCE/api_log_summary.txt" <<'PY'
import re, sys
lines = open(sys.argv[1], errors='replace').read().splitlines()
mask = lambda s: re.sub(r'\b\d{4,8}\b', '<n>', re.sub(r'(postgres(ql)?|redis)://\S+', '<url>', s))
keep = [l for l in lines if re.search(r'(ERROR|WARN|listening|Nest application|Mapped \{/health)', l)
        and not re.search(r'otp|code', l, re.I)]
with open(sys.argv[2], 'w') as f:
    f.write(f'total_lines={len(lines)} error_lines={sum("ERROR" in l for l in lines)} '
            f'warn_lines={sum("WARN" in l for l in lines)}\n')
    f.write('\n'.join(mask(l) for l in keep[:200]) + '\n')
PY
  say "evidence: api_log_summary.txt (masked; OTP lines excluded)"
fi

# 2. API -------------------------------------------------------------------------
API_PID=$(fx_api_pid || true)
if [[ -n "${API_PID:-}" ]] && kill -0 "$API_PID" 2>/dev/null; then
  if fx_is_fx_api "$API_PID"; then
    kill -TERM "$API_PID"
    for _ in $(seq 1 30); do kill -0 "$API_PID" 2>/dev/null || break; sleep 1; done
    if kill -0 "$API_PID" 2>/dev/null; then kill -KILL "$API_PID"; sleep 1; fi
    say "api: stopped pid $API_PID"
  else
    say "api: pid $API_PID is not the isolated API; not touched"
  fi
else
  say "api: not running"
fi
LISTENER=$(lsof -nP -tiTCP:$FX_API_PORT -sTCP:LISTEN 2>/dev/null || true)
[[ -z "$LISTENER" ]] && say "api: port $FX_API_PORT free" || say "api: port $FX_API_PORT held by pid $LISTENER (not ours, not touched)"
for _ in $(seq 1 15); do
  CLIENTS=$(redis-cli -h 127.0.0.1 -p 6381 CLIENT LIST | grep -c " db=$FX_REDIS_INDEX " || true)
  [[ "$CLIENTS" == "0" ]] && break
  sleep 1
done
say "workers: redis clients left on index $FX_REDIS_INDEX = $CLIENTS"

# 3. this run's processes -------------------------------------------------------
if [[ -f "$FX_HOME/run_pids" ]]; then
  while read -r pid; do
    [[ "$pid" =~ ^[0-9]+$ ]] || continue
    cmd=$(ps -o command= -p "$pid" 2>/dev/null || true)
    if [[ -n "$cmd" && ( "$cmd" == *parity_isolated_fx_live_test* || "$cmd" == *fx_run.sh* ) ]]; then
      kill -TERM "$pid" 2>/dev/null || true
      say "process: ended $pid"
    fi
  done < "$FX_HOME/run_pids"
fi
if [[ -f "$FX_HOME/booted_simulator" ]]; then
  SIM=$(cat "$FX_HOME/booted_simulator")
  if [[ "$SIM" == 8DB9007A-B816-4EC5-86ED-C627AC60F2C5 ]]; then
    xcrun simctl shutdown "$SIM" 2>/dev/null || true
    say "simulator: shut down $SIM (booted by this environment)"
  fi
else
  say "simulator: not booted by this environment; left as is"
fi

# 4. Redis index 9 --------------------------------------------------------------
FOREIGN=$(fx_redis_foreign_keys | head -5)
if [[ -n "$FOREIGN" ]]; then
  say "redis: index $FX_REDIS_INDEX holds keys without an isolated prefix; FLUSHDB refused"
  REDIS_OK=0
else
  BEFORE=$(fx_redis DBSIZE)
  [[ "$(fx_redis FLUSHDB)" == "OK" ]] || fx_die "FLUSHDB failed"
  say "redis: index $FX_REDIS_INDEX flushed ($BEFORE keys, all isolated); now $(fx_redis DBSIZE)"
  REDIS_OK=1
fi

# 5. database ---------------------------------------------------------------------
if fx_db_exists; then
  python3 "$FX_GUARD" check-name "$FX_DB_NAME" || FX_EXIT=3 fx_die "name guard refused"
  python3 "$FX_GUARD" check-admin-db "$FX_ADMIN_URL" || FX_EXIT=3 fx_die "maintenance URL refused"
  MARKER=$(fx_db_marker)
  [[ "$MARKER" == "speedygo-parity-fx disposable run="* ]] || FX_EXIT=3 fx_die "database lacks the disposable marker; DROP refused"
  [[ "$RUN_ID" == fxenv_unknown_* || "$MARKER" == "speedygo-parity-fx disposable run=$RUN_ID" ]] \
    || FX_EXIT=3 fx_die "marker belongs to another run ($MARKER); DROP refused"
  fx_psql_admin -c "select count(pg_terminate_backend(pid)) from pg_stat_activity where datname = 'speedygo_parity_fx' and pid <> pg_backend_pid()" >/dev/null
  fx_psql_admin -c "DROP DATABASE speedygo_parity_fx"
  fx_db_exists && fx_die "database still present after DROP"
  say "database: speedygo_parity_fx dropped (marker: $MARKER)"
else
  say "database: speedygo_parity_fx absent"
fi

# 6. isolation comparison ---------------------------------------------------------
bash "$HERE/fx_snapshot.sh" "$EVIDENCE/isolation_after_cleanup.json" \
  "$SINCE" >/dev/null
JOBS_FILE="$EVIDENCE/dev_redis_job_scan.json"
python3 - "$EVIDENCE/fx_row_ids.json" "$JOBS_FILE" <<'PY'
import json, subprocess, sys
from pathlib import Path
ids_path, out = Path(sys.argv[1]), Path(sys.argv[2])
ids = set()
if ids_path.exists():
    for values in json.loads(ids_path.read_text()).values():
        ids.update(values)
def rc(db, *args):
    return subprocess.run(['redis-cli', '-h', '127.0.0.1', '-p', '6381', '-n', str(db), *args],
                          capture_output=True, text=True, check=True).stdout
result = {"isolatedRowIds": len(ids), "indexes": {}}
for db in (0, 15):
    keys = [k for k in rc(db, '--scan', '--count', '1000').splitlines() if k]
    hits, hashes = [], 0
    for k in keys:
        if any(i in k for i in ids):
            hits.append(k)
            continue
        if rc(db, 'TYPE', k).strip() == 'hash':
            hashes += 1
            blob = rc(db, 'HGETALL', k)
            if any(i in blob for i in ids):
                hits.append(k)
    result["indexes"][str(db)] = {"keys": len(keys), "hashesScanned": hashes, "keysReferencingIsolatedRows": hits}
out.write_text(json.dumps(result, indent=2) + "\n")
PY
COMPARE_RC=0
python3 - "$EVIDENCE/isolation_before.json" "$EVIDENCE/isolation_after_cleanup.json" "$EVIDENCE/isolation_comparison.json" "$JOBS_FILE" <<'PY' | tee -a "$LOG" || COMPARE_RC=$?
import json, sys
from pathlib import Path
b_path, a_path, out, jobs_path = map(Path, sys.argv[1:])
a = json.loads(a_path.read_text())
checks = []
def check(name, ok, detail):
    checks.append({"check": name, "result": "PASS" if ok else "FAIL", "detail": detail})
if b_path.exists():
    b = json.loads(b_path.read_text())
    bd, ad = b["devDb"], a["devDb"]
    diff = {k: [bd["counts"][k], ad["counts"][k]] for k in bd["counts"] if bd["counts"][k] != ad["counts"].get(k)}
    check("speedygo_dev row counts unchanged", not diff, diff or "all equal")
    check("seven tracked orders unchanged", bd["trackedOrders"] == ad["trackedOrders"], f'{len(ad["trackedOrders"] or [])} rows compared')
    check("late order unchanged", bd["lateOrder"] == ad["lateOrder"], ad["lateOrder"])
    check("shared branch names unchanged", bd["branchNames"] == ad["branchNames"], ad["branchNames"])
    check("Dar El Bahja order states unchanged", bd["darElBahjaOrdersByState"] == ad["darElBahjaOrdersByState"], ad["darElBahjaOrdersByState"])
    jobs = json.loads(jobs_path.read_text())
    refs = {db: v["keysReferencingIsolatedRows"] for db, v in jobs["indexes"].items()}
    check("no dev/e2e Redis job references an isolated row", jobs["isolatedRowIds"] > 0 and not any(refs.values()),
          f'{jobs["isolatedRowIds"]} isolated IDs; hashes scanned 0:{jobs["indexes"]["0"]["hashesScanned"]} 15:{jobs["indexes"]["15"]["hashesScanned"]}; hits {refs}')
    checks.append({"check": "dev BullMQ job counters (informational)", "result": "INFO",
                   "detail": f'before {b["redis"]["devJobCounters"]} after {a["redis"]["devJobCounters"]}; the shared dev API advances these on its own (recovery loops)'})
else:
    check("baseline present", False, "isolation_before.json missing")
ns = ad["fixtureNamespaceInDev"] if b_path.exists() else a["devDb"]["fixtureNamespaceInDev"]
check("no fixture identities in speedygo_dev", all(v == 0 for v in ns.values()), ns)
cs = {k: v for k, v in a["devDb"]["createdSince"].items() if k != "since"}
check("no speedygo_dev rows created or updated since start", all(v == 0 for v in cs.values()), cs)
pk = a["redis"]["parityfxKeys"]
check("no isolated keys on Redis 0 or 15", pk["0"] == 0 and pk["15"] == 0, pk)
check("Redis index 9 empty", a["redis"]["dbsize"]["9"] == 0, a["redis"]["dbsize"])
check("speedygo_parity_fx dropped", a["fxDb"] is None, "absent" if a["fxDb"] is None else "present")
out.write_text(json.dumps(checks, indent=2) + "\n")
for c in checks:
    print(f'{c["result"]}  {c["check"]}: {c["detail"]}')
sys.exit(0 if all(c["result"] in ("PASS", "INFO") for c in checks) else 1)
PY

# 7. private state ------------------------------------------------------------------
if [[ -d "$FX_HOME" && "$FX_HOME" == "$HOME/.speedygo/parity_fx" ]]; then
  [[ -L "$FX_HOME/node_modules" ]] && unlink "$FX_HOME/node_modules"
  for item in dist otp storage logs; do
    [[ -d "$FX_HOME/$item" && ! -L "$FX_HOME/$item" ]] && rm -rf "${FX_HOME:?}/$item"
  done
  rm -f "$FX_HOME/api.env" "$FX_HOME/api.pid" "$FX_HOME/run_pids" "$FX_HOME/booted_simulator" "$FX_HOME/run_id"
  rmdir "$FX_HOME" 2>/dev/null && say "state: ~/.speedygo/parity_fx removed" || say "state: ~/.speedygo/parity_fx not empty; left for inspection"
fi

if [[ $COMPARE_RC -eq 0 && ${REDIS_OK:-0} -eq 1 ]]; then
  say "FX_CLEANUP_OK run=$RUN_ID"
else
  say "FX_CLEANUP_INCOMPLETE run=$RUN_ID compare=$COMPARE_RC redis=${REDIS_OK:-0}"
  exit 1
fi
