#!/usr/bin/env python3
"""Builds audit/parity/review/contract_batch_2026-10-02/ and its ZIP.

Copies only the authoritative evidence of the contract-completion batch: the
report and INDEX, the matrix / comparison index / progress.json, the relevant
workspace docs and migration descriptors, the final 1.0 and 1.35 comparison
panels, the raw screenshots of the two final runs, their provenance and result
files, the backend e2e results and the test logs. environment.json files,
.env files, dumps, caches, the empty fxenv_unknown folder and every
failed-attempt screenshot are excluded; failed attempts are listed by path in
provenance_failed_attempts/FAILED_ATTEMPTS.txt only. Earlier packages are
untouched.
"""
import hashlib
import shutil
import sys
import zipfile
from pathlib import Path

ROOT = Path('/Users/mac/Downloads/speedygo_project')
APP = ROOT / 'apps/merchant_app'
PARITY = APP / 'audit/parity'
BATCH = PARITY / 'contract_batch'
EVIDENCE = PARITY / 'isolated/evidence'
MIGRATION = ROOT / 'apps/backend/migrations/app/20261002T1907_merchant_contract_completion_batch'
NAME = 'contract_batch_2026-10-02'
OUT = PARITY / 'review' / NAME
ZIP = PARITY / 'review' / 'merchant_contract_batch_2026-10-02_review.zip'

RUN_T100 = EVIDENCE / 'fxenv_20261002T211645Z'
RUN_T135 = EVIDENCE / 'fxenv_20261002T211050Z'
RUN_E2E = EVIDENCE / 'fxenv_20261002T193016Z'

DOCS = [
    'architecture/MERCHANT_BRANCH_LOGO_FOUNDATION.md',
    'architecture/MERCHANT_OPENING_HOURS_EXCEPTIONS_FOUNDATION.md',
    'architecture/MERCHANT_OPENING_HOURS_FOUNDATION.md',
    'architecture/MERCHANT_STORE_AVAILABILITY_FOUNDATION.md',
    'architecture/CATALOG_PRODUCT_DUPLICATION_FOUNDATION.md',
    'architecture/CATALOG_FOUNDATION.md',
    'architecture/CUSTOMER_CATALOG_DISCOVERY_FOUNDATION.md',
    'architecture/DOMAIN_MODEL.md',
    'business-rules/MERCHANT_BRANCH_LOGO.md',
    'business-rules/MERCHANT_OPENING_HOURS_EXCEPTIONS.md',
    'business-rules/MERCHANT_OPENING_HOURS.md',
    'business-rules/MERCHANT_STORE_AVAILABILITY.md',
    'business-rules/CATALOG_PRODUCT_DUPLICATION.md',
    'database/ERD.md',
    'database/PRISMA_IMPLEMENTATION.md',
    'api/API_CONVENTIONS.md',
]
MOCKED = ['b8_logo_cover', 'b8_hours_exceptions', 'b8_duplicate',
          'b3_product_menu', 'b4_cover', 'b4_hours']
RUN_FILES = ['PROVENANCE_fxc_{t}.json', 'BUNDLE_fxc_{t}.txt', 'flutter_fxc_{t}.log',
             'shots_fxc_{t}.log', 'isolation_before.json', 'isolation_after_fxc_{t}.json',
             'isolation_pre_cleanup.json', 'isolation_after_cleanup.json',
             'isolation_comparison.json', 'dev_redis_job_scan.json', 'fx_row_ids.json',
             'cleanup.log', 'migrate.log', 'verify.log', 'seed.log',
             'api_log_summary.txt', 'started_at']
E2E_FILES = ['contract_e2e/contract_e2e_results.json', 'contract_e2e/hours_states.json',
             'cleanup.log', 'isolation_comparison.json', 'migrate.log', 'verify.log',
             'fx_row_ids.json', 'started_at']
BATCH_FILES = ['count_matrix.py', 'update_progress.py', 'verify_sources_unchanged.sh',
               'compose_contract_batch_live.py', 'build_contract_batch_package.py',
               'check_links.py']
FAILED = [
    'fxenv_20261002T192656Z', 'fxenv_20261002T192823Z', 'fxenv_20261002T195904Z',
    'fxenv_20261002T200449Z', 'fxenv_20261002T200923Z', 'fxenv_20261002T201535Z',
    'fxenv_20261002T201945Z', 'fxenv_20261002T202439Z', 'fxenv_20261002T203005Z',
    'fxenv_20261002T203415Z', 'fxenv_20261002T204011Z', 'fxenv_20261002T204412Z',
    'fxenv_20261002T205950Z', 'fxenv_20261002T210605Z',
]
NOT_EVIDENCE = 'fxenv_unknown_20261002T204328Z'
FORBIDDEN_NAMES = {'environment.json', '.env'}


def copy(src: Path, dest_dir: Path, name: str | None = None) -> None:
    if not src.is_file():
        raise SystemExit(f'missing: {src}')
    if src.name in FORBIDDEN_NAMES or src.name.startswith('.env'):
        raise SystemExit(f'forbidden: {src}')
    dest_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dest_dir / (name or src.name))


