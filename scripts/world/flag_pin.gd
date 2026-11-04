class_name FlagPin
extends BreakableBlock

# A flag pin standing in its cup on the green. It blocks nothing, anything that touches it breaks it,
# and it never holds anything, like grass.


func is_solid() -> bool:
	return false


func body_size() -> Vector2:
	return Vector2(14, 26)


func art_id() -> String:
	return "flag_pin"


func debris_color() -> Color:
	return look().flag_cloth


func can_break_by(_source: String) -> bool:
	return true


func _draw_placeholder() -> void:
	var p := look()
	draw_set_transform(Vector2(0, 11), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 5.0, Color("15131a"))
	draw_set_transform(Vector2.ZERO)
	draw_line(Vector2(0, 11), Vector2(0, -13), p.flag_pole, 2.0)
	var cloth := PackedVector2Array([Vector2(1, -13), Vector2(11, -9), Vector2(1, -5)])
	draw_colored_polygon(cloth, p.flag_cloth)
	draw_polyline(cloth + PackedVector2Array([cloth[0]]), Color.BLACK, 1.0)
