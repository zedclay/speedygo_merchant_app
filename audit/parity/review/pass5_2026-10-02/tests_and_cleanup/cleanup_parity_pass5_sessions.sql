-- Removes the sessions and devices created by the fifth-pass live runs
-- (live3_*, live4_*, fx_* and the fixture-order customer logins), by explicit
-- ID only. Every session must already be revoked, each device must carry only
-- this pass's sessions and no push token. Orders created as tracked fixtures
-- are kept (financial records; see the matrix). audit_logs rows are kept.
\set ON_ERROR_STOP on
BEGIN;

DO $$
BEGIN
  IF current_database() <> 'speedygo_dev' THEN
    RAISE EXCEPTION 'refusing to clean outside speedygo_dev';
  END IF;
END $$;

CREATE TEMP TABLE p5_sessions (id uuid) ON COMMIT DROP;
INSERT INTO p5_sessions VALUES
  ('01a0f910-5616-76de-86be-9d3acbf7244a'),
  ('01a0f914-328c-77c2-b790-e419e27bf6f8'),
  ('01a0fd27-7b8b-7d4b-b1ba-93dd59c29651'),
  ('01a0fd2a-2ce3-7321-a99f-6416f5ff4169'),
  ('01a0fd2b-96f2-759b-96b1-d342ee191b89'),
  ('01a0fd31-5b86-768a-9e90-7bdfea134ea4'),
  ('01a0fd32-67d4-726b-a6a3-4bfa22b2d6fd'),
  ('01a0fd33-7d79-7a74-9caf-ef16e57b6470'),
  ('01a0fd37-f28b-794c-a643-afd532e78095'),
  ('01a0fd39-3901-7df1-a4af-d78789d2d5dc'),
  ('01a0fd60-8e1c-7bd9-92b7-8192d96f8ca9'),
  ('01a0fd63-3cb5-7664-b1ae-99348228be5e'),
  ('01a0fd64-7b38-7f4f-a20b-d238b9d8d5ff');

CREATE TEMP TABLE p5_devices (id uuid) ON COMMIT DROP;
INSERT INTO p5_devices VALUES
  ('01a0f910-5618-7984-bad8-849089d35ee0'),
  ('01a0f914-328d-71db-84ea-c6409a8ea9f6'),
  ('01a0fd27-7b8c-728a-81c6-abef44d291f4'),
  ('01a0fd2a-2ce3-71e6-ab46-e6122b5fffcb'),
  ('01a0fd2b-96f4-709f-86e4-834f90c4ebf4'),
  ('01a0fd31-5b87-7893-906d-93ddd4e38f0a'),
  ('01a0fd32-67d4-7953-971e-71c1acb34fea'),
  ('01a0fd33-7d7a-76b6-8fb9-a0554a4b76f5'),
  ('01a0fd37-f28c-7316-a0e6-a06a4220bb04'),
  ('01a0fd39-3902-76a2-9fa4-c212e4e46d5b'),
  ('01a0fd60-8e1e-7aa2-883b-64a76fe8408c'),
  ('01a0fd63-3cb5-7c6f-a111-7d5a8e63f68b'),
  ('01a0fd64-7b39-702f-a061-ca3b56ba83e2');

DO $$
BEGIN
  IF (SELECT count(*) FROM sessions WHERE id IN (SELECT id FROM p5_sessions)
        AND revoked_at IS NOT NULL
        AND account_id IN ('0d00c071-d000-7000-8000-000000000001',
                           '0d00c074-d000-7000-8000-000000000001')) <> 13 THEN
    RAISE EXCEPTION 'session shape differs from the pre-cleanup scan';
  END IF;
  IF (SELECT count(*) FROM devices WHERE id IN (SELECT id FROM p5_devices)) <> 13 THEN
    RAISE EXCEPTION 'device shape differs from the pre-cleanup scan';
  END IF;
  IF EXISTS (SELECT 1 FROM sessions WHERE device_id IN (SELECT id FROM p5_devices)
               AND id NOT IN (SELECT id FROM p5_sessions)) THEN
    RAISE EXCEPTION 'a device is shared with a session outside this pass';
  END IF;
  IF EXISTS (SELECT 1 FROM device_tokens WHERE device_id IN (SELECT id FROM p5_devices)) THEN
    RAISE EXCEPTION 'a device has push tokens';
  END IF;
END $$;

DELETE FROM sessions WHERE id IN (SELECT id FROM p5_sessions);
DELETE FROM devices WHERE id IN (SELECT id FROM p5_devices);

SELECT
  (SELECT count(*) FROM sessions WHERE id IN (SELECT id FROM p5_sessions)) AS run_sessions_left,
  (SELECT count(*) FROM devices WHERE id IN (SELECT id FROM p5_devices)) AS run_devices_left,
  (SELECT count(*) FROM sessions WHERE account_id = '0d00c071-d000-7000-8000-000000000001' AND revoked_at IS NULL) AS merchant_active,
  (SELECT count(*) FROM sessions WHERE account_id = '0d00c074-d000-7000-8000-000000000001' AND revoked_at IS NULL) AS customer_active,
  (SELECT count(*) FROM sessions) AS sessions_total;
COMMIT;
