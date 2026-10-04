# Parity inventory — A: Shell / Dashboard / Navigation + E: Reports

Read-only inventory (no code, tests or existing docs changed). Design truth:
`screens/MerchantScreens/<folder>/{screen.png,code.html}`; tokens
`screens/MerchantScreens/speedygo_merchant_system/DESIGN.md`. Evidence consulted (not design
truth): `audit/phase-3-tabs/`, `audit/phase-5-ui/mocked/`, `audit/phase-5-ui/reports/`,
`audit/phase-5-ui/reports-live/`.

All five `screen.png` and `code.html` files were readable. No file missing.

## Summary

| reference | route/state | proposed status | one-line required work |
| --- | --- | --- | --- |
| *(shell)* canonical bottom nav + top app bar | `MerchantShell` (all `/app/*` tabs); `MerchantScaffold` AppBar | `needs_work` | Replace the text-colour `BottomNavigationBar` with the canonical pill nav (colour pending a decision). Align the tab app bars: `#F9F9FF` surface, `shadow-sm`, primary title, and the bell with a red dot on every main tab. |
| `merchant_operational_dashboard_french` | `HomeScreen` → `/app/home` | `needs_work` | Add the KPI strip for Ventes and Commandes from `GET /reports/sales?period=TODAY&branchId`; omit Temps moyen. Restyle the chip, card accent, CTA and the READY card. Remove the dead banner tap. Settle the Ouvert/Actif pill question. |
| `merchant_reports_overview_french` | `ReportsScreen` → `/app/reports` | `needs_work` | Header chrome (storefront avatar, primary title, bell, shadow), card/rank-badge tokens, KPI order, pill nav, and a French label for settlement status. Growth % and average prep time stay omitted. |
| `sales_summary_french` | Merged into `ReportsScreen` (documented decision) | `not_applicable_duplicate` | No separate screen. The payment-method block and "+12 % vs Hier" are blocked (no contract). Optional: hero-style net figure in the overview. |
| `daily_summary_french` | Partly covered by `ReportsScreen` with the TODAY period | `blocked_contract` | Its own sections (breakdown bar, preparation efficiency, cancellation reasons, prep time) have no contract. The shared KPIs are already in the overview. |
| `popular_products_french` | `TopProductsScreen` → `/app/reports/top-products` | `partial_contract_limited` | Card/ribbon/badge styling. Images are only partly available (no `hasImage` on the aggregate). Row navigation and search need product decisions or a contract. |

---

## Shell and navigation (canonical)

### Survey method

All 77 `code.html` files under `screens/MerchantScreens/*/` were checked for the five labels.
`speedygo_merchant_system/` has no `code.html`, only `DESIGN.md`. Twelve files contain
"Accueil". Eleven render the SpeedyGo five-tab bar. `merchant_language_french` renders an
unrelated template. `DESIGN.md` has **no bottom-nav spec**. Its only nav cue is in the prose:
"Primary Blue (#2F59AF): … active navigation states".

### Bottom nav: markup found

