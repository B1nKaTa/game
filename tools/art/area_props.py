# Builds the props of the rollout areas in the depth look (docs/art/art-direction-notes.md section 13):
# art/props/<set>/<id>.png for every prop and decor picture an area uses, so each sits on its new ground.
# Plain Python, no packages.
#
# Usage: py tools/art/area_props.py <export folder> <game root> [set ...]
#
# The export folder (D:/grandpa-art/direction) holds props2/<name>.png, create_map_object exports.
# Each entry of AREA_PROPS is  game id: (source, max width, max height[, mode]).  The source is
#   'name'           props2/<name>.png, a new drawing: trimmed, shrunk to its box, outlined again, toned
#   'game'           the area's current shared picture (art/props/<id>.png), only toned onto the look
#   'floor_1:<id>'   the basement's own depth picture, shrunk to the box and toned a little
# and the mode is
#   'dim'            a pale or loud picture (white sheets, a yellow sign), toned further
#   'lift'           a dark picture, left at its own brightness
#   'deep'           a floor piece that fills its box exactly, toned deep (pool water)
#   'stub'           grass cut down: the bottom rows of the tuft
#   'split'          a run piece: <id>.png alone and <id>_west/_mid/_east.png cut from one wide drawing
# The box is the size the prop was drawn at before, so no footprint grows; collision is code and never
# changes.
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from env_art import fit, hard_alpha, load, save, trim  # noqa: E402

# Every prop is toned onto the look as the rollout's were: the area's light, not the picture, makes it
# bright, so nothing reads as a lamp.
TONE = (0.8, 0.78, 0.76)
DIM = (0.68, 0.66, 0.64)
# A dark picture on a dark floor (a black chair, a black candelabra on wine carpet) keeps its own light.
LIFT = (1.0, 1.0, 1.0)
# Pool water, a floor piece: a deep blue, so a lit pool never glares like a lamp.
DEEP = (0.52, 0.6, 0.7)
KEPT = (0.84, 0.82, 0.8)

