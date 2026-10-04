#!/usr/bin/env python3
"""Isolated API e2e for Merchant Daily Summary + Delivery Impact (rows 5, 18).

Usage: fx_daily_delay_e2e.py <out-dir> <fx_sql.sh>
"""
import json
import subprocess
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

BASE = 'http://127.0.0.1:3100/api/v1'
OTP = Path.home() / '.speedygo' / 'parity_fx' / 'otp' / 'otp-last'
NS = '0d00f0f0-fa00-7000-8000-'
MERCHANT = NS + '000000001001'
BRANCH = NS + '000000002001'
FOREIGN_MERCHANT = NS + '000000001002'
OWNER = '+213550009101'
MANAGER = '+213550009102'
STAFF = '+213550009103'
CUSTOMER = '+213550009111'
TZ = ZoneInfo('Africa/Algiers')

OUT = Path(sys.argv[1])
FX_SQL = sys.argv[2]
RESULTS = []
TOKENS = {}


def record(cid, name, ok, detail=''):
    RESULTS.append({
        'id': cid, 'check': name,
        'result': 'PASS' if ok else 'FAIL', 'detail': detail,
    })
    print(f'{"PASS" if ok else "FAIL"}  {cid} {name} {detail}'[:400])


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


def login(phone, label):
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
        'deviceName': f'parity-fx-daily-{label}',
    })
    if s not in (200, 201):
        raise SystemExit(f'otp verify {label} http={s}')
    TOKENS[label] = body['accessToken']
    return body['accessToken']


def logout(token):
    jreq('POST', '/auth/logout', token=token, data={})


def clear_otp_keys():
    subprocess.run(
        [
            'bash', '-c',
            "redis-cli -p 6381 -n 9 --scan --pattern 'auth:parityfx:*' "
            "| while read -r k; do redis-cli -p 6381 -n 9 DEL \"$k\" >/dev/null; done",
        ],
        capture_output=True, text=True, check=False,
    )


