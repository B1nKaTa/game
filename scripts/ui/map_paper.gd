class_name MapPaper
extends RefCounted

# The paper look both maps share: a floor plan drawn in ink on the case file's cream paper, as an
# architect would (the big map's sheet, the small map's scrap). Every mark is a block of whole pixels
# on the grid, so it stays crisp at any size the game shows. A mark is drawn on a CanvasItem in play,
# or painted into an Image by the tests, which then look at the marks themselves (no mark may read as a
# cross: two straight strokes running through each other).
const PAPER := CaseFile.PAPER
const PAPER_EDGE := CaseFile.PAPER_EDGE
const INK := CaseFile.INK
# A pencil line: a room the Floor Plan shows but he has not walked into, and the way to it.
const PENCIL := CaseFile.INK_DIM
const STAMP := CaseFile.STAMP
# A walked room's floor, a shade darker than the paper.
const ROOM_FILL := Color("e8dcbc")
# The graph paper's faint lines.
const GRID := Color("d9cba6")
const SHADOW := Color(0.0, 0.0, 0.0, 0.33)
const SHADOW_OFFSET := Vector2(5, 5)
const SHEET_EDGE := 2
# Around the stamp's words, inside its frame.
const STAMP_PAD := Vector2(5, 3)
const STAMP_FRAME := 2
# The pixel font's own line (art/ui/basement_ledger.fnt: lineHeight 9, base 7 at its 8 px size). The
# Font's get_height and get_ascent count its fallback font too, which is taller.
const FONT_LINE := 9
const FONT_BASE := 7


# One block of colour: drawn on a CanvasItem, or painted into an Image.
static func fill(canvas: Object, rect: Rect2, color: Color) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	if canvas is Image:
		var image := canvas as Image
		var box := Rect2i(rect.position.floor(), rect.size.floor()).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
		if box.size.x > 0 and box.size.y > 0:
			image.fill_rect(box, color)
	else:
		(canvas as CanvasItem).draw_rect(Rect2(rect.position.floor(), rect.size.floor()), color)


