# Builds the floor exit's cage lift (art/props/lift_closed.png, lift_half.png, lift_open.png) from one
# PixelLab create_map_object export (D:/grandpa-art/direction/lift/raw_d194c6a6.png: an old cage lift in
# a grey stone surround with a brass lattice gate, 48x72, low top-down, single colour outline, basic
# shading, low detail). Plain Python, no packages.
#
# The export is kept as drawn but for three fixes, in the depth look (docs/art/art-direction-notes.md):
# - its dial above the gate showed an up arrow; it is redrawn by hand as a brass floor indicator with
#   tick marks and a needle leaning down (never an arrow or cross shape, which read as a cross);
# - its rail rivets were a red close to the warning red (#e93934 beside #e4524f), so they become brass;
# - the open states are made from the closed one: each leaf of the lattice gate folds to its side of the
#   frame (to FOLD_HALF, then FOLD_OPEN columns wide), showing the dark car behind with its floor boards.
#
# Usage: py tools/art/lift_art.py <export png> <game root>
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from env_art import load, save  # noqa: E402


def hexc(text):
    return (int(text[0:2], 16), int(text[2:4], 16), int(text[4:6], 16), 255)


OUTLINE = hexc("110e21")
BRASS = hexc("f3c161")
BRASS_MID = hexc("c09e36")
BRASS_DARK = hexc("7d5c34")
WOOD_DARK = hexc("423420")
WOOD = hexc("6a4f30")
# The lit side of a folded bar, the gate's own mid brass.
BAR_LIT = hexc("a37533")
CAR_WALL = hexc("151226")
CAR_SEAM = hexc("191629")
CAR_FLOOR = hexc("2b251a")
CAR_FLOOR_EDGE = hexc("57442a")
ARROW = hexc("222031")
PALE = hexc("eeeef1")
RIVET_RED = (0xe9, 0x39, 0x34)

# The gate's box inside the frame (x from GATE_X0 to GATE_X1, rows GATE_Y0 to GATE_Y1, inclusive): the
# lattice and its rails, read off the export. The threshold boards below stay.
GATE_X0, GATE_X1 = 13, 35
GATE_Y0, GATE_Y1 = 17, 66
FOLD_HALF = 6
FOLD_OPEN = 3
# The dial's middle, over the gate.
DIAL = (24, 11)


def copy(pixels):
    return [list(row) for row in pixels]


def recolour_rivets(px):
    for row in px:
        for x, p in enumerate(row):
            if p[3] > 0 and p[:3] == RIVET_RED:
                row[x] = BRASS_MID


def draw_dial(px):
    cx, cy = DIAL
    # An old floor indicator: a brass disc with a dark rim, three tick marks round its top and one
    # needle leaning down to the left (to the lowest floor). No straight cross or arrow shape: an
    # upright line with a bar across it reads as a cross at this size, which the game must not show.
    for y in range(cy - 3, cy + 4):
        for x in range(cx - 3, cx + 4):
            d = (x - cx) ** 2 + (y - cy) ** 2
            # Radius under 3, so the disc has no single-pixel bumps at its top, bottom and sides.
            if d <= 8:
                px[y][x] = BRASS if d <= 5 else BRASS_MID
            elif d <= 13 and px[y][x][3] > 0:
                px[y][x] = OUTLINE
    for (x, y) in [(cx - 2, cy - 1), (cx, cy - 2), (cx + 2, cy - 1)]:
        px[y][x] = BRASS_DARK
    for (x, y) in [(cx, cy), (cx - 1, cy + 1), (cx - 2, cy + 2)]:
        px[y][x] = ARROW


# The rows of the gate's three rails (top, middle, bottom), which fold with the leaves.
RAIL_ROWS = [range(17, 21), range(41, 45), range(63, 67)]


def folded_leaf(px, closed, x0, width, edge):
    # A leaf folded up: its bars packed side by side, lit and shaded in turn, crossed by the three
    # rails (copied from the gate's own edge column, edge), with a dark line where it meets the car.
    rails = [y for rows in RAIL_ROWS for y in rows]
    for i in range(width):
        x = x0 + i
        for y in range(GATE_Y0, GATE_Y1 + 1):
            if y in rails:
                px[y][x] = closed[y][edge]
            else:
                px[y][x] = BAR_LIT if i % 2 == 0 else WOOD


def car(px):
    # The empty car behind the gate: a dark back wall with panel seams, and its floor boards.
    floor_from = GATE_Y1 - 6
    for y in range(GATE_Y0, GATE_Y1 + 1):
        for x in range(GATE_X0, GATE_X1 + 1):
            if y >= floor_from:
                px[y][x] = CAR_FLOOR_EDGE if y == floor_from else (CAR_FLOOR if (x + y) % 5 else WOOD_DARK)
            elif (x - GATE_X0) % 5 == 2:
                px[y][x] = CAR_SEAM
            else:
                px[y][x] = CAR_WALL
    # A small brass lamp on the car's back wall.
    mid = (GATE_X0 + GATE_X1) // 2
    for x in (mid, mid + 1):
        px[GATE_Y0 + 3][x] = BRASS
        px[GATE_Y0 + 4][x] = BRASS_MID


def opened(closed, width):
    px = copy(closed)
    car(px)
    folded_leaf(px, closed, GATE_X0, width, GATE_X0 + 2)
    folded_leaf(px, closed, GATE_X1 - width + 1, width, GATE_X1 - 2)
    for y in range(GATE_Y0, GATE_Y1 + 1):
        px[y][GATE_X0 + width] = OUTLINE
        px[y][GATE_X1 - width] = OUTLINE
    return px


def main():
    export, game = sys.argv[1], sys.argv[2]
    closed = copy(load(export))
    recolour_rivets(closed)
    draw_dial(closed)
    out = os.path.join(game, "art", "props")
    save(os.path.join(out, "lift_closed.png"), closed)
    save(os.path.join(out, "lift_half.png"), opened(closed, FOLD_HALF))
    save(os.path.join(out, "lift_open.png"), opened(closed, FOLD_OPEN))
    print("wrote lift_closed, lift_half, lift_open", len(closed[0]), "x", len(closed))


if __name__ == "__main__":
    main()
