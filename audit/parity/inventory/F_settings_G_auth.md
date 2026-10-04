# Parity inventory — F (notifications / settings / support / staff) + G (auth / registration / verification)

Read-only inventory. No code, tests or docs were modified. Evidence: `screens/MerchantScreens/<folder>/{screen.png,code.html}` (all 40 files opened), Flutter sources under `apps/merchant_app/lib`, backend under `apps/backend/src/modules/**` and `apps/backend/prisma/contract.prisma`, prior audit captures under `apps/merchant_app/audit/**` (evidence only, not design truth).

Tokens used below come from each reference's Tailwind config (identical across folders): `primary #0a4096`, `primary-container #2f59af`, `primary-fixed #d9e2ff`, `surface/background #f9f9ff`, `surface-container-lowest #ffffff`, `surface-container-low #f1f3ff`, `surface-container #e9edff`, `surface-container-high #e1e8ff`, `surface-variant #d9e2fc`, `on-surface #121b2e`, `on-surface-variant #434652`, `outline #747783`, `outline-variant #c3c6d4`, `secondary-container #94a6ff`, `on-secondary-container #24388b`, `tertiary #3c4b00`, `tertiary-fixed #d3ee78`, `tertiary-fixed-dim #b7d15f`, `error #ba1a1a`, `error-container #ffdad6`. Type scale: `title-lg 20/28 600`, `title-md 16/24 600`, `body-lg 16/24 400`, `body-md 14/20 400`, `label-lg 14/20 600`, `label-md 12/16 600 +0.5px`, `headline-md 24/32 600`, `headline-lg 32/40 700`. Radius: `DEFAULT 4px`, `lg 8px`, `xl 12px`, `full`. Spacing: `margin-horizontal/gutter/inset-square 16`, `stack-md 12`, `stack-lg 24`, `base 8`.

## Summary

| reference | route/state | proposed status | one-line required work |
| --- | --- | --- | --- |
| `merchant_notification_center_french` | `/app/notifications` → `NotificationsScreen` | `needs_work` | Move "Tout marquer comme lu" to app bar, pill chips without checkmark, 48px type-icon circles, time top-right; omit Compte/Support chips, inline Accepter and help FAB (no contract / no screen). |
| `order_notification_settings_french` | `/app/notifications/settings` → `NotificationSettingsScreen` | `partial_contract_limited` | Full-bleed permission banner + risk strip, grouped bordered cards, sticky save bar, title "Paramètres de notification"; volume slider and repeat-reminder have no alert-engine capability; lock-screen/preview are OS-controlled. |
| `merchant_settings_french` | `/app/profile/settings` → `ProfileSettingsScreen` | `needs_work` | Rebuild as grouped nav-row cards (Compte / Opérations / Préférences / Support & légal) using only real destinations; icon-left red outlined logout; fix misleading "Sécurité, langue, déconnexion" subtitle on Profil hub. |
| `merchant_language_french` | none post-auth (pre-auth `/language` → `LanguageScreen` only) | `needs_work` | Add in-app language screen under `/app/…` reusing `setLocale`; selectable cards + note + sticky "Appliquer les modifications". Arabic copy does not exist yet (RTL only) → product decision. |
| `merchant_logout_french` | settings → `AlertDialog` (`_confirmLogout`) | `needs_work` | Replace dialog with full-screen confirmation: account card, conditional operational warning from real active-order count + availability, preserved-data note, "Se déconnecter" (error fill) + "Annuler et retourner". |
| `merchant_support_french` | none | `partial_contract_limited` | New support screen: "Nouveau ticket", active/resolved lists from `GET /merchant/:id/support` (OWNER/MANAGER only). Topic cards, FAQ card and ticket titles have no contract. |
| `staff_and_account_access_french` | none | `blocked_contract` | Read-only roster impossible: only caller's own membership is exposed. Own role already shown in settings. Mutations out of scope (prior instruction). |
| `premium_splash_and_session_routing_french` | `/` → `SplashScreen` | `exception_approved` | None (approved). Differences summarized only. |
| `merchant_onboarding_manage_business_unified` | `/onboarding` page 3 | `exception_approved` | None (approved). |
| `merchant_onboarding_manage_preparation_unified` | `/onboarding` page 2 | `exception_approved` | None (approved). |
| `merchant_onboarding_receive_orders_unified` | `/onboarding` page 1 | `exception_approved` | None (approved). |
| `merchant_phone_login_french` | `/phone` → `PhoneScreen` | `exception_approved` | None (Customer-aligned, approved). |
| `merchant_otp_verification_french` | `/otp` → `OtpScreen` | `exception_approved` | None (Customer-aligned, approved). |
| `merchant_registration_french` | `/access/registration` step 1 → `_AccountStep` | `exception_approved`\* | State/routing approved. If visuals are not covered: 2-col role cards, section icons, locked phone field; owner name / e-mail / consent have no contract. |
| `business_document_upload_french` | `/access/registration` step 3 → `_DocumentsStep` | `exception_approved`\* | Closest match already. If visuals not covered: third tip, privacy note, header title "Vérification". RC/NIF/ID naming and sequential lock not in contract. |
| `merchant_verification_pending_french` | `/verification/pending` → `_PendingVerificationBody` | `exception_approved`\* | If visuals not covered: add "Contacter le support" (contract exists, no UI), status-card copy; no priority chip, submitted date, step timestamps or SLA/SMS promise (no contract). |
| `merchant_verification_review_french` | `/access/registration` step 4 → `_ReviewStep` | `exception_approved`\* | If visuals not covered: info banner, section headers with "Modifier", doc chips grid, address instead of raw coordinates; owner name, category, customer preview, declaration have no/partial contract. |
| `merchant_verification_approved_french` | none (ACTIVE → `/app/home` or `/access/need-branch`) | `exception_approved`\* | No interstitial exists. Whether to add a one-time approval screen is an unresolved product decision (routing is inside the exception). |
| `merchant_verification_rejected_french` | `/verification/rejected` → `_LegacyVerificationBody` | `exception_approved`\* | If visuals not covered: hero + reference badge + guidance + support link + sticky "Corriger et soumettre"/"Se déconnecter"; per-item reasons and per-document verdicts have no contract. |
| `merchant_verification_resubmission_french` | REJECTED → `openRegistrationCorrections()` → `RegistrationHostScreen` | `exception_approved`\* | If visuals not covered: correction-mode header "Correction du dossier" + "Action requise" intro inside the wizard; refusal motifs, NIF previous/new value have no contract. |

\* Doc text (`MERCHANT_UI_SOURCE_OF_TRUTH.md` §7): "Verification / registration refs | `/access/*`, `/verification/*` | `exception_approved` / phase-1 evidence | Server-authoritative access; do not invent states". §3: "Auth / access | Authentication, access restrictions, and server-authoritative verification/membership states". The wording clearly covers **states and routing**; it does **not** clearly say pure visual styling is exempt. Prior evidence (`audit/registration-verification/SCREEN_MATRIX.md`, `STEP34_VISUAL_CORRECTION.md`) shows the team already applied Stitch visuals to these screens, which suggests visuals were not treated as exempt. **Unresolved product decision**: if visuals are not covered, the proposed status for these six becomes `partial_contract_limited` (registration, pending, review, rejected, resubmission, approved) and `needs_work` (document upload).

---

## merchant_notification_center_french

### Design
- Files: `screens/MerchantScreens/merchant_notification_center_french/screen.png`, `code.html` — both readable.
- App bar: sticky, `h-14`, `bg-surface`, `shadow-sm`, `px-16`. Left: `arrow_back` (primary) + title "Notifications" (`title-lg`, on-surface). Right: text button "Tout marquer comme lu" (`label-lg`, primary, hover `surface-container-high`). After tap in HTML it becomes "Tout est lu" in outline colour.
- Filter chips row (`px-16 py-16`, horizontal scroll, `gap-8`): "Tout" (selected: `bg-primary`, white, `rounded-full`, `px-16 py-8`, `label-lg`, `shadow-sm`), "Commandes", "Compte", "Support" (unselected: `bg-surface-container-high`, on-surface-variant). No checkmarks.
- Group headers: "AUJOURD'HUI", "PLUS TÔT" (`label-lg`, outline `#747783`, uppercase, `tracking-wider`, `mb-12`). Groups `space-y-24`; cards `space-y-8`.
- Card: `bg-white`, `p-16`, `rounded-xl` (12px), `shadow-sm`, `flex gap-16`. Unread: `border-l-4 border-primary` + 8px primary dot absolute `top-16 right-16`.
  - Leading 48×48 circle by type: new order `bg-primary-fixed` + `shopping_basket` primary; driver arrived `bg-tertiary-fixed` + `delivery_dining` tertiary; account `bg-secondary-container` + `verified_user` on-secondary-container; catalogue `bg-error-container` + `inventory_2` error.
  - Title `title-md` + relative time top-right (`label-md`, outline: "5 min", "12 min", "2h", "Hier").
  - Body `body-md` on-surface-variant; bold names; order ref `text-primary font-mono`.
  - New-order card: two buttons `flex-1 py-8 rounded-lg label-lg`: "Accepter" (`bg-primary` white), "Détails" (`bg-surface-container-high`).
