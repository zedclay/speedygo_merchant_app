# B — Orders journey: design-parity inventory (read-only)

Scope: 20 MerchantScreens folders for the Merchant orders journey. All 40 reference files
(`screen.png` + `code.html`) exist and were readable. No code, test or existing doc was changed.

Evidence base: Flutter `lib/features/orders/**`, `lib/features/notifications/presentation/incoming_order_alert_overlay.dart`,
`lib/features/access/data/merchant_api.dart`, `lib/core/constants/{app_strings,app_constants}.dart`;
backend `src/modules/{orders,delivery,support}/**`, `prisma/contract.prisma`; docs
`MERCHANT_ORDER_WORKFLOW.md`, `MERCHANT_ORDER_PREPARATION_ESTIMATE_FOUNDATION.md`, `DELIVERY_FOUNDATION.md`,
`DRIVER_DELIVERY_WORKFLOW.md`, `DRIVER_MATCHING.md`, `SUPPORT_FOUNDATION.md`, `MERCHANT_FINANCIAL_VISIBILITY.md`;
captures `audit/phase-2/review/**`, `audit/phase-5-ui/{prep-time-live,order-alerts-live}/*.png`.

Reference sample data (Sara Belkacem, Dar El Benna, `#SG-260803-1842`, 2 250 DZD, 13:30, 18:42 timers,
Yacine Mansouri, plate 16-12345, ★4.9, code 4186) is example data — never hardcode.

## Summary

| reference | route/state | proposed status | one-line required work |
| --- | --- | --- | --- |
| `active_orders_list_french` | `/app/orders` · `OrdersScreen` · En cours segment | `partial_contract_limited` | Rebuild card (ref/name/amount/ribbon/inline actions), counts on every chip, bell + open/closed header; omit search/Aujourd'hui/Urgent/5+ (no contract) |
| `merchant_order_history_unified` | `/app/orders` · Historique segment | `partial_contract_limited` | Day-grouped cards with left status bar + icon chips; omit search and "Tout" (no multi-status query) |
| `incoming_order_alert_french` | `MerchantAlertHost` overlay · `IncomingOrderAlertOverlay` | `needs_work` | White sheet over blue header, bento tiles, dashed items card, white footer; relabel GMS total; no countdown/Urgent/logo |
| `incoming_order_details_french` | `/app/orders/:orderId` · `CREATED`+`PENDING_ACCEPTANCE` | `partial_contract_limited` | Primary-container identity block, item rows, CTA "Choisir le temps de préparation"; omit expiry, loyalty, note, customer total |
| `accept_order_and_preparation_time_french` | Detail → `showAcceptPreparationSheet` | `needs_work` | Bento time grid + "Temps personnalisé" (5–120 supported), summary card, "Confirmer et Accepter"; no Recommandé / dispatch claim |
| `commande_en_pr_paration_tat_initial` | Detail · `CONFIRMED`+`ACCEPTED` | `partial_contract_limited` | Big MM:SS boxes + "Prévu pour", Client/Paiement tiles, footer Modifier temps + Support; keep "Démarrer la préparation"; no Appeler/note/Synchronisé |
| `commande_en_pr_paration_en_cours` | Detail · `ACTIVE`+`PREPARING` | `partial_contract_limited` | Same structure (light-box timer variant), item cards, footer Modifier temps + Support + Marquer comme prête (not checklist-gated) |
| `preparing_order_french_1` | Detail · ACCEPTED/PREPARING | `not_applicable_duplicate` | Duplicate of `…_tat_initial` (+ stock kitchen photo); do not implement separately |
| `preparing_order_french_2` | Detail · `ACTIVE`+`PREPARING` | `not_applicable_duplicate` | Duplicate of `…_en_cours`; its enabled CTA is the contract-correct state |
| `mise_jour_du_temps_de_pr_paration` | Detail → `showUpdatePreparationSheet` | `partial_contract_limited` | Full-screen/sheet parity: context header, state card, 4-col grid, "Saisie personnalisée" (1–60), comparison card; drop notification claim |
| `update_preparation_time_french` | same | `not_applicable_duplicate` | Variant with named Client/Livreur notification (unsupported); fold into `mise_jour…` |
| `delayed_order_french` | Detail late state (`PreparationCountdownBanner` late) + update sheet | `partial_contract_limited` | Late hero card from server instant; "+" only revision; omit reason chips taxonomy, minus, customer ETA, driver row |
| `mark_order_ready_french` | Detail · PREPARING → mark-ready | `needs_work` | Optional confirm step with packing list + note block, "Confirmer et marquer prêt" / "Retour"; checklist must not gate |
| `waiting_for_driver_french` | Detail · `READY` (+ delivery `SEARCHING_DRIVER`) | `needs_work` | Status hero, "Prête depuis" (ORDER_READY event), order + pickup cards, sticky Actualiser + Contacter le support; no wait ETA |
| `driver_assigned_call_action_at_bottom` | Detail · READY + delivery `DRIVER_ASSIGNED`/`TO_PICKUP` | `partial_contract_limited` | Status header + summary + pickup card + support; driver identity, call and ETA blocked |
| `driver_arrived_french` | Detail · READY + delivery `AT_PICKUP` | `partial_contract_limited` | "Livreur Arrivé" banner with arrival time/wait from `DRIVER_ARRIVED_PICKUP` event; fix AT_PICKUP label; no driver card/call/confirm |
| `driver_arrived_secure_handoff_final_ux` | — (would be detail · `AT_PICKUP`) | `blocked_contract` | Pickup code + merchant validation do not exist; only post-pickup "Remise confirmée" state is supported |
| `cancelled_order_french` | Detail · `status=CANCELLED` | `needs_work` | Centered hero, actor ("par le client"/rejet) from statusHistory, reason chip, summary, Support + Voir l'historique, "Compris" |
| `d_tails_de_la_commande_finance_transparente` | Detail · finance card (+ COMPLETED layout) | `needs_work` | Status card + localized timeline (order + delivery events), finance card styling, support CTA; no receipt/driver card/note |
| `signaler_un_probl_me_standardis` | none (new route) | `partial_contract_limited` | New order-scoped support form → `POST /merchant/:merchantId/support`; no category/photos/draft; OWNER/MANAGER only |

---

## Contract checks (explicit)

| Check | Result | Evidence |
| --- | --- | --- |
| Delay reporting | **PARTIAL.** Only "add minutes" revision: `POST /merchant/:merchantId/orders/:orderId/preparation-estimate` `{addMinutes 1–60, expectedEstimateVersion, reason? ≤255 free text}`; `isPreparationLate` derived. No reduction, no reason taxonomy, no Customer/Driver delay notification ("Does not claim Customer/Driver push"). | `merchant-order.controller.ts:133-172`, `merchant-order-write.dto.ts:93-122`, `preparation-estimate.policy.ts:1-5`, `MERCHANT_ORDER_PREPARATION_ESTIMATE_FOUNDATION.md` §Updates/Out |
| Prep-time update | **SUPPORTED** (above) and wired in Flutter (`orders_controller.dart:591-608`, `merchant_api.dart:518-538`). Accept with `preparationMinutes 5–120` **SUPPORTED** and wired (`AcceptMerchantOrderDto`, `merchant_api.dart:498-515`). Custom values are supported by the API but not offered in Flutter (presets only). | `merchant-order-write.dto.ts:78-91`, `preparation_time_widgets.dart:9,243` |
| Report-a-problem / support ticket from merchant | **SUPPORTED (text only).** `POST/GET /merchant/:merchantId/support`, `GET …/:ticketId`, `POST …/:ticketId/messages`; body 1–4000 + optional `orderId` (must belong to Merchant). OWNER/MANAGER only, **STAFF forbidden**. No category/subject, no attachments, no draft, no notifications (explicit exclusions). Flutter: endpoint constant `ApiEndpoints.merchantSupport` exists but is **unused**; no client method, screen or route. | `merchant-support.controller.ts:22-93`, `support.dto.ts:21-33`, `SUPPORT_FOUNDATION.md` §Final safe subset / Freeze invariants, `app_constants.dart:116` |
| Driver contact / call | **NOT SUPPORTED.** Merchant delivery GET returns `assignedDriverId` only; "Driver private data is not returned"; FINAL decision "Customer/Merchant assigned-driver summary = `assignedDriverId` only". No driver name, photo, vehicle, plate, rating or phone. Customer phone also excluded from Merchant order detail. | `merchant-delivery.controller.ts:26-31`, `delivery-response.dto.ts:131-192`, `DRIVER_MATCHING.md:348`, `merchant-order.controller.ts:74` |
| Secure handoff code | **NOT SUPPORTED.** No code field in `Delivery`/schema; `confirm-pickup` is Driver-declared, "Merchant confirmation is not required", no body. No Merchant delivery mutation. | `driver-delivery.controller.ts:67-80`, `DRIVER_DELIVERY_WORKFLOW.md:87`, `contract.prisma` (`enum DeliveryStatus` :43; no pickup-code column) |
| Order search / urgent filter | **NOT SUPPORTED.** List query = `branchId`, `orderStatus` (single), `fulfillmentStatus` (single), `limit`, `offset`. No text search, date range, urgency, item-count or multi-status filter. | `merchant-order-write.dto.ts:34-73`, `merchant-order.controller.ts:41-68` |
| Related gaps found | Acceptance expiry: none (no timeout/auto-reject in orders module). Order/kitchen note: no Order note field (only delivery-address `instructions`). Customer order total: not in Merchant DTO. List item count: not in summary DTO. `Delivery.estimatedArrivalAt`: exposed but created `null` and never written. | `contract.prisma` (`model Order` :777, `model OrderDeliveryAddressSnapshot` :857), `merchant-order-response.dto.ts:91-196`, `delivery.repository.ts:195` |

