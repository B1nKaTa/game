class_name SeanceLook
extends RefCounted

# How the Beyond Calling Psychic Hotline's floor and walls are drawn, called from RoomBackdrop for a
# palette that asks for them. The carpet is a deep violet pile with a few faint four-point stars and
# thin crescent moons woven in, scattered by a per-cell roll so they never line up. The walls are dark
# teal panels under a thin teal rail, with a small star on every other panel above the dado line.
#
# Shapes kept off the carpet on purpose: no blobs, drips or puddle shapes (the ectoplasm's sticky trail),
# no letter grid, square grid or seams round each cell (the Ouija board Madame Zara lays), no dark bands
# with holes (a film strip's look), and no bright diagonal streaks (a wet floor's look). The stars are two
# short thin strokes, upright and level, and the moons two thin arcs, all faint.
#
# The numbers stand past the shared patterns' 1 to 3 and the other paths' 10, 12, 13 and 14.
const CARPET := 15
const STAR_WALL := 15
# Of every hundred carpet cells, about this many carry a star and this many more a moon.
const STAR_SHARE := 0.2
const MOON_SHARE := 0.07
# A roll of its own, so the carpet's stars never follow the floor tones or the scatter.
const SALT := 4157
# How far from a cell's edge a star or moon keeps, in pixels.
const MARGIN := 7.0


# What a carpet cell carries: 0 plain, 1 a star, 2 a moon.
static func motif_of(cell: Vector2i) -> int:
	var roll := RoomDecor.noise(cell, SALT)
	if roll < STAR_SHARE:
		return 1
	if roll < STAR_SHARE + MOON_SHARE:
		return 2
	return 0


# Where in its cell a star or moon sits, so they never form rows or columns.
static func motif_offset(cell: Vector2i, tile_size: float) -> Vector2:
	var span := tile_size - MARGIN * 2.0
	return Vector2(MARGIN + RoomDecor.noise(Vector2i(cell.y, cell.x), SALT + 1) * span, MARGIN + RoomDecor.noise(cell, SALT + 2) * span)


static func draw_floor_tile(canvas: CanvasItem, tile: Rect2, cell: Vector2i, palette: RoomPalette) -> void:
	var motif := motif_of(cell)
	if motif == 0:
		return
	var at := tile.position + motif_offset(cell, tile.size.x)
	var ink := palette.carpet_motif
	if motif == 1:
		# A four-point star: a longer upright stroke and a shorter level one.
		canvas.draw_line(at + Vector2(0, -4), at + Vector2(0, 4), ink, 1.0)
		canvas.draw_line(at + Vector2(-3, 0), at + Vector2(3, 0), ink, 1.0)
		return
	# A crescent moon: an outer arc and an inner one nudged aside.
	var turn := RoomDecor.noise(cell, SALT + 3) * TAU
	canvas.draw_arc(at, 5.0, turn, turn + PI * 1.2, 9, ink, 1.0)
	canvas.draw_arc(at + Vector2.from_angle(turn + PI * 0.6) * 2.0, 3.5, turn + PI * 0.15, turn + PI * 1.05, 7, ink, 1.0)


# A thin teal rail along the top, a dado line lower down and a skirting at the foot. Every other panel
# carries a small star above the dado, the hotline's own sign.
static func draw_wall_tile(canvas: CanvasItem, tile: Rect2, cell: Vector2i, palette: RoomPalette) -> void:
	var p := tile.position
	canvas.draw_rect(Rect2(p, Vector2(tile.size.x, 2)), palette.seance_trim)
	canvas.draw_line(p + Vector2(0, tile.size.y * 0.62), p + Vector2(tile.size.x, tile.size.y * 0.62), palette.brick_line, 1.0)
	if posmod(cell.x + cell.y, 2) == 0:
		var star := p + Vector2(tile.size.x / 2.0, tile.size.y * 0.36)
		canvas.draw_line(star + Vector2(0, -4), star + Vector2(0, 4), Color(palette.seance_trim, 0.7), 1.0)
		canvas.draw_line(star + Vector2(-3, 0), star + Vector2(3, 0), Color(palette.seance_trim, 0.7), 1.0)
	canvas.draw_rect(Rect2(p + Vector2(0, tile.size.y - 2), Vector2(tile.size.x, 2)), Color(palette.seance_trim, 0.5))
