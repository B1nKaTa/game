# Cuts Harold's extra anims from frame folders (D:/grandpa-art/harold/<set>/<anim>/, east-facing PNGs,
# see that folder's notes.md) into art/sprites/<set>/<anim>.png: every frame on one 60 px canvas, feet on
# row 52, as harold_strips.py places his export, so Player.SPRITE_FRAME_WIDTH and SPRITE_FEET_Y hold.
# Only the anims whose folder exists are written; nothing else in the target is touched.
# A 64 px export is centred onto the 60 px canvas (2 px of empty margin cut each side, nothing resampled);
# the tool refuses a frame that would lose a drawn pixel.
# Plain Python, no packages.
# Usage: py -I tools/art/harold_anims.py <set folder> <art/sprites/<set> folder> [anim ...]
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from npc_strips import join, load  # noqa: E402
from harold_strips import FEET_ROW, SIZE  # noqa: E402

ANIMS = ('idle', 'walk', 'attack', 'hurt', 'death', 'dodge')
# The export's frame 000 is PixelLab's standing reference pose, never part of the motion.
FRAME = re.compile(r'^east_frame_(\d{3})\.png$')
# Export frames to leave out, per (set, anim). The reference frame 0 goes everywhere (see frames_in).
DROP = {}
# Strip index (export frame - 1) to play, in order, for the anims whose hit window needs choosing. The
# swing hits for SwingAttack.DURATION (0.1 s) of the EraMoves lock, and the strip plays once over that
# lock, so the first ceil(0.1 / lock * count) frames show while it hits.
# Dance Hall spin (lock 0.14 s, 4 frames, 3 in the window): the arms-out frames 5, 6 (widest), 7, then
# frame 0 back to facing east, so the snap to idle is a small one.
# Allotment spade (lock 0.5 s, 8 frames, 2 in the window): full reach 5, 6, then 7 and 4 still far out,
# and the export's wind-up played backwards (3, 2, 1, 0) as the spade is drawn back.
PICKS = {
    ('harold_1962', 'attack'): (5, 6, 7, 0),
    ('harold_1988', 'attack'): (5, 6, 7, 4, 3, 2, 1, 0),
}
# A dodge keeps its hop: one shift for the whole strip, set by its lowest frame, instead of putting every
# frame's lowest row on the feet row.
HOPS = ('dodge',)


def frames_in(folder, drop=()):
    names = sorted(n for n in os.listdir(folder) if FRAME.match(n))
    names = names[1:]
    return [os.path.join(folder, n) for i, n in enumerate(names) if i + 1 not in drop]


def drawn(frame):
    width, height, rows = frame
    return sum(1 for row in rows for x in range(width) if row[x * 4 + 3])


def bottom(frame):
    width, height, rows = frame
    return max(y for y in range(height) if any(rows[y][x * 4 + 3] for x in range(width)))


def cut(frames, hop):
    if hop:
        lowest = max(bottom(f) for f in frames)
        placed = [place_at(f, lowest) for f in frames]
    else:
        placed = [place_at(f, bottom(f)) for f in frames]
    for src, out in zip(frames, placed):
        if drawn(src) != drawn(out):
            raise ValueError('a frame loses %d drawn pixels on the %d px canvas' % (drawn(src) - drawn(out), SIZE))
    return placed


def place_at(frame, lowest):
    width, height, rows = frame
    shift_y = FEET_ROW - lowest
    shift_x = (SIZE - width) // 2
    out = [bytearray(SIZE * 4) for _ in range(SIZE)]
    for y in range(height):
        ty = y + shift_y
        if 0 <= ty < SIZE:
            for x in range(width):
                tx = x + shift_x
                if 0 <= tx < SIZE and rows[y][x * 4 + 3]:
                    out[ty][tx * 4:tx * 4 + 4] = rows[y][x * 4:x * 4 + 4]
    if any(out[0][x * 4 + 3] for x in range(SIZE)):
        raise ValueError('a frame reaches the top of the canvas')
    return SIZE, SIZE, out


def main():
    source, target = sys.argv[1], sys.argv[2]
    wanted = sys.argv[3:] or ANIMS
    set_name = os.path.basename(os.path.normpath(source))
    os.makedirs(target, exist_ok=True)
    for anim in wanted:
        folder = os.path.join(source, anim)
        if not os.path.isdir(folder):
            print(anim, 'missing')
            continue
        paths = frames_in(folder, DROP.get((set_name, anim), ()))
        loaded = [load(p) for p in paths]
        picks = PICKS.get((set_name, anim))
        if picks is not None:
            loaded = [loaded[i] for i in picks]
        frames = cut(loaded, anim in HOPS)
        join(frames, os.path.join(target, anim + '.png'))
        print(set_name, anim, len(frames))


if __name__ == '__main__':
    main()
