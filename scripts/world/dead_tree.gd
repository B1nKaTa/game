class_name DeadTree
extends RockBlock

# A bare trunk that blocks walking and shots. It breaks like a rock, and never holds anything.


func art_id() -> String:
	return "dead_tree"


func debris_color() -> Color:
	return look().dead_tree


func _draw_placeholder() -> void:
	var p := look()
	var trunk := PackedVector2Array([Vector2(-7, 14), Vector2(-4, -6), Vector2(4, -6), Vector2(7, 14)])
	draw_colored_polygon(trunk, p.dead_tree)
	draw_polyline(trunk + PackedVector2Array([trunk[0]]), p.dead_tree_edge, 2.0)
	for branch: PackedVector2Array in [
		PackedVector2Array([Vector2(-2, -6), Vector2(-9, -16), Vector2(-16, -19)]),
		PackedVector2Array([Vector2(-6, -11), Vector2(-5, -23)]),
		PackedVector2Array([Vector2(2, -6), Vector2(8, -18), Vector2(16, -22)]),
		PackedVector2Array([Vector2(5, -12), Vector2(13, -11)]),
		PackedVector2Array([Vector2(0, -6), Vector2(1, -26)]),
	]:
		draw_polyline(branch, p.dead_tree, 3.0)
