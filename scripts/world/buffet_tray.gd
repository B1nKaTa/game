class_name BuffetTray
extends BreakableBlock

# A buffet tray on a little folding stand, piled with something from the midnight buffet. It blocks
# nothing, anything that touches it breaks it, and it never holds anything, like grass.
const STAND := Color("c9cdd6")
const TRAY := Color("e8ebf0")
const TRAY_EDGE := Color("5a6070")
const FOOD: Array[Color] = [Color("e8a33c"), Color("d9576b"), Color("8fc46a")]


func is_solid() -> bool:
	return false


func body_size() -> Vector2:
	return Vector2(22, 18)


func art_id() -> String:
	return "buffet_tray"


func debris_color() -> Color:
	return FOOD[0]


func can_break_by(_source: String) -> bool:
	return true


func _draw_placeholder() -> void:
	draw_line(Vector2(-7, 9), Vector2(5, -1), STAND, 1.0)
	draw_line(Vector2(7, 9), Vector2(-5, -1), STAND, 1.0)
	draw_rect(Rect2(-11, -4, 22, 6), TRAY)
	draw_rect(Rect2(-11, -4, 22, 6), TRAY_EDGE, false, 1.0)
	for i in FOOD.size():
		draw_circle(Vector2(-6 + i * 6, -5), 2.5, FOOD[i])
