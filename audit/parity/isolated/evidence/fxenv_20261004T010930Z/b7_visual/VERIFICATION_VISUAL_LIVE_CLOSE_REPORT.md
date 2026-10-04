# Verification visual/live close — rows 71–74, 76, 77

**Environment:** `fxenv_20261004T010930Z` · `speedygo_parity_fx` · API `:3100` · Redis index **9**  
**Device:** iPhone 16e (`8DB9007A-B816-4EC5-86ED-C627AC60F2C5`) · text scales **large (1.0)** and **extra-extra-extra-large (1.35)**  
**Orchestrator:** `audit/parity/isolated/fx_b7_live.sh` + `integration_test/parity_b7_fx_live_capture_test.dart`  
**Acceptance:** `implementer_reviewed` (Bottom Navigation V1 remains `user_accepted`)

## Result table

| # | Check | Result |
| --- | --- | --- |
| 1 | Registration with server-recorded consent (consent on review submit) | **PASS** |
| 2 | Document upload (IDENTITY + REGISTRATION fixture picker) | **PASS** |
| 3 | Review before submission (legal versions from API, both consents) | **PASS** |
| 4 | Pending with real dossier reference (`sgm_…`) | **PASS** |
| 5 | Structured APPLICATION + DOCUMENT rejection reasons (admin API) | **PASS** |
| 6 | Correction of rejected evidence (rebind BUSINESS_IDENTITY) | **PASS** |
| 7 | Resubmission; DOCUMENT issue cleared; APPLICATION stays open truthfully; attempt 2 | **PASS** |
| 8 | Cold relaunch persistence (pending after submit; pending after resubmit) | **PASS** |
| 9 | Sticky footer / scroll / long reference / text 1.35 layout | **PASS** |
| 10 | Stitch side-by-side comparisons for all six rows | **PASS** |
| 11 | Matrix progress updated only after visual + functional pass | **PASS** |
| 12 | Counts regenerated to 69/77 closed (89.6%) | **PASS** |
| 13 | `speedygo_dev` unchanged; isolated DB + Redis 9 cleaned | see cleanup |
| 14 | External services / commit / push / deployment / dev migration | **NOT RUN** (refused by brief) |

## Fixtures (isolated only)

| Size | Phone | Merchant reference | Attempt after resubmit |
| --- | --- | --- | --- |
| 1.0 (`fxb7_t100`) | `+213550009841` | `sgm_01a1047ddcdc7f139c1d77bcc5130373` | 2 |
| 1.35 (`fxb7_t135`) | `+213550009842` | `sgm_01a104815369777dbcde476868498074` | 2 |

Admin reject body (real API, both sizes): `PROFILE_INCOMPLETE` + `DOCUMENT_ILLEGIBLE` on `BUSINESS_IDENTITY`.

## Comparisons (Reference \| t1.0 \| t1.35)

| Row | Folder | Panel |
| --- | --- | --- |
| 71 | `merchant_registration_french` | `comparisons/live/fxb7_b7_registration.png` |
| 72 | `business_document_upload_french` | `comparisons/live/fxb7_b7_documents.png` |
| 74 | `merchant_verification_review_french` | `comparisons/live/fxb7_b7_review.png` |
| 73 | `merchant_verification_pending_french` | `comparisons/live/fxb7_b7_pending.png` |
| 76 | `merchant_verification_rejected_french` | `comparisons/live/fxb7_b7_rejected.png` |
| 77 | `merchant_verification_resubmission_french` | `comparisons/live/fxb7_b7_resubmission.png` |

Raw screens: `screens/fxb7_t{100,135}_b7_*.png`. Provenance: `PROVENANCE_fxb7_t*_b7_*.json`.

## Contract-limited omissions (unchanged; not faked)

- Step-1 owner name / e-mail / checkbox (consent is D-G5 on review).
- RC/NIF/ID naming, document thumbnails, sequential lock.
- Pending: person name, Prioritaire, SMS/SLA promise, FR chip.
- Review/Stitch: owner block, category, map/customer preview cards.
- Rejected Stitch: RC/NIF cards and “Validée” inventory (app shows structured `currentIssues`).

## Parity counts

**56 done · 3 partial · 3 blocked_contract · 2 deferred · 8 accepted exceptions · 5 duplicates → 69/77 closed (89.6%).**

## Notes

- Algeria wilaya/commune catalogue was empty after `prisma db migrate`; seeded into `speedygo_parity_fx` only via `fx_geo_seed.py` (same locked JSON/SHA-256 as backend `geo-import-algeria.mjs`). Not applied to `speedygo_dev`.
- Verification Contract Completion backend/Flutter was not redesigned; this batch is visual/live capture + matrix close only.

## Isolation cleanup

`fx_cleanup.sh` completed **FX_CLEANUP_OK**. All `speedygo_dev` fingerprints **PASS** (row counts, tracked orders, no fixture identities, no writes since start). Redis index **9** empty; `speedygo_parity_fx` dropped; `~/.speedygo/parity_fx` removed.
