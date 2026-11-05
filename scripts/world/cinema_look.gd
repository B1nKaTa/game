class_name CinemaLook
extends RefCounted

# How the Flashback Cinema's floor and walls are drawn, called from RoomBackdrop for a palette that asks
# for them. The carpet is a deep teal with a faint art-deco fan in its pile, and two carpet runners
# cross the room through the four doors, lighter than the carpet and edged in thin gold lines. The
# walls are dark panels with gold trim, fluted, with a small gold chevron on every other panel.
#
# Shapes kept off the carpet on purpose: no dots, small squares or holes (a Runaway Film Reel lays a dark
# strip with sprocket holes), no bright diagonal streaks (a wet floor's look) and no dark bands (the film
# strip again). The runners are lighter than the carpet, never darker, and the fans are only thin arcs.
#
# The numbers stand well past the shared patterns' 1 to 3 and the other paths' 10, 12 and 13.
const CARPET := 14
const DECO_WALL := 14
# The fans repeat every two cells, turned a quarter each time, so the pile never reads as a grid.
const FAN_CELLS := 2
const FAN_ARCS := 3
# How far in from a runner's sides its gold edging runs, in pixels.
const RUNNER_EDGE := 3.0


# The runners lie along the column and the row of the doors, so they always lead from door to door.
static func is_runner(cell: Vector2i, room_cells: Vector2i) -> bool:
	return cell.x == room_cells.x / 2 or cell.y == room_cells.y / 2


static func draw_floor_tile(canvas: CanvasItem, tile: Rect2, cell: Vector2i, room_cells: Vector2i, palette: RoomPalette) -> void:
	var down := cell.x == room_cells.x / 2
	var across := cell.y == room_cells.y / 2
	if down or across:
		canvas.draw_rect(tile, palette.carpet_runner)
		var edge := palette.deco_gold_dim
		if down and not across:
			canvas.draw_line(tile.position + Vector2(RUNNER_EDGE, 0), tile.position + Vector2(RUNNER_EDGE, tile.size.y), edge, 1.0)
			canvas.draw_line(tile.position + Vector2(tile.size.x - RUNNER_EDGE, 0), tile.position + Vector2(tile.size.x - RUNNER_EDGE, tile.size.y), edge, 1.0)
		elif across and not down:
			canvas.draw_line(tile.position + Vector2(0, RUNNER_EDGE), tile.position + Vector2(tile.size.x, RUNNER_EDGE), edge, 1.0)
			canvas.draw_line(tile.position + Vector2(0, tile.size.y - RUNNER_EDGE), tile.position + Vector2(tile.size.x, tile.size.y - RUNNER_EDGE), edge, 1.0)
		else:
			canvas.draw_rect(tile.grow(-RUNNER_EDGE), edge, false, 1.0)
		return
	if posmod(cell.x, FAN_CELLS) != 0 or posmod(cell.y, FAN_CELLS) != 0:
		return
	# A fan of thin arcs opening from one corner of the cell, the corner turning with the cell.
	var turn := posmod(cell.x / FAN_CELLS + cell.y / FAN_CELLS, 4)
	var corners := [Vector2(0, tile.size.y), Vector2(tile.size.x, tile.size.y), Vector2(tile.size.x, 0), Vector2.ZERO]
	var starts := [-PI / 2.0, -PI, PI / 2.0, 0.0]
	var corner: Vector2 = tile.position + corners[turn]
	var start: float = starts[turn]
	for arc in FAN_ARCS:
		var radius := 9.0 + arc * 8.0
		canvas.draw_arc(corner, radius, start, start + PI / 2.0, 10, palette.carpet_motif, 1.0)


# A gold rail along the top, fluting down the panel, and a gold skirting at the foot. Every other panel
# carries a small gold chevron, the picture house's own sign.
static func draw_wall_tile(canvas: CanvasItem, tile: Rect2, cell: Vector2i, palette: RoomPalette) -> void:
	var p := tile.position
	canvas.draw_rect(Rect2(p, Vector2(tile.size.x, 2)), palette.deco_gold)
	canvas.draw_line(p + Vector2(0, 5), p + Vector2(tile.size.x, 5), palette.deco_gold_dim, 1.0)
	for flute in [8.0, 16.0, 24.0]:
		canvas.draw_line(p + Vector2(flute, 9), p + Vector2(flute, 26), palette.brick_line, 1.0)
	if posmod(cell.x + cell.y, 2) == 0:
		canvas.draw_polyline(PackedVector2Array([p + Vector2(11, 25), p + Vector2(16, 20), p + Vector2(21, 25)]), palette.deco_gold_dim, 1.0)
	canvas.draw_rect(Rect2(p + Vector2(0, tile.size.y - 2), Vector2(tile.size.x, 2)), palette.deco_gold_dim)