| Folder | Container (Tailwind) | Approx. height | Active style | Inactive | Notes |
| --- | --- | --- | --- | --- | --- |
| `merchant_operational_dashboard_french` | `bg-surface` `border-t outline-variant/30` `shadow-[0_-2px_8px_rgba(0,0,0,0.04)]` `px-4 py-2 pb-safe`, **no rounded top** | ≈64 + safe | **Text only**: `text-primary`, icon `FILL 1`, label `font-bold`; items `flex-1` | `text-on-surface-variant` | Home tab active |
| `active_orders_list_french`, `merchant_order_history_unified` | `<div>` not `<nav>`; `bg-white` `border-t outline-variant/30` `px-2 pt-2 pb-safe` | ≈62 + safe | **Text only**: `text-primary` `FILL 1` `font-semibold` | `text-outline` (#747783) | Labels `text-[10px]`; 8px `bg-error` unread dot on Commandes |
| `merchant_reports_overview_french` | `bg-surface-container` `border-t outline-variant` `shadow-[0_-2px_10px_0_rgba(0,0,0,0.04)]` `rounded-t-xl` `h-[80px]` | 80 | **Pill** `rounded-full px-5 py-1` `bg-primary-container` `text-on-primary-container`, `FILL 1`, `font-semibold` | `text-on-surface-variant` | Nav **not visible in screen.png** (cropped) |
| `sales_summary_french` | same as above | 80 | **Pill** `bg-secondary-container` `text-on-secondary-container` | same | Nav **not visible in screen.png** |
| `daily_summary_french` | `bg-surface-container` `rounded-t-xl` shadow `0 -2 10 .04`, **no border** `h-[80px]` | 80 | **Pill** `bg-primary-container` **`text-on-primary`** | same | screen.png: Commandes/Catalogue icons render as dots, Profil tab clipped off-screen |
| `liste_des_produits_standardis_e`, `liste_des_produits_menu_ouvert` | `bg-surface` shadow `0 -2 8 .04` `rounded-t-xl` `px-4 py-2 pb-safe`, no border | ≈68 + safe | **Pill** `rounded-full px-4 py-1` `bg-primary-container` `text-on-primary-container` `FILL 1` `font-semibold` | `text-on-surface-variant` | Catalogue active |
| `liste_des_cat_gories_standardis_e` | `bg-surface` `shadow-sm` `border-t outline-variant` `h-20`, no rounded top | 80 | **Pill** `px-3 py-1` `bg-secondary-container` `text-on-secondary-container` | same | Rapports icon is **`analytics`** (every other folder uses `bar_chart`) |
| `merchant_settings_french` | `bg-surface` shadow `0 -2 8 .04` `rounded-t-xl` `px-4 py-2`, `<button>` items, no `pb-safe` | ≈68 | **Pill** `bg-secondary-container` `text-on-secondary-container` | same | Profil active; settings is a *sub-screen* but still shows the nav |
| `store_profile_french` | `bg-surface` shadow `0 -2 10 .05` `rounded-t-xl` `px-2 py-3` | ≈76 | **Pill** `px-5 py-1` `bg-secondary-container` `text-on-secondary-container` | same | Profil active |
| `merchant_language_french` | `bg-gray-50` `border-[#e9ecf1]` | — | Phosphor SVG icons; labels Accueil / Commandes / Catalogue / **Messages** / a gear tab; colours `#586a8d` / `#101319` | — | **Foreign template. Ignore as a nav reference.** |
| `popular_products_french` | Comment `<!-- Shared Component: BottomNavBar -->` but **no nav rendered** | — | — | — | Consistent with a pushed detail screen |

### Canonical bottom nav (majority of the 11 SpeedyGo bars)

- **Items (11/11):** Accueil · Commandes · Catalogue · Rapports · Profil, in this order,
  equal width (`justify-around`).
- **Icons (10/11):** Material Symbols Outlined `home`, `receipt_long`, `inventory_2`,
  `bar_chart`, `person`, size 24. Inactive is outlined (`FILL 0`), active is filled (`FILL 1`).
  Outlier: `analytics` in `liste_des_cat_gories_standardis_e`.
- **Label (9/11):** `label-md` = Inter 12 px / 16 px line / 600 / +0.5 px tracking, `mt-1`
  (4 px) below the icon. Active is `font-semibold`; the dashboard uses `font-bold`.
  Outliers: 10 px labels in the two order folders.
- **Inactive colour (9/11):** `on-surface-variant` `#434652`. Outliers use `outline` `#747783`.
- **Active indicator (8/11): pill** `rounded-full` around icon + label, padding
  `px-4…px-5 / py-1`. The dashboard and the two order folders use colour only (no pill).
- **Pill colour: UNRESOLVED (4–4 tie).**
  - `secondary-container #94A6FF` + `on-secondary-container #24388B`: `sales_summary_french`,
    `liste_des_cat_gories_standardis_e`, `merchant_settings_french`, `store_profile_french`.
  - `primary-container #2F59AF` + `on-primary-container #C7D5FF`:
    `merchant_reports_overview_french`, `liste_des_produits_standardis_e`,
    `liste_des_produits_menu_ouvert`, plus `daily_summary_french` (with `on-primary #FFFFFF`).
  - `DESIGN.md` prose ties "active navigation states" to `#2F59AF`, which favours
    primary-container / on-primary-container. Both pairs have roughly 4.6:1 contrast.
    Needs a human pick.
- **Background:** `surface #F9F9FF` in 6/11. Two use `#FFFFFF`; the three report folders use
  `surface-container #E9EDFF`.
- **Top edge:** soft upward shadow `0 -2px 8px rgba(0,0,0,0.04)` in 9/11 (a 10 px / 0.05
  variant in 4). `rounded-t-xl` (12 px, per the code.html Tailwind config) in 7/11. A top
  border (`outline-variant`, often `/30`) appears in 6/11, so it is optional; if used,
  `outline-variant/30`.
- **Height:** content-driven, about 64–68 px plus safe area (`px-4 py-2 pb-safe`, item `py-1`).
  The explicit 80 px appears only in the three report folders and the category list.
- **Badge:** unread is an 8 px `bg-error #BA1A1A` dot with no count (order folders; the same
  pattern is used on header bells).
- **Visibility:** shown on the five tab roots. Deviations: `merchant_settings_french`,
  `sales_summary_french` (has a back arrow) and `daily_summary_french` show the nav on
  drill-down screens. `popular_products_french` (drill-down) does not.

### Canonical top app bar

Of the 72 files with a `<header>`: height `h-14` (56 px) in 42, exactly `h-14 + shadow` in 28
(the plurality). A second family uses `h-16 + border-b` (8; order-prep and editor screens).
Of the 62 `<h1>` titles: `title-lg` (20/600) in 45, `headline-md` (24/600, often bold) in 12;
colour `text-primary #0A4096` in 41, `on-surface` in 19.

- **Main tab (with bottom nav):** sticky, `h-14`, `bg-surface #F9F9FF`, `shadow-sm`,
  `px-4` (16). Left side is an identity mark plus title in primary:
  - dashboard: `speed` icon + store name, `headline-md` bold primary;
  - reports: 32 px `storefront` circle (`bg-surface-variant #D9E2FC`, icon primary 20) +
    `title-lg` primary;
  - daily: 32 px avatar image + "SpeedyGo" `headline-md`;
  - catalogue: `menu` + "Catalogue".

  Right side is the **`notifications` bell** (on-surface-variant, 24, 40–44 px target) with an
  8 px `bg-error` dot. The bell appears on dashboard, reports overview, sales summary, daily
  summary, catalogue and orders. An optional status pill sits left of the bell (dashboard
  "Ouvert"). The orders folders use a 64 px `bg-white` variant with a 22 px bold ink title and
  a "Dar El Bahia • ● Ouvert" subline.
- **Sub-screen:** `arrow_back` leading (40–44 px), `title-lg` title (primary in the majority),
  optional `label-md` subtitle in on-surface-variant (for example "Dar El Benna • Amine
  Bensaïd"), optional trailing action (`search`, `notifications`, `help`), `h-14`,
  `bg-surface`, `shadow-sm`. `sales_summary_french` centres a brand title ("SpeedyGo") over a
  subtitle ("Résumé des ventes"). This is a minority pattern (14/62 centred).

### Flutter today

- `lib/features/shell/merchant_shell.dart` uses a Material `BottomNavigationBar`:
  - background `AppColors.surface` = **`#FFFFFF`** (reference `#F9F9FF`);
  - 1 px top border `outlineVariant @ 0.55`; no shadow; no rounded top;
  - active = colour only (`primary #0A4096`) with filled Material icon; labels
    **11 px w700 / 10 px w500** (reference 12 px / 600); default height 56 + safe area;
  - no pill; no unread dot on any tab.

  This matches the minority "text-only" family (dashboard/orders), not the pill majority.
  Icons map correctly (`Icons.home_outlined/home`, `receipt_long`, `inventory_2`, `bar_chart`,
  `person`), with small glyph differences between Material Icons and Material Symbols.
- `app_theme.dart` defines `navigationBarTheme` (indicator `surfaceContainer`), but the shell
  never uses `NavigationBar`, so this is dead theming. The M3 `NavigationBar` indicator wraps
  the icon only (64×32), while the reference pill wraps icon + label, so a custom bar item
  is needed.
- Visibility: tab roots only (the `ShellRoute` in `app_router.dart`). Detail routes (orders
  detail, settings, top products, notifications) use `_rootKey`, so they have no nav. This is
  correct for `popular_products_french`, and deviates from the settings/sales/daily
  references (acceptable: those refs are internally inconsistent).
- App bars:
  - `MerchantScaffold` (`merchant_ui.dart`) → `AppBar` with bg `AppColors.background
    #F9F9FF` (✓), `elevation: 0` (**no shadow**, ✗), title colour `onSurface #121B2E` (✗;
    majority is primary), `titleLarge` 20/600 (✓), height 56 (✓). The subtitle carries a
    hard-coded `Key('orders-branch-context')` on every screen.
  - `HomeScreen` uses its own `Material(elevation: 1)` header instead, so the tabs are
    inconsistent with each other.
  - The **bell exists only on Home** (and as a row in the store profile). Orders, Catalogue
    and Reports have no bell, although the references show one.

### Required work (shared, fix once)

1. Build a `MerchantBottomNav`:
   - bg `#F9F9FF`, top shadow `0 -2 8 rgba(0,0,0,.04)`, optional `outline-variant/30`
     hairline, 12 px top radius;
   - 5 equal items, 24 px icons (outlined / filled), 12/600 labels, inactive `#434652`;
   - active pill around icon + label; pill colour **pending a decision**
     (primary-container/on-primary-container recommended by DESIGN.md prose);
   - optional 8 px error dot on Commandes, driven only by a real server count
     (for example new/incoming orders). Never invented.
2. Add a `MerchantTabAppBar` (identity slot + title in primary + bell with an 8 px dot from
   `notificationsUnreadCountProvider` + `shadow-sm`) and use it on all five tabs.
3. `MerchantScaffold`: optional `shadow-sm` / scrolled-under treatment; primary title colour
   for tab roots; drop the hard-coded subtitle key.
4. Remove or use the unused `navigationBarTheme`.

Proposed status: **`needs_work`**.

---

## merchant_operational_dashboard_french

### Design

screen.png and code.html agree (the PNG includes the bottom nav).

- **Header:** sticky `h-14` `bg-surface` `shadow-sm` `px-4`.
  - Left: `speed` icon (primary) + store name "Dar El Benna" (`headline-md` 24, bold,
    primary).
  - Right (`gap-4`): pill **"Ouvert"** (`bg-tertiary-fixed #D3EE78`, text
    `on-tertiary-fixed #171E00`, `px-2.5 py-1` rounded-full, 8 px `bg-tertiary #3C4B00` dot
    with `animate-pulse`, `label-md`), then the `notifications` bell (on-surface-variant) with
    an 8 px `bg-error` dot.
- **Body:** `main` `flex-col gap-6 (24) p-4 mt-2`.
  1. **Verification banner:** `bg-primary-container #2F59AF`, text `on-primary-container
     #C7D5FF`, `p-4 rounded-xl shadow-sm`, `info` icon.
     - Title "Vérification à finaliser" (`title-md`).
     - Body "Complétez votre dossier pour conserver l’accès complet à votre espace
       marchand." (`body-md`, opacity .9).
     - Trailing `chevron_right`.
  2. **KPI strip:** `grid-cols-3 gap-3`.
     - Card: white, `p-3 rounded-xl`, shadow `0 2 8 rgba(0,0,0,.04)`,
       `border outline-variant/30`.
     - Label `label-md` on-surface-variant: **Ventes**, **Commandes**, **Temps moyen**.
     - Value `title-lg` primary; unit `text-[10px]` ("42.3k DZD", "18", "23 min").
  3. **Queue tiles:** 4 buttons, `gap-2 justify-between`, `min-w-[84px] px-4 py-3
     rounded-xl`.
     - First tile selected: `bg-primary`, text white, `shadow-md`.
     - Others: `bg-surface-container-high #E1E8FF`, on-surface-variant,
       `border outline-variant/30`.
     - Value `headline-md` bold; labels **Nouveaux**, **En prép.**, **Prêts**, **Livreur**.
  4. **"Commandes Actives"** (`title-lg`) with, on the right, **"Dernière synchro : Il y a
     1 min"** (`label-md` on-surface-variant).
  5. **Priority card (new):**
     - Container: white, `p-4 rounded-xl`, `border outline-variant`, shadow
       `0 4 12 rgba(0,0,0,.05)`, **6 px left accent bar `bg-primary`**.
     - Top row: reference "#SG-260803-1842" (`title-md` primary) + chip **"Nouveau"**
       (`bg-tertiary-fixed`, `on-tertiary-fixed`, `rounded` 4 px, `border tertiary/20`,
       `label-md`).
     - Customer name `body-lg` bold.
     - Right side: amount `title-lg` bold; **"À accepter"** (bold, error) and
       `schedule` 14 "2:34 restantes" (error).
     - Row `body-md` on-surface-variant: "3 Articles" | "Couscous Royal (x2), Lben".
     - CTA **"Traiter la commande"**: `h-12` `bg-primary #0A4096` white `label-lg` (14/600)
       `rounded-lg` (8 px) `shadow-sm`.
  6. **READY card:**
     - Card at `opacity-80`; reference in on-surface-variant; chip **"Prête"**
       (`bg-surface-container-high`).
     - `timer` + "Depuis 8 min".
     - Tonal button **"Prête pour retrait"** (`h-10`, `bg-surface-container-high`,
       on-surface-variant, no shadow).
  7. **Insight card:**
     - Container `bg-surface-container-low #F1F3FF`, `p-4 rounded-xl`,
       `border outline-variant/30`.
     - 40 px circle `bg-tertiary-fixed` with `trending_up` (tertiary).
     - Text **"Bonne journée !"** / "Vos ventes ont augmenté de 12%."; trailing
       `arrow_forward_ios`.
- **Bottom nav:** text-only active family (see the canonical section).

### Flutter mapping

`HomeScreen` (`lib/features/shell/home_dashboard_screen.dart`) → `/app/home`, inside
`MerchantShell`.

- **Data:**
  - `homeOrderCountsProvider`: list `total` for `CREATED∧PENDING_ACCEPTANCE`,
    `ACTIVE∧PREPARING`, `ACTIVE∧READY`.
  - `homeActiveOrdersProvider`: up to 5 of each, merged, newest first.
  - `branchAvailabilityControllerProvider`: `isOpenNow`.
  - `notificationsUnreadCountProvider`.
  - `accessControllerProvider`: branch name, `verificationAttentionRequired`,
    `operationalStatus`.
- **Evidence:** `audit/phase-5-ui/mocked/home_populated_pro.png`.

### Differences

1. **Header:**
   - Flutter shows *two* pills, "Ouvert" (availability) **and** "Actif" (operational status).
     The store name truncates ("Finjan C…") in the capture.
   - The Ouvert pill uses bg `#E8F5D3` / text `tertiary`, with a 7 px dot and no pulse.
     Reference: `#D3EE78` / `#171E00`, 8 px dot.
   - The bell shows a numeric `Badge`; the reference shows an 8 px dot.
2. **Verification banner:**
   - Text is `onPrimary #FFF` (reference `#C7D5FF`), and there is **no chevron**.
   - `InkWell` has an **empty `onTap`**, which gives a ripple with no destination
     (a dead action).
3. **KPI strip is missing entirely.** `AppStrings.homeKpiUnavailableHint` ("Ventes et temps
   moyen ne sont pas fournis par l’API") is **outdated**: sales now exist (see Contract).
4. **Tiles:** unselected bg `surfaceContainer #E9EDFF` (reference `#E1E8FF`); no `shadow-md`
   on the emphasised tile. "Livreur" shows "—" and is disabled (honest; the reference shows 0).
5. **Section title:** "Commandes actives", with no sync caption. The unused string
   `homeSyncJustNow` exists.
6. **Order cards:**
   - Shape: radius 16 (reference 12); no left accent bar (incoming uses a 1.5 px
     `primary@.25` border instead); no shadow.
   - Status chip: placed under the amount on the right, not next to the reference.
     Label "Nouvelle", warning-orange (reference "Nouveau", lime `tertiary-fixed`).
   - Reference shows `sgo_…` with a copy icon (documented decision in the source-of-truth
     doc).
   - CTA: `FilledButton`, `primaryContainer #2F59AF`, 52 h, radius 12, 16/700.
     Reference: `primary #0A4096`, 48 h, radius 8, 14/600.
   - READY card: a filled "Voir la commande" button instead of the tonal "Prête pour
     retrait"; no reduced opacity.
   - No acceptance countdown, no items summary, no "Depuis N min" (see Contract).
7. **No insight card.** Correct: blocked, see Contract.
8. Bottom nav: see the shell section.

### Contract

| Reference element | Status | Source |
| --- | --- | --- |
| Store name | SUPPORTED | membership / `selectedBranch.name` |
| "Ouvert" | SUPPORTED | Branch availability `isOpenNow` (`apps/backend/src/modules/merchants/presentation/http/merchant.controller.ts` → `BranchAvailabilityService`) |
| Bell dot | SUPPORTED | notifications unread count (already wired) |
| Verification banner | SUPPORTED (flag) / destination undecided | `verificationAttentionRequired` in `lib/features/access/data/models.dart`; no dedicated route |
| KPI **Ventes** (today) | **SUPPORTED** | `GET /merchant/:merchantId/reports/sales?period=TODAY&branchId=` → `grossMerchandiseMinor` (null → "—" when `dataStatus=MISSING_FINANCIAL_SNAPSHOT`); STAFF may read it (`docs/architecture/MERCHANT_SALES_REPORTS.md` Access) |
| KPI **Commandes** | SUPPORTED (semantics to decide) | Same response: `completedOrderCount` (COMPLETED today). "All orders today" has no date-filtered source |
| KPI **Temps moyen** | NOT SUPPORTED | "Average preparation time" is listed under "Not provided" in `MERCHANT_SALES_REPORTS.md`. Only per-order merchant *estimates* (`preparationMinutes`, `estimatedReadyAt`) exist in `merchant-order-response.dto.ts`, not actuals |
| Queue counts Nouveaux / En prép. / Prêts | SUPPORTED | `GET /merchant/:id/orders` `total` + `orderStatus`/`fulfillmentStatus` (`merchant-order.controller.ts`, `ListMerchantOrdersQueryDto`) |
| Queue count **Livreur** | NOT SUPPORTED | List filters are branchId/orderStatus/fulfillmentStatus only; the controller states "Driver … filters are not part of this foundation" |
| "Dernière synchro : Il y a N min" | PARTIAL | No server `asOf` on the orders list. A client-side "last successful load" time is honest; it must not imply realtime |
| Card reference, name, amount | SUPPORTED | order summary DTO (`publicReference`, `customerFullName`, `financial.grossMerchandiseSubtotalMinor`) |
| "À accepter · 2:34 restantes" | NOT SUPPORTED | No acceptance deadline in the `Order` model (`apps/backend/prisma/contract.prisma` ≈ L785–792) or the DTO |
| "3 Articles · Couscous Royal (x2), Lben" | NOT SUPPORTED in list | `items` exist only on `MerchantOrderDetailResponseDto`; per-card detail calls would be N+1 |
| READY "Depuis 8 min" | NOT SUPPORTED in list | READY time exists only in detail `statusHistory` |
| Insight "+12 %" | NOT SUPPORTED | Growth versus a previous period is listed under "Not provided" |

### Alternatives

- `docs/architecture/MERCHANT_SALES_REPORTS.md` (reports contract): the same TODAY data
  feeds the overview.
- `audit/phase-3-tabs/REFERENCE_COMPARISON.md` decided "Actif≠Ouvert; no hours API". Now
  **outdated**: availability ships, so both pills render.
- `MERCHANT_UI_SOURCE_OF_TRUTH.md` §6 lists "Counts via orderStatus∧fulfillment; no invent
  KPIs". This predates the reports contract.

### Required work

1. KPI strip (3-col grid, white cards, 12 px radius, `0 2 8 .04` shadow,
   `outline-variant/30` border):
   - **Ventes** = `grossMerchandiseMinor` for TODAY + selected branch, "—" when null.
     Compact "42.3k" formatting only with integer math, or show the full amount.
   - **Commandes** = `completedOrderCount`, pending the semantics decision.
   - **Temps moyen**: omit (or a 2-column strip). Delete the outdated
     `homeKpiUnavailableHint`.
2. Header:
   - Resolve the Ouvert + Actif crowding (decision below). Style the Ouvert pill per the
     reference (`#D3EE78` / `#171E00`, 8 px dot).
   - Bell: 8 px error dot (keep the count accessible via semantics).
3. Verification banner: add `chevron_right` and `#C7D5FF` text. **Remove the empty `onTap`**
   or wire it to a real verification route (decision).
4. Tiles: unselected `#E1E8FF`; `shadow-md` on the emphasised tile. Keep "Livreur" as "—"
   (no fake 0).
5. Cards:
   - 12 px radius, `0 4 12 .05` shadow, 6 px primary accent bar on PENDING_ACCEPTANCE.
   - Chip next to the reference; lime "Nouveau" tone. This needs the shared status-chip
     palette; coordinate with the orders batch.
   - CTA 48 h / radius 8 / 14/600 / `#0A4096`.
   - READY card: tonal secondary button (still opens detail; no fake "pickup" action) and
     reduced emphasis.
   - Optional for PREPARING cards: show the real `estimatedReadyAt` / `isPreparationLate`
     instead of the reference timer (decision).
6. Optional "Dernière synchro" from the client load time.
7. No insight card, countdown, items line or "Depuis" until contracts exist.

### Proposed status

**`needs_work`**

---

## merchant_reports_overview_french

### Design

**screen.png vs code.html:** the PNG does not show the fixed bottom nav (cropped), and the
chips "Ce mois" and "Personnalisé" are scrolled off.

- **Header:** sticky `h-14` `bg-surface` `shadow-sm`.
  - Left: 32 px circle `bg-surface-variant #D9E2FC` with `storefront` (primary, 20).
  - Title **"Rapports et Performance"** (`title-lg` primary, truncate).
  - Right: `notifications` bell (40 px, on-surface-variant, no dot).
- **Period chips:** horizontal scroll `gap-2`, `px-4 py-2 rounded-full label-lg`.
  - Selected: `bg-primary` text white.
  - Others: `bg-surface-container #E9EDFF`, `border outline-variant`, on-surface-variant.
  - Labels: **Aujourd'hui · Hier · Cette semaine · Ce mois · Personnalisé**.
- **Cards** (shared style): white, `border outline-variant` (full `#C3C6D4`), `rounded-xl`
  (12 px), `p-4`, shadow `0 2 8 rgba(0,0,0,.04)`.
- **Finance card** (full width):
  - Header row with bottom divider: **"DÉTAILS FINANCIERS"** (`label-md` uppercase,
    tracking-wide) + `payments` icon (outline, 20).
  - **Ventes brutes** row (`body-md` label / `title-md` value).
  - **"Commission SpeedyGo (7%)"** row, value error "- 2 961 DZD".
  - Divider, then **Net commerçant** (`label-lg` primary) with value `title-lg` bold primary.
  - Green growth tag `trending_up +8%` (bg `#F0F9EB`, text `tertiary-container`).
- **KPI cards** (2-col, `gap-3`):
  - **COMMANDES** (`receipt_long`), **TEMPS PRÉP. MOY.** (`timer`), **ANNULATIONS**
    (`cancel`; value in error colour).
  - The fourth slot is empty.
  - Label `label-md` uppercase; value `title-lg` bold.
- **Banner:** `bg-surface-variant #D9E2FC` `rounded-lg p-3`, centred: `update` 16 +
  **"Dernière mise à jour : 13:00"** (`label-md`).
- **Trend card:** **"Tendance des ventes"** (`title-md`). Chart area `h-32` (128)
  `bg-surface-container-low rounded-lg` with a **smooth area curve** (primary stroke 2 +
  10 % fill).
- **Top products:**
  - Header **"Produits les plus vendus"** (`title-md`) + **"Voir tout"** (`label-lg`
    primary).
  - Rows: white, `border outline-variant`, `rounded-lg` (8 px), `p-3`, no shadow.
  - Rank badge 32 px `rounded` (4 px): #1 `bg-primary-container` / `on-primary-container
    #C7D5FF`; #2+ `bg-surface-container-high` / on-surface-variant.
  - Name `title-md`; "N commandes" `body-md`; amount `label-lg` semibold.
- **Bottom nav:** pill family, `bg-surface-container`, active Rapports
  `bg-primary-container` / `on-primary-container`.

### Flutter mapping

`ReportsScreen` (`lib/features/reports/presentation/reports_screen.dart`) → `/app/reports`.

- Data: `salesReportControllerProvider` (sales + top 3) and `reportsControllerProvider`
  (ratings + settlements).
- Widgets: `report_widgets.dart` (period chips, rank badge, error/loading cards).
- Evidence: `audit/phase-5-ui/reports-live/16e_normal_01_overview_today.png` and the mocked
  set in `audit/phase-5-ui/reports/`.

### Differences

1. **Header:**
   - Title "Rapports" (shortened for 1.35 text scale, documented in
     `MERCHANT_REPORTS_IMPLEMENTATION_REPORT.md` §11.1), in `onSurface` rather than primary.
   - No storefront avatar, **no bell** (a refresh icon instead), no shadow.
2. **Chips:** match (the selected chip also has a primary border). ✓
3. **Finance card:** content matches. The "+8 %" tag is omitted (correct).
   Card radius 16 and `Material elevation 1` (alpha .08) with border `outlineVariant@.55`,
   versus the reference 12 px, `0 2 8 .04` shadow and full `#C3C6D4` border (shared
   `MerchantCard`).
4. **KPI grid:**
   - Order and content differ: Commandes · **Panier moyen** · Annulations · Temps prép.
     moy. (showing "—" + "Non suivi"). Reference: Commandes · Temps prép. moy. ·
     Annulations · (empty).
   - Panier moyen is borrowed from `sales_summary_french` (documented).
   - Icon size 16 (reference 20).
5. **Banner:** `surfaceContainerHigh #E1E8FF` vs `surface-variant #D9E2FC`.
6. **Trend:** bars (primary, 120 h) vs the reference curve. Documented decision, justified by
   the bar chart in `sales_summary_french`.
7. **Top products:**
   - Rows use `MerchantCard` (16 px radius + elevation) instead of 8 px flat outlined.
   - Rank #1: white text (reference `#C7D5FF`). Ranks #2+: `surfaceContainer` + border +
     primary text (reference `surface-container-high`, no border, on-surface-variant);
     radius 6 (reference 4).
   - Name `titleSmall w700` (reference `title-md` 16/600).
8. **Extra sections not in the reference:**
   - Ratings card ("NOTES CLIENTS"): supported, keep.
   - Settlements ("RÈGLEMENTS"): supported. **The raw enum `DRAFT` / `FINALIZED` is shown
     to users** (`_SettlementTile` prints `settlement.status`).
9. Bottom nav: see the shell section.

### Contract

| Element | Status | Source |
| --- | --- | --- |
| Period chips incl. Personnalisé | SUPPORTED | `period=TODAY/YESTERDAY/THIS_WEEK/THIS_MONTH/CUSTOM` (≤ 93 days), `apps/backend/src/modules/reports/presentation/http/merchant-reports.controller.ts`, `dto/merchant-reports.dto.ts` |
| Ventes brutes / commission (historical snapshot rate) / net | SUPPORTED (OWNER/MANAGER); STAFF `finance=null` | `merchant-sales-report.types.ts` (`MerchantSalesFinanceView`, `uniformCommissionRateBps`) |
| Growth "+8 %" | NOT SUPPORTED | `MERCHANT_SALES_REPORTS.md` "Not provided" |
| Commandes, Annulations | SUPPORTED | `completedOrderCount`, `cancelledOrderCount` |
| Temps prép. moy. | NOT SUPPORTED | "Not provided". An aggregate would have to be derived from `OrderStatusEvent` PREPARATION_STARTED→READY (contract needed) |
| Dernière mise à jour | SUPPORTED | `asOf` (server instant; the UI renders device-local time, see gap 9 of the implementation report) |
| Trend | SUPPORTED | `trend.granularity` HOUR/DAY, zero-filled buckets up to `asOf` |
| Top products + Voir tout | SUPPORTED | `GET /merchant/:id/reports/top-products` |
| Ratings | SUPPORTED | `GET /merchant/:id/ratings/summary` (`ratings/presentation/http/merchant-ratings.controller.ts`). The response is `{targetType,targetId,count,average}`; the Flutter model reads `merchantId`, which is unused and harmless |
| Settlements | SUPPORTED (OWNER/MANAGER; STAFF 403 → "forbidden" copy) | `merchant-settlements/presentation/http/merchant-settlement.controller.ts`; `status` enum `DRAFT`/`FINALIZED`; "Settlement is not payout" (no Merchant payout endpoint) |

### Alternatives

- `sales_summary_french` shows the same finance card as a hero, plus Panier moyen and bars.
- `MERCHANT_REPORTS_IMPLEMENTATION_REPORT.md` §7 and §11 record the decisions: bars, Panier
  moyen, "Non suivi" card, short titles.
- `audit/phase-3-tabs/REFERENCE_COMPARISON.md` "Rapports" rows are **stale** (they say
  finance/trend/top products are unavailable and chips are display-only).
- `MERCHANT_UI_SOURCE_OF_TRUTH.md` §6 row "finance skeleton unavailable; trend/top
  unavailable" is also stale.

### Required work

1. Header: 32 px `storefront` circle + primary `title-lg` title; add the **bell with
   unread dot**. Keep refresh (it is load-bearing for the SE 1.35 tests) or move it to
   pull-to-refresh only (decision). Add `shadow-sm`. The title length decision ("Rapports"
   vs "Rapports et Performance") is recorded; keep "Rapports" unless revisited.
2. Card tokens via the shared `MerchantCard` fix: 12 px radius, `0 2 8 .04` shadow, full
   `outline-variant` border.
3. KPI order: Commandes, Temps prép. moy., Annulations, Panier moyen, **or** drop the
   "Non suivi" card and keep Panier moyen (decision; see unresolved list).
4. Banner colour `#D9E2FC`.
5. Rank badge:
   - #1 `primaryContainer` bg with `#C7D5FF` text;
   - #2+ `surfaceContainerHigh`, no border, on-surface-variant;
   - radius 4.
   - Top-product rows 8 px radius, flat outlined; name 16/600.
6. Settlements: map `DRAFT`→"Brouillon" and `FINALIZED`→"Finalisé" (or similar French copy).
   Never show raw enums.
7. Optional: curve instead of bars (visual only, from the same buckets). No growth tag.

### Proposed status

**`needs_work`**

---

## sales_summary_french

### Design

**screen.png vs code.html:** in the PNG the **bar chart renders empty** (only the dashed
future "14h" bar is visible; the other bars and tooltips are missing), and the **bottom nav is
not visible**. Everything else agrees.

- **Header:** sticky `h-14` `bg-surface`, shadow `0 2 8 .04`.
  - `arrow_back` (primary, 44 px).
  - Centred **"SpeedyGo"** (`title-lg` primary) over **"Résumé des ventes"** (`label-md`
    on-surface-variant).
  - Filled `notifications` (primary).
- **Chips:** `h-[44px] px-4 rounded-full label-lg`.
  - Selected: `bg-primary-container #2F59AF` / `on-primary-container`.
  - Others: `border outline-variant`, text on-surface.
  - Labels: **Aujourd'hui · Hier · Cette semaine · 📅 Personnalisé** (`calendar_month` icon).
- **Hero card:**
  - Container: white, `rounded-xl`, `border surface-container-highest #D9E2FC`,
    `0 2 8 .04`, decorative 128 px `primary/5` quarter circle top right.
  - `account_balance_wallet` + **"Ventes brutes"** (`title-md` on-surface-variant); value
    `title-lg` + "DZD" `label-md`.
  - Row between `outline-variant/30` rules: **"Commission SpeedyGo (7%)"** with value in
    error.
  - **"NET COMMERÇANT"** (`label-md` uppercase primary); value **`number-xl` 40/700**
    primary + "DZD" `title-lg`.
  - Growth "**+12% vs Hier**" (`tertiary-container`).
- **Secondary grid** (2-col, `p-3 px-4` cards): **"Nombre de commandes"** (`shopping_bag`) and
  **"Panier moyen"** (`receipt`), values `headline-lg` 32/700.
- **"Tendances des ventes"** (plural):
  - Bar chart `h-48`, y-axis ticks 50k / 25k / 0 (10 px `outline-variant`), hourly labels
    10h–14h.
  - Normal bars `primary-fixed-dim/50`; peak bar `primary-container` with a primary bold
    label.
  - Future hour: dashed `surface-container-high` bar.
  - Tooltips show "42.3k DZD".
- **"Méthodes de paiement":**
  - Rows with 40 px icon circles: **"Paiement à la livraison"** (`payments`, lime) "42,300
    DZD / 100%".
  - Divider, then **"Edahabia / CIB"** (`credit_card`) at 50 % opacity, "0 DZD / 0%".
- **Footer note:** `sync` + **"Dernière mise à jour : 13:00"** (`label-md` outline).
- **Bottom nav:** pill `bg-secondary-container` (Rapports active) on `bg-surface-container`.

### Flutter mapping

No dedicated route. Its content lives in `ReportsScreen` (`_FinanceSection`, `_OpsMetrics`
Panier moyen, `_TrendBars` hourly), per `MERCHANT_REPORTS_IMPLEMENTATION_REPORT.md` §7.

### Differences

- No drill-down screen and no centred brand header.
- The net figure is `titleLarge` in a row, not a 40 px hero.
- Trend has no y-axis ticks, no peak highlight and first/middle/last labels only.
- No payment methods; no growth line.
- "Nombre de commandes" is labelled "Commandes".

### Contract

| Element | Status | Source |
| --- | --- | --- |
| Gross, commission (snapshot rate), net, count, average basket | SUPPORTED | `/reports/sales` |
| Hourly bars | SUPPORTED | `trend.granularity=HOUR` for single-day periods; future buckets are not returned, so the dashed "future" bar does not apply |
| Axis ticks, peak highlight | SUPPORTED (presentation only, derived from returned integer buckets) | — |
| "+12 % vs Hier" | NOT SUPPORTED | "Not provided" |
| Méthodes de paiement (COD vs Edahabia/CIB) | NOT SUPPORTED | "Payment-method breakdown … for merchants" is listed under "Not provided". Per-order `payment.method` exists in the order summary DTO, but a client-side aggregation over paginated lists would be non-authoritative. A contract is needed |
| Personnalisé | SUPPORTED | `CUSTOM` |

### Alternatives

`merchant_reports_overview_french` carries the same finance/KPI/trend content as the tab root.
The recorded decision is "Implemented in the overview (no separate screen)".

### Required work

- None mandatory.
- Optional, visual only, applied to the overview: net-commerçant hero (`number-xl`), y-axis
  ticks and peak bar from real buckets.
- Payment methods and growth stay out until a contract exists.

### Proposed status

**`not_applicable_duplicate`**. Covered by the overview. Its unique payment-method block is
`blocked_contract`.

---

## daily_summary_french

### Design

**screen.png vs code.html:**
- The PNG bottom nav renders the Commandes/Catalogue icons as dots, and **Profil is clipped**
  (the active pill overflows).
- The CTA **"Voir toutes les commandes du jour"** in code.html is **not visible** in the PNG
  (hidden behind the nav or cropped).
- Every Material Symbol is globally `FILL 1` in this file's CSS.

Layout:

- **Header:** sticky `h-14` `bg-surface` `shadow-sm`: 32 px avatar photo (bordered) +
  **"SpeedyGo"** (`headline-md` primary) + bell.
- **Title block:**
  - **"Résumé quotidien"** (`headline-lg` 32/700) over "Dar El Benna • Amine Bensaïd"
    (`body-md`).
  - Right: date pill `calendar_today` **"Aujourd'hui, 26 Août"** (`bg-surface-container-low`,
    `border outline-variant`, rounded-full, `label-lg` primary).
- **KPI grid** (2×2, `card-shadow` `0 2 8 .04`, **no border**, `rounded-xl`, `p-4`):
  - Title `title-md` on-surface-variant with a 32 px icon circle on the right.
  - Values `headline-md`.
  - **Ventes** (`payments`, primary, with "+8% vs hier" `trending_up` in tertiary).
  - **Commandes** (`receipt_long`).
  - **Temps Prép.** (`timer`, "23 min").
  - **Annulations** (`cancel` on `error-container/30`, value in error).
- **"Répartition des commandes"** (`title-lg`): 16 px stacked bar with segments tertiary
  (Livrées 15), secondary (En cours 1) and error (Annulées 2); legend with 12 px dots.
- **"Efficacité de préparation":** **Moyenne** "23 min" (`headline-lg` primary) | **Objectif**
  "20 min"; 8 px progress track with secondary fill and a **"Cible"** marker.
- **"Motifs d'annulation":** rows "Indisponibilité produit 1", "Client absent 1".
- **CTA:** `h-[52px]` `bg-primary` `title-md`, `rounded-lg`, `list_alt` icon,
  "**Voir toutes les commandes du jour**".
- **Bottom nav:** pill `bg-primary-container` + `text-on-primary` (a third colour variant).

### Flutter mapping

No dedicated route. Ventes / Commandes / Annulations are available in `ReportsScreen` with the
**Aujourd’hui** chip (and any single day via Personnalisé with from = to).

### Differences

- No daily screen, title block, date pill or avatar.
- No breakdown bar, efficiency block, cancellation reasons or CTA.
- Temps Prép. shows "—" / "Non suivi" in the overview.

### Contract

| Element | Status | Source |
| --- | --- | --- |
| Ventes / Commandes / Annulations for a day | SUPPORTED | `/reports/sales` `TODAY` or `CUSTOM` from = to |
| Date button → pick a day | SUPPORTED | `CUSTOM` |
| "+8 % vs hier" | NOT SUPPORTED | "Not provided" |
| Temps Prép.; Efficacité (Moyenne / Objectif / Cible) | NOT SUPPORTED | "Average preparation time and preparation-efficiency target" are listed under "Not provided". `originalPreparationMinutes` is a merchant estimate, not a target |
| Répartition Livrées / En cours / Annulées | PARTIAL | Livrées ≈ `completedOrderCount`, Annulées = `cancelledOrderCount` (period-scoped). **En cours** has no period-scoped source: the orders list has no date filter, so `total` for ACTIVE is a live count. A bar mixing the two would misstate proportions |
| Motifs d'annulation | NOT SUPPORTED | `OrderCancellation.reason` is free text ("Not provided"); only per-order `cancellation.reason` exists in detail |
| "Amine Bensaïd" (person name) | NOT SUPPORTED | Not in the Merchant access model (`lib/features/access/data/models.dart`); no `fullName` in `merchants` DTOs |
| Avatar photo | NOT SUPPORTED | No member/account avatar in the Merchant contract |
| "Voir toutes les commandes du jour" | NOT SUPPORTED | `ListMerchantOrdersQueryDto` has no date filter (`merchant-order-write.dto.ts`) |

### Alternatives

`merchant_reports_overview_french` covers the shared KPIs. The recorded decision says
"Implemented via TODAY period in the overview … Merchant/Branch header with date button not
replicated".

### Required work

- Nothing buildable beyond what the overview already shows.
- If a daily screen is later wanted, it needs contracts for: prep-time aggregate and target,
  period-scoped status breakdown, cancellation reason categories, and an orders date filter
  for the CTA.
- Do not render a partial breakdown bar or an "Objectif" from merchant estimates.

### Proposed status

**`blocked_contract`**. The shared KPIs are a duplicate of the overview.

---

## popular_products_french

### Design

screen.png and code.html agree. There is no bottom nav in either.

- **Header:** sticky `bg-surface`, `border-b outline-variant`, `p-4 gap-4`.
  - `arrow_back` (on-surface, 40 px).
  - **"Produits les plus vendus"** (`title-lg` bold) over "Dar El Benna • Amine Bensaïd"
    (`label-md` outline).
  - `search` button (40 px round).
- **Chips inside the header:** `px-4 py-2 rounded-full label-lg`. Selected `bg-primary`
  white; others `bg-surface-container`, **no border**. Labels **Aujourd'hui · Hier · Cette
  semaine · Ce mois** (no Personnalisé).
- **Segmented toggle:** track `bg-surface-container-low p-1 rounded-lg`. Selected
  `bg-surface-container-highest #D9E2FC` primary `shadow-sm`; other `text-outline`. Labels
  **Commandes | Chiffre d'affaires**.
- **List header:** **"Top des ventes"** (`title-md` on-surface-variant) + **"Total: 4
  articles"** (`label-md` outline).
- **Rank #1 card:**
  - White, `border outline-variant`, `rounded-lg`, `p-3`, `gap-4`.
  - **"N°1" ribbon** top-left (`bg-primary` white, `rounded-br-lg`, `label-md` bold,
    `shadow-md`).
  - 80 px product photo, `rounded-lg`.
  - Name `title-md` bold.
  - `shopping_bag` (primary) "12 commandes" (`body-md` semibold); `payments` (tertiary)
    "18,000 DZD" (bold primary).
  - `chevron_right`.
- **Rank #2+ cards:** 56 px rank square (`bg-surface-container`, `text-primary-container`,
  bold lg, `border outline-variant`) + 56 px photo + name `title-md` semibold + "9 commandes •
  3,150 DZD" (amount primary) + `chevron_right`.
- **Footer:** `sync` 14 + **"Synchronisé à 13:00"** (`label-md` outline), centred.

### Flutter mapping

`TopProductsScreen` (`lib/features/reports/presentation/top_products_screen.dart`) →
`/app/reports/top-products` (root navigator, no nav ✓).

- Data: `topProductsControllerProvider` (limit 20) + `topProductsSortProvider`; shares
  `reportPeriodProvider` with the overview.
- Evidence: `audit/phase-5-ui/reports-live/16e_normal_05_top_week_orders.png`.

### Differences

1. **Header:**
   - Title "Top produits" (shortened, documented §11.1) vs "Produits les plus vendus".
   - Subtitle is the branch name only.
   - **Refresh** icon instead of **search**; no bottom border (AppBar, elevation 0).
2. **Chips:** include Personnalisé and have borders (the shared chip; the overview reference
   uses bordered chips too).
3. **Toggle:** a Material `SegmentedButton` with an outlined border between segments. The
   reference is a filled track with a raised selected segment (`#D9E2FC`, `shadow-sm`).
4. **Cards:**
   - `MerchantCard` (16 px radius + elevation) vs 8 px flat outlined.
   - Rank #1 has a filled 32 px badge instead of the "N°1" ribbon.
   - Ranks #2+ use a 32 px badge (reference 56 px square).
   - No photos, no chevrons, no `shopping_bag` / `payments` icon lines.
   - Extra "N unités" and the "Produit retiré du catalogue" caption (supported, keep).
5. **Footer:** matches ("Synchronisé à HH:mm" from `asOf`). ✓

### Contract

| Element | Status | Source |
| --- | --- | --- |
| Ranking, order count, revenue, total articles, sort toggle | SUPPORTED | `GET /merchant/:id/reports/top-products` (`sort=ORDERS\|REVENUE`, `limit ≤ 50`, `distinctProductCount`), `merchant-sales-report.types.ts` |
| "N°1" ribbon | SUPPORTED (presentation) | — |
| Product photos | PARTIAL | Items carry `productId` (null if deleted), but **no `hasImage`**. The merchant image stream exists at `GET /merchant/:merchantId/branches/:branchId/products/:productId/image` (`catalog/presentation/http/merchant-product-image.controller.ts`), which needs a branch scope and shows the *current* catalog photo, not the historical one. "Product images in top products" is listed under "Not provided" |
| Chevron / row destination | PARTIAL | `/app/catalog/products/:productId` exists but is the **editor** (`ProductEditorScreen`). STAFF cannot manage the catalogue; deleted products have no id. The earlier report's claim of "no product-detail destination" is imprecise |
| Search | NOT SUPPORTED | No `q` / search param in `MerchantTopProductsQueryDto`; client filtering over the top 20 would hide products outside the limit |
| Subtitle person name | NOT SUPPORTED | As in the daily summary |

### Alternatives

- Overview reference top-3 list (same data).
- Implementation report §7 records the ribbon, photo and chevron omissions.

### Required work

1. Cards:
   - 8 px radius, flat, `outline-variant` border, `p-3`, `gap-4`.
   - Rank #1: "N°1" ribbon (`bg-primary`, `rounded-br-lg`) plus the `shopping_bag` /
     `payments` icon lines.
   - Ranks #2+: 56 px rank square (`surface-container`, `primary-container` text, border)
     and the single "N commandes • amount" line (keep units if wanted).
2. Toggle: filled track style (`surface-container-low`; selected `#D9E2FC` + `shadow-sm`
   primary).
3. Header: `border-b outline-variant`; subtitle as today.
4. **Do not add search** without a contract.
5. Photos only after a decision to use current catalog images and a `hasImage` flag (or a
   tolerated 404 fallback) on branch-scoped data.
6. Chevron only if the product decides that rows open the editor, for OWNER/MANAGER and
   non-null `productId`.

### Proposed status

**`partial_contract_limited`**

---

## Cross-cutting findings (fix once)

- **Bottom nav:** see the shell section. The shell uses a minority text-only style; the
  majority is a pill (colour tie). Labels 12/600, bg `#F9F9FF`, soft top shadow, 12 px top
  radius.
- **App bar:**
  - `MerchantScaffold` has no shadow and an `onSurface` title (majority primary).
  - Home uses a separate custom header.
  - The bell is missing on Orders/Catalogue/Reports.
  - Hard-coded `Key('orders-branch-context')` on every subtitle.
- **Card:** `MerchantCard` uses radius 16 + Material elevation 1 (alpha .08) + border
  `outlineVariant@.55`. The references use Tailwind `rounded-xl` = **12 px** (code.html
  config: DEFAULT .25rem, lg .5rem, xl .75rem), shadow `0 2 8 rgba(0,0,0,.04)` and a full
  `outline-variant` border (or `/30`).
  - **Conflict:** `DESIGN.md` prose says cards are 16 px and its YAML `rounded` scale differs
    (`lg: 1rem`, `xl: 1.5rem`) from every code.html config. Record it; do not pick silently.
  - List rows (top products) are 8 px and flat.
- **Status chip:** the reference "Nouveau" uses lime `tertiary-fixed #D3EE78` / `#171E00`,
  4 px radius, `tertiary/20` border; Flutter uses a warning-orange "Nouvelle", 8 px radius.
  `DESIGN.md` wants a leading icon on every chip, which the references do not show.
  Coordinate with the orders batch.
- **Buttons:** the theme `FilledButton` uses `primaryContainer #2F59AF`, 52 h, radius 12,
  16/700. Dashboard/list CTAs in references use `primary #0A4096`, 48 h, `rounded-lg` 8 px,
  `label-lg` 14/600; the daily CTA is 52 h `title-md`. `DESIGN.md` says buttons are 48–52 h
  with a 12 px radius (another DESIGN.md vs code.html conflict).
- **Surface token:** `AppColors.surface` = `#FFFFFF`, but the reference `surface` =
  `#F9F9FF` (`#FFFFFF` is `surface-container-lowest`). Widgets that use `AppColors.surface`
  for reference `bg-surface` (nav, headers) come out whiter than the design.
- **Stale docs:** `MERCHANT_UI_SOURCE_OF_TRUTH.md` §6 reports row, `phase-3-tabs/
  REFERENCE_COMPARISON.md` Rapports and Accueil rows ("no hours API"), and the
  `homeKpiUnavailableHint` string all predate the reports and availability contracts.
- **Raw enum in UI:** settlement `status` (`DRAFT` / `FINALIZED`) is rendered verbatim.

## Unresolved product decisions (not decided here)

1. Bottom-nav active pill colour: secondary-container `#94A6FF` / `#24388B` vs
   primary-container `#2F59AF` / `#C7D5FF` (4–4 tie; DESIGN.md prose favours `#2F59AF`).
   Also: pill style (8/11) vs the dashboard/orders text-only style.
2. Home header: show both "Ouvert" (availability) and "Actif" (operational), or show the
   operational pill only when not ACTIVE? The reference shows one pill.
3. Home KPI "Commandes": completed today (`completedOrderCount`) vs orders received today
   (no source). Also whether to show a 2-KPI strip without Temps moyen.
4. Verification banner destination (no dedicated route), or make it non-interactive.
5. Reports KPI grid: keep the "Temps prép. moy. — Non suivi" card or omit it (the
   source-of-truth doc says omit unsupported controls; it is a metric, not a control).
6. Reports header: keep the refresh icon alongside the bell, or rely on pull-to-refresh.
7. Top products: should rows open the product editor (OWNER/MANAGER only)? Use current
   catalog photos?
8. Whether dedicated "Résumé des ventes" / "Résumé quotidien" screens are wanted once their
   contracts exist.
