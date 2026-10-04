#!/usr/bin/env python3
"""Reference | live t1.0 | live t1.35 panels for the contract-completion batch.

Reads the two authoritative isolated runs (screens/fxc_t100_<tag>.png and
screens/fxc_t135_<tag>.png) and writes ../comparisons/live/fxc_<tag>.png.
Failed-attempt runs are never read. Usage: compose_contract_batch_live.py
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
PARITY = os.path.abspath(os.path.join(HERE, '..'))
sys.path.insert(0, PARITY)
from compose import BG, GAP, LABEL_H, REFS, font, wrap  # noqa: E402

EVIDENCE = os.path.join(PARITY, 'isolated', 'evidence')
RUNS = {
    't100': ('fxenv_20261002T211645Z', 'LIVE isolated 16e t1.0'),
    't135': ('fxenv_20261002T211050Z', 'LIVE isolated 16e t1.35'),
}
OUT = os.path.join(PARITY, 'comparisons', 'live')
DUPLICATE_RENDER = os.path.join(
    PARITY, 'reference_renders', 'duplicate_product_french_code_html_w390.png')

LOGO = 'store_logo_and_cover_french'
PROFILE = 'store_profile_french'
EXCEPTIONS = 'horaires_exceptionnels_format_24h'
WEEKLY = 'horaires_d_ouverture_pur'
MENU = 'liste_des_produits_menu_ouvert'
DUPLICATE = 'duplicate_product_french'
EDITOR = 'modifier_le_produit_standardis_image_corrig_e'
LIST = 'liste_des_produits_standardis_e'

PAIRS = {
    'logo_empty': LOGO,
    'logo_reopened': LOGO,
    'logo_replaced': LOGO,
    'logo_removed': LOGO,
    'profile_logo': PROFILE,
    'profile_logo_fallback': PROFILE,
    'manager_logo': LOGO,
    'staff_logo': LOGO,
    'hours_exceptions_empty': EXCEPTIONS,
    'hours_exception_form': EXCEPTIONS,
    'hours_exception_saved': EXCEPTIONS,
    'hours_exception_reopened': EXCEPTIONS,
    'hours_exception_conflict': EXCEPTIONS,
    'hours_exception_open_interval': EXCEPTIONS,
    'hours_exception_deleted': EXCEPTIONS,
    'hours_today_closed': WEEKLY,
    'hours_weekly_fallback': WEEKLY,
    'staff_hours_exceptions': EXCEPTIONS,
    'duplicate_owner_menu': MENU,
    'duplicate_owner_screen': DUPLICATE,
    'duplicate_owner_editor': EDITOR,
    'catalog_with_copy': LIST,
    'duplicate_manager_menu': MENU,
    'duplicate_manager_screen': DUPLICATE,
    'duplicate_manager_editor': EDITOR,
    'staff_catalog': LIST,
    'staff_duplicate': DUPLICATE,
}

EXCEPTIONS_PARTIAL = (
    'PARTIAL by decision: one civil date per exception, saved one at a time '
    '(no date ranges, no "Ajouter à la liste" batch). The customer message is '
    'stored only; the Customer app does not show it yet.'
)
DUPLICATE_REF = (
    'Reference PNG unusable (all black); code.html render used. "Brouillon" maps '
    'to available=false. "Unités de vente" is shown as not managed (no contract). '
    'Fixture products have no image, so live image copying is not shown '
    '(verified by backend e2e D03/D13/D15).'
)

NOTES = {
    'logo_empty': 'No logo bound: fallback avatar; Modifier only.',
    'logo_reopened': 'After a fresh app instance: logo A read back from the server.',
    'logo_replaced': 'Logo B shown; server bytes and displayed bytes equal B '
    'byte-for-byte (logoReplacedMatchesB, logoDisplayedIsB).',
    'logo_removed': 'After Supprimer: server returns no logo; fallback shown.',
    'profile_logo': 'Store profile header shows the bound logo from the server.',
    'profile_logo_fallback': 'Store profile header falls back to the storefront '
    'placeholder after removal.',
    'manager_logo': 'MANAGER sees Modifier / Supprimer controls.',
    'staff_logo': 'STAFF: logo read-only (no Modifier / Supprimer).',
    'hours_exception_conflict': 'A concurrent server change returned 409: the '
    'draft (10:00–14:00, new label) is kept and the server row is shown above. '
    + EXCEPTIONS_PARTIAL,
    'hours_today_closed': 'Closed exception for today: Fermé actuellement '
    '(API isOpenNow=false, acceptingOrders=false) while the weekly schedule is 24h.',
    'hours_weekly_fallback': 'Exception deleted: weekly fallback, Ouvert actuellement.',
    'staff_hours_exceptions': 'STAFF: list read-only, no form. ' + EXCEPTIONS_PARTIAL,
    'duplicate_owner_screen': DUPLICATE_REF,
    'duplicate_manager_screen': DUPLICATE_REF,
    'staff_duplicate': 'STAFF opening the duplicate route directly is refused. '
    + DUPLICATE_REF,
    'duplicate_owner_editor': 'Editor of the new copy opened after a double tap '
    'on Créer la copie; exactly one copy exists, available=false.',
    'catalog_with_copy': 'List refreshed with the copy, toggle off (unavailable). '
    'The copy row is partly under the add-product button at 1.0.',
    'staff_catalog': 'STAFF: no product menu, so no Dupliquer entry.',
}
for tag, ref in PAIRS.items():
    if ref == EXCEPTIONS and tag not in NOTES:
        NOTES[tag] = EXCEPTIONS_PARTIAL


def reference(ref):
    if ref == DUPLICATE:
        im = Image.open(DUPLICATE_RENDER).convert('RGB')
        label = f'Reference: {ref} (code.html render; PNG is black)'
    else:
        im = Image.open(os.path.join(REFS, ref, 'screen.png')).convert('RGB')
        label = f'Reference: {ref}'
    return im.resize((780, round(im.height * 780 / im.width)), Image.LANCZOS), label


def live(tag, size):
    run, label = RUNS[size]
    path = os.path.join(EVIDENCE, run, 'screens', f'fxc_{size}_{tag}.png')
    if not os.path.exists(path):
        raise SystemExit(f'missing authoritative screenshot: {path}')
    im = Image.open(path).convert('RGB')
    if im.width > 1000:
        im = im.resize((780, round(im.height * 780 / im.width)), Image.LANCZOS)
    return im, f'{label} ({run})'


def compose(tag, ref):
    images = [reference(ref), live(tag, 't100'), live(tag, 't135')]
    width = sum(i.width for i, _ in images) + GAP * (len(images) + 1)
    f = font(22)
    note = NOTES.get(tag, '')
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
    canvas.save(os.path.join(OUT, f'fxc_{tag}.png'), optimize=True)


def main():
    for tag, ref in PAIRS.items():
        compose(tag, ref)
        print('composed', f'fxc_{tag}.png')


if __name__ == '__main__':
    main()
