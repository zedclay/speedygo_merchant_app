#!/usr/bin/env python3
"""Black-box e2e for the contract-completion batch on the isolated API only.

Invoked by fx_contract_e2e.sh (which proves the environment). Talks to
http://127.0.0.1:3100/api/v1, reads OTPs from the isolated capture file, runs
row assertions through fx_sql.sh (speedygo_parity_fx only) and inspects the
isolated local storage root. Every session it creates is logged out at the end.
Never prints tokens, OTPs or connection strings.
Usage: fx_contract_e2e.py <out-dir> <fx_sql.sh> <storage-root>
"""
import hashlib
import json
import struct
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.request
import uuid
import zlib
from datetime import datetime, timedelta, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

BASE = 'http://127.0.0.1:3100/api/v1'
OTP = Path.home() / '.speedygo' / 'parity_fx' / 'otp' / 'otp-last'
TZ = ZoneInfo('Africa/Algiers')
NS = '0d00f0f0-fa00-7000-8000-'
MERCHANT = NS + '000000001001'
BRANCH = NS + '000000002001'
FOREIGN_MERCHANT = NS + '000000001002'
FOREIGN_BRANCH = NS + '000000002002'
FOREIGN_PRODUCT = NS + '000000007101'
SRC_PRODUCT = NS + '000000007001'
FAIL_PRODUCT = NS + '000000007002'
ORDER_PRODUCT = NS + '000000007003'
ADDRESS = NS + '000000000113'
NOSCHEDULE_BRANCH = NS + '000000002003'
PHONES = {'OWNER': '+213550009101', 'MANAGER': '+213550009102', 'STAFF': '+213550009103',
          'CUSTOMER': '+213550009111'}

OUT = Path(sys.argv[1])
FX_SQL = sys.argv[2]
STORAGE = Path(sys.argv[3])
RESULTS = []
TOKENS = {}


# --- plumbing -------------------------------------------------------------------
def record(cid, area, name, ok, detail=''):
    RESULTS.append({'id': cid, 'area': area, 'check': name, 'result': 'PASS' if ok else 'FAIL',
                    'detail': detail})
    print(f'{"PASS" if ok else "FAIL"}  {cid} {name} {detail}'[:400])


def req(method, path, token=None, data=None, raw=None, headers=None, timeout=60):
    h = dict(headers or {})
    if token:
        h['Authorization'] = f'Bearer {token}'
    body = None
    if data is not None:
        body = json.dumps(data).encode()
        h['Content-Type'] = 'application/json'
    elif raw is not None:
        body = raw
    r = urllib.request.Request(BASE + path, data=body, headers=h, method=method)
    try:
        with urllib.request.urlopen(r, timeout=timeout) as res:
            return res.status, res.read(), dict(res.headers)
    except urllib.error.HTTPError as e:
        return e.code, e.read(), dict(e.headers)


def jreq(method, path, token=None, data=None, **kw):
    s, b, h = req(method, path, token, data, **kw)
    try:
        return s, json.loads(b.decode() or '{}'), h
    except ValueError:
        return s, {}, h


def code_of(body):
    if isinstance(body, dict):
        err = body.get('error')
        if isinstance(err, dict):
            return err.get('code')
        return body.get('code')
    return None


def multipart(field, filename, content_type, content):
    boundary = 'fxboundary' + uuid.uuid4().hex
    head = (f'--{boundary}\r\nContent-Disposition: form-data; name="{field}"; filename="{filename}"\r\n'
            f'Content-Type: {content_type}\r\n\r\n').encode()
    return head + content + f'\r\n--{boundary}--\r\n'.encode(), f'multipart/form-data; boundary={boundary}'


def upload(path, token, filename, ctype, content):
    body, ct = multipart('file', filename, ctype, content)
    return jreq('POST', path, token, raw=body, headers={'Content-Type': ct})


def png(w, h, rgb):
    row = b'\x00' + bytes(rgb) * w
    raw = row * h
    def chunk(t, d):
        return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))


def sha(b):
    return hashlib.sha256(b).hexdigest()


def sql(statement):
    p = subprocess.run(['bash', FX_SQL], input=statement, capture_output=True, text=True)
    if p.returncode != 0:
        raise RuntimeError(f'fx_sql failed rc={p.returncode}: {p.stderr.strip()[:300]}')
    return p.stdout.strip()


def sql_json(statement):
    out = sql(statement)
    return json.loads(out) if out else None


def objects(namespace):
    d = STORAGE / namespace
    if not d.exists():
        return set()
    return {p.name for p in d.iterdir() if p.is_file() and not p.name.endswith('.meta')}


def login(role):
    before = time.time() - 1
    s, body, _ = jreq('POST', '/auth/otp/request',
                      data={'channel': 'PHONE', 'identifier': PHONES[role], 'purpose': 'AUTHENTICATE'})
    if s not in (200, 201, 202):
        raise SystemExit(f'otp request refused for {role} http={s} code={code_of(body)}')
    otp = None
    for _ in range(80):
        if OTP.exists() and OTP.stat().st_mtime >= before:
            otp = OTP.read_text().strip()
            if otp.isdigit():
                break
        time.sleep(0.25)
    if not otp:
        raise SystemExit('isolated OTP capture not found')
    s, body, _ = jreq('POST', '/auth/otp/verify', data={
        'channel': 'PHONE', 'identifier': PHONES[role], 'purpose': 'AUTHENTICATE', 'code': otp,
        'platform': 'ios', 'appVersion': '1.0.0', 'deviceName': f'parity-fx-contract-e2e-{role.lower()}'})
    if s not in (200, 201):
        raise SystemExit(f'otp verify failed for {role} http={s} code={code_of(body)}')
    TOKENS[role] = body['accessToken']
    return body['accessToken']


def hhmm(minute):
    return f'{(minute // 60) % 24:02d}:{minute % 60:02d}'


def local_midnight_utc(d):
    return datetime(d.year, d.month, d.day, tzinfo=TZ).astimezone(timezone.utc)


