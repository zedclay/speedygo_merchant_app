"""Record the contract-completion batch (2026-10-02) in matrix/progress.json.

Rewrites six rows only. Keeps the file's format (indent 2, UTF-8, trailing
newline). Refuses to run if a row's current note is not the expected one.
"""
import json
from pathlib import Path

PROGRESS = Path(__file__).resolve().parents[1] / 'matrix' / 'progress.json'

LIVE = 'live compared (isolated 16e, 1.0 + 1.35)'
SNACK = ('Shared UI issue: a snackbar can cover the in-body MerchantStickyBar '
         'Save button for about 4 s (tracked, not fixed).')

UPDATES = {
    'liste_des_produits_menu_ouvert': (
        'done (mocked compared',
        'done (mocked compared, b3_product_menu; ' + LIVE + ': '
        'fxc_duplicate_owner_menu, fxc_duplicate_manager_menu) — '
        'Contract-completion batch (2026-10-02, D-C2): "Dupliquer" added; it opens '
        'the duplicate screen. OWNER/MANAGER only; STAFF has no product menu '
        '(fxc_staff_catalog). Earlier: Modifier / Gérer la disponibilité / divider / '
        'Supprimer (red). "Archiver" not offered (no archive contract).',
    ),
    'duplicate_product_french': (
        'no change — PNG unusable',
        'done (mocked compared, b8_duplicate; ' + LIVE + ': '
        'fxc_duplicate_owner_screen, fxc_duplicate_manager_screen, '
        'fxc_duplicate_owner_editor, fxc_catalog_with_copy, fxc_staff_duplicate) — '
        'Contract-completion batch (2026-10-02, D-C2): one atomic server command. '
        'Source card, name prefilled "Copie de …" (editable), copied-items '
        'checklist, not-copied banner, draft note; the copy starts unavailable '
        '("Brouillon" = available=false). One requestId per screen: a live double '
        'tap created exactly one copy and the original stayed unchanged. Reference '
        'PNG is black, so the code.html render is the reference. Gaps: "Unités de '
        'vente" shown as not managed (no contract). Live image copy not shown '
        '(fixture products have no image); verified by backend e2e D03/D13/D15 only. '
        + SNACK,
    ),
    'store_profile_french': (
        'done (mocked compared, b4_profile',
        None,
    ),
    'store_logo_and_cover_french': (
        'done for cover',
        'done (mocked compared, b8_logo_cover, b4_cover; live compared (16e): '
        'live_b4_cover; ' + LIVE + ': fxc_logo_empty, fxc_logo_reopened, '
        'fxc_logo_replaced, fxc_logo_removed, fxc_manager_logo, fxc_staff_logo) — '
        'Contract-completion batch (2026-10-02, D-D3): logo circle with Modifier / '
        'Supprimer for OWNER/MANAGER, read-only for STAFF; customer preview card '
        'shows the logo. Saved only after the server bind; read back after a fresh '
        'app instance; replacement verified byte-for-byte live; removal returns to '
        'the fallback. Cover unchanged: saved cover preview, save enabled only after '
        "a new pick, 'Supprimer' shown only when a cover is saved. " + SNACK,
    ),
    'horaires_d_ouverture_pur': (
        'done (mocked compared, b4_hours',
        None,
    ),
    'horaires_exceptionnels_format_24h': (
        'blocked_contract',
        'partial (mocked compared, b8_hours_exceptions; ' + LIVE + ': '
        'fxc_hours_exceptions_empty, fxc_hours_exception_form, '
        'fxc_hours_exception_saved, fxc_hours_exception_reopened, '
        'fxc_hours_exception_conflict, fxc_hours_exception_open_interval, '
        'fxc_hours_exception_deleted, fxc_staff_hours_exceptions) — '
        'Contract-completion batch (2026-10-02, D-D4): info banner, upcoming list '
        'with Fermé / Ouvert badges and 24-hour intervals, add form (date, Ouvert / '
        'Fermé, up to 3 intervals, reason, optional customer message), delete per '
        'date; Africa/Algiers dates; a 409 keeps the draft and reloads the list; '
        'STAFF read-only. Partial by decision: one civil date per exception, saved '
        'one at a time (no date ranges, no "Ajouter à la liste" batch); the customer '
        'message is stored but not shown in the Customer app. ' + SNACK,
    ),
}


def patch_profile(note):
    old_gap = 'Gaps: logo tile is a storefront placeholder (no logo contract), '
    if old_gap not in note:
        raise SystemExit('store_profile_french: logo gap text not found')
    head_end = note.index(') — ')
    head = note[:head_end] + '; ' + LIVE + ': fxc_profile_logo, fxc_profile_logo_fallback'
    body = note[head_end + len(') — '):].replace(old_gap, 'Gaps: ')
    return (head + ') — Contract-completion batch (2026-10-02, D-D3): the identity '
            'card shows the branch logo from the server and the storefront '
            'placeholder when none is bound. ' + body)


def patch_hours(note):
    old_gap = 'Gaps: exceptional hours (blocked), no Arabic branch name'
    if old_gap not in note:
        raise SystemExit('horaires_d_ouverture_pur: exceptional-hours gap text not found')
    head_end = note.index(') — ')
    head = note[:head_end] + '; ' + LIVE + ': fxc_hours_today_closed, fxc_hours_weekly_fallback'
    body = note[head_end + len(') — '):].replace(old_gap, 'Gaps: no Arabic branch name')
    return (head + ') — Contract-completion batch (2026-10-02, D-D4): a "Horaires '
            'exceptionnels" row opens the exceptions screen and shows today\'s '
            'exception; the status pill follows it (live: closed exception today → '
            'Fermé while the week is 24h; weekly fallback after delete). ' + body)


def main():
    text = PROGRESS.read_text()
    data = json.loads(text)
    for key, (expected_prefix, new_note) in UPDATES.items():
        current = data[key]
        if not current.startswith(expected_prefix):
            raise SystemExit(f'{key}: unexpected current note {current[:60]!r}')
        if key == 'store_profile_french':
            new_note = patch_profile(current)
        elif key == 'horaires_d_ouverture_pur':
            new_note = patch_hours(current)
        data[key] = new_note
    PROGRESS.write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n')
    print(f'updated {len(UPDATES)} rows')


if __name__ == '__main__':
    main()
