class_name Hedge
extends RockBlock

# A clipped box hedge. Solid, and only blasts and bosses break it, like a rock. Runs of them make the
# course's hedgerows. It can hide a coin, as furniture does: a lost ball's worth, under the leaves.


func art_id() -> String:
	return "hedge"


func debris_color() -> Color:
	# The dark of its own outline: its leaf green vanished on the grass.
	return look().hedge.darkened(0.45)


func _draw_placeholder() -> void:
	var p := look()
	draw_rect(Rect2(-16, -14, 32, 28), p.hedge)
	for at in [Vector2(-9, -6), Vector2(1, -8), Vector2(10, -5), Vector2(-5, 4), Vector2(7, 5)]:
		draw_circle(at, 6.0, p.hedge_leaf)
	draw_rect(Rect2(-16, -14, 32, 3), p.hedge_leaf.lightened(0.2))
	draw_rect(Rect2(-16, -14, 32, 28), p.hedge.darkened(0.45), false, 1.0)
