class_name TipCoach
extends Node

# Shows the first run's control tips (FirstRunTips) on the HUD and marks each done the moment he does
# the thing, whether or not its tip was showing. Polls map and interact in _process, since the full loop
# presses actions without events.

const MOVE_TIME := 0.6
const MOVING_SPEED := 4.0

# Set by FloorScene to Progress.mark_tip_done; empty in tests, so nothing is saved.
var mark := Callable()
var done: Dictionary = {}
var _player: Player
var _hud: Hud
var _run: RunState
var _rules: RuleKeeper
var _view: RoomView
var _room_type := ""
var _swings := 0
var _moved := 0.0
var _cleared_one := false
var _was_fighting := false
var _shown := ""


func setup(player: Player, hud: Hud, run: RunState, rules: RuleKeeper) -> void:
	_player = player
	_hud = hud
	_run = run
	_rules = rules
	player.swing_started.connect(_on_swing)
	player.dodge_started.connect(note_done.bind(FirstRunTips.DODGE))
	player.teeth_thrown.connect(note_done.bind(FirstRunTips.THROW))
	player.swing_landed.connect(_on_swing_ended)
	player.swing_missed.connect(_on_swing_missed)
	player.potion_drunk.connect(_on_potion)
	player.bomb_requested.connect(_on_bomb)
	player.active_used.connect(_on_active_used)
	if rules != null:
		rules.era_started.connect(_on_era)


func set_room(view: RoomView, room_type: String) -> void:
	_view = view
	_room_type = room_type


func note_done(id: String) -> void:
	if done.has(id):
		return
	done[id] = true
	if mark.is_valid():
		mark.call(id)
	if _shown == id and _hud != null:
		_shown = ""
		_hud.clear_tip()


func _on_swing() -> void:
	_swings += 1
	note_done(FirstRunTips.SWING)


func _on_swing_ended(heavy: bool, _finisher: bool) -> void:
	if heavy:
		note_done(FirstRunTips.CHARGE)


func _on_swing_missed(heavy: bool) -> void:
	if heavy:
		note_done(FirstRunTips.CHARGE)


func _on_potion(_potion: PotionDef) -> void:
	note_done(FirstRunTips.POTION)


func _on_bomb(_at: Vector2) -> void:
	note_done(FirstRunTips.THERMOS)


func _on_active_used(_item: ItemDef) -> void:
	note_done(FirstRunTips.USE_ITEM)


func _on_era(_era: String) -> void:
	note_done(FirstRunTips.REEL)


func facts() -> Dictionary:
	var fighting := _view != null and is_instance_valid(_view) and _view.is_fighting()
	var watch: RuleWatch = _rules.watch_of(_rules.current_id) if _rules != null else null
	return {
		"fighting": fighting,
		"room_type": _room_type,
		"rule_on": watch != null and watch.is_open() and fighting,
		"announcing": _hud != null and _hud.rule_announcing(),
		"has_reel": _run != null and not _run.held_reel.is_empty(),
		"has_potion": _run != null and _run.potion != null,
		"has_active": _run != null and _run.active != null,
		"hurt": _run != null and _run.health.pills < _run.health.max_pills,
		"has_bomb": _run != null and _run.bombs > 0,
		"swings": _swings,
		"cleared_one": _cleared_one,
	}


func _process(delta: float) -> void:
	if _player == null or _hud == null:
		return
	# The run is over (the floor scene switches Harold off): the line goes and stays gone.
	if _player.process_mode == Node.PROCESS_MODE_DISABLED:
		_shown = ""
		_hud.clear_tip()
		return
	if _player.velocity.length() >= MOVING_SPEED:
		_moved += delta
		if _moved >= MOVE_TIME:
			note_done(FirstRunTips.MOVE)
	if Input.is_action_just_pressed("map"):
		note_done(FirstRunTips.MAP)
	if Input.is_action_just_pressed("interact"):
		note_done(FirstRunTips.INTERACT)
	var now := facts()
	var fighting: bool = now["fighting"]
	if _was_fighting and not fighting:
		_cleared_one = true
	_was_fighting = fighting
	# The rule tip is done once the room it was shown in stops posting its rule.
	if _shown == FirstRunTips.RULE and not now["rule_on"] and not now["announcing"]:
		note_done(FirstRunTips.RULE)
	var next := FirstRunTips.next_tip(done, now)
	if next != _shown:
		_shown = next
		_hud.show_tip(FirstRunTips.text_for(next, ActiveDevice.using_pad, ActiveDevice.family) if not next.is_empty() else "")
