# Merchant parity, third-pass live review (2026-10-01)

**Status: `implementer_reviewed`. Nothing is visually accepted.** This package is for your review.

Each image has three panels: Stitch reference | live at text 1.0 | live at text 1.35.
- **Text 1.0** is iOS content size `large`; **text 1.35** is `extra-extra-extra-large`.
- **Devices:** iPhone 16e (390 pt) for the store screens; SE (375 pt) for registration and verification.
- **Data:** live local dev backend. Store screens use Dar El Bahja through a fresh memory-only session. Verification screens use isolated fixtures that were removed afterwards.

Optional captures, **NOT RUN**: the mark-ready confirmation, the CONFIRMED order detail and the store map have mocked evidence only.

| # | Image | Screen (Stitch reference) | Text scale | Remaining difference |
| --- | --- | --- | --- | --- |
| 1 | `live2_b2_order_detail.png` | Order detail, late (`delayed_order_french`) | 1.0, 1.35 | Late card only. Reason tiles and the delivery-impact block need a contract (D-B3). The −/+ editor is not built by decision (presets kept). |
| 2 | `live2_b3_category.png` | Category detail (`d_tails_de_la_cat_gorie_standardis`) | 1.0, 1.35 | No Arabic name (no field). |
| 3 | `live2_b3_variants.png` | Required variants (`required_variants_french`) | 1.0, 1.35 | Changes save immediately (no "Enregistrer les variantes"); no option drag reorder; no Arabic names. |
| 4 | `live2_b3_extras.png` | Optional extras (`optional_extras_french`) | 1.0, 1.35 | Same as variants. |
| 5 | `live2_b3_product_availability.png` | Product availability (`product_availability_french`) | 1.0, 1.35 | No temporary or scheduled availability, history or sync badge (no contract). |
| 6 | `live2_b3_reorder.png` | Reorder categories (`reorder_categories_french`) | 1.0, 1.35 | Saves with one call per moved category (no batch endpoint); no Arabic names. |
| 7 | `live2_b4_profile.png` | Store profile (`store_profile_french`) | 1.0, 1.35 | Logo is a placeholder (D-D3); no category subtitle (D-D2); no customer preview or owner name; "Informations générales" opens read-only settings (D-D1). Extra rows kept. |
| 8 | `live2_b4_address.png` | Contact and address (`store_contact_and_address_french`) | 1.0, 1.35 | No public contact or pickup instructions (no contract); no address search (D-D7). The phone helper uses truthful wording (drivers only). |
| 9 | `live2_b6_notifications.png` | Notification centre (`merchant_notification_center_french`) | 1.0, 1.35 | No Compte or Support filters or non-order types (no such notification types); no inline "Accepter" (D-B2); no help button. At 1.35 "Tout marquer comme lu" becomes an icon. |
| 10 | `live2_b6_notification_settings.png` | Notification settings (`order_notification_settings_french`) | 1.0, 1.35 | No volume slider, repeat reminder or test sound (D-G4). Lock-screen rows replaced by an OS-controlled note. |
| 11 | `live2_b7_pending.png` | Verification pending (`merchant_verification_pending_french`) | 1.0, 1.35 | No person name, "Prioritaire" tag, dates or 24–48 h promise (no contract). |
| 12 | `live2_b7_rejected.png` | Verification rejected (`merchant_verification_rejected_french`) | 1.35 only (1.0 panel is a placeholder) | No per-document refusal reasons, error count or inline replace actions (contract). The real checklist is shown instead. |
| 13 | `live2_b7_resubmission.png` | Correction (`merchant_verification_resubmission_french`) | 1.35 only (1.0 panel is a placeholder) | No refusal motifs, "Refusé" chips or previous/new values (contract). |
| 14 | `live2_b7_approved.png` | Approval screen (`merchant_verification_approved_french`) | 1.0, 1.35 | No menu or bell (no app shell yet); role instead of person name; a truthful "store not opened automatically" note replaces the 24/7 claim. |
| 15 | `live2_b7_approved_next.png` | Home after acknowledgement (`merchant_operational_dashboard_french`) | 1.0, 1.35 | New fixture merchant (closed, no orders). Not a parity target for this pass, only evidence of the onward routing. Known dashboard gaps: average time, insight card, amount format (D-C5). |

**Live checks recorded with the approval flow**, identical at both sizes:
- the dossier was seen as unapproved before the admin call;
- the notice survives a cold restart;
- acknowledgement routes to home;
- no notice appears after an acknowledged restart.

Also included: `MERCHANT_SCREEN_PARITY_MATRIX.md` (current matrix) and `DECISIONS.md` with `decision_crops/` (the unresolved decisions; none implemented).
