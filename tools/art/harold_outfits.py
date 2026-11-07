# Builds Harold's cardigan outfits: for every cardigan-slot cosmetic drawn as a cardigan (shape "band"),
# a copy of his strips (art/sprites/grandpa/idle, walk, attack) with his own olive cardigan redrawn in
# the cosmetic's colour, into art/sprites/grandpa_<cosmetic id>/. The cardigan is found by its five
# exact export colours (CARDIGAN, darkest first), so every frame, outline and shading row lines up with
# his own, and each tone becomes the same step of a ramp built from the cosmetic's colour (RAMP: value
# share of the colour, saturation gain, hue shift in degrees; shadows lean cool). GrandpaLook.outfit_art
# picks the folder. Run harold_strips.py first when his own strips change. Plain Python, no packages.
# Usage: py tools/art/harold_outfits.py <project folder>
import colorsys
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from npc_strips import load, save  # noqa: E402

ANIMS = ('idle', 'walk', 'attack')
# His 2026-11-06 redraw's cardigan, darkest to lightest (luminance 0.30, 0.32, 0.38, 0.40, 0.43).
CARDIGAN = ('464d4b', '515146', '65614a', '756640', '826c3e')
# The lit tones reach a little past the colour itself, so a burgundy cardigan still parts from his
# maroon trousers.
RAMP = ((0.64, 1.10, -10.0), (0.72, 1.05, -6.0), (0.88, 1.0, -3.0), (1.0, 1.0, 0.0), (1.12, 0.92, 3.0))


def cosmetic_colours(project):
    folder = os.path.join(project, 'data', 'cosmetics')
    out = {}
    for name in sorted(os.listdir(folder)):
        if not name.endswith('.tres'):
            continue
        text = open(os.path.join(folder, name), encoding='utf-8').read()
        slot = re.search(r'^slot = "(\w+)"', text, re.M)
        shape = re.search(r'^shape = "(\w+)"', text, re.M)
        colour = re.search(r'^color = Color\(([^)]*)\)', text, re.M)
        if slot and slot.group(1) == 'cardigan' and shape and shape.group(1) == 'band' and colour:
            out[name[:-5]] = [float(v) for v in colour.group(1).split(',')[:3]]
    return out


def ramp(rgb):
    h, s, v = colorsys.rgb_to_hsv(*rgb)
    tones = []
    for share, sat, shift in RAMP:
        r, g, b = colorsys.hsv_to_rgb((h + shift / 360.0) % 1.0, min(s * sat, 1.0), min(v * share, 1.0))
        tones.append(bytes((round(r * 255), round(g * 255), round(b * 255))))
    return tones


def recolour(path, out, tones):
    width, height, rows = load(path)
    swap = {bytes.fromhex(c): t for c, t in zip(CARDIGAN, tones)}
    changed = 0
    for row in rows:
        for x in range(width):
            px = bytes(row[x * 4:x * 4 + 3])
            if row[x * 4 + 3] and px in swap:
                row[x * 4:x * 4 + 3] = swap[px]
                changed += 1
    if not changed:
        raise ValueError('%s shows none of the cardigan colours; were his strips redrawn?' % path)
    save(out, width, height, rows)
    return changed


def main():
    project = sys.argv[1]
    source = os.path.join(project, 'art', 'sprites', 'grandpa')
    for cosmetic, rgb in cosmetic_colours(project).items():
        target = os.path.join(project, 'art', 'sprites', 'grandpa_' + cosmetic)
        os.makedirs(target, exist_ok=True)
        tones = ramp(rgb)
        counts = [recolour(os.path.join(source, a + '.png'), os.path.join(target, a + '.png'), tones) for a in ANIMS]
        print(cosmetic, ' '.join(t.hex() for t in tones), counts)


if __name__ == '__main__':
    main()
