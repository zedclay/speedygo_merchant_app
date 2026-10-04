# Proposed provisioning — merchants.verify (**APPLIED** 2026-09-18)

**Status:** authorized and applied to `speedygo_dev` via  
`apps/backend/scripts/dev-merchant-lifecycle-acceptance/` (manual apply script only; not Nest startup).

Canonical copy of the seed lives under that scripts folder. This file remains the review record.

## Why this is required

Read-only diagnosis (2026-09-18):

| Check | Result |
| --- | --- |
| `permissions` row `merchants.verify` | **0 rows** (code absent) |
| Any `role_permissions` → `merchants.verify` | **none** |
| Existing Admin effective codes | delivery.*, drivers.*, commerce.*, promotions.* only |
| Reject on fixture | **403 AUTH_FORBIDDEN** for every Admin probed |

Cause is **absent permission + unassigned**, not a stale JWT/cache and not the wrong Admin among existing identities. No authorized development Admin currently holds `merchants.verify`.

Canonical code: `ADMIN_PERMISSIONS.MERCHANTS_VERIFY` = `'merchants.verify'` in  
`apps/backend/src/modules/admin/domain/admin-permissions.ts`.  
Guard: `@RequirePermissions(ADMIN_PERMISSIONS.MERCHANTS_VERIFY)` on  
`POST /api/v1/admin/merchants/:id/verification/{approve|reject}`.

Supported pattern (existing): `apps/backend/scripts/dev-cod-lifecycle-driver/seed-admin.sql`  
(idempotent `ON CONFLICT`, `speedygo_dev` gate, synthetic `+21355000009x` phone).

## Minimal grant (one capability)

| Item | Value |
| --- | --- |
| Permission | `merchants.verify` (required for reject/approve) |
| Companion read | `merchants.read` (queue/detail; same role as e2e verify admins) |
| Role | new synthetic `speedygo-dev-merchant-lifecycle-acceptance` |
| Account phone | `+213550000099` / local `0550000099` (unused in current DB) |
| Display name | `SpeedyGo Dev Merchant Lifecycle Acceptance Admin` |
| Mechanism | SQL seed file (below), applied only with `psql` against `speedygo_dev` after approval |

Not requested: `merchants.suspend`, finance, promotions, drivers.*, schema/guard edits.

## Contract note for acceptance after grant

`AdminMerchantCommandsService.rejectVerification` and the Admin OpenAPI text state:  
**v1.0 does not accept or persist a rejection reason.**  
Merchant correction UI is status-driven (`REJECTED` → correct → resubmit).  
“Verify reason text” is **NOT RUN / N/A** under the frozen contract — not a Merchant app defect.

## Authorization to apply

Apply only if you explicitly approve:

1. Create `apps/backend/scripts/dev-merchant-lifecycle-acceptance/seed-admin.sql` (content below), **or** run the same SQL from this audit folder once.
2. `psql` to `127.0.0.1:5433/speedygo_dev` as the usual local role.
3. Resume acceptance: Admin API reject (API-only) → Merchant UI correct/resubmit → Admin API approve → relaunch.

Until then overall acceptance stays **PARTIAL / BLOCKED**.

## Seed SQL (review copy — not executed)

```sql
-- SYNTHETIC ONLY. Target: 127.0.0.1:5433 / speedygo_dev.
-- Idempotent ON CONFLICT. Does not UPDATE/DELETE unrelated rows.
-- Grants merchants.read + merchants.verify only.

DO $$
BEGIN
  IF current_database() <> 'speedygo_dev' THEN
    RAISE EXCEPTION
      'Refused merchant lifecycle acceptance seed: expected speedygo_dev, got %',
      current_database();
  END IF;
END
$$;

INSERT INTO accounts (id, phone, email, status)
VALUES (
  '0d00c074-d000-7000-8000-000000000001',
  '+213550000099',
  NULL,
  'ACTIVE'
)
ON CONFLICT (id) DO UPDATE
SET phone = EXCLUDED.phone
WHERE accounts.phone IS DISTINCT FROM EXCLUDED.phone;

INSERT INTO roles (id, name, description, active)
VALUES (
  '0d00c074-d000-7000-8000-000000000002',
  'speedygo-dev-merchant-lifecycle-acceptance',
  'Synthetic role: merchant verification reject/approve for acceptance only',
  TRUE
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO permissions (id, code, description)
VALUES
  (
    '0d00c074-d000-7000-8000-000000000011',
    'merchants.read',
    'Synthetic fixture: read merchants / verification queue'
  ),
  (
    '0d00c074-d000-7000-8000-000000000012',
    'merchants.verify',
    'Synthetic fixture: approve/reject merchant verification'
  )
ON CONFLICT (code) DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT
  '0d00c074-d000-7000-8000-000000000002',
  p.id
FROM permissions p
WHERE p.code IN ('merchants.read', 'merchants.verify')
ON CONFLICT (role_id, permission_id) DO NOTHING;

INSERT INTO admin_profiles (
  id,
  account_id,
  role_id,
  display_name,
  two_factor_enabled
)
VALUES (
  '0d00c074-d000-7000-8000-000000000003',
  '0d00c074-d000-7000-8000-000000000001',
  '0d00c074-d000-7000-8000-000000000002',
  'SpeedyGo Dev Merchant Lifecycle Acceptance Admin',
  FALSE
)
ON CONFLICT (id) DO NOTHING;
```
