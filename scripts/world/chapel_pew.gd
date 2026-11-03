class_name ChapelPew
extends RockBlock

# A heavy wooden pew: solid, and only blasts and bosses break it, like a rock. Pews stand in rows,
# which makes lanes. It can hide a coin, as furniture does.


func art_id() -> String:
	return "chapel_pew"


func debris_color() -> Color:
	return look().pew


func _draw_placeholder() -> void:
	var p := look()
	# The seat and its high back, seen from above and a little in front.
	draw_rect(Rect2(-15, -12, 30, 7), p.pew.darkened(0.15))
	draw_rect(Rect2(-15, -5, 30, 13), p.pew)
	draw_rect(Rect2(-15, 8, 3, 5), p.pew_edge)
	draw_rect(Rect2(12, 8, 3, 5), p.pew_edge)
	draw_rect(Rect2(-15, -12, 30, 20), p.pew_edge, false, 1.0)
	draw_line(Vector2(-14, -5), Vector2(14, -5), p.pew_edge, 1.0)
	draw_line(Vector2(-13, -10), Vector2(13, -10), p.pew.lightened(0.2), 1.0)
