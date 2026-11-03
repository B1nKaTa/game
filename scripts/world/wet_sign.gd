class_name WetSign
extends BreakableBlock

# The yellow "Caution: Wet" stand beside a mopped patch. It blocks nothing, and any hit knocks it
# over for good. It never holds anything.


func is_solid() -> bool:
	return false


func body_size() -> Vector2:
	return Vector2(14, 20)


func art_id() -> String:
	return "wet_sign"


func debris_color() -> Color:
	return look().caution


func can_break_by(_source: String) -> bool:
	return true


func _draw_placeholder() -> void:
	var p := look()
	var stand := PackedVector2Array([Vector2(-7, 10), Vector2(-2, -11), Vector2(2, -11), Vector2(7, 10)])
	draw_colored_polygon(stand, p.caution)
	draw_polyline(stand + PackedVector2Array([stand[0]]), Color.BLACK, 1.0)
	draw_line(Vector2(-4, -2), Vector2(4, -2), Color.BLACK, 1.0)
	draw_line(Vector2(0, -7), Vector2(0, -3), Color.BLACK, 2.0)
	draw_rect(Rect2(-1, 0, 2, 2), Color.BLACK)
