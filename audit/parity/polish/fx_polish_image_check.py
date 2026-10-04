"""Host-side storage check for the polish live image duplication.

Reads PROVENANCE_<prefix>.json from the isolated evidence directory for the
source and copy product ids, reads their product_images rows through
fx_sql.sh (speedygo_parity_fx only) and compares the stored objects under the
isolated local storage root. Run before fx_cleanup.sh. Never prints secrets.
Usage: fx_polish_image_check.py <evidence-dir> <out.json> <prefix>...
"""
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
FX_SQL = HERE.parent / 'isolated' / 'fx_sql.sh'
STORAGE = Path(os.environ['HOME']) / '.speedygo' / 'parity_fx' / 'storage' / 'product-images'
UUID = set('0123456789abcdef-')


def sql_json(statement):
    p = subprocess.run(['bash', str(FX_SQL)], input=statement, capture_output=True, text=True)
    if p.returncode != 0:
        raise RuntimeError(f'fx_sql failed rc={p.returncode}: {p.stderr.strip()[:300]}')
    out = p.stdout.strip()
    return json.loads(out) if out else None


def image_row(product_id):
    assert set(product_id) <= UUID and len(product_id) == 36, product_id
    return sql_json(
        "select row_to_json(i) from (select object_id, content_type, byte_size, width_px, height_px "
        f"from product_images where product_id = '{product_id}') i"
    )


def stored(object_id):
    path = STORAGE / object_id
    if not path.is_file():
        return None
    data = path.read_bytes()
    return {'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}


def main():
    evidence, out, *prefixes = sys.argv[1:]
    checks = []
    for prefix in prefixes:
        prov = json.loads((Path(evidence) / f'PROVENANCE_{prefix}.json').read_text())
        source_id = prov['sourceProductId']
        copy_id = prov['results'].get('copyId')
        source = image_row(source_id)
        copy = image_row(copy_id) if copy_id else None
        s_obj = stored(source['object_id']) if source else None
        c_obj = stored(copy['object_id']) if copy else None
        ok = bool(
            source and copy and s_obj and c_obj
            and source['object_id'] != copy['object_id']
            and s_obj['sha256'] == c_obj['sha256']
        )
        checks.append({
            'prefix': prefix,
            'sourceProductId': source_id,
            'copyProductId': copy_id,
            'sourceRow': source,
            'copyRow': copy,
            'sourceStored': s_obj,
            'copyStored': c_obj,
            'distinctObjects': bool(source and copy and source['object_id'] != copy['object_id']),
            'equalBytes': bool(s_obj and c_obj and s_obj['sha256'] == c_obj['sha256']),
            'result': 'PASS' if ok else 'FAIL',
        })
    Path(out).write_text(json.dumps({'storageRoot': '~/.speedygo/parity_fx/storage/product-images',
                                     'checks': checks}, indent=2) + '\n')
    for c in checks:
        print(c['prefix'], c['result'], 'distinct_objects=%s equal_bytes=%s' % (c['distinctObjects'], c['equalBytes']))
    sys.exit(0 if all(c['result'] == 'PASS' for c in checks) else 1)


if __name__ == '__main__':
    main()
