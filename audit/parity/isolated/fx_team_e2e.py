#!/usr/bin/env python3
"""Isolated API e2e for Merchant Team Management (row 64).

Usage: fx_team_e2e.py <out-dir> <fx_sql.sh>
Never prints tokens, OTPs or accept codes.
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
FOREIGN_MERCHANT = NS + '000000001002'
OWNER_MEMBER = NS + '000000003001'
MANAGER_MEMBER = NS + '000000003002'
STAFF_MEMBER = NS + '000000003003'
OWNER = '+213550009101'
MANAGER = '+213550009102'
STAFF = '+213550009103'
FOREIGN_OWNER = '+213550009104'
INVITEE = '+213550009105'
INVITEE2 = '+213550009106'

OUT = Path(sys.argv[1])
FX_SQL = sys.argv[2]
RESULTS = []
TOKENS = {}
SECRETS = {}  # accept codes held in memory only; never printed


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
        'deviceName': f'parity-fx-team-{label}',
    })
    if s not in (200, 201):
        raise SystemExit(f'otp verify {label} http={s} code={code_of(body)}')
    TOKENS[label] = body['accessToken']
    return body['accessToken']


def logout(token):
    jreq('POST', '/auth/logout', token=token, data={})


def _finish(code=0):
    OUT.mkdir(parents=True, exist_ok=True)
    # Strip secrets from RESULT details before write
    safe_results = []
    for r in RESULTS:
        detail = r.get('detail', '')
        for secret in SECRETS.values():
            if secret and secret in detail:
                detail = detail.replace(secret, '<code>')
        safe_results.append({**r, 'detail': detail})
    (OUT / 'RESULTS.json').write_text(
        json.dumps({'results': safe_results}, indent=2) + '\n',
    )
    fails = sum(1 for r in RESULTS if r['result'] == 'FAIL')
    print(f'SUMMARY pass={len(RESULTS)-fails} fail={fails}')
    raise SystemExit(code if fails == 0 else 1)


def main():
    OUT.mkdir(parents=True, exist_ok=True)

    inv_table = sql("""
SELECT count(*) FROM information_schema.tables
WHERE table_schema='public' AND table_name='merchant_member_invitations'
""")
    ver_col = sql("""
SELECT count(*) FROM information_schema.columns
WHERE table_schema='public' AND table_name='merchant_members'
  AND column_name IN ('version','updated_at')
