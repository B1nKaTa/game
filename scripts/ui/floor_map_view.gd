class_name FloorMapView
extends Control

signal opened_changed(is_open: bool)

const ROOM_COLORS := {
	RoomLayout.TYPE_COMBAT: Color("8f8ba0"),
	RoomLayout.TYPE_ITEM: Color("7dd3fc"),
	RoomLayout.TYPE_HEALING: Color("e4524f"),
	RoomLayout.TYPE_SIDE: Color("a78bda"),
	RoomLayout.TYPE_MINI_BOSS: Color("ff9a3c"),
	RoomLayout.TYPE_FLOOR_BOSS: Color("ffd24a"),
	RoomLayout.TYPE_TREASURE: Color("67f0d0"),
	RoomLayout.TYPE_SHOP: Color("7d9a5c"),
	RoomLayout.TYPE_SECRET: Color("ece9e0"),
	RoomLayout.TYPE_VAULT: Color("5fd8ff"),
	RoomLayout.TYPE_CROSSROADS: Color("c9b98a"),
	RoomLayout.TYPE_LANDING: Color("c9b98a"),
	RoomLayout.TYPE_ARCADE: Color("e85fd0"),
}
const PANEL_COLOR := Color(0.09, 0.07, 0.11, 0.65)
const BIG_PANEL_COLOR := Color(0.09, 0.07, 0.11, 0.95)
const LINE_COLOR := Color("c9c5d6")
const CURRENT_COLOR := Color.WHITE
# The floor's name sits on the row above it, at the top of the screen.
const NAME_FONT := 9
const NAME_BASELINE := 10.0
const NAME_COLOR := Color("ece9e0")
const MINI_RECT := Rect2(528, 13, 108, 58)
const CROSSROADS_SCALE := 0.65
const MINI_SPACING := Vector2(13, 11)
const MINI_FONT := 8
const MINI_LINK := 3.0
const BIG_RECT := Rect2(60, 40, 520, 280)
const BIG_AREA := Rect2(72, 70, 496, 214)
const BIG_SPACING := Vector2(60, 46)
const BIG_FONT := 16
const BIG_LINK := 6.0
const ROOM_FILL := 0.8
const LEGEND_TOP := "C Combat   I Item   H Healing   ? Side   S Secret"
const LEGEND_BOTTOM := "T Treasure   $ Shop   M Mini boss   B Boss   V Vault   + Crossroads"
const CLOSE_HINT := "Close"
# A room the Floor Plan shows but he has not walked into: an outline only, saying nothing of what is in it.
const PLAN_COLOR := Color("8a8698")
const PLAN_LINK_COLOR := Color(0.79, 0.77, 0.84, 0.45)
# The Fortune Teller's Card writes who waits in a boss room under it on the big map.
const BOSS_NAME_FONT := 10
const BOSS_NAME_COLOR := Color("ffd24a")
# Rooms the Floor Plan never gives away, since finding them is the point.
const HIDDEN_TYPES := [RoomLayout.TYPE_SECRET, RoomLayout.TYPE_VAULT]
const BOSS_TYPES := [RoomLayout.TYPE_FLOOR_BOSS, RoomLayout.TYPE_MINI_BOSS]

var enabled := true
# The Night Vision option: secret rooms show, as outlines with a "?", before they are found.
var show_secrets := false
var _map: FloorMap
var _progress: FloorProgress
var _current_id := -1
var _is_big := false
var _floor_name := ""
# The run's combos, listed on the paused big map as its run summary.
var combo_names := PackedStringArray():
	set(value):
		combo_names = value
		queue_redraw()
# The Floor Plan: every room but the hidden ones shows from the start, as an outline until visited.
var show_plan := false:
	set(value):
		show_plan = value
		queue_redraw()
# The Fortune Teller's Card: room type -> the name of the boss who waits there. Boss rooms then show
# before they are found, and the big map names them.
var boss_names := {}:
	set(value):
		boss_names = value
		queue_redraw()


