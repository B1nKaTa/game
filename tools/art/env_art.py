# Builds the room art (floor and wall tiles, props, decor, doors, chests and pickups) from PixelLab
# exports into art/tiles and art/props. Plain Python, no packages.
#
# Usage:
#   py tools/art/env_art.py tiles <export root> <game root> [set ...]
#   py tools/art/env_art.py props <export root> <game root> [set ...]
#   py tools/art/env_art.py check <game root>
#
# The export root holds one folder per art set (a floor id such as floor_1, or shared, waiting_room,
# crossroads), as saved from PixelLab: <set>/tiles/tile_0.png .. tile_15.png from one create_tiles_pro
# sheet, and <set>/props/<name>.png from create_map_object.
#
# Tiles. Each sheet is numbered as TILE_ROLES says: four variants of each floor tone, then two walls and
# two wall faces. Every tile is moved onto its tone: its mean colour becomes the palette's floor_a,
# floor_b, floor_c or wall (read from the floor's .tres, so every lit-contrast check already made against
# those colours still holds), and its detail is squeezed until its spread of brightness is at most
# FLOOR_SPREAD (WALL_SPREAD for walls). Drawn unlit and flat; the engine lights them.
#
# Props. Each PROPS entry trims the export to its used pixels, shrinks it to fit the prop's box if it is
# bigger (by the commonest colour in each block, so the outline survives), makes every pixel fully
# opaque or fully clear, and writes art/props/[<set>/]<id>.png.
import os
import re
import struct
import sys
import zlib

TILE = 32
TILE_ROLES = {
    'floor_a': [0, 1, 2, 3],
    'floor_b': [4, 5, 6, 7],
    'floor_c': [8, 9, 10, 11],
    'wall': [12, 13],
    'wall_face': [14, 15],
}
# Tiles left out of a sheet because they came out wrong (index: why).
SKIP = {
    # The third sheet; the first two came back as blank white tiles.
    'cemetery': {5: 'red leaves that read as warning specks', 7: 'a dark blotch like a pit', 11: 'a dark blotch like a pit'},
    'funeral_parlour': {1: 'pale scribble like writing', 8: 'a strip of grass along its foot'},
    'head_office': {3: 'a yellow swirl like a logo', 7: 'worn blotches that read as a motif in play'},
    'furnace_works': {10: 'cracks that read as the crack decor'},
    'sunset_shores': {1: 'a waffle grid that reads as a pattern in play'},
    # The second sheet (the first was busy with grids and blotches).
    'terminal_zero': {0: 'a weave that reads as a window grid', 1: 'a weave that reads as a window grid'},
    'waiting_room': {1: 'a loud diamond motif', 7: 'a worn blotch that reads as a stain', 11: 'a grey scuff like a scribble'},
}
# Spread of brightness (standard deviation, 0 to 1) a tile may keep. Floors stay quiet so bodies stay
# the strongest contrast in the room; walls may show their courses.
FLOOR_SPREAD = 0.035
WALL_SPREAD = 0.07
# Bright floors show the same spread as louder speckle, so theirs is quieter.
QUIET_FLOORS = {'head_office': 0.025, 'terminal_zero': 0.025}

# Tones that override the palette's for the tiles only, as hex: a set whose palette keeps another look
# in code, and a tone moved to keep a path's three within 10% of each other. The Cinema and the Seance
# Hotline, drawn ahead of their floors, now build onto their own palettes' tones.
EXTRA_TONES = {
    # The palette's iron-plate tone (0.30 value) sits 0.12 under the rust; lifted to 0.36, still the
    # darkest of the three, so the plate patches read without a dark checkerboard.
    'furnace_works': {'floor_b': '5c4d44'},
    # The palette's wine (0.45 value) lights up next to the warning red under the parlour's warm
    # torches, and the brown third tone sits 0.09 under it. Darker wine and a matching brown keep every
    # warning lighter than the carpet.
    'funeral_parlour': {'floor_a': '561528', 'floor_b': '4c1223', 'floor_c': '553a27'},
    # The Waiting Room's palette keeps the stone defaults for its code look; its art is warmer, a brown
    # lobby carpet and parquet under olive wallpaper, as the inventory allows (section 4.4).
    'waiting_room': {'floor_a': '6b5946', 'floor_b': '645341', 'floor_c': '6f5c48', 'wall': '46462f'},
}


