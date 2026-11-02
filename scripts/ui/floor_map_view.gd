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
}
const PANEL_COLOR := Color(0.09, 0.07, 0.11, 0.65)
const BIG_PANEL_COLOR := Color(0.09, 0.07, 0.11, 0.95)
const LINE_COLOR := Color("625e6f")
const CURRENT_COLOR := Color.WHITE
const MIN_ROW := -1.0
const MINI_RECT := Rect2(528, 3, 108, 30)
const MINI_SPACING := Vector2(13, 8)
const MINI_ROOM := Vector2(9, 6)
const BIG_RECT := Rect2(60, 40, 520, 280)
const BIG_SPACING := Vector2(60, 46)
const BIG_ROOM := Vector2(40, 30)
const BIG_MARGIN := Vector2(38, 58)
const LEGEND := "C Combat    I Item    H Healing    ? Side room    T Treasure    M Mini boss    B Boss"
const TITLE := "Floor Map"
const CLOSE_HINT := "M: Close"

var enabled := true
var _map: FloorMap
var _progress: FloorProgress
var _current_id := -1
var _is_big := false


# Column is the layer, read left to right from the start to the boss. Row is measured so a lone room sits between two.
static func map_position(map: FloorMap, room: FloorRoom) -> Vector2:
	if room.room_type == RoomLayout.TYPE_SIDE:
		var parent := map_position(map, map.room(room.parent_id))
		return Vector2(parent.x, parent.y - 1.0 if parent.y < 1.0 else parent.y + 1.0)
	if room.room_type == RoomLayout.TYPE_TREASURE:
		var parent := map_position(map, map.room(room.parent_id))
		return Vector2(parent.x, parent.y + 1.0)
	var in_layer: Array[FloorRoom] = []
	for candidate in map.main_rooms():
		if candidate.layer == room.layer:
			in_layer.append(candidate)
	if in_layer.size() == 1:
		return Vector2(room.layer, 0.5)
	return Vector2(room.layer, in_layer.find(room))


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
	if _map == null or _progress == null:
		return
	var panel := BIG_RECT if _is_big else MINI_RECT
	var spacing := BIG_SPACING if _is_big else MINI_SPACING
	var room_size := BIG_ROOM if _is_big else MINI_ROOM
	var origin := panel.position + (BIG_MARGIN if _is_big else Vector2(3, 3))
	draw_rect(panel, BIG_PANEL_COLOR if _is_big else PANEL_COLOR)
	draw_rect(panel, LINE_COLOR, false, 1.0)
	for room_id in _progress.visited_ids():
		var previous := _progress.previous_of(room_id)
		if previous != -1:
			draw_line(_room_center(room_id, origin, spacing, room_size), _room_center(previous, origin, spacing, room_size), LINE_COLOR, 2.0 if _is_big else 1.0)
	for room_id in _progress.visited_ids():
		_draw_room(_map.room(room_id), origin, spacing, room_size)
	if _is_big:
		_draw_text(panel.position + Vector2(12, 22), TITLE, 16, Color.WHITE)
		_draw_text(panel.end - Vector2(62, 257), CLOSE_HINT, 11, Color("ffd24a"))
		_draw_text(panel.position + Vector2(12, panel.size.y - 12), LEGEND, 11, Color("ece9e0"))


func _room_center(room_id: int, origin: Vector2, spacing: Vector2, room_size: Vector2) -> Vector2:
	var at := map_position(_map, _map.room(room_id)) - Vector2(0, MIN_ROW)
	return origin + at * spacing + room_size / 2.0


func _draw_room(room: FloorRoom, origin: Vector2, spacing: Vector2, room_size: Vector2) -> void:
	var rect := Rect2(_room_center(room.id, origin, spacing, room_size) - room_size / 2.0, room_size)
	draw_rect(rect, ROOM_COLORS.get(room.room_type, Color.WHITE))
	var is_current := room.id == _current_id
	draw_rect(rect, CURRENT_COLOR if is_current else Color.BLACK, false, 2.0 if is_current and _is_big else 1.0)
	if _is_big:
		_draw_text(rect.position + Vector2(room_size.x / 2.0 - 5.0, room_size.y / 2.0 + 6.0), RoomRules.door_icon(room.room_type), 16, Color.BLACK)


func _draw_text(at: Vector2, text: String, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
