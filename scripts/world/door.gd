class_name Door
extends Node2D

signal entered(target_id: int)

const ENTER_RADIUS := 18.0

var locked := true
var sealed := false
var _target_id := -1
var _icon := "?"
var _player: Node2D
var _used := false
var _armed := false


# A door only works after the player has stepped away from it, so arriving on one doesn't bounce them back.
static func next_armed(armed: bool, in_range: bool) -> bool:
	return armed or not in_range


static func should_enter(is_locked: bool, is_sealed: bool, used: bool, armed: bool, in_range: bool) -> bool:
	return armed and in_range and not (is_locked or is_sealed or used)


func setup(target_id: int, icon: String, player: Node2D) -> void:
	_target_id = target_id
	_icon = icon
	_player = player


func target_id() -> int:
	return _target_id


func rearm() -> void:
	_used = false
	_armed = false


func _process(_delta: float) -> void:
	queue_redraw()
	if not is_instance_valid(_player):
		return
	var in_range := global_position.distance_to(_player.global_position) <= ENTER_RADIUS
	_armed = next_armed(_armed, in_range)
	if should_enter(locked, sealed, _used, _armed, in_range):
		_used = true
		entered.emit(_target_id)


func _draw() -> void:
	var color := Color("7a3b3b") if locked else Color("c98a3c")
	if sealed:
		color = Color("2c2833")
	draw_rect(Rect2(-14, -14, 28, 28), color)
	draw_rect(Rect2(-14, -14, 28, 28), Color.BLACK, false, 2.0)
	if sealed:
		draw_line(Vector2(-9, -9), Vector2(9, 9), Color("625e6f"), 2.0)
		draw_line(Vector2(-9, 9), Vector2(9, -9), Color("625e6f"), 2.0)
		return
	draw_string(ThemeDB.fallback_font, Vector2(-5, 6), _icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
