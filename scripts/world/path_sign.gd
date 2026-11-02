class_name PathSign
extends Node2D

# A signpost at one exit of the Crossroads. Up close it gives the path's name and skulls for its
# danger, and a closed path's sign hangs in chains with a hint. It blocks nothing.
const NEAR_RADIUS := 96.0
const TEXT_COLOR := Color("ece9e0")
const HINT_COLOR := Color("ffd24a")
const POST_COLOR := Color("5a4630")
const BOARD_COLOR := Color("8a6a3a")
const BOARD_EDGE := Color("2b2018")
const CHAIN_COLOR := Color("b9bdc6")
const CHAIN_EDGE := Color("23252c")
const SKULL_COLOR := Color("efe8d2")
const SKULL_EYES := Color("15131a")
const NAME_FONT := 11
const HINT_FONT := 9
const SKULL_GAP := 14.0
const TEXT_TOP := -58.0

var _def: FloorDef
var _is_open := true
var _player: Node2D
var _side := Vector2i.LEFT
var _near := false


static func shows_details(sign_at: Vector2, feet: Vector2) -> bool:
	return sign_at.distance_to(feet) <= NEAR_RADIUS


static func title_for(def: FloorDef, _open: bool) -> String:
	return def.display_name


static func detail_for(def: FloorDef, open: bool) -> String:
	return "" if open else def.closed_hint


static func skulls_for(def: FloorDef) -> int:
	return maxi(def.danger, 1)


func setup(def: FloorDef, is_open: bool, player: Node2D, side: Vector2i) -> void:
	_def = def
	_is_open = is_open
	_player = player
	_side = side


func is_chained() -> bool:
	return not _is_open


func is_showing_details() -> bool:
	return _near


func _ready() -> void:
	z_index = 5
	queue_redraw()


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return
	var near := shows_details(global_position, _player.global_position)
	if near != _near:
		_near = near
		queue_redraw()


func _draw() -> void:
	_draw_post()
	if not _is_open:
		_draw_chains()
	if _near and _def != null:
		_draw_details()


func _draw_post() -> void:
	draw_rect(Rect2(-2, -6, 4, 22), POST_COLOR)
	draw_rect(Rect2(-2, -6, 4, 22), BOARD_EDGE, false, 1.0)
	var board := Rect2(-16, -22, 32, 16)
	draw_rect(board, BOARD_COLOR)
	draw_rect(board, BOARD_EDGE, false, 2.0)
	# The board's tip points the way the exit lies.
	var tip_x := 22.0 * _side.x
	var base_x := 16.0 * _side.x
	draw_colored_polygon(PackedVector2Array([Vector2(base_x, -22), Vector2(tip_x, -14), Vector2(base_x, -6)]), BOARD_COLOR)


func _draw_chains() -> void:
	for ends: Array in [[Vector2(-18, -24), Vector2(18, -5)], [Vector2(18, -24), Vector2(-18, -5)]]:
		draw_line(ends[0], ends[1], CHAIN_EDGE, 4.0)
		draw_line(ends[0], ends[1], CHAIN_COLOR, 2.0)
	var lock := Rect2(-4, -17, 8, 7)
	draw_rect(lock, CHAIN_COLOR)
	draw_rect(lock, CHAIN_EDGE, false, 1.0)


func _draw_details() -> void:
	var font := ThemeDB.fallback_font
	var title := title_for(_def, _is_open)
	var width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT).x
	var at := Vector2(-width / 2.0, TEXT_TOP)
	draw_string_outline(font, at, title, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT, 3, Color.BLACK)
	draw_string(font, at, title, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_FONT, TEXT_COLOR)
	var skulls := skulls_for(_def)
	var start := -(skulls - 1) * SKULL_GAP / 2.0
	for i in skulls:
		_draw_skull(Vector2(start + i * SKULL_GAP, TEXT_TOP + 11.0))
	var hint := detail_for(_def, _is_open)
	if not hint.is_empty():
		var hint_width := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, HINT_FONT).x
		var hint_at := Vector2(-hint_width / 2.0, TEXT_TOP + 28.0)
		draw_string_outline(font, hint_at, hint, HORIZONTAL_ALIGNMENT_LEFT, -1, HINT_FONT, 3, Color.BLACK)
		draw_string(font, hint_at, hint, HORIZONTAL_ALIGNMENT_LEFT, -1, HINT_FONT, HINT_COLOR)


func _draw_skull(at: Vector2) -> void:
	draw_circle(at, 5.0, SKULL_COLOR)
	draw_rect(Rect2(at + Vector2(-3, 3), Vector2(6, 4)), SKULL_COLOR)
	draw_circle(at + Vector2(-2, -0.5), 1.4, SKULL_EYES)
	draw_circle(at + Vector2(2, -0.5), 1.4, SKULL_EYES)
	draw_line(at + Vector2(-1, 5), at + Vector2(-1, 7), SKULL_EYES, 1.0)
	draw_line(at + Vector2(1, 5), at + Vector2(1, 7), SKULL_EYES, 1.0)
