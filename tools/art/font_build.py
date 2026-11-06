# Builds the HUD's bitmap font (art/ui/basement_ledger.png + .fnt, a BMFont text file Godot imports) from
# the PixelLab create_font atlas, with the glyphs that read badly redrawn by hand. Plain Python, no packages.
# Usage: py tools/art/font_build.py <atlas.png> <game root>
#
# The atlas is 8 columns of 8 px cells in ORDER. Each glyph keeps its own used columns, so the font is
# proportional, and advances one pixel past them. FIXES replaces a glyph (D and O came out swapped in
# shape, so D read as O) or adds one the atlas lacks ([ and ]). '#' is ink.
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from env_art import load, save  # noqa: E402

CELL = 8
ORDER = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.,!?:;'\"-+()0123456789/%*=_$"
FIXES = {
    'D': ["####", "#...#", "#...#", "#...#", "#...#", "#...#", "####"],
    'O': [".###", "#...#", "#...#", "#...#", "#...#", "#...#", ".###"],
    '[': ["###", "#", "#", "#", "#", "#", "###"],
    ']': ["###", "..#", "..#", "..#", "..#", "..#", "###"],
}
SPACE_ADVANCE = 3
LINE_HEIGHT = 9
BASE = 7


def main():
    atlas = load(sys.argv[1])
    root = sys.argv[2]
    glyphs = {}
    for i, ch in enumerate(ORDER):
        cx, cy = (i % 8) * CELL, (i // 8) * CELL
        cells = [[atlas[cy + y][cx + x][3] > 128 for x in range(CELL)] for y in range(CELL)]
        glyphs[ch] = cells
    for ch, rows in FIXES.items():
        cells = [[False] * CELL for _ in range(CELL)]
        for y, row in enumerate(rows):
            for x, c in enumerate(row):
                if c == '#':
                    cells[y][x + 1] = True
        glyphs[ch] = cells
    chars = list(glyphs.keys())
    cols = 10
    rows_n = (len(chars) + cols - 1) // cols
    sheet = [[(0, 0, 0, 0)] * (cols * CELL) for _ in range(rows_n * CELL)]
    lines = []
    for n, ch in enumerate(chars):
        cells = glyphs[ch]
        used = [x for x in range(CELL) if any(cells[y][x] for y in range(CELL))]
        first, last = (used[0], used[-1]) if used else (0, 0)
        sx, sy = (n % cols) * CELL, (n // cols) * CELL
        for y in range(CELL):
            for x in range(CELL):
                if cells[y][x]:
                    sheet[sy + y][sx + x] = (255, 255, 255, 255)
        width = last - first + 1
        lines.append('char id=%d x=%d y=%d width=%d height=%d xoffset=0 yoffset=0 xadvance=%d page=0 chnl=15'
                     % (ord(ch), sx + first, sy, width, CELL, width + 1))
    lines.append('char id=32 x=0 y=0 width=0 height=0 xoffset=0 yoffset=0 xadvance=%d page=0 chnl=15' % SPACE_ADVANCE)
    out = os.path.join(root, 'art', 'ui')
    os.makedirs(out, exist_ok=True)
    save(os.path.join(out, 'basement_ledger.png'), sheet)
    header = [
        'info face="Basement Ledger" size=8 bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1',
        'common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0' % (LINE_HEIGHT, BASE, cols * CELL, rows_n * CELL),
        'page id=0 file="basement_ledger.png"',
        'chars count=%d' % (len(lines)),
    ]
    with open(os.path.join(out, 'basement_ledger.fnt'), 'w', encoding='utf-8', newline='\r\n') as f:
        f.write('\n'.join(header + lines) + '\n')
    print('font', len(lines), 'glyphs')


if __name__ == '__main__':
    main()