- Help FAB: `fixed bottom-96 right-24`, 56px, `bg-tertiary-fixed`, `help` filled icon, `shadow-lg`.
- Bottom nav: commented out (none).
- Example data (never hardcode): Sara Belkacem, `#SG-260803-1842`, Yacine Mansouri, Dar El Benna, Amine Bensaïd, "3 articles".
- png vs html: consistent (png crops FAB over the last card).

### Flutter mapping
- Route `/app/notifications` (root navigator, no shell nav) → `lib/features/store/presentation/notifications_screen.dart` `NotificationsScreen`; data `notificationsControllerProvider` (`store_controllers.dart`) → `GET /notifications`, `POST /notifications/:id/read`, `POST /notifications/read-all`.
- Entry points: Home bell (`home_dashboard_screen.dart:88`), Profil hub row (`store_profile_screen.dart:229`).
- Current look: `audit/phase-5-ui/order-alerts-live/alert-inbox.png`.

### Differences
- App bar: `MerchantScaffold` title + refresh `IconButton`; "Tout marquer comme lu" is a left-aligned body `TextButton` above the chips instead of the app-bar trailing action.
- Chips: Material `ChoiceChip` with checkmark and outlined unselected state; only "Tout" and "Commandes" (Commandes = `MERCHANT_ORDER_CREATED` only).
- Group labels: "Aujourd’hui" / "Hier" / `dd/MM/yyyy` in `labelMedium` onSurfaceVariant, not uppercase outline; reference uses "Aujourd'hui" + "Plus tôt".
- Card: `MerchantCard` radius 16 + outline border + elevation; unread stripe is an inner 4px container (ok); icon circle 40px (ref 48) with `shopping_bag_outlined` or generic `notifications_active` for all other types; time is absolute `HH:mm` under the body (ref relative, top-right).
- Order ref: `sgo_…` via `OrderPublicReferenceLine` (copy affordance) on its own line vs inline mono ref (canonical ref differs from Stitch `#SG-` by design, see §6 of source-of-truth).
- Action: single "Détails" filled button (primary-container, left-aligned, auto width) vs two equal-width buttons.
- No help FAB. Extra refresh action.

### Contract
- List/read/read-all: SUPPORTED (`notifications/presentation/http/notification.controller.ts`). Item exposes type + `sourceId` (`dto/notification.dto.ts:88`).
- "Compte" filter: NOT SUPPORTED — merchant-audience types are only `MERCHANT_ORDER_CREATED` and `SETTLEMENT_FINALIZED` (`notification.service.ts:380–440`); no verification/account notification is emitted.
- "Support" filter: NOT SUPPORTED — support module emits no notifications.
- "Livreur arrivé" / "Alerte catalogue" cards: NOT SUPPORTED (no such merchant notification types).
- Inline "Accepter": `POST /merchant/:merchantId/orders/:orderId/accept` exists (`merchant-order.controller.ts:93`, OWNER/MANAGER only), but acceptance from the inbox bypasses detail/prep-time context and the item may be stale (`AppStrings.notificationsOrderStale` already exists for the overlay). Product decision, not a contract gap.
- `SETTLEMENT_FINALIZED` items currently fall to the generic icon; a "Paiements"-style mapping would be real data but has no reference chip.

### Alternatives
- `incoming_order_alert_french` designs the new-order interrupt (covered by `IncomingOrderAlertOverlay`, other batch).
- `MERCHANT_UI_SOURCE_OF_TRUTH.md` §6 marks this screen `implementer_reviewed` ("List + mark-read + day groups"); `audit/phase-4-ui/SCREEN_MATRIX.md:17` notes "Filters simplified".

### Required work
1. Move "Tout marquer comme lu" into `MerchantScaffold.actions` as a text action (disabled when no unread); keep refresh only if product wants it (not in ref).
2. Replace `ChoiceChip` with pill chips (selected `primary`/white, unselected `surface-container-high`/on-surface-variant, no checkmark). Keep only chips backed by types: Tout, Commandes.
3. Group headers uppercase `label-lg` outline; relabel older-than-today group as "Plus tôt" only if product accepts collapsing Hier/dates (otherwise keep real dates).
4. Card: 48px circle; per-type icon/colour map for real types only (`MERCHANT_ORDER_CREATED` → `shopping_basket` on `primary-fixed`; `SETTLEMENT_FINALIZED` → neutral mapping); relative time top-right derived from `createdAt`.
5. Order card: full-width "Détails" (`surface-container-high`) button; do not add "Accepter" without product approval.
6. Do not add the help FAB until a support screen exists (would be a dead action).

### Proposed status
`needs_work`

---

## order_notification_settings_french

### Design
- Files readable. **png vs html discrepancy**: html has an outlined pill "Tester l'alerte sonore" (`play_arrow`, `h-12 rounded-full border-primary`) after Rappels; the png does not show it (hidden behind the sticky bar or omitted) — record, do not pick silently.
- App bar: `h-16`, `bg-surface`, `border-b outline-variant`; `arrow_back` on-surface-variant; title "Paramètres de notification" (`title-lg`, **primary**).
- Permission banner (full-bleed, no card): `bg-surface-variant p-16`, `info` primary, "Les notifications sont activées sur votre appareil." (`body-md`) + link "Paramètres système" (`label-md` primary).
- Risk strip: `bg-error-container/30 px-16 py-12`, `warning` error 18px, "Les commandes entrantes critiques ne peuvent pas être totalement réduites au silence sans risque de retard." (xs, on-surface-variant).
- Sections (`p-16 space-y-24`), header `label-md` primary uppercase tracking-wider `mb-8`; card `bg-white rounded-lg (8px) border outline-variant divide-y`:
  - "ALERTES SONORES": "Sonnerie des nouvelles commandes" toggle; "Volume de l'alerte" slider (`volume_down` / range / `volume_up`).
  - "VIBRATIONS": "Vibration lors d'une commande" toggle.
  - "ALERTES PUSH": "Notifications sur l'écran de verrouillage", "Aperçu du contenu de la commande" toggles.
  - "RAPPELS": "Répéter l'alerte si non acceptée" select (`bg-surface-container-low border rounded-md py-12`, `expand_more`): "Toutes les 30 secondes / 1 minute / 2 minutes / Jamais".
- Toggle track checked `#2f59af`. Row label `title-md`.
- Sticky bottom bar: `bg-surface border-t p-16`; "Enregistrer les paramètres" `h-12 bg-primary rounded-full title-md shadow-sm`.
- No bottom nav.

### Flutter mapping
- `/app/notifications/settings` → `lib/features/notifications/presentation/notification_settings_screen.dart`; prefs `lib/features/notifications/data/notification_preferences.dart` (SharedPreferences, device-only); push via `merchant_push_controller.dart`. Entry: Profil hub row "Paramètres de notification" (`store_profile_screen.dart:232`). Not reachable from `ProfileSettingsScreen`.
- Current look: `audit/phase-5-ui/order-alerts-live/alert-preferences.png`.

### Differences
- Title "Alertes" (`notifSettingsScreenTitle`) vs "Paramètres de notification"; the Profil row that opens it is labelled "Paramètres de notification" (inconsistent). Default app bar, no bottom border.
- Permission banner is a `MerchantCard` (radius 16) with permission-state copy; no risk strip.
- Extra card: explanatory note "Ces interrupteurs contrôlent uniquement…" and an extra "Alertes dans l’application" toggle (real pref `foregroundAlertsEnabled`).
- Each toggle is its own `MerchantCard` (radius 16) instead of one bordered 8px card per section with dividers.
- No volume slider, no reminders select, no test button.
- Push section titled "HORS APPLICATION" with a single "Notifications hors application" toggle + registration status + lock-screen note, or an "indisponible" card when push is not configured.
- Save button is inline at list end (52px, theme radius), not a sticky bar.

### Contract
- Preferences: **local only** (device SharedPreferences). No server preference model exists (`contract.prisma` has no NotificationPreference; `Account` has no preference columns). Native push opt-out is enforced server-side via `PUT/DELETE /notifications/device-tokens` (`notification.controller.ts:92,117`). This is correct for device-level alerts; no backend change needed.
- Volume: NOT SUPPORTED by the client alert engine — `order_alert_controller.dart:417–420` uses `SystemSound.play(SystemSoundType.alert)` (system volume, no per-app level).
- Repeat reminder: NOT SUPPORTED — the controller plays once per discovered order; adding a repeat loop is a new behaviour (product decision; must not be an invented timer).
- Lock-screen / preview: OS-controlled on iOS/Android; the app cannot toggle them (current note is correct).
- Test sound: feasible locally (same `SystemSound` call) — real action, no contract needed.

### Alternatives
- Settings reference shows a "Notifications — Désactivé" status badge; that badge can be derived from OS permission + `nativePushEnabled`.