# Words in the game's pixel font, with `at` on the baseline. Only a CanvasItem shows them.
static func text(canvas: Object, at: Vector2, words: String, font_size: int, color: Color) -> void:
	if canvas is CanvasItem:
		(canvas as CanvasItem).draw_string(HudStyle.font(), at.floor(), words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


static func text_width(words: String, font_size: int) -> float:
	return HudStyle.font().get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


# A line of the pixel font at this size (a whole multiple of 8), and its baseline below the line's top.
static func line_height(font_size: int) -> float:
	return float(FONT_LINE * font_size / HudStyle.SMALL)


static func ascent(font_size: int) -> float:
	return float(FONT_BASE * font_size / HudStyle.SMALL)


# The baseline that centres a line of this size in a box's height.
static func baseline_in(box: Rect2, font_size: int) -> float:
	return box.position.y + floorf((box.size.y - line_height(font_size)) / 2.0) + ascent(font_size)


# Words centred in a box, by the font's own measure.
static func text_in(canvas: Object, box: Rect2, words: String, font_size: int, color: Color) -> void:
	var x := box.position.x + floorf((box.size.x - text_width(words, font_size)) / 2.0)
	text(canvas, Vector2(x, baseline_in(box, font_size)), words, font_size, color)


# A rectangle's edge, `width` pixels thick, drawn inside it. Its corners meet as corners, never crossing.
static func frame(canvas: Object, rect: Rect2, width: int, color: Color) -> void:
	for stroke in outline_strokes(rect, width, [], 0):
		fill(canvas, stroke, color)


# A sheet of paper with its edge and a shadow on the desk under it.
static func sheet(canvas: Object, rect: Rect2) -> void:
	fill(canvas, Rect2(rect.position + SHADOW_OFFSET, rect.size), SHADOW)
	fill(canvas, rect, PAPER)
	frame(canvas, rect, SHEET_EDGE, PAPER_EDGE)


# Graph paper's faint lines every `step` pixels. Each line stops a pixel short of every other line, so
# the paper holds small squares and no spot of it is two lines running through each other.
static func grid(canvas: Object, area: Rect2, step: int, color := GRID) -> void:
	var x := area.position.x
	while x < area.end.x:
		var y := area.position.y
		while y < area.end.y:
			var right := minf(x + step - 1.0, area.end.x)
			var bottom := minf(y + step - 1.0, area.end.y)
			fill(canvas, Rect2(x + 2.0, y, right - x - 2.0, 1.0), color)
			fill(canvas, Rect2(x, y + 2.0, 1.0, bottom - y - 2.0), color)
			y += step
		x += step


# The middle of a room's edge on one side, on whole pixels.
static func edge_mid(rect: Rect2, side: Vector2i) -> Vector2:
	var center := (rect.position + (rect.size / 2.0).floor())
	match side:
		Vector2i.RIGHT:
			return Vector2(rect.end.x, center.y)
		Vector2i.LEFT:
			return Vector2(rect.position.x, center.y)
		Vector2i.DOWN:
			return Vector2(center.x, rect.end.y)
	return Vector2(center.x, rect.position.y)


# A room's edge as strokes `width` thick, with a door gap on each side in `gaps` between the two walls
# of a corridor `gap_half` from the middle (the gap is the corridor's inside, so its walls join the room's).
static func outline_strokes(rect: Rect2, width: int, gaps: Array, gap_half: int, line := 1) -> Array[Rect2]:
	var strokes: Array[Rect2] = []
	var w := float(width)
	var sides := {
		Vector2i.UP: Rect2(rect.position, Vector2(rect.size.x, w)),
		Vector2i.DOWN: Rect2(rect.position.x, rect.end.y - w, rect.size.x, w),
		Vector2i.LEFT: Rect2(rect.position.x, rect.position.y + w, w, rect.size.y - 2.0 * w),
		Vector2i.RIGHT: Rect2(rect.end.x - w, rect.position.y + w, w, rect.size.y - 2.0 * w),
	}
	for side: Vector2i in sides:
		var stroke: Rect2 = sides[side]
		if not gaps.has(side):
			strokes.append(stroke)
			continue
		var mid := edge_mid(rect, side)
		var inner := float(gap_half - line)
		if side.y != 0:
			strokes.append(Rect2(stroke.position, Vector2(mid.x - inner - stroke.position.x, w)))
			strokes.append(Rect2(mid.x + inner, stroke.position.y, stroke.end.x - mid.x - inner, w))
		else:
			strokes.append(Rect2(stroke.position, Vector2(w, mid.y - inner - stroke.position.y)))
			strokes.append(Rect2(stroke.position.x, mid.y + inner, w, stroke.end.y - mid.y - inner))
	return strokes


static func outline(canvas: Object, rect: Rect2, width: int, color: Color, gaps: Array = [], gap_half := 0, line := 1) -> void:
	for stroke in outline_strokes(rect, width, gaps, gap_half, line):
		fill(canvas, stroke, color)


# The two walls of a corridor running `length` pixels out of a room's side, `half` either side of its
# middle, each `line` thick; `dash` > 0 breaks them into dashes that long with gaps as long. The grid
# under it is wiped first, a pixel either side, so no grid line runs through a wall.
static func corridor_strokes(from: Vector2, side: Vector2i, length: int, half: int, line: int, dash := 0) -> Array[Rect2]:
	var strokes: Array[Rect2] = []
	var step := length if dash <= 0 else dash
	var gap := 0 if dash <= 0 else dash
	var t := 0
	while t < length:
		var run := mini(step, length - t)
		for wall in [-1, 1]:
			var across := float(-half if wall < 0 else half - line)
			if side.x != 0:
				var x := from.x + t if side.x > 0 else from.x - t - run
				strokes.append(Rect2(x, from.y + across, run, line))
			else:
				var y := from.y + t if side.y > 0 else from.y - t - run
				strokes.append(Rect2(from.x + across, y, line, run))
		t += step + gap
	return strokes


# The corridor's whole footprint, a pixel wider than its walls on both sides.
static func corridor_box(from: Vector2, side: Vector2i, length: int, half: int) -> Rect2:
	var along := Vector2(side) * length
	var box := Rect2(from, Vector2.ZERO).expand(from + along)
	if side.x != 0:
		return Rect2(box.position.x, from.y - half - 1, box.size.x, half * 2 + 2)
	return Rect2(from.x - half - 1, box.position.y, half * 2 + 2, box.size.y)


# A corridor between two rooms side by side: two solid walls across the gap between their edges.
static func corridor(canvas: Object, a: Rect2, b: Rect2, half: int, line: int, color: Color) -> void:
	var side := side_between(a, b)
	var from := edge_mid(a, side)
	var length := int(absf((edge_mid(b, -side) - from).dot(Vector2(side))))
	fill(canvas, corridor_box(from, side, length, half), PAPER)
	for stroke in corridor_strokes(from, side, length, half, line):
		fill(canvas, stroke, color)


# Which way b lies from a, as a grid side.
static func side_between(a: Rect2, b: Rect2) -> Vector2i:
	var d := b.get_center() - a.get_center()
	if absf(d.x) >= absf(d.y):
		return Vector2i.RIGHT if d.x > 0 else Vector2i.LEFT
	return Vector2i.DOWN if d.y > 0 else Vector2i.UP


# An exit not yet walked through: a dashed corridor `length` long out of a room's side. Returns the
# middle of its far end, where its sign goes.
static func stub(canvas: Object, from_rect: Rect2, side: Vector2i, length: int, half: int, line: int, dash: int, color: Color) -> Vector2:
	var from := edge_mid(from_rect, side)
	fill(canvas, corridor_box(from, side, length, half), PAPER)
	for stroke in corridor_strokes(from, side, length, half, line, dash):
		fill(canvas, stroke, color)
	return stub_end(from_rect, side, length)


static func stub_end(from_rect: Rect2, side: Vector2i, length: int) -> Vector2:
	return edge_mid(from_rect, side) + Vector2(side) * length


# Where a sign `scale` times DoorSign.SIZE big sits past a stub's end: a pixel clear of it.
static func stub_sign_rect(end: Vector2, side: Vector2i, scale: int) -> Rect2:
	var size := float(DoorSign.SIZE * scale)
	var center := end + Vector2(side) * (size / 2.0 + 1.0)
	return Rect2((center - Vector2(size, size) / 2.0).floor(), Vector2(size, size))


# A door sign's picture as ink line art: 'x' is ink (the outline and the dark shade), 's' the lighter
# shade (the highlights), '.' bare paper. The arcade's die has no picture here; ink_sign draws it.
static func ink_cells(icon: String) -> Array:
	var rows: Array = []
	if not DoorSign.PICTURES.has(icon):
		return rows
	for row: String in DoorSign.PICTURES[icon]:
		var line := ""
		for c in row:
			match c:
				"#", "d":
					line += "x"
				"w":
					line += "s"
				_:
					line += "."
		rows.append(line)
	return rows


# A room's door sign in ink, each picture cell `scale` pixels square, its middle at `center`. A room
# with no sign (a plain fight room, the way back) draws nothing.
static func ink_sign(canvas: Object, center: Vector2, icon: String, scale: int, ink := INK, shade := PENCIL) -> void:
	if not DoorSign.has_sign(icon):
		return
	var size := DoorSign.SIZE * scale
	var origin := (center - Vector2(size, size) / 2.0).floor()
	if icon == RoomRules.ARCADE_ICON:
		ink_die(canvas, Rect2(origin, Vector2(size, size)), scale, ink)
		return
	var rows := ink_cells(icon)
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] == "x" or row[x] == "s":
				fill(canvas, Rect2(origin + Vector2(x, y) * scale, Vector2(scale, scale)), ink if row[x] == "x" else shade)