def iso_eq(a, b):
    if a is None or b is None:
        return a is None and b is None
    pa = datetime.fromisoformat(a.replace('Z', '+00:00'))
    return abs((pa - b).total_seconds()) < 1


# --- store logo -------------------------------------------------------------------
def logo_suite():
    owner, manager, staff = TOKENS['OWNER'], TOKENS['MANAGER'], TOKENS['STAFF']
    base = f'/merchant/{MERCHANT}/branches/{BRANCH}/logo'
    a, b, c = png(256, 256, (200, 40, 40)), png(320, 320, (30, 120, 200)), png(300, 300, (40, 160, 60))

    s, body, _ = jreq('GET', base, owner)
    record('L01', 'logo', 'no logo → GET 404 STORAGE_OBJECT_MISSING (fallback state)',
           s == 404 and code_of(body) == 'STORAGE_OBJECT_MISSING', f'http={s} code={code_of(body)}')

    s, up, _ = upload(base + '/content', owner, 'logo.png', 'image/png', a)
    ok = s in (200, 201) and up.get('purpose') == 'MERCHANT_BRANCH_LOGO' and up.get('widthPx') == 256
    record('L02', 'logo', 'OWNER upload PNG → pending reference, purpose MERCHANT_BRANCH_LOGO', ok,
           f'http={s} purpose={up.get("purpose")} size={up.get("sizeBytes")}')
    s, bound, _ = jreq('PUT', base, owner, {'uploadReference': up.get('uploadReference')})
    v1 = bound.get('logoVersion')
    record('L03', 'logo', 'OWNER bind → logoVersion + logoImageUrl',
           s == 200 and bool(v1) and bound.get('logoImageUrl') == f'/merchant/{MERCHANT}/branches/{BRANCH}/logo',
           f'http={s} url={bound.get("logoImageUrl")}')
    s, raw, hdr = req('GET', base, owner)
    hl = {k.lower(): v for k, v in hdr.items()}
    record('L04', 'logo', 'GET streams exact bytes with ETag/no-cache/nosniff',
           s == 200 and sha(raw) == sha(a) and hl.get('etag') == f'"{v1}"'
           and 'no-cache' in hl.get('cache-control', '') and hl.get('x-content-type-options') == 'nosniff',
           f'http={s} sha_match={sha(raw) == sha(a)} etag_match={hl.get("etag") == chr(34) + str(v1) + chr(34)} cc={hl.get("cache-control")}')
    row = sql_json(f"select json_agg(object_id) from merchant_branch_logos where branch_id='{BRANCH}'")
    record('L05', 'logo', 'DB: one merchant_branch_logos row bound to the branch; object stored under logos/',
           row == [v1] and v1 in objects('logos'), f'rows={len(row or [])} stored={v1 in objects("logos")}')

    s, raw, _ = req('GET', base, staff)
    record('L06', 'logo', 'STAFF may view the logo', s == 200 and sha(raw) == sha(a), f'http={s}')
    s1, b1, _ = upload(base + '/content', staff, 'logo.png', 'image/png', b)
    s2, b2, _ = jreq('PUT', base, staff, {'uploadReference': up.get('uploadReference')})
    s3, b3, _ = jreq('DELETE', base, staff)
    record('L07', 'logo', 'STAFF upload / bind / delete → 403',
           (s1, s2, s3) == (403, 403, 403), f'http={s1},{s2},{s3} codes={code_of(b1)},{code_of(b2)},{code_of(b3)}')

    s, up_b, _ = upload(base + '/content', manager, 'logo-b.png', 'image/png', b)
    s, bound_b, _ = jreq('PUT', base, manager, {'uploadReference': up_b.get('uploadReference')})
    v2 = bound_b.get('logoVersion')
    s_get, raw, hdr = req('GET', base, owner)
    hl = {k.lower(): v for k, v in hdr.items()}
    stored = objects('logos')
    row = sql_json(f"select json_agg(object_id) from merchant_branch_logos where branch_id='{BRANCH}'")
    record('L08', 'logo', 'MANAGER replace → new version, new bytes, no stale object, single row',
           s == 200 and v2 and v2 != v1 and sha(raw) == sha(b) and hl.get('etag') == f'"{v2}"'
           and v1 not in stored and v2 in stored and row == [v2],
           f'http={s} new_version={v2 != v1} sha_b={sha(raw) == sha(b)} old_object_removed={v1 not in stored} rows={len(row or [])}')

    s, rebind, _ = jreq('PUT', base, owner, {'uploadReference': up_b.get('uploadReference')})
    record('L09', 'logo', 'consumed upload reference cannot be bound twice',
           s >= 400 and s < 500, f'http={s} code={code_of(rebind)}')

    cover = png(480, 480, (90, 90, 90))
    s, upc, _ = upload(f'/merchant/{MERCHANT}/branches/{BRANCH}/cover/content', owner, 'cover.png', 'image/png', cover)
    s2, cross, _ = jreq('PUT', base, owner, {'uploadReference': upc.get('uploadReference')})
    row = sql_json(f"select json_agg(object_id) from merchant_branch_logos where branch_id='{BRANCH}'")
    record('L10', 'logo', 'cover upload reference refused as logo (purpose isolation)',
           s in (200, 201) and 400 <= s2 < 500 and row == [v2], f'cover_upload={s} bind={s2} code={code_of(cross)}')

    gif = b'GIF89a' + b'\x00' * 200
    s, g, _ = upload(base + '/content', owner, 'logo.gif', 'image/gif', gif)
    record('L11', 'logo', 'GIF refused (JPEG/PNG only)', s == 400 and code_of(g) == 'STORAGE_UNSUPPORTED_TYPE',
           f'http={s} code={code_of(g)}')
    s, tiny, _ = upload(base + '/content', owner, 'tiny.png', 'image/png', png(64, 64, (1, 2, 3)))
    record('L12', 'logo', 'below 128 px refused', s == 400, f'http={s} code={code_of(tiny)}')
    s, big, _ = upload(base + '/content', owner, 'big.png', 'image/png', b'\x89PNG\r\n\x1a\n' + b'\x00' * (1024 * 1024 + 64))
    record('L13', 'logo', 'over 1 MiB refused at the multipart limit (413, same as cover/documents)',
           s == 413 or (s == 400 and code_of(big) == 'STORAGE_FILE_TOO_LARGE'), f'http={s} code={code_of(big)}')

    s1, f1, _ = upload(f'/merchant/{MERCHANT}/branches/{FOREIGN_BRANCH}/logo/content', owner, 'x.png', 'image/png', c)
    s2, f2, _ = jreq('GET', f'/merchant/{MERCHANT}/branches/{FOREIGN_BRANCH}/logo', owner)
    s3, f3, _ = upload(f'/merchant/{FOREIGN_MERCHANT}/branches/{FOREIGN_BRANCH}/logo/content', owner, 'x.png', 'image/png', c)
    s4, f4, _ = jreq('DELETE', f'/merchant/{FOREIGN_MERCHANT}/branches/{FOREIGN_BRANCH}/logo', owner)
    foreign_rows = sql(f"select count(*) from merchant_branch_logos where branch_id='{FOREIGN_BRANCH}'")
    record('L14', 'logo', 'foreign branch / foreign merchant refused, no row',
           s1 == 404 and s2 == 404 and s3 in (403, 404) and s4 in (403, 404) and foreign_rows == '0',
           f'http={s1},{s2},{s3},{s4} codes={code_of(f1)},{code_of(f2)},{code_of(f3)},{code_of(f4)}')

    s, d, _ = jreq('DELETE', base, owner)
    s_get, g, _ = jreq('GET', base, owner)
    rows = sql(f"select count(*) from merchant_branch_logos where branch_id='{BRANCH}'")
    cover_rows = sql(f"select count(*) from merchant_branch_covers where branch_id='{BRANCH}'")
    record('L15', 'logo', 'OWNER delete → GET 404 fallback, row and object removed, cover untouched',
           s == 200 and d.get('deleted') is True and s_get == 404 and rows == '0' and v2 not in objects('logos')
           and cover_rows == '0',
           f'http={s} get={s_get} rows={rows} object_removed={v2 not in objects("logos")} covers={cover_rows}')
    s, d2, _ = jreq('DELETE', base, owner)
    record('L16', 'logo', 'repeat delete is idempotent', s == 200 and d2.get('deleted') is True, f'http={s}')
    left = objects('logos')
    record('L17', 'logo', 'no orphan logo objects remain', not left, f'objects={len(left)}')


