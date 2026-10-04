#!/usr/bin/env python3
"""Isolated API e2e for Merchant Verification Contract Completion (rows 71–77).

Invoked by fx_verification_e2e.sh against http://127.0.0.1:3100/api/v1 only.
Reads OTPs from the isolated capture file; seeds a loginable admin via fx_sql.sh
(speedygo_parity_fx only). Never prints tokens, OTPs or connection strings.
Usage: fx_verification_e2e.py <out-dir> <fx_sql.sh>
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
OWNER_PHONE = '+213550009191'
ADMIN_PHONE = '+213550009192'
ADMIN_ACCOUNT = '0d00f0f0-fa00-7000-8000-000000009191'
ADMIN_ROLE = '0d00f0f0-fa00-7000-8000-000000009192'
ADMIN_PROFILE = '0d00f0f0-fa00-7000-8000-000000009193'
PERM_READ = '0d00f0f0-fa00-7000-8000-000000009194'
PERM_VERIFY = '0d00f0f0-fa00-7000-8000-000000009195'

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
        raise RuntimeError(
            f'fx_sql failed rc={p.returncode}: {p.stderr.strip()[:300]}',
        )
    return p.stdout.strip()


def login(phone, label):
    before = time.time() - 1
    s, body = jreq('POST', '/auth/otp/request', data={
        'channel': 'PHONE', 'identifier': phone, 'purpose': 'AUTHENTICATE',
    })
    if s not in (200, 201, 202):
        raise SystemExit(f'otp request refused for {label} http={s} code={code_of(body)}')
    otp = None
    for _ in range(80):
        if OTP.exists() and OTP.stat().st_mtime >= before:
            otp = OTP.read_text().strip()
            if otp.isdigit():
                break
        time.sleep(0.25)
    if not otp:
        raise SystemExit(f'isolated OTP capture not found for {label}')
    s, body = jreq('POST', '/auth/otp/verify', data={
        'channel': 'PHONE', 'identifier': phone, 'purpose': 'AUTHENTICATE',
        'code': otp, 'platform': 'ios', 'appVersion': '1.0.0',
        'deviceName': f'parity-fx-verification-{label}',
    })
    if s not in (200, 201):
        raise SystemExit(f'otp verify failed for {label} http={s} code={code_of(body)}')
    TOKENS[label] = body['accessToken']
    return body['accessToken']


def logout(token):
    jreq('POST', '/auth/logout', token=token, data={})


def seed_admin():
    sql(f"""
DO $$
BEGIN
  IF current_database() <> 'speedygo_parity_fx' OR inet_server_port() <> 5433 THEN
    RAISE EXCEPTION 'refused: expected speedygo_parity_fx on 5433';
  END IF;
END $$;
INSERT INTO accounts (id, phone, email, status)
VALUES ('{ADMIN_ACCOUNT}', '{ADMIN_PHONE}', NULL, 'ACTIVE')
ON CONFLICT (id) DO NOTHING;
INSERT INTO roles (id, name, description, active)
VALUES ('{ADMIN_ROLE}', 'parity-fx-verification-admin',
        'Disposable: merchants.read + merchants.verify', TRUE)
ON CONFLICT (id) DO NOTHING;
INSERT INTO permissions (id, code, description) VALUES
  ('{PERM_READ}', 'merchants.read', 'fx verification e2e'),
  ('{PERM_VERIFY}', 'merchants.verify', 'fx verification e2e')
ON CONFLICT (code) DO NOTHING;
INSERT INTO role_permissions (role_id, permission_id)
SELECT '{ADMIN_ROLE}', p.id FROM permissions p
WHERE p.code IN ('merchants.read', 'merchants.verify')
ON CONFLICT (role_id, permission_id) DO NOTHING;
INSERT INTO admin_profiles (id, account_id, role_id, display_name, two_factor_enabled)
VALUES ('{ADMIN_PROFILE}', '{ADMIN_ACCOUNT}', '{ADMIN_ROLE}',
        'Parity FX Verification Admin', FALSE)
ON CONFLICT (id) DO NOTHING;
""")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    seed_admin()
    tables = sql("""
SELECT count(*) FROM information_schema.tables
WHERE table_schema='public' AND table_name IN (
  'legal_document_versions','merchant_verification_submissions',
  'merchant_legal_acceptances','merchant_verification_issues')
