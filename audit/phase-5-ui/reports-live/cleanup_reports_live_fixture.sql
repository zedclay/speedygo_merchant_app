-- Removes the controlled reports live fixture (public_reference 'sgo_rptlive_%').
\set ON_ERROR_STOP on
BEGIN;

DO $$
BEGIN
  IF current_database() <> 'speedygo_dev' THEN
    RAISE EXCEPTION 'refusing to clean outside speedygo_dev';
  END IF;
END $$;

CREATE TEMP TABLE rpt_ids ON COMMIT DROP AS
SELECT id FROM orders WHERE public_reference LIKE 'sgo_rptlive_%';

DELETE FROM order_delivery_address_snapshots WHERE order_id IN (SELECT id FROM rpt_ids);
DELETE FROM order_financial_snapshots WHERE order_id IN (SELECT id FROM rpt_ids);
DELETE FROM order_items WHERE order_id IN (SELECT id FROM rpt_ids);
DELETE FROM order_status_events WHERE order_id IN (SELECT id FROM rpt_ids);
DELETE FROM orders WHERE id IN (SELECT id FROM rpt_ids);

SELECT COUNT(*) AS remaining FROM orders WHERE public_reference LIKE 'sgo_rptlive_%';

COMMIT;
