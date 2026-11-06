# Builds the art of every enemy shot and thrown thing, and of Harold's own (docs/art/art-direction-
# notes.md section 14), into art/props/<id>.png. Plain Python, no packages.
#
# Usage: py tools/art/shot_art.py <export folder> <game root>
#
# The export folder (D:/grandpa-art/direction) holds projectiles/<name>.png, create_map_object exports;
# the smallest shots are drawn here by hand, pixel by pixel, since a drawing shrunk to 10 px turns to mud.
#
# Readability. Everything an enemy throws has a warm or bright body, a dark outline (ENEMY_LINE) and a
# pale warm rim outside that (ENEMY_RIM), so it reads on the darkest floor as well as the palest and
# never looks like Harold's. Harold's own things wear a cool pale ring inside a dark one (HAROLD_RING).
# What lies on the floor (the thorns, the write-up, goo, film, red tape) and the scythe's sweep are
# outlined only. No shot uses the warning red or the safe-spot mint.
#
# Each picture is drawn 1:1 at the size its code drawing had. A strip holds square frames side by side:
# a flicker, or a spinning thing's turns, pre-drawn so nothing small is rotated at draw time (ROTATIONS).
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from env_art import fit, hard_alpha, load, save, trim  # noqa: E402
from area_props import _darkest_edge, outline_again, tone  # noqa: E402

ENEMY_LINE = (26, 16, 20, 255)
ENEMY_RIM = (255, 228, 168, 255)
HAROLD_RING = (232, 246, 255, 255)
HAROLD_EDGE = (20, 24, 34, 255)
K = ENEMY_LINE

