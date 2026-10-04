-- Additive identities for Catalogue / Concept V1 gap-close only.
-- Target: speedygo_parity_fx on 5433 (already seeded by fx_seed.sql).
-- Namespace 0d00f0f0-fa00-7000-8000-000000009*.

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
END $$;

-- Extra products on Comptoir Essai so Catalogue scrolls past the 48 px dock threshold.
INSERT INTO products (id, merchant_branch_id, category_id, name, description, price_minor, available)
SELECT
  ('0d00f0f0-fa00-7000-8000-0000000090' || lpad(n::text, 2, '0'))::uuid,
  '0d00f0f0-fa00-7000-8000-000000002001',
  (CASE (n % 3)
    WHEN 1 THEN '0d00f0f0-fa00-7000-8000-000000006001'
    WHEN 2 THEN '0d00f0f0-fa00-7000-8000-000000006002'
    ELSE '0d00f0f0-fa00-7000-8000-000000006003'
  END)::uuid,
  'Plat essai ' || n,
  'Produit de défilement isolé n°' || n,
  10000 + (n * 500),
  TRUE
FROM generate_series(1, 24) AS n;

-- Empty Catalogue merchant (OWNER never overlaps Finjan / Comptoir Essai login in this pass).
INSERT INTO accounts (id, phone, email, status) VALUES
  ('0d00f0f0-fa00-7000-8000-000000000105', '+213550009105', NULL, 'ACTIVE');

INSERT INTO merchants (id, public_reference, name, status, verified_at) VALUES
  ('0d00f0f0-fa00-7000-8000-000000001003', 'sgm_parityfx_03', 'Comptoir Vide', 'ACTIVE', now());

INSERT INTO merchant_branches (id, merchant_id, name, phone, address_text, latitude, longitude, operational_status) VALUES
  ('0d00f0f0-fa00-7000-8000-000000002003', '0d00f0f0-fa00-7000-8000-000000001003',
   'Comptoir Vide', '+213550009205',
   'Commerce fictif vide — base de test isolée.', 36.78700, 3.06200, 'ACTIVE');

INSERT INTO merchant_members (id, merchant_id, account_id, role) VALUES
  ('0d00f0f0-fa00-7000-8000-000000003005', '0d00f0f0-fa00-7000-8000-000000001003',
   '0d00f0f0-fa00-7000-8000-000000000105', 'OWNER');

INSERT INTO categories (id, merchant_branch_id, name, sort_order, active) VALUES
  ('0d00f0f0-fa00-7000-8000-000000006201', '0d00f0f0-fa00-7000-8000-000000002003',
   'Rayon vide', 1, TRUE);

-- Opening schedule so the branch is usable in the shell.
INSERT INTO merchant_branch_opening_schedules (id, branch_id, version, updated_by_account_id) VALUES
  ('0d00f0f0-fa00-7000-8000-000000004101', '0d00f0f0-fa00-7000-8000-000000002003', 1,
   '0d00f0f0-fa00-7000-8000-000000000105');

INSERT INTO merchant_branch_opening_intervals (id, schedule_id, day_of_week, opens_minute, closes_minute, closes_next_day, sort_order)
SELECT ('0d00f0f0-fa00-7000-8000-00000000420' || d)::uuid,
       '0d00f0f0-fa00-7000-8000-000000004101', d, 0, 0, TRUE, 0
FROM generate_series(1, 7) AS d;

COMMIT;
