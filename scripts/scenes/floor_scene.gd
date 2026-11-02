extends Node2D

const FLOOR_PATH := "res://data/floors/floor_1.tres"
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
	_hud = Hud.new()
	_hud.setup(_run)
	add_child(_hud)
	_hud.set_pension(Progress.data.pension)
	Progress.pension_changed.connect(_hud.set_pension)
	_floor_def = load(FLOOR_PATH)
	_map = FloorBuilder.build(_rng, RoomCatalog.load_valid(_floor_def.rooms_dir))
	if _map == null:
		_end_run("This floor could not be built. Returning to the Waiting Room.")
		return
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


func debug_take_first_exit() -> void:
	var room := _map.room(_current_id)
	if room.is_detour():
		_enter_room(room.parent_id)
	elif not room.exits.is_empty():
		_enter_room(room.exits[0])


func debug_go_back() -> void:
	_enter_room(_progress.back_target(_current_id))


func debug_big_map() -> FloorMapView:
	return _big_map


func _add_map_view(is_big: bool) -> FloorMapView:
	var view := FloorMapView.new()
	view.setup(_map, _progress, is_big)
	_hud.add_child(view)
	return view


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
	_progress.enter(target_id, from_id)
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
	var view := RoomView.new()
	view.setup(room, _map, _floor_def, _run, player, _rng, _progress, Progress)
	view.notice.connect(_hud.show_notice)
	view.door_entered.connect(func(id: int): _enter_room.call_deferred(id))
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
	is_cleared = true
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