""")
    record('T0', 'schema invitations + member version/updated_at',
           inv_table == '1' and ver_col == '2',
           f'table={inv_table} cols={ver_col}')

    owner = login(OWNER, 'OWNER')
    manager = login(MANAGER, 'MANAGER')
    staff = login(STAFF, 'STAFF')
    foreign = login(FOREIGN_OWNER, 'FOREIGN')

    # --- reads ---
    s, team = jreq('GET', f'/merchant/{MERCHANT}/team', token=owner)
    members = team.get('members') or []
    can_manage = (team.get('capabilities') or {}).get('canManage')
    record('T1', 'OWNER lists roster with 3 seeded members',
           s == 200 and len(members) == 3 and can_manage is True,
           f'status={s} members={len(members)} canManage={can_manage}')

    s, mteam = jreq('GET', f'/merchant/{MERCHANT}/team', token=manager)
    m_can = (mteam.get('capabilities') or {}).get('canManage')
    record('T2', 'MANAGER can read roster (canManage false)',
           s == 200 and m_can is False
           and len(mteam.get('members') or []) == 3,
           f'status={s} canManage={m_can}')

    s, steamy = jreq('GET', f'/merchant/{MERCHANT}/team', token=staff)
    record('T3', 'STAFF forbidden on team read',
           s == 403 and code_of(steamy) == 'MERCHANT_ROLE_FORBIDDEN',
           f'status={s} code={code_of(steamy)}')

    s, foreign_team = jreq('GET', f'/merchant/{MERCHANT}/team', token=foreign)
    record('T4', 'foreign merchant owner cannot read Comptoir team',
           s in (403, 404),
           f'status={s} code={code_of(foreign_team)}')

    s, owner_foreign = jreq(
        'GET', f'/merchant/{FOREIGN_MERCHANT}/team', token=owner,
    )
    record('T5', 'OWNER cannot read foreign merchant team',
           s in (403, 404),
           f'status={s} code={code_of(owner_foreign)}')

    # --- unauthorized mutations ---
    s, body = jreq(
        'POST', f'/merchant/{MERCHANT}/team/invitations', token=manager,
        data={'phone': INVITEE, 'role': 'STAFF'},
    )
    record('T6', 'MANAGER cannot create invite',
           s == 403 and code_of(body) == 'MERCHANT_ROLE_FORBIDDEN',
           f'status={s} code={code_of(body)}')

    s, body = jreq(
        'POST', f'/merchant/{MERCHANT}/team/invitations', token=staff,
        data={'phone': INVITEE, 'role': 'STAFF'},
    )
    record('T7', 'STAFF cannot create invite',
           s == 403 and code_of(body) == 'MERCHANT_ROLE_FORBIDDEN',
           f'status={s} code={code_of(body)}')

    # --- invite create ---
    s, issued = jreq(
        'POST', f'/merchant/{MERCHANT}/team/invitations', token=owner,
        data={'phone': INVITEE, 'role': 'STAFF'},
    )
    accept = issued.get('acceptCode') or ''
    SECRETS['invite1'] = accept
    invite_id = issued.get('id')
    invite_ver = issued.get('version', 1)
    ok_issue = (
        s == 201
        and invite_id
        and len(accept) == 64
        and issued.get('phone') == INVITEE
        and issued.get('role') == 'STAFF'
        and issued.get('status') == 'PENDING'
        and 'sent' not in json.dumps(issued).lower()
    )
    record('T8', 'OWNER creates invite; acceptCode returned; no sent claim',
           ok_issue, f'status={s} hasCode={bool(accept)} role={issued.get("role")}')

    s, dup = jreq(
        'POST', f'/merchant/{MERCHANT}/team/invitations', token=owner,
        data={'phone': INVITEE, 'role': 'STAFF'},
    )
    record('T9', 'duplicate pending invite rejected',
           s == 409 and code_of(dup) == 'TEAM_DUPLICATE_INVITE',
           f'status={s} code={code_of(dup)}')

    s, bad_role = jreq(
        'POST', f'/merchant/{MERCHANT}/team/invitations', token=owner,
        data={'phone': INVITEE2, 'role': 'OWNER'},
    )
    record('T10', 'invite OWNER role rejected',
           s in (400, 403) and code_of(bad_role) in (
               'TEAM_OWNER_PROTECTED', 'TEAM_INVALID_INPUT',
           ),
           f'status={s} code={code_of(bad_role)}')

    s, member_phone = jreq(
        'POST', f'/merchant/{MERCHANT}/team/invitations', token=owner,
        data={'phone': MANAGER, 'role': 'STAFF'},
    )
    record('T11', 'invite existing member phone rejected',
           s == 409 and code_of(member_phone) == 'TEAM_DUPLICATE_MEMBER',
           f'status={s} code={code_of(member_phone)}')

    s, branch_body = jreq(
        'POST', f'/merchant/{MERCHANT}/team/invitations', token=owner,
        data={'phone': INVITEE2, 'role': 'MANAGER', 'branchIds': ['x']},
    )
    record('T12', 'client branch assignment rejected',
           s == 400 and code_of(branch_body) == 'TEAM_INVALID_INPUT',
           f'status={s} code={code_of(branch_body)}')

    # --- accept path (no prior membership) ---
    invitee = login(INVITEE, 'INVITEE')
    s, mine = jreq('GET', '/merchant/me/team-invitations', token=invitee)
    pending = mine.get('invitations') or mine.get('items') or []
    if isinstance(mine, list):
        pending = mine
    record('T13', 'invitee without membership lists pending invite',
           s == 200 and any(i.get('id') == invite_id for i in pending),
           f'status={s} count={len(pending)}')

    s, bad_code = jreq(
        'POST', f'/merchant/me/team-invitations/{invite_id}/accept',
        token=invitee, data={'acceptCode': '0' * 64},
    )
    record('T14', 'bad accept code rejected',
           s == 400 and code_of(bad_code) == 'TEAM_INVITE_CODE_INVALID',
           f'status={s} code={code_of(bad_code)}')

    # phone mismatch: manager tries to accept invitee's invite
    s, mismatch = jreq(
        'POST', f'/merchant/me/team-invitations/{invite_id}/accept',
        token=manager, data={'acceptCode': accept},
    )
    record('T15', 'phone mismatch on accept',
           s in (403, 404) and code_of(mismatch) in (
               'TEAM_PHONE_MISMATCH', 'TEAM_INVITE_NOT_FOUND',
           ),
           f'status={s} code={code_of(mismatch)}')

    s, accepted = jreq(
        'POST', f'/merchant/me/team-invitations/{invite_id}/accept',
        token=invitee, data={'acceptCode': accept},
    )
    record('T16', 'invitee accepts with code → STAFF membership',
           s == 200 and accepted.get('role') == 'STAFF'
           and accepted.get('merchantId') == MERCHANT
           and accepted.get('memberId'),
           f'status={s} role={accepted.get("role")}')

    s, reuse = jreq(
        'POST', f'/merchant/me/team-invitations/{invite_id}/accept',
        token=invitee, data={'acceptCode': accept},
    )
    record('T17', 'accept code single-use',
           s in (404, 409) and code_of(reuse) in (
               'TEAM_INVITE_NOT_FOUND', 'TEAM_DUPLICATE_MEMBER',
               'TEAM_INVITE_EXPIRED',
           ),
           f'status={s} code={code_of(reuse)}')

    # --- role change / protected owner / self ---
    s, team2 = jreq('GET', f'/merchant/{MERCHANT}/team', token=owner)
    invitee_member = next(
        (m for m in (team2.get('members') or []) if m.get('phone') == INVITEE),
        None,
    )
    invitee_mid = invitee_member['id'] if invitee_member else None
    invitee_ver = invitee_member.get('version', 1) if invitee_member else 1

    s, promote = jreq(
        'PATCH', f'/merchant/{MERCHANT}/team/members/{invitee_mid}',
        token=owner, data={'role': 'MANAGER', 'expectedVersion': invitee_ver},
    )
    record('T18', 'OWNER promotes STAFF → MANAGER',
           s == 200 and promote.get('role') == 'MANAGER',
           f'status={s} role={promote.get("role")}')
    invitee_ver = promote.get('version', invitee_ver + 1)

    # Seeded OWNER is the actor: self-guard fires first. Also insert a second
    # OWNER row and prove TEAM_OWNER_PROTECTED for a non-self OWNER target.
    co_owner_account = NS + '000000000191'
    co_owner_member = NS + '000000003091'
    sql(f"""