# Hand-drawn: id: (palette, rows) or (palette, [frame rows, ...]) for a strip.
HAND = {
    # A plain shot, every floor's: a sheet of paper with lines of ink and a folded warm corner.
    'shot_paper': ({'k': K, 'w': (250, 242, 220, 255), 'i': (120, 106, 92, 255), 'a': (240, 172, 84, 255)}, [
        "kkkkkkkkkk..",
        "kwwwwwwwwwk.",
        "kwiiiiiwwaak",
        "kwwwwwwwwaak",
        "kwiiiiiiwwwk",
        "kwwwwwwwwwwk",
        "kwiiiiwwwwwk",
        "kwwwwwwwwwwk",
        "kwiiiiiiiwwk",
        "kwwwwwwwwwwk",
        "kwiiiiiwwwwk",
        "kwwwwwwwwwwk",
        "kkkkkkkkkkkk",
    ]),
    # The orderly's sedative dart, flying east (the node turns it): pale plunger, amber dose, steel tip.
    'shot_dart': ({'k': K, 'p': (127, 183, 216, 255), 'b': (223, 243, 255, 255), 'a': (255, 179, 71, 255), 'n': (244, 244, 244, 255)}, [
        "....kkkkkkkk.....",
        "kkkkbbbbbbbbk....",
        "kppkaaaaaaabkkkk.",
        "kppkaaaaaaabnnnnk",
        "kppkaaaaaaabkkkk.",
        "kkkkbbbbbbbbk....",
        "....kkkkkkkk.....",
    ]),
    # A note of hold music: a warm cream quaver.
    'shot_note': ({'k': K, 'y': (255, 226, 140, 255), 'o': (232, 160, 70, 255)}, [
        ".....kk.....",
        ".....kykk...",
        ".....kyyykk.",
        ".....kykyyyk",
        ".....kyk.kyk",
        ".....kyk..kk",
        ".....kyk....",
        ".....kyk....",
        "..kkkkyk....",
        ".kyyyyyk....",
        "kyyyoyyk....",
        "kyyooyyk....",
        "kyoooyk.....",
        ".kkkkk......",
    ]),
    # A thrown lump of coal, its cracks glowing: two frames, the glow flickering.
    'shot_coal': ({'k': K, 'c': (70, 58, 54, 255), 'e': (255, 138, 42, 255), 'o': (255, 214, 110, 255)}, [[
        "..kkkkkkk..",
        ".kccccccck.",
        "kcccecccck.",
        "kcceoeeccck",
        "kceoooeecck",
        "kceooooecck",
        "kcceooeccck",
        "kccceeccck.",
        ".kccccccck.",
        "..kkkkkkk..",
    ], [
        "..kkkkkkk..",
        ".kccccccck.",
        "kccccecccck",
        "kcceeeeccck",
        "kceeoooecck",
        "kceooooeeck",
        "kcceeoeeeck",
        "kcccceeccck",
        ".kccccccck.",
        "..kkkkkkk..",
    ]]),
    # The florist's thorny wreath in flight: a bramble ring with a pale bloom on top.
    'shot_wreath': ({'k': K, 'g': (110, 170, 84, 255), 'd': (64, 118, 54, 255), 'w': (250, 232, 220, 255), 'r': (230, 140, 160, 255)}, [
        ".....kkk.....",
        "..kkkwrwkkk..",
        ".kgggkwkgggk.",
        "kgddk...kddgk",
        "kgdk.....kdgk",
        "kgk.......kgk",
        "kgk.......kgk",
        "kgk.......kgk",
        "kgdk.....kdgk",
        "kgddk...kddgk",
        ".kgggkkkgggk.",
        "..kkkgggkkk..",
        ".....kkk.....",
    ]),
    # A spirit from the seance circle: a pale lavender wisp with a bright core.
    'spirit_orb': ({'k': (40, 22, 58, 255), 'l': (204, 178, 244, 255), 'p': (160, 126, 222, 255), 'w': (255, 250, 255, 255)}, [
        "...kkkkkk...",
        "..kllllllk..",
        ".klllwwlllk.",
        "kllwwwwwwllk",
        "klwwwwwwwwlk",
        "klwwwwwwwwlk",
        "kllwwwwwwllk",
        "kpllwwwwllpk",
        ".kpllllllpk.",
        "..kppppppk..",
        "...kkkkkk...",
    ]),
}
# What lies on the floor, drawn by hand: no rim.
FLOOR_HAND = {
    # A length of the Projectionist's film, along x: dark film, pale sprockets on both edges, a frame line.
    'film_piece': ({'k': (18, 14, 12, 255), 'f': (40, 34, 28, 255), 'e': (96, 84, 60, 255), 's': (206, 196, 164, 255)}, [
        "kkkkkkkkkkkk",
        "esseesseesse",
        "effffeffffff",
        "ffffffeffffe",
        "fffffeffffff",
        "ffffffefffff",
        "fffffffeffff",
        "ffffffefffff",
        "fffffeffffff",
        "effffefffffe",
        "esseesseesse",
        "kkkkkkkkkkkk",
    ]),
    # A cell of the Chairman's red tape, along x: a crimson band with pale hatching and dark edges.
    'red_tape': ({'k': (74, 9, 16, 255), 'r': (208, 33, 46, 255), 'd': (160, 22, 34, 255), 'h': (251, 243, 230, 255)}, [
        "kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk",
        "rrrrhrrrrrhrrrrrhrrrrrhrrrrrhrrr",
        "rrrhrrrrrhrrrrrhrrrrrhrrrrrhrrrr",
        "rrhrrrrrhrrrrrhrrrrrhrrrrrhrrrrr",
        "rhrrrrrhrrrrrhrrrrrhrrrrrhrrrrrh",
        "hddddddhdddddhdddddhdddddhdddddd",
        "dddddddddddddddddddddddddddddddd",
        "kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk",
    ]),
}

# Harold's own, in his pale ring: the knitting needle, flying east, steel with a yarn bead, and the two
# jaws of his thrown false teeth, which the code opens and shuts.
HAROLD_HAND = {
    'fx_needle': ({'s': (186, 194, 206, 255), 'S': (240, 244, 250, 255), 'y': (224, 106, 58, 255)}, [
        "yy...........",
        "yySSSSSSSSSSs",
        "yy...........",
    ]),
    'dentures_upper': ({'g': (217, 112, 122, 255), 'G': (168, 72, 88, 255), 'w': (244, 241, 230, 255), 't': (200, 192, 176, 255)}, [
        ".GggggggggG.",
        "Gggggggggggg",
        "wwtwwtwwtwwt",
    ]),
    'dentures_lower': ({'g': (217, 112, 122, 255), 'G': (168, 72, 88, 255), 'w': (244, 241, 230, 255), 't': (200, 192, 176, 255)}, [
        "wwtwwtwwtwwt",
        "gggggggggggG",
        ".GggggggggG.",
    ]),
}

