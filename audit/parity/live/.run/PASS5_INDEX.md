# Merchant parity: fifth pass review package (2026-10-02, updated after provisional review)

**Status: `implementer_reviewed`.** The pass was reviewed provisionally from two screenshots; this is not full visual acceptance.
- No external service was activated.
- Nothing was committed, pushed or deployed.
- Earlier packages (`live2_2026-10-01/` and its ZIP) are unchanged.

**Outcome:**
- **Fifth pass:** the five scoped UI corrections are in place, and the two live-found defects are fixed with regression tests.
- **Live verification:** the eight changed rows were verified live at 1.0 and 1.35, including list-card accept and reject and the branch-name save, reopen and restore.
- **Follow-up corrections:** the update-time sheet now shows the compact order reference (with full reveal and copy) and dates any estimate on another Africa/Algiers day. Both are verified by focused tests, a mocked capture and a read-only live capture.
- **Retained orders:** the seven fixture orders are documented with their effects and kept, per the established policy. An isolated-fixture strategy is proposed (section 6).

Each section separates automated, mocked, live and visual results.

---

## 1. Automated results

| Check | Result | File |
| --- | --- | --- |
| Full suite (fifth pass, before the follow-up) | 525 passed, 1 skipped, 0 failed | `tests_and_cleanup/pass5_suite_summary.txt` |
| Analyzer (fifth pass) | 0 errors, 1 pre-existing warning, 64 style infos | same |
| Focused tests (follow-up, 8 files) | 129 passed, 0 failed | `tests_and_cleanup/pass5_followup_tests.txt` |
| Analyzer on changed files (follow-up) | 0 errors, 0 warnings, 1 pre-existing info | same |
| Regression tests for the two live defects | Each failed before its fix and passes after | `pass5_suite_summary.txt` |
| Follow-up tests (fixed clock) | Overdue previous-day estimate; midnight crossing 23:55 → 00:05 dated 03/10 while UTC is still 02/10; yesterday dated just after midnight; compact reference reveal and copy | `pass5_followup_tests.txt` |

## 2. Evidence for the eight changed rows

The table below lists the live panels at 1.0 and 1.35 (iPhone 16e) for each row; each composite image holds both sizes. Live panels are single real viewports; mocked panels are widget captures with fake data.

| Row | Reference | Live (`comparisons/live/`) | Mocked (`comparisons/mocked/`) | Accurate note |
| --- | --- | --- | --- | --- |
| 3 | `merchant_reports_overview_french` | `live4_b5_overview` | none (unchanged this pass) | KPIs stack at 1.35. Annulations 0 at 1.0 and 2 at 1.35 because fixture rejects happened in between. No completed sales in the period. |
| 6 | `popular_products_french` | `live4_b5_top_products` | `b5_top_products` | Captured live only in its empty state (no ranked rows). OWNER/MANAGER editor navigation (D-A6) is automated and mocked evidence (`b5_top_products`, `merchant_sales_reports_test.dart` "top-product navigation by role"), not a live interaction. |
| 7 | `active_orders_list_french` | `live4_b2_orders`; fixture writes `fx_fx_alert`, `fx_fx_incoming`, `fx_fx_accept_sheet`, `fx_fx_after_accept`, `fx_fx_reject_sheet`, `fx_fx_after_reject` | `b2_orders_active_incoming` | The walk had no incoming orders. Incoming cards come from tracked fixtures: the name stacks above the amount at both sizes. Accept goes through the sheet, then a snackbar. Reject opens through the button's semantics action, then the reason, then a snackbar. The 1.35 incoming panel is scrolled to the second card. |
| 18 | `delayed_order_french` (+ `mise_jour_du_temps_de_pr_paration`) | `live4_b2_order_detail`, `_end`; `live5_b2_order_detail`, `live5_b2_update_sheet`, `live5_b2_update_sheet_reason` | `b2_delayed_detail`, `b2_delayed_update_flow_t100` / `_t135`, `b2_delayed_update_days`, `b2_detail_preparing_late(_days)`, `b2_update_sheet(_reason)` | PARTIAL, different composition (delivery impact needs a contract; −/+ editor not built by decision). The sheet shows "COMMANDE sgo_01a0e8…a64cdc" and "le 28/09 à 17:45" → 17:55 "le 28/09". At 1.35 the comparison card spans the fold. The sheet was never confirmed. The `live4` sheet images are superseded (`comparisons/live/superseded/`). |
| 31 | `d_tails_de_la_cat_gorie_standardis` | `live4_b3_category`, `live4_b3_category_end` | `b3_category_detail`, `_end` | Olive switches and a radius-12 FAB. At 1.35 the FAB covers the last switch in the top view; the end view clears it. |
| 46 | `store_profile_french` | `live4_b4_profile` | `b4_profile` | "Informations générales" opens the editor (row 47: `live4_b4_general`, `fx_fx_branch_saved`, `fx_fx_branch_reopened`). |
| 59 | `order_notification_settings_french` | `live4_b6_notification_settings` | none | Title wraps at 1.35. The permission banner shows the real (not yet granted) state. |
| 63 | `merchant_support_french` | `live4_b6_support` | none | Topic tiles wrap without clipping. No tickets exist; FAQ and subject need a contract. |

Row 16 (`mise_jour_du_temps_de_pr_paration`, the update-time sheet) is now also live compared through the `live5` images.

## 3. Mocked comparisons (`comparisons/mocked/`)