### Required work
1. Title "Paramètres de notification"; app bar bottom border; back icon on-surface-variant.
2. Full-bleed permission banner (`surface-variant`) with the existing permission-state copy + "Paramètres système"; add the risk strip (static advisory copy).
3. Group toggles into one bordered 8px card per section with dividers; keep the extra "Alertes dans l’application" toggle (real) inside "ALERTES SONORES" or its own section.
4. Omit volume and reminders (document as gaps); keep lock-screen note in place of the two push toggles.
5. Optional "Tester l'alerte sonore" outlined pill calling the real system alert (respecting sound pref) — resolve png/html discrepancy first.
6. Sticky bottom save bar, `rounded-full` 48px primary (see cross-cutting button radius conflict).

### Proposed status
`partial_contract_limited`

---

## merchant_settings_french

### Design
- Files readable. png omits the bottom nav (cropped); html has it.
- App bar: `h-14`, no shadow, `arrow_back` primary, centered title "Paramètres" (`headline-md` 24 **bold**, primary, `pr-40` to centre).
- Main `px-16 py-24 gap-24`.
- Profile summary card: `bg-white rounded-xl p-16 shadow-[0_2px_8px_rgba(0,0,0,0.04)]`; 64px `primary-container` avatar initials ("AB", `headline-lg`); name `title-lg`; `storefront` 16px + store name `body-md`.
- Group cards (same bg/radius/shadow, `overflow-hidden`): header `label-md` primary uppercase `px-16 pt-16 pb-8`; rows `px-16 py-16`, leading icon outline `#747783`, label `body-lg`, trailing `chevron_right` outline-variant; dividers `h-px outline-variant/30 mx-16`.
  - "COMPTE": `person` Profil · `security` Sécurité · `group` Gestion de l'équipe.
  - "OPÉRATIONS DU MAGASIN": `schedule` Horaires d'ouverture · `event_busy` Horaires exceptionnels · `map` Zone de livraison.
  - "PRÉFÉRENCES": `notifications` Notifications + badge "Désactivé" (`rounded px-8 py-2 bg-error-container on-error-container label-md border error/20`) · `language` Langue + trailing "Français" (`body-md`).
  - "SUPPORT & LÉGAL": `help` Centre d'aide · `description` Conditions d'utilisation · `policy` Politique de confidentialité.
- Logout: `pt-16 pb-32`, full width `h-48 bg-white border-error text-error rounded-lg title-md`, `logout` icon + "Déconnexion".
- Bottom nav (html): Accueil/Commandes/Catalogue/Rapports/Profil, Profil active pill `secondary-container`.

### Flutter mapping
- `/app/profile/settings` (root navigator) → `lib/features/shell/profile_settings_screen.dart` `ProfileSettingsScreen`. Entries: Profil gear, "Informations générales" row and "Paramètres du compte" row (`store_profile_screen.dart:81,169,246`) — three entries to the same screen.
- Current look: no dedicated capture found under `audit/**` (profile hub captures only: `audit/phase-5-ui/mocked/profile_*.png`).

### Differences
- Title left-aligned default app bar (not centred 24 bold primary).
- Header card: avatar initials from **merchant** name, merchant name, role label, branch — reference shows a **person** name + store.
- "COMPTE" card contains read-only text lines (Commerce / Établissement / Rôle) instead of nav rows.
- "ÉTABLISSEMENT" card: operational status badge + "Changer d’établissement" (multi-branch only) — not in reference.
- No Opérations, Préférences or Support & légal groups; hours and notifications live on the Profil hub instead.
- Logout: outlined error button with text only (no icon); opens an `AlertDialog` (see logout).
- No bottom nav (root-navigator push).
- Profil hub subtitle for this screen is "Sécurité, langue, déconnexion" (`AppStrings.storeProfileSettingsSub`) but the screen has neither security nor language — misleading copy.
- `MerchantCard` radius 16 + border vs reference 12px borderless soft shadow.

### Contract (per row)
- Profil → `/app/profile` hub exists (SUPPORTED, navigation only).
- Sécurité → `GET /auth/sessions`, `DELETE /auth/sessions/:id`, `POST /auth/logout-all` exist (`auth/presentation/http/auth.controller.ts:89,105,112`); no Flutter client/UI. SUPPORTED contract, screen not built (out of batch unless opened).
- Gestion de l'équipe → see `staff_and_account_access_french` (roster NOT SUPPORTED).
- Horaires d'ouverture → `/app/profile/hours` SUPPORTED.
- Horaires exceptionnels → NOT SUPPORTED (no exception-hours endpoint in `merchant.controller.ts`; §6 "exceptional hours blocked").
- Zone de livraison → NOT SUPPORTED for Merchant (no zones controller exposed to merchants; `src/modules/zones` has no merchant controller).
- Notifications + badge → `/app/notifications/settings` SUPPORTED; badge derivable from OS permission + local prefs (real).
- Langue → local `setLocale` SUPPORTED; no post-auth route (see language).
- Centre d'aide → merchant support API SUPPORTED, no UI (see support).
- CGU / Confidentialité → NOT SUPPORTED: no URL or content anywhere (no setting key; `settings.registry.ts` only has support contact email/phone, admin-only).
- Person name → NOT SUPPORTED: `Account` has only phone/email (`contract.prisma:145`); only `CustomerProfile.fullName` exists.

### Alternatives
- `store_profile_french` (other batch) already hosts hours / availability / notifications rows. Source-of-truth §6: "Nested under Profil; no dead menu rows".
- `audit/phase-4-ui/SCREEN_MATRIX.md:44` "Dead rows omitted".

