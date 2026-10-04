"""Compose reference | mocked 390 | mocked 375@1.35 panels for a batch.

Usage: compose_batch.py b2   (prefix of the capture names below)
"""
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent

PAIRS = {
    'b1_dashboard_populated': 'merchant_operational_dashboard_french',
    'b2_orders_active_incoming': 'active_orders_list_french',
    'b2_orders_active_preparing': 'active_orders_list_french',
    'b2_orders_history': 'merchant_order_history_unified',
    'b2_detail_incoming': 'incoming_order_details_french',
    'b2_detail_preparing': 'commande_en_pr_paration_en_cours',
    'b2_detail_ready_searching': 'waiting_for_driver_french',
    'b2_detail_ready_at_pickup': 'driver_arrived_french',
    'b2_detail_completed': 'd_tails_de_la_commande_finance_transparente',
    'b2_detail_cancelled': 'cancelled_order_french',
    'b2_support_form': 'signaler_un_probl_me_standardis',
    'b2_incoming_alert': 'incoming_order_alert_french',
    'b2_accept_sheet': 'accept_order_and_preparation_time_french',
    'b2_update_sheet': 'mise_jour_du_temps_de_pr_paration',
    'b2_update_sheet_reason': 'mise_jour_du_temps_de_pr_paration',
    'b2_detail_preparing_late': 'delayed_order_french',
    'b3_products': 'liste_des_produits_standardis_e',
    'b3_product_menu': 'liste_des_produits_menu_ouvert',
    'b3_categories': 'liste_des_cat_gories_standardis_e',
    'b3_category_detail': 'd_tails_de_la_cat_gorie_standardis',
    'b3_reorder': 'reorder_categories_french',
    'b3_filters': 'product_search_and_filters_french',
    'b3_availability': 'product_availability_french',
    'b3_bulk': 'bulk_availability_french',
    'b3_delete': 'delete_product_logic_fixed',
    'b3_editor_edit': 'modifier_le_produit_standardis_image_corrig_e',
    'b3_editor_new': 'ajouter_un_produit_standardis',
    'b3_variants': 'required_variants_french',
    'b3_extras': 'optional_extras_french',
    'b3_category_editor': 'modifier_la_cat_gorie_standardis',
    'b3_product_detail': 'd_tails_du_produit_standardis',
    'b3_image_crop': 'product_image_upload_and_crop_french',
    'b4_profile': 'store_profile_french',
    'b4_hours': 'horaires_d_ouverture_pur',
    'b4_availability': 'store_availability_control_french',
    'b4_temporary': 'temporary_closure_french',
    'b4_cover': 'store_logo_and_cover_french',
    'b4_address': 'store_contact_and_address_french',
    'b5_overview': 'merchant_reports_overview_french',
    'b5_top_products': 'popular_products_french',
    'b5_daily_summary': 'daily_summary_french',
    'b5_daily_summary_end': 'daily_summary_french',
    'b6_settings': 'merchant_settings_french',
    'b6_logout': 'merchant_logout_french',
    'b6_support': 'merchant_support_french',
    'b6_notifications': 'merchant_notification_center_french',
    'b6_notification_settings': 'order_notification_settings_french',
    'b6_team_top': 'staff_and_account_access_french',
    'b6_team_end': 'staff_and_account_access_french',
    'b6_team_invite_sheet': 'staff_and_account_access_french',
    'b7_registration': 'merchant_registration_french',
    'b7_documents': 'business_document_upload_french',
    'b7_review': 'merchant_verification_review_french',
    'b7_pending': 'merchant_verification_pending_french',
    'b7_rejected': 'merchant_verification_rejected_french',
    'b7_resubmission': 'merchant_verification_resubmission_french',
    'b2_detail_preparing_late_days': 'delayed_order_french',
    'b2_detail_confirmed': 'commande_en_pr_paration_tat_initial',
    'b2_detail_ready_to_pickup': 'driver_assigned_call_action_at_bottom',
    'b2_mark_ready_confirm': 'mark_order_ready_french',
    'b4_map': 'store_map_location_french',
    'b7_approved': 'merchant_verification_approved_french',
    'b7_approved_need_branch': 'merchant_verification_approved_french',
    'b3_category_detail_end': 'd_tails_de_la_cat_gorie_standardis',
    'b3_products_end': 'liste_des_produits_standardis_e',
    'b7_pending_top': 'merchant_verification_pending_french',
    'b7_pending_end': 'merchant_verification_pending_french',
    'b7_approved_top': 'merchant_verification_approved_french',
    'b7_approved_end': 'merchant_verification_approved_french',
    'b4_general': 'store_information_french',
    'b8_logo_cover': 'store_logo_and_cover_french',
    'b8_hours_exceptions': 'horaires_exceptionnels_format_24h',
}


PARTIAL_DELAY = (
    'PARTIAL, different composition: the app shows the late state in the order '
    'detail and edits the time in the "Mise à jour du temps" sheet. '
    'Not built: delivery impact (no contract); −/+ editor (presets kept by decision).'
)

DELAY_DONE_NOTE = (
    'Implementer-reviewed: truthful delivery-impact card from server state '
    '(no invented delivery ETA minutes). −/+ editor still omitted (presets by decision).'
)

DAILY_SUMMARY_NOTE = (
    'Implementer-reviewed: Africa/Algiers daily-summary contract; breakdown, '
    'prep efficiency and cancellation motifs from persisted data; no fake prep target.'
)

