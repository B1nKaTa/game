extends SceneTree
# Opens a real window and saves screenshots of what is left of Fairway's End Golf Club: its rooms, the
# sand beside the striped fairway, every prop, and the HUD over the palest tile in a large room. Its
# enemies and bosses are retired; the hotline's own look shots show Sister Celestine and Madame Zara.
# Run only from an exported copy whose config/name is renamed.
# Args after --: rooms | props | pale | all

const OUT := "D:/grandpa-look-golf/shots/"
const WALL_LIMIT_MS := 280000
const GOLF := 1

var _start := 0
var scene
var view: RoomView
var player: Player
var progress
# Behaviors whose own attacks are held off, so only the probe starts them.
var held: Array = []


func _initialize() -> void:
	_start = Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(OUT)
	_main.call_deferred()


func _process(_d: float) -> bool:
	if Time.get_ticks_msec() - _start > WALL_LIMIT_MS:
		print("PROBE TIMEOUT")
		quit(3)
	if player != null and is_instance_valid(player):
		player.run.health.heal(99)
	for b in held:
		b._cooldown = 99.0
	return false


func _wait(seconds: float) -> void:
	var began := Time.get_ticks_msec()
	while Time.get_ticks_msec() - began < seconds * 1000.0:
		await process_frame


func _shot(shot_name: String) -> void:
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	image.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	image.save_png(OUT + shot_name + ".png")
	print("shot " + shot_name)


func _stand(at: Vector2) -> void:
	player.global_position = at - Player.FEET_OFFSET


func _cell(x: int, y: int) -> Vector2:
	return RoomBackdrop.cell_center(Vector2i(x, y))


func _main() -> void:
	await process_frame
	progress = root.get_node("Progress")
	progress._store = SaveStore.new("user://look_save.json")
	progress._store.delete_all()
	progress.reload()
	progress.data.floors_cleared = 1
	progress.data.record_floor_cleared(2, "sunset_shores")
	progress.data.record_floor_cleared(3, "funeral_parlour")
	progress.data.record_floor_cleared(4, "last_resort_cruise")
	var args := OS.get_cmdline_user_args()
	var which: String = args[0] if args.size() > 0 else "all"
	for part in ["rooms", "props", "pale"]:
		if which == "all" or which == part:
			await call("_" + part)
	progress._store.delete_all()
	print("LOOK DONE")
	quit(0)


func _new_run() -> void:
	change_scene_to_file("res://scenes/floor.tscn")
	await _wait(0.3)
	scene = current_scene
	player = scene.player
	scene._depth = 4
	scene.debug_choose_path(GOLF)
	await _wait(0.2)
	view = scene.debug_room_view()
	print("floor %s" % scene.debug_floor_def().display_name)
	await _clear()


func _rows(width: int, height: int) -> PackedStringArray:
	var rows := PackedStringArray(["#".repeat(width)])
	for y in range(1, height - 1):
		rows.append("#" + ".".repeat(width - 2) + "#")
	rows.append("#".repeat(width))
	return rows


func _put(rows: PackedStringArray, cell: Vector2i, symbol: String) -> void:
	var row := rows[cell.y]
	rows[cell.y] = row.substr(0, cell.x) + symbol + row.substr(cell.x + 1)


func _fill(rows: PackedStringArray, from: Vector2i, to: Vector2i, symbol: String) -> void:
	for y in range(from.y, to.y + 1):
		for x in range(from.x, to.x + 1):
			_put(rows, Vector2i(x, y), symbol)


func _enter_layout(layout: RoomLayout) -> void:
	var map: FloorMap = scene.debug_map()
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.cell = Vector2i(70 + room.id, 70)
	room.room_type = layout.room_type
	room.layout = layout
	room.decor_seed = 7 + room.id
	map.rooms.append(room)
	scene._enter_room(room.id)
	await _wait(0.15)
	view = scene.debug_room_view()


func _enter(rows: PackedStringArray) -> void:
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_HEALING
	layout.rows = rows
	await _enter_layout(layout)


func _enter_quiet(file: String) -> RoomLayout:
	var source: RoomLayout = load(file)
	var layout: RoomLayout = source.duplicate()
	layout.room_type = RoomLayout.TYPE_HEALING
	await _enter_layout(layout)
	await _clear()
	return layout


func _clear() -> void:
	for enemy in get_nodes_in_group("enemies"):
		enemy.dismiss()
	await _wait(0.1)


