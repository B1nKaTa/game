class_name RuleKeeper
extends Node

# The floor's room rules at play: which room posts one, the notice on first entry, the watch on Harold's
# actions, the whistle for the Auditor, and the stamps on the clear. A kept rule leaves a film reel; the
# flashback button readies it at a door into a room whose fight hasn't started, and walking through
# plays that era for the room. Names no autoload but Sfx, so tests load it.

signal rule_broken(view: RoomView)
signal rule_kept(view: RoomView, at: Vector2)
signal era_started(era: String)
signal era_ended(era: String)

const HOLD_TIME := RuleStamp.ANNOUNCE_TIME
# A step this long or longer counts as moving, for No Loitering.
const STILL_SPEED := 4.0
# How near a door his feet must be for the flashback button to ready a reel for it.
const USE_RADIUS := 48.0
const READY_NOTICE := "Memory ready: go through the door"
const HELD_NOTICE := "Already holding a memory"
const WRONG_PLACE := "Use a memory at a door to a room you haven't fought in"
# An era whose room cleared and that waits for its next fight room (Old Projector).
const ERA_WAITING := -2
const FIGHT_ROOMS := [RoomLayout.TYPE_COMBAT, RoomLayout.TYPE_MINI_BOSS, RoomLayout.TYPE_FLOOR_BOSS]

var current_id := -1
# A save's first run: the floor's first rule room is one of its first fights (FloorScene sets it).
var first_run := false
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
# The floor's map and what he has visited of it, for which doors a reel can be readied at.
var _map: FloorMap
var _progress: FloorProgress
# The room a readied reel waits to play in (-1 for none), and the room an era plays in now.
var _readied_door := -1
var _era_room := -1
var _era_rooms_left := 0
var _unlocked: Array = Eras.STARTING
# The wrong-place hint shows once per run (the keeper lasts the run).
var _hinted := false
var _f7_was_down := false


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
	rule_kept.connect(_on_rule_kept)


# A step at STILL_SPEED or more is moving; so is any moment he is held where he stands.
static func counts_as_moving(speed: float, held: bool) -> bool:
	return held or speed >= STILL_SPEED


# Each new map plans its rule rooms afresh, and forgets the last map's, whose room ids mean other rooms.
func plan_floor(map: FloorMap, depth: int, seed_text: String, progress: FloorProgress = null) -> void:
	_seed = seed_text
	_watches.clear()
	_hooked.clear()
	_rule_rooms = RulePicker.rule_rooms(map, depth, seed_text, _run.stats.extra_rule_rooms if _run != null else 0, first_run)
	set_floor(map, progress)


# The map and visits a reel is readied against. A resumed floor sets them here, as it plans no rules.
func set_floor(map: FloorMap, progress: FloorProgress) -> void:
	_map = map
	_progress = progress
	if _readied_door != -1:
		_readied_door = -1
		_set_glow(false)
	# An era never outlives its floor: the room it plays in is gone, so it ends quietly here.
	if _era_room != -1 or (_run != null and not _run.era.is_empty()):
		_stop_era()


func set_unlocked(unlocked: Array) -> void:
	_unlocked = unlocked


func era_waiting() -> bool:
	return _era_room == ERA_WAITING


# A longer flashback (Old Projector) takes the next fight room he walks into for the first time.
func _claim_era_room(room_id: int) -> void:
	if _era_room == ERA_WAITING:
		_era_room = room_id


func readied_door() -> int:
	return _readied_door


func set_watch(room_id: int, watch: RuleWatch) -> void:
	_watches[room_id] = watch


func watch_of(room_id: int) -> RuleWatch:
	return _watches.get(room_id)


# The full loop's checks measure rooms exactly, so it lifts a room's rule before pressing anything there.
func lift_rule(room_id: int) -> void:
	_watches.erase(room_id)
	_rule_rooms.erase(room_id)
	if room_id == current_id and _hud != null:
		_hud.clear_rule()


func on_room_entered(view: RoomView, room: FloorRoom, first_visit: bool) -> void:
	_leave_view()
	current_id = room.id
	_view = view
	# A readied reel plays only through its own door; any other door puts it back in his pocket.
	if _readied_door != -1:
		var going := _readied_door
		_readied_door = -1
		_set_glow(false)
		if going == room.id and first_visit and view.is_fighting() and not _run.held_reel.is_empty():
			_start_era(_run.take_reel(), room.id)
	if first_visit and view.is_fighting():
		_claim_era_room(room.id)
	if first_visit and _rule_rooms.has(room.id) and view.is_fighting() and not _watches.has(room.id):
		var ready := {"has_bomb": _run.bombs > 0, "has_potion": _run.potion != null, "has_breakables": view.has_breakables()}
		_watches[room.id] = RuleWatch.new(RulePicker.pick_rule(_seed, room.id, ready))
	var watch := watch_of(room.id)
	var watching := watch != null and watch.is_open() and view.is_fighting()
	# One finished hook per room serves both the rule and an era playing there.
	if (watching or _era_room == room.id) and _hooked.get(room.id) != view:
		_hooked[room.id] = view
		view.finished.connect(_on_room_finished.bind(view, room.id), CONNECT_ONE_SHOT)
		view.prop_broken.connect(_on_prop_broken.bind(room.id))
	if not watching:
		return
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
	if _record_rule.is_valid():
		_record_rule.call(false)
	if _run != null:
		_run.rules_broken += 1
		_run.effects.event(RunEffects.EVENT_RULE_BROKEN)
	# Fine Print lets the first break of a floor off: no Auditor, a warning stamp.
	var excused := _run != null and _run.effects.excuses_rule_break()
	if _hud != null:
		_hud.stamp_rule(RuleStamp.KIND_WARNING if excused else RuleStamp.KIND_VIOLATION)
		_hud.break_rule()
	if not excused:
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


