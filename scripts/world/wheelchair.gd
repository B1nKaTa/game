class_name Wheelchair
extends Barrel

# Breaks to anything, like a barrel, and holds what a barrel holds. It reads as an empty wheelchair.


func art_id() -> String:
	return "wheelchair"


func debris_color() -> Color:
	return look().wheelchair


func _draw_placeholder() -> void:
	var p := look()
	draw_rect(Rect2(-9, -12, 14, 12), p.wheelchair_seat)
	draw_rect(Rect2(-9, -12, 14, 12), Color.BLACK, false, 1.0)
	draw_rect(Rect2(-9, -1, 16, 4), p.wheelchair_seat)
	draw_arc(Vector2(-2, 8), 7.0, 0.0, TAU, 16, p.wheelchair, 2.0)
	draw_line(Vector2(-2, 1), Vector2(-2, 15), p.wheelchair, 1.0)
	draw_circle(Vector2(10, 12), 2.5, p.wheelchair)
	draw_line(Vector2(5, -12), Vector2(10, -14), p.wheelchair, 2.0)
