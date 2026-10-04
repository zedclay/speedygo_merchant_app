-- Removes the financial-visibility fixture: 'sgo_finvis_%' orders, the two
-- synthetic memberships and the fixture accounts +213550000081/+213550000082
-- (with their sessions/devices/notifications). Owner and Finjan untouched.
\set ON_ERROR_STOP on
BEGIN;

DO $$
BEGIN
  IF current_database() <> 'speedygo_dev' THEN
    RAISE EXCEPTION 'refusing to clean outside speedygo_dev';
  END IF;
END $$;

CREATE TEMP TABLE finvis_orders ON COMMIT DROP AS
SELECT id FROM orders WHERE public_reference LIKE 'sgo_finvis_%';

CREATE TEMP TABLE finvis_accounts ON COMMIT DROP AS
SELECT id FROM accounts WHERE phone IN ('+213550000081', '+213550000082');

-- The dev backend emits MERCHANT_ORDER_CREATED / PAYMENT_SUCCEEDED notifications
-- (category '<TYPE>:<orderId|paymentId>') for the seeded rows, including to the
-- owner and the fixture customer.
CREATE TEMP TABLE finvis_notifications ON COMMIT DROP AS
SELECT n.id FROM notifications n
WHERE n.account_id IN (SELECT id FROM finvis_accounts)
   OR split_part(n.category, ':', 2) IN (
        SELECT id::text FROM finvis_orders
        UNION ALL
        SELECT p.id::text FROM payments p WHERE p.order_id IN (SELECT id FROM finvis_orders));

DELETE FROM notification_delivery_logs WHERE notification_id IN (SELECT id FROM finvis_notifications);
DELETE FROM notifications WHERE id IN (SELECT id FROM finvis_notifications);

DELETE FROM payments WHERE order_id IN (SELECT id FROM finvis_orders);
DELETE FROM order_delivery_address_snapshots WHERE order_id IN (SELECT id FROM finvis_orders);
DELETE FROM order_financial_snapshots WHERE order_id IN (SELECT id FROM finvis_orders);
DELETE FROM order_items WHERE order_id IN (SELECT id FROM finvis_orders);
DELETE FROM order_status_events WHERE order_id IN (SELECT id FROM finvis_orders);
DELETE FROM orders WHERE id IN (SELECT id FROM finvis_orders);

DELETE FROM merchant_members WHERE account_id IN (SELECT id FROM finvis_accounts);
DELETE FROM device_tokens WHERE account_id IN (SELECT id FROM finvis_accounts);
DELETE FROM devices WHERE account_id IN (SELECT id FROM finvis_accounts);
DELETE FROM sessions WHERE account_id IN (SELECT id FROM finvis_accounts);
DELETE FROM accounts WHERE id IN (SELECT id FROM finvis_accounts);

SELECT
  (SELECT count(*) FROM orders WHERE public_reference LIKE 'sgo_finvis_%') AS orders_left,
  (SELECT count(*) FROM accounts WHERE phone IN ('+213550000081', '+213550000082')) AS accounts_left,
  (SELECT count(*) FROM finvis_notifications) AS fixture_notifications_removed,
  (SELECT count(*) FROM notifications WHERE id IN (SELECT id FROM finvis_notifications)) AS fixture_notifications_left,
  (SELECT string_agg(mm.role, ',' ORDER BY mm.role) FROM merchant_members mm
    WHERE mm.merchant_id = '0d00c071-d000-7000-8000-000000010001') AS dar_el_bahja_roles;

COMMIT;
