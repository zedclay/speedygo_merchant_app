# Isolated Merchant write-test environment — report

Status: `implementer_reviewed`, pending visual acceptance. Nothing here is user-accepted.
Date: 2026-10-02 (Africa/Algiers 18:42–19:00). Device: iPhone 16e `8DB9007A-…` (already booted; left booted). No external service, commit, push or deployment.

## Result

| # | Requirement | Result | Evidence |
| --- | --- | --- | --- |
| 1 | Reusable disposable environment: `speedygo_parity_fx`, API on 3100, Redis index 9 + `parityfx` prefixes, `API_BASE_URL` define, providers disabled | PASS | `fx_start.sh`, `evidence/fxenv_20261002T174558Z/environment.json` |
| 2 | Guards: localhost/127.0.0.1 + port 5433 only, exact name, shared and production-like names refused, no reset/migrate/truncate/drop of a shared DB, disk preflight first | PASS | `fx_guard.py`, `fx_guard_test.sh` (77 pass, 0 fail) |
| 3 | Existing migrations + explicit fixture identities only; no test hooks in production code | PASS | `migrate.log` (exit 0), `verify.log` ("Database schema satisfies contract"), `fx_seed.sql`, `seed.log` |
| 4a | Accept and reject an incoming order | PASS (1.0 and 1.35) | `comparisons/accept_sheet.png`, `after_accept.png`, `reject_sheet.png`, `after_reject.png` |
| 4b | Save and reopen the branch name | PASS (1.0 and 1.35) | `comparisons/branch_saved.png`, `branch_reopened.png` |
| 4c | Populated Reports and Top produits | PASS (1.0 and 1.35) | `comparisons/reports.png`, `reports_top_section.png`, `top_products_owner.png` |
| 4d | OWNER/MANAGER product-editor navigation, live | PASS (1.0 and 1.35) | `comparisons/editor_owner.png`, `editor_manager.png`; provenance `topRowOpensEditor_OWNER/MANAGER: true`, `ownerOverviewRowOpensEditor: true` |
| 4e | STAFF receives no editor route | PASS (1.0 and 1.35) | `comparisons/top_products_staff.png`, `reports_staff.png`; provenance `topChevrons_STAFF: 0`, `topRowOpensEditor_STAFF: false`, `staffOverviewRowOpensEditor: false` |
| 4f | No rows, notifications, sessions, reports or Redis jobs in `speedygo_dev` | PASS | `isolation_comparison.json`, `dev_redis_job_scan.json` |
| 5 | Cleanup: evidence first, API and workers stopped, only this run's processes, only index 9 flushed, only `speedygo_parity_fx` dropped, dev counts unchanged | PASS | `cleanup.log` (`FX_CLEANUP_OK`) |
| 6 | Seven tracked `speedygo_dev` orders preserved exactly | PASS | `isolation_comparison.json` ("seven tracked orders unchanged") |
| — | Content sizes 1.0 (`large`) and 1.35 (`extra-extra-extra-large`) | PASS | `screens/fxi_t100_*`, `screens/fxi_t135_*` (16 steps each) |
| — | Simulator shutdown by cleanup | NOT RUN (by design) | The 16e was already booted, so the run did not boot it and cleanup left it running |

## Files (`apps/merchant_app/audit/parity/isolated/`)

| File | Role |
| --- | --- |
| `fx_common.sh` | Fixed targets and guarded helpers (`fx_psql` with a server-side identity check, read-only `fx_psql_dev_ro`, `fx_redis` on index 9 only). Refuses override variables. |
| `fx_guard.py` | URL and name guards; derives the isolated URLs from `apps/backend/.env` without printing them. |
| `fx_start.sh` | Preflight → guards → baseline snapshot → `CREATE DATABASE` + marker comment → `prisma db migrate` → seed → private compile → API on 3100 → connection-isolation proof. |
| `fx_seed.sql` | Explicit identities in namespace `0d00f0f0-fa00-7000-8000-*`. |
| `fx_create_incoming.py` | Places COD orders through the real cart and checkout on 3100 as the fixture customer. |
| `fx_run.sh` | One live run: simulator guard (16e only, Finjan refused), two new incoming orders, `flutter test` with `API_BASE_URL=http://127.0.0.1:3100/api/v1`, host screenshots, isolation snapshot. |
| `fx_cleanup.sh` | Evidence → stop API → this run's processes → flush index 9 → guarded `DROP DATABASE` → comparison → remove `~/.speedygo/parity_fx`. |
| `fx_snapshot.sh` | Read-only snapshot of `speedygo_dev`, Redis 0/9/15 and the isolated database. |
| `fx_guard_test.sh` | Guard tests (no real database or Redis touched). |
| `compose_fx.py` | 1.0 / 1.35 side-by-side panels. |
| `../../../integration_test/parity_isolated_fx_live_test.dart` | The live test; fails at once unless `AppConstants.apiBaseUrl` is the 3100 URL. |