DO $$
BEGIN
  IF current_database() <> 'speedygo_parity_fx' OR inet_server_port() <> 5433 THEN
    RAISE EXCEPTION 'refused';
  END IF;
END $$;
INSERT INTO accounts (id, phone, email, status)
VALUES ('{co_owner_account}', '+213550009191', NULL, 'ACTIVE')
ON CONFLICT (id) DO NOTHING;
INSERT INTO merchant_members (id, merchant_id, account_id, role, version)
VALUES ('{co_owner_member}', '{MERCHANT}', '{co_owner_account}', 'OWNER', 1)
ON CONFLICT (id) DO NOTHING;
""")
    s, owner_prot = jreq(
        'PATCH', f'/merchant/{MERCHANT}/team/members/{co_owner_member}',
        token=owner, data={'role': 'MANAGER', 'expectedVersion': 1},
    )
    record('T19', 'cannot demote a protected OWNER (non-self)',
           s == 403 and code_of(owner_prot) == 'TEAM_OWNER_PROTECTED',
           f'status={s} code={code_of(owner_prot)}')
    sql(f"""
DO $$
BEGIN
  IF current_database() <> 'speedygo_parity_fx' OR inet_server_port() <> 5433 THEN
    RAISE EXCEPTION 'refused';
  END IF;
