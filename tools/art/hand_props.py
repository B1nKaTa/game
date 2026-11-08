# Draws by hand, at 1:1, the small props that read poorly at 1x as shrunk drawings (the polish pass,
# 2026-11-08): the care home's drip stand, the furnace's gauge, the parlour's candelabra and the Cinema's
# aisle light. Each fills the box it was drawn at before (area_props.py, which leaves these entries to
# this tool as 'hand'), in the depth look (docs/art/art-direction-notes.md): one dark outline round a
# standing prop, one or two shading steps per colour, light from the upper left, toned like the rest,
# and no warning red or safe-spot mint. The aisle light lies flat in the carpet, so it has a brass rim and
# no outline. Plain Python, no packages.
# Usage: py tools/art/hand_props.py <game root>
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from env_art import save  # noqa: E402
from area_props import LIFT, TONE, tone  # noqa: E402

OUTLINE = (24, 20, 30, 255)


def hexc(text):
    return (int(text[0:2], 16), int(text[2:4], 16), int(text[4:6], 16), 255)


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.px = [[(0, 0, 0, 0)] * w for _ in range(h)]

    def put(self, x, y, colour):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = colour

    def rect(self, x, y, w, h, colour):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.put(xx, yy, colour)

    def disc(self, cx, cy, r, colour):
        for yy in range(self.h):
            for xx in range(self.w):
                if (xx + 0.5 - cx) ** 2 + (yy + 0.5 - cy) ** 2 <= r * r:
                    self.put(xx, yy, colour)

    # One outline pixel on every clear pixel that touches the drawing side on.
    def outline(self, colour=OUTLINE):
        edge = []
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x][3]:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < self.w and 0 <= ny < self.h and self.px[ny][nx][3] and self.px[ny][nx] != colour:
                        edge.append((x, y))
                        break
        for x, y in edge:
            self.px[y][x] = colour


# The care home's drip stand, 14x28: a steel hook bar with a fluid bag on its left hook, a tube down to
# the pole, and a five-wheeled base.
def drip_stand():
    steel, steel_dark, steel_lit = hexc('9aa4ae'), hexc('5c6670'), hexc('d4dae0')
    bag, bag_dark, bag_lit, shine = hexc('6cb4c8'), hexc('3c7c94'), hexc('a6dce8'), hexc('eef8fa')
    label, tube, wheel = hexc('e4dcc4'), hexc('c4d8e0'), hexc('2c2a34')
    c = Canvas(14, 28)
    # The hook bar, lit on top.
    c.rect(2, 1, 10, 1, steel_lit)
    c.rect(2, 2, 10, 1, steel_dark)
    # The pole, lit on its left.
    c.rect(7, 3, 1, 20, steel)
    c.rect(8, 3, 1, 20, steel_dark)
    # The hook and the bag under it, rounded at the top, lit on the left, with a label and a shine.
    c.put(3, 3, steel_dark)
    c.rect(1, 5, 5, 8, bag)
    c.rect(2, 4, 3, 1, bag)
    c.rect(2, 13, 3, 1, bag_dark)
    c.rect(1, 5, 1, 8, bag_lit)
    c.rect(5, 5, 1, 8, bag_dark)
    c.rect(2, 8, 3, 2, label)
    c.put(2, 5, shine)
    c.put(2, 6, shine)
    # The drip chamber and the tube to the pole.
    c.put(3, 14, tube)
    c.put(3, 15, tube)
    c.put(4, 16, tube)
    c.put(5, 17, tube)
    # The base: a hub, a spread of legs and three wheels in sight.
    c.rect(6, 22, 4, 1, steel)
    c.rect(3, 23, 10, 1, steel)
    c.rect(3, 24, 10, 1, steel_dark)
    for x in (3, 7, 12):
        c.put(x, 25, wheel)
    c.outline()
    return tone(c.px, TONE)