Usage:

```bash
cd apps/merchant_app/audit/parity/isolated
bash fx_guard_test.sh
bash fx_start.sh
bash fx_run.sh 8DB9007A-B816-4EC5-86ED-C627AC60F2C5 fxi_t100 large
bash fx_run.sh 8DB9007A-B816-4EC5-86ED-C627AC60F2C5 fxi_t135 extra-extra-extra-large
python3 compose_fx.py <run-id>
bash fx_cleanup.sh
```

The seed refuses to run before 01:00 Algiers time (report orders must fall "today").

## Environment

- **PostgreSQL:** native Homebrew 17 on 5433. `speedygo_parity_fx` is created from the maintenance database and marked `COMMENT ON DATABASE … 'speedygo-parity-fx disposable run=<id>'`. Seed and drop both require that marker. The 12 app migrations plus the PostGIS extension migration are applied by `prisma db migrate --db <isolated URL>`.
- **API:** `tsc -p tsconfig.build.json --outDir ~/.speedygo/parity_fx/dist`, so the backend repo's `dist/` and the dev watcher are untouched. Started with `env -i`, an explicit variable file (0600, ephemeral JWT/OTP/webhook secrets) and its own session (`setsid`). Before start, every key name in the dev `.env` must be set explicitly, so `ConfigModule` cannot fill any value from the shared file.
- **Redis:** `redis://localhost:6381/9`. Prefixes `auth:parityfx:`, `matching:parityfx:`, `bull:matching:parityfx`, `tracking:parityfx:`, `socket.io:tracking:parityfx`, `storage:parityfx:`. Index 0 (dev API) and 15 (backend e2e) are refused.
- **Providers:** `PUSH_PROVIDER=disabled` (every push log `SKIPPED_NOT_CONFIGURED`; `IN_APP/SENT` is the in-app inbox row), `PAYMENT_PROVIDER=test` with an empty Chargily key, empty Google Maps key, empty S3 and FCM settings, local storage in `~/.speedygo/parity_fx/storage`. Console OTP goes to `~/.speedygo/parity_fx/otp/otp-last`, never the dev OTP file. The OTP limits are the `.env.example` defaults (5 per identifier, 20 per IP per hour). Recovery and cleanup loops run every 24 h. The Merchant app is built without Firebase or Maps defines and uses in-memory push registration.
- **App:** `--dart-define=API_BASE_URL=http://127.0.0.1:3100/api/v1` (existing define), plus `FX_OTP_FILE`, `FX_EVIDENCE_DIR`, `FX_ACCEPT_ORDER_ID` and `FX_REJECT_ORDER_ID` for the test only. Session, context, launch, approval and push stores are in memory (Keychain never read or written). Each role signs out through the app's logout. All 10 sessions lived only in the isolated database and were revoked.

## Fixture identities (`fx_seed.sql`)

| Identity | Value |
| --- | --- |
| Merchant / branch | "Comptoir Essai" `…001001` / `…002001`, ACTIVE, verified, open 24 h |
| OWNER / MANAGER / STAFF | +213550009101 / 102 / 103 (`…000101–103`) |
| Customer | +213550009111, "Client Essai Isolé", one address in the zone |
| Zone / pricing / commission | one MultiPolygon zone; all-day fee 20000, driver 15000; GLOBAL_DEFAULT 700 bps |
| Commission rule owner | non-login admin profile + role (required by the commission-rule foreign key) |
| Catalogue | 3 categories, 6 products |
| Report orders | 5 COMPLETED today: gross 740000, commission 51800, net 688200 (Reports shows 7 400 / −518 / 6 882 DZD, basket 1 480 DZD) |
| Incoming orders | not seeded: 2 per run placed through the real checkout (IDs in `incoming_orders_<prefix>.json`) |