---

## active_orders_list_french

### Design
- **App bar** (sticky, white, h-64px, bottom border outline-variant/20, shadow-sm): title "Commandes" 22px bold `#172033`; subtitle row 12px medium on-surface-variant `Dar El Bahia • ` + 8px dot tertiary-fixed-dim `#b7d15f` + "Ouvert". Right: 44px round button, `notifications` icon + 8px error `#ba1a1a` dot (white border).
- **Segment** (px-4): h-36 rounded-lg surface-container `#e9edff` p-1; active "En cours" primary `#0a4096` white 12px semibold rounded-md shadow-sm; inactive "Historique" 12px medium on-surface-variant.
- **Status tabs** (px-4 py-3): h-44 rounded-xl surface-container-high `#e1e8ff` p-1; selected tab white bg shadow-sm primary 14px semibold; others on-surface-variant medium. Labels verbatim: "Nouveaux (2)", "En préparation (4)", "Prêtes (1)".
- **Search**: h-48 rounded-xl surface-container-highest `#d9e2fc`, `search` icon, placeholder "Rechercher une commande...".
- **Filter chips** (h-32 rounded-full 12px): "Aujourd'hui" + `expand_more` (secondary-fixed `#dde1ff` / on-secondary-fixed); "Urgent" + `priority_high` (error-container `#ffdad6`, on-error-container, border error/20); "Plus de 5 articles" (surface-container-highest).
- **New order card**: white, rounded-2xl (16px), 2px border primary/20, p-4, shadow-sm; top-right ribbon "NOUVEAU" primary bg, 10px bold white uppercase tracking-widest, rounded-bl-xl. Left: "#SG-…" 12px bold primary; name 18px bold. Right: amount 14px bold primary; "2 articles" 10px outline. Banner primary-fixed/30 rounded-lg p-2: `notifications_active` primary + "À accepter immédiatement" 14px semibold on-primary-fixed. Actions: "Accepter" flex-1 primary bold py-3 rounded-xl shadow-md; 48px square outlined (outline-variant) `close` icon error.
- **Hidden variants in html**: preparing card (border outline-variant; row border-y `restaurant` secondary "En préparation" + mono red timer; full-width "Marquer comme prête" tertiary-fixed `#d3ee78` + `check_circle`); ready card (border tertiary-fixed, bg tertiary-fixed/5, inner row `moped` in tertiary-fixed-dim circle, "Prêt" / "En attente livreur", `hourglass_bottom`).
- **Bottom nav**: 5 tabs, Commandes active primary with FILL `receipt_long` + red dot.
- **png vs html**: in png the "NOUVEAU" ribbon covers the amount (only a "1" is visible); html places amount at top-right below ribbon layer. Bottom-nav active icon renders as a dot in png (icon font not loaded).

### Flutter mapping
`AppRoutes.orders` → `OrdersScreen` (`orders_screen.dart`), `ordersListControllerProvider` with `MerchantOrderListFilter` (incoming/accepted/preparing/ready). Card `_OrderListCard`, chips `_StatusFilterBar` (Material `ChoiceChip`), segment `_SegmentBar`. Shell `merchant_shell.dart`.

### Differences
- Header: subtitle shows `operationalStatus` ("Actif") not open/closed; refresh icon instead of bell with unread dot.
- Status tabs are separate `ChoiceChip`s with checkmark in a horizontal scroller, not a single segmented container; count shown only on the selected chip (`list.total`); label "Nouvelles" vs "Nouveaux"; extra "Acceptées" chip (documented, contract state CONFIRMED+ACCEPTED).
- Card: customer name first + `StatusBadge`; `sgo_…` ref line + copy; payment line; "Marchandises" + GMS; "Créée · dd/MM HH:mm". No ribbon, no "À accepter immédiatement" banner, no inline Accepter/✕, no item count, no per-state variants (prep timer / ready moped row). Left 4px primary bar instead of 2px tinted border + ribbon.
- No search field / filter chips.

