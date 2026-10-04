# Merchant final polish pass — report (2026-10-03)

**Status: `implementer_reviewed`, pending user visual acceptance.** No screen is user-accepted. No commit, push, deployment or external-service activation. No backend contract, Prisma model, migration or business behaviour changed. The shared dev API (port 3000) was not restarted, and the batch migration was not applied to `speedygo_dev`.

Paths are relative to `apps/merchant_app/` unless they start with `apps/` or `docs/` (workspace root).

## 1. PASS / FAIL / NOT RUN

| # | Check | Result | Evidence |
| --- | --- | --- | --- |
| 1 | Polish geometry widget tests (`test/features/merchant_polish_geometry_test.dart`): snack bar vs sticky bar on 3 real forms at 1.0 and 1.35; generic matrix (text scale × safe area × keyboard × two bars); no-bar case; catalogue end inside and outside the shell and with a taller FAB at both scales; STAFF direct, pushed and fallback navigation; OWNER close fallback | **PASS** 35/35 | `audit/parity/polish/test_logs/flutter_focused_widget_tests.log` |
| 2 | Focused widget tests of the touched screens (`contract_completion_batch_test`, `phase5_catalog_reports_test`, `phase5_forms_test`, `order_ops_test`, `store_general_save_navigation_test`, `mark_ready_confirm_test`, and row 1) | **PASS** 101/101 (row 1 included) | same log |
| 3 | Mocked captures after the change (`test/audit/parity/batch9_polish_capture_test.dart`, `B9_PHASE=after`) | **PASS** 10/10 | `test_logs/flutter_b9_capture_after.log`; `geometry/*_after_*.json` |
| 4 | Mocked captures before the change (same test, `B9_PHASE=before`) | **PASS** 10/10 images and geometry written 01:56:28–01:58:20 UTC, before the code change. The console log was not kept | `geometry/*_before_*.json`, `audit/parity/mocked/b9_*_before_*.png` |
| 5 | `b4_cover` recapture (`batch4_store_capture_test.dart --plain-name 'cover w'`) | **PASS** 2/2 | `test_logs/flutter_b4_cover_recapture.log` |
| 6 | `flutter analyze` on the 8 changed or new Dart files: no errors | **PASS** 0 errors, 0 warnings | `test_logs/flutter_analyze_changed_files.log` |
| 7 | `flutter analyze` on the same files: no issues at all | **FAIL** (exit 1): 1 info, `use_null_aware_elements` at `lib/core/widgets/merchant_ui.dart:837`. It was already present before this pass (line 685 in `audit/parity/contract_batch/test_logs/flutter_analyze.log`) and was not touched | same |
| 8 | Isolation guard tests (`fx_guard_test.sh`, now 84 with the polish test's Finjan refusal) | **PASS** 84/84 | `test_logs/fx_guard_test.log` |
| 9 | Live, isolated, iPhone 16e, text 1.35: polish checks (image duplication 10 keys, 3 snack-bar geometries, catalogue end, STAFF state, back, fallback, server 403) | **PASS** every polish check (section 3) | `audit/parity/isolated/evidence/fxenv_20261003T022402Z/` |
| 10 | Live, same, text 1.0 | **PASS** every polish check | `audit/parity/isolated/evidence/fxenv_20261003T022804Z/` |
| 11 | Live test as a whole (`integration_test/polish_fx_live_test.dart`) at 1.35 and 1.0 | **FAIL** at both sizes, on one assertion only: the weekly-hours restore round-trip (row 13). It is checked last, so every other step ran and was recorded first | `flutter_fxp_t135.log`, `flutter_fxp_t100.log` |
| 12 | Storage objects: source and copy use distinct `product_images.object_id` with equal stored bytes (SHA-256), checked on the host before teardown | **PASS** at 1.35 and 1.0 | `IMAGE_STORAGE_CHECK_fxp_t135.json`, `IMAGE_STORAGE_CHECK_fxp_t100.json` |
| 13 | Weekly hours restored exactly after the live save | **FAIL** at both sizes: **backend defect** (section 4). Not fixed: outside this pass | `PROVENANCE_fxp_*.json` (`weeklyAfterRestore`), `WEEKLY_INTERVAL_ROWS_after_restore.txt` (18 rows instead of 7) |
| 14 | Isolation after each final run (11 checks: `speedygo_dev` counts, tracked orders, late order, branch names, Redis 0/15/9, database dropped) | **PASS** 11/11 each, `FX_CLEANUP_OK` | `cleanup.log` of both runs |
| 15 | Matrix and document links, with no allowed exceptions | **PASS** (`check_links.py`: 0 bad; the two broken anchors fixed at their source) | `audit/parity/contract_batch/check_links.py` |
| 16 | Backend suites (unit, e2e) | **NOT RUN** by instruction (no backend change) | — |
| 17 | Backend jest e2e harness | **NOT RUN** by rule (forces `speedygo_test`, flushes Redis DB 15) | — |
| 18 | Full Flutter suite | **NOT RUN** (it regenerates every mocked PNG; focused tests only, by instruction) | — |
| 19 | Snack bar with the keyboard open, live | **NOT RUN** live; covered by the widget matrix (row 1: keyboard inset 320 px at both scales) | row 1 |
| 20 | MANAGER on the polish surfaces, live | **NOT RUN** (not requested; MANAGER duplication was verified live in the batch) | — |
| 21 | Exception-interval replacement defect, live | **NOT RUN** live (found by code inspection, section 4) | — |
| 22 | `speedygo_dev` scanned for duplicate weekly intervals | **NOT RUN** (left to your decision; `speedygo_dev` was not queried in this pass beyond the isolation snapshots) | — |
| 23 | Migration applied to `speedygo_dev` | **NOT RUN** (by instruction) | — |
| 24 | User visual acceptance | **NOT RUN**: no screen is user-accepted | — |

## 2. UI corrections and geometry

### 2.1 Snack bar vs in-body `MerchantStickyBar`

`MerchantSnackBarScope` wraps every `MerchantScaffold`, and the order detail `Scaffold` that does not use it. When a `MerchantStickyBar` is below it, the scope makes snack bars floating with bottom inset = measured bar height − bottom safe area + 8 px. The bar measures itself after layout, so text scale, safe area and the keyboard are all reflected: with the keyboard open the safe area is 0 and the full bar height is used. The scope keeps the tallest of several bars. With no bar, snack bars are unchanged. Duration is not changed, and every existing message and action is preserved (asserted in row 1).

| Surface | Before 1.0 | Before 1.35 | After 1.0 | After 1.35 | Live 1.0 | Live 1.35 |
| --- | --- | --- | --- | --- | --- | --- |
| Exceptional-hours save | −110 px, covers "Enregistrer" | −110 px, covers it | +8 px | +8 px | +8 px | +8 px |
| Duplicate → editor ("Copie créée") | −110 px | −166 px | +8 px | +8 px | +8 px | +8 px |
| Weekly opening-hours save (other sticky-footer form) | −110 px | −110 px | +8 px | +8 px | +8 px | +8 px |

Values are the gap between the snack bar's bottom and the sticky bar's top (negative = overlap). Mocked: 390×844 at 1.0 and 375×812 at 1.35 with a 34 px safe area (`geometry/b9_snack_*`). Live: iPhone 16e, 390×844, safe area 34 px, measured text scale 1.00 and 1.35. In no case does the snack bar overlap the bar or its primary action.

### 2.2 Catalogue end vs FAB, bottom navigation and safe area

The list's end padding is now measured FAB height + `kFloatingActionButtonMargin` + bottom safe area + 24 px. It used to be a fixed 96 px. When no FAB is shown (STAFF, empty list), the padding is 24 px + safe area. The FAB and catalogue behaviour are unchanged.

**Honest result:** inside the app shell the populated list did **not** overlap before. The shell's bottom navigation consumes the safe area and the FAB is 56 px, so the fixed 96 px already left 24 px. The new formula gives the same 96 px there, so the before and after panels are identical. The change matters when the safe area is not consumed (catalogue outside the shell, 34 px) and with a taller FAB (88 px). The fixed 96 px would fail both cases, and both are now asserted at 1.0 and 1.35 (row 1).

| | Gap above FAB | Gap above bottom nav | Gap above safe area |
| --- | --- | --- | --- |
| Mocked before, 1.0 / 1.35 | 24 / 24 px | 96 / 96 px | — |
| Mocked after, 1.0 / 1.35 | 24 / 24 px | 96 / 96 px | 162 / 168 px |
| Live (7 products incl. the copy), 1.0 / 1.35 | 24 / 24 px | 96 / 96 px | 162 / 168 px |

### 2.3 STAFF reaching the duplicate route directly

Authorization is unchanged (`catalogRoleCanManage`). It is checked before any catalogue loading, so STAFF never sees the form, the source card or "Créer la copie". The forbidden state has an AppBar titled "Dupliquer le produit" and a back arrow; when nothing is below the route, back opens the catalogue. Below the lock icon it shows "Duplication réservée au propriétaire ou au responsable", the read-only explanation and "Retour au catalogue". OWNER's close and Annuler buttons use the same fallback when reached directly. The server's protection still holds: live as STAFF, `POST …/duplicate` returned **403 `MERCHANT_ROLE_FORBIDDEN`** and the product count did not change.

| | AppBar | Back action | "Retour au catalogue" | Form / create action |
| --- | --- | --- | --- | --- |
| Before | yes | close button only | no | not shown |
| After (mocked and live, both sizes) | yes | yes (back opens the catalogue) | yes (opens the catalogue) | not shown |

### 2.4 Before / after panels

`audit/parity/polish/before_after/`: `b9_snack_hours_before_after.png`, `b9_snack_duplicate_editor_before_after.png`, `b9_snack_weekly_hours_before_after.png`, `b9_catalog_end_before_after.png`, `b9_staff_duplicate_before_after.png` (before | after at 390 t1.0, then 375 t1.35; panel labels carry the measured gap). Live panels (1.0 | 1.35): `audit/parity/polish/live_panels/fxp_*.png`.

## 3. Live product-image duplication (isolated environment only)

Environment: disposable `speedygo_parity_fx` on 127.0.0.1:3100, Redis index 9, local storage under `~/.speedygo/parity_fx/storage`. Each content size ran in a fresh environment, so the 1.0 run did not start from the 1.35 run's data. One memory-only OTP session per role, each ended by the app's logout. `speedygo_dev` and `speedygo_test` were never written.

Steps: bind a synthetic 480×480 JPEG (13,968 bytes) to "Couscous royal" through the Merchant API, which had no image before. Open the duplicate screen, duplicate the product, then reopen the copy after a fresh app instance (new `ProviderScope`, same in-memory session).

| Recorded key (`PROVENANCE_fxp_*.json` → `results`) | Expected | 1.0 | 1.35 |
| --- | --- | --- | --- |
| `sourceHadImageBefore` | false | false | false |
| `sourceServedEqualsFixture` | true | true | true |
| `duplicateSourceImageMatchesServer` (thumbnail painted: `RawImage.image` set, bytes equal) | true | true | true |
| `copyHasImage` / `copyAvailable` | true / false | true / false | true / false |
| `copyServedEqualsSource` | true | true | true |
| `copyEditorImageMatchesSource` (editor image painted, bytes equal) | true | true | true |
| `copyEditorImageAfterFreshInstanceMatchesSource` | true | true | true |
| `sourceImageUnchanged` | true | true | true |
| Host check: distinct `object_id`, equal SHA-256 of the stored files | PASS | PASS | PASS |

Example (1.35): source object `2b3f594f…`, copy object `def7b97c…`; both 13,968 bytes, 480×480 JPEG, SHA-256 `a7a2a718…0a36`. Screenshots: `fxp_*_01_duplicate_source_image`, `03_duplicate_editor_image`, `04_copy_editor_reopened`. Teardown used the existing `fx_cleanup.sh`: the database was dropped, `~/.speedygo/parity_fx` was removed and Redis index 9 was emptied.

## 4. Backend defect found (not fixed)

`OpeningHoursRepository.replaceSchedule` (`apps/backend/src/modules/merchants/infrastructure/opening-hours.repository.ts:149–151`) clears the old intervals with `orm(tx).MerchantBranchOpeningInterval.where({ scheduleId }).delete()`. In Prisma 8 (`@prisma/orm-family-sql` 8.0.0-rc.8), `delete()` deletes **only the first matching row**; `deleteAll()` and `deleteAndCount()` delete every match. Each weekly save therefore keeps all but one previous interval and adds the new ones.

Observed live in each isolated run: the seed had 7 intervals (00:00–00:00, one per day). One UI save (Monday off) and one API restore of the original days left **18 rows**: 1 on Monday, 2 on Tuesday, 3 on each other day. That is exactly the single-row-delete prediction. The API then returns the duplicated intervals.

`opening-hours-exception.repository.ts:191–193` uses the same pattern for an exception's intervals. That was found by code inspection only: the live and e2e flows never edited an exception that already had two or more intervals. All other multi-line `.delete()` calls in the backend filter by `id`.

This pass was limited to UI and evidence, so nothing was changed. A fix would use `deleteAndCount()` at both sites, add a repository-level regression test, and require a decision on whether to check and repair existing weekly schedules in `speedygo_dev`.

## 5. Documentation hygiene

- **Matrix anchors:** rows 1 and 45 now carry an explicit `anchor` in `audit/parity/matrix/rows.json` (`shell-and-navigation-canonical`, `root-pair-merchantscreensscreenpng--merchantscreenscodehtml-arabic-rtl-add-product`). `build_matrix.py` uses it when the row's reference is not an inventory heading. The matrix was regenerated; only those two links changed. The pre-existing allowance was removed from `check_links.py`.
- **`b4_cover`:** recaptured with the final stacked logo buttons. The stale captures and panel are in `audit/parity/superseded/b4_cover_stale_2026-10-02T2047/` (with a README), outside the review evidence and not packaged.
- **Wording:** every "all passed" or "All tests passed!" summary in the matrix, batch report and batch INDEX was replaced with counts (PASS / FAIL / NOT RUN).
- **Historical attempts:** kept apart from the authoritative runs (section 6).
- **Updated:** `docs/MERCHANT_SCREEN_PARITY_MATRIX.md` (new section "Final Merchant polish pass", limitations, visual gaps, next actions, wording), `audit/parity/matrix/progress.json` (5 rows: duplicate, exceptions, weekly hours, products list, logo and cover), `audit/parity/COMPARISON_INDEX.md` (`b4_cover` row, snack-bar notes, new polish section), `audit/parity/contract_batch/CONTRACT_COMPLETION_BATCH_REPORT.md` and `INDEX.md` (follow-up pointers, resolved limitations, wording).

## 6. Failed and superseded live attempts (provenance only, not evidence)

| Folder (`audit/parity/isolated/evidence/`) | Size | Outcome | Cause and change |
| --- | --- | --- | --- |
| `fxenv_20261003T021436Z` | 1.35 | failed at the weekly restore check; the STAFF steps never ran | Revealed the backend defect (section 4). The restore check was moved to the end of the test so the remaining evidence is always captured. The test kept the same assertion |
| `fxenv_20261003T022037Z` | 1.35 | failed at STAFF back | Test harness: the duplicate route is nested under the catalogue, so the catalogue is already built underneath; the test now waits for the forbidden page to leave (the failure screenshot shows the catalogue was reached) |

Both ended with `FX_CLEANUP_OK` and 11/11 isolation checks. Their screenshots are excluded from the review evidence. Their storage checks also passed (`IMAGE_STORAGE_CHECK_fxp_t135.json` in each folder).

## 7. Changed files

Merchant app (Git repository without commits):
- `lib/core/widgets/merchant_ui.dart`: `MerchantSnackBarScope`, `MerchantSizeReporter`, `MerchantStickyBar` reports its height; `MerchantScaffold` wraps its `Scaffold` in the scope.
- `lib/features/orders/presentation/order_detail_screen.dart`: its `Scaffold` wrapped in the scope.
- `lib/features/catalog/presentation/catalog_screen.dart`: `catalogListEndPadding`; FAB measured.
- `lib/features/catalog/presentation/product_duplicate_screen.dart`: role check first; forbidden state; close/Annuler fallback.
- `lib/core/constants/app_strings.dart`: `duplicateForbiddenTitle`, `duplicateBackToCatalog`.
- New tests: `test/features/merchant_polish_geometry_test.dart`, `test/audit/parity/batch9_polish_capture_test.dart`, `integration_test/polish_fx_live_test.dart`.
- Tooling: `audit/parity/isolated/fx_run.sh` (allowlists `polish_fx_live_test`), `fx_guard_test.sh` (+1 check), `audit/parity/matrix/build_matrix.py` and `rows.json` (anchors), `audit/parity/contract_batch/check_links.py` (no allowance), `audit/parity/polish/compose_polish.py`, `fx_polish_image_check.py`, `build_polish_package.py`.

Not changed: backend (source, Prisma, migrations), Customer, Driver, Admin, workspace `docs/`.

## 8. Safety

- **Not touched:** `speedygo_dev` (11/11 isolation checks after each run: equal row counts, seven tracked orders, late order, shared branch names, no rows created or updated); Finjan (its iPhone 17 Pro was never booted; only the iPhone 16e `8DB9007A-…` was used, already booted, content size restored); Customer and Driver apps; the Keychain (memory-only sessions); existing sessions.
- **Not restarted:** the shared dev API on port 3000.
- **Isolated environment:** stopped and dropped after each run; Redis index 9 empty; `~/.speedygo/parity_fx` removed.
- No commit, push, deployment or external-service activation.
