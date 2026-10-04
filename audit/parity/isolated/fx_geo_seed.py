#!/usr/bin/env python3
"""Load the locked Algeria wilaya/commune catalogue into speedygo_parity_fx only.

Uses the same JSON + SHA-256 as apps/backend/scripts/geo-import-algeria.mjs.
Writes only through fx_sql.sh (disposable DB guards). Never touches speedygo_dev.
Usage: fx_geo_seed.py <fx_sql.sh> <out.json>
"""
import hashlib
import json
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

FX_SQL = sys.argv[1]
OUT = Path(sys.argv[2])
JSON_PATH = Path(
    '/Users/mac/Downloads/speedygo_project/apps/backend/data/geo/'
    'algeria_69_wilayas_1541_communes.json',
)
EXPECTED_SHA256 = (
    '92fa211dcb606e7e9d83f3c426bd3a80930cacef74ecb9fded00b6de2a3e5f55'
)
EXPECTED_WILAYAS = 69
EXPECTED_COMMUNES = 1541


def sql(statement: str) -> str:
    p = subprocess.run(
        ['bash', FX_SQL], input=statement, capture_output=True, text=True,
    )
    if p.returncode != 0:
        raise SystemExit(
            f'fx_sql failed rc={p.returncode}: {p.stderr.strip()[:500]}',
        )
    return p.stdout.strip()


def lit(value) -> str:
    if value is None:
        return 'NULL'
    return "'" + str(value).replace("'", "''") + "'"


def main() -> None:
    existing = sql(
        "SELECT (SELECT count(*) FROM wilayas)::text || '|' || "
        '(SELECT count(*) FROM communes)::text',
    )
    if existing == f'{EXPECTED_WILAYAS}|{EXPECTED_COMMUNES}':
        proof = {
            'ok': True,
            'skipped': True,
            'reason': 'already seeded',
            'databaseCounts': existing,
        }
        OUT.write_text(json.dumps(proof, indent=2) + '\n')
        print(json.dumps(proof))
        return

    raw = JSON_PATH.read_bytes()
    sha = hashlib.sha256(raw).hexdigest()
    if sha != EXPECTED_SHA256:
        raise SystemExit(f'SHA-256 mismatch: {sha}')
    data = json.loads(raw)
    wilayas = data['wilayas']
    communes = data['communes']
    if len(wilayas) != EXPECTED_WILAYAS or len(communes) != EXPECTED_COMMUNES:
        raise SystemExit(
            f'count mismatch wilayas={len(wilayas)} communes={len(communes)}',
        )

    now = datetime.now(timezone.utc).isoformat()
    with tempfile.NamedTemporaryFile(
        'w', suffix='.sql', delete=False, encoding='utf-8',
    ) as fh:
        path = fh.name
        fh.write('BEGIN;\n')
        for w in wilayas:
            fh.write(
                'INSERT INTO wilayas (code, name_fr, name_ar, created_at, updated_at) '
                f"VALUES ({lit(w['code'])}, {lit(w['name_fr'])}, {lit(w['name_ar'])}, "
                f"{lit(now)}::timestamptz, {lit(now)}::timestamptz) "
                'ON CONFLICT (code) DO UPDATE SET '
                'name_fr = EXCLUDED.name_fr, name_ar = EXCLUDED.name_ar, '
                'updated_at = EXCLUDED.updated_at;\n',
            )
        for c in communes:
            aliases = c.get('aliases_fr') or None
            aliases_sql = (
                'NULL' if not aliases else f"{lit(json.dumps(aliases))}::jsonb"
            )
            fh.write(
                'INSERT INTO communes '
                '(id, wilaya_code, name_fr, name_ar, aliases_fr, created_at, updated_at) '
                f"VALUES ({int(c['id'])}, {lit(c['wilaya_code'])}, "
                f"{lit(c['name_fr'])}, {lit(c['name_ar'])}, {aliases_sql}, "
                f"{lit(now)}::timestamptz, {lit(now)}::timestamptz) "
                'ON CONFLICT (id) DO UPDATE SET '
                'wilaya_code = EXCLUDED.wilaya_code, name_fr = EXCLUDED.name_fr, '
                'name_ar = EXCLUDED.name_ar, aliases_fr = EXCLUDED.aliases_fr, '
                'updated_at = EXCLUDED.updated_at;\n',
            )
        fh.write('COMMIT;\n')

    # fx_sql.sh reads stdin; stream the file.
    with open(path, encoding='utf-8') as fh:
        p = subprocess.run(
            ['bash', FX_SQL], stdin=fh, capture_output=True, text=True,
        )
    Path(path).unlink(missing_ok=True)
    if p.returncode != 0:
        raise SystemExit(
            f'geo seed failed rc={p.returncode}: {p.stderr.strip()[:500]}',
        )

    counts = sql(
        "SELECT (SELECT count(*) FROM wilayas)::text || '|' || "
        '(SELECT count(*) FROM communes)::text',
    )
    if counts != f'{EXPECTED_WILAYAS}|{EXPECTED_COMMUNES}':
        raise SystemExit(f'post-seed counts {counts}')
    proof = {
        'ok': True,
        'skipped': False,
        'sha256': sha,
        'databaseCounts': counts,
        'source': str(JSON_PATH),
    }
    OUT.write_text(json.dumps(proof, indent=2) + '\n')
    print(json.dumps(proof))


if __name__ == '__main__':
    main()
