#!/usr/bin/env python3
"""Builds audit/parity/review/polish_pass_2026-10-03/ and its ZIP.

The contract-completion batch evidence is assembled by the batch builder
(same selection and exclusions) into the new folder. The final polish pass is
then added under polish/: before/after panels, geometry, raw mocked and live
captures, the two final live runs' provenance and result files, test logs, the
changed lib/ files and the tools. environment.json, .env files and failed-attempt
screenshots are excluded; failed polish attempts are listed by path only. The
superseded b4_cover files are not packaged. Earlier packages are untouched.
Usage: build_polish_package.py [--replace]
"""
import hashlib
import importlib.util
import shutil
import sys
import zipfile
from pathlib import Path

ROOT = Path('/Users/mac/Downloads/speedygo_project')
APP = ROOT / 'apps/merchant_app'
PARITY = APP / 'audit/parity'
POLISH = PARITY / 'polish'
EVIDENCE = PARITY / 'isolated/evidence'
NAME = 'polish_pass_2026-10-03'
OUT = PARITY / 'review' / NAME
ZIP = PARITY / 'review' / 'merchant_polish_pass_2026-10-03_review.zip'

RUNS = {'t100': EVIDENCE / 'fxenv_20261003T022804Z', 't135': EVIDENCE / 'fxenv_20261003T022402Z'}
FAILED = ['fxenv_20261003T021436Z', 'fxenv_20261003T022037Z']
RUN_FILES = ['PROVENANCE_fxp_{t}.json', 'BUNDLE_fxp_{t}.txt', 'flutter_fxp_{t}.log',
             'shots_fxp_{t}.log', 'IMAGE_STORAGE_CHECK_fxp_{t}.json',
             'WEEKLY_INTERVAL_ROWS_after_restore.txt', 'isolation_before.json',
             'isolation_after_fxp_{t}.json', 'isolation_pre_cleanup.json',
             'isolation_after_cleanup.json', 'isolation_comparison.json',
             'dev_redis_job_scan.json', 'fx_row_ids.json', 'cleanup.log', 'migrate.log',
             'verify.log', 'seed.log', 'api_log_summary.txt', 'started_at']
LIB = ['lib/core/widgets/merchant_ui.dart', 'lib/core/constants/app_strings.dart',
       'lib/features/catalog/presentation/catalog_screen.dart',
       'lib/features/catalog/presentation/product_duplicate_screen.dart',
       'lib/features/orders/presentation/order_detail_screen.dart']
TOOLS = ['integration_test/polish_fx_live_test.dart',
         'test/features/merchant_polish_geometry_test.dart',
         'test/audit/parity/batch9_polish_capture_test.dart',
         'audit/parity/polish/compose_polish.py',
         'audit/parity/polish/fx_polish_image_check.py',
         'audit/parity/polish/build_polish_package.py',
         'audit/parity/isolated/fx_run.sh',
         'audit/parity/matrix/build_matrix.py']


def batch_builder():
    spec = importlib.util.spec_from_file_location(
        'batch_builder', PARITY / 'contract_batch/build_contract_batch_package.py')
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def failed_listing() -> str:
    lines = [
        'Failed live attempts of the final Merchant polish pass.',
        'Provenance only: NOT successful evidence. No screenshot from these folders',
        'is included. Causes are in MERCHANT_POLISH_PASS_REPORT.md section 6.',
        'Paths are relative to apps/merchant_app/audit/parity/isolated/evidence/.',
        '',
    ]
    for name in FAILED:
        d = EVIDENCE / name
        files = [p for p in d.rglob('*') if p.is_file() and p.name != '.DS_Store']
        pngs = sum(1 for p in files if p.suffix == '.png')
        ok = 'FX_CLEANUP_OK' in (d / 'cleanup.log').read_text(errors='replace')
        lines.append(f'{name}/  files={len(files)}  screenshots_excluded={pngs}  '
                     f'cleanup={"FX_CLEANUP_OK" if ok else "not recorded"}')
    return '\n'.join(lines) + '\n'


def main() -> None:
    if '--replace' in sys.argv:
        if OUT.exists():
            shutil.rmtree(OUT)
        if ZIP.exists():
            ZIP.unlink()
    if OUT.exists() or ZIP.exists():
        raise SystemExit(f'refusing to overwrite {OUT} / {ZIP}')

    b = batch_builder()
    b.NAME, b.OUT, b.ZIP = NAME, OUT, ZIP
    sys.argv = [sys.argv[0]]
    b.main()
    ZIP.unlink()
    copy = b.copy

    copy(POLISH / 'MERCHANT_POLISH_PASS_REPORT.md', OUT)
    for p in sorted((POLISH / 'before_after').glob('*.png')):
        copy(p, OUT / 'polish/before_after')
    geometry = sorted((POLISH / 'geometry').glob('b9_*.json'))
    if len(geometry) != 20:
        raise SystemExit(f'expected 20 geometry files, found {len(geometry)}')
    for p in geometry:
        copy(p, OUT / 'polish/geometry')
    mocked = sorted((PARITY / 'mocked').glob('b9_*.png'))
    if len(mocked) != 20:
        raise SystemExit(f'expected 20 b9 captures, found {len(mocked)}')
    for p in [*mocked, *sorted((PARITY / 'mocked').glob('b4_cover_*.png'))]:
        copy(p, OUT / 'polish/raw/mocked')
    panels = sorted((POLISH / 'live_panels').glob('fxp_*.png'))
    if len(panels) != 10:
        raise SystemExit(f'expected 10 live panels, found {len(panels)}')
    for p in panels:
        copy(p, OUT / 'polish/live_panels')
    for t, run in RUNS.items():
        shots = sorted((run / 'screens').glob(f'fxp_{t}_*.png'))
        if len(shots) != 11:
            raise SystemExit(f'expected 11 raw {t} screens, found {len(shots)}')
        for p in shots:
            copy(p, OUT / f'polish/raw/live_{t}')
        for pattern in RUN_FILES:
            copy(run / pattern.format(t=t), OUT / f'polish/evidence/live_{t}')
        if (run / 'cleanup_stdout.log').is_file():
            copy(run / 'cleanup_stdout.log', OUT / f'polish/evidence/live_{t}')
    for p in sorted((POLISH / 'test_logs').glob('*.log')):
        copy(p, OUT / 'polish/test_logs')
    for rel in LIB:
        copy(APP / rel, OUT / 'polish/source')
    for rel in TOOLS:
        copy(APP / rel, OUT / 'polish/tools')
    failed = OUT / 'polish/provenance_failed_attempts'
    failed.mkdir(parents=True)
    (failed / 'FAILED_ATTEMPTS.txt').write_text(failed_listing())

    files = sorted(p for p in OUT.rglob('*') if p.is_file() and p.name != 'SHA256SUMS.txt')
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
