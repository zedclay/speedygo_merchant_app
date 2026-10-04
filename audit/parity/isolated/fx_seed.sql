-- Explicit fixture identities for the disposable Merchant write-test database.
-- SYNTHETIC ONLY. Namespace 0d00f0f0-fa00-7000-8000-*. Target: speedygo_parity_fx
-- on port 5433, created by fx_start.sh and dropped by fx_cleanup.sh.
--
-- Identities:
--   OWNER +213550009101, MANAGER +213550009102, STAFF +213550009103
--   customer +213550009111 (one address inside the fixture zone)
--   merchant "Comptoir Essai" / branch "Comptoir Essai", open 24 h
--   one delivery zone, one all-day pricing rule (fee 20000, driver 15000),
--   one GLOBAL_DEFAULT commission rule (700 bps), owned by a non-login admin
--   profile that only satisfies the commission-rule foreign key
--   3 categories, 6 products; option groups on "Couscous royal" and "Poulet rôti"
--   foreign merchant "Atelier Voisin" (owner +213550009104, never logs in),
--   one branch, one category, one product — cross-tenant refusals only
--   5 COMPLETED report orders, today in Africa/Algiers (10..55 min ago)
-- Incoming orders are not seeded: fx_create_incoming.py places them through
-- the real checkout on the isolated API.

\set ON_ERROR_STOP on
BEGIN;

DO $$
BEGIN
  IF current_database() <> 'speedygo_parity_fx' OR inet_server_port() <> 5433 THEN
    RAISE EXCEPTION 'refused: expected speedygo_parity_fx on 5433, got % on %',
      current_database(), inet_server_port();
  END IF;
  IF coalesce(shobj_description(
       (SELECT oid FROM pg_database WHERE datname = current_database()), 'pg_database'), '')
     NOT LIKE 'speedygo-parity-fx disposable%' THEN
    RAISE EXCEPTION 'refused: database is not marked as the disposable fixture database';
  END IF;
  IF EXISTS (SELECT 1 FROM accounts) OR EXISTS (SELECT 1 FROM orders) THEN
    RAISE EXCEPTION 'refused: database is not empty; seed runs once on a fresh database';
  END IF;
  IF (now() AT TIME ZONE 'Africa/Algiers')::date
     <> ((now() - interval '55 minutes') AT TIME ZONE 'Africa/Algiers')::date THEN
    RAISE EXCEPTION 'refused: report orders must fall today in Africa/Algiers (run after 01:00 local)';
  END IF;
END $$;

INSERT INTO accounts (id, phone, email, status) VALUES
  ('0d00f0f0-fa00-7000-8000-000000000101', '+213550009101', NULL, 'ACTIVE'),
  ('0d00f0f0-fa00-7000-8000-000000000102', '+213550009102', NULL, 'ACTIVE'),
  ('0d00f0f0-fa00-7000-8000-000000000103', '+213550009103', NULL, 'ACTIVE'),
  ('0d00f0f0-fa00-7000-8000-000000000111', '+213550009111', NULL, 'ACTIVE'),
  ('0d00f0f0-fa00-7000-8000-000000000121', '+213550009121', NULL, 'ACTIVE');

INSERT INTO customer_profiles (id, account_id, full_name, avatar_url) VALUES
  ('0d00f0f0-fa00-7000-8000-000000000112', '0d00f0f0-fa00-7000-8000-000000000111',
   'Client Essai Isolé', NULL);

INSERT INTO addresses (id, customer_id, label, address_text, latitude, longitude, is_default) VALUES
  ('0d00f0f0-fa00-7000-8000-000000000113', '0d00f0f0-fa00-7000-8000-000000000112',
   'Bureau', 'Adresse fictive — 12 rue d''Essai, Alger-Centre', 36.77000, 3.05000, TRUE);

INSERT INTO roles (id, name, description, active) VALUES
  ('0d00f0f0-fa00-7000-8000-000000000122', 'parity-fx-fixture-admin',
   'Disposable fixture database only. Owns the fixture commission rule.', TRUE);