# From exports: id: (export file, max width, max height, recolour, kind). Recolours: 'steel' redraws the
# body on a pale steel ramp (the anchor), 'orange' and 'brass' turn any red to a warm orange or to pale
# brass (the lifebuoy's stripes and the plate's velvet sat near the warning red), 'warm' turns a navy
# body orange (the puck), 'lift' brightens a grey that sank into the floor (the tray), 'calm' tones a
# loud slime toward a deep green, 'mirror' flips it (the scythe's blade goes to the far end).
# Kinds: 'shot' gets the enemy rim, 'floor' keeps its outline only, 'harold' gets his ring.
EXPORTS = {
    'anchor': ('anchor2.png', 26, 30, 'steel', 'shot'),
    'quoit': ('quoit2.png', 30, 30, '', 'shot'),
    'puck': ('puck.png', 14, 14, 'warm', 'shot'),
    'lifebuoy': ('lifebuoy.png', 24, 24, 'orange', 'shot'),
    'collection_plate': ('plate.png', 14, 14, 'brass', 'shot'),
    'gavel': ('gavel.png', 42, 24, '', 'shot'),
    'security_tray': ('tray.png', 24, 18, 'lift', 'shot'),
    'rubber_stamp': ('stamp.png', 62, 40, '', 'shot'),
    'casket': ('casket.png', 40, 80, '', 'shot'),
    'scythe': ('scythe.png', 116, 40, 'mirror', 'floor'),
    'thorns_lying': ('thorns2.png', 56, 56, '', 'floor'),
    'write_up': ('write_up.png', 16, 20, '', 'floor'),
    'ectoplasm': ('ectoplasm.png', 16, 16, 'calm', 'floor'),
    'fx_peel': ('peel.png', 14, 14, '', 'harold'),
}

# Pre-drawn turns: id: (frames, the turn they cover in degrees). A plate or a buoy looks the same after a
# quarter turn, a sheet of paper or a strip of film after a half, so their frames cover only that.
ROTATIONS = {
    'collection_plate': (4, 90),
    'lifebuoy': (4, 90),
    'shot_paper': (8, 180),
    'film_piece': (4, 180),
}

STEEL = [(132, 140, 156), (170, 178, 192), (204, 212, 222), (236, 240, 246)]
ORANGE = [(196, 96, 30), (232, 130, 44), (250, 162, 66), (255, 196, 110)]
BRASS = [(176, 132, 56), (206, 164, 76), (230, 194, 104), (250, 222, 140)]


def from_rows(palette, rows):
    assert len(set(len(r) for r in rows)) == 1, rows
    palette = dict(palette)
    palette['.'] = (0, 0, 0, 0)
    return [[palette[c] for c in row] for row in rows]


# Frames side by side, each on a square cell (the code reads a frame as height x height).
def strip(frames):
    if len(frames) > 1:
        frames = [square(f) for f in frames]
    return [sum((f[y] for f in frames), []) for y in range(len(frames[0]))]


def square(pixels):
    h, w = len(pixels), len(pixels[0])
    side = max(h, w)
    left, top = (side - w) // 2, (side - h) // 2
    blank = (0, 0, 0, 0)
    rows = [[blank] * left + row + [blank] * (side - w - left) for row in pixels]
    return [[blank] * side] * top + rows + [[blank] * side] * (side - h - top)


def pad(pixels, n=1):
    w = len(pixels[0])
    blank = [(0, 0, 0, 0)] * (w + 2 * n)
    return [blank] * n + [[(0, 0, 0, 0)] * n + row + [(0, 0, 0, 0)] * n for row in pixels] + [blank] * n