# ---------------------------------------------------------------- PNG


def load(path):
    data = open(path, 'rb').read()
    pos = 8
    idat = b''
    palette = []
    trns = b''
    while pos < len(data):
        length, kind = struct.unpack('>I4s', data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + length]
        if kind == b'IHDR':
            width, height, depth, colour, _c, _f, interlace = struct.unpack('>IIBBBBB', body)
        elif kind == b'PLTE':
            palette = [tuple(body[i:i + 3]) for i in range(0, len(body), 3)]
        elif kind == b'tRNS':
            trns = body
        elif kind == b'IDAT':
            idat += body
        pos += 12 + length
    if depth != 8 or interlace != 0 or colour not in (2, 3, 6):
        raise ValueError('%s: unsupported PNG (depth %d, colour %d)' % (path, depth, colour))
    channels = {2: 3, 3: 1, 6: 4}[colour]
    raw = zlib.decompress(idat)
    stride = width * channels
    prev = bytearray(stride)
    pixels = []
    i = 0
    for _ in range(height):
        kind = raw[i]
        i += 1
        line = bytearray(raw[i:i + stride])
        i += stride
        for x in range(stride):
            a = line[x - channels] if x >= channels else 0
            b = prev[x]
            c = prev[x - channels] if x >= channels else 0
            if kind == 1:
                line[x] = (line[x] + a) & 255
            elif kind == 2:
                line[x] = (line[x] + b) & 255
            elif kind == 3:
                line[x] = (line[x] + (a + b) // 2) & 255
            elif kind == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else (b if pb <= pc else c))) & 255
        row = []
        for x in range(width):
            if colour == 6:
                row.append(tuple(line[x * 4:x * 4 + 4]))
            elif colour == 2:
                row.append(tuple(line[x * 3:x * 3 + 3]) + (255,))
            else:
                index = line[x]
                alpha = trns[index] if index < len(trns) else 255
                row.append(palette[index] + (alpha,))
        pixels.append(row)
        prev = line
    return pixels


def save(path, pixels):
    height = len(pixels)
    width = len(pixels[0])

    def chunk(kind, body):
        return struct.pack('>I', len(body)) + kind + body + struct.pack('>I', zlib.crc32(kind + body) & 0xffffffff)
    raw = b''.join(b'\x00' + bytes(v for p in row for v in p) for row in pixels)
    png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
    png += chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b'')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'wb').write(png)


# ---------------------------------------------------------------- colour


def luma(rgb):
    return (0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]) / 255.0


def hex_rgb(text):
    return tuple(int(text[i:i + 2], 16) for i in (0, 2, 4))


def parse_colour(text):
    text = text.strip()
    m = re.match(r'Color\(\s*"#?([0-9a-fA-F]{6})', text)
    if m:
        return hex_rgb(m.group(1))
    m = re.match(r'Color\(([^)]*)\)', text)
    if m:
        parts = [float(v) for v in m.group(1).split(',')]
        return tuple(int(round(v * 255)) for v in parts[:3])
    raise ValueError(text)


def tones(game, art_set):
    # The palette's defaults (RoomPalette), then whatever the floor's .tres overrides.
    found = {}
    source = open(os.path.join(game, 'scripts', 'content', 'room_palette.gd'), encoding='utf-8').read()
    for key in ('floor_a', 'floor_b', 'floor_c', 'wall'):
        found[key] = parse_colour(re.search(r'var %s := (Color\([^)]*\))' % key, source).group(1))
    tres = os.path.join(game, 'data', 'floors', art_set + '.tres')
    if os.path.exists(tres):
        text = open(tres, encoding='utf-8').read()
        for key in ('floor_a', 'floor_b', 'floor_c', 'wall'):
            m = re.search(r'^%s = (Color\([^)]*\))' % key, text, re.M)
            if m:
                found[key] = parse_colour(m.group(1))
    for key, value in EXTRA_TONES.get(art_set, {}).items():
        found[key] = hex_rgb(value)
    return found


