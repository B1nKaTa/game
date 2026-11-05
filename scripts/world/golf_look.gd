class_name GolfLook
extends RefCounted

# How Fairway's End's floor and walls are drawn, called from RoomBackdrop for a palette that asks for
# them. The fairway is mown in broad stripes, two cells wide, a lighter band beside a darker one, and
# nothing else: no dots, speckles or grout, which are the sand's own look, so a bunker never reads as
# floor and the floor never reads as sand. The walls are hedges of yew, overgrown at midnight.
#
# The numbers stand well past the shared patterns' 1 to 3, so paths built at the same time never pick
# the same one.
const FAIRWAY := 13
const HEDGE_WALL := 13
const STRIPE_CELLS := 2


static func is_light_stripe(cell: Vector2i) -> bool:
	return posmod(cell.x, STRIPE_CELLS * 2) < STRIPE_CELLS


static func draw_floor_tile(canvas: CanvasItem, tile: Rect2, cell: Vector2i, palette: RoomPalette) -> void:
	if is_light_stripe(cell):
		canvas.draw_rect(tile, palette.fairway_stripe)


# Dark clumps of leaves over the wall colour, and a lighter top along the cell, gone ragged: every
# third cell a stray shoot straggles down from it.
static func draw_wall_tile(canvas: CanvasItem, tile: Rect2, cell: Vector2i, palette: RoomPalette) -> void:
	var lift := 3.0 if posmod(cell.x + cell.y, 2) == 0 else 0.0
	for i in 3:
		var at := tile.position + Vector2(6.0 + i * 10.0, 11.0 + float(i % 2) * 9.0 - lift)
		canvas.draw_circle(at, 6.0, palette.brick_line)
	canvas.draw_rect(Rect2(tile.position, Vector2(tile.size.x, 3.0)), palette.carpet_motif)
	if posmod(cell.x * 2 + cell.y, 3) == 0:
		var root := tile.position + Vector2(8.0 + float(posmod(cell.x, 2)) * 14.0, 3.0)
		canvas.draw_line(root, root + Vector2(3.0, 6.0), palette.carpet_motif, 2.0)