AREA_PROPS = {
    'waiting_room': {
        'lobby_lamps': ('lobby_lamps', 14, 18),
        'arcade_table_slot': ('arcade_slot', 26, 28),
        'decor_lantern': ('floor_1:decor_lantern', 14, 20),
        'station_key_board': ('game', 0, 0), 'station_forms_counter': ('game', 0, 0),
        'station_ticket_machine': ('game', 0, 0), 'station_noticeboard': ('game', 0, 0),
        'station_decor_counter': ('game', 0, 0), 'station_item_rack': ('game', 0, 0),
        'station_duty_free': ('game', 0, 0), 'station_severance_desk': ('game', 0, 0),
        'station_employee_plaque': ('game', 0, 0), 'station_ending_archive': ('game', 0, 0),
        'trophy_frame': ('game', 0, 0), 'lobby_fern': ('game', 0, 0), 'lobby_poster': ('game', 0, 0),
        'lobby_chair': ('game', 0, 0), 'lobby_tank': ('game', 0, 0), 'arcade_table_cards': ('game', 0, 0),
    },
    'crossroads': {
        'grass': ('weeds', 20, 22, 'dim'),
        'grass_cut': ('weeds', 17, 10, 'stub'),
        'decor_lantern': ('floor_1:decor_lantern', 14, 20),
        'path_sign': ('game', 0, 0), 'path_sign_chained': ('game', 0, 0),
    },
    'cemetery': {
        'gravestone': ('gravestone', 20, 26),
        'grass': ('weeds', 20, 22, 'dim'),
        'grass_cut': ('weeds', 17, 10, 'stub'),
        'decor_sapling': ('dead_bush', 18, 22),
        'bone_pile': ('floor_1:bone_pile', 22, 20),
        'decor_lantern': ('floor_1:decor_lantern', 14, 20),
        'barrel': ('game', 0, 0), 'rock': ('game', 0, 0), 'dead_tree': ('game', 0, 0),
        'decor_stump': ('game', 0, 0), 'decor_torch': ('game', 0, 0),
    },
    'sunset_shores': {
        'care_bed': ('care_bed', 30, 30),
        'food_trolley': ('food_trolley', 24, 26),
        'wet_sign': ('wet_sign', 14, 20, 'dim'),
        'decor_iv_stand': ('iv_stand2', 14, 28),
        'decor_lantern': ('floor_1:decor_lantern', 14, 20),
        'flower_vase': ('game', 0, 0), 'armchair': ('game', 0, 0), 'wheelchair': ('game', 0, 0),
        'decor_plant': ('game', 0, 0),
    },
    'furnace_works': {
        'coal_heap': ('coal_heap', 30, 25),
        'pipe_valve': ('pipe_valve', 14, 22),
        'decor_gauge': ('gauge', 16, 20),
        'decor_pipe': ('pipe2', 24, 18),
        'decor_lantern': ('floor_1:decor_lantern', 14, 20),
        'coal_sack': ('game', 0, 0), 'furnace_crate': ('game', 0, 0), 'floor_vent': ('game', 0, 0),
        'decor_furnace': ('game', 0, 0),
    },
    'funeral_parlour': {
        'candle_stand': ('candelabra', 14, 26, 'lift'),
        'wreath_stand': ('wreath', 18, 24),
        'hymn_cart': ('hymn_cart', 27, 22),
        'decor_coffin_stand': ('coffin_stand', 26, 20),
        'decor_lantern': ('floor_1:decor_lantern', 14, 20),
        'chapel_pew': ('game', 0, 0), 'organ_pipe': ('game', 0, 0, 'dim'), 'dropped_coffin': ('game', 0, 0),
        'decor_stained_glass': ('game', 0, 0),
    },
    'flashback_cinema': {
        'lobby_card': ('lobby_card2', 20, 26),
        'decor_plant': ('game', 0, 0),
    },
    'last_resort_cruise': {
        'buffet_tray': ('buffet_tray', 22, 20),
        'lifeboat_davit': ('davit2', 28, 28),
        'decor_bench': ('bench', 26, 16),
        'decor_food_table': ('food_table', 28, 20),
        'decor_lantern': ('floor_1:decor_lantern', 14, 20),
        'deck_chair': ('game', 0, 0), 'decor_plant': ('game', 0, 0),
        'pool_water': ('game', 32, 32, 'deep'),
    },
    'seance_hotline': {
        'cubicle_partition': ('cubicle_partition', 64, 36, 'split'),
        'seance_table_small': ('seance_table_small', 28, 28),
        'in_tray': ('in_tray_hand', 18, 16, 'dim'),
        'decor_office_chair': ('office_chair', 18, 24, 'lift'),
        'decor_lantern': ('floor_1:decor_lantern', 14, 20),
    },
    'terminal_zero': {
        'departure_seats': ('departure_seats', 30, 24),
        'decor_lantern': ('floor_1:decor_lantern', 14, 20),
        'suitcase_stack': ('game', 0, 0), 'luggage_trolley': ('game', 0, 0),
        'decor_departure_board': ('game', 0, 0), 'decor_plant': ('game', 0, 0),
    },
    'head_office': {
        'cubicle_wall': ('cubicle_wall', 32, 29),
        'water_cooler': ('water_cooler', 18, 30, 'dim'),
        'in_tray': ('in_tray_hand', 18, 16, 'dim'),
        'decor_office_chair': ('office_chair', 18, 24, 'lift'),
        'decor_ficus': ('game', 0, 0), 'decor_plant': ('game', 0, 0),
    },
}


def tone(pixels, mult):
    return [[(min(255, int(p[0] * mult[0])), min(255, int(p[1] * mult[1])), min(255, int(p[2] * mult[2])), p[3]) for p in row] for row in pixels]


def _lum(p):
    return p[0] * 0.299 + p[1] * 0.587 + p[2] * 0.114


