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
# Objects drawn on a 48 px canvas about twice their body box (the film reel's 18x18, the Ectoplasm's
# 22x18), halved so the art covers the box a hit tests.
HALVED = ('film_reel', 'ectoplasm')
# The way an anim was drawn: east, mirrored in the game, or south for an object that never turns
# (EnemyDef.art_flips false: the Ectoplasm, the film reel, the mimic, the Lost Luggage and the steam valve).
DIRECTIONS = ('east', 'south')

# id -> {game anim: (export anim, frames, hash of the export anim's frames[, replace])}. Frames are the
# export's own numbers (000 is the reference pose). A game anim cut to no frames is left out, so the
# game falls back. replace lets a cut win over the export's own
# anim of that name (the mimic's lunge comes from its idle, whose lid opens).
CUTS = {
    # The scythe drawn back, then the low sweep from the moment it lands.
    'intern_reaper': {'windup': ('attack', [1, 2, 3], '4090bbed'), 'attack': ('attack', [4, 5, 6, 8], '4090bbed')},
    # The shovel lifted back, then the throw with the coal leaving it.
    'stoker': {'windup': ('attack', [1, 2, 3], 'a40730c4'), 'attack': ('attack', [5, 6, 7, 8], 'a40730c4')},
    # His export is a whistle, which he blows after a charge (MallCopBehavior._stop); the charge itself walks.
    'mall_cop': {'whistle': ('attack', [2, 3, 4, 5, 6, 7, 8], '5c2ee994'), 'attack': ('attack', [], '5c2ee994')},
    # The memo raised back, then thrown.
    'hr_representative': {'windup': ('attack', [4, 5, 6, 7], '06a0adcd'), 'attack': ('attack', [8], '06a0adcd')},
    'old_smokey': {'windup': ('attack', [3, 4, 5], 'f5edbd72'), 'attack': ('attack', [6, 7, 8], 'f5edbd72')},
    # The gavel raised overhead, then brought down.
    'chairman_of_the_board': {'windup': ('attack', [3, 4, 5, 6], '2c6098a8'), 'attack': ('attack', [7, 8], '2c6098a8')},
    # The regenerated, lighter robe (2026-11-06): the scythe drawn back over his shoulder, then swept low.
    'regional_reaper': {'windup': ('attack', [1, 2, 3, 4], '436d18dc'), 'attack': ('attack', [5, 6, 7, 8], '436d18dc')},
    # The second batch (2026-11-06), picked off labelled contact sheets of each attack.
    # The basement's redraw (2026-11-06, D:/grandpa-art/direction/enemies): the stack lowered and the arm
    # drawn back, then the sheet thrown.
    'filing_clerk': {'windup': ('attack', [5, 6, 7], '35c6f414'), 'attack': ('attack', [8], '35c6f414')},
    'debt_ghost': {'windup': ('attack', [2, 3, 4, 5, 6], '4a29e87f'), 'attack': ('attack', [7, 8], '4a29e87f')},
    # The skeleton temp crouches, then leaps and bites.
    'seasonal_temp': {'windup': ('attack', [1, 2, 3, 4], '8ed37757'), 'attack': ('attack', [5, 6, 7, 8], '8ed37757')},
    'notary_public': {'windup': ('attack', [1, 2, 3, 4, 5], '56314993'), 'attack': ('attack', [6, 7, 8], '56314993')},
    # His windup is the lit fuse, which he crawls through; the blast is code and he is gone after it.
    'burnt_out_auditor': {'windup': ('attack', [2, 3, 4, 5, 6, 7], '07de8230'), 'attack': ('attack', [8], '07de8230')},
    # The claims clerk raises his rubber stamp high behind the drawer, then slams it down.
    'denial_officer': {'windup': ('attack', [3, 4, 5, 6], 'e3c13db4'), 'attack': ('attack', [7, 8], 'e3c13db4')},
    # The care home's own Denial Officer (2026-11-06): the serving tray raised overhead, then brought down.
    'shores_denial_officer': {'windup': ('attack', [3, 4, 5, 6], 'c3169a31'), 'attack': ('attack', [7, 8], 'c3169a31')},
    # The Cinema's own Intern Reaper, a reaper usher: the scythe drawn back, then swept low.
    'cinema_intern_reaper': {'windup': ('attack', [1, 2, 3, 4], '6f387949'), 'attack': ('attack', [5, 6, 7, 8], '6f387949')},
    # The parlour's own Seasonal Temp, an altar server: a crouch, then the lunge.
    'parlour_seasonal_temp': {'windup': ('attack', [1, 2, 3], 'b40a7a33'), 'attack': ('attack', [4, 5, 6, 7], 'b40a7a33')},
    'senior_adjuster': {'windup': ('attack', [1, 2, 3, 4], '041ecf4f'), 'attack': ('attack', [5, 6, 7, 8], '041ecf4f')},
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
    'weeping_mourner': {'windup': ('attack', [1, 2, 3, 4], '6526bc4a'), 'attack': ('attack', [5, 6, 7, 8], '6526bc4a')},
    'florist': {'windup': ('attack', [2, 3, 4], '18910f6c'), 'attack': ('attack', [5, 6, 7, 8], '18910f6c')},
    'pallbearer': {'windup': ('attack', [2, 3, 4], 'e47cf197'), 'attack': ('attack', [5, 6, 7, 8], 'e47cf197')},
    'reverend': {'windup': ('attack', [1, 2, 3, 4, 5], 'f3cc9ded'), 'attack': ('attack', [6, 7, 8], 'f3cc9ded')},
    'mortimer_grimsby': {'windup': ('attack', [1, 2, 3, 4, 5, 6], '028b5719'), 'attack': ('attack', [7, 8], '028b5719')},
    'early_bird_diner': {'windup': ('attack', [1, 2, 3, 4], 'c8d78d0f'), 'attack': ('attack', [5, 6, 7, 8], 'c8d78d0f')},
    'shuffleboard_shark': {'windup': ('attack', [3, 4, 5, 6, 7], 'eadce400'), 'attack': ('attack', [8], 'eadce400')},
    'sunburnt_sunbather': {'windup': ('attack', [2, 3, 4, 5], '34adec86'), 'attack': ('attack', [6, 7, 8], '34adec86')},
    'lorraine': {'windup': ('attack', [1, 2, 3], 'd0421961'), 'attack': ('attack', [4, 5, 6, 7, 8], 'd0421961')},
    'commodore_wellington': {'windup': ('attack', [2, 3, 4], 'd64b43ee'), 'attack': ('attack', [5, 6, 7, 8], 'd64b43ee')},
    'tour_group': {'windup': ('attack', [1, 2, 3], '97a2911b'), 'attack': ('attack', [4, 5, 6], '97a2911b')},
    'baggage_handler': {'windup': ('attack', [2, 3, 4], 'db21c530'), 'attack': ('attack', [5, 6, 7, 8], 'db21c530')},
    # Its mouth gapes over the windup and snaps shut on the bite.
    'lost_luggage': {'windup': ('attack', [1, 2, 3, 4, 5], '4f73d2d0'), 'attack': ('attack', [6, 7, 8], '4f73d2d0')},
    'sergeant_wanda': {'windup': ('attack', [2, 3, 4, 5], 'cd03d84f'), 'attack': ('attack', [6, 7, 8], 'cd03d84f')},
    'augustine': {'windup': ('attack', [1, 2, 3], '93bfcf81'), 'attack': ('attack', [4, 5, 6, 7, 8], '93bfcf81')},
    'yes_man': {'windup': ('attack', [2, 3, 4, 5], 'a78791b6'), 'attack': ('attack', [6, 7, 8], 'a78791b6')},
    'paper_shredder': {'windup': ('attack', [1, 2, 3, 4], 'bdcec632'), 'attack': ('attack', [5, 6, 7, 8], 'bdcec632')},
    'doreen': {'windup': ('attack', [1, 2, 3], '1a44f1cb'), 'attack': ('attack', [4, 5, 6, 7, 8], '1a44f1cb')},
    # The Cinema and the Seance Hotline (2026-11-06, D:/grandpa-art/newpaths). The bosses play their own
    # anims (crabtree star_rating and thumbs_down, the projectionist reel_change and splice, celestine
    # deal_cards, madame_zara tether_call and possession), so they keep the default cuts.
    # Shh with a finger, the torch raised, then the lunge of the charge.
    'usher': {'windup': ('attack', [1, 2, 3, 4, 5, 6], '9fcb0998'), 'attack': ('attack', [7, 8], '9fcb0998')},
    # The arm drawn back with the tray, then the tub thrown.
    'popcorn_vendor': {'windup': ('attack', [3, 4, 5, 6], '86176168'), 'attack': ('attack', [7, 8], '86176168')},
    # Arms out to heckle, then the shove.
    'extra': {'windup': ('attack', [3, 4, 5, 6, 7], 'd589017a'), 'attack': ('attack', [8], 'd589017a')},
    # The cord gathered up, then whipped round.
    'phone_psychic': {'windup': ('attack', [1, 2, 3, 4], '81d81a91'), 'attack': ('attack', [5, 6, 7, 8], '81d81a91')},
    # The ball raised to her eye, then let go.
    'crystal_gazer': {'windup': ('attack', [1, 2, 3, 4, 5], '1f8a98aa'), 'attack': ('attack', [6, 7, 8], '1f8a98aa')},
    # The arm thrown up, then the hurl.
    'poltergeist': {'windup': ('attack', [3, 4, 5, 6], 'fb8cba67'), 'attack': ('attack', [7, 8], 'fb8cba67')},
    # The returning pairs' own looks (2026-11-06, D:/grandpa-art/newpaths2, each export's folder renamed
    # to the variant's id, since the base ids already wear round-2's art on the older floors).
    # The ball raised over his shoulder, then the follow-through (frame 4's ball in flight is left out,
    # since the game throws its own ball).
    'seance_bingo_caller': {'windup': ('attack', [1, 2, 3], '655789ce'), 'attack': ('attack', [5, 6, 7], '655789ce')},
    # The squash with the soot rising, then the lunge and its puff.
    'seance_soot_ghost': {'windup': ('attack', [1, 2, 3], 'ef978010'), 'attack': ('attack', [4, 5, 6], 'ef978010')},
    # The stamp lifted overhead, then the slam.
    'cinema_notary_public': {'windup': ('attack', [2, 3, 4], 'c85d6dd3'), 'attack': ('attack', [5, 6, 7], 'c85d6dd3')},
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


# Half size: each 2x2 block takes its most common opaque colour when at least two of its pixels
# are opaque, and the darkest on a tie, so the black outline survives.
def halve(frame):
    width, height, rows = frame
    w, h = width // 2, height // 2
    out = [bytearray(w * 4) for _ in range(h)]
    for y in range(h):
        for x in range(w):
            seen = {}
            for dy in (0, 1):
                for dx in (0, 1):
                    px = bytes(rows[y * 2 + dy][(x * 2 + dx) * 4:(x * 2 + dx) * 4 + 4])
                    if px[3]:
                        seen[px] = seen.get(px, 0) + 1
            if sum(seen.values()) >= 2:
                best = max(seen, key=lambda c: (seen[c], -(c[0] + c[1] + c[2])))
                out[y][x * 4:x * 4 + 4] = best
    return w, h, out


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
    if enemy in HALVED:
        loaded = {name: [halve(f) for f in frames] for name, frames in loaded.items()}
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
