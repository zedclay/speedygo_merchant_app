# Merchant Catalogue infinite loading — implementer review

Status: **implementer_reviewed**

Date: 2026-10-03

## Environment

| Check | Result |
| --- | --- |
| Free disk (resume) | ~1.4 Gi free (no prune) |
| Docker | up; postgres/redis/minio/clamav |
| PostgreSQL 5433 | healthy, `speedygo_dev` accepting |
| Redis 6381 | PING → PONG |
| `GET http://127.0.0.1:3000/health` | Initially down on resume; restarted with existing `dist/src/main` + current `.env` (unchanged). Then HTTP 200. |
| Volumes / Keychain / sessions | preserved; no reset, prune, migration, commit, or push |

## Backend / API

Catalogue requests used by the Merchant app (`http://127.0.0.1:3000/api/v1`):

- `GET /merchant/:merchantId/catalog?branchId=`
- `GET /merchant/:merchantId/categories?branchId=`
- `GET /merchant/:merchantId/products?branchId=&limit=&offset=`

Isolated fixture probe (TEST FIXTURE — Lifecycle Acceptance Shop / Branch Alger corrected):

| Request | Status | Time | Code | Outcome |
| --- | --- | --- | --- | --- |
| Unauthenticated catalog | 401 | ~1 ms | `AUTH_INVALID_TOKEN` | finished |
| Fixture OTP request/verify | 200 | tens | — | token issued |
| Authenticated catalog / categories / products | 404 | 2–3 ms | `MERCHANT_NOT_FOUND` | finished (session had no membership on `/merchant/me`) |

Live iPhone 16e session is **Finjan Coffer**. After backend restart, Nest logs show schema drift against `speedygo_dev` (no migration applied, per instruction):

- `column products.duplicate_request_key does not exist` on Catalogue load
- (other screens also log missing `merchant_branch_hours_exceptions`)

So the live Catalogue API fails fast with a server error. That must surface as **Réessayer**, not **Chargement…**.

## Flutter state bug

Yes. Fixed.

1. **Riverpod 3 default retry** on `catalogControllerProvider` re-entered loading after every failure → infinite **Chargement…**. Disabled with `retry: _noAutomaticRetry` (same pattern as reports/support).
2. **`build()` watched the whole `AccessState`**, so access pulses restarted loads; `reload()` forced bare `AsyncLoading`; `when()` had no `skipLoadingOnReload`.

Also: 25s load timeout, missing merchant/branch → error (not fake empty), auth → `invalidateLocalSession`, product page cap, retry is the only reload path. No mocked products in production UI.

## Live device (iPhone 16e)

1. Fully quit prior `flutter run`, relaunched on `8DB9007A-B816-4EC5-86ED-C627AC60F2C5`.
2. Opened **Catalogue** from the floating dock.
3. Result: **Impossible de charger le catalogue.** + **Réessayer** (not Chargement).
4. Tapped **Réessayer**: request re-ran; still honest error (backend schema mismatch), still not Chargement.

Evidence:

- `audit/parity/catalog_loading/live_catalog_open.png`
- `audit/parity/catalog_loading/live_catalog_after_retry.png`
- Mocked recovery captures: `mocked/catalog_recovery_t1.00.png`, `mocked/catalog_recovery_t1.35.png`

## Files changed

| Path | Change |
| --- | --- |
| `lib/features/catalog/application/catalog_controller.dart` | identity watches, no auto-retry, timeout, honest errors, session invalidation |
| `lib/features/catalog/presentation/catalog_screen.dart` | `skipLoadingOnReload` / `skipLoadingOnRefresh` |
| `lib/features/catalog/presentation/catalog_sub_screens.dart` | same |
| `lib/features/access/data/merchant_api.dart` | product page cap |
| `test/features/catalog_loading_test.dart` | regression cases |
| `test/audit/parity/catalog_loading_capture_test.dart` | recovery captures 1.0 / 1.35 |

## Tests

| Suite | Result |
| --- | --- |
| `test/features/catalog_loading_test.dart` | PASS (populated, empty, timeout, offline, 500, auth, retry, leave/reopen, dispose, access pulse) |
| `test/audit/parity/catalog_loading_capture_test.dart` | PASS |
| `test/features/phase5_catalog_reports_test.dart` | PASS |
| Other Bottom Navigation work | NOT RUN (stopped until Catalogue is honest) |

## Summary for review

| Area | Verdict |
| --- | --- |
| Environment | Docker/PG/Redis OK; port 3000 was restarted once with existing dist after it was down |
| Backend/API | Routes live; Finjan Catalogue currently fails due to dist↔`speedygo_dev` schema drift (`duplicate_request_key`); no migration applied |
| Flutter bug | Fixed — permanent loading removed; failures show Réessayer; retry re-runs |
| Bottom Nav continuation | Blocked until Catalogue path is accepted |
