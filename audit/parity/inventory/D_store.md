# D — Store profile journey (parity inventory, read-only)

Batch: STORE PROFILE. References under `screens/MerchantScreens/`. Design tokens common to all
12 references (Tailwind config, identical except `store_map_location_french` where
`primary=#2f59af`): `primary #0a4096`, `primary-container #2f59af`, `background/surface #f9f9ff`,
`surface-container-lowest #ffffff`, `surface-container-low #f1f3ff`, `surface-container #e9edff`,
`surface-container-high #e1e8ff`, `outline-variant #c3c6d4`, `on-surface #121b2e`,
`on-surface-variant #434652`, `tertiary #3c4b00`, `tertiary-fixed #d3ee78`,
`tertiary-fixed-dim #b7d15f`, `error #ba1a1a`, `error-container #ffdad6`. Type: Inter;
`title-lg 20/28 600`, `title-md 16/24 600`, `body-lg 16/24 400`, `body-md 14/20 400`,
`label-lg 14/20 600 +0.1`, `label-md 12/16 600 +0.5`, `headline-md 24/32 600`. Radii: `lg 8px`,
`xl 12px`. Card shadow `0 2px 8px rgba(0,0,0,.04)`; sticky footer shadow
`0 -4px 12px rgba(0,0,0,.05)`. Icons: Material Symbols Outlined (FILL 0 unless noted).

Backend base: `apps/backend/src/modules/merchants/presentation/http/merchant.controller.ts`
(`@Controller('merchant')` → `/api/v1/merchant/...`). Role policy:
`apps/backend/src/modules/merchants/domain/merchant.policy.ts` — `MERCHANT_PROFILE_UPDATE` =
OWNER only and only while `PENDING_REVIEW`/`REJECTED` (`statusAllowsProfileUpdate`);
`MERCHANT_BRANCH_UPDATE` = OWNER+MANAGER, allowed in `PENDING_REVIEW`/`REJECTED`/`ACTIVE`.
STAFF cannot mutate any store field.

## Summary

| reference | route/state | proposed status | one-line required work |
| --- | --- | --- | --- |
| `store_profile_french` | `/app/profile` · `StoreProfileScreen` | `needs_work` | Use bound branch cover as hero; fix "Informations générales" (routes to read-only settings); align row order/copy/icons; keep preview/owner/call omitted (contract) |
| `store_information_french` | none post-onboarding; wizard step ≈ `/access/registration` `_EstablishmentStep` | `partial_contract_limited` | Decide whether "Informations générales" editor exists; if so build branch name + phone editor (supported) and omit AR name/description/email/ETA (not supported) |
| `merchant_information_french` | wizard step ≈ `/access/registration` `_ActivityStep` | `exception_approved` | Registration is an approved exception; manager name / pro email / NIF have no contract — do not build post-onboarding |
| `store_contact_and_address_french` | `/app/profile/address` · `StoreAddressScreen` | `partial_contract_limited` | Fix false "visible par les clients" helper; restyle to outlined floating-label fields; CTA copy; keep public contact / pickup instructions omitted |
| `store_address_french` | wizard step ≈ `_EstablishmentStep`; post-onboarding = `StoreAddressScreen` | `not_applicable_duplicate` | Same state as contact/address (onboarding framing); landmark field unsupported |
| `store_map_location_french` | `LocationPickerScreen` (pushed from `StoreAddressScreen`) | `partial_contract_limited` | Pass branch label; primary title/CTA tokens; omit address search (no geocoding) and owner footer (no owner name) |
| `store_logo_and_cover_french` | `/app/profile/cover` · `StoreCoverScreen` | `partial_contract_limited` | Align cover card, outlined-error "Supprimer", sticky CTA copy; logo blocked (no contract) |
| `store_category_selection_french` | none | `blocked_contract` | No Merchant read/write for `CommerceVertical`; admin-assigned single vertical; product decision needed |
| `store_availability_control_french` | `/app/profile/availability` · `StoreAvailabilityScreen` | `needs_work` | Show today's real hours; add 1 HEURE preset; closing warning; accurate active-order count; real relative "Dernière mise à jour" |
| `temporary_closure_french` | `/app/profile/availability/temporary` · `TemporaryClosureScreen` | `needs_work` | Remove hardcoded "Aujourd'hui à 15:30"; branch name as app-bar subtitle; zero-count copy; accurate count |
| `horaires_d_ouverture_pur` | `/app/profile/hours` · `OpeningHoursScreen` | `needs_work` | Row list + day editor; multi-interval support (currently drops intervals 2–3); status card; Sunday-first; CTA copy |
| `horaires_exceptionnels_format_24h` | none | `blocked_contract` | Date-specific hours explicitly out of scope in both foundation docs; needs new domain/ERD/contract |

Unreadable / partial reference files:

- `screens/MerchantScreens/store_map_location_french/screen.png` — cropped: only the header and
  search bar render (780×274). Design below is taken from `code.html`.
- No missing files. Several PNGs contain rendering defects relative to `code.html` (listed per
  section under Design → PNG vs HTML).

---

## store_profile_french

### Design

- No top app bar. Hero: `h-48` (192px) cover photo, full width, overlaid gradient
  `from-black/60 to-transparent` (bottom→top). Background fallback `surface-container-high`.
- Identity card overlaps hero (`-mt-12`, 16px side margin): white, `rounded-xl` (12px), shadow
  `0 4px 12px rgba(0,0,0,.08)`, padding 16, column gap 12.
  - Floating circular settings button at card top-right (`-top-5 -right-2`), 40×40 white,
    `shadow-md`, icon `settings` (`on-surface-variant`, hover primary). Links to settings.
  - Row: logo tile 64×64 white, `rounded-lg`, 1px `outline-variant`, `shadow-sm`, 4px padding,
    image `object-contain`. Title `title-lg` `on-surface` ("Dar El Benna" — example) + filled
    `check_circle` 20px `#1D4ED8` (verified). Subtitle `body-md` `on-surface-variant`
    (category text "Restaurant et Cuisine Traditionnelle" — example).
  - Status chip top-right: bg `#ECFDF5`, 1px border `#10B981`, `rounded-full`, `px-3 py-1`, 8px
    dot `#10B981`, label `label-md` `#065F46` "Actif".
  - Full-width outlined button h-48: 1px `primary` border, text `primary` `title-md`,
    `rounded-lg`, icon `visibility`, label **"Aperçu client"**.
- Settings list card (24px below): white, `rounded-xl`, shadow `0 2px 8px rgba(0,0,0,.04)`,
  `divide-y outline-variant`. Each row padding 16: 40×40 circle `primary-container/10` with
  primary icon, title `title-md`, subtitle `body-md` `on-surface-variant`, trailing
  `chevron_right` `outline`. Rows in order:
  1. `storefront` **Informations générales** — "Nom, description, catégories"
  2. `image` **Médias et Logos** — "Photo de couverture, logo du restaurant"
  3. `location_on` **Adresse et Emplacement** — "Coordonnées GPS, instructions livreur"
  4. `schedule` **Horaires d'ouverture** — "Jours d'ouverture, pauses"
  5. `timer` **Paramètres de préparation** — "Temps moyen, capacité de commande"
- Owner card (24px below): white `rounded-xl` soft shadow, padding 16: 48px round avatar
  (photo; fallback `person` icon on `surface-variant`), overline `label-md` uppercase
  tracking-wider **"PROPRIÉTAIRE"**, name `title-md`; trailing primary `call` icon button.
- Bottom nav (HTML only; not visible in PNG crop): 5 items Accueil `home` / Commandes
  `receipt_long` / Catalogue `inventory_2` / Rapports `bar_chart` / Profil `person` (active:
  `secondary-container #94a6ff` pill, `on-secondary-container`, filled icon), `rounded-t-xl`,
  shadow `0 -2px 10px rgba(0,0,0,.05)`.
- PNG vs HTML: PNG cropped before bottom nav. Otherwise consistent.

### Flutter mapping

