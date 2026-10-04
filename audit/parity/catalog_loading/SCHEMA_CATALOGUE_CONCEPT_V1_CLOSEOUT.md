# Schema gap + Catalogue + Concept V1 closeout

**Status: `implementer_reviewed`** (pending your visual acceptance).  
No commit, push, deploy, Docker prune/volume delete, Customer/Driver changes, Finjan data wipe, Dar El Bahja hours repair, or prior audit ZIP modification.

---

## Phase A — `speedygo_dev` migration

### Pending migration inspected

| Item | Value |
| --- | --- |
| Migration | `apps/backend/migrations/app/20261002T1907_merchant_contract_completion_batch` |
| `migrationHash` | `24a95c1a89e39ebb31855371dd2d0f448825818cacf65dbb1cd87f99f7a08fcc` |
| Contract | `0cb52e95…` → `8f14779ee734e1c537960d26019452073e584014cbc451a6fc0caac66b910079` |
| Ops | 15 additive (incl. `products.duplicate_request_key` `varchar(64)` nullable + unique) |
| Destructive ops | None (no DROP / truncate / reset / uncontrolled rewrite) |
| Comparison | Same reviewed additive migration previously tested in the isolated environment |

No unexpected pending migration remained. Official Prisma workflow applied (`prisma db migrate` / project scripts). Column was **not** added by hand; migration history was not edited.

### Backups (outside repo)

Root: `/Users/mac/.speedygo/backups/speedygo_dev_contract_completion_20261003T131907Z`

| File | SHA-256 |
| --- | --- |
| `schema.sql` | `045fd4e34ab25c06629203bc3d9c9549be5e725e8c6a7c75de2b6eaa6119fb90` |
| `affected_tables_data.sql` | `fa90f12c00f00c3f33bd2e3abae2ec8660342c47cbaab5c6f1bfdc634b162464` |
| `pre_invariants.txt` | `d95b8f53992e6d256f77fccc590ef5196a22361889d004451e3a395b325ea373` |
| `products_describe_before.txt` | `44133a51aa98e785dc089c70afdb19d5696f7d6975bda734fc2080dfc2716582` |
| `products_rows_before.txt` | `fb98a91571692820972951e5317eb078d988e82e5a211426e4cef4944376cbd3` |

Native post-migration copy: `/Users/mac/.speedygo/backups/speedygo_dev_native_post_migration_20261003T132524Z`  
(`schema.sql` `6ec2006f…`, `affected_tables_data.sql` `c1ded803…`, `post_invariants.txt` `1251d34e…`).

### Env confirmed (apply time + closeout)

- Database exactly `speedygo_dev` on `127.0.0.1:5433`
- Redis healthy on `6381` (`PONG`)
- Backend `.env` left unchanged (`STORAGE_LOCAL_ROOT` = `~/.speedygo/dev/storage`)
- Port 3000 stopped before migrate; Dar El Bahja weekly-hours repair **not** run

### Migration result

| Check | Result |
| --- | --- |
| Apply via Prisma workflow | **PASS** |
| `prisma db verify` | **PASS** — “Database schema satisfies contract” (`8f14779e…`) |
| `products.duplicate_request_key` | **PASS** — `character varying(64)`, nullable, unique `products_duplicate_request_key_key` |
| Pre/post invariants (backup) | **PASS** — `pre_invariants.txt` == `post_invariants.txt` |
| Product row dump before/after | **PASS** — identical files in backup set |
| Other migration objects | **PASS** (verify + native post schema) |

Later OTP probes for Catalogue API increased session count (expected). Product count remains **79**.

---

## Phase B — Backend rebuild + Catalogue

| Check | Result | Evidence |
| --- | --- | --- |
| Rebuild current source | **PASS** | `nest build` → `dist/src/…` |
| `deleteAndCount()` in dist | **PASS** | `opening-hours.repository.js:109`, exception repo `:116` |
| Restart port 3000, unchanged config | **PASS** | persistent `node dist/src/main.js` + sourced `.env` + `STORAGE_LOCAL_ROOT` |
| `/health` HTTP 200 | **PASS** | closeout still 200 |
| Authenticated Catalogue API | **PASS** | `CATALOG_API_POST_MIGRATION.json`, `CATALOG_API_LIVE_RECHECK.json` — Finjan catalog/categories/products **200**; Coffee + Caps |
| Merchant app full restart | **PASS** | iPhone 16e `8DB9007A-…` |
| Finjan Catalogue UI (truthful) | **PASS** | Finjan has **1** product → shows **Caps** / Coffee; not empty; not mocked — `evidence_20261003T1517Z/40_catalogue.png` |
| Empty Catalogue state | **PASS** | Isolated Comptoir Vide — Phase D |
| Populated fixture (Dar El Bahja 8) | **NOT RUN** | Would require merchant/session switch on :3000 |
| No permanent `Chargement…` | **PASS** | Catalogue settles on real product card |
| Offline/500 + Réessayer | **PASS** | Isolated :3100 process-stop + controlled 500 stub — Phase D |
| No mocked product | **PASS** | Caps matches API |

