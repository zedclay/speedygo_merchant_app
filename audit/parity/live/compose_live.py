#!/usr/bin/env python3
"""Reference | live t1.0 | live t1.35 panels (live evidence only).

Usage: compose_live.py [prefix] [--set live2]   e.g. b3, b7, or nothing for all.
  --set live2 composes the second live pass (live2_t100 / live2_t135 captures)
  into ../comparisons/live/live2_<tag>.png; first-pass images are untouched.
  A size that was not captured in a pass gets a labelled placeholder panel.

Live captures are full simulator screenshots (one viewport, status bar
included). iPhone 16e (390 pt @3x) is scaled to 780 px and the SE (375 pt
@2x) stays at 750 px, matching the @2x scale of the reference and mocked
panels. Output: ../comparisons/live/live_<tag>.png
"""
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from compose import BG, GAP, LABEL_H, REFS, font, wrap  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.abspath(os.path.join(HERE, '..', 'comparisons', 'live'))

PAIRS = {
    'b1_home': 'merchant_operational_dashboard_french',
    'b1_home_end': 'merchant_operational_dashboard_french',
    'b2_orders': 'active_orders_list_french',
    'b2_order_detail': 'delayed_order_french',
    'b2_order_detail_end': 'delayed_order_french',
    'b3_catalog': 'liste_des_produits_standardis_e',
    'b3_category': 'd_tails_de_la_cat_gorie_standardis',
    'b3_product': 'modifier_le_produit_standardis_image_corrig_e',
    'b3_variants': 'required_variants_french',
    'b3_extras': 'optional_extras_french',
    'b3_product_availability': 'product_availability_french',
    'b3_reorder': 'reorder_categories_french',
    'b3_bulk_availability': 'bulk_availability_french',
    'b4_profile': 'store_profile_french',
    'b4_hours': 'horaires_d_ouverture_pur',
    'b4_availability': 'store_availability_control_french',
    'b4_temporary': 'temporary_closure_french',
    'b4_cover': 'store_logo_and_cover_french',
    'b4_address': 'store_contact_and_address_french',
    'b5_overview': 'merchant_reports_overview_french',
    'b5_top_products': 'popular_products_french',
    'b6_settings': 'merchant_settings_french',
    'b6_notifications': 'merchant_notification_center_french',
    'b6_notification_settings': 'order_notification_settings_french',
    'b6_support': 'merchant_support_french',
    'b6_logout': 'merchant_logout_french',
    'b7_registration': 'merchant_registration_french',
    'b7_documents': 'business_document_upload_french',
    'b7_review': 'merchant_verification_review_french',
    'b7_pending': 'merchant_verification_pending_french',
    'b7_rejected': 'merchant_verification_rejected_french',
    'b7_resubmission': 'merchant_verification_resubmission_french',
    'b7_approved': 'merchant_verification_approved_french',
    'b7_approved_next': 'merchant_operational_dashboard_french',
    'b2_update_sheet': 'mise_jour_du_temps_de_pr_paration',
    'b2_update_sheet_reason': 'mise_jour_du_temps_de_pr_paration',
    'b3_category_end': 'd_tails_de_la_cat_gorie_standardis',
    'b4_general': 'store_information_french',
    # Tracked fixture writes (run "fx"): list-card accept / reject, branch name.
    'fx_alert': 'incoming_order_alert_french',
    'fx_incoming': 'active_orders_list_french',
    'fx_accept_sheet': 'accept_order_and_preparation_time_french',
    'fx_after_accept': 'active_orders_list_french',
    'fx_reject_sheet': 'active_orders_list_french',
    'fx_after_reject': 'active_orders_list_french',
    'fx_branch_saved': 'merchant_operational_dashboard_french',
    'fx_branch_reopened': 'store_information_french',
    # Daily summary + delayed-order contract close (rows 5, 18) — fxdd set.
    'daily_summary': 'daily_summary_french',
    'daily_summary_end': 'daily_summary_french',
    'daily_summary_empty': 'daily_summary_french',
    'daily_summary_staff': 'daily_summary_french',
    'daily_summary_cold': 'daily_summary_french',
    'delayed_order_before': 'delayed_order_french',
    'delayed_order_impact': 'delayed_order_french',
    'delayed_order_update_sheet': 'mise_jour_du_temps_de_pr_paration',
    'delayed_order_update_reason': 'mise_jour_du_temps_de_pr_paration',
    'delayed_order_after': 'delayed_order_french',
    # Team management (row 64) — fxteam set.
    'settings_owner': 'merchant_settings_french',
    'team_top': 'staff_and_account_access_french',
    'team_end': 'staff_and_account_access_french',
    'team_invite_sheet': 'staff_and_account_access_french',
    'team_cold': 'staff_and_account_access_french',
    'settings_staff': 'merchant_settings_french',
    'team_staff_denied': 'staff_and_account_access_french',
}

