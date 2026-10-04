# Merchant contract-completion batch — report (2026-10-02)

**Status: `implementer_reviewed`, pending user visual acceptance.** No screen is user-accepted. No commit, push, deployment or external-service activation. This closeout was documentation-only: no live test was rerun, the shared dev API (port 3000, stopped by the user) was not restarted, and no source or migration file changed (section 8).

The batch adds three backend contracts and their Merchant screens:

| Contract | Decision | Matrix rows | Result |
| --- | --- | --- | --- |
| Store logo (Branch-owned, authenticated Merchant media) | D-D3 | 52 → done; 46 logo tile | Implemented; e2e and live PASS |
| Exceptional opening hours (per `Africa/Algiers` date, optimistic concurrency) | D-D4 | 57 → partial by decision; 56 entry row | Implemented; e2e and live PASS |
| Atomic product duplication (one transaction, idempotent `requestId`, copy unavailable) | D-C2 | 38 → done; 28 "Dupliquer" | Implemented; e2e and live PASS; product-image copy verified by e2e only |

Paths are relative to `apps/merchant_app/` unless they start with `apps/`, `docs/` (workspace root) or `/`.

## 1. PASS / FAIL / NOT RUN

| # | Check | Result | Evidence |
| --- | --- | --- | --- |
| 1 | Backend unit tests, full (`jest`, unit config) | **PASS** 131 suites, 1088/1088 | `audit/parity/contract_batch/test_logs/backend_unit_full.log` |
| 2 | Backend unit specs of the batch (logo service, exception service and evaluator, duplication service, catalog-write DTO, error filter, cover-media storage) | **PASS** 7 suites, 66/66 | `test_logs/backend_unit_batch_specs_verbose.log` |
| 3 | Backend contract e2e on the isolated fixture API (`fx_contract_e2e.py`; logo L01–L17, hours H01–H23, duplication D01–D15) | **PASS** 55/55 | `audit/parity/isolated/evidence/fxenv_20261002T193016Z/contract_e2e/contract_e2e_results.json`, `hours_states.json` |
| 4 | Migration applied to a fresh database (`prisma db migrate`) and verified (`prisma db verify`) in every isolated run | **PASS** | `…/fxenv_20261002T211645Z/migrate.log`, `verify.log` (same in every run folder) |
| 5 | Isolation guard tests (`fx_guard_test.sh`) | **PASS** 83/83 | `test_logs/fx_guard_test.log` |
| 6 | Flutter focused batch tests (`test/features/contract_completion_batch_test.dart`) | **PASS** 25/25 | `test_logs/flutter_contract_completion_batch_test.log` |
| 7 | `flutter analyze`: no errors | **PASS** 0 errors | `test_logs/flutter_analyze.log` |
| 8 | `flutter analyze`: no issues at all | **FAIL** (exit 1): 1 pre-existing warning (`test/features/order_list_visual_corrections_test.dart:66`, unused parameter) and 66 infos, 4 of them in batch files (`lib/app/theme/app_theme.dart:90`, `lib/features/shell/store_profile_screen.dart:89`, `lib/features/store/presentation/store_cover_screen.dart:1`, `test/features/contract_completion_batch_test.dart:51`). Not fixed in this documentation-only pass | same |
| 9 | Live, isolated environment, iPhone 16e, text 1.0 (`large`) | **PASS** 30/30 recorded checks, 27 screenshots, test "All tests passed!" | `audit/parity/isolated/evidence/fxenv_20261002T211645Z/` |
| 10 | Live, isolated environment, iPhone 16e, text 1.35 (`extra-extra-extra-large`) | **PASS** 30/30 recorded checks, 27 screenshots | `audit/parity/isolated/evidence/fxenv_20261002T211050Z/` |
| 11 | Isolation after each final run (11 checks: `speedygo_dev` counts, tracked orders, late order, branch names, Redis 0/15/9, database dropped) | **PASS** 11/11 each | `…/fxenv_20261002T211645Z/cleanup.log`, `isolation_comparison.json`; same in `…T211050Z/` |
| 12 | Mocked captures of the batch (`b8_logo_cover`, `b8_hours_exceptions`, `b8_duplicate`) | **PASS** (images reviewed). Written 20:50:48–50 CET, after the last screen change (20:50:36) | `audit/parity/comparisons/b8_*.png`, `audit/parity/mocked/b8_*` |
| 13 | Batch-8 capture test re-run in this closeout | **NOT RUN** (it rewrites the mocked PNGs). An earlier 6/6 result is in session notes only; no log was retained | — |
| 14 | Full Flutter suite re-run in this closeout | **NOT RUN** (it regenerates every mocked PNG). An earlier "556 passed, 1 skipped" is in session notes only; no log was retained, so it is not counted as evidence | — |
| 15 | Backend jest e2e harness (`test/*.e2e-spec.ts`) | **NOT RUN** by rule: it forces `speedygo_test` and flushes Redis DB 15 | — |
| 16 | Live product-image copy | **NOT RUN live**: the fixture products have no image. Verified by backend e2e D03 (distinct object, same bytes), D13–D15 (media safety) | e2e results above |
| 17 | Live midnight crossing for exceptions | **NOT RUN live**. Covered by e2e H14/H15 and the evaluator unit specs | e2e results, row 2 log |
| 18 | Customer app display of exceptions or logo | **NOT RUN** (out of scope: no Customer field exists) | — |
| 19 | Migration applied to `speedygo_dev` | **NOT RUN** (by design: `speedygo_dev` was kept unchanged) | — |
| 20 | User visual acceptance | **NOT RUN**: no screen is user-accepted | — |

