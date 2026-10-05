# Merchant–Driver pickup handoff — live close report

**Date:** 2026-10-05  
**Scope:** Controlled batch to validate/localize/live-test Merchant–Driver pickup handoff and close Merchant parity **row 23** only if every gate passes.  
**Git actions:** none (no commit, push, merge, rewrite, migrations on shared DBs, or provider activation).

| App | Branch | Notes |
| --- | --- | --- |
| Backend | `snapshot/2026-10-04-current-workspace` @ `d188a21` | Uncommitted: `assignmentVersion` on current-delivery response + unit coverage |
| Driver | `feat/driver-current-delivery-pickup-handoff-v1` @ `0de24a0` | Uncommitted: current delivery + confirm-pickup + FR/AR/RTL |
| Merchant | `feat/merchant-fr-ar-localization-v1` @ `fd4e50e` | Uncommitted: localization regressions fixed for this batch’s suite gate |

---

## Verdict

**Row 23 stays open. Parity remains 75/77.**  
Live Merchant–Driver UI handoff was **not** completed; API fixture evidence is **not** Driver UI evidence.

---

## Gate matrix

| Gate | Result | Evidence |
| --- | --- | --- |
| Backend `assignmentVersion` review + unit tests | **PASS** | Driver delivery service specs (41 related unit tests in prior/this batch) |
| Driver FR/AR + RTL + persist | **PASS** | `AppStrings` / ARB / `locale_*` / language settings; RTL via app directionality |
| Driver `flutter analyze` + `flutter test` | **PASS** | analyze clean; `flutter test` **+29** |
| Merchant `flutter analyze` | **PASS** (0 errors) | 137 info/warning issues; no `error •` |
| Merchant full `flutter test` | **PASS** | **+743 ~1** (2026-10-05) |
| Isolated env `speedygo_parity_fx` + API `:3100` | **PASS** | Health OK; Redis 6381 / DB marker `fxenv_20261005T125234Z` |
| Authenticated handoff API e2e | **PASS 24/24** | `apps/merchant_app/audit/parity/isolated/evidence/fxenv_20261005T125234Z/driver_handoff/` (`H0–H1`, `A1–A4`, `P1–P18`) |
| Live Merchant–Driver UI + FR/AR captures | **NOT RUN** | No handoff live harness; iPhone 16e booted briefly; free disk ~9 GiB (preflight min 5) but dual-app iOS build risk; shut down without live captures |
| Close row 23 → 76/77 | **BLOCKED** | Live joint UI gate unmet |
| Row 51 | **Unchanged / open** | Out of scope |

P9 note in e2e log remains: *API fixture ≠ Driver UI evidence*.

---

## What changed this batch (Merchant suite unblockers)

Localization / fixture regressions that blocked the full Merchant suite were fixed without inventing product formulas:

- Restored `availabilityLastUpdate` colon (`Dernière mise à jour : …`).
- Restored plural-aware `temporaryClosureImpactTail(int count)` (removed doubled count / wrong tail).
- Restored `availabilityCloseWarningBody` “les N commandes actives” wording.
- FAQ ExpansionTile: `Material` owns surface/border (ListTile ink assertion).
- Support topic fixtures aligned to server seed codes; batch 2/6 tests updated for topic+subject compose.
- Order support error banner moved above the fold (ListView was culling it).
- Reject mutation expectation includes `OTHER` reason code; branch update expectations include `publicInfo`.

---

## Driver report delta

See updated section in  
`apps/driver_app/docs/DRIVER_CURRENT_DELIVERY_PICKUP_HANDOFF_V1_REPORT.md`  
(FR/AR done; authenticated API e2e **24/24 PASS**; live joint still **NOT VERIFIED**).

---

## Remaining blockers for row 23

1. **Live Merchant–Driver UI** on isolated FX (Merchant shows code @ `AT_PICKUP`; Driver enters code / confirm-pickup; CONSUMED / Remise confirmée) with FR + AR captures — **missing**.
2. Dedicated live harness (OTP both apps, seed `AT_PICKUP`, screenshot pipeline) — **not present**; existing live scripts cover team/B7/daily-delay only.
3. Tracker copy that said “driver_app has no confirm-pickup UI” is **stale** (UI exists on Driver feature branch) but **does not** authorize closing without live joint proof.

---

## Confirmation

- No commit / push / force-push / merge.
- No migrations on shared DBs; no `.env` committed; FX only.
- Row 23 **not** closed; row 51 **not** touched; score **75/77**.
