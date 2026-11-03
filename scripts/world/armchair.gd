class_name Armchair
extends RockBlock

# A heavy armchair: solid, and only blasts and bosses break it, like a rock. It can hide a coin.


func art_id() -> String:
	return "armchair"


func debris_color() -> Color:
	return look().armchair


func _draw_placeholder() -> void:
	var p := look()
	draw_rect(Rect2(-13, -13, 26, 10), p.armchair)
	draw_rect(Rect2(-14, -5, 6, 18), p.armchair)
	draw_rect(Rect2(8, -5, 6, 18), p.armchair)
	draw_rect(Rect2(-8, -3, 16, 14), p.armchair.lightened(0.15))
	for r in [Rect2(-13, -13, 26, 10), Rect2(-14, -5, 6, 18), Rect2(8, -5, 6, 18)]:
		draw_rect(r, p.armchair_edge, false, 1.0)
