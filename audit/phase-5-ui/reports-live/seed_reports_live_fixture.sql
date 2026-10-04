-- Controlled live fixture for the Merchant reports smoke (speedygo_dev only).
-- Dar El Bahja synthetic Merchant, branch 0d00c071-…-000000011001.
-- Every row is marked by public_reference 'sgo_rptlive_%' and removed by
-- cleanup_reports_live_fixture.sql. Not real sales.
--
-- Usage: psql -v day=YYYY-MM-DD -f seed_reports_live_fixture.sql
-- `day` = the current Africa/Algiers date; must not be a Monday (yesterday must
-- fall in the same ISO week) and local time must be after 01:35.
--   today      4 COMPLETED orders at 00:15/00:45/01:10/01:35 local, 700 bps
--   yesterday  1 COMPLETED order at 19:00 local, snapshot rate 1000 bps
-- Expected TODAY:     4 orders, gross 570000, commission 39900, net 530100, 7%
-- Expected THIS_WEEK: 5 orders, gross 655000, commission 48400, net 606600, mixed rates

\set ON_ERROR_STOP on
BEGIN;

DO $$
BEGIN
  IF current_database() <> 'speedygo_dev' THEN
    RAISE EXCEPTION 'refusing to seed outside speedygo_dev';
  END IF;
  IF EXISTS (SELECT 1 FROM orders WHERE public_reference LIKE 'sgo_rptlive_%') THEN
    RAISE EXCEPTION 'reports live fixture already present; run cleanup first';
  END IF;
END $$;

CREATE TEMP TABLE rpt_seed (
  n int PRIMARY KEY,
  order_id uuid NOT NULL DEFAULT gen_random_uuid(),
  completed_at timestamptz NOT NULL,
  rate_bps int NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE rpt_day ON COMMIT DROP AS SELECT :'day'::date AS d;

INSERT INTO rpt_seed (n, completed_at, rate_bps)
SELECT n, ((SELECT d FROM rpt_day) + day_offset + t) AT TIME ZONE 'Africa/Algiers', rate
FROM (VALUES
    (1, 0, time '00:15', 700),
    (2, 0, time '00:45', 700),
    (3, 0, time '01:10', 700),
    (4, 0, time '01:35', 700),
    (5, -1, time '19:00', 1000)
  ) AS v(n, day_offset, t, rate);

DO $$
DECLARE
  seed_day date := (SELECT d FROM rpt_day);
BEGIN
  IF seed_day <> (now() AT TIME ZONE 'Africa/Algiers')::date THEN
    RAISE EXCEPTION 'day must be the current Africa/Algiers date';
  END IF;
  IF extract(isodow FROM seed_day) = 1 THEN
    RAISE EXCEPTION 'day is a Monday; yesterday would leave the ISO week';
  END IF;
  IF EXISTS (SELECT 1 FROM rpt_seed WHERE completed_at > now()) THEN
    RAISE EXCEPTION 'seed times must be in the past (run after 01:35 local)';
  END IF;
END $$;

CREATE TEMP TABLE rpt_items (
  n int NOT NULL,
  product_id uuid NOT NULL,
  name text NOT NULL,
  qty int NOT NULL,
  unit bigint NOT NULL
) ON COMMIT DROP;

INSERT INTO rpt_items VALUES
  (1, '0d00c071-d000-7000-8000-000000030101', 'Couscous royal', 2, 120000),
  (1, '0d00c071-d000-7000-8000-000000030141', 'Thé à la menthe', 1, 15000),
  (2, '0d00c071-d000-7000-8000-000000030121', 'Chorba frik', 1, 45000),
  (2, '0d00c071-d000-7000-8000-000000030141', 'Thé à la menthe', 2, 15000),
  (3, '0d00c071-d000-7000-8000-000000030103', 'Poulet rôti', 1, 95000),
  (3, '0d00c071-d000-7000-8000-000000030142', 'Jus d’orange pressé', 1, 25000),
  (4, '0d00c071-d000-7000-8000-000000030101', 'Couscous royal', 1, 120000),
  (5, '0d00c071-d000-7000-8000-000000030102', 'Couscous légumes', 1, 85000);

INSERT INTO orders (
  id, public_reference, status, fulfillment_status, customer_id,
  delivery_zone_id, merchant_branch_id, created_at, confirmed_at,
  completed_at, updated_at, preparation_estimate_version
)
SELECT
  s.order_id,
  'sgo_rptlive_' || s.n,
  'COMPLETED',
  'READY',
  '01a0d4b6-5338-7d6c-aa70-426bf92f49a6',
  '0d00c071-d000-7000-8000-0000000a0001',
  '0d00c071-d000-7000-8000-000000011001',
  s.completed_at - interval '40 minutes',
  s.completed_at - interval '38 minutes',
  s.completed_at,
  s.completed_at,
  0
FROM rpt_seed s;

INSERT INTO order_items (
  id, order_id, product_id, product_name_snapshot, quantity,
  unit_price_minor, line_total_minor
)
SELECT gen_random_uuid(), s.order_id, i.product_id, i.name, i.qty, i.unit,
       i.qty * i.unit
FROM rpt_items i
JOIN rpt_seed s ON s.n = i.n;

-- Historical snapshot: commission = base × rate / 10000 (integer, exact here).
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
  s.order_id, 'DZD', t.gms, 0, 0, 0, t.gms, s.rate_bps,
  t.gms * s.rate_bps / 10000,
  t.gms - t.gms * s.rate_bps / 10000,
  20000, 15000, 5000, 0, t.gms + 20000,
  '0d00c071-d000-7000-8000-0000000a0003',
  '0d00c071-d000-7000-8000-0000000a0002',
  s.completed_at - interval '40 minutes'
FROM rpt_seed s
JOIN (
  SELECT n, SUM(qty * unit)::bigint AS gms FROM rpt_items GROUP BY n
) t ON t.n = s.n;

INSERT INTO order_delivery_address_snapshots (
  order_id, address_text, instructions, latitude, longitude
)
SELECT s.order_id, 'Adresse de test — fixture rapports', NULL, 36.7538, 3.0588
FROM rpt_seed s;

SELECT o.public_reference, o.completed_at AT TIME ZONE 'Africa/Algiers' AS local_completed,
       f.gross_merchandise_subtotal_minor AS gms,
       f.merchant_commission_rate_bps AS rate,
       f.merchant_commission_amount_minor AS commission,
       f.merchant_net_amount_minor AS net
FROM orders o
JOIN order_financial_snapshots f ON f.order_id = o.id
WHERE o.public_reference LIKE 'sgo_rptlive_%'
ORDER BY o.completed_at;

COMMIT;
