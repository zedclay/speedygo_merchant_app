#!/usr/bin/env python3
"""Side-by-side parity comparisons.

Usage: compose.py <out_name> <ref_folder|-> [--note=TEXT] <panel>[=Label] ...

A panel is a mocked capture name, an absolute PNG path, or ref:<folder> for an
additional reference. --note adds a status line under the labels (used to
mark partial parity or a different screen composition).

The reference is scaled to 780 px (390 pt @2x). Mocked captures are already
@2x at their logical width (390 -> 780 px, 375 -> 750 px) and are not scaled,
so relative sizes stay truthful. Panels are top-aligned (same scroll origin).
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.abspath(__file__))
REFS = os.path.abspath(os.path.join(ROOT, '../../../../screens/MerchantScreens'))
OUT = os.path.join(ROOT, 'comparisons')
LABEL_H = 64
GAP = 32
BG = (236, 238, 244)


def font(size):
    for path in (
        '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
        '/System/Library/Fonts/Helvetica.ttc',
    ):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def wrap(text, f, max_width):
    probe = ImageDraw.Draw(Image.new('RGB', (1, 1)))
    lines, line = [], ''
    for word in text.split():
        candidate = f'{line} {word}'.strip()
        if probe.textlength(candidate, font=f) <= max_width or not line:
            line = candidate
        else:
            lines.append(line)
            line = word
    if line:
        lines.append(line)
    return lines


def reference(folder):
    im = Image.open(os.path.join(REFS, folder, 'screen.png')).convert('RGB')
    scale = 780 / im.width
    return im.resize((780, round(im.height * scale)), Image.LANCZOS)


def main():
    out_name, ref, *args = sys.argv[1:]
    note = None
    panels = []
    for arg in args:
        if arg.startswith('--note='):
            note = arg[len('--note='):]
        else:
            panels.append(arg)
    images = []
    if ref != '-':
        images.append((reference(ref), f'Reference: {ref}'))
    for spec in panels:
        path, _, label = spec.partition('=')
        if path.startswith('ref:'):
            folder = path[len('ref:'):]
            images.append((reference(folder), label or f'Reference: {folder}'))
            continue
        path = path if os.path.isabs(path) else os.path.join(ROOT, 'mocked', path)
        images.append((Image.open(path).convert('RGB'), label or os.path.basename(path)))
    width = sum(i.width for i, _ in images) + GAP * (len(images) + 1)
    f = font(22)
    lines = wrap(note, f, width - 2 * GAP) if note else []
    top = LABEL_H + 30 * len(lines) + (12 if lines else 0)
    height = max(i.height for i, _ in images) + top + GAP
    canvas = Image.new('RGB', (width, height), BG)
    draw = ImageDraw.Draw(canvas)
    for n, line in enumerate(lines):
        draw.text((GAP, 56 + 30 * n), line, fill=(147, 0, 10), font=f)
    x = GAP
    for im, label in images:
        draw.text((x, 18), label, fill=(18, 27, 46), font=f)
        canvas.paste(im, (x, top))
        x += im.width + GAP
    os.makedirs(OUT, exist_ok=True)
    dest = os.path.join(OUT, f'{out_name}.png')
    canvas.save(dest, optimize=True)
    print(dest)


if __name__ == '__main__':
    main()
