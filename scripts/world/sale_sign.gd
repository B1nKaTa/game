class_name SaleSign
extends BreakableBlock

# A sale sign on a thin stand. It blocks nothing, anything that touches it breaks it, and it never
# holds anything, like grass.


func is_solid() -> bool:
	return false


func body_size() -> Vector2:
	return Vector2(16, 22)


func art_id() -> String:
	return "sale_sign"


func debris_color() -> Color:
	return look().sale_board


func can_break_by(_source: String) -> bool:
	return true


func _draw_placeholder() -> void:
	var p := look()
	draw_line(Vector2(0, 0), Vector2(0, 11), Color("4a4d55"), 2.0)
	draw_line(Vector2(-5, 11), Vector2(5, 11), Color("4a4d55"), 2.0)
	draw_rect(Rect2(-8, -11, 16, 12), p.sale_board)
	draw_rect(Rect2(-8, -11, 16, 12), Color.BLACK, false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(-7, -2), "%", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, p.sale_text)
	draw_line(Vector2(0, -8), Vector2(6, -8), p.sale_text, 2.0)
	draw_line(Vector2(0, -4), Vector2(6, -4), p.sale_text, 1.0)