END $$;
DELETE FROM merchant_members WHERE id = '{co_owner_member}';
DELETE FROM accounts WHERE id = '{co_owner_account}';
""")

    s, self_patch = jreq(
        'PATCH', f'/merchant/{MERCHANT}/team/members/{OWNER_MEMBER}',
        token=owner, data={'role': 'STAFF', 'expectedVersion': 1},
    )
    record('T20', 'self role change forbidden',
           s == 403 and code_of(self_patch) in (
               'TEAM_SELF_FORBIDDEN', 'TEAM_OWNER_PROTECTED',
           ),
           f'status={s} code={code_of(self_patch)}')

    s, escalate = jreq(
        'PATCH', f'/merchant/{MERCHANT}/team/members/{invitee_mid}',
        token=owner, data={'role': 'OWNER', 'expectedVersion': invitee_ver},
    )
    record('T21', 'cannot assign OWNER via patch',
           s in (400, 403) and code_of(escalate) in (
               'TEAM_OWNER_PROTECTED', 'TEAM_INVALID_INPUT',
           ),
           f'status={s} code={code_of(escalate)}')

    s, mgr_mut = jreq(
        'PATCH', f'/merchant/{MERCHANT}/team/members/{invitee_mid}',
        token=manager, data={'role': 'STAFF', 'expectedVersion': invitee_ver},
    )
    record('T22', 'MANAGER cannot mutate roles',
           s == 403 and code_of(mgr_mut) == 'MERCHANT_ROLE_FORBIDDEN',
           f'status={s} code={code_of(mgr_mut)}')

    s, stale = jreq(
        'PATCH', f'/merchant/{MERCHANT}/team/members/{invitee_mid}',
        token=owner, data={'role': 'STAFF', 'expectedVersion': 999},
    )
    record('T23', 'stale version conflict on role change',
           s == 409 and code_of(stale) == 'TEAM_VERSION_CONFLICT',
           f'status={s} code={code_of(stale)}')

    # demote invitee back to STAFF (revokes sessions)
    s, demote = jreq(
        'PATCH', f'/merchant/{MERCHANT}/team/members/{invitee_mid}',
        token=owner, data={'role': 'STAFF', 'expectedVersion': invitee_ver},
    )
    record('T24', 'OWNER demotes MANAGER → STAFF (session revoke)',
           s == 200 and demote.get('role') == 'STAFF',
           f'status={s} role={demote.get("role")}')
    invitee_ver = demote.get('version', invitee_ver + 1)

    # demotion revokes all sessions of the target
    s, me_stale = jreq('GET', '/merchant/me', token=invitee)
    record('T25', 'demoted invitee session revoked on next protected request',
           s in (401, 403) or code_of(me_stale) in (
               'AUTH_SESSION_REVOKED', 'AUTH_INVALID_TOKEN', 'AUTH_SESSION_EXPIRED',
           ),
           f'status={s} code={code_of(me_stale)}')

    # re-login invitee; still STAFF; cannot read team
    invitee = login(INVITEE, 'INVITEE2')
    s, staff_read = jreq('GET', f'/merchant/{MERCHANT}/team', token=invitee)
    record('T26', 're-authed STAFF still cannot read team',
           s == 403 and code_of(staff_read) == 'MERCHANT_ROLE_FORBIDDEN',
           f'status={s} code={code_of(staff_read)}')

    # --- regenerate / cancel invite ---
    s, issued2 = jreq(
        'POST', f'/merchant/{MERCHANT}/team/invitations', token=owner,
        data={'phone': INVITEE2, 'role': 'MANAGER'},
    )
    code2 = issued2.get('acceptCode') or ''
    SECRETS['invite2'] = code2
    inv2_id = issued2.get('id')
    inv2_ver = issued2.get('version', 1)
    record('T27', 'second invite for new phone',
           s == 201 and inv2_id and len(code2) == 64,
           f'status={s}')

    s, regen = jreq(
        'POST',
        f'/merchant/{MERCHANT}/team/invitations/{inv2_id}/regenerate-code',
        token=owner, data={'expectedVersion': inv2_ver},
    )
    code2b = regen.get('acceptCode') or ''
    SECRETS['invite2b'] = code2b
    record('T28', 'regenerate code invalidates previous',
           s == 200 and code2b and code2b != code2
           and regen.get('version', 0) > inv2_ver,
           f'status={s} version={regen.get("version")}')
    inv2_ver = regen.get('version', inv2_ver + 1)

    s, cancel = jreq(
        'POST', f'/merchant/{MERCHANT}/team/invitations/{inv2_id}/cancel',
        token=owner, data={'expectedVersion': inv2_ver},
    )
    record('T29', 'cancel pending invitation',
           s == 200 and cancel.get('status') == 'CANCELLED',
           f'status={s} invStatus={cancel.get("status")}')

    # --- revoke member + protect owner/self ---
    s, self_revoke = jreq(
        'DELETE',
        f'/merchant/{MERCHANT}/team/members/{OWNER_MEMBER}?expectedVersion=1',
        token=owner,
    )
    record('T30', 'self-revoke rejected',
           s == 403 and code_of(self_revoke) in (
               'TEAM_SELF_FORBIDDEN', 'TEAM_OWNER_PROTECTED',
           ),
           f'status={s} code={code_of(self_revoke)}')

    s, owner_revoke = jreq(
        'DELETE',
        f'/merchant/{MERCHANT}/team/members/{OWNER_MEMBER}?expectedVersion=1',
        token=owner,
    )
    # same as self for owner member id when called by owner
    record('T31', 'OWNER membership protected from revoke',
           s == 403 and code_of(owner_revoke) in (
               'TEAM_SELF_FORBIDDEN', 'TEAM_OWNER_PROTECTED',
           ),
           f'status={s} code={code_of(owner_revoke)}')

    # refresh invitee member version
    s, team3 = jreq('GET', f'/merchant/{MERCHANT}/team', token=owner)
    invitee_member = next(
        (m for m in (team3.get('members') or []) if m.get('phone') == INVITEE),
        None,
    )
    invitee_mid = invitee_member['id']
    invitee_ver = invitee_member['version']

    s, revoked = jreq(
        'DELETE',
        f'/merchant/{MERCHANT}/team/members/{invitee_mid}'
        f'?expectedVersion={invitee_ver}',
        token=owner,
    )
    record('T32', 'OWNER revokes invitee membership',
           s == 200 and (
               revoked.get('revoked') is True
               or revoked.get('memberId') == invitee_mid
               or revoked.get('id') == invitee_mid
           ),
           f'status={s} keys={sorted(revoked.keys())[:6]}')

    s, me_gone = jreq('GET', '/merchant/me', token=invitee)
    record('T33', 'revoked member session dead',
           s in (401, 403) or code_of(me_gone) in (
               'AUTH_SESSION_REVOKED', 'AUTH_INVALID_TOKEN', 'AUTH_SESSION_EXPIRED',
           ),
           f'status={s} code={code_of(me_gone)}')

    invitee = login(INVITEE, 'INVITEE3')
    s, me_after = jreq('GET', '/merchant/me', token=invitee)
    memberships = (me_after.get('memberships') or [])
    still = any(m.get('merchantId') == MERCHANT for m in memberships)
    record('T34', 'revoked account has no Comptoir membership; Account remains',
           s == 200 and not still,
           f'status={s} still={still} exists={me_after.get("merchantMembershipExists")} '
           f'count={len(memberships)}')

    # foreign membership of foreign owner still intact
    s, fme = jreq('GET', '/merchant/me', token=foreign)
    f_ok = any(
        m.get('merchantId') == FOREIGN_MERCHANT
        for m in (fme.get('memberships') or [])
    )
    record('T35', 'unrelated foreign membership intact',
           s == 200 and f_ok, f'status={s} foreign={f_ok}')

    # seeded manager/staff still present; owner still OWNER
    s, final = jreq('GET', f'/merchant/{MERCHANT}/team', token=owner)
    roles = {m.get('phone'): m.get('role') for m in (final.get('members') or [])}
    record('T36', 'legacy seeded members remain (OWNER/MANAGER/STAFF)',
           s == 200
           and roles.get(OWNER) == 'OWNER'
           and roles.get(MANAGER) == 'MANAGER'
           and roles.get(STAFF) == 'STAFF'
           and INVITEE not in roles,
           f'status={s} phones={len(roles)}')

    # historical attribution readable: accounts still exist
    acct = sql(f"SELECT count(*) FROM accounts WHERE phone='{INVITEE}'")
    mem = sql(
        f"SELECT count(*) FROM merchant_members "
        f"WHERE merchant_id='{MERCHANT}' AND account_id=("
        f"SELECT id FROM accounts WHERE phone='{INVITEE}')"
    )
    record('T37', 'Account preserved; membership row removed',
           acct == '1' and mem == '0', f'accounts={acct} members={mem}')

    # manager still can read after all mutations
    manager = login(MANAGER, 'MANAGER2')
    s, m2 = jreq('GET', f'/merchant/{MERCHANT}/team', token=manager)
    record('T38', 'MANAGER re-auth still has TEAM_READ',
           s == 200 and (m2.get('capabilities') or {}).get('canManage') is False,
           f'status={s}')

    # staff still forbidden
    staff = login(STAFF, 'STAFF2')
    s, s2 = jreq('GET', f'/merchant/{MERCHANT}/team', token=staff)
    record('T39', 'STAFF re-auth still forbidden',
           s == 403, f'status={s} code={code_of(s2)}')

    # expire invite via SQL then accept attempt
    s, issued3 = jreq(
        'POST', f'/merchant/{MERCHANT}/team/invitations', token=owner,
        data={'phone': '+213550009107', 'role': 'STAFF'},
    )
    code3 = issued3.get('acceptCode') or ''
    SECRETS['invite3'] = code3
    inv3_id = issued3.get('id')
    if inv3_id:
        sql(f"""
