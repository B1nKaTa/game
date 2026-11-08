# Draws the Waiting Room's wall pieces and fixtures by hand, at 1:1, in the depth look
# (docs/art/art-direction-notes.md), into res://art/props/waiting_room/ and res://art/sprites/:
#  - the Bounty Office's cork board (poster_board), its poster paper, the stamps for each poster state
#    (REWARD, TAKEN, DENIED, CLOSED), the cross over a closed poster, and one sepia portrait per wanted
#    boss (poster_<boss id>), cut from that boss's own south-facing sprite;
#  - the lobby's portrait wall: a dark wood frame with a brass bevel (trophy_frame), one colour portrait
#    per floor boss (trophy_<boss id>, drawn as a dark silhouette until he is beaten), a brass name plate
#    and a larger brass plaque for the endings count (both stretched across their one middle column);
#  - a corner cobweb for the departments' 'w' cells (decor_cobweb), in place of the crossed code lines;
#  - the Training Yard's dummy (art/sprites/training_dummy/idle.png) from its PixelLab export.
# Words are set in a 3x5 pixel font here, so they stay crisp. No warning red or safe-spot mint in any
# large area: the stamps' red is a deep ink red and only ever a thin band.
# Plain Python, no packages. Usage: py tools/art/waiting_props.py <export root> <game root>
# <export root> holds portraits/<boss id>.png (each boss's Idle/rotations/south.png) and
# props2/training_dummy.png (D:/grandpa-art/direction).
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from env_art import hard_alpha, load, save  # noqa: E402
from area_props import KEPT, TONE, outline_again, tone  # noqa: E402

OUT = ('art', 'props', 'waiting_room')
CLEAR = (0, 0, 0, 0)

# Every wanted boss, as data/bounties names them. The first ten are the floor bosses, in Mementos order.
FLOOR_BOSSES = ['regional_reaper', 'tired_undertaker', 'matron_mercy', 'old_smokey', 'mortimer_grimsby',
                'projectionist', 'commodore_wellington', 'madame_zara', 'augustine', 'chairman_of_the_board']
MINI_BOSSES = ['senior_adjuster', 'head_groundskeeper', 'activities_coordinator', 'foreman_klaus', 'reverend',
               'crabtree', 'lorraine', 'doreen', 'sergeant_wanda', 'celestine']

# Sizes the GDScript reads (PosterBoard, TrophyWall); keep them in step.
BOARD = (258, 84)
PAPER = (24, 28)
PORTRAIT_AT = (4, 3)
PORTRAIT = (16, 14)
STAMP_Y = 19
# Nine rows: a rule, a clear row, the word, a clear row, a rule. With the rules touching the word (seven
# rows) the stamps could not be read at 1x.
STAMP = (24, 9)
FRAME = 22
FACE = 16

FONT = {
    'A': ['.#.', '#.#', '###', '#.#', '#.#'],
    'C': ['.##', '#..', '#..', '#..', '.##'],
    'D': ['##.', '#.#', '#.#', '#.#', '##.'],
    'E': ['###', '#..', '##.', '#..', '###'],
    'K': ['#.#', '#.#', '##.', '#.#', '#.#'],
    'L': ['#..', '#..', '#..', '#..', '###'],
    'N': ['#..#', '##.#', '#.##', '#..#', '#..#'],
    'O': ['.#.', '#.#', '#.#', '#.#', '.#.'],
    'R': ['##.', '#.#', '##.', '#.#', '#.#'],
    'S': ['.##', '#..', '.#.', '..#', '##.'],
    'T': ['###', '.#.', '.#.', '.#.', '.#.'],
    'W': ['#.#', '#.#', '###', '###', '#.#'],
    'I': ['###', '.#.', '.#.', '.#.', '###'],
}
WIDE_W = ['#...#', '#...#', '#.#.#', '#.#.#', '.#.#.']


def hexc(text):
    return (int(text[0:2], 16), int(text[2:4], 16), int(text[4:6], 16), 255)


def blank(w, h, colour=CLEAR):
    return [[colour] * w for _ in range(h)]


def put(px, x, y, colour):
    if 0 <= y < len(px) and 0 <= x < len(px[0]):
        px[y][x] = colour