# --- exceptional opening hours -------------------------------------------------------
def hours_suite():
    owner, staff, cust = TOKENS['OWNER'], TOKENS['STAFF'], TOKENS['CUSTOMER']
    exc = f'/merchant/{MERCHANT}/branches/{BRANCH}/opening-hours/exceptions'
    avail = f'/merchant/{MERCHANT}/branches/{BRANCH}/availability'
    now = datetime.now(TZ)
    today, tomorrow, yesterday = now.date(), now.date() + timedelta(days=1), now.date() - timedelta(days=1)
    m = now.hour * 60 + now.minute
    if m < 150 or m > 1290:
        record('H00', 'hours', 'time-of-day precondition (02:30–21:30 Algiers)', False,
               f'local {now:%H:%M}; relative-interval checks need room on both sides')
        return

    def preview():
        s, b, _ = jreq('POST', '/customer/checkout/preview', cust, {'addressId': ADDRESS})
        return s, code_of(b), b

    def storefront():
        s, b, _ = jreq('GET', f'/customer/branches/{BRANCH}', cust)
        sl, bl, _ = jreq('GET', '/customer/branches?openNow=true&limit=50', cust)
        items = bl.get('items') if isinstance(bl, dict) else None
        listed = any(i.get('branchId') == BRANCH or i.get('id') == BRANCH for i in (items or []))
        return (b.get('isOpenNow') if isinstance(b, dict) else None), listed, s, sl

    def availability():
        s, b, _ = jreq('GET', avail, owner)
        return b

    def state(label):
        av = availability()
        ps, pc, _ = preview()
        open_detail, listed, _, _ = storefront()
        return {'label': label, 'merchantIsOpenNow': av.get('isOpenNow'), 'acceptingOrders': av.get('acceptingOrders'),
                'hoursException': av.get('hoursException'), 'nextOpenAt': av.get('nextOpenAt'),
                'currentClosesAt': av.get('currentClosesAt'), 'previewHttp': ps, 'previewCode': pc,
                'customerIsOpenNow': open_detail, 'listedOpenNow': listed}

    def consistent(st, expect_open):
        return (st['merchantIsOpenNow'] is expect_open and st['acceptingOrders'] is expect_open
                and st['customerIsOpenNow'] is expect_open and st['listedOpenNow'] is expect_open
                and ((st['previewHttp'] == 200) if expect_open else (st['previewCode'] == 'CHECKOUT_BRANCH_CLOSED')))

    states = []
    def put(date, payload, token=owner):
        return jreq('PUT', f'{exc}/{date.isoformat() if hasattr(date, "isoformat") else date}', token, payload)

    # cart for checkout checks
    s, cart, _ = jreq('GET', '/customer/cart', cust)
    c = (cart.get('cart') or cart) if isinstance(cart, dict) else {}
    for it in (c.get('items') or []):
        jreq('DELETE', f'/customer/cart/items/{it["id"]}', cust)
    s, _, _ = jreq('POST', '/customer/cart/items', cust, {'productId': ORDER_PRODUCT, 'quantity': 1})

    s, lst, _ = jreq('GET', exc, owner)
    record('H01', 'hours', 'GET exceptions: empty list, today is the Algiers civil date',
           s == 200 and lst.get('items') == [] and lst.get('today') == today.isoformat()
           and lst.get('timezone') == 'Africa/Algiers', f'http={s} today={lst.get("today")} local={today}')
    st = state('baseline weekly 24h, no exception'); states.append(st)
    ps, _, base_preview = preview()
    record('H02', 'hours', 'baseline: weekly 24h open on every surface', consistent(st, True), json.dumps(st))

    s, sb, _ = jreq('GET', exc, staff)
    s2, sp, _ = put(today, {'expectedVersion': 0, 'closed': True, 'intervals': [], 'label': 'Fermeture'}, staff)
    s3, sd, _ = jreq('DELETE', f'{exc}/{today}?expectedVersion=1', staff)
    record('H03', 'hours', 'STAFF read-only: GET 200, PUT/DELETE 403', s == 200 and s2 == 403 and s3 == 403,
           f'http={s},{s2},{s3} codes={code_of(sp)},{code_of(sd)}')

    s, v1, _ = put(today, {'expectedVersion': 0, 'closed': True, 'intervals': [], 'label': 'Inventaire',
                           'customerMessage': 'Fermé exceptionnellement aujourd’hui.'})
    st = state('today closed all day'); states.append(st)
    record('H04', 'hours', 'today closed → closed on every surface; checkout preview CHECKOUT_BRANCH_CLOSED',
           s == 200 and v1.get('version') == 1 and v1.get('closed') is True and consistent(st, False)
           and (st['hoursException'] or {}).get('closed') is True, f'http={s} {json.dumps(st)}')
    os_, ob, _ = jreq('POST', '/customer/orders', cust, {
        'addressId': ADDRESS, 'paymentMethod': 'COD',
        'expectedMerchandiseSubtotalMinor': int(base_preview['merchandiseSubtotalMinor']),
        'expectedDeliveryFeeMinor': int(base_preview['deliveryFeeMinor']),
        'expectedCustomerTotalMinor': int(base_preview['customerTotalMinor'])})
    record('H05', 'hours', 'today closed → order creation ORDER_BRANCH_CLOSED',
           os_ in (400, 409, 422) and code_of(ob) == 'ORDER_BRANCH_CLOSED', f'http={os_} code={code_of(ob)}')

    opens = max(0, (m - 60) // 15 * 15)
    closes = ((m + 75) // 15) * 15
    s, v2, _ = put(today, {'expectedVersion': 1, 'closed': False, 'label': 'Horaires réduits',
                           'intervals': [{'opens': hhmm(opens), 'closes': hhmm(closes)}]})
    st = state(f'today custom {hhmm(opens)}–{hhmm(closes)} (now inside)'); states.append(st)
    expected_close = local_midnight_utc(today) + timedelta(minutes=closes)
    record('H06', 'hours', 'custom interval containing now → open everywhere; currentClosesAt = interval end',
           s == 200 and v2.get('version') == 2 and consistent(st, True) and iso_eq(st['currentClosesAt'], expected_close),
           f'http={s} {json.dumps(st)}')
    ps, pc, pv = preview()
    if ps != 200:
        raise RuntimeError(f'preview inside custom interval failed http={ps} code={pc}')
    os_, ob, _ = jreq('POST', '/customer/orders', cust, {
        'addressId': ADDRESS, 'paymentMethod': 'COD',
        'expectedMerchandiseSubtotalMinor': int(pv['merchandiseSubtotalMinor']),
        'expectedDeliveryFeeMinor': int(pv['deliveryFeeMinor']),
        'expectedCustomerTotalMinor': int(pv['customerTotalMinor'])})
    record('H07', 'hours', 'inside custom interval → order creation succeeds', os_ in (200, 201) and ob.get('id'),
           f'http={os_} code={code_of(ob)}')
    jreq('POST', '/customer/cart/items', cust, {'productId': ORDER_PRODUCT, 'quantity': 1})

    later_open, later_close = m + 90, min(m + 150, 1425)
    s, v3, _ = put(today, {'expectedVersion': 2, 'closed': False, 'label': 'Ouverture tardive',
                           'intervals': [{'opens': hhmm(later_open), 'closes': hhmm(later_close)}]})
    st = state(f'today custom {hhmm(later_open)}–{hhmm(later_close)} (now before)'); states.append(st)
    expected_next = local_midnight_utc(today) + timedelta(minutes=later_open)
    record('H08', 'hours', 'custom interval after now → closed; nextOpenAt = interval start',
           s == 200 and consistent(st, False) and iso_eq(st['nextOpenAt'], expected_next), f'http={s} {json.dumps(st)}')
    os_, ob, _ = jreq('POST', '/customer/orders', cust, {
        'addressId': ADDRESS, 'paymentMethod': 'COD',
        'expectedMerchandiseSubtotalMinor': int(pv['merchandiseSubtotalMinor']),
        'expectedDeliveryFeeMinor': int(pv['deliveryFeeMinor']),
        'expectedCustomerTotalMinor': int(pv['customerTotalMinor'])})
    record('H09', 'hours', 'outside custom interval → order creation ORDER_BRANCH_CLOSED',
           code_of(ob) == 'ORDER_BRANCH_CLOSED', f'http={os_} code={code_of(ob)}')

    s, conflict, _ = put(today, {'expectedVersion': 2, 'closed': True, 'intervals': [], 'label': 'Fermeture'})
    cur = (conflict.get('error') or {}).get('openingHoursException') or {}
    record('H10', 'hours', 'stale expectedVersion → 409 VERSION_CONFLICT with current server row',
           s == 409 and code_of(conflict) == 'OPENING_HOURS_EXCEPTION_VERSION_CONFLICT' and cur.get('version') == 3,
           f'http={s} code={code_of(conflict)} current_version={cur.get("version")}')
    s, conflict0, _ = put(today, {'expectedVersion': 0, 'closed': True, 'intervals': [], 'label': 'Fermeture'})
    record('H11', 'hours', 'expectedVersion 0 on an existing date → 409',
           s == 409 and code_of(conflict0) == 'OPENING_HOURS_EXCEPTION_VERSION_CONFLICT', f'http={s}')
    st_after = state('after rejected writes'); states.append(st_after)
    record('H12', 'hours', 'rejected writes change nothing (still the version-3 schedule)',
           consistent(st_after, False) and iso_eq(st_after['nextOpenAt'], expected_next), json.dumps(st_after))

    bad = [
        ('overnight interval', today, {'expectedVersion': 3, 'closed': False, 'label': 'x', 'intervals': [{'opens': '22:00', 'closes': '02:00'}]}),
        ('overlapping intervals', today, {'expectedVersion': 3, 'closed': False, 'label': 'x', 'intervals': [{'opens': '10:00', 'closes': '12:00'}, {'opens': '11:30', 'closes': '13:00'}]}),
        ('zero-length interval', today, {'expectedVersion': 3, 'closed': False, 'label': 'x', 'intervals': [{'opens': '10:00', 'closes': '10:00'}]}),
        ('closed with intervals', today, {'expectedVersion': 3, 'closed': True, 'label': 'x', 'intervals': [{'opens': '10:00', 'closes': '12:00'}]}),
        ('open without intervals', today, {'expectedVersion': 3, 'closed': False, 'label': 'x', 'intervals': []}),
        ('blank label', today, {'expectedVersion': 3, 'closed': True, 'intervals': [], 'label': '   '}),
        ('past local date', yesterday, {'expectedVersion': 0, 'closed': True, 'intervals': [], 'label': 'x'}),
        ('beyond 365 days', today + timedelta(days=366), {'expectedVersion': 0, 'closed': True, 'intervals': [], 'label': 'x'}),
        ('impossible date', '2027-02-30', {'expectedVersion': 0, 'closed': True, 'intervals': [], 'label': 'x'}),
        ('24:00 notation', today, {'expectedVersion': 3, 'closed': False, 'label': 'x', 'intervals': [{'opens': '10:00', 'closes': '24:00'}]}),
    ]
    bad_res = []
    for label, d, payload in bad:
        s, b, _ = put(d, payload)
        bad_res.append((label, s, code_of(b)))
    s, om, _ = put(today, {'expectedVersion': 3, 'closed': True, 'label': 'x'})
    bad_res.append(('intervals omitted (contract requires [])', s, code_of(om)))
    record('H13', 'hours', 'validation: overnight/overlap/zero/closed+intervals/empty/blank/past/>365/impossible/24:00 → 400',
           all(s == 400 and c in ('OPENING_HOURS_EXCEPTION_INVALID', 'VALIDATION_ERROR') for _, s, c in bad_res),
           json.dumps(bad_res, ensure_ascii=False))

    # midnight boundary: open until 00:00 today, tomorrow closed → closes exactly at local midnight
    s, t1, _ = put(tomorrow, {'expectedVersion': 0, 'closed': True, 'intervals': [], 'label': 'Jour férié'})
    s2, v4, _ = put(today, {'expectedVersion': 3, 'closed': False, 'label': 'Jusqu’à minuit',
                            'intervals': [{'opens': hhmm(opens), 'closes': '00:00'}]})
    st = state(f'today {hhmm(opens)}–00:00, tomorrow closed'); states.append(st)
    midnight = local_midnight_utc(tomorrow)
    record('H14', 'hours', 'until-midnight interval + closed tomorrow → open now, closes at Algiers midnight',
           s == 200 and s2 == 200 and consistent(st, True) and iso_eq(st['currentClosesAt'], midnight),
           f'http={s},{s2} closes={st["currentClosesAt"]} expected={midnight.isoformat()}')

    # weekly fallback today with tomorrow closed: weekly 24h spill is clipped at midnight
    s, dl, _ = jreq('DELETE', f'{exc}/{today}?expectedVersion=4', owner)
    st = state('no exception today (weekly 24h), tomorrow closed'); states.append(st)
    record('H15', 'hours', 'delete today → weekly fallback open; spill clipped at tomorrow’s closed date',
           s == 200 and consistent(st, True) and iso_eq(st['currentClosesAt'], midnight) and st['hoursException'] is None,
           f'http={s} {json.dumps(st)}')
    s, lst, _ = jreq('GET', exc, owner)
    record('H16', 'hours', 'reopen list: only tomorrow remains, persisted fields intact',
           s == 200 and [i.get('date') for i in lst.get('items', [])] == [tomorrow.isoformat()]
           and lst['items'][0].get('label') == 'Jour férié' and lst['items'][0].get('closed') is True,
           f'http={s} items={[i.get("date") for i in lst.get("items", [])]}')
    s, dstale, _ = jreq('DELETE', f'{exc}/{tomorrow}?expectedVersion=7', owner)
    s2, dok, _ = jreq('DELETE', f'{exc}/{tomorrow}?expectedVersion=1', owner)
    s3, dmiss, _ = jreq('DELETE', f'{exc}/{tomorrow}?expectedVersion=1', owner)
    record('H17', 'hours', 'delete: stale version 409, correct version 200, repeat 404',
           s == 409 and s2 == 200 and s3 == 404, f'http={s},{s2},{s3} codes={code_of(dstale)},{code_of(dmiss)}')
    st = state('no exceptions at all'); states.append(st)
    record('H18', 'hours', 'no exceptions → identical to weekly-only baseline',
           consistent(st, True) and st['currentClosesAt'] == states[0]['currentClosesAt'], json.dumps(st))

    # override precedence over an all-day open exception
    s, v_all, _ = put(today, {'expectedVersion': 0, 'closed': False, 'label': 'Journée continue',
                              'intervals': [{'opens': '00:00', 'closes': '00:00'}]})
    av = availability()
    ver = av.get('version') or 0
    s1, fc, _ = jreq('PUT', avail, owner, {'expectedVersion': ver, 'mode': 'FORCE_CLOSED', 'reasonCode': 'TECHNICAL'})
    st = state('open all-day exception + FORCE_CLOSED'); states.append(st)
    ok_fc = s == 200 and s1 == 200 and consistent(st, False)
    until = (datetime.now(timezone.utc) + timedelta(minutes=30)).replace(microsecond=0).isoformat().replace('+00:00', 'Z')
    s2, tc, _ = jreq('PUT', avail, owner, {'expectedVersion': fc.get('version'), 'mode': 'TEMPORARY_CLOSED',
                                           'reasonCode': 'PEAK_KITCHEN', 'closedUntil': until})
    st2 = state('open all-day exception + TEMPORARY_CLOSED'); states.append(st2)
    s3, fs, _ = jreq('PUT', avail, owner, {'expectedVersion': tc.get('version'), 'mode': 'FOLLOW_SCHEDULE'})
    st3 = state('open all-day exception + FOLLOW_SCHEDULE'); states.append(st3)
    record('H19', 'hours', 'FORCE_CLOSED and active TEMPORARY_CLOSED win over an open exception; FOLLOW_SCHEDULE restores',
           ok_fc and s2 == 200 and consistent(st2, False) and s3 == 200 and consistent(st3, True),
           f'http={s},{s1},{s2},{s3}')
    s, closed_v2, _ = put(today, {'expectedVersion': v_all.get('version'), 'closed': True, 'intervals': [], 'label': 'Fermé'})
    st = state('closed exception + FOLLOW_SCHEDULE'); states.append(st)
    record('H20', 'hours', 'FOLLOW_SCHEDULE does not override a closed exception date', s == 200 and consistent(st, False),
           json.dumps(st))
    jreq('DELETE', f'{exc}/{today}?expectedVersion={closed_v2.get("version")}', owner)

    s1, f1, _ = jreq('PUT', f'/merchant/{MERCHANT}/branches/{FOREIGN_BRANCH}/opening-hours/exceptions/{tomorrow}', owner,
                     {'expectedVersion': 0, 'closed': True, 'intervals': [], 'label': 'x'})
    s2, f2, _ = jreq('GET', f'/merchant/{FOREIGN_MERCHANT}/branches/{FOREIGN_BRANCH}/opening-hours/exceptions', owner)
    foreign = sql(f"select count(*) from merchant_branch_hours_exceptions where branch_id='{FOREIGN_BRANCH}'")
    record('H21', 'hours', 'foreign branch / foreign merchant refused, no row', s1 == 404 and s2 in (403, 404) and foreign == '0',
           f'http={s1},{s2} codes={code_of(f1)},{code_of(f2)}')

    sql(f"""DO $$ BEGIN
      IF current_database() <> 'speedygo_parity_fx' THEN RAISE EXCEPTION 'refused'; END IF;
    END $$;
    INSERT INTO merchant_branches (id, merchant_id, name, phone, address_text, latitude, longitude, operational_status)
    VALUES ('{NOSCHEDULE_BRANCH}', '{MERCHANT}', 'Annexe sans horaires', '+213550009203',
            'Annexe fictive — e2e uniquement.', 36.78400, 3.05900, 'ACTIVE');""")
    s, wr, _ = jreq('PUT', f'/merchant/{MERCHANT}/branches/{NOSCHEDULE_BRANCH}/opening-hours/exceptions/{tomorrow}', owner,
                    {'expectedVersion': 0, 'closed': True, 'intervals': [], 'label': 'x'})
    record('H22', 'hours', 'branch without weekly hours → 409 OPENING_HOURS_EXCEPTION_WEEKLY_REQUIRED',
           s == 409 and code_of(wr) == 'OPENING_HOURS_EXCEPTION_WEEKLY_REQUIRED', f'http={s} code={code_of(wr)}')
    sql(f"DELETE FROM merchant_branches WHERE id = '{NOSCHEDULE_BRANCH}' AND merchant_id = '{MERCHANT}';")

    left = sql(f"select count(*) from merchant_branch_hours_exceptions where branch_id='{BRANCH}'")
    record('H23', 'hours', 'suite leaves no exception rows on the fixture branch', left == '0', f'rows={left}')
    (OUT / 'hours_states.json').write_text(json.dumps(states, indent=2, ensure_ascii=False) + '\n')
    s, cart, _ = jreq('GET', '/customer/cart', cust)
    c = (cart.get('cart') or cart) if isinstance(cart, dict) else {}
    for it in (c.get('items') or []):
        jreq('DELETE', f'/customer/cart/items/{it["id"]}', cust)


# --- atomic product duplication -------------------------------------------------------
SNAP_SQL = """select json_build_object(
  'product', (select row_to_json(p) from (select id, merchant_branch_id, category_id, name, description, price_minor::text,
              available, duplicate_request_key, created_at, updated_at from products where id = '{pid}') p),
  'groups', (select coalesce(json_agg(g order by g.created_at, g.id), '[]') from (select id, name, required, min_selections,
             max_selections, created_at, updated_at from product_option_groups where product_id = '{pid}') g),
  'options', (select coalesce(json_agg(o order by o.created_at, o.id), '[]') from (select o.id, o.option_group_id, o.name,
              o.additional_price_minor::text as price, o.available, o.created_at, o.updated_at from product_options o
              join product_option_groups g on g.id = o.option_group_id where g.product_id = '{pid}') o),
  'image', (select row_to_json(i) from (select id, object_id, content_type, byte_size, width_px, height_px, created_at,
            updated_at from product_images where product_id = '{pid}') i))"""

COUNTS_SQL = """select json_build_object('products', (select count(*) from products),
  'groups', (select count(*) from product_option_groups), 'options', (select count(*) from product_options),
  'images', (select count(*) from product_images))"""


def shape(snap):
    groups = [(g['name'], g['required'], g['min_selections'], g['max_selections']) for g in snap['groups']]
    gname = {g['id']: g['name'] for g in snap['groups']}
    options = [(gname[o['option_group_id']], o['name'], o['price'], o['available']) for o in snap['options']]
    return groups, options


def dup_suite():
    owner, manager, staff = TOKENS['OWNER'], TOKENS['MANAGER'], TOKENS['STAFF']
    pbase = f'/merchant/{MERCHANT}/products'
    img_path = lambda pid: f'/merchant/{MERCHANT}/branches/{BRANCH}/products/{pid}/image'
    src_img = png(640, 480, (210, 150, 60))
    for pid, content in ((SRC_PRODUCT, src_img), (FAIL_PRODUCT, png(500, 500, (60, 60, 160)))):
        s, up, _ = upload(img_path(pid) + '/content', owner, 'p.png', 'image/png', content)
        s2, _, _ = jreq('PUT', img_path(pid), owner, {'uploadReference': up.get('uploadReference')})
        if s2 != 200:
            record('D00', 'dup', f'fixture image bind for {pid[-4:]}', False, f'upload={s} bind={s2}')
            return

    before = sql_json(SNAP_SQL.format(pid=SRC_PRODUCT))
    s, raw_src, _ = req('GET', img_path(SRC_PRODUCT), owner)
    counts0 = sql_json(COUNTS_SQL)
    imgs0 = objects('product-images')

    r1 = str(uuid.uuid4())
    s, d1, _ = jreq('POST', f'{pbase}/{SRC_PRODUCT}/duplicate', owner, {'requestId': r1})
    prod = d1.get('product') or {}
    copy_id = prod.get('id')
    record('D01', 'dup', 'OWNER duplicate → 201, default French name, unavailable, counts reported',
           s == 201 and prod.get('name') == 'Copie de Couscous royal' and prod.get('available') is False
           and d1.get('replayed') is False and d1.get('copied') == {'optionGroupCount': 2, 'optionCount': 5, 'imageCopied': True},
           f'http={s} name={prod.get("name")} available={prod.get("available")} copied={d1.get("copied")}')
    after_copy = sql_json(SNAP_SQL.format(pid=copy_id)) if copy_id else None
    if not after_copy or not after_copy.get('product'):
        record('D02', 'dup', 'copy persisted', False, 'copy row missing')
        return
    src_ids = {before['product']['id']} | {g['id'] for g in before['groups']} | {o['id'] for o in before['options']}
    copy_ids = {after_copy['product']['id']} | {g['id'] for g in after_copy['groups']} | {o['id'] for o in after_copy['options']}
    cp, sp = after_copy['product'], before['product']
    record('D02', 'dup', 'deep copy: same branch/category/description/price, same groups/options in order, distinct IDs',
           shape(after_copy) == shape(before) and not (src_ids & copy_ids) and cp['category_id'] == sp['category_id']
           and cp['merchant_branch_id'] == sp['merchant_branch_id'] and cp['description'] == sp['description']
           and cp['price_minor'] == sp['price_minor'] and cp['duplicate_request_key'] and cp['available'] is False,
           f'groups={len(after_copy["groups"])} options={len(after_copy["options"])} shared_ids={len(src_ids & copy_ids)}')
    s, raw_copy, _ = req('GET', img_path(copy_id), owner)
    record('D03', 'dup', 'image: bytes copied to a distinct object (no shared reference)',
           s == 200 and sha(raw_copy) == sha(raw_src) and after_copy['image']['object_id'] != before['image']['object_id']
           and after_copy['image']['object_id'] in objects('product-images'),
           f'http={s} same_bytes={sha(raw_copy) == sha(raw_src)} distinct_object={after_copy["image"]["object_id"] != before["image"]["object_id"]}')
    no_history = sql(f"select (select count(*) from order_items where product_id='{copy_id}') + (select count(*) from cart_items where product_id='{copy_id}')")
    record('D04', 'dup', 'no order/cart history attached to the copy', no_history == '0', f'rows={no_history}')
    mid = sql_json(SNAP_SQL.format(pid=SRC_PRODUCT))
    record('D05', 'dup', 'original unchanged (product, groups, options, image incl. timestamps)', mid == before,
           'identical' if mid == before else 'DIFFERS')

    s, d1b, _ = jreq('POST', f'{pbase}/{SRC_PRODUCT}/duplicate', owner, {'requestId': r1})
    counts1 = sql_json(COUNTS_SQL)
    record('D06', 'dup', 'retry with the same requestId → 200 replay of the same product, nothing new',
           s == 200 and d1b.get('replayed') is True and (d1b.get('product') or {}).get('id') == copy_id
           and counts1['products'] == counts0['products'] + 1,
           f'http={s} replayed={d1b.get("replayed")} products={counts0["products"]}→{counts1["products"]}')

    r2 = str(uuid.uuid4())
    out = []
    def tap():
        out.append(jreq('POST', f'{pbase}/{SRC_PRODUCT}/duplicate', owner, {'requestId': r2}))
    th = [threading.Thread(target=tap) for _ in range(3)]
    [t.start() for t in th]
    [t.join() for t in th]
    ids = {(b.get('product') or {}).get('id') for _, b, _ in out}
    statuses = sorted(s for s, _, _ in out)
    counts2 = sql_json(COUNTS_SQL)
    record('D07', 'dup', 'three concurrent taps with one requestId → exactly one new product',
           len(ids) == 1 and None not in ids and statuses.count(201) == 1 and counts2['products'] == counts1['products'] + 1,
           f'statuses={statuses} distinct_ids={len(ids)} products={counts1["products"]}→{counts2["products"]}')

    s, dm, _ = jreq('POST', f'{pbase}/{SRC_PRODUCT}/duplicate', manager,
                    {'requestId': str(uuid.uuid4()), 'name': '  Couscous royal — format famille  '})
    record('D08', 'dup', 'MANAGER duplicate with edited name → 201, trimmed name, unavailable',
           s == 201 and (dm.get('product') or {}).get('name') == 'Couscous royal — format famille'
           and (dm.get('product') or {}).get('available') is False, f'http={s} name={(dm.get("product") or {}).get("name")}')

    c_before = sql_json(COUNTS_SQL)
    s1, b1, _ = jreq('POST', f'{pbase}/{SRC_PRODUCT}/duplicate', staff, {'requestId': str(uuid.uuid4())})
    s2, b2, _ = jreq('POST', f'{pbase}/{FOREIGN_PRODUCT}/duplicate', owner, {'requestId': str(uuid.uuid4())})
    s3, b3, _ = jreq('POST', f'/merchant/{FOREIGN_MERCHANT}/products/{FOREIGN_PRODUCT}/duplicate', owner,
                     {'requestId': str(uuid.uuid4())})
    s4, b4, _ = jreq('POST', f'{pbase}/{SRC_PRODUCT}/duplicate', owner, {'requestId': 'not-a-uuid'})
    s5, b5, _ = jreq('POST', f'{pbase}/{SRC_PRODUCT}/duplicate', owner, {'requestId': str(uuid.uuid4()), 'name': '   '})
    c_after = sql_json(COUNTS_SQL)
    record('D09', 'dup', 'STAFF 403; foreign product 404; foreign merchant refused; invalid requestId/name 400; no rows',
           s1 == 403 and s2 == 404 and s3 in (403, 404) and s4 == 400 and s5 == 400 and c_after == c_before,
           f'http={s1},{s2},{s3},{s4},{s5} codes={code_of(b1)},{code_of(b2)},{code_of(b3)},{code_of(b4)},{code_of(b5)}')

    # forced child-copy failure (temporary trigger, isolated DB only)
    fail_before = sql_json(SNAP_SQL.format(pid=FAIL_PRODUCT))
    counts_f0 = sql_json(COUNTS_SQL)
    imgs_f0 = objects('product-images')
    sql("""DO $$ BEGIN
      IF current_database() <> 'speedygo_parity_fx' OR inet_server_port() <> 5433 THEN RAISE EXCEPTION 'refused'; END IF;
    END $$;
    CREATE FUNCTION fx_fail_option_copy() RETURNS trigger LANGUAGE plpgsql AS $f$
    BEGIN
      IF NEW.name = 'Sauce piquante (fx-fail)' THEN RAISE EXCEPTION 'fx forced child-copy failure'; END IF;
      RETURN NEW;
    END $f$;
    CREATE TRIGGER fx_fail_option_copy BEFORE INSERT ON product_options
      FOR EACH ROW EXECUTE FUNCTION fx_fail_option_copy();""")
    rf = str(uuid.uuid4())
    try:
        s, fb, _ = jreq('POST', f'{pbase}/{FAIL_PRODUCT}/duplicate', owner, {'requestId': rf})
        counts_f1 = sql_json(COUNTS_SQL)
        partial = sql("select count(*) from products where name = 'Copie de Poulet rôti'")
        imgs_f1 = objects('product-images')
        record('D10', 'dup', 'forced failure on the 2nd option insert → error, zero product/group/option/image rows, copied object discarded',
               s >= 500 and counts_f1 == counts_f0 and partial == '0' and imgs_f1 == imgs_f0,
               f'http={s} code={code_of(fb)} counts_equal={counts_f1 == counts_f0} partial={partial} objects_equal={imgs_f1 == imgs_f0}')
    finally:
        sql("DROP TRIGGER IF EXISTS fx_fail_option_copy ON product_options; DROP FUNCTION IF EXISTS fx_fail_option_copy();")
    record('D11', 'dup', 'failed source unchanged', sql_json(SNAP_SQL.format(pid=FAIL_PRODUCT)) == fail_before, '')
    s, fr, _ = jreq('POST', f'{pbase}/{FAIL_PRODUCT}/duplicate', owner, {'requestId': rf})
    record('D12', 'dup', 'retry of the failed requestId after the fault is removed → 201 complete copy',
           s == 201 and fr.get('copied') == {'optionGroupCount': 1, 'optionCount': 2, 'imageCopied': True},
           f'http={s} copied={fr.get("copied")}')

    s, _, _ = jreq('DELETE', img_path(copy_id), owner)
    s2, raw_src2, _ = req('GET', img_path(SRC_PRODUCT), owner)
    record('D13', 'dup', 'deleting the copy’s image leaves the original image intact',
           s == 200 and s2 == 200 and sha(raw_src2) == sha(raw_src) and before['image']['object_id'] in objects('product-images'),
           f'delete={s} source_get={s2}')
    s, _, _ = jreq('DELETE', f'{pbase}/{copy_id}', owner)
    s2, raw_src3, _ = req('GET', img_path(SRC_PRODUCT), owner)
    final = sql_json(SNAP_SQL.format(pid=SRC_PRODUCT))
    record('D14', 'dup', 'deleting the copy product leaves the original product and image intact',
           s2 == 200 and sha(raw_src3) == sha(raw_src) and final == before, f'delete={s} source_get={s2}')
    referenced = set(sql_json("select coalesce(json_agg(object_id), '[]') from product_images") or [])
    stored = objects('product-images')
    record('D15', 'dup', 'no shared product-image object between rows; no unreferenced stored objects',
           len(referenced) == int(sql('select count(*) from product_images')) and stored == referenced,
           f'rows={sql("select count(*) from product_images")} distinct={len(referenced)} stored={len(stored)}')


def main():
    for role in ('OWNER', 'MANAGER', 'STAFF', 'CUSTOMER'):
        login(role)
    started = datetime.now(TZ).isoformat()
    try:
        for suite in (logo_suite, hours_suite, dup_suite):
            try:
                suite()
            except Exception as e:  # recorded, never hidden
                record('X', suite.__name__, 'suite raised', False, f'{type(e).__name__}: {e}'[:300])
    finally:
        logouts = {r: req('POST', '/auth/logout', t)[0] for r, t in TOKENS.items()}
        summary = {'api': BASE, 'startedAtAlgiers': started, 'finishedAtAlgiers': datetime.now(TZ).isoformat(),
                   'logoutHttp': logouts,
                   'pass': sum(r['result'] == 'PASS' for r in RESULTS),
                   'fail': sum(r['result'] == 'FAIL' for r in RESULTS), 'results': RESULTS}
        (OUT / 'contract_e2e_results.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False) + '\n')
        print(f'FX_CONTRACT_E2E pass={summary["pass"]} fail={summary["fail"]} logout={logouts}')
    return 0 if summary['fail'] == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