# The furnace's pressure gauge, 16x20: a round brass dial on a short pipe with a flange.
def gauge():
    brass, brass_dark, brass_lit = hexc('c8983c'), hexc('7c5a22'), hexc('ecc46c')
    face, face_shade, tick, needle = hexc('ece6d4'), hexc('bcb4a0'), hexc('3c3432'), hexc('2a2228')
    steel, steel_dark = hexc('8c96a0'), hexc('545c66')
    c = Canvas(16, 20)
    c.disc(8, 7.5, 6.6, brass_dark)
    c.disc(7.6, 7.1, 6.0, brass)
    c.disc(7.0, 6.4, 3.0, brass_lit)
    c.disc(8, 7.5, 4.6, face_shade)
    c.disc(7.6, 7.1, 4.2, face)
    # Ticks round the dial and the needle up and right from the pin.
    for x, y in ((4, 7), (5, 4), (7, 3), (10, 4), (11, 7)):
        c.put(x, y, tick)
    for x, y in ((7, 7), (8, 6), (9, 5), (10, 5)):
        c.put(x, y, needle)
    c.put(7, 8, tick)
    # The pipe under it, lit on the left, and the flange it stands on.
    c.rect(6, 14, 2, 3, steel)
    c.rect(8, 14, 2, 3, steel_dark)
    c.rect(3, 17, 10, 1, brass)
    c.rect(3, 18, 10, 1, brass_dark)
    c.outline()
    return tone(c.px, TONE)


# The parlour's candelabra, 14x26: three cream candles lit on a brass stand, which reads against the
# wine carpet where the old black one sank into it. Kept at its own light, as before ('lift').
def candelabra():
    brass, brass_dark, brass_lit = hexc('b88a34'), hexc('6e4e1c'), hexc('e2b85a')
    wax, wax_shade = hexc('f0e6c8'), hexc('c8b894')
    flame, flame_core = hexc('f0a83c'), hexc('fff0b4')
    c = Canvas(14, 26)
    # The foot and the base, lit on the left.
    c.rect(2, 23, 10, 1, brass_dark)
    c.rect(3, 22, 8, 1, brass)
    c.rect(3, 22, 3, 1, brass_lit)
    c.rect(4, 21, 6, 1, brass)
    # The stem with a knob halfway.
    c.rect(6, 10, 1, 11, brass_lit)
    c.rect(7, 10, 1, 11, brass_dark)
    c.rect(5, 15, 4, 2, brass)
    c.put(5, 15, brass_lit)
    # The arms: a bar and an upturn at each end, with drip pans.
    c.rect(2, 10, 10, 1, brass)
    c.rect(2, 11, 10, 1, brass_dark)
    c.rect(2, 8, 1, 2, brass_lit)
    c.rect(11, 8, 1, 2, brass)
    c.rect(1, 7, 3, 1, brass)
    c.rect(10, 7, 3, 1, brass)
    c.rect(5, 8, 4, 1, brass)
    # The candles: the middle one taller, each lit on the left.
    for x, top, bottom in ((1, 4, 7), (6, 3, 8), (11, 4, 7)):
        c.rect(x, top, 2, bottom - top, wax)
        c.rect(x + 1, top, 1, bottom - top, wax_shade)
    # The flames.
    for x, top in ((1, 2), (6, 1), (11, 2)):
        c.put(x, top, flame_core)
        c.put(x + 1, top + 1, flame)
        c.put(x, top + 1, flame_core)
    c.outline()
    return tone(c.px, LIFT)


# The Cinema's aisle light, 10x6, set flat in the carpet: a dark brass rim round a warm lens, its upper
# half lit.
def aisle_light():
    rim, brass, lens_lit, lens = hexc('3a2a18'), hexc('a07a34'), hexc('fff0c0'), hexc('f0b450')
    c = Canvas(10, 6)
    c.rect(0, 0, 10, 6, rim)
    c.rect(1, 1, 8, 4, brass)
    c.rect(2, 2, 6, 1, lens_lit)
    c.rect(2, 3, 6, 1, lens)
    return c.px


PIECES = {
    ('sunset_shores', 'decor_iv_stand'): drip_stand,
    ('furnace_works', 'decor_gauge'): gauge,
    ('funeral_parlour', 'candle_stand'): candelabra,
    ('flashback_cinema', 'aisle_light'): aisle_light,
}


def main():
    game = sys.argv[1]
    for (art_set, game_id), draw in PIECES.items():
        pixels = draw()
        # A standing prop stands on its last row (PropArt.standing), so no clear rows stay under it.
        while len(pixels) > 1 and not any(p[3] for p in pixels[-1]):
            pixels = pixels[:-1]
        path = os.path.join(game, 'art', 'props', art_set, game_id + '.png')
        save(path, pixels)
        print(art_set, game_id, len(pixels[0]), len(pixels))


if __name__ == '__main__':
    main()
