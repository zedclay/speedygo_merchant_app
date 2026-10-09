#!/usr/bin/env python3
"""Cleanup disposable live handoff fixture + restricted secrets.

Scoped to the unique order/delivery/assignment from meta.json.
Never FLUSHDB / never drop the whole FX database.
Usage: fx_live_handoff_cleanup.py <meta.json>
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
META_PATH = Path(sys.argv[1])
_orig_argv = list(sys.argv)
sys.argv = [_orig_argv[0], str(META_PATH.parent), str(HERE / 'fx_sql.sh')]
sys.path.insert(0, str(HERE))
import fx_driver_handoff_e2e as e2e  # noqa: E402
sys.argv = _orig_argv

META = json.loads(META_PATH.read_text())
SECRETS_FILE = Path.home() / '.speedygo' / 'parity_fx' / 'live_handoff' / 'secrets.json'


def main() -> None:
    order_id = META['orderId']
    delivery_id = META['deliveryId']
    assignment_id = META['assignmentId']

    # Invalidate any remaining PENDING handoff for this delivery.
    e2e.sql(f"""
UPDATE delivery_pickup_handoffs
SET status = 'INVALIDATED', invalidated_at = now(),
    invalidated_reason = 'LIVE_FIXTURE_CLEANUP', updated_at = now()
WHERE delivery_id = '{delivery_id}' AND status = 'PENDING';
""")
    # Release assignment if still open.
    e2e.sql(f"""
UPDATE driver_assignments
SET status = 'RELEASED', released_at = now()
WHERE id = '{assignment_id}' AND released_at IS NULL;
""")
    # Soft-cancel the fixture order if still active (does not touch other FX data).
    e2e.sql(f"""
UPDATE orders
SET status = 'CANCELLED', updated_at = now()
WHERE id = '{order_id}' AND status NOT IN ('CANCELLED', 'COMPLETED');
""")
    e2e.sql(f"""
UPDATE deliveries
SET status = CASE
  WHEN status IN ('PICKED_UP', 'COMPLETED', 'CANCELLED', 'FAILED') THEN status
  ELSE 'CANCELLED'
END,
updated_at = now()
WHERE id = '{delivery_id}';
""")

    if SECRETS_FILE.exists():
        SECRETS_FILE.write_text('')
        SECRETS_FILE.unlink()

    print(
        f'LIVE_CLEANUP_OK orderSuffix={order_id[-8:]} '
        f'deliverySuffix={delivery_id[-8:]} secretsRemoved=1',
    )


if __name__ == '__main__':
    main()
