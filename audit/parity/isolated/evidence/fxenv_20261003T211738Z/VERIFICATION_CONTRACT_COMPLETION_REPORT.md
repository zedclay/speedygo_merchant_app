# Merchant Verification Contract Completion — isolated evidence

**Run:** `fxenv_20261003T211738Z`  
**Date:** 2026-10-03 (Africa/Algiers)  
**API:** `127.0.0.1:3100` · Redis index **9** · DB `speedygo_parity_fx` (dropped after)  
**Migration:** `20261003T2036_merchant_verification_contract_completion` (`8f14779e…` → `62b296fb…`)  
**Status:** `implementer_reviewed` (not visually accepted)  
**Bottom Nav:** unchanged (`user_accepted`)

## Scope closed (matrix rows 71, 72, 73, 74, 76, 77)

| Row | Reference | Contract work |
| --- | --- | --- |
| 71 | `merchant_registration_french` | Consent recorded on review submit (D-G5), not inventing fields on step 1 |
| 72 | `business_document_upload_french` | Rebind while REJECTED resolves DOCUMENT-scoped issues |
| 73 | `merchant_verification_pending_french` | attempt / submittedAt visibility when server provides them |
| 74 | `merchant_verification_review_french` | Dual legal acceptance + versioned submit body |
| 76 | `merchant_verification_rejected_french` | Structured `currentIssues` |
| 77 | `merchant_verification_resubmission_french` | Re-accept + attempt n+1 + approve path |

## Results

| Check | Result |
| --- | --- |
| `prisma db migrate` on `speedygo_parity_fx` | PASS (12 probe tables incl. 4 new) |
| `prisma db verify` | see `verify.log` |
| Isolated API e2e `fx_verification_e2e.sh` | **16 / 16 PASS** → `verification_contract/RESULTS.json` |
| Backend unit `merchant-verification.service.spec` | **17 / 17 PASS** |
| Flutter `verification_contract_completion_test.dart` | **14 / 14 PASS** |
| `speedygo_dev` fingerprint before/after | **unchanged** (legal table absent on dev; no writes) |
| Isolation comparison (`fx_cleanup`) | PASS (dev counts, fixtures, Redis 9 empty) |

## API behaviours proven on :3100

1. `GET /merchant/legal/current` seeds active `MERCHANT_TERMS` + `DOSSIER_ACCURACY_DECLARATION` (`2026-10-03`)
2. Submit without acceptances when ready → `LEGAL_ACCEPTANCE_REQUIRED`
3. Outdated version → `LEGAL_VERSION_OUTDATED`
4. Submit with both acceptances → submission attempt 1 + 2 legal acceptance rows
5. Admin reject with APPLICATION + DOCUMENT issues → REJECTED + OWNER `currentIssues`
6. Rebind `BUSINESS_IDENTITY` → DOCUMENT issue cleared
7. Resubmit → attempt 2 PENDING_REVIEW
8. Admin approve → ACTIVE, `reviewedAt` set, unresolved issues 0

## Out of scope (unchanged)

- Admin Web UI
- Customer / Driver apps
- Bottom Nav / Catalogue / Maps
- Arabic localization
- Visual re-acceptance of Stitch references
- Migration / writes against `speedygo_dev`

## Artefacts

- `verification_contract/RESULTS.json`, `e2e.log`
- `speedygo_dev_fingerprint_before.json` / `_after.json`
- `isolation_*.json`, `cleanup.log`, `migrate.log`, `environment.json`
