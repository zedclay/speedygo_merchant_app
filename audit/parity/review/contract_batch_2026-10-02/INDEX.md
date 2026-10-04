# Merchant contract-completion batch — review package index (2026-10-02)

**Status: `implementer_reviewed`, pending user visual acceptance.** No screen is user-accepted. No commit, push, deployment or external-service activation.

Links in this file are relative to the package root (`contract_batch_2026-10-02/`). The table below shows where each package folder comes from in the repository. Paths in backticks are repository paths: they start at the workspace root when they begin with `apps/` or `docs/`.

| Package folder | Repository source |
| --- | --- |
| [CONTRACT_COMPLETION_BATCH_REPORT.md](CONTRACT_COMPLETION_BATCH_REPORT.md), this INDEX | `apps/merchant_app/audit/parity/contract_batch/` |
| [parity/](parity/MERCHANT_SCREEN_PARITY_MATRIX.md) | `apps/merchant_app/docs/MERCHANT_SCREEN_PARITY_MATRIX.md`, `apps/merchant_app/audit/parity/COMPARISON_INDEX.md` |
| [matrix/](matrix/progress.json) | `apps/merchant_app/audit/parity/matrix/progress.json`, `apps/merchant_app/audit/parity/matrix/rows.json` |
| [docs/](docs/api/API_CONVENTIONS.md) | workspace `docs/` (same sub-folders) |
| [migration/](migration/20261002T1907_merchant_contract_completion_batch/ops.json) | `apps/backend/migrations/app/20261002T1907_merchant_contract_completion_batch/` (no `migration.sql` exists) |
| [comparisons/live/](comparisons/live/fxc_logo_empty.png) | `apps/merchant_app/audit/parity/comparisons/live/fxc_*.png` (27): reference \| live 1.0 \| live 1.35 |
| [comparisons/mocked/](comparisons/mocked/b8_logo_cover.png) | `apps/merchant_app/audit/parity/comparisons/` (`b8_*`, recomposed `b3_product_menu`, `b4_cover`, `b4_hours`) |
| [raw/live_t100/](raw/live_t100/fxc_t100_logo_empty.png), [raw/live_t135/](raw/live_t135/fxc_t135_logo_empty.png) | `screens/` of the two final runs (27 each) |
| [raw/mocked/](raw/mocked/b8_logo_cover_w390.png) | `apps/merchant_app/audit/parity/mocked/b8_*.png` |
| [evidence/live_t100/](evidence/live_t100/PROVENANCE_fxc_t100.json) | `apps/merchant_app/audit/parity/isolated/evidence/fxenv_20261002T211645Z/` (text 1.0) |
| [evidence/live_t135/](evidence/live_t135/PROVENANCE_fxc_t135.json) | `apps/merchant_app/audit/parity/isolated/evidence/fxenv_20261002T211050Z/` (text 1.35) |
| [evidence/backend_e2e/](evidence/backend_e2e/contract_e2e_results.json) | `apps/merchant_app/audit/parity/isolated/evidence/fxenv_20261002T193016Z/` |
| [test_logs/](test_logs/backend_unit_full.log) | `apps/merchant_app/audit/parity/contract_batch/test_logs/` |
| [contract_batch/](contract_batch/count_matrix.py) | closeout scripts, and `apps/merchant_app/integration_test/contract_batch_fx_live_test.dart` |
| [reference_renders/](reference_renders/duplicate_product_french_code_html_w390.png) | `apps/merchant_app/audit/parity/reference_renders/` |
| [provenance_failed_attempts/](provenance_failed_attempts/FAILED_ATTEMPTS.txt) | listing only; **not evidence**, no screenshots |
| [SHA256SUMS.txt](SHA256SUMS.txt) | SHA-256 of every other file in the package |

Excluded: `environment.json` files, `.env` files, database dumps, build caches, the empty `fxenv_unknown_20261002T204328Z` folder, and every failed-attempt screenshot. Links in the packaged matrix and comparison index that point outside the package (inventory, references, earlier panels) resolve only inside the repository.

## 1. Documentation requirements

