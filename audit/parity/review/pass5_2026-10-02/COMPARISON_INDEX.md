# Merchant parity comparison index

Side-by-side images: **reference** (Stitch `screen.png`, scaled to 780 px = 390 pt) | **mocked 390 pt, text 1.0** | **mocked 375 pt, text 1.35**. Mocked panels are full page height (the primary scroll view is unrolled), top-aligned and unscaled at 2×.

- **Evidence type:** every image in sections 1–7 is **mocked** (widget-test fixtures through the real screens, fake API). Live captures against the local dev backend are listed separately in "Live evidence" at the end, with their own images under `comparisons/live/`.
- **Fixture data:** representative, not copied from the references (names, amounts and times differ on purpose; times follow the test clock in the Branch timezone).
- **Regenerate:** `flutter test test/audit/parity/` then `python3 audit/parity/compose_batch.py` (optionally with a prefix such as `b2`).
- **Navigation context:** secondary screens are pumped above a blank route, as when pushed in the app, so their back arrow renders. Tab roots are pumped inside the real bottom navigation.
- **Status:** "compared" means the implementer reviewed the pair. It is not visual acceptance.

## 1 · Shell, dashboard and navigation

| Comparison | Reference | State | Notes |
| --- | --- | --- | --- |
| [b1_dashboard_populated](comparisons/b1_dashboard_populated.png) | `merchant_operational_dashboard_french` | Home, verification banner, 2 incoming / 3 preparing / 1 ready, 2 unread | KPIs from TODAY sales summary. Empty state: `mocked/b1_dashboard_empty_*.png` (no reference). |

## 2 · Orders, preparation, ready and driver states

| Comparison | Reference | State | Notes |
| --- | --- | --- | --- |
| [b2_orders_active_incoming](comparisons/b2_orders_active_incoming.png) | `active_orders_list_french` | En cours · Nouveaux (2), OWNER | Search and filter chips omitted (no contract). Fourth pass (D-B2): "Accepter" and ✕ on CREATED cards for OWNER/MANAGER only; STAFF keeps "Traiter". Both reuse the detail's validated accept/reject flows after a fresh state and role check. |
| [b2_orders_active_preparing](comparisons/b2_orders_active_preparing.png) | `active_orders_list_french` (hidden preparing card) | En cours · En prép. (on time + late) | "Prête vers HH:mm" / "En retard" from the server estimate. |
| [b2_orders_history](comparisons/b2_orders_history.png) | `merchant_order_history_unified` | Historique · Terminées (default), today + yesterday | "Tout" and search omitted (single-status API). Yesterday rows keep the clock time instead of the reference's "Hier" label. |
| [b2_incoming_alert](comparisons/b2_incoming_alert.png) | `incoming_order_alert_french` | Alert overlay, OWNER | Countdown, Urgent and logo row omitted. |
| [b2_detail_incoming](comparisons/b2_detail_incoming.png) | `incoming_order_details_french` | CREATED + PENDING_ACCEPTANCE, OWNER | |
| [b2_accept_sheet](comparisons/b2_accept_sheet.png) | `accept_order_and_preparation_time_french` | Accept sheet over incoming detail, 25 min selected | No "Recommandé" tile (no server source); Annuler instead of Refuser in the sheet footer. |
| [b2_detail_confirmed](comparisons/b2_detail_confirmed.png) | `commande_en_pr_paration_tat_initial` | CONFIRMED + ACCEPTED, 24:54 remaining, OWNER (third pass) | "Commencer la préparation" shown, no mark-ready action. |
| [b2_detail_preparing](comparisons/b2_detail_preparing.png) | `commande_en_pr_paration_en_cours` | ACTIVE + PREPARING, 11:40 remaining | |
| [b2_mark_ready_confirm](comparisons/b2_mark_ready_confirm.png) | `mark_order_ready_french` | Confirmation page after "Marquer comme prête", 3 items (third pass) | Packing list shows only the order's items; no checkboxes, note or "Couverts & Serviettes" row (no contract). Confirm always enabled; Retour changes nothing. |
| [b2_update_sheet](comparisons/b2_update_sheet.png) | `mise_jour_du_temps_de_pr_paration` | Update sheet, +10 selected (top of the sheet) | Notification note omitted (backend does not notify). The "→" in the caption shows as a box only in the test font. |
| [b2_update_sheet_reason](comparisons/b2_update_sheet_reason.png) | `mise_jour_du_temps_de_pr_paration` (and the `delayed_order_french` reason tiles) | Same sheet scrolled to the reason, "Forte affluence" tapped (fourth pass) | D-B3: the 2×2 tiles only prefill the existing editable free-text "Motif" (`reason`, max 255); "Autre raison" clears it and focuses the field. No structured category is sent and no notification is claimed. The 5/10/15/20 presets are unchanged. The test checks that the field ends above the footer. |
| [b2_detail_preparing_late](comparisons/b2_detail_preparing_late.png) | `delayed_order_french` | ACTIVE + PREPARING, 8 min late | Partial. Fourth pass: countdown card first, then a compact customer/payment block; "Heure prévue : …" instead of "Prête le …" while the order is not ready. Delivery impact not built (no contract); −/+ editor not built (presets kept by decision). |
| [b2_detail_preparing_late_days](comparisons/b2_detail_preparing_late_days.png) | `delayed_order_french` | ACTIVE + PREPARING, 2838 min late (the live case) | Second pass: reads "1 j 23 h de retard"; the estimate line gives the day ("Prête le dd/MM à HH:mm (heure locale)"); the title wraps at 1.35. |
| [b2_detail_ready_searching](comparisons/b2_detail_ready_searching.png) | `waiting_for_driver_french` | READY + delivery SEARCHING_DRIVER | |
| [b2_detail_ready_to_pickup](comparisons/b2_detail_ready_to_pickup.png) | `driver_assigned_call_action_at_bottom` | READY + delivery TO_PICKUP (third pass) | Partial: "Livreur en route" status only. Driver identity, call action and ETA omitted (no contract). |
| [b2_detail_ready_at_pickup](comparisons/b2_detail_ready_at_pickup.png) | `driver_arrived_french` | READY + delivery AT_PICKUP | Driver card / handoff not supported. |
| [b2_detail_completed](comparisons/b2_detail_completed.png) | `d_tails_de_la_commande_finance_transparente` | COMPLETED + delivery DELIVERED, OWNER | |
| [b2_detail_cancelled](comparisons/b2_detail_cancelled.png) | `cancelled_order_french` | CANCELLED by customer | |
| [b2_support_form](comparisons/b2_support_form.png) | `signaler_un_probl_me_standardis` | New ticket form, OWNER | Category selector and photo proof omitted (no contract). |

