class_name DepartureSeats
extends RockBlock

# A row of joined departure lounge seats on a steel beam: solid, and only blasts and bosses break it,
# like a rock. Seats stand in rows, which makes lanes. It can hide a coin, as furniture does.
const BEAM := Color("5a5f6a")
const BEAM_EDGE := Color("23252b")
const CUSHION := Color("3b5a8a")
const CUSHION_LIGHT := Color("5a7db5")


func art_id() -> String:
	return "departure_seats"


func debris_color() -> Color:
	return CUSHION


func _draw_placeholder() -> void:
	# Three seats seen from above and a little in front, their backs along the top.
	draw_rect(Rect2(-15, 6, 30, 3), BEAM)
	for i in 3:
		var left := -15.0 + i * 10.0
		draw_rect(Rect2(left + 0.5, -11, 9, 6), CUSHION.darkened(0.2))
		draw_rect(Rect2(left + 0.5, -5, 9, 10), CUSHION)
		draw_line(Vector2(left + 2, -3), Vector2(left + 8, -3), CUSHION_LIGHT, 1.0)
		draw_rect(Rect2(left + 0.5, -11, 9, 16), BEAM_EDGE, false, 1.0)
	for x in [-13.0, 12.0]:
		draw_rect(Rect2(x, 9, 2, 4), BEAM_EDGE)


# Furniture, so it splinters like wood.
func break_sound() -> String:
	return "wood_break"