# The rooms the map shows: every visited room, and with show_secrets every secret room as well. With
# the Floor Plan every room but the secret ones and vaults shows, and with boss names every boss room.
static func shown_ids(map: FloorMap, progress: FloorProgress, with_secrets: bool, with_plan := false, with_bosses := false) -> Array[int]:
	var ids: Array[int] = []
	ids.append_array(progress.visited_ids())
	for room in map.rooms:
		if ids.has(room.id):
			continue
		var secret := room.room_type == RoomLayout.TYPE_SECRET
		if (with_secrets and secret) or (with_plan and not HIDDEN_TYPES.has(room.room_type)) or (with_bosses and BOSS_TYPES.has(room.room_type)):
			ids.append(room.id)
	return ids


# Who waits in this floor's boss rooms, by room type, for the Fortune Teller's Card.
static func boss_names_for(floor_def: FloorDef) -> Dictionary:
	var names := {}
	if floor_def == null:
		return names
	if floor_def.floor_boss != null:
		names[RoomLayout.TYPE_FLOOR_BOSS] = floor_def.floor_boss.display_name
	if floor_def.mini_boss != null:
		names[RoomLayout.TYPE_MINI_BOSS] = floor_def.mini_boss.display_name
	return names


# Whether a link between two rooms shows: between two visited rooms always, and with the Floor Plan
# between any two rooms it shows, as long as neither is hidden.
static func link_shown(a: FloorRoom, b: FloorRoom, progress: FloorProgress, with_plan: bool) -> bool:
	if progress.is_visited(a.id) and progress.is_visited(b.id):
		return true
	return with_plan and not HIDDEN_TYPES.has(a.room_type) and not HIDDEN_TYPES.has(b.room_type)


# A room's place on the map is its grid cell, counted from the floor's top left, whatever its size.
static func map_position(map: FloorMap, room: FloorRoom) -> Vector2:
	return Vector2(room.cell - map.bounds().position)


static func room_size(spacing: Vector2) -> Vector2:
	return (spacing * ROOM_FILL).floor()


static func room_rect(at: Vector2, origin: Vector2, spacing: Vector2) -> Rect2:
	return Rect2(origin + at * spacing, room_size(spacing))


# As roomy as the panel allows while the whole floor fits, with a stable picture as rooms are found.
static func big_spacing(extent: Vector2i) -> Vector2:
	var fit := (BIG_AREA.size / Vector2(extent)).floor()
	return Vector2(minf(fit.x, BIG_SPACING.x), minf(fit.y, BIG_SPACING.y))


static func big_origin(extent: Vector2i, spacing: Vector2) -> Vector2:
	var used := Vector2(extent) * spacing - (spacing - room_size(spacing))
	return BIG_AREA.position + ((BIG_AREA.size - used) / 2.0).floor()


# The small map keeps the current room in the middle, since a whole floor won't fit in the corner.
static func mini_origin(current_at: Vector2) -> Vector2:
	return MINI_RECT.get_center() - current_at * MINI_SPACING - room_size(MINI_SPACING) / 2.0


# The Crossroads is a smaller square in its cell, so it reads as the little room it is.
static func crossroads_rect(cell_rect: Rect2) -> Rect2:
	var size := (cell_rect.size * CROSSROADS_SCALE).floor()
	return Rect2(cell_rect.get_center() - size / 2.0, size)


func setup(map: FloorMap, progress: FloorProgress, is_big: bool, floor_name := "") -> void:
	_map = map
	_progress = progress
	_is_big = is_big
	_floor_name = floor_name
	queue_redraw()


func floor_name() -> String:
	return _floor_name


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _is_big:
		visible = false
		# It has to hear the key while the game is paused.
		process_mode = Node.PROCESS_MODE_ALWAYS


