# Merchant screen parity — 77/77 phase closure

**Date:** 2026-10-09  
**Repository:** `apps/merchant_app`  
**Branch:** `feat/merchant-fr-ar-localization-v1`  
**Scope:** Close the last open parity reference (row 51) as `exception_approved` per explicit user deferral of external providers.

---

## Verdict

| Claim | Result |
| --- | --- |
| Merchant parity references resolved for current development phase | **77/77 = 100.0%** |
| Google Maps / Places / Geocoding implemented | **No** |
| Production map provider configured | **No** |
| Row 51 status | **`exception_approved`** (not `done`, not `user_accepted`, not `release_ready`) |
| Merchant `release_ready` | **No** |
| SpeedyGo project complete | **No** |

---

## User decision recorded (2026-10-09)

> Complete the functional development of Merchant, Driver, Admin, and Customer first. Configure and activate external APIs and providers together during the final integration phase.

Includes Maps SDK / Places / Geocoding, production SMS/OTP, FCM/APNs, payments, email, and related credentials.  
**Planned Maps direction:** Google Maps Platform — deferred, not activated.

This decision resolves **D-D7** for the **current Merchant parity phase** as an approved external-integration exception. Final Maps work remains mandatory before release readiness (see backlog).

---

## Row 51 transition

| Field | Before | After |
| --- | --- | --- |
| Reference | `store_map_location_french` | same |
| Baseline / matrix status | `partial_contract_limited` | `exception_approved` |
| `progress.json` prefix | `partial (…) ` | `exception_approved (user decision 2026-10-09: …)` |

**Implemented in phase (retained):** location picker UI, FR/AR, GPS, pan/zoom, center-pin lat/lng, branch persistence, configurable tiles, OSM local/dev fallback, map-card polish.

**Not implemented / not verified:** production provider, autocomplete, forward/reverse geocoding, production keys, live production-provider evidence.

**Still omitted (no contract):** pickup hint, owner footer.

---

## `progress.json` composition (validated)

77 keys total; **0 open** (`partial` count = 0).

| Prefix | Count |
| --- | --- |
| `done` | 63 |
| `exception_approved` | 9 |
| `not_applicable_duplicate` | 2 |
| `no_change` (duplicate rows) | 3 |
| `partial` | 0 |

Closed/resolved for parity-phase counting = **77**.  
This is **not** a claim that all 77 references are fully product-implemented or visually `user_accepted`.

---

## Deferred functionality (Maps)

See `docs/MERCHANT_MAPS_FINAL_INTEGRATION_BACKLOG.md` for the durable checklist (Cloud project, billing, Maps SDK iOS/Android, Places, Geocoding, key restrictions, autocomplete, FR/AR, Algeria bias, quotas, privacy/attribution, live tests, acceptance).

---

## Tracker files updated

- `audit/parity/matrix/progress.json`
- `audit/parity/matrix/MERCHANT_SCREEN_PARITY_MATRIX.md`
- `docs/MERCHANT_SCREEN_PARITY_MATRIX.md`
- `docs/MERCHANT_MAPS_FINAL_INTEGRATION_BACKLOG.md` (new)
- `docs/MERCHANT_PARITY_77_OF_77_CLOSE_REPORT_2026-10-09.md` (this file)

---

## Preserved elsewhere

- Row 23 live handoff evidence and `implementer_reviewed` status unchanged.
- Bottom Navigation Concept V1 limited `user_accepted` scope unchanged.
- Untracked review ZIP left untouched.

---

## Confirmations

- Row 51 is an **approved exception**, not an implemented Maps verification.
- Merchant parity tracker is **77/77** for the current phase.
- Google Maps remains **unconfigured**.
- Merchant app is **not** declared release-ready.
- The SpeedyGo project is **not** declared complete.
- No Merchant production source, Backend, migration, provider activation, API key, merge to `main`, or force-push in this documentation batch.
