class_name FlowerVase
extends BreakableBlock

# A vase of flowers on the floor. It blocks nothing, anything that touches it breaks it, and it
# never holds anything, like grass.


func is_solid() -> bool:
	return false


func body_size() -> Vector2:
	return Vector2(14, 20)


func art_id() -> String:
	return "flower_vase"


func debris_color() -> Color:
	return look().vase_flower


func can_break_by(_source: String) -> bool:
	return true


func _draw_placeholder() -> void:
	var p := look()
	for stem in [Vector2(-4, -9), Vector2(0, -12), Vector2(4, -9)]:
		draw_line(Vector2(0, -2), stem, p.vase_leaf, 1.0)
		draw_circle(stem, 2.5, p.vase_flower)
	var body := PackedVector2Array([Vector2(-4, -2), Vector2(4, -2), Vector2(6, 6), Vector2(3, 10), Vector2(-3, 10), Vector2(-6, 6)])
	draw_colored_polygon(body, p.vase)
	draw_polyline(body + PackedVector2Array([body[0]]), Color.BLACK, 1.0)