### Live checks (identical values at both text sizes)

| Recorded key | Expected | 1.0 | 1.35 |
| --- | --- | --- | --- |
| `logoInitiallyEmpty` | true | true | true |
| `logoSavedMatchesA` | true | true | true |
| `logoAfterFreshInstance` | fixture A (`13659:5260b817`, bytes:hash) | A | A |
| `logoReplacedMatchesB` / `logoReplacedDiffersFromA` / `logoDisplayedIsB` | true / true / true | all true | all true |
| `logoAfterRemove` | none | none | none |
| `serverToday` | Africa/Algiers date | 2026-10-02 | 2026-10-02 |
| `exceptionAfterFreshInstance` | saved date read back | 2026-10-05 | 2026-10-05 |
| `conflictKeptDraft` / `retryAfterConflictSaved` | true / true | true / true | true / true |
| `todayClosedIsOpenNow` / `todayClosedAccepting` | false / false | false / false | false / false |
| `weeklyFallbackIsOpenNow` | true | true | true |
| `ownerCopyAvailable` / `managerCopyAvailable` | false / false (copy starts unavailable) | false / false | false / false |
| `ownerCopyName` | "Copie de Couscous royal" | match | match |
| `ownerCopyHasImage` | false (fixture has no image) | false | false |
| `ownerCopiesAfterDoubleTap` | 1 | 1 | 1 |
| `sourceUnchanged` | true | true | true |
| `managerLogoControls` / `managerExceptionEditor` | true / true | true / true | true / true |
| `staffLogoReadOnly` / `staffExceptionsReadOnly` / `staffNoProductMenu` / `staffDuplicateRefused` | all true | all true | all true |
| `logout_OWNER` / `logout_MANAGER` / `logout_STAFF` (sessions revoked by the app) | all true | all true | all true |

`ownerCopyId` differs per run (a new copy each time): `01a0fe7d-b560-783e-8a32-a74452a1d1e0` (1.0), `01a0fe78-38f0-7ad0-90e9-3c894c1dd9ec` (1.35).

**Passed live at both text sizes:** STAFF restrictions; conflict draft preservation; byte-for-byte logo replacement and removal; exceptional-hours evaluation (closed today, then weekly fallback); double-tap protection; duplicate starts unavailable; original product unchanged.

**Both final runs used the same final test file** (`integration_test/contract_batch_fx_live_test.dart`, last modified 21:10:27 UTC; runs started 21:10:50 UTC (1.35) and 21:16:45 UTC (1.0)). Bundle `com.speedygo.speedygoMerchantApp` and the content size were confirmed before the first capture (`BUNDLE_fxc_t100.txt`, `BUNDLE_fxc_t135.txt`). One memory-only OTP session per role; the Keychain was not read or written.

## 2. Evidence inventory (authoritative)

