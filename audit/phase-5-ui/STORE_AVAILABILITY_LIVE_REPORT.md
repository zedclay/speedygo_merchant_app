# Store availability — live report

**Fixture:** Dar El Bahja (`+213550000071`) on iPhone 16e only.  
**Preserved:** Finjan (17 Pro), Customer sessions/Keychain — no uninstall, no Finjan writes.  
**Date:** 2026-09-24  

## Results

| Check | Result | Evidence |
| --- | --- | --- |
| Domain / ERD / foundation docs | **PASS** | `docs/architecture/MERCHANT_STORE_AVAILABILITY_FOUNDATION.md`, `docs/business-rules/MERCHANT_STORE_AVAILABILITY.md` |
| Prisma `MerchantBranchAvailabilityOverride` migrate (speedygo_dev) | **PASS** | migration `20260924T1644_merchant_branch_availability_override` |
| Unit: evaluator + policy | **PASS** | 9 jest tests |
| Backend GET/PUT availability (HTTP live) | **PASS** | `audit/phase-5-ui/availability-http/AVAILABILITY_HTTP_EVIDENCE.json` |
| HTTP: FORCE_CLOSED → `isOpenNow=false`, `nextOpenAt=null` | **PASS** | same |
| HTTP: version conflict + current payload | **PASS** | `AVAILABILITY_VERSION_CONFLICT` + `error.availability` |
| HTTP: TEMPORARY_CLOSED + past `closedUntil` rejected | **PASS** | `AVAILABILITY_INVALID` |
| HTTP: restore FOLLOW_SCHEDULE | **PASS** | final GET/PUT follow |
| Jest e2e (`merchant-branch-availability.e2e-spec.ts`) | **NOT RUN** | Prisma ESM bootstrap (`@prisma/orm-extension-postgis/runtime`) fails under jest-e2e — same class of blocker as prior OTP/Prisma e2e notes. Spec file is present for when bootstrap is fixed. |
| Merchant UI: État du magasin (Selon les horaires / Fermé) | **PASS** | `availability-live/avail-etat-magasin.png` |
| Merchant UI: Ouvert badge from server `isOpenNow` (home) | **PASS** | `availability-live/avail-home-badge.png` (Ouvert ≠ Actif) |
| Merchant UI: FORCE_CLOSED save | **PASS** | `avail-force-closed.png` + provenance |
| Merchant UI: Fermeture temporaire | **PASS** | `avail-fermeture-temp.png` |
| Merchant UI: restore FOLLOW_SCHEDULE | **PASS** | `avail-follow-schedule.png` |
| Cold relaunch restores server state | **PASS** | home badge from GET after session restore on Dar El Bahja |
| Customer UI changes | **N/A** | out of scope |
| Commit / push | **NOT DONE** | per plan |

## HTTP steps (Dar El Bahja)

See `apps/merchant_app/audit/phase-5-ui/availability-http/AVAILABILITY_HTTP_EVIDENCE.json`.

1. Login OTP  
2. Resolve merchant/branch  
3. GET availability  
4. PUT FORCE_CLOSED  
5. PUT stale version → 409 + current  
6. PUT TEMPORARY_CLOSED (+30m)  
7. PUT FOLLOW_SCHEDULE  
8. PUT past closedUntil → 400  

## UI screenshots

Directory: `apps/merchant_app/audit/phase-5-ui/availability-live/`

| File | Meaning |
| --- | --- |
| `avail-home-badge.png` | Home Ouvert + Actif separate |
| `avail-profile.png` | Profil → État du magasin row |
| `avail-etat-magasin.png` | Segment **Selon les horaires** + badge **Ouvert** |
| `avail-force-closed.png` | After Fermé save |
| `avail-fermeture-temp.png` | Temporary closure form |
| `avail-after-temp.png` | After confirm temp |
| `avail-follow-schedule.png` | Restored follow schedule |

Provenance: `AVAILABILITY_LIVE_PROVENANCE.json` (all steps PASS).

## Notes

- Segment label is **Selon les horaires**, never “Ouvert”. Ouvert/Fermé comes only from effective `isOpenNow`.  
- `operationalStatus` (Actif) remains platform eligibility only.  
- Expired temporary overrides: GET evaluates in memory without DB write (covered in unit tests; live HTTP exercised conflict/validation/modes).