def rect(px, x, y, w, h, colour):
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            put(px, xx, yy, colour)


def glyphs(word, wide_w=False):
    return [WIDE_W if (ch == 'W' and wide_w) else FONT[ch] for ch in word]


def word_width(word, wide_w=False, scale=1):
    g = glyphs(word, wide_w)
    return (sum(len(x[0]) for x in g) + len(g) - 1) * scale


def text(px, word, x, y, colour, wide_w=False, scale=1):
    for g in glyphs(word, wide_w):
        for gy, line in enumerate(g):
            for gx, ch in enumerate(line):
                if ch == '#':
                    rect(px, x + gx * scale, y + gy * scale, scale, scale, colour)
        x += (len(g[0]) + 1) * scale


def noise(x, y, seed=0):
    n = (x * 374761393 + y * 668265263 + seed * 2147483647) & 0xffffffff
    n = ((n ^ (n >> 13)) * 1274126177) & 0xffffffff
    return (n >> 8) % 100


# ---------------------------------------------------------------- the cork board

WOOD_LINE = hexc('1c120c')
WOOD_DARK = hexc('3a2416')
WOOD = hexc('5a3a22')
WOOD_LIT = hexc('7a5232')
CORK = hexc('8a5e38')
CORK_DARK = hexc('74492a')
CORK_LIT = hexc('9c6e44')
CARD = hexc('d6c49a')
CARD_DARK = hexc('a8946a')
HEADER_INK = hexc('6a1c16')
PIN_BRASS = hexc('c8a050')
PIN_DARK = hexc('6a4a18')


def poster_board():
    w, h = BOARD
    px = blank(w, h)
    # Cork, speckled, with a soft shade under the top rail.
    for y in range(3, h - 3):
        for x in range(3, w - 3):
            n = noise(x, y, 1)
            c = CORK_DARK if n < 14 else (CORK_LIT if n > 90 else CORK)
            if y in (3, 4):
                c = CORK_DARK
            px[y][x] = c
    # The frame: three pixels of dark wood, lit along its top and left, a black line outside.
    for y in range(h):
        for x in range(w):
            edge = min(x, y, w - 1 - x, h - 1 - y)
            if edge == 0:
                px[y][x] = WOOD_LINE
            elif edge < 3:
                lit = (y == 1 or x == 1) and not (y == h - 2 or x == w - 2)
                dark = y >= h - 3 or x >= w - 3
                px[y][x] = WOOD_LIT if lit else (WOOD_DARK if dark else WOOD)
    # Wood grain on the long rails.
    for x in range(4, w - 4, 7):
        put(px, x, 2, WOOD_DARK)
        put(px, x + 3, h - 2, WOOD_LINE)
    # The WANTED card, pinned at its two top corners, in letters two pixels to the dot.
    word = 'WANTED'
    tw = word_width(word, wide_w=True, scale=2)
    cw, ch = tw + 8, 15
    cx, cy = (w - cw) // 2, 5
    rect(px, cx + 1, cy + 1, cw, ch, WOOD_LINE)
    rect(px, cx, cy, cw, ch, CARD)
    rect(px, cx, cy + ch - 1, cw, 1, CARD_DARK)
    rect(px, cx + cw - 1, cy, 1, ch, CARD_DARK)
    text(px, word, cx + 4, cy + 3, HEADER_INK, wide_w=True, scale=2)
    for pin_x in (cx + 2, cx + cw - 3):
        put(px, pin_x, cy + 1, PIN_BRASS)
        put(px, pin_x, cy + 2, PIN_DARK)
    return tone(px, KEPT)


# ---------------------------------------------------------------- the posters

PAPER_TONES = [hexc('cdb88e'), hexc('c2ab80'), hexc('b39c72')]
PAPER_EDGE = hexc('8c7652')
PAPER_CLOSED = [hexc('8e877a'), hexc('857e72'), hexc('77705f')]
PAPER_CLOSED_EDGE = hexc('5a5448')
PRINT_INK = hexc('3a281a')
SEPIA_DARK = (52, 36, 24)
SEPIA_LIGHT = (214, 192, 148)