def onto_tone(pixels, target, spread):
    opaque = [p for row in pixels for p in row if p[3] > 0]
    n = float(len(opaque))
    mean = [sum(p[c] for p in opaque) / n for c in range(3)]
    lumas = [luma(p) for p in opaque]
    lmean = sum(lumas) / n
    std = (sum((v - lmean) ** 2 for v in lumas) / n) ** 0.5
    squeeze = min(1.0, spread / std) if std > 0 else 1.0
    out = []
    for row in pixels:
        line = []
        for p in row:
            line.append(tuple(max(0, min(255, int(round(target[c] + (p[c] - mean[c]) * squeeze)))) for c in range(3)) + (255,))
        out.append(line)
    return out


def build_tiles(export, game, art_set):
    source = os.path.join(export, art_set, 'tiles')
    target = os.path.join(game, 'art', 'tiles', art_set)
    tone = tones(game, art_set)
    skip = SKIP.get(art_set, {})
    written = set()
    for role, all_indices in TILE_ROLES.items():
        indices = [i for i in all_indices if i not in skip]
        for index in indices:
            raw = load(os.path.join(source, 'tile_%d.png' % index))
            lumas = [luma(p) for row in raw for p in row]
            spread = (sum((v - sum(lumas) / len(lumas)) ** 2 for v in lumas) / len(lumas)) ** 0.5
            # A failed sheet comes back as blank white tiles, which would build as flat colour.
            if spread < 0.02 and sum(lumas) / len(lumas) > 0.9:
                raise ValueError('%s tile %d is blank white; regenerate the sheet' % (art_set, index))
        colour = tone['wall' if role.startswith('wall') else role]
        spread = WALL_SPREAD if role.startswith('wall') else QUIET_FLOORS.get(art_set, FLOOR_SPREAD)
        for n, index in enumerate(indices):
            pixels = load(os.path.join(source, 'tile_%d.png' % index))
            if len(pixels) != TILE or len(pixels[0]) != TILE:
                raise ValueError('%s tile %d is not %d px' % (art_set, index, TILE))
            name = '%s_%d.png' % (role, n)
            save(os.path.join(target, name), onto_tone(pixels, colour, spread))
            written.add(name)
    # A tile dropped since the last build goes, with its import, so the game never picks it up.
    for f in os.listdir(target):
        if f.endswith('.png') and f not in written:
            os.remove(os.path.join(target, f))
        if f.endswith('.png.import') and f[:-7] not in written:
            os.remove(os.path.join(target, f))
    print('tiles', art_set, '->', target)


# ---------------------------------------------------------------- props


def trim(pixels):
    rows = [y for y, row in enumerate(pixels) if any(p[3] > 0 for p in row)]
    cols = [x for x in range(len(pixels[0])) if any(row[x][3] > 0 for row in pixels)]
    return [row[cols[0]:cols[-1] + 1] for row in pixels[rows[0]:rows[-1] + 1]]


def shrink(pixels, width, height):
    sh, sw = len(pixels), len(pixels[0])
    out = []
    for y in range(height):
        line = []
        y0, y1 = int(y * sh / height), max(int((y + 1) * sh / height), int(y * sh / height) + 1)
        for x in range(width):
            x0, x1 = int(x * sw / width), max(int((x + 1) * sw / width), int(x * sw / width) + 1)
            block = [pixels[j][i] for j in range(y0, y1) for i in range(x0, x1)]
            solid = [p[:3] for p in block if p[3] >= 128]
            if len(solid) * 2 < len(block):
                line.append((0, 0, 0, 0))
                continue
            counts = {}
            for p in solid:
                counts[p] = counts.get(p, 0) + 1
            # The darkest of the commonest colours wins a tie, so outlines are kept.
            best = max(counts.items(), key=lambda kv: (kv[1], -sum(kv[0])))[0]
            line.append(best + (255,))
        out.append(line)
    return out


def hard_alpha(pixels):
    return [[p[:3] + (255,) if p[3] >= 128 else (0, 0, 0, 0) for p in row] for row in pixels]


def key_background(pixels, reach=40):
    # A canvas too big for PixelLab to clear comes back on one flat colour: everything joined to the
    # corners within reach of that colour goes clear.
    h, w = len(pixels), len(pixels[0])
    bg = pixels[0][0][:3]
    near = lambda p: sum(abs(p[c] - bg[c]) for c in range(3)) <= reach
    out = [list(row) for row in pixels]
    stack = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]
    seen = set()
    while stack:
        x, y = stack.pop()
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h) or not near(pixels[y][x]):
            continue
        seen.add((x, y))
        out[y][x] = (0, 0, 0, 0)
        stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    return out


