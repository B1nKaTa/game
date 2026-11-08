# Builds the title screen's art (art/title/) from its PixelLab exports (D:/grandpa-art/title/raw), and
# writes scripts/core/title_frames.gd with the frame layout and Harold's per-frame anchors.
#
# - The room's backdrop and props are toned down onto the dim waiting room (TONE); the bodies keep their
#   own light, as in the depth look.
# - Seated Harold is a state of his own PixelLab character (the same 44 px chunky redraw as his strips),
#   facing south-west, with three idles (cane tap, ticket check, sigh). Every frame goes on one 64 px
#   canvas, export-centred, with stray specks (motion lines) cleared.
# - His cardigan outfits use harold_outfits.py's own ramp and five cardigan tones, as in play, into
#   harold_<cosmetic id>.png. His cane is found per frame (the tall thin run of cane browns, apart from
#   his trousers' same browns) and written to harold_cane.png, its light and dark tones as two greys, so
#   a cane cosmetic can recolour only the cane (TitleHarold's shader).
# - Hats are drawn in code over the head anchor (GrandpaLook.draw_hat), and the Power Tie at the tie
#   anchor (GrandpaLook.draw_tie): for each frame, the anchor follows the hair's top and middle, the
#   way GrandpaLook.HEAD sits 6 px under the top of his hair in play, and the tie hangs from the top of
#   his shirt front.
# - Each ghost is a seated state of its own character: front and turned rotations, talk, cross legs,
#   shift and stand up, then the standing rotations for drifting along the row, on one 64 px canvas.
#
# Plain Python, no packages. Usage: py tools/art/title_art.py D:/grandpa-art/title/raw <project folder>
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from npc_strips import load, save  # noqa: E402
from harold_outfits import CARDIGAN, cosmetic_colours, ramp  # noqa: E402

HAROLD_SIZE = 64
GHOST_SIZE = 64
# Room props are toned to this share of their colour, cooled a little; the wall darker still.
TONE = {'wall': (0.36, 0.06), 'chair': (0.66, 0.02), 'machine': (0.70, 0.02), 'lamp': (0.80, 0.0), 'board': (0.72, 0.0)}
HAROLD_ANIMS = (('cane_tap', 8), ('ticket_check', 8), ('sigh', 8))
GHOST_ANIMS = (('talk', 'south-east'), ('cross_legs', 'south-east'), ('shift', 'south-east'), ('stand_up', 'south'))
CANE_TONES = {'7a4736': 255, '472a2f': 150, '4d2a36': 150}
# On the 64 px canvas his trousers start at x = 23; the cane's pieces are never this many pixels.
TROUSERS_X = 23
CANE_MAX_GROUP = 20
SHIRT = ('eceeee', 'c9cfd6', 'b4bccb', '9196a4')
OUTLINE_MAX = 40
# His trousers' browns, and how many columns at their back end his seat spans.
TROUSERS = ('472a2f', '7a4736', '342427', '4d2a36')
SEAT_SPAN = 6
# A seated ghost's body ends where its rows narrow below this share of its widest row.
SIT_SHARE = 0.7
# The chair export: its seat's front lip ends on this row, and the sitters sit on CHAIR_SEAT_ROW, just
# inside the lip. LEG_CUT rows of leg come out under the lip, so the seat line stands as high over the
# floor as Harold's thighs do (8 to 9 px).
CHAIR_LIP_END = 28
CHAIR_SEAT_ROW = 27
LEG_CUT = 10


def px(rows, x, y):
    return bytes(rows[y][x * 4:x * 4 + 4])


def blank(size):
    return [bytearray(size * 4) for _ in range(size)]


def place(frame, size):
    """The export frame on a size canvas, centred as the export was centred."""
    w, h, rows = frame
    ox, oy = (size - w) // 2, (size - h) // 2
    out = blank(size)
    for y in range(h):
        for x in range(w):
            if 0 <= y + oy < size and 0 <= x + ox < size:
                out[y + oy][(x + ox) * 4:(x + ox) * 4 + 4] = rows[y][x * 4:x * 4 + 4]
    return out


