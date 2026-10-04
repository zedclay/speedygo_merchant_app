-- Isolated fixture for the Merchant financial-visibility verification
-- (speedygo_dev only). Dar El Bahja synthetic Merchant and Branch.
--
-- Adds two synthetic MerchantMember rows (STAFF, MANAGER) for accounts that
-- were created for this check only (+213550000081 / +213550000082), and two
-- orders marked 'sgo_finvis_%'. cleanup_financial_visibility_fixture.sql
-- removes every row. Finjan and existing role assignments are not touched.
--
-- Usage: psql -v staff_phone=+213550000081 -v manager_phone=+213550000082 \
--             -f seed_financial_visibility_fixture.sql
--   sgo_finvis_1  CREATED / PENDING_ACCEPTANCE, COD PENDING, merchant discount
--                 gross 255000, discount 5000, 700 bps on 250000 → 17500,
--                 net 232500, customer delivery fee 20000
--   sgo_finvis_2  COMPLETED 30 min ago (today, Africa/Algiers), COD SUCCEEDED
--                 gross 120000, 700 bps → 8400, net 111600

\set ON_ERROR_STOP on
BEGIN;

CREATE TEMP TABLE finvis_params ON COMMIT DROP AS
SELECT :'staff_phone'::text AS staff_phone, :'manager_phone'::text AS manager_phone;

DO $$
DECLARE
  p finvis_params%ROWTYPE;
BEGIN
  SELECT * INTO p FROM finvis_params;
  IF current_database() <> 'speedygo_dev' THEN
    RAISE EXCEPTION 'refusing to seed outside speedygo_dev';
  END IF;
  IF p.staff_phone NOT IN ('+213550000081') OR p.manager_phone NOT IN ('+213550000082') THEN
    RAISE EXCEPTION 'only the dedicated fixture phones are allowed';
  END IF;
  IF EXISTS (SELECT 1 FROM orders WHERE public_reference LIKE 'sgo_finvis_%') THEN
    RAISE EXCEPTION 'financial visibility fixture already present; run cleanup first';
  END IF;
  IF EXISTS (
    SELECT 1 FROM merchant_members mm JOIN accounts a ON a.id = mm.account_id
    WHERE a.phone IN (p.staff_phone, p.manager_phone)
  ) THEN
    RAISE EXCEPTION 'fixture accounts already hold a membership';
  END IF;
  IF (SELECT count(*) FROM accounts WHERE phone IN (p.staff_phone, p.manager_phone)) <> 2 THEN
    RAISE EXCEPTION 'fixture accounts must be created by OTP login first';
  END IF;
  IF (now() AT TIME ZONE 'Africa/Algiers')::time < time '00:45' THEN
    RAISE EXCEPTION 'run after 00:45 Africa/Algiers so sgo_finvis_2 falls today';
  END IF;
END $$;

INSERT INTO merchant_members (id, merchant_id, account_id, role, created_at)
SELECT gen_random_uuid(), '0d00c071-d000-7000-8000-000000010001', a.id,
       CASE WHEN a.phone = p.staff_phone THEN 'STAFF' ELSE 'MANAGER' END, now()
FROM accounts a, finvis_params p
WHERE a.phone IN (p.staff_phone, p.manager_phone);

CREATE TEMP TABLE finvis_seed (
  n int PRIMARY KEY,
  order_id uuid NOT NULL DEFAULT gen_random_uuid(),
  status text NOT NULL,
  fulfillment text NOT NULL,
  created_at timestamptz NOT NULL,
  completed_at timestamptz,
  gms bigint NOT NULL,
  discount bigint NOT NULL,
  payment_status text NOT NULL
) ON COMMIT DROP;

INSERT INTO finvis_seed (n, status, fulfillment, created_at, completed_at, gms, discount, payment_status)
VALUES
  (1, 'CREATED', 'PENDING_ACCEPTANCE', now() - interval '5 minutes', NULL, 255000, 5000, 'PENDING'),
  (2, 'COMPLETED', 'READY', now() - interval '40 minutes', now() - interval '30 minutes', 120000, 0, 'SUCCEEDED');

