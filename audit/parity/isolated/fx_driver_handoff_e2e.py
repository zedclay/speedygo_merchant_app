#!/usr/bin/env python3
"""Isolated API e2e for Merchant assigned-driver + pickup handoff (rows 21, 23).

Uses authenticated fixture Merchants and Drivers against :3100 / Redis 9.
Never prints tokens, OTPs or plaintext pickup codes.
Driver confirm-pickup is API-fixture evidence only — not Driver UI proof.

Usage: fx_driver_handoff_e2e.py <out-dir> <fx_sql.sh>
"""
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

BASE = 'http://127.0.0.1:3100/api/v1'
OTP = Path.home() / '.speedygo' / 'parity_fx' / 'otp' / 'otp-last'
NS = '0d00f0f0-fa00-7000-8000-'
MERCHANT = NS + '000000001001'
BRANCH = NS + '000000002001'
FOREIGN_MERCHANT = NS + '000000001002'
OWNER = '+213550009101'
MANAGER = '+213550009102'
STAFF = '+213550009103'
DRIVER_A_PHONE = '+213550009131'
DRIVER_B_PHONE = '+213550009132'
DRIVER_A_ACCT = NS + '000000000131'
DRIVER_B_ACCT = NS + '000000000132'
DRIVER_A_ID = NS + '000000009131'
DRIVER_B_ID = NS + '000000009132'
VEHICLE_A = NS + '000000009231'
VEHICLE_B = NS + '000000009232'

OUT = Path(sys.argv[1])
FX_SQL = sys.argv[2]
RESULTS = []
TOKENS = {}
SECRETS = {}


def record(cid, name, ok, detail=''):
    RESULTS.append({
        'id': cid, 'check': name,
        'result': 'PASS' if ok else 'FAIL', 'detail': detail,
    })
    safe = detail
    for secret in SECRETS.values():
        if secret and secret in safe:
            safe = safe.replace(secret, '<code>')
    print(f'{"PASS" if ok else "FAIL"}  {cid} {name} {safe}'[:400])


def req(method, path, token=None, data=None, timeout=60):
    h = {}
    if token:
        h['Authorization'] = f'Bearer {token}'
    body = None
    if data is not None:
        body = json.dumps(data).encode()
        h['Content-Type'] = 'application/json'
    r = urllib.request.Request(BASE + path, data=body, headers=h, method=method)
    try:
        with urllib.request.urlopen(r, timeout=timeout) as res:
            return res.status, res.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()


def jreq(method, path, token=None, data=None):
    s, b = req(method, path, token, data)
    try:
        return s, json.loads(b.decode() or '{}')
    except ValueError:
        return s, {}


def code_of(body):
    if isinstance(body, dict):
        err = body.get('error')
        if isinstance(err, dict):
            return err.get('code')
        return body.get('code')
    return None


def sql(statement):
    p = subprocess.run(
        ['bash', FX_SQL], input=statement, capture_output=True, text=True,
    )
    if p.returncode != 0:
        raise RuntimeError(f'fx_sql failed: {p.stderr.strip()[:300]}')
    return p.stdout.strip()


def clear_otp_keys():
    subprocess.run(
        [
            'bash', '-c',
            "redis-cli -p 6381 -n 9 --scan --pattern 'auth:parityfx:*' "
            "| while read -r k; do redis-cli -p 6381 -n 9 DEL \"$k\" >/dev/null; done",
        ],
        capture_output=True, text=True, check=False,
    )


def login(phone, label):
    clear_otp_keys()
    time.sleep(0.2)
    before = time.time() - 1
    s, body = jreq('POST', '/auth/otp/request', data={
        'channel': 'PHONE', 'identifier': phone, 'purpose': 'AUTHENTICATE',
    })
    if s not in (200, 201, 202):
        raise SystemExit(f'otp request {label} http={s}')
    otp = None
    for _ in range(80):
        if OTP.exists() and OTP.stat().st_mtime >= before:
            otp = OTP.read_text().strip()
            if otp.isdigit():
                break
        time.sleep(0.25)
    if not otp:
        raise SystemExit(f'OTP missing for {label}')
    s, body = jreq('POST', '/auth/otp/verify', data={
        'channel': 'PHONE', 'identifier': phone, 'purpose': 'AUTHENTICATE',
        'code': otp, 'platform': 'ios', 'appVersion': '1.0.0',
        'deviceName': f'parity-fx-handoff-{label}',
    })
    if s not in (200, 201):
        raise SystemExit(f'otp verify {label} http={s}')
    TOKENS[label] = body['accessToken']
    return body['accessToken']