| Kind | Path |
| --- | --- |
| Backend e2e results | `audit/parity/isolated/evidence/fxenv_20261002T193016Z/contract_e2e/contract_e2e_results.json`, `…/hours_states.json`, `…/cleanup.log` |
| Live 1.0 run | `audit/parity/isolated/evidence/fxenv_20261002T211645Z/` — `PROVENANCE_fxc_t100.json`, `BUNDLE_fxc_t100.txt`, `flutter_fxc_t100.log`, `shots_fxc_t100.log`, `screens/fxc_t100_*.png` (27), `isolation_before.json`, `isolation_after_fxc_t100.json`, `isolation_pre_cleanup.json`, `isolation_after_cleanup.json`, `isolation_comparison.json`, `dev_redis_job_scan.json`, `fx_row_ids.json`, `cleanup.log`, `migrate.log`, `verify.log`, `seed.log`, `api_log_summary.txt` |
| Live 1.35 run | `audit/parity/isolated/evidence/fxenv_20261002T211050Z/` — same files with `t135` |
| Live comparison panels (reference \| live 1.0 \| live 1.35) | `audit/parity/comparisons/live/fxc_<tag>.png` (27), composed by `audit/parity/contract_batch/compose_contract_batch_live.py` |
| Mocked comparisons | `audit/parity/comparisons/b8_logo_cover.png`, `b8_hours_exceptions.png`, `b8_duplicate.png`; recomposed `b3_product_menu.png`, `b4_cover.png`, `b4_hours.png` |
| Mocked raw captures | `audit/parity/mocked/b8_*_w390.png`, `b8_*_w375_t135.png` |
| Test logs (this closeout) | `audit/parity/contract_batch/test_logs/` |
| Live test | `integration_test/contract_batch_fx_live_test.dart` |
| Isolated tooling | `audit/parity/isolated/fx_start.sh`, `fx_run.sh`, `fx_cleanup.sh`, `fx_contract_e2e.py`, `fx_guard_test.sh` (report: `audit/parity/isolated/ISOLATED_FIXTURE_ENV_REPORT.md`) |
| Reference render for duplication (the PNG is black) | `audit/parity/reference_renders/duplicate_product_french_code_html_w390.png` (rendered from `code.html`, which loads Tailwind and Google Fonts from their CDNs) |

### Live panels by flow

| Flow | Panels (`comparisons/live/`) | Reference |
| --- | --- | --- |
| Logo: empty, save A, fresh instance, replace B, remove | `fxc_logo_empty`, `fxc_logo_reopened`, `fxc_logo_replaced`, `fxc_logo_removed` | `store_logo_and_cover_french` |
| Logo in the store profile | `fxc_profile_logo`, `fxc_profile_logo_fallback` | `store_profile_french` |
| Logo roles | `fxc_manager_logo`, `fxc_staff_logo` | `store_logo_and_cover_french` |
| Exceptions: list, form, save, fresh instance, conflict, open interval, delete | `fxc_hours_exceptions_empty`, `fxc_hours_exception_form`, `fxc_hours_exception_saved`, `fxc_hours_exception_reopened`, `fxc_hours_exception_conflict`, `fxc_hours_exception_open_interval`, `fxc_hours_exception_deleted` | `horaires_exceptionnels_format_24h` |
| Exception evaluation on the weekly screen | `fxc_hours_today_closed`, `fxc_hours_weekly_fallback` | `horaires_d_ouverture_pur` |
| Exceptions STAFF | `fxc_staff_hours_exceptions` | `horaires_exceptionnels_format_24h` |
| Duplicate OWNER: menu, screen, editor of the copy, list with the copy | `fxc_duplicate_owner_menu`, `fxc_duplicate_owner_screen`, `fxc_duplicate_owner_editor`, `fxc_catalog_with_copy` | `liste_des_produits_menu_ouvert`, duplicate render, `modifier_le_produit_standardis_image_corrig_e`, `liste_des_produits_standardis_e` |
| Duplicate MANAGER | `fxc_duplicate_manager_menu`, `fxc_duplicate_manager_screen`, `fxc_duplicate_manager_editor` | same |
| Duplicate STAFF | `fxc_staff_catalog`, `fxc_staff_duplicate` | `liste_des_produits_standardis_e`, duplicate render |

## 3. Failed and superseded attempts (provenance only, not evidence)

