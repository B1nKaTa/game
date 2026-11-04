class_name WaitingStation
extends Node2D

# A counter, board or merchant in a Waiting Room department. The scene opens its panel when Grandpa
# presses interact beside the nearest one. A station with "art" shows that sprite, one without is a
# board drawn in its colour, with its "label" written on it.

const USE_RADIUS := 48.0
const BODY_SIZE := Vector2(22, 30)
const FRAME_WIDTH := 32
const DEFAULT_BOARD_SIZE := Vector2(28, 36)
const DEFAULT_PROMPT := "Use"
const PROMPT_OFFSET := Vector2(-30, -24)
const PROMPT_COLOR := Color.WHITE
const BOARD_EDGE := Color.BLACK
const LABEL_COLOR := Color.WHITE
const BADGE_COLOR := Color("ffd24a")
const PAPER := Color("f4efe2")
const PIN := Color("d8323a")

var id := ""
var title := ""
var prompt := ""
var entry: Dictionary = {}
# Set by the scene on the one station that answers interact, so only its prompt shows.
var highlighted := false
# A small mark over the board, such as the noticeboard's NEW while a letter waits unread. Empty for none.
var badge := ""
var _feet: Node2D


func setup(station_entry: Dictionary, feet: Node2D) -> void:
	entry = station_entry
	id = entry.get("id", "")
	title = entry.get("title", "")
	prompt = entry.get("prompt", DEFAULT_PROMPT)
	_feet = feet


func _ready() -> void:
	if entry.has("art"):
		var art := SpriteVisual.new()
		add_child(art)
		art.setup(entry["art"], BODY_SIZE, entry.get("color", Color.WHITE), FRAME_WIDTH)


func is_near() -> bool:
	return is_instance_valid(_feet) and _feet.global_position.distance_to(global_position) <= USE_RADIUS


func distance_to_feet() -> float:
	return _feet.global_position.distance_to(global_position) if is_instance_valid(_feet) else INF


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# A station whose look is drawn by something else, such as the trophy wall, says "board": false.
	if not entry.has("art") and entry.get("board", true):
		var size: Vector2 = entry.get("size", DEFAULT_BOARD_SIZE)
		var box := Rect2(-size / 2.0, size)
		draw_rect(box, entry.get("color", Color.GRAY))
		draw_rect(box, BOARD_EDGE, false, 2.0)
		var label: String = entry.get("label", "")
		if not label.is_empty():
			var width := ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			draw_string(ThemeDB.fallback_font, Vector2(-width / 2.0, 5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, LABEL_COLOR)
		_draw_look(entry.get("look", ""), size)
		if not badge.is_empty():
			var at := Vector2(size.x / 2.0 - 6.0, -size.y / 2.0 - 2.0)
			draw_string_outline(ThemeDB.fallback_font, at, badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color.BLACK)
			draw_string(ThemeDB.fallback_font, at, badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, BADGE_COLOR)
	if highlighted:
		draw_string(ThemeDB.fallback_font, PROMPT_OFFSET, KeyBindings.with_key("interact", prompt), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, PROMPT_COLOR)


# The few boards with more to them than a coloured box. Placeholders, drawn in code.
func _draw_look(look: String, size: Vector2) -> void:
	match look:
		"ticket_machine":
			# A dark slot with a paper tongue sticking out of it, and a number window above.
			draw_rect(Rect2(Vector2(-size.x / 2.0 + 3.0, -size.y / 2.0 + 3.0), Vector2(size.x - 6.0, 6.0)), Color(0.1, 0.1, 0.1))
			draw_rect(Rect2(Vector2(-5.0, 2.0), Vector2(10.0, 2.0)), Color(0.1, 0.1, 0.1))
			draw_rect(Rect2(Vector2(-4.0, 3.0), Vector2(8.0, 9.0)), PAPER)
			draw_rect(Rect2(Vector2(-4.0, 3.0), Vector2(8.0, 9.0)), BOARD_EDGE, false, 1.0)
		"noticeboard":
			# Letters pinned to the cork.
			for spot: Vector2 in [Vector2(-11, -6), Vector2(-1, -4), Vector2(8, -7), Vector2(-6, 3), Vector2(5, 2)]:
				draw_rect(Rect2(spot - Vector2(3.5, 2.5), Vector2(7.0, 5.0)), PAPER)
				draw_circle(spot + Vector2(0, -2.5), 1.0, PIN)