---

## Phase C — Concept V1 live review

Evidence dir:  
`apps/merchant_app/audit/parity/bottom_nav/live_20261003T1517Z/` (+ `SHA256SUMS`)

Session: Finjan restored via OTP after `flutter run` cleared Keychain (required for Catalogue UI; not for screenshots alone).

| Scenario | 1.0 | 1.35 | Notes |
| --- | --- | --- | --- |
| Five root tabs | **PASS** | **PASS** | `live_t100_tab_*`, `live_t135_tab_*` |
| Dock visible | **PASS** | **PASS** | |
| Dock hidden after 48 px (Finjan) | **NOT RUN — insufficient live scroll extent** | **NOT RUN — insufficient live scroll extent** | Finjan Catalogue list never crossed the 48 px hide threshold; dock stayed visible. Reclassified from FAIL. Closed on isolated fixture (Phase D). |
| Reveal handle | **NOT RUN** (Finjan) | **NOT RUN** | Depends on hide; **PASS** on isolated fixture |
| Dock restored by upward scroll | **NOT RUN** (Finjan) | **NOT RUN** | Depends on hide; **PASS** on isolated fixture |
| Tab-tap slide | **PASS** | — | `live_t100_tab_slide_commandes.png` |
| Intentional horizontal swipe | **PASS** | — | `live_t100_swipe_to_catalogue.png` |
| Final list row above dock | **PASS** | — | Profil list + dock |
| Safe-area | **PASS** | **PASS** | Dock above home indicator |
| French labels @ 390 pt | **PASS** | **PASS** | Readable, centered, unclipped at 1.0 and 1.35 |
| Chip overscroll → pager | **PASS** (fixed) | **PASS** | See below |
| `nav_dock_only` ghost icons | **PASS** (artifact) | — | Harness-only; shell captures show single dock |

### Chip overscroll (known gap #1)

- **Reproduced** earlier: nested chip drag at end could change root tab (e.g. → Rapports).
- **Fix:** `MerchantShell` locks `PageView` physics while a nested horizontal scroller is dragging (`_lockPagerForNestedHorizontal` / `_onPagerScrollGate`).
- **Regression test:** `nested horizontal overscroll at either end does not change root tabs` in `test/features/merchant_bottom_nav_test.dart` — **PASS** (with intentional swipe still **PASS**).
- **Live recheck:** Orders and Rapports chip end-drags kept active tab (`recheck_orders_after_chip_overscroll.png`, `recheck_rapports_after_chip_overscroll.png`).

### `nav_dock_only` ghost icons (known gap #2)

Standalone scaffold capture (`bottomNavigationBar` + empty body) can show a faint extra icon row. **Not** observed as a double dock in the live shell. Treat as capture-harness artifact; no shell code change.

---

## Phase D — Remaining gaps closed (isolated `speedygo_parity_fx`)

Run: `fxenv_20261003T143647Z` · API `127.0.0.1:3100` · Redis index **9** · iPhone 16e · **no writes to `speedygo_dev`**.

Harness: `audit/parity/isolated/fx_gap_close.sh` + `integration_test/gap_close_fx_live_test.dart`  
Evidence: `audit/parity/isolated/evidence/fxenv_20261003T143647Z/gap_close/`  
Review ZIP: `…/gap_close/review_package_gap_close_v1.zip`

### D1 — Live dock hide / reveal (scrollable Catalogue)

Seeded 24 additive products on Comptoir Essai so the root Catalogue scrolls past 48 px.

| Check | 1.0 (`fxg_t100`) | 1.35 (`fxg_t135`) |
| --- | --- | --- |
| `catalogMaxScrollExtent` | **2839.8** px | **5329.3** px |
| Dock initially visible | **PASS** | **PASS** |
| Finger upward scroll ≥ 48 px | **PASS** (delta **140** → hide at pixels **140**) | **PASS** (delta **140** → hide at **140**) |
| Dock slides away → handle | **PASS** | **PASS** |
| Downward scroll restores | **PASS** (restore at pixels **80**) | **PASS** (at **80**) |
| Handle tap restores | **PASS** | **PASS** |
| Reach top restores | **PASS** (pixels **0**) | **PASS** (pixels **0**) |
| Tab change restores | **PASS** | **PASS** |
| No jitter on ballistic settle | **PASS** | **PASS** |
| Last row reachable above dock | **PASS** (`Plat essai 24`; lastBottom≤dockTop) | **PASS** |

