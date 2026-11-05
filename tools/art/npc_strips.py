# Builds an NPC's strips from a PixelLab export: idle.png from the four south idle frames and
# rotations.png from the eight rotations (south, south-east, east, north-east, north, north-west, west,
# south-west), each a row of 48 px frames, into art/npcs/<id>/. Plain Python, no packages.
# Usage: py tools/art/npc_strips.py <export folder holding one folder per npc id> <art/npcs folder> [id ...]
# With --idle-from-south, an export with no idle animation gets a hand-made breathing loop from its south
# rotation instead: frames 0 and 2 as drawn, frames 1 and 3 with everything above the waist 1 px lower.
# The feet rows stay the same in every frame, so he doesn't jitter.
import os
import struct
import sys
import zlib

ORDER = ['south', 'south-east', 'east', 'north-east', 'north', 'north-west', 'west', 'south-west']


def load(path):
    data = open(path, 'rb').read()
    pos = 8
    idat = b''
    while pos < len(data):
        length, kind = struct.unpack('>I4s', data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + length]
        if kind == b'IHDR':
            width, height, depth, colour = struct.unpack('>IIBB', body[:10])
        elif kind == b'IDAT':
            idat += body
        pos += 12 + length
    if depth != 8 or colour != 6:
        raise ValueError('%s is not 8-bit RGBA' % path)
    raw = zlib.decompress(idat)
    stride = width * 4
    rows = []
    prev = bytearray(stride)
    i = 0
    for _ in range(height):
        kind = raw[i]
        i += 1
        line = bytearray(raw[i:i + stride])
        i += stride
        for x in range(stride):
            a = line[x - 4] if x >= 4 else 0
            b = prev[x]
            c = prev[x - 4] if x >= 4 else 0
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
        rows.append(line)
        prev = line
    return width, height, rows


def save(path, width, height, rows):
    def chunk(kind, body):
        return struct.pack('>I', len(body)) + kind + body + struct.pack('>I', zlib.crc32(kind + body) & 0xffffffff)
    raw = b''.join(b'\x00' + bytes(row) for row in rows)
    png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
    png += chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b'')
    open(path, 'wb').write(png)


def strip(files, out):
    join([load(f) for f in files], out)


# Where the waist is, as a share of the figure's height from the top of the head down to the feet.
WAIST = 0.55


def breathe(frame):
    width, height, rows = frame
    used = [y for y in range(height) if any(rows[y][x * 4 + 3] for x in range(width))]
    top, bottom = used[0], used[-1] + 1
    waist = top + int(round((bottom - top) * WAIST))
    lower = [bytearray(width * 4)] + [bytearray(r) for r in rows[:waist - 1]]
    return width, height, lower + [bytearray(r) for r in rows[waist:]]


def join(frames, out):
    width, height = frames[0][0], frames[0][1]
    if any(f[0] != width or f[1] != height for f in frames):
        raise ValueError('frames for %s differ in size' % out)
    rows = [bytearray() for _ in range(height)]
    for _, _, frame in frames:
        for y in range(height):
            rows[y] += frame[y]
    save(out, width * len(frames), height, rows)


def main():
    args = sys.argv[1:]
    from_south = '--idle-from-south' in args
    args = [a for a in args if a != '--idle-from-south']
    source, target = args[0], args[1]
    ids = args[2:] or sorted(d for d in os.listdir(source) if os.path.isdir(os.path.join(source, d, 'Idle')))
    for npc in ids:
        base = os.path.join(source, npc, 'Idle')
        os.makedirs(os.path.join(target, npc), exist_ok=True)
        idle = os.path.join(target, npc, 'idle.png')
        if from_south:
            south = load(os.path.join(base, 'rotations', 'south.png'))
            join([south, breathe(south), south, breathe(south)], idle)
        else:
            strip([os.path.join(base, 'animations', 'idle', 'south', 'frame_%03d.png' % i) for i in range(4)], idle)
        strip([os.path.join(base, 'rotations', d + '.png') for d in ORDER], os.path.join(target, npc, 'rotations.png'))
        print(npc)


if __name__ == '__main__':
    main()