### Contract
- Chip counts: **SUPPORTED** via `limit=1` `total` per filter (pattern already used in `HomeOrderCountsController`, `orders_controller.dart:224-250`).
- Inline accept/reject from card: **SUPPORTED** (`…/accept` with `preparationMinutes`, `…/reject` with reason), OWNER/MANAGER only.
- Prep timer on preparing card: **SUPPORTED** (`estimatedReadyAt`, `isPreparationLate` on summary DTO).
- Open/closed subtitle: **SUPPORTED** (`MerchantApi.getAvailability`, `merchant_api.dart:280`); bell unread: **SUPPORTED** (`notificationsUnreadCountProvider`).
- Search, "Aujourd'hui", "Urgent", "Plus de 5 articles": **NOT SUPPORTED** (`ListMerchantOrdersQueryDto` has no such params). Item count ("2 articles"): **NOT SUPPORTED** on summary (`CONTRACT_GAPS.md` #6). Client-side filtering of one page would be misleading.

### Alternatives
`merchant_operational_dashboard_french` (home queue) shows similar cards. Documented decisions: canonical `sgo_…` reference, "Marchandises" label, no combined "all active" query (`REFERENCE_COMPARISON.md`, `order_models.dart:481-500`). **Unresolved:** inline accept/reject on list cards vs "open detail only" (`MERCHANT_FINANCIAL_VISIBILITY.md` app table records current behaviour, not a product decision); keep or drop "Acceptées" tab label vs reference's three tabs.

### Required work
1. Header: bell (to `/app/notifications`) with unread dot; subtitle `branch • ● Ouvert/Fermé` from availability; move refresh to pull-to-refresh only.
2. Replace chip row with segmented status container (h-44, surface-container-high, white selected) and show counts on every tab from `total`.
3. Rebuild card per state: ref line 12px bold primary (compact `sgo_…`), name 18px bold, right amount labelled GMS (no item count), NOUVEAU ribbon + "À accepter immédiatement" banner for incoming; prep timer row for PREPARING (server instant); ready row keyed on real delivery status only.
4. Inline Accepter (opens prep sheet) / ✕ (reject sheet) only if product approves and role is OWNER/MANAGER.
5. Omit search/filter chips; record as contract gap.

### Proposed status
`partial_contract_limited`

---

## merchant_order_history_unified

### Design
- Same app bar + segment (Historique active, `mt-2`).
- Filter chips (px-4 py-1.5 rounded-full 12px): "Tout" selected primary/white semibold; "Livré", "Annulé", "Échoué" surface-container-highest + border outline-variant, medium.
- Search field (same as active list) **below** chips.
- Section headers 12px uppercase tracking-wide semibold on-surface-variant: "Aujourd'hui", "Hier".
- Card: white rounded-2xl p-4 gap-3 border outline-variant/30 shadow-sm, 4px full-height left bar (success `#16a34a` / error). Ref 12px bold primary (cancelled: on-surface); time row 14px medium with `schedule` "13:30" (today) or `calendar_today` "Hier"; right amount 14px bold (cancelled: line-through outline) + "N articles" 10px. Chip rounded (4px) px-2 py-1 10px bold with icon 14px: `check_circle` "Livré" (success/10 bg, success/20 border) or `cancel` "Annulé" (error). Cancelled card opacity-75.
- Bottom nav as list. png and html consistent.

### Flutter mapping
`OrdersScreen` with `MerchantOrderListFilter.cancelled|completed|failed` (`historyFilters`), same `_OrderListCard`.

### Differences
- No "Tout"; chips "Annulées / Terminées / Échouées" (order differs: reference Livré first). Default history filter is `cancelled` (`orders_screen.dart:55`).
- No day grouping, no left success/error bar, no icon chips, no strike-through amount, no opacity for cancelled; card shows same fields as active list.

### Contract
- Day grouping, colour bar, icon chips, strike-through: presentation over `createdAt`/`status` — **SUPPORTED**.
- "Tout" (COMPLETED ∪ CANCELLED ∪ FAILED): **NOT SUPPORTED** (single `orderStatus` value; omitting it also returns active orders).
- Search: **NOT SUPPORTED**. Item count: **NOT SUPPORTED** (summary DTO).
- "Livré" wording for `COMPLETED`: order status only; delivery DELIVERED needs per-order delivery GET — use order status label.

### Alternatives
`d_tails_de_la_commande_finance_transparente` is the tap-through for a completed order. Decision on record: explicit chips only, no combined OR query (`MERCHANT_UI_SOURCE_OF_TRUTH.md` §6).

### Required work
1. Chip order and labels aligned to reference wording where truthful ("Livrées"=COMPLETED, "Annulées", "Échouées"); default chip COMPLETED if product agrees.
2. History card variant: left 4px status bar, time/"Hier"/date row with icons, icon status chip, struck amount + reduced opacity for cancelled.
3. Group by local day (Aujourd'hui / Hier / date) client-side on loaded pages.
4. Omit "Tout" and search (contract gap).

### Proposed status
`partial_contract_limited`

---

## incoming_order_alert_french

### Design
- Full-screen, no app bar. **Header** primary `#0a4096` pt-48 pb-32, two decorative white ring circles at 10% opacity; centered "NOUVELLE COMMANDE" label-lg tertiary-fixed `#d3ee78` uppercase tracking-widest; row FILL `timer` 36px (pulse) + countdown "01:41" headline-lg (32/700) **error red**.
- **Body sheet** surface, `-mt-4 rounded-t-3xl`, px-16 py-24:
  - Store row: 48px rounded-xl logo tile (border outline-variant) + "Dar El Benna" title-lg + "Gérant: Amine Bensaïd" label-md; right chip tertiary-fixed rounded-full `bolt` "Urgent".
  - Bento grid 2 cols gap-16, cards white rounded-2xl border outline-variant, shadow `0 4px 20px -4px rgba(10,64,150,.08)`:
    - Customer (col-span-2): 48px circle secondary-container FILL `person`; "Client" label-md + name title-md; right "Commande" label-md + "#SG-…" title-md primary.
    - Two tiles h-128: FILL `schedule` primary top; "Reçue à" + "13:05" title-lg; FILL `payments` + "Paiement" + "À la livraison" label-lg.
    - Items (col-span-2): surface-container-low, **dashed** border, header `restaurant_menu` "4 Articles" title-md + "Voir la liste" primary label-lg; rows body-md on-surface-variant "1x Couscous Royal (Agneau)" … price right; divider; "Total de la commande" label-lg + "2,250 DZD" headline-md primary.
- **Footer** fixed white, border-t, shadow `0 -8px 30px rgba(0,0,0,.06)`, p-16 gap-12: "Voir les détails" h-56 primary rounded-xl `visibility`; "Refuser" h-56 white, error border/text, `cancel`.
- **png vs html**: png payment icon is a card glyph (html `payments`); timer "01:38" vs "01:41"; html fontSize token `number-xl` typo `400px`.

### Flutter mapping
`IncomingOrderAlertOverlay` (`incoming_order_alert_overlay.dart`) hosted by `MerchantAlertHost`; data `IncomingOrderAlert.fromDetail`. Live capture `audit/phase-5-ui/order-alerts-live/alert-incoming.png`.

### Differences
- Header is a left-aligned 20px/800 label + close ✕ on blue; no centered layout, no rings, no timer (correct omission).
- Body is a floating white card on blue (rest of screen blue), not a rounded-top sheet over surface.
- Customer row: avatar + name with `sgo_…` ref underneath (reference: "Client"/"Commande" two-column).
- Fact tiles are compact horizontal rows (surfaceContainerLow, radius 8) not tall white bordered tiles.
- Items: plain list, no dashed container, no header icon/"Voir la liste".
- **Label risk**: "Total de la commande" shows `grossMerchandiseSubtotalMinor` (GMS), not a customer total.
- Footer: buttons on blue; primary-container fill 48h; Refuser 44h `close` icon; no white footer bar.

### Contract
- Receipt time, payment method, items, GMS: **SUPPORTED** (order detail).
- Countdown/expiry: **NOT SUPPORTED** (no acceptance timeout). "Urgent": **NOT SUPPORTED** (no concept). Store logo: **NOT SUPPORTED** (`CONTRACT_GAPS.md` #3; branch cover exists). Manager name: not in order/alert data.
- Customer total: **NOT SUPPORTED** in Merchant DTO.
- Refuser: **SUPPORTED** (reject), hidden for STAFF (already).

### Alternatives
`incoming_order_details_french` (tap-through). Evidence `ORDER_ALERT_LIVE_REPORT.md`. SoT §6 still lists this folder `not_in_scope` although the overlay is implemented — doc is stale.

### Required work
1. Layout: blue header block (centered label, decorative rings optional) with white `rounded-t-3xl` body sheet; white fixed footer with shadow; h-56 buttons (`visibility` / `cancel`).
2. Customer card two-column ("Client" / "Commande" + compact ref); tall bento fact tiles with filled icons.
3. Items card dashed with header icon; "Voir la liste" → opens detail (or omit).
4. Rename total label to the GMS wording ("Sous-total marchandises"/"Marchandises") — do not show "Total de la commande".
5. No countdown, Urgent chip, logo or manager line.

### Proposed status
`needs_work`

---

## incoming_order_details_french

### Design
- App bar h-56 surface shadow-sm: `menu` + "SpeedyGo Merchant" title-lg primary; right `notifications`. No bottom nav (comment: shell suppressed).
- Identity block: primary-container `#2f59af` / on-primary-container, rounded-xl p-16 shadow-md border-b-2 primary: "NOUVELLE COMMANDE" label-md uppercase 80%; "#SG-…" headline-md bold; "Reçue à 13:05 • Sidi Djillali" body-md. Right timer box surface-lowest rounded-lg "EXPIRE DANS" + number-xl red "01:42" (pulse).
- Customer card white rounded-xl border: 48px secondary-container `person`; name title-md; "Client fidèle • 12 commandes"; red note block error-container, left 4px error border, `warning`, "NOTE SPÉCIALE :" label-lg bold uppercase + ""Sans piment"" title-md.
- "Articles (5)" title-lg + store chip "Dar El Benna" label-md surface-container-high. Items card rows p-16 border-b: qty "1×" title-lg primary w-32, name title-md, description body-md on-surface-variant, price label-lg right.
- Summary surface-container-low rounded-xl border: "Sous-total", "Frais de livraison", divider, "Total" title-lg + headline-md primary bold; payment chip secondary-container/20 `payments` "Paiement à la livraison" + "CASH".
- Sticky footer: "Refuser" flex-1 h-56 border-2 error; "Choisir le temps de préparation" flex-2 h-56 primary shadow-lg.
- **png vs html**: "Articles (5)" but 4 rows; subtotal 1,750 ≠ row sum; png shows timer box overflowing the block.

### Flutter mapping
`AppRoutes.orderDetail` → `OrderDetailScreen`, incoming branch: `_HeaderCard` (banner "Nouvelle commande"), `_ItemsCard`, `_AddressCard`, `_FinanceCard`, `_StickyActions`/`_IncomingActionRow` (Refuser | Accepter).

### Differences
- App bar "Commande" + refresh (reference brand title — shell rule favours task title; keep task title).
- Header is a white card with a warning-toned banner; no primary-container identity block with received time + locality.
- No customer sub-line; no note block.
- Items title "Articles (N)" without store chip; item price styling similar; options shown as "· option (+x)".
- Finance card shows GMS/commission/net/delivery fee instead of subtotal/fee/total + payment chip.
- CTA copy "Accepter" though it opens the prep-time sheet.

### Contract
- Received time, address text, items, options, payment method: **SUPPORTED**.
- Expiry countdown: **NOT SUPPORTED**. Loyalty ("Client fidèle • 12 commandes"): **NOT SUPPORTED**. Kitchen note: **NOT SUPPORTED** (no Order note field; address `instructions` is delivery info, not a kitchen note). Customer total: **NOT SUPPORTED** (DTO has GMS, discount, commission, net, delivery fee only).
- Accept with prep time: **SUPPORTED**.

### Alternatives
`incoming_order_alert_french`; `accept_order_and_preparation_time_french` (next step). SoT §6 claims "prep-time gate on accept" unsupported — stale (accept body supports `preparationMinutes`).

### Required work
1. Replace `_HeaderCard` (incoming) with primary-container identity block: label, compact ref, "Reçue à HH:mm • {address locality}" (no timer box).
2. Customer card without loyalty line or note.
3. Items header with branch name chip; qty column title-lg primary.
4. Summary: keep contract labels (GMS, delivery fee client) — no computed "Total"; payment chip with method.
5. CTA copy "Choisir le temps de préparation" (flex-2) + "Refuser" (flex-1, 2px error border), h-56.

### Proposed status
`partial_contract_limited`

---

## accept_order_and_preparation_time_french

### Design
- Full-screen page. App bar h-56: `arrow_back` primary; "Accepter la commande" title-lg primary + "#SG-…" label-md; right `help_outline`.
- "Établissement" badge surface-container-low rounded-xl: 40px primary circle initial "D" + label-lg uppercase "ÉTABLISSEMENT" + title-md store name.
- Summary card white rounded-xl border shadow `0 2px 8px rgba(0,0,0,.04)`: 48px customer photo; name title-md; "4 articles • Livraison SpeedyGo"; right amount headline-md primary; divider; `location_on` + address body-md.
- "Temps de préparation estimé" title-lg + "Sélectionnez le temps nécessaire pour préparer les 4 articles." body-md.
- Bento grid 2 cols gap-12, tiles h-72 border outline-variant rounded-xl white: "15" headline-md + "MINUTES" label-md; "20"; full-width selected tile "25 min" + "RECOMMANDÉ" + `auto_awesome` 32px (selected style primary bg white text); "30"; "45".
- "Temps personnalisé" row dashed outline rounded-xl primary title-md `more_time` + `chevron_right`.
- Callout tertiary-fixed `#d3ee78` `info`: "Le client sera informé de l'heure de livraison estimée et un livreur sera dépêché automatiquement."
- Footer: "Confirmer et Accepter" h-52 primary `check_circle`; "Refuser la commande" h-48 text error.

### Flutter mapping
`showAcceptPreparationSheet` (`preparation_time_widgets.dart:38-139`) invoked by `_acceptWithPrep` in `order_detail_screen.dart:190-203`. Capture `audit/phase-5-ui/prep-time-live/prep-accept-sheet.png`.

### Differences
- Modal bottom sheet, not a page; no store badge, no summary card (only ref under title).
- Presets as Material `ChoiceChip`s ("15 min"…) in a `Wrap`, default 25 selected without label; no bento tiles.
- No custom time; no callout; CTA "Confirmer l’acceptation" (no icon in reference wording "Confirmer et Accepter"); secondary "Annuler" instead of "Refuser la commande".

### Contract
- Presets and custom value: **SUPPORTED** (`preparationMinutes` 5–120).
- "Recommandé": **NOT SUPPORTED** (no rule; removed deliberately per `PREP_TIME_LIVE_REPORT.md` §C).
- Callout claims (customer informed, driver auto-dispatched at accept): **NOT SUPPORTED** / untrue — no customer delay/ETA push; Delivery is created by matching after READY, not at accept.
- Customer photo: **NOT SUPPORTED**. Branch name/address: available (access branch; address from order).

### Alternatives
`incoming_order_details_french` CTA leads here. Documented decision: no "Recommandé".

### Required work
1. Sheet (or page) parity: header title + ref; branch badge; summary card (initial avatar, item count from items, GMS labelled, address).
2. Bento tiles h-72 (value headline-md + "MINUTES"); selected = primary fill; no Recommandé/`auto_awesome`.
3. "Temps personnalisé" row → numeric input bounded 5–120.
4. No impact callout (or truthful neutral copy only if product writes one).
5. CTA "Confirmer et Accepter" with `check_circle`; secondary "Refuser la commande" opens reject sheet (OWNER/MANAGER).

### Proposed status
`needs_work`

---

## commande_en_pr_paration_tat_initial

### Design
- Sticky header surface border-b px-16 py-12: `arrow_back`; "Commande en préparation" title-md + "#SG-…" label-md uppercase; right chip tertiary-fixed rounded-full label-md bold "EN PRÉPARATION". Second row right: `cloud_done` 16px + "Synchronisé" label-md primary.
- Timer section white border-b p-24 centered: "TEMPS DE PRÉPARATION RESTANT" label-lg uppercase tracking-widest; two boxes w-80 h-96 primary-container `#2f59af` white "18" / "42" headline-lg bold, rounded-lg, glow shadow; ":" headline-lg primary; captions "Minutes" / "Secondes"; pill surface-container rounded-full `schedule` "Prévu pour **13:30**".
- 2-col tiles surface-container-low rounded-lg border p-16: "Client" / name title-md / locality body-md / outlined "Appeler" chip (`call`); "Paiement" / "2 250 DZD" title-md / error `payments` "Paiement à la livraison".
- Note block error-container border-2 error: FILL `warning` + "NOTE DU CLIENT : 'SANS PIMENT'" title-md bold uppercase.
- Checklist header surface-container border-y: "Articles à préparer" title-md bold + "Tout cocher" primary; "4 produits • 5 unités" label-md. Rows p-16 divide-y: 32px rounded-lg checkbox (border-2 outline; checked primary-container + white `check`), name title-md + "x1" bold right. Checked rows go 50% + line-through.
- Footer shadow `0 -8px 30px rgba(0,0,0,.08)`: 2-col h-48 surface-container-highest buttons `timer` "Modifier temps" / `headset_mic` "Support"; full-width h-56 "Marquer comme prête" **disabled** (surface-variant, 50%).
- **png vs html**: png is rendered in dark mode (black header/sections, unreadable text); html is light. Use html.

### Flutter mapping
`OrderDetailScreen` with `fulfillmentStatus=ACCEPTED` (`status=CONFIRMED`): `_HeaderCard` (banner "Acceptée"), `PreparationCountdownBanner` (if `estimatedReadyAt`), `_ItemsCard(emphasizePrep)`, address, finance, history; sticky "Démarrer la préparation". Capture `prep-time-live/prep-countdown.png`.

### Differences
- App bar "Commande" + refresh; no state title/ref/status chip.
- Countdown is a text card ("Temps restant · 24:54" + TextButton "Modifier temps" + "Heure prévue : 04:48"); no big MM:SS boxes, no "Prévu pour" pill.
- No Client/Paiement tiles; items card without checkboxes/"Tout cocher"/"N produits • N unités".
- Footer: single "Démarrer la préparation"; no Modifier temps / Support buttons in footer.
- Extra cards (address, finance, history) visible in this state.

### Contract
- Countdown/prévu: **SUPPORTED** (`estimatedReadyAt`, branch clock `prep_time_clock.dart`). Modifier temps: **SUPPORTED**. Support: **SUPPORTED** (OWNER/MANAGER). Item/unit counts: **SUPPORTED** (items).
- Appeler (customer): **NOT SUPPORTED** (no customer phone to Merchant). Note: **NOT SUPPORTED**. "Synchronisé": **NOT SUPPORTED** (no realtime channel for merchant orders; pull only).
- Reference shows no start step; backend requires `start-preparation` (CONFIRMED+ACCEPTED → ACTIVE+PREPARING). Checklist is local-only; no persistence endpoint.

### Alternatives
`preparing_order_french_1` (duplicate + kitchen photo), `commande_en_pr_paration_en_cours`, `preparing_order_french_2`. Conflicts: status chip style (tertiary-fixed here vs primary-container/10 in `…en_cours`); timer box style (solid primary-container here vs light surface-container-highest boxes in `…en_cours`). SoT §6 forbids checklists that change eligibility.

### Required work
1. State app bar: title "Commande en préparation" (ACCEPTED: consider "Commande acceptée" — product copy), ref subtitle, status chip right; no "Synchronisé".
2. Countdown component with MM:SS boxes + captions + "Prévu pour HH:mm" pill from server instant; late state per `delayed_order_french`.
3. Client tile (name, locality from address, no Appeler) + Paiement tile (GMS labelled, method in error tone if COD).
4. Items list with counts header; checkboxes only if product approves as purely local aid (not persisted, not gating).
5. Footer: Modifier temps + Support (OWNER/MANAGER; STAFF hides both) above primary "Démarrer la préparation" (contract step retained).

### Proposed status
`partial_contract_limited`

---

## commande_en_pr_paration_en_cours

### Design
- Sticky header surface/90 blur border-b: `arrow_back` 40px; "Commande #SG-…" 18px bold; chip primary-container/10 border primary-container/20 "EN PRÉPARATION" 12px bold primary uppercase. Row right: FILL `sync` 14px + "SYNCHRONISÉ" 11px semibold uppercase primary 70%.
- "TEMPS DE PRÉPARATION RESTANT" 12px bold uppercase; two flex boxes h-64 rounded-xl surface-container-highest `#d9e2fc` border outline-variant/30 with "11" / "40" 30px bold on-surface; captions "MINUTES"/"SECONDES" 12px bold uppercase. "Prêt à 13:30 (Heure locale)" 14px italic.
- Customer card white rounded-xl border shadow-sm: 56px photo; name 16px bold; `location_on` "Sidi Djillali"; chips "PAIEMENT COD" (tertiary-container bg, tertiary text, 10px bold) + "2 250 DZD" (surface-container); right 40px round outlined `call`.
- Note: error-container, left 4px error, FILL `warning`, "NOTE DU CLIENT :" 14px black uppercase error + "Sans piment" 18px bold.
- "Articles à préparer" 18px bold + pill "2/4 produits préparés" 12px bold surface-container. Item cards white rounded-xl border p-16: 24px checkbox; "1x Couscous Royal" 18px bold + italic description 14px; checked = strike/opacity.
- Footer white border-t shadow `0 -4px 20px rgba(0,0,0,.05)`: 2-col h-48 rounded-xl border outline surface-container-low bold 14px `schedule` "Modifier temps" / `help` "Support"; h-56 "Marquer comme prête" `check_circle` **disabled** (outline-variant, 50%).
- **png vs html**: seconds 38 (png) vs 40 (html).

### Flutter mapping
`OrderDetailScreen` `status=ACTIVE`, `fulfillmentStatus=PREPARING`: `_HeaderCard` banner "En préparation", `PreparationCountdownBanner`, `_ItemsCard`, sticky `order-mark-ready` "Marquer comme prête".

### Differences
As `…_tat_initial`, plus: no customer card with photo/COD chips/call; no progress pill; items not card-per-row; "Marquer comme prête" enabled (correct per contract; reference disables pending checklist).

### Contract
Same as `…_tat_initial`. Mark-ready: **SUPPORTED** (`…/mark-ready`, OWNER/MANAGER). "2/4 produits préparés": local-only (no endpoint).

### Alternatives
`preparing_order_french_2` shows the same screen with 0 checked and CTA **enabled** — this matches the contract (no gating). **Unresolved:** which timer-box and chip style is canonical (this light style vs `…_tat_initial` solid style).

### Required work
1. Reuse the preparing layout from `…_tat_initial` with this variant's app bar ("Commande {ref}" + chip) if chosen canonical.
2. Customer card: initial avatar (no photo), locality, method chip + GMS chip; no call button.
3. Item cards with qty prefix + options italic; optional local checkboxes/pill only if approved, never disabling mark-ready.
4. Footer: outlined Modifier temps / Support + primary "Marquer comme prête" (enabled for OWNER/MANAGER; hidden for STAFF).

### Proposed status
`partial_contract_limited`

---

## preparing_order_french_1

### Design
Same structure as `commande_en_pr_paration_tat_initial` (header chip "PRÉPARATION", timer title "Temps restant", solid primary-container boxes `rounded-xl`, Client tile with text "Appeler" link, Paiement tile "2,250 DZD" / "À la livraison", note "Note Importante" + ""Sans piment"", checklist header "ARTICLES (4)" label-lg uppercase + "Tout cocher", rows with descriptions "Portion standard, semoule fine"). Extra: 192px rounded-2xl stock kitchen photo with gradient caption "Dar El Benna - Poste de Cuisine". Footer: Modifier temps / Support + html CTA "PRÊT POUR RETRAIT / LIVRAISON" primary. **png vs html**: png shows no primary CTA (only the two secondary buttons).

### Flutter mapping
Same as `commande_en_pr_paration_tat_initial` (ACCEPTED/PREPARING detail).

### Differences
Same as `…_tat_initial`; kitchen image absent (correct).

### Contract
Kitchen photo: **NOT SUPPORTED** (no such media; branch cover exists but would be decorative). Rest as `…_tat_initial`.

### Alternatives
Duplicate of `commande_en_pr_paration_tat_initial`. CTA wording "PRÊT POUR RETRAIT / LIVRAISON" conflicts with "Marquer comme prête" elsewhere (unresolved copy).

### Required work
None separately; covered by `…_tat_initial` / `…_en_cours`.

### Proposed status
`not_applicable_duplicate`

---

## preparing_order_french_2

### Design
Identical to `commande_en_pr_paration_en_cours` except: timer "14:29" (png) / "18:41" (html); customer card shows only "PAIEMENT COD" chip (no amount chip); pill "4 produits • 5 unités"; all items unchecked; "Marquer comme prête" **enabled** primary h-56 shadow-lg `check_circle`.

### Flutter mapping
`OrderDetailScreen` PREPARING.

### Differences
As `…_en_cours`.

### Contract
As `…_en_cours`.

### Alternatives
Duplicate of `commande_en_pr_paration_en_cours`; this variant's enabled CTA and "N produits • N unités" pill are the contract-compatible choices.

### Required work
None separately.

### Proposed status
`not_applicable_duplicate`

---

## mise_jour_du_temps_de_pr_paration

### Design
- Full-screen. Header h-64 border-b: `close` left; centered "Mise à jour du temps" headline-md bold; right spacer.
- Context: "COMMANDE #SG-…" label-md uppercase; FILL `person` + name title-lg.
- State card white rounded-lg (8px) border shadow-sm p-16: 40px secondary-container circle `schedule`; "Heure prévue actuelle" body-md + "13:30" title-md; right chip surface-container-highest border `hourglass_top` "En cours" label-md.
- "Ajouter du temps de préparation" title-md; grid 4 cols gap-8: "+5" "+10" "+15" "+20" py-12 rounded-lg title-md; selected primary-container bg / on-primary-container text; others white border.
- "Saisie personnalisée" text button primary `edit`.
- Comparison card surface-container rounded-lg border, corner ribbon primary "+10 min" label-md bold rounded-bl-lg; "Nouvelle estimation" title-md; left struck "Heure actuelle" / "13:30"; `arrow_forward` outline; right "Nouvelle estimation" primary bold + "13:40" headline-md primary bold.
- Info banner surface-container-high FILL `info`: "Le client sera immédiatement informé de cette nouvelle estimation. Si un livreur est déjà affecté à la commande, il sera également notifié."
- "Raison du retard (Optionnel)" title-md label above textarea rows=3 white border rounded-lg, placeholder "Ex : Problème technique en cuisine…".
- Footer: "Annuler" flex-1 h-48 white border primary; "Mettre à jour" flex-2 h-48 primary bold + `update`.
- **Note**: selected chip text on-primary-container `#c7d5ff` on `#2f59af` is low contrast.

### Flutter mapping
`showUpdatePreparationSheet` (`preparation_time_widgets.dart:141-298`) opened from `PreparationCountdownBanner.onUpdate` (OWNER/MANAGER, not mutating). Capture `prep-time-live/prep-update-sheet.png`.

### Differences
- Bottom sheet with left title, no close icon, no order/customer context header.
- State card: "Heure prévue actuelle" + time headline + "Initiale : HH:mm"; no icon circle, no "En cours" chip.
- Presets are `ChoiceChip`s with checkmark in a `Wrap`, selected primary-container + white text (better contrast than reference).
- No "Saisie personnalisée".
- Preview is one line "Nouvelle estimation : 04:48 → 04:58 (+10 min)" in a card, not the comparison card with ribbon.
- No info banner (correct: no notification contract).
- Reason: floating-label `OutlineInputBorder` with 0/255 counter; footer buttons without icon.

### Contract
- +N minutes, reason, optimistic version: **SUPPORTED** (`addMinutes` 1–60 → custom input feasible). Conflict 409 returns current projection (handled by reconcile in `runAction`).
- Notification of customer/driver: **NOT SUPPORTED** (not claimed).
- Customer name in header: **SUPPORTED** (`customerFullName`).

### Alternatives
`update_preparation_time_french` (variant), `delayed_order_french` (late entry). Decision on record: late display derived, no auto-READY.

### Required work
1. Sheet header with close ✕ + centered title; context line (compact ref + customer name).
2. State card with icon circle and state chip ("En cours"/"En retard").
3. 4-col equal preset grid (keep white-on-blue selected for contrast) + "Saisie personnalisée" numeric input 1–60.
4. Comparison card (struck current → new, "+N min" ribbon) from `prepEstimatePreview`.
5. Label-above textarea "Raison du retard (Optionnel)"; footer Annuler / Mettre à jour + `update` icon.
6. No notification banner.

### Proposed status
`partial_contract_limited`

---

## update_preparation_time_french

### Design
Identical to `mise_jour_du_temps_de_pr_paration` except: state label "Heure prévue initiale"; comparison labels "Ancienne" / "Nouvelle"; banner "**Sara Belkacem** (Client) et **Yacine Mansouri** (Livreur) seront notifiés immédiatement de ce retard."; placeholder "Ex: Problème technique en cuisine...".

### Flutter mapping
Same sheet as `mise_jour…`.

### Differences
As `mise_jour…`.

### Contract
Named driver: **NOT SUPPORTED** (assignedDriverId only). Notifications: **NOT SUPPORTED**. "Heure prévue initiale" label: the state card shows the current estimate, which is not the initial one after a revision — `originalEstimatedReadyAt` is the initial; mislabel risk.

### Alternatives
Variant of `mise_jour_du_temps_de_pr_paration`.

### Required work
None separately; "Ancienne/Nouvelle" short labels may be reused if copy owner prefers.

### Proposed status
`not_applicable_duplicate`

---

## delayed_order_french

### Design
- Header h-56 shadow-sm: `close`; centered "Commande retardée" title-md + "#SG-…" label-md; right `sync` 14px primary.
- Alert card error-container/30, border error (pulsing), rounded-xl centered: faint 100px FILL `warning` watermark; `timer_off` 32px error; "8 minutes de retard" headline-md; "L'heure de préparation initiale était prévue à 13:30." body-md.
- "Motif du retard" title-md + "Sélectionnez la raison pour informer le client et le livreur."; 2×2 radio tiles rounded-lg border, selected primary border + primary-fixed/20 + primary text: `groups` "Forte affluence", `skillet` "Préparation longue", `grocery` "Ingrédient manquant", `more_horiz` "Autre raison" (reveals textarea "Précisez la raison...").
- "Nouvelle heure" card white rounded-xl shadow `0 2px 8px rgba(0,0,0,.04)`: chip "Prévu: 13:30"; row 48px round `remove` / time input w-128 h-64 number-xl primary "13:42" / `add`; "Le client sera notifié du nouveau délai (+12 min)."
- "Impact sur la livraison": list card; row 1 `person` + name + `schedule` "Nouvelle ETA: ~14:15"; row 2 surface-container-low `two_wheeler` + driver name + error `hourglass_empty` "Livreur en attente au restaurant".
- Footer: "Confirmer l'heure révisée" h-52 primary `update`; "Contacter le support" h-48 outlined `support_agent`.
- **png vs html**: png shows time input empty and driver icon as bike glyph.

### Flutter mapping
No dedicated screen. Late state lives in `PreparationCountdownBanner` (`preparation_time_widgets.dart:301-465`: `timer_off`, "N min de retard", `prepLateHint`) + the update sheet.

### Differences
Late shown as a banner line + error hint inside a white card; no hero card, no reason tiles, no +/- time editor, no impact list, no support CTA.

### Contract
- Lateness minutes: **SUPPORTED** (derived from `estimatedReadyAt` / `isPreparationLate`); initial time: **SUPPORTED** (`originalEstimatedReadyAt`).
- Revision: **PARTIAL** — add-only (1–60 min); "−" decrease **NOT SUPPORTED**; absolute time input must be converted to `addMinutes` (positive).
- Reason chips: **NOT SUPPORTED** as a taxonomy (free text ≤255 only).
- Customer ETA, notifications: **NOT SUPPORTED**. Driver row: name **NOT SUPPORTED**; "driver waiting at restaurant" derivable anonymously from delivery `AT_PICKUP` — **PARTIAL**.
- Support: **SUPPORTED** (OWNER/MANAGER).

### Alternatives
`mise_jour_du_temps_de_pr_paration` is the editor; this screen is the late-state entry. **Unresolved:** whether reason tiles may prefill free-text `reason` (product copy decision; must not be presented as a server taxonomy).

### Required work
1. Late hero card in detail (or dedicated sheet) with minutes late + initial time, driven by server instant.
2. "Nouvelle heure" control: `+` only (steps within 1–60), preview time and delta; no `−`.
3. Optional reason input (free text); tiles only if product approves as text prefills.
4. Optional anonymous "Livreur au restaurant" line only when delivery status is `AT_PICKUP`.
5. Footer "Confirmer l'heure révisée" + "Contacter le support" (support form, OWNER/MANAGER). No notification copy.

### Proposed status
`partial_contract_limited`

---

## mark_order_ready_french

### Design
- Fixed header h-56 shadow `0 2px 8px rgba(0,0,0,.04)` border-b: `arrow_back`; "#SG-…" title-md primary; right chip tertiary-container/10 border tertiary-fixed `cooking` "En préparation" label-md tertiary-container.
- Checklist card white rounded-xl border surface-container-highest p-16: `checklist` primary + "Liste de colisage" title-lg; right "0/5 vérifiés" label-md + "✓ Tout est emballé" primary label-lg; hint "Vérifiez que tous les éléments de la commande sont bien emballés avant de la marquer prête."; rows 20px checkbox + title-md "1x Couscous Royal", … , "Couverts & Serviettes".
- Note block error-container/20 border error-container: `warning` "Note Client" label-lg + ""Sans piment"" title-md bold.
- Footer px-20: "Confirmer et marquer prêt" h-56 primary-container `#2f59af` bold; "Retour" h-52 outlined primary.

### Flutter mapping
`_StickyActions` → `order-mark-ready` "Marquer comme prête" calls `markReady()` directly (`order_detail_screen.dart:1038-1044`, `orders_controller.dart:635-645`).

### Differences
No confirmation step, no packing list, no note; one-tap mutation.

### Contract
Mark-ready: **SUPPORTED**. Packing checklist: local-only (no endpoint). "Couverts & Serviettes": not an order item (invented row). Note: **NOT SUPPORTED**.

### Alternatives
Preparing refs also place "Marquer comme prête" in the footer. SoT §6 bans checklists that change eligibility.

### Required work
1. Optional confirmation sheet/page before `markReady`: header ref + state chip, items as list (from order items only, no invented extras), CTA "Confirmer et marquer prêt" + "Retour".
2. Checkboxes purely informative if product approves; CTA always enabled.
3. OWNER/MANAGER only.

### Proposed status
`needs_work`

---

## waiting_for_driver_french

### Design
- Header h-56 surface/90 blur: `arrow_back`; right pill surface-container FILL `cloud_sync` "Synchronisé".
- Hero: pill tertiary-fixed border tertiary-fixed-dim shadow-sm FILL `check_circle` + "COMMANDE PRÊTE" label-lg uppercase on-tertiary-fixed-variant; "Prête depuis 13:28" body-md.
- Dispatch card surface-container-highest rounded-2xl min-h-220: two radar rings (animated) around 64px primary circle FILL `motorcycle`; "Recherche de livreur..." title-lg primary; `schedule` "Temps d'attente estimé: 02:45".
- Order card white rounded-xl border shadow `0 2px 8px rgba(18,27,46,.04)`: "#SG-…" title-md + `person` name; right "2 250 DZD" title-lg primary + "Payé en ligne" label-md; rows "1x Couscous Royal … 1 200 DZD".
- Pickup card: `storefront` "Détails du ramassage"; inner surface-container-low `location_on` "Dar El Benna" / "Sidi Bel Abbès, Centre Ville".
- Footer blur: "Actualiser" h-52 primary `refresh`; "Contacter le support" h-48 outlined `support_agent`.

### Flutter mapping
`OrderDetailScreen` `fulfillmentStatus=READY`: `_ReadyStatusSection` (pill "Commande prête"; "Recherche de livreur" only if `delivery.status=SEARCHING_DRIVER`, else "Un livreur est assigné." / "En attente de prise en charge…"), `_ReadySummaryCard`, items, address, finance, `_DeliveryCard`, history. No sticky actions.

### Differences
- No "Prête depuis"; no dispatch card with icon; search copy is a text line.
- Summary card lacks amount/payment status and items (items in a separate card).
- No pickup card; no Actualiser / Contacter le support footer.
- `_DeliveryCard` shows technical copy "Arrivée estimée (serveur)" and a static "confirmation de remise sécurisée n’est pas disponible…" sentence.

### Contract
- "Prête depuis": **SUPPORTED** (`statusHistory` `ORDER_READY.occurredAt`).
- Search state: **SUPPORTED** (`delivery.status`, `driverSearchStartedAt`).
- Wait-time estimate: **NOT SUPPORTED**. Radar animation: presentation; acceptable only while status is `SEARCHING_DRIVER` (product call).
- Payment status "Payé en ligne": **SUPPORTED** (`payment.method` + `payment.status`).
- Pickup name/address (+ branch phone): **SUPPORTED** in `MerchantDeliveryResponseDto.pickup`, but Flutter `MerchantDeliverySummary` does not parse `pickup`, `dropoff`, `events`.
- Actualiser: **SUPPORTED** (reload). Support: **SUPPORTED** (OWNER/MANAGER).

### Alternatives
`driver_assigned_call_action_at_bottom`, `driver_arrived_french` (next delivery states). Decision on record: search copy only on authoritative status.

### Required work
1. Hero pill + "Prête depuis HH:mm" from ORDER_READY event.
2. Dispatch card (static icon; optional pulse only while `SEARCHING_DRIVER`); no wait ETA; fallback copy when no delivery yet.
3. Order card: compact ref, customer, GMS labelled + payment method/status, item lines.
4. Pickup card from `delivery.pickup` (extend model) or selected branch.
5. Sticky footer: Actualiser + Contacter le support (support hidden for STAFF).
6. Remove technical strings from `_DeliveryCard` (`orderHandoffUnsupported`, "(serveur)").

### Proposed status
`needs_work`

---

## driver_assigned_call_action_at_bottom

### Design
- Fixed header (two rows): `arrow_back`; "#SG-…" headline-md bold primary; right `more_vert`. Row 2: `schedule` tertiary-fixed-dim + "En attente du livreur"; chip tertiary-fixed-dim/20 border FILL `check_circle` "COMMANDE PRÊTE" uppercase.
- Driver card white rounded-xl shadow `0 2px 8px rgba(0,0,0,.04)` border surface-container-high: 64px photo; "Yacine Mansouri" title-lg; chip "Moto" + ★ `#f59e0b` "4.9"; right "Statut" / "Livreur en route" title-md primary. Inner ETA box surface-container-low: 40px primary/10 `navigation`; "TEMPS ESTIMÉ" label-md; "Arrivée dans 7 min" headline-md primary; `refresh` "Actualiser".
- "Résumé de la Commande" rows with dividers: Client / name; Articles / "4 articles"; "Total (COD)" / "2 250 DZD" title-lg primary.
- "Point de Retrait" `storefront`: branch name + address; inner `info` "NOTE POUR LE LIVREUR" / "Entrée côté retrait".
- Footer: "Appeler le livreur" h-56 primary-container `call`; "Contacter le support" h-52 outlined primary.
- **png**: fixed header overlaps the driver card top (layout artifact).

### Flutter mapping
`OrderDetailScreen` READY with `_ReadyStatusSection` (`DRIVER_ASSIGNED` → "Un livreur est assigné.") and `_DeliveryCard` (badge "Livreur assigné"). `TO_PICKUP` falls to `default` → raw "TO_PICKUP" badge.

### Differences
No driver card, no ETA box, no call CTA; header generic; status label missing for `TO_PICKUP`; no summary rows/pickup card/support.

### Contract
- Driver name/photo/vehicle/rating/phone and call: **NOT SUPPORTED** (FINAL `assignedDriverId` only).
- "Livreur en route": **SUPPORTED** (`delivery.status=TO_PICKUP`).
- ETA: **NOT SUPPORTED** (`estimatedArrivalAt` never written).
- Summary (client, item count from items, GMS): **SUPPORTED**; "Total (COD)" customer total **NOT SUPPORTED**.
- Pickup: **SUPPORTED** (`delivery.pickup`); "Note pour le livreur": **NOT SUPPORTED** (no field).
- `more_vert`: no defined actions (omit).

### Alternatives
`driver_arrived_french`, `waiting_for_driver_french`. SoT §6 `partial`.

### Required work
1. Two-row header with ref + "En attente du livreur" + ready chip.
2. Anonymous delivery status card: "Livreur assigné" / "Livreur en route" (TO_PICKUP) with icon; no name/photo/rating/ETA.
3. Summary rows (Client, Articles from items, Marchandises GMS); pickup card from delivery pickup.
4. Footer: "Contacter le support" only; no call button.
5. Add missing delivery status labels (TO_PICKUP, AT_PICKUP, IN_TRANSIT, FAILED, CANCELLED).

### Proposed status
`partial_contract_limited`

---

## driver_arrived_french

### Design
- Header h-64 border-b: `close` primary; centered "Détails de la commande" title-lg semibold.
- Arrival banner primary-container rounded-xl shadow-lg border-2 pulsing: `directions_bike` 32px + "Livreur Arrivé" headline-lg bold; "Veuillez remettre la commande." body-lg; inner glass row: `timer` "TEMPS D'ATTENTE" / "02:15" title-lg bold | divider | "HEURE D'ARRIVÉE" / "13:36".
- "Informations Livreur" card: header surface-container-low + chip tertiary-fixed FILL `star` "4.9"; 64px photo; name headline-md bold; `two_wheeler` "Moto • Plaque: 16-12345"; 48px primary-container/10 `call` button.
- Order card: "RÉF COMMANDE" label + "#SG-…" title-lg bold; right chip secondary-container "2 / Colis"; "Contenu à remettre" title-md; list "1x" title-md primary + name body-lg + description; footer surface-container-low "PAIEMENT CLIENT" / "Espèces (Livreur encaisse)" + "2,250 DZD" title-lg bold.
- Footer blur: "Confirmer la remise" h-52 primary `verified`; "Signaler un problème" h-48 outlined `report_problem`.

### Flutter mapping
`OrderDetailScreen` READY + delivery. `AT_PICKUP` unmapped in `_deliveryStatusLabel` (raw "AT_PICKUP"); `ARRIVED_CUSTOMER` is labelled "Livreur arrivé" (`app_strings.dart:238`) — misleading for the merchant (that status means arrived at the **customer**).

### Differences
No arrival banner, no driver card, no contents card styling, no handoff/problem CTAs.

### Contract
- Arrived at restaurant: **SUPPORTED** (`delivery.status=AT_PICKUP`). Arrival time: **SUPPORTED** via `events[type=DRIVER_ARRIVED_PICKUP].occurredAt` (Flutter does not parse `events`). Wait time: derivable live from that server instant (**SUPPORTED**, not invented).
- Driver info/rating/plate/call: **NOT SUPPORTED**. Parcel count "2 Colis": **NOT SUPPORTED**.
- "Espèces (Livreur encaisse)" + amount: method **SUPPORTED**; collectable customer amount **NOT SUPPORTED** in Merchant DTO.
- "Confirmer la remise": **NOT SUPPORTED** (no Merchant delivery mutation; pickup is Driver-declared).
- "Signaler un problème": **SUPPORTED** as support ticket (OWNER/MANAGER).

### Alternatives
`driver_arrived_secure_handoff_final_ux` (code-based variant). **Unresolved:** product must choose handoff model (none / merchant confirm / code) before any handoff UI.

### Required work
1. Arrival banner for `AT_PICKUP` with arrival clock and live wait from event timestamp; "Veuillez remettre la commande."
2. Contents card (ref, items); payment line shows method only (no collectable amount).
3. Footer: "Signaler un problème" → support form; no "Confirmer la remise", no driver card/call.
4. Fix status labels: `AT_PICKUP` → "Livreur arrivé au commerce"-type copy; `ARRIVED_CUSTOMER` → customer-arrival wording.

### Proposed status
`partial_contract_limited`

---

## driver_arrived_secure_handoff_final_ux

### Design
- 390×844 frame. Header h-56 bg `#F7F9FC`: `arrow_back`; centered "Détails de la commande" title-lg.
- Driver verification card: 56px photo; "Yacine Mansouri" title-md `#172033`; 36px surface-container-high `call`; "Moto • 16-12345 • ★ 4.9"; info strip "Vérifiez que le livreur correspond à la photo et au véhicule affichés."
- Order card: "Commande à remettre"; "#SG-… · 2 colis"; items list 14px; divider; "À encaisser par le livreur" + "2 250 DZD" primary-container bold.
- State A card: `lock` "Code de retrait"; box `#E9EDFF` rounded-xl py-24, "4 1 8 6" 36px bold `#162B7F` tracking 0.5em; copy "Communiquez ce code uniquement au livreur affiché ci-dessus." / "Le livreur doit saisir ce code dans son application pour confirmer la récupération."; spinner + "En attente de validation par le livreur…".
- State B (hidden): bg `#F0F9EB` border `#E1F3D8`, FILL `check_circle` `#67C23A` 40px, "✓ Remise confirmée", "Commande récupérée par le livreur.", "Récupérée à 13:38", "Statut: En livraison".
- Footer: "Signaler un problème" h-52 outlined `report_problem`.

### Flutter mapping
None (SoT §6 `not_in_scope`). Would live in `OrderDetailScreen` READY branch as a delivery sub-section.

### Differences
Entire screen absent.

### Contract
- Pickup code, driver-entered code validation: **NOT SUPPORTED** (no field, `confirm-pickup` has no body, Merchant confirmation not required).
- Driver identity/verification: **NOT SUPPORTED**. Collectable amount: **NOT SUPPORTED**.
- State B ("Récupérée à", "En livraison"): **SUPPORTED** (`pickedUpAt`, status `PICKED_UP`/`IN_TRANSIT`).
- Report problem: **SUPPORTED** (support ticket).

### Alternatives
`driver_arrived_french` (confirm-button variant). Both conflict with the current Driver-declared pickup contract.

### Required work
Contract needed first (pickup-code or merchant-confirm handoff in Delivery + Driver app). Meanwhile only: post-pickup confirmation state ("Récupérée à HH:mm", status) and "Signaler un problème".

### Proposed status
`blocked_contract`

---

## cancelled_order_french

### Design
- Header h-56 shadow-sm: `close`; centered "Commande Annulée" title-lg primary; right SpeedyGo logo 32px.
- Hero centered: 64px error-container circle FILL `cancel` 36px; "Annulée" headline-lg error; "La commande #SG-… n'aboutira pas." body-lg.
- Details card white rounded-xl shadow `0 2px 8px rgba(0,0,0,.04)` border error-container/30, 4px left error bar: `person_remove` "Annulée par le client" label-lg + "Aujourd'hui à 13:45"; divider (ml-40); `info` "Raison" + chip "Temps d'attente trop long" body-md error on error-container/20.
- Summary card: "Détails de la commande" label-lg + store name right; 40px surface-container initials "SB" + name + "Client"; rows surface-container-low rounded-lg: "Articles" / "4 (Couscous, Chorba...)"; "Montant Total (COD)" / "2 250 DZD" title-lg; chip `receipt_long` "Commande non facturée".
- 2-col outlined h-48: `support_agent` "Contacter le support" / `history` "Voir l'historique".
- Sticky: "Compris" h-48 primary `check`.

### Flutter mapping
`OrderDetailScreen` `status=CANCELLED`: `_CancellationCard` (red "Annulée", "Motif : …", "Annulée le …") + `_CancelledSummaryCard`, then items/address/finance (cancelled note)/history. No sticky actions. Capture `phase-2/review/mocked/se-cancelled.png`.

### Differences
No hero; no actor line; reason as "Motif :" text; no initials avatar/rows; no support/history buttons; no "Compris"; generic app bar.

### Contract
- Actor: **SUPPORTED** via `statusHistory` (`CUSTOMER_CANCELLED` vs `MERCHANT_REJECTED`, `actorType`) — not via `cancellation` (DTO has `reason`, `cancelledAt` only).
- Reason, time: **SUPPORTED**. Articles summary: **SUPPORTED** (items). "Montant Total (COD)": customer total **NOT SUPPORTED** → show GMS labelled.
- "Commande non facturée": **NOT SUPPORTED** (no billing flag; business claim).
- Support: **SUPPORTED** (OWNER/MANAGER). "Voir l'historique": navigation to Historique/Annulées (**SUPPORTED**). "Compris": close/pop (navigation only).

### Alternatives
`merchant_order_history_unified` destination. Decision on record: finance note "Montants historiques figés — pas un paiement dû".

### Required work
1. Task app bar (close ✕, "Commande annulée").
2. Hero (icon circle, "Annulée", "La commande {compact ref} n'aboutira pas.").
3. Details card: actor from statusHistory ("Annulée par le client" / "Refusée par le commerce"), local time, reason chip.
4. Summary card with initials, articles summary, GMS labelled; no "non facturée" chip.
5. Secondary buttons Contacter le support (OWNER/MANAGER) + Voir l'historique; sticky "Compris" pops.

### Proposed status
`needs_work`

---

## d_tails_de_la_commande_finance_transparente

### Design
- Fixed header h-56 shadow-sm: `arrow_back`; "Détails de la commande" title-md semibold primary.
- "RÉFÉRENCE: #SG-…" label-md uppercase.
- Status card white rounded-xl border shadow-sm: "Statut actuel" title-md + "Livrée le 26 Août, 18:42"; chip tertiary-fixed-dim/20 border `check_circle` "Livré" tertiary label-lg.
- Timeline card: `schedule` primary "Historique de la commande"; vertical 1px line, 12px dots (latest tertiary, others outline); rows label-lg title + body-md caption + time right: "Livrée / Client a reçu la commande / 18:42", "Récupérée / Livreur en route vers le client / 18:25", "Préparée / Prête pour la collecte / 18:15", "Acceptée / Commande confirmée / 17:50".
- Customer & items: "SB" initials + name + "Client"; "4 ARTICLES" label-lg uppercase; rows "1x" primary + name title-md + description + price label-lg; note block error-container/20 `info` "Note du client".
- Driver card: 48px photo, name, `two_wheeler` "Scooter • 16-12345", chip "Livreur".
- Finance card: title (typo) "Dtails de la commande (Finance transparente)"; rows body-md: "Sous-total articles 2,200 DZD", "Commission SpeedyGo (7%) -154,00 DZD" (error), "Frais de livraison (Pris en charge) 0 DZD"; border-t "Net commerant" (typo) title-lg + "2,046,00 DZD" (malformed) primary; chip surface-container-high `payments` "Méthode: Espèces (COD)".
- Footer: "Voir le reçu" outlined primary + "Contacter le support" primary `support_agent`. **png vs html**: png buttons side by side; html stacks on mobile (`flex-col`, `md:flex-row`).

### Flutter mapping
`OrderDetailScreen` generic branch (COMPLETED): `_HeaderCard`, `_ItemsCard`, `_AddressCard`, `_FinanceCard` ("Répartition financière": Sous-total marchandises / Remise commerçant / Commission SpeedyGo (x %) / Net commerçant / Frais de livraison (client) + disclaimer; STAFF restricted notice), `_DeliveryCard`, `_HistoryCard`.

### Differences
- No status card with delivered time; `_HistoryCard` lists raw `eventType` codes ("MERCHANT_ACCEPTED · …") and its title string is misspelled `'Histororique'` (`app_strings.dart:231`); no timeline visuals, no delivery events.
- Finance: labels follow contract (correct); commission not shown negative/red; no payment method chip.
- No driver card (correct), no receipt/support footer.

### Contract
- Timeline: **SUPPORTED** by combining `statusHistory` (ORDER_CREATED, MERCHANT_ACCEPTED, PREPARATION_STARTED, ORDER_READY, …) and delivery `events`/`pickedUpAt`/`deliveredAt`.
- Delivered time: **SUPPORTED** via delivery `deliveredAt` (Order `completedAt` not in DTO).
- Finance rows: **SUPPORTED** for OWNER/MANAGER; STAFF sees GMS + delivery fee only (keys absent).
- "Frais de livraison (Pris en charge)": semantics conflict with contract (delivery fee is customer-paid, not merchant cost) — keep "(client)".
- Receipt: **NOT SUPPORTED**. Driver card: **NOT SUPPORTED**. Client note: **NOT SUPPORTED**. Support: **SUPPORTED**.

### Alternatives
`merchant_order_history_unified` entry point; `cancelled_order_french` for cancelled snapshot note.

### Required work
1. Reference line + status card ("Livrée le …" from `deliveredAt`, status chip with icon).
2. Timeline component with localized French labels mapped from event types (fix raw codes and the title typo).
3. Items card with initials header and "N ARTICLES" label.
4. Finance card styling: commission as negative error row, net emphasized primary, payment method chip; keep contract labels and STAFF restriction.
5. Footer: "Contacter le support" (OWNER/MANAGER); omit "Voir le reçu".

### Proposed status
`needs_work`

---

## signaler_un_probl_me_standardis

### Design
- Frame 390×844. Header h-64 border-b: `arrow_back` (48px target); centered "Signaler un problème" title-lg.
- Order context card white rounded-xl shadow `0 2px 8px rgba(0,0,0,.04)`: "COMMANDE" label-md outline + "#SG-…" title-md on-primary-fixed-variant; right chip `check_circle` "Livré" (tertiary tones); full-bleed divider; 2 cols "CLIENT" / name, "TOTAL" / "2 250 DZD" semibold.
- "Catégorie du problème" title-md label; select h-48 border outline rounded-lg, placeholder "Sélectionnez une catégorie...", options "Livreur (Mismatch)", "Paiement / Espèces", "Annulation incorrecte", "Problème technique", "Autre"; `expand_more`.
- "Description du problème" label; textarea rows=5 border outline rounded-lg placeholder "Expliquez-nous ce qui s'est passé en détail..."; hint `info` "Veuillez ne pas inclure de données sensibles (ex: mots de passe)."
- "Ajouter une preuve (Photo)": dashed 2px outline-variant rounded-xl min-h-120, primary-container/10 circle `add_a_photo` 32px, "Appuyez pour ajouter des photos", "JPG, PNG (Max 5MB)".
- Footer: optional spinner "Synchronisation en cours..."; "Envoyer le ticket" h-52 primary `send`; "Enregistrer le brouillon" h-48 outlined primary.

### Flutter mapping
None. No route in `app_routes.dart`, no support feature folder, no `MerchantApi` method. Would live at e.g. `/app/orders/:orderId/support` (new `AppRoutes` entry + `app_router.dart` child of order detail) with `lib/features/support/{data,application,presentation}` using existing `ApiEndpoints.merchantSupport`.

### Differences
Screen absent. Every "Support" / "Contacter le support" / "Signaler un problème" CTA in this batch currently has no destination.

### Contract
- Create ticket: **SUPPORTED** `POST /merchant/:merchantId/support` `{body 1–4000, orderId?}`; list/get/reply also available. OWNER/MANAGER; **STAFF forbidden** (hide entry).
- Category: **NOT SUPPORTED** (explicitly excluded). Photos: **NOT SUPPORTED** (no attachments). Draft: **NOT SUPPORTED** server-side. Sync indicator: not applicable.
- Context card: status, customer name, GMS: **SUPPORTED** (order detail).

### Alternatives
`merchant_support_french` (support hub folder, outside this batch) for ticket list/thread. **Unresolved:** whether category may be embedded as text in `body` (would imitate a taxonomy the backend rejects) and whether a local-only draft is acceptable.

### Required work
1. New order-scoped form: context card (compact ref, status chip, customer, GMS labelled), required description (1–4000, label above), sensitive-data hint, "Envoyer le ticket" with loading state.
2. On success show server `publicReference` (`sgt_…`) confirmation; errors mapped (403 for STAFF).
3. Omit category select, photo upload and draft button until contract exists.
4. Wire all batch "Support"/"Signaler un problème" CTAs here with `orderId`; hidden for STAFF.

### Proposed status
`partial_contract_limited`

---

## Cross-cutting findings (fix once)

- **Stale binding doc**: `docs/MERCHANT_UI_SOURCE_OF_TRUTH.md` §6 says accept has no prep-time body, prep update is `not_in_scope`, alert overlay `not_in_scope`; all three are now implemented (`preparation_time_widgets.dart`, `incoming_order_alert_overlay.dart`).
- **App bar**: order detail always "Commande" + refresh. References use a task header per state (ref and/or state title, status chip at right, close ✕ for terminal/modal flows). List header needs bell + open/closed subtitle.
- **Status chip**: `StatusBadge` has no leading icon (DESIGN.md requires one); detail refs use rounded-full uppercase pills; history uses 4px-radius 10px bold chips with icons. One chip component with icon + tone variants.
- **Card shadow**: `MerchantCard` = Material elevation 1 + 8% shadow + 55% outline; DESIGN.md = 4% alpha, 8px blur, 2px offset; refs `0 2px 8px rgba(0,0,0,.04)` or `shadow-sm`.
- **Sticky footer / buttons**: refs use h-56 primary rounded-xl with leading icon, plus outlined secondary (h-48/52) or a 2-col secondary row above; `MerchantPrimaryButton` radius 12 is right, height/icon usage inconsistent; add an outlined secondary variant.
- **Selectors**: Material `ChoiceChip` (checkmark) used for status tabs and time presets; refs use segmented containers and bento tiles.
- **Inputs**: floating-label `OutlineInputBorder` + counter; DESIGN.md/refs want persistent label above, 1px outline-variant, 8–12px radius.
- **Countdown component**: two reference variants (solid primary-container boxes vs light surface-container-highest boxes) — pick one.
- **Delivery model**: `MerchantDeliverySummary` drops `pickup`, `dropoff`, `events`, `createdAt`; `_deliveryStatusLabel` lacks TO_PICKUP / AT_PICKUP / IN_TRANSIT / FAILED / CANCELLED and mislabels ARRIVED_CUSTOMER as "Livreur arrivé".
- **Copy defects**: `'Histororique'`; raw `eventType` codes in history; technical strings "(serveur)" and `orderHandoffUnsupported` shown to users; alert "Total de la commande" over GMS.
- **Support**: backend ready, Flutter unused endpoint; one form serves 8 CTAs in this batch.
- **Contract gaps to raise**: search/date/multi-status list filters; list item count; customer order total; order/kitchen note; acceptance expiry; driver identity/contact (FINAL-excluded); handoff model; delay reason taxonomy + customer/driver notification; `Delivery.estimatedArrivalAt` writer; support category/attachments.
