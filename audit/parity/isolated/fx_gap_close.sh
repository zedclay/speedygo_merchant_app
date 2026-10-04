#!/usr/bin/env bash
# Gap-close runner: dock hide/reveal, empty Catalogue, offline/500/retry.
# Requires fx_start.sh already completed. Does not touch speedygo_dev or :3000.
# Usage: fx_gap_close.sh <udid> <prefix> <content-size>
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/fx_common.sh"
. "$FX_APP/audit/parity/live/disk_preflight.sh"

UDID="$1"
PREFIX="$2"
SIZE="$3"
ALLOWED_UDID=8DB9007A-B816-4EC5-86ED-C627AC60F2C5
BUNDLE=com.speedygo.speedygoMerchantApp
SHOT=/tmp/parity_fx_gap_close_shot.txt
GATE=/tmp/fx_gap_close_gate.txt

[[ "$UDID" == "$ALLOWED_UDID" ]] || fx_die "only the iPhone 16e $ALLOWED_UDID is allowed"
[[ "$PREFIX" =~ ^[a-z0-9_]+$ ]] || fx_die "prefix must be [a-z0-9_]+"
case "$SIZE" in large|extra-extra-extra-large) ;; *) fx_die "unsupported content size $SIZE" ;; esac

require_free_disk "fx-gap:$PREFIX" || exit $?
fx_load_targets
RUN_ID=$(cat "$FX_HOME/run_id" 2>/dev/null) || fx_die "no environment; run fx_start.sh first"
[[ "$(fx_db_marker)" == "speedygo-parity-fx disposable run=$RUN_ID" ]] || fx_die "database marker mismatch"
API_PID=$(fx_api_pid)
fx_is_fx_api "$API_PID" || fx_die "isolated API is not running on $FX_API_PORT"
curl -sf "http://127.0.0.1:$FX_API_PORT/health" >/dev/null || fx_die "isolated API not healthy"
EVIDENCE="$FX_EVIDENCE_ROOT/$RUN_ID"
SCREENS="$EVIDENCE/screens"
mkdir -p "$SCREENS" "$EVIDENCE/gap_close"

# Clear isolated OTP rate-limit / cooldown keys so consecutive gap-close runs can login.
if command -v redis-cli >/dev/null 2>&1; then
  redis-cli -p 6381 -n 9 --scan --pattern 'auth:parityfx:*' 2>/dev/null \
    | while read -r k; do redis-cli -p 6381 -n 9 DEL "$k" >/dev/null; done || true
fi

# Seed extras once per environment.
SEED_FLAG="$FX_HOME/gap_close_seeded"
if [[ ! -f "$SEED_FLAG" ]]; then
  fx_psql -f "$HERE/fx_gap_close_seed.sql" | tee "$EVIDENCE/gap_close/seed.log"
  touch "$SEED_FLAG"
  # Track additive IDs for cleanup evidence
  fx_psql -c "
    select json_build_object(
      'extraProducts', (select count(*) from products where id::text like '0d00f0f0-fa00-7000-8000-0000000090%'),
      'emptyMerchant', '0d00f0f0-fa00-7000-8000-000000001003',
      'emptyBranch', '0d00f0f0-fa00-7000-8000-000000002003',
      'emptyOwner', '0d00f0f0-fa00-7000-8000-000000000105'
    )" > "$EVIDENCE/gap_close/seed_ids.json"
fi

# Empty Catalogue API proof (HTTP 200, zero products) against isolated :3100 only.
python3 - "$FX_API_BASE" "$FX_OTP_FILE" "$EVIDENCE/gap_close/empty_catalogue_api_${PREFIX}.json" <<'PY'
import json, time, pathlib, urllib.request, urllib.error, sys
base, otp_path, out_path = sys.argv[1], pathlib.Path(sys.argv[2]), pathlib.Path(sys.argv[3])
mid = "0d00f0f0-fa00-7000-8000-000000001003"
bid = "0d00f0f0-fa00-7000-8000-000000002003"
phone = "+213550009105"

