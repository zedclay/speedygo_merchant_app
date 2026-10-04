"""Regenerate the table rows of docs/MERCHANT_SCREEN_PARITY_MATRIX.md.

Header and footer text in the doc are kept as edited; only the rows under
"## Matrix" are rebuilt from rows.json (baseline inventory) and
progress.json (reference folder -> progress note).
"""
import json
import re
from pathlib import Path

HERE = Path(__file__).parent
DOC = HERE.parents[2] / 'docs' / 'MERCHANT_SCREEN_PARITY_MATRIX.md'


def batch_of(r):
    ref = r['ref']
    if r['batch'] == 'A/E':
        reports = ['report', 'sales', 'daily', 'popular']
        return 'B5 Reports' if any(k in ref for k in reports) else 'B1 Shell/Dashboard'
    if r['batch'] == 'F/G':
        auth = ['splash', 'onboarding', 'phone_login', 'otp', 'registration',
                'document', 'verification']
        return 'B7 Auth/Registration' if any(k in ref for k in auth) else 'B6 Settings/Notifications'
    return {'B': 'B2 Orders', 'C': 'B3 Catalogue', 'D': 'B4 Store'}[r['batch']]


def short(s, n=240):
    s = re.sub(r'\s+', ' ', s or '').replace('|', '/')
    return s if len(s) <= n else s[:n].rsplit(' ', 1)[0] + '…'


def key_of(ref):
    return ref.strip('`* ')


def main():
    rows = json.loads((HERE / 'rows.json').read_text())
    progress = json.loads((HERE / 'progress.json').read_text())
    lines = DOC.read_text().split('\n')
    start = next(i for i, l in enumerate(lines) if l.startswith('| # | Batch'))
    body_start = start + 2
    body_end = body_start
    while body_end < len(lines) and lines[body_end].startswith('|'):
        body_end += 1
    out = []
    for i, r in enumerate(rows, 1):
        name = key_of(r['ref'])
        # Rows whose ref is not an inventory heading carry an explicit anchor.
        anchor = r.get('anchor') or re.sub(r'[^a-z0-9_ -]', '', name.lower()).replace(' ', '-')
        link = f"[{r['file'].split('_')[0]}](../audit/parity/inventory/{r['file']}#{anchor})"
        prog = short(progress.get(name, '—'), 320)
        out.append(
            f"| {i} | {batch_of(r)} | {r['ref']} | {short(r['route'], 120)} | "
            f"{short(r.get('diff', 'see inventory'))} | {short(r['work'], 200)} | "
            f"{r['status']} | {prog} | {link} |"
        )
    unknown = set(progress) - {key_of(r['ref']) for r in rows}
    if unknown:
        raise SystemExit(f'progress keys not in matrix: {sorted(unknown)}')
    DOC.write_text('\n'.join(lines[:body_start] + out + lines[body_end:]))
    print(f'{len(out)} rows, {len(progress)} with progress')


if __name__ == '__main__':
    main()
