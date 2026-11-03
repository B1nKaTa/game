extends Node2D

# The one place that says which floors a run can start on. Each entry gets an exit at the Crossroads,
# west first and then east, and its FloorDef says when it opens.
const PATH_FLOORS: Array[String] = ["res://data/floors/floor_1.tres", "res://data/floors/cemetery.tres"]
const CROSSROADS_FLOOR := "res://data/floors/crossroads.tres"
const CROSSROADS_LAYOUT := "res://data/rooms/crossroads/crossroads.tres"
const MESSAGE_TIME := 2.0

var player: Player
var is_cleared := false
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


func _ready() -> void:
	_rng.randomize()
	Progress.start_run()
	_run = Progress.make_run()
	var crafted := Progress.take_crafted_item()
	if crafted != null:
		_run.add_item(crafted)
	var brewed := Progress.take_brewed_potion()
	if brewed != null:
		_run.give_potion(brewed)
	_hud = Hud.new()
	_hud.setup(_run)
	add_child(_hud)
	_hud.set_pension(Progress.data.pension)
	Progress.pension_changed.connect(_hud.set_pension)
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


# Walks out of the Crossroads along a path at once, for checks that are not about the walking.
func debug_choose_path(index: int) -> void:
	_choose_path(index)


func _add_map_view(is_big: bool) -> FloorMapView:
	var view := FloorMapView.new()
	view.setup(_map, _progress, is_big, _floor_def.display_name)
	_hud.add_child(view)
	return view


func _path_defs() -> Array[FloorDef]:
	var defs: Array[FloorDef] = []
	for path in PATH_FLOORS:
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
	player.recall_cane()
	var from_id := _current_id
	if _room_view != null:
		_room_view.clear_passing_effects()
		remove_child(_room_view)
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


func _on_player_died() -> void:
	_end_run("You died again. Please take a number.")


func _on_floor_cleared() -> void:
	if is_cleared:
		return
	is_cleared = true
	# Merchants open on floors cleared, so the clear is saved before anything else can end the run.
	Progress.record_floor_cleared(_floor_def.depth, _floor_def.id)
	_continue_after_floor()


# Every path ends here, whichever floor was taken. No second floor exists yet, so a floor boss's fall
# ends the run. When one does, build it here the way _choose_path builds a first floor, and both paths
# reach it without any other change.
func _continue_after_floor() -> void:
	_end_run("FLOOR CLEARED")


func _end_run(message: String) -> void:
	if is_over:
		return
	is_over = true
	if _big_map != null:
		_big_map.enabled = false
		_big_map.set_open(false)
	_hud.hide_boss_bar()
	_hud.show_message(message)
	if player != null:
		player.recall_cane()
		player.process_mode = Node.PROCESS_MODE_DISABLED
	if _room_view != null:
		_room_view.process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().create_timer(MESSAGE_TIME).timeout
	Game.return_to_waiting()


func _on_boss_spawned(boss: Enemy) -> void:
	_hud.show_boss_bar(boss.def.display_name, boss.def.max_hp)
	boss.health_changed.connect(_hud.set_boss_health)
	boss.defeated.connect(_on_boss_defeated)


func _on_boss_defeated(_boss: Enemy) -> void:
	_hud.hide_boss_bar()
