"""Compose before | after panels for the final Merchant polish pass.

Usage: python3 audit/parity/polish/compose_polish.py
       python3 audit/parity/polish/compose_polish.py --live <t100-run> <t135-run>
Reads audit/parity/mocked/b9_*_{before,after}_*.png and the geometry JSON in
polish/geometry/, writes polish/before_after/<surface>.png. With --live, reads
screens/fxp_t100_<tag>.png and screens/fxp_t135_<tag>.png of the two isolated
runs and writes polish/live_panels/fxp_<tag>.png (live 1.0 | live 1.35).
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
import compose  # noqa: E402

compose.OUT = str(HERE / 'before_after')

SURFACES = {
    'b9_snack_hours': ('Exceptional-hours save snackbar', 'gapAboveStickyBar'),
    'b9_snack_duplicate_editor': ('Duplicate success -> editor snackbar', 'gapAboveStickyBar'),
    'b9_snack_weekly_hours': ('Weekly opening-hours save snackbar', 'gapAboveStickyBar'),
    'b9_catalog_end': ('Catalogue list end vs FAB / nav / safe area', 'gapAboveFab'),
    'b9_staff_duplicate': ('STAFF direct duplicate route', None),
}
VARIANTS = [('w390', '390 t1.0'), ('w375_t135', '375 t1.35')]


def geometry(name: str) -> dict:
    return json.loads((HERE / 'geometry' / f'{name}.json').read_text())


def label(surface: str, phase: str, suffix: str, title: str, metric) -> str:
    g = geometry(f'{surface}_{phase}_{suffix}')
    if metric:
        return f'{phase.upper()} {title} ({metric}={g[metric]:g}px)'
    flags = 'back' if g.get('backButton') else 'no back'
    flags += ', catalogue fallback' if g.get('catalogFallback') else ', no fallback'
    return f'{phase.upper()} {title} (AppBar, {flags})'


LIVE_TAGS = {
    '01_duplicate_source_image': 'Duplicate screen paints the bound source image',
    '02_duplicate_editor_snack': 'Copy editor: "Copie créée" snack bar above the sticky bar',
    '03_duplicate_editor_image': 'Copy editor paints the copied image',
    '04_copy_editor_reopened': 'Copy editor after a fresh app instance: image still painted',
    '05_catalog_end': 'Catalogue end: last product above FAB, bottom nav and safe area',
    '06_hours_exception_snack': 'Exceptional-hours save: snack bar above the sticky bar',
    '07_weekly_hours_snack': 'Weekly-hours save: snack bar above the sticky bar',
    '08_staff_duplicate_forbidden': 'STAFF direct duplicate route: forbidden state with AppBar',
    '09_staff_back_catalogue': 'STAFF back action opens the catalogue',
    '10_staff_fallback_catalogue': 'STAFF "Retour au catalogue" opens the catalogue',
}


def live(t100: Path, t135: Path) -> None:
    compose.OUT = str(HERE / 'live_panels')
    for tag, title in LIVE_TAGS.items():
        sys.argv = [
            'compose.py', f'fxp_{tag}', '-', f'--note={title}',
            f'{t100 / "screens" / f"fxp_t100_{tag}.png"}=Live isolated iPhone 16e, text 1.0',
            f'{t135 / "screens" / f"fxp_t135_{tag}.png"}=Live isolated iPhone 16e, text 1.35',
        ]
        compose.main()


def main() -> None:
    if '--live' in sys.argv:
        i = sys.argv.index('--live')
        live(Path(sys.argv[i + 1]).resolve(), Path(sys.argv[i + 2]).resolve())
        return
    for surface, (title, metric) in SURFACES.items():
        panels = []
        for suffix, vlabel in VARIANTS:
            for phase in ('before', 'after'):
                panels.append(
                    f'{surface}_{phase}_{suffix}.png='
                    + label(surface, phase, suffix, vlabel, metric)
                )
        sys.argv = ['compose.py', f'{surface}_before_after', '-', f'--note={title}', *panels]
        compose.main()


if __name__ == '__main__':
    main()