TEAM_NOTE = (
    'Implementer-reviewed: persisted MerchantMember roster + phone-bound invitations '
    '(manual acceptCode, no SMS/email). Roles OWNER/MANAGER/STAFF only; merchant-wide '
    'branchScope. Stitch names/presence/role-split omitted (no contract).'
)

NOTES = {
    'b2_detail_preparing_late': DELAY_DONE_NOTE,
    'b2_detail_preparing_late_days': DELAY_DONE_NOTE,
    'b5_daily_summary': DAILY_SUMMARY_NOTE +
    ' UI fix 2026-10-04: title/date wrap at 1.35; sticky CTA two-line full label.',
    'b5_daily_summary_end': DAILY_SUMMARY_NOTE +
    ' End viewport; last content above sticky CTA.',
    'b8_logo_cover': (
        'Logo and cover from the server (synthetic fixtures). The preview card keeps '
        'its existing honest note instead of the reference rating/ETA (no contract).'
    ),
    'b8_hours_exceptions': (
        'PARTIAL by decision: one civil date per exception, saved and confirmed by '
        'the server one at a time (no date ranges, no "Ajouter à la liste" batch). '
        'The customer message is stored only; the Customer app does not show it yet.'
    ),
    'b6_team_top': TEAM_NOTE,
    'b6_team_end': TEAM_NOTE +
    ' End viewport; list bottom padding uses measured FAB height + margin + safe area '
    'so Résumé des rôles clears « Inviter un membre » at 1.35.',
    'b6_team_invite_sheet': TEAM_NOTE + ' Invite sheet shows shareable code (not "sent").',
}

# The duplicate_product_french screen.png is entirely black (0,0,0); its
# code.html, rendered at 390 pt in a 390 px iframe, is the visual reference.
HTML_REFERENCES = {
    'b8_duplicate': (
        'reference_renders/duplicate_product_french_code_html_w390.png',
        'Reference: duplicate_product_french (code.html render; PNG is black)',
        'Reference PNG unusable (all black); code.html render used. "Brouillon" maps '
        'to available=false. "Unités de vente" is shown as not managed (no contract).',
    ),
}

# Multi-reference comparisons: name -> (references, panels, note).
FLOWS = {
    'b2_delayed_detail': (
        ['delayed_order_french', 'commande_en_pr_paration_en_cours'],
        [
            'b2_detail_preparing_late_w390.png=Mocked late detail 390 t1.0',
            'b2_detail_preparing_late_w375_t135.png=Mocked late detail 375 t1.35',
        ],
        PARTIAL_DELAY,
    ),
    'b2_delayed_update_flow_t100': (
        ['delayed_order_french', 'mise_jour_du_temps_de_pr_paration'],
        [
            'b2_update_sheet_w390.png=Mocked sheet top 390 t1.0',
            'b2_update_sheet_reason_w390.png=Mocked sheet reason 390 t1.0',
        ],
        PARTIAL_DELAY,
    ),
    'b2_delayed_update_flow_t135': (
        ['delayed_order_french', 'mise_jour_du_temps_de_pr_paration'],
        [
            'b2_update_sheet_w375_t135.png=Mocked sheet top 375 t1.35',
            'b2_update_sheet_reason_w375_t135.png=Mocked sheet reason 375 t1.35',
        ],
        PARTIAL_DELAY,
    ),
    'b2_delayed_update_days': (
        ['delayed_order_french', 'mise_jour_du_temps_de_pr_paration'],
        [
            'b2_update_sheet_days_w390.png=Mocked previous-day sheet 390 t1.0',
            'b2_update_sheet_days_w375_t135.png=Mocked previous-day sheet 375 t1.35',
        ],
        PARTIAL_DELAY + ' Estimate from an earlier day: current and proposed times carry their date.',
    ),
}


def main() -> None:
    prefix = sys.argv[1] if len(sys.argv) > 1 else ''
    for shot, ref in PAIRS.items():
        if not shot.startswith(prefix):
            continue
        note = [f'--note={NOTES[shot]}'] if shot in NOTES else []
        subprocess.run(
            [
                sys.executable,
                str(HERE / 'compose.py'),
                shot,
                ref,
                *note,
                f'{shot}_w390.png=Mocked 390 t1.0',
                f'{shot}_w375_t135.png=Mocked 375 t1.35',
            ],
            check=True,
            stdout=subprocess.DEVNULL,
        )
        print('composed', shot)
    for shot, (render, label, note) in HTML_REFERENCES.items():
        if not shot.startswith(prefix):
            continue
        subprocess.run(
            [
                sys.executable,
                str(HERE / 'compose.py'),
                shot,
                '-',
                f'--note={note}',
                f'{HERE / render}={label}',
                f'{shot}_w390.png=Mocked 390 t1.0',
                f'{shot}_w375_t135.png=Mocked 375 t1.35',
            ],
            check=True,
            stdout=subprocess.DEVNULL,
        )
        print('composed', shot)
    for name, (refs, panels, note) in FLOWS.items():
        if not name.startswith(prefix):
            continue
        subprocess.run(
            [
                sys.executable,
                str(HERE / 'compose.py'),
                name,
                refs[0],
                f'--note={note}',
                *[f'ref:{r}' for r in refs[1:]],
                *panels,
            ],
            check=True,
            stdout=subprocess.DEVNULL,
        )
        print('composed', name)


if __name__ == '__main__':
    main()
