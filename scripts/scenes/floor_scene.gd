extends Node2D

# The one place that says which floors each depth offers. Each entry gets an exit at that depth's
# Crossroads, west first and then east, and its FloorDef says when it opens.
const PATHS_BY_DEPTH := {
	1: ["res://data/floors/floor_1.tres", "res://data/floors/cemetery.tres"],
	2: ["res://data/floors/sunset_shores.tres", "res://data/floors/furnace_works.tres"],
	3: ["res://data/floors/funeral_parlour.tres", "res://data/floors/flashback_cinema.tres"],
	4: ["res://data/floors/last_resort_cruise.tres", "res://data/floors/seance_hotline.tres"],
	5: ["res://data/floors/terminal_zero.tres", "res://data/floors/head_office.tres"],
}
# The deepest floor there is. A floor boss falling here ends the run.
const LAST_DEPTH := 5
const CROSSROADS_FLOOR := "res://data/floors/crossroads.tres"
const CROSSROADS_LAYOUT := "res://data/rooms/crossroads/crossroads.tres"
# The landing each depth below the first starts on. Its FloorDef names the floor on the sign and maps.
const LANDINGS_BY_DEPTH := {
	2: "res://data/floors/landing.tres",
	3: "res://data/floors/landing_3.tres",
	4: "res://data/floors/landing_4.tres",
	5: "res://data/floors/landing_5.tres",
}
const LANDING_LAYOUT := "res://data/rooms/landing/landing.tres"
# The Auditor is on no floor's list: only a broken room rule sends him, so the scene names him here.
const AUDITOR_PATH := "res://data/enemies/auditor.tres"
# Pills healed on reaching the landing, up to his maximum.
const LANDING_HEAL := 2
const MESSAGE_TIME := 2.0
const CURSED_NOTICE := "Cursed ticket: tougher enemies, better pay"
const LIFE_JACKET_NOTICE := "Your life jacket keeps you afloat. One pill left."
const FLOOR_CLEARED := "FLOOR CLEARED"
# Shown on arriving back in the Waiting Room after an ending.
const ARRIVAL_NOTICE := "Welcome back. Please take a number."

var player: Player
var is_cleared := false
# Which depth of floors the run has reached: 1 for the first Crossroads and its floors, then one more
# for each stairwell taken.
var _depth := 1
var is_over := false
var _map: FloorMap
var _floor_def: FloorDef
var _run: RunState
var _rng := RandomNumberGenerator.new()
var _room_view: RoomView
var _current_id := -1
var _progress: FloorProgress
var _room_views := {}
var _hud: Hud
var _feedback: CombatFeedback
var _mini_map: FloorMapView
var _big_map: FloorMapView
var _camera: Camera2D
# The Arcade overlay while it is open, and the frame it last closed on, so the press that closes it
# never opens it again at once.
var _card_panel: CardTablePanel
var _card_panel_closed_frame := -1
# What the Purser's Bon Voyage Bag put in this run: a potion's id, BonVoyage.THERMOS, or "" for none.
var _bon_voyage := ""
# What the map is, for the checkpoint: the run's first Crossroads, a landing, or a floor built from
# _floor_seed and entered from the side _exit_side.
const MAP_START := "start"
const MAP_LANDING := "landing"
const MAP_FLOOR := "floor"
const RESUMED_NOTICE := "Your run picks up where you left it."
var _map_kind := MAP_START
var _floor_seed := ""
var _exit_side := Vector2i.ZERO
# The room Grandpa came into the current room from, so a resumed run puts him on that door.
var _arrived_from := -1
# Snapshots of cleared rooms from a checkpoint, by room id, to rebuild them from.
var _restored := {}
var _resumed := false
# The last cleared room a checkpoint was written in on this map, and the room he came into it from.
var _safe_room := -1
var _safe_from := -1
# The Pension the room he stands in has paid since he came in, left out of a checkpoint written while
# its fight is still on.
var _room_paid := 0
# How long this run has gone, for the Game tab's run timer. It stops while the game is paused.
var _run_time := 0.0
# The pause menu while it is open, and the frame it closed on, so the Esc that closed it never opens it.
var _pause: PauseMenu
var _pause_closed_frame := -1
# Harold's case file while it is open (Tab), and the frame it closed on, so the key that closed it
# never opens it again or pauses.
var _case_file: CaseFile
var _case_closed_frame := -1
# Counts every room entry, so a won Arcade game knows which visit it was on (RunState.note_arcade_win).
var _visit := 0
# The run as it stood when the Chairman fell, for EndingRules, or empty when he has not. The ending
# plays after the run's last message, before the Waiting Room.
var _ending_snapshot := {}
# A scene to play before the last message: Augustine's, on a win over him.
var _scene_before_message: Array = []
var _scene_first_time := false
# Whether Augustine had been beaten before this run, so his whole scene shows only the first time.
var _augustine_seen_before := false
# The scene playing, if any, and the ending it is.
var _cutscene: CutscenePlayer
var _ending_id := ""
# The floor's room rules. Made first in _ready, so a resumed run can load them back before any room.
var _rules: RuleKeeper


