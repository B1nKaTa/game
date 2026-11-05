class_name Hedge
extends RockBlock

# A box hedge of yew, dark and long past its last clipping. Solid, and only blasts and bosses break it,
# like a rock. Runs of them make the course's hedgerows. It can hide a coin, as furniture does: a lost ball's worth, under the leaves.


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
	# Overgrown: stray shoots poke up out of the top and the sides.
	for shoot: Array in [[Vector2(-11, -14), Vector2(-13, -19)], [Vector2(-2, -14), Vector2(0, -20)], [Vector2(8, -14), Vector2(11, -18)], [Vector2(16, 2), Vector2(19, 0)], [Vector2(-16, 6), Vector2(-19, 4)]]:
		draw_line(shoot[0], shoot[1], p.hedge_leaf.lightened(0.2), 2.0)


# Leaves, not stone.
func break_sound() -> String:
	return "grass_cut"