def place_incoming(tag='a'):
    clear_otp_keys()
    time.sleep(0.3)
    script = Path(__file__).resolve().parent / 'fx_create_incoming.py'
    out = OUT / f'incoming_{tag}.json'
    p = subprocess.run(
        ['python3', str(script), str(out), '1'],
        capture_output=True, text=True,
    )
    if p.returncode != 0:
        raise RuntimeError(
            f'create incoming failed: {(p.stderr or p.stdout)[:400]}',
        )
    return json.loads(out.read_text())['orders'][0]['id']


def merchant_ready(order_id, token):
    s, body = jreq(
        'POST', f'/merchant/{MERCHANT}/orders/{order_id}/accept',
        token=token, data={'preparationMinutes': 20},
    )
    if s not in (200, 201):
        raise RuntimeError(f'accept failed http={s} code={code_of(body)}')
    s, body = jreq(
        'POST', f'/merchant/{MERCHANT}/orders/{order_id}/start-preparation',
        token=token, data={},
    )
    if s not in (200, 201):
        raise RuntimeError(f'start-prep failed http={s} code={code_of(body)}')
    s, body = jreq(
        'POST', f'/merchant/{MERCHANT}/orders/{order_id}/mark-ready',
        token=token, data={},
    )
    if s not in (200, 201):
        raise RuntimeError(f'mark-ready failed http={s} code={code_of(body)}')
    return body


def seed_drivers():
    sql(f"""
INSERT INTO accounts (id, phone, email, status)
VALUES
  ('{DRIVER_A_ACCT}', '{DRIVER_A_PHONE}', NULL, 'ACTIVE'),
  ('{DRIVER_B_ACCT}', '{DRIVER_B_PHONE}', NULL, 'ACTIVE')
ON CONFLICT (id) DO NOTHING;
INSERT INTO driver_profiles (id, account_id, full_name, verification_status, approved_at)
VALUES
  ('{DRIVER_A_ID}', '{DRIVER_A_ACCT}', 'Yacine Mansouri', 'APPROVED', now()),
  ('{DRIVER_B_ID}', '{DRIVER_B_ACCT}', 'Karim Bensaid', 'APPROVED', now())
ON CONFLICT (id) DO NOTHING;
INSERT INTO driver_availability (driver_id, status, offline_after_current_delivery, updated_at)
VALUES
  ('{DRIVER_A_ID}', 'ONLINE', false, now()),
  ('{DRIVER_B_ID}', 'ONLINE', false, now())
ON CONFLICT (driver_id) DO UPDATE SET status = EXCLUDED.status, updated_at = now();
INSERT INTO vehicles (id, driver_id, type, plate_number, model, color, status)
VALUES
  ('{VEHICLE_A}', '{DRIVER_A_ID}', 'Moto', '16-12345', 'Fixture Moto A', 'Noir', 'ACTIVE'),
  ('{VEHICLE_B}', '{DRIVER_B_ID}', 'Voiture', '16-54321', 'Fixture Car B', 'Blanc', 'ACTIVE')
ON CONFLICT (id) DO NOTHING;
""")


def _fx_uuid(tag: str) -> str:
    return NS + hashlib.sha1(tag.encode()).hexdigest()[:12]


