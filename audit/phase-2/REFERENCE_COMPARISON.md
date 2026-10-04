# Phase 2 reference comparison

**Design source of truth:** `screens/MerchantScreens/<folder>/screen.png` + `code.html`  
(see `docs/MERCHANT_UI_SOURCE_OF_TRUTH.md`).  
**Audit** under `audit/phase-2/` is evidence only — not a design replacement.  
**Visual matching:** `implementer_reviewed` until human acceptance (tests ≠ accepted).

Inspected under `screens/MerchantScreens/` (`code.html` + `screen.png`) for:

- `active_orders_list_french`
- `incoming_order_details_french`
- `accept_order_and_preparation_time_french`
- `commande_en_pr_paration_tat_initial`
- `commande_en_pr_paration_en_cours`
- `mark_order_ready_french`
- `waiting_for_driver_french`
- `cancelled_order_french`
- `d_tails_de_la_commande_finance_transparente`
- `merchant_order_history_unified`

Full inventory (reference → route → status → gaps → unsupported):  
**`docs/MERCHANT_UI_SOURCE_OF_TRUTH.md` §6**.

## Implementation mapping (summary)

| Reference folder | Role | Implementation |
| --- | --- | --- |
| `active_orders_list_french` | List | En cours segment + fulfillment chips + labelled GMS + five-tab shell |
| `incoming_order_details_french` | Incoming | Compact banner; customer/items; Refuser\|Accepter; secondary ref + copy |
| `accept_order_and_preparation_time_french` | Accept + ETA | Accept only; **no** prep-time picker or disclaimer inventing support |
| `commande_en_pr_paration_*` | Preparing | Articles à préparer + start-prep / mark-ready |
| `mark_order_ready_french` | Ready CTA | Mark ready when PREPARING |
| `waiting_for_driver_french` | Post-ready | Single ready status; “Recherche de livreur” only if delivery.status=SEARCHING_DRIVER |
| `merchant_order_history_unified` | History | Historique segment + CANCELLED/COMPLETED/FAILED chips |
| `cancelled_order_french` | Cancelled | Status / reason / cancelledAt first; summary secondary |
| `d_tails_de_la_commande_finance_transparente` | Finance | GMS / commission / net / delivery fee disclaimer; cancelled snapshot note |

## Recorded reference tensions (png vs html / vs contract)

| Topic | Note |
| --- | --- |
| Accept primary CTA | Stitch often shows prep-time chooser; API accept body is empty → UI uses **Accepter** (capability omission, not alternate branding) |
| List amount | Stitch may show a single customer-facing total; contract forbids inventing client totals → labelled **Marchandises** (GMS) on list; net only in finance |
| Ready / driver | Stitch shows search animation + ETA; show search copy only when delivery status is authoritative `SEARCHING_DRIVER` |
| Public IDs | Stitch `#SG-…` vs server `sgo_…` → keep canonical server reference (compact + copy) |

If additional `screen.png` ↔ `code.html` conflicts are found while correcting a screen, append them here; do not invent a third design.

## Money / date clarifications

- List amount = **Marchandises** (`grossMerchandiseSubtotalMinor`), never unlabeled merchant net beside payment.
- Detail finance separates GMS, commission, **Net commerçant**, delivery fee (client).
- Cancelled finance notes historical snapshot ≠ payable earnings.
- List footer uses **Créée ·** (`createdAt`). Cancellation detail uses **Annulée le** (`cancellation.cancelledAt`).

## Sticky footer strip

Prior Material `elevation: 8` under sticky actions produced a dark/grey band in some captures. Replaced with surface `DecoratedBox` + hairline top border + soft shadow. Live historical shots did not show the band — treated as capture/elevation artifact; fixed prophylactically.

## Captured comparisons

Side-by-sides: `review/structure/side-*.png`. Mocked: `review/mocked/` (includes shell list). Live UI update this pass: **NOT RUN** (Finjan on 17 Pro preserved; API health 200). Historical live shots retained under `review/live/`.

## Remaining visual differences

See `docs/MERCHANT_UI_SOURCE_OF_TRUTH.md` §6 and `review/INDEX.md`. Status stays `implementer_reviewed`.
