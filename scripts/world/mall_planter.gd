class_name MallPlanter
extends RockBlock

# A concrete planter with a potted palm: solid, and only blasts and bosses break it, like a rock.
# Planters stand in rows along the walkways. It can hide a coin, as furniture does.


func art_id() -> String:
	return "mall_planter"


func debris_color() -> Color:
	return look().planter


func _draw_placeholder() -> void:
	var p := look()
	draw_rect(Rect2(-15, -2, 30, 15), p.planter)
	draw_rect(Rect2(-15, -2, 30, 15), p.planter_edge, false, 1.0)
	draw_rect(Rect2(-15, -2, 30, 3), p.planter.lightened(0.2))
	draw_line(Vector2(0, -1), Vector2(1, -9), Color("6b4a2a"), 3.0)
	for leaf in [Vector2(-12, -10), Vector2(-6, -15), Vector2(4, -16), Vector2(11, -11), Vector2(13, -5), Vector2(-13, -4)]:
		draw_line(Vector2(1, -10), leaf, p.palm_leaf, 3.0)
		draw_line(Vector2(1, -10), leaf, p.palm_leaf.lightened(0.25), 1.0)
