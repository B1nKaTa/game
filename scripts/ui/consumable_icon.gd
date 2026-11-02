class_name ConsumableIcon
extends Control

enum Kind { SLIP, THERMOS }

const SLIP_COLOR := Color("ece9e0")
const SLIP_LINE := Color("7a6a58")
const STAMP_COLOR := Color("e4524f")
const THERMOS_COLOR := Color("ff9a3c")
const THERMOS_CAP := Color("625e6f")

var _kind := Kind.SLIP


func setup(kind: Kind) -> void:
	_kind = kind


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	if _kind == Kind.SLIP:
		_draw_slip()
	else:
		_draw_thermos()


func _draw_slip() -> void:
	draw_rect(Rect2(1, 0, 10, 13), SLIP_COLOR)
	draw_rect(Rect2(1, 0, 10, 13), Color.BLACK, false, 1.0)
	draw_line(Vector2(3, 3), Vector2(9, 3), SLIP_LINE, 1.0)
	draw_line(Vector2(3, 6), Vector2(9, 6), SLIP_LINE, 1.0)
	draw_rect(Rect2(6, 8, 3, 3), STAMP_COLOR)


func _draw_thermos() -> void:
	draw_rect(Rect2(3, 0, 6, 3), THERMOS_CAP)
	draw_rect(Rect2(1, 3, 10, 10), THERMOS_COLOR)
	draw_rect(Rect2(1, 3, 10, 10), Color.BLACK, false, 1.0)
	draw_line(Vector2(1, 8), Vector2(10, 8), Color.BLACK, 1.0)