func _ready() -> void:
	# Harold and the room's bodies are drawn in order of where their feet are (RoomView sorts too).
	y_sort_enabled = true
	_rng.randomize()
	_rules = RuleKeeper.new()
	add_child(_rules)
	# An interrupted run comes back from its checkpoint, and never starts a new run on the way.
	var resume := Progress.resume
	Progress.resume = {}
	_resumed = not resume.is_empty() and not Progress.is_dev_run() and _resume_map(resume)
	if not resume.is_empty() and not _resumed:
		# A checkpoint this build cannot rebuild is no run, so it goes and is never offered again.
		Progress.clear_checkpoint()
	if _resumed:
		_resume_run(resume)
	else:
		_start_run()
	_hud = Hud.new()
	_hud.setup(_run)
	add_child(_hud)
	_hud.set_pension(Progress.data.pension)
	Progress.pension_changed.connect(_hud.set_pension)
	if _resumed:
		_hud.show_notice(tr(RESUMED_NOTICE))
	else:
		_show_start_notes()
		_start_map()
	_camera = Camera2D.new()
	add_child(_camera)
	_feedback = CombatFeedback.new()
	_feedback.setup(_camera)
	add_child(_feedback)
	player = Player.new()
	player.setup(_run)
	player.died.connect(_on_player_died)
	player.hurt.connect(_on_player_hurt)
	_run.health.rescued.connect(_on_rescued)
	player.bomb_requested.connect(_on_bomb_requested)
	player.show_crosshair = true
	var ctx := _run.effects.ctx
	ctx.player = player
	ctx.hud = _hud
	ctx.feedback = _feedback
	_run.effects.combo_formed.connect(_on_combo_formed)
	Input.mouse_mode = Settings.cursor_mode(true)
	add_child(player)
	_rules.setup(player, _hud, _run, Progress.record_rule)
	_rules.set_unlocked(Progress.data.eras_unlocked)
	_rules.rule_broken.connect(_on_rule_broken)
	_feedback.watch_player(player)
	var glow := Lighting.make_light(Color(1.0, 0.85, 0.6), 0.7, 0.8)
	player.add_child(glow)
	if not _resumed:
		_progress = FloorProgress.new(_map)
	_mini_map = _add_map_view(false)
	_big_map = _add_map_view(true)
	_big_map.opened_changed.connect(_on_big_map_changed)
	_big_map.combo_names = _run.effects.combo_names()
	# An item taken mid-floor can change what the maps show (Floor Plan, Fortune Teller's Card).
	_run.changed.connect(_refresh_map_items)
	_apply_game_settings()
	Settings.changed.connect(_apply_game_settings)
	PadWatch.pad_lost.connect(_on_pad_lost)
	if _resumed:
		_enter_resumed_room(resume)
	else:
		_enter_room(_map.start_id)
		# The run's start checkpoint, so quitting at the first Crossroads keeps what start_run used up.
		_write_checkpoint_soon()


func _start_run() -> void:
	Progress.start_run()
	_augustine_seen_before = Progress.data.bosses_beaten.has(EndingRules.AUGUSTINE)
	_run = Progress.make_run()
	# Before the first room is built, so every enemy of a cursed run is spawned tougher.
	_run.cursed = Progress.take_cursed_run()
	_wire_item_pension()
	_run.extra_table_visits = Progress.table_wins_before_run
	Progress.table_wins_before_run = 0
	var crafted := Progress.take_crafted_item()
	if crafted != null:
		_run.add_item(crafted)
	var brewed := Progress.take_brewed_potion()
	if brewed != null:
		_run.give_potion(brewed)
	# After the brew, so a brew always keeps its slot, and before a dev run's kit, which sets its own.
	if BonVoyage.is_packed(Progress.data):
		_bon_voyage = BonVoyage.pack(_run, Content.potions_for_sale(), _rng.randf(), _rng.randf())
	if Progress.is_dev_run():
		DevStart.apply_kit(_run, Content.items())


# Items pay and spend through here, so their Pension counts as the run's, as a coin's does. Before any
# item is added, so an item's on_gain can already pay.
func _wire_item_pension() -> void:
	_run.effects.ctx.pay_pension = _on_pension_earned
	_run.effects.ctx.spend_pension = Progress.spend


func _show_start_notes() -> void:
	var start_notes := PackedStringArray()
	if _run.has_perk(Mementos.START_PENSION_PERK):
		Progress.add_pension(Mementos.START_PENSION)
		start_notes.append("Your name badge still works: +%d Pension" % Mementos.START_PENSION)
	if not _bon_voyage.is_empty():
		start_notes.append(BonVoyage.notice(_bon_voyage, Content.potions_for_sale()))
	if not start_notes.is_empty():
		_hud.show_notice(".  ".join(start_notes))
	# Shown after the badge's notice, in its place, since it matters more.
	if _run.cursed:
		_hud.show_notice(CURSED_NOTICE)


func _start_map() -> void:
	if Progress.is_dev_run():
		# A dev run skips straight to its landing, with that depth's Crossroads beyond it.
		_depth = Progress.dev_start_depth
		_floor_def = load(LANDINGS_BY_DEPTH[_depth])
		_map = _landing_map()
		_map_kind = MAP_LANDING
	else:
		_floor_def = load(CROSSROADS_FLOOR)
		_map = FloorMap.with_only_crossroads(load(CROSSROADS_LAYOUT))
		_map_kind = MAP_START
	# A landing or the first Crossroads posts no rules.
	_rules.plan_floor(FloorMap.new(), _depth, "")


# --- The run checkpoint: written as rooms are cleared, on landings and on entering a floor ---

