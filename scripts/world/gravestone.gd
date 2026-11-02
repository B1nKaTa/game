class_name Gravestone
extends RockBlock

# Blocks walking and shots like a rock, and hides a coin as often, but reads as a grave.


func art_id() -> String:
	return "gravestone"


func debris_color() -> Color:
	return look().gravestone


func _draw_placeholder() -> void:
	var p := look()
	var pts := PackedVector2Array([Vector2(-10, 14), Vector2(-10, -6), Vector2(-6, -12), Vector2(6, -12), Vector2(10, -6), Vector2(10, 14)])
	draw_colored_polygon(pts, p.gravestone)
	draw_polyline(pts + PackedVector2Array([pts[0]]), p.gravestone_edge, 2.0)
	draw_line(Vector2(0, -7), Vector2(0, 3), p.gravestone_edge, 2.0)
	draw_line(Vector2(-4, -3), Vector2(4, -3), p.gravestone_edge, 2.0)
	draw_rect(Rect2(-10, 9, 20, 5), p.gravestone_moss)