| Requirement | Documents | Evidence |
| --- | --- | --- |
| Store logo: Branch ownership, authenticated Merchant media lifecycle, roles | [business-rules/MERCHANT_BRANCH_LOGO.md](docs/business-rules/MERCHANT_BRANCH_LOGO.md) (new), [architecture/MERCHANT_BRANCH_LOGO_FOUNDATION.md](docs/architecture/MERCHANT_BRANCH_LOGO_FOUNDATION.md), [architecture/CUSTOMER_CATALOG_DISCOVERY_FOUNDATION.md](docs/architecture/CUSTOMER_CATALOG_DISCOVERY_FOUNDATION.md) (logo is Merchant-only) | e2e L01–L17 in [contract_e2e_results.json](evidence/backend_e2e/contract_e2e_results.json); live logo panels (section 3) |
| Exceptional hours: `Africa/Algiers` dates, precedence, optimistic concurrency | [business-rules/MERCHANT_OPENING_HOURS_EXCEPTIONS.md](docs/business-rules/MERCHANT_OPENING_HOURS_EXCEPTIONS.md), [architecture/MERCHANT_OPENING_HOURS_EXCEPTIONS_FOUNDATION.md](docs/architecture/MERCHANT_OPENING_HOURS_EXCEPTIONS_FOUNDATION.md); unchanged context: [MERCHANT_OPENING_HOURS_FOUNDATION.md](docs/architecture/MERCHANT_OPENING_HOURS_FOUNDATION.md), [MERCHANT_STORE_AVAILABILITY_FOUNDATION.md](docs/architecture/MERCHANT_STORE_AVAILABILITY_FOUNDATION.md), [MERCHANT_OPENING_HOURS.md](docs/business-rules/MERCHANT_OPENING_HOURS.md), [MERCHANT_STORE_AVAILABILITY.md](docs/business-rules/MERCHANT_STORE_AVAILABILITY.md) | e2e H01–H23 and [hours_states.json](evidence/backend_e2e/hours_states.json); live exception panels (section 3) |
| Atomic product duplication: copied fields, unavailable start, transaction, idempotent / double-tap, media-copy policy | [business-rules/CATALOG_PRODUCT_DUPLICATION.md](docs/business-rules/CATALOG_PRODUCT_DUPLICATION.md), [architecture/CATALOG_PRODUCT_DUPLICATION_FOUNDATION.md](docs/architecture/CATALOG_PRODUCT_DUPLICATION_FOUNDATION.md), [architecture/CATALOG_FOUNDATION.md](docs/architecture/CATALOG_FOUNDATION.md) (route row) | e2e D01–D15; live duplication panels (section 3) |
| Domain model | [architecture/DOMAIN_MODEL.md](docs/architecture/DOMAIN_MODEL.md) | matches the code and migration (report section 4) |
| ERD | [database/ERD.md](docs/database/ERD.md) | constraint and index names as in [ops.json](migration/20261002T1907_merchant_contract_completion_batch/ops.json) |
| API documentation | [api/API_CONVENTIONS.md](docs/api/API_CONVENTIONS.md) (exceptions, logo and duplication sections; `isOpenNow` wording; `error.openingHoursException`) | e2e results; report section 4 |
| Prisma implementation notes | [database/PRISMA_IMPLEMENTATION.md](docs/database/PRISMA_IMPLEMENTATION.md) ("Merchant contract-completion batch models") | [migration.json](migration/20261002T1907_merchant_contract_completion_batch/migration.json) (hashes), [ops.json](migration/20261002T1907_merchant_contract_completion_batch/ops.json) (15 operations), [verify.log](evidence/live_t100/verify.log) |
| Parity matrix | [parity/MERCHANT_SCREEN_PARITY_MATRIX.md](parity/MERCHANT_SCREEN_PARITY_MATRIX.md) (rows 28, 38, 46, 52, 56, 57; decisions D-C2, D-D3, D-D4; "Contract-completion batch (2026-10-02)" section; status counts) | [matrix/progress.json](matrix/progress.json), [matrix/rows.json](matrix/rows.json) |
| Comparison index | [parity/COMPARISON_INDEX.md](parity/COMPARISON_INDEX.md) (b8 rows, recomposition notes, final section listing all 27 `fxc_*` panels) | `comparisons/` folders |
| progress.json | [matrix/progress.json](matrix/progress.json) (the same six rows) | — |
| Batch report with PASS / FAIL / NOT RUN matrix, evidence inventory, migration/API inventory, remaining gaps | [CONTRACT_COMPLETION_BATCH_REPORT.md](CONTRACT_COMPLETION_BATCH_REPORT.md) sections 1, 2, 4 and 6 | — |

