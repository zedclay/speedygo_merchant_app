#!/usr/bin/env python3
"""Create a disposable AT_PICKUP + PENDING handoff fixture for live UI.

Writes:
  - meta JSON (no secrets) to the evidence directory
  - restricted secrets file under ~/.speedygo/parity_fx/live_handoff/ (chmod 600)

Never prints pickup codes, OTPs, or tokens.
Usage: fx_live_handoff_setup.py <meta-out.json>
"""
from __future__ import annotations

import json
import os
import stat
import sys
import time
from pathlib import Path

# Reuse authenticated fixture helpers from the API e2e module.
HERE = Path(__file__).resolve().parent
META_OUT = Path(sys.argv[1])
# fx_driver_handoff_e2e reads argv[1]/argv[2] at import time (out-dir, fx_sql.sh).
_orig_argv = list(sys.argv)
sys.argv = [_orig_argv[0], str(META_OUT.parent), str(HERE / 'fx_sql.sh')]
sys.path.insert(0, str(HERE))
import fx_driver_handoff_e2e as e2e  # noqa: E402
sys.argv = _orig_argv

SECRETS_DIR = Path.home() / '.speedygo' / 'parity_fx' / 'live_handoff'
SECRETS_FILE = SECRETS_DIR / 'secrets.json'
RUN_TAG = f"fxlive_merchant_driver_{time.strftime('%Y%m%dT%H%M%SZ', time.gmtime())}"


def main() -> None:
    e2e.OUT = META_OUT.parent
    e2e.seed_drivers()
    owner = e2e.login(e2e.OWNER, 'OWNER')
    e2e.login(e2e.DRIVER_A_PHONE, 'DRIVER_A')

    order_id = e2e.place_incoming(f'live_{int(time.time())}')
    e2e.merchant_ready(order_id, owner)
    delivery_id, assignment_id, assignment_version = e2e.attach_assignment(
        order_id, e2e.DRIVER_A_ID, status='AT_PICKUP', arrived=True,
    )

    status, handoff = e2e.jreq(
        'GET',
        f'/merchant/{e2e.MERCHANT}/orders/{order_id}/delivery/pickup-handoff',
        token=owner,
    )
    code = handoff.get('pickupCode') or ''
    if status != 200 or not (
        isinstance(code, str) and len(code) == 4 and code.isdigit()
    ):
        raise SystemExit(f'handoff issue failed status={status}')

    # Confirm driver current delivery is AT_PICKUP with matching assignment.
    driver_token = e2e.TOKENS['DRIVER_A']
    ds, current = e2e.jreq(
        'GET', '/driver/deliveries/current', token=driver_token,
    )
    delivery = current.get('delivery') if isinstance(current, dict) else None
    if not isinstance(delivery, dict):
        delivery = current if isinstance(current, dict) else {}
    if ds != 200 or delivery.get('deliveryStatus') != 'AT_PICKUP':
        raise SystemExit(
            f'driver current not AT_PICKUP status={ds} '
            f'delivery={delivery.get("deliveryStatus")}',
        )
    if delivery.get('assignmentId') != assignment_id:
        raise SystemExit('assignmentId mismatch on driver current')
    if int(delivery.get('assignmentVersion') or 0) != int(assignment_version):
        raise SystemExit('assignmentVersion mismatch on driver current')

    SECRETS_DIR.mkdir(parents=True, exist_ok=True)
    secrets = {
        'runTag': RUN_TAG,
        'pickupCode': code,
        'orderId': order_id,
        'deliveryId': delivery_id,
        'assignmentId': assignment_id,
        'assignmentVersion': assignment_version,
        'merchantId': e2e.MERCHANT,
        'ownerPhoneLocal': '550009101',
        'driverPhoneLocal': '550009131',
    }
    SECRETS_FILE.write_text(json.dumps(secrets) + '\n')
    os.chmod(SECRETS_FILE, stat.S_IRUSR | stat.S_IWUSR)

    meta = {
        'runTag': RUN_TAG,
        'orderId': order_id,
        'orderIdSuffix': order_id[-8:],
        'deliveryId': delivery_id,
        'deliveryIdSuffix': delivery_id[-8:],
        'assignmentId': assignment_id,
        'assignmentVersion': assignment_version,
        'merchantId': e2e.MERCHANT,
        'driverId': e2e.DRIVER_A_ID,
        'deliveryStatus': 'AT_PICKUP',
        'handoffStatus': handoff.get('status'),
        'secretsPath': str(SECRETS_FILE),
        'createdAt': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
        'apiBase': e2e.BASE,
        'dbAlias': 'speedygo_parity_fx',
        'redisIndex': 9,
    }
    META_OUT.parent.mkdir(parents=True, exist_ok=True)
    META_OUT.write_text(json.dumps(meta, indent=2) + '\n')
    print(
        f'LIVE_FIXTURE_OK run={RUN_TAG} orderSuffix={order_id[-8:]} '
        f'delivery={delivery.get("deliveryStatus")} handoff={handoff.get("status")}',
    )


if __name__ == '__main__':
    main()
