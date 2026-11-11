class_name TipCoach
extends Node

# Shows the first run's control tips (FirstRunTips) on the HUD and marks each done the moment he does
# the thing, whether or not its tip was showing. A tip that stays on screen too long is given up for
# this run (never saved, so it comes back next run), so it cannot starve the tips behind it; a tip
# shown stays at least MIN_SHOW_TIME before another replaces it.

const MOVE_TIME := 0.6
const MOVING_SPEED := 4.0
# Shown seconds after which a tip is passed over for the rest of the run.
const GIVE_UP_TIME := 12.0
const MIN_SHOW_TIME := 2.5
# Swings this far apart (the combo's lock plus its window, with slack) still count as one combo.
const COMBO_GAP := 0.9
const COMBO_SWINGS := 3

# Set by FloorScene to Progress.mark_tip_done; empty in tests, so nothing is saved.
var mark := Callable()
var done: Dictionary = {}
var _player: Player
var _hud: Hud
var _run: RunState
var _rules: RuleKeeper
var _view: RoomView
var _room_type := ""
var _combo_swings := 0
var _since_swing := 0.0
var _moved := 0.0
var _cleared_one := false
var _shown := ""
var _shown_time := 0.0
# Tips given up this run. Not saved.
var _skipped: Dictionary = {}


# FirstRunTips.interacted reaches note_done while this node lives, when he really takes, opens or talks
# to something.
func _enter_tree() -> void:
	FirstRunTips.listener = note_done


func _exit_tree() -> void:
	if FirstRunTips.listener == note_done:
		FirstRunTips.listener = Callable()


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
	# A fight counts as cleared when its room finishes, not when the fight merely pauses between waves
	# or he leaves the room.
	if view != null and not view.finished.is_connected(_on_room_finished):
		view.finished.connect(_on_room_finished)


# The big map: its opening is the MAP tip's thing done.
func watch_map(view: FloorMapView) -> void:
	view.opened_changed.connect(_on_map_changed)


func note_done(id: String) -> void:
	if done.has(id):
		return
	done[id] = true
	if mark.is_valid():
		mark.call(id)
	if _shown == id and _hud != null:
		_shown = ""
		_hud.clear_tip()


func is_skipped(id: String) -> bool:
	return _skipped.has(id)


func _on_swing() -> void:
	_since_swing = 0.0
	_combo_swings += 1
	if _combo_swings >= COMBO_SWINGS:
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


func _on_room_finished() -> void:
	_cleared_one = true


func _on_map_changed(is_open: bool) -> void:
	if is_open:
		note_done(FirstRunTips.MAP)


func facts() -> Dictionary:
	var fighting := _view != null and is_instance_valid(_view) and _view.is_fighting()
	var watch: RuleWatch = _rules.watch_of(_rules.current_id) if _rules != null else null
	var forbidden: Array[String] = []
	if watch != null and watch.state == RuleWatch.State.ACTIVE and fighting:
		forbidden = FirstRunTips.forbidden_by(watch.rule)
	return {
		"fighting": fighting,
		"room_type": _room_type,
		# Only an unbroken rule: once it is broken the Auditor is already there.
		"rule_on": watch != null and watch.state == RuleWatch.State.ACTIVE and fighting,
		# What an active rule forbids is never tipped, even after the rule tip itself is done or given up.
		"forbidden": forbidden,
		"era": _run != null and not _run.era.is_empty(),
		"announcing": _hud != null and _hud.rule_announcing(),
		"has_reel": _run != null and not _run.held_reel.is_empty(),
		"has_potion": _run != null and _run.potion != null,
		"has_active": _run != null and _run.active != null,
		"hurt": _run != null and _run.health.pills < _run.health.max_pills,
		"has_bomb": _run != null and _run.bombs > 0,
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
	_since_swing += delta
	if _since_swing > COMBO_GAP:
		_combo_swings = 0
	var now := facts()
	# The rule tip is done once the room it was shown in stops posting its rule.
	if _shown == FirstRunTips.RULE and not now["rule_on"] and not now["announcing"]:
		note_done(FirstRunTips.RULE)
	if not _shown.is_empty():
		_shown_time += delta
		if _shown_time >= GIVE_UP_TIME:
			_skipped[_shown] = true
			_shown = ""
	var next := FirstRunTips.next_tip(done, now, _skipped)
	# A line on screen stays its minimum time even if its moment has passed.
	if next != _shown and not _shown.is_empty() and _shown_time < MIN_SHOW_TIME and not FirstRunTips.withheld(now).has(_shown):
		next = _shown
	if next != _shown:
		_shown = next
		_shown_time = 0.0
	# Built every frame, so a switch of device or a rebinding changes the words at once.
	var text := FirstRunTips.text_for(_shown, ActiveDevice.using_pad, ActiveDevice.family) if not _shown.is_empty() else ""
	if text != _hud.tip_text():
		_hud.show_tip(text)