def attach_assignment(order_id, driver_id, status='TO_PICKUP', arrived=False):
    """Create/replace Delivery + open ACCEPTED assignment in the requested status."""
    delivery_id = sql(
        f"SELECT id FROM deliveries WHERE order_id = '{order_id}'",
    )
    if not delivery_id:
        delivery_id = _fx_uuid(f'delivery:{order_id}')
        sql(f"""
INSERT INTO deliveries (id, order_id, status, driver_search_started_at, created_at, updated_at)
VALUES ('{delivery_id}', '{order_id}', '{status}', now(), now(), now());
""")
    assignment_id = _fx_uuid(f'assignment:{order_id}:{driver_id}:{status}')
    # release any open assignment on delivery or driver
    sql(f"""
UPDATE driver_assignments
SET status = 'RELEASED', released_at = now()
WHERE released_at IS NULL
  AND (delivery_id = '{delivery_id}' OR driver_id = '{driver_id}');
UPDATE deliveries
SET status = '{status}', updated_at = now()
WHERE id = '{delivery_id}';
INSERT INTO driver_assignments (
  id, delivery_id, driver_id, status, assigned_at, accepted_at, released_at, version
) VALUES (
  '{assignment_id}', '{delivery_id}', '{driver_id}', 'ACCEPTED',
  now(), now(), NULL, 1
);
""")
    if arrived:
        event_id = _fx_uuid(f'arrived:{order_id}:{driver_id}:{assignment_id}')
        sql(f"""
INSERT INTO delivery_events (id, delivery_id, type, driver_id, occurred_at)
VALUES (
  '{event_id}', '{delivery_id}',
  'DRIVER_ARRIVED_PICKUP', '{driver_id}', now()
);
""")
    version = sql(
        f"SELECT version::text FROM driver_assignments WHERE id = '{assignment_id}'",
    )
    return delivery_id, assignment_id, int(version or '1')


def reassign(order_id, new_driver_id, status='AT_PICKUP'):
    delivery_id = sql(f"SELECT id FROM deliveries WHERE order_id = '{order_id}'")
    sql(f"""
UPDATE driver_assignments
SET status = 'RELEASED', released_at = now()
WHERE delivery_id = '{delivery_id}' AND released_at IS NULL;
""")
    # also invalidate pending handoffs (releaseAcceptedAssignment does this in app;
    # SQL path mirrors the side-effect for fixture reassignment)
    sql(f"""
UPDATE delivery_pickup_handoffs
SET status = 'INVALIDATED', invalidated_at = now(),
    invalidated_reason = 'ASSIGNMENT_RELEASED', updated_at = now()
WHERE delivery_id = '{delivery_id}' AND status = 'PENDING';
""")
    return attach_assignment(order_id, new_driver_id, status=status, arrived=True)


