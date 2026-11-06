# Builds an enemy's strips from its PixelLab export into art/sprites/<id>/<anim>.png, the folder
# SpriteVisual loads (res://art/sprites/<art_id>/<anim>.png). Plain Python, no packages.
# Usage: py tools/art/enemy_strips.py <export folder holding one folder per enemy id> <art/sprites folder> [id ...]
#
# Anims. Every east anim in the export, <id>/<state>/animations/<name>/east/frame_###.png, becomes
# <name>.png, so a new folder (windup, or a boss's own such as summon or charge) is picked up as it lands.
# The names the game asks for are idle, walk, windup and attack (see EnemyAnim), plus whatever a
# behavior names through Enemy.play_anim. idle and walk keep every frame. Every other anim drops
# frame 000, PixelLab's reference pose.
#
# Cuts. CUTS picks frames by hand for one export: the windup out of the first frames of the attack, and
# the attack trimmed to open on the strike, since every enemy's hit lands the moment its windup ends
# (Enemy plays the attack for EnemyAnim.ATTACK_TIME then). A cut only applies to the export it was
# picked from (its frames' hash); a newer export gets the default, and a real folder of the cut's name
# (a generated windup) always wins over a cut.
#
# Canvas. All frames of one actor go onto one square canvas, a multiple of 4 wide, centred across on
# the source canvas's middle column (so a flip keeps the feet in place), with the lowest used row of
# each frame on FEET_ROW. SpriteVisual then puts that row on the body box bottom (+body_size.y / 2).
import hashlib
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from npc_strips import join, load  # noqa: E402

# Rows left empty under the feet.
FOOT_MARGIN = 1
KEEP_FIRST = ('idle', 'walk')

# id -> {game anim: (export anim, frames, hash of the export anim's frames)}. A game anim cut to no
# frames is left out, so the game falls back to its walk or idle.
CUTS = {
    # The scythe drawn back, then the low sweep from the moment it lands.
    'intern_reaper': {'windup': ('attack', [1, 2, 3], '4090bbed'), 'attack': ('attack', [4, 5, 6, 8], '4090bbed')},
    # The shovel lifted back, then the throw with the coal leaving it.
    'stoker': {'windup': ('attack', [1, 2, 3], 'a40730c4'), 'attack': ('attack', [5, 6, 7, 8], 'a40730c4')},
    # His export is a whistle, which he blows after a charge (MallCopBehavior._stop); the charge itself walks.
    'mall_cop': {'whistle': ('attack', [2, 3, 4, 5, 6, 7, 8], '5c2ee994'), 'attack': ('attack', [], '5c2ee994')},
    # The memo raised back, then thrown.
    'hr_representative': {'windup': ('attack', [4, 5, 6, 7], '06a0adcd'), 'attack': ('attack', [8], '06a0adcd')},
    'regional_reaper': {'windup': ('attack', [1, 2], 'cc7370db'), 'attack': ('attack', [3, 4, 5, 6, 7], 'cc7370db')},
    'old_smokey': {'windup': ('attack', [3, 4, 5], 'f5edbd72'), 'attack': ('attack', [6, 7, 8], 'f5edbd72')},
    'thaddeus_fairweather': {'windup': ('attack', [4, 5, 6], 'eb66e3b2'), 'attack': ('attack', [7, 8], 'eb66e3b2')},
    # The gavel raised overhead, then brought down.
    'chairman_of_the_board': {'windup': ('attack', [3, 4, 5, 6], '2c6098a8'), 'attack': ('attack', [7, 8], '2c6098a8')},
}


def frame_hash(files):
    digest = hashlib.sha1()
    for f in files:
        digest.update(open(f, 'rb').read())
    return digest.hexdigest()[:8]


def used(frame):
    width, height, rows = frame
    ys = [y for y in range(height) if any(rows[y][x * 4 + 3] for x in range(width))]
    if not ys:
        return None
    xs = [x for x in range(width) if any(rows[y][x * 4 + 3] for y in ys)]
    return xs[0], ys[0], xs[-1] + 1, ys[-1] + 1


def canvas_size(frames):
    need = 0
    for frame in frames:
        box = used(frame)
        if box is None:
            continue
        middle = frame[0] / 2.0
        need = max(need, 2 * (middle - box[0]), 2 * (box[2] - middle), box[3] - box[1] + FOOT_MARGIN + 1)
    size = int(need + 0.999)
    return size + (-size) % 4


def place(frame, size):
    width, height, rows = frame
    box = used(frame)
    out = [bytearray(size * 4) for _ in range(size)]
    if box is None:
        return size, size, out
    shift_x = size // 2 - width // 2
    shift_y = (size - 1 - FOOT_MARGIN) - (box[3] - 1)
    for y in range(height):
        ty = y + shift_y
        if not 0 <= ty < size:
            continue
        for x in range(width):
            tx = x + shift_x
            if 0 <= tx < size and rows[y][x * 4 + 3]:
                out[ty][tx * 4:tx * 4 + 4] = rows[y][x * 4:x * 4 + 4]
    return size, size, out


def export_anims(base):
    anims = {}
    folder = os.path.join(base, 'animations')
    for name in sorted(os.listdir(folder)) if os.path.isdir(folder) else []:
        east = os.path.join(folder, name, 'east')
        files = sorted(os.path.join(east, f) for f in os.listdir(east) if f.endswith('.png')) if os.path.isdir(east) else []
        if files:
            anims[name.lower().replace('-', '_').replace(' ', '_')] = files
    return anims


def plan(enemy, anims):
    # game anim -> list of frame files, in order.
    out = {}
    for name, files in anims.items():
        out[name] = files if name in KEEP_FIRST or len(files) == 1 else files[1:]
    for name, (source, picks, wanted) in CUTS.get(enemy, {}).items():
        if source not in anims:
            continue
        if name != source and name in anims:
            print('  %s: the export has its own %s, the cut is skipped' % (enemy, name))
            continue
        got = frame_hash(anims[source])
        if got != wanted:
            print('  %s: %s was cut from another export (%s, now %s), using the default' % (enemy, name, wanted, got))
            continue
        if picks:
            out[name] = [anims[source][i] for i in picks]
        else:
            out.pop(name, None)
    return out


def state_folder(folder):
    for name in sorted(os.listdir(folder)):
        if os.path.isdir(os.path.join(folder, name, 'animations')):
            return os.path.join(folder, name)
    return None


def build(source, target, enemy):
    base = state_folder(os.path.join(source, enemy))
    if base is None:
        print(enemy, 'has no animations')
        return
    strips = plan(enemy, export_anims(base))
    if 'idle' not in strips:
        print(enemy, 'has no idle, so it would show its placeholder; skipped')
        return
    loaded = {name: [load(f) for f in files] for name, files in strips.items()}
    size = canvas_size([f for frames in loaded.values() for f in frames])
    out = os.path.join(target, enemy)
    os.makedirs(out, exist_ok=True)
    for name, frames in loaded.items():
        join([place(f, size) for f in frames], os.path.join(out, name + '.png'))
    print(enemy, size, ', '.join('%s %d' % (n, len(f)) for n, f in sorted(loaded.items())))


def main():
    source, target = sys.argv[1], sys.argv[2]
    ids = sys.argv[3:] or sorted(d for d in os.listdir(source) if os.path.isdir(os.path.join(source, d)) and state_folder(os.path.join(source, d)))
    for enemy in ids:
        build(source, target, enemy)


if __name__ == '__main__':
    main()