Every attempt below ran in its own disposable database and ended with `FX_CLEANUP_OK` and 11/11 isolation checks. All live attempts ran on the final application code (the last `lib/` change is 20:50:36 CET, before the first live attempt at 20:59 CET); the fixes between attempts were test-harness changes only. Their screenshots are excluded from the review evidence.

| Folder (`audit/parity/isolated/evidence/`) | Kind | Outcome | Cause and fix |
| --- | --- | --- | --- |
| `fxenv_20261002T192656Z` | backend e2e | 33 PASS, 6 FAIL | Harness errors: malformed request bodies (STAFF and closed-day PUT returned `400 VALIDATION_ERROR`), and a `KeyError` in the checkout-preview parsing that aborted the suite. L13 expected `400 STORAGE_FILE_TOO_LARGE` but observed `413 HTTP_ERROR`; the expectation was aligned to this existing multipart-limit behaviour, which covers and documents share, and the docs now state 413 |
| `fxenv_20261002T192823Z` | backend e2e | 54 PASS, 1 FAIL (H10) | The version-conflict response carried no current row. **Backend fix** (20:29:31–38 CET): the error filter now emits `error.openingHoursException`; filter spec added. The final run followed with no further source change |
| `fxenv_20261002T195904Z` | live 1.0 | failed | Test read the wrong copy ID; now read from `ProductEditorScreen.productId` |
| `fxenv_20261002T200449Z` | live 1.0 | failed | Double-tap race in the test harness; fixed with a dedicated `tapAt` double tap |
| `fxenv_20261002T200923Z` | live 1.0 | passed, superseded | Earlier test revision |
| `fxenv_20261002T201535Z` | live 1.35 | failed | Lazily built card not yet on screen; `reveal` helper added |
| `fxenv_20261002T201945Z` | live 1.35 | failed | Snackbar over the Save button / label not entered; wait for the snackbar to go |
| `fxenv_20261002T202439Z` | live 1.35 | failed | Label not entered |
| `fxenv_20261002T203005Z` | live 1.35 | failed | Status pill scrolled off screen (failure-state screenshot kept) |
| `fxenv_20261002T203415Z` | live 1.35 | passed, superseded | Earlier test revision |
| `fxenv_20261002T204011Z` | live 1.0 | stopped | **Duplicated tool invocation:** one invocation ran twice and the second copy's cleanup stopped this run. Isolation still passed (11/11). Since then, start, run and cleanup are separate tool calls |
| `fxenv_unknown_20261002T204328Z` | — | empty `cleanup.log` (0 bytes) | **Not evidence** |
| `fxenv_20261002T204412Z` | live 1.0 | failed | Label not entered at 1.0 |
| `fxenv_20261002T205950Z` | live 1.0 | passed, superseded | Test revision before the final label-entry change |
| `fxenv_20261002T210605Z` | live 1.35 | failed | Label not entered after the dialog at 1.35; final label loop (unfocus, ensure visible, tap, enter, verify; 3 attempts) |

## 4. Migration and API inventory

**Migration** `apps/backend/migrations/app/20261002T1907_merchant_contract_completion_batch` (`migration.json`, `migration.ts`, `ops.json`): contract `0cb52e95a90c…` → `8f14779ee734…`, `migrationHash` `24a95c1a89e39ebb31855371dd2d0f448825818cacf65dbb1cd87f99f7a08fcc`. 15 additive operations; no column dropped or altered; no financial table touched.

| Object | Change |
| --- | --- |
| `merchant_branch_logos` (`MerchantBranchLogo`) | New table; unique `branch_id`; FK → `merchant_branches` RESTRICT; CHECKs on size and dimensions |
| `merchant_branch_hours_exceptions` (`MerchantBranchHoursException`) | New table; unique index `(branch_id, local_date)`; FKs → `merchant_branches`, `accounts` RESTRICT; CHECKs `version >= 1`, non-blank label; indexes `(branch_id)`, `(updated_by_account_id)` |
| `merchant_branch_hours_exception_intervals` (`MerchantBranchHoursExceptionInterval`) | New table; FK → exception CASCADE; same-day CHECK; indexes `(exception_id, sort_order)`, `(exception_id)` |
| `products.duplicate_request_key` (`Product.duplicateRequestKey`) | New nullable `varchar(64)`, unique |

**API** (prefix `/api/v1/merchant/:merchantId`):