def components(rows, size, keep):
    """4-connected groups of the pixels keep(x, y) accepts."""
    seen = set()
    groups = []
    for y in range(size):
        for x in range(size):
            if (x, y) in seen or not keep(x, y):
                continue
            group = []
            todo = [(x, y)]
            seen.add((x, y))
            while todo:
                cx, cy = todo.pop()
                group.append((cx, cy))
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < size and 0 <= ny < size and (nx, ny) not in seen and keep(nx, ny):
                        seen.add((nx, ny))
                        todo.append((nx, ny))
            groups.append(group)
    return groups


def clear_specks(rows, size):
    """Keeps only the largest 8-connected body of opaque pixels (drops motion lines and specks)."""
    seen = set()
    groups = []
    for y in range(size):
        for x in range(size):
            if (x, y) in seen or rows[y][x * 4 + 3] == 0:
                continue
            group = []
            todo = [(x, y)]
            seen.add((x, y))
            while todo:
                cx, cy = todo.pop()
                group.append((cx, cy))
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < size and 0 <= ny < size and (nx, ny) not in seen and rows[ny][nx * 4 + 3]:
                            seen.add((nx, ny))
                            todo.append((nx, ny))
            groups.append(group)
    groups.sort(key=len, reverse=True)
    cleared = 0
    for group in groups[1:]:
        for x, y in group:
            rows[y][x * 4:x * 4 + 4] = bytes(4)
            cleared += 1
    return cleared


def cane_pixels(rows, size):
    """The cane: the small groups of cane browns west of his trousers. The trousers share the browns but
    are big groups from x = TROUSERS_X on; a swung cane breaks into several one-pixel-wide pieces."""
    def keep(x, y):
        return rows[y][x * 4 + 3] and px(rows, x, y)[:3].hex() in CANE_TONES
    cane = []
    for group in components(rows, size, keep):
        xs = [p[0] for p in group]
        # Pieces of the cane are one or two pixels wide; his shoes' browns lie flat.
        if len(group) < CANE_MAX_GROUP and min(xs) < TROUSERS_X and max(xs) - min(xs) <= 1:
            cane += group
    if len(cane) < 4:
        raise ValueError('no cane found in a seated frame')
    return cane


def head_anchor(rows, size):
    """Where a hat goes: the middle of the hair's top rows, 6 px under the top of the hair."""
    top = None
    for y in range(size):
        for x in range(size):
            if rows[y][x * 4 + 3] and sum(rows[y][x * 4:x * 4 + 3]) > OUTLINE_MAX * 3:
                top = y
                break
        if top is not None:
            break
    xs = []
    for y in range(top, top + 4):
        xs += [x for x in range(size) if rows[y][x * 4 + 3]]
    return ((min(xs) + max(xs) + 1) / 2.0, top + 6)


def tie_anchor(rows, size, head):
    """Where the Power Tie's knot goes: the top of his white shirt front under the beard."""
    shirt = [(x, y) for y in range(int(head[1]) + 8, size) for x in range(size)
             if rows[y][x * 4 + 3] and px(rows, x, y)[:3].hex() in SHIRT]
    if not shirt:
        return (head[0], head[1] + 12)
    top = min(y for x, y in shirt)
    xs = [x for x, y in shirt if y <= top + 2]
    return ((min(xs) + max(xs) + 1) / 2.0, top + 1)


def harold_sit(rows, size):
    """Where he sits on the seat: the underside of his thighs at their back end (he faces south-west, so
    his seat is at the east end of his trousers), the lowest trouser row within SEAT_SPAN columns of
    that end, and the middle of those columns."""
    cane = set(cane_pixels(rows, size))
    trousers = [(x, y) for y in range(size) for x in range(size)
                if rows[y][x * 4 + 3] and px(rows, x, y)[:3].hex() in TROUSERS and (x, y) not in cane]
    back = max(x for x, y in trousers)
    seat = [(x, y) for x, y in trousers if x > back - SEAT_SPAN]
    return ((back - SEAT_SPAN / 2.0) + 1.0, max(y for x, y in seat) + 1)


