class_name Door
extends Node2D

signal entered(target_id: int)
signal key_spent

const ENTER_RADIUS := 18.0
const KEY_PROMPT := "Use Slip"
const NO_KEY_PROMPT := "Needs a Slip"

var locked := true
var sealed := false
var requires_key := false
var has_key := Callable()
var _target_id := -1
var _icon := "?"
var _player: Node2D
var _used := false
var _armed := false
var _near := false


# A door only works after the player has stepped away from it, so arriving on one doesn't bounce them back.
static func next_armed(armed: bool, in_range: bool) -> bool:
	return armed or not in_range


static func should_enter(is_locked: bool, is_sealed: bool, needs_key: bool, used: bool, armed: bool, in_range: bool) -> bool:
	return armed and in_range and not (is_locked or is_sealed or needs_key or used)


static func can_spend_key(needs_key: bool, is_locked: bool, in_range: bool, player_has_key: bool) -> bool:
	return needs_key and not is_locked and in_range and player_has_key


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
	_near = global_position.distance_to(_player.global_position) <= ENTER_RADIUS
	_armed = next_armed(_armed, _near)
	if Input.is_action_just_pressed("interact") and can_spend_key(requires_key, locked, _near, _player_has_key()):
		requires_key = false
		key_spent.emit()
		return
	if should_enter(locked, sealed, requires_key, _used, _armed, _near):
		_used = true
		entered.emit(_target_id)


func _player_has_key() -> bool:
	return has_key.is_valid() and has_key.call()


func _draw() -> void:
	var color := Color("7a3b3b") if locked else Color("c98a3c")
	if requires_key and not locked:
		color = Color("5d4a8c")
	if sealed:
		color = Color("2c2833")
	draw_rect(Rect2(-14, -14, 28, 28), color)
	draw_rect(Rect2(-14, -14, 28, 28), Color.BLACK, false, 2.0)
	if sealed:
		draw_line(Vector2(-9, -9), Vector2(9, 9), Color("625e6f"), 2.0)
		draw_line(Vector2(-9, 9), Vector2(9, -9), Color("625e6f"), 2.0)
		return
	draw_string(ThemeDB.fallback_font, Vector2(-5, 6), _icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	if requires_key and not locked and _near:
		var prompt := KeyBindings.with_key("interact", KEY_PROMPT) if _player_has_key() else NO_KEY_PROMPT
		draw_string(ThemeDB.fallback_font, Vector2(18, 4), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("ffd24a"))