INSERT INTO admin_profiles (id, account_id, display_name, role_id) VALUES
  ('0d00f0f0-fa00-7000-8000-000000000123', '0d00f0f0-fa00-7000-8000-000000000121',
   'Fixture Admin (non-login)', '0d00f0f0-fa00-7000-8000-000000000122');

INSERT INTO merchants (id, public_reference, name, status, verified_at) VALUES
  ('0d00f0f0-fa00-7000-8000-000000001001', 'sgm_parityfx_01', 'Comptoir Essai', 'ACTIVE', now());

INSERT INTO merchant_branches (id, merchant_id, name, phone, address_text, latitude, longitude, operational_status) VALUES
  ('0d00f0f0-fa00-7000-8000-000000002001', '0d00f0f0-fa00-7000-8000-000000001001',
   'Comptoir Essai', '+213550009201',
   'Commerce fictif — base de test isolée. 3 rue de l''Essai, Alger-Centre.',
   36.78500, 3.06000, 'ACTIVE');

INSERT INTO merchant_members (id, merchant_id, account_id, role) VALUES
  ('0d00f0f0-fa00-7000-8000-000000003001', '0d00f0f0-fa00-7000-8000-000000001001', '0d00f0f0-fa00-7000-8000-000000000101', 'OWNER'),
  ('0d00f0f0-fa00-7000-8000-000000003002', '0d00f0f0-fa00-7000-8000-000000001001', '0d00f0f0-fa00-7000-8000-000000000102', 'MANAGER'),
  ('0d00f0f0-fa00-7000-8000-000000003003', '0d00f0f0-fa00-7000-8000-000000001001', '0d00f0f0-fa00-7000-8000-000000000103', 'STAFF');

INSERT INTO merchant_branch_opening_schedules (id, branch_id, version, updated_by_account_id) VALUES
  ('0d00f0f0-fa00-7000-8000-000000004001', '0d00f0f0-fa00-7000-8000-000000002001', 1,
   '0d00f0f0-fa00-7000-8000-000000000101');

INSERT INTO merchant_branch_opening_intervals (id, schedule_id, day_of_week, opens_minute, closes_minute, closes_next_day, sort_order)
SELECT ('0d00f0f0-fa00-7000-8000-00000000410' || d)::uuid,
       '0d00f0f0-fa00-7000-8000-000000004001', d, 0, 0, TRUE, 0
FROM generate_series(1, 7) AS d;

INSERT INTO delivery_zones (id, name, geometry, active) VALUES
  ('0d00f0f0-fa00-7000-8000-000000005001', 'FIXTURE ISOLÉE Alger',
   ST_GeomFromText('MULTIPOLYGON(((2.95 36.7,2.95 36.85,3.2 36.85,3.2 36.7,2.95 36.7)))', 4326),
   TRUE);

INSERT INTO delivery_pricing_rules (id, zone_id, name, time_band, customer_delivery_fee_minor,
  driver_remuneration_minor, start_local_time, end_local_time, effective_from, effective_to, active) VALUES
  ('0d00f0f0-fa00-7000-8000-000000005002', '0d00f0f0-fa00-7000-8000-000000005001',
   'FIXTURE ISOLÉE jour', 'DAY', 20000, 15000, NULL, NULL, now() - interval '30 days', NULL, TRUE);

INSERT INTO merchant_commission_rules (id, scope, merchant_id, rate_bps, effective_from, effective_to,
  active, changed_by_admin_id, change_reason) VALUES
  ('0d00f0f0-fa00-7000-8000-000000005003', 'GLOBAL_DEFAULT', NULL, 700, now() - interval '30 days', NULL,
   TRUE, '0d00f0f0-fa00-7000-8000-000000000123', 'Disposable fixture database');

INSERT INTO categories (id, merchant_branch_id, name, sort_order, active) VALUES
  ('0d00f0f0-fa00-7000-8000-000000006001', '0d00f0f0-fa00-7000-8000-000000002001', 'Plats', 1, TRUE),
  ('0d00f0f0-fa00-7000-8000-000000006002', '0d00f0f0-fa00-7000-8000-000000002001', 'Entrées', 2, TRUE),
  ('0d00f0f0-fa00-7000-8000-000000006003', '0d00f0f0-fa00-7000-8000-000000002001', 'Boissons', 3, TRUE);