Only implemented behaviour is documented. Not implemented, and stated as such: exception date ranges and batch entry, Customer display of exceptions or the logo, Admin logo moderation, server-side logo crop.

## 2. Authoritative live runs

| Text size | Run | Result | Same test file |
| --- | --- | --- | --- |
| 1.0 (`large`) | [evidence/live_t100/](evidence/live_t100/PROVENANCE_fxc_t100.json), started 21:16:45 UTC ([started_at](evidence/live_t100/started_at)) | 30/30 recorded checks; "All tests passed!" ([flutter log](evidence/live_t100/flutter_fxc_t100.log)); 27 screenshots ([shots log](evidence/live_t100/shots_fxc_t100.log)); bundle and content size ([BUNDLE](evidence/live_t100/BUNDLE_fxc_t100.txt)) | [contract_batch_fx_live_test.dart](contract_batch/contract_batch_fx_live_test.dart), last modified 21:10:27 UTC, before both runs |
| 1.35 (`extra-extra-extra-large`) | [evidence/live_t135/](evidence/live_t135/PROVENANCE_fxc_t135.json), started 21:10:50 UTC ([started_at](evidence/live_t135/started_at)) | 30/30; [flutter log](evidence/live_t135/flutter_fxc_t135.log); [shots log](evidence/live_t135/shots_fxc_t135.log); [BUNDLE](evidence/live_t135/BUNDLE_fxc_t135.txt) | same file |

Isolation after each run, 11/11 PASS and `FX_CLEANUP_OK`: [1.0 cleanup.log](evidence/live_t100/cleanup.log), [1.0 isolation_comparison.json](evidence/live_t100/isolation_comparison.json), [1.35 cleanup.log](evidence/live_t135/cleanup.log), [1.35 isolation_comparison.json](evidence/live_t135/isolation_comparison.json). Rows written during the runs: [1.0 fx_row_ids.json](evidence/live_t100/fx_row_ids.json), [1.35 fx_row_ids.json](evidence/live_t135/fx_row_ids.json). Dev Redis job scan: [1.0](evidence/live_t100/dev_redis_job_scan.json), [1.35](evidence/live_t135/dev_redis_job_scan.json).

## 3. Flows and their evidence

Each flow lists the comparison panel and the raw screenshot names; raw names are `fxc_t100_<tag>.png` in [raw/live_t100/](raw/live_t100/fxc_t100_logo_empty.png) and `fxc_t135_<tag>.png` in [raw/live_t135/](raw/live_t135/fxc_t135_logo_empty.png). Recorded keys are in the PROVENANCE `results` of both runs (identical values).

