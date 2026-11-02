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
}
const PANEL_COLOR := Color(0.09, 0.07, 0.11, 0.65)
const BIG_PANEL_COLOR := Color(0.09, 0.07, 0.11, 0.95)
const LINE_COLOR := Color("c9c5d6")
const CURRENT_COLOR := Color.WHITE
const MINI_RECT := Rect2(528, 3, 108, 58)
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
const LEGEND_BOTTOM := "T Treasure   $ Shop   M Mini boss   B Boss"
const TITLE := "Floor Map"
const CLOSE_HINT := "Close"

var enabled := true
var _map: FloorMap
var _progress: FloorProgress
var _current_id := -1
var _is_big := false


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


func setup(map: FloorMap, progress: FloorProgress, is_big: bool) -> void:
	_map = map
	_progress = progress
	_is_big = is_big


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
	for room_id in _progress.visited_ids():
		_draw_links(_map.room(room_id), panel, origin, spacing)
	for room_id in _progress.visited_ids():
		_draw_room(_map.room(room_id), panel, origin, spacing)
	if _is_big:
		_draw_text(panel.position + Vector2(12, 22), TITLE, 16, Color.WHITE)
		_draw_text(panel.end - Vector2(62, 257), KeyBindings.with_key("map", CLOSE_HINT), 11, Color("ffd24a"))
		_draw_text(panel.position + Vector2(12, panel.size.y - 26), LEGEND_TOP, 11, Color("ece9e0"))
		_draw_text(panel.position + Vector2(12, panel.size.y - 12), LEGEND_BOTTOM, 11, Color("ece9e0"))


# Only between two visited rooms, so a link never gives away a room or a secret not yet found.
func _draw_links(room: FloorRoom, panel: Rect2, origin: Vector2, spacing: Vector2) -> void:
	var from := _rect_of(room, origin, spacing)
	if not panel.encloses(from):
		return
	for side: Vector2i in room.doors:
		var other_id: int = room.doors[side]
		if not _progress.is_visited(other_id) or not panel.encloses(_rect_of(_map.room(other_id), origin, spacing)):
			continue
		var center := from.get_center()
		draw_line(center, center + Vector2(side) * spacing, LINE_COLOR, BIG_LINK if _is_big else MINI_LINK)


func _rect_of(room: FloorRoom, origin: Vector2, spacing: Vector2) -> Rect2:
	return room_rect(map_position(_map, room), origin, spacing)


func _draw_room(room: FloorRoom, panel: Rect2, origin: Vector2, spacing: Vector2) -> void:
	var rect := _rect_of(room, origin, spacing)
	if not panel.encloses(rect):
		return
	draw_rect(rect, ROOM_COLORS.get(room.room_type, Color.WHITE))
	var is_current := room.id == _current_id
	draw_rect(rect, CURRENT_COLOR if is_current else Color.BLACK, false, 2.0 if is_current else 1.0)
	var font_size := BIG_FONT if _is_big else MINI_FONT
	var icon := RoomRules.door_icon(room.room_type)
	var icon_size := ThemeDB.fallback_font.get_string_size(icon, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var ascent := ThemeDB.fallback_font.get_ascent(font_size)
	_draw_text(rect.get_center() + Vector2(-icon_size.x / 2.0, ascent - icon_size.y / 2.0), icon, font_size, Color.BLACK)


func _draw_text(at: Vector2, text: String, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