| Method and path | Capability | Success | Notable errors |
| --- | --- | --- | --- |
| `POST /branches/:branchId/logo/content` | `MERCHANT_BRANCH_UPDATE` | 200 `uploadReference` | 400 `STORAGE_UNSUPPORTED_TYPE`; 413 `HTTP_ERROR` (> 1 MiB); 403 STAFF |
| `PUT /branches/:branchId/logo` | `MERCHANT_BRANCH_UPDATE` | 200 `{ branchId, logoImageUrl, logoVersion, contentType, widthPx, heightPx }` | 404 `STORAGE_UPLOAD_REFERENCE_FOREIGN` |
| `GET /branches/:branchId/logo` | `MERCHANT_READ` | 200 bytes, `ETag`, `private, no-cache`, `nosniff` | 404 `STORAGE_OBJECT_MISSING` |
| `DELETE /branches/:branchId/logo` | `MERCHANT_BRANCH_UPDATE` | 200 `{ deleted: true }` (idempotent) | 403 STAFF |
| `GET /branches/:branchId/opening-hours/exceptions` | `MERCHANT_READ` | 200 `{ branchId, timezone, today, items[] }` | — |
| `PUT /branches/:branchId/opening-hours/exceptions/:date` | `MERCHANT_BRANCH_UPDATE` | 200 item | 400 `OPENING_HOURS_EXCEPTION_INVALID` / `VALIDATION_ERROR`; 409 `…_VERSION_CONFLICT` (+ `error.openingHoursException`); 409 `…_WEEKLY_REQUIRED` |
| `DELETE /branches/:branchId/opening-hours/exceptions/:date?expectedVersion=n` | `MERCHANT_BRANCH_UPDATE` | 200 `{ deleted: true, date }` | 404 `…_NOT_FOUND`; 409 conflict |
| `GET`/`PUT /branches/:branchId/availability` | existing | additive `hoursException` | — |
| `POST /products/:productId/duplicate` | `PRODUCT_MANAGE` | 201 new copy / 200 `replayed: true` | 400 `VALIDATION_ERROR`; 404 `CATALOG_PRODUCT_NOT_FOUND`; 409 `CATALOG_DUPLICATE_REQUEST_CONFLICT`; 503 `STORAGE_UNAVAILABLE` |

Checkout and Order reuse `CHECKOUT_BRANCH_CLOSED` / `ORDER_BRANCH_CLOSED` when an exception closes the Branch; Customer `isOpenNow` and the `openNow=true` filter apply exceptions. No Customer field was added.

**Documentation updated in this closeout:** see section 7.

## 5. Recorded limitations

- **Product image duplication** was verified by backend e2e (D03, D13–D15), not by the final live run: the fixture products had no image. Live image copying is not claimed.
- **Shared UI issue (tracked, not fixed):** a snackbar can cover the Save button for about four seconds on screens that place the shared in-body sticky footer (`MerchantStickyBar`) inside the body. Visible in `fxc_hours_exception_open_interval` (both sizes, "Exception enregistrée") and `fxc_duplicate_owner_editor` (1.35, "Copie créée"); it caused the failed run `fxenv_20261002T201945Z`. The live test waits for the snackbar to disappear before saving.
- **Failed-attempt folders** (section 3) are kept for provenance and are not successful evidence.
- **Duplicated tool invocation:** one invocation ran twice; the duplicate's cleanup stopped `fxenv_20261002T204011Z`. Isolation still passed. Historical execution provenance only.
- **`fxenv_unknown_20261002T204328Z`** is empty and is not evidence.
- **Stale mocked panel:** the 1.35 panel of `b4_cover` was captured at 20:47:59 CET, before the final logo-button change (20:50:36) that stacks the buttons at text ≥ 1.25, so it shows "Supprim/er" broken. `b8_logo_cover` and the live `fxc_logo_*` panels show the final layout.
- **Backend e2e L13** expectation was aligned to the existing 413 multipart-limit behaviour (section 3).

## 6. Remaining gaps

