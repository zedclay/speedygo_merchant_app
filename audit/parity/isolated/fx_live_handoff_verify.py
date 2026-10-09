#!/usr/bin/env python3
"""Verify post-confirm server state for the live handoff fixture.

Usage: fx_live_handoff_verify.py <meta.json> <results-out.json>
Never prints pickup codes or tokens.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
META_PATH = Path(sys.argv[1])
OUT = Path(sys.argv[2])
_orig_argv = list(sys.argv)
sys.argv = [_orig_argv[0], str(META_PATH.parent), str(HERE / 'fx_sql.sh')]
sys.path.insert(0, str(HERE))
import fx_driver_handoff_e2e as e2e  # noqa: E402
sys.argv = _orig_argv

META = json.loads(META_PATH.read_text())
RESULTS = []


def record(cid: str, name: str, ok: bool, detail: str = '') -> None:
    RESULTS.append({
        'id': cid,
        'check': name,
        'result': 'PASS' if ok else 'FAIL',
        'detail': detail,
    })
    print(f'{"PASS" if ok else "FAIL"}  {cid} {name} {detail}'[:400])


def main() -> None:
    order_id = META['orderId']
    delivery_id = META['deliveryId']
    assignment_id = META['assignmentId']
    expected_version = int(META['assignmentVersion'])

    delivery_status = e2e.sql(
        f"SELECT status FROM deliveries WHERE id = '{delivery_id}'",
    )
    picked_up_at = e2e.sql(
        f"SELECT coalesce(picked_up_at::text, '') FROM deliveries "
        f"WHERE id = '{delivery_id}'",
    )
    handoff_status = e2e.sql(
        f"SELECT status FROM delivery_pickup_handoffs "
        f"WHERE delivery_id = '{delivery_id}' "
        f"ORDER BY created_at DESC LIMIT 1",
    )
    event_count = e2e.sql(
        f"SELECT count(*)::text FROM delivery_events "
        f"WHERE delivery_id = '{delivery_id}' AND type = 'ORDER_PICKED_UP'",
    )
    assignment_row = e2e.sql(
        f"SELECT id || '|' || version::text || '|' || status "
        f"FROM driver_assignments WHERE id = '{assignment_id}'",
    )
    # COD settlement / earnings / completed must remain absent for this slice.
    settlement = e2e.sql(
        f"SELECT count(*)::text FROM merchant_settlement_lines "
        f"WHERE order_id = '{order_id}'",
    ) if e2e.sql(
        "SELECT count(*) FROM information_schema.tables "
        "WHERE table_schema='public' AND table_name='merchant_settlement_lines'",
    ) == '1' else '0'
    earnings = e2e.sql(
        f"SELECT count(*)::text FROM driver_earnings "
        f"WHERE delivery_id = '{delivery_id}'",
    ) if e2e.sql(
        "SELECT count(*) FROM information_schema.tables "
        "WHERE table_schema='public' AND table_name='driver_earnings'",
    ) == '1' else '0'
    completed = delivery_status == 'COMPLETED'

    parts = assignment_row.split('|') if assignment_row else []
    assign_ok = (
        len(parts) == 3
        and parts[0] == assignment_id
        and int(parts[1]) == expected_version
        and parts[2] in ('ACCEPTED', 'ACTIVE', 'IN_PROGRESS')
    )

    record(
        'V1', 'delivery PICKED_UP',
        delivery_status == 'PICKED_UP',
        f'status={delivery_status}',
    )
    record(
        'V2', 'pickedUpAt set',
        bool(picked_up_at),
        f'set={bool(picked_up_at)}',
    )
    record(
        'V3', 'handoff consumed',
        handoff_status == 'CONSUMED',
        f'status={handoff_status}',
    )
    record(
        'V4', 'exactly one ORDER_PICKED_UP event',
        event_count == '1',
        f'count={event_count}',
    )
    record(
        'V5', 'assignment id/version preserved',
        assign_ok,
        f'row={assignment_row}',
    )
    record(
        'V6', 'no COD settlement lines',
        settlement == '0',
        f'count={settlement}',
    )
    record(
        'V7', 'no driver earnings lines',
        earnings == '0',
        f'count={earnings}',
    )
    record(
        'V8', 'delivery not COMPLETED',
        not completed,
        f'status={delivery_status}',
    )

    fails = sum(1 for r in RESULTS if r['result'] == 'FAIL')
    OUT.write_text(json.dumps({
        'results': RESULTS,
        'summary': {'pass': len(RESULTS) - fails, 'fail': fails},
        'orderIdSuffix': order_id[-8:],
        'deliveryIdSuffix': delivery_id[-8:],
    }, indent=2) + '\n')
    raise SystemExit(0 if fails == 0 else 1)


if __name__ == '__main__':
    main()
