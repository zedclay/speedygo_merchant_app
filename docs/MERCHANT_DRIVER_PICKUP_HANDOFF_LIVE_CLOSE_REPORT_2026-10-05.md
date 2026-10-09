# Merchant–Driver pickup handoff — live close report

**Date:** 2026-10-05 (live UI closed 2026-10-09)
**Scope:** Sequential live Merchant→Driver pickup handoff on isolated FX; close Merchant parity **row 23** only if every live gate passes.
**Git actions:** none (no commit, push, merge, rewrite, migrations on shared DBs, or provider activation).

| App | Branch | Verified SHA |
| --- | --- | --- |
| Backend | `feat/driver-assignment-version-contract` | `3131c4ec0e0d3295f1eeedf5e13f3cbdeb3c02b4` |
| Driver | `feat/driver-current-delivery-pickup-handoff-v1` | `e994e7aa91652b9a7c16cba306c29146217f2fb9` |
| Merchant | `feat/merchant-fr-ar-localization-v1` | `9a0bc393c6833b9d8d0a617f47aef38471dfca12` |

---

## Verdict

**Row 23 = implementer_reviewed. Merchant parity = 76/77 = 98.7%.**
Only **row 51** remains open. Not `user_accepted` / not `release_ready`.

Live run tag: `fxlive_merchant_driver_20261009T161443Z`
Evidence: `apps/merchant_app/audit/parity/captures/merchant_driver_live_2026-10-09/`
Manifest: `MANIFEST.json` (`allGatesPass: true`)

---

## Gate matrix

| Gate | Result | Evidence |
| --- | --- | --- |
| Backend `assignmentVersion` tests (prior) | **PASS** | Verified SHA |
| Driver FR/AR + analyze + tests | **PASS** | `flutter analyze` (1 info); `flutter test` **+29** after `generate: true` |
| Merchant full suite (prior) | **PASS** | ~743 at verified SHA |
| Isolated env `speedygo_parity_fx` + API `:3100` / Redis 9 | **PASS** | run `fxenv_20261005T125234Z` |
| Authenticated handoff API e2e | **PASS 24/24** | prior `driver_handoff` evidence |
| Live Merchant pickup-code UI | **PASS** | `screens/fxlive_merchant_pickup_code.png` |
| Live Driver code-entry + confirm UI | **PASS** | `screens/fxlive_driver_code_entry.png`, `fxlive_driver_picked_up.png` |
| Backend post-confirm (V1–V8) | **PASS 8/8** | `backend_verify.json` — `PICKED_UP`, `pickedUpAt`, handoff `CONSUMED`, one `ORDER_PICKED_UP`, assignment preserved, no COD/earnings/COMPLETED |
| Live Merchant post-confirm recheck | **PASS** | `screens/fxlive_merchant_post_confirm.png` — assigned-driver status « Récupérée » (handoff chrome is AT_PICKUP-only by contract) |
| Fixture cleanup | **PASS** | scoped order/delivery/assignment + secrets removed; no FLUSHDB |
| Close row 23 → 76/77 | **PASS** | implementer_reviewed |
| Row 51 | **Unchanged / open** | Out of scope |

---

## Storage / simulator preflight (batch)

| Check | Result |
| --- | --- |
| Disk (start of successful close run) | ≥3 GiB free (min floor temporarily 3 after reclaim); ended ~1.6 GiB mid-run, recovered to ~4.1 GiB |
| Simulator | Existing **iPhone 16e** `8DB9007A-B816-4EC5-86ED-C627AC60F2C5` (iOS 26.0) — sequential reuse |
| Bundles | Distinct: `com.speedygo.speedygoMerchantApp` / `com.speedygo.speedygoDriverApp` |
| Isolation | DB `speedygo_parity_fx`, API `3100`, Redis index **9** (not `speedygo_dev` / 3000 / 15) |
| Migrations / providers | None applied / none activated |

---

## Fixture

- Identifier: `fxlive_merchant_driver_20261009T161443Z`
- Order suffix: `fcac9d7a` · Delivery suffix: `ed581296`
- Assignment: `0d00f0f0-fa00-7000-8000-64ce3387d158` · version `1`
- Seed: disposable Merchant + Driver, delivery `AT_PICKUP`, pending handoff, server 4-digit code (secrets file chmod 600 under `~/.speedygo/parity_fx/live_handoff/`; deleted after cleanup)
- Cleanup: scoped SQL + secrets unlink — **PASS**

---

## Live UI classification

Sequential single-simulator integration_test against real production UI + real Dio clients + real OTP session on `:3100`. Repository mocks disabled (only in-memory session/push stores for test hermeticity). Screenshots via `simctl io screenshot` correlated with UI marker file.

---

## Tracker updates

- `apps/merchant_app/audit/parity/matrix/progress.json` — row 23 → done / implementer_reviewed
- `apps/merchant_app/audit/parity/matrix/MERCHANT_SCREEN_PARITY_MATRIX.md` — 76/77; only row 51 open
- `apps/merchant_app/docs/MERCHANT_SCREEN_PARITY_MATRIX.md` — same
- This report

---

## Harness added (test-only; uncommitted)

- `apps/merchant_app/audit/parity/isolated/fx_live_handoff.sh` (+ setup/verify/cleanup.py)
- `apps/merchant_app/integration_test/live_pickup_handoff_merchant_test.dart`
- `apps/driver_app/integration_test/live_pickup_handoff_driver_test.dart`
- Driver `pubspec.yaml`: `integration_test` + `flutter: generate: true` (required by existing `l10n.yaml`); iOS project auto-touched by Flutter tooling during first driver integration build

---

## Confirmation

- No commit / push / force-push / merge.
- No migrations; no `.env` committed; FX only; no broad DB/Redis wipe.
- Row 23 closed as **implementer_reviewed** only.
- Row 51 untouched / remains open.
- Final parity: **76/77 = 98.7%**.