def main_part(pixels):
    # The largest piece of touching pixels, so a stray sign floating beside a desk is dropped.
    h, w = len(pixels), len(pixels[0])
    seen = [[False] * w for _ in range(h)]
    best = []
    for y in range(h):
        for x in range(w):
            if seen[y][x] or pixels[y][x][3] == 0:
                continue
            part, stack = [], [(x, y)]
            seen[y][x] = True
            while stack:
                cx, cy = stack.pop()
                part.append((cx, cy))
                for nx in (cx - 1, cx, cx + 1):
                    for ny in (cy - 1, cy, cy + 1):
                        if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and pixels[ny][nx][3] > 0:
                            seen[ny][nx] = True
                            stack.append((nx, ny))
            if len(part) > len(best):
                best = part
    keep = set(best)
    return [[p if (x, y) in keep else (0, 0, 0, 0) for x, p in enumerate(row)] for y, row in enumerate(pixels)]


def fit(pixels, max_w, max_h, exact=False, main=False):
    pixels = hard_alpha(pixels)
    if main:
        pixels = main_part(pixels)
    pixels = trim(pixels)
    h, w = len(pixels), len(pixels[0])
    # A floor piece that must fill its cell (a hole, pool water) is stretched or squeezed to it exactly.
    if exact:
        return shrink(pixels, max_w, max_h)
    scale = min(1.0, max_w / float(w), max_h / float(h))
    if scale < 1.0:
        pixels = shrink(pixels, max(1, int(round(w * scale))), max(1, int(round(h * scale))))
    return pixels


# Every prop is a line of tools/art/env_props.txt: set (shared for art/props itself), game id, export file
# under <export>/<set>/props, max width, max height. Boxes come from each prop's body or drawn size in
# docs/art/art-inventory.md section 2, a little larger where the art may lean outside it. A sixth word,
# exact, makes the picture exactly that size, for floor pieces that fill their cell; main keeps only the
# largest piece of touching pixels; keybg clears a flat background joined to the corners.
MANIFEST = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'env_props.txt')


def read_manifest():
    entries = []
    for line in open(MANIFEST, encoding='utf-8'):
        line = line.split('#', 1)[0].strip()
        if not line:
            continue
        parts = line.split()
        art_set, game_id, export_file, max_w, max_h = parts[:5]
        entries.append((art_set, game_id, export_file, int(max_w), int(max_h), parts[5:]))
    return entries


def build_props(export, game, sets):
    made = 0
    for art_set, game_id, export_file, max_w, max_h, flags in read_manifest():
        if sets and art_set not in sets:
            continue
        source = os.path.join(export, art_set, 'props', export_file)
        if not os.path.exists(source):
            print('missing', source)
            continue
        folder = os.path.join(game, 'art', 'props')
        if art_set not in ('shared',):
            folder = os.path.join(folder, art_set)
        pixels = load(source)
        if 'keybg' in flags:
            pixels = key_background(pixels)
        pixels = fit(pixels, max_w, max_h, 'exact' in flags, 'main' in flags)
        save(os.path.join(folder, game_id + '.png'), pixels)
        made += 1
    print('props', made)


def check(game):
    bad = 0
    for root, _dirs, files in os.walk(os.path.join(game, 'art', 'tiles')):
        for f in files:
            if f.endswith('.png'):
                p = load(os.path.join(root, f))
                if len(p) != TILE or len(p[0]) != TILE or any(px[3] != 255 for row in p for px in row):
                    print('bad tile', os.path.join(root, f))
                    bad += 1
    print('check done,', bad, 'bad')
    return bad


def main():
    command = sys.argv[1]
    if command == 'check':
        sys.exit(1 if check(sys.argv[2]) else 0)
    export, game = sys.argv[2], sys.argv[3]
    sets = sys.argv[4:]
    if command == 'tiles':
        for art_set in sets or sorted(os.listdir(export)):
            if os.path.isdir(os.path.join(export, art_set, 'tiles')):
                build_tiles(export, game, art_set)
    elif command == 'props':
        build_props(export, game, sets)


if __name__ == '__main__':
    main()