INSERT INTO orders (
  id, public_reference, status, fulfillment_status, customer_id,
  delivery_zone_id, merchant_branch_id, created_at, confirmed_at,
  completed_at, updated_at, preparation_estimate_version
)
SELECT
  s.order_id, 'sgo_finvis_' || s.n, s.status, s.fulfillment,
  '01a0d4b6-5338-7d6c-aa70-426bf92f49a6',
  '0d00c071-d000-7000-8000-0000000a0001',
  '0d00c071-d000-7000-8000-000000011001',
  s.created_at,
  CASE WHEN s.n = 2 THEN s.created_at + interval '2 minutes' END,
  s.completed_at,
  coalesce(s.completed_at, s.created_at),
  0
FROM finvis_seed s;

INSERT INTO order_items (
  id, order_id, product_id, product_name_snapshot, quantity,
  unit_price_minor, line_total_minor
)
SELECT gen_random_uuid(), s.order_id, i.product_id, i.name, i.qty, i.unit, i.qty * i.unit
FROM (VALUES
    (1, '0d00c071-d000-7000-8000-000000030101'::uuid, 'Couscous royal', 2, 120000::bigint),
    (1, '0d00c071-d000-7000-8000-000000030141'::uuid, 'Thé à la menthe', 1, 15000::bigint),
    (2, '0d00c071-d000-7000-8000-000000030101'::uuid, 'Couscous royal', 1, 120000::bigint)
  ) AS i(n, product_id, name, qty, unit)
JOIN finvis_seed s ON s.n = i.n;

-- Historical snapshot: commission = (gross − merchant discount) × 700 / 10000.
INSERT INTO order_financial_snapshots (
  order_id, currency, gross_merchandise_subtotal_minor,
  merchant_discount_minor, platform_discount_minor, total_discount_minor,
  commission_base_minor, merchant_commission_rate_bps,
  merchant_commission_amount_minor, merchant_net_amount_minor,
  customer_delivery_fee_minor, driver_remuneration_minor,
  speedygo_delivery_share_minor, service_fee_minor, customer_payable_minor,
  commission_rule_id, pricing_rule_id, created_at
)
SELECT
  s.order_id, 'DZD', s.gms, s.discount, 0, s.discount,
  s.gms - s.discount, 700,
  (s.gms - s.discount) * 700 / 10000,
  (s.gms - s.discount) - (s.gms - s.discount) * 700 / 10000,
  20000, 15000, 5000, 0, s.gms - s.discount + 20000,
  '0d00c071-d000-7000-8000-0000000a0003',
  '0d00c071-d000-7000-8000-0000000a0002',
  s.created_at
FROM finvis_seed s;

INSERT INTO payments (id, order_id, method, status, amount_minor, currency, created_at, updated_at)
SELECT gen_random_uuid(), s.order_id, 'COD', s.payment_status, s.gms - s.discount + 20000, 'DZD',
       s.created_at, coalesce(s.completed_at, s.created_at)
FROM finvis_seed s;

INSERT INTO order_delivery_address_snapshots (order_id, address_text, instructions, latitude, longitude)
SELECT s.order_id, 'Adresse de test — fixture visibilité financière', NULL, 36.7538, 3.0588
FROM finvis_seed s;

SELECT o.public_reference, o.status, o.fulfillment_status,
       f.gross_merchandise_subtotal_minor AS gms, f.merchant_discount_minor AS discount,
       f.merchant_commission_amount_minor AS commission, f.merchant_net_amount_minor AS net
FROM orders o JOIN order_financial_snapshots f ON f.order_id = o.id
WHERE o.public_reference LIKE 'sgo_finvis_%' ORDER BY o.public_reference;

SELECT a.phone, mm.role FROM merchant_members mm JOIN accounts a ON a.id = mm.account_id
WHERE mm.merchant_id = '0d00c071-d000-7000-8000-000000010001' ORDER BY mm.role;

COMMIT;