def failed_listing() -> str:
    lines = [
        'Failed and superseded attempts of the contract-completion batch.',
        'Provenance only: NOT successful evidence. No screenshot from these folders',
        'is included in this package. Causes are in CONTRACT_COMPLETION_BATCH_REPORT.md',
        'section 3. Paths are relative to apps/merchant_app/audit/parity/isolated/evidence/.',
        '',
    ]
    for name in FAILED:
        d = EVIDENCE / name
        if not d.is_dir():
            raise SystemExit(f'missing failed-attempt folder: {d}')
        files = [p for p in d.rglob('*') if p.is_file() and p.name != '.DS_Store']
        pngs = sum(1 for p in files if p.suffix == '.png')
        cleanup = d / 'cleanup.log'
        ok = cleanup.is_file() and 'FX_CLEANUP_OK' in cleanup.read_text(errors='replace')
        lines.append(f'{name}/  files={len(files)}  screenshots_excluded={pngs}  '
                     f'cleanup={"FX_CLEANUP_OK" if ok else "not recorded"}')
    d = EVIDENCE / NOT_EVIDENCE
    size = (d / 'cleanup.log').stat().st_size if (d / 'cleanup.log').is_file() else 'absent'
    lines += ['', f'{NOT_EVIDENCE}/  empty (cleanup.log bytes={size}); NOT evidence, not packaged.', '']
    return '\n'.join(lines)


def main() -> None:
    if '--replace' in sys.argv:
        # Only this package's own generated output is replaced.
        if OUT.exists():
            shutil.rmtree(OUT)
        if ZIP.exists():
            ZIP.unlink()
    if OUT.exists() or ZIP.exists():
        raise SystemExit(f'refusing to overwrite {OUT} / {ZIP}')

    copy(BATCH / 'INDEX.md', OUT)
    copy(BATCH / 'CONTRACT_COMPLETION_BATCH_REPORT.md', OUT)
    copy(APP / 'docs/MERCHANT_SCREEN_PARITY_MATRIX.md', OUT / 'parity')
    copy(PARITY / 'COMPARISON_INDEX.md', OUT / 'parity')
    copy(PARITY / 'matrix/progress.json', OUT / 'matrix')
    copy(PARITY / 'matrix/rows.json', OUT / 'matrix')
    for rel in DOCS:
        copy(ROOT / 'docs' / rel, OUT / 'docs' / Path(rel).parent)
    for name in ('migration.json', 'ops.json', 'migration.ts'):
        copy(MIGRATION / name, OUT / 'migration' / MIGRATION.name)

    live = sorted((PARITY / 'comparisons/live').glob('fxc_*.png'))
    if len(live) != 27:
        raise SystemExit(f'expected 27 fxc panels, found {len(live)}')
    for p in live:
        copy(p, OUT / 'comparisons/live')
    for tag in MOCKED:
        copy(PARITY / 'comparisons' / f'{tag}.png', OUT / 'comparisons/mocked')
    for p in sorted((PARITY / 'mocked').glob('b8_*.png')):
        copy(p, OUT / 'raw/mocked')
    copy(PARITY / 'reference_renders/duplicate_product_french_code_html_w390.png',
         OUT / 'reference_renders')

    for t, run in (('t100', RUN_T100), ('t135', RUN_T135)):
        shots = sorted((run / 'screens').glob(f'fxc_{t}_*.png'))
        if len(shots) != 27:
            raise SystemExit(f'expected 27 raw {t} screens, found {len(shots)}')
        for p in shots:
            copy(p, OUT / f'raw/live_{t}')
        for pattern in RUN_FILES:
            copy(run / pattern.format(t=t), OUT / f'evidence/live_{t}')
    for rel in E2E_FILES:
        copy(RUN_E2E / rel, OUT / 'evidence/backend_e2e')

    for p in sorted((BATCH / 'test_logs').glob('*.log')):
        copy(p, OUT / 'test_logs')
    for name in BATCH_FILES:
        copy(BATCH / name, OUT / 'contract_batch')
    copy(APP / 'integration_test/contract_batch_fx_live_test.dart', OUT / 'contract_batch')

    failed_dir = OUT / 'provenance_failed_attempts'
    failed_dir.mkdir(parents=True)
    (failed_dir / 'FAILED_ATTEMPTS.txt').write_text(failed_listing())

    files = sorted(p for p in OUT.rglob('*') if p.is_file())
    sums = [f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.relative_to(OUT)}' for p in files]
    (OUT / 'SHA256SUMS.txt').write_text('\n'.join(sums) + '\n')

    with zipfile.ZipFile(ZIP, 'w', zipfile.ZIP_DEFLATED) as z:
        for p in sorted(OUT.rglob('*')):
            if p.is_file():
                z.write(p, Path(NAME) / p.relative_to(OUT))
    count = sum(1 for p in OUT.rglob('*') if p.is_file())
    print(f'{OUT} files={count}')
    print(f'{ZIP} bytes={ZIP.stat().st_size}')


if __name__ == '__main__':
    main()
