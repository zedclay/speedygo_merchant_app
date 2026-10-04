#!/usr/bin/env python3
"""Side-by-side 1.0 | 1.35 panels for one isolated run.

Reads evidence/<run>/screens/fxi_t100_<step>.png and fxi_t135_<step>.png and
writes evidence/<run>/comparisons/<step>.png with a caption per panel.
Usage: compose_fx.py <run-id>
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
STEPS = {
    'alert': 'Incoming alert (real checkout order)',
    'incoming': 'Incoming list cards',
    'accept_sheet': 'Accept: preparation-time sheet',
    'after_accept': 'After accept',
    'reject_sheet': 'Reject: reason sheet',
    'after_reject': 'After reject',
    'branch_saved': 'Branch name saved (screen closed)',
    'branch_reopened': 'Branch name after a fresh app instance',
    'reports': 'Reports, populated (OWNER)',
    'reports_top_section': 'Reports top products, chevrons (OWNER)',
    'top_products_owner': 'Top produits, OWNER (chevrons)',
    'editor_owner': 'Editor opened from Top produits (OWNER)',
    'top_products_manager': 'Top produits, MANAGER (chevrons)',
    'editor_manager': 'Editor opened from Top produits (MANAGER)',
    'top_products_staff': 'Top produits, STAFF (no chevron, no route)',
    'reports_staff': 'Reports after a STAFF row tap (no editor)',
}


def font(size):
    for name in ('/System/Library/Fonts/SFNS.ttf', '/System/Library/Fonts/Helvetica.ttc'):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def main():
    run = sys.argv[1]
    base = HERE / 'evidence' / run
    out = base / 'comparisons'
    out.mkdir(exist_ok=True)
    title_font, label_font = font(30), font(24)
    for step, caption in STEPS.items():
        paths = [base / 'screens' / f'fxi_{s}_{step}.png' for s in ('t100', 't135')]
        if not all(p.exists() for p in paths):
            print('missing', step)
            continue
        shots = [Image.open(p).convert('RGB') for p in paths]
        h = 1100
        shots = [im.resize((int(im.width * h / im.height), h)) for im in shots]
        pad, head = 24, 150
        width = sum(im.width for im in shots) + pad * 3
        canvas = Image.new('RGB', (width, h + head + pad), 'white')
        draw = ImageDraw.Draw(canvas)
        draw.text((pad, 14), caption, fill='black', font=title_font)
        draw.text((pad, 56), 'Isolated environment · speedygo_parity_fx · API :3100',
                  fill='#444444', font=label_font)
        x = pad
        for im, label in zip(shots, ('iPhone 16e · text 1.0 (large)', 'iPhone 16e · text 1.35 (xxxl)')):
            draw.text((x, 104), label, fill='#444444', font=label_font)
            canvas.paste(im, (x, head))
            x += im.width + pad
        canvas.save(out / f'{step}.png', optimize=True)
        print('composed', step)


if __name__ == '__main__':
    main()