- Route `AppRoutes.profile` = `/app/profile` (shell tab 5) → `StoreProfileScreen`
  (`lib/features/shell/store_profile_screen.dart`).
- Rows: Informations générales → `context.push(AppRoutes.settings)` (`ProfileSettingsScreen`,
  read-only); Médias et logos → `/app/profile/cover`; Adresse et emplacement →
  `/app/profile/address`; **État du magasin** (extra) → `/app/profile/availability`;
  Horaires d’ouverture → `/app/profile/hours`; Paramètres de préparation → disabled
  "Indisponible". Second card (extra): Notifications, Réglages notifications, Paramètres du
  compte. Owner card shows role label + merchant name. Footer text "Aperçu client
  indisponible.".
- Current look: `audit/phase-5-ui/availability-live/avail-profile.png`.

### Differences

- Hero is a static gradient (`surfaceContainerHigh → surfaceDim → primaryContainer`), height
  168, even when a branch cover is bound; the cover is instead shown in the 64px logo slot via
  `MerchantBranchCoverThumb`. The reference puts the cover in the hero and a logo in the tile.
- Title row: merchant name + `Icons.verified` (primary, 18) vs `check_circle` filled `#1D4ED8`
  20. Subtitle is branch name (duplicates title when equal, as in capture "Dar El Bahja / Dar El
  Bahja") vs category.
- Status pill placed under the subtitle instead of top-right; tone uses `StatusTone.success`
  (lime wash) instead of `#ECFDF5/#10B981/#065F46`. Label = branch `operationalStatus`
  ("Actif") — semantically correct (Actif ≠ Ouvert).
- "Aperçu client" button missing; replaced with centered footnote "Aperçu client indisponible."
- **"Informations générales" routes to `ProfileSettingsScreen`, a read-only account screen.**
  Subtitle was changed to "Nom et statut du commerce", but the row still implies editing that
  doesn't exist. Nothing there edits name/description/categories.
- Row copy: "Médias et logos" / "Adresse et emplacement" (lowercase) vs "Médias et Logos" /
  "Adresse et Emplacement"; media subtitle "Photo de couverture" (logo dropped, correct);
  address subtitle shows the full `addressText` (4+ lines in capture) instead of a fixed
  one-line subtitle.
- Extra rows not in reference: État du magasin (uses `storefront` icon, duplicating row 1's
  icon), Notifications, Réglages notifications, Paramètres du compte (duplicates gear
  destination).
- Owner card: initials avatar + role overline (PROPRIÉTAIRE/GÉRANT/EMPLOYÉ) + merchant
  name, not an owner person name; no call button (correct — see Contract).
- Card radius 16 (`MerchantLayout.radiusCard`) + 1px outline + elevation 1 vs 12px, no border,
  `0 2px 8px .04` shadow.

### Contract

| Feature | Status | Evidence |
| --- | --- | --- |
| Branch cover display in hero | SUPPORTED | `GET /merchant/:merchantId/branches/:branchId/cover` (`merchant.controller.ts:614`); client `fetchBranchCoverBytes` |
| Store logo | NOT SUPPORTED | No logo entity/route in `contract.prisma` or `merchants/**`; only `MERCHANT_BRANCH_COVER` purpose (`infrastructure/storage/domain/cover-media.policy.ts:3`); prior `phase-5-ui/CONTRACT_GAPS.md` §3 |
| Category subtitle | NOT SUPPORTED (Merchant side) | `MerchantBranchClassification` exists (`contract.prisma:428`) but `MerchantBranchResponseDto` has no classification field (`dto/merchant-response.dto.ts:36-93`) |
| Verified badge | SUPPORTED | `merchant.status` + `approved` in `MerchantMembershipResponseDto` |
| Aperçu client | NOT SUPPORTED for Merchant principal | Customer storefront routes require CustomerProfile (`catalog/presentation/http/customer-catalog.controller.ts:45-104`) |
| Owner person name / phone | NOT SUPPORTED | `Merchant` has only `name` (`contract.prisma:339`); membership DTO exposes `role`, no person name |
| Preparation parameters (store level) | NOT SUPPORTED | Only per-order estimate (`Order.preparationMinutes`, `OrderPreparationEstimateRevision`); product-level default explicitly out (`docs/architecture/MERCHANT_ORDER_PREPARATION_ESTIMATE_FOUNDATION.md:15-20`) |

### Alternatives

- `store_availability_control_french` is the destination of the extra "État du magasin" row.
- `merchant_settings_french` (other batch) covers the gear/settings destination.
- `docs/MERCHANT_UI_SOURCE_OF_TRUTH.md` §6 already records "cover placeholder; settings nested"
  for this screen.
- Unresolved: what "Informations générales" should open post-onboarding (see
  `store_information_french`).

### Required work

1. Hero: render bound branch cover (same Merchant-JWT bytes as `MerchantBranchCoverThumb`) at
   192px with `black/60 → transparent` gradient; keep gradient only as empty/error fallback.
2. Logo tile: since logo is unsupported, show a neutral placeholder (storefront icon on white,
   outlined) rather than the cover.
3. Move status pill top-right with the reference chip colors (via shared `MerchantStatusPill`
   success tone fix — see cross-cutting).
4. Subtitle: hide when equal to title; do not invent a category.
5. "Informations générales": either route to a real editor (if product approves — see
   `store_information_french`) or relabel/disable honestly. Do not keep a row whose subtitle
   promises editing that the destination does not offer.
6. Restore reference row order and copy; one-line address subtitle (ellipsized); give État du
   magasin a distinct icon (e.g. `toggle_on`/`storefront` only once).
7. Keep preview button, owner name and call omitted.
8. Cards: 12px radius, no border, soft shadow (shared `MerchantCard`).

### Proposed status

`needs_work`

---

## store_information_french

### Design

- Fixed top app bar h-56, `surface`, `shadow-sm`: 40px round back button `arrow_back` primary;
  title **"Informations"** `title-lg` primary; trailing SpeedyGo logo image h-32.
- Progress: "Étape 4 de 4" (`label-md` on-surface-variant) / "100% complété" (`label-lg`
  primary); bar h-8 `surface-variant`, fill `primary-container` 100%.
- H2 **"Détails de l'établissement"** `headline-md`; body "Configurez comment les clients
  verront votre commerce sur l'application."
- Card "Nom de l'établissement" (white, `rounded-xl`, 1px outline-variant, `shadow-sm`,
  padding 16; header icon `storefront` filled primary + `title-md`): fields
  "Nom en Français" (h-48 input, `rounded-lg`, 1px outline-variant, focus primary ring-1) and
  RTL "الاسم بالعربية" (label right-aligned, `text-right dir=rtl`).
- "APERÇU CLIENT" card: bg `primary-fixed-dim/20`, border `primary/10`, `rounded-xl`; overline
  `label-md` primary uppercase + "Modifier" link (`label-lg` primary). Inner white row
  `rounded-lg` border shadow-sm: 64px image `rounded-lg`, name `title-md`, filled `star` 16
  yellow-600 + "4.8", category line-clamp-1, chip "Ouvert" (`bg-green-100 text-green-800`
  rounded) + "• 15-25 min".
- Card "Description de l’établissement" (icon `category` filled): textarea 3 rows, label
  "Description courte", placeholder "Présentez brièvement votre établissement...".
- Card "Contact de l'établissement" (icon `contact_phone` filled): "Numéro de téléphone" with
  DZ flag + "+213" prefix separated by right border, `pl-24`; "E-mail (Optionnel)".
- Outlined button h-48 `rounded-xl` border-2 `primary/20` text primary `label-lg`, icon
  `visibility`: **"Aperçu de la fiche client"**.
- Sticky footer white, border-top, shadow `0 -4px 12px .05`, `pt-4 pb-8`: primary button h-56
  `rounded-xl` `title-md` **"Continuer"** + `arrow_forward`, `shadow-lg shadow-primary/20`.
- No bottom nav.
- PNG vs HTML: consistent.

### Flutter mapping

- No post-onboarding screen. Closest: registration `_EstablishmentStep`
  (`lib/features/access/presentation/registration_screens.dart:858`), title
  "Détails de l’établissement", fields branch FR name, phone, category read-only ("La catégorie
  sera attribuée après vérification."), address, pickup place, preview, "Continuer".
- Hub row "Informations générales" (`store_profile_screen.dart:165`) currently opens
  `ProfileSettingsScreen` (read-only).
- Would live at e.g. `/app/profile/info` → `lib/features/store/presentation/store_info_screen.dart`.

### Differences

- Post-onboarding: screen entirely missing.
- Wizard chrome ("Étape 4 de 4", "Continuer") does not fit a post-onboarding editor; would need
  "Enregistrer les modifications".

### Contract

| Field | Status | Evidence |
| --- | --- | --- |
| Establishment (branch) name FR | SUPPORTED | `PATCH /merchant/:m/branches/:b` `name` (`dto/merchant-write.dto.ts:131-138`); OWNER/MANAGER, ACTIVE allowed; client `updateBranch(name:)` |
| Merchant (legal/commerce) name | PARTIAL | `PATCH /merchant/:m/profile` `name` only; OWNER only; **locked after ACTIVE** (`merchant.policy.ts:393-398`; `docs/architecture/MERCHANT_FOUNDATION.md:169`) |
| Arabic name | NOT SUPPORTED | No `nameAr` on `Merchant`/`MerchantBranch` (`contract.prisma:339-410`) |
| Description | NOT SUPPORTED | No description column on Merchant/Branch |
| Contact phone | SUPPORTED | Branch `phone` (E.164 normalized, `MERCHANT_FOUNDATION.md:195`) |
| Contact email | NOT SUPPORTED | No email on Merchant/Branch (only `Account.email`, not writable via merchant module) |
| Preview rating | SUPPORTED (separate) | `ratingsSummary` in client (`merchant_api.dart:254`) |
| Preview Ouvert | SUPPORTED | `GET .../availability` `isOpenNow` |
| Preview "15-25 min" delivery/prep range | NOT SUPPORTED | No store-level ETA |

### Alternatives

- Registration `_EstablishmentStep` covers the onboarding framing (approved exception per
  `MERCHANT_UI_SOURCE_OF_TRUTH.md` §7).
- `store_contact_and_address_french` already edits the branch phone.
- Unresolved product question: should a post-onboarding "Informations générales" editor exist,
  and should it edit the branch name (editable while ACTIVE) or the merchant name (locked after
  ACTIVE)? Phone would then be editable in two places.

### Required work

- Pending decision. If approved: new editor with FR branch name (OWNER/MANAGER; read-only for
  STAFF), optional preview block using only supported data (cover, name, rating summary,
  server Ouvert/Fermé), no AR name / description / email / ETA; "Enregistrer les
  modifications" sticky CTA; no wizard progress.
- If not approved: fix the hub row (see `store_profile_french`).

### Proposed status

`partial_contract_limited`

---

## merchant_information_french

### Design

- Fixed app bar h-56 `surface` shadow-sm: `arrow_back` primary; title **"SpeedyGo Merchant"**
  `title-lg` bold primary. No trailing icon.
- Progress "Étape 2 sur 4" / "50% complété" (`label-md`), bar h-6 `surface-container`, fill
  `primary-container` 50%.
- H2 **"Informations du marchand"**; body "Ces informations sont nécessaires pour la
  validation légale de votre compte **Dar El Benna**." (name in semibold primary).
- Sections (no cards; header icon 20px primary + `title-md`):
  - `badge` **Identité légale** — "Nom complet du gérant" (placeholder "Ex: Jean Dupont").
  - `contact_mail` **Coordonnées** — "Numéro de téléphone" (+213 prefix) and "Adresse e-mail
    professionnelle".
  - `gavel` **Identifiant professionnel** — "Numéro d'Identification Fiscale (NIF)"
    (placeholder "000XXXXXXXXXXXX"), helper italic "Utilisé uniquement pour la facturation
    officielle."
- Inputs h-48 `surface-container-lowest`, 1px outline-variant, `rounded-lg`, focus ring-2
  primary/20.
- Info banner `surface-container-low`, `rounded-xl`, border `primary/10`: filled `info` primary,
  "Confidentialité & Transparence" (`label-lg` primary) + body "Vos identifiants légaux
  restent strictement confidentiels. Seuls votre nom commercial et numéro opérationnel seront
  visibles par les livreurs SpeedyGo."
- Sticky footer `surface/80` backdrop-blur, border-top: primary h-52 `rounded-xl` **"Continuer"**
  + `arrow_forward`. Decorative blurred blobs (primary/5, tertiary-fixed-dim/10).
- PNG vs HTML: consistent (PNG cut mid-banner under footer).

### Flutter mapping

- Registration `_ActivityStep` (`registration_screens.dart:330`), title "Informations du
  commerce", merchant name only, note "Les pièces d’identité professionnelle se déposent à
  l’étape Documents." No post-onboarding equivalent.

### Differences

- Registration asks only the commerce name; manager name, pro email and NIF are absent by
  design (evidence goes through Documents step).

### Contract

| Field | Status | Evidence |
| --- | --- | --- |
| Commerce name | SUPPORTED (pre-ACTIVE) | `POST /merchant/profile`, `PATCH /merchant/:m/profile` |
| Manager full name | NOT SUPPORTED | No person-name column on Merchant/MerchantMember |
| Phone | Auth phone (not editable here) | OTP account identity |
| Professional email | NOT SUPPORTED | Not in merchant write DTOs |
| NIF | NOT SUPPORTED | No tax-id column; verification uses `MerchantDocument` evidence types (`merchant.policy.ts:61-69`) |

### Alternatives

- Registration/verification refs are `exception_approved` (`MERCHANT_UI_SOURCE_OF_TRUTH.md`
  §7). Presumably also inventoried by the registration batch.

### Required work

- None in the store journey. Do not add manager name / email / NIF without a new contract.

### Proposed status

`exception_approved`

---

## store_contact_and_address_french

### Design

- Fixed app bar h-56 `surface`, 1px bottom border `outline-variant`, flat: `arrow_back` primary
  (40px round hit), title **"Contact et Adresse du magasin"** `title-lg` bold primary,
  truncate.
- Info card `surface-container-low`, `rounded-lg`, 1px outline-variant, padding 16: `info`
  primary + "La modification de l'adresse peut affecter vos zones de livraison et les
  opérations en cours."
- Section card "Coordonnées" (white, `rounded-xl`, 1px outline-variant, soft shadow; header
  icon `call` in `secondary #4658ac`): **outlined floating-label inputs** (`.form-input` 1px
  outline, 4px radius, label 12px/600 notched at top-left on `surface`, focus 2px primary):
  "Numéro de téléphone" (value +213 …), "Contact public (Optionnel)" (placeholder "Ex: +213 555
  00 00 00"), helper `label-md` "Numéro visible par les clients." under the **public**
  contact.
- Section card "Adresse" (icon `location_on` secondary): Wilaya select, Commune select (1 col on
  mobile, 2 on md), "Adresse détaillée" textarea h-96, "Instructions de retrait" textarea h-96.
- Map card: h-160 static map `rounded-lg`, primary/5 overlay, filled `location_on` 40px; full
  outlined button h-48 1px primary, 4px radius, `map` icon, **"Modifier sur la carte"**.
- Sticky footer `surface` border-top shadow: primary button h-48, 4px radius, `label-lg` bold
  **"Enregistrer les modifications"**.
- PNG vs HTML: PNG shows Wilaya/Commune side-by-side overflowing the card (Commune clipped),
  a large blank gap under them, and the literal text "location_on" over the map (icon font not
  loaded). HTML is authoritative for layout (single column on mobile).

### Flutter mapping

- `/app/profile/address` → `StoreAddressScreen`
  (`lib/features/store/presentation/store_address_screen.dart`). Map confirmation pushes
  `LocationPickerScreen`. Captures: `audit/phase-5-ui/mocked/editors/address_*.png`,
  `audit/phase-5-ui/comparisons/address_ref_vs_mocked_se.png`.

### Differences

- Title matches; `centerTitle: true` vs left-aligned; title color `onSurface` vs primary.
- Info banner: `primaryContainer/10` wash, `bodySmall` primary text vs `surface-container-low`
  + border + `body-md` on-surface-variant.
- Sections use `MerchantEditorSection` + `MerchantLabeledField` (label above, 12px radius
  filled input) instead of notched floating-label outlined inputs; section icons
  `phone_outlined`/`place_outlined` vs `call`/`location_on` in `secondary`.
- **Helper "Numéro visible par les clients." is attached to the main branch phone**, but the
  Customer storefront explicitly omits phone
  (`customer-catalog.controller.ts:104`: "Omits phone, …"). The statement is false. In the
  reference the helper belongs to the (unsupported) public contact.
- Public contact and pickup instructions are rendered as `MerchantContractGapRow`s
  ("Non disponible"); acceptable omission pattern but the reference puts them inside the
  flow.
- Wilaya/Commune: searchable pickers (`AdminLocationSelectField`) — functionally superior; keep.
- Map card: live `FlutterMap` preview + title "Emplacement confirmé"; button label "Modifier sur
  la carte" matches; icon `map_outlined` ok.
- Sticky CTA "Enregistrer" vs "Enregistrer les modifications"; 12px vs 4px radius; button bg
  `primaryContainer #2f59af` vs `primary #0a4096`.
- Save only visible to OWNER/MANAGER (correct).

### Contract

| Field | Status | Evidence |
| --- | --- | --- |
| Phone update | SUPPORTED | `PATCH /merchant/:m/branches/:b` `phone` (`merchant-write.dto.ts:140-146`) |
| Address text | SUPPORTED | same, `addressText` ≤500 |
| Coordinates | SUPPORTED | same, `latitude`/`longitude` |
| Wilaya/commune | SUPPORTED | same, pair rule (`contract.prisma:402-405`); `GET` geo lists |
| Public contact | NOT SUPPORTED | No column |
| Pickup instructions | NOT SUPPORTED | No column |

### Alternatives

- `store_address_french` (onboarding framing of the same state).
- `docs/MERCHANT_FOUNDATION.md:194-198` field table.

### Required work

1. Remove or correct "Numéro visible par les clients." under the branch phone (not true under
   current contract).
2. Adopt reference input style (outlined, notched label, 4px radius) if the shared input
   component is updated app-wide; otherwise at minimum align section icons/colors.
3. CTA "Enregistrer les modifications", primary `#0a4096`.
4. Title left-aligned primary (shared app bar).
5. Keep gap rows compact; do not add fake inputs.

### Proposed status

`partial_contract_limited`

---

## store_address_french

### Design

- App bar h-56 `surface` shadow-sm: `arrow_back` on-surface; title **"Adresse"** bold primary;
  trailing wordmark "SpeedyGo" `headline-md` extrabold primary.
- H2 **"Détails de l'établissement"** `headline-md` **primary**; body "Veuillez renseigner
  l'emplacement précis de votre point de vente pour faciliter le retrait des commandes."
- 2-col Wilaya / Commune selects h-52, `rounded-lg`, `expand_more` trailing. "Adresse exacte"
  h-52 input with trailing primary `location_on` (placeholder "Numéro et nom de rue").
  "Point de repère ou instructions" textarea (placeholder "Ex: Près de la grande poste, entrée
  côté retrait").
- Map summary card `rounded-xl` soft shadow: h-160 map, filled `location_on` 36px primary,
  top-right badge `tertiary-fixed` bg `on-tertiary-fixed` text, border `tertiary`, `check_circle`
  **"Position confirmée"**; footer: name `title-md` + "Sidi Bel Abbès, Algérie" + link
  `edit_location_alt` **"Modifier"**.
- Sticky footer: primary h-56 `rounded-xl` **"Continuer"** + `arrow_forward`.
- PNG vs HTML: consistent.

### Flutter mapping

- Onboarding: registration `_EstablishmentStep` (same H2, confirmed-location card with
  "Position confirmée" / "Modifier", "Continuer").
- Post-onboarding: `StoreAddressScreen` (see previous section).

### Differences

- Wizard framing (Continuer, wordmark) duplicates registration; post-onboarding covered by
  `store_contact_and_address_french`.
- "Position confirmée" badge + name/commune footer are not in `StoreAddressScreen`'s map card
  (it uses title "Emplacement confirmé").

### Contract

- Wilaya/commune/address/coords SUPPORTED (as above). "Point de repère ou instructions" NOT
  SUPPORTED (no column). Commune display name SUPPORTED (`communeNameFr`,
  `merchant-response.dto.ts:81`).

### Alternatives

- `store_contact_and_address_french` (post-onboarding), registration establishment step.
  Optionally borrow the "Position confirmée" badge + name/commune footer for
  `StoreAddressScreen`'s map card.

### Required work

- None standalone. Optional: reuse the confirmed badge/footer pattern in `StoreAddressScreen`.

### Proposed status

`not_applicable_duplicate`

---

## store_map_location_french

### Design (from `code.html`; PNG cropped)

- Full-screen map. Header absolute, `surface/90` backdrop-blur, bottom border
  `outline-variant/30`, padding 16: 40px round `arrow_back`; title **"Position du magasin"**
  18px bold on-surface; trailing primary filled `speed` icon (logo placeholder).
- Map gradient overlay (surface 90% → 0 at 15% / 85% → 90%).
- Floating search bar `top-24`, h-56, `rounded-xl`, white, `shadow-xl`: `search` outline icon +
  placeholder **"Rechercher une adresse à Sidi Bel Abbès"** (city is example data).
- Center pin: primary teardrop (rotated square, `rounded-t-full rounded-br-full`), 2px surface
  border, filled `storefront` white 24; needle 4×16 primary; two pulsing rings primary/20,
  primary/10.
- Controls right, `bottom-52`: 48px `my_location` (primary) button; zoom stack `add`/`remove`,
  `rounded-xl` white `shadow-xl`.
- Address card `bottom-24`, white `rounded-xl` `shadow-2xl` padding 16: 64px storefront photo,
  name bold 16, address 14 on-surface-variant, filled `info` lime + "Entrée côté retrait"
  (12 semibold outline); trailing primary `edit_location_alt`.
- Footer `surface` border-top, `p-4 pb-8`: primary h-56 `rounded-xl` bold **"Confirmer
  l'emplacement"** + `check_circle`, `shadow-lg primary/20`; below, lime dot + uppercase
  tracking-widest 12 bold outline **"Propriétaire : Amine Bensaïd"**.

### Flutter mapping

- `LocationPickerScreen` (`lib/features/access/presentation/location_picker_screen.dart`),
  shared by registration and `StoreAddressScreen._openMap` (MaterialPageRoute, no named route).
  Captures: `audit/registration-verification/captures/live-map/*.png`.

### Differences

- Title "Position du magasin" and CTA "Confirmer l’emplacement" + `check_circle_outline`
  match. Pin shape matches (no pulse rings). GPS + zoom controls match.
- No right header icon; header uses `titleMedium` w700.
- No search bar.
- `StoreAddressScreen` does not pass `branchLabel`, so the card shows address + raw
  coordinates only; no photo, no pickup hint.
- No owner footer.
- CTA via `MerchantPrimaryButton` (check color vs `primary #0a4096`).

### Contract

| Feature | Status | Evidence |
| --- | --- | --- |
| Coordinates confirm/update | SUPPORTED | `PATCH .../branches/:b` lat/lng |
| Address search / geocoding | NOT SUPPORTED | No geocode endpoint in backend; would need a provider (new dependency/contract) |
| Pickup hint on card | NOT SUPPORTED | No column |
| Storefront photo | SUPPORTED (cover) | `GET .../cover` |
| Owner name | NOT SUPPORTED | see `store_profile_french` |

### Alternatives

- Registration map captures (`registration-verification/captures/comparisons/estab_location.png`).

### Required work

1. Pass `branchLabel: branch.name` from `StoreAddressScreen`. **Done.**
2. Optionally show the bound cover as the card thumbnail. **Done** (2026-10-03 map-card polish;
   `MerchantBranchCoverThumb` / storefront placeholder).
3. Hide raw coordinates when an address exists (keep for a11y only). **Done** (2026-10-03).
4. Omit search and owner footer (no contract). No pulse animation needed (decorative; optional).
   **Still omitted** — address search blocked on D-D7 / geocoding; pickup hint and owner name
   have no contract.

### Proposed status

`partial_contract_limited`

---

## store_logo_and_cover_french

### Design

- App bar h-56 `surface` shadow-sm: `arrow_back` on-surface-variant; centered title **"Logo et
  Couverture"** `title-lg` bold primary.
- Logo card (white, `rounded-xl`, soft shadow, padding 16): "Logo du magasin" `title-md`,
  "Le logo doit être lisible même en petit format." `body-md`; two buttons h-48 `rounded-lg`:
  filled `primary-container` **"Modifier"** (`edit`) and outlined `error` **"Supprimer"**
  (`delete`, hover `error-container`); 128px round logo preview (`outline-variant` border,
  hover `photo_camera` overlay).
- Cover card: "Photo de couverture" + "La photo de couverture doit représenter votre
  établissement."; 16:9 image `rounded-lg` border, gradient `on-surface/80 → transparent`,
  bottom-right surface button `swap_horiz` **"Remplacer"** (primary text, outline-variant border,
  `rounded-lg`).
- "Aperçu Client" card `surface-container-low`, border, `rounded-xl`: `visibility` primary
  header; "Voici comment votre établissement apparaîtra dans l'application client."; inner
  merchant card: cover h-128, rating chip top-right (filled `star` tertiary-fixed-dim + "4.8"),
  64px round logo overlapping `-24px`, chip `schedule` "20-30 min", name `title-lg` bold,
  "Sidi Bel Abbès • Restauration".
- Sticky footer: primary h-52 `rounded-xl` bold **"Enregistrer les modifications"**.
- PNG vs HTML: in the PNG the 128px logo circle is pushed off the right edge (only a sliver
  visible) and the logo card has large empty space; HTML (`flex-col` on mobile) centers the
  logo below the buttons.

### Flutter mapping

- `/app/profile/cover` → `StoreCoverScreen`
  (`lib/features/store/presentation/store_cover_screen.dart`). Captures:
  `audit/phase-5-ui/mocked/editors/cover_*.png`, `audit/phase-5-ui/media-live/*.png`,
  `audit/phase-5-ui/comparisons/cover_ref_vs_mocked_se.png`.

### Differences

- Title/centered matches (color onSurface vs primary).
- Logo card: `MerchantContractGapRow` "Modifier / Supprimer — Non disponible actuellement" in
  place of buttons + preview (correct omission).
- Cover: 16:9, "Remplacer"/"Choisir une couverture" pill bottom-right (20px radius vs 8px),
  no dark gradient overlay; "Supprimer" is a plain `TextButton` below the image rather than an
  outlined error button; deletion applies immediately (no save step) — acceptable.
- Preview: 16:9 cover + initial-letter avatar + name below; hint "Notes et délai estimé non
  disponibles actuellement." No rating chip, no commune line.
- Sticky CTA "Enregistrer" only when bytes are loaded/picked (it shows even when the image is
  just the remote cover, i.e. nothing changed) vs always-visible "Enregistrer les
  modifications".

### Contract

| Feature | Status | Evidence |
| --- | --- | --- |
| Cover upload | SUPPORTED | `POST /merchant/:m/branches/:b/cover/content` (`merchant.controller.ts:567`) |
| Cover bind | SUPPORTED | `PUT .../cover` `{uploadReference}` (`:637`; `BindMerchantBranchCoverDto`) |
| Cover delete / read | SUPPORTED | `DELETE .../cover` (`:657`), `GET .../cover` (`:614`) |
| Logo upload/bind/delete | NOT SUPPORTED | No entity/route; `CONTRACT_GAPS.md` §3–4; `MEDIA.md` |
| Preview rating | SUPPORTED | `ratingsSummary` (`merchant_api.dart:254`) |
| Preview "20-30 min" | NOT SUPPORTED | No store ETA |
| Preview commune | SUPPORTED | `communeNameFr` |
| Preview vertical ("Restauration") | NOT SUPPORTED (Merchant side) | classification not in Merchant DTO |

Role: OWNER/MANAGER (`MERCHANT_BRANCH_UPDATE`); Flutter `_canManage` hides actions for STAFF.

### Alternatives

- `store_profile_french` hero also consumes the cover.

### Required work

1. Cover card: add `on-surface/80` bottom gradient; "Remplacer" button 8px radius with
   `outline-variant` border.
2. "Supprimer" as outlined error button (with confirm dialog, since it is immediate).
3. Sticky CTA "Enregistrer les modifications", shown only when a new local pick exists
   (`_remoteIsLocalPick`), not when the remote cover is merely displayed.
4. Preview: add rating chip from `ratingsSummary` only if already loaded elsewhere; add
   commune line; keep ETA and vertical omitted.
5. Logo: keep gap row; no fake buttons.

### Proposed status

`partial_contract_limited`

---

## store_category_selection_french

### Design

- App bar h-56 `surface`: 40px `arrow_back` on-surface-variant; title = store name (example)
  `title-lg` primary truncate; trailing wordmark "SpeedyGo" bold `headline-md` primary.
- H2 **"Catégorie de l'établissement"** `headline-md`; body "Sélectionnez les catégories qui
  décrivent le mieux votre activité."
- Search input h-48 `surface-container-low`, 1px outline-variant, `rounded-lg`, leading `search`,
  placeholder **"Rechercher une catégorie..."**.
- Selected-chips row (min-h 40): chip `primary-container` bg, `on-primary-container` text,
  `rounded-full`, `label-lg`, trailing `close`.
- Info card `surface-container-high/30`, border `surface-variant`, `rounded-xl`: `info` primary +
  "Votre choix définit les champs de votre inventaire et la visibilité dans l'application
  client."
- 2-col grid gap 16 of cards (white, `rounded-xl`, `shadow-sm`, padding 16, centered): 48px
  circle (`surface-container-highest`; selected `primary-container`) with icon; label
  `label-lg`. Selected: 2px primary border + top-right `check_circle` primary. Items: Restaurant
  `restaurant`, Boulangerie `bakery_dining`, Épicerie `local_grocery_store`, Supermarché
  `shopping_basket`, Boucherie `kebab_dining`, Pharmacie `medical_services`, Cosmétiques
  `content_cut`, Électronique `devices` (example list). Multi-select.
- Sticky footer white border-top: primary h-52 `rounded-lg` **"Enregistrer et continuer"** +
  `arrow_forward`.
- PNG vs HTML: PNG's selected-chip row is empty (blank gap) and the Restaurant icon circle is
  faded; HTML shows a "Restaurant" chip and a `primary-container` circle.

### Flutter mapping

- None. Registration shows category read-only: "La catégorie sera attribuée après
  vérification." (`app_strings.dart:694`). Would live at `/app/profile/category` or inside the
  "Informations générales" editor.

### Differences

- Screen missing.

### Contract

| Feature | Status | Evidence |
| --- | --- | --- |
| List categories (Merchant) | NOT SUPPORTED | `CommerceVertical` listed only for Customer (`GET /commerce-verticals`, `customer-catalog.controller.ts:45`) and Admin (`admin/commerce-verticals`) |
| Read own classification | NOT SUPPORTED | Only `GET admin/merchant-branches/:branchId/classification` (`admin-merchant-branch-storefront.controller.ts`) |
| Assign classification | NOT SUPPORTED for Merchant | Admin-only `PUT/DELETE admin/merchant-branches/:branchId/classification`; audit actions `COMMERCE_VERTICAL_ASSIGN_BRANCH` (`admin/domain/admin-audit-actions.ts:46`) |
| Multi-select | NOT SUPPORTED | `MerchantBranchClassification.branchId @unique` → one vertical per branch (`contract.prisma:428-440`) |
| "définit les champs de votre inventaire" | NOT SUPPORTED | Vertical does not drive catalog fields; "Separate from per-branch menu Category" (`customer-catalog.controller.ts:49`) |

### Alternatives

- `docs/architecture/CUSTOMER_CATALOG_DISCOVERY_FOUNDATION.md` (platform verticals, admin
  classification). Registration's read-only category copy is an existing implementation
  decision.
- Unresolved conflict: reference = merchant self-selects multiple categories; contract =
  admin assigns exactly one. Product must decide.

### Required work

- Blocked. If product wants Merchant visibility only: a read-only Merchant endpoint exposing the
  branch's vertical (name + iconKey) would allow a subtitle on the hub. Self-selection /
  multi-select requires domain → ERD → contract changes.

### Proposed status

`blocked_contract`

---

## store_availability_control_french

### Design

- Sticky app bar h-56 `surface` shadow-sm: `arrow_back` primary; title **"État du magasin"**
  bold primary; trailing "FR" `label-md` + `language` icon (on-surface-variant).
- Identity row: overline **"ÉTABLISSEMENT"** `label-md` outline uppercase tracking-wider; name
  `headline-md`; `account_circle` 18 primary + "Propriétaire: Amine Bensaïd"; right 64px
  `rounded-xl` `primary-container` tile with `storefront` 32 `on-primary-container`.
- Segmented control: track `#E2E8F0` pill, padding 4; buttons `label-lg` bold, py-12;
  **"OUVERT"** active bg `tertiary-fixed #d3ee78` text `#171e00`; **"FERMÉ"** active bg `error`
  text white; animated thumb.
- Banner (open): `tertiary-fixed/30`, border `tertiary-fixed-dim`, `rounded-xl`: `check_circle`
  tertiary, **"Magasin en ligne"** `title-md` tertiary, "Les clients peuvent passer commande et
  voir votre menu normalement." Closed variant: `error-container/30`, `do_not_disturb_on` error,
  **"Magasin hors ligne"**, "Votre magasin n'apparaîtra plus sur l'application SpeedyGo pour
  le moment."
- Active orders card white `rounded-xl` soft shadow border `outline-variant/30`: 48px
  `secondary-fixed` circle `list_alt`; **"6 commandes en cours"** `title-md` (example count);
  "ID Session: #SG-260803-1842" (example); trailing round `surface-container-high`
  `chevron_right` primary.
- Grid (1 col mobile / 2 col md): "Aujourd'hui" card `surface-container`, `schedule`, time range
  `headline-md` primary "08:00 - 22:00", link "Modifier" + `edit`; "Pause rapide" card
  `surface-container-highest`, `pause_circle`, "Fermer temporairement pour un rush en cuisine.",
  two buttons **"30 MIN"** / **"1 HEURE"** (white, 1px outline-variant, `rounded-lg`).
- Closing warning (visible when FERMÉ): `error-container/20`, 4px left border error,
  `rounded-r-xl`: `warning` + **"ATTENTION : FERMETURE IMMÉDIATE"** + "Toutes les nouvelles
  commandes seront rejetées. Vous devez toujours traiter les 6 commandes actives."
- Bottom bar white shadow: primary h-56 `rounded-xl` bold `save` **"Enregistrer les
  modifications"**; caption "Dernière mise à jour: Il y a 5 min". No bottom nav (HTML comment).
- PNG vs HTML: PNG renders the grid as 2 columns with the Pause card overflowing off-screen
  (1 HEURE hidden); HTML is 1 column on mobile.

### Flutter mapping

- `/app/profile/availability` → `StoreAvailabilityScreen`
  (`lib/features/store/presentation/store_availability_screen.dart`). Capture:
  `audit/phase-5-ui/availability-live/avail-etat-magasin.png`.

### Differences

- Segment labels "Selon les horaires" / "Fermé" vs "OUVERT" / "FERMÉ"; server-driven
  Ouvert/Fermé pill added under the name. Documented decision
  (`STORE_AVAILABILITY_LIVE_REPORT.md` notes: segment never labeled "Ouvert"). Keep.
- Segment track `surfaceContainer #e9edff` vs `#E2E8F0`; labels mixed-case vs uppercase.
- Owner line missing (no contract — correct). Header FR/language missing (no destination
  here — correct to omit).
- Active-orders card: `receipt_long` icon without circle, no session ID (correct), `IconButton`
  chevron without round bg. **Count is wrong at scale:** `homeActiveOrdersProvider`
  (`orders_controller.dart:305-346`) merges three pages with `limit: 5` each (max 15) and ignores
  `page.total`; it also omits ACCEPTED orders. The screen presents this as the number of orders
  in progress.
- "Aujourd'hui" card shows the generic string "Horaires configurés" (both ternary branches
  identical, `store_availability_screen.dart:235-239`) instead of today's time range.
- Pause rapide: only "30 MIN"; "1 HEURE" missing (the closure screen supports 60 min).
- Closing warning block missing (banner switches to closed copy only). Closed banner body
  differs: "Les clients ne peuvent plus passer de nouvelles commandes." (arguably more accurate
  than "n'apparaîtra plus" since storefront still lists the branch as closed).
- Caption "Dernière mise à jour confirmée" (static) vs relative time; `updatedAt` is available.
- Save button bg `primaryContainer` vs `primary`; card radius 16 vs 12.

### Contract

| Feature | Status | Evidence |
| --- | --- | --- |
| Availability pause / force close / follow schedule | SUPPORTED | `GET/PUT /merchant/:m/branches/:b/availability` (`merchant.controller.ts:466,494`); `PutBranchAvailabilityDto` modes `FOLLOW_SCHEDULE/FORCE_CLOSED/TEMPORARY_CLOSED` (`branch-availability.constants.ts`) |
| Effective open state | SUPPORTED | `isOpenNow`, `outsideWeeklyHours`, `currentClosesAt`, `nextOpenAt` (`dto/branch-availability.dto.ts`) |
| Today's hours | SUPPORTED | `GET .../opening-hours` days/intervals (`dto/opening-hours.dto.ts`) |
| Active order count | SUPPORTED | `listOrders` (`merchant_api.dart:93`) returns `MerchantOrderListPage.total` (`lib/features/orders/data/order_models.dart:403-428`) |
| Last update | SUPPORTED | `updatedAt` |
| Owner name, session ID | NOT SUPPORTED / invented | — |

Role: `MERCHANT_BRANCH_UPDATE` (OWNER/MANAGER) (`branch-availability.service.ts:73`). Flutter
shows Save to all roles and relies on server 403 for STAFF — verify STAFF gating in UI.

### Alternatives

- `temporary_closure_french` (pause destination). `docs/architecture/MERCHANT_STORE_AVAILABILITY_FOUNDATION.md`
  (Actif ≠ Ouvert; segment semantics).

### Required work

1. "Aujourd'hui": render today's intervals (Africa/Algiers weekday) from opening hours, e.g.
   "11:00–14:30 · 18:00–23:30"; "Fermé aujourd'hui" when empty; keep "non configurés" copy.
2. Add "1 HEURE" button → `temporaryClosure` with `presetMinutes: 60`.
3. Show the closing warning block when the draft segment is Fermé (count from accurate source).
4. Active count: dedicated count using `page.total` per status (incl. ACCEPTED) — not the
   5-per-bucket home preview.
5. Relative "Dernière mise à jour : il y a N min" from `updatedAt` (or keep static if product
   prefers; do not invent).
6. Hide/disable Save and segment for STAFF (`membership.role`).
7. Visual: uppercase segment labels, `#E2E8F0`-like track, round chevron bg, `list_alt` in
   `secondary-fixed` circle, primary CTA.

### Proposed status

`needs_work`

---

## temporary_closure_french

### Design

- Fixed app bar h-56 `surface`, border-bottom, shadow-sm: `arrow_back` primary; title
  **"Fermeture temporaire"** `title-lg` primary with subtitle store name `label-md`
  on-surface-variant; trailing `help_outline`.
- Error card `error-container`, `rounded-xl`, border `error/10`: filled `warning` error,
  **"Action requise"** `title-md`, "La fermeture suspendra l'acceptation de nouvelles
  commandes. Les **6 commandes en cours** seront maintenues et doivent être préparées."
- "Motif de la fermeture" `title-md`; reason pills (1 col mobile / 2 col md, gap 12): white,
  1px outline-variant, `rounded-xl`, padding 16, icon + `body-md`: `restaurant` "Forte charge
  (cuisine)", `engineering` "Problème technique", `inventory_2` "Rupture de stock", `timer`
  "Pause déjeuner". Selected icon primary.
- "Réouverture prévue": select white 1px outline-variant `rounded-xl` py-14, leading `schedule`,
  trailing `expand_more`; options (example) "Aujourd'hui à 15:30", "Aujourd'hui à 16:00",
  "Aujourd'hui à 17:00", "Demain à l'ouverture", "Indéfinie (Manuel)".
- "Message client" + "FACULTATIF" (`label-md`); textarea 3 rows `rounded-xl`, placeholder "Ex:
  Nous sommes complets pour le moment, revenez dans 30 minutes !"
- Image banner h-160 `rounded-xl` (kitchen stock photo) with gradient black/60 and white
  `label-lg` "Impact sur votre visibilité : Les clients verront votre établissement comme «
  Fermé temporairement »."
- Footer white border-top shadow: `info` 18 + "Vous pourrez rouvrir manuellement à tout
  moment."; primary h-52 `rounded-xl` bold **"Confirmer la fermeture"** + `lock_clock`.
- PNG vs HTML: PNG shows reasons in 2 columns overflowing right (labels clipped) plus a large
  blank gap; HTML is 1 column on mobile.

### Flutter mapping

- `/app/profile/availability/temporary` (extra `presetMinutes`) → `TemporaryClosureScreen`
  (`lib/features/store/presentation/temporary_closure_screen.dart`). Capture:
  `audit/phase-5-ui/availability-live/avail-fermeture-temp.png`.

### Differences

- Structure, copy and reason icons match; single-column reasons match HTML.
- Store name rendered as body text above the card instead of app-bar subtitle
  (`MerchantScaffold` supports `subtitle`). No `help_outline` (no help destination — correct).
- Presets: "Dans 30 minutes", "Dans 1 heure", **"Aujourd’hui à 15:30"** (hardcoded 14:30 UTC in
  `_closedUntilFor`, `temporary_closure_screen.dart:65-77` — copied from the reference example
  and rolls to tomorrow silently if past), "Indéfinie (Manuel)" → `FORCE_CLOSED`. No "Demain à
  l'ouverture".
- Impact copy renders "Les 0 commandes en cours …" when count is 0 (see capture); count comes
  from the capped `homeActiveOrdersProvider` (see availability section).
- Image banner replaced by plain text hint (correct — no invented imagery).
- Dropdown uses Material default `OutlineInputBorder` (4px) vs 12px `rounded-xl`; message field
  shows a character counter (maxLength 500) not in reference.

### Contract

| Feature | Status | Evidence |
| --- | --- | --- |
| Temporary closure with reason, message, until | SUPPORTED | `PUT .../availability` `mode=TEMPORARY_CLOSED`, `closedUntil` required & future, `reasonCode` ∈ `PEAK_KITCHEN/TECHNICAL/OUT_OF_STOCK/LUNCH_BREAK/OTHER`, `customerMessage` ≤500 (`dto/branch-availability.dto.ts`, `branch-availability.policy.ts`) |
| Indefinite closure | SUPPORTED | `mode=FORCE_CLOSED` (null `closedUntil`) |
| "Demain à l'ouverture" | PARTIAL | No server "until next opening" mode; client would have to compute the next weekly open from opening hours. `nextOpenAt` is computed under the *effective* rules, so it cannot be used as-is. |
| Arbitrary reopening time | SUPPORTED | any future RFC3339 `closedUntil` |

### Alternatives

- `store_availability_control_french` "Pause rapide" entry.
  `MERCHANT_STORE_AVAILABILITY_FOUNDATION.md` (expired temporary never implies open).

### Required work

1. Remove the hardcoded "Aujourd’hui à 15:30" preset; replace with a real time picker
   ("Aujourd'hui à HH:mm", Africa/Algiers, must be future) or drop it.
2. "Demain à l'ouverture": only after a product/backend decision (it is a business rule; avoid
   client-side derivation of authoritative times).
3. Branch name as `MerchantScaffold.subtitle`.
4. Impact copy: omit the count clause when 0, use accurate count.
5. 12px radii on dropdown/text field; hide counter or make it subtle.

### Proposed status

`needs_work`

---

## horaires_d_ouverture_pur

### Design

- Sticky app bar h-56 `surface`, bottom border `outline-variant/30`: `arrow_back`
  on-surface-variant; title **"Horaires d'ouverture"** `title-lg` **on-surface** (not primary).
- Status card white `rounded-xl` shadow-sm border `outline-variant/30`: "Dar El Benna / دار
  البنة" `title-md` (example bilingual name), "Horaires habituels" `body-md`; chip
  `tertiary-fixed-dim/20` bg, border `tertiary-fixed-dim`, dot `tertiary-container`, label
  `label-md` `tertiary-container` **"Ouvert actuellement"**.
- Weekly card (one card, row dividers `outline-variant/30`), rows px-16 py-16 in order
  **Dimanche, Lundi, Mardi, Mercredi, Jeudi, Vendredi, Samedi**: day `title-md` (w-96),
  centered time summary `body-md` on-surface-variant ("11:00–23:00"; split day
  "11:00–14:30 · 18:00–23:30"), switch 40×24 (on: `primary-container #2f59af` track, white knob),
  `chevron_right` 20. Whole row is a button (opens day editor).
- "Horaires exceptionnels" row card: 40px circle `surface-container-high` with filled
  `calendar_month` `primary-container`; title `title-md`; subtitle "Jours fériés, fermetures et
  horaires spéciaux"; `chevron_right`.
- Info note (opacity 80): `info` + "Les clients peuvent commander uniquement pendant vos heures
  d’ouverture. Les modifications sont appliquées immédiatement."
- Sticky footer `surface` border-top: `primary-container` h-52 `rounded-xl` `title-md`
  **"Enregistrer les horaires"**.
- PNG vs HTML: PNG's exceptional-hours circle is empty (icon missing).

### Flutter mapping

- `/app/profile/hours` → `OpeningHoursScreen`
  (`lib/features/store/presentation/opening_hours_screen.dart`). Data model
  `OpeningDay`/`OpeningInterval` (`lib/features/store/data/store_models.dart`).

### Differences

- Layout: one `MerchantCard` per day with inline "Ouverture"/"Fermeture" `InputDecorator` fields
  vs a single list card with one-line summaries + chevron to a day editor.
- Order Lundi→Dimanche (ISO) vs Dimanche-first (Algerian week).
- **Only the first interval is displayed and edited** (`opening_hours_screen.dart:79-81`,
  `124-155`): a split day (e.g. Vendredi with two intervals) shows one range, and editing that
  day overwrites it with a single interval → silent loss of intervals 2–3 on save. Backend
  allows up to 3 per day.
- Switch colors `tertiaryFixed`/`tertiaryContainer` (lime) vs `primary-container` blue.
- No status card, no "Horaires exceptionnels" row, no info note.
- Empty state text "Aucun horaire configuré pour cet établissement." (fine).
- CTA "Enregistrer" vs "Enregistrer les horaires"; bg `primaryContainer` matches this reference
  (the only one using `primary-container` for the CTA).

### Contract

| Feature | Status | Evidence |
| --- | --- | --- |
| Weekly hours GET/PUT | SUPPORTED | `GET/PUT /merchant/:m/branches/:b/opening-hours` (`merchant.controller.ts:399,426`); `PutOpeningHoursDto` exactly 7 days, `expectedVersion` |
| Multiple intervals / day | SUPPORTED | `OPENING_HOURS_MAX_INTERVALS_PER_DAY = 3`, total 21 (`opening-hours.constants.ts`) |
| Overnight / 24h | SUPPORTED | closes<opens overnight; 00:00→00:00 = 24h (`dto/opening-hours.dto.ts:25-29`) |
| "Ouvert actuellement" | SUPPORTED | availability `isOpenNow` (effective) |
| Arabic name | NOT SUPPORTED | — |
| Exceptional hours entry | NOT SUPPORTED | see next section |

Role: `MERCHANT_BRANCH_UPDATE` (`opening-hours.service.ts:85`). Flutter shows Save/switches
to all roles — verify STAFF gating.

### Alternatives

- `store_availability_control_french` "Aujourd'hui" card links here. `MERCHANT_UI_SOURCE_OF_TRUTH.md`
  §6 lists this as `implementer_reviewed` with "exceptional hours blocked".
- Week start (Sunday vs Monday) is a product/locale question; flag, do not decide.

### Required work

1. Fix multi-interval handling first (data-integrity): display all intervals joined by " · ",
   day editor that adds/removes up to 3 intervals, preserve untouched intervals.
2. Restructure to single list card + day editor (bottom sheet or pushed screen) with 24h time
   pickers.
3. Status card: branch name + "Horaires habituels" + server Ouvert/Fermé chip from
   availability (not inferred from hours).
4. Switch colors per reference; CTA "Enregistrer les horaires".
5. Info note verbatim.
6. Exceptional-hours row: omit (or disabled "Indisponible") until contract exists; no dead
   navigation.
7. STAFF read-only.

### Proposed status

`needs_work`

---

## horaires_exceptionnels_format_24h

### Design

- Sticky app bar h-56 `surface`, border-bottom, flat: `arrow_back` on-surface-variant; centered
  title **"Horaires exceptionnels"** `title-lg` primary; trailing `help`.
- Info banner `primary-fixed #d9e2ff`, `on-primary-fixed`, `rounded-lg`, padding 12×16: filled
  `info` + "Ces horaires remplacent vos horaires habituels uniquement pour les dates
  sélectionnées."
- "Exceptions à venir" `title-md`; list cards white `rounded-lg` 1px outline-variant shadow-sm
  with 4px left accent (error for closed, `tertiary-fixed-dim` for special hours): title
  `label-lg`, chip (closed: `error-container` + `event_busy` "Fermé"; open: `tertiary-fixed` +
  `schedule` "Ouvert", 10px), date line `calendar_today` + range, optional "• 10:00 - 15:00";
  trailing `delete` (hover error).
- Divider.
- "Ajouter une exception" card `surface-container-low` `rounded-xl` border shadow-sm, header
  `add_circle` primary: "Date(s)" input with `calendar_month`; hidden conflict warning
  `warning` "Cette date chevauche une exception existante."; "Statut" segmented
  (`surface-container-highest` track; Ouvert `check_circle` primary / Fermé `cancel` error);
  "Horaires modifiés" two `type=time` inputs with "à" (hidden when Fermé); "Motif" input
  (placeholder "ex: Jour férié, Travaux..."); "Message pour les clients (Optionnel)" textarea;
  outlined button h-40 `add` **"Ajouter à la liste"**.
- Sticky footer: outlined **"Annuler"** (flex-1) + primary **"Enregistrer les horaires"**
  (flex-2), h-48, `rounded-lg`.
- PNG vs HTML: PNG time inputs are empty; HTML values 09:00 / 13:00.

### Flutter mapping

- None. Would live at `/app/profile/hours/exceptions` →
  `lib/features/store/presentation/exceptional_hours_screen.dart`, entered from the
  "Horaires exceptionnels" row of `OpeningHoursScreen`.

### Differences

- Screen missing.

### Contract

- NOT SUPPORTED. No date-specific schedule model in `apps/backend/prisma/contract.prisma`
  (only `MerchantBranchOpeningSchedule/Interval` weekly and `MerchantBranchAvailabilityOverride`);
  no route in `merchant.controller.ts`; explicitly **out of scope**:
  `docs/architecture/MERCHANT_OPENING_HOURS_FOUNDATION.md:18` ("Temporary closures / holiday
  calendars") and `docs/architecture/MERCHANT_STORE_AVAILABILITY_FOUNDATION.md:19` ("Holiday /
  exceptional hours calendars"). Evaluator/checkout/customer projections would all need to
  consume it.

### Alternatives

- A single one-off closure can be approximated today with `TEMPORARY_CLOSED` + `closedUntil`,
  but that is not a scheduled future exception (it starts immediately). Do not present it as
  exceptional hours.

### Required work

- Blocked: Domain model → ERD → Prisma contract → evaluator precedence → Merchant CRUD endpoints
  before any UI. No UI stub with fake data.

### Proposed status

`blocked_contract`

---

## Cross-cutting findings (fix once)

- **App bar** (`MerchantScaffold`, `app_theme.dart:118-120`): title uses `onSurface`; every store
  reference except `horaires_d_ouverture_pur` uses **primary `#0a4096`** `title-lg`, left-aligned,
  h-56, `shadow-sm` or 1px bottom border. Subtitle support exists but is unused
  (`TemporaryClosureScreen`).
- **Primary CTA**: `filledButtonTheme` bg = `primaryContainer #2f59af`; references use
  `primary #0a4096` (only `horaires_d_ouverture_pur` uses `primary-container`). Sticky CTAs are
  h-52/56, `rounded-xl`, `title-md` bold, `shadow-lg shadow-primary/20`, often with trailing
  icon. Copy mismatches: "Enregistrer" → "Enregistrer les modifications" / "Enregistrer les
  horaires".
- **Cards** (`MerchantCard`): 16px radius + 1px outline + elevation 1; references: 12px
  (`rounded-xl`), `0 2px 8px rgba(0,0,0,.04)`, border only on some editors.
- **Status chip** (`MerchantStatusPill`): success tone should match `#ECFDF5` / `#10B981` /
  `#065F46` (hub) and `tertiary-fixed-dim/20` variant (hours).
- **Inputs**: references use two styles — floating-label outlined (contact/address) and
  label-above h-48 `rounded-lg` (information/category/exceptions). Flutter uses label-above,
  12px radius; decide one shared editor input.
- **Segmented control**: availability and exceptions both use a pill track with filled thumb;
  make one shared widget.
- **Bottom nav**: only the hub shows it (active pill `secondary-container #94a6ff`); all
  sub-screens hide it — Flutter matches (root-navigator routes).
- **Role gating**: server enforces `MERCHANT_BRANCH_UPDATE`; cover/address hide actions for STAFF,
  but availability, temporary closure and opening hours show mutating controls to STAFF.
- **Active order count** used for store screens is a capped home preview (max 15, ignores
  `total`, excludes ACCEPTED) — misleading metric.
- **Stale evidence**: `audit/phase-5-ui/CONTRACT_GAPS.md` §7 still lists "Ouvert/Fermé toggle,
  temporary closure" as gaps although both are shipped (`STORE_AVAILABILITY_LIVE_REPORT.md`).

## Unresolved product decisions

1. Post-onboarding "Informations générales": exists? edits branch name (editable while ACTIVE)
   vs merchant name (locked after ACTIVE)? Where does phone live?
2. Store category: merchant self-select (reference, multi) vs admin-assigned single vertical
   (contract + registration copy).
3. Store logo: new media purpose/entity, or drop logo from all references.
4. Exceptional hours: schedule a foundation, or remove the entry point.
5. Temporary closure "Demain à l'ouverture": server-side mode or omit.
6. Week start for hours list: Dimanche (reference) vs Lundi (ISO/current).
7. Address search in map picker (requires geocoding provider).