# Writes the run as it stands into the slot's run.json. A dev run and a run that is over write nothing.
# The first Crossroads writes one too, since start_run has already used up the brew, the crafted item,
# a cursed ticket and the Bon Voyage pack by then.
func write_checkpoint() -> bool:
	if is_over or Progress.is_dev_run() or _run == null or _current_id < 0:
		return false
	# He comes back in the last room he cleared, so a fight going on now starts over when he walks back in.
	var room := _current_id
	var from := _arrived_from
	# What this room paid while its fight is still on comes back with the fight, so it is left out.
	var room_paid := 0
	if _room_view != null and _room_view.is_finished():
		_safe_room = room
		_safe_from = from
	else:
		room_paid = _room_paid
		if _safe_room >= 0:
			room = _safe_room
			from = _safe_from
	var ending := RunCheckpoint.ending_to_dict(_run)
	ending["pension_earned"] = maxi(_run.pension_earned - room_paid, 0)
	var rooms := {}
	for id: int in _room_views:
		# Untyped: a typed assignment fails on a freed view before is_instance_valid can skip it.
		var view = _room_views[id]
		if is_instance_valid(view) and view.is_finished() and not view is CrossroadsView:
			rooms[str(id)] = view.snapshot()
	var checkpoint := {
		"depth": _depth,
		"floor": _floor_def.resource_path,
		"kind": _map_kind,
		"seed": _floor_seed,
		"exit_side": [_exit_side.x, _exit_side.y],
		"visited": _progress.visited_ids().duplicate(),
		"room": room,
		"from": from,
		"rooms": rooms,
		"run": RunCheckpoint.run_to_dict(_run),
		"ending": ending,
		"rng": RunCheckpoint.rng_to_dict(_rng),
		"run_earned": ending["pension_earned"],
		# Put back on resume, so coins banked after this moment never pay twice. Condolences are not.
		"pension": RunCheckpoint.pension_to_save(Progress.data, room_paid),
		"bon_voyage": _bon_voyage,
		"is_cleared": is_cleared,
		"bosses": int(Progress.last_run.get("bosses", 0)),
		"run_time": snappedf(_run_time, 0.1),
		"rules": _rules.to_dict(),
	}
	return Progress.write_checkpoint(checkpoint)


func _write_checkpoint_soon() -> void:
	write_checkpoint.call_deferred()


# Rebuilds the checkpoint's map: a landing as every landing is, or the floor from its seed with the
# Crossroads beside its start. False when the file names something this build cannot rebuild.
func _resume_map(resume: Dictionary) -> bool:
	var depth := int(resume.get("depth", 0))
	var floor_path := str(resume.get("floor", ""))
	if not PATHS_BY_DEPTH.has(depth) or not ResourceLoader.exists(floor_path):
		return false
	var def := load(floor_path) as FloorDef
	if def == null:
		return false
	var kind := str(resume.get("kind", ""))
	var map: FloorMap
	if kind == MAP_START:
		# The run's first Crossroads, alone, as _start_map builds it.
		if depth != 1 or floor_path != CROSSROADS_FLOOR:
			return false
		map = FloorMap.with_only_crossroads(load(CROSSROADS_LAYOUT))
	elif kind == MAP_LANDING:
		map = _landing_map()
	elif kind == MAP_FLOOR:
		map = RunCheckpoint.build_floor(def, str(resume.get("seed", "")))
		if map == null:
			return false
		var side: Array = resume.get("exit_side", [0, 0])
		_exit_side = Vector2i(int(side[0]), int(side[1]))
		var crossroads := map.attach_crossroads(load(CROSSROADS_LAYOUT), -_exit_side)
		if crossroads == null:
			return false
		# A run on a retired path comes back at the start of its replacement's floor.
		if bool(resume.get(PathMigration.FLOOR_START, false)):
			RunCheckpoint.restart_floor(resume, map, crossroads.id)
		_floor_seed = str(resume.get("seed", ""))
	else:
		return false
	var room := int(resume.get("room", -1))
	if room < 0 or room >= map.rooms.size():
		return false
	_depth = depth
	_floor_def = def
	_map = map
	_map_kind = kind
	_progress = FloorProgress.new(map)
	for id in resume.get("visited", []):
		if int(id) >= 0 and int(id) < map.rooms.size():
			_progress.enter(int(id))
	var rooms: Dictionary = resume.get("rooms", {})
	for key in rooms:
		if str(key).is_valid_int() and rooms[key] is Dictionary and rooms[key].get("cleared", false):
			_restored[int(key)] = rooms[key]
	is_cleared = bool(resume.get("is_cleared", false))
	# Before the first room is entered, so a rule room he saw already gives no second notice. An older
	# checkpoint has no rules, and its floor posts none.
	var rules: Variant = resume.get("rules", {})
	_rules.load_dict(rules if rules is Dictionary else {})
	_rules.set_floor(map, _progress)
	return true


