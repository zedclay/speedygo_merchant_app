#!/usr/bin/env python3
"""Isolated API e2e for Merchant Catalogue & Store Contracts Completion.

Usage: fx_catalogue_store_e2e.py <out-dir> <fx_sql.sh>
"""
import json
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

BASE = 'http://127.0.0.1:3100/api/v1'
OTP = Path.home() / '.speedygo' / 'parity_fx' / 'otp' / 'otp-last'
NS = '0d00f0f0-fa00-7000-8000-'
MERCHANT = NS + '000000001001'
BRANCH = NS + '000000002001'
PRODUCT = NS + '000000007001'
CATEGORY = NS + '000000006001'
VERTICAL_ACTIVE = NS + '000000008001'
VERTICAL_INACTIVE = NS + '000000008004'
OWNER = '+213550009101'
MANAGER = '+213550009102'
STAFF = '+213550009103'

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
        raise SystemExit(f'otp request {label} http={s} code={code_of(body)}')
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
        'deviceName': f'parity-fx-csc-{label}',
    })
    if s not in (200, 201):
        raise SystemExit(f'otp verify {label} http={s}')
    TOKENS[label] = body['accessToken']
    return body['accessToken']


def logout(token):
    jreq('POST', '/auth/logout', token=token, data={})


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    owner = login(OWNER, 'OWNER')
    manager = login(MANAGER, 'MANAGER')
    staff = login(STAFF, 'STAFF')

    # --- schema probes ---
    cols = sql("""
SELECT count(*) FROM information_schema.columns
WHERE table_schema='public' AND (
  (table_name='products' AND column_name='selling_unit_code') OR
  (table_name='merchant_branches' AND column_name='description') OR
  (table_name='support_tickets' AND column_name='topic_code') OR
  (table_name='support_topics') OR
  (table_name='support_faq_articles' AND column_name='slug')
)""")
    record('C0', 'additive columns/tables present', int(cols) >= 5, f'count={cols}')

    # --- selling unit (catalog routes require branchId query) ---
    prod_path = f'/merchant/{MERCHANT}/products/{PRODUCT}?branchId={BRANCH}'
    list_path = f'/merchant/{MERCHANT}/products?branchId={BRANCH}'

    s, listed = jreq('GET', list_path, token=owner)
    items = listed.get('items') or []
    found = next((p for p in items if p.get('id') == PRODUCT), None)
    record('C1', 'legacy product sellingUnit null',
           s == 200 and found is not None and found.get('sellingUnitCode') is None,
           f'status={s} found={found is not None}')

    s, patched = jreq(
        'PATCH', prod_path, token=owner,
        data={'sellingUnitCode': 'PLAT'},
    )
    record('C2', 'OWNER sets PLAT unit',
           s == 200 and patched.get('sellingUnitCode') == 'PLAT'
           and patched.get('sellingUnitLabelFr') == 'Plat',
           f'status={s} label={patched.get("sellingUnitLabelFr")}')

    s, bad = jreq(
        'PATCH', prod_path, token=owner,
        data={'sellingUnitCode': 'KG'},
    )
    record('C3', 'weight unit KG rejected',
           s in (400, 422) or code_of(bad) is not None,
           f'status={s} code={code_of(bad)}')

    s, custom = jreq(
        'PATCH', prod_path, token=manager,
        data={'sellingUnitCode': 'CUSTOM', 'sellingUnitLabelFr': '  Marmite  '},
    )
    record('C4', 'MANAGER CUSTOM unit with label',
           s == 200 and custom.get('sellingUnitCode') == 'CUSTOM'
           and custom.get('sellingUnitLabelFr') == 'Marmite',
           f'status={s}')

    s, staff_deny = jreq(
        'PATCH', prod_path, token=staff,
        data={'sellingUnitCode': 'PIECE'},
    )
    record('C5', 'STAFF cannot edit selling unit',
           s in (403, 404), f'status={s} code={code_of(staff_deny)}')

    s, cleared = jreq(
        'PATCH', prod_path, token=owner,
        data={'sellingUnitCode': None},
    )
    record('C6', 'clear selling unit to null',
           s == 200 and cleared.get('sellingUnitCode') is None,
           f'status={s}')

    # --- store information ---
    s, branch = jreq(
        'PATCH', f'/merchant/{MERCHANT}/branches/{BRANCH}', token=owner,
        data={
            'description': 'Cuisine familiale d’essai.',
            'nameAr': 'مختبر',
            'publicEmail': 'comptoir@example.test',
        },
    )
    record('C7', 'OWNER patches store info fields',
           s == 200
           and branch.get('description') == 'Cuisine familiale d’essai.'
           and branch.get('nameAr') == 'مختبر'
           and branch.get('publicEmail') == 'comptoir@example.test',
           f'status={s}')

    s, bad_email = jreq(
        'PATCH', f'/merchant/{MERCHANT}/branches/{BRANCH}', token=owner,
        data={'publicEmail': 'not-an-email'},
    )
    record('C8', 'invalid publicEmail rejected',
           s in (400, 422), f'status={s} code={code_of(bad_email)}')

    s, staff_branch = jreq(
        'PATCH', f'/merchant/{MERCHANT}/branches/{BRANCH}', token=staff,
        data={'description': 'hack'},
    )
    record('C9', 'STAFF cannot patch store info',
           s in (403, 404), f'status={s}')

    s, branches = jreq('GET', f'/merchant/{MERCHANT}/branches', token=manager)
    blist = branches.get('branches') or branches.get('items') or []
    if isinstance(branches, list):
        blist = branches
    b = next((x for x in blist if x.get('id') == BRANCH), {})
    record('C10', 'MANAGER reopens persisted store info',
           s == 200 and b.get('description') == 'Cuisine familiale d’essai.',
           f'status={s} desc={b.get("description")!r}')

    # --- category ---
    s, verts = jreq('GET', '/merchant/commerce-verticals', token=staff)
    items = verts.get('items') or []
    active_ids = {i.get('id') for i in items}
    record('C11', 'commerce-verticals active only (items)',
           s == 200 and VERTICAL_ACTIVE in active_ids
           and VERTICAL_INACTIVE not in active_ids
           and len(items) >= 3,
           f'status={s} n={len(items)}')

    s, assigned = jreq(
        'PUT',
        f'/merchant/{MERCHANT}/branches/{BRANCH}/classification',
        token=owner,
        data={'verticalId': VERTICAL_ACTIVE},
    )
    record('C12', 'OWNER assigns classification',
           s == 200
           and (assigned.get('classification') or {}).get('verticalId')
           == VERTICAL_ACTIVE,
           f'status={s}')

    s, inactive = jreq(
        'PUT',
        f'/merchant/{MERCHANT}/branches/{BRANCH}/classification',
        token=owner,
        data={'verticalId': VERTICAL_INACTIVE},
    )
    record('C13', 'inactive vertical rejected',
           s in (400, 404), f'status={s} code={code_of(inactive)}')

    s, staff_cls = jreq(
        'PUT',
        f'/merchant/{MERCHANT}/branches/{BRANCH}/classification',
        token=staff,
        data={'verticalId': VERTICAL_ACTIVE},
    )
    record('C14', 'STAFF cannot assign classification',
           s in (403, 404), f'status={s}')

    s, cleared_cls = jreq(
        'DELETE',
        f'/merchant/{MERCHANT}/branches/{BRANCH}/classification',
        token=manager,
    )
    record('C15', 'MANAGER clears classification',
           s == 200 and cleared_cls.get('classification') is None,
           f'status={s}')

    # --- support ---
    s, topics = jreq('GET', f'/merchant/{MERCHANT}/support/topics', token=owner)
    topic_list = topics.get('topics') or topics.get('items') or []
    codes = {t.get('code') for t in topic_list}
    record('C16', 'support topics seeded for Merchant',
           s == 200 and 'ORDER_ISSUE' in codes and len(topic_list) >= 2,
           f'status={s} n={len(topic_list)}')

    s, faq = jreq('GET', f'/merchant/{MERCHANT}/support/faq', token=owner)
    articles = faq.get('articles') or faq.get('items') or []
    record('C17', 'support FAQ articles present',
           s == 200 and len(articles) >= 1
           and all(a.get('titleFr') and a.get('bodyFr') for a in articles),
           f'status={s} n={len(articles)}')

    s, no_topic = jreq(
        'POST', f'/merchant/{MERCHANT}/support', token=owner,
        data={'body': 'x' * 20},
    )
    record('C18', 'create without topic/subject rejected',
           s in (400, 422), f'status={s} code={code_of(no_topic)}')

    topic_code = next(iter(codes)) if codes else 'ORDER_ISSUE'
    s, ticket = jreq(
        'POST', f'/merchant/{MERCHANT}/support', token=owner,
        data={
            'subject': 'Retard de commande FX',
            'topicCode': topic_code,
            'body': 'Commande de test isolée — délai anormal.',
        },
    )
    record('C19', 'create ticket with topic+subject',
           s in (200, 201)
           and (ticket.get('subject') == 'Retard de commande FX'
                or ticket.get('publicReference')),
           f'status={s} ref={ticket.get("publicReference")}')

    s, staff_sup = jreq(
        'POST', f'/merchant/{MERCHANT}/support', token=staff,
        data={
            'subject': 'x', 'topicCode': topic_code,
            'body': 'staff should not create',
        },
    )
    record('C20', 'STAFF cannot create support ticket',
           s in (403, 404), f'status={s}')

    # restore product unit cleared earlier is fine; restore branch description optional
    for label, token in list(TOKENS.items()):
        logout(token)

    _finish(0 if all(r['result'] == 'PASS' for r in RESULTS) else 1)


def _finish(code):
    summary = {
        'suite': 'merchant_catalogue_store_contracts_completion',
        'pass': sum(1 for r in RESULTS if r['result'] == 'PASS'),
        'fail': sum(1 for r in RESULTS if r['result'] == 'FAIL'),
        'results': RESULTS,
    }
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'RESULTS.json').write_text(json.dumps(summary, indent=2) + '\n')
    print(json.dumps({'pass': summary['pass'], 'fail': summary['fail'], 'exit': code}))
    raise SystemExit(code)


if __name__ == '__main__':
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:
        record('CX', 'unexpected error', False, str(exc)[:200])
        _finish(1)
