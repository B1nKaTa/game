class_name LobbyText
extends Control

# The lobby's ticket line and the DEV hint. They sit on the screen, not in the room, since the lobby is
# wider than the view and the camera scrolls: anything drawn on its walls left the screen.

const VIEW := Vector2(640, 360)
# On the HUD's top row, right-aligned, so it stays clear of Pension and Condolences on the left and of
# the notices, which show lower down.
const TICKET_TOP := 4.0
const TICKET_SIZE := 12
const RIGHT_MARGIN := 8.0
const TICKET_COLOR := Color("ece9e0")
const NOW_SERVING_COLOR := Color("e4524f")
# A number that is not called shows 999: "you'll be a while". Never 666, which reads as devil imagery
# (the game keeps all heaven, hell and devil symbols out).
const NOT_CALLED := 999
# Along the bottom of the screen, the DEV hint on the left and the dev profile's label on the right.
const HINT_AT := Vector2(12, 332)
const HINT_SIZE := 10
const PROFILE_AT := Vector2(548, 330)
const PROFILE_SIZE := 12
const DEV_COLOR := Color("ffd34f")

var _ticket: Label
var _serving: Label
var _hint: Label


static func ticket_text(run_count: int) -> String:
	return "YOUR TICKET: %d   " % (run_count + 1)


static func serving_text(serving: int) -> String:
	var text := "NOW SERVING: %d" % serving
	if serving != NOT_CALLED:
		text += "  Called!"
	return text


static func text_width(text: String, font_size: int) -> float:
	return ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


static func text_height(font_size: int) -> float:
	return ThemeDB.fallback_font.get_height(font_size)


# Where the ticket line starts, so that it ends RIGHT_MARGIN in from the screen's right edge.
static func ticket_left(ticket: String, serving: String) -> float:
	return VIEW.x - RIGHT_MARGIN - text_width(ticket + serving, TICKET_SIZE)


static func make_label(at: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	return label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ticket = make_label(Vector2.ZERO, TICKET_SIZE, TICKET_COLOR)
	_serving = make_label(Vector2.ZERO, TICKET_SIZE, NOW_SERVING_COLOR)
	_hint = make_label(HINT_AT, HINT_SIZE, DEV_COLOR)
	add_child(_ticket)
	add_child(_serving)
	add_child(_hint)


# hint is "" outside debug builds.
func show_text(run_count: int, serving: int, hint: String) -> void:
	_ticket.text = ticket_text(run_count)
	_serving.text = serving_text(serving)
	var left := ticket_left(_ticket.text, _serving.text)
	_ticket.position = Vector2(left, TICKET_TOP)
	_serving.position = Vector2(left + text_width(_ticket.text, TICKET_SIZE), TICKET_TOP)
	_hint.text = hint
	_hint.visible = not hint.is_empty()


func ticket_line() -> String:
	return _ticket.text + _serving.text


func hint_line() -> String:
	return _hint.text if _hint.visible else ""
