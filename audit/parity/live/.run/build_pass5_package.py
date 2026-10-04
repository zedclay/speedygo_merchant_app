#!/usr/bin/env python3
"""Builds audit/parity/review/pass5_2026-10-02/ and its ZIP.

Copies only: selected mocked comparisons, this pass's live and fixture
comparisons, raw defect evidence, provenance / guard / fixture JSON, the test
summary, the matrix and the comparison index. Earlier packages are untouched.
"""
import shutil
import sys
import zipfile
from pathlib import Path

APP = Path('/Users/mac/Downloads/speedygo_project/apps/merchant_app')
PARITY = APP / 'audit/parity'
LIVE = PARITY / 'live'
RUN = LIVE / '.run'
NAME = 'pass5_2026-10-02'
OUT = PARITY / 'review' / NAME
ZIP = PARITY / 'review' / f'merchant_parity_{NAME}_review.zip'

MOCKED = [
    'b2_update_sheet', 'b2_update_sheet_reason', 'b2_orders_active_incoming',
    'b2_delayed_detail', 'b2_delayed_update_flow_t100', 'b2_delayed_update_flow_t135',
    'b2_detail_preparing_late', 'b2_detail_preparing_late_days',
    'b3_category_detail', 'b3_category_detail_end', 'b3_products', 'b3_products_end',
    'b7_approved', 'b7_approved_top', 'b7_approved_end', 'b4_general', 'b4_profile',
    'b2_delayed_update_days', 'b5_top_products',
]
SUPERSEDED = {'live4_b2_update_sheet.png', 'live4_b2_update_sheet_reason.png'}


def copy(src: Path, dest_dir: Path) -> None:
    if not src.exists():
        raise SystemExit(f'missing: {src}')
    dest_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dest_dir / src.name)


def main() -> None:
    if '--replace' in sys.argv:
        # Only this pass's own generated package is replaced.
        if OUT.exists():
            shutil.rmtree(OUT)
        if ZIP.exists():
            ZIP.unlink()
    if OUT.exists() or ZIP.exists():
        raise SystemExit(f'refusing to overwrite {OUT} / {ZIP}')
    for tag in MOCKED:
        copy(PARITY / 'comparisons' / f'{tag}.png', OUT / 'comparisons/mocked')
    for p in sorted((PARITY / 'comparisons/live').glob('live[45]_*.png')):
        dest = 'comparisons/live/superseded' if p.name in SUPERSEDED else 'comparisons/live'
        copy(p, OUT / dest)
    for p in sorted((PARITY / 'comparisons/live').glob('fx_fx_*.png')):
        copy(p, OUT / 'comparisons/fixture_writes')
    for p in sorted(LIVE.glob('fx_t1*_attempt*.png')):
        copy(p, OUT / 'evidence/failed_attempts')
    for pattern in ('PROVENANCE_live[45]_*.json', 'PROVENANCE_FIXTURE_fx_*.json',
                    'BUNDLE_live[45]_*.txt', 'BUNDLE_FIXTURE_fx_*.txt'):
        for p in sorted(LIVE.glob(pattern)):
            copy(p, OUT / 'provenance')
    for pattern in ('created_live[45]_*.json', 'created_fx_*.json', 'fixture_orders_fx_*.json'):
        for p in sorted(RUN.glob(pattern)):
            copy(p, OUT / 'provenance/guard_and_fixtures')
    for p in ('pass5_suite_summary.txt', 'pass5_followup_tests.txt',
              'cleanup_pass5_result.txt', 'cleanup_pass5_live5_result.txt'):
        if (RUN / p).exists():
            copy(RUN / p, OUT / 'tests_and_cleanup')
    copy(LIVE / 'cleanup_parity_pass5_sessions.sql', OUT / 'tests_and_cleanup')
    copy(LIVE / 'cleanup_parity_pass5_live5_sessions.sql', OUT / 'tests_and_cleanup')
    copy(APP / 'docs/MERCHANT_SCREEN_PARITY_MATRIX.md', OUT)
    copy(PARITY / 'COMPARISON_INDEX.md', OUT)
    copy(RUN / 'PASS5_INDEX.md', OUT)
    (OUT / 'PASS5_INDEX.md').rename(OUT / 'INDEX.md')

    with zipfile.ZipFile(ZIP, 'w', zipfile.ZIP_DEFLATED) as z:
        for p in sorted(OUT.rglob('*')):
            if p.is_file():
                z.write(p, Path(NAME) / p.relative_to(OUT))
    files = sum(1 for p in OUT.rglob('*') if p.is_file())
    print(f'{OUT} files={files}')
    print(f'{ZIP} bytes={ZIP.stat().st_size}')


if __name__ == '__main__':
    main()