""")
    record('V0', 'schema tables present', tables == '4', f'count={tables}')

    owner = login(OWNER_PHONE, 'OWNER')
    admin = login(ADMIN_PHONE, 'ADMIN')

    # Legal current seeds defaults when empty
    s, legal = jreq('GET', '/merchant/legal/current', token=owner)
    versions = {v['kind']: v['version'] for v in legal.get('versions', [])}
    record('V1', 'GET legal/current seeds both kinds',
           s == 200
           and versions.get('MERCHANT_TERMS') == '2026-10-03'
           and versions.get('DOSSIER_ACCURACY_DECLARATION') == '2026-10-03',
           f'status={s} kinds={sorted(versions)}')

    s, created = jreq('POST', '/merchant/profile', token=owner,
                      data={'name': 'Dossier Contrat FX'})
    record('V2', 'create PENDING merchant',
           s == 201 and created.get('merchant', {}).get('status') == 'PENDING_REVIEW',
           f'status={s}')
    if s != 201:
        _finish(1)
    mid = created['merchantId']

    s, empty = jreq('POST', f'/merchant/{mid}/verification/submit', token=owner,
                    data={})
    record('V3', 'submit without acceptances → LEGAL_ACCEPTANCE_REQUIRED or NOT_READY',
           s in (400, 409)
           and code_of(empty) in (
               'LEGAL_ACCEPTANCE_REQUIRED', 'MERCHANT_VERIFICATION_NOT_READY',
           ),
           f'status={s} code={code_of(empty)}')

    for dtype, body in (
        ('BUSINESS_IDENTITY', {}),
        ('BUSINESS_REGISTRATION', {'expiryDate': '2099-01-01'}),
    ):
        s, _ = jreq(
            'PUT', f'/merchant/{mid}/verification/documents/{dtype}',
            token=owner, data=body,
        )
        if s != 200:
            record('V4', f'upsert {dtype}', False, f'status={s}')
            _finish(1)
    record('V4', 'required documents PENDING', True)

    s, no_consent = jreq(
        'POST', f'/merchant/{mid}/verification/submit', token=owner, data={},
    )
    record('V5', 'ready but empty acceptances → LEGAL_ACCEPTANCE_REQUIRED',
           s == 400 and code_of(no_consent) == 'LEGAL_ACCEPTANCE_REQUIRED',
           f'status={s} code={code_of(no_consent)}')

    s, outdated = jreq(
        'POST', f'/merchant/{mid}/verification/submit', token=owner,
        data={'acceptances': [
            {'kind': 'MERCHANT_TERMS', 'version': '1999-01-01'},
            {'kind': 'DOSSIER_ACCURACY_DECLARATION', 'version': '2026-10-03'},
        ]},
    )
    record('V6', 'outdated terms → LEGAL_VERSION_OUTDATED',
           s == 400 and code_of(outdated) == 'LEGAL_VERSION_OUTDATED',
           f'status={s} code={code_of(outdated)}')

    acceptances = [
        {'kind': 'MERCHANT_TERMS', 'version': versions['MERCHANT_TERMS']},
        {'kind': 'DOSSIER_ACCURACY_DECLARATION',
         'version': versions['DOSSIER_ACCURACY_DECLARATION']},
    ]
    s, submitted = jreq(
        'POST', f'/merchant/{mid}/verification/submit', token=owner,
        data={'acceptances': acceptances},
    )
    ok_sub = (
        s == 200
        and submitted.get('verificationSubmitted') is True
        and submitted.get('attemptNumber') == 1
        and submitted.get('legalAcceptance') is not None
        and submitted.get('merchant', {}).get('status') == 'PENDING_REVIEW'
    )
    record('V7', 'submit with consent creates attempt 1', ok_sub,
           f'status={s} attempt={submitted.get("attemptNumber")} '
           f'submittedAt={bool(submitted.get("submittedAt"))}')

    sub_count = sql(
        f"SELECT count(*) FROM merchant_verification_submissions "
        f"WHERE merchant_id='{mid}' AND outcome='PENDING_REVIEW'",
    )
    acc_count = sql(
        f"SELECT count(*) FROM merchant_legal_acceptances "
        f"WHERE merchant_id='{mid}'",
    )
    record('V8', 'DB submission + 2 acceptances',
           sub_count == '1' and acc_count == '2',
           f'sub={sub_count} acc={acc_count}')

    issues = [
        {
            'scope': 'APPLICATION',
            'code': 'PROFILE_INCOMPLETE',
            'messageFr': 'Complétez le nom commercial.',
        },
        {
            'scope': 'DOCUMENT',
            'code': 'DOCUMENT_ILLEGIBLE',
            'messageFr': 'Pièce d’identité illisible.',
            'documentType': 'BUSINESS_IDENTITY',
        },
    ]
    s, rejected = jreq(
        'POST', f'/admin/merchants/{mid}/verification/reject',
        token=admin, data={'issues': issues},
    )
    record('V9', 'admin reject with structured issues',
           s in (200, 201)
           and rejected.get('status') == 'REJECTED',
           f'status={s} merchant={rejected.get("status")}')

    s, pkg = jreq('GET', f'/merchant/{mid}/verification', token=owner)
    current = pkg.get('currentIssues') or []
    record('V10', 'OWNER sees currentIssues after reject',
           s == 200
           and pkg.get('status') == 'REJECTED'
           and len(current) >= 2
           and pkg.get('unresolvedIssueCount', 0) >= 2
           and any(i.get('scope') == 'DOCUMENT' for i in current),
           f'status={s} merchantStatus={pkg.get("status")} '
           f'issues={len(current)} count={pkg.get("unresolvedIssueCount")}')

    s, rebound = jreq(
        'PUT', f'/merchant/{mid}/verification/documents/BUSINESS_IDENTITY',
        token=owner, data={},
    )
    # Membership view after rebind; package-style fields are flat on membership too.
    issues_after = rebound.get('currentIssues') or []
    doc_open = [
        i for i in issues_after
        if i.get('scope') == 'DOCUMENT'
        and i.get('documentType') == 'BUSINESS_IDENTITY'
    ]
    record('V11', 'rebind IDENTITY resolves DOCUMENT issue',
           s == 200 and len(doc_open) == 0,
           f'status={s} doc_open={len(doc_open)}')

    s, resub = jreq(
        'POST', f'/merchant/{mid}/verification/submit', token=owner,
        data={'acceptances': acceptances},
    )
    record('V12', 'resubmit after reject → attempt 2',
           s == 200
           and resub.get('attemptNumber') == 2
           and resub.get('merchant', {}).get('status') == 'PENDING_REVIEW'
           and resub.get('verificationSubmitted') is True,
           f'status={s} attempt={resub.get("attemptNumber")}')

    s, approved = jreq(
        'POST', f'/admin/merchants/{mid}/verification/approve',
        token=admin, data={},
    )
    record('V13', 'admin approve stamps ACTIVE',
           s in (200, 201)
           and approved.get('status') == 'ACTIVE'
           and approved.get('verifiedAt') is not None,
           f'status={s} merchant={approved.get("status")}')

    s, final = jreq('GET', f'/merchant/{mid}/verification', token=owner)
    record('V14', 'OWNER package after approve',
           s == 200
           and final.get('status') == 'ACTIVE'
           and final.get('attemptNumber') == 2
           and final.get('reviewedAt') is not None
           and final.get('verifiedAt') is not None
           and final.get('unresolvedIssueCount', 0) == 0,
           f'status={s} merchantStatus={final.get("status")} '
           f'attempt={final.get("attemptNumber")} '
           f'reviewedAt={bool(final.get("reviewedAt"))} '
           f'issues={final.get("unresolvedIssueCount")}')

    # Isolation probe: legal tables must exist only on fx (count via fx sql)
    legal_rows = sql('SELECT count(*) FROM legal_document_versions')
    record('V15', 'legal_document_versions seeded on fx',
           int(legal_rows) >= 2, f'rows={legal_rows}')

    for label, token in list(TOKENS.items()):
        logout(token)

    _finish(0 if all(r['result'] == 'PASS' for r in RESULTS) else 1)


def _finish(code):
    OUT.mkdir(parents=True, exist_ok=True)
    summary = {
        'suite': 'merchant_verification_contract_completion',
        'pass': sum(1 for r in RESULTS if r['result'] == 'PASS'),
        'fail': sum(1 for r in RESULTS if r['result'] == 'FAIL'),
        'results': RESULTS,
    }
    (OUT / 'RESULTS.json').write_text(json.dumps(summary, indent=2) + '\n')
    print(json.dumps({
        'pass': summary['pass'], 'fail': summary['fail'],
        'exit': code,
    }))
    raise SystemExit(code)


if __name__ == '__main__':
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:
        record('VX', 'unexpected error', False, str(exc)[:200])
        _finish(1)
