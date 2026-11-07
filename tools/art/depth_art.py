# Builds the "depth" look of an art set (docs/art/art-direction-notes.md): one continuous ground made of
# Wang tiles, wall caps and front faces, the wall sconce, and the set's own props. Plain Python, no packages.
#
# Usage: py tools/art/depth_art.py <export folder> <game root> [set]
#
# The export folder (D:/grandpa-art/direction) holds, as saved from PixelLab:
#   tiles/ground2.png + ground2.json   a create_topdown_tileset sheet (16 Wang tiles) and its metadata,
#                                      lower terrain = the base ground, upper = the patches laid over it
#   tiles/cap1.png + cap1.json         a tileset whose lower base tile is the top of a wall
#   tiles/walls1/tile_N.png            create_tiles_pro wall faces (FACES picks them)
#   props/<name>.png                   create_map_object props (PROPS maps them to game ids)
#
# Writes art/tiles/<set>/depth/:
#   ground.png  a 512x32 strip of the 16 ground tiles ordered by Wang index NW*8 + NE*4 + SW*2 + SE
#               (a set bit is the upper terrain), toned by GROUND_TONE
#   cap.png     the wall top; face_N.png the wall fronts, toned onto one brightness
#   sconce.png  the wall torch, drawn on north wall faces (DepthLook)
# and art/props/<set>/<id>.png for each prop, trimmed, made fully opaque or clear, and shrunk to its box.
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from env_art import fit, key_background, load, luma, save  # noqa: E402

TILE = 32
# The ground tileset: ground2 has smaller, rounder cobbles and a softer edge than ground1, whose large
# flagstones made blotchy stepped patches.
GROUND = 'ground2'
# The tiles_pro sheet's wall fronts, plain first: the game picks the plain ones most (DepthLook.FACE_ODDS).
FACES = [0, 15, 1, 3, 2, 4, 14, 5]
# (multiplier per channel) for the base ground and the patches. The flagstones came out a pale grey that
# outshone the bodies, so they are dimmed and warmed; the earth is lifted a little so it reads as floor.
GROUND_TONE = {'lower': (1.08, 1.04, 1.0), 'upper': (0.62, 0.58, 0.55)}
FACE_TONE = (0.95, 0.9, 0.86)
CAP_TONE = (0.72, 0.68, 0.66)
# game id: (export file, max width, max height, recolour)
PROPS = {
    'barrel': ('barrel.png', 24, 28, None),
    # Archive boxes, toned down: at full brightness the torches lit them like lamps.
    'crate': ('boxes.png', 30, 30, 'dim'),
    # A fallen block of masonry, big enough to name; the small heap of pink rubble was not.
    'rock': ('masonry.png', 30, 26, 'dim'),
    'bone_pile': ('skull_pile.png', 24, 22, 'dim'),
    # The basement has no grass: its tufts are tied stacks of files, and a cut one a few torn scraps.
    'grass': ('paper_stack.png', 20, 24, 'dim'),
    'grass_cut': ('papers_flat.png', 14, 10, 'scrap'),
    'decor_lantern': ('lantern.png', 16, 22, None),
}


def tone(pixels, mult):
    return [[(min(255, int(p[0] * mult[0])), min(255, int(p[1] * mult[1])), min(255, int(p[2] * mult[2])), p[3]) for p in row] for row in pixels]


def crop(pixels, box):
    return [row[box['x']:box['x'] + box['width']] for row in pixels[box['y']:box['y'] + box['height']]]


# Pink and red bricks in the rubble sat near the warning red, so they become a dull brown.
def recolour_brick(pixels):
    out = []
    for row in pixels:
        line = []
        for p in row:
            if p[3] and p[0] > p[1] + 30 and p[0] > p[2] + 20:
                v = (p[0] + p[1] + p[2]) / 3.0
                line.append((int(v * 1.05), int(v * 0.88), int(v * 0.72), p[3]))
            else:
                line.append(p)
        out.append(line)
    return out