**Batch-specific:**
- Snackbar over the in-body sticky Save bar (shared UI issue above).
- Exceptions: one civil date per exception, no range card or batch entry (partial by decision); the label and customer message are not shown in the Customer app (no Customer field); a real midnight crossing was not observed live.
- Duplication: "Unités de vente" shown as not managed (no unit contract); live image copy not shown.
- Logo: no Customer display, no Admin moderation, no server-side crop.
- The migration is not applied to `speedygo_dev`. The shared dev API (port 3000) is stopped and was not restarted; applying the migration there is the user's decision.
- Analyzer: 4 infos in batch files and 1 pre-existing warning (row 8).
- `docs/database/PRISMA_IMPLEMENTATION.md` still omits the two 2026-09-24 migrations (`20260924T1644_merchant_branch_availability_override`, `20260924T1757_order_preparation_estimate`); this omission predates the batch and was left unchanged.

**Merchant parity overall** (`apps/merchant_app/docs/MERCHANT_SCREEN_PARITY_MATRIX.md`, 77 rows): 46 done · 12 partial · 5 blocked by contract · 2 deferred · 7 accepted exceptions · 5 duplicates. Live: 36 live compared · 29 not · 12 not applicable. Visual acceptance: 0.
- Partial (12): rows 18, 21, 47, 51, 57, 63, 71, 72, 73, 74, 76, 77.
- Blocked by contract (5): rows 5, 23, 44, 53, 64.
- Deferred (2): rows 45 (D-C6) and 61 (D-G3).
- Open decisions (9): D-A1, D-A5, D-B4, D-C6, D-D2, D-D5, D-D7, D-G3, D-G4. D-G5 stays deferred.
- Optional live captures still NOT RUN: mark-ready confirmation, CONFIRMED detail, store map.

## 7. Files updated in this closeout

Workspace `docs/` (not a Git repository):
- `docs/architecture/MERCHANT_BRANCH_LOGO_FOUNDATION.md` (status, routes, errors, verification)
- `docs/architecture/MERCHANT_OPENING_HOURS_EXCEPTIONS_FOUNDATION.md` (status, conflict key `error.openingHoursException`, DTO vs domain errors, zero-length and year rules, verification)
- `docs/architecture/CATALOG_PRODUCT_DUPLICATION_FOUNDATION.md` (status, lower-cased `requestId`, errors, media policy, UI, verification)
- `docs/architecture/CATALOG_FOUNDATION.md` (duplicate route row)
- `docs/architecture/CUSTOMER_CATALOG_DISCOVERY_FOUNDATION.md` (logo is Merchant-only)
- `docs/architecture/DOMAIN_MODEL.md` (logo read scope and idempotent removal, exception precedence and concurrency, duplication precision)
- `docs/business-rules/MERCHANT_BRANCH_LOGO.md` (new)
- `docs/business-rules/MERCHANT_OPENING_HOURS_EXCEPTIONS.md` (precedence, concurrency, roles, partial-by-decision ranges)
- `docs/business-rules/CATALOG_PRODUCT_DUPLICATION.md` (roles, transaction, double tap, media)
- `docs/database/ERD.md` (logo read scope, indexes, request-key formula, migration pointers)
- `docs/database/PRISMA_IMPLEMENTATION.md` (migration entry and model notes)
- `docs/api/API_CONVENTIONS.md` (three API sections, `isOpenNow` wording, conflict-key note)

Merchant app (`apps/merchant_app/`, Git repository without commits):
- `apps/merchant_app/docs/MERCHANT_SCREEN_PARITY_MATRIX.md` (rows 28, 38, 46, 52, 56, 57 regenerated; decisions, counts, gaps and the new batch section hand-edited)
- `audit/parity/matrix/progress.json` (the same six rows)
- `audit/parity/COMPARISON_INDEX.md` (b8 entries, recomposition notes, contract-batch live section)
- `audit/parity/contract_batch/` — this report, `INDEX.md`, `count_matrix.py`, `update_progress.py`, `verify_sources_unchanged.sh`, `check_links.py`, `build_contract_batch_package.py`, `compose_contract_batch_live.py`, `test_logs/`

## 8. Closeout safety

- **Sources unchanged:** `verify_sources_unchanged.sh` re-hashed the 923 backend and Merchant source, test, migration and isolated-tooling files snapshotted before the documentation work, and found no change, addition or removal (result recorded in `INDEX.md`).
- **Not restarted or touched:** the shared dev API on port 3000; `speedygo_dev`; Finjan; the Customer and Driver apps; the Keychain; existing sessions. The isolated API on port 3100 is stopped, Redis index 9 is empty and the isolated database is dropped (final `cleanup.log`).
- No commit, push, deployment or external-service activation.
