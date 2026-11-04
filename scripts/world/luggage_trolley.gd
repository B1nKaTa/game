class_name LuggageTrolley
extends Barrel

# A luggage trolley piled with cases. Breaks to anything, like a barrel, and holds what a barrel holds.
const FRAME := Color("9aa0a8")
const FRAME_EDGE := Color("3c4048")
const CASES: Array[Color] = [Color("4a5d8a"), Color("7a2f3a"), Color("3f6b34")]


func art_id() -> String:
	return "luggage_trolley"


func debris_color() -> Color:
	return CASES[0]


func _draw_placeholder() -> void:
	draw_rect(Rect2(-12, 6, 24, 4), FRAME)
	draw_rect(Rect2(-12, 6, 24, 4), FRAME_EDGE, false, 1.0)
	draw_line(Vector2(-12, 8), Vector2(-14, -12), FRAME, 2.0)
	draw_line(Vector2(-16, -12), Vector2(-11, -12), FRAME_EDGE, 2.0)
	draw_rect(Rect2(-9, -4, 20, 10), CASES[0])
	draw_rect(Rect2(-7, -12, 15, 8), CASES[1])
	draw_rect(Rect2(-9, -4, 20, 10), Color.BLACK, false, 1.0)
	draw_rect(Rect2(-7, -12, 15, 8), Color.BLACK, false, 1.0)
	draw_rect(Rect2(-1, -14, 4, 2), CASES[2])
	for x in [-8.0, 8.0]:
		draw_circle(Vector2(x, 12), 2.5, Color("2a2420"))
