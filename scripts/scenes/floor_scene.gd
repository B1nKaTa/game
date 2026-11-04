extends Node2D

# The one place that says which floors each depth offers. Each entry gets an exit at that depth's
# Crossroads, west first and then east, and its FloorDef says when it opens.
const PATHS_BY_DEPTH := {
	1: ["res://data/floors/floor_1.tres", "res://data/floors/cemetery.tres"],
	2: ["res://data/floors/sunset_shores.tres", "res://data/floors/furnace_works.tres"],
	3: ["res://data/floors/funeral_parlour.tres", "res://data/floors/golden_years_mall.tres"],
}
# The deepest floor there is. A floor boss falling here ends the run.
const LAST_DEPTH := 3
const CROSSROADS_FLOOR := "res://data/floors/crossroads.tres"
const CROSSROADS_LAYOUT := "res://data/rooms/crossroads/crossroads.tres"
# The landing each depth below the first starts on. Its FloorDef names the floor on the sign and maps.
const LANDINGS_BY_DEPTH := {
	2: "res://data/floors/landing.tres",
	3: "res://data/floors/landing_3.tres",
}
const LANDING_LAYOUT := "res://data/rooms/landing/landing.tres"
# Pills healed on reaching the landing, up to his maximum.
const LANDING_HEAL := 2
const MESSAGE_TIME := 2.0
const CURSED_NOTICE := "Cursed ticket: tougher enemies, better pay"

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


func _ready() -> void:
	_rng.randomize()
	Progress.start_run()
	_run = Progress.make_run()
	# Before the first room is built, so every enemy of a cursed run is spawned tougher.
	_run.cursed = Progress.take_cursed_run()
	var crafted := Progress.take_crafted_item()
	if crafted != null:
		_run.add_item(crafted)
	var brewed := Progress.take_brewed_potion()
	if brewed != null:
		_run.give_potion(brewed)
	if Progress.is_dev_run():
		DevStart.apply_kit(_run, Content.items())
	_hud = Hud.new()
	_hud.setup(_run)
	add_child(_hud)
	_hud.set_pension(Progress.data.pension)
	Progress.pension_changed.connect(_hud.set_pension)
	if _run.has_perk(Mementos.START_PENSION_PERK):
		Progress.add_pension(Mementos.START_PENSION)
		_hud.show_notice("Your name badge still works: +%d Pension" % Mementos.START_PENSION)
	# Shown after the badge's notice, in its place, since it matters more.
	if _run.cursed:
		_hud.show_notice(CURSED_NOTICE)
	if Progress.is_dev_run():
		# A dev run skips straight to its landing, with that depth's Crossroads beyond it.
		_depth = DevStart.START_DEPTH
		_floor_def = load(LANDINGS_BY_DEPTH[_depth])
		_map = _landing_map()
	else:
		_floor_def = load(CROSSROADS_FLOOR)
		_map = FloorMap.with_only_crossroads(load(CROSSROADS_LAYOUT))
	_camera = Camera2D.new()
	add_child(_camera)
	_feedback = CombatFeedback.new()
	_feedback.setup(_camera)
	add_child(_feedback)
	player = Player.new()
	player.setup(_run)
	player.died.connect(_on_player_died)
	player.bomb_requested.connect(_on_bomb_requested)
	player.show_crosshair = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	add_child(player)
	_feedback.watch_player(player)
	var glow := Lighting.make_light(Color(1.0, 0.85, 0.6), 0.7, 0.8)
	player.add_child(glow)
	_progress = FloorProgress.new(_map)
	_mini_map = _add_map_view(false)
	_big_map = _add_map_view(true)
	_big_map.opened_changed.connect(_on_big_map_changed)
	_enter_room(_map.start_id)


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


func debug_card_panel() -> CardTablePanel:
	return _card_panel


# Walks out of the Crossroads along a path at once, for checks that are not about the walking.
func debug_choose_path(index: int) -> void:
	_choose_path(index)


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
	var map := FloorBuilder.build(_rng, def)
	if map == null:
		_end_run("This floor could not be built. Returning to the Waiting Room.")
		return
	var exit_side: Vector2i = _room_view.side_of_path(index)
	var crossroads := map.attach_crossroads(_map.room(_current_id).layout, -exit_side)
	var leaving := _room_view
	_room_views.clear()
	_floor_def = def
	_map = map
	_progress = FloorProgress.new(map)
	_progress.enter(crossroads.id)
	_mini_map.setup(map, _progress, false, def.display_name)
	_big_map.setup(map, _progress, true, def.display_name)
	_current_id = crossroads.id
	_enter_room(map.start_id)
	leaving.queue_free()