| Flow | Panels | Recorded keys | Backend e2e |
| --- | --- | --- | --- |
| Logo empty state | [fxc_logo_empty](comparisons/live/fxc_logo_empty.png), [fxc_profile_logo_fallback](comparisons/live/fxc_profile_logo_fallback.png) | `logoInitiallyEmpty` | L01 |
| Logo save, fresh instance, byte-for-byte | [fxc_logo_reopened](comparisons/live/fxc_logo_reopened.png), [fxc_profile_logo](comparisons/live/fxc_profile_logo.png) | `logoSavedMatchesA`, `logoAfterFreshInstance` | L02–L05 |
| Logo replacement, byte-for-byte | [fxc_logo_replaced](comparisons/live/fxc_logo_replaced.png) | `logoReplacedMatchesB`, `logoReplacedDiffersFromA`, `logoDisplayedIsB` | L08, L09 |
| Logo removal | [fxc_logo_removed](comparisons/live/fxc_logo_removed.png) | `logoAfterRemove` = none | L15–L17 |
| Logo roles (MANAGER may edit; STAFF read-only) | [fxc_manager_logo](comparisons/live/fxc_manager_logo.png), [fxc_staff_logo](comparisons/live/fxc_staff_logo.png) | `managerLogoControls`, `staffLogoReadOnly` | L06, L07 |
| Logo validation and isolation | — (backend only) | — | L10–L14 |
| Exceptions list and form | [fxc_hours_exceptions_empty](comparisons/live/fxc_hours_exceptions_empty.png), [fxc_hours_exception_form](comparisons/live/fxc_hours_exception_form.png) | `serverToday` | H01, H13 |
| Exception save and fresh instance | [fxc_hours_exception_saved](comparisons/live/fxc_hours_exception_saved.png), [fxc_hours_exception_reopened](comparisons/live/fxc_hours_exception_reopened.png) | `exceptionAfterFreshInstance` | H16 |
| Optimistic concurrency: conflict keeps the draft, retry saves | [fxc_hours_exception_conflict](comparisons/live/fxc_hours_exception_conflict.png), [fxc_hours_exception_open_interval](comparisons/live/fxc_hours_exception_open_interval.png) | `conflictKeptDraft`, `retryAfterConflictSaved` | H10–H12, H17 |
| Exception evaluation (closed today, then weekly fallback) | [fxc_hours_today_closed](comparisons/live/fxc_hours_today_closed.png), [fxc_hours_weekly_fallback](comparisons/live/fxc_hours_weekly_fallback.png), [fxc_hours_exception_deleted](comparisons/live/fxc_hours_exception_deleted.png) | `todayClosedIsOpenNow`, `todayClosedAccepting`, `weeklyFallbackIsOpenNow` | H02, H04–H09, H14, H15, H18 |
| Precedence over availability overrides | — (backend only) | — | H19, H20 |
| Exception roles | [fxc_staff_hours_exceptions](comparisons/live/fxc_staff_hours_exceptions.png) | `managerExceptionEditor`, `staffExceptionsReadOnly` | H03, H21, H22 |
| Duplicate OWNER: menu, screen, double tap, unavailable copy | [fxc_duplicate_owner_menu](comparisons/live/fxc_duplicate_owner_menu.png), [fxc_duplicate_owner_screen](comparisons/live/fxc_duplicate_owner_screen.png), [fxc_duplicate_owner_editor](comparisons/live/fxc_duplicate_owner_editor.png), [fxc_catalog_with_copy](comparisons/live/fxc_catalog_with_copy.png) | `ownerCopiesAfterDoubleTap` = 1, `ownerCopyAvailable` = false, `ownerCopyName`, `ownerCopyHasImage` = false, `sourceUnchanged` | D01, D02, D04–D07 |
| Duplicate MANAGER | [fxc_duplicate_manager_menu](comparisons/live/fxc_duplicate_manager_menu.png), [fxc_duplicate_manager_screen](comparisons/live/fxc_duplicate_manager_screen.png), [fxc_duplicate_manager_editor](comparisons/live/fxc_duplicate_manager_editor.png) | `managerCopyAvailable` = false | D08 |
| Duplicate STAFF refused | [fxc_staff_catalog](comparisons/live/fxc_staff_catalog.png), [fxc_staff_duplicate](comparisons/live/fxc_staff_duplicate.png) | `staffNoProductMenu`, `staffDuplicateRefused` | D09 |
| Duplicate transaction, rollback and retry | — (backend only) | — | D10–D12 |
| Product-image copy and media safety | — (**not live**: the fixture products had no image) | — | D03, D13–D15 |
| Sessions revoked at logout | — | `logout_OWNER`, `logout_MANAGER`, `logout_STAFF` | — |

Mocked comparisons: [b8_logo_cover](comparisons/mocked/b8_logo_cover.png), [b8_hours_exceptions](comparisons/mocked/b8_hours_exceptions.png), [b8_duplicate](comparisons/mocked/b8_duplicate.png); recomposed [b3_product_menu](comparisons/mocked/b3_product_menu.png), [b4_hours](comparisons/mocked/b4_hours.png) and [b4_cover](comparisons/mocked/b4_cover.png) (its 1.35 panel is **stale**: captured before the final logo-button stacking). Raw mocked captures in [raw/mocked/](raw/mocked/b8_logo_cover_w390.png). Duplication reference render: [duplicate_product_french_code_html_w390.png](reference_renders/duplicate_product_french_code_html_w390.png).