# The run itself comes back on a run made fresh from the save, as Progress.make_run makes any run, and
# Progress.start_run is never called again, so the run count and the ticket stay as they were.
func _resume_run(resume: Dictionary) -> void:
	_run = Progress.make_run()
	_wire_item_pension()
	RunCheckpoint.apply_run(_run, resume.get("run", {}), Content.items())
	RunCheckpoint.apply_rng(_rng, resume.get("rng", {}))
	# The ending's tracking, with the Pension the rooms paid from run_earned for older files.
	RunCheckpoint.apply_ending(_run, resume.get("ending", {"pension_earned": resume.get("run_earned", 0)}))
	# The save's Pension as the checkpoint kept it, after the items are back, so one that pays on gain
	# never pays twice. Condolences stay as they are, since a first boss beat's Condolences must stay
	# paid (RunCheckpoint.apply_pension).
	Progress.restore_pension(resume)
	_augustine_seen_before = Progress.data.bosses_beaten.has(EndingRules.AUGUSTINE)
	_bon_voyage = str(resume.get("bon_voyage", ""))
	_run_time = float(resume.get("run_time", 0.0))
	Progress.last_run = {"died": false, "bosses": int(resume.get("bosses", 0))}


# Grandpa arrives in the room he was last in, by the door he first came in through.
func _enter_resumed_room(resume: Dictionary) -> void:
	var from := int(resume.get("from", -1))
	_current_id = from if from >= 0 and from < _map.rooms.size() else -1
	_enter_room(int(resume.get("room", _map.start_id)))
	_write_checkpoint_soon()


func debug_resumed() -> bool:
	return _resumed


func debug_map() -> FloorMap:
	return _map


func debug_progress() -> FloorProgress:
	return _progress


func debug_current_id() -> int:
	return _current_id


func debug_room_view() -> RoomView:
	return _room_view


func debug_feedback() -> CombatFeedback:
	return _feedback


func debug_camera() -> Camera2D:
	return _camera


func debug_big_map() -> FloorMapView:
	return _big_map


func debug_mini_map() -> FloorMapView:
	return _mini_map


func debug_floor_def() -> FloorDef:
	return _floor_def


func debug_depth() -> int:
	return _depth


func debug_bon_voyage() -> String:
	return _bon_voyage


func debug_card_panel() -> CardTablePanel:
	return _card_panel


# Walks out of the Crossroads along a path at once, for checks that are not about the walking.
func debug_choose_path(index: int) -> void:
	_choose_path(index)


# The maps show what the held items let them: the whole floor's rooms with the Floor Plan, and with the
# Fortune Teller's Card the boss rooms and, on the big map, who waits in them.
func _refresh_map_items() -> void:
	if _mini_map == null or _big_map == null:
		return
	var names := FloorMapView.boss_names_for(_floor_def) if _run.stats.names_bosses else {}
	for view: FloorMapView in [_mini_map, _big_map]:
		view.show_plan = _run.stats.shows_floor_plan
		view.boss_names = names


func _add_map_view(is_big: bool) -> FloorMapView:
	var view := FloorMapView.new()
	view.setup(_map, _progress, is_big, _floor_def.display_name)
	# The views last the whole run, through every path and floor, so this is set once.
	view.show_secrets = _run.stats.reveals_secrets
	_hud.add_child(view)
	return view


func _path_defs() -> Array[FloorDef]:
	var defs: Array[FloorDef] = []
	for path: String in PATHS_BY_DEPTH[_depth]:
		defs.append(load(path))
	return defs


# Builds the chosen floor only now, and brings the Crossroads along as a small room on its map.
func _choose_path(index: int) -> void:
	if is_over or _room_view == null or not _room_view is CrossroadsView:
		return
	var def: FloorDef = _path_defs()[index]
	if not def.is_open_for(Progress.data):
		return
	# Built from a seed of its own, so a resumed run can build the very same floor again.
	var seed_text := RunCheckpoint.new_seed(_rng)
	var map := RunCheckpoint.build_floor(def, seed_text)
	if map == null:
		_end_run("This floor could not be built. Returning to the Waiting Room.")
		return
	_floor_seed = seed_text
	_run.seeds.append(seed_text)
	_restored.clear()
	_safe_room = -1
	_exit_side = _room_view.side_of_path(index)
	_map_kind = MAP_FLOOR
	var exit_side: Vector2i = _room_view.side_of_path(index)
	var crossroads := map.attach_crossroads(_map.room(_current_id).layout, -exit_side)
	var leaving := _room_view
	_room_views.clear()
	_floor_def = def
	_map = map
	_run.paths_taken[_depth] = def.id
	# A new floor, a new boss room: only the pills lost in this floor's boss room count.
	_run.boss_room_pill_lost = false
	_progress = FloorProgress.new(map)
	_progress.enter(crossroads.id)
	_rules.plan_floor(map, def.depth, seed_text, _progress)
	# Each floor fills the Life Jacket again.
	_run.start_floor()
	_mini_map.setup(map, _progress, false, def.display_name)
	_big_map.setup(map, _progress, true, def.display_name)
	_current_id = crossroads.id
	_enter_room(map.start_id)
	leaving.queue_free()
	_run.effects.floor_start()
	_write_checkpoint_soon()


func _on_big_map_changed(is_open: bool) -> void:
	_mini_map.visible = not is_open
	player.cancel_charge()


