class_name DepartmentSign
extends Node2D

# A department's name over the door that leads to it. A closed department's name is grey, with what
# opens it written under it. The text keeps inside the room, however near a wall the sign stands.

const NAME_SIZE := 10
const HINT_SIZE := 8
const NAME_COLOR := Color("ece9e0")
const CLOSED_COLOR := Color("8d8a94")
const HINT_COLOR := Color("b9b4c4")
const OUTLINE := Color.BLACK
const NAME_Y := -6.0
const HINT_Y := 6.0
# The room's inside, in this node's parent coordinates: from one cell in on the left to one cell in
# on the right.
const MARGIN := 32.0

var text := ""
var hint := ""
var closed := false
var _min_x := -INF
var _max_x := INF


func setup(sign_text: String, is_closed: bool, closed_hint := "", room_width := 0.0) -> void:
	text = sign_text
	closed = is_closed
	hint = closed_hint if is_closed else ""
	if room_width > 0.0:
		_min_x = MARGIN
		_max_x = room_width - MARGIN
	z_index = 5


# Where a line of text starts so that it is centred on the sign, yet stays between min_x and max_x,
# which are in the same coordinates as center_x.
static func text_left(center_x: float, width: float, min_x: float, max_x: float) -> float:
	var left := center_x - width / 2.0
	if left + width > max_x:
		left = max_x - width
	return maxf(left, min_x)


func _draw() -> void:
	_draw_line(text, NAME_SIZE, CLOSED_COLOR if closed else NAME_COLOR, NAME_Y)
	if not hint.is_empty():
		_draw_line(hint, HINT_SIZE, HINT_COLOR, HINT_Y)


func _draw_line(line: String, font_size: int, color: Color, y: float) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var left := text_left(position.x, width, _min_x, _max_x) - position.x
	draw_string_outline(font, Vector2(left, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, OUTLINE)
	draw_string(font, Vector2(left, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
