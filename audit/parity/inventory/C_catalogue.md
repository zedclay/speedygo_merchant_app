# Parity inventory — C. CATALOGUE journey

Read-only design-parity inventory. No code, tests or existing docs were modified.
References: `screens/MerchantScreens/<folder>/{screen.png,code.html}`. Tokens:
`screens/MerchantScreens/speedygo_merchant_system/DESIGN.md`. Binding guidance:
`apps/merchant_app/docs/MERCHANT_UI_SOURCE_OF_TRUTH.md`.

Flutter surfaces in scope (all under `apps/merchant_app/lib/features/catalog/`):

| Route | Widget | Notes |
| --- | --- | --- |
| `/app/catalog` (shell tab) | `CatalogScreen` (`presentation/catalog_screen.dart`) | `CatalogTab.products` / `CatalogTab.categories` segmented |
| `/app/catalog/products/new` | `ProductEditorScreen()` (`presentation/product_editor_screen.dart`) | create mode (`isCreate`) |
| `/app/catalog/products/:productId` | `ProductEditorScreen(productId:)` | edit mode |
| `/app/catalog/categories/new` and `/:categoryId` | `CategoryEditorScreen` (`presentation/category_editor_screen.dart`) | `id=='new'` → create |

State: `CatalogController` (`application/catalog_controller.dart`) — `GET …/catalog` bootstrap + one `GET …/products?branchId=` call; search/category filtering is **client-side** over that single page. API client: `apps/merchant_app/lib/features/access/data/merchant_api.dart` (lines ~670–970).

Backend contract: `apps/backend/src/modules/catalog/presentation/http/catalog.controller.ts`,
`…/merchant-product-image.controller.ts`, DTOs in `…/dto/catalog-write.dto.ts` and
`…/dto/catalog-response.dto.ts`, Prisma `apps/backend/prisma/contract.prisma` (models `Category`
L566, `Product` L581, `ProductImage` L602, `ProductOptionGroup` L621, `ProductOption` L638),
rules in `docs/architecture/CATALOG_FOUNDATION.md`.

## Summary

| reference | route/state | proposed status | one-line required work |
| --- | --- | --- | --- |
| `liste_des_produits_standardis_e` | `/app/catalog` · `CatalogTab.products` | `needs_work` | Restyle rows/header/FAB to ref, drop category+description lines and ",00", add "En stock/Rupture" label above toggle; paginate beyond first 50 products; omit "/ unité" suffix (no contract) |
| `liste_des_produits_menu_ouvert` | `/app/catalog` · row `PopupMenuButton` | `partial_contract_limited` | Menu to ref style (icons, divider, error delete); remove dead "Dupliquer" snackbar or wire real composition; "Archiver" wording has no contract |
| `product_search_and_filters_french` | none (inline search + chips only) | `partial_contract_limited` | New filters screen from filter icon: search, category, status via server `q/categoryId/available` + `total`; omit units & translation filters; "Image manquante" only client-side |
| `liste_des_cat_gories_standardis_e` | `/app/catalog` · `CatalogTab.categories` | `needs_work` | Rows to ref (article count, inline Visible/Masqué toggle, more_vert, hidden styling), search, "Réorganiser" header action; omit Arabic line |
| `d_tails_de_la_cat_gorie_standardis` | none (row tap → editor) | `needs_work` | New category detail route: header w/ edit, details card (count, visibility, sortOrder), product list w/ toggles, "Ajouter un produit" FAB |
| `modifier_la_cat_gorie_standardis` | `/app/catalog/categories/:id` | `partial_contract_limited` | Tighten visuals (card radius, toggle style); AR name + description stay omitted/gap; map `CATALOG_CATEGORY_IN_USE` on delete |
| `reorder_categories_french` | none | `partial_contract_limited` | New reorder screen (`ReorderableListView`) saving via per-category `PATCH sortOrder`; no atomic batch endpoint |
| `ajouter_un_produit_standardis` | `/app/catalog/products/new` | `partial_contract_limited` | Media dropzone + price row visuals; wire variants/extras (supported) after first save; AR fields, prep time, unit remain unsupported |
| `d_tails_du_produit_standardis` | none (row tap → editor) | `partial_contract_limited` | Optional read-only detail screen: header card, config groups (supported), client preview; no fake short ID; omit AR/unit/prep |
| `modifier_le_produit_standardis_image_corrig_e` | `/app/catalog/products/:id` | `needs_work` | Header subtitle from `updatedAt`, solid banner, availability card, section headers, warning icon, "Enregistrer les modifications"; replace variants/extras gap rows with real navigation |
| `product_image_upload_and_crop_french` | none (picker → direct) | `needs_work` | Crop/rotate/zoom screen client-side (existing `image` pkg), tips card, "Utiliser cette image"; copy must say 2 Mo not 5 Mo |
| `duplicate_product_french` | dead menu item | `partial_contract_limited` | PNG unusable; build from HTML only if composition approved; "brouillon" has no contract |
| `delete_product_logic_fixed` | `AlertDialog` in editor | `partial_contract_limited` | Dedicated delete screen; "archive" ⇒ only `available=false`; historical-use known only after `DELETE` 409 |
| `product_availability_french` | inline `Switch` only | `partial_contract_limited` | Screen with Disponible/Rupture (boolean) only; omit temporary/scheduled, history, sync badge, order ref |
| `bulk_availability_french` | none | `partial_contract_limited` | Multi-select screen looping `PATCH available`; per-item failure reporting; omit temporary status + time presets |
| `required_variants_french` | gap row "Variantes obligatoires" | `needs_work` | New screen on option-groups API (`required=true`); omit AR names + drag reorder; client API + models missing |
| `optional_extras_french` | gap row "Suppléments optionnels" | `needs_work` | New screen on option-groups API (`required=false`, `maxSelections`, option `available`); omit drag reorder |
| `selling_units_french` | gap row "Unité de vente" | `blocked_contract` | No unit field anywhere in contract; keep omitted |
| root `MerchantScreens/screen.png` + `code.html` (Arabic add-product) | would be `/app/catalog/products/new` in `ar` locale | `not_applicable_duplicate` (pending decision) | Different design, not a translation of the French form — see section |

---

## liste_des_produits_standardis_e