INSERT INTO products (id, merchant_branch_id, category_id, name, description, price_minor, available) VALUES
  ('0d00f0f0-fa00-7000-8000-000000007001', '0d00f0f0-fa00-7000-8000-000000002001', '0d00f0f0-fa00-7000-8000-000000006001',
   'Couscous royal', 'Semoule, poulet, agneau et pois chiches.', 120000, TRUE),
  ('0d00f0f0-fa00-7000-8000-000000007002', '0d00f0f0-fa00-7000-8000-000000002001', '0d00f0f0-fa00-7000-8000-000000006001',
   'Poulet rôti', 'Demi-poulet rôti aux herbes.', 95000, TRUE),
  ('0d00f0f0-fa00-7000-8000-000000007003', '0d00f0f0-fa00-7000-8000-000000002001', '0d00f0f0-fa00-7000-8000-000000006002',
   'Chorba frik', 'Soupe de blé vert, tomate et coriandre.', 45000, TRUE),
  ('0d00f0f0-fa00-7000-8000-000000007004', '0d00f0f0-fa00-7000-8000-000000002001', '0d00f0f0-fa00-7000-8000-000000006002',
   'Salade méchouia', 'Poivrons et tomates grillés.', 40000, TRUE),
  ('0d00f0f0-fa00-7000-8000-000000007005', '0d00f0f0-fa00-7000-8000-000000002001', '0d00f0f0-fa00-7000-8000-000000006003',
   'Thé à la menthe', 'Thé vert et menthe fraîche.', 15000, TRUE),
  ('0d00f0f0-fa00-7000-8000-000000007006', '0d00f0f0-fa00-7000-8000-000000002001', '0d00f0f0-fa00-7000-8000-000000006003',
   'Jus d’orange pressé', 'Oranges pressées à la commande.', 25000, TRUE);

-- Catalogue configuration for the duplication checks (contract-completion batch).
-- 7001 carries one required and one optional group; 7002 carries the option the
-- rollback check targets with a temporary trigger. Customer orders use 7003 only.
INSERT INTO product_option_groups (id, product_id, name, required, min_selections, max_selections, created_at) VALUES
  ('0d00f0f0-fa00-7000-8000-000000007201', '0d00f0f0-fa00-7000-8000-000000007001', 'Taille', TRUE, 1, 1, now() - interval '3 hours'),
  ('0d00f0f0-fa00-7000-8000-000000007202', '0d00f0f0-fa00-7000-8000-000000007001', 'Suppléments', FALSE, 0, 3, now() - interval '2 hours'),
  ('0d00f0f0-fa00-7000-8000-000000007203', '0d00f0f0-fa00-7000-8000-000000007002', 'Sauce', FALSE, 0, 1, now() - interval '2 hours');

INSERT INTO product_options (id, option_group_id, name, additional_price_minor, available, created_at) VALUES
  ('0d00f0f0-fa00-7000-8000-000000007301', '0d00f0f0-fa00-7000-8000-000000007201', 'Normale', 0, TRUE, now() - interval '3 hours'),
  ('0d00f0f0-fa00-7000-8000-000000007302', '0d00f0f0-fa00-7000-8000-000000007201', 'Grande', 30000, TRUE, now() - interval '170 minutes'),
  ('0d00f0f0-fa00-7000-8000-000000007303', '0d00f0f0-fa00-7000-8000-000000007202', 'Merguez', 25000, TRUE, now() - interval '2 hours'),
  ('0d00f0f0-fa00-7000-8000-000000007304', '0d00f0f0-fa00-7000-8000-000000007202', 'Œuf dur', 5000, FALSE, now() - interval '110 minutes'),
  ('0d00f0f0-fa00-7000-8000-000000007305', '0d00f0f0-fa00-7000-8000-000000007202', 'Raisins secs', 4000, TRUE, now() - interval '100 minutes'),
  ('0d00f0f0-fa00-7000-8000-000000007306', '0d00f0f0-fa00-7000-8000-000000007203', 'Harissa', 0, TRUE, now() - interval '2 hours'),
  ('0d00f0f0-fa00-7000-8000-000000007307', '0d00f0f0-fa00-7000-8000-000000007203', 'Sauce piquante (fx-fail)', 2000, TRUE, now() - interval '110 minutes');