func _enter_room(target_id: int) -> void:
	_hud.hide_boss_bar()
	player.recall_teeth()
	player.end_push()
	# A hold from the room he leaves (On the Line) stays there too.
	player.end_leash()
	var from_id := _current_id
	if _room_view != null:
		# Before anything leaves the room, so an item can still take from it (Moving Boxes).
		_run.effects.room_leave(_room_view)
		_room_view.clear_passing_effects()
		remove_child(_room_view)
	var first_visit := not _progress.is_visited(target_id)
	_visit += 1
	_progress.enter(target_id)
	_arrived_from = from_id
	_current_id = target_id
	_room_paid = 0
	# Before the room is added, since a boss that appears on arrival starts its own music.
	_play_room_music()
	_room_view = _room_views.get(target_id)
	if _room_view == null:
		_room_view = _make_room_view(_map.room(target_id))
		_room_views[target_id] = _room_view
	add_child(_room_view)
	move_child(_room_view, 0)
	_room_view.refresh_doors()
	# A boss still standing in a room he comes back to (after a teleport out) keeps his bar; it was
	# shown only when he spawned, and leaving hid it.
	_show_standing_boss()
	# A room with a fight in it shuts its doors behind him.
	if _room_view.is_fighting():
		Sfx.play("door_close")
	# A cleared floor boss's room keeps its way down, a resumed one too.
	if is_cleared and _map.room(target_id).room_type == RoomLayout.TYPE_FLOOR_BOSS and _floor_def.depth < LAST_DEPTH:
		_room_view.add_stairwell()
	player.global_position = Player.arrival_position(_progress.arrival_cell(target_id, from_id))
	# Where the Eternal Warranty brings him back to.
	_run.effects.ctx.arrival = player.global_position
	_run.effects.ctx.has_arrival = true
	_refresh_map_items()
	_mini_map.set_current(target_id)
	_big_map.set_current(target_id)
	_follow_player()
	if first_visit:
		_tip_hat(_map.room(target_id))
	_run.effects.ctx.room = _room_view
	_run.effects.room_enter(_room_view)
	_rules.on_room_entered(_room_view, _map.room(target_id), first_visit)


# The whistle blew: the Auditor walks in by the door Harold came in by (none in a start room, where
# the room picks a spot of its own).
func _on_rule_broken(view: RoomView) -> void:
	if view != _room_view or is_over:
		return
	view.call_auditor(load(AUDITOR_PATH), view.door_to(_arrived_from))


# The room's music: its path's theme, the landing's, or the Arcade's. A boss's music starts when it
# appears, and this brings the room's back once it falls.
func _play_room_music() -> void:
	if not is_over:
		MusicPlayer.play(MusicRules.room(_floor_def.id, _map.room(_current_id).room_type))


# The top hat memento: a pill on first walking into a boss room.
func _tip_hat(room: FloorRoom) -> void:
	if not _run.has_perk(Mementos.BOSS_ROOM_PILL_PERK):
		return
	if room.room_type != RoomLayout.TYPE_MINI_BOSS and room.room_type != RoomLayout.TYPE_FLOOR_BOSS:
		return
	_run.health.heal(Mementos.BOSS_ROOM_HEAL)
	_hud.show_notice("You tip your hat. +%d pill" % Mementos.BOSS_ROOM_HEAL)


# The Game tab's options, read again whenever Options is changed from the pause menu.
func _apply_game_settings() -> void:
	_feedback.shake_enabled = Settings.game("screen_shake")
	_feedback.hit_stop_enabled = Settings.game("hit_stop")
	_run.heals_at_full = Settings.game("heal_at_full")
	player.mouse_aim = Settings.game("mouse_aim")
	_mini_map.modulate.a = Settings.game("minimap_opacity") / 100.0
	_hud.show_timer = Settings.game("run_timer")
	_hud.set_run_time(_run_time)


# The scene pauses with the tree, so a paused big map adds no play time.
func _process(delta: float) -> void:
	_follow_player()
	if not is_over:
		_run.play_time += delta
		_run_time += delta
	_hud.set_run_time(_run_time)
	var fighting := _room_view != null and _room_view.is_fighting()
	_mini_map.visible = GameSettings.minimap_visible(Settings.game("hide_minimap_in_combat"), fighting, _big_map.is_open())
	# The small map lies over the play area's top right: it fades while a warning lies under it.
	var under_map := MapFade.world_rect(get_viewport().get_canvas_transform())
	_hud.set_map_alpha(MapFade.step(_hud.map_alpha(), MapFade.covered(_room_view, under_map), delta), _mini_map)
	var frame := Engine.get_process_frames()
	if frame != _pause_closed_frame and frame != _big_map.closed_frame and frame != _case_closed_frame and Input.is_action_just_pressed("pause"):
		_on_pause_key()
	if frame != _case_closed_frame and Input.is_action_just_pressed("case_file"):
		_open_case_file()
	# B backs out of a card table, as its Leave does, but never opens the pause menu.
	if _card_panel != null and Input.is_action_just_pressed(PadInput.BACK_ACTION):
		_card_panel.leave()


# Esc closes whatever is open first: an Arcade table, then the big map. Only then does it pause.
func _on_pause_key() -> void:
	if is_over or _pause != null:
		return
	if _card_panel != null:
		_card_panel.leave()
		return
	if _big_map.is_open():
		_big_map.set_open(false)
		return
	_open_pause()


# Unplugging the pad he plays with pauses the run, over the big map or a card table if one is open.
func _on_pad_lost() -> void:
	if is_over or _pause != null:
		return
	_close_case_file()
	if _big_map.is_open():
		_big_map.set_open(false)
	_open_pause()