def place_incoming(tag='a'):
    """Place one COD order via checkout helpers used by fx_create_incoming."""
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
    clear_otp_keys()
    time.sleep(0.5)
    col = sql(
        "SELECT count(*) FROM information_schema.columns "
        "WHERE table_schema='public' AND table_name='order_cancellations' "
        "AND column_name='reason_code'",
    )
    record('D0', 'reason_code column present', col == '1', f'count={col}')

    owner = login(OWNER, 'OWNER')
    manager = login(MANAGER, 'MANAGER')
    staff = login(STAFF, 'STAFF')

    today = datetime.now(TZ).date().isoformat()
    s, emptyish = jreq(
        'GET',
        f'/merchant/{MERCHANT}/reports/daily-summary?date={today}&branchId={BRANCH}',
        token=owner,
    )
    record(
        'D1', 'OWNER daily-summary TODAY',
        s == 200
        and emptyish.get('period', {}).get('timezone') == 'Africa/Algiers'
        and emptyish.get('period', {}).get('localFrom') == today
        and emptyish.get('period', {}).get('interval') == '[from, to)'
        and 'ordersCreatedCount' in emptyish
        and 'breakdown' in emptyish
        and emptyish.get('averageActualPreparationMinutes') != 0,
        f'status={s} created={emptyish.get("ordersCreatedCount")} '
        f'completed={emptyish.get("completedOrderCount")} '
        f'avgPrep={emptyish.get("averageActualPreparationMinutes")}',
    )

    # Midnight exclusion: tomorrow must 400
    tomorrow = (datetime.now(TZ).date() + timedelta(days=1)).isoformat()
    s, future = jreq(
        'GET',
        f'/merchant/{MERCHANT}/reports/daily-summary?date={tomorrow}',
        token=owner,
    )
    record(
        'D2', 'future date refused',
        s == 400 and code_of(future) == 'REPORTS_INVALID_INPUT',
        f'status={s} code={code_of(future)}',
    )

    # Foreign merchant
    s, foreign = jreq(
        'GET', f'/merchant/{FOREIGN_MERCHANT}/reports/daily-summary',
        token=owner,
    )
    record(
        'D3', 'foreign merchant → 404',
        s == 404,
        f'status={s} code={code_of(foreign)}',
    )

    s, staff_body = jreq(
        'GET',
        f'/merchant/{MERCHANT}/reports/daily-summary?branchId={BRANCH}',
        token=staff,
    )
    record(
        'D4', 'STAFF sees ops metrics',
        s == 200
        and staff_body.get('ordersCreatedCount') is not None
        and staff_body.get('financeAccess') == 'ROLE_RESTRICTED',
        f'status={s} finance={staff_body.get("financeAccess")}',
    )

    # Reject with structured reason
    oid = place_incoming('reject')
    s, rejected = jreq(
        'POST', f'/merchant/{MERCHANT}/orders/{oid}/reject',
        token=owner,
        data={
            'reasonCode': 'PRODUCT_UNAVAILABLE',
            'reason': 'Produit indisponible (essai isolé).',
        },
    )
    record(
        'D5', 'reject with reasonCode',
        s == 200
        and rejected.get('status') == 'CANCELLED'
        and (rejected.get('cancellation') or {}).get('reasonCode')
        == 'PRODUCT_UNAVAILABLE',
        f'status={s} code={(rejected.get("cancellation") or {}).get("reasonCode")}',
    )

    s, after = jreq(
        'GET',
        f'/merchant/{MERCHANT}/reports/daily-summary?branchId={BRANCH}',
        token=owner,
    )
    reasons = after.get('cancellationReasons') or []
    has_product = any(
        r.get('reasonCode') == 'PRODUCT_UNAVAILABLE' and r.get('count', 0) >= 1
        for r in reasons
    )
    record(
        'D6', 'daily-summary lists PRODUCT_UNAVAILABLE motif',
        s == 200 and has_product,
        f'status={s} reasons={reasons}',
    )

    # Prep late order: accept with short estimate then force past estimate in DB
    oid2 = place_incoming('late')
    s, accepted = jreq(
        'POST', f'/merchant/{MERCHANT}/orders/{oid2}/accept',
        token=owner,
        data={'preparationMinutes': 15},
    )
    record('D7', 'accept for late fixture', s == 200, f'status={s}')
    past = (datetime.now(timezone.utc) - timedelta(minutes=12)).isoformat()
    sql(
        f"UPDATE orders SET estimated_ready_at = '{past}'::timestamptz, "
        f"original_estimated_ready_at = COALESCE(original_estimated_ready_at, '{past}'::timestamptz) "
        f"WHERE id = '{oid2}'",
    )
    s, detail = jreq(
        'GET', f'/merchant/{MERCHANT}/orders/{oid2}', token=owner,
    )
    impact = detail.get('deliveryImpact') or {}
    record(
        'D8', 'late detail exposes delayMinutes + deliveryImpact',
        s == 200
        and detail.get('isPreparationLate') is True
        and isinstance(detail.get('delayMinutes'), int)
        and detail.get('delayMinutes') >= 1
        and impact.get('state') in (
            'MAY_DELAY_DRIVER_ASSIGNMENT',
            'DELIVERY_TIMING_UNAVAILABLE',
        ),
        f'status={s} late={detail.get("isPreparationLate")} '
        f'delay={detail.get("delayMinutes")} impact={impact.get("state")}',
    )

    s, rev = jreq(
        'POST',
        f'/merchant/{MERCHANT}/orders/{oid2}/preparation-estimate',
        token=owner,
        data={
            'addMinutes': 10,
            'expectedEstimateVersion': detail.get('preparationEstimateVersion'),
            'reason': 'Forte affluence (essai isolé)',
        },
    )
    record(
        'D9', 'prep revision after late',
        s == 200
        and (rev.get('latestPreparationRevision') or {}).get('reason')
        is not None,
        f'status={s} rev={rev.get("latestPreparationRevision")}',
    )

    s, mgr = jreq(
        'GET',
        f'/merchant/{MERCHANT}/reports/daily-summary?branchId={BRANCH}',
        token=manager,
    )
    record('D10', 'MANAGER daily-summary', s == 200, f'status={s}')

    # Seed has completed orders today — GMS should be non-null when snapshots exist
    record(
        'D11', 'completed sales / basket not fabricated as zero when empty avg',
        after.get('averageBasketMinor') is None
        or (
            isinstance(after.get('averageBasketMinor'), str)
            and after.get('completedOrderCount', 0) > 0
        ),
        f'completed={after.get("completedOrderCount")} '
        f'basket={after.get("averageBasketMinor")} '
        f'gms={after.get("grossMerchandiseMinor")}',
    )

    for t in (owner, manager, staff):
        logout(t)
    _finish(0)


if __name__ == '__main__':
    try:
        main()
    except SystemExit:
        raise
    except Exception as e:
        record('DX', 'uncaught', False, str(e)[:300])
        _finish(1)
