class_name Barrel
extends BreakableBlock

# Blocks walking and shots, but a cane hit, thrown dentures, a bomb or a boss breaks it.


func art_id() -> String:
	return "barrel"


func debris_color() -> Color:
	return look().barrel


func can_break_by(_source: String) -> bool:
	return true


func _draw_placeholder() -> void:
	var p := look()
	var body := Rect2(-12, -14, 24, 28)
	draw_rect(body, p.barrel)
	draw_rect(body, Color.BLACK, false, 1.0)
	for y in [-8.0, 6.0]:
		draw_rect(Rect2(-12, y, 24, 3), p.barrel_band)
	draw_line(Vector2(-4, -14), Vector2(-4, 14), p.barrel.darkened(0.3), 1.0)
	draw_line(Vector2(4, -14), Vector2(4, 14), p.barrel.darkened(0.3), 1.0)