# Tab: the case file on the Harold tab, over nothing else that is open. It pauses the game itself.
func _open_case_file() -> void:
	if is_over or _pause != null or _card_panel != null or _case_file != null or _big_map.is_open() or debug_cutscene() != null:
		return
	Sfx.play("pause_open")
	player.cancel_charge()
	_case_file = CaseFile.new()
	_case_file.setup(_run, case_info(), Progress.data)
	_case_file.closed.connect(_close_case_file)
	add_child(_case_file)
	Input.mouse_mode = Settings.cursor_mode(false)


func _close_case_file() -> void:
	if _case_file == null:
		return
	Sfx.play("pause_close")
	_case_file.queue_free()
	_case_file = null
	_case_closed_frame = Engine.get_process_frames()
	get_tree().paused = false
	Input.mouse_mode = Settings.cursor_mode(_card_panel == null)


func debug_case_file() -> CaseFile:
	return _case_file


func debug_open_case_file() -> void:
	_open_case_file()


# What the case file's Harold tab says of the floor, the route and the time.
func case_info() -> Dictionary:
	var route: PackedStringArray = []
	var depths := _run.paths_taken.keys()
	depths.sort()
	for depth in depths:
		for path: String in PATHS_BY_DEPTH.get(int(depth), []):
			var def := load(path) as FloorDef
			if def != null and def.id == str(_run.paths_taken[depth]):
				route.append(def.display_name)
	return {
		"floor": "%s (floor %d)" % [_floor_def.display_name, _depth] if _floor_def != null else "",
		"route": " > ".join(route) if not route.is_empty() else "-",
		"time": _run_time,
	}


func _open_pause() -> void:
	Sfx.play("pause_open")
	_pause = PauseMenu.new()
	_pause.setup(true)
	_pause.resumed.connect(_close_pause)
	_pause.quit_wanted.connect(_on_pause_quit)
	add_child(_pause)
	player.cancel_charge()
	get_tree().paused = true
	Input.mouse_mode = Settings.cursor_mode(false)


func _close_pause() -> void:
	if _pause == null:
		return
	Sfx.play("pause_close")
	_pause.queue_free()
	_pause = null
	_pause_closed_frame = Engine.get_process_frames()
	get_tree().paused = false
	Input.mouse_mode = Settings.cursor_mode(_card_panel == null)


# Save and Quit: the checkpoint first, so the run waits in its slot.
func _on_pause_quit(to_desktop: bool) -> void:
	write_checkpoint()
	if to_desktop:
		get_tree().quit()
	else:
		Game.quit_to_title()


func debug_pause_menu() -> PauseMenu:
	return _pause


# Shake moves the camera through its offset, so following never fights it.
func _follow_player() -> void:
	if _camera == null or _current_id == -1:
		return
	var room_size := Vector2(_map.room(_current_id).layout.size_in_cells()) * RoomBackdrop.TILE
	_camera.position = RoomCamera.center_for(room_size, player.camera_focus(), RoomBackdrop.VIEW_SIZE)


func _make_room_view(room: FloorRoom) -> RoomView:
	var view: RoomView
	if room.room_type == RoomLayout.TYPE_CROSSROADS:
		view = CrossroadsView.new()
		view.setup_paths(_path_defs(), Progress.data)
		view.door_entered.connect(func(index: int): _choose_path.call_deferred(index))
	else:
		view = RoomView.new()
		view.door_entered.connect(func(id: int): _enter_room.call_deferred(id))
		view.stairwell_entered.connect(func(): _go_down.call_deferred())
		view.arcade_game_wanted.connect(_open_card_table)
		view.arcade_won.connect(_on_arcade_won)
	view.setup(room, _map, _floor_def, _run, player, _rng, _progress, Progress)
	if _restored.has(room.id):
		view.restore = _restored[room.id]
	view.finished.connect(_write_checkpoint_soon)
	view.notice.connect(_hud.show_notice)
	view.pension_earned.connect(_on_room_pension)
	view.floor_cleared.connect(_on_floor_cleared)
	view.boss_spawned.connect(_on_boss_spawned)
	_feedback.watch_room(view)
	return view


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Rooms the player has left are out of the tree, so nothing else frees them.
	for view: RoomView in _room_views.values():
		if is_instance_valid(view) and not view.is_inside_tree():
			view.free()


func _on_bomb_requested(at: Vector2) -> void:
	_room_view.place_bomb(at)


# An Arcade table opens its overlay. Grandpa holds still, as at a Waiting Room counter, the mouse shows
# for the buttons and the big map waits, but the room itself carries on, safe as it is.
func _open_card_table(table: ArcadeTable) -> void:
	if is_over or _card_panel != null or Engine.get_process_frames() == _card_panel_closed_frame:
		return
	if _big_map.is_open() or not is_instance_valid(table):
		return
	_card_panel = CardTablePanel.new()
	_card_panel.setup(table, _room_view, _rng)
	_card_panel.closed.connect(_close_card_table)
	add_child(_card_panel)
	player.cancel_charge()
	player.set_physics_process(false)
	_big_map.enabled = false
	Input.mouse_mode = Settings.cursor_mode(false)


func _close_card_table() -> void:
	if _card_panel == null:
		return
	_card_panel.queue_free()
	_card_panel = null
	_card_panel_closed_frame = Engine.get_process_frames()
	if is_over:
		return
	player.set_physics_process(true)
	_big_map.enabled = true
	Input.mouse_mode = Settings.cursor_mode(true)