def paper(tones, edge):
    w, h = PAPER
    px = blank(w, h)
    for y in range(h):
        for x in range(w):
            n = noise(x, y, 7)
            px[y][x] = tones[2] if n < 8 else (tones[1] if n < 30 else tones[0])
    for x in range(w):
        px[h - 1][x] = edge
    for y in range(h):
        px[y][w - 1] = edge
    # A turned-up bottom right corner, and a darker top left one, where the paper has aged.
    px[h - 1][w - 1] = CLEAR
    px[h - 2][w - 2] = edge
    px[0][0] = tones[2]
    # The portrait's printed border.
    x0, y0 = PORTRAIT_AT
    pw, ph = PORTRAIT
    for x in range(x0 - 1, x0 + pw + 1):
        px[y0 - 1][x] = PRINT_INK
        px[y0 + ph][x] = PRINT_INK
    for y in range(y0 - 1, y0 + ph + 1):
        px[y][x0 - 1] = PRINT_INK
        px[y][x0 + pw] = PRINT_INK
    # A brass pin at the top.
    mid = w // 2 - 1
    px[0][mid] = PIN_BRASS
    px[0][mid + 1] = PIN_DARK
    return px


STAMPS = {
    'reward': ('REWARD', hexc('a02a22')),
    'denied': ('DENIED', hexc('a02a22')),
    'taken': ('TAKEN', hexc('2c3e78')),
    'closed': ('CLOSED', hexc('241e1a')),
}


