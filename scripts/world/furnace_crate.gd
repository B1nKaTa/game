class_name FurnaceCrate
extends Barrel

# A wooden crate of spare parts. Breaks to anything, like a barrel, and holds what a barrel holds.


func art_id() -> String:
	return "furnace_crate"


func debris_color() -> Color:
	return look().crate


func _draw_placeholder() -> void:
	var p := look()
	var body := Rect2(-12, -12, 24, 24)
	draw_rect(body, p.crate)
	draw_rect(body, Color.BLACK, false, 1.0)
	draw_rect(Rect2(-10, -10, 20, 20), p.crate_edge, false, 1.0)
	draw_line(Vector2(-10, -10), Vector2(10, 10), p.crate_edge, 2.0)
	draw_line(Vector2(-10, 10), Vector2(10, -10), p.crate_edge, 1.0)
