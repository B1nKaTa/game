class_name CubicleWall
extends RockBlock

# A length of cubicle partition: a fabric panel in an aluminium frame. Solid, and only blasts and
# bosses break it, like a rock. Runs of them make the office's lanes. It can hide a coin, as furniture
# does: someone's lost change, down the back.
const FABRIC := Color("6f7a8a")
const FABRIC_DARK := Color("5b6573")
const FRAME := Color("c9cdd6")
const FRAME_EDGE := Color("3a3d45")


func art_id() -> String:
	return "cubicle_wall"


func debris_color() -> Color:
	return FABRIC


func _draw_placeholder() -> void:
	draw_rect(Rect2(-16, -12, 32, 26), FABRIC)
	# The weave shows as a few darker flecks, never as stripes, so it is never taken for tape.
	for i in 6:
		draw_rect(Rect2(-12 + (i * 9) % 24, -6 + (i * 5) % 14, 2, 2), FABRIC_DARK)
	draw_rect(Rect2(-16, -15, 32, 4), FRAME)
	draw_rect(Rect2(-16, -15, 32, 29), FRAME_EDGE, false, 1.0)
	draw_line(Vector2(-16, 14), Vector2(16, 14), FRAME_EDGE, 2.0)


# Furniture, so it splinters like wood.
func break_sound() -> String:
	return "wood_break"