def req(method, path, data=None, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    body = None if data is None else json.dumps(data).encode()
    r = urllib.request.Request(base + path, data=body, method=method, headers=headers)
    try:
        with urllib.request.urlopen(r, timeout=30) as resp:
            raw = resp.read()
            return resp.status, json.loads(raw) if raw else {}, dict(resp.headers)
    except urllib.error.HTTPError as e:
        raw = e.read()
        try:
            j = json.loads(raw)
        except Exception:
            j = {"raw": raw.decode("utf-8", "replace")[:400]}
        return e.code, j, {}

before = time.time() - 1
s, body, _ = req("POST", "/auth/otp/request", {
    "channel": "PHONE", "identifier": phone, "purpose": "AUTHENTICATE"
})
if s not in (200, 201, 202):
    raise SystemExit(f"otp request failed {s} {body}")
otp = None
for _ in range(80):
    if otp_path.exists() and otp_path.stat().st_mtime >= before:
        t = otp_path.read_text().strip()
        if t.isdigit():
            otp = t
            break
    time.sleep(0.25)
if not otp:
    raise SystemExit("otp missing")
s, body, _ = req("POST", "/auth/otp/verify", {
    "channel": "PHONE", "identifier": phone, "purpose": "AUTHENTICATE", "code": otp,
    "platform": "ios", "appVersion": "1.0.0", "deviceName": "parity-fx-gap-empty-api"
})
if s not in (200, 201):
    raise SystemExit(f"otp verify failed {s} {body}")
token = body["accessToken"]
s, body, _ = req("GET", f"/merchant/{mid}/products?branchId={bid}&limit=50", token=token)
items = body.get("items") or body.get("data") or body.get("products") or []
if isinstance(body, list):
    items = body
proof = {
    "endpoint": f"GET /merchant/{mid}/products?branchId={bid}",
    "httpStatus": s,
    "productCount": len(items) if isinstance(items, list) else None,
    "bodyKeys": sorted(body.keys()) if isinstance(body, dict) else type(body).__name__,
    "label": "isolated empty Catalogue API proof — not a native offline gate",
}
out_path.write_text(json.dumps(proof, indent=2) + "\n")
print(json.dumps(proof))
if s != 200:
    raise SystemExit(f"expected HTTP 200, got {s}")
if proof["productCount"] not in (0,):
    raise SystemExit(f"expected 0 products, got {proof['productCount']} body={str(body)[:400]}")
PY

# Clear OTP keys again so the Flutter run can login (API proof consumed one request).
if command -v redis-cli >/dev/null 2>&1; then
  redis-cli -p 6381 -n 9 --scan --pattern 'auth:parityfx:*' 2>/dev/null \
    | while read -r k; do redis-cli -p 6381 -n 9 DEL "$k" >/dev/null; done || true
fi

: > "$SHOT"
: > "$GATE"
PREVIOUS_SIZE=$(xcrun simctl ui "$UDID" content_size)
xcrun simctl ui "$UDID" content_size "$SIZE"
restore_size() { xcrun simctl ui "$UDID" content_size "$PREVIOUS_SIZE" || true; }
trap restore_size EXIT

restart_fx_api() {
  local old
  old=$(cat "$FX_HOME/api.pid" 2>/dev/null || true)
  if [[ -n "$old" ]] && kill -0 "$old" 2>/dev/null; then
    kill "$old" 2>/dev/null || true
    sleep 1
    kill -9 "$old" 2>/dev/null || true
  fi
  # Also clear any stub on 3100
  for p in $(lsof -nP -tiTCP:$FX_API_PORT -sTCP:LISTEN 2>/dev/null || true); do
    kill "$p" 2>/dev/null || true
  done
  sleep 1
  cd "$FX_BACKEND"
  nohup python3 -c 'import os, sys; os.setsid(); os.execvp(sys.argv[1], sys.argv[1:])' \
    env -i PATH="$PATH" HOME="$HOME" LANG=en_US.UTF-8 \
    bash -c 'set -a; . "$1"; set +a; exec node "$2"' fx-api "$FX_HOME/api.env" "$FX_HOME/dist/src/main.js" \
    > "$FX_HOME/logs/api.log" 2>&1 < /dev/null &
  echo $! > "$FX_HOME/api.pid"
  cd "$HERE"
  for _ in $(seq 1 90); do
    curl -sf "http://127.0.0.1:$FX_API_PORT/health" >/dev/null 2>&1 && return 0
    sleep 1
  done
  fx_die "failed to restore isolated API on $FX_API_PORT"
}

start_500_stub() {
  local old
  old=$(cat "$FX_HOME/api.pid" 2>/dev/null || true)
  if [[ -n "$old" ]] && kill -0 "$old" 2>/dev/null; then
    kill "$old" 2>/dev/null || true
    sleep 1
    kill -9 "$old" 2>/dev/null || true
  fi
  for p in $(lsof -nP -tiTCP:$FX_API_PORT -sTCP:LISTEN 2>/dev/null || true); do
    kill "$p" 2>/dev/null || true
  done
  sleep 1
  # Deterministic HTTP 500 stub on the same port (not a native network disconnect).
  nohup python3 - "$FX_API_PORT" > "$FX_HOME/logs/stub500.log" 2>&1 < /dev/null &
  echo $! > "$FX_HOME/stub500.pid"
  python3 - "$FX_API_PORT" <<'PY' &
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
port = int(sys.argv[1])
class H(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith('/health'):
            self.send_response(200); self.end_headers(); self.wfile.write(b'ok'); return
        if '/catalog' in self.path or '/categories' in self.path or '/products' in self.path:
            body = b'{"error":{"code":"INTERNAL","message":"controlled stub 500"}}'
            self.send_response(500); self.send_header('Content-Type','application/json')
            self.send_header('Content-Length', str(len(body))); self.end_headers(); self.wfile.write(body)
            return
        self.send_response(500); self.end_headers()
    def do_POST(self):
        # Allow OTP so a cold launch could still work; catalogue GETs are the target.
        length = int(self.headers.get('Content-Length') or 0)
        _ = self.rfile.read(length)
        if '/auth/otp' in self.path:
            body = b'{"ok":true}'
            self.send_response(200); self.send_header('Content-Type','application/json')
            self.send_header('Content-Length', str(len(body))); self.end_headers(); self.wfile.write(body)
            return
        self.send_response(500); self.end_headers()
    def log_message(self, *a): pass
HTTPServer(('127.0.0.1', port), H).serve_forever()
PY
  echo $! > "$FX_HOME/stub500.pid"
  sleep 1
}

watch_shots_and_gate() {
  local last="" last_gate="" tag cmd old stub
  while true; do
    tag=$(tail -1 "$SHOT" 2>/dev/null | tr -d '\n' || true)
    if [[ -n "$tag" && "$tag" != "$last" ]]; then
      [[ "$tag" == "${PREFIX}_99_done" ]] && break
      xcrun simctl io "$UDID" screenshot "$SCREENS/${tag}.png" >/dev/null 2>&1 || true
      echo "SHOT $tag"
      last="$tag"
    fi
    cmd=$(tail -1 "$GATE" 2>/dev/null | tr -d '\n' || true)
    if [[ -n "$cmd" && "$cmd" != "$last_gate" ]]; then
      case "$cmd" in
        stop_api)
          echo "GATE stop_api (isolated API unreachable — process stopped, not a native network disconnect)"
          old=$(cat "$FX_HOME/api.pid" 2>/dev/null || true)
          if [[ -n "$old" ]]; then kill "$old" 2>/dev/null || true; sleep 1; kill -9 "$old" 2>/dev/null || true; fi
          for p in $(lsof -nP -tiTCP:$FX_API_PORT -sTCP:LISTEN 2>/dev/null || true); do kill "$p" 2>/dev/null || true; done
          echo "unreachable_ready" > "$GATE"
          last_gate="unreachable_ready"
          ;;
        start_500_stub)
          echo "GATE start_500_stub (controlled HTTP 500 stub on :3100)"
          old=$(cat "$FX_HOME/api.pid" 2>/dev/null || true)
          if [[ -n "$old" ]]; then kill "$old" 2>/dev/null || true; sleep 1; kill -9 "$old" 2>/dev/null || true; fi
          for p in $(lsof -nP -tiTCP:$FX_API_PORT -sTCP:LISTEN 2>/dev/null || true); do kill "$p" 2>/dev/null || true; done
          sleep 1
          nohup python3 -c "
from http.server import BaseHTTPRequestHandler, HTTPServer
class H(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith('/health'):
            self.send_response(200); self.end_headers(); self.wfile.write(b'ok'); return
        body = b'{\"error\":{\"code\":\"INTERNAL\",\"message\":\"controlled stub 500\"}}'
        self.send_response(500); self.send_header('Content-Type','application/json')
        self.send_header('Content-Length', str(len(body))); self.end_headers(); self.wfile.write(body)
    def do_POST(self):
        n=int(self.headers.get('Content-Length') or 0); self.rfile.read(n)
        body=b'{\"ok\":true}'
        self.send_response(200); self.send_header('Content-Type','application/json')
        self.send_header('Content-Length', str(len(body))); self.end_headers(); self.wfile.write(body)
    def log_message(self,*a): pass
HTTPServer(('127.0.0.1', $FX_API_PORT), H).serve_forever()
" > "$FX_HOME/logs/stub500.log" 2>&1 &
          echo $! > "$FX_HOME/stub500.pid"
          sleep 1
          echo "stub500_ready" > "$GATE"
          last_gate="stub500_ready"
          ;;
        restore_api)
          echo "GATE restore_api"
          stub=$(cat "$FX_HOME/stub500.pid" 2>/dev/null || true)
          if [[ -n "$stub" ]]; then kill "$stub" 2>/dev/null || true; sleep 1; kill -9 "$stub" 2>/dev/null || true; fi
          for p in $(lsof -nP -tiTCP:$FX_API_PORT -sTCP:LISTEN 2>/dev/null || true); do kill "$p" 2>/dev/null || true; done
          sleep 1
          restart_fx_api
          echo "api_restored" > "$GATE"
          last_gate="api_restored"
          ;;
        *)
          last_gate="$cmd"
          ;;
      esac
    fi
    sleep 0.25
  done
}

