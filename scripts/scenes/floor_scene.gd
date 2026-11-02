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
var _finished_rooms := {}
var _used_sides := {}
var _hud: Hud


func _ready() -> void:
	_rng.randomize()
	_run = Progress.make_run()
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
	player = Player.new()
	player.setup(_run)
	player.died.connect(_on_player_died)
	add_child(player)
	var glow := Lighting.make_light(Color(1.0, 0.85, 0.6), 0.7, 0.8)
	player.add_child(glow)
	_enter_room(_map.start_id)


func debug_take_first_exit() -> void:
	var room := _map.room(_current_id)
	if room.room_type == RoomLayout.TYPE_SIDE:
		_enter_room(room.parent_id)
	elif not room.exits.is_empty():
		_enter_room(room.exits[0])


func _enter_room(target_id: int) -> void:
	var from_side := _current_id != -1 and _map.room(_current_id).room_type == RoomLayout.TYPE_SIDE
	if _room_view != null:
		_room_view.queue_free()
	var room := _map.room(target_id)
	if room.room_type == RoomLayout.TYPE_SIDE:
		_used_sides[room.parent_id] = true
	_current_id = target_id
	_room_view = RoomView.new()
	_room_view.setup(room, _map, _floor_def, _run, player, _rng, _finished_rooms.has(target_id), not _used_sides.has(target_id))
	_room_view.door_entered.connect(func(id: int): _enter_room.call_deferred(id))
	_room_view.pension_earned.connect(func(amount: int): Progress.add_pension(amount))
	_room_view.room_finished.connect(func(id: int): _finished_rooms[id] = true)
	_room_view.floor_cleared.connect(_on_floor_cleared)
	add_child(_room_view)
	move_child(_room_view, 0)
	var entry := RoomLayout.ENTRY
	if from_side:
		entry = RoomLayout.SIDE_DOOR
	elif room.room_type == RoomLayout.TYPE_SIDE:
		entry = RoomLayout.SIDE_ROOM_SPAWN
	player.global_position = RoomBackdrop.cell_center(entry)


func _on_player_died() -> void:
	_end_run("You died again. Please take a number.")


func _on_floor_cleared() -> void:
	is_cleared = true
	_end_run("FLOOR CLEARED")


func _end_run(message: String) -> void:
	if is_over:
		return
	is_over = true
	_hud.show_message(message)
	if player != null:
		player.process_mode = Node.PROCESS_MODE_DISABLED
	if _room_view != null:
		_room_view.process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().create_timer(MESSAGE_TIME).timeout
	Game.return_to_waiting()
