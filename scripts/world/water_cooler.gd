class_name WaterCooler
extends Barrel

# An office water cooler, a blue bottle upside down on a white stand. Breaks to anything, like a
# barrel, and holds what a barrel holds.
const BOTTLE := Color(0.45, 0.72, 0.95, 0.85)
const STAND := Color("e8e4da")
const TAP := Color("d9453b")


func art_id() -> String:
	return "water_cooler"


func debris_color() -> Color:
	return BOTTLE


func _draw_placeholder() -> void:
	draw_rect(Rect2(-9, -2, 18, 16), STAND)
	draw_rect(Rect2(-9, -2, 18, 16), Color.BLACK, false, 1.0)
	draw_rect(Rect2(-7, -15, 14, 13), BOTTLE)
	draw_rect(Rect2(-7, -15, 14, 13), Color("2a4a6a"), false, 1.0)
	draw_line(Vector2(-4, -12), Vector2(-4, -5), Color(1, 1, 1, 0.6), 2.0)
	draw_rect(Rect2(-3, 3, 2, 3), TAP)
	draw_rect(Rect2(2, 3, 2, 3), Color("3b7dd8"))