### Design
- Files: `screen.png`, `code.html` both readable. PNG omits the bottom nav (cropped at 1024 px); HTML has it.
- Header (`h-14`, `bg-surface`, `shadow-sm`, sticky): left `menu` icon button (primary), centered **"Catalogue"** (`title-lg` 20/28, bold, `text-primary` #0a4096), right `notifications` icon (primary).
- Segmented control (`px-16 mb-24`): container `bg-surface-container` #e9edff, `p-1`, `rounded-lg` (8px per HTML tailwind config); selected **"Produits"** `bg-surface shadow-sm rounded-md label-lg` on-surface; unselected **"Catégories"** on-surface-variant.
- Search row: input `h-12`, `rounded-lg`, `border-outline-variant`, `bg-surface`, leading `search` icon (outline-variant), placeholder **"Rechercher un produit..."**; separate square `h-12 w-12` button with `filter_list` icon (outlined, rounded-lg).
- Category chips (horizontal scroll): selected **"Tous"** `bg-primary-container` #2f59af `text-on-primary-container` #c7d5ff, `rounded-full px-4 py-2 label-md` (12/16, 600), shadow-sm; unselected `bg-surface-container-lowest` white, `border-outline-variant`, on-surface.
- Product cards (`gap-12`): `bg-surface-container-lowest`, `p-[12px_16px]`, `rounded-xl` (12px), `shadow-[0_2px_8px_rgba(0,0,0,0.04)]`, `border-surface-variant` #d9e2fc, `flex items-center gap-4`.
  - Thumb `64×64 rounded-lg bg-surface-container`; placeholder uses category-like Material Symbols (`bakery_dining`, `local_cafe`) in outline, `text-3xl`.
  - Title `title-md` 16/24 600 truncate; price `body-md text-primary mt-1` **"1 500 DZD / plat"** (no decimals, unit suffix).
  - Right cluster: status label above toggle — **"En stock"** `label-md text-tertiary-container` #516400 / **"Rupture"** `text-outline` #747783; toggle 40×20, on = track `tertiary-fixed` #d3ee78 + thumb border tertiary-container, off = track `surface-variant`; then `more_vert` icon button (on-surface-variant).
  - Unavailable card: whole card `opacity-75`, image `grayscale-[30%]`.
- FAB: `fixed bottom-24 right-4`, `bg-primary` #0a4096, `rounded-2xl`, `py-4 px-6`, `title-md`, shadow `0_4px_12px_rgba(10,64,150,0.3)`, `add` icon + **"Ajouter un produit"**.
- Bottom nav: 5 tabs Accueil / Commandes / **Catalogue** (active: `bg-primary-container text-on-primary-container rounded-full px-4`, filled `inventory_2`) / Rapports / Profil; `rounded-t-xl`, shadow up.

### Flutter mapping
`CatalogScreen` → `/app/catalog`, `CatalogState.tab == CatalogTab.products`; rows `_ProductCard`; thumb `MerchantProductThumb` (52 px); FAB `catalog-add-fab`. Current look: `audit/phase-5-ui/mocked/catalog_populated_se.png`.

### Differences
- App bar: left-aligned "Catalogue" with `refresh` action; no menu icon, no bell (ref centered primary title + menu + bell).
- No filter button next to search; search placeholder uses `…` ellipsis char (fine) — Flutter search has `surface` fill, 12px radius.
- Chips: Material `ChoiceChip` with check mark and `primaryContainer` fill + `onPrimary` text (ref: no check, on-primary-container text, full-pill radius, white unselected with outline).
- Rows add a **category name line and description line** (ref: title + price only). Thumb 52 vs 64 px; placeholder icon `inventory_2_outlined` for all.
- Price formatted `1 500,00 DZD` (`MoneyFormat.dzd`) vs ref `1 500 DZD`; unit suffix absent (correct — no contract).
- Manager rows: no "En stock/Rupture" label above the switch; switch is Material `Switch` scaled 0.75 (no check-in-thumb). Unavailable rows not dimmed.
- Card radius 16 (`MerchantLayout.radiusCard`) + elevation 1 vs ref 12px radius + 4% soft shadow + `surface-variant` border.
- FAB `FloatingActionButton.extended` default colors (renders primaryContainer #2f59af) vs ref `primary` #0a4096, radius 16.
- Bottom nav: no active pill (see cross-cutting).
- **Structural:** only the first page (backend default `limit=50`, `CATALOG_PRODUCT_LIST_DEFAULT_LIMIT` in `apps/backend/src/modules/catalog/domain/catalog.policy.ts`) is loaded; `total` ignored (`merchant_api.dart` `listProducts` sends only `branchId`). Search/category filtering is client-side over that page, so merchants with >50 products silently lose rows.

### Contract
- List/filter/paginate: **SUPPORTED** `GET /merchant/:merchantId/products?branchId&categoryId&available&q&limit&offset` → `{items,limit,offset,total}` (`catalog.controller.ts` `listProducts`; `ListCatalogProductsQueryDto`). `q` is name-only `LIKE` contains (`catalog.repository.ts` `productCollection`); Flutter additionally matches description client-side.
- Availability toggle: **SUPPORTED** `PATCH /products/:id {available}`.
- Thumb: **SUPPORTED** `hasImage` + `GET …/branches/:branchId/products/:id/image`.
- Unit suffix "/ plat": **NOT SUPPORTED** (no unit column on `Product`, `contract.prisma` L581–600).

### Alternatives
`liste_des_produits_menu_ouvert` (same list, menu open). `MERCHANT_UI_SOURCE_OF_TRUTH.md` §6 records this screen `implementer_reviewed` ("description/category on rows; no create FAB" — the FAB now exists). Unresolved: whether to keep the extra category/description lines (source-of-truth notes them as an accepted delta) vs ref's two-line row.

### Required work
1. App bar per cross-cutting decision (centered primary title; bell → `/app/notifications`; menu icon only if a real destination exists — else omit; keep refresh via pull-to-refresh).
2. Row: 64 px thumb, title + price only (decide on category/description lines), status label above toggle for OWNER/MANAGER, dim unavailable rows, ref toggle styling.
3. Chips + FAB + card tokens per ref.
4. Paginate (`limit`/`offset` with `total`) or push `q`/`categoryId` to the server; never show a truncated list as complete.
5. Do not render a unit suffix.

### Proposed status
`needs_work`

---

## liste_des_produits_menu_ouvert

### Design
- Files readable. Same page as above with a context menu overlay: `fixed w-[220px] bg-white rounded-xl shadow-lg border-outline-variant py-2`, anchored below the row's `more_vert`.
- Items (`px-4 py-3 gap-3`, icon `text-primary`, label `font-label-lg` on-surface):
  1. `edit` **"Modifier le produit"**
  2. `event_available` **"Gérer la disponibilité"**
  3. `content_copy` **"Dupliquer"**
  4. divider `h-px bg-outline-variant mx-4`
  5. `delete` (`text-error`) **"Archiver / Supprimer"**

### Flutter mapping
`_ProductCard` → `PopupMenuButton` (`catalog-product-menu-<id>`), OWNER/MANAGER only; items "Modifier le produit" and "Dupliquer".

### Differences
- Only 2 items, no icons, no divider, no availability or delete entries.
- **Dead action:** "Dupliquer" shows `AppStrings.catalogDuplicateUnsupported` ("La duplication n'est pas disponible.") — violates "no dead actions".
- Material default popup styling vs 220 px rounded-xl bordered card.

### Contract
- Modifier: **SUPPORTED** (editor route).
- Gérer la disponibilité: **PARTIAL** — only boolean `available` (see `product_availability_french`).
- Dupliquer: **PARTIAL** — no clone endpoint; composable from existing calls (see `duplicate_product_french`). `CATALOG_FOUNDATION.md` lists "product cloning" out of scope.
- Archiver / Supprimer: **PARTIAL** — `DELETE /products/:id` hard-deletes or returns 409 `CATALOG_PRODUCT_IN_USE`; there is **no archive state** (`CATALOG_FOUNDATION.md` "Do not introduce archive fields"; `available=false` "is not archive").

### Alternatives
`delete_product_logic_fixed`, `duplicate_product_french`, `product_availability_french` are the menu destinations.

### Required work
- Restyle menu (icons, divider, error-tinted delete).
- Remove "Dupliquer" until a real flow exists (or implement the approved composition).
- Add "Gérer la disponibilité" only if the availability screen ships; add delete entry → delete flow.
- Label for last item must not promise "Archiver" unless product approves `available=false` wording (see unresolved decisions).

### Proposed status
`partial_contract_limited`

---

## product_search_and_filters_french

### Design
- Files readable.
- Header `h-14` sticky: `arrow_back` (on-surface-variant), title **"Recherche et Filtres"** (`title-lg` bold on-surface, left), right text button **"Réinitialiser"** (`label-lg text-primary`).
- Search input `h-12 rounded-lg bg-surface-container-lowest border-outline-variant body-lg`, `search` icon, placeholder **"Rechercher un produit..."**.
- Sections (`gap-24`, heading `title-md`), wrapping chips `px-4 py-2 rounded-full label-md`:
  - **"Catégories"** — selected `bg-primary border-primary text-on-primary`; others white w/ outline-variant, on-surface-variant.
  - **"Statut"** — **"En stock"** selected `bg-tertiary-fixed text-on-tertiary-fixed` + `check_circle`; **"Rupture de stock"** + `cancel`.
  - **"Unités de vente"** — Portion / Assiette (selected) / Pièce / Kilogramme.
  - **"Contrôle qualité"** — `image_not_supported` **"Image manquante"**, `translate` **"Traduction manquante"**.
- **"Aperçu des résultats"** + right count **"12 produits"**; result cards `rounded-lg p-[12px_16px]`, 48 px icon tile `bg-surface-container-high`, title + price, badge `bg-tertiary-fixed text-on-tertiary-fixed` `check` **"En stock"**.
- Sticky footer: full-width `h-12 bg-primary rounded-lg title-md bold` **"Appliquer les filtres"** + pill count `(12)` (`bg-white/20`).
- No bottom nav.

### Flutter mapping
None. Current catalog has an inline search field + category `ChoiceChip`s only (`_CatalogBody`). Would live at e.g. `/app/catalog/filters` (root navigator) opened from a filter icon on `CatalogScreen`.

### Differences
Screen absent. No status filter, no result count, no reset.

### Contract
- Search: **SUPPORTED** `q` (name contains).
- Category: **SUPPORTED** `categoryId` (single value — the ref appears single-select; multi-select would be **NOT SUPPORTED**).
- Statut: **SUPPORTED** `available=true|false`.
- Result count: **SUPPORTED** `total` in list response.
- Unités de vente: **NOT SUPPORTED** (no unit field).
- Image manquante: **PARTIAL** — `hasImage` is on each list item but there is no server filter; only correct client-side if all pages are loaded.
- Traduction manquante: **NOT SUPPORTED** (no Arabic/translation fields on `Product`).

### Alternatives
Inline search/chips on `liste_des_produits_standardis_e`. Unresolved: full-screen filters vs inline chips (both designed).

### Required work
Build the screen with search, category, status and live count from `total`; omit units and translation sections; include "Image manquante" only if all products are fetched (or drop it). "Réinitialiser" clears local filter state only.

### Proposed status
`partial_contract_limited`

---

## liste_des_cat_gories_standardis_e

### Design
- Files readable. PNG crops bottom nav; HTML includes the 5-tab nav.
- Header (`border-b`, `px-16 pt-2 pb-3`): left `menu` + **"Catalogue"** (`title-lg` primary bold, left-aligned here, unlike the product list), right text link **"Réorganiser"** (`label-lg text-primary`) + `notifications`. Segmented control inside header (`max-w-sm`, `py-1.5`, **"Produits"** / **"Catégories"** selected with border).
- Search `h-[48px]` `rounded` (4px) placeholder **"Rechercher une catégorie..."** + filter button `filter_list`.
- Category cards `bg-surface-container-lowest rounded border-outline-variant p-4 shadow-[0_2px_8px_rgba(0,0,0,0.04)]`:
  - name `title-md`; Arabic name below (`label-md dir=rtl`); `inventory_2` 16px + **"12 articles"** (`body-md` on-surface-variant).
  - right: toggle (`w-11 h-6`) with caption **"Visible"** (`text-[10px] text-tertiary-container`) / **"Masqué"** (`text-outline`); `more_vert` 48×48.
  - Hidden category: card `bg-surface-container opacity-80`, name `line-through`, extra badge `visibility_off` **"Masqué"** (`bg-surface-variant text-[10px] rounded border`).
- FAB `bottom-[100px] right-4 bg-primary h-12 px-6 rounded-full shadow-lg label-lg` `add` **"Ajouter une catégorie"**.

### Flutter mapping
`CatalogScreen` · `CatalogTab.categories` → `_CategoriesList`; row tap (OWNER/MANAGER) → `/app/catalog/categories/:id`.

### Differences
- Rows show name + `StatusBadge` **"Actif"/"Inactif"** + chevron (ref: "Visible"/"Masqué" toggle + count + more_vert). No inline toggle, no article count, no hidden styling.
- No category search, no filter button, no "Réorganiser" action.
- FAB is extended Material (radius 16) vs full-pill.
- Header per product-list differences.

### Contract
- Visibility toggle: **SUPPORTED** `PATCH /categories/:id {active}`.
- Article count: **PARTIAL** — bootstrap `stats` has only branch totals (`CatalogStats`); per-category count requires `GET /products?categoryId=…&limit=1` → `total` per category (N calls) or a full product fetch.
- Arabic name: **NOT SUPPORTED** (`Category` has `name` only, `contract.prisma` L566–579; `name_ar` exists only for wilayas/communes in `docs/database/ERD.md`).
- Category search: client-side only (list unpaginated) — acceptable.
- Reorder: see `reorder_categories_french`.
- Delete from menu: **SUPPORTED** `DELETE /categories/:id` (409 `CATALOG_CATEGORY_IN_USE` when non-empty).

### Alternatives
`d_tails_de_la_cat_gorie_standardis`, `modifier_la_cat_gorie_standardis`, `reorder_categories_french`.

### Required work
Ref rows (count, inline Visible/Masqué toggle for OWNER/MANAGER, read-only label for STAFF, hidden styling), category search, "Réorganiser" action, pill FAB; omit Arabic line; source counts from real `total`s (no guessing).

### Proposed status
`needs_work`

---

## d_tails_de_la_cat_gorie_standardis

### Design
- Files readable. No bottom nav.
- Header `h-14 border-b`: `arrow_back`, centered **"Détails de la catégorie"** (`title-lg` primary bold), `edit` icon right.
- Page title `headline-md` (24/32 600) **"Plats Traditionnels / أطباق تقليدية"**.
- Details card `rounded-xl p-16 shadow-sm border-outline-variant/30`: **"Détails de la catégorie"** (`title-md`), **"12 articles"**; right **"Visible"** (`label-md text-tertiary`) + toggle; row `format_list_numbered` **"Ordre d'affichage: 1"**.
- **"Produits"** heading; product cards `rounded-lg p-[12px_16px] shadow-sm`: title, price `text-primary font-semibold` ("1 500 DZD"); right badge **"En stock"** (`bg-tertiary-fixed-dim/20 text-tertiary-fixed-dim` + `check_circle`) or **"Rupture"** (`bg-error-container text-on-error-container` + `cancel`) with a small toggle below; unavailable row `opacity-75`.
- FAB `bottom-6 right-6 bg-primary h-14 rounded-xl` **"Ajouter un produit"**.

### Flutter mapping
None — tapping a category opens `CategoryEditorScreen`. Would live at e.g. `/app/catalog/categories/:id` (detail) with editor at `…/:id/edit`.

### Differences
Screen absent.

### Contract
- Name, active, sortOrder: **SUPPORTED** (category record from bootstrap/list).
- Products in category + count: **SUPPORTED** `GET /products?categoryId=&limit&offset` (`total`).
- Per-product toggle: **SUPPORTED**.
- Arabic title: **NOT SUPPORTED**.
- "Ajouter un produit" preselecting category: client-only (create DTO accepts `categoryId`).

### Alternatives
Categories list + editor already cover edit; this adds a read view. Unresolved: whether tap on a category row opens this detail or the editor.

### Required work
New detail screen with real counts/sortOrder (display as 1-based position or raw value — decide), product list with availability toggles (OWNER/MANAGER), FAB → create with category preselected; edit icon → editor.

### Proposed status
`needs_work`

---

## modifier_la_cat_gorie_standardis

### Design
- Files readable.
- Header `h-16 bg-surface-container-lowest border-b shadow-sm`: `arrow_back`, centered **"Modifier la catégorie"** (`title-lg` on-surface, not bold), spacer.
- Section card 1 (`rounded-lg` 8px, `border-outline-variant`, `p-16`, 4% shadow): `translate` icon (primary) + **"Détails de la catégorie"**; field **"Nom de la catégorie (Français) \*"** (`h-48 rounded bg-surface-bright`); RTL field **"\* Nom de la catégorie (Arabe)"** right-aligned.
- Section card 2: `settings_suggest` + **"Paramètres"**; row **"Visibilité dans le menu"** / **"Afficher cette catégorie aux clients"** with toggle (track `on-tertiary-container` #c7e16d, thumb check in PNG); **"Description de la catégorie (Optionnel)"** + helper **"Visible par les clients dans l'application."** + textarea placeholder "Ajoutez une courte description de cette catégorie…".
- Sticky footer: **"Annuler"** (outlined primary) | **"Enregistrer"** (`bg-primary` + filled `save`), equal widths, `h-48 rounded-lg`.

### Flutter mapping
`CategoryEditorScreen(categoryId:)` → `/app/catalog/categories/:id`. Evidence: `audit/phase-5-ui/comparisons/category_edit_ref_vs_mocked_se.png`.

### Differences
- Section titles primary-colored with Material `translate`/`settings` icons (ref on-surface titles, `settings_suggest`).
- Card radius 16 + elevation vs 8px + soft shadow. Field fill `surfaceContainerLow` (tinted) vs `surface-bright`.
- Switch: Material primary thumb vs ref green track + check thumb.
- AR name and description rendered as disabled `MerchantContractGapRow` "Non disponible actuellement".
- Extra "Supprimer la catégorie" outlined button inside Paramètres (ref has no delete here).
- Footer ratio 2:3 (`MerchantDualStickyBar`) vs equal halves.
- Validation error on empty name reuses the save-failure copy (`catalogSaveError`).
- Delete 409 `CATALOG_CATEGORY_IN_USE` shows generic "Enregistrement impossible…" (no error-code mapping; `rg CATALOG_ lib` returns nothing).

### Contract
- name, active: **SUPPORTED** `PATCH /categories/:id`.
- sortOrder: **SUPPORTED** but not exposed in editor (ref doesn't show it here either).
- Arabic name, description: **NOT SUPPORTED** (`Category` model).
- Delete: **SUPPORTED** with 409 when products exist.

### Alternatives
Create mode uses the same widget (`/app/catalog/categories/new`, title "Ajouter une catégorie"). Documented in `audit/phase-5-ui/CONTRACT_GAPS.md` (AR name, category description).

### Required work
Visual tightening (tokens, toggle, footer ratio); decide whether gap rows remain visible or are omitted (source-of-truth §4 says "omit unsupported controls"); field-level validation copy; map `CATALOG_CATEGORY_IN_USE` to an explicit "catégorie non vide — masquez-la" message.

### Proposed status
`partial_contract_limited`

---

## reorder_categories_french

### Design
- Files readable. No bottom nav.
- Header `h-16 border-b`: `arrow_back` + **"Réorganiser les catégories"** (`title-lg` bold, left).
- Info strip `bg-surface-container-low`: **"4 Catégories"** (`label-lg`) + **"Faites glisser pour modifier l'ordre d'affichage."** (`text-outline`).
- Draggable cards `bg-white border-outline-variant rounded-lg p-16 shadow-sm`: position number (`title-md bold text-outline`, w-8), name `title-md`, Arabic name (rtl), badge **"Visible"** (`bg-tertiary-fixed text-on-tertiary-fixed`, filled `visibility`) or **"Masqué"** (`bg-surface-variant`, `visibility_off`); trailing `drag_handle`. Hidden card `bg-surface-container-low opacity-80`.
- Sticky footer: **"Réinitialiser"** (outlined `border-outline`) | **"Enregistrer l'ordre"** (`bg-primary shadow-md`).

### Flutter mapping
None. Would live at `/app/catalog/categories/reorder`, reached from "Réorganiser" on the categories tab. Flutter `ReorderableListView` is in the SDK (no new dependency).

### Differences
Screen absent. Current list order = backend `sortOrder asc` (`catalog.repository.ts` L56).

### Contract
**PARTIAL.** `sortOrder` is client-editable on `PATCH /categories/:id` (`UpdateCatalogCategoryDto`, range ±100 000). No batch/atomic reorder endpoint: saving N positions = N PATCH calls; a mid-way failure leaves a mixed order. Flutter client `updateCategory` already accepts `sortOrder` (`merchant_api.dart` ~L856) but `CatalogController.updateCategory` does not pass it.

### Alternatives
None. Contract need (optional): `PUT /categories/order` with ordered ids for atomicity.

### Required work
Reorder screen writing sequential `sortOrder` via PATCH, only for rows whose value changed; on partial failure reload and show which rows failed (no fake success). "Réinitialiser" restores server order. Omit Arabic line.

### Proposed status
`partial_contract_limited`

---

## ajouter_un_produit_standardis

### Design
- Files readable (PNG is a tall 218×1024 thumbnail but legible).
- Header `h-14 shadow-sm`: `arrow_back` (primary), centered **"Ajouter un produit"** (`title-lg` on-surface).
- Cards `bg-surface-container-lowest p-16 rounded-xl shadow-[0_2px_8px_rgba(0,0,0,0.04)] border-outline-variant/30`, section headings `title-md text-primary` with 20px icon:
  1. `info` **"Informations"** — **"Nom du produit (Français)"** (`h-12 rounded-lg bg-surface-bright`), **"Nom du produit (Arabe)"** + `RTL` tag, **"Description (Français)"** textarea (3 rows), **"Description (Arabe)"** + `RTL`, **"Catégorie"** select with `arrow_drop_down`.
  2. `image` **"Médias"** — dropzone `border-2 border-dashed border-primary-fixed-dim bg-surface-container-low rounded-xl p-6`, 56px circle `bg-primary-container` with `add_a_photo`, **"Ajouter une photo"** (`label-lg text-primary`), **"JPG, PNG (Max 5MB)"**; below, preview `h-40 rounded-lg` with `delete` button (`bg-surface/80 text-error`, top-right) and **"Image Principale"** tag bottom-left.
  3. `payments` **"Prix et préparation"** — row: **"Prix de base"** (right-aligned, suffix `DZD`) | **"Temps de prép."** (suffix `min`); **"Unité de vente"** radio chips Plat / Portion / Pièce / Kilogramme (`rounded-lg`, selected `bg-primary-container text-on-primary-container border-primary`).
  4. `settings` **"Configuration"** — rows **"Variantes obligatoires"** (sub "Portion · 2 options") and **"Suppléments optionnels"** (sub "Suppléments viande · 2 options") with `chevron_right`; divider; **"Visible dans le menu"** / **"Activer pour rendre disponible"** toggle (primary).
- Sticky footer: **"Aperçu"** (flex-1, `bg-surface-container border-primary text-primary`) | **"Enregistrer"** (flex-2, `bg-primary`, `save` icon).

### Flutter mapping
`ProductEditorScreen()` → `/app/catalog/products/new` (`isCreate`). Evidence: `audit/phase-5-ui/comparisons/product_create_ref_vs_mocked_se.png`, `product_create_scrolled_ref_vs_mocked_se.png`.

### Differences
- Section order matches (Informations → Médias → Prix et préparation → Configuration) and CTA copy matches.
- Red required asterisks on name/category/price (ref FR has none).
- AR name/desc, "Temps de prép.", "Unité de vente", "Variantes obligatoires", "Suppléments optionnels" all rendered as disabled gap rows.
- Media: custom 1.5px dashed painter, no filled circle icon; shows dropzone **or** preview (ref shows both); delete button is solid error circle w/ white icon; hint "JPG, PNG (max. 2 Mo, min. 400 px)" (correct vs ref "Max 5MB").
- Price field full-width (ref half-width beside prep time).
- Card radius 16 + elevation; field fill tinted.
- Footer ratio 2:3 vs 1:2.

### Contract
- name, description, categoryId, priceMinor, available: **SUPPORTED** `POST /products`.
- Image: **SUPPORTED** after create (`POST …/image/content` → `PUT …/image`), one image per product (`ProductImage.productId @unique`). Limits JPEG/PNG, 400–4096 px, 2 MiB (`merchant-product-image.controller.ts`, `CATALOG_FOUNDATION.md` "Product media").
- Variantes / Suppléments: **SUPPORTED** by `…/products/:productId/option-groups` (+ `/options`) — but require an existing `productId` (nested create "not supported", `CATALOG_FOUNDATION.md`). Flutter client has **no** option-group methods and `CatalogProduct.fromJson` ignores `optionGroups`.
- Arabic name/description: **NOT SUPPORTED**.
- Temps de prép. (product-level): **NOT SUPPORTED** — explicitly out of scope in `docs/architecture/MERCHANT_ORDER_PREPARATION_ESTIMATE_FOUNDATION.md` ("Product-level default prep minutes catalog field").
- Unité de vente: **NOT SUPPORTED**.

### Alternatives
Root Arabic RTL pair (see last section). `modifier_le_produit_standardis_image_corrig_e` for edit.

### Required work
Media dropzone/preview visuals per ref; price row layout (price only — omit prep field rather than half-empty row, or keep gap row per decision); wire "Variantes obligatoires"/"Suppléments optionnels" rows to real screens — in create mode they need a saved product first (e.g. save then continue); keep 2 Mo hint; decide gap-row vs omission for AR/prep/unit.

### Proposed status
`partial_contract_limited`

---

## d_tails_du_produit_standardis

### Design
- Files readable. **PNG/HTML conflict:** PNG renders the `md:grid-cols-2` layout at phone width (right column clipped); HTML intends single column on mobile.
- Header fixed `h-14`: `arrow_back` + **"Détails du Produit"** (`headline-md` bold primary, left).
- Summary card `bg-white rounded-xl p-16`: 96px image; **"Couscous Royal / كسكس ملكي"** (`title-lg`); **"ID: PRD-4928A"**; badges **"En stock"** (`bg-tertiary-container/10 text-tertiary-container rounded-full`) + category pill.
- `translate` **"Informations Bilingues"** — read-only fields **"Nom (Français)"**, **"Description (Français)"**, divider, **"الاسم (عربي)"**, **"الوصف (عربي)"**.
- `storefront` **"Tarification & Logistique"** — tiles **"Prix de Base"** (1 500 DZD), **"Unité"** (Plat), **"Temps de Préparation"** (25 min, `timer`).
- `tune` **"Configuration"** — group **"Portion"** with **"Obligatoire · Sélection unique"** (primary), options with `+0 DZD` / `+700 DZD`; group **"Suppléments viande"** **"Facultatif · Maximum 3"**.
- **"Aperçu Client"** ribbon card (`bg-surface-container shadow-inner`) **"Apparence sur l'application"**: 256px mock customer card (image, name, 2-line desc, price, `add` button).
- Sticky footer: availability toggle (tertiary) **"Produit Disponible"** | **"Modifier le produit"** (`bg-primary`, filled `edit`).

### Flutter mapping
None — row tap opens `ProductEditorScreen` directly. Would live at `/app/catalog/products/:id` (detail) with editor at `…/:id/edit`.

### Differences
Screen absent. Editor has a local "Aperçu du produit" bottom sheet (name/desc/category/price/availability/image) — partial analogue of "Aperçu Client".

### Contract
- Summary, FR info, price, availability, image: **SUPPORTED** (`GET /products/:id` detail + image stream).
- Configuration groups (required/min/max, options, `additionalPriceMinor`): **SUPPORTED** in the same detail response (`CatalogProductDetailResponseDto.optionGroups`).
- "ID: PRD-4928A": **NOT SUPPORTED** — ids are UUIDs; a short product code does not exist (do not invent).
- Arabic fields, Unité, Temps de Préparation: **NOT SUPPORTED**.

### Alternatives
Editor edit mode covers most content. Unresolved: whether a read-only detail step is wanted before edit (list tap → detail vs → editor).

### Required work
If approved: detail screen from real detail DTO incl. option groups, availability toggle footer, client preview built only from real fields; omit ID line (or show nothing), bilingual/unit/prep blocks.

### Proposed status
`partial_contract_limited`

---

## modifier_le_produit_standardis_image_corrig_e

### Design
- Files readable. **PNG/HTML conflict:** footer is `flex-col-reverse` on mobile in HTML (Aperçu below save), PNG shows side-by-side; PNG image slot shows a SpeedyGo logo placeholder ("image corrigée").
- Header sticky `h-14`: `arrow_back` (primary) + left-aligned title **"Modifier le produit"** (`title-lg` primary) with subtitle **"Dernière mise à jour : Aujourd'hui à 11:20"** (`label-md` on-surface-variant).
- Banner `bg-primary-container` #2f59af `text-on-primary-container`, filled `info`: **"Cet article est actuellement en ligne pour les clients."**
- Availability card `rounded-xl p-16`: filled `check_circle` (tertiary-container) + **"Disponibilité"** / **"Actuellement en stock"** + tertiary toggle.
- **"Image du produit"** card (plain title, no icon): 4:3 image `rounded-lg border`; hover `edit` overlay; helper **"Une image de haute qualité aide les clients à faire leur choix. Formats recommandés : JPG ou PNG."**; outlined button `upload` **"Changer la photo"**.
- **"Informations Générales"** (title with bottom border): **"Nom du produit (Français)"**, **"Nom du produit (Arabe)"** + tag **"Requis"**, **"Description (Français)"**, **"Description (Arabe)"**.
- **"Prix et Détails"**: warning box `bg-error-container text-on-error-container` filled `warning` **"Les changements de prix et de disponibilité sont appliqués immédiatement aux clients."**; **"Prix"** (right-aligned, `DZD`); row button **"Unité de vente"** / "Plat" + chevron; **"Temps de préparation"** (`min`).
- **"Configuration"**: **"Variantes obligatoires"** ("Portion · 2 options") | divider | **"Suppléments optionnels"** ("Suppléments viande · 2 options"), chevrons.
- Footer: **"Aperçu"** (outlined) + **"Enregistrer les modifications"** (`bg-primary`, filled `save`).

### Flutter mapping
`ProductEditorScreen(productId:)` → `/app/catalog/products/:id`, `_StatusBanner`, `MerchantEditorSection`s. Evidence: `audit/phase-5-ui/comparisons/product_edit_ref_vs_mocked_se.png`, `live/live-product-reopen-se.png`, `media-live/media-product-reopened.png`.

### Differences
- Title is left-aligned (`centerTitle: false`, matches) but there is **no "Dernière mise à jour" subtitle**; `CatalogProduct` does not parse `updatedAt`.
- Banner is 12% tint + primary text (ref solid primary-container + light text).
- Availability is a sectioned `SwitchListTile` ("Actuellement en stock." with period, primary switch) vs compact card with status icon + tertiary toggle.
- Image section: icon header; hint is the 2 Mo contract hint; button icon `add_photo_alternate_outlined`; destructive solid red circle on image (ref: no delete in edit).
- Section headers use icon + primary title (ref: plain on-surface title with bottom rule).
- Price warning: 45% error-container, no icon, error text color.
- **Variants/Extras shown as "Non disponible actuellement" gap rows although the backend supports option groups** — `audit/phase-5-ui/CONTRACT_GAPS.md` L19 lists them as unsupported, which is inaccurate against `catalog.controller.ts` L307–480.
- Extra "Supprimer" outlined button in Configuration (ref: delete lives in list menu → delete screen).
- Primary CTA "Enregistrer" vs ref "Enregistrer les modifications" (`AppStrings.catalogSaveProductEdits` exists but equals "Enregistrer").
- Category cannot be changed in edit (matches ref; contract allows `categoryId` PATCH).

### Contract
- name, description, priceMinor, available, categoryId: **SUPPORTED** `PATCH /products/:id`.
- "Dernière mise à jour": **SUPPORTED** `updatedAt` on summary/detail DTO.
- Image replace/delete: **SUPPORTED** (bind replaces; `DELETE …/image`).
- Variantes / Suppléments: **SUPPORTED** (option groups); client missing.
- Arabic fields, unit, prep time: **NOT SUPPORTED**.
- Delete: **SUPPORTED** with 409 `CATALOG_PRODUCT_IN_USE`; Flutter shows generic save error on 409.

### Alternatives
`ajouter_un_produit_standardis` (create), `d_tails_du_produit_standardis` (read view), `product_image_upload_and_crop_french` (image step).

### Required work
Subtitle from real `updatedAt` (formatted relative/absolute; no fake time); banner/availability/warning/section-header styling to ref; "Changer la photo" → image screen; real variants/extras navigation with summaries from `optionGroups` ("<group> · N options"); rename CTA; move delete to the ref delete flow (or keep, per decision) and map 409 to an explicit message; correct `CONTRACT_GAPS.md` in a later doc pass (not in this task).

### Proposed status
`needs_work`

---

## product_image_upload_and_crop_french

### Design
- Files readable.
- Header `h-16 border-b`: `arrow_back`, centered **"Image du produit"** (`title-lg` primary bold).
- Crop stage: full-width **aspect-square** image; overlay `inset-4 border-2 border-primary border-dashed` with rule-of-thirds lines and 4 corner handles (`w-4 h-4 bg-primary rounded-full`); floating round buttons bottom-right `rotate_right`, `zoom_in` (`bg-surface-container-lowest/90 backdrop-blur border`).
- Action row: `photo_library` **"Changer la photo"** (flex-1 outlined primary, `h-12 rounded`) + square error-outlined `delete` (aria "Supprimer l'image").
- Tips card `rounded-lg border p-4`: `lightbulb` **"Conseils pour une belle photo"**; three `check_circle` bullets ("Utilisez un fond neutre et propre (blanc ou bois clair).", "Assurez-vous d'avoir un bon éclairage, de préférence naturel.", "Centrez le produit ('Couscous Royal') dans le cadre."); footer `info` **"Format : JPG, PNG (Max 5Mo)"**.
- Sticky footer: full-width `bg-primary h-12` **"Utiliser cette image"**.

### Flutter mapping
None. `pickMerchantImage` (`lib/core/media/merchant_image_picker.dart`) opens gallery/camera sheet, then `prepareMerchantImage` bakes orientation, downsizes to ≤4096 px, rejects <400 px, re-encodes JPEG ≤2 MiB — no crop/rotate/zoom UI. Would live as a pushed route/modal after picking, before returning bytes to `ProductEditorScreen`.

### Differences
Screen absent; no crop, rotate, zoom, or tips.

### Contract
**SUPPORTED** (server needs only bytes): `POST …/branches/:branchId/products/:productId/image/content` (multipart `file`, JPEG/PNG, 400–4096 px, ≤2 MiB) → `PUT …/image {uploadReference}`; `DELETE …/image`. Crop/rotate are client-side; `image` ^4.10 (already in `pubspec.yaml`) provides `copyCrop`/`copyRotate`, so no new dependency is required. "Max 5Mo" contradicts backend 2 MiB.

### Alternatives
Editor inline image block. **Unresolved aspect conflict:** crop frame is square, editor previews are 4:3 (`MEDIA.md` "Product image preview: 4/3"), list thumbs are square.

### Required work
Crop/rotate/zoom screen after pick, producing JPEG within contract limits; tips card (product name in tip must be the real name or generic text); copy "JPG, PNG (max. 2 Mo)"; delete action only for an existing bound image (calls `DELETE …/image`) or clearing a local pick.

### Proposed status
`needs_work`

---

## duplicate_product_french

### Design
- **`screen.png` is unusable**: 669×1600 solid black (3 208 bytes). HTML `body` has `md:hidden`, likely why the export rendered blank. Design below is from `code.html` only.
- Header fixed `h-14`: `close` icon, centered **"Dupliquer le produit"** (`title-lg` primary bold).
- Source card `rounded-xl p-16 shadow`: 80px image, **"SOURCE"** (`label-md uppercase tracking-wider`), name, category, price (`text-primary bold`).
- `edit` **"Nouveau nom du produit"**, helper **"Veuillez modifier le nom avant de publier la copie."**, input `h-12 rounded-lg border-outline` prefilled **"Copie de Couscous Royal"** + clear `cancel` icon.
- **"Éléments copiés"** card (`bg-surface-container-low rounded-xl`): filled `check_circle` rows **"Image du produit"**, **"Prix (1 500 DZD)"**, **"Options et variantes"**, **"Unités de vente"**.
- Warning `bg-error-container/30 border-error-container`: **"Le statut de disponibilité et l'historique des ventes ne seront pas copiés vers le nouveau produit."**
- Info `bg-surface-container-low`: **"La copie sera créée comme brouillon afin que vous puissiez la vérifier avant publication."**
- Footer (rounded-full buttons): **"Annuler"** (flex-1 outlined) | `content_copy` **"Créer la copie"** (flex-2 primary).

### Flutter mapping
Row menu "Dupliquer" → snackbar "La duplication n'est pas disponible." (dead action). No screen.

### Differences
Screen absent; current menu item is a dead action.

### Contract
**PARTIAL** — no clone endpoint (`CATALOG_FOUNDATION.md` Out: "product cloning"). Composable client-side, non-atomically: `GET /products/:id` (detail incl. `optionGroups`) → `POST /products` → `POST …/option-groups` + `POST …/options` per group/option → image: `GET …/image` bytes → `POST …/image/content` → `PUT …/image`. Failure mid-way leaves a partial copy that must be surfaced (and optionally deleted).
- "Unités de vente": **NOT SUPPORTED** (nothing to copy).
- "brouillon"/draft: **NOT SUPPORTED** — no DRAFT status (`CATALOG_FOUNDATION.md` "No Draft / Published lifecycle"); closest is creating with `available=false`, which docs say is not a draft.

### Alternatives
None. Contract need (optional): `POST /products/:id/duplicate` for atomicity.

### Required work
Product decision first (compose client-side vs backend endpoint; `available=false` wording instead of "brouillon"). Until then remove the menu entry. If built: omit "Unités de vente" row; copy list must reflect what actually succeeded.

### Proposed status
`partial_contract_limited`

---

## delete_product_logic_fixed

### Design
- Files readable. PNG thumbnail contains an embedded screenshot of another screen (artifact).
- Header fixed `h-14`: `arrow_back` + **"Supprimer le produit"** (`title-lg` bold, left).
- Product card: 80px image, store name (`label-md`, example "Dar El Benna"), name `title-md`, price `label-lg text-primary bold`.
- Info box `bg-surface-container border-l-4 border-primary` `info`: **"Attention : Ce produit est lié à l'historique de vos ventes."** / **"La suppression définitive peut affecter vos rapports financiers passés."**
- Radio cards `rounded-xl p-16`:
  - selected `inventory_2` **"Archiver le produit"** + badge **"Recommandé"** (`bg-tertiary-container text-on-tertiary-container rounded-full text-[10px]`) — "Le produit sera masqué pour les clients, mais les données de vente seront conservées dans vos rapports." (checked: `border-primary bg-primary-fixed ring-1`).
  - disabled `delete_forever` (error) **"Supprimer définitivement"** — "Action irréversible. Toutes les données associées seront perdues. Impossible tant que des commandes contenant ce produit sont en cours."
- Footer stacked rounded-full: **"Archiver le produit"** (primary) / **"Annuler"** (outlined).

### Flutter mapping
`ProductEditorScreen._delete` → `AlertDialog` title "Supprimer", body "Supprimer ce produit ? Les commandes historiques sont conservées.", actions Annuler / Supprimer; on any error shows `catalogSaveError`.

### Differences
Dialog vs full screen; no archive option; 409 not explained.

### Contract
- Hard delete: **SUPPORTED** `DELETE /products/:id`; 409 `CATALOG_PRODUCT_IN_USE` if **any** `OrderItem` references it (not only "en cours" as the ref copy says) — `catalog.controller.ts` L284–305, `CATALOG_FOUNDATION.md` "Deletion".
- "Archiver": **NOT SUPPORTED** as a state. Only `PATCH {available:false}`, which the contract defines as operational non-availability, explicitly "not archive"; the product stays listed/editable for the merchant.
- Pre-knowing "lié à l'historique": **NOT SUPPORTED** — no `inUse`/order-count flag; known only from the 409 after attempting delete.
- Store name line: available from branch/merchant context, not from product DTO.

### Alternatives
Menu "Archiver / Supprimer" entry. Unresolved: wording "Archiver" vs "Masquer / Rendre indisponible".

### Required work
Delete screen offering "Rendre indisponible" (`available=false`) and "Supprimer définitivement" (DELETE); do not pre-disable delete without data — attempt and map 409 to explicit guidance; correct the "commandes en cours" wording to match server rule.

### Proposed status
`partial_contract_limited`

---

## product_availability_french

### Design
- Files readable.
- Header `h-16 border-b`: `arrow_back`, **"Disponibilité du produit"** (primary bold), `history` icon.
- Strip `bg-surface-container-low`: filled `cloud_sync` **"Synchronisé avec le catalogue"**.
- Product card `bg-surface-container rounded-lg p-16 ring-1`: 64px image, name, category, price.
- Note `bg-surface-container-high border-l-4 border-secondary-container`: **"Note : Les modifications n'affectent pas les commandes #SG-260803-1845 déjà acceptées."**
- **"État de disponibilité"** radio cards: **"Disponible"** (selected, `border-2 border-primary`, `check_circle`) "Visible et commandable immédiatement."; **"Rupture de stock"** "Affiché comme indisponible jusqu'à réactivation manuelle."; **"Temporairement indisponible"** "Caché du menu pour une durée déterminée." + date/time row; **"Planifié"** "Disponible à partir de demain 10:00" + disabled date/time row.
- Footer: rounded-full primary `save` **"Enregistrer la disponibilité"** (hidden secondary "Programmer la réactivation").

### Flutter mapping
No screen. Availability is the inline `Switch` on each row (`CatalogController.toggleAvailability`, optimistic with rollback) and a `SwitchListTile` in the edit form.

### Differences
Screen absent.

### Contract
- Disponible / Rupture de stock: **SUPPORTED** (`available` true/false). Note ref distinguishes "Rupture" (shown unavailable) — contract has a single boolean; customer discovery hides unavailable products per predicate (`isProductCustomerOfferable`).
- Temporairement indisponible (until time), Planifié: **NOT SUPPORTED** (no time fields on `Product`).
- History (`history` icon): **NOT SUPPORTED** (no availability audit endpoint).
- "Synchronisé" badge: invented realtime indicator — omit.
- Order note: statement is true (order snapshots) but must not cite an example order number.

### Alternatives
Inline toggle (list), edit-form toggle, `bulk_availability_french`.

### Required work
Optional screen with two real states only (or keep inline toggle and skip); static note without order ref; no history icon, no sync badge.

### Proposed status
`partial_contract_limited`

---

## bulk_availability_french

### Design
- Files readable.
- Header `h-14`: `close` (primary), centered **"Disponibilité groupée"** (primary bold).
- Info `bg-primary-fixed/30 border-primary-fixed-dim`: **"Les modifications s'appliqueront immédiatement sur l'application client. Elles n'affecteront pas les commandes en cours comme #SG-260803-1842."**
- Sticky selection card (`rounded-xl p-16`, `top-[72px]`): **"Sélection multiple"** + pill **"0 produit sélectionné"** (`bg-primary text-on-primary`); **"Nouveau statut"** select (Disponible / Rupture de stock / Indisponible temporairement); hidden **"Jusqu'à quand ?"** presets "1 Heure" / "18:00" / "Demain".
- Grouped by category: heading `title-md` + **"Tout sélectionner"** checkbox; rows `rounded-lg p-3 border`: 24px checkbox, 48px thumb, name, optional price, status dot + **"Disponible"** (tertiary dot) / **"Rupture de stock"** (error dot + error text).
- Footer: square `deselect` button + disabled `update` **"Appliquer"** (primary, 50% opacity until selection).

### Flutter mapping
None. Would live at `/app/catalog/availability/bulk` from catalog (entry point not designed in the list ref).

### Differences
Screen absent.

### Contract
- Disponible / Rupture: **PARTIAL** — no bulk endpoint; loop `PATCH /products/:id {available}` per selected product; non-atomic.
- Indisponible temporairement + "Jusqu'à quand ?": **NOT SUPPORTED**.
- Grouping by category: client-side from categories + products (needs all pages).

### Alternatives
`product_availability_french` (single), inline toggles. Contract need (optional): `PATCH /products/availability` with ids.

### Required work
Multi-select screen with two statuses; progress + per-item failure list after apply, reload from server (no fake success); static info copy without order ref; omit temporary option/presets.

### Proposed status
`partial_contract_limited`

---

## required_variants_french

### Design
- Files readable. **PNG/HTML conflict:** HTML footer stacks vertically on mobile (`flex-col`, save first); PNG shows side-by-side.
- Header `h-14 border-b`: `arrow_back`, centered **"Variantes obligatoires"** (primary bold), `help` icon.
- Intro: product name (`label-md uppercase`), **"Configurez les options requises avant l'ajout au panier."**
- Info box `bg-surface-container-low`: **"Les variantes obligatoires demandent au client de choisir une option avant d'ajouter le produit au panier."**
- Group card `rounded-xl shadow-sm border overflow-hidden`: header `drag_indicator` + **"Portion / الحصة"** + **"Sélection unique"**, badge **"OBLIGATOIRE"** (`bg-tertiary-fixed text-on-tertiary-fixed uppercase text-[10px]`); option rows `border rounded-lg` `drag_handle` + "Individuel / فردي" + price chip **"+0 DZD"** (`bg-surface-container`) + `close`; **"Ajouter un choix"** (`add`, primary).
- New group card: italic **"Nouveau groupe"** + `delete`; **"Nom du groupe (Français)"** (placeholder "ex: Sauce"), **"اسم المجموعة (العربية)"**; toggle **"Choix obligatoire"** / "Le client doit choisir une option." (primary).
- Dashed button `add_circle` **"Ajouter un groupe de variantes"**.
- Footer: **"Enregistrer les variantes"** (primary) + `preview` **"Aperçu client"** (outlined).

### Flutter mapping
None. Edit/create forms show a disabled gap row "Variantes obligatoires". Would live at `/app/catalog/products/:id/variants`.

### Differences
Screen absent; entry misreported as unsupported.

### Contract
- Groups: **SUPPORTED** `GET/POST /products/:id/option-groups`, `PATCH/DELETE …/:groupId` with `required`, `minSelections`, `maxSelections` (required ⇒ min ≥ 1; `requireOptionGroupRules` in `catalog.policy.ts`). "Sélection unique" = min 1 / max 1.
- Options: **SUPPORTED** `POST/PATCH/DELETE …/options` with `additionalPriceMinor ≥ 0`, `available`.
- Drag reorder (groups/options): **NOT SUPPORTED** — no position column; ordering by `createdAt` (`catalog.repository.ts` L322, L409).
- Arabic names: **NOT SUPPORTED**.
- "Enregistrer les variantes" batch save: **PARTIAL** — only per-row calls; no batch endpoint.
- "Aperçu client": client-side render only.
- Flutter client: **missing** — no option-group methods in `merchant_api.dart`; `CatalogProduct` drops `optionGroups`.

### Alternatives
`optional_extras_french` is the same API with `required=false`. The toggle "Choix obligatoire" in this ref means both screens could share one editor — unresolved whether they stay separate entry points.

### Required work
Add client models + API for option groups/options; build screen with real CRUD (immediate per-row save or tracked batch with per-call error handling); omit drag handles and Arabic fields; enforce min/max rules in UI matching server errors (`CATALOG_OPTION_GROUP_INVALID`).

### Proposed status
`needs_work`

---

## optional_extras_french

### Design
- Files readable.
- Header `h-16`: `arrow_back` + **"Suppléments optionnels"** (primary bold, left).
- Group card `rounded-lg border p-16`: **"Suppléments Viande"** + **"Maximum 3 sélections"**, `edit` (aria "Modifier le groupe"); option rows: `drag_indicator`, name `body-lg`, primary toggle (option available); **"Prix (+)"** input `h-10` right-aligned + `DZD`; error `delete`.
- **"Ajouter une option"** (dashed primary border button).
- **"Nouveau groupe de suppléments"** (`bg-surface-container-low border-primary-container`, `add_circle`).
- Footer: **"Aperçu client"** (flex-1 outlined) | **"Enregistrer les suppléments"** (flex-2 primary).

### Flutter mapping
None. Gap row "Suppléments optionnels". Would live at `/app/catalog/products/:id/extras`.

### Differences
Screen absent.

### Contract
- Groups `required=false`, `minSelections=0`, `maxSelections` ("Maximum 3 sélections"): **SUPPORTED**.
- Option toggle = `ProductOption.available`: **SUPPORTED**.
- Prix (+) = `additionalPriceMinor` (non-negative integer minor units): **SUPPORTED**.
- Drag reorder: **NOT SUPPORTED**.
- Batch save: **PARTIAL** (per-call only).

### Alternatives
`required_variants_french`.

### Required work
Same client work as variants; screen with group edit (name, max), option CRUD, availability toggle, price input converting major→minor via `MoneyFormat` (no float money); omit drag handles.

### Proposed status
`needs_work`

---

## selling_units_french

### Design
- Files readable. **PNG/HTML conflict:** PNG renders two-column grid clipped at phone width; HTML is `grid-cols-1` on mobile.
- Header `h-16 border-b`: `arrow_back` + **"Unités de vente"** (`headline-md` primary bold).
- Info card: filled `info` **"Précision de l'unité"** / "Choisissez l'unité exacte pour éviter toute confusion lors de la préparation. Cette unité sera affichée aux clients (ex: 1 500 DZD / Plat)."
- **"APERÇU CLIENT"** card: "1 500 DZD / Plat" (`title-lg` primary bold + on-surface-variant unit).
- Radio lists (`rounded-lg p-[12px_16px] border`): **"Unités courantes"** Plat / Pièce / Portion / Boîte; **"Poids"** Kilogramme (kg) / Demi-kilogramme (500g) / Quart de kilogramme (250g); **"Conditionnement"** Pack familial / Plateau; **"Unité personnalisée"** revealing FR/AR name inputs.
- Footer: `h-[52px]` primary **"Appliquer l'unité"** + `check`.

### Flutter mapping
None; gap row "Unité de vente" in the product form.

### Differences
Screen absent.

### Contract
**NOT SUPPORTED.** No unit field on `Product` (`contract.prisma` L581–600), DTOs (`CreateCatalogProductDto`/`UpdateCatalogProductDto`), or domain model; `forbidNonWhitelisted` rejects unknown fields. Requires Domain model → ERD → Prisma change first.

### Alternatives
Referenced by list price suffix, filters, add/edit/detail forms, duplicate — all dependent on this contract.

### Required work
None in Flutter until a contract exists; keep unit UI omitted everywhere (decide whether the gap row stays).

### Proposed status
`blocked_contract`

---

## Root pair `MerchantScreens/screen.png` + `MerchantScreens/code.html` (Arabic RTL add-product)

### Design
- Files readable. `<html dir="rtl" lang="ar">`, title "SpeedyGo Merchant - إضافة منتج (Add Product)". SHA-1 of `screen.png` differs from `ajouter_un_produit_standardis/screen.png` (`3e7b81…` vs `f21c97…`). **PNG/HTML conflict:** PNG shows LTR French inputs overflowing off the left edge and empty gaps (broken render of `md:grid-cols-2`).
- Header `h-14 border-b`: mirrored `arrow_forward` + left-weighted title **"إضافة منتج جديد"** (primary, 20 px semibold); desktop-only `help`.
- Sections (cards `rounded-xl shadow-sm border-surface-variant`, headings `title-md` on-surface with primary icon):
  1. `info` **"المعلومات الأساسية"** — "اسم المنتج (عربي) \*" first, then "Nom du produit (Français) \*" + `LTR` tag; "الفئة \*" select with bilingual options; "الوصف (عربي)" + "Description (Français)" each with **0/200** counter.
  2. `payments` **"السعر والتحضير"** — "السعر الأساسي \*" (DZD suffix chip), "وقت التحضير المقدر \*" (دقيقة); "وحدة البيع (Unité de vente) \*" as a **2-column grid** of 48px tiles with check icon.
  3. `image` **"صورة المنتج"** — dashed box containing the image only (no add CTA, no delete, no "Image principale").
  4. `settings` **"الإعدادات"** — variants / supplements rows (bilingual labels).
  5. Separate card **"تفعيل المنتج"** / "تفعيل هذا الخيار يجعل المنتج مرئياً للعملاء فوراً." with larger toggle (`w-14 h-7`).
- Footer: **pill** buttons — `visibility` **"معاينة"** (outlined) | **"حفظ المنتج"** + `arrow_forward` (primary).

### Classification
**Different design, not a language variant** of `ajouter_un_produit_standardis`:
- Section order differs (Info → Price → Image → Settings → Activation card vs Info → Médias → Prix → Configuration-with-toggle).
- Field order/requiredness differ (Arabic first; asterisks on name/category/price/**prep time**/unit; 0/200 counters — backend description max is 4 000, `CATALOG_DESCRIPTION_MAX_LENGTH`).
- Different components (unit tiles grid vs chip row; pill footer; save CTA with arrow; no media add/delete controls; activation as its own card).
- Header title means "Add **new** product" and is start-aligned.

### Flutter mapping
Same `ProductEditorScreen` would render under `Locale('ar')` (`lib/app/app.dart` supports `fr`/`ar` and flips `TextDirection`), but catalog copy is hard-coded French `AppStrings`, so Arabic mode today shows French labels in RTL.

### Contract
Same as `ajouter_un_produit_standardis`; prep time, unit and Arabic fields **NOT SUPPORTED**; the 200-char counter contradicts the backend limit.

### Alternatives / conflicts
Competes with the "standardisé" French form for the same state. Unresolved: which layout governs Arabic locale (mirror the French standardized layout vs adopt this design), and whether catalog strings get Arabic localization at all.

### Required work
None until product decides; recommended treatment is to mirror the French standardized layout under RTL with Arabic copy, and treat this pair as superseded.

### Proposed status
`not_applicable_duplicate` (pending product confirmation)

---

## Unreadable / problematic reference files

- `screens/MerchantScreens/duplicate_product_french/screen.png` — solid black 669×1600 image; HTML-only design.
- PNG/HTML layout conflicts (HTML treated as intent): `d_tails_du_produit_standardis`, `selling_units_french`, root Arabic `screen.png` (desktop grids clipped at phone width); `modifier_le_produit_standardis_image_corrig_e`, `required_variants_french` (footer stacking); `liste_des_produits_standardis_e`, `liste_des_cat_gories_standardis_e` (PNG crops bottom nav).
- `delete_product_logic_fixed/screen.png` thumbnail contains an embedded screenshot (artifact).
- Token conflict: HTML tailwind configs set `rounded-lg`=8px, `rounded-xl`=12px, while `DESIGN.md` lists `rounded.lg`=1rem, `rounded.xl`=1.5rem.

## Unresolved product decisions

1. Row content on product list: keep category + description lines (current, noted in source-of-truth) or ref's title + price only.
2. "Archiver" wording/semantics: contract has only `available=false` (explicitly not archive). Approve "Rendre indisponible" or request an archive contract.
3. Duplicate: client-side composition (non-atomic) vs backend endpoint vs drop; "brouillon" has no equivalent.
4. Tap target from lists: category row → detail vs editor; product row → detail vs editor.
5. Unsupported fields (Arabic names/descriptions, prep time, selling unit, category description): keep disabled "Non disponible actuellement" rows or omit entirely (source-of-truth §4 says omit).
6. Variants and extras: one shared option-group editor or two separate screens; immediate per-row save vs batch "Enregistrer".
7. Variants/extras during create: require save-first flow (product id needed).
8. Image aspect: square crop frame vs 4:3 editor preview vs square thumbs.
9. Search/filters: full-screen filters screen vs inline chips; whether "Image manquante" is worth fetching all pages.
10. Arabic locale for catalogue: mirror French standardized layout vs root Arabic design; whether catalog strings get localized.
11. Money display: ref shows whole DZD ("1 500 DZD"), app shows "1 500,00 DZD" (cross-app formatting decision).

## Cross-cutting findings (fix once)

- **App bar:** refs use centered primary bold title for tab roots (with `menu` + `notifications`) and back-arrow + title for sub-screens; editors use left title + subtitle on edit. `MerchantScaffold` defaults `centerTitle: false`, no bell on Catalogue, refresh icon instead. Decide one tab-root app bar (bell → `/app/notifications`; omit menu unless a drawer exists).
- **Bottom nav:** ref active tab is a `bg-primary-container` pill with filled icon + `on-primary-container` label and `rounded-t-xl` bar; current shell shows colored icon/label without pill.
- **Cards:** refs use `surface-container-lowest` white, 12px radius (`rounded-xl` per HTML config), `0 2px 8px rgba(0,0,0,.04)` + `surface-variant`/`outline-variant` 1px border; `MerchantCard` uses 16px radius + Material elevation 1.
- **Status chips:** stock states are tertiary family ("En stock" `tertiary-fixed`/`tertiary-container`; "Rupture" outline or error-container). Category visibility uses **"Visible"/"Masqué"**, not "Actif"/"Inactif" (`StatusBadge` copy).
- **Toggles:** refs use a green (tertiary-fixed/tertiary-container) track with check thumb for availability/visibility, primary track for "Visible dans le menu"/options; Material `Switch` defaults differ. A shared `MerchantToggle` would cover list, editors, variants, extras.
- **Buttons / sticky footers:** refs vary ratio (1:1 category, 1:2 product create/extras, full-width single CTA elsewhere) and some use pills; `MerchantDualStickyBar` is fixed 2:3. Primary FAB should be `primary` #0a4096 not `primaryContainer`.
- **Inputs:** refs `h-12`, 8px radius, `surface-bright`/white fill, `outline-variant` border, primary focus ring; Flutter uses tinted `surfaceContainerLow` fill, 12px radius. Section headers inside forms vary (primary+icon in create; plain with bottom rule in edit).
- **Error-code mapping:** no Flutter mapping for `CATALOG_PRODUCT_IN_USE`, `CATALOG_CATEGORY_IN_USE`, `CATALOG_OPTION_GROUP_INVALID`, `CATALOG_INVALID_PRICE` — all fall back to generic save-error copy.
- **Contract docs drift:** `audit/phase-5-ui/CONTRACT_GAPS.md` lists variants/extras as unsupported, but option-group/option CRUD exists (`catalog.controller.ts` L307–480).
- **Pagination:** catalog list reads only the first 50 products; affects list, search, category counts, bulk availability and filters.