def ground_strip(export):
    sheet = load(os.path.join(export, 'tiles', GROUND + '.png'))
    meta = json.load(open(os.path.join(export, 'tiles', GROUND + '.json'), encoding='utf-8'))
    strip = [[(0, 0, 0, 0)] * (16 * TILE) for _ in range(TILE)]
    for tile in meta['tileset_data']['tiles']:
        c = tile['corners']
        bits = [c['NW'] == 'upper', c['NE'] == 'upper', c['SW'] == 'upper', c['SE'] == 'upper']
        index = bits[0] * 8 + bits[1] * 4 + bits[2] * 2 + bits[3]
        pixels = crop(sheet, tile['bounding_box'])
        # Each pixel is toned by the terrain it shows, so the patch edge keeps the shape PixelLab drew.
        toned = [[tone([[p]], GROUND_TONE['upper' if _is_upper(p) else 'lower'])[0][0] for p in row] for row in pixels]
        for y in range(TILE):
            strip[y][index * TILE:(index + 1) * TILE] = toned[y]
    return strip


# The flagstones are grey and the earth brown: a pixel is a stone when its colour is nearly neutral.
def _is_upper(p):
    spread = max(p[:3]) - min(p[:3])
    return spread < 26 and luma(p) > 0.22


# A pit: a broken rim of the wall top round the edge, the brick of its far (north) side going down into
# the dark, and black at the bottom, so it reads as a hole with depth and not a flat black square.
def pit(face, cap):
    size = TILE
    out = [[(0, 0, 0, 0)] * size for _ in range(size)]
    for y in range(size):
        for x in range(size):
            out[y][x] = (6, 5, 7, 255)
    # The far wall: the face's brick, darker the deeper it goes.
    for y in range(3, 15):
        shade = 0.62 - (y - 3) * 0.045
        for x in range(3, size - 3):
            p = face[(y + 6) % size][x]
            out[y][x] = (int(p[0] * shade), int(p[1] * shade), int(p[2] * shade), 255)
    # The side walls, in shadow, narrowing toward the bottom.
    for y in range(3, size - 3):
        depth = max(1, 4 - (y - 3) // 6)
        for x in range(3, 3 + depth):
            q = out[y][x]
            out[y][x] = (q[0] // 2 + 10, q[1] // 2 + 9, q[2] // 2 + 8, 255)
    # The rim: wall top along every edge, ragged on the inside, with a lit lip and a dark edge.
    for y in range(size):
        for x in range(size):
            edge = min(x, y, size - 1 - x, size - 1 - y)
            ragged = 3 + ((x * 7 + y * 13) % 5 == 0) - ((x * 3 + y * 5) % 7 == 0)
            if edge < ragged:
                p = cap[y][x]
                lift = 2.1 if edge == ragged - 1 else 1.5
                out[y][x] = (min(255, int(p[0] * lift)), min(255, int(p[1] * lift)), min(255, int(p[2] * lift)), 255)
            if edge == 0:
                out[y][x] = (14, 11, 10, 255)
    return out


def build(export, game, art_set):
    out = os.path.join(game, 'art', 'tiles', art_set, 'depth')
    os.makedirs(out, exist_ok=True)
    save(os.path.join(out, 'ground.png'), ground_strip(export))
    cap_sheet = load(os.path.join(export, 'tiles', 'cap1.png'))
    cap_meta = json.load(open(os.path.join(export, 'tiles', 'cap1.json'), encoding='utf-8'))
    for tile in cap_meta['tileset_data']['tiles']:
        if all(v == 'lower' for v in tile['corners'].values()):
            save(os.path.join(out, 'cap.png'), tone(crop(cap_sheet, tile['bounding_box']), CAP_TONE))
    for n, index in enumerate(FACES):
        face = load(os.path.join(export, 'tiles', 'walls1', 'tile_%d.png' % index))
        save(os.path.join(out, 'face_%d.png' % n), tone(face, FACE_TONE))
    props_dir = os.path.join(game, 'art', 'props', art_set)
    os.makedirs(props_dir, exist_ok=True)
    cap_tile = load(os.path.join(out, 'cap.png'))
    save(os.path.join(props_dir, 'hole.png'), pit(load(os.path.join(out, 'face_0.png')), cap_tile))
    sconce = fit(load(os.path.join(export, 'props', 'sconce.png')), 16, 26)
    save(os.path.join(out, 'sconce.png'), sconce)
    props = os.path.join(game, 'art', 'props', art_set)
    os.makedirs(props, exist_ok=True)
    for game_id, (name, w, h, recolour) in PROPS.items():
        path = os.path.join(export, 'props', name)
        if not os.path.exists(path):
            print('missing', name)
            continue
        pixels = fit(load(path), w, h, exact=recolour == 'exact', main=game_id not in ('grass', 'grass_cut', 'hole'))
        if recolour == 'dim':
            pixels = tone(pixels, (0.74, 0.71, 0.68))
        if recolour == 'paper':
            pixels = tone(pixels, (0.82, 0.78, 0.7))
        if recolour == 'scrap':
            pixels = tone(pixels, (0.62, 0.58, 0.52))
        if recolour == 'brick':
            pixels = tone(recolour_brick(pixels), (0.78, 0.76, 0.74))
        save(os.path.join(props, game_id + '.png'), pixels)
        print(game_id, len(pixels[0]), 'x', len(pixels))
    print('built', out)


# ---------------------------------------------------------------- the other areas
#
# Every other area's export lives in <export>/sets/<set>/: ground.png + ground.json (one pro Wang
# tileset), walls/tile_N.png (one tiles_pro sheet of wall fronts) and props/<name>.png. Its wall top is
# its plainest front, darkened and with the courses softened, so the top always reads darker than the
# front. Its sconce is the basement's torch for stone places and a brass lamp (<export>/sets/_shared/
# lamp.png) indoors. Tones keep the ground under the bodies; a red or bright floor is pulled further.
# set: faces (tiles_pro indices, plain first), ground tone, face tone, sconce, props {game id: (file, w, h)}
AREAS = {
    # The lobby's parquet patches came out saturated orange (0.58 against the floor's 0.27) and read as
    # stains under the lamps, so they are calmed toward their own grey and dimmed a little ('patch').
    'waiting_room': {'faces': [0, 1, 7, 2, 5, 6, 3, 1], 'ground': (0.82, 0.8, 0.78), 'face': (0.9, 0.88, 0.84), 'sconce': 'lamp',
                     'patch': (0.5, 0.9)},
    'crossroads': {'faces': [0, 1, 7, 5, 4, 2, 3, 6], 'ground': (0.8, 0.78, 0.76), 'face': (0.9, 0.88, 0.86), 'sconce': 'torch'},
    'cemetery': {'faces': [0, 1, 7, 2, 5, 3, 6, 4], 'ground': (0.78, 0.8, 0.76), 'face': (0.88, 0.9, 0.86), 'sconce': 'torch'},
    'sunset_shores': {'faces': [0, 1, 7, 2, 3, 4, 5, 6], 'ground': (0.78, 0.76, 0.74), 'face': (0.86, 0.84, 0.82), 'sconce': 'lamp'},
    'furnace_works': {'faces': [0, 1, 7, 2, 3, 4, 5, 6], 'ground': (0.78, 0.74, 0.72), 'face': (0.86, 0.82, 0.8), 'sconce': 'torch'},
    'funeral_parlour': {'faces': [0, 1, 7, 2, 3, 4, 5, 6], 'ground': (0.72, 0.66, 0.66), 'face': (0.86, 0.82, 0.8), 'sconce': 'lamp'},
    'flashback_cinema': {'faces': [0, 1, 7, 2, 3, 4, 5, 6], 'ground': (0.76, 0.76, 0.78), 'face': (0.86, 0.84, 0.84), 'sconce': 'lamp'},
    'last_resort_cruise': {'faces': [0, 1, 7, 2, 3, 4, 5, 6], 'ground': (0.8, 0.78, 0.76), 'face': (0.86, 0.86, 0.88), 'sconce': 'lamp'},
    'seance_hotline': {'faces': [0, 1, 7, 2, 3, 4, 5, 6], 'ground': (0.76, 0.74, 0.78), 'face': (0.86, 0.84, 0.88), 'sconce': 'lamp'},
    'terminal_zero': {'faces': [0, 1, 7, 2, 3, 4, 5, 6], 'ground': (0.62, 0.62, 0.66), 'face': (0.82, 0.82, 0.84), 'sconce': 'lamp'},
    'head_office': {'faces': [1, 7, 6, 2, 3, 5, 4, 0], 'ground': (0.72, 0.7, 0.68), 'face': (0.82, 0.8, 0.78), 'sconce': 'lamp'},
}


def area_ground(folder, mult, patch=None):
    sheet = load(os.path.join(folder, 'ground.png'))
    meta = json.load(open(os.path.join(folder, 'ground.json'), encoding='utf-8'))
    strip = [[(0, 0, 0, 0)] * (16 * TILE) for _ in range(TILE)]
    for tile in meta['tileset_data']['tiles']:
        c = tile['corners']
        index = (c['NW'] == 'upper') * 8 + (c['NE'] == 'upper') * 4 + (c['SW'] == 'upper') * 2 + (c['SE'] == 'upper')
        pixels = tone(crop(sheet, tile['bounding_box']), mult)
        for y in range(TILE):
            strip[y][index * TILE:(index + 1) * TILE] = pixels[y]
    if patch is not None:
        strip = calm_patch(strip, patch)
    return strip


# Pulls the patch terrain's pixels (those nearer the all-patch tile's mean than the all-base tile's, or
# far more coloured than the base, as the patch's own dark edge is) a share of the way to their own
# grey, then dims them: patch = (share kept of the colour, dim).
def calm_patch(strip, patch):
    keep, dim = patch

    def mean(index):
        px = [p for row in strip for p in row[index * TILE:(index + 1) * TILE]]
        return [sum(p[k] for p in px) / len(px) for k in range(3)]

    lower, upper = mean(0), mean(15)
    base_chroma = max(lower) - min(lower)
    out = []
    for row in strip:
        new_row = []
        for p in row:
            near_upper = sum((p[k] - upper[k]) ** 2 for k in range(3)) < sum((p[k] - lower[k]) ** 2 for k in range(3))
            near_upper = near_upper or max(p[:3]) - min(p[:3]) > base_chroma + 25
            if not near_upper or p[3] == 0:
                new_row.append(p)
                continue
            grey = 0.2126 * p[0] + 0.7152 * p[1] + 0.0722 * p[2]
            new_row.append(tuple(min(255, int((grey + (p[k] - grey) * keep) * dim)) for k in range(3)) + (p[3],))
        out.append(new_row)
    return out


# A wall top from a wall front: darker, and each pixel pulled toward its row's mean so the courses blur.
def cap_from(face):
    out = []
    for row in face:
        mean = [sum(p[c] for p in row) / len(row) for c in range(3)]
        out.append([(int((p[0] * 0.4 + mean[0] * 0.6) * 0.62), int((p[1] * 0.4 + mean[1] * 0.6) * 0.6),
                     int((p[2] * 0.4 + mean[2] * 0.6) * 0.6), 255) for p in row])
    return out


def build_area(export, game, art_set):
    spec = AREAS[art_set]
    folder = os.path.join(export, 'sets', art_set)
    out = os.path.join(game, 'art', 'tiles', art_set, 'depth')
    os.makedirs(out, exist_ok=True)
    save(os.path.join(out, 'ground.png'), area_ground(folder, spec['ground'], spec.get('patch')))
    faces = []
    for n, index in enumerate(spec['faces']):
        face = tone(load(os.path.join(folder, 'walls', 'tile_%d.png' % index)), spec['face'])
        faces.append(face)
        save(os.path.join(out, 'face_%d.png' % n), face)
    cap = cap_from(faces[0])
    save(os.path.join(out, 'cap.png'), cap)
    sconce_file = os.path.join(export, 'props', 'sconce.png') if spec['sconce'] == 'torch' else os.path.join(export, 'sets', '_shared', 'lamp.png')
    if os.path.exists(sconce_file):
        # The lamp came back on a flat white canvas, so its background is keyed out first.
        save(os.path.join(out, 'sconce.png'), fit(key_background(load(sconce_file)), 16, 26))
    props = os.path.join(game, 'art', 'props', art_set)
    os.makedirs(props, exist_ok=True)
    save(os.path.join(props, 'hole.png'), pit(faces[0], cap))
    for game_id, (name, w, h) in spec.get('props', {}).items():
        path = os.path.join(folder, 'props', name)
        if os.path.exists(path):
            save(os.path.join(props, game_id + '.png'), tone(fit(load(path), w, h, main=True), (0.78, 0.76, 0.74)))
            print(art_set, game_id)
    print('built', out)


if __name__ == '__main__':
    which = sys.argv[3] if len(sys.argv) > 3 else 'floor_1'
    if which in AREAS:
        build_area(sys.argv[1], sys.argv[2], which)
    else:
        build(sys.argv[1], sys.argv[2], which)
