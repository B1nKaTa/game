# Builds the art of every enemy shot and thrown thing, and of Harold's own (docs/art/art-direction-
# notes.md section 14), into art/props/<id>.png. Plain Python, no packages.
#
# Usage: py tools/art/shot_art.py <export folder> <game root>
#
# The export folder (D:/grandpa-art/direction) holds projectiles/<name>.png, create_map_object exports;
# the smallest shots are drawn here by hand, pixel by pixel, since a drawing shrunk to 10 px turns to mud.
#
# Readability. An enemy's shot has a warm or bright core and a dark outline (ENEMY_LINE), so it stands
# out on every floor and reads as hostile. Harold's own things wear a pale ring inside a dark one
# (HAROLD_RING), so they never look like an enemy's. No shot uses the warning red or the safe-spot mint.
# Each picture is drawn 1:1 at the size its code drawing had; a strip holds its frames side by side.
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from env_art import fit, hard_alpha, load, save  # noqa: E402
from area_props import _darkest_edge, outline_again, tone  # noqa: E402

ENEMY_LINE = (26, 16, 20, 255)
HAROLD_RING = (232, 246, 255, 255)
HAROLD_EDGE = (20, 24, 34, 255)

# Hand-drawn shots: id: (palette, rows) or (palette, [frame rows, ...]) for a strip.
K = ENEMY_LINE
HAND = {
    # A plain shot, every floor's: a sheet of paper with two lines of ink and a folded warm corner.
    'shot_paper': ({'k': K, 'w': (246, 238, 214, 255), 'i': (120, 106, 92, 255), 'a': (236, 168, 84, 255)}, [
        "kkkkkkkk..",
        "kwwwwwwwk.",
        "kwiiiiwwak",
        "kwwwwwwaak",
        "kwiiiiiwwk",
        "kwwwwwwwwk",
        "kwiiiwwwwk",
        "kwwwwwwwwk",
        "kwiiiiiwwk",
        "kwwwwwwwwk",
        "kwwwwwwwwk",
        "kkkkkkkkkk",
    ]),
    # The orderly's sedative dart, flying east (the node turns it): pale plunger, amber dose, steel tip.
    'shot_dart': ({'k': K, 'p': (127, 183, 216, 255), 'b': (223, 243, 255, 255), 'a': (255, 179, 71, 255), 'n': (244, 244, 244, 255)}, [
        "...kkkkkkk...",
        "kkkkbbbbbbk..",
        "kppkaaaaabkkn",
        "kkkkbbbbbbk..",
        "...kkkkkkk...",
    ]),
    # A note of hold music: a warm cream quaver, dark-lined, for the pale glow it used to need.
    'shot_note': ({'k': K, 'y': (255, 226, 140, 255), 'o': (232, 160, 70, 255)}, [
        "....kk....",
        "....kykk..",
        "....kyyyk.",
        "....kykyyk",
        "....kyk.kk",
        "....kyk...",
        "....kyk...",
        ".kkkkyk...",
        "kyyyyyk...",
        "kyyoyyk...",
        "kyoooyk...",
        ".kkkkk....",
    ]),
    # A thrown lump of coal, its cracks glowing: two frames, the glow flickering.
    'shot_coal': ({'k': K, 'c': (44, 36, 34, 255), 'e': (255, 138, 42, 255), 'o': (255, 206, 96, 255)}, [[
        "..kkkkk..",
        ".kccccck.",
        "kccecccck",
        "kcceoecck",
        "kceoooeck",
        "kcceoecck",
        "kccceccck",
        ".kccccck.",
        "..kkkkk..",
    ], [
        "..kkkkk..",
        ".kccccck.",
        "kcccecck.",
        "kcceeecck",
        "kceeoeeck",
        "kcceeecck",
        "kccecccck",
        ".kccccck.",
        "..kkkkk..",
    ]]),
    # The florist's thorny wreath in flight: a bramble ring with a pale bloom on top.
    'shot_wreath': ({'k': K, 'g': (86, 138, 70, 255), 'd': (52, 96, 46, 255), 'w': (246, 226, 214, 255), 'r': (214, 120, 140, 255)}, [
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
    'spirit_orb': ({'k': (40, 22, 58, 255), 'l': (196, 168, 240, 255), 'p': (150, 116, 214, 255), 'w': (255, 250, 255, 255)}, [
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
        "............",
    ]),
}

# Harold's own, in his pale ring: the knitting needle, flying east, steel with a yarn bead.
HAROLD_HAND = {
    'fx_needle': ({'s': (186, 194, 206, 255), 'S': (240, 244, 250, 255), 'y': (224, 106, 58, 255)}, [
        "yy...........",
        "yySSSSSSSSSSs",
        "yy...........",
    ]),
    # His thrown false teeth, as two jaws the code opens and shuts: gums over a row of teeth.
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

# From exports: id: (export file, max width, max height, mode). Modes: 'lift' brightens a pale object
# that sank into the floor (the tray), 'steel' redraws a dark one on a pale steel ramp (the anchor, iron
# on a dark sea), 'orange' and 'brass' turn any red to a warm orange or to brass (the lifebuoy's stripes
# and the plate's velvet sat near the warning red), 'calm' tones a loud slime toward a deep green,
# 'harold' puts Harold's ring round it.
EXPORTS = {
    'anchor': ('anchor.png', 26, 30, 'steel'),
    'quoit': ('quoit.png', 28, 28, ''),
    'puck': ('puck.png', 16, 16, ''),
    'lifebuoy': ('lifebuoy.png', 26, 26, 'orange'),
    'collection_plate': ('plate.png', 16, 16, 'brass'),
    'gavel': ('gavel.png', 42, 24, ''),
    'security_tray': ('tray.png', 24, 18, 'lift'),
    'thorns_lying': ('thorns.png', 48, 48, ''),
    'write_up': ('write_up.png', 16, 20, ''),
    'ectoplasm': ('ectoplasm.png', 16, 16, 'calm'),
    'fx_peel': ('peel.png', 14, 14, 'harold'),
}


def from_rows(palette, rows):
    assert len(set(len(r) for r in rows)) == 1, rows
    palette = dict(palette)
    palette['.'] = (0, 0, 0, 0)
    return [[palette[c] for c in row] for row in rows]


def strip(frames):
    return [sum((f[y] for f in frames), []) for y in range(len(frames[0]))]


def pad(pixels, n=1):
    w = len(pixels[0])
    blank = [(0, 0, 0, 0)] * (w + 2 * n)
    return [blank] * n + [[(0, 0, 0, 0)] * n + row + [(0, 0, 0, 0)] * n for row in pixels] + [blank] * n


# Harold's ring: a pale line round the picture, and a dark one round that.
def harold_ring(pixels):
    pale = outline_grow(pixels, HAROLD_RING)
    return outline_grow(pale, HAROLD_EDGE)


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


# Every pixel but the outline onto a ramp by its brightness, darkest to lightest.
def on_ramp(pixels, ramp):
    lums = [p[0] * 0.3 + p[1] * 0.59 + p[2] * 0.11 for row in pixels for p in row if p[3] and p[:3] != ENEMY_LINE[:3]]
    low, high = min(lums), max(lums)
    out = []
    for row in pixels:
        line = []
        for p in row:
            if not p[3] or p[:3] == ENEMY_LINE[:3]:
                line.append(p)
                continue
            v = ((p[0] * 0.3 + p[1] * 0.59 + p[2] * 0.11) - low) / max(1.0, high - low)
            line.append(ramp[min(len(ramp) - 1, int(v * len(ramp)))] + (255,))
        out.append(line)
    return out


def reds_onto(pixels, ramp):
    out = []
    for row in pixels:
        line = []
        for p in row:
            if p[3] and p[0] > p[1] + 40 and p[0] > p[2] + 30:
                line.append(ramp[min(len(ramp) - 1, int(p[0] / 256.0 * len(ramp)))] + (255,))
            else:
                line.append(p)
        out.append(line)
    return out


STEEL = [(84, 92, 108), (122, 132, 148), (162, 172, 186), (206, 214, 224)]
ORANGE = [(176, 82, 26), (220, 116, 38), (244, 150, 58), (255, 186, 96)]
BRASS = [(120, 84, 32), (156, 116, 44), (190, 148, 62), (220, 182, 92)]


def build(export, game):
    out = os.path.join(game, 'art', 'props')
    for game_id, (palette, rows) in HAND.items():
        frames = rows if isinstance(rows[0], list) else [rows]
        pixels = strip([from_rows(palette, f) for f in frames])
        save(os.path.join(out, game_id + '.png'), pixels)
        print(game_id, len(pixels[0]), 'x', len(pixels))
    for game_id, (palette, rows) in HAROLD_HAND.items():
        pixels = harold_ring(from_rows(palette, rows))
        save(os.path.join(out, game_id + '.png'), pixels)
        print(game_id, len(pixels[0]), 'x', len(pixels))
    for game_id, (name, w, h, mode) in EXPORTS.items():
        raw = load(os.path.join(export, 'projectiles', name))
        line = _darkest_edge(raw)
        pixels = outline_again(fit(raw, w, h, main=True), ENEMY_LINE if mode != 'harold' else line)
        if mode == 'lift':
            pixels = tone(pixels, (1.7, 1.65, 1.6))
            pixels = outline_again(pixels, ENEMY_LINE)
        elif mode == 'steel':
            pixels = on_ramp(pixels, STEEL)
        elif mode == 'orange':
            pixels = reds_onto(pixels, ORANGE)
        elif mode == 'brass':
            pixels = reds_onto(pixels, BRASS)
        elif mode == 'calm':
            pixels = tone(pixels, (0.55, 0.72, 0.6))
        if mode == 'harold':
            pixels = harold_ring(pixels)
        save(os.path.join(out, game_id + '.png'), pixels)
        print(game_id, len(pixels[0]), 'x', len(pixels))


if __name__ == '__main__':
    build(sys.argv[1], sys.argv[2])