def ghost_sit(rows, size):
    """Where a seated ghost sits: the bottom of its body, the last row, going down from its widest row,
    whose span is still at least SIT_SHARE of that width (below it only the legs hang), and the middle
    of that row."""
    spans = []
    for y in range(size):
        xs = [x for x in range(size) if rows[y][x * 4 + 3]]
        spans.append((max(xs) - min(xs) + 1, min(xs), max(xs)) if xs else (0, 0, 0))
    widest = max(range(size), key=lambda y: spans[y][0])
    y = widest
    while y + 1 < size and spans[y + 1][0] >= spans[widest][0] * SIT_SHARE:
        y += 1
    return ((spans[y][1] + spans[y][2] + 1) / 2.0, y + 1)


def chair_parts(raw, out_dir):
    """The chair cut down to the sitters' legs: LEG_CUT rows of its legs come out, so its seat line
    (CHAIR_SEAT_ROW) sits as far over the floor as their thighs do. Its front legs, from just under the
    seat's front lip down, go into chair_front.png, drawn over the sitter."""
    w, h, rows = load(os.path.join(raw, 'chair.png'))
    share, cool = TONE['chair']
    for row in rows:
        for x in range(w):
            r, g, b = row[x * 4:x * 4 + 3]
            row[x * 4] = int(r * share * (1.0 - cool))
            row[x * 4 + 1] = int(g * share * (1.0 - cool * 0.5))
            row[x * 4 + 2] = int(b * share)
    kept = rows[:CHAIR_LIP_END + 1] + rows[CHAIR_LIP_END + 1 + LEG_CUT:]
    kept += [bytearray(w * 4) for _ in range(h - len(kept))]
    front = [bytearray(r) if y > CHAIR_LIP_END else bytearray(w * 4) for y, r in enumerate(kept)]
    save(os.path.join(out_dir, 'chair.png'), w, h, kept)
    save(os.path.join(out_dir, 'chair_front.png'), w, h, front)
    return max(y for y in range(h) if any(kept[y][x * 4 + 3] for x in range(w)))


def strip(frames, size):
    out = [bytearray() for _ in range(size)]
    for frame in frames:
        for y in range(size):
            out[y] += frame[y]
    return size * len(frames), size, out


def tone(path, out, share, cool):
    w, h, rows = load(path)
    for row in rows:
        for x in range(w):
            r, g, b = row[x * 4:x * 4 + 3]
            row[x * 4] = int(r * share * (1.0 - cool))
            row[x * 4 + 1] = int(g * share * (1.0 - cool * 0.5))
            row[x * 4 + 2] = int(b * share)
    save(out, w, h, rows)


def harold_frames(raw):
    base = os.path.join(raw, 'harold_seated', 'Seated')
    files = [os.path.join(base, 'rotations', 'south-west.png')]
    names = ['rest']
    for anim, count in HAROLD_ANIMS:
        for i in range(1, count + 1):
            files.append(os.path.join(base, 'animations', anim, 'south-west', 'frame_%03d.png' % i))
            names.append(anim)
    frames = []
    for f in files:
        rows = place(load(f), HAROLD_SIZE)
        clear_specks(rows, HAROLD_SIZE)
        frames.append(rows)
    return frames, names


