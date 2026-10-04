# Merchant registration lifecycle acceptance

**Verdict: PASS (registration lifecycle)** — Phase 2 order ops still paused

Dates: 2026-09-18  
Environment: `speedygo_dev` / API `http://127.0.0.1:3000` / storage `~/.speedygo/dev/storage` / OTP `PHONE` / SE `E342AC62-65EB-4786-87D1-292AF132E1CF`  
Constraints: no Customer/.env/schema edits beyond authorized seed; no commit/push; Finjan untouched; merchant not recreated.

---

## Primary TEST FIXTURE (final)

| Field | Value |
| --- | --- |
| Label | `TEST FIXTURE — Lifecycle Acceptance Shop` |
| Phone | `+213559907701` |
| Account | `01a0b4e7-7672-7c21-b1c5-e64d4fdacfb4` |
| Merchant | `01a0b4e7-83a0-7742-8ac0-03fcb5e9b056` |
| Public ref | `sgm_01a0b4e783a07ccdac06eccbec3ea39c` |
| **Final status** | **`ACTIVE`** (`verified_at` set) |
| Branch | present (`TEST FIXTURE Branch Alger (corrected)` after correction) |

**Approval ≠ operational readiness for orders.** Home after approve means membership + ACTIVE + branch routing succeeded. Catalog/order intake (Phase 2) was **not** exercised.

---

## Seed provisioning (authorized, applied)

| Item | Value |
| --- | --- |
| Script | `apps/backend/scripts/dev-merchant-lifecycle-acceptance/seed-admin.sql` |
| Apply | `apply-seed-admin.sh` (manual; **not** Nest startup) |
| DB gate | `current_database() = speedygo_dev` |
| Phone check | `+213550000099` was free before insert |
| Admin account | `0d00c074-d000-7000-8000-000000000001` |
| Role | `speedygo-dev-merchant-lifecycle-acceptance` |
| Permissions | **`merchants.read`, `merchants.verify` only** |
| Auth verify | `GET /admin/me` → those two codes; reject/approve on fixture succeeded |

Proposal archive: `PROPOSED_MERCHANTS_VERIFY_PROVISIONING.md` (status: applied).

---

## Segment A — draft → pending (preserved)

| Step | Result | Layer |
| --- | --- | --- |
| Auth OTP → draft → docs → map → submit | **PASS** | live Merchant UI |
| Pending optional absent | **PASS** | live Merchant UI |
| Pending blocks Home | **PASS** | live Merchant UI |

Screenshots: `live-review.png`, `live-pending.png`.  
Prior Flutter lifecycle test exit 0.

---

## Segment B — Admin reject (API-only)

| Step | Result | Evidence |
| --- | --- | --- |
| Admin OTP + `/admin/me` | **PASS** | permissions = read+verify only |
| `POST …/verification/reject` on fixture | **PASS** | HTTP **201**, status → `REJECTED` |
| Finjan | **PASS** | still `PENDING_REVIEW` |
| Rejection reason field | **N/A (product limitation)** | v1.0 does not accept/persist a reason — not a failed transition |

---

## Segment C — Merchant correction + resubmit (live UI)

| Step | Result | Evidence |
| --- | --- | --- |
| Refresh / login → correction screen | **PASS** | Title `Dossier à corriger` |
| Generic guidance (no invented reason) | **PASS** | `verificationRejectedBody` + `regRejectionNoReason`; no motif/raison admin |
| Correct docs + branch label | **PASS** | Re-pick required evidence; branch “(corrected)” |
| Resubmit | **PASS** | → pending UI |
| Flutter correction test | **PASS** | exit 0 |

Screenshots: `live-rejected.png`, `live-resubmit-review.png`, `live-resubmit-pending.png`.

---

## Segment D — Admin approve + relaunch

| Step | Result | Layer / evidence |
| --- | --- | --- |
| `POST …/verification/approve` | **PASS** | API-only, HTTP **201** → `ACTIVE` + verified |
| Merchant refresh → Home | **PASS** | live UI `home-branch-name` |
| Cold relaunch session restore → Home | **PASS** | live UI (persisted session; SE only) |
| Finjan | **PASS** | still `PENDING_REVIEW` |

Screenshots: `live-approved-home.png`, `live-cold-relaunch-home.png`.  
`admin_approve_http.txt` = `201`.

---

## Step matrix (overall)

| Step | Result |
| --- | --- |
| Draft → pending | **PASS** |
| Seed `merchants.verify` (dev-only) | **PASS** (applied) |
| Admin reject | **PASS** (API-only) |
| Rejection reason UX | **LIMITATION** (contract; status transition OK) |
| Correction + resubmit | **PASS** (Merchant UI) |
| Admin approve | **PASS** (API-only) |
| Home + cold relaunch | **PASS** |
| Phase 2 order ops | **NOT RUN** (paused) |
| Customer Revue | Untouched |

---

## Isolation

| Actor | Result |
| --- | --- |
| Finjan `01a0ad2a-29eb-7959-b23c-d21f1e1c0915` | `PENDING_REVIEW` unchanged |
| Customer app / Revue | Not modified |
| iPhone 17 Pro | Not targeted (SE keychain/uninstall only) |

---

## Artifacts

- `step_results.json` (updated)  
- `step_results_partial.json` (segment A)  
- `step_results_correction.json` (segment C–D)  
- `host_correction_log.txt`  
- `flutter_correction_test.log`  
- `screenshots/live-*.png`  
- Backend seed: `scripts/dev-merchant-lifecycle-acceptance/`
