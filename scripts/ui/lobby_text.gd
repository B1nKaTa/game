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
# Harold's ticket is the run he is about to start, and the sign always serves the number just before
# his: he is forever next. Once, after a run that reached an ending, the sign serves his own number.
const SERVED_MARK := "  That's you!"
const SERVED_NOTICE := "Now serving: you."
# Along the bottom of the screen, the DEV hint on the left and the dev profile's label on the right.
const HINT_AT := Vector2(12, 332)
const HINT_SIZE := 10
const PROFILE_AT := Vector2(548, 330)
const PROFILE_SIZE := 12
const DEV_COLOR := Color("ffd34f")

var _ticket: Label
var _serving: Label
var _hint: Label


# The run about to start, or, while his finished run is being served, that run's own number.
static func ticket_number(run_count: int, served := false) -> int:
	return run_count if is_served(run_count, served) else run_count + 1


# Always one short of his ticket, except in the one moment his finished run is served.
static func serving_number(run_count: int, served := false) -> int:
	var ticket := ticket_number(run_count, served)
	return ticket if is_served(run_count, served) else ticket - 1


# A fresh save has no finished run to serve.
static func is_served(run_count: int, served: bool) -> bool:
	return served and run_count > 0


# Three digits, as on the title screen's board: 000, 041, 1000.
static func number_text(number: int) -> String:
	return "%03d" % number


static func ticket_text(ticket: int) -> String:
	return "YOUR TICKET: %s   " % number_text(ticket)


static func serving_text(serving: int, served := false) -> String:
	return "NOW SERVING: %s%s" % [number_text(serving), SERVED_MARK if served else ""]


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


# hint is "" outside debug builds. served is true only for the visit that serves a finished run.
func show_text(run_count: int, hint: String, served := false) -> void:
	_ticket.text = ticket_text(ticket_number(run_count, served))
	_serving.text = serving_text(serving_number(run_count, served), is_served(run_count, served))
	var left := ticket_left(_ticket.text, _serving.text)
	_ticket.position = Vector2(left, TICKET_TOP)
	_serving.position = Vector2(left + text_width(_ticket.text, TICKET_SIZE), TICKET_TOP)
	_hint.text = hint
	_hint.visible = not hint.is_empty()


func ticket_line() -> String:
	return _ticket.text + _serving.text


func hint_line() -> String:
	return _hint.text if _hint.visible else ""
