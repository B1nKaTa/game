class_name CinemaSeat
extends RockBlock

# One plum velvet cinema seat, a whole cell, seen from behind as the rows face the screen to the north:
# a chunky seat back sized beside Harold, gold-trimmed, with brass armrests. A run of seat cells is a
# row of seats. A seat is cover: solid, it stops walkers and shots alike, and only blasts and bosses
# break it, as a chapel pew does. It can hide a coin at the furniture rate: something dropped down the
# back of a seat.
# The picture's size (art/props/flashback_cinema/seat_row.png, built by tools/art/area_props.py): one
# seat filling its cell's height, a little narrower than the cell so neighbours' armrests nearly meet.
const ART_SIZE := Vector2i(28, 32)
var joins_west := false
var joins_east := false


# The Cinema's own picture (art/props/flashback_cinema/seat_row.png), one seat per cell.
func art_id() -> String:
	return "seat_row"


func debris_color() -> Color:
	return look().seat_velvet


func _draw_placeholder() -> void:
	var p := look()
	# Brass armrests either side, then the tall rounded velvet back with its gold trim.
	for arm in [-13.0, 11.0]:
		draw_rect(Rect2(arm, -2, 2, 12), p.deco_gold)
		draw_rect(Rect2(arm, 10, 2, 5), p.seat_velvet_dark)
	draw_rect(Rect2(-11, -15, 22, 28), p.seat_velvet_dark)
	draw_rect(Rect2(-10, -14, 20, 24), p.seat_velvet)
	draw_rect(Rect2(-10, -14, 20, 3), p.seat_velvet.lightened(0.18))
	draw_line(Vector2(-10, -15), Vector2(10, -15), p.deco_gold_dim, 1.0)
	draw_rect(Rect2(-11, -15, 22, 28), Color.BLACK, false, 1.0)


# Velvet over a wooden frame, so it splinters like furniture.
func break_sound() -> String:
	return "wood_break"
