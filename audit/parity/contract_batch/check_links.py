#!/usr/bin/env python3
"""Checks markdown links and backtick evidence paths of the closeout documents.

Markdown links resolve against the linking file. Backtick paths (report and
INDEX only) resolve against the workspace root when they start with `apps/` or
`docs/`, otherwise against apps/merchant_app/. With `--package DIR`, INDEX.md
links are checked against the extracted package instead. Read-only.
"""
import re
import sys
from pathlib import Path

ROOT = Path('/Users/mac/Downloads/speedygo_project')
APP = ROOT / 'apps/merchant_app'
BATCH = APP / 'audit/parity/contract_batch'

LINKED = [
    *(ROOT / 'docs' / p for p in (
        'architecture/MERCHANT_BRANCH_LOGO_FOUNDATION.md',
        'architecture/MERCHANT_OPENING_HOURS_EXCEPTIONS_FOUNDATION.md',
        'architecture/CATALOG_PRODUCT_DUPLICATION_FOUNDATION.md',
        'architecture/CATALOG_FOUNDATION.md',
        'architecture/CUSTOMER_CATALOG_DISCOVERY_FOUNDATION.md',
        'architecture/DOMAIN_MODEL.md',
        'business-rules/MERCHANT_BRANCH_LOGO.md',
        'business-rules/MERCHANT_OPENING_HOURS_EXCEPTIONS.md',
        'business-rules/CATALOG_PRODUCT_DUPLICATION.md',
        'database/ERD.md',
        'database/PRISMA_IMPLEMENTATION.md',
        'api/API_CONVENTIONS.md',
    )),
    APP / 'docs/MERCHANT_SCREEN_PARITY_MATRIX.md',
    APP / 'audit/parity/COMPARISON_INDEX.md',
    BATCH / 'CONTRACT_COMPLETION_BATCH_REPORT.md',
]
PATH_CHECKED = [BATCH / 'CONTRACT_COMPLETION_BATCH_REPORT.md', BATCH / 'INDEX.md']
NOT_PATHS = {'Africa/Algiers'}
PREEXISTING: set[str] = set()

LINK = re.compile(r'\]\(([^)\s]+)\)')
TICK = re.compile(r'`([^`\s]+)`')
PATHLIKE = re.compile(r'^[\w.\-]+(/[\w.\-]+)+/?$')


def slug(heading: str) -> str:
    s = heading.strip().lower()
    s = re.sub(r'[^\w\- ]', '', s)
    return s.replace(' ', '-')


def anchors(md: Path) -> set[str]:
    out = set()
    for line in md.read_text(errors='replace').splitlines():
        m = re.match(r'^#{1,6}\s+(.*)$', line)
        if m:
            out.add(slug(m.group(1)))
        for a in re.findall(r'<a (?:name|id)="([^"]+)"', line):
            out.add(a)
    return out


def check_links(md: Path, base: Path) -> list[str]:
    bad = []
    for target in LINK.findall(md.read_text(errors='replace')):
        if re.match(r'^(https?:|mailto:)', target):
            continue
        if target in PREEXISTING:
            print(f'PREEXISTING {md.name}: {target}')
            continue
        path, _, frag = target.partition('#')
        dest = (base / path).resolve() if path else md
        if not dest.exists():
            bad.append(f'{md}: missing link target {target}')
        elif frag and dest.suffix == '.md' and frag not in anchors(dest):
            bad.append(f'{md}: missing anchor {target}')
    return bad


def check_paths(md: Path) -> tuple[int, list[str]]:
    bad, seen = [], 0
    for tok in TICK.findall(md.read_text(errors='replace')):
        if tok in NOT_PATHS or '…' in tok or '<' in tok or '*' in tok \
                or not PATHLIKE.match(tok):
            continue
        if tok.startswith(('/api/', 'api/v1')) or re.match(r'^\d', tok):
            continue
        base = ROOT if tok.startswith(('apps/', 'docs/')) else APP
        seen += 1
        if not (base / tok).exists() and not (BATCH / tok).exists() \
                and not (APP / 'audit/parity' / tok).exists():
            bad.append(f'{md}: missing path {tok}')
    return seen, bad


def main() -> None:
    bad = []
    if '--package' in sys.argv:
        pkg = Path(sys.argv[sys.argv.index('--package') + 1])
        n = len(LINK.findall((pkg / 'INDEX.md').read_text()))
        bad += check_links(pkg / 'INDEX.md', pkg)
        print(f'package INDEX.md links={n}')
    else:
        for md in LINKED:
            n = len(LINK.findall(md.read_text(errors='replace')))
            found = check_links(md, md.parent)
            bad += found
            print(f'{md.relative_to(ROOT)} links={n} bad={len(found)}')
        for md in PATH_CHECKED:
            seen, found = check_paths(md)
            bad += found
            print(f'{md.relative_to(ROOT)} backtick_paths={seen} bad={len(found)}')
    for b in bad:
        print('BAD', b)
    print('LINKS_OK' if not bad else f'LINKS_BAD {len(bad)}')
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
