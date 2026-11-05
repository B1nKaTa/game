# Builds an enemy's strips from its PixelLab export into art/sprites/<id>/<anim>.png, the folder
# SpriteVisual loads (res://art/sprites/<art_id>/<anim>.png). Plain Python, no packages.
# Usage: py tools/art/enemy_strips.py <export folder holding one folder per enemy id> <art/sprites folder> [id ...]
#
# Anims. Every east (or, for an object that never turns, south) anim in the export, <id>/<state>/animations/<name>/east/frame_###.png, becomes
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
# The way an anim was drawn: east, mirrored in the game, or south for an object that never turns
# (EnemyDef.art_flips false: the mimic, the Lost Luggage and the steam valve).
DIRECTIONS = ('east', 'south')

# id -> {game anim: (export anim, frames, hash of the export anim's frames[, replace])}. Frames are the
# export's own numbers (000 is the reference pose). A game anim cut to no frames is left out, so the
# game falls back (Santa's attack shows no strike yet). replace lets a cut win over the export's own
# anim of that name (the mimic's lunge comes from its idle, whose lid opens).
CUTS = {
    # The scythe drawn back, then the low sweep from the moment it lands.
    'intern_reaper': {'windup': ('attack', [1, 2, 3], '4090bbed'), 'attack': ('attack', [4, 5, 6, 8], '4090bbed')},
    # The shovel lifted back, then the throw with the coal leaving it.
    'stoker': {'windup': ('attack', [1, 2, 3], 'a40730c4'), 'attack': ('attack', [5, 6, 7, 8], 'a40730c4')},
    # His export is a whistle, which he blows after a charge (MallCopBehavior._stop); the charge itself walks.
    'mall_cop': {'whistle': ('attack', [2, 3, 4, 5, 6, 7, 8], '5c2ee994'), 'attack': ('attack', [], '5c2ee994')},
    # The backswing to the top, then impact and follow-through as the balls fly.
    'club_golfer': {'windup': ('attack', [3, 4, 5, 6], 'b990c9bf'), 'attack': ('attack', [7, 8], 'b990c9bf')},
    # The memo raised back, then thrown.
    'hr_representative': {'windup': ('attack', [4, 5, 6, 7], '06a0adcd'), 'attack': ('attack', [8], '06a0adcd')},
    'old_smokey': {'windup': ('attack', [3, 4, 5], 'f5edbd72'), 'attack': ('attack', [6, 7, 8], 'f5edbd72')},
    # The export barely moves and shows no strike, so Santa keeps the fallbacks until it is redone.
    'mall_santa': {'attack': ('attack', [], '026823f5')},
    'thaddeus_fairweather': {'windup': ('attack', [4, 5, 6], 'eb66e3b2'), 'attack': ('attack', [7, 8], 'eb66e3b2')},
    # The gavel raised overhead, then brought down.
    'chairman_of_the_board': {'windup': ('attack', [3, 4, 5, 6], '2c6098a8'), 'attack': ('attack', [7, 8], '2c6098a8')},
    # The regenerated, lighter robe (2026-11-06): the scythe drawn back over his shoulder, then swept low.
    'regional_reaper': {'windup': ('attack', [1, 2, 3, 4], '436d18dc'), 'attack': ('attack', [5, 6, 7, 8], '436d18dc')},
    # The second batch (2026-11-06), picked off labelled contact sheets of each attack.
    'filing_clerk': {'windup': ('attack', [2, 3, 4, 5], '72d5a1a2'), 'attack': ('attack', [6, 7, 8], '72d5a1a2')},
    'debt_ghost': {'windup': ('attack', [2, 3, 4, 5, 6], '4a29e87f'), 'attack': ('attack', [7, 8], '4a29e87f')},
    'seasonal_temp': {'windup': ('attack', [2, 3, 4, 5], 'cc82e029'), 'attack': ('attack', [7, 8], 'cc82e029')},
    'notary_public': {'windup': ('attack', [1, 2, 3, 4, 5], '56314993'), 'attack': ('attack', [6, 7, 8], '56314993')},
    # His windup is the lit fuse, which he crawls through; the blast is code and he is gone after it.
    'burnt_out_auditor': {'windup': ('attack', [3, 4, 5, 6, 7, 8], '0cb59401'), 'attack': ('attack', [8], '0cb59401')},
    'denial_officer': {'windup': ('attack', [2, 3, 4], '3861f270'), 'attack': ('attack', [5, 6, 7, 8], '3861f270')},
    'senior_adjuster': {'windup': ('attack', [1, 2, 3, 4], '6efafedd'), 'attack': ('attack', [5, 6, 7, 8], '6efafedd')},
    'plot_holder': {'windup': ('attack', [1, 2], '6d2d20b4'), 'attack': ('attack', [3, 4, 5, 6, 7], '6d2d20b4')},
    'head_groundskeeper': {'windup': ('attack', [3, 4, 5, 6, 7], 'ca1f2154'), 'attack': ('attack', [8], 'ca1f2154')},
    'tired_undertaker': {'windup': ('attack', [1, 2, 3, 4, 5], 'bc9e77cc'), 'attack': ('attack', [6, 7, 8], 'bc9e77cc')},
    'orderly': {'windup': ('attack', [1, 2, 3], '1e74290e'), 'attack': ('attack', [4, 5, 6], '1e74290e')},
    'cart_nurse': {'windup': ('attack', [1, 2, 3], '42d72338'), 'attack': ('attack', [4, 5, 6, 7, 8], '42d72338')},
    'bingo_caller': {'windup': ('attack', [1, 2], 'fa80664a'), 'attack': ('attack', [3, 4, 5, 6], 'fa80664a')},
    'resident': {'windup': ('attack', [2, 3, 4, 5], '8467683f'), 'attack': ('attack', [6, 7, 8], '8467683f')},
    'activities_coordinator': {'windup': ('attack', [1, 2, 3], 'd336d6c6'), 'attack': ('attack', [4, 5, 6, 7, 8], 'd336d6c6')},
    'matron_mercy': {'windup': ('attack', [2, 3, 4], 'f1fae23f'), 'attack': ('attack', [5, 6, 7, 8], 'f1fae23f')},
    # The mimic's export opens its lid in the idle and barely moves in the attack: it sleeps on the
    # closed frames, cracks the lid over the windup and lunges with it wide open (replacing its attack).
    'mimic': {'idle': ('idle', [0, 1, 2, 3, 7, 8], '43d91cae'), 'windup': ('idle', [3, 4], '43d91cae', True),
              'attack': ('idle', [5, 6, 5], '43d91cae', True)},
    'soot_ghost': {'windup': ('attack', [2, 3, 4, 5], '34ec3f23'), 'attack': ('attack', [6, 7, 8], '34ec3f23')},
    'foreman_klaus': {'windup': ('attack', [2, 3, 4], 'a20d2a9f'), 'attack': ('attack', [5, 6, 7, 8], 'a20d2a9f')},
    # The wheel turns as the lane is warned, then the vent.
    'steam_valve': {'windup': ('attack', [1, 2, 3, 4, 5], '888e423f'), 'attack': ('attack', [6, 7, 8], '888e423f')},
    'weeping_mourner': {'windup': ('attack', [1, 2, 3, 4, 5], '24d60d69'), 'attack': ('attack', [6, 7, 8], '24d60d69')},
    'florist': {'windup': ('attack', [2, 3, 4], '18910f6c'), 'attack': ('attack', [5, 6, 7, 8], '18910f6c')},
    'pallbearer': {'windup': ('attack', [2, 3, 4], 'e47cf197'), 'attack': ('attack', [5, 6, 7, 8], 'e47cf197')},
    'reverend': {'windup': ('attack', [1, 2, 3, 4, 5], 'f3cc9ded'), 'attack': ('attack', [6, 7, 8], 'f3cc9ded')},
    'mortimer_grimsby': {'windup': ('attack', [1, 2, 3], 'd163d56a'), 'attack': ('attack', [4, 5, 6, 7], 'd163d56a')},
    'early_bird_diner': {'windup': ('attack', [1, 2, 3, 4, 5, 6], '13176c9a'), 'attack': ('attack', [7, 8], '13176c9a')},
    'shuffleboard_shark': {'windup': ('attack', [3, 4, 5, 6, 7], 'eadce400'), 'attack': ('attack', [8], 'eadce400')},
    'sunburnt_sunbather': {'windup': ('attack', [2, 3, 4, 5], '34adec86'), 'attack': ('attack', [6, 7, 8], '34adec86')},
    'lorraine': {'windup': ('attack', [1, 2, 3], 'd0421961'), 'attack': ('attack', [4, 5, 6, 7, 8], 'd0421961')},
    'commodore_wellington': {'windup': ('attack', [2, 3, 4], 'd64b43ee'), 'attack': ('attack', [5, 6, 7, 8], 'd64b43ee')},
    'tour_group': {'windup': ('attack', [1, 2, 3, 4, 5], '4476b4a5'), 'attack': ('attack', [6, 7, 8], '4476b4a5')},
    'baggage_handler': {'windup': ('attack', [2, 3, 4], 'db21c530'), 'attack': ('attack', [5, 6, 7, 8], 'db21c530')},
    # Its mouth gapes over the windup and snaps shut on the bite.
    'lost_luggage': {'windup': ('attack', [1, 2, 3, 4, 5], '4f73d2d0'), 'attack': ('attack', [6, 7, 8], '4f73d2d0')},
    'sergeant_wanda': {'windup': ('attack', [2, 3, 4, 5], 'cd03d84f'), 'attack': ('attack', [6, 7, 8], 'cd03d84f')},
    'augustine': {'windup': ('attack', [1, 2, 3], '93bfcf81'), 'attack': ('attack', [4, 5, 6, 7, 8], '93bfcf81')},
    'yes_man': {'windup': ('attack', [1, 2, 3, 4], '1cce2630'), 'attack': ('attack', [5, 6, 7, 8], '1cce2630')},
    'paper_shredder': {'windup': ('attack', [1, 2, 3, 4], 'bdcec632'), 'attack': ('attack', [5, 6, 7, 8], 'bdcec632')},
    'doreen': {'windup': ('attack', [1, 2, 3], '1a44f1cb'), 'attack': ('attack', [4, 5, 6, 7, 8], '1a44f1cb')},
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
        files = []
        for way in DIRECTIONS:
            drawn = os.path.join(folder, name, way)
            if os.path.isdir(drawn):
                files = sorted(os.path.join(drawn, f) for f in os.listdir(drawn) if f.endswith('.png'))
                break
        if files:
            anims[name.lower().replace('-', '_').replace(' ', '_')] = files
    return anims


def plan(enemy, anims):
    # game anim -> list of frame files, in order.
    out = {}
    for name, files in anims.items():
        out[name] = files if name in KEEP_FIRST or len(files) == 1 else files[1:]
    for name, cut in CUTS.get(enemy, {}).items():
        source, picks, wanted = cut[:3]
        replace = len(cut) > 3 and cut[3]
        if source not in anims:
            continue
        if name != source and name in anims and not replace:
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
