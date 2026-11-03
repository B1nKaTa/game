class_name CoalHeap
extends RockBlock

# A heap of coal: solid, and only blasts and bosses break it, like a rock. It can hide a coin.


func art_id() -> String:
	return "coal_heap"


func debris_color() -> Color:
	return look().coal


func _draw_placeholder() -> void:
	var p := look()
	var heap := PackedVector2Array([Vector2(-15, 12), Vector2(-11, 0), Vector2(-5, -10), Vector2(2, -13), Vector2(9, -5), Vector2(15, 12)])
	draw_colored_polygon(heap, p.coal)
	draw_polyline(heap + PackedVector2Array([heap[0]]), p.coal_edge, 2.0)
	for at in [Vector2(-6, 2), Vector2(3, -5), Vector2(7, 6), Vector2(-2, 8)]:
		draw_circle(at, 2.0, p.coal_shine)