-- A second, foreign merchant for cross-tenant refusals. Its owner never logs in.
INSERT INTO accounts (id, phone, email, status) VALUES
  ('0d00f0f0-fa00-7000-8000-000000000104', '+213550009104', NULL, 'ACTIVE');
INSERT INTO merchants (id, public_reference, name, status, verified_at) VALUES
  ('0d00f0f0-fa00-7000-8000-000000001002', 'sgm_parityfx_02', 'Atelier Voisin', 'ACTIVE', now());
INSERT INTO merchant_branches (id, merchant_id, name, phone, address_text, latitude, longitude, operational_status) VALUES
  ('0d00f0f0-fa00-7000-8000-000000002002', '0d00f0f0-fa00-7000-8000-000000001002',
   'Atelier Voisin', '+213550009202', 'Commerce fictif étranger — base de test isolée.', 36.78600, 3.06100, 'ACTIVE');
INSERT INTO merchant_members (id, merchant_id, account_id, role) VALUES
  ('0d00f0f0-fa00-7000-8000-000000003004', '0d00f0f0-fa00-7000-8000-000000001002', '0d00f0f0-fa00-7000-8000-000000000104', 'OWNER');
INSERT INTO categories (id, merchant_branch_id, name, sort_order, active) VALUES
  ('0d00f0f0-fa00-7000-8000-000000006101', '0d00f0f0-fa00-7000-8000-000000002002', 'Pâtisseries', 1, TRUE);
INSERT INTO products (id, merchant_branch_id, category_id, name, description, price_minor, available) VALUES
  ('0d00f0f0-fa00-7000-8000-000000007101', '0d00f0f0-fa00-7000-8000-000000002002', '0d00f0f0-fa00-7000-8000-000000006101',
   'Makrout', 'Produit d’un autre commerçant.', 8000, TRUE);

CREATE TEMP TABLE fx_report_orders (
  n int PRIMARY KEY,
  order_id uuid NOT NULL,
  completed_at timestamptz NOT NULL
) ON COMMIT DROP;

INSERT INTO fx_report_orders (n, order_id, completed_at)
SELECT n, ('0d00f0f0-fa00-7000-8000-00000000800' || n)::uuid,
       now() - make_interval(mins => 5 + 10 * n)
FROM generate_series(1, 5) AS n;

CREATE TEMP TABLE fx_report_items (
  n int NOT NULL,
  line int NOT NULL,
  product_id uuid NOT NULL,
  name text NOT NULL,
  qty int NOT NULL,
  unit bigint NOT NULL
) ON COMMIT DROP;

INSERT INTO fx_report_items VALUES
  (1, 1, '0d00f0f0-fa00-7000-8000-000000007001', 'Couscous royal', 2, 120000),
  (1, 2, '0d00f0f0-fa00-7000-8000-000000007005', 'Thé à la menthe', 1, 15000),
  (2, 1, '0d00f0f0-fa00-7000-8000-000000007003', 'Chorba frik', 1, 45000),
  (2, 2, '0d00f0f0-fa00-7000-8000-000000007005', 'Thé à la menthe', 2, 15000),
  (3, 1, '0d00f0f0-fa00-7000-8000-000000007002', 'Poulet rôti', 1, 95000),
  (3, 2, '0d00f0f0-fa00-7000-8000-000000007006', 'Jus d’orange pressé', 1, 25000),
  (4, 1, '0d00f0f0-fa00-7000-8000-000000007001', 'Couscous royal', 1, 120000),
  (5, 1, '0d00f0f0-fa00-7000-8000-000000007001', 'Couscous royal', 1, 120000),
  (5, 2, '0d00f0f0-fa00-7000-8000-000000007006', 'Jus d’orange pressé', 2, 25000);