## Isolation evidence (run `fxenv_20261002T174558Z`)

- **API connections:** both Postgres sockets of the API PID map to `speedygo_parity_fx` in `pg_stat_activity`. Redis clients on index 9 went from 0 to 9 at API start, while index 0 stayed at 10 clients. Redis runs in Docker, so client addresses are NATed; the per-index client count is the proof. No key on index 9 lacked an isolated prefix.
- **Reports cancellations:** 2 at 1.0 and 3 at 1.35. Each run rejects one incoming order, and the first 1.0 attempt had already rejected one, all on the same Algiers day.
- **Isolated database at the end:** 11 orders (5 COMPLETED, 3 CONFIRMED/ACCEPTED, 3 CANCELLED/PENDING_ACCEPTANCE), 39 notifications, 0 deliveries, 10 sessions (0 active), branch name restored to "Comptoir Essai".
- **`speedygo_dev` before vs after cleanup (`isolation_comparison.json`):** every row count equal (accounts, sessions 243, devices, orders 76, status events, cancellations, estimate revisions, snapshots, payments, notifications 163, delivery logs, deliveries, assignments, ledger, carts, audit logs, merchants, branches, products). The seven tracked orders, the late order `01a0e8dc-…` (CONFIRMED/ACCEPTED, version 1, 28/09 17:45), the Dar El Bahja and Atelier Sucré names, and the Dar El Bahja order states (47 / 1 / 28) are all equal. Zero fixture identities, and zero rows created or updated since the start.
- **Sessions (read-only, after cleanup):** Dar El Bahja owner 159 active, PrepTime customer 61 active, 243 in total, as documented.
- **Redis:** 0 isolated keys on indexes 0 and 15. No hash on index 0 (13 scanned) or 15 (4 scanned) references any of the 65 isolated row IDs (orders, notifications, sessions, deliveries, accounts). The dev BullMQ job counters are reported as INFO only: a control measurement with no isolated API running showed the shared dev API advancing them by itself (about 1 notification job and 6 matching jobs per minute).
- **Cleanup:** API PID 3999 stopped after its identity was checked (binary path and 3100 listener); port 3100 free; 0 Redis clients left on index 9; 22 keys flushed, all isolated; `speedygo_parity_fx` dropped after the name, host/port and marker checks; `~/.speedygo/parity_fx` removed. Remaining databases: `postgres`, `speedygo_dev`, `speedygo_test`, `template0`, `template1`.

## Attempts kept as evidence

1. **`fxenv_20261002T174228Z`, start failed.** The API booted and wrote only isolated keys, but ended with the calling shell's process group. The Redis check also tried to match host ports to Redis clients, which Docker NAT makes impossible. Fixed: the API now runs in its own session (`setsid`), and Redis isolation is proven by per-index client counts. That attempt's cleanup dropped the database and flushed 14 isolated keys. Its comparison shows two FAILs caused by the tooling, not by any write to `speedygo_dev`: no start timestamp had been written yet, so "created since" counted from 1970; and the dev job counters drift by themselves. Its row counts, tracked orders and branch names were all equal. Fixed: the start time is written first; counters became INFO and are replaced by the job-payload scan.
2. **`fxi_t100_attempt1`, test failed at Reports.** The top-products section is built lazily below the fold of a `ListView`, so the test now scrolls to it. Accept/reject and the branch name had passed. Files are kept with the `attempt1` suffix.
3. The cleanup script once stopped silently: the foreign-key filter returned non-zero under `pipefail`. Fixed before any data was removed.

## Not changed

- No production application code changed (backend or Merchant `lib/`). The only new Dart file is the integration test.
- Nothing in `speedygo_dev` was written. Shared dev Redis keys were not cleared, the dev OTP limits were not changed, and the dev API (pid 35888 on 3000) kept running.
- Finjan, the Dar El Bahja shared data, Customer, Driver, Keychain, existing sessions and earlier review packages are untouched.