PARTIAL_DELAY = (
    'PARTIAL, different composition: the app shows the late state in the order '
    'detail and edits the time in the "Mise à jour du temps" sheet. '
    'Not built: delivery impact (no contract); −/+ editor (presets kept by decision).'
)

DELAY_CONTRACT_NOTE = (
    'Implementer-reviewed: truthful delivery-impact block from server state '
    '(no invented delivery ETA). −/+ editor still omitted (presets by decision).'
)

DAILY_SUMMARY_NOTE = (
    'Implementer-reviewed: Africa/Algiers daily-summary contract; no fabricated '
    'prep target; STAFF omits finance (—).'
)

NOTES = {
    'b2_order_detail': PARTIAL_DELAY,
    'b2_order_detail_end': PARTIAL_DELAY,
    'b2_update_sheet': PARTIAL_DELAY,
    'b2_update_sheet_reason': PARTIAL_DELAY,
    'fx_reject_sheet': 'No Stitch reference for the reject reason sheet; '
    'the list is the closest reference.',
    'fx_branch_saved': 'Evidence, not a parity target: after saving, the screen '
    'closes back to where it was opened (home here) and the header shows the '
    'new name.',
    'daily_summary': DAILY_SUMMARY_NOTE,
    'daily_summary_end': DAILY_SUMMARY_NOTE,
    'daily_summary_empty': DAILY_SUMMARY_NOTE,
    'daily_summary_staff': 'STAFF role: operational KPIs only; sales shown as —.',
    'daily_summary_cold': DAILY_SUMMARY_NOTE,
    'delayed_order_before': DELAY_CONTRACT_NOTE,
    'delayed_order_impact': DELAY_CONTRACT_NOTE,
    'delayed_order_update_sheet': DELAY_CONTRACT_NOTE,
    'delayed_order_update_reason': DELAY_CONTRACT_NOTE,
    'delayed_order_after': DELAY_CONTRACT_NOTE,
    'team_top': (
        'Implementer-reviewed: persisted roster (phone + role); no Stitch names/presence.'
    ),
    'team_end': (
        'Implementer-reviewed: end viewport; measured FAB clearance keeps '
        'Résumé des rôles (incl. branch-access line) readable above Inviter at 1.35.'
    ),
    'team_invite_sheet': (
        'Invite sheet returns a shareable acceptCode; UI never claims SMS/email sent.'
    ),
    'team_cold': 'Cold relaunch still shows the server roster.',
    'team_staff_denied': 'STAFF denied team administration (server + UI).',
    'settings_staff': 'STAFF settings omit Gestion de l’équipe.',
}