# A rubber stamp across the poster: a rule, the word with a clear row either side, a rule, with a few
# pixels missing from the rules as real ink does (never from the word, so it stays legible).
def stamp(word, ink):
    w, h = STAMP
    px = blank(w, h)
    for x in range(w):
        if noise(x, 0, 3) > 12:
            px[0][x] = ink
        if noise(x, 6, 4) > 12:
            px[h - 1][x] = ink
    text(px, word, (w - word_width(word)) // 2, 2, ink)
    return px


def cross():
    w, h = PORTRAIT
    px = blank(w, h)
    ink = hexc('241e1a')
    for i in range(w):
        y = round(i * (h - 1) / (w - 1))
        put(px, i, y, ink)
        put(px, i, h - 1 - y, ink)
        put(px, i, min(h - 1, y + 1), ink)
        put(px, i, max(0, h - 2 - y), ink)
    return px


# The bust: the figure's head and shoulders, found by its torso's middle column and the top of the head
# above it, cut square and shrunk by a box filter that weighs each pixel by its alpha.
def bust(path, out_w, out_h, side_share=0.5):
    src = hard_alpha(load(path))
    sh, sw = len(src), len(src[0])
    rows = [y for y in range(sh) if any(p[3] for p in src[y])]
    y0, y1 = rows[0], rows[-1] + 1
    height = y1 - y0
    torso = [x for y in range(y0 + int(height * 0.3), y0 + int(height * 0.6)) for x in range(sw) if src[y][x][3]]
    torso.sort()
    cx = torso[len(torso) // 2] + 0.5
    reach = height * 0.18
    head_top = next(y for y in range(y0, y1) if any(src[y][x][3] for x in range(int(cx - reach), int(cx + reach) + 1) if 0 <= x < sw))
    side = height * side_share
    cut_h = side * out_h / out_w
    left, top = cx - side / 2.0, head_top - side * 0.06
    out = blank(out_w, out_h)
    for oy in range(out_h):
        for ox in range(out_w):
            ax, bx = left + ox * side / out_w, left + (ox + 1) * side / out_w
            ay, by = top + oy * cut_h / out_h, top + (oy + 1) * cut_h / out_h
            acc = [0.0, 0.0, 0.0]
            cover = 0.0
            total = 0.0
            for sy in range(int(ay), int(by) + 1):
                for sx in range(int(ax), int(bx) + 1):
                    fy = max(0.0, min(by, sy + 1) - max(ay, sy))
                    fx = max(0.0, min(bx, sx + 1) - max(ax, sx))
                    wgt = fx * fy
                    if wgt <= 0:
                        continue
                    total += wgt
                    if 0 <= sy < sh and 0 <= sx < sw and src[sy][sx][3]:
                        p = src[sy][sx]
                        for i in range(3):
                            acc[i] += p[i] * wgt
                        cover += wgt
            if total and cover / total >= 0.45:
                out[oy][ox] = tuple(int(acc[i] / cover) for i in range(3)) + (255,)
    return out


def sepia(px, keep=0.3):
    out = []
    for row in px:
        line = []
        for p in row:
            lum = (p[0] * 0.299 + p[1] * 0.587 + p[2] * 0.114) / 255.0
            lum = min(1.0, lum * 1.15)
            s = [SEPIA_DARK[i] + (SEPIA_LIGHT[i] - SEPIA_DARK[i]) * lum for i in range(3)]
            line.append(tuple(int(s[i] * (1 - keep) + p[i] * keep) for i in range(3)) + (255,))
        out.append(line)
    return out


# A printed photo: the bust over a plain backdrop a shade under the paper, all toned to sepia.
def poster_portrait(path):
    w, h = PORTRAIT
    figure = bust(path, w, h)
    backdrop = hexc('a8946c')
    px = [[figure[y][x] if figure[y][x][3] else backdrop for x in range(w)] for y in range(h)]
    return sepia(px)


def unknown_portrait():
    w, h = PORTRAIT
    px = blank(w, h, hexc('a8946c'))
    shade = hexc('5a4630')
    # A plain head-and-shoulders shape, for a poster whose boss has no picture yet.
    for y in range(h):
        for x in range(w):
            if (x - 7.5) ** 2 + (y - 5.0) ** 2 <= 10.0 or (y >= 10 and abs(x - 7.5) <= 2 + (y - 10) * 1.5):
                px[y][x] = shade
    return px


# ---------------------------------------------------------------- the portrait wall

FRAME_LINE = hexc('140c08')
FRAME_WOOD = hexc('3e2616')
FRAME_WOOD_LIT = hexc('5c3a22')
FRAME_WOOD_DARK = hexc('2a1a10')
BEVEL = hexc('b08a42')
BEVEL_DARK = hexc('6e5222')
BACKING = hexc('2a2030')
BACKING_DARK = hexc('201828')


def trophy_frame():
    s = FRAME
    px = blank(s, s)
    for y in range(s):
        for x in range(s):
            edge = min(x, y, s - 1 - x, s - 1 - y)
            if edge == 0:
                c = FRAME_LINE
            elif edge == 1:
                c = FRAME_WOOD_LIT if (x == 1 or y == 1) and x < s - 2 and y < s - 2 else FRAME_WOOD_DARK
            elif edge == 2:
                # The brass bevel, lit on top and left, shaded on bottom and right.
                c = BEVEL if x < s - 3 and y < s - 3 else BEVEL_DARK
            else:
                c = BACKING_DARK if (x + y) % 5 == 0 else BACKING
            px[y][x] = c
    # Two little brass corner pieces.
    for cx_, cy_ in ((1, 1), (s - 2, 1), (1, s - 2), (s - 2, s - 2)):
        px[cy_][cx_] = BEVEL
    return tone(px, KEPT)


def trophy_portrait(path):
    face = bust(path, FACE, FACE, side_share=0.52)
    return tone(outline_again(face, hexc('120c10')), KEPT)


BRASS_LINE = hexc('3a2610')
BRASS_LIT = hexc('ecd08a')
BRASS = hexc('c89c4c')
BRASS_MID = hexc('b08638')
BRASS_DARK = hexc('7c5a22')


# A brass plate in three parts across: caps of `cap` columns at each end and one middle column the
# game stretches. Rounded corners, lit top, shaded bottom, a screw in each cap of a plaque.
def brass(cap, h, screws):
    w = cap * 2 + 1
    px = blank(w, h)
    for y in range(h):
        for x in range(w):
            corner = (x in (0, w - 1)) and (y in (0, h - 1))
            if corner:
                continue
            if x in (0, w - 1) or y in (0, h - 1):
                c = BRASS_LINE
            elif y == 1:
                c = BRASS_LIT
            elif y == h - 2:
                c = BRASS_DARK
            elif y >= h * 0.6:
                c = BRASS_MID
            else:
                c = BRASS
            px[y][x] = c
    if screws:
        for sx in (2, w - 3):
            px[h // 2][sx] = BRASS_DARK
            px[h // 2 - 1][sx] = BRASS_LIT
    return tone(px, KEPT)


# ---------------------------------------------------------------- the cobweb

def line(px, x0, y0, x1, y1, colour):
    dx, dy = abs(x1 - x0), -abs(y1 - y0)
    sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
    err = dx + dy
    while True:
        put(px, x0, y0, colour)
        if x0 == x1 and y0 == y1:
            return
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy


# A web in the top-left corner of a 32 px cell (DecorLayer centres it on the cell and mirrors odd
# variants into the top-right corner, where the code drawing put them): five threads out of the corner
# and three sagging rings across them, thin and grey, flat with no outline, so it reads as a web and
# not as the crossed box the code lines made.
def cobweb():
    px = blank(32, 32)
    thread = (170, 166, 178, 210)
    ring = (150, 146, 160, 190)
    corner = (2, 2)
    ends = [(17, 2), (15, 8), (12, 12), (8, 15), (2, 17)]
    for e in ends:
        line(px, corner[0], corner[1], e[0], e[1], thread)
    for share in (0.35, 0.62, 0.9):
        pts = [(round(corner[0] + (e[0] - corner[0]) * share), round(corner[1] + (e[1] - corner[1]) * share)) for e in ends]
        for a, b in zip(pts, pts[1:]):
            # Each span sags a pixel toward the corner, as a loaded thread does.
            mid = ((a[0] + b[0]) // 2 - (1 if share > 0.5 else 0), (a[1] + b[1]) // 2 - (1 if share > 0.5 else 0))
            line(px, a[0], a[1], mid[0], mid[1], ring)
            line(px, mid[0], mid[1], b[0], b[1], ring)
    return tone(px, KEPT)


# ---------------------------------------------------------------- the dummy

def dummy(export):
    raw = hard_alpha(load(os.path.join(export, 'props2', 'training_dummy.png')))
    rows = [y for y in range(len(raw)) if any(p[3] for p in raw[y])]
    cols = [x for x in range(len(raw[0])) if any(raw[y][x][3] for y in range(len(raw)))]
    fig = [row[cols[0]:cols[-1] + 1] for row in raw[rows[0]:rows[-1] + 1]]
    fw, fh = len(fig[0]), len(fig)
    # One square frame, its feet on the bottom row, two clear rows over the head. Its pale sack is toned
    # down a step, so it never reads as a lamp under the yard's light.
    side = max(fh + 2, fw + 2)
    px = blank(side, side)
    ox = (side - fw) // 2
    oy = side - fh
    for y in range(fh):
        for x in range(fw):
            if fig[y][x][3]:
                px[oy + y][ox + x] = fig[y][x]
    return tone(px, TONE)


def main():
    export, game = sys.argv[1], sys.argv[2]
    out = os.path.join(game, *OUT)

    def keep(name, px):
        save(os.path.join(out, name + '.png'), px)
        print(name, len(px[0]), 'x', len(px))

    keep('poster_board', poster_board())
    keep('poster_paper', tone(paper(PAPER_TONES, PAPER_EDGE), KEPT))
    keep('poster_paper_closed', tone(paper(PAPER_CLOSED, PAPER_CLOSED_EDGE), KEPT))
    for state, (word, ink) in STAMPS.items():
        keep('poster_stamp_' + state, tone(stamp(word, ink), KEPT))
    keep('poster_cross', tone(cross(), KEPT))
    keep('poster_unknown', tone(unknown_portrait(), KEPT))
    for boss in FLOOR_BOSSES + MINI_BOSSES:
        path = os.path.join(export, 'portraits', boss + '.png')
        keep('poster_' + boss, tone(poster_portrait(path), KEPT))
        if boss in FLOOR_BOSSES:
            keep('trophy_' + boss, trophy_portrait(path))
    keep('trophy_frame', trophy_frame())
    keep('brass_plate', brass(3, 10, False))
    keep('brass_plaque', brass(4, 13, True))
    keep('decor_cobweb', cobweb())
    strip = dummy(export)
    save(os.path.join(game, 'art', 'sprites', 'training_dummy', 'idle.png'), strip)
    print('training_dummy idle', len(strip[0]), 'x', len(strip))


if __name__ == '__main__':
    main()