func set_current(room_id: int) -> void:
	_current_id = room_id
	queue_redraw()


func is_open() -> bool:
	return _is_big and visible


func set_open(open: bool) -> void:
	if not _is_big or open == visible:
		return
	visible = open
	get_tree().paused = open
	queue_redraw()
	opened_changed.emit(open)


func _unhandled_input(event: InputEvent) -> void:
	if _is_big and event.is_action_pressed("map") and (enabled or visible):
		set_open(not visible)
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if is_open():
		get_tree().paused = false


func _draw() -> void:
	if _map == null or _progress == null or _current_id == -1:
		return
	var panel := BIG_RECT if _is_big else MINI_RECT
	var extent := _map.bounds().size
	var spacing := big_spacing(extent) if _is_big else MINI_SPACING
	var origin := big_origin(extent, spacing) if _is_big else mini_origin(map_position(_map, _map.room(_current_id)))
	draw_rect(panel, BIG_PANEL_COLOR if _is_big else PANEL_COLOR)
	draw_rect(panel, Color("625e6f"), false, 1.0)
	var shown := shown_ids(_map, _progress, show_secrets, show_plan, not boss_names.is_empty())
	for room_id in (shown if show_plan else _progress.visited_ids()):
		_draw_links(_map.room(room_id), panel, origin, spacing)
	for room_id in shown:
		_draw_room(_map.room(room_id), panel, origin, spacing)
	if _is_big:
		for room_id in shown:
			_draw_boss_name(_map.room(room_id), panel, origin, spacing)
	if not _is_big:
		_draw_floor_name()
	else:
		_draw_text(panel.position + Vector2(12, 22), _floor_name, 16, Color.WHITE)
		if not combo_names.is_empty():
			_draw_text(panel.position + Vector2(12, 36), combos_line(combo_names), 10, Hud.BANNER_COLOR)
		_draw_text(panel.end - Vector2(62, 257), KeyBindings.with_key("map", CLOSE_HINT), 11, Color("ffd24a"))
		_draw_text(panel.position + Vector2(12, panel.size.y - 26), LEGEND_TOP, 11, Color("ece9e0"))
		_draw_text(panel.position + Vector2(12, panel.size.y - 12), LEGEND_BOTTOM, 11, Color("ece9e0"))


static func combos_line(names: PackedStringArray) -> String:
	return "Combos: %s" % ", ".join(names)


func _draw_floor_name() -> void:

	var font := ThemeDB.fallback_font
	var width := font.get_string_size(_floor_name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT).x
	var at := Vector2(MINI_RECT.end.x - width, NAME_BASELINE)
	draw_string_outline(font, at, _floor_name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT, 3, Color.BLACK)
	draw_string(font, at, _floor_name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT, NAME_COLOR)


# Only between two visited rooms, so a link never gives away a room or a secret not yet found.
func _draw_links(room: FloorRoom, panel: Rect2, origin: Vector2, spacing: Vector2) -> void:
	var from := _rect_of(room, origin, spacing)
	if not panel.encloses(from):
		return
	for side: Vector2i in room.doors:
		var other_id: int = room.doors[side]
		var other := _map.room(other_id)
		if not link_shown(room, other, _progress, show_plan) or not panel.encloses(_rect_of(other, origin, spacing)):
			continue
		var center := from.get_center()
		var known := _progress.is_visited(room.id) and _progress.is_visited(other_id)
		draw_line(center, center + Vector2(side) * spacing, LINE_COLOR if known else PLAN_LINK_COLOR, BIG_LINK if _is_big else MINI_LINK)