Prior Finjan dock attempt: **NOT RUN — insufficient live scroll extent** (not FAIL).

### D2 — Empty Catalogue (API + UI)

Isolated merchant **Comptoir Vide** (`…001003` / branch `…002003`), zero products.

| Check | Result |
| --- | --- |
| `GET /merchant/…/products?branchId=…` HTTP **200**, `total`/`items` **0** | **PASS** (`empty_catalogue_api_fxg_t100.json`) |
| UI empty state @ 1.0 / 1.35 | **PASS** |
| Exactly one creation CTA; FAB hidden; no error; no mocked product | **PASS** |

### D3 — Unreachable API / controlled HTTP 500 / Réessayer

| Check | 1.0 | 1.35 | Label |
| --- | --- | --- | --- |
| Unreachable (API **process stopped** on :3100) | **PASS** (~3162 ms leave loading) | **PASS** (~3162 ms) | Not a native network disconnection |
| Controlled HTTP **500** stub on :3100 | **PASS** (~3157–3163 ms) | **PASS** | Deterministic stub |
| Message « Impossible de charger le catalogue. » | **PASS** | **PASS** | |
| « Réessayer » → one new request; recovers to empty Catalogue | **PASS** | **PASS** | |
| No permanent spinner / no duplicate permanent load | **PASS** | **PASS** | |

### Cleanup

| Step | Result |
| --- | --- |
| Stop :3100 | **PASS** (port free; :3000 still 200) |
| Flush Redis index 9 | **PASS** (DBSIZE 0) |
| `DROP DATABASE speedygo_parity_fx` | **PASS** |
| `speedygo_dev` isolation comparison | **PASS** (`isolation_comparison.json` — row counts, tracked orders, no fixture IDs, no created/updated since start) |
| Port 3000 / Finjan | Untouched |

---

## PASS / FAIL / NOT RUN matrix

| # | Requirement | Verdict |
| --- | --- | --- |
| A1 | Stop 3000; confirm DB/Redis/env | **PASS** |
| A2 | List/compare pending migration (additive only) | **PASS** |
| A3 | Timestamped backups + SHA-256 + fingerprints | **PASS** |
| A4 | Official Prisma migrate (no manual column) | **PASS** |
| A5 | Post-migrate schema + invariants + verify | **PASS** |
| A6 | Skip Dar El Bahja hours repair | **PASS** (skipped) |
| B1 | Rebuild backend incl. schema code + `deleteAndCount` | **PASS** |
| B2 | Restart 3000; `/health` 200 | **PASS** |
| B3 | Authenticated Catalogue API | **PASS** |
| B4 | Merchant app restart + Catalogue UI | **PASS** (Finjan Caps) |
| B5 | Empty Catalogue UI | **PASS** (isolated Comptoir Vide @ 1.0 / 1.35) |
| B6 | Offline/500 + Réessayer | **PASS** (isolated :3100 process-stop + controlled 500 stub) |
| C1 | Five tabs @ 1.0 / 1.35 | **PASS** |
| C2 | Dock hide / reveal / restore (live Finjan) | **NOT RUN — insufficient live scroll extent** |
| C2b | Dock hide / reveal / restore (isolated scrollable Catalogue) | **PASS** @ 1.0 / 1.35 |
| C3 | Tab tap + intentional swipe | **PASS** |
| C4 | Chip overscroll isolation | **PASS** (fixed + tested + live recheck) |
| C5 | `nav_dock_only` investigation | **PASS** (harness artifact) |
| C6 | Labels readable @ 390 | **PASS** |

---

## Remaining gaps

None for the three evidence items requested in this closeout. Status stays **`implementer_reviewed`** until your visual acceptance of the review package.

---

## Key paths

- Backups: `/Users/mac/.speedygo/backups/speedygo_dev_contract_completion_20261003T131907Z`
- API: `audit/parity/catalog_loading/CATALOG_API_LIVE_RECHECK.json`
- Catalogue UI: `audit/parity/catalog_loading/evidence_20261003T1517Z/`
- Concept V1 live: `audit/parity/bottom_nav/live_20261003T1517Z/`
- Gap-close evidence: `audit/parity/isolated/evidence/fxenv_20261003T143647Z/gap_close/`
- Review ZIP: `audit/parity/isolated/evidence/fxenv_20261003T143647Z/gap_close/review_package_gap_close_v1.zip`
- Shell fix: `lib/features/shell/merchant_shell.dart`
- Tests: `test/features/merchant_bottom_nav_test.dart`, `integration_test/gap_close_fx_live_test.dart`
