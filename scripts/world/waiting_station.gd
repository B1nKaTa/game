class_name WaitingStation
extends Node2D

# A counter, board or merchant in a Waiting Room department. The scene opens its panel when Grandpa
# presses interact beside the nearest one. A station with "art" is a merchant who stands there, drawn
# from res://art/npcs/<art>/ as the department's people are (or that sprite, or its colour box, without
# it); one without is a board, its picture at res://art/props/[waiting_room/]station_<id>.png, with its
# "label" written on it.

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
# The merchant's own art, when he has some (NpcSprite), or null.
var _person: NpcSprite


func setup(station_entry: Dictionary, feet: Node2D) -> void:
	entry = station_entry
	id = entry.get("id", "")
	title = entry.get("title", "")
	prompt = entry.get("prompt", DEFAULT_PROMPT)
	_feet = feet


func _ready() -> void:
	if not entry.has("art"):
		return
	# A merchant who stands at his station is drawn as the department's people are (NpcSprite, from
	# res://art/npcs/<art>/), on the bottom of the body box, with a contact shadow, and turns to face
	# Grandpa while he is in reach. Without that art, a SpriteVisual (or its colour box) stands in.
	var person := NpcSprite.new()
	if person.setup(entry["art"]):
		# His art stands on his feet, so the room sorts him by them, as it does an Npc.
		y_sort_enabled = true
		person.position = Vector2(0, BODY_SIZE.y / 2.0)
		add_child(person)
		_person = person
		ContactShadow.add_to(self, BODY_SIZE.x, Vector2(0.0, BODY_SIZE.y / 2.0))
		return
	person.free()
	var art := SpriteVisual.new()
	add_child(art)
	art.setup(entry["art"], BODY_SIZE, entry.get("color", Color.WHITE), FRAME_WIDTH)


func person() -> NpcSprite:
	return _person


func is_near() -> bool:
	return is_instance_valid(_feet) and _feet.global_position.distance_to(global_position) <= USE_RADIUS


func distance_to_feet() -> float:
	return _feet.global_position.distance_to(global_position) if is_instance_valid(_feet) else INF


func _process(_delta: float) -> void:
	if _person != null:
		_person.face(_feet.global_position - global_position if is_near() else Vector2.ZERO)
	queue_redraw()


func _draw() -> void:
	# A station whose look is drawn by something else, such as the trophy wall, says "board": false.
	if not entry.has("art") and entry.get("board", true):
		var size: Vector2 = entry.get("size", DEFAULT_BOARD_SIZE)
		var box := Rect2(-size / 2.0, size)
		# A picture at res://art/props/station_<id>.png replaces the board and its look; the label is
		# still drawn over it, outlined so it reads on the picture.
		var art := PropArt.texture(art_id())
		if art != null:
			PropArt.draw(self, art)
		else:
			draw_rect(box, entry.get("color", Color.GRAY))
			draw_rect(box, BOARD_EDGE, false, 2.0)
		var label: String = entry.get("label", "")
		if not label.is_empty():
			var width := ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			if art != null:
				draw_string_outline(ThemeDB.fallback_font, Vector2(-width / 2.0, 5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color.BLACK)
			draw_string(ThemeDB.fallback_font, Vector2(-width / 2.0, 5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, LABEL_COLOR)
		if art == null:
			_draw_look(entry.get("look", ""), size)
		if not badge.is_empty():
			var at := Vector2(size.x / 2.0 - 6.0, -size.y / 2.0 - 2.0)
			draw_string_outline(ThemeDB.fallback_font, at, badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color.BLACK)
			draw_string(ThemeDB.fallback_font, at, badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, BADGE_COLOR)
	if highlighted:
		draw_string(ThemeDB.fallback_font, entry.get("prompt_offset", PROMPT_OFFSET), KeyBindings.with_key("interact", prompt), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, PROMPT_COLOR)


func art_id() -> String:
	return "station_" + str(entry.get("id", ""))


# The few boards with more to them than a coloured box. Placeholders, drawn in code.
func _draw_look(look: String, size: Vector2) -> void:
	match look:
		"filing_cabinet":
			# Three drawers, each with a handle and a white label slot.
			var drawer_height := size.y / 3.0
			for i in 3:
				var top := -size.y / 2.0 + drawer_height * i
				draw_line(Vector2(-size.x / 2.0, top), Vector2(size.x / 2.0, top), BOARD_EDGE, 1.0)
				draw_rect(Rect2(Vector2(-4.0, top + 2.0), Vector2(8.0, 3.0)), PAPER)
				draw_rect(Rect2(Vector2(-3.0, top + drawer_height - 5.0), Vector2(6.0, 2.0)), Color("c8c8d0"))
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
