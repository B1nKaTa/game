class_name BonePile
extends BreakableBlock

# A small heap that blocks nothing. Anything that touches it scatters it.


func is_solid() -> bool:
	return false


func body_size() -> Vector2:
	return Vector2(22, 16)


func art_id() -> String:
	return "bone_pile"


func debris_color() -> Color:
	return look().bones


func can_break_by(_source: String) -> bool:
	return true


func _draw_placeholder() -> void:
	var c := look().bones
	draw_circle(Vector2(0, -3), 5.0, c)
	draw_rect(Rect2(-2, -1, 1, 1), Color.BLACK)
	draw_rect(Rect2(1, -1, 1, 1), Color.BLACK)
	draw_line(Vector2(-10, 5), Vector2(4, 1), c, 3.0)
	draw_line(Vector2(-4, 7), Vector2(10, 4), c, 3.0)
	draw_line(Vector2(5, -6), Vector2(11, -1), c, 2.0)