func _on_pension_earned(amount: int) -> void:
	_run.pension_earned += amount
	Progress.add_pension(amount)


# A room's coins and clear pay, counted for the checkpoint as well (see write_checkpoint).
func _on_room_pension(amount: int) -> void:
	_room_paid += amount
	_on_pension_earned(amount)


func _on_arcade_won() -> void:
	_run.note_arcade_win(_visit)


# Whether the Chairman's room cost him a pill, for Under New Management.
func _on_player_hurt() -> void:
	_run.hits_taken += 1
	if _current_id != -1 and _map.room(_current_id).room_type == RoomLayout.TYPE_FLOOR_BOSS:
		_run.boss_room_pill_lost = true


func _on_rescued() -> void:
	_hud.show_notice(LIFE_JACKET_NOTICE)


func _on_player_died() -> void:
	Progress.last_run["died"] = true
	if not is_over:
		MusicPlayer.play(MusicRules.game_over(), 0.3)
	var parachute := _run.parachute_pay(_run.pension_earned)
	if parachute > 0 and not is_over:
		Progress.add_pension(parachute)
		_hud.show_notice("Golden Parachute: +%d Pension" % parachute)
	_end_run("You died again. Please take a number.")

func _on_floor_cleared() -> void:
	if is_cleared:
		return
	is_cleared = true
	# Merchants open on floors cleared, so the clear is saved before anything else can end the run.
	Progress.record_floor_cleared(_floor_def.depth, _floor_def.id)
	if _run.cursed:
		Progress.add_condolences(ProgressData.CURSED_FLOOR_CONDOLENCES)
		_hud.show_notice("Cursed ticket: +%d Condolences" % ProgressData.CURSED_FLOOR_CONDOLENCES)
	_continue_after_floor()


# Every path ends here, whichever floor was taken. Above the last depth the boss room opens a stairwell
# down, and on the last one the run ends. A deeper floor slots in here: raise LAST_DEPTH, list its paths
# in PATHS_BY_DEPTH, give it a landing in LANDINGS_BY_DEPTH, and every path above reaches it.
func _continue_after_floor() -> void:
	if _floor_def.depth < LAST_DEPTH:
		_room_view.add_stairwell()
		return
	MusicPlayer.stop()
	# Read here rather than when the boss falls, since the room hears the fall first and clears.
	var boss_id := _floor_def.floor_boss.id if _floor_def.floor_boss != null else ""
	if boss_id == EndingRules.CHAIRMAN:
		_ending_snapshot = _run.ending_snapshot()
	elif boss_id == EndingRules.AUGUSTINE:
		_scene_first_time = not _augustine_seen_before
		_scene_before_message = CutsceneSteps.for_ending(EndingRules.AUGUSTINE, 0 if _scene_first_time else 1)
	_end_run(FLOOR_CLEARED)


# Takes the stairwell: a safe landing that heals him, with the next Crossroads beyond it. Everything he
# carries lives on the run, so it comes along. Only what belonged to the floor above stays behind.
func _go_down() -> void:
	if is_over or _depth >= LAST_DEPTH:
		return
	_depth += 1
	is_cleared = false
	var leaving := _room_view
	for view: RoomView in _room_views.values():
		if view != leaving and is_instance_valid(view) and not view.is_inside_tree():
			view.free()
	_room_views.clear()
	_floor_def = load(LANDINGS_BY_DEPTH[_depth])
	_map = _landing_map()
	_progress = FloorProgress.new(_map)
	_mini_map.setup(_map, _progress, false, _floor_def.display_name)
	_big_map.setup(_map, _progress, true, _floor_def.display_name)
	_current_id = -1
	_map_kind = MAP_LANDING
	_floor_seed = ""
	_rules.plan_floor(FloorMap.new(), _depth, "")
	_restored.clear()
	_safe_room = -1
	_enter_room(_map.start_id)
	leaving.queue_free()
	Sfx.play("landing_arrive")
	var missing := _run.health.max_pills - _run.health.pills
	_run.health.heal(landing_heal())
	var healed := mini(landing_heal(), missing)
	_hud.show_notice("You catch your breath. +%d pills" % healed if healed > 0 else "You catch your breath.")
	# After the landing's own heal, so an item's landing rule has the last word.
	_run.effects.floor_start()


# A combo forms: its banner shows, and the paused map lists it from now on.
func _on_combo_formed(combo: ComboDef) -> void:
	_hud.show_combo(combo.display_name)
	_big_map.combo_names = _run.effects.combo_names()



# What a landing heals: LANDING_HEAL, and one more with the boarding pass.
func landing_heal() -> int:
	return LANDING_HEAL + (Mementos.LANDING_EXTRA if _run.has_perk(Mementos.LANDING_PERK) else 0)


func _landing_map() -> FloorMap:
	return FloorMap.with_landing_and_crossroads(load(LANDING_LAYOUT), load(CROSSROADS_LAYOUT))


