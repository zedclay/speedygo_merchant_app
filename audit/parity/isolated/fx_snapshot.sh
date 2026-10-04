#!/usr/bin/env bash
# Read-only isolation snapshot. Writes JSON with:
#   devDb    speedygo_dev counts (read-only transaction), the seven tracked
#            pass-5 orders, the late order, shared branch names, fixture
#            namespace probes and rows created since <since-iso>;
#   redis    key counts per index (0 shared dev, 9 isolated, 15 e2e), keys
#            with the isolated prefix on 0 and 15, BullMQ job counters on 0;
#   fxDb     the same core counts inside speedygo_parity_fx when it exists.
# Usage: fx_snapshot.sh <out.json> [since-iso]
set -euo pipefail
. "$(dirname "$0")/fx_common.sh"
OUT="$1"
SINCE="${2:-1970-01-01T00:00:00Z}"
[[ "$SINCE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+Z$ ]] || fx_die "since must be an ISO UTC timestamp"
fx_load_targets

DEV_SQL=$(cat <<SQL
select json_build_object(
  'database', current_database(),
  'readOnly', current_setting('transaction_read_only'),
  'counts', json_build_object(
    'accounts', (select count(*) from accounts),
    'sessions', (select count(*) from sessions),
    'sessionsActiveMerchant', (select count(*) from sessions s where s.revoked_at is null and s.expires_at > now()
        and exists (select 1 from merchant_members m where m.account_id = s.account_id)),
    'sessionsActiveCustomer', (select count(*) from sessions s where s.revoked_at is null and s.expires_at > now()
        and exists (select 1 from customer_profiles c where c.account_id = s.account_id)),
    'sessionsActiveDarElBahjaOwner', (select count(*) from sessions
        where account_id = '0d00c071-d000-7000-8000-000000000001' and revoked_at is null),
    'sessionsActivePrepTimeCustomer', (select count(*) from sessions
        where account_id = '0d00c074-d000-7000-8000-000000000001' and revoked_at is null),
    'devices', (select count(*) from devices),
    'orders', (select count(*) from orders),
    'ordersCompleted', (select count(*) from orders where status = 'COMPLETED'),
    'orderStatusEvents', (select count(*) from order_status_events),
    'orderCancellations', (select count(*) from order_cancellations),
    'estimateRevisions', (select count(*) from order_preparation_estimate_revisions),
    'financialSnapshots', (select count(*) from order_financial_snapshots),
    'payments', (select count(*) from payments),
    'notifications', (select count(*) from notifications),
    'notificationDeliveryLogs', (select count(*) from notification_delivery_logs),
    'deliveries', (select count(*) from deliveries),
    'driverAssignments', (select count(*) from driver_assignments),
    'ledgerEntries', (select count(*) from financial_ledger_entries),
    'carts', (select count(*) from carts),
    'cartItems', (select count(*) from cart_items),
    'auditLogs', (select count(*) from audit_logs),
    'merchants', (select count(*) from merchants),
    'merchantBranches', (select count(*) from merchant_branches),
    'products', (select count(*) from products)
  ),
  'darElBahjaOrdersByState', (select coalesce(json_object_agg(k, c), '{}') from (
      select status || '/' || fulfillment_status k, count(*) c from orders
      where merchant_branch_id = '0d00c071-d000-7000-8000-000000011001' group by 1) x),
  'trackedOrders', (select json_agg(json_build_object('id', id, 'status', status,
      'fulfillment', fulfillment_status, 'estimateVersion', preparation_estimate_version,
      'updatedAt', updated_at) order by id) from orders where id in (
      '01a0fd2a-2e34-7919-ab9a-043225c2fbf1', '01a0fd32-688b-7757-9124-3aa8574d93ea',
      '01a0fd37-f350-7c88-ac7e-7c4c5c8c3d30', '01a0fd63-3d79-7d51-a414-6bf504b8fc81',
      '01a0fd2a-2f23-7094-abf0-26b4b3c0e977', '01a0fd37-f447-7440-a6db-bf459aca7c8e',
      '01a0fd63-3e5c-7d0a-8801-d5bb1e793486')),
  'lateOrder', (select json_build_object('status', status, 'fulfillment', fulfillment_status,
      'estimateVersion', preparation_estimate_version, 'estimatedReadyAt', estimated_ready_at)
      from orders where id = '01a0e8dc-8a8f-74de-95e0-82b84cca4d19'),
  'branchNames', (select json_object_agg(id, name) from merchant_branches where id in (
      '0d00c071-d000-7000-8000-000000011001', '0d00c071-d000-7000-8000-000000011010')),
  'fixtureNamespaceInDev', json_build_object(
    'accounts', (select count(*) from accounts where id::text like '0d00f0f0-fa00-%'
        or phone in ('+213550009101', '+213550009102', '+213550009103', '+213550009111', '+213550009121')),
    'merchants', (select count(*) from merchants where id::text like '0d00f0f0-fa00-%' or public_reference like 'sgm_parityfx%'),
    'orders', (select count(*) from orders where id::text like '0d00f0f0-fa00-%' or public_reference like 'sgo_parityfx%'),
    'products', (select count(*) from products where id::text like '0d00f0f0-fa00-%')
  ),
  'createdSince', json_build_object(
    'since', '$SINCE',
    'accounts', (select count(*) from accounts where created_at >= '$SINCE'::timestamptz),
    'sessions', (select count(*) from sessions where created_at >= '$SINCE'::timestamptz),
    'devices', (select count(*) from devices where created_at >= '$SINCE'::timestamptz),
    'orders', (select count(*) from orders where created_at >= '$SINCE'::timestamptz),
    'orderStatusEvents', (select count(*) from order_status_events where occurred_at >= '$SINCE'::timestamptz),
    'notifications', (select count(*) from notifications where created_at >= '$SINCE'::timestamptz),
    'ordersUpdated', (select count(*) from orders where updated_at >= '$SINCE'::timestamptz),
    'branchesUpdated', (select count(*) from merchant_branches where updated_at >= '$SINCE'::timestamptz)
  )
)
SQL
)
DEV_JSON=$(fx_psql_dev_ro -c "$DEV_SQL")

FX_JSON=null
if fx_db_exists; then
  FX_JSON=$(fx_psql -c "select json_build_object(
    'database', current_database(),
    'accounts', (select count(*) from accounts),
    'sessions', (select count(*) from sessions),
    'sessionsActive', (select count(*) from sessions where revoked_at is null and expires_at > now()),
    'orders', (select count(*) from orders),
    'ordersByState', (select coalesce(json_object_agg(k, c), '{}') from (
        select status || '/' || fulfillment_status k, count(*) c from orders group by 1) x),
    'notifications', (select count(*) from notifications),
    'notificationDeliveryLogsByChannelStatus', (select coalesce(json_object_agg(k, c), '{}') from (
        select channel || '/' || status k, count(*) c from notification_delivery_logs group by 1) x),
    'deliveries', (select count(*) from deliveries),
    'branchName', (select name from merchant_branches where id = '0d00f0f0-fa00-7000-8000-000000002001'))")
fi

redis_count() { redis-cli -h 127.0.0.1 -p 6381 -n "$1" DBSIZE; }
prefixed_keys() { redis-cli -h 127.0.0.1 -p 6381 -n "$1" --scan --pattern '*parityfx*' --count 1000 | wc -l | tr -d ' '; }
counter() { redis-cli -h 127.0.0.1 -p 6381 -n 0 GET "$1" 2>/dev/null || true; }
FOREIGN=$(fx_redis_foreign_keys | wc -l | tr -d ' ')

python3 - "$OUT" "$DEV_JSON" "$FX_JSON" <<PY
import json, sys
out, dev, fx = sys.argv[1], json.loads(sys.argv[2]), json.loads(sys.argv[3])
doc = {
  "takenAt": "$(date -u +%FT%TZ)",
  "devDb": dev,
  "fxDb": fx,
  "redis": {
    "dbsize": {"0": int("$(redis_count 0)"), "9": int("$(redis_count 9)"), "15": int("$(redis_count 15)")},
    "parityfxKeys": {"0": int("$(prefixed_keys 0)"), "15": int("$(prefixed_keys 15)"), "9": int("$(prefixed_keys 9)")},
    "index9KeysWithoutIsolatedPrefix": int("$FOREIGN"),
    "devJobCounters": {
      "bull:matching:notifications:id": "$(counter bull:matching:notifications:id)",
      "bull:matching:matching:id": "$(counter bull:matching:matching:id)",
    },
  },
}
open(out, "w").write(json.dumps(doc, indent=2, default=str) + "\n")
print(f"FX_SNAPSHOT {out}")
PY