## 3 · Catalogue

| Comparison | Reference | State | Notes |
| --- | --- | --- | --- |
| [b3_products](comparisons/b3_products.png) | `liste_des_produits_standardis_e` | Produits tab, 5 products (1 out of stock), OWNER | Fixture products have no photo (placeholder thumb). No hamburger (no drawer); bulk entry is the header checklist icon. |
| [b3_product_menu](comparisons/b3_product_menu.png) | `liste_des_produits_menu_ouvert` | Menu open on the first product | "Dupliquer" omitted (no contract); "Supprimer" instead of "Archiver / Supprimer". |
| [b3_categories](comparisons/b3_categories.png) | `liste_des_cat_gories_standardis_e` | Catégories tab, 4 categories (1 hidden) | Real product counts. No Arabic names; category filter button omitted. |
| [b3_category_detail](comparisons/b3_category_detail.png) | `d_tails_de_la_cat_gorie_standardis` | Category with 3 products | |
| [b3_category_detail_end](comparisons/b3_category_detail_end.png) | same | 8 products, 667 pt viewport with a 34 pt home-indicator inset, scrolled to the end (fourth pass) | Mocked panels show the scrolled viewport, not the full page. The first check found the last row overlapping the FAB at 1.35 (row bottom 575.5, FAB top 569); the list's bottom padding now includes the system inset. The test checks the last row ends at least 8 pt above the FAB. |
| [b3_products_end](comparisons/b3_products_end.png) | `liste_des_produits_standardis_e` | Produits tab inside the shell, scrolled to the end (fourth pass) | Viewport capture. The test checks the last row ends above the FAB and the FAB above the bottom navigation. At 1.35 on 375 pt the sticky header leaves a small list area. |
| [b3_category_editor](comparisons/b3_category_editor.png) | `modifier_la_cat_gorie_standardis` | Edit visible category, OWNER | Arabic name / description shown as unavailable (no contract). |
| [b3_reorder](comparisons/b3_reorder.png) | `reorder_categories_french` | Unchanged order (save disabled) | |
| [b3_filters](comparisons/b3_filters.png) | `product_search_and_filters_french` | Plats traditionnels + En stock selected | No units or translation filters (no contract). |
| [b3_product_detail](comparisons/b3_product_detail.png) | `d_tails_du_produit_standardis` | Product with 1 required + 1 optional group | Reference PNG is a broken desktop render; compare with its HTML. No short ID, Arabic fields, unit or prep time. |
| [b3_editor_edit](comparisons/b3_editor_edit.png) | `modifier_le_produit_standardis_image_corrig_e` | Edit available product, 1 variant group + 1 extras group | Arabic, prep time and unit rows shown as unavailable (no contract). |
| [b3_editor_new](comparisons/b3_editor_new.png) | `ajouter_un_produit_standardis` | New product | Variants / extras available after the first save. |
| [b3_image_crop](comparisons/b3_image_crop.png) | `product_image_upload_and_crop_french` | Crop step after picking a 900×700 synthetic image | Fixture image is a red/blue test pattern, not a photo. Copy says 2 Mo (contract), not 5 Mo. |
| [b3_availability](comparisons/b3_availability.png) | `product_availability_french` | Available product | Temporary / scheduled availability, history and sync badge omitted (no contract). |
| [b3_bulk](comparisons/b3_bulk.png) | `bulk_availability_french` | Nothing selected | |
| [b3_delete](comparisons/b3_delete.png) | `delete_product_logic_fixed` | Available product, hide option recommended | "Mettre en rupture" instead of "Archiver" (no archive contract). |
| [b3_variants](comparisons/b3_variants.png) | `required_variants_french` | 1 required group, 2 choices | **Explicit UX difference:** each confirmed sheet or switch saves immediately, while the reference has a bottom "Enregistrer les variantes" button. No decorative Save button was added; the draft/save proposal is in the matrix ("Variants and extras: save model"). No option drag reorder; no Arabic names. |
| [b3_extras](comparisons/b3_extras.png) | `optional_extras_french` | 1 optional group, 1 option disabled | Same deviations as variants (immediate save versus the reference's "Enregistrer les suppléments"). |

Not compared (no buildable design or no contract): `duplicate_product_french`, `selling_units_french`, root Arabic add-product design (pending decision).

Text 1.35 (second pass): long app-bar titles now wrap to up to 3 lines and the bar grows to fit, on the shared header and on order detail. Text scaling is not clamped by the app; Flutter's `AppBar` itself caps title scaling at 1.34.

## 4 · Store profile

Test clock: Wednesday 30 Sep 2026, 12:10 Africa/Algiers. Fixture hours 11:00–23:00 (Saturday until 23:30), Friday 11:00–14:30 · 18:00–23:30; 6 active orders.

| Comparison | Reference | State | Notes |
| --- | --- | --- | --- |
| [b4_profile](comparisons/b4_profile.png) | `store_profile_french` | Profil tab, OWNER, saved cover, branch ACTIVE | Hero shows the saved cover (fixture is a synthetic banded JPEG, not a photo). Logo tile is a placeholder, no category subtitle, no Aperçu client / owner name / call (no contract). Extra rows kept. |
| [b4_hours](comparisons/b4_hours.png) | `horaires_d_ouverture_pur` | OWNER, open now, Friday with two ranges | Week starts on Monday (D-D6), the reference on Sunday. Exceptional hours omitted (no contract). At 1.35 each range goes on its own line. |
| [b4_availability](comparisons/b4_availability.png) | `store_availability_control_french` | Selon les horaires, open, 6 active orders | Cards stacked per the HTML mobile layout. Owner name, session ID and FR action omitted. |
| [b4_temporary](comparisons/b4_temporary.png) | `temporary_closure_french` | Default reason, 30 min reopen | Kitchen image is the Stitch asset bundled locally. No "Demain à l’ouverture" option (D-D5 open). |
| [b4_cover](comparisons/b4_cover.png) | `store_logo_and_cover_french` | Saved cover, nothing new picked (save disabled) | Logo section omitted (no contract). Fixture cover is synthetic. |
| [b4_address](comparisons/b4_address.png) | `store_contact_and_address_french` | Wilaya 22 / commune 2201, location confirmed | Map tiles are blank in widget tests. Phone helper states that only drivers see the number. Title wraps (2 lines at 390, 3 at 375/1.35). |

| [b4_map](comparisons/b4_map.png) | `store_map_location_french` | Location picker at the branch coordinates (third pass) | Partial: no address search, storefront photo, pickup hint or owner footer (no contract). Map tiles are blank in widget tests. Re-captured with real shadows; the first image showed black outlines because flutter_test disables shadows by default. |
| [b4_general](comparisons/b4_general.png) | `store_information_french` | "Informations générales", OWNER, unchanged (save disabled) (fourth pass) | D-D1, partial: only the branch name is editable (OWNER/MANAGER, PATCH branch `name`); the verified merchant name is read-only with a lock; STAFF sees both read-only. Arabic name, description, e-mail, customer preview and step header omitted (no contract); the phone stays in "Adresse et Emplacement". |

Not compared: `store_category_selection_french` and `horaires_exceptionnels_format_24h` (no contract), `store_address_french` (duplicate), `merchant_information_french` (registration exception).

## 5 · Reports

Fixture: the existing contract fixture (`test/features/sales_report_fixtures.dart`), which reuses the reference's totals (18 orders, 42 300 DZD gross, 7 % commission); top products differ. Ratings 4.6 / 37, one finalized and one draft settlement.

| Comparison | Reference | State | Notes |
| --- | --- | --- | --- |
| [b5_overview](comparisons/b5_overview.png) | `merchant_reports_overview_french` | OWNER, Aujourd’hui, hourly trend | Bars kept instead of the curve (documented decision). Panier moyen fills the empty 4th KPI slot; Temps prép. moy. is "—" (not tracked). Ratings and settlements sections are extra (supported). The settlement date arrow renders as a box only in the test font. |
| [b5_top_products](comparisons/b5_top_products.png) | `popular_products_french` | OWNER, Aujourd’hui, sorted by orders, rank 4 deleted from catalogue | No product photos or search (no contract). Title kept as "Top produits". Fourth pass (D-A6): for OWNER/MANAGER, rows with a catalogue product show a chevron and open the product editor (also on the overview's top-products section). STAFF gets no chevron or editor route, and the deleted rank 4 stays non-interactive. |

Not compared: `sales_summary_french` (duplicate of the overview), `daily_summary_french` (no contract for its unique blocks).

## 6 · Notifications, settings, support, staff

Test clock: Wednesday 30 Sep 2026, 13:00 Africa/Algiers. Merchant "Dar El Benna" (OWNER), 3 orders in preparation, store open unless stated.

| Comparison | Reference | State | Notes |
| --- | --- | --- | --- |
| [b6_settings](comparisons/b6_settings.png) | `merchant_settings_french` | OWNER, single branch, push not configured | Header shows the merchant name and role (no owner name). Sécurité, Gestion de l’équipe, Horaires exceptionnels, Zone de livraison, Langue (D-G3) and legal rows omitted (no route or contract). "Désactivé" appears only when OS permission is denied. |
| [b6_logout](comparisons/b6_logout.png) | `merchant_logout_french` | 3 active orders, store open | Warning, counts and handover advice come from the real order counts and availability. Calm state (no orders, store closed, no warning): `mocked/b6_logout_calm_*.png`. |
| [b6_support](comparisons/b6_support.png) | `merchant_support_french` | 2 active tickets (order-linked + general), 1 resolved | Tickets are titled by type (the contract has no subject). Fourth pass (D-G6): the 2×2 "Sujets fréquents" tiles open the compose sheet with an editable prefix in the message body. Only `body` is sent: no ticket category or subject exists in the contract. FAQ banner omitted. Ticket detail (no reference): `mocked/b6_support_ticket_*.png`. |
| [b6_notifications](comparisons/b6_notifications.png) | `merchant_notification_center_french` | 2 unread today (order, settlement), 1 read yesterday | Only Tout / Commandes filters (real types). No "Accepter" (acceptance requires the prep-time flow) and no help FAB. When the title and the text action don't both fit (measured by width, e.g. at 1.35), "Tout marquer comme lu" becomes an icon button with the same tooltip and semantics, so it stays visible and reachable. |
| [b6_notification_settings](comparisons/b6_notification_settings.png) | `order_notification_settings_french` | Push configured, authorized, device registered | Extra "Dans l’application" toggle (real preference). Volume and repeat reminder omitted (D-G4); test sound omitted (no capability); lock-screen/preview rows replaced by the OS note. Title wraps at 1.35. Fourth pass: shorter explanations that keep three things distinct: in-app alerts (only while the app is open), the iOS permission, and native push (APNs/FCM, not configured). |

Not compared: `merchant_language_french` (D-G3 open, no in-app route), `staff_and_account_access_french` (no roster contract; staff management out of scope).

## 7 · Registration and verification

Merchant "Dar El Benna" (OWNER), reference `sgm_01a0f3306fa976c4a954d2a26f7a7137` (the real long format, shown compact as `sgm_01a0f3…7a7137` with a full view and copy sheet), branch in Alger Centre with a confirmed position. Visuals follow the references per D-G1; server state, routing and submission rules are unchanged.

| Comparison | Reference | State | Notes |
| --- | --- | --- | --- |
| [b7_registration](comparisons/b7_registration.png) | `merchant_registration_french` | New account, no role chosen yet | Owner name, e-mail field and consent checkbox omitted (no contract / D-G5); consent shown as a note. No back arrow on step 1. |
| [b7_documents](comparisons/b7_documents.png) | `business_document_upload_french` | Identity attached, registration missing, supporting absent | SpeedyGo evidence categories instead of RC/NIF/ID; no sequential lock or thumbnail. Brand tile uses the real logo asset. At 1.35 "+ Ajouter" moves under the title. |
| [b7_review](comparisons/b7_review.png) | `merchant_verification_review_french` | All required documents attached, ready to submit | Owner name, category, map and customer preview omitted (no contract); declaration checkbox omitted (D-G5). |
| [b7_pending](comparisons/b7_pending.png) | `merchant_verification_pending_french` | Submitted, documents in review, optional document absent | Headline is the merchant name. No "Prioritaire", dates or SMS promise (no contract). Adds the real "Pièces du dossier" checklist. "Contacter le support" opens the support compose sheet (OWNER/MANAGER). |
| [b7_rejected](comparisons/b7_rejected.png) | `merchant_verification_rejected_french` | REJECTED, one required document missing | Real checklist with states instead of per-document refusal reasons and error count (contract proposal in the matrix). "Corriger et soumettre" opens the existing correction flow. |
| [b7_resubmission](comparisons/b7_resubmission.png) | `merchant_verification_resubmission_french` | REJECTED, corrections complete, review step | Correction mode of the review step. No refusal motifs, "Refusé" chips or previous values (no contract). |

| [b7_approved](comparisons/b7_approved.png) | `merchant_verification_approved_french` | Server approved after this installation saw the dossier pending; branch exists | D-G2 (second pass). Real name, compact reference, role and "Approuvé" badge. Horaires / Catalogue / Alertes links open the real screens. A truthful "the store is not opened automatically" note replaces the 24/7 claim; no menu or bell. |
| [b7_approved_need_branch](comparisons/b7_approved_need_branch.png) | same | Approved, no branch yet | Links disabled with "Disponible après l’ajout d’un établissement"; the CTA reads "Ajouter un établissement" and resumes server routing. |
| [b7_pending_top](comparisons/b7_pending_top.png) · [b7_pending_end](comparisons/b7_pending_end.png) | `merchant_verification_pending_french` | Device viewport (844 pt at 1.0, 667 pt at 1.35, 34 pt inset), top and scrolled to the end (fourth pass) | The test checks that the guidance box ends above the sticky "Actualiser" footer, the footer sits above the inset, and a tap on the guidance box reaches it. The reference has no scrolled state, so the end panel is compared with the reference's lower half. |
| [b7_approved_top](comparisons/b7_approved_top.png) · [b7_approved_end](comparisons/b7_approved_end.png) | `merchant_verification_approved_french` | Same viewports (fourth pass) | Same checks with the approval note and "Accéder à l’accueil marchand". At 1.35 the CTA label wraps to two lines and looks tight. |

Splash, onboarding, phone login and OTP are previously approved exceptions and were not changed.

## Second pass (2026-09-30) · live defects and D-G2

Mocked only. The changed screens were re-captured with `flutter test test/audit/parity/` and recomposed; the images linked in sections 2–7 are the new ones. The pre-change comparisons are archived, unchanged, in `comparisons/previous_pass/` (14 images: `b2_detail_preparing`, `b2_detail_preparing_late`, `b3_availability`, `b3_category_detail`, `b3_extras`, `b3_reorder`, `b3_variants`, `b4_address`, `b4_profile`, `b6_notification_settings`, `b6_notifications`, `b7_pending`, `b7_rejected`, `b7_resubmission`).

| Live finding | Fix | Mocked evidence |
| --- | --- | --- |
| Long `sgm_<32 hex>` references wrap in the pending card, rejected badge and correction summary | Compact reference; tapping opens a sheet with the full value and a copy action; screen readers get the full value | [b7_pending](comparisons/b7_pending.png), [b7_rejected](comparisons/b7_rejected.png), [b7_resubmission](comparisons/b7_resubmission.png) |
| "2838 min de retard" | French duration ("1 j 23 h de retard"); dated estimate when it is not today in the branch timezone | [b2_detail_preparing_late_days](comparisons/b2_detail_preparing_late_days.png) (new), [b2_detail_preparing_late](comparisons/b2_detail_preparing_late.png) |
| App-bar titles truncated at 1.35 (and address at 1.0) | Titles wrap to up to 3 lines; the bar grows | [b2_detail_preparing](comparisons/b2_detail_preparing.png), [b3_category_detail](comparisons/b3_category_detail.png), [b3_extras](comparisons/b3_extras.png), [b3_variants](comparisons/b3_variants.png), [b3_availability](comparisons/b3_availability.png), [b3_reorder](comparisons/b3_reorder.png), [b4_address](comparisons/b4_address.png), [b6_notification_settings](comparisons/b6_notification_settings.png) |
| "Tout marquer comme lu" clipped | Correction: the first-pass finding was a misread of the downscaled comparison sheet; the raw live screenshot shows the full label. The text/icon switch is now decided by measured width, and a test checks that the action stays visible and tappable in every variant | [b6_notifications](comparisons/b6_notifications.png) |
| Grey band under the store cover | The gradient scrim was taller than the cover; it is now limited to the cover | [b4_profile](comparisons/b4_profile.png) |
| No approval screen (D-G2) | Implemented | [b7_approved](comparisons/b7_approved.png), [b7_approved_need_branch](comparisons/b7_approved_need_branch.png) (new) |

D-G5 (terms and declaration consent) is explicitly deferred: no client-only checkbox was added and no consent is recorded. The contract proposal is in `docs/MERCHANT_SCREEN_PARITY_MATRIX.md`.

**Live re-capture of these screens: done on 2026-10-01.** See "Third-pass live status" at the end of the live section.

## Fourth pass (2026-10-01) · visual corrections and scoped decisions

**Mocked only.** No simulator, no live backend. Status: `implementer_reviewed`; nothing is user-accepted. All 7 batch capture suites were re-run (220 tests) and all 65 comparisons recomposed, so every mocked panel reflects the current formatter and layout. Rows changed in this pass are annotated "Fourth pass" in sections 2–7.

- **Whole amounts (D-C5, Merchant only):** amounts in whole dinars print without ",00" ("42 300 DZD"), and fractional amounts keep their centimes ("2 200,50 DZD", "0,01 DZD"). The formatter stays integer-based (`BigInt`, no floats). Customer's formatter was not changed.
- **New scrolled and viewport captures:** `b2_update_sheet_reason`, `b3_category_detail_end`, `b3_products_end`, `b7_pending_top` / `_end`, `b7_approved_top` / `_end`. These are viewport-sized, not full-page, so lower sections are shown as they actually appear above the sticky footer, FAB and navigation. Each is backed by a geometric assertion in its test, not inferred from the image.
- **New screen:** `b4_general` (D-D1).
- **Live evidence for the changed rows predates this pass.** For example, `live2_b2_order_detail` still shows "Prête le …", and `live_b2_orders` has no inline actions. The live images were not re-captured and are unchanged.
- **Still NOT RUN:** the rejected and correction captures at normal size, and the three optional live captures (mark-ready confirmation, CONFIRMED detail, store map).

## Live evidence (separate from mocked)

**Status (first pass): captured on 2026-09-30** against the local dev backend (API on 3000, `speedygo_dev`). Implementer-reviewed; this is not visual acceptance.

Images: **reference** | **LIVE t1.0** | **LIVE t1.35**. Live panels are real simulator screenshots of one viewport (status bar included, not unrolled like the mocked panels). iPhone 16e captures (@3×) are scaled to 780 px; SE captures stay at 750 px (375 pt @2×). Raw screenshots are in `live/`. Regenerate the images with `python3 audit/parity/live/compose_live.py`.

### Provenance

| Run | Device | Session | Text size | Result |
| --- | --- | --- | --- | --- |
| Batches 1–6, `live_t100` | iPhone 16e `8DB9007A…` (390 pt) | Dar El Bahja session already stored on the device, used read-only by decision (the device keeps a preserved session). Logout screen opened, never confirmed; session not revoked. | `large` (1.0) | 26 shots, test passed |
| Batches 1–6, `live_t135` | same | same | `extra-extra-extra-large` (≈1.35) | 26 shots, test passed |
| Batch 7, `live_t100` | "SpeedyGo Reports SE (isolated)" `E6EF4B1F…` (375 pt) | Dedicated OTP session for fixture `+213550000095`, held in memory only (test overrides of the session, context, launch and push-token stores), revoked by logout in each phase. The SE's own stored session was never read or cleared. | `large` | 6 shots, both phases passed |
| Batch 7, `live_t135` | same | Fixture `+213550000096`, same isolation | `extra-extra-extra-large` | 6 shots, both phases passed |

- **Bundle check:** before the first screenshot of every run, the installed and running app was verified as `com.speedygo.speedygoMerchantApp` ("Speedygo Merchant App"): `live/BUNDLE_live_t100.txt`, `BUNDLE_live_t135.txt`, `BUNDLE_live_t1*_b7_register.txt`, `BUNDLE_live_t1*_b7_rejected.txt`. Step logs: `live/PROVENANCE_*.json`.
- **B7 on the SE, not the 16e:** the 16e holds a preserved Merchant session. A temporary 16e simulator nearly filled the disk during first boot and was deleted (only that simulator was touched). B7 panels are therefore 375 pt wide.
- **Admin step (B7):** the dev admin (`merchants.verify` only) rejected each fixture through `POST /admin/merchants/:id/verification/reject` (HTTP 201). Each admin session was revoked right after (HTTP 200).
- **Sessions:** all 243 session rows that existed before the runs are unchanged (same IDs, same revocation state). Every session created by the runs is revoked, and the fixture and admin rows were removed afterwards (see cleanup).

### Batch 1 · Dashboard

| Comparison | Reference | Live notes |
| --- | --- | --- |
| [live_b1_home](comparisons/live/live_b1_home.png) | `merchant_operational_dashboard_french` | Real counts (0 new, 0 preparing, 1 ready) and sales of the day. The "Vérification à finaliser" banner comes from the server flag `verificationAttentionRequired`. |
| [live_b1_home_end](comparisons/live/live_b1_home_end.png) | same | Identical to the first capture: the live dashboard fits in one viewport at 1.0. |

### Batch 2 · Orders

| Comparison | Reference | Live notes |
| --- | --- | --- |
| [live_b2_orders](comparisons/live/live_b2_orders.png) | `active_orders_list_french` | "Nouveaux (0)" empty state; Acceptées 24, Prêtes 1. |
| [live_b2_order_detail](comparisons/live/live_b2_order_detail.png) | `delayed_order_french` | Accepted order two days old: the late counter reads "2838 min de retard" (see gaps). |
| [live_b2_order_detail_end](comparisons/live/live_b2_order_detail_end.png) | same | Financial breakdown (sous-total, commission 7 %, net commerçant) and status history from the server. |

### Batch 3 · Catalogue

| Comparison | Reference | Live notes |
| --- | --- | --- |
| [live_b3_catalog](comparisons/live/live_b3_catalog.png) | `liste_des_produits_standardis_e` | Real products; the fixture images are flat colour uploads. At 1.35 the stock toggle stacks under the name. |
| [live_b3_category](comparisons/live/live_b3_category.png) | `d_tails_de_la_cat_gorie_standardis` | "Plats", 3 products. |
| [live_b3_product](comparisons/live/live_b3_product.png) | `modifier_le_produit_standardis_image_corrig_e` | Couscous royal editor; last update date from the server. |
| [live_b3_variants](comparisons/live/live_b3_variants.png) | `required_variants_french` | Taille (Normale, Grande +200,00 DZD). |
| [live_b3_extras](comparisons/live/live_b3_extras.png) | `optional_extras_french` | Two extras, max 2. |
| [live_b3_product_availability](comparisons/live/live_b3_product_availability.png) | `product_availability_french` | — |
| [live_b3_reorder](comparisons/live/live_b3_reorder.png) | `reorder_categories_french` | 4 real categories. |
| [live_b3_bulk_availability](comparisons/live/live_b3_bulk_availability.png) | `bulk_availability_french` | — |

### Batch 4 · Store

| Comparison | Reference | Live notes |
| --- | --- | --- |
| [live_b4_profile](comparisons/live/live_b4_profile.png) | `store_profile_french` | Real cover; grey band between the cover and the identity card (see gaps). |
| [live_b4_hours](comparisons/live/live_b4_hours.png) | `horaires_d_ouverture_pur` | The fixture schedule has an extra 00:00–00:00 interval on every day; it is shown as stored. |
| [live_b4_availability](comparisons/live/live_b4_availability.png) | `store_availability_control_french` | "Selon les horaires", 25 active orders. |
| [live_b4_temporary](comparisons/live/live_b4_temporary.png) | `temporary_closure_french` | Warning uses the real active-order count. |
| [live_b4_cover](comparisons/live/live_b4_cover.png) | `store_logo_and_cover_french` | Logo editing shown as unavailable (no contract). |
| [live_b4_address](comparisons/live/live_b4_address.png) | `store_contact_and_address_french` | Title truncated at 1.0 and 1.35. |

### Batch 5 · Reports

| Comparison | Reference | Live notes |
| --- | --- | --- |
| [live_b5_overview](comparisons/live/live_b5_overview.png) | `merchant_reports_overview_french` | "Aujourd'hui": zero sales, "Aucune vente sur la période". |
| [live_b5_top_products](comparisons/live/live_b5_top_products.png) | `popular_products_french` | Empty state for today. |

### Batch 6 · Settings, notifications, support

| Comparison | Reference | Live notes |
| --- | --- | --- |
| [live_b6_settings](comparisons/live/live_b6_settings.png) | `merchant_settings_french` | Owner role, Actif. |
| [live_b6_notifications](comparisons/live/live_b6_notifications.png) | `merchant_notification_center_french` | Real "Nouvelle commande" notifications. First-pass note "clipped at 1.0" was wrong: the raw screenshot shows the full label close to the edge (1.0) and the icon button (1.35). |
| [live_b6_notification_settings](comparisons/live/live_b6_notification_settings.png) | `order_notification_settings_french` | Simulator notification permission not granted, reported as such. |
| [live_b6_support](comparisons/live/live_b6_support.png) | `merchant_support_french` | No tickets: empty state only. |
| [live_b6_logout](comparisons/live/live_b6_logout.png) | `merchant_logout_french` | Real warning (25 active orders, store open). Not confirmed. |

### Batch 7 · Registration and verification (fixture "Fixture Parité B7")

| Comparison | Reference | Live notes |
| --- | --- | --- |
| [live_b7_registration](comparisons/live/live_b7_registration.png) | `merchant_registration_french` | Verified phone from the OTP login. |
| [live_b7_documents](comparisons/live/live_b7_documents.png) | `business_document_upload_french` | Identity uploaded through the acceptance evidence picker (harmless PNG); registration missing. |
| [live_b7_review](comparisons/live/live_b7_review.png) | `merchant_verification_review_french` | Both required documents "Ajouté". At 1.35 the submit label wraps to two lines. |
| [live_b7_pending](comparisons/live/live_b7_pending.png) | `merchant_verification_pending_french` | Real submission; server status `PENDING_REVIEW`. The real reference is long (`sgm_<32 hex>`). |
| [live_b7_rejected](comparisons/live/live_b7_rejected.png) | `merchant_verification_rejected_french` | After the admin rejection. The reference wraps to two lines in the "ID DE DEMANDE" badge. |
| [live_b7_resubmission](comparisons/live/live_b7_resubmission.png) | `merchant_verification_resubmission_french` | Correction mode of the review step. |

Not captured live in this first pass: `merchant_verification_approved_french` (captured live in the third pass, see "Third-pass live status"), and the mocked-only states of sections 1–7 that the live fixtures don't reach (incoming alert, accept and update sheets, ready and driver states, completed and cancelled orders, filters, delete, image crop, category and product editors, product detail). These states have mocked evidence only.

### Gaps seen only in live evidence

*Historical (second pass, 2026-09-30):* these gaps were then fixed in mocked evidence and host tests but not yet re-verified live. **Superseded on 2026-10-01:** the third pass re-captured them live (see "Third-pass live status"). The first-pass images above are kept unchanged and still show the old behaviour.

- **Long references (B7):** the real dossier reference is `sgm_` + 32 hex characters. The mocked fixture used a short `SGM-260803`, so the mocked panels understated the wrap in the rejected badge and pending card. Fixed in mocked (compact reference, full view and copy; the mocked fixture now uses the long format).
- **Late counter (B2):** multi-day delays read in raw minutes ("2838 min de retard"). Fixed in mocked ("1 j 23 h de retard", dated estimate).
- **App-bar titles at 1.35:** truncated on order detail, category detail, supplements, product availability, reorder, address and notification settings. The address title is also truncated at 1.0. Fixed in mocked (wrap up to 3 lines).
- **Notifications (B6):** reported as "Tout marquer comme lu" clipped at 1.0. Withdrawn: misread of the downscaled sheet (see the B6 row). The switch is now width-based and covered by a test.
- **Store profile (B4):** grey band between the cover image and the identity card. Fixed in mocked (scrim limited to the cover).
- **Fixture data, not UI:** the 00:00–00:00 schedule interval and the flat-colour product images come from earlier test fixtures.

### Fixture cleanup (Batch 7)

Only rows created by these runs were removed, by explicit ID: `live/cleanup_parity_b7_fixtures.sql` (refuses outside `speedygo_dev` and aborts unless the row counts match the pre-cleanup scan).

| Fixture | Account | Merchant | Branch |
| --- | --- | --- | --- |
| `+213550000093` (aborted at the map step; its session was revoked) | `01a0f32c-f802-7763-94da-38eb3ba6dcf9` | `01a0f32d-2685-7149-bf31-8276284a4bac` | none |
| `+213550000095` (`FIXTURE_IDS_live_t100.json`) | `01a0f330-415c-7f34-a95e-7e94e634c6f1` | `01a0f330-6fa9-76c4-a954-d2a26f7a7137` | `01a0f331-4d6d-76d6-b0c3-b9077a32f7c2` |
| `+213550000096` (`FIXTURE_IDS_live_t135.json`) | `01a0f33d-0da4-7069-934a-dfcc38c43152` | `01a0f33d-3bc5-7162-8fd4-9b3132a18684` | `01a0f33d-deec-72c9-9167-2eed28f45499` |

- **Deleted:** 3 accounts, 3 merchants, 2 branches, 3 memberships, 6 evidence documents, 5 fixture sessions, 5 fixture devices, and the 2 revoked admin sessions with their 2 devices. The 6 stored evidence objects (plus their `.meta` files) under the dev storage root were deleted by object key.
- **Verified:** every table count equals the pre-Batch-7 snapshot except `audit_logs` (+2). The storage listing is identical to its snapshot (114 files). Dar El Bahja is still `ACTIVE`, and Finjan is untouched.
- **Kept:** the 2 `audit_logs` rows `merchant.verification.reject` for the deleted fixture merchants (audit records, no foreign key; earlier fixture cleanups also kept audit logs). OTP challenges live in Redis and expire by TTL; they were not touched.
- **Devices:** the app was uninstalled from the SE, which had no apps before. The SE's content size was restored to its previous value (`extra-extra-extra-large`), and the 16e's to `large`. Both simulators are shut down. The Finjan iPhone 17 Pro was never booted.


## Second-pass live status

**Not captured in the second pass: blocked by Docker.** The first-pass images under `comparisons/live/live_*.png` were left unchanged; the re-capture happened in the third pass (`live2_*`).

- **Blocker:** Docker Desktop's Linux VM stopped at 18:22 local time after "no space left on device" (Docker's own log). The old `com.docker.backend` processes (started 16:59) kept running without a VM. After the app exited (20:08), the authorised `open -a Docker` started no new app or VM, and `docker info` still gives no answer within a 20 s bound. The approved scoped recovery sent SIGTERM to the verified stale backend processes: the children (6277, 6278) exited, but the parent `com.docker.backend` (PID 6259) ignored two SIGTERMs (60 s wait each). Recovery stopped there without SIGKILL, so no VM was started.
- **Resume attempt (2026-10-01):** after a real reboot, Docker, Redis on 6381 and the API were healthy. The 1.0 run on the 16e stopped at its guard "no restored Merchant session on this device" before any screenshot, and nothing was revoked. The missing restored session is **unexplained**: a Dar El Bahja session is still active on the server, but that does not prove its credentials are still on the device. Live work then stopped because free space fell to 1.5–3 GB under memory pressure.
- **Effect (before the reboot):** the project Redis (`speedygo-redis`, host port 6381, the API's configured `REDIS_URL`) is unavailable, so the API cannot start (Redis `read ECONNRESET` on the last attempt). The native Postgres on 5433 is healthy and untouched. The Homebrew Redis on 6379 is a separate shared instance and was not used.
- **Not done in the second pass** (*historical*: all done in the third pass, except need-branch, which stays mocked only because the registration wizard always creates a branch):
  - iPhone 16e, read-only device session, `PARITY_ONLY` filter, prefix `live2_t100` / `live2_t135`: order detail, category, supplements, variants, product availability, reorder, address, store profile, notifications, notification settings.
  - SE (375 pt), isolated fixtures with in-memory sessions: pending, rejected and correction with the long reference; admin approval, approval screen, acknowledgement and routing; need-branch; both text sizes.
- **Fixtures and sessions:** none created in this pass, so there is nothing to clean up. No session was created or revoked, and no Docker configuration, volume or database data was touched.

## Third-pass live status (2026-10-01)

**Captured.** The run was paused at first: free disk was below 5 GB, and another project's `flutter run` held the Flutter SDK lock. It ran at 13:15–13:36, after the user closed that project, one simulator at a time.

Services were healthy: Docker 28.3.2, `speedygo-redis` on 6381, the API on 3000 (`/health` ok) and native Postgres 17 on 5433. Sessions were fresh OTP logins with every app store held in memory; the Keychain was never read or written. Each session was revoked by the app at the end of its run, so no fallback revocation was needed. Panels: Reference | LIVE2 t1.0 | LIVE2 t1.35. A size not captured in this pass shows a labelled placeholder.

| Comparison | Reference | Device | Notes |
| --- | --- | --- | --- |
| [live2_b2_order_detail](comparisons/live/live2_b2_order_detail.png) | `delayed_order_french` | 16e | Compact reference + copy; "2 j 19 h de retard" with the dated estimate; title wraps at 1.35. |
| [live2_b3_category](comparisons/live/live2_b3_category.png) | `d_tails_de_la_cat_gorie_standardis` | 16e | Title wraps at 1.35. |
| [live2_b3_variants](comparisons/live/live2_b3_variants.png) | `required_variants_french` | 16e | |
| [live2_b3_extras](comparisons/live/live2_b3_extras.png) | `optional_extras_french` | 16e | Title wraps at 1.35. |
| [live2_b3_product_availability](comparisons/live/live2_b3_product_availability.png) | `product_availability_french` | 16e | Title wraps at 1.35. |
| [live2_b3_reorder](comparisons/live/live2_b3_reorder.png) | `reorder_categories_french` | 16e | Title wraps at 1.35. |
| [live2_b4_profile](comparisons/live/live2_b4_profile.png) | `store_profile_french` | 16e | No grey band under the cover. |
| [live2_b4_address](comparisons/live/live2_b4_address.png) | `store_contact_and_address_french` | 16e | "Contact et Adresse du magasin" wraps to two lines at 1.35. |
| [live2_b6_notifications](comparisons/live/live2_b6_notifications.png) | `merchant_notification_center_french` | 16e | "Tout marquer comme lu" fits at 1.0; icon action at 1.35. |
| [live2_b6_notification_settings](comparisons/live/live2_b6_notification_settings.png) | `order_notification_settings_french` | 16e | Title wraps at 1.35. |
| [live2_b7_pending](comparisons/live/live2_b7_pending.png) | `merchant_verification_pending_french` | SE 375 | Compact reference at both sizes. |
| [live2_b7_rejected](comparisons/live/live2_b7_rejected.png) | `merchant_verification_rejected_french` | SE 375 | 1.35 only (rejected path ran at 1.35). |
| [live2_b7_resubmission](comparisons/live/live2_b7_resubmission.png) | `merchant_verification_resubmission_french` | SE 375 | 1.35 only. |
| [live2_b7_approved](comparisons/live/live2_b7_approved.png) | `merchant_verification_approved_french` | SE 375 | First live capture of the approval screen (D-G2). |
| [live2_b7_approved_next](comparisons/live/live2_b7_approved_next.png) | `merchant_operational_dashboard_french` | SE 375 | Home after acknowledgement (fixture merchant, closed, no orders). |

Approval checks, recorded in `live/PROVENANCE_live2_t1*_b7_approval.json`, were identical at both sizes:
- the dossier was observed unapproved before the admin call;
- the notice survived a cold restart;
- acknowledgement led to `home`;
- no notice appeared after an acknowledged cold restart.

**Fixture and session cleanup** used `live/cleanup_parity_live2_fixtures.sql`, by explicit ID. The script refuses outside `speedygo_dev` and aborts unless the row shape matches the pre-cleanup scan.
- **Deleted:**
  - 2 fixture accounts, merchants, branches and memberships, plus 4 documents;
  - the fixtures' 4 sessions and 4 devices;
  - the run's 2 Dar El Bahja sessions and 2 devices;
  - the 3 admin sessions and 3 devices;
  - the 4 evidence objects and their `.meta` files.
- **Verified:** the session table is back to 243 rows, Dar El Bahja's 159 active sessions are unchanged, and storage is back to 114 files.
- **Kept:** 3 `audit_logs` rows.
- **Simulators:** both are shut down at `large`; the Finjan iPhone 17 Pro was never booted.

## Fifth pass (2026-10-01 → 2026-10-02) · scoped corrections and live verification

Status: `implementer_reviewed`, pending visual acceptance. Mocked, live and fixture-write results are listed separately below. Details of each correction are in the matrix ("Fifth pass").

### Mocked (recomposed; all 68 mocked comparisons regenerated)

| Comparison | Reference(s) | What to check |
| --- | --- | --- |
| [b2_update_sheet](comparisons/b2_update_sheet.png), [b2_update_sheet_reason](comparisons/b2_update_sheet_reason.png) | `mise_jour_du_temps_de_pr_paration` | No summary line or arrow under the comparison card |
| [b2_orders_active_incoming](comparisons/b2_orders_active_incoming.png) | `active_orders_list_french` | Long name on its own line at 1.35, amount row below; reject button |
| [b2_delayed_detail](comparisons/b2_delayed_detail.png), [b2_delayed_update_flow_t100](comparisons/b2_delayed_update_flow_t100.png), [b2_delayed_update_flow_t135](comparisons/b2_delayed_update_flow_t135.png) | `delayed_order_french` + `commande_en_pr_paration_en_cours` / `mise_jour_du_temps_de_pr_paration` | PARTIAL, different composition (red note) |
| [b3_category_detail](comparisons/b3_category_detail.png), [b3_category_detail_end](comparisons/b3_category_detail_end.png) | `d_tails_de_la_cat_gorie_standardis` | FAB radius 12; olive switch track with check thumb |
| [b3_products](comparisons/b3_products.png), [b3_products_end](comparisons/b3_products_end.png) | `liste_des_produits_standardis_e` | Header scrolls with the list on SE at 1.35 |
| [b7_approved](comparisons/b7_approved.png), [b7_approved_top](comparisons/b7_approved_top.png), [b7_approved_end](comparisons/b7_approved_end.png) | `merchant_verification_approved_french` | Two-line CTA keeps ≥ 8 pt inner margins at 1.35 |

### Live read-only walk (`live4_*`, iPhone 16e, 1.0 and 1.35)

Panels: Reference | LIVE4 t1.0 | LIVE4 t1.35. Raw screenshots: `live/live4_t100_*`, `live/live4_t135_*`. Provenance: `live/PROVENANCE_live4_t1*.json`, `live/BUNDLE_live4_t1*.txt`.

| Comparison | Reference | Row |
| --- | --- | --- |
| [live4_b2_orders](comparisons/live/live4_b2_orders.png) | `active_orders_list_french` | 7 (no new orders during the walk; incoming cards are in the fixture run) |
| [live4_b2_order_detail](comparisons/live/live4_b2_order_detail.png), [live4_b2_order_detail_end](comparisons/live/live4_b2_order_detail_end.png) | `delayed_order_french` | 18 (PARTIAL) |
| [live4_b2_update_sheet](comparisons/live/live4_b2_update_sheet.png), [live4_b2_update_sheet_reason](comparisons/live/live4_b2_update_sheet_reason.png) | `mise_jour_du_temps_de_pr_paration` | 18 (PARTIAL; sheet opened, never confirmed). Superseded by `live5_b2_update_sheet*` (follow-up): these images still show the full reference and undated times. |
| [live4_b3_category](comparisons/live/live4_b3_category.png), [live4_b3_category_end](comparisons/live/live4_b3_category_end.png) | `d_tails_de_la_cat_gorie_standardis` | 31 |
| [live4_b4_profile](comparisons/live/live4_b4_profile.png) | `store_profile_french` | 46 |
| [live4_b4_general](comparisons/live/live4_b4_general.png) | `store_information_french` | 46 (D-D1) |
| [live4_b5_overview](comparisons/live/live4_b5_overview.png) | `merchant_reports_overview_french` | 3 |
| [live4_b5_top_products](comparisons/live/live4_b5_top_products.png) | `popular_products_french` | 6 (live capture of the empty state only; OWNER/MANAGER editor navigation is automated + mocked evidence, `b5_top_products`, not a live interaction) |
| [live4_b6_notification_settings](comparisons/live/live4_b6_notification_settings.png) | `order_notification_settings_french` | 59 |
| [live4_b6_support](comparisons/live/live4_b6_support.png) | `merchant_support_french` | 63 |

### Live fixture writes (`fx_*`, iPhone 16e, 1.0 and 1.35)

Panels: Reference | FX t1.0 | FX t1.35. Raw screenshots: `live/fx_t100_fx_*`, `live/fx_t135_fx_*`. Failed attempts are kept as `live/fx_t100_attempt*_*`. Provenance: `live/PROVENANCE_FIXTURE_fx_*.json`, `.run/fixture_orders_fx_*.json`, `.run/created_fx_*.json`.

| Comparison | Reference | Step |
| --- | --- | --- |
| [fx_fx_alert](comparisons/live/fx_fx_alert.png) | `incoming_order_alert_french` | Real alert for a fixture order, dismissed by its close button |
| [fx_fx_incoming](comparisons/live/fx_fx_incoming.png) | `active_orders_list_french` | Two fixture orders under "Nouveaux" |
| [fx_fx_accept_sheet](comparisons/live/fx_fx_accept_sheet.png) | `accept_order_and_preparation_time_french` | Accept from the list card |
| [fx_fx_after_accept](comparisons/live/fx_fx_after_accept.png) | `active_orders_list_french` | Accepted card left "Nouveaux" |
| [fx_fx_reject_sheet](comparisons/live/fx_fx_reject_sheet.png) | `active_orders_list_french` (closest) | Reject opened through the button's semantics tap action |
| [fx_fx_after_reject](comparisons/live/fx_fx_after_reject.png) | `active_orders_list_french` | List empty after reject |
| [fx_fx_branch_saved](comparisons/live/fx_fx_branch_saved.png) | `merchant_operational_dashboard_french` | Evidence: the editor closed, header shows the new name |
| [fx_fx_branch_reopened](comparisons/live/fx_fx_branch_reopened.png) | `store_information_french` | Fresh app instance shows the saved name; then restored |

### Fifth pass follow-up (2026-10-02): update-time sheet reference and dates

| Comparison | Kind | Reference(s) | What to check |
| --- | --- | --- | --- |
| [b2_update_sheet](comparisons/b2_update_sheet.png), [b2_update_sheet_reason](comparisons/b2_update_sheet_reason.png) | Mocked (recaptured) | `mise_jour_du_temps_de_pr_paration` | Same-day estimate: time only. The mock reference is short (`sgo_o1`), so it is shown unchanged. |
| [b2_delayed_update_days](comparisons/b2_delayed_update_days.png) | Mocked (new) | `delayed_order_french` + `mise_jour_du_temps_de_pr_paration` | Previous-day estimate: "le 30/09 à 18:14"; "le 30/09" under the current and proposed times (PARTIAL note) |
| [live5_b2_order_detail](comparisons/live/live5_b2_order_detail.png) | Live 16e, 1.0 + 1.35 | `delayed_order_french` | Context: late detail of the real 28/09 order (PARTIAL) |
| [live5_b2_update_sheet](comparisons/live/live5_b2_update_sheet.png) | Live 16e, 1.0 + 1.35 | `mise_jour_du_temps_de_pr_paration` | "COMMANDE sgo_01a0e8…a64cdc" with copy icon; "le 28/09 à 17:45"; 17:55 "le 28/09". At 1.35 the card continues below the fold. |
| [live5_b2_update_sheet_reason](comparisons/live/live5_b2_update_sheet_reason.png) | Live 16e, 1.0 + 1.35 | `mise_jour_du_temps_de_pr_paration` | Scrolled view; at 1.35 the proposed "le 28/09" is visible at the top |

Live provenance: `live/PROVENANCE_live5_t1*.json`, `live/BUNDLE_live5_t1*.txt`. The sheet was never confirmed; the order is still estimate version 1. Sessions were revoked by the app; the sessions and devices were then deleted by ID (`live/cleanup_parity_pass5_live5_sessions.sql`).