# Notes that only apply to one run's captures: (run, tag) -> note.
RUN_NOTES = {
    ('live4', 'b2_update_sheet'): 'Superseded by live5_b2_update_sheet: these panels '
    'predate the compact reference and the dated estimates.',
    ('live4', 'b2_update_sheet_reason'): 'Superseded by live5_b2_update_sheet_reason.',
    ('live5', 'b2_update_sheet'): 'Estimate from 28/09: current and proposed times carry '
    'their date. At 1.35 the comparison card continues below the fold (proposed date '
    'in the scrolled view).',
    ('live5', 'b2_update_sheet_reason'): 'Scrolled view; at 1.35 the proposed '
    '"le 28/09" shows at the top.',
    ('live4', 'b2_orders'): 'No incoming orders during the walk; incoming cards are in '
    'fx_fx_incoming.',
    ('live4', 'b3_category'): 'At 1.35 the FAB covers the last product switch in this top '
    'view; the end view clears it.',
    ('live4', 'b5_overview'): 'Data differs between panels: Annulations 0 at 1.0 (16:08) '
    'and 2 at 1.35 (17:11), from tracked fixture rejects made in between.',
    ('live4', 'b5_top_products'): 'Live capture of the empty state only (no ranked rows). Editor navigation is automated + mocked evidence, not live.',
    ('fx', 'fx_incoming'): 'The long fixture name stacks above the amount at both sizes. '
    'The 1.35 panel is scrolled to the second card.',
}


def live_panel(tag, prefix):
    path = os.path.join(HERE, f'{prefix}_{tag}.png')
    if not os.path.exists(path):
        im = Image.new('RGB', (750, 1334), (236, 238, 244))
        ImageDraw.Draw(im).text((40, 600), 'not captured at this size\nin this pass',
                                fill=(90, 96, 110), font=font(30))
        return im
    im = Image.open(path).convert('RGB')
    if im.width > 1000:
        im = im.resize((780, round(im.height * 780 / im.width)), Image.LANCZOS)
    return im


def compose(tag, ref, run='live'):
    if not any(os.path.exists(os.path.join(HERE, f'{run}_{t}_{tag}.png')) for t in ('t100', 't135')):
        return False
    device = 'SE 375' if tag.startswith('b7') else '16e 390'
    images = []
    im = Image.open(os.path.join(REFS, ref, 'screen.png')).convert('RGB')
    im = im.resize((780, round(im.height * 780 / im.width)), Image.LANCZOS)
    images.append((im, f'Reference: {ref}'))
    images.append((live_panel(tag, f'{run}_t100'), f'{run.upper()} {device} t1.0'))
    images.append((live_panel(tag, f'{run}_t135'), f'{run.upper()} {device} t1.35'))
    width = sum(i.width for i, _ in images) + GAP * (len(images) + 1)
    f = font(22)
    note = ' '.join(n for n in (NOTES.get(tag), RUN_NOTES.get((run, tag))) if n)
    lines = wrap(note, f, width - 2 * GAP) if note else []
    top = LABEL_H + 30 * len(lines) + (12 if lines else 0)
    height = max(i.height for i, _ in images) + top + GAP
    canvas = Image.new('RGB', (width, height), BG)
    draw = ImageDraw.Draw(canvas)
    for n, line in enumerate(lines):
        draw.text((GAP, 56 + 30 * n), line, fill=(147, 0, 10), font=f)
    x = GAP
    for panel, label in images:
        draw.text((x, 18), label, fill=(18, 27, 46), font=f)
        canvas.paste(panel, (x, top))
        x += panel.width + GAP
    os.makedirs(OUT, exist_ok=True)
    canvas.save(os.path.join(OUT, f'{run}_{tag}.png'), optimize=True)
    return True


def main():
    args = sys.argv[1:]
    run = 'live'
    if '--set' in args:
        i = args.index('--set')
        run = args[i + 1]
        del args[i:i + 2]
    prefix = args[0] if args else ''
    for tag, ref in PAIRS.items():
        if tag.startswith(prefix) and compose(tag, ref, run):
            print(f'composed {run}', tag)


if __name__ == '__main__':
    main()
