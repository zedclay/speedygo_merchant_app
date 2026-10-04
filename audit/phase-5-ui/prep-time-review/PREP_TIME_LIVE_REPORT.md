# Merchant preparation-time — live report

**Fixture:** Dar El Bahja (`+213550000071`) on iPhone 16e only.  
**Preserved:** Finjan / Customer / Driver sessions & Keychain — no uninstall of those apps.  
**Date:** 2026-09-25  
**Status:** `implementer_reviewed` (pending visual acceptance of UI corrections)

Layers are separate. Screenshots do **not** convert a failed harness run into PASS.

---

## Result matrix

| Layer | Check | Result | Evidence |
| --- | --- | --- | --- |
| **HTTP** | Accept / persist / update / conflict / validation / late / revisions | **PASS** | `prep-time-http/PREP_TIME_HTTP_EVIDENCE.json` (**reused, unaffected**) |
| **Automated** | Prior non-green harness (DDS / `order-card`) | **FAIL** (historical) | Screenshots from that run ≠ harness PASS |
| **Automated** | Card-finder root cause | **Harness** | Filter/scroll fix; no deep-link bypass |
| **Automated** | Accept mode (card nav) | **PASS** | Recaptured 2026-09-25 ~04:23 |
| **Automated** | Cold relaunch persistence | **PASS** | `PREP_COLD_COMPARE.json` (**reused**) `coldPersistOk: true` |
| **Automated** | A11y mode textScale 1.35 | **PASS** | Recaptured 2026-09-25 ~04:25 |
| **Unit** | Preview arithmetic + branch TZ (+ midnight) | **PASS** | `test/features/prep_time_clock_test.dart` |
| **Unit** | Widget preview `04:19 → 04:29`; singular hint; no Recommandé | **PASS** | `preparation_time_widgets_test.dart` |
| **Visual fix** | Preview TZ consistency | **PASS** (pixels) | `prep-update-sheet.png`: `04:48 → 04:58`; a11y: `04:50 → 05:00` |
| **Visual fix** | Post-save revised ready prominent | **PASS** (pixels) | `prep-after-update.png`: prévue `04:58`, initiale `04:48` |
| **Visual fix** | Selected chip blue + no +10 clip @ 1.35 | **PASS** (pixels) | `prep-a11y-update-sheet.png`; sample RGB≈`(47,89,175)` |
| **Visual fix** | No technical server/countdown copy; singular accept hint | **PASS** (pixels) | `prep-a11y-accept-sheet.png` |
| **Jest e2e** | Prisma ESM | **NOT RUN** | Separate blocker |
| — | Customer/Driver delay notifications | **NOT CLAIMED** | — |
| — | Commit / push | **NOT DONE** | — |

---

## A. HTTP (reused — already passed)

Unaffected by UI formatting fixes. See `prep-time-http/PREP_TIME_HTTP_EVIDENCE.json`.

## B. Automated integration

### B1. Historical non-green

Earlier harness **FAIL** (DDS / `order-card` under wrong filter). Screenshots from that run remain visual-only.

### B2. Green runs retained / recaptured

| Mode | Result | Notes |
| --- | --- | --- |
| `accept` | **PASS** (recaptured) | Update preview + post-save ready |
| `cold` | **PASS** (reused) | Terminate/relaunch; version/`estimatedReadyAt` unchanged |
| `a11y` | **PASS** (recaptured) | textScale 1.35; chips wrap; blue selected |

## C. Visual defects fixed (this pass)

| Defect | Cause / fix |
| --- | --- |
| Preview `04:19 → 03:29` | Current used `toLocal()`; proposed used UTC `.hour`. Now both use `prep_time_clock.dart` (absolute instant + Africa/Algiers UTC+1). |
| +10 clipped @ 1.35 | `ChoiceChip` in equal `Expanded` row. Now `Wrap`; no text-scale reduction. |
| Turquoise selected chip | Material3 default. Now `AppColors.primaryContainer` + white label/checkmark. |
| Technical countdown copy | Removed. Late-only operational French retained. |
| `les 1 articles` | Singular/plural in `prepSelectHint`. |
| `Recommandé` | Removed — no documented recommendation rule. |
| Post-save hierarchy | Banner shows **Heure prévue** (revised) prominently; **Heure initiale** secondary. |

## D. Clock start (unchanged)

`estimatedReadyAt = acceptInstant + preparationMinutes`. Updates advance estimate only; originals never rewrite. Late ≠ auto READY.

## E. Review package

`apps/merchant_app/audit/phase-5-ui/prep-time-review/prep_time_review.zip`
