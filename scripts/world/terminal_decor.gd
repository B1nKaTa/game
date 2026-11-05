class_name TerminalDecor
extends RefCounted

# The placeholder look of Departures, Terminal Zero's own decor. DecorLayer calls this after its own
# kinds, so the shared file only gains one line. A picture at res://art/props/decor_<kind>.png still
# replaces it, as for every kind.
const BOARD := Color("15131a")
const BOARD_EDGE := Color("5a5f6a")
const FLIGHT := Color("f2b134")
const DELAYED := Color("e4524f")
const STAND := Color("3c4048")


static func draw_placeholder(canvas: CanvasItem, kind: String, variant: int, _palette: RoomPalette) -> void:
	if kind != RoomDecor.DEPARTURE_BOARD:
		return
	# A black board on two legs, with rows of amber flight times and now and then one in red.
	canvas.draw_line(Vector2(-8, 4), Vector2(-8, 11), STAND, 2.0)
	canvas.draw_line(Vector2(8, 4), Vector2(8, 11), STAND, 2.0)
	canvas.draw_rect(Rect2(-13, -11, 26, 16), BOARD)
	canvas.draw_rect(Rect2(-13, -11, 26, 16), BOARD_EDGE, false, 1.0)
	for row in 4:
		var color := DELAYED if row == variant % 4 and variant % 2 == 1 else FLIGHT
		canvas.draw_line(Vector2(-11, -8 + row * 3.5), Vector2(-2, -8 + row * 3.5), color, 1.0)
		canvas.draw_line(Vector2(1, -8 + row * 3.5), Vector2(4, -8 + row * 3.5), color, 1.0)
		canvas.draw_line(Vector2(6, -8 + row * 3.5), Vector2(11, -8 + row * 3.5), color, 1.0)
