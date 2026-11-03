class_name PipeValve
extends BreakableBlock

# A short stub of pipe with a valve wheel, standing on the floor. It blocks nothing, anything that
# touches it breaks it, and it never holds anything, like grass.


func is_solid() -> bool:
	return false


func body_size() -> Vector2:
	return Vector2(14, 20)


func art_id() -> String:
	return "pipe_valve"


func debris_color() -> Color:
	return look().pipe


func can_break_by(_source: String) -> bool:
	return true


func _draw_placeholder() -> void:
	var p := look()
	draw_rect(Rect2(-3, -4, 6, 14), p.pipe)
	draw_rect(Rect2(-6, 8, 12, 3), p.pipe.darkened(0.3))
	draw_line(Vector2(0, -4), Vector2(0, -8), p.pipe, 2.0)
	draw_arc(Vector2(0, -10), 5.0, 0.0, TAU, 12, p.valve_wheel, 2.0)
	draw_line(Vector2(-5, -10), Vector2(5, -10), p.valve_wheel, 1.0)
