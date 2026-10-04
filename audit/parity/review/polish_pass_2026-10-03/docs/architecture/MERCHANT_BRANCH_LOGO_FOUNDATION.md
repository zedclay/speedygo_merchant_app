# Merchant Branch Logo Foundation v1.0

Status: **implemented 2026-10-02, `implementer_reviewed`** (not FINAL FREEZE, not visually accepted). Migration `migrations/app/20261002T1907_merchant_contract_completion_batch`. Extends the storefront cover mechanism of the commerce verticals and covers foundation; it does not add a second upload system.

## Scope

In:

- One optional logo per MerchantBranch (`MerchantBranchLogo`, table `merchant_branch_logos`)
- Merchant upload → bind/replace → stream → delete under `/api/v1/merchant/:merchantId/branches/:branchId/logo`
- Merchant app: Logo et Couverture screen, store profile header and the customer preview card on that screen

Out:

- Customer projections and Customer UI (no Customer route or field is added)
- Admin logo moderation
- Image transformation (crop, resize, recompression) on the server

## Ownership scope

The logo belongs to the **Branch**, like the cover. The Merchant app edits the store name, address, cover and hours per Branch, and the Customer storefront is a Branch. A Merchant with several Branches can use different logos.

## Storage and validation

| Rule | Value |
| --- | --- |
| Purpose (pending registry) | `MERCHANT_BRANCH_LOGO` |
| Namespace | `logos/<32-hex object id>` (locator `sg-logo:v1:<id>`) |
| Content types | `image/jpeg`, `image/png` (magic bytes; declared MIME must match) |
| Size | ≤ 1 MiB (multipart limit) |
| Dimensions | 128–2048 px on each side |
| Malware scan | Same scanner and `STORAGE_MALWARE_SCAN_REQUIRED` rule as covers (shared `CoverMediaStorageService` pipeline) |

The pipeline is the cover pipeline with the logo policy: bytes go to `pending/`, an opaque `uploadReference` is returned, and PUT promotes the pending object to a new `logos/` object and binds it.

## Endpoints

| Method | Path | Capability | Success |
| --- | --- | --- | --- |
| POST | `…/branches/:branchId/logo/content` (multipart `file`) | `MERCHANT_BRANCH_UPDATE` (OWNER, MANAGER) | `200` pending upload with `uploadReference` |
| PUT | `…/branches/:branchId/logo` `{ uploadReference }` | `MERCHANT_BRANCH_UPDATE` | `200` `{ branchId, logoImageUrl, logoVersion, contentType, widthPx, heightPx }` |
| GET | `…/branches/:branchId/logo` | `MERCHANT_READ` (all roles, including STAFF) | `200` bytes |
| DELETE | `…/branches/:branchId/logo` | `MERCHANT_BRANCH_UPDATE` | `200` `{ deleted: true }`, also when no logo exists (idempotent) |

- `logoImageUrl` is the Merchant path `/merchant/:merchantId/branches/:branchId/logo`; `logoVersion` is the object id, which changes on every replacement.
- GET streams the bound bytes with `Cache-Control: private, no-cache`, `ETag: "<objectId>"` and `X-Content-Type-Options: nosniff`.

## Errors

| Situation | Response |
| --- | --- |
| No logo bound (GET) | `404 STORAGE_OBJECT_MISSING` (the Merchant app shows its fallback) |
| GIF or other unsupported type; side below 128 px or above 2048 px | `400 STORAGE_UNSUPPORTED_TYPE` |
| File over 1 MiB | `413` with the generic `HTTP_ERROR` code (multipart limit, same behaviour as covers and documents) |
| Upload reference already consumed, owned by another Account/Branch, or issued for another purpose (cover, product image) | `404 STORAGE_UPLOAD_REFERENCE_FOREIGN` |
| Foreign Branch | `404 MERCHANT_BRANCH_NOT_FOUND` |
| Foreign Merchant | `404 MERCHANT_NOT_FOUND` |
| STAFF upload / bind / delete | `403 MERCHANT_ROLE_FORBIDDEN` |

## Replacement and deletion safety

- Every bind writes a **new** object id, so a replaced logo can never be served from the old key.
- After the row update, the previous object is deleted only if no `merchant_branch_logos` row still references it.
- If the database write fails after promotion, the newly promoted object is deleted (no orphan object).
- DELETE removes the row, then the object if unreferenced. Covers, product images and verification documents use other namespaces and are never touched.

## Merchant UI

- Logo et Couverture: logo circle with Modifier / Supprimer (OWNER, MANAGER), read-only for STAFF; the existing cover card; the customer preview card shows the real logo.
- Store profile header shows the logo when bound, and the existing storefront placeholder otherwise.
- A save is confirmed only after PUT 200. Partial failure (uploaded but not bound) is reported, never shown as saved.
- At text scale ≥ 1.25 the Modifier / Supprimer buttons stack.

## Verification (2026-10-02)

- Backend e2e on the isolated fixture API: checks L01–L17 PASS (`apps/merchant_app/audit/parity/isolated/evidence/fxenv_20261002T193016Z/contract_e2e/contract_e2e_results.json`).
- Merchant live on the isolated API at text 1.0 and 1.35: empty → save A → profile header → fresh app instance → replace with B (server and displayed bytes equal B byte-for-byte) → remove → fallback; MANAGER controls; STAFF read-only. Report: `apps/merchant_app/audit/parity/contract_batch/CONTRACT_COMPLETION_BATCH_REPORT.md`.
