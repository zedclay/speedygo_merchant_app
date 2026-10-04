#!/usr/bin/env bash
# Isolated Batch 7 visual/live captures (rows 71–74, 76, 77) on speedygo_parity_fx.
# Requires fx_start.sh. Never touches speedygo_dev or :3000.
#
# Usage: fx_b7_live.sh <simulator-udid> <prefix> <content-size> <phone-local-9>
#   content-size: large (1.0) or extra-extra-extra-large (1.35)
#   phone must have no account yet on the isolated DB.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/fx_common.sh"
. "$FX_APP/audit/parity/live/disk_preflight.sh"

UDID="$1"
PREFIX="$2"
SIZE="$3"
PHONE_LOCAL="$4"
PHONE_E164="+213$PHONE_LOCAL"
ALLOWED_UDID=8DB9007A-B816-4EC5-86ED-C627AC60F2C5
FINJAN_UDID=4A1C3481
BUNDLE=com.speedygo.speedygoMerchantApp
SHOT=/tmp/parity_fx_isolated_shot.txt
ADMIN_PHONE="+213550009819"
ADMIN_ACCOUNT="0d00f0f0-fa00-7000-8000-000000009819"
ADMIN_ROLE="0d00f0f0-fa00-7000-8000-000000009820"
ADMIN_PROFILE="0d00f0f0-fa00-7000-8000-000000009821"
PERM_READ="0d00f0f0-fa00-7000-8000-000000009822"
PERM_VERIFY="0d00f0f0-fa00-7000-8000-000000009823"

[[ "$UDID" != "$FINJAN_UDID"* ]] || fx_die "the Finjan simulator is never used"
[[ "$UDID" == "$ALLOWED_UDID" ]] || fx_die "only the iPhone 16e $ALLOWED_UDID is allowed"
[[ "$PREFIX" =~ ^[a-z0-9_]+$ ]] || fx_die "prefix must be [a-z0-9_]+"
[[ "$PHONE_LOCAL" =~ ^[0-9]{9}$ ]] || fx_die "phone-local must be 9 digits"
case "$SIZE" in large|extra-extra-extra-large) ;; *) fx_die "unsupported content size $SIZE" ;; esac

require_free_disk "fx-b7:$PREFIX" || exit $?
fx_load_targets
RUN_ID=$(cat "$FX_HOME/run_id" 2>/dev/null) || fx_die "no environment; run fx_start.sh first"
[[ "$(fx_db_marker)" == "speedygo-parity-fx disposable run=$RUN_ID" ]] || fx_die "database marker mismatch"
API_PID=$(fx_api_pid)
fx_is_fx_api "$API_PID" || fx_die "isolated API is not running on $FX_API_PORT"
curl -sf "http://127.0.0.1:$FX_API_PORT/health" >/dev/null || fx_die "isolated API not healthy"
EVIDENCE="$FX_EVIDENCE_ROOT/$RUN_ID/b7_visual"
SCREENS="$EVIDENCE/screens"
mkdir -p "$SCREENS" "$EVIDENCE"

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

# Clear OTP cooldown keys between phases / sizes.
clear_otp_keys() {
  redis-cli -p 6381 -n 9 --scan --pattern 'auth:parityfx:*' 2>/dev/null \
    | while read -r k; do redis-cli -p 6381 -n 9 DEL "$k" >/dev/null; done || true
}

seed_admin() {
  bash "$HERE/fx_sql.sh" <<SQL
DO \$\$
BEGIN
  IF current_database() <> 'speedygo_parity_fx' OR inet_server_port() <> 5433 THEN
    RAISE EXCEPTION 'refused: expected speedygo_parity_fx on 5433';
  END IF;
END \$\$;
INSERT INTO accounts (id, phone, email, status)
VALUES ('$ADMIN_ACCOUNT', '$ADMIN_PHONE', NULL, 'ACTIVE')
ON CONFLICT (id) DO NOTHING;
INSERT INTO roles (id, name, description, active)
VALUES ('$ADMIN_ROLE', 'parity-fx-b7-admin',
        'Disposable: merchants.read + merchants.verify', TRUE)
ON CONFLICT (id) DO NOTHING;
INSERT INTO permissions (id, code, description) VALUES
  ('$PERM_READ', 'merchants.read', 'fx b7 visual'),
  ('$PERM_VERIFY', 'merchants.verify', 'fx b7 visual')
ON CONFLICT (code) DO NOTHING;
INSERT INTO role_permissions (role_id, permission_id)
SELECT '$ADMIN_ROLE', p.id FROM permissions p
WHERE p.code IN ('merchants.read', 'merchants.verify')
ON CONFLICT DO NOTHING;
INSERT INTO admin_profiles (id, account_id, role_id, display_name, two_factor_enabled)
VALUES ('$ADMIN_PROFILE', '$ADMIN_ACCOUNT', '$ADMIN_ROLE',
        'Parity FX B7 Admin', FALSE)
ON CONFLICT (id) DO NOTHING;
SQL
}