The fifth-pass set, plus `b2_delayed_update_days`: the update sheet opened from a previous-day late order, showing "le 30/09 à 18:14" with "le 30/09" under the current and proposed times. The mock's reference is short (`sgo_o1`), so it is shown unchanged. The compact form appears in the live images and is asserted in the tests.

## 4. Live provenance

- **Device:** iPhone 16e simulator `8DB9007A-…`, one simulator at a time.
- **Bundle:** `com.speedygo.speedygoMerchantApp`, confirmed before each run's first capture (`provenance/BUNDLE_*.txt`).
- **Backend:** local dev API on 3000, Postgres on 5433, Redis on 6381.
- **Sessions:** a fresh OTP session per run, app stores held in memory, Keychain never touched. Each session was revoked by the app. The run's sessions and devices were then deleted by exact ID (`tests_and_cleanup/cleanup_*`). Pre-existing active sessions are unchanged (merchant 159, customer 61).
- **Runs:**

| Run | What | Result |
| --- | --- | --- |
| `live4_t100`, `live4_t135` | Read-only walk, 13 screens each | exit 0 |
| `fx_t100` (after 3 failed attempts, kept in `evidence/failed_attempts/`), `fx_t135` | Accept/reject on tracked orders; branch-name save, reopen and restore | exit 0 |
| `live5_t100`, `live5_t135` | Follow-up: late detail and update sheet, read-only | exit 0 |

## 5. Visual review (implementer only)

- All live panels were inspected by the implementer: no clipping, overflow or error screens.
- Known compositions are noted on each image: the 1.35 FAB overlap in the top view, the comparison card spanning the fold at 1.35, and the scrolled incoming list.
- **Not visual acceptance.**

## 6. Retained fixture orders

Full table and analysis: matrix, "Fifth pass follow-up", "Retained fixture orders".

- **The orders:** 7 COD orders on Dar El Bahja, created through the real checkout by the test customer +213550000099. They are financial records with immutable snapshots.
  - 4 CONFIRMED/ACCEPTED, past their estimate: `01a0fd2a-2e34-…`, `01a0fd32-688b-…`, `01a0fd37-f350-…`, `01a0fd63-3d79-…`.
  - 3 CANCELLED/PENDING_ACCEPTANCE, the documented reject state: `01a0fd2a-2f23-…`, `01a0fd37-f447-…`, `01a0fd63-3e5c-…`.
  - Full IDs: `provenance/guard_and_fixtures/fixture_orders_fx_*.json`.
- **Reports:** sales, orders, commission, average basket and top products count only COMPLETED orders, so these add nothing. Cancellations rise by 3 on 02/10 (today, this week, this month).
- **Alerts:** one incoming alert per order at creation. None can fire again: accepted orders are no longer incoming, and rejected ones are excluded by the app (`isStillIncoming`, the host's CANCELLED check) and by the backend push worker. Push was never sent (`SKIPPED_NOT_CONFIGURED`). 7 unread entries remain in the merchant inbox.
- **Lists and actions:** the accepted orders show under En cours › Acceptées (4 of 28) as late. The rejected ones show only under Historique › Annulées. Existing evidence:
  - `order_ops_test` "reject is not offered after acceptance": CANCELLED + PENDING_ACCEPTANCE offers no actions;
  - `order_list_visual_corrections_test`: filters send order status and fulfilment;
  - live "Nouveaux (0)" after the rejects.
- **Matching:** no delivery exists. Matching starts only when an order is marked ready, so no driver offers exist and the Driver app is unaffected.
- **Cleanup:** none for orders. The established policy keeps orders. All 16 tables that reference `orders` restrict deletion, the snapshots are immutable, and closing an accepted order would need a status change made only to clean screenshots.
- **Still active:** 4 accepted orders with PENDING COD payments, 7 merchant inbox entries, 7 customer notifications, and +3 report cancellations.
- **Proposal (not implemented, needs approval):** run write fixtures against a disposable database (`speedygo_parity_fx`) with a second API on port 3100, selected in the app with `--dart-define=API_BASE_URL`. Drop the database after the run, so `speedygo_dev` never receives fixture orders. The lighter alternative is a dedicated fixture merchant, branch and customer in `speedygo_dev`.

## 7. NOT RUN (unchanged by decision)

- The rejected and correction registration captures at normal size.
- Three optional live captures: the mark-ready confirmation, the CONFIRMED detail and the store map.

## 8. Remaining gaps

- **Row 18:** PARTIAL (delivery impact needs a contract; −/+ editor not built by decision; different composition).
- **Rows 7, 47 and 63:** contract gaps (list search and chips; Arabic name, description and preview; FAQ and subject).
- **Rows 3 and 6:** Top products was captured live only in its empty state. OWNER/MANAGER editor navigation is automated and mocked evidence, not a live interaction.
- **Variants/extras persistence:** unchanged. Sequential saves are not atomic; a future draft/save design must keep unsaved edits after a partial failure.
- **Fixture isolation:** proposal pending approval (section 6).

## Contents

- `INDEX.md`, `MERCHANT_SCREEN_PARITY_MATRIX.md`, `COMPARISON_INDEX.md`
- `comparisons/mocked/`, `comparisons/live/` (with `superseded/`), `comparisons/fixture_writes/`
- `evidence/failed_attempts/`
- `provenance/` and `provenance/guard_and_fixtures/`
- `tests_and_cleanup/`
