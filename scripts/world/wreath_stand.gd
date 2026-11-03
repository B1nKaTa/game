class_name WreathStand
extends BreakableBlock

# A funeral wreath on a thin easel. It blocks nothing, anything that touches it breaks it, and it
# never holds anything, like grass.


func is_solid() -> bool:
	return false


func body_size() -> Vector2:
	return Vector2(18, 22)


func art_id() -> String:
	return "wreath_stand"


func debris_color() -> Color:
	return look().wreath_leaf


func can_break_by(_source: String) -> bool:
	return true


func _draw_placeholder() -> void:
	var p := look()
	draw_line(Vector2(-5, 11), Vector2(0, -2), p.pew_edge, 1.0)
	draw_line(Vector2(5, 11), Vector2(0, -2), p.pew_edge, 1.0)
	draw_arc(Vector2(0, -4), 7.0, 0.0, TAU, 16, p.wreath_leaf, 4.0)
	for i in 5:
		draw_circle(Vector2(0, -4) + Vector2.from_angle(TAU * i / 5.0 - 0.6) * 7.0, 1.8, p.wreath_bloom)
	draw_line(Vector2(-3, 3), Vector2(3, 3), Color("7a2f3a"), 2.0)