# The flashback button: in reach of a door into a room whose fight hasn't started, ready the reel for it.
func try_ready_reel(view: RoomView, progress: FloorProgress, map: FloorMap) -> bool:
	if _run == null or _run.held_reel.is_empty() or not _run.era.is_empty():
		return false
	if view == null or not is_instance_valid(view) or view.is_fighting() or progress == null or map == null:
		return false
	for door in view.doors():
		var target := door.target_id()
		if not door.is_within(USE_RADIUS) or door.is_shut() or progress.is_visited(target):
			continue
		var room: FloorRoom = map.room(target) if target >= 0 and target < map.rooms.size() else null
		if room == null or not FIGHT_ROOMS.has(room.room_type):
			continue
		_readied_door = target
		_notice(tr(READY_NOTICE))
		_set_glow(true)
		return true
	if not _hinted:
		_hinted = true
		_notice(tr(WRONG_PLACE))
	return false


func _on_rule_kept(view: RoomView, at: Vector2) -> void:
	if view == null or not is_instance_valid(view):
		return
	for i in 1 + (_run.stats.bonus_kept_reels if _run != null else 0):
		var era := Eras.pick(_unlocked, _seed if i == 0 else "%s:%d" % [_seed, i], current_id)
		view.drop_reel(at, era, _reel_taken.bind(era))


# A reel picked up: his if his pocket is empty, or it fades, since he holds one memory at a time.
func _reel_taken(era: String) -> void:
	if _run.give_reel(era):
		_notice(tr("Reel: %s") % tr(Eras.title(era)))
	else:
		_notice(tr(HELD_NOTICE))


func _start_era(era: String, room_id: int) -> void:
	_run.era = era
	_era_room = room_id
	_era_rooms_left = _run.stats.extra_era_rooms if _run != null else 0
	SepiaFlicker.play(get_parent())
	Sfx.play("reel_flicker")
	if _player != null:
		_player.set_era(era)
	era_started.emit(era)
	if _run != null:
		_run.flashbacks_played += 1
		_run.effects.event(RunEffects.EVENT_FLASHBACK_START)


func _end_era() -> void:
	SepiaFlicker.play(get_parent())
	Sfx.play("reel_flicker")
	var line := tr(Eras.RETURN_LINES[randi() % Eras.RETURN_LINES.size()])
	if _player != null:
		_player.say_line(line)
	# Harold has no speech bubble yet, so his line shows as a notice.
	_notice(line)
	if _run != null:
		_run.effects.event(RunEffects.EVENT_FLASHBACK_END)
	_stop_era()


# Old Harold again, with no flicker or line. The keeper alone sets run.era; the player only his moves.
func _stop_era() -> void:
	var era := ""
	if _run != null:
		era = _run.era
		_run.era = ""
	_era_room = -1
	_era_rooms_left = 0
	if _player != null:
		_player.set_era("")
	era_ended.emit(era)


func _set_glow(on: bool) -> void:
	if _player != null:
		_player.set_sepia_glow(on)


func _notice(text: String) -> void:
	if _hud != null:
		_hud.show_notice(text)


func _poll_reel_keys() -> void:
	if InputMap.has_action("flashback") and Input.is_action_just_pressed("flashback"):
		try_ready_reel(_view, _progress, _map)
	if not DevStart.is_available():
		return
	var down := Input.is_key_pressed(DevStart.REEL_KEY)
	if down and not _f7_was_down:
		_reel_taken(Eras.pick(_unlocked, str(Time.get_ticks_msec()), 0))
	_f7_was_down = down


func _process(delta: float) -> void:
	_poll_reel_keys()
	var watch := watch_of(current_id)
	if watch == null or _player == null or _hud == null or not is_instance_valid(_view):
		return
	if not watch.is_open() or not _view.is_fighting() or _hud.rule_announcing():
		return
	if watch.tick_still(delta, counts_as_moving(_player.velocity.length(), _player.is_held_still())):
		report(RoomRule.ACTION_LOITER)
	var held := {}
	var button := RoomRule.button_of(watch.rule)
	if not button.is_empty() and InputMap.has_action(button):
		held[button] = Input.is_action_pressed(button)
	_hud.pulse_rule(watch.pulsing(held))


func _on_room_finished(view: RoomView, room_id: int) -> void:
	if _era_room == room_id:
		if _era_rooms_left > 0:
			_era_rooms_left -= 1
			_era_room = ERA_WAITING
		else:
			_end_era()
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
		if _run != null:
			_run.rules_kept += 1
			_run.effects.event(RunEffects.EVENT_RULE_KEPT)
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
