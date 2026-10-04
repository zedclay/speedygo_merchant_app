-- Removes the three Batch 7 live fixtures created by the parity run of
-- 2026-09-30 (phones +213550000093 partial, +213550000095, +213550000096),
-- by explicit ID only. Aborts unless the row counts match the pre-cleanup
-- reference scan (scan_refs_before_cleanup.txt). audit_logs (admin reject
-- records) and the two revoked admin sessions are left in place.
\set ON_ERROR_STOP on
BEGIN;

DO $$
BEGIN
  IF current_database() <> 'speedygo_dev' THEN
    RAISE EXCEPTION 'refusing to clean outside speedygo_dev';
  END IF;
END $$;

CREATE TEMP TABLE b7_accounts (id uuid) ON COMMIT DROP;
INSERT INTO b7_accounts VALUES
  ('01a0f32c-f802-7763-94da-38eb3ba6dcf9'),
  ('01a0f330-415c-7f34-a95e-7e94e634c6f1'),
  ('01a0f33d-0da4-7069-934a-dfcc38c43152');

CREATE TEMP TABLE b7_merchants (id uuid) ON COMMIT DROP;
INSERT INTO b7_merchants VALUES
  ('01a0f32d-2685-7149-bf31-8276284a4bac'),
  ('01a0f330-6fa9-76c4-a954-d2a26f7a7137'),
  ('01a0f33d-3bc5-7162-8fd4-9b3132a18684');

CREATE TEMP TABLE b7_branches (id uuid) ON COMMIT DROP;
INSERT INTO b7_branches VALUES
  ('01a0f331-4d6d-76d6-b0c3-b9077a32f7c2'),
  ('01a0f33d-deec-72c9-9167-2eed28f45499');

DO $$
DECLARE
  n_acc int; n_mer int; n_br int; n_doc int; n_mem int; n_dev int; n_ses int;
BEGIN
  SELECT count(*) INTO n_acc FROM accounts a
    WHERE a.id IN (SELECT id FROM b7_accounts)
      AND a.phone IN ('+213550000093', '+213550000095', '+213550000096');
  SELECT count(*) INTO n_mer FROM merchants WHERE id IN (SELECT id FROM b7_merchants);
  SELECT count(*) INTO n_br FROM merchant_branches
    WHERE id IN (SELECT id FROM b7_branches) AND merchant_id IN (SELECT id FROM b7_merchants);
  SELECT count(*) INTO n_doc FROM merchant_documents WHERE merchant_id IN (SELECT id FROM b7_merchants);
  SELECT count(*) INTO n_mem FROM merchant_members
    WHERE merchant_id IN (SELECT id FROM b7_merchants) AND account_id IN (SELECT id FROM b7_accounts);
  SELECT count(*) INTO n_dev FROM devices WHERE account_id IN (SELECT id FROM b7_accounts);
  SELECT count(*) INTO n_ses FROM sessions WHERE account_id IN (SELECT id FROM b7_accounts);
  IF (n_acc, n_mer, n_br, n_doc, n_mem, n_dev, n_ses) <> (3, 3, 2, 6, 3, 5, 5) THEN
    RAISE EXCEPTION 'unexpected fixture shape acc=% mer=% br=% doc=% mem=% dev=% ses=%',
      n_acc, n_mer, n_br, n_doc, n_mem, n_dev, n_ses;
  END IF;
  IF EXISTS (SELECT 1 FROM sessions WHERE account_id IN (SELECT id FROM b7_accounts) AND revoked_at IS NULL) THEN
    RAISE EXCEPTION 'a fixture session is still active';
  END IF;
  IF EXISTS (SELECT 1 FROM merchant_members
             WHERE merchant_id IN (SELECT id FROM b7_merchants)
               AND account_id NOT IN (SELECT id FROM b7_accounts)) THEN
    RAISE EXCEPTION 'a fixture merchant has a non-fixture member';
  END IF;
END $$;

DELETE FROM merchant_documents WHERE merchant_id IN (SELECT id FROM b7_merchants);
DELETE FROM merchant_branches WHERE id IN (SELECT id FROM b7_branches);
DELETE FROM merchant_members WHERE merchant_id IN (SELECT id FROM b7_merchants);
DELETE FROM merchants WHERE id IN (SELECT id FROM b7_merchants);
DELETE FROM sessions WHERE account_id IN (SELECT id FROM b7_accounts);
DELETE FROM devices WHERE account_id IN (SELECT id FROM b7_accounts);
DELETE FROM accounts WHERE id IN (SELECT id FROM b7_accounts);

SELECT
  (SELECT count(*) FROM accounts WHERE phone IN ('+213550000093', '+213550000095', '+213550000096')) AS accounts_left,
  (SELECT count(*) FROM merchants WHERE id IN (SELECT id FROM b7_merchants)) AS merchants_left,
  (SELECT status FROM merchants WHERE id = '0d00c071-d000-7000-8000-000000010001') AS dar_el_bahja_status,
  (SELECT count(*) FROM merchants WHERE id::text LIKE '01a0b9ad%') AS finjan_present;

COMMIT;
