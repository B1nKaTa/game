class_name MallFountain
extends RockBlock

# A piece of the mall's fountain: a stone basin of rippling water. Solid, and only blasts and bosses
# break it, like a rock. A run of them makes one fountain. It can hide a coin, as furniture does:
# someone's wish, at the bottom.
var _time := 0.0


func art_id() -> String:
	return "mall_fountain"


func debris_color() -> Color:
	return look().fountain_water


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw_placeholder() -> void:
	var p := look()
	draw_rect(Rect2(-16, -12, 32, 26), p.fountain_stone)
	draw_rect(Rect2(-13, -9, 26, 20), p.fountain_water)
	draw_rect(Rect2(-16, -12, 32, 26), Color.BLACK, false, 1.0)
	for i in 3:
		var ripple := fposmod(_time * 0.8 + i / 3.0, 1.0)
		draw_arc(Vector2(0, 1), 3.0 + ripple * 9.0, 0.0, TAU, 16, Color(1, 1, 1, 0.5 * (1.0 - ripple)), 1.0)
	draw_line(Vector2(0, 1), Vector2(0, -6), Color(1, 1, 1, 0.7), 2.0)
	draw_circle(Vector2(0, -7), 2.0, Color(1, 1, 1, 0.6))
