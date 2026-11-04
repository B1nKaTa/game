class_name InTray
extends BreakableBlock

# A desk in-tray stacked with forms on a little stand. It blocks nothing, anything that touches it
# breaks it, and it never holds anything, like grass.
const WIRE := Color("3a3d45")
const FORMS := Color("fbf7ef")
const STAMP := Color("c8202c")


func is_solid() -> bool:
	return false


func body_size() -> Vector2:
	return Vector2(18, 16)


func art_id() -> String:
	return "in_tray"


func debris_color() -> Color:
	return FORMS


func can_break_by(_source: String) -> bool:
	return true


func _draw_placeholder() -> void:
	draw_line(Vector2(-6, 6), Vector2(-6, 10), WIRE, 2.0)
	draw_line(Vector2(6, 6), Vector2(6, 10), WIRE, 2.0)
	for level in 2:
		var top := -6.0 + level * 6.0
		draw_rect(Rect2(-8, top - 3.0, 16, 4), FORMS)
		draw_rect(Rect2(-9, top, 18, 2), WIRE)
	draw_rect(Rect2(-3, -8, 6, 2), STAMP)
