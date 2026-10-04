# Finjan development-test approval

**Not** real document validation. Development testing only.

| Field | Value |
| --- | --- |
| Environment | `speedygo_dev` (`DATABASE_URL` …/speedygo_dev) |
| Account phone | `+213549445167` / local `0549445167` |
| Merchant ID | `01a0ad2a-29eb-7959-b23c-d21f1e1c0915` |
| Name | Finjan |
| Membership | OWNER |
| Before | `PENDING_REVIEW`, `approved=false`, `verifiedAt=null` |
| After | `ACTIVE`, `approved=true`, `verifiedAt=2026-09-18 18:58:34.7+00` |
| API | `POST /api/v1/admin/merchants/:id/verification/approve` → **201** |
| Admin | `+213550000099` with `merchants.verify` |
| UI | Existing 17 Pro session refreshed in place → **Accueil** / Finjan ACTIVE |
| Documents | Unchanged (no upload/replace/delete) |
| Store hours / catalog / orders | Not touched |
