class_name Door
extends Node2D

signal entered(target_id: int)
signal key_spent

const ENTER_RADIUS := 18.0
const PROMPT_GAP := 18.0
const KEY_PROMPT := "Use Slip"
const NO_KEY_PROMPT := "Needs a Slip"
const CHAINED_COLOR := Color("3c3a44")

var locked := true
var requires_key := false
# Stays shut however the room goes, as a closed path at the Crossroads does.
var chained := false
var has_key := Callable()
var _target_id := -1
var _side := Vector2i.ZERO
var _icon := "?"
var _player: Node2D
var _used := false
var _armed := false
var _near := false


# A door only works after the player has stepped away from it, so arriving on one doesn't bounce them back.
static func next_armed(armed: bool, in_range: bool) -> bool:
	return armed or not in_range


static func should_enter(is_locked: bool, needs_key: bool, used: bool, armed: bool, in_range: bool, is_chained := false) -> bool:
	return armed and in_range and not (is_locked or needs_key or used or is_chained)


static func can_spend_key(needs_key: bool, is_locked: bool, in_range: bool, player_has_key: bool) -> bool:
	return needs_key and not is_locked and in_range and player_has_key


func setup(target_id: int, icon: String, player: Node2D, side := Vector2i.ZERO) -> void:
	_side = side
	_target_id = target_id
	_icon = icon
	_player = player


# A door on the east wall would otherwise run its prompt off the room.
static func prompt_x(text_width: float, side: Vector2i) -> float:
	return -PROMPT_GAP - text_width if side == RoomLayout.EAST else PROMPT_GAP


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
	if should_enter(locked, requires_key, _used, _armed, _near, chained):
		_used = true
		entered.emit(_target_id)


func _player_has_key() -> bool:
	return has_key.is_valid() and has_key.call()


# Which picture the door shows (PropArt door_<state>): chained, locked, a Slip's lock, or open.
func art_state() -> String:
	if chained:
		return "chained"
	if locked:
		return "locked"
	if requires_key:
		return "key"
	return "open"


func _draw() -> void:
	var art := PropArt.state_texture("door", art_state())
	if art != null:
		PropArt.draw(self, art)
		if not chained:
			_draw_icon_and_prompt(true)
		return
	var color := Color("7a3b3b") if locked else Color("c98a3c")
	if requires_key and not locked:
		color = Color("5d4a8c")
	if chained:
		color = CHAINED_COLOR
	draw_rect(Rect2(-14, -14, 28, 28), color)
	draw_rect(Rect2(-14, -14, 28, 28), Color.BLACK, false, 2.0)
	if chained:
		draw_line(Vector2(-14, -14), Vector2(14, 14), PathSign.CHAIN_EDGE, 4.0)
		draw_line(Vector2(14, -14), Vector2(-14, 14), PathSign.CHAIN_EDGE, 4.0)
		draw_line(Vector2(-14, -14), Vector2(14, 14), PathSign.CHAIN_COLOR, 2.0)
		draw_line(Vector2(14, -14), Vector2(-14, 14), PathSign.CHAIN_COLOR, 2.0)
		return
	_draw_icon_and_prompt()


# The room's letter (or the Arcade's die) and the Slip prompt stay in code, over a picture or not. Over
# a picture the letter gets a dark outline, so it reads on any door.
func _draw_icon_and_prompt(outlined := false) -> void:
	if _icon == RoomRules.ARCADE_ICON:
		ArcadeTable.draw_die(self, Vector2.ZERO, 16.0)
	else:
		if outlined:
			draw_string_outline(ThemeDB.fallback_font, Vector2(-5, 6), _icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color.BLACK)
		draw_string(ThemeDB.fallback_font, Vector2(-5, 6), _icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	if requires_key and not locked and _near:
		var prompt := KeyBindings.with_key("interact", KEY_PROMPT) if _player_has_key() else NO_KEY_PROMPT
		var width := ThemeDB.fallback_font.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		draw_string(ThemeDB.fallback_font, Vector2(prompt_x(width, _side), 4), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("ffd24a"))