func _on_big_map_changed(is_open: bool) -> void:
	_mini_map.visible = not is_open
	player.cancel_charge()


func _enter_room(target_id: int) -> void:
	_hud.hide_boss_bar()
	player.recall_teeth()
	var from_id := _current_id
	if _room_view != null:
		_room_view.clear_passing_effects()
		remove_child(_room_view)
	var first_visit := not _progress.is_visited(target_id)
	_progress.enter(target_id)
	_current_id = target_id
	_room_view = _room_views.get(target_id)
	if _room_view == null:
		_room_view = _make_room_view(_map.room(target_id))
		_room_views[target_id] = _room_view
	add_child(_room_view)
	move_child(_room_view, 0)
	_room_view.refresh_doors()
	player.global_position = Player.arrival_position(_progress.arrival_cell(target_id, from_id))
	_mini_map.set_current(target_id)
	_big_map.set_current(target_id)
	_follow_player()
	if first_visit:
		_tip_hat(_map.room(target_id))


# The top hat memento: a pill on first walking into a boss room.
func _tip_hat(room: FloorRoom) -> void:
	if not _run.has_perk(Mementos.BOSS_ROOM_PILL_PERK):
		return
	if room.room_type != RoomLayout.TYPE_MINI_BOSS and room.room_type != RoomLayout.TYPE_FLOOR_BOSS:
		return
	_run.health.heal(Mementos.BOSS_ROOM_HEAL)
	_hud.show_notice("You tip your hat. +%d pill" % Mementos.BOSS_ROOM_HEAL)


func _process(_delta: float) -> void:
	_follow_player()


# Shake moves the camera through its offset, so following never fights it.
func _follow_player() -> void:
	if _camera == null or _current_id == -1:
		return
	var room_size := Vector2(_map.room(_current_id).layout.size_in_cells()) * RoomBackdrop.TILE
	_camera.position = RoomCamera.center_for(room_size, player.feet().global_position, RoomBackdrop.VIEW_SIZE)


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
	view.setup(room, _map, _floor_def, _run, player, _rng, _progress, Progress)
	view.notice.connect(_hud.show_notice)
	view.pension_earned.connect(func(amount: int): Progress.add_pension(amount))
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
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


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
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _on_player_died() -> void:
	Progress.last_run["died"] = true
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
	_end_run("FLOOR CLEARED")


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
	_enter_room(_map.start_id)
	leaving.queue_free()
	var missing := _run.health.max_pills - _run.health.pills
	_run.health.heal(LANDING_HEAL)
	var healed := mini(LANDING_HEAL, missing)
	_hud.show_notice("You catch your breath. +%d pills" % healed if healed > 0 else "You catch your breath.")


func _landing_map() -> FloorMap:
	return FloorMap.with_landing_and_crossroads(load(LANDING_LAYOUT), load(CROSSROADS_LAYOUT))


func _end_run(message: String) -> void:
	if is_over:
		return
	is_over = true
	if _card_panel != null:
		_card_panel.leave()
	if _big_map != null:
		_big_map.enabled = false
		_big_map.set_open(false)
	_hud.hide_boss_bar()
	_hud.show_message(message)
	if player != null:
		player.recall_teeth()
		player.process_mode = Node.PROCESS_MODE_DISABLED
	if _room_view != null:
		_room_view.process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().create_timer(MESSAGE_TIME).timeout
	Game.return_to_waiting()


func _on_boss_spawned(boss: Enemy) -> void:
	_hud.show_boss_bar(boss.def.display_name, boss.max_hp())
	boss.health_changed.connect(_hud.set_boss_health)
	boss.defeated.connect(_on_boss_defeated)


func _on_boss_defeated(boss: Enemy) -> void:
	_hud.hide_boss_bar()
	# Only a real mini boss or floor boss counts, never something one of them summoned.
	if boss.is_summon or not boss.def.is_boss:
		return
	Progress.last_run["bosses"] = int(Progress.last_run.get("bosses", 0)) + 1
	var paid := Progress.record_boss_beaten(boss.def.id, boss.def == _floor_def.floor_boss)
	if paid > 0:
		_hud.show_notice("+%d Condolences" % paid)
