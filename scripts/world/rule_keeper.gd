class_name RuleKeeper
extends Node

# The floor's room rules at play: which room posts one, the notice on first entry, the watch on Harold's
# actions, the whistle for the Auditor, and the stamps on the clear. Names no autoload, so tests load it.

signal rule_broken(view: RoomView)
signal rule_kept(view: RoomView, at: Vector2)

const HOLD_TIME := RuleStamp.ANNOUNCE_TIME
# A step this long or longer counts as moving, for No Loitering.
const STILL_SPEED := 4.0

var current_id := -1
var _watches := {}  # room id -> RuleWatch
var _rule_rooms: Array[int] = []
# Room id -> the view whose finished and prop_broken signals are connected, so a room comes back
# hooked once however often he walks in.
var _hooked := {}
var _seed := ""
var _player: Player
var _hud: Hud
var _run: RunState
var _view: RoomView
var _record_rule := Callable()


func setup(player: Player, hud: Hud, run: RunState, record_rule: Callable) -> void:
	_player = player
	_hud = hud
	_run = run
	_record_rule = record_rule
	player.swing_started.connect(_on_swing)
	player.dodge_started.connect(_on_dodge)
	player.teeth_thrown.connect(_on_throw)
	player.bomb_requested.connect(_on_bomb)
	player.potion_drunk.connect(_on_potion)


# Each new map plans its rule rooms afresh, and forgets the last map's, whose room ids mean other rooms.
func plan_floor(map: FloorMap, depth: int, seed_text: String) -> void:
	_seed = seed_text
	_watches.clear()
	_hooked.clear()
	_rule_rooms = RulePicker.rule_rooms(map, depth, seed_text)


func set_watch(room_id: int, watch: RuleWatch) -> void:
	_watches[room_id] = watch


func watch_of(room_id: int) -> RuleWatch:
	return _watches.get(room_id)


func on_room_entered(view: RoomView, room: FloorRoom, first_visit: bool) -> void:
	_leave_view()
	current_id = room.id
	_view = view
	if first_visit and _rule_rooms.has(room.id) and view.is_fighting() and not _watches.has(room.id):
		var ready := {"has_bomb": _run.bombs > 0, "has_potion": _run.potion != null, "has_breakables": view.has_breakables()}
		_watches[room.id] = RuleWatch.new(RulePicker.pick_rule(_seed, room.id, ready))
	var watch := watch_of(room.id)
	if watch == null or not watch.is_open() or not view.is_fighting():
		return
	if _hooked.get(room.id) != view:
		_hooked[room.id] = view
		view.finished.connect(_on_room_finished.bind(view, room.id), CONNECT_ONE_SHOT)
		view.prop_broken.connect(_on_prop_broken.bind(room.id))
	if not watch.announced:
		watch.announced = true
		_hud.announce_rule(watch.rule)
		view.hold_enemies(HOLD_TIME)
	else:
		_hud.show_rule(watch.rule)
		if watch.state == RuleWatch.State.BROKEN:
			_hud.break_rule()


# A dodge or any other action during the notice still breaks the rule; only loitering waits for it.
func report(action: String) -> void:
	var watch := watch_of(current_id)
	if watch == null or not watch.report(action):
		return
	Sfx.play("rule_whistle")
	if _hud != null:
		_hud.stamp_rule(RuleStamp.KIND_VIOLATION)
		_hud.break_rule()
	if _record_rule.is_valid():
		_record_rule.call(false)
	rule_broken.emit(_view)


func to_dict() -> Dictionary:
	var out := {}
	for id in _watches:
		out[str(id)] = _watches[id].to_dict()
	return {"rooms": _rule_rooms.duplicate(), "watches": out, "seed": _seed}


func load_dict(raw: Dictionary) -> void:
	_watches.clear()
	_rule_rooms.clear()
	_hooked.clear()
	_seed = str(raw.get("seed", ""))
	for id in raw.get("rooms", []):
		_rule_rooms.append(int(id))
	var saved: Dictionary = raw.get("watches", {})
	for key in saved:
		if str(key).is_valid_int() and saved[key] is Dictionary:
			_watches[int(key)] = RuleWatch.from_dict(saved[key])


func _process(delta: float) -> void:
	var watch := watch_of(current_id)
	if watch == null or _player == null or _hud == null or not is_instance_valid(_view):
		return
	if not watch.is_open() or not _view.is_fighting() or _hud.rule_announcing():
		return
	if watch.tick_still(delta, _player.velocity.length() >= STILL_SPEED):
		report(RoomRule.ACTION_LOITER)
	var held := {}
	var button := RoomRule.button_of(watch.rule)
	if not button.is_empty() and InputMap.has_action(button):
		held[button] = Input.is_action_pressed(button)
	_hud.pulse_rule(watch.pulsing(held))


func _on_room_finished(view: RoomView, room_id: int) -> void:
	var watch := watch_of(room_id)
	if watch == null or not watch.is_open():
		return
	var kept := watch.finish() == RuleWatch.State.KEPT
	if _hud != null:
		_hud.stamp_rule(RuleStamp.KIND_GOOD if kept else RuleStamp.KIND_LIFTED)
		_hud.clear_rule()
	if kept:
		if _record_rule.is_valid():
			_record_rule.call(true)
		rule_kept.emit(view, view.last_death_spot())


func _leave_view() -> void:
	if _hud != null:
		_hud.clear_rule()


func _on_swing() -> void:
	report(RoomRule.ACTION_SWING)


func _on_dodge() -> void:
	report(RoomRule.ACTION_DODGE)


func _on_throw() -> void:
	report(RoomRule.ACTION_THROW)


func _on_bomb(_at: Vector2) -> void:
	report(RoomRule.ACTION_BOMB)


func _on_potion(_potion: PotionDef) -> void:
	report(RoomRule.ACTION_POTION)


# Connected once per room with its id bound, so a prop that falls in a room he has left counts for nothing.
func _on_prop_broken(by_harold: bool, room_id: int) -> void:
	if by_harold and room_id == current_id:
		report(RoomRule.ACTION_BREAK)