admin_reject() {
  local merchant_id="$1"
  python3 - "$FX_API_BASE" "$FX_OTP_FILE" "$ADMIN_PHONE" "$merchant_id" "$EVIDENCE/admin_reject_${PREFIX}.json" <<'PY'
import json, sys, time, pathlib, urllib.request, urllib.error
base, otp_path, phone, mid, out = sys.argv[1], pathlib.Path(sys.argv[2]), sys.argv[3], sys.argv[4], pathlib.Path(sys.argv[5])

def req(method, path, data=None, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    body = None if data is None else json.dumps(data).encode()
    r = urllib.request.Request(base + path, data=body, method=method, headers=headers)
    try:
        with urllib.request.urlopen(r, timeout=60) as resp:
            raw = resp.read()
            return resp.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raw = e.read()
        try:
            return e.code, json.loads(raw)
        except Exception:
            return e.code, {"raw": raw.decode("utf-8", "replace")[:400]}

before = time.time() - 1
s, body = req("POST", "/auth/otp/request", {
    "channel": "PHONE", "identifier": phone, "purpose": "AUTHENTICATE"
})
if s not in (200, 201, 202):
    raise SystemExit(f"admin otp request failed {s}")
otp = None
for _ in range(80):
    if otp_path.exists() and otp_path.stat().st_mtime >= before:
        t = otp_path.read_text().strip()
        if t.isdigit():
            otp = t
            break
    time.sleep(0.25)
if not otp:
    raise SystemExit("admin otp missing")
s, body = req("POST", "/auth/otp/verify", {
    "channel": "PHONE", "identifier": phone, "purpose": "AUTHENTICATE",
    "code": otp, "platform": "ios", "appVersion": "1.0.0",
    "deviceName": "parity-fx-b7-admin",
})
if s not in (200, 201):
    raise SystemExit(f"admin otp verify failed {s}")
token = body["accessToken"]
issues = [
    {"scope": "APPLICATION", "code": "PROFILE_INCOMPLETE",
     "messageFr": "Complétez le nom commercial."},
    {"scope": "DOCUMENT", "code": "DOCUMENT_ILLEGIBLE",
     "messageFr": "Pièce d’identité illisible.",
     "documentType": "BUSINESS_IDENTITY"},
]
s, rejected = req("POST", f"/admin/merchants/{mid}/verification/reject",
                  {"issues": issues}, token=token)
req("POST", "/auth/logout", {}, token=token)
proof = {
    "httpStatus": s,
    "merchantStatus": rejected.get("status"),
    "issueScopes": [i["scope"] for i in issues],
    "merchantId": mid,
}
out.write_text(json.dumps(proof, indent=2) + "\n")
print(json.dumps(proof))
if s not in (200, 201) or rejected.get("status") != "REJECTED":
    raise SystemExit(f"admin reject failed {proof}")
PY
}

record_ids() {
  fx_psql -c "
    select json_build_object(
      'phone', '$PHONE_E164',
      'accountId', a.id,
      'merchantId', m.id,
      'merchantStatus', m.status,
      'publicReference', m.public_reference,
      'branchIds', (select json_agg(b.id) from merchant_branches b where b.merchant_id = m.id)
    )
    from accounts a
    join merchant_members mm on mm.account_id = a.id
    join merchants m on m.id = mm.merchant_id
    where a.phone = '$PHONE_E164'" > "$EVIDENCE/FIXTURE_IDS_${PREFIX}.json"
  cat "$EVIDENCE/FIXTURE_IDS_${PREFIX}.json"
}

verify_bundle() {
  local app id running
  app=$(xcrun simctl get_app_container "$UDID" "$BUNDLE" app 2>/dev/null || true)
  id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Info.plist" 2>/dev/null || echo missing)
  running=$(xcrun simctl spawn "$UDID" launchctl list 2>/dev/null | grep -c "UIKitApplication:$BUNDLE" || true)
  printf 'bundleId=%s\nrunningProcesses=%s\ncontentSize=%s\nudid=%s\napiBase=%s\nat=%s\n' \
    "$id" "$running" "$SIZE" "$UDID" "$FX_API_BASE" "$(date -u +%FT%TZ)" \
    > "$EVIDENCE/BUNDLE_${PREFIX}.txt"
  [[ "$id" == "$BUNDLE" && "$running" -ge 1 ]]
}

run_phase() {
  local phase="$1"
  require_free_disk "fx-b7-$phase:$PREFIX" || exit $?
  clear_otp_keys
  : > "$SHOT"
  (
    last="" verified=0
    while true; do
      tag=$(tail -1 "$SHOT" 2>/dev/null | tr -d '\n' || true)
      if [[ -n "$tag" && "$tag" != "$last" ]]; then
        if [[ $verified -eq 0 ]]; then
          if verify_bundle; then verified=1; echo BUNDLE_OK; else echo BUNDLE_MISMATCH; break; fi
        fi
        [[ "$tag" == "${PREFIX}_99_done" ]] && break
        xcrun simctl io "$UDID" screenshot "$SCREENS/${tag}.png" >/dev/null 2>&1 || true
        echo "SHOT $tag $(stat -f%z "$SCREENS/${tag}.png" 2>/dev/null || echo 0)"
        last="$tag"
      fi
      sleep 0.3
    done
  ) > "$EVIDENCE/shots_${PREFIX}_$phase.log" 2>&1 &
  local watch=$!
  echo "$watch" >> "$FX_HOME/run_pids"
  set +e
  (cd "$FX_APP" && flutter test integration_test/parity_b7_fx_live_capture_test.dart \
    -d "$UDID" \
    --dart-define=API_BASE_URL="$FX_API_BASE" \
    --dart-define=FX_OTP_FILE="$FX_OTP_FILE" \
    --dart-define=FX_EVIDENCE_DIR="$EVIDENCE" \
    --dart-define=ACCEPTANCE_EVIDENCE_PICKER=true \
    --dart-define=B7_PHONE="$PHONE_LOCAL" \
    --dart-define=B7_PHASE="$phase" \
    --dart-define=PARITY_PREFIX="$PREFIX" \
    --dart-define=B7_MERCHANT_NAME="Parité B7 Isolé" \
    > "$EVIDENCE/flutter_${PREFIX}_$phase.log" 2>&1)
  local rc=$?
  set -e
  sleep 2
  kill "$watch" 2>/dev/null || true
  wait "$watch" 2>/dev/null || true
  xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
  sed -E 's/[0-9]{6}/<masked>/g' -i '' "$EVIDENCE/flutter_${PREFIX}_$phase.log" 2>/dev/null || true
  cat "$EVIDENCE/shots_${PREFIX}_$phase.log"
  echo "PHASE $phase exit=$rc"
  return $rc
}

# Refuse if phone already registered on the isolated DB.
EXISTING=$(fx_psql -c "select count(*) from accounts where phone = '$PHONE_E164'")
[[ "$EXISTING" == "0" ]] || fx_die "fixture phone already has an account on isolated DB"

PREVIOUS_SIZE=$(xcrun simctl ui "$UDID" content_size)
xcrun simctl ui "$UDID" content_size "$SIZE"
restore_size() { xcrun simctl ui "$UDID" content_size "$PREVIOUS_SIZE" || true; }
trap restore_size EXIT

# Algeria catalogue required for wilaya/commune pickers (not in prisma migrations).
python3 "$HERE/fx_geo_seed.py" "$HERE/fx_sql.sh" "$EVIDENCE/geo_seed.json"

seed_admin
clear_otp_keys
run_phase register
record_ids
MERCHANT_ID=$(python3 -c "import json;print(json.load(open('$EVIDENCE/FIXTURE_IDS_${PREFIX}.json'))['merchantId'])")
clear_otp_keys
admin_reject "$MERCHANT_ID"
clear_otp_keys
run_phase rejected

# Copy primary screens into the live/ folder for compose_live --set fxb7
LIVE="$FX_APP/audit/parity/live"
mkdir -p "$LIVE"
for tag in b7_registration b7_documents b7_review b7_pending b7_rejected b7_resubmission \
           b7_pending_cold b7_documents_correction b7_pending_after_resubmit; do
  src="$SCREENS/${PREFIX}_${tag}.png"
  [[ -f "$src" ]] && cp "$src" "$LIVE/${PREFIX}_${tag}.png"
done

bash "$HERE/fx_snapshot.sh" "$EVIDENCE/isolation_after_${PREFIX}.json" "$(cat "$FX_EVIDENCE_ROOT/$RUN_ID/started_at")" >/dev/null
echo "FX_B7_LIVE prefix=$PREFIX size=$SIZE phone=$PHONE_LOCAL done"
