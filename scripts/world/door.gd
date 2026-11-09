class_name Door
extends Node2D

signal entered(target_id: int)
signal key_spent

const ENTER_RADIUS := 18.0
const PROMPT_GAP := 18.0
const KEY_PROMPT := "Use Slip"
const NO_KEY_PROMPT := "Needs a Slip"
const CHAINED_COLOR := Color("3c3a44")
# A door in a wall shows as an opening in it (DoorOpening): two cells wide, the full wall deep, with
# jambs, the floor running on into darkness, a gate of bars while it is shut, and a small sign of the
# room type beyond. Its cell and the walls' bodies are as they always were; only the look changed.
const GATE_TIME := 0.35
# The way down (the stairwell a fallen floor boss leaves, the Waiting Room's run door) is an old cage lift
# standing on the floor (PropArt lift_closed, lift_half, lift_open): full wall height, wider than Grandpa,
# with brass gates shut while the way is barred and a dial pointing down over them. Its gates fold open
# over LIFT_TIME. Its trigger is the door's own, at the same spot; the picture's bottom row stands
# LIFT_FEET below that spot, so he walks into the car. Without the art it draws as the old door.
const LIFT_ART := "lift"
const LIFT_TIME := 0.6
const LIFT_FEET := 16.0
# Where a door standing on the floor hangs its plaque: in the arch of its picture.
const SIGN_AT := Vector2(0, -1)

var locked := true
var requires_key := false
# Stays shut however the room goes, as a closed path at the Crossroads does.
var chained := false
var has_key := Callable()
# Drawn as the cage lift (LIFT_ART) when its art is there.
var lift := false
# A lift that appears already open (the stairwell, which comes once the boss falls) still shows its
# gates folding open, from shut.
var lift_opens_on_arrival := false
# The room's colours, for the jambs and the floor beyond (set by RoomView before the door enters).
var palette: RoomPalette
# The depth look, when the floor is drawn in it (DepthLook), for the jambs and the floor beyond.
var depth: DepthLook
var _target_id := -1
var _side := Vector2i.ZERO
var _icon := "?"
var _player: Node2D
var _used := false
var _armed := false
var _near := false
var _opening: DoorOpening
# How far the gate has risen: 0 shut, 1 open.
var _gate := -1.0
var _drawn_key := ""


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


func side() -> Vector2i:
	return _side


func icon() -> String:
	return _icon


func rearm() -> void:
	_used = false
	_armed = false


# Whether the way through is barred now: by the fight, a Slip's lock or a chain.
func is_shut() -> bool:
	return locked or requires_key or chained


# Whether Harold's feet are within radius of the door, as the flashback button asks (RuleKeeper).
func is_within(radius: float) -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	return _spot(self).distance_to(_spot(_player)) <= radius


# Where a node stands on screen, or its own position when it is out of the tree (as in a test).
static func _spot(node: Node2D) -> Vector2:
	return node.global_position if node.is_inside_tree() else node.position


# For tests.
func debug_set_player(player: Node2D) -> void:
	_player = player


# How far the gate has risen, 0 shut to 1 open (DoorOpening).
func gate() -> float:
	return clampf(_gate, 0.0, 1.0)


func _ready() -> void:
	if _side != Vector2i.ZERO:
		_opening = DoorOpening.new()
		_opening.door = self
		add_child(_opening)
	queue_redraw()


func _process(delta: float) -> void:
	_update_gate(delta)
	if not is_instance_valid(_player):
		_redraw_if_changed()
		return
	_near = global_position.distance_to(_player.global_position) <= ENTER_RADIUS
	_armed = next_armed(_armed, _near)
	_redraw_if_changed()
	if Input.is_action_just_pressed("interact") and can_spend_key(requires_key, locked, _near, _player_has_key()):
		requires_key = false
		key_spent.emit()
		return
	if should_enter(locked, requires_key, _used, _armed, _near, chained):
		_used = true
		entered.emit(_target_id)


# The gate rises over GATE_TIME once the way opens, and drops at once when it shuts. A door that starts
# open starts with its gate up.
func _update_gate(delta: float) -> void:
	var target := 0.0 if is_shut() else 1.0
	if _gate < 0.0:
		_gate = 0.0 if lift and lift_opens_on_arrival else target
		_redraw_opening()
		return
	if is_equal_approx(_gate, target):
		return
	var rise_time := LIFT_TIME if lift else GATE_TIME
	_gate = move_toward(_gate, target, delta / rise_time) if target > _gate else target
	_redraw_opening()


func _redraw_opening() -> void:
	if _opening != null:
		_opening.queue_redraw()
	if lift:
		queue_redraw()


# Drawn again only when what it shows changes, not every frame.
func _redraw_if_changed() -> void:
	var prompt := KeyBindings.with_key("interact", KEY_PROMPT) if requires_key and _near else ""
	var key := "%s|%s|%s|%s" % [art_state(), _near, _player_has_key(), prompt]
	if key == _drawn_key:
		return
	_drawn_key = key
	queue_redraw()
	_redraw_opening()


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


# Which picture the lift shows for how far its gates have folded open (0 shut, 1 open).
static func lift_state(opened: float) -> String:
	if opened <= 0.0:
		return "closed"
	if opened < 1.0:
		return "half"
	return "open"


# The cage lift's picture for now, standing on the floor; false when its art is missing.
func _draw_lift() -> bool:
	var art := PropArt.state_texture(LIFT_ART, lift_state(gate()))
	if art == null:
		return false
	draw_texture(art, PropArt.standing(art, Vector2(0.0, LIFT_FEET)))
	return true


func _draw() -> void:
	# A door in a wall is drawn by its opening; only the Slip prompt is drawn here, over the room.
	if _side != Vector2i.ZERO:
		_draw_prompt()
		return
	# The way down is the cage lift, which needs no letter: its dial points down.
	if lift and _draw_lift():
		_draw_prompt()
		return
	var art := PropArt.state_texture("door", art_state())
	if art != null:
		PropArt.draw(self, art)
		if not chained and DoorSign.has_sign(_icon):
			# The plaque a door in a wall hangs in its opening (the stairs for the run door and the
			# stairwell), here hung in the doorway of the picture, in place of the bare letter.
			DoorSign.draw(self, SIGN_AT, _icon)
			_draw_prompt()
		elif not chained:
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


# A door standing on the floor (the stairwell, the Waiting Room's run door) keeps its picture and its
# letter or the Arcade's die. Over a picture the letter gets a dark outline, so it reads on any door.
func _draw_icon_and_prompt(outlined := false) -> void:
	if _icon == RoomRules.ARCADE_ICON:
		ArcadeTable.draw_die(self, Vector2.ZERO, 16.0)
	else:
		if outlined:
			draw_string_outline(ThemeDB.fallback_font, Vector2(-5, 6), _icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color.BLACK)
		draw_string(ThemeDB.fallback_font, Vector2(-5, 6), _icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	_draw_prompt()


func _draw_prompt() -> void:
	if requires_key and not locked and _near:
		var prompt := KeyBindings.with_key("interact", KEY_PROMPT) if _player_has_key() else NO_KEY_PROMPT
		var width := ThemeDB.fallback_font.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		draw_string_outline(ThemeDB.fallback_font, Vector2(prompt_x(width, _side), 4), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, Color.BLACK)
		draw_string(ThemeDB.fallback_font, Vector2(prompt_x(width, _side), 4), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("ffd24a"))