func _until(check: Callable, limit: float) -> bool:
	var began := Time.get_ticks_msec()
	while not check.call() and Time.get_ticks_msec() - began < limit * 1000.0:
		await process_frame
	return check.call()


func _spawn(id: String, at: Vector2) -> Enemy:
	return view._spawn_enemy(load("res://data/enemies/%s.tres" % id), at, true)


func _of(type) -> Array:
	var found := []
	_collect(view, type, found)
	return found


func _collect(node: Node, type, found: Array) -> void:
	for child in node.get_children():
		if is_instance_of(child, type) and not child.is_queued_for_deletion():
			found.append(child)
		_collect(child, type, found)


func _warned(enemy: Enemy, share: float) -> bool:
	return is_instance_valid(enemy) and enemy._warning != null and enemy._warning.warning_progress(enemy._warning_share()) > share


func _middle(layout: RoomLayout) -> Vector2:
	var size := layout.size_in_cells()
	return RoomBackdrop.cell_center(layout.nearest_floor_cell(Vector2i(size.x / 2, size.y / 2)))


func _floor_near(layout: RoomLayout, at: Vector2) -> Vector2:
	return RoomBackdrop.cell_center(layout.nearest_floor_cell(Vector2i(floori(at.x / RoomBackdrop.TILE), floori(at.y / RoomBackdrop.TILE))))


func _freeze_all() -> void:
	for e in get_nodes_in_group("enemies"):
		e.set_physics_process(false)


# --- real rooms with their enemies ---

func _show_room(file: String, type: String, shot_name: String, stand_side := RoomLayout.SOUTH) -> void:
	var source: RoomLayout = load(file)
	var map: FloorMap = scene.debug_map()
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.cell = Vector2i(90 + room.id, 90)
	room.room_type = type
	room.layout = source
	room.decor_seed = 7 + room.id
	map.rooms.append(room)
	scene._enter_room(room.id)
	await _wait(0.15)
	view = scene.debug_room_view()
	_stand(RoomBackdrop.cell_center(source.door_cell(stand_side)))
	_freeze_all()
	await _wait(0.6)
	await _shot(shot_name)
	await _clear()


func _rooms() -> void:
	await _new_run()
	var f := "res://data/rooms/seance_hotline/%s.tres"
	for entry: Array in [["combat_small_01", "combat"], ["combat_small_02", "combat"], ["combat_01", "combat"], ["combat_04", "combat"], ["combat_large_01", "combat"], ["combat_large_03", "combat"]]:
		await _show_room(f % entry[0], entry[1], "10_room_" + entry[0])
	# The large room's far end too, since the camera travels.
	await _show_room(f % "combat_large_02", "combat", "11_room_combat_large_02_north", RoomLayout.NORTH)


# --- sand by the fairway, and every prop ---

func _props() -> void:
	await _new_run()
	var rows := _rows(20, 11)
	# Sand straddling light and dark stripes.
	_fill(rows, Vector2i(3, 3), Vector2i(7, 5), "s")
	# A hedge run and a lone hedge cell (a parked cart).
	for x in range(10, 14):
		_put(rows, Vector2i(x, 3), "5")
	_put(rows, Vector2i(16, 3), "5")
	_put(rows, Vector2i(11, 7), "3")
	_put(rows, Vector2i(13, 7), "4")
	_put(rows, Vector2i(16, 7), "5")
	_put(rows, Vector2i(5, 8), "3")
	await _enter(rows)
	_stand(_cell(9, 6))
	await _wait(0.4)
	await _shot("20_props_sand_by_fairway")
	# Grandpa wading in the sand.
	_stand(_cell(5, 4))
	await _wait(0.3)
	await _shot("21_grandpa_in_sand")
	# Every prop broken, for the debris colours.
	_stand(_cell(9, 9))
	for prop in view.get_children():
		if prop is BreakableBlock and prop.global_position.y < _cell(0, 8).y:
			prop.take_blast()
	await _wait(0.05)
	await _shot("22_props_debris")
	await _wait(0.6)
	await _shot("23_props_after_breaking")


# --- the palest tile: sand in a large room, the HUD over it, and every effect on it ---

func _pale() -> void:
	await _new_run()
	var rows := _rows(30, 17)
	_fill(rows, Vector2i(3, 1), Vector2i(26, 2), "s")
	_fill(rows, Vector2i(4, 4), Vector2i(25, 9), "s")
	await _enter(rows)
	_stand(_cell(14, 3))
	await _wait(0.4)
	await _shot("70_pale_hud_over_sand")
	await _clear()
