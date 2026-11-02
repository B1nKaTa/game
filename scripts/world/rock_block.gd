class_name RockBlock
extends BreakableBlock

# Blocks walking and shots. Bombs and bosses break it, the cane does not.
var hides_coin := false


func art_id() -> String:
	return "rock"


func debris_color() -> Color:
	return look().rock


func _draw_placeholder() -> void:
	var p := look()
	var pts := PackedVector2Array([Vector2(-14, 8), Vector2(-15, -3), Vector2(-8, -13), Vector2(5, -14), Vector2(14, -5), Vector2(15, 9), Vector2(6, 14), Vector2(-8, 14)])
	draw_colored_polygon(pts, p.rock)
	draw_polyline(pts + PackedVector2Array([pts[0]]), p.rock_edge, 2.0)
	draw_line(Vector2(-6, -6), Vector2(2, 0), p.rock_edge, 1.0)
	draw_line(Vector2(2, 0), Vector2(0, 8), p.rock_edge, 1.0)
	draw_line(Vector2(-9, -9), Vector2(-3, -11), p.rock.lightened(0.25), 2.0)
