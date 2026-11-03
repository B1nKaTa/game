class_name CoalSack
extends Barrel

# A sack of coal. Breaks to anything, like a barrel, and holds what a barrel holds.


func art_id() -> String:
	return "coal_sack"


func debris_color() -> Color:
	return look().coal


func _draw_placeholder() -> void:
	var p := look()
	var body := PackedVector2Array([Vector2(-11, 13), Vector2(-13, 2), Vector2(-9, -9), Vector2(-4, -13), Vector2(4, -13), Vector2(9, -9), Vector2(13, 2), Vector2(11, 13)])
	draw_colored_polygon(body, p.sack)
	draw_polyline(body + PackedVector2Array([body[0]]), Color.BLACK, 1.0)
	draw_line(Vector2(-5, -10), Vector2(5, -10), p.sack.darkened(0.4), 2.0)
	for at in [Vector2(-3, -14), Vector2(2, -15), Vector2(5, -13)]:
		draw_circle(at, 2.0, p.coal)
