# Merchant UI — design source of truth

**Status of this document:** binding guidance for Merchant UI work.  
**Does not claim:** human visual acceptance of any screen merely because tests or captures pass.

## 1. Primary design references

For each folder under `screens/MerchantScreens/<screen-folder>/`:

| Artifact | Role |
| --- | --- |
| `screen.png` | Visual appearance — composition, hierarchy, color, icons, cards, CTA placement |
| `code.html` | Layout / style details — structure, spacing, typography, component arrangement |

**Required practice:** inspect **both** before implementing or correcting a screen.

**Conflicts:** if `screen.png` and `code.html` disagree, record the discrepancy in the phase audit (e.g. `audit/phase-*/REFERENCE_COMPARISON.md`). Do not silently pick an undocumented third look.

## 2. Audit package role

`apps/merchant_app/audit/` is **implementation evidence** (captures, side-by-sides, contract maps, acceptance notes). It is **not** a design source of truth and must not replace MerchantScreens.

## 3. Approved exceptions (preserve)

| Area | Policy |
| --- | --- |
| Splash | Current approved Merchant splash — do not regress to an unapproved Stitch variant without explicit ask |
| Onboarding | Current approved **three** onboarding pages |
| Phone / OTP | Presentation aligned with Customer auth patterns |
| Auth / access | Authentication, access restrictions, and server-authoritative verification/membership states |

## 4. Compatibility rules

- Match reference hierarchy, spacing, typography, colors, cards, icons, and action placement when compatible with actual contracts.
- Missing API / domain capabilities → omit unsupported controls; keep the rest of the presentation aligned.
- Never invent data, timers, permissions, ETA pickers, driver phones, handoff scans, or realtime merely to look like a mockup.
- Document gaps and unsupported interactions in audit docs.

## 5. Status vocabulary

| Status | Meaning |
| --- | --- |
| `exception_approved` | Intentionally not matching that MerchantScreens folder; approved exception |
| `implementer_reviewed` | Implemented against refs + evidence; **awaits human visual acceptance** |
| `partial` | Behavior/contract OK; material visual gaps still listed |
| `placeholder` | Route exists; content not in current phase |
| `not_in_scope` | Reference exists; not authorized for this phase |
| `human_accepted` | **Only** after explicit human visual acceptance (never from tests alone) |

---

## 6. Phase 2 scope inventory (orders)

Catalogue and other MerchantScreens folders remain **paused / not_in_scope** unless a later brief opens them.

| Reference folder | Flutter screen / route | Status | Remaining visual differences | Unsupported interactions |
| --- | --- | --- | --- | --- |
| `active_orders_list_french` | `OrdersScreen` → `/app/orders` | `implementer_reviewed` | No search / Urgent chips; short `#SG-` IDs unused (canonical `sgo_…`); Stitch bell/chrome absent; En cours has Acceptées (API) beyond Stitch’s three chips | List search; urgent filter; item-count chips; fake combined “all active” OR query |
| `merchant_order_history_unified` | Same route — **Historique** segment | `implementer_reviewed` | Historique “Tout” (multi-status) omitted — explicit CANCELLED/COMPLETED/FAILED chips only; Stitch secondary chrome | Combined history OR query; support CTAs |
| `incoming_order_details_french` | `OrderDetailScreen` → `/app/orders/:orderId` (incoming) | `implementer_reviewed` | No expiry countdown; no loyalty / special-note banner; AppBar title `Commande` vs brand wordmark; long refs secondary + copy sheet | Accept countdown / expire timer; prep-time gate on accept |
| `accept_order_and_preparation_time_french` | Same detail — accept CTA | `partial` | Accept is **Accepter**, not “Choisir le temps de préparation”; no time picker sheet | Prep-time body on accept; ETA configuration |
| `commande_en_pr_paration_tat_initial` | Detail — ACCEPTED | `implementer_reviewed` | No prep countdown / “temps restant” | Update preparation time |
| `commande_en_pr_paration_en_cours` / `preparing_order_french_*` | Detail — PREPARING | `implementer_reviewed` | No live timer; checklist UI not invented as mutation gate | Prep ETA editor; artificial checklists that change eligibility |
| `mark_order_ready_french` | Detail — mark-ready CTA | `implementer_reviewed` | CTA copy/placement may differ slightly from Stitch chrome | — |
| `waiting_for_driver_french` | Detail — READY | `implementer_reviewed` | No radar animation / “Synchronisé”; no invented ETA; search copy only if `delivery.status=SEARCHING_DRIVER` | Fake driver search animation; driver phone; map; realtime sync badge |
| `driver_assigned_*` / `driver_arrived_*` | Detail — delivery card when present | `partial` | Delivery summary only when GET delivery returns data | Call driver; secure handoff / scan |
| `driver_arrived_secure_handoff_final_ux` | — | `not_in_scope` | — | Merchant handoff confirmation (no Merchant mutation) |
| `cancelled_order_french` | Detail — CANCELLED | `implementer_reviewed` | No “Compris” / support / invented history destinations | Support ticket from cancel screen |
| `d_tails_de_la_commande_finance_transparente` | Detail — finance card | `implementer_reviewed` | Labels follow contract (GMS / commission / net / delivery fee); no invented “total client” formula | Client-side recomputed totals |
| `incoming_order_alert_french` | — | `not_in_scope` | Covered by list + detail, not a separate overlay route | Push overlay / realtime alert UI |
| `mise_jour_du_temps_de_pr_paration` / `update_preparation_time_french` | — | `not_in_scope` | — | Prep-time update API |
| `delayed_order_french` | — | `not_in_scope` | — | Delay contract |

### Shell (orders context)

| Reference cue | Flutter | Status | Notes |
| --- | --- | --- | --- |
| Five-tab bar (Accueil / Commandes / Catalogue / Rapports / Profil) | `MerchantShell` | `implementer_reviewed` | Labels must remain readable at text scale 1.3; Catalogue/Reports are placeholders |
| `merchant_operational_dashboard_french` | `HomeScreen` → `/app/home` | `partial` | Counts from `list.total` only; no fabricated KPIs |

---

## 7. Approved exceptions inventory (auth / access)

| Reference folder (if any) | Flutter route | Status | Notes |
| --- | --- | --- | --- |
| `premium_splash_and_session_routing_french` | `/` splash | `exception_approved` | Preserve current approved splash |
| Onboarding Stitch variants | `/onboarding` | `exception_approved` | Preserve current three pages |
| `merchant_phone_login_french` / OTP refs | `/phone`, `/otp` | `exception_approved` | Aligned with Customer presentation |
| Verification / registration refs | `/access/*`, `/verification/*` | `exception_approved` / phase-1 evidence | Server-authoritative access; do not invent states |

---

## 8. Future phases

Apply §1–§4 to every later Merchant phase. Updating this inventory when a screen enters scope is required; implementing every MerchantScreens folder is **not** authorized by this document alone.

Evidence for Phase 2 comparisons: `audit/phase-2/review/`, `audit/phase-2/REFERENCE_COMPARISON.md`.