def outline_grow(pixels, colour):
    p = pad(pixels)
    h, w = len(p), len(p[0])
    out = [list(row) for row in p]
    for y in range(h):
        for x in range(w):
            if p[y][x][3]:
                continue
            if any(0 <= x + dx < w and 0 <= y + dy < h and p[y + dy][x + dx][3] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                out[y][x] = colour
    return out


def enemy_rim(pixels):
    return outline_grow(pixels, ENEMY_RIM)


def harold_ring(pixels):
    return outline_grow(outline_grow(pixels, HAROLD_RING), HAROLD_EDGE)


def _lum(p):
    return (p[0] * 0.299 + p[1] * 0.587 + p[2] * 0.114) / 255.0


# Every pixel but the outline (and those `only` leaves out) onto a ramp by its brightness.
def on_ramp(pixels, ramp, only=lambda p: True):
    lums = [_lum(p) for row in pixels for p in row if p[3] and p[:3] != K[:3] and only(p)]
    if not lums:
        return pixels
    low, high = min(lums), max(lums)
    out = []
    for row in pixels:
        line = []
        for p in row:
            if not p[3] or p[:3] == K[:3] or not only(p):
                line.append(p)
                continue
            v = (_lum(p) - low) / max(0.004, high - low)
            line.append(ramp[min(len(ramp) - 1, int(v * len(ramp)))] + (255,))
        out.append(line)
    return out


def _red(p):
    return p[0] > p[1] + 40 and p[0] > p[2] + 30


def _blue(p):
    return p[2] > p[0] + 12 and p[2] >= p[1]


# A picture turned by `degrees` about its middle, nearest pixel, onto a square canvas of `side`.
def rotate(pixels, degrees, side):
    h, w = len(pixels), len(pixels[0])
    a = math.radians(degrees)
    ca, sa = math.cos(a), math.sin(a)
    cx, cy = (w - 1) / 2.0, (h - 1) / 2.0
    c = (side - 1) / 2.0
    out = []
    for y in range(side):
        line = []
        for x in range(side):
            dx, dy = x - c, y - c
            sx, sy = ca * dx + sa * dy + cx, -sa * dx + ca * dy + cy
            # Always half up (never Python's half-to-even), so a straight turn keeps every row.
            ix, iy = math.floor(sx + 0.5 + 1e-6), math.floor(sy + 0.5 + 1e-6)
            line.append(pixels[iy][ix] if 0 <= ix < w and 0 <= iy < h else (0, 0, 0, 0))
        out.append(line)
    return out


# The turns of a body before its rim, each outlined again so a turned edge keeps its line, on one square
# frame big enough for every turn.
def turns(body, frames, span, finish):
    side = int(math.ceil(math.hypot(len(body), len(body[0]))))
    line = _darkest_edge(body)
    cells = [finish(outline_again(rotate(body, span * i / frames, side), line)) for i in range(frames)]
    return strip(cells)


def finish_for(kind):
    return {'shot': enemy_rim, 'harold': harold_ring}.get(kind, lambda p: p)


# The scythe lies along x from its butt to its blade, padded so its shaft runs along its middle row; the
# code draws it from the sweep's centre with that row on the sweep line.
def centre_on_shaft(pixels):
    h = len(pixels)
    half = len(pixels[0]) // 2
    counts = [sum(1 for p in row[:half] if p[3]) for row in pixels]
    shaft = max(range(h), key=lambda y: counts[y])
    above, below = shaft, h - 1 - shaft
    blank = [(0, 0, 0, 0)] * len(pixels[0])
    grow = abs(above - below)
    return [blank] * grow + pixels if above < below else pixels + [blank] * grow


def build(export, game):
    out = os.path.join(game, 'art', 'props')
    made = {}
    for table, kind in ((HAND, 'shot'), (FLOOR_HAND, 'floor'), (HAROLD_HAND, 'harold')):
        for game_id, (palette, rows) in table.items():
            frames = rows if isinstance(rows[0], list) else [rows]
            bodies = [from_rows(palette, f) for f in frames]
            if game_id in ROTATIONS:
                made[game_id] = turns(bodies[0], *ROTATIONS[game_id], finish_for(kind))
            else:
                made[game_id] = strip([finish_for(kind)(b) for b in bodies])
    for game_id, (name, w, h, recolour, kind) in EXPORTS.items():
        raw = load(os.path.join(export, 'projectiles', name))
        if recolour == 'mirror':
            raw = [list(reversed(row)) for row in raw]
        body = outline_again(fit(raw, w, h, main=True), ENEMY_LINE if kind != 'harold' else _darkest_edge(raw))
        if recolour == 'steel':
            body = on_ramp(body, STEEL)
        elif recolour == 'orange':
            body = on_ramp(body, ORANGE, _red)
        elif recolour == 'brass':
            body = on_ramp(body, BRASS, _red)
        elif recolour == 'warm':
            body = on_ramp(body, ORANGE, _blue)
        elif recolour == 'lift':
            body = outline_again(tone(body, (1.25, 1.2, 1.15)), ENEMY_LINE)
        elif recolour == 'calm':
            body = tone(body, (0.55, 0.72, 0.6))
        if game_id == 'scythe':
            body = centre_on_shaft(trim(hard_alpha(body)))
        if game_id in ROTATIONS:
            made[game_id] = turns(body, *ROTATIONS[game_id], finish_for(kind))
        else:
            made[game_id] = finish_for(kind)(body)
    for game_id, pixels in made.items():
        save(os.path.join(out, game_id + '.png'), pixels)
        print(game_id, len(pixels[0]), 'x', len(pixels))
    return made


if __name__ == '__main__':
    build(sys.argv[1], sys.argv[2])