# Shrinking by the commonest colour of each block can break the outline, so every edge pixel (one with
# a clear neighbour) takes the export's own outline colour: the darkest colour on its edge.
def outline_again(pixels, colour=None):
    h, w = len(pixels), len(pixels[0])

    def edge(x, y):
        if not pixels[y][x][3]:
            return False
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if nx < 0 or ny < 0 or nx >= w or ny >= h or not pixels[ny][nx][3]:
                return True
        return False
    edges = [(x, y) for y in range(h) for x in range(w) if edge(x, y)]
    if colour is None:
        if not edges:
            return pixels
        colour = min((pixels[y][x] for x, y in edges), key=_lum)
    out = [list(row) for row in pixels]
    for x, y in edges:
        out[y][x] = colour[:3] + (255,)
    return out


def _darkest_edge(pixels):
    p = hard_alpha(pixels)
    h, w = len(p), len(p[0])
    best = None
    for y in range(h):
        for x in range(w):
            if not p[y][x][3]:
                continue
            if any(not (0 <= x + dx < w and 0 <= y + dy < h) or not p[y + dy][x + dx][3] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                if best is None or _lum(p[y][x]) < _lum(best):
                    best = p[y][x]
    return best


def drawing(path, w, h):
    raw = load(path)
    line = _darkest_edge(raw)
    return outline_again(fit(raw, w, h, main=True), line)


# The bottom rows of a tuft, as the stubble left once it is cut.
def stub(pixels, w, h):
    rows = trim(hard_alpha(pixels))
    keep = rows[-max(1, len(rows) * 2 // 5):]
    return outline_again(fit(keep, w, h))


# A run piece from one drawing two cells wide: the west end, a middle and the east end, each one cell
# wide, and a lone piece of both ends.
def split(pixels):
    w = len(pixels[0])
    cell = w // 2
    q = cell // 2
    rows = len(pixels)
    west = [row[0:cell] for row in pixels]
    east = [row[w - cell:w] for row in pixels]
    mid = [row[q:q + cell] for row in pixels]
    alone = [row[0:q] + row[w - q:w] for row in pixels]
    assert all(len(r) == cell for r in west + east + mid + alone) and rows
    return {'': alone, '_west': west, '_mid': mid, '_east': east}


def build(export, game, art_set):
    out_dir = os.path.join(game, 'art', 'props', art_set)
    for game_id, spec in AREA_PROPS[art_set].items():
        source, w, h = spec[:3]
        mode = spec[3] if len(spec) > 3 else ''
        mult = {'dim': DIM, 'split': DIM, 'lift': LIFT, 'deep': DEEP}.get(mode, TONE)
        if source == 'game':
            path = os.path.join(game, 'art', 'props', game_id + '.png')
            pixels = hard_alpha(load(path))
            if mode == 'deep':
                pixels = fit(pixels, w, h, exact=True)
            pixels = tone(pixels, {'dim': DIM, 'deep': DEEP}.get(mode, KEPT))
        elif source.startswith('floor_1:'):
            path = os.path.join(game, 'art', 'props', 'floor_1', source.split(':')[1] + '.png')
            pixels = tone(fit(load(path), w, h), KEPT)
        else:
            path = os.path.join(export, 'props2', source + '.png')
            if not os.path.exists(path):
                print('missing', path)
                continue
            if mode == 'stub':
                pixels = tone(stub(load(path), w, h), DIM)
            elif mode == 'split':
                raw = load(path)
                line = _darkest_edge(raw)
                # Outlined whole before the cut, so no piece gets a dark seam where it joins the next.
                whole = outline_again(fit(raw, w, h, exact=True, main=True), line)
                for suffix, piece in split(whole).items():
                    piece = tone(piece, mult)
                    save(os.path.join(out_dir, game_id + suffix + '.png'), piece)
                    print(art_set, game_id + suffix, len(piece[0]), 'x', len(piece))
                continue
            else:
                pixels = tone(drawing(path, w, h), mult)
        save(os.path.join(out_dir, game_id + '.png'), pixels)
        print(art_set, game_id, len(pixels[0]), 'x', len(pixels))


if __name__ == '__main__':
    sets = sys.argv[3:] or list(AREA_PROPS)
    for one in sets:
        build(sys.argv[1], sys.argv[2], one)
