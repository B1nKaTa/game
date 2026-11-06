# Builds Harold's strips (idle.png, walk.png, attack.png in art/sprites/grandpa/) from his PixelLab export.
# Every frame goes onto one 60 px canvas, centred across, with its lowest used row (his feet) on FEET_ROW,
# so the strips share Player.SPRITE_FRAME_WIDTH and his feet stay on one row in every frame and strip.
# The idle is the east breathing loop, the walk drops the export's standing reference frame, and the
# attack keeps four of the nine swing frames so the cane is out while the swing hits (see FRAMES).
# Plain Python, no packages.
# Usage: py tools/art/harold_strips.py <export folder holding Idle/> <art/sprites/grandpa folder>
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from npc_strips import join, load  # noqa: E402

SIZE = 60
# Row 52 of a centred 60 px frame ends 23 px below the middle: Player.SPRITE_FEET_Y, his feet box's bottom.
FEET_ROW = 52
FRAMES = {
    # The 2026-11-06 chunky redraw (D:/grandpa-art/direction/harold/harold_v4): frame 0 of every export
    # is the reference pose, so the idle loops its four breathing frames.
    'idle': ('idle', range(1, 5)),
    'walk': ('walk', range(1, 9)),
    # The swing hits at once and for its first half, so it opens on the cane thrust level (7), holds it
    # out low (8) while the arc shows, then draws it back down (2) to the rest pose (1).
    'attack': ('attack', [7, 8, 2, 1]),
}


def place(frame):
    width, height, rows = frame
    used = [y for y in range(height) if any(rows[y][x * 4 + 3] for x in range(width))]
    shift_y = FEET_ROW - used[-1]
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
    os.makedirs(target, exist_ok=True)
    for name, (anim, picks) in FRAMES.items():
        folder = os.path.join(source, 'Idle', 'animations', anim, 'east')
        frames = [place(load(os.path.join(folder, 'frame_%03d.png' % i))) for i in picks]
        join(frames, os.path.join(target, name + '.png'))
        print(name, len(frames))


if __name__ == '__main__':
    main()
