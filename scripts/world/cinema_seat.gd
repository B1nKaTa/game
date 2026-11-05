class_name CinemaSeat
extends RockBlock

# One cell of a row of plum velvet seats, two seats side by side facing the screen to the north. A row
# is cover: solid, it stops walkers and shots alike, and only blasts and bosses break it, as a chapel
# pew does. It can hide a coin at the furniture rate: something dropped down the back of a seat.
# A seat beside another one joins it, so a run of cells reads as one long row.
var joins_west := false
var joins_east := false


func art_id() -> String:
	return "cinema_seat"


func debris_color() -> Color:
	return look().seat_velvet


func _draw_placeholder() -> void:
	var p := look()
	var left := -16.0 if joins_west else -14.0
	var right := 16.0 if joins_east else 14.0
	# The row's dark frame under the seats, and the high backs along its south edge.
	draw_rect(Rect2(left, -11, right - left, 24), p.seat_velvet_dark)
	for seat in 2:
		var x := -14.0 + seat * 15.0
		draw_rect(Rect2(x + 1, -9, 12, 12), p.seat_velvet)
		draw_rect(Rect2(x + 1, -9, 12, 3), p.seat_velvet.lightened(0.18))
		draw_rect(Rect2(x, 4, 14, 7), p.seat_velvet.darkened(0.15))
		draw_line(Vector2(x, 4), Vector2(x + 14, 4), p.deco_gold_dim, 1.0)
	# Armrests between and at the ends, picked out in gold.
	for arm in [-15.0, 0.0, 15.0]:
		if (arm < 0.0 and joins_west) or (arm > 0.0 and joins_east):
			continue
		draw_rect(Rect2(arm - 1, -10, 2, 20), p.deco_gold)
	draw_line(Vector2(left, 12), Vector2(right, 12), Color.BLACK, 1.0)
	if not joins_west:
		draw_line(Vector2(left, -11), Vector2(left, 12), Color.BLACK, 1.0)
	if not joins_east:
		draw_line(Vector2(right, -11), Vector2(right, 12), Color.BLACK, 1.0)


# Velvet over a wooden frame, so it splinters like furniture.
func break_sound() -> String:
	return "wood_break"