## 4. Reporting rules and limitations

| Rule | Where recorded | Evidence |
| --- | --- | --- |
| Product-image duplication verified by backend e2e only, not live | Report sections 1 (row 16) and 5; matrix batch section | e2e D03, D13–D15; `ownerCopyHasImage` = false in both PROVENANCE files |
| Snackbar covers the Save button for about 4 s on screens with the shared in-body sticky footer; tracked, not fixed | Report sections 5 and 6; matrix "Visual gaps" and next actions | visible in [fxc_hours_exception_open_interval](comparisons/live/fxc_hours_exception_open_interval.png) (both sizes) and [fxc_duplicate_owner_editor](comparisons/live/fxc_duplicate_owner_editor.png) (1.35) |
| Failed-attempt folders retained for provenance, not evidence | Report section 3 | [FAILED_ATTEMPTS.txt](provenance_failed_attempts/FAILED_ATTEMPTS.txt) (paths only) |
| Duplicated tool invocation stopped `fxenv_20261002T204011Z`; isolation still passed | Report sections 3 and 5 | `apps/merchant_app/audit/parity/isolated/evidence/fxenv_20261002T204011Z/cleanup.log` (repository only) |
| Empty `fxenv_unknown_20261002T204328Z` is not evidence | Report sections 3 and 5 | not packaged |
| STAFF restrictions, conflict draft preservation, byte-for-byte logo replacement and removal, exceptional-hours evaluation, double-tap protection, unavailable duplicate, original preserved: all live PASS at both sizes | Report section 1 | section 3 above |
| No live product-image copying claimed; no screen user-accepted | Report header and section 1 (rows 16, 20) | — |
| Stale mocked `b4_cover` 1.35 panel | Report section 5; comparison index | [b4_cover](comparisons/mocked/b4_cover.png) |

## 5. Validation (closeout, 2026-10-02)

| Check | Result |
| --- | --- |
| Source and migration files unchanged during this documentation step | **PASS**: `apps/merchant_app/audit/parity/contract_batch/verify_sources_unchanged.sh` against the snapshot taken before the documentation work: "UNCHANGED 923 files", "NONE ADDED, NONE REMOVED" (backend `src`, `prisma`, `test`, `migrations`; Merchant `lib`, `test`, `integration_test`; isolated tooling) |
| Documentation links and evidence paths | **PASS**: [check_links.py](contract_batch/check_links.py) on the 12 edited workspace docs, the matrix, the comparison index, the report and this INDEX (repository paths), and on this INDEX inside the package. Two anchors in generated matrix rows 1 and 45 were already broken before this closeout; they are reported as pre-existing and left unchanged |
| JSON parses | **PASS**: 26 files (`progress.json`, `rows.json`, both PROVENANCE files, e2e results, `hours_states.json`, every other JSON of the three runs except the excluded `environment.json`) |
| Parity counts reconciled | **PASS**: [count_matrix.py](contract_batch/count_matrix.py) gives 77 rows: 46 done · 12 partial · 5 blocked · 2 deferred · 7 exceptions · 5 duplicates; live 36 · not live 29 · n/a 12. Same figures in the matrix ("Status counts"; "Remaining non-done rows (31 of 77)"), the comparison index (batch section) and the report (section 6) |
| ZIP contents and secrets | Listed with `unzip -l`; no `environment.json`, `.env`, dump, cache or failed-attempt screenshot; no database or Redis URL, password, bearer token, JWT, OTP value or API key in any text file |
| ZIP SHA-256 | Stated in the closeout response (a ZIP cannot contain its own hash). [SHA256SUMS.txt](SHA256SUMS.txt) covers every file inside |

Not restarted or touched during the closeout: the shared dev API on port 3000 (stopped by the user), `speedygo_dev`, Finjan, the Customer and Driver apps, the Keychain and existing sessions.