func _end_run(message: String) -> void:
	if is_over:
		return
	is_over = true
	# Death, FLOOR CLEARED or anything else that ends the run ends its checkpoint too.
	Progress.clear_checkpoint()
	_log_run(message)
	_close_case_file()
	if _card_panel != null:
		_card_panel.leave()
	if _big_map != null:
		_big_map.enabled = false
		_big_map.set_open(false)
	_hud.hide_boss_bar()
	if player != null:
		player.recall_teeth()
		player.process_mode = Node.PROCESS_MODE_DISABLED
	if _room_view != null:
		_room_view.process_mode = Node.PROCESS_MODE_DISABLED
	# No rule breaks, and no Auditor comes, once the run is over.
	_rules.process_mode = Node.PROCESS_MODE_DISABLED
	if not _scene_before_message.is_empty():
		await _play_cutscene(_scene_before_message, _scene_first_time)
		_cutscene.queue_free()
		_cutscene = null
	_hud.show_message(message)
	await get_tree().create_timer(MESSAGE_TIME).timeout
	if message == FLOOR_CLEARED and not _ending_snapshot.is_empty():
		await _play_ending()
	Game.return_to_waiting()


# Chooses the ending and saves it found before the scene plays, so quitting during the scene never
# plays it as new again. The scene stays on its black last frame until the Waiting Room loads.
func _play_ending() -> void:
	var found_before := Progress.data.endings_found.duplicate()
	_ending_id = EndingRules.choose(_ending_snapshot, found_before)
	var variant := 0
	if _ending_id == EndingRules.REPEAT_CUSTOMER:
		variant = EndingRules.pick_repeat_death(Progress.data.last_repeat_death, _rng.randf())
		Progress.record_repeat_death(variant)
	var paid := Progress.record_ending(_ending_id)
	Progress.set_last_run_ending(_ending_id)
	Progress.last_run["ending"] = _ending_id
	Progress.last_run["ending_paid"] = paid
	Progress.notice = ARRIVAL_NOTICE
	MusicPlayer.play(MusicRules.ending_scene(_ending_id))
	await _play_cutscene(CutsceneSteps.for_ending(_ending_id, variant), not found_before.has(_ending_id))


# The run's line in the case file's Log, saved the moment it ends, before any scene can be quit.
func _log_run(message: String) -> void:
	var result := RunLog.ENDED
	if Progress.last_run.get("died", false):
		result = RunLog.DIED
	elif message == FLOOR_CLEARED:
		result = RunLog.CLEARED
	var room := ""
	if _map != null and _current_id >= 0 and _current_id < _map.rooms.size():
		room = _map.room(_current_id).room_type
	Progress.record_run(RunLog.entry(_run, {
		"n": Progress.data.run_count,
		"date": Time.get_datetime_string_from_system(false, true),
		"result": result,
		"depth": _depth,
		"floor": _floor_def.display_name if _floor_def != null else "",
		"room": room,
		"killer": _killer_name() if result == RunLog.DIED else "",
	}))


# Who the Log says he fell to: his own Thermos, or else the boss in the room, or the nearest enemy
# still standing. Hits carry only a kind of source, so the nearest one stands in for the attacker.
func _killer_name() -> String:
	if player == null:
		return ""
	if player.last_hurt_source == RunEffects.HURT_OWN_BLAST:
		return "his own Thermos"
	var best: Enemy = null
	var best_score := INF
	if _room_view != null:
		for node in get_tree().get_nodes_in_group("enemies"):
			var enemy := node as Enemy
			if enemy == null or enemy.def == null or enemy.is_dead() or not _room_view.is_ancestor_of(enemy):
				continue
			var score := enemy.global_position.distance_to(player.global_position) - (10000.0 if enemy.def.is_boss and not enemy.is_summon else 0.0)
			if score < best_score:
				best_score = score
				best = enemy
	if best != null:
		return best.def.display_name
	return "the room itself"


func _play_cutscene(steps: Array, first_time: bool) -> void:
	_cutscene = CutscenePlayer.new()
	_cutscene.setup(steps, first_time)
	add_child(_cutscene)
	await _cutscene.finished


func debug_cutscene() -> CutscenePlayer:
	return _cutscene if is_instance_valid(_cutscene) else null


func debug_ending_id() -> String:
	return _ending_id


func debug_ending_snapshot() -> Dictionary:
	return _ending_snapshot


func _show_standing_boss() -> void:
	for child in _room_view.get_children():
		var enemy := child as Enemy
		if enemy != null and enemy.def.is_boss and not enemy.is_summon and enemy.hp > 0.0 and not enemy.is_queued_for_deletion():
			_hud.show_boss_bar(enemy.def.display_name, enemy.max_hp())
			_hud.set_boss_health(enemy.hp)
			return


func _on_boss_spawned(boss: Enemy) -> void:
	_hud.show_boss_bar(boss.def.display_name, boss.max_hp())
	boss.health_changed.connect(_hud.set_boss_health)
	boss.defeated.connect(_on_boss_defeated)
	if not boss.is_summon and not is_over:
		MusicPlayer.play(MusicRules.boss(boss.def.id, boss.def == _floor_def.floor_boss, _floor_def.depth))


func _on_boss_defeated(boss: Enemy) -> void:
	_hud.hide_boss_bar()
	# Only a real mini boss or floor boss counts, never something one of them summoned.
	if boss.is_summon or not boss.def.is_boss:
		return
	_play_room_music()
	Progress.last_run["bosses"] = int(Progress.last_run.get("bosses", 0)) + 1
	var paid := Progress.record_boss_beaten(boss.def.id, boss.def == _floor_def.floor_boss)
	if paid > 0:
		_hud.show_notice("+%d Condolences" % paid)