def ghost_frames(raw, ghost):
    seated = os.path.join(raw, ghost, 'Seated')
    standing = os.path.join(raw, ghost, 'Idle')
    files = [os.path.join(seated, 'rotations', 'south.png'), os.path.join(seated, 'rotations', 'south-east.png')]
    for anim, direction in GHOST_ANIMS:
        for i in range(1, 9):
            files.append(os.path.join(seated, 'animations', anim, direction, 'frame_%03d.png' % i))
    files += [os.path.join(standing, 'rotations', 'south.png'), os.path.join(standing, 'rotations', 'south-east.png')]
    frames = []
    for f in files:
        rows = place(load(f), GHOST_SIZE)
        clear_specks(rows, GHOST_SIZE)
        frames.append(rows)
    return frames


def lowest_row(rows, size):
    for y in range(size - 1, -1, -1):
        if any(rows[y][x * 4 + 3] for x in range(size)):
            return y
    return 0


def main():
    raw, project = sys.argv[1], sys.argv[2]
    out_dir = os.path.join(project, 'art', 'title')
    os.makedirs(out_dir, exist_ok=True)
    for name, (share, cool) in TONE.items():
        if name == 'chair':
            continue
        source = os.path.join(raw, 'machine_wall.png' if name == 'machine' else name + '.png')
        tone(source, os.path.join(out_dir, name + '.png'), share, cool)
    chair_feet = chair_parts(raw, out_dir)

    frames, names = harold_frames(raw)
    heads, ties, feet, sits = [], [], [], []
    canes = []
    for rows in frames:
        sits.append(harold_sit(rows, HAROLD_SIZE))
        head = head_anchor(rows, HAROLD_SIZE)
        heads.append(head)
        ties.append(tie_anchor(rows, HAROLD_SIZE, head))
        feet.append(lowest_row(rows, HAROLD_SIZE))
        mask = blank(HAROLD_SIZE)
        for x, y in cane_pixels(rows, HAROLD_SIZE):
            v = CANE_TONES[px(rows, x, y)[:3].hex()]
            mask[y][x * 4:x * 4 + 4] = bytes((v, v, v, 255))
        canes.append(mask)
    save(os.path.join(out_dir, 'harold.png'), *strip(frames, HAROLD_SIZE))
    save(os.path.join(out_dir, 'harold_cane.png'), *strip(canes, HAROLD_SIZE))
    swap_from = [bytes.fromhex(c) for c in CARDIGAN]
    outfits = cosmetic_colours(project)
    for cid, rgb in outfits.items():
        tones = ramp(rgb)
        swap = dict(zip(swap_from, tones))
        dressed = []
        changed = 0
        for rows in frames:
            copy = [bytearray(r) for r in rows]
            for row in copy:
                for x in range(HAROLD_SIZE):
                    key = bytes(row[x * 4:x * 4 + 3])
                    if row[x * 4 + 3] and key in swap:
                        row[x * 4:x * 4 + 3] = swap[key]
                        changed += 1
            dressed.append(copy)
        if not changed:
            raise ValueError('the seated frames show none of the cardigan colours')
        save(os.path.join(out_dir, 'harold_%s.png' % cid), *strip(dressed, HAROLD_SIZE))

    ghost_counts = {}
    ghost_rows = {}
    ghost_sits = {}
    for ghost in ('ghost_a', 'ghost_b'):
        gframes = ghost_frames(raw, ghost)
        ghost_counts[ghost] = len(gframes)
        ghost_sits[ghost] = [ghost_sit(rows, GHOST_SIZE) for rows in gframes]
        front = gframes[0]
        top = next(y for y in range(GHOST_SIZE) if any(front[y][x * 4 + 3] for x in range(GHOST_SIZE)))
        ghost_rows[ghost] = (top, lowest_row(front, GHOST_SIZE))
        save(os.path.join(out_dir, ghost + '.png'), *strip(gframes, GHOST_SIZE))

    write_frames(project, names, heads, ties, feet, outfits, ghost_rows, sits, ghost_sits, chair_feet)
    print('harold sits', sorted(set(y for x, y in sits)), 'chair feet row', chair_feet)
    for ghost, gs in ghost_sits.items():
        print(ghost, 'sits', [int(y) for x, y in gs])
    print('harold frames %d, feet rows %s' % (len(frames), sorted(set(feet))))
    print('heads', heads)
    print('ties', ties)
    print('ghost frames', ghost_counts)


