# Builds the "depth" look of an art set (docs/art/art-direction-notes.md): one continuous ground made of
# Wang tiles, wall caps and front faces, the wall sconce, and the set's own props. Plain Python, no packages.
#
# Usage: py tools/art/depth_art.py <export folder> <game root> [set]
#
# The export folder (D:/grandpa-art/direction) holds, as saved from PixelLab:
#   tiles/ground1.png + ground1.json   a create_topdown_tileset sheet (16 Wang tiles) and its metadata,
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
from env_art import fit, load, luma, save  # noqa: E402

TILE = 32
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
    'crate': ('boxes.png', 30, 30, None),
    'rock': ('rubble.png', 28, 28, 'brick'),
    'hole': ('hole.png', 32, 32, 'exact'),
    'bone_pile': ('bones.png', 26, 20, None),
    # The basement has no grass: its tufts are loose sheets of paper, and a cut one a few torn scraps.
    'grass': ('papers_flat.png', 22, 20, 'paper'),
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
    sheet = load(os.path.join(export, 'tiles', 'ground1.png'))
    meta = json.load(open(os.path.join(export, 'tiles', 'ground1.json'), encoding='utf-8'))
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
        if recolour == 'paper':
            pixels = tone(pixels, (0.82, 0.78, 0.7))
        if recolour == 'scrap':
            pixels = tone(pixels, (0.62, 0.58, 0.52))
        if recolour == 'brick':
            pixels = tone(recolour_brick(pixels), (0.78, 0.76, 0.74))
        save(os.path.join(props, game_id + '.png'), pixels)
        print(game_id, len(pixels[0]), 'x', len(pixels))
    print('built', out)


if __name__ == '__main__':
    build(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else 'floor_1')
