"""Classify every matrix row from rows.json + progress.json and print the counts.

Used to reconcile the hand-edited counts in MERCHANT_SCREEN_PARITY_MATRIX.md,
the report and the comparison index. Read-only.
"""
import json
import sys
from pathlib import Path

MATRIX = Path(__file__).resolve().parents[1] / 'matrix'


def key_of(ref):
    return ref.strip('`* ')


def implementation(note):
    n = note.lower()
    if n.startswith('done for cover'):
        return 'partial'
    if n.startswith('done'):
        return 'done'
    if n.startswith('partial'):
        return 'partial'
    if n.startswith('exception_approved'):
        return 'exception'
    if n.startswith('not_applicable_duplicate') or n.startswith('no change (duplicate'):
        return 'duplicate'
    if n.startswith('blocked_decision') or n.startswith('not compared') or n.startswith('no change — png'):
        return 'deferred'
    if n.startswith('blocked_contract') or n.startswith('no change (blocked') or n.startswith('no change — blocked'):
        return 'blocked'
    return 'unknown'


def live(note, impl):
    if impl in ('exception', 'duplicate'):
        return 'n/a'
    head = note.split(' — ')[0].lower()
    if 'live compared' in head and 'not live compared' not in head:
        return 'live'
    return 'not live'


def main():
    rows = json.loads((MATRIX / 'rows.json').read_text())
    progress = json.loads((MATRIX / 'progress.json').read_text())
    impl_counts, live_counts, unknown = {}, {}, []
    per_row = []
    for i, r in enumerate(rows, 1):
        name = key_of(r['ref'])
        note = progress.get(name, '—')
        impl = implementation(note)
        lv = live(note, impl)
        impl_counts[impl] = impl_counts.get(impl, 0) + 1
        live_counts[lv] = live_counts.get(lv, 0) + 1
        per_row.append((i, name, impl, lv))
        if impl == 'unknown':
            unknown.append((i, name, note[:60]))
    if '-v' in sys.argv:
        for row in per_row:
            print(*row, sep=' | ')
    print('rows', len(rows))
    print('implementation', dict(sorted(impl_counts.items())))
    print('live', dict(sorted(live_counts.items())))
    if unknown:
        print('UNKNOWN', unknown)
        raise SystemExit(1)


if __name__ == '__main__':
    main()