def write_frames(project, names, heads, ties, feet, outfits, ghost_rows, sits, ghost_sits, chair_feet):
    starts = {}
    for i, name in enumerate(names):
        starts.setdefault(name, i)
    lines = [
        'class_name TitleFrames',
        'extends RefCounted',
        '',
        '# Written by tools/art/title_art.py; do not edit by hand. The title screen\'s strips in art/title/:',
        '# seated Harold (64 px frames, facing south-west) with the first frame and length of each idle, the',
        '# head anchor a hat is drawn round (GrandpaLook.draw_hat) and the Power Tie\'s knot (draw_tie), both',
        '# from the frame\'s top-left; and the ghosts\' %d px frames.' % GHOST_SIZE,
        '',
        'const HAROLD_SIZE := %d' % HAROLD_SIZE,
        'const HAROLD_FRAMES := %d' % len(names),
        'const HAROLD_REST := 0',
        'const HAROLD_ANIMS := {%s}' % ', '.join('"%s": [%d, %d]' % (a, starts[a], c) for a, c in HAROLD_ANIMS),
        'const HAROLD_FEET_ROW := %d' % max(set(feet), key=feet.count),
        'const HAROLD_HEAD: Array[Vector2] = [%s]' % ', '.join('Vector2(%g, %g)' % h for h in heads),
        'const HAROLD_TIE: Array[Vector2] = [%s]' % ', '.join('Vector2(%g, %g)' % t for t in ties),
        '# Where he sits in each frame: the underside of his thighs at their back end. TitleRoom puts this',
        '# point on his chair\'s seat line in every frame.',
        'const HAROLD_SIT: Array[Vector2] = [%s]' % ', '.join('Vector2(%g, %g)' % t for t in sits),
        '# Cardigans drawn as outfits of the seated strip, as GrandpaLook.outfit_art builds them for play.',
        'const OUTFITS: Array[String] = [%s]' % ', '.join('"%s"' % o for o in sorted(outfits)),
        '',
        'const GHOST_SIZE := %d' % GHOST_SIZE,
        'const GHOST_FRONT := 0',
        'const GHOST_TURNED := 1',
        'const GHOST_ANIMS := {%s}' % ', '.join('"%s": [%d, 8]' % (a, 2 + 8 * i) for i, (a, _d) in enumerate(GHOST_ANIMS)),
        'const GHOST_HOVER := %d' % (2 + 8 * len(GHOST_ANIMS)),
        'const GHOST_DRIFT := %d' % (3 + 8 * len(GHOST_ANIMS)),
        'const GHOST_FRAMES := %d' % (4 + 8 * len(GHOST_ANIMS)),
        '# Each ghost\'s top row and lowest row in its seated front frame (its head and dangling feet).',
        'const GHOST_ROWS := {%s}' % ', '.join('"%s": Vector2i(%d, %d)' % (g, r[0], r[1]) for g, r in sorted(ghost_rows.items())),
        '# Where each ghost sits in each frame: the bottom of its body above its hanging legs.',
        'const GHOST_SIT := {%s}' % ', '.join('"%s": [%s]' % (g, ', '.join('Vector2(%g, %g)' % t for t in gs)) for g, gs in sorted(ghost_sits.items())),
        '',
        '# The chair (art/title/chair.png, its legs cut by LEG_CUT): the row its sitters sit on, and its feet.',
        'const CHAIR_SEAT_ROW := %d' % CHAIR_SEAT_ROW,
        'const CHAIR_FEET_ROW := %d' % chair_feet,
        '',
    ]
    path = os.path.join(project, 'scripts', 'core', 'title_frames.gd')
    with open(path, 'w', encoding='utf-8', newline='\r\n') as f:
        f.write('\n'.join(lines))


if __name__ == '__main__':
    main()