### Required work
1. Centred 24/700 primary title; reference card style (see cross-cutting).
2. Header: 64px initials avatar (from merchant name — no person name exists) + merchant name + `storefront` branch line; keep role label.
3. Replace text lines with `MerchantNavRow` groups using only live destinations: COMPTE (Profil → hub; Gestion de l'équipe only if a read-only own-role view is approved), OPÉRATIONS (Horaires d'ouverture), PRÉFÉRENCES (Notifications with derived status badge; Langue with current value once the in-app language route exists), SUPPORT (Centre d'aide once the support screen exists). Omit Sécurité unless its screen is built; omit exceptional hours, zone, CGU, privacy.
4. Keep "Changer d’établissement" (real) as a row in COMPTE or OPÉRATIONS.
5. Logout button with `logout` icon, `h-48 rounded-lg border-error`, label "Déconnexion".
6. Fix `storeProfileSettingsSub` copy to reflect actual content; consider collapsing the three Profil entries.

### Proposed status
`needs_work`

---

## merchant_language_french

### Design
- Files readable. png vs html: html subtitle typo "Gisage de gauche à droite (LTR)" is rendered the same in png ("Gisage") — typo in reference, do not copy; intended "Affichage" is an assumption → copy is a product decision.
- App bar: sticky, `px-16 py-12`, `border-b outline-variant`, 40px round `arrow_back`, title "Langue" (`title-lg` bold, on-surface).
- "Choisir la langue" (`title-md` bold, `mb-16`).
- Cards `space-y-16`, `p-16 rounded-lg`: selected `border-2 border-primary bg-white`; unselected `border outline-variant`. Leading 48px `rounded-lg` tile ("A" on `primary-fixed`/primary; "أ" on `surface-container`); title "Français" / "العربية" (base semibold); subtitle LTR/RTL (sm outline); trailing radio 20px (selected: primary ring + 10px dot).
- "APERÇU DU CHANGEMENT" (`label-lg` bold outline uppercase) + skeleton window preview (`rounded-xl border shadow-sm`) that mirrors direction.
- Info note `bg-surface-container-low rounded-lg p-16`, `info` primary 20px: "Le changement de langue affecte uniquement l'interface de l'application. Vos données de catalogue (noms des produits, descriptions) restent dans leurs langues respectives."
- Sticky CTA above nav: `bg-surface/80 backdrop-blur border-t p-16`, "Appliquer les modifications" `h-12 rounded-full bg-primary bold shadow-lg`.
- Bottom nav in reference is a **non-Merchant** variant (Accueil/Commandes/Catalogue/Messages/Paramètres with Phosphor SVGs) — conflicts with the Merchant 5-tab bar; ignore.

### Flutter mapping
- Only pre-auth `/language` → `LanguageScreen` (`lib/features/auth/presentation/splash_screen.dart:118`): heading "Langue / اللغة", filled "Français" + outlined "العربية" buttons, immediate `setLocale`. Signed-in redirect (`app_router.dart:64`) sends any non-`/app/` path home, so this route is unreachable after login.
- `SessionController.setLocale` (`session_controller.dart:241`) persists locally; `app.dart` switches `Locale` + `Directionality`.
- `AppStrings` header: "Arabic uses the same keys via locale direction; content stays French until ARB extraction" — choosing Arabic flips layout to RTL but all text stays French.

### Differences
- No in-app language screen at all; settings has no Langue row.
- Pre-auth screen is two buttons, no cards, no preview, no note, no apply step.

### Contract
- Locale is device-local: SUPPORTED (no server locale needed for UI). `Account` has no locale column (`contract.prisma:145`) — server-side locale for push/SMS copy is NOT SUPPORTED, but not required by this reference.
- Arabic UI strings: NOT AVAILABLE in the app (content gap, not backend).

### Alternatives
- Pre-auth `LanguageScreen` is not listed as an approved exception in §3/§7 (only splash, onboarding, phone/OTP). Whether it should adopt this reference's card style is an unresolved question.

### Required work
1. New route under the shell root navigator (e.g. `/app/profile/settings/language`) + settings row "Langue" with current value.
2. Screen per reference: selectable cards with radio, info note, sticky "Appliquer les modifications" calling `setLocale` (apply is real; no fake success).
3. Preview skeleton is decorative (no data) — optional.
4. Do not ship an "العربية" option that yields French text without a product decision (see unresolved decisions).

### Proposed status
`needs_work`

---

## merchant_logout_french

### Design
- Files readable, consistent.
- App bar: `h-14`, 40px `arrow_back` primary, title "Déconnexion" (`headline-md` bold primary, left, `ml-8`).
- Main `px-16 pt-24 pb-96 gap-24`, actions pushed to bottom.
- Account card: `bg-white rounded-xl p-16 shadow-sm`; 56px initials (`primary-container`); name `title-md`, store `body-md`; trailing chip "Connecté" (`bg-tertiary-fixed-dim/20 border-tertiary-fixed/30 rounded-full px-12 py-4`, 8px dot + text `#16a34a` `label-md`).
- Warning card: `bg-error-container/30 border-error-container rounded-xl p-16`; filled `warning` error; "Attention aux opérations en cours" (`title-md`); "Vous avez des commandes actives et le magasin est actuellement ouvert."; inner white `rounded-lg p-12 border` table: "Commandes en cours" → count (`label-lg` error), divider, "État du magasin" → "Ouvert" (`label-lg` primary); note "Assurez-vous qu'un autre gestionnaire est disponible pour traiter les commandes avant de vous déconnecter." (`label-md`, `bg-surface-container-low p-12 rounded-lg`).
- Info row: `info` + "Vos données, le catalogue et l'historique des commandes seront préservés."
- Actions `gap-12`: "Se déconnecter" (`h-52 bg-error text-white rounded-xl label-lg`, `logout` icon, `shadow-sm`); "Annuler et retourner" (`h-48 bg-white border-primary text-primary rounded-xl`).
- No bottom nav.

### Flutter mapping
- `ProfileSettingsScreen._confirmLogout` → `AlertDialog` (title/actions "Déconnexion", body "Voulez-vous vraiment vous déconnecter de SpeedyGo Merchant ?", "Annuler"). Logout: `SessionController.logout()` → push token deactivation + `POST /auth/logout` + local clear.

### Differences
- Dialog vs full screen; no account card, no operational warning, no preserved-data note, no icon CTA; destructive action is a text button.
- `audit/phase-4-ui/SCREEN_MATRIX.md:45` recorded "matches: yes" — this inventory disagrees (structure differs materially).

### Contract
- Logout: SUPPORTED (`auth.controller.ts:80`, push `DELETE /notifications/device-tokens`).
- Active order count: SUPPORTED via existing orders list (`homeOrderCountsProvider`, `orders_controller.dart:281`).
- Store state: SUPPORTED via `GET …/branches/:branchId/availability` (`branchAvailabilityControllerProvider`).
- "Connecté": trivially true while on the screen (session present).
- Person name: NOT SUPPORTED (use merchant/branch name).
- "another manager available": no presence/roster contract — keep only as generic advice, never as a claim.

### Alternatives
- Settings reference embeds the entry button; pending/rejected references also offer "Se déconnecter" directly (no confirmation).

### Required work
1. Replace the dialog with a pushed confirmation screen (e.g. `/app/profile/settings/logout`) per reference.
2. Show the warning card **only** when active orders > 0 or availability is open, with real values; hide otherwise (no hardcoded "3"/"Ouvert").
3. Account card from merchant/branch names; "Connecté" chip.
4. CTAs as specified; "Annuler et retourner" pops.
5. Verify STAFF/MANAGER both reach it (logout is role-agnostic).

### Proposed status
`needs_work`

---

## merchant_support_french

### Design
- Files readable, consistent.
- Header: sticky `bg-surface/80 backdrop-blur border-b`, `p-16 gap-16`; 40px `arrow_back`; title "Support Merchant" (`title-lg` bold) + subtitle "DAR EL BENNA • AMINE BENSAÏD" (xs outline uppercase tracking-wider).
- Hero CTA (`px-16 py-24`): "Nouveau ticket" full width `bg-primary-container text-white py-16 rounded-lg text-lg bold shadow-sm`, filled `add_circle`.
- "Tickets actifs" (`title-md` bold) + count badge (20px `primary-container` circle, 10px white). Card `bg-surface-container-low border outline-variant rounded-lg p-16 shadow-sm`: 48px tile `surface-container-highest` + `shopping_bag` primary; title (truncate, semibold) "Problème avec la commande #SG-…"; status chip "EN COURS" (`secondary-container/30 on-secondary-container 11px bold rounded-full uppercase`) + "• Mis à jour il y a 2h"; `chevron_right`.
- "Sujets fréquents" 2×2 grid: white `border rounded-lg p-16`, 40px `surface-container` circle icons `local_shipping` Commande Active · `inventory_2` Catalogue · `payments` Paiement · `verified_user` Profil & Vérification.
- "Tickets résolus": white bordered list, `opacity-75`, `check_circle` outline tile, title, "RÉSOLU" (`#07883b` 10px bold) + date.
- Dark help card: `bg-inverse-surface #273044 rounded-lg p-24 shadow-lg` + blurred circles; "Besoin d'aide immédiate ?"; body; white pill "Consulter la FAQ".
- No bottom nav.

### Flutter mapping
- None. Only `AppConstants.merchantSupport(merchantId)` path constant (`app_constants.dart:116`) is defined and unused. Pre-auth "Besoin d’aide ?" on phone/OTP shows `helpUnavailable` snackbar (exception screens; not to change here).
- Would live at e.g. `/app/profile/support` (+ `/app/profile/support/:ticketId`) on the root navigator, reachable from settings "Centre d'aide".

### Differences
- Screen does not exist.

### Contract
- `merchant/:merchantId/support` (`support/presentation/http/merchant-support.controller.ts`): `POST` create (body 1–4000 chars + optional `orderId` belonging to merchant), `GET` list (limit/offset), `GET :ticketId` (messages, no internal notes), `POST :ticketId/messages`. **OWNER or MANAGER only; STAFF forbidden** (`support.service.ts:324–340`). No merchant-status gate (works for PENDING_REVIEW/REJECTED/SUSPENDED owners too).
- List item fields: `publicReference (sgt_…)`, `status` (OPEN / IN_PROGRESS / WAITING_CUSTOMER / RESOLVED / CLOSED), `priority`, `orderId`, `createdAt`, `updatedAt` (`support.types.ts:71`). **No subject/title, no message preview, no order public reference in list** (detail includes `order.publicReference`).
- Topic cards (categories): NOT SUPPORTED — `CreateSupportTicketDto` has no category (`dto/support.dto.ts:22`).
- FAQ / documentation: NOT SUPPORTED (no content endpoint).
- Support contact phone/e-mail: PARTIAL — stored as platform settings but admin-only (`settings.registry.ts:12–44`, "no mobile consumer"; only `admin/settings` controller).

### Alternatives
- `signaler_un_probl_me_standardis` (order-level problem report; other batch) overlaps "Nouveau ticket" with `orderId`.
- Pending/rejected verification references both have "Contacter le support".

### Required work
1. Merchant API client methods for the four endpoints + role gate (hide entry for STAFF).
2. Screen: header (title + merchant name subtitle only), "Nouveau ticket" → compose sheet/screen (free text, optional order link from own orders).
3. Active list = OPEN/IN_PROGRESS/WAITING_CUSTOMER; resolved list = RESOLVED/CLOSED; row shows `publicReference`, status chip, relative `updatedAt`. Titles: generic ("Ticket" / "Commande <ref>" only when detail data is loaded) — no invented subjects.
4. Ticket detail with message thread + reply.
5. Omit topic grid and FAQ card (or topic cards only as body-prefill helpers if product approves — not categories).

### Proposed status
`partial_contract_limited`

---

## staff_and_account_access_french

### Design
- Files readable. png: FAB overlaps the roles summary (visual only).
- App bar: flat, `arrow_back` primary, centred "Personnel et Accès" (`title-lg` bold primary), `more_vert`.
- Store context card (white `rounded-lg p-16 shadow-[0_2px_8px_rgba(0,0,0,0.04)]`): 48px `primary-container` circle `storefront`; "Dar El Benna" / "Gestion de l'équipe".
- "Membres actifs": member cards with 40px initials, name `title-md`, role label; owner has "Admin" chip (`shield`, `surface-container-high`, bordered); others `more_horiz`, footer (`border-t`) presence ("Actif maintenant" with dot / "Dernière activité: Il y a 2h") + "Révoquer" (`person_remove`, error).
- "Invitations en attente" (`mail`): dashed card with phone, "Rôle: Opérateur", "Renvoyer" pill, "Envoyée hier", "Annuler".
- "Résumé des rôles" (`bg-surface-container`): "Opérateur: Peut accepter/annuler des commandes et gérer le statut des préparations." / "Gestionnaire: Peut modifier les prix, ajouter/retirer des produits du catalogue."
- FAB "Inviter un membre" (`person_add`, `h-14 rounded-full bg-primary`).

### Flutter mapping
- None. Own role is shown read-only in `ProfileSettingsScreen` (COMPTE card: "Rôle: …") and Profil hub identity card.

### Differences
- Screen does not exist. Per prior instruction ("Do not create a staff-management feature"): only a read-only view of existing membership/role is assessable; Révoquer / Renvoyer / Annuler / Inviter / more menus are out of scope.

### Contract
- Roster listing: NOT SUPPORTED — no endpoint lists other members; `GET /merchant/me` returns only the caller's memberships (`merchant.controller.ts:83`). `MerchantMember` has `role` + `createdAt` only (`contract.prisma:532`).
- Presence/last activity: NOT SUPPORTED.
- Invitations: NOT SUPPORTED (no model).
- Role taxonomy conflict: backend roles are `OWNER / MANAGER / STAFF` (`merchant.policy.ts:1`). STAFF cannot mutate orders or manage catalogue; MANAGER can do both (`roleHasCapability`). The reference's "Opérateur can accept/cancel orders" and "Gestionnaire can edit prices" contradict the policy and must not be copied.

### Alternatives
- `merchant_registration_french` shows a Propriétaire/Opérateur choice (operator join is unsupported — `RegistrationIntent.operatorJoinUnsupported`).

### Required work
- None buildable for the roster. If product wants a read-only "Mon accès" card: own role + merchant + branch + policy-accurate role description (already present as text in settings). Anything more needs a members-list contract (and would still exclude mutations).

### Proposed status
`blocked_contract`

---

## premium_splash_and_session_routing_french

### Design (summary only)
- Full-screen WebGL shader gradient `#162B7F → #2F59AF` with faint route curves and a lime `#BBD562` node; centred 100px logo image, "SpeedyGo Merchant" (28px white), "Gérez votre activité, simplement." (80% white); 48px lime `#c7e16d` spinner; "Vérification de votre espace marchand..."; footer `verified_user` + "Conçu pour les commerçants en Algérie".
- png vs html: png shows only the backdrop, loading text and footer (logo/title not rendered at capture time).

### Flutter mapping
- `/` → `SplashScreen` (`lib/features/auth/presentation/splash_screen.dart`), backdrop `MerchantSplashBackdropPainter` (`splash_backdrop.dart`).

### Differences (no changes proposed)
- Static painted backdrop instead of animated shader; large logo asset (62% width, 180–280px) instead of 100px logo + separate title; tagline "Votre commerce. Simplement." instead of title + "Gérez votre activité, simplement."; no loading text; no footer trust line; 28px white spinner instead of 48px lime.

### Contract
- N/A (session restore uses existing auth).

### Alternatives
- Source-of-truth §3/§7: "Preserve current approved splash".

### Required work
None.

### Proposed status
`exception_approved`

---

## merchant_onboarding_manage_business_unified

### Design (summary only)
- **png partially unreadable**: `screens/MerchantScreens/merchant_onboarding_manage_business_unified/screen.png` renders only the left ~40%; the right side is blank. Design taken from `code.html`.
- Brand "SpeedyGo Merchant" (`headline-md` bold primary, no Passer); 350×286 tilted hero mock (store card "Établissement ouvert" + FR/AR, stats Commandes 12 / Revenu 24 500 DZD, product "Couscous royal 1 200 DZD Disponible" with image); "Pilotez toute votre activité" + "Gérez votre catalogue bilingue, vos disponibilités, vos horaires et vos performances depuis un seul endroit."; dots (3rd active); "Créer mon espace marchand" (`h-52 rounded-xl`) + outlined "J’ai déjà un compte"; legal microcopy.

### Flutter mapping
- `/onboarding` → `OnboardingScreen` page 3 (`onboarding_screen.dart`, asset `assets/images/onboardin3.png`).

### Differences (no changes proposed)
- Static illustration asset vs live HTML mock; title "Votre commerce, à portée de main" and different body; CTA "Commencer"; secondary is a text button; no legal microcopy; "Passer" present in Flutter.

### Contract
N/A.

### Alternatives
§3: "Current approved three onboarding pages".

### Required work
None.

### Proposed status
`exception_approved`

---

## merchant_onboarding_manage_preparation_unified

### Design (summary only)
- Fixed header brand + "Passer"; hero card "COMMANDE EN COURS #SG-260803", "En préparation" orange chip, clock "17:26", 3-step tracker (Acceptée / Préparation / Prête), customer row "Sara B. 3 articles", "Marquer comme prête"; "Maîtrisez chaque préparation" + "Suivez les délais, ajustez le temps nécessaire et informez automatiquement le client et le livreur."; dots (2nd active); sticky blurred footer "Suivant" + outlined "J’ai déjà un compte" (`h-14 rounded-xl`).

### Flutter mapping
- `/onboarding` page 2 (`onboardin2.png`).

### Differences (no changes proposed)
- Static illustration; title "Maîtrisez la préparation"; body avoids automatic-notification claim; secondary as text button.

### Contract
N/A.

### Alternatives
§3.

### Required work
None.

### Proposed status
`exception_approved`

---

## merchant_onboarding_receive_orders_unified

### Design (summary only)
- Brand + "Passer"; dotted hero with tilted order card ("NOUVELLE COMMANDE #SG-260803", "25 min", "2 450 DZD", "3 articles • Cité El Salem", Refuser/Accepter); "Recevez vos commandes à temps" + "Soyez alerté immédiatement, consultez les détails et répondez sans interrompre votre activité."; dots (1st active); "Suivant" + outlined "J’ai déjà un compte" (`h-54 rounded-xl`).

### Flutter mapping
- `/onboarding` page 1 (`onboardin1.png`).

### Differences (no changes proposed)
- Static illustration; title "Recevez vos commandes"; body "Retrouvez les nouvelles commandes et consultez leurs détails."; secondary as text button.

### Contract
N/A.

### Alternatives
§3.

### Required work
None.

### Proposed status
`exception_approved`

---

## merchant_phone_login_french

### Design (summary only)
- App bar "Connexion" + back + `notifications`; "Entrez votre numéro" (`headline-lg` 32); OTP/SMS explainer; label "Numéro de téléphone"; 52px field with flag + "+213" divider; inline link `help` "Besoin d'aide pour vous connecter ?"; faded shield "Sécurisé par SpeedyGo Merchant System"; sticky "Continuer →" (`h-52 rounded-xl`) + "En continuant, vous acceptez nos Conditions d'utilisation".

### Flutter mapping
- `/phone` → `PhoneScreen` (`phone_otp_screens.dart:17`).

### Differences (no changes proposed)
- Centred brand header without back/bell; title "Entrez votre numéro de téléphone" at 24px; 64px field; SMS fee note; "Besoin d’aide ?" in blurred bottom bar (snackbar "L’assistance sera disponible dans une prochaine version."); no shield graphic; no terms microcopy.

### Contract
- OTP request/verify SUPPORTED (`auth.controller.ts:33,48`).

### Alternatives
§3/§7 "Aligned with Customer presentation"; `audit/phase-1/AUTH_UI_AND_VERIFICATION.md`.

### Required work
None.

### Proposed status
`exception_approved`

---

## merchant_otp_verification_french

### Design (summary only)
- App bar "Vérification"; 64px `primary-container` shield; "Code de validation" + "Entrez le code à 6 chiffres envoyé au +213 …"; six 48×56 cells; "Renvoyer le code dans 01:59" (html timer); "Modifier le numéro de téléphone"; security pill "Votre sécurité est notre priorité."; "Vérifier le code" (`h-52 rounded-xl`).

### Flutter mapping
- `/otp` → `OtpScreen` (`phone_otp_screens.dart:369`).

### Differences (no changes proposed)
- No shield or pill; title "Vérification du code"; inline "Code envoyé au … Modifier"; resend countdown from server-driven `otpResendSecondsRemaining` (correctly not a fixed 01:59); header help icon (snackbar); CTA "Vérifier".

### Contract
SUPPORTED.

### Alternatives
§3/§7.

### Required work
None.

### Proposed status
`exception_approved`

---

## merchant_registration_french

### Design
- Files readable, consistent.
- App bar fixed `h-14 shadow-sm`: 44px `arrow_back` primary, title "Inscription" (`title-lg`, **on-surface**), balancing spacer.
- Progress: "ÉTAPE 1 SUR 4" (`label-md` primary uppercase) · "Configuration du compte" (`label-md` italic on-surface-variant); 8px track `surface-container`, fill `primary-container` 25%.
- Sections (`space-y-24`), header `title-md` + primary icon:
  - `person` "Identité du propriétaire": "Nom complet" input (`h-12 rounded-xl border outline-variant`).
  - `badge` "Rôle": 2-col grid, `h-24 rounded-xl border-2`; selected `border-primary bg-primary-container/10`; `account_balance` (filled) "Propriétaire", `engineering` "Opérateur".
  - `contact_phone` "Contact": locked phone input (`bg-surface-container-low opacity-80`, `lock` icon) + "Ce numéro a été vérifié lors de l'étape précédente." (11px); "Email (Optionnel)" input.
- Consent: 24px checkbox + "Je consens au traitement de mes données et j'accepte les Conditions Générales ainsi que la Politique de Confidentialité." (links primary semibold underlined).
- Sticky bar `bg-surface/80 backdrop-blur border-t`: "Continuer l'inscription →" (`h-52 rounded-xl bg-primary shadow-lg`).
- In the png, sections sit on tinted rounded containers (`surface-container-low`-like) — html `form-section` class styling not in the file (discrepancy: png shows card backgrounds, html has no explicit bg).

### Flutter mapping
- `/access/registration` (and `/access/none`) → `RegistrationHostScreen` → `RegistrationStep.account` → `_AccountStep` (`registration_screens.dart:148`), scaffold `_RegScaffold`.
- Current look: `audit/registration-verification/captures/` (account step not captured; docs step capture `reg-documents-375x667.png` shows shared scaffold).

### Differences
- Title "Inscription" in primary; progress row "Étape 1 sur 4" + "25%" (not uppercase, no step name), then headline "Configuration du compte".
- Role: vertical list tiles with subtitle hints (`storefront_outlined` / `badge_outlined`) instead of 2-col icon cards.
- Phone: plain card with text + hint, not a locked input.
- No owner name field; e-mail and consent replaced by explanatory text lines.
- CTA "Continuer" without arrow; not in blurred sticky bar.

### Contract
- Role choice: OWNER creation SUPPORTED (`POST /merchant/profile`); operator join NOT SUPPORTED (no invitation contract) — current `operatorJoinUnsupported` honest.
- Owner full name: NOT SUPPORTED (`Account` has no name; merchant name is captured in step 2).
- E-mail: NOT SUPPORTED on the merchant path (`Account.email` exists but no write endpoint).
- Consent: NOT SUPPORTED (no persistence); CGU/privacy URLs NOT SUPPORTED.

### Alternatives
- `merchant_information_french` (step 2; other batch or not in scope) and `audit/registration-verification/SCREEN_MATRIX.md` row 1: "Works (supported subset)".

### Required work (only if visuals are ruled not covered by the exception)
1. Progress header per reference (uppercase step label + step name, `primary-container` fill).
2. Sectioned layout with primary icons; 2-col role cards (keep operator card with its unsupported notice on select).
3. Locked phone input style + hint.
4. Keep e-mail/consent as honest notes; do not add a non-persisted consent checkbox without product/legal approval.
5. CTA "Continuer l'inscription" with `arrow_forward` in a blurred sticky bar.

### Proposed status
`exception_approved` (state/routing). Visual coverage unresolved → otherwise `partial_contract_limited`.

---

## business_document_upload_french

### Design
- Files readable, consistent.
- App bar fixed: `arrow_back` primary, "Vérification" (`title-lg` primary), trailing 24px logo image.
- Stepper: "Étape 3 sur 4" (`label-md` on-surface-variant) · "75%" (`label-md` primary bold); 8px track `surface-container-highest`, primary fill with glow.
- "Documents d'entreprise" (`headline-md`) + "Établissement : **Dar El Benna** • Amine Bensaïd".
- Cards `space-y-12`, `p-16 rounded-xl`:
  - Uploaded: white, border outline-variant, soft shadow; 56px thumbnail with image preview + filled `check_circle` tertiary; "Registre du Commerce (RC)" + `verified` "Téléchargé" (tertiary); trailing `edit` primary.
  - Action: `border-2 primary-container`; 56px `primary-fixed` tile `receipt_long`; "Identifiant Fiscal (NIF)" + "Prêt à télécharger" (primary-container); "+ Ajouter" pill (`bg-primary rounded-full shadow-md`).
  - Locked: `bg-surface-container-low opacity-80`; `badge` outline; "Pièce d'identité du gérant" / "En attente"; `lock`.
- Tips card (`bg-surface-container rounded-xl`): `tips_and_updates` "Conseils pour une capture nette"; `wb_sunny`, `center_focus_strong`, `no_flash` tips (3).
- Privacy note: `security` + "Vos documents sont stockés de manière sécurisée et ne sont utilisés qu'à des fins de validation légale conformément à notre politique de confidentialité."
- Sticky footer: "Continuer vers l'étape finale" (`h-52 rounded-xl`) + "Veuillez télécharger tous les documents requis".

### Flutter mapping
- `/access/registration` step 3 → `_DocumentsStep` / `_DocumentCard` / `_DocsTipsCard` (`registration_screens.dart:416–856`); upload via `uploadEvidenceContent` + `bindEvidence`.
- Current look: `audit/registration-verification/captures/reg-documents-375x667.png`.

### Differences
- App bar title "Inscription" (shared `_RegScaffold`), no logo.
- Document titles are SpeedyGo evidence categories ("Identité de l’activité", "Enregistrement de l’activité", "Document complémentaire") with Obligatoire/Facultatif labels — not RC/NIF/ID.
- Attached state shows type icon + check badge (no image thumbnail); "+ Ajouter" is `rounded 8` not a pill.
- No locked/sequential state; all types uploadable at once.
- Two tips (no `no_flash`), rounded-12 `#F1F3FF` card; no privacy note; formats line "PDF, JPEG ou PNG (10 Mo max)".
- CTA "Continuer" (not "Continuer vers l'étape finale").

### Contract
- Upload + bind: SUPPORTED — `POST /merchant/:id/verification/documents/:type/content` (PDF/JPEG/PNG, 10 MiB) and `PUT …/documents/:type` (`merchant.controller.ts:160,208`), OWNER only; types `BUSINESS_IDENTITY`, `BUSINESS_REGISTRATION`, `SUPPORTING_DOCUMENT`.
- Document status: only `PENDING`/`SUBMITTED` (`merchant.policy.ts:83–89`); no per-document approved/rejected.
- Thumbnail: merchant has no binary download ("No binary download", `merchant.controller.ts:142`) — only an in-session local preview of the picked file would be possible.
- Reference "Max 5Mo" is example data; backend 10 MiB is authoritative.

### Alternatives
- `merchant_verification_resubmission_french` reuses the dropzone pattern for replacements.
- `STEP34_VISUAL_CORRECTION.md` already aligned this step.

### Required work (only if visuals not covered)
1. Add the third tip (flash) and the privacy note.
2. Pill "+ Ajouter"; CTA copy "Continuer vers l'étape finale" if product agrees.
3. Keep SpeedyGo categories (do not rename to RC/NIF); no fake locked state.

### Proposed status
`exception_approved` (state/routing). Visual coverage unresolved → otherwise `needs_work`.

---

## merchant_verification_pending_french

### Design
- Files readable. png: sticky footer overlaps the timeline (visual only).
- Header `h-14 shadow-sm`: `speed` icon + "SpeedyGo Merchant" (`headline-md` extrabold primary); trailing "FR" chip (`surface-container-high rounded-full`).
- Illustration: 160px circle `primary-fixed/30` with 80px `hourglass_empty` (`primary-container`, pulse); person name "Amine Bensaïd" (`headline-md`) + store (`body-md`).
- Status card (white `rounded-xl p-16 shadow-sm border/20`): `schedule` + "Vérification en cours" (`title-md` primary-container); "ID: #SG-260803-1842" (`label-md` outline); chip "PRIORITAIRE" (`primary-fixed` 10px uppercase); divider; italic "Soumis le 20 juillet 2024".
- Timeline card "Progression du dossier": Dossier soumis (primary check, "Reçu le 20/07/2024 à 18:42") → Examen des documents (`tertiary-fixed` circle, spinning `sync`, "En cours d'analyse par nos agents") → Validation finale (`pending`, outline-variant, "Attente des approbations").
- Info block `bg-primary-fixed/20 border-l-4 primary`: "Nous vous informerons par SMS et notification dès que votre compte sera prêt. Cela prend généralement 24 à 48 heures."
- Footer (gradient): "Actualiser le statut" (`h-14 rounded-xl primary`, `refresh`), "Contacter le support" (`h-12` outlined, `contact_support`), text "Se déconnecter" (`logout`, outline-variant).

### Flutter mapping
- `/verification/pending` → `VerificationScreen(kind: verificationPending)` → `_PendingVerificationBody` (`access_screens.dart:230`). Routed when merchant is `PENDING_REVIEW`/not approved **and** `verificationSubmitted` (`access_controller.dart:139`).
- Current look: `audit/registration-lifecycle-acceptance/screenshots/live-pending.png`.

### Differences
- Header present (icon + brand) but no FR chip.
- Headline is merchant name; no person name.
- Status card: title + "Référence : <publicReference>" + guidance text; no priority chip, no submitted date.
- Timeline: "État du dossier" (vs "Progression du dossier"), steps "Dossier soumis" (no timestamp) → "Examen des documents" ("En cours d’examen par SpeedyGo") → "Décision" ("En attente").
- Extra "Pièces du dossier" checklist with state badges (not in ref).
- No info/SLA block; no "Contacter le support". Footer: optional "Soumettre le dossier", "Actualiser le statut", "Se déconnecter".
- Hardcoded `Color(0xFFD9E2FF)` / `0xFFE1E8FF` instead of tokens.

### Contract
- Status/reference/checklist: SUPPORTED via `GET /merchant/me` (checklist OWNER-only).
- Refresh: SUPPORTED (re-resolve).
- Support: SUPPORTED for OWNER/MANAGER regardless of merchant status (`support.service.ts`, `merchant-access.service.ts:39` has no status gate); no Flutter client.
- Priority chip: NOT SUPPORTED (no verification priority).
- Submitted date / step timestamps: NOT SUPPORTED (boolean `verificationSubmitted` only).
- SLA "24 à 48 heures" and "SMS et notification": NOT SUPPORTED — no verification notification is emitted; must not be promised.
- Language chip: local locale only (see language).

### Alternatives
- `SCREEN_MATRIX.md` row 9: "Works… No fake SLA/priority/SMS".

### Required work (only if visuals not covered)
1. "Contacter le support" outlined button → support compose (after support screen exists; OWNER/MANAGER).
2. Timeline title copy "Progression du dossier"; replace hex literals with tokens.
3. Keep checklist (real) below timeline; omit priority, dates, SLA.
4. FR chip only if in-app language switching is approved pre-home.

### Proposed status
`exception_approved` (state/routing). Visual coverage unresolved → otherwise `partial_contract_limited`.

---

## merchant_verification_review_french

### Design
- Files readable, consistent.
- App bar fixed: `arrow_back` primary, "Révision" (`title-lg` bold primary), trailing `notifications`.
- Info banner `bg-surface-container-high rounded-xl p-16 border primary-container/20`, `info`: "Veuillez vérifier attentivement vos informations avant la soumission finale pour éviter tout retard de validation."
- Sections (`space-y-24`), header row: title `title-md` primary + "Modifier" (`edit` 18px, `label-lg` primary):
  - "Propriétaire": card with "NOM COMPLET" / "TÉLÉPHONE" (`label-md` outline uppercase + `body-lg` semibold).
  - "Documents légaux": 2-col cards "REGISTRE DU COMMERCE", "IDENTIFIANT FISCAL (NIF)" each with chip `check_circle` "Téléchargé" (`primary-container/10 rounded-full`).
  - "Établissement": NOM DU COMMERCE / CATÉGORIE, LOCALISATION text + 128px map image.
  - "Aperçu pour le client": cover image, "35-45 min" badge, name, star "4.8", "Cuisine Traditionnelle • Sidi Bel Abbès".
- Declaration checkbox: "Je déclare que toutes les informations fournies sont exactes et conformes à la réalité juridique de mon établissement."
- Sticky footer: "Soumettre pour vérification" (`send`, `h-14 rounded-xl`), disabled at 50% until checked.

### Flutter mapping
- `/access/registration` step 4 → `_ReviewStep` / `_ReviewBlock` (`registration_screens.dart:1415–1580`).
- Current look: `audit/registration-lifecycle-acceptance/screenshots/live-review.png`.

### Differences
- No info banner; title "Révision" rendered as headline under shared "Inscription" app bar.
- Blocks: "Informations du commerce" (merchant name), "Documents d’entreprise" (text rows "Ajouté"/"Non fourni"), "Détails de l’établissement" (name, phone, address, raw "Coordonnées lat, lng"); no Propriétaire block, no chips grid, no map, no customer preview.
- "Modifier" as plain `TextButton` without icon.
- Missing-items list (real) shown instead of declaration; submit disabled until `verificationReady` and nothing missing.

### Contract
- Merchant name, evidence states, branch name/phone/address/lat-lng: SUPPORTED.
- Verified phone: SUPPORTED (session).
- Owner name: NOT SUPPORTED.
- Category: PARTIAL — admin-assigned classification (`PUT admin/merchant-branches/:branchId/classification`, `catalog/presentation/http/admin-merchant-branch-storefront.controller.ts:46–53`); not settable by merchant; may be empty pre-verification.
- Map preview: PARTIAL — app already has map config for the location picker (`access/data/map_config.dart`, `location_picker_screen.dart`); a static preview would reuse it when configured.
- Customer preview (ETA, rating, cover): NOT SUPPORTED pre-approval (ETA would be invented; ratings don't exist yet).
- Declaration: NOT SUPPORTED (not persisted); a client-only gate is a product/legal decision.
- Submit: SUPPORTED (`POST /merchant/:id/verification/submit`, OWNER only).

### Alternatives
- `store_information_french` preview is labelled "non publié" (`regPreviewLabel`).

### Required work (only if visuals not covered)
1. Info banner; section header rows with `edit` icon + "Modifier".
2. Documents as 2-col chip cards using real states.
3. Replace raw coordinates with wilaya/commune names (already on `MerchantBranch`) and, if map configured, a static preview.
4. Omit Propriétaire name, customer preview; add phone row under an honest heading.
5. `send` icon on CTA.

### Proposed status
`exception_approved` (state/routing). Visual coverage unresolved → otherwise `partial_contract_limited`.

---

## merchant_verification_approved_french

### Design
- Files readable, consistent.
- App bar fixed: `menu` + "SpeedyGo Merchant" (`headline-md` bold primary), `notifications`.
- Celebration: 96px `tertiary-fixed` circle with glow + filled `check_circle` tertiary 48px; "Félicitations !" (`headline-lg` primary); "Votre établissement est approuvé" (`title-md`); body "Pour commencer à recevoir des commandes, assurez-vous que votre magasin est ouvert, que vos horaires sont définis et que vos produits sont disponibles."
- Reference card: "RÉFÉRENCE MERCHANT", name (primary), "#SG-260803-1842", chip "Approuvé" (`tertiary-container` / `on-tertiary-container`, `verified`), divider, `person` "Amine Bensaïd — Gérant".
- "Étapes de configuration": nav cards `schedule` Horaires d'ouverture / "Configurez quand vous êtes ouvert", `inventory_2` Catalogue de produits / "Ajoutez vos premiers articles", `notifications_active` Alertes et notifications / "Restez informé des commandes".
- Info: "L'assistance SpeedyGo est disponible 24/7 pour vous accompagner dans votre lancement."
- Sticky CTA: "Accéder à l'accueil marchand →".

### Flutter mapping
- None. ACTIVE merchant → `needBranch` / `selectBranch` / `home` directly (`access_controller.dart:149–197`). Strings `verificationApprovedTitle`, `verificationApprovedBody`, `regApprovedNext` exist but are unused.
- Current look: `audit/registration-lifecycle-acceptance/screenshots/live-approved-home.png`.

### Differences
- No interstitial; user lands on Accueil.

### Contract
- Status ACTIVE + `verifiedAt` + `publicReference`: SUPPORTED (`/merchant/me`).
- "First time since approval": NOT in contract; would need a local seen-flag keyed by merchantId + `verifiedAt`.
- Setup shortcuts: routes exist (`/app/profile/hours`, `/app/catalog`, `/app/notifications/settings`).
- Person name: NOT SUPPORTED. "24/7 assistance": not verifiable → omit.

### Alternatives
- `SCREEN_MATRIX.md` row 10: "ACTIVE → existing home/branch flow (not Stitch congrats marketing)".

### Required work
- Product decision first (routing lives inside the approved exception). If approved: one-time interstitial with real reference card and three real shortcuts; no 24/7 claim.

### Proposed status
`exception_approved` (routing). Visual/interstitial decision unresolved → otherwise `partial_contract_limited`.

---

## merchant_verification_rejected_french

### Design
- Files readable, consistent.
- Header sticky `h-14 shadow-sm`: `speed` 28px + "SpeedyGo" (`headline-md` bold primary); "FR" (`title-lg` primary).
- Hero: 80px `error-container` circle, filled `assignment_late` 40px error; "Dossier à compléter" (`headline-md`); "Bonjour **Amine Bensaïd**, votre dossier pour **Dar El Benna** nécessite des corrections."; badge `surface-container-high rounded-xl`: "ID DE DEMANDE" / "#SG-260803-1842" / italic "Révisé le 22 juillet 2024".
- "POINTS À CORRIGER" + chip "2 Erreurs" (`error-container`); issue cards (white, `border-l-4 error`, `rounded-xl p-16`): icon + doc title, quoted reason in `surface-container-low` box, outlined action ("Remplacer le document" `cloud_upload` / "Modifier l'information" `edit_note`).
- "DOCUMENT VALIDÉ": `border-l-4 tertiary-fixed-dim` row "Pièce d’identité du gérant" — "Validée".
- Guidance `bg-surface-container rounded-xl`: "Ne vous inquiétez pas, les informations déjà approuvées ont été conservées. Vous n'avez qu'à rectifier les éléments signalés ci-dessus."
- "Besoin d'aide pour votre dossier ?" + underlined `support_agent` "Contacter le support".
- Sticky: "Corriger et soumettre" (`send`, `h-14 rounded-xl title-lg`), "Se déconnecter" (error text, `logout`).

### Flutter mapping
- `/verification/rejected` → `_LegacyVerificationBody(kind: verificationRejected)` (`access_screens.dart:589`); CTA "Modifier" → `openRegistrationCorrections()`.
- Current look: `audit/registration-lifecycle-acceptance/screenshots/live-rejected.png`.

### Differences
- Generic `MerchantScaffold` with title "Dossier à corriger"; card with merchant name, "À corriger" badge and **two stacked generic paragraphs** (`verificationRejectedBody` + `regRejectionNoReason`, redundant).
- Checklist of evidence states ("Ajouté") instead of per-item verdicts.
- Buttons: "Modifier" (filled), "Actualiser le statut" (outlined), "Se déconnecter" (text). No hero, no reference badge, no support link.

### Contract
- Rejection reason: NOT SUPPORTED — "No rejection reason field is accepted or persisted in v1.0" (`admin-merchant.controller.ts:146–150`, `merchant.controller.ts:142`).
- Per-document rejected/validated: NOT SUPPORTED (document statuses PENDING/SUBMITTED only).
- Error count chip: NOT SUPPORTED (derived from reasons).
- Public reference: SUPPORTED; "Révisé le" date: NOT SUPPORTED.
- Corrections + resubmit: SUPPORTED (PUT documents / PATCH profile editable while REJECTED; submit transitions REJECTED → PENDING_REVIEW).
- Support: SUPPORTED (OWNER/MANAGER), no client.

### Alternatives
- `merchant_verification_resubmission_french` designs the correction workspace that follows.
- `registration-lifecycle-acceptance/ACCEPTANCE_REPORT.md:64,103` — reason UX is a recorded product limitation.

### Required work (only if visuals not covered)
1. Hero (icon circle, "Dossier à compléter", greeting with merchant name only), reference badge (no date).
2. Single guidance paragraph (drop the duplicate).
3. Keep real checklist in place of "Points à corriger"; no invented reasons/counts.
4. "Contacter le support" link (after support screen exists).
5. Sticky "Corriger et soumettre" → corrections; "Actualiser le statut" secondary; "Se déconnecter" error text.

### Proposed status
`exception_approved` (state/routing). Visual coverage unresolved → otherwise `partial_contract_limited`.

---

## merchant_verification_resubmission_french

### Design
- Files readable. png: header right-side name/ID visible (html hides it below `sm`) — minor discrepancy.
- App bar: `arrow_back` + "Correction du dossier" (`title-lg` primary); trailing name/ID (sm+) + `notifications`.
- Intro: `info` + "Action requise" (`label-lg` primary); "Veuillez corriger les éléments signalés ci-dessous pour finaliser votre dossier. Votre établissement **Dar El Benna** sera activé après validation." (`body-lg`).
- Correction cards (white `rounded-xl p-16 border`): title with icon + "Refusé" chip (error); motif box `bg-error-container/20 border-l-4 error` "**Motif du refus :** …"; dashed dropzone (`border-2 dashed rounded-xl`, `cloud_upload` in `primary-container/10` circle, "Remplacer le document", "Format PDF, JPG ou PNG (Max 5Mo)"); NIF card with "VALEUR PRÉCÉDENTE" struck-through value + "Nouveau Identifiant Fiscal (NIF)" input.
- Summary card `bg-surface-container-high`: `history_edu` in primary circle, "Détails de l'établissement", "Propriétaire: …", "ID Application: …".
- Sticky: "Soumettre les corrections" (`send`), disabled until a change.

### Flutter mapping
- REJECTED → "Modifier" → `openRegistrationCorrections()` → `RegistrationHostScreen` (same 4-step wizard, "Inscription" title), then `_ReviewStep` "Soumettre pour vérification".
- Current look: `audit/registration-lifecycle-acceptance/screenshots/live-resubmit-review.png`.

### Differences
- No correction-mode presentation; identical to first-time registration (title, progress, copy).
- No motif, no "Refusé" chips, no previous value; document replacement uses the normal document cards.

### Contract
- Replace document / edit name / edit branch + resubmit: SUPPORTED.
- Motif du refus, per-item "Refusé": NOT SUPPORTED (see rejected).
- NIF value field: NOT SUPPORTED (no tax-id field in contract).
- Reference: SUPPORTED; owner name NOT SUPPORTED.

### Alternatives
- Overlaps `merchant_verification_rejected_french` ("Corriger et soumettre") and `business_document_upload_french` (replacement UI).

### Required work (only if visuals not covered)
1. When entering the wizard from REJECTED, show correction mode: app bar "Correction du dossier", "Action requise" intro with merchant name, summary card with public reference; submit copy "Soumettre les corrections".
2. Optional dashed dropzone style for replacements; keep real types and 10 MiB copy.
3. No motif/previous-value UI.

### Proposed status
`exception_approved` (state/routing). Visual coverage unresolved → otherwise `partial_contract_limited`.

---

## Unreadable / partially unreadable files

- `screens/MerchantScreens/merchant_onboarding_manage_business_unified/screen.png` — right ~60% renders blank (capture artifact); `code.html` used.
- All other 39 files readable. Recorded png/html discrepancies: notification settings test button (html only); splash logo/title (html only); settings bottom nav (html only); registration section backgrounds (png only); resubmission header identity (png shows, html hides < sm); language subtitle typo "Gisage" in both.

## Unresolved product decisions

1. Do the §7 registration/verification exceptions cover **visual styling** or only states/routing? (drives six statuses).
2. Approved interstitial: add a one-time "Félicitations" screen (local seen-flag) or keep direct routing?
3. Offer "العربية" in an in-app language screen before Arabic strings exist (RTL-only today)? Should the pre-auth `/language` screen (not listed in §3) follow this reference?
4. Inline "Accepter" from a notification card (role-gated; possible stale order).
5. Repeat-alert reminders and volume: new alert-engine behaviour or permanently omitted?
6. Non-persisted consent/declaration checkboxes as client-only gates (legal).
7. Support topic cards as body-prefill helpers (no category contract) or omitted.
8. Staff: any read-only "Mon accès" view beyond the existing settings role line? Roster requires a new members contract.
9. Settings under Profil is pushed on the root navigator (no bottom nav) while the reference shows the 5-tab bar.

## Cross-cutting findings (fix once)

- **App bar**: references disagree — settings uses centred 24/700 primary; logout 24/700 primary left; notification settings / review / resubmission / OTP use `title-lg` 20/600 primary with primary back icon; notifications / language / registration use on-surface titles; some add a bottom border. `MerchantScaffold` uses the theme default. Propose one `MerchantAppBar` with a primary `title-lg` default + optional centred-large variant, after a product call on the conflict.
- **Card**: references use `rounded-xl` 12px + `shadow-[0_2px_8px_rgba(0,0,0,0.04)]` with no border (settings, staff, logout) or `rounded-lg` 8px + `border outline-variant` for grouped setting lists. `MerchantCard` is radius 16 (`MerchantLayout.radiusCard`) + 55% outline border + elevation 1. Changing `radiusCard` to 12 and the shadow affects every batch — coordinate.
- **Section label**: uppercase `label-md` primary tracking-wider is re-implemented in `ProfileSettingsScreen._SectionCard` and `NotificationSettingsScreen._SectionLabel`; `MerchantSectionLabel` already exists in `merchant_ui.dart` — consolidate.
- **Status chip**: `StatusBadge` (radius 8, 10×6 padding, `labelLarge`) is larger than reference chips: small square chip (`rounded` 4px, `px-8 py-2`, `label-md`, e.g. "Désactivé") and pill chip (`rounded-full`, e.g. "Connecté", "Approuvé", "EN COURS"). Add both variants.
- **Buttons**: sticky CTAs are `rounded-full` h-48 (notification settings, language) vs `rounded-xl` h-52 (logout, registration, verification, OTP). `MerchantPrimaryButton` should expose the shape; conflict needs a product call. Destructive filled (logout) and destructive outlined (settings) variants missing.
- **Nav rows**: settings reference rows (outline icon, `body-lg`, chevron outline-variant, inset dividers `outline-variant/30`) — reuse `MerchantNavRow` with trailing value/badge slots.
- **Inputs**: registration inputs `h-12 rounded-xl border outline-variant`; locked variant `surface-container-low` + `lock`.
- **Tokens missing in `AppColors`**: `primaryFixed #d9e2ff`, `surfaceVariant #d9e2fc`, `secondaryContainer #94a6ff`, `onSecondaryContainer #24388b`, `tertiaryFixedDim #b7d15f`, `inverseSurface #273044`, `surfaceContainerHighest #d9e2fc`. Hex literals in `access_screens.dart` (`0xFFD9E2FF`, `0xFFE1E8FF`) and `registration_screens.dart` (`0xFFD9E2FC`, `0xFFF1F3FF`, `0xFFD9E2FF`) should use tokens.
- **Bottom nav**: only settings/language references show it; Flutter pushes all settings-area screens on the root navigator (no nav) — keep consistent once decided.
- **Person name**: references show an owner/person name on settings, logout, support, pending, approved, rejected, review, resubmission. No contract exists (`Account` has phone/e-mail only) — always substitute merchant/branch name.
- **Dead/misleading strings**: unused `profileSectionOps/Prefs/Support`, `profileUnavailableItem`, `verificationApprovedTitle/Body`, `regApprovedNext`, `verificationPendingBody`; misleading `storeProfileSettingsSub` ("Sécurité, langue, déconnexion").
- **Localization**: all `AppStrings` are French; Arabic only flips direction.
