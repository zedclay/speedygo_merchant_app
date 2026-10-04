# Merchant Catalogue and Store Contracts Completion

**Run:** `fxenv_20261004T005442Z`  
**Date:** 2026-10-04  
**API:** `127.0.0.1:3100` · Redis **9** · DB `speedygo_parity_fx` (dropped)  
**Migration:** `20261003T2144_merchant_catalogue_store_contracts_completion` (`62b296fb…` → `dc7b1a4b…`, 13 additive ops)  
**Status:** `implementer_reviewed` (not visually accepted)  
**Bottom Nav:** unchanged (`user_accepted`)  
**Verification Contract Completion:** unchanged

## Rows

| # | Reference | Outcome |
| --- | --- | --- |
| 44 | `selling_units_french` | **done** — persisted integer-compatible unit |
| 47 | `store_information_french` | **done** — description / nameAr / publicEmail |
| 53 | `store_category_selection_french` | **done** — Branch 0..1 CommerceVertical self-select |
| 57 | `horaires_exceptionnels_format_24h` | **exception_approved** — one-date MVP; ranges/batch non-goals |
| 63 | `merchant_support_french` | **done** — topic + subject + FAQ |

## PASS / FAIL / NOT RUN

| Check | Result |
| --- | --- |
| Domain / ERD / foundation docs | PASS |
| Prisma migrate on `speedygo_parity_fx` | PASS (14 probe tables + 6 columns) |
| Backend `tsc -p tsconfig.build.json` | PASS |
| Backend unit (catalog/support/profile selling-unit paths) | PASS |
| Flutter `catalogue_store_contracts_test.dart` | PASS (6) |
| Isolated API e2e `fx_catalogue_store_e2e.sh` | **21 / 21 PASS** |
| OWNER / MANAGER / STAFF matrix (e2e) | PASS |
| Legacy null product / unclassified branch | PASS |
| Inactive vertical / invalid email / KG unit | PASS (rejected) |
| Support topic+subject required; FAQ seeded | PASS |
| `speedygo_dev` fingerprint before/after | **unchanged** (selling_col=0) |
| fx cleanup isolation | PASS |
| Visual re-acceptance vs Stitch | NOT RUN (by design) |
| Customer exceptional-hours UI | NOT RUN (excluded) |

## Remaining differences vs Stitch

| Screen | Honest gaps |
| --- | --- |
| Selling units | No kg/500g/250g (integer qty); no AR custom label |
| Store information | No wizard “Étape 4”; phone on address screen; no invented rating |
| Store category | **Single-select** (domain 0..1); multi-select chips are visual exception |
| Exceptional hours | No date ranges / batch list (accepted exception) |
| Support | No live chat / SLA; FAQ is versioned FR articles only |

## Artefacts

- `catalogue_store_contracts/RESULTS.json`, `e2e.log`
- `speedygo_dev_fingerprint_before.json` / `_after.json`
- `isolation_*.json`, `cleanup.log`, `migrate.log`