INSERT INTO orders (id, public_reference, status, fulfillment_status, customer_id, delivery_zone_id,
  merchant_branch_id, created_at, confirmed_at, completed_at, updated_at, preparation_estimate_version)
SELECT r.order_id, 'sgo_parityfx_rpt_' || r.n, 'COMPLETED', 'READY',
       '0d00f0f0-fa00-7000-8000-000000000112', '0d00f0f0-fa00-7000-8000-000000005001',
       '0d00f0f0-fa00-7000-8000-000000002001',
       r.completed_at - interval '40 minutes', r.completed_at - interval '38 minutes',
       r.completed_at, r.completed_at, 0
FROM fx_report_orders r;

INSERT INTO order_items (id, order_id, product_id, product_name_snapshot, quantity, unit_price_minor, line_total_minor)
SELECT ('0d00f0f0-fa00-7000-8000-0000000081' || i.n || i.line)::uuid, r.order_id, i.product_id, i.name,
       i.qty, i.unit, i.qty * i.unit
FROM fx_report_items i
JOIN fx_report_orders r ON r.n = i.n;

-- Historical snapshot: commission = base × 700 / 10000 (integer minor units, exact here).
INSERT INTO order_financial_snapshots (order_id, currency, gross_merchandise_subtotal_minor,
  merchant_discount_minor, platform_discount_minor, total_discount_minor, commission_base_minor,
  merchant_commission_rate_bps, merchant_commission_amount_minor, merchant_net_amount_minor,
  customer_delivery_fee_minor, driver_remuneration_minor, speedygo_delivery_share_minor,
  service_fee_minor, customer_payable_minor, commission_rule_id, pricing_rule_id, created_at)
SELECT r.order_id, 'DZD', t.gms, 0, 0, 0, t.gms, 700, t.gms * 700 / 10000, t.gms - t.gms * 700 / 10000,
       20000, 15000, 5000, 0, t.gms + 20000,
       '0d00f0f0-fa00-7000-8000-000000005003', '0d00f0f0-fa00-7000-8000-000000005002',
       r.completed_at - interval '40 minutes'
FROM fx_report_orders r
JOIN (SELECT n, sum(qty * unit)::bigint AS gms FROM fx_report_items GROUP BY n) t ON t.n = r.n;

INSERT INTO order_delivery_address_snapshots (order_id, address_text, instructions, latitude, longitude)
SELECT r.order_id, 'Adresse fictive — 12 rue d''Essai, Alger-Centre', NULL, 36.77000, 3.05000
FROM fx_report_orders r;

-- Active commerce verticals for Merchant store-category self-select (row 53).
INSERT INTO commerce_verticals (id, slug, name, icon_key, sort_order, active) VALUES
  ('0d00f0f0-fa00-7000-8000-000000008001', 'restaurant', 'Restaurant', 'restaurant', 10, TRUE),
  ('0d00f0f0-fa00-7000-8000-000000008002', 'boulangerie', 'Boulangerie', 'bakery_dining', 20, TRUE),
  ('0d00f0f0-fa00-7000-8000-000000008003', 'epicerie', 'Épicerie', 'local_mall', 30, TRUE),
  ('0d00f0f0-fa00-7000-8000-000000008004', 'pharmacie', 'Pharmacie', 'medical_services', 40, FALSE);

SELECT 'seeded accounts=' || (SELECT count(*) FROM accounts)
    || ' members=' || (SELECT count(*) FROM merchant_members)
    || ' products=' || (SELECT count(*) FROM products)
    || ' option_groups=' || (SELECT count(*) FROM product_option_groups)
    || ' options=' || (SELECT count(*) FROM product_options)
    || ' completed_orders=' || (SELECT count(*) FROM orders WHERE status = 'COMPLETED')
    || ' gms_today=' || (SELECT sum(gross_merchandise_subtotal_minor) FROM order_financial_snapshots)
    || ' verticals=' || (SELECT count(*) FROM commerce_verticals WHERE active);

COMMIT;
