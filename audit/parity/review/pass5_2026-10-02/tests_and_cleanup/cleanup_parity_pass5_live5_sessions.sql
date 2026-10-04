-- Removes the sessions and devices created by the fifth-pass follow-up
-- re-capture (live5_t100, live5_t135), by explicit ID only. Every session must already be revoked, each device must carry only
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
  ('01a0fd7b-cdde-77d2-afab-48f3e7babfcc'),
  ('01a0fd7e-8322-74e1-a6b0-f23d112817d4');

CREATE TEMP TABLE p5_devices (id uuid) ON COMMIT DROP;
INSERT INTO p5_devices VALUES
  ('01a0fd7b-cddf-7917-ba1d-ecdfe301c2d8'),
  ('01a0fd7e-8323-7efa-ae00-fa0aa0ac1cdd');

DO $$
BEGIN
  IF (SELECT count(*) FROM sessions WHERE id IN (SELECT id FROM p5_sessions)
        AND revoked_at IS NOT NULL
        AND account_id IN ('0d00c071-d000-7000-8000-000000000001',
                           '0d00c074-d000-7000-8000-000000000001')) <> 2 THEN
    RAISE EXCEPTION 'session shape differs from the pre-cleanup scan';
  END IF;
  IF (SELECT count(*) FROM devices WHERE id IN (SELECT id FROM p5_devices)) <> 2 THEN
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
