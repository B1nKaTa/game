class_name SuitcaseStack
extends BreakableBlock

# Two suitcases stacked on the carpet, waiting for someone. It blocks nothing, anything that touches it
# knocks it over, and it never holds anything, like grass.
const LOWER := Color("8a5a2b")
const UPPER := Color("4a5d8a")
const TAG := Color("fbf7ef")


func is_solid() -> bool:
	return false


func body_size() -> Vector2:
	return Vector2(20, 22)


func art_id() -> String:
	return "suitcase_stack"


func debris_color() -> Color:
	return LOWER


func can_break_by(_source: String) -> bool:
	return true


func _draw_placeholder() -> void:
	draw_rect(Rect2(-10, -1, 20, 11), LOWER)
	draw_rect(Rect2(-10, -1, 20, 11), Color.BLACK, false, 1.0)
	draw_rect(Rect2(-7, -10, 14, 9), UPPER)
	draw_rect(Rect2(-7, -10, 14, 9), Color.BLACK, false, 1.0)
	draw_rect(Rect2(-3, -12, 6, 2), Color.BLACK, false, 1.0)
	draw_rect(Rect2(6, 1, 4, 4), TAG)
	draw_line(Vector2(-10, 4), Vector2(10, 4), LOWER.darkened(0.35), 1.0)