# The arcade's die in ink: a square edge and the five's pips, each pip a dot apart from the rest.
static func ink_die(canvas: Object, box: Rect2, scale: int, ink: Color) -> void:
	frame(canvas, box, scale, ink)
	var inner := box.grow(-float(scale * 2))
	for corner: Vector2 in [Vector2.ZERO, Vector2(1, 0), Vector2(0.5, 0.5), Vector2(0, 1), Vector2(1, 1)]:
		var at := (inner.position + (inner.size - Vector2(scale, scale)) * corner).floor()
		fill(canvas, Rect2(at, Vector2(scale, scale)), ink)


# A rubber stamp's box for these words at this size.
static func stamp_size(words: String, font_size: int) -> Vector2:
	var inner := Vector2(text_width(words, font_size), line_height(font_size)) + STAMP_PAD * 2.0
	return (inner + Vector2.ONE * STAMP_FRAME * 2.0).ceil()


# A red rubber stamp: words in a frame, pressed on a clean patch so nothing under it shows through.
static func stamp(canvas: Object, rect: Rect2, words: String, font_size: int, color := STAMP) -> void:
	fill(canvas, rect, PAPER)
	frame(canvas, rect, STAMP_FRAME, color)
	text_in(canvas, rect, words, font_size, color)


# How thick a room's outline is, how far a corridor's walls stand from its middle, and how big a sign
# is drawn, for rooms this big on the map.
static func outline_width(room: Vector2) -> int:
	return 2 if room.y >= 24.0 else 1


static func corridor_half(room: Vector2) -> int:
	return clampi(int(room.y) / 6, 2, 6)


static func sign_scale(room: Vector2) -> int:
	return clampi((int(room.y) - 6) / DoorSign.SIZE, 1, 3)
