class_name SecretWall
extends BreakableBlock

const CRACK_COLOR := Color(0.0, 0.0, 0.0, 0.55)


# The crack is the only hint, so it stays faint. A blast opens it through take_blast.
func _draw() -> void:
	draw_line(Vector2(-3, -14), Vector2(1, -6), CRACK_COLOR, 1.0)
	draw_line(Vector2(1, -6), Vector2(-4, 1), CRACK_COLOR, 1.0)
	draw_line(Vector2(-4, 1), Vector2(2, 8), CRACK_COLOR, 1.0)
	draw_line(Vector2(2, 8), Vector2(0, 15), CRACK_COLOR, 1.0)
	draw_line(Vector2(1, -6), Vector2(7, -3), CRACK_COLOR, 1.0)
	draw_line(Vector2(-4, 1), Vector2(-9, 4), CRACK_COLOR, 1.0)