# The Fortune Teller's Card: the boss's name in the gap under its room, outlined so it reads over links.
func _draw_boss_name(room: FloorRoom, panel: Rect2, origin: Vector2, spacing: Vector2) -> void:
	if not boss_names.has(room.room_type):
		return
	var rect := _rect_of(room, origin, spacing)
	if not panel.encloses(rect):
		return
	var text: String = boss_names[room.room_type]
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, BOSS_NAME_FONT).x
	var x := clampf(rect.get_center().x - width / 2.0, panel.position.x + 4.0, panel.end.x - width - 4.0)
	var at := Vector2(x, rect.end.y + font.get_ascent(BOSS_NAME_FONT) + 1.0)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, BOSS_NAME_FONT, 4, Color.BLACK)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, BOSS_NAME_FONT, BOSS_NAME_COLOR)


func _rect_of(room: FloorRoom, origin: Vector2, spacing: Vector2) -> Rect2:
	return room_rect(map_position(_map, room), origin, spacing)


func _draw_room(room: FloorRoom, panel: Rect2, origin: Vector2, spacing: Vector2) -> void:
	var rect := _rect_of(room, origin, spacing)
	if not panel.encloses(rect):
		return
	var is_crossroads := room.room_type == RoomLayout.TYPE_CROSSROADS
	if is_crossroads:
		rect = crossroads_rect(rect)
	# A boss room the Fortune Teller's Card shows before it is found: an outline in its colour, with its letter.
	if not _progress.is_visited(room.id) and boss_names.has(room.room_type):
		var boss_color: Color = ROOM_COLORS.get(room.room_type, Color.WHITE)
		draw_rect(rect, Color(boss_color, 0.25))
		draw_rect(rect, boss_color, false, 1.0)
		var letter_size := BIG_FONT if _is_big else MINI_FONT
		var letter := RoomRules.door_icon(room.room_type)
		var letter_box := ThemeDB.fallback_font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, letter_size)
		var letter_ascent := ThemeDB.fallback_font.get_ascent(letter_size)
		_draw_text(rect.get_center() + Vector2(-letter_box.x / 2.0, letter_ascent - letter_box.y / 2.0), letter, letter_size, boss_color)
		return
	# A room the Floor Plan shows but he has not walked into: a plain outline, nothing of what it holds.
	if not _progress.is_visited(room.id) and room.room_type != RoomLayout.TYPE_SECRET:
		draw_rect(rect, Color(PLAN_COLOR, 0.18))
		draw_rect(rect, PLAN_COLOR, false, 1.0)
		return
	# A secret room Night Vision shows but Grandpa has not found is only an outline with a "?".
	if not _progress.is_visited(room.id):
		draw_rect(rect, ROOM_COLORS.get(room.room_type, Color.WHITE), false, 1.0)
		var mark_size := BIG_FONT if _is_big else MINI_FONT
		var mark := ThemeDB.fallback_font.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, mark_size)
		var mark_ascent := ThemeDB.fallback_font.get_ascent(mark_size)
		_draw_text(rect.get_center() + Vector2(-mark.x / 2.0, mark_ascent - mark.y / 2.0), "?", mark_size, ROOM_COLORS.get(room.room_type, Color.WHITE))
		return
	draw_rect(rect, ROOM_COLORS.get(room.room_type, Color.WHITE))
	var is_current := room.id == _current_id
	draw_rect(rect, CURRENT_COLOR if is_current else Color.BLACK, false, 2.0 if is_current else 1.0)
	# Too small for a letter on the corner map, and its shape says enough there.
	if is_crossroads and not _is_big:
		return
	var font_size := BIG_FONT if _is_big else MINI_FONT
	var icon := RoomRules.door_icon(room.room_type)
	if icon == RoomRules.ARCADE_ICON:
		ArcadeTable.draw_die(self, rect.get_center(), float(font_size))
		return
	var icon_size := ThemeDB.fallback_font.get_string_size(icon, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var ascent := ThemeDB.fallback_font.get_ascent(font_size)
	_draw_text(rect.get_center() + Vector2(-icon_size.x / 2.0, ascent - icon_size.y / 2.0), icon, font_size, Color.BLACK)


func _draw_text(at: Vector2, text: String, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