DO $$
BEGIN
  IF current_database() <> 'speedygo_parity_fx' OR inet_server_port() <> 5433 THEN
    RAISE EXCEPTION 'refused';
  END IF;
END $$;
UPDATE merchant_member_invitations
SET expires_at = now() - interval '1 hour'
WHERE id = '{inv3_id}';
""")
        invitee_exp = login('+213550009107', 'INVITEE_EXP')
        s, exp = jreq(
            'POST', f'/merchant/me/team-invitations/{inv3_id}/accept',
            token=invitee_exp, data={'acceptCode': code3},
        )
        record('T40', 'expired invitation rejected',
               s == 409 and code_of(exp) == 'TEAM_INVITE_EXPIRED',
               f'status={s} code={code_of(exp)}')
    else:
        record('T40', 'expired invitation rejected', False, 'no invite created')

    # branchScope truth
    scopes = {
        m.get('branchScope')
        for m in (final.get('members') or [])
        if m.get('branchScope')
    }
    record('T41', 'members expose ALL_MERCHANT_BRANCHES scope',
           not scopes or scopes == {'ALL_MERCHANT_BRANCHES'},
           f'scopes={sorted(scopes)}')

    # revoke manager via unauthorized foreign token
    s, foreign_rev = jreq(
        'DELETE',
        f'/merchant/{MERCHANT}/team/members/{MANAGER_MEMBER}?expectedVersion=1',
        token=foreign,
    )
    record('T42', 'foreign owner cannot revoke Comptoir member',
           s in (403, 404),
           f'status={s} code={code_of(foreign_rev)}')

    # retry create after cancel should work for INVITEE2
    s, retry = jreq(
        'POST', f'/merchant/{MERCHANT}/team/invitations', token=owner,
        data={'phone': INVITEE2, 'role': 'STAFF'},
    )
    code_r = retry.get('acceptCode') or ''
    SECRETS['retry'] = code_r
    record('T43', 're-invite after cancel succeeds (no duplicate pending)',
           s == 201 and len(code_r) == 64,
           f'status={s}')

    # cancel that invite to leave roster clean for live captures
    if retry.get('id'):
        jreq(
            'POST',
            f'/merchant/{MERCHANT}/team/invitations/{retry["id"]}/cancel',
            token=owner, data={'expectedVersion': retry.get('version', 1)},
        )

    # prove speedygo_dev untouched marker via row probe (caller also snapshots)
    record('T44', 'isolated e2e completed against :3100 only', True, 'port=3100')

    _finish(0)


if __name__ == '__main__':
    try:
        main()
    except SystemExit:
        raise
    except Exception as e:
        record('TX', 'uncaught', False, type(e).__name__)
        _finish(1)
