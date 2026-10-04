# Merchant Daily Summary + Delayed-Order Contract Close — rows 5 & 18

**Environment:** `fxenv_20261004T014647Z` · `speedygo_parity_fx` · API `:3100` · Redis index **9**  
**Device:** iPhone 16e (`8DB9007A-B816-4EC5-86ED-C627AC60F2C5`) · text scales **large (1.0)** and **extra-extra-extra-large (1.35)**  
**Orchestrators:** `fx_daily_delay_e2e.sh` · `fx_daily_delay_live.sh` · `parity_daily_delay_fx_live_test.dart`  
**Acceptance:** `implementer_reviewed` (neither row `user_accepted`; Bottom Navigation V1 remains `user_accepted`)

## Result matrix

| # | Check | Result |
| --- | --- | --- |
| 1 | Domain / ERD / API docs (`MERCHANT_DAILY_SUMMARY`, `MERCHANT_DELIVERY_IMPACT`) | **PASS** |
| 2 | Additive Prisma migration `20261004T0137_merchant_daily_summary_delayed_order_contracts` (`order_cancellations.reason_code`) | **PASS** |
| 3 | Backend unit tests (Africa/Algiers bounds, prep, cancel, finance visibility, delivery impact) | **PASS** (33) |
| 4 | Isolated HTTP e2e D0–D11 | **PASS** (12/12) |
| 5 | Flutter widget/unit tests (empty, populated, missing money, STAFF dash when null, error/retry, delivery-impact copy) | **PASS** (10) |
| 6 | Live Daily Summary populated / empty / cold / STAFF | **PASS** |
| 7 | Live delayed order before/after estimate update + delivery impact | **PASS** |
| 8 | Stitch side-by-side mocked + live (1.0 \| 1.35) | **PASS** |
| 9 | Matrix → 71/77 closed (92.2%), 6 unfinished | **PASS** |
| 10 | `speedygo_dev` unchanged; Redis 9 + `speedygo_parity_fx` cleaned | see cleanup |
| 11 | Firebase / Maps / Chargily / SMS / commit / push / prod migrate | **NOT RUN** (refused by brief) |
| 12 | Customer / Driver / Admin UI changes | **NOT RUN** (out of scope) |

## Contract summary

### Daily summary — `GET /api/v1/merchant/:merchantId/reports/daily-summary`

- Window: Africa/Algiers local midnight inclusive → next midnight exclusive; `date=YYYY-MM-DD` (default today; future refused).
- Metrics from persisted data only: created / completed / cancelled / active; status breakdown; completed GMS + average basket when snapshots exist; actual prep = `confirmedAt` → `ORDER_READY` (invalid durations excluded; missing averages null, never 0); on-time vs late vs `estimatedReadyAt`; cancellation `reasonCode` counts (`UNSET` → « Non renseignée »).
- Finance: OWNER/MANAGER `GRANTED`; STAFF `ROLE_RESTRICTED` (no commission/net); GMS allowed for STAFF per shared sales-report policy.
- Merchant + branch isolation enforced server-side.

### Delayed order / delivery impact

- Detail exposes `delayMinutes`, immutable `originalEstimatedReadyAt`, latest prep revision, and `deliveryImpact.state` ∈ `NOT_APPLICABLE` \| `DELIVERY_TIMING_UNAVAILABLE` \| `MAY_DELAY_DRIVER_ASSIGNMENT` \| `MAY_DELAY_PICKUP` \| `DRIVER_WAITING` \| `RESOLVED`.
- No invented driver ETA or delivery-delay minutes.
- Prep update, optimistic concurrency, matching rules unchanged.

## Automated test counts

| Suite | Count | Result |
| --- | --- | --- |
| Backend Jest `merchant-daily-summary` + `merchant-delivery-impact` | 33 | PASS |
| Flutter `merchant_daily_summary_test.dart` | 10 | PASS |
| Isolated API e2e `fx_daily_delay_e2e` | 12 | PASS |
| Live integration (×2 sizes) | 2 runs | PASS |

## Evidence

| Kind | Location |
| --- | --- |
| API e2e | `daily_delay/RESULTS.json`, `e2e.log` |
| Live screens | `daily_delay_visual/screens/fxdd_t{100,135}_*.png` |
| Provenance | `daily_delay_visual/PROVENANCE_fxdd_t*.json` |
| Mocked Stitch | `audit/parity/comparisons/b5_daily_summary.png`, `b2_detail_preparing_late*.png` |
| Live Stitch | `audit/parity/comparisons/live/fxdd_*.png` |
| Matrix | `audit/parity/matrix/progress.json`, `docs/MERCHANT_SCREEN_PARITY_MATRIX.md`, `COMPARISON_INDEX.md` |

## Remaining visual / contract differences

- Stitch daily-summary prep “target” line omitted (no server target).
- Stitch −/+ prep editor omitted (presets kept by prior decision).
- STAFF still sees merchandise sales (GMS) — same as sales overview shared policy; commission/net never returned.
- Avatar / decorative Stitch chrome not inventing owner identity.

## Parity counts

**58 done · 2 partial · 2 blocked_contract · 2 deferred · 8 accepted exceptions · 5 duplicates → 71/77 closed (92.2%).**