def _finish(code=0):
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'RESULTS.json').write_text(
        json.dumps({'results': RESULTS}, indent=2) + '\n',
    )
    fails = sum(1 for r in RESULTS if r['result'] == 'FAIL')
    print(f'SUMMARY pass={len(RESULTS)-fails} fail={fails}')
    raise SystemExit(code if fails == 0 else 1)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    # Schema probes
    tbl = sql(
        "SELECT count(*) FROM information_schema.tables "
        "WHERE table_schema='public' AND table_name='delivery_pickup_handoffs'",
    )
    record('H0', 'delivery_pickup_handoffs table', tbl == '1', f'count={tbl}')
    ver_col = sql(
        "SELECT count(*) FROM information_schema.columns "
        "WHERE table_schema='public' AND table_name='driver_assignments' "
        "AND column_name='version'",
    )
    record('H1', 'driver_assignments.version', ver_col == '1', f'count={ver_col}')

    seed_drivers()
    owner = login(OWNER, 'OWNER')
    manager = login(MANAGER, 'MANAGER')
    staff = login(STAFF, 'STAFF')
    driver_a = login(DRIVER_A_PHONE, 'DRIVER_A')
    driver_b = login(DRIVER_B_PHONE, 'DRIVER_B')

    # --- Assigned driver (row 21) ---
    oid = place_incoming('assigned')
    merchant_ready(oid, owner)
    delivery_id, assignment_id, assignment_version = attach_assignment(
        oid, DRIVER_A_ID, status='TO_PICKUP', arrived=False,
    )

    s, body = jreq(
        'GET', f'/merchant/{MERCHANT}/orders/{oid}/delivery', token=owner,
    )
    ad = body.get('assignedDriver') or {}
    blob = json.dumps(body)
    record(
        'A1', 'OWNER assignedDriver current assignment',
        s == 200
        and ad.get('driverId') == DRIVER_A_ID
        and ad.get('assignmentId') == assignment_id
        and ad.get('assignmentVersion') == assignment_version
        and ad.get('displayName') == 'Yacine Mansouri'
        and (ad.get('vehicle') or {}).get('plateNumber') == '16-12345'
        and ad.get('contactPhone') is None
        and ad.get('callAllowed') is False
        and ad.get('estimatedArrivalAt') is None
        and '550009131' not in blob
        and DRIVER_A_PHONE not in blob,
        f'status={s} name={ad.get("displayName")} call={ad.get("callAllowed")}',
    )

    s, staff_body = jreq(
        'GET', f'/merchant/{MERCHANT}/orders/{oid}/delivery', token=staff,
    )
    record(
        'A2', 'STAFF can read assignedDriver (ORDER_READ)',
        s == 200 and (staff_body.get('assignedDriver') or {}).get('driverId') == DRIVER_A_ID,
        f'status={s}',
    )

    s, foreign = jreq(
        'GET', f'/merchant/{FOREIGN_MERCHANT}/orders/{oid}/delivery', token=owner,
    )
    record(
        'A3', 'foreign merchant rejected',
        s == 404,
        f'status={s} code={code_of(foreign)}',
    )

    # Reassignment removes old driver access
    delivery_id, assignment_b, version_b = reassign(oid, DRIVER_B_ID, status='TO_PICKUP')
    s, body2 = jreq(
        'GET', f'/merchant/{MERCHANT}/orders/{oid}/delivery', token=owner,
    )
    ad2 = body2.get('assignedDriver') or {}
    record(
        'A4', 'reassignment shows new driver only',
        s == 200
        and ad2.get('driverId') == DRIVER_B_ID
        and ad2.get('displayName') == 'Karim Bensaid'
        and ad2.get('assignmentId') == assignment_b
        and ad2.get('driverId') != DRIVER_A_ID,
        f'status={s} driver={ad2.get("driverId")}',
    )

    # --- Secure handoff (row 23 API) ---
    oid2 = place_incoming('handoff')
    merchant_ready(oid2, owner)
    delivery_id2, assignment2, version2 = attach_assignment(
        oid2, DRIVER_A_ID, status='AT_PICKUP', arrived=True,
    )

    s, handoff = jreq(
        'GET',
        f'/merchant/{MERCHANT}/orders/{oid2}/delivery/pickup-handoff',
        token=owner,
    )
    code = handoff.get('pickupCode') or ''
    SECRETS['c1'] = code
    record(
        'P1', 'merchant issues/read PENDING handoff',
        s == 200
        and handoff.get('status') == 'PENDING'
        and isinstance(code, str)
        and len(code) == 4
        and code.isdigit()
        and handoff.get('assignmentId') == assignment2,
        f'status={s} attempts={handoff.get("attemptsRemaining")}',
    )

    # cold relaunch read returns same code (sealed retrieval)
    s, handoff2 = jreq(
        'GET',
        f'/merchant/{MERCHANT}/orders/{oid2}/delivery/pickup-handoff',
        token=manager,
    )
    code2 = handoff2.get('pickupCode') or ''
    SECRETS['c1b'] = code2
    record(
        'P2', 'cold re-read returns same code (no silent regenerate)',
        s == 200 and code2 == code and handoff2.get('id') == handoff.get('id'),
        f'status={s} same={code2 == code}',
    )

    # list-like delivery GET must not include plaintext code
    s, deliv = jreq(
        'GET', f'/merchant/{MERCHANT}/orders/{oid2}/delivery', token=owner,
    )
    deliv_blob = json.dumps(deliv)
    record(
        'P3', 'delivery GET omits plaintext pickup code',
        s == 200 and code not in deliv_blob and 'pickupCode' not in deliv_blob,
        f'status={s}',
    )

    # wrong code
    s, wrong = jreq(
        'POST', '/driver/deliveries/current/confirm-pickup',
        token=driver_a,
        data={
            'pickupCode': '0000' if code != '0000' else '1111',
            'assignmentId': assignment2,
            'assignmentVersion': version2,
        },
    )
    record(
        'P4', 'wrong code distinct error',
        s in (400, 409) and code_of(wrong) == 'PICKUP_HANDOFF_CODE_INVALID',
        f'status={s} code={code_of(wrong)}',
    )

    # wrong driver
    s, wrong_drv = jreq(
        'POST', '/driver/deliveries/current/confirm-pickup',
        token=driver_b,
        data={
            'pickupCode': code,
            'assignmentId': assignment2,
            'assignmentVersion': version2,
        },
    )
    record(
        'P5', 'wrong driver rejected',
        s in (403, 404, 409),
        f'status={s} code={code_of(wrong_drv)}',
    )

    # foreign merchant handoff
    s, fhand = jreq(
        'GET',
        f'/merchant/{FOREIGN_MERCHANT}/orders/{oid2}/delivery/pickup-handoff',
        token=owner,
    )
    record(
        'P6', 'foreign merchant handoff 404',
        s == 404,
        f'status={s} code={code_of(fhand)}',
    )

    # regenerate invalidates old
    s, regen = jreq(
        'POST',
        f'/merchant/{MERCHANT}/orders/{oid2}/delivery/pickup-handoff/regenerate',
        token=owner,
        data={},
    )
    new_code = regen.get('pickupCode') or ''
    SECRETS['c2'] = new_code
    record(
        'P7', 'regenerate issues new code',
        s == 200 and new_code and new_code != code and regen.get('status') == 'PENDING',
        f'status={s} changed={new_code != code}',
    )
    s, stale = jreq(
        'POST', '/driver/deliveries/current/confirm-pickup',
        token=driver_a,
        data={
            'pickupCode': code,
            'assignmentId': assignment2,
            'assignmentVersion': version2,
        },
    )
    record(
        'P8', 'old code rejected after regenerate',
        s in (400, 409) and code_of(stale) in (
            'PICKUP_HANDOFF_CODE_INVALID',
            'PICKUP_HANDOFF_EXPIRED',
            'PICKUP_HANDOFF_INVALID_STATE',
            'PICKUP_HANDOFF_NOT_FOUND',
        ),
        f'status={s} code={code_of(stale)}',
    )

    # successful verify (API fixture — not Driver UI)
    s, ok = jreq(
        'POST', '/driver/deliveries/current/confirm-pickup',
        token=driver_a,
        data={
            'pickupCode': new_code,
            'assignmentId': assignment2,
            'assignmentVersion': version2,
        },
    )
    record(
        'P9', 'authorized confirm-pickup consumes handoff (API fixture)',
        s == 200 and ok.get('deliveryStatus') == 'PICKED_UP',
        f'status={s} delivery={ok.get("deliveryStatus")} '
        f'(API fixture ≠ Driver UI evidence)',
    )

    # retry after success — no repeated side effects
    s, retry = jreq(
        'POST', '/driver/deliveries/current/confirm-pickup',
        token=driver_a,
        data={
            'pickupCode': new_code,
            'assignmentId': assignment2,
            'assignmentVersion': version2,
        },
    )
    record(
        'P10', 'retry after success idempotent / already confirmed',
        s == 200
        and retry.get('deliveryStatus') == 'PICKED_UP'
        and (retry.get('alreadyConfirmed') is True
             or retry.get('deliveryStatus') == 'PICKED_UP'),
        f'status={s} already={retry.get("alreadyConfirmed")} '
        f'delivery={retry.get("deliveryStatus")}',
    )

    # Reassignment invalidates pending proof
    oid3 = place_incoming('reassign_handoff')
    merchant_ready(oid3, owner)
    _, a3, v3 = attach_assignment(oid3, DRIVER_A_ID, status='AT_PICKUP', arrived=True)
    s, h3 = jreq(
        'GET',
        f'/merchant/{MERCHANT}/orders/{oid3}/delivery/pickup-handoff',
        token=owner,
    )
    code3 = h3.get('pickupCode') or ''
    SECRETS['c3'] = code3
    reassign(oid3, DRIVER_B_ID, status='AT_PICKUP')
    s, after_re = jreq(
        'POST', '/driver/deliveries/current/confirm-pickup',
        token=driver_a,
        data={'pickupCode': code3, 'assignmentId': a3, 'assignmentVersion': v3},
    )
    record(
        'P11', 'reassignment invalidates old proof for old driver',
        s in (403, 404, 409),
        f'status={s} code={code_of(after_re)}',
    )

    # Legacy: AT_PICKUP without handoff row — confirm without code
    oid4 = place_incoming('legacy')
    merchant_ready(oid4, owner)
    attach_assignment(oid4, DRIVER_A_ID, status='AT_PICKUP', arrived=True)
    # ensure no handoff
    sql(
        "DELETE FROM delivery_pickup_handoffs "
        f"WHERE delivery_id = (SELECT id FROM deliveries WHERE order_id = '{oid4}')",
    )
    s, legacy = jreq(
        'POST', '/driver/deliveries/current/confirm-pickup',
        token=driver_a,
        data={},
    )
    record(
        'P12', 'legacy confirm-pickup without handoff (no code)',
        s == 200 and legacy.get('deliveryStatus') == 'PICKED_UP',
        f'status={s} delivery={legacy.get("deliveryStatus")}',
    )

    # Concurrent verification: exactly one consumption
    oid5 = place_incoming('concurrent')
    merchant_ready(oid5, owner)
    _, a5, v5 = attach_assignment(oid5, DRIVER_A_ID, status='AT_PICKUP', arrived=True)
    s, h5 = jreq(
        'GET',
        f'/merchant/{MERCHANT}/orders/{oid5}/delivery/pickup-handoff',
        token=staff,
    )
    code5 = h5.get('pickupCode') or ''
    SECRETS['c5'] = code5

    def attempt_confirm():
        return jreq(
            'POST', '/driver/deliveries/current/confirm-pickup',
            token=driver_a,
            data={
                'pickupCode': code5,
                'assignmentId': a5,
                'assignmentVersion': v5,
            },
        )

    outcomes = []
    with ThreadPoolExecutor(max_workers=2) as pool:
        futs = [pool.submit(attempt_confirm) for _ in range(2)]
        for fut in as_completed(futs):
            outcomes.append(fut.result())
    successes = [o for o in outcomes if o[0] == 200 and o[1].get('deliveryStatus') == 'PICKED_UP']
    record(
        'P13', 'concurrent verify → exactly one consumption',
        len(successes) == 1,
        f'successes={len(successes)} outcomes='
        + ','.join(f'{o[0]}:{code_of(o[1]) or o[1].get("deliveryStatus")}' for o in outcomes),
    )

    # TO_PICKUP (not AT_PICKUP) cannot issue handoff
    oid6 = place_incoming('wrong_state')
    merchant_ready(oid6, owner)
    attach_assignment(oid6, DRIVER_A_ID, status='TO_PICKUP', arrived=False)
    s, bad_state = jreq(
        'GET',
        f'/merchant/{MERCHANT}/orders/{oid6}/delivery/pickup-handoff',
        token=owner,
    )
    record(
        'P14', 'handoff refused outside AT_PICKUP',
        s == 409 and code_of(bad_state) == 'PICKUP_HANDOFF_INVALID_STATE',
        f'status={s} code={code_of(bad_state)}',
    )

    # Stale assignment version conflict
    oid7 = place_incoming('stale_ver')
    merchant_ready(oid7, owner)
    _, a7, v7 = attach_assignment(oid7, DRIVER_A_ID, status='AT_PICKUP', arrived=True)
    s, h7 = jreq(
        'GET',
        f'/merchant/{MERCHANT}/orders/{oid7}/delivery/pickup-handoff',
        token=owner,
    )
    code7 = h7.get('pickupCode') or ''
    SECRETS['c7'] = code7
    s, stale_v = jreq(
        'POST', '/driver/deliveries/current/confirm-pickup',
        token=driver_a,
        data={
            'pickupCode': code7,
            'assignmentId': a7,
            'assignmentVersion': v7 + 99,
        },
    )
    record(
        'P15', 'stale assignmentVersion conflict',
        s in (400, 409) and code_of(stale_v) == 'PICKUP_HANDOFF_ASSIGNMENT_CONFLICT',
        f'status={s} code={code_of(stale_v)}',
    )

    # Expired code
    oid8 = place_incoming('expired')
    merchant_ready(oid8, owner)
    d8, a8, v8 = attach_assignment(oid8, DRIVER_A_ID, status='AT_PICKUP', arrived=True)
    s, h8 = jreq(
        'GET',
        f'/merchant/{MERCHANT}/orders/{oid8}/delivery/pickup-handoff',
        token=owner,
    )
    code8 = h8.get('pickupCode') or ''
    SECRETS['c8'] = code8
    sql(
        f"UPDATE delivery_pickup_handoffs SET expires_at = now() - interval '1 minute' "
        f"WHERE delivery_id = '{d8}' AND status = 'PENDING'",
    )
    s, exp = jreq(
        'POST', '/driver/deliveries/current/confirm-pickup',
        token=driver_a,
        data={
            'pickupCode': code8,
            'assignmentId': a8,
            'assignmentVersion': v8,
        },
    )
    record(
        'P16', 'expired code distinct error',
        s in (400, 409) and code_of(exp) == 'PICKUP_HANDOFF_EXPIRED',
        f'status={s} code={code_of(exp)}',
    )

    # Attempt lock
    oid9 = place_incoming('locked')
    merchant_ready(oid9, owner)
    _, a9, v9 = attach_assignment(oid9, DRIVER_A_ID, status='AT_PICKUP', arrived=True)
    s, h9 = jreq(
        'GET',
        f'/merchant/{MERCHANT}/orders/{oid9}/delivery/pickup-handoff',
        token=owner,
    )
    code9 = h9.get('pickupCode') or ''
    SECRETS['c9'] = code9
    lock_hit = False
    for i in range(8):
        bad = '0000' if code9 != '0000' else '1111'
        s, body = jreq(
            'POST', '/driver/deliveries/current/confirm-pickup',
            token=driver_a,
            data={
                'pickupCode': bad,
                'assignmentId': a9,
                'assignmentVersion': v9,
            },
        )
        if code_of(body) == 'PICKUP_HANDOFF_LOCKED':
            lock_hit = True
            break
    record(
        'P17', 'attempt limit locks handoff',
        lock_hit,
        f'locked={lock_hit} last_status={s} last_code={code_of(body)}',
    )

    # No financial side effect from viewing/generating
    oid10 = place_incoming('nofinance')
    merchant_ready(oid10, owner)
    attach_assignment(oid10, DRIVER_A_ID, status='AT_PICKUP', arrived=True)
    s, h10 = jreq(
        'GET',
        f'/merchant/{MERCHANT}/orders/{oid10}/delivery/pickup-handoff',
        token=owner,
    )
    SECRETS['c10'] = h10.get('pickupCode') or ''
    earn = sql(
        "SELECT count(*) FROM driver_earnings de "
        "JOIN deliveries d ON d.id = de.delivery_id "
        f"WHERE d.order_id = '{oid10}'",
    )
    pay = sql(
        f"SELECT status FROM payments WHERE order_id = '{oid10}'",
    )
    record(
        'P18', 'generate code has no financial side effect',
        s == 200 and earn == '0' and pay in ('PENDING', 'SUCCEEDED', 'AUTHORIZED', ''),
        f'earnings={earn} payment={pay}',
    )

    _finish(0)


if __name__ == '__main__':
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:  # noqa: BLE001
        record('XX', 'uncaught', False, str(exc)[:300])
        _finish(1)
