class_name CareBed
extends RockBlock

# A care home bed: solid, and only blasts and bosses break it, like a rock. It can hide a coin.


func art_id() -> String:
	return "care_bed"


func debris_color() -> Color:
	return look().bed_sheet


func _draw_placeholder() -> void:
	var p := look()
	draw_rect(Rect2(-11, -15, 22, 30), p.bed)
	draw_rect(Rect2(-9, -9, 18, 22), p.bed_sheet)
	draw_rect(Rect2(-8, -13, 16, 5), Color.WHITE.darkened(0.05))
	draw_line(Vector2(-9, 0), Vector2(9, 0), p.bed_sheet.darkened(0.2), 1.0)
	draw_rect(Rect2(-11, -15, 22, 30), Color.BLACK, false, 1.0)