watch_shots_and_gate > "$EVIDENCE/gap_close/shots_${PREFIX}.log" 2>&1 &
WATCH=$!
echo "$WATCH" >> "$FX_HOME/run_pids"

cd "$FX_APP"
set +e
flutter test integration_test/gap_close_fx_live_test.dart \
  -d "$UDID" \
  --dart-define=API_BASE_URL="$FX_API_BASE" \
  --dart-define=FX_OTP_FILE="$FX_OTP_FILE" \
  --dart-define=FX_EVIDENCE_DIR="$EVIDENCE" \
  --dart-define=PARITY_PREFIX="$PREFIX" \
  --dart-define=FX_GAP_GATE="$GATE" \
  --dart-define=FX_GAP_SHOT="$SHOT" \
  2>&1 | tee "$EVIDENCE/gap_close/flutter_${PREFIX}.log"
CODE=${PIPESTATUS[0]}
set -e

echo "${PREFIX}_99_done" >> "$SHOT"
sleep 2
kill "$WATCH" 2>/dev/null || true
wait "$WATCH" 2>/dev/null || true

# Ensure real API is back if a gate left a stub
if ! curl -sf "http://127.0.0.1:$FX_API_PORT/health" >/dev/null 2>&1 || \
   ! fx_is_fx_api "$(fx_api_pid 2>/dev/null || echo 0)" 2>/dev/null; then
  stub=$(cat "$FX_HOME/stub500.pid" 2>/dev/null || true)
  [[ -n "$stub" ]] && kill "$stub" 2>/dev/null || true
  restart_fx_api || true
fi

bash "$HERE/fx_snapshot.sh" "$EVIDENCE/gap_close/isolation_after_${PREFIX}.json" "$(date -u +%FT%TZ)" >/dev/null || true
exit "$CODE"
