-- Removes the rows created by the third-pass live run of 2026-10-01, by
-- explicit ID only: the two approval fixtures (+213550000097 pending path,
-- +213550000098 rejected path), plus the sessions and devices the run created
-- for Dar El Bahja (two memory-only capture sessions) and the dev admin (three
-- approve/reject calls). Aborts unless the row shape matches the pre-cleanup
-- scan (.run/scan_refs_live2_*.txt) and every session is already revoked.
-- audit_logs rows are kept (audit records, no foreign key), as before.
\set ON_ERROR_STOP on
BEGIN;

DO $$
BEGIN
  IF current_database() <> 'speedygo_dev' THEN
    RAISE EXCEPTION 'refusing to clean outside speedygo_dev';
  END IF;
END $$;

CREATE TEMP TABLE l2_accounts (id uuid) ON COMMIT DROP;
INSERT INTO l2_accounts VALUES
  ('01a0f76f-bdf6-73e5-92f7-31d59970cb48'),
  ('01a0f773-d531-72eb-94ec-c3ff00315cb2');

CREATE TEMP TABLE l2_merchants (id uuid) ON COMMIT DROP;
INSERT INTO l2_merchants VALUES
  ('01a0f76f-da4c-74d6-b799-45a0b53e037c'),
  ('01a0f773-f164-71ac-83a9-d4597b7e857f');

CREATE TEMP TABLE l2_branches (id uuid) ON COMMIT DROP;
INSERT INTO l2_branches VALUES
  ('01a0f770-6bc1-7186-8712-aa0cb253ae4c'),
  ('01a0f774-82c3-7ab4-9997-2cfec437d73b');

CREATE TEMP TABLE l2_run_sessions (id uuid) ON COMMIT DROP;
INSERT INTO l2_run_sessions VALUES
  ('01a0f766-67a0-7e5e-8df1-5d74ac3bf30f'),
  ('01a0f76a-2a1b-7b32-8c48-6a91dc5c7575'),
  ('01a0f771-9570-7770-aa17-f6af88464a51'),
  ('01a0f774-9669-732c-a7c7-57240b1bada5'),
  ('01a0f775-c7f8-743e-ac85-891e189fb1f4');

CREATE TEMP TABLE l2_run_devices (id uuid) ON COMMIT DROP;
INSERT INTO l2_run_devices VALUES
  ('01a0f766-67a2-7479-9ff6-c9cd341faab3'),
  ('01a0f76a-2a1d-7c66-b6a2-1f0be25da888'),
  ('01a0f771-9570-7f68-a50d-22746d748224'),
  ('01a0f774-9669-7d1d-83ff-74a24b9dd25d'),
  ('01a0f775-c7f8-797f-8594-59765e1500cb');

DO $$
DECLARE
  n_acc int; n_mer int; n_br int; n_doc int; n_mem int; n_dev int; n_ses int;
  n_rses int; n_rdev int; n_tok int;
BEGIN
  SELECT count(*) INTO n_acc FROM accounts
    WHERE id IN (SELECT id FROM l2_accounts)
      AND phone IN ('+213550000097', '+213550000098');
  SELECT count(*) INTO n_mer FROM merchants WHERE id IN (SELECT id FROM l2_merchants);
  SELECT count(*) INTO n_br FROM merchant_branches
    WHERE id IN (SELECT id FROM l2_branches) AND merchant_id IN (SELECT id FROM l2_merchants);
  SELECT count(*) INTO n_doc FROM merchant_documents WHERE merchant_id IN (SELECT id FROM l2_merchants);
  SELECT count(*) INTO n_mem FROM merchant_members
    WHERE merchant_id IN (SELECT id FROM l2_merchants) AND account_id IN (SELECT id FROM l2_accounts);
  SELECT count(*) INTO n_dev FROM devices WHERE account_id IN (SELECT id FROM l2_accounts);
  SELECT count(*) INTO n_ses FROM sessions WHERE account_id IN (SELECT id FROM l2_accounts);
  SELECT count(*) INTO n_rses FROM sessions
    WHERE id IN (SELECT id FROM l2_run_sessions)
      AND account_id IN ('0d00c071-d000-7000-8000-000000000001', '0d00c074-d000-7000-8000-000000000001');
  SELECT count(*) INTO n_rdev FROM devices
    WHERE id IN (SELECT id FROM l2_run_devices)
      AND account_id IN ('0d00c071-d000-7000-8000-000000000001', '0d00c074-d000-7000-8000-000000000001');
  SELECT count(*) INTO n_tok FROM device_tokens
    WHERE device_id IN (SELECT id FROM l2_run_devices)
       OR device_id IN (SELECT id FROM devices WHERE account_id IN (SELECT id FROM l2_accounts));
  IF (n_acc, n_mer, n_br, n_doc, n_mem, n_dev, n_ses, n_rses, n_rdev, n_tok)
     <> (2, 2, 2, 4, 2, 4, 4, 5, 5, 0) THEN
    RAISE EXCEPTION 'unexpected shape acc=% mer=% br=% doc=% mem=% dev=% ses=% rses=% rdev=% tok=%',
      n_acc, n_mer, n_br, n_doc, n_mem, n_dev, n_ses, n_rses, n_rdev, n_tok;
  END IF;
  IF EXISTS (SELECT 1 FROM sessions
             WHERE (account_id IN (SELECT id FROM l2_accounts) OR id IN (SELECT id FROM l2_run_sessions))
               AND revoked_at IS NULL) THEN
    RAISE EXCEPTION 'a session created by this run is still active';
  END IF;
  IF EXISTS (SELECT 1 FROM sessions
             WHERE device_id IN (SELECT id FROM l2_run_devices)
               AND id NOT IN (SELECT id FROM l2_run_sessions)) THEN
    RAISE EXCEPTION 'a run device is used by a session outside this run';
  END IF;
  IF EXISTS (SELECT 1 FROM merchant_members
             WHERE merchant_id IN (SELECT id FROM l2_merchants)
               AND account_id NOT IN (SELECT id FROM l2_accounts)) THEN
    RAISE EXCEPTION 'a fixture merchant has a non-fixture member';
  END IF;
END $$;

DELETE FROM merchant_documents WHERE merchant_id IN (SELECT id FROM l2_merchants);
DELETE FROM merchant_branches WHERE id IN (SELECT id FROM l2_branches);
DELETE FROM merchant_members WHERE merchant_id IN (SELECT id FROM l2_merchants);
DELETE FROM merchants WHERE id IN (SELECT id FROM l2_merchants);
DELETE FROM sessions WHERE account_id IN (SELECT id FROM l2_accounts);
DELETE FROM devices WHERE account_id IN (SELECT id FROM l2_accounts);
DELETE FROM accounts WHERE id IN (SELECT id FROM l2_accounts);
DELETE FROM sessions WHERE id IN (SELECT id FROM l2_run_sessions);
DELETE FROM devices WHERE id IN (SELECT id FROM l2_run_devices);

SELECT
  (SELECT count(*) FROM accounts WHERE phone IN ('+213550000097', '+213550000098')) AS accounts_left,
  (SELECT count(*) FROM merchants WHERE id IN (SELECT id FROM l2_merchants)) AS merchants_left,
  (SELECT count(*) FROM sessions WHERE id IN (SELECT id FROM l2_run_sessions)) AS run_sessions_left,
  (SELECT status FROM merchants WHERE id = '0d00c071-d000-7000-8000-000000010001') AS dar_el_bahja_status,
  (SELECT count(*) FROM merchants WHERE id::text LIKE '01a0b9ad%') AS finjan_present;

COMMIT;
