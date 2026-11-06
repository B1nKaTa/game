extends SceneTree
# Opens a real window and saves screenshots of the room art on every path: a combat room with a ground
# warning laid near Harold, a shop, a treasure room with every chest kind (one left open) and every
# pickup, and the boss room; then the Waiting Room's lobby with all its decor and two departments.
# Prints the lit luminance of the floor, of the warning over it and of Harold, sampled from each shot.
# Run only from an exported copy whose config/name is renamed.
# Args after --: <path id> | waiting | all

const OUT := "D:/grandpa-shots-env/"
const WALL_LIMIT_MS := 560000
const FLOORS := {
	"floor_1": [1, 0], "cemetery": [1, 1], "sunset_shores": [2, 0], "furnace_works": [2, 1],
	"funeral_parlour": [3, 0], "last_resort_cruise": [4, 0], "terminal_zero": [5, 0], "head_office": [5, 1],
}
const ORDER := ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "last_resort_cruise",
	"terminal_zero", "head_office"]

var _start := 0
var scene
var view: RoomView
var player: Player
var progress


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
	return false


func _wait(seconds: float) -> void:
	var began := Time.get_ticks_msec()
	while Time.get_ticks_msec() - began < seconds * 1000.0:
		await process_frame


func _shot(shot_name: String) -> Image:
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	var big := image.duplicate()
	big.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	big.save_png(OUT + shot_name + ".png")
	print("shot " + shot_name)
	return image


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
	progress.data.record_floor_cleared(5, "terminal_zero")
	var args := OS.get_cmdline_user_args()
	var which: String = args[0] if args.size() > 0 else "all"
	for path in ORDER:
		if which == "all" or which == path:
			await _path(path)
	if which == "all" or which == "waiting":
		await _waiting_room()
	progress._store.delete_all()
	print("LOOK DONE")
	quit(0)


func _new_run(floor_id: String) -> bool:
	change_scene_to_file("res://scenes/floor.tscn")
	await _wait(0.3)
	scene = current_scene
	player = scene.player
	scene._depth = FLOORS[floor_id][0]
	scene.debug_choose_path(FLOORS[floor_id][1])
	await _wait(0.2)
	view = scene.debug_room_view()
	var got: String = scene.debug_floor_def().id
	if got != floor_id:
		print("WRONG FLOOR %s for %s" % [got, floor_id])
		return false
	await _clear()
	return true


func _clear() -> void:
	for enemy in get_nodes_in_group("enemies"):
		enemy.dismiss()
	await _wait(0.1)


func _freeze() -> void:
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)


func _enter(file: String, room_type := "") -> RoomLayout:
	var source: RoomLayout = load(file)
	var layout: RoomLayout = source.duplicate()
	if not room_type.is_empty():
		layout.room_type = room_type
	var map: FloorMap = scene.debug_map()
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.cell = Vector2i(70 + room.id, 70)
	room.room_type = layout.room_type
	room.layout = layout
	room.decor_seed = 7 + room.id
	map.rooms.append(room)
	scene._enter_room(room.id)
	await _wait(0.2)
	view = scene.debug_room_view()
	return layout


func _stand(cell: Vector2i) -> void:
	player.global_position = RoomBackdrop.cell_center(cell) - Player.FEET_OFFSET
	player.velocity = Vector2.ZERO


func _middle(layout: RoomLayout) -> Vector2i:
	var size := layout.size_in_cells()
	return layout.nearest_floor_cell(Vector2i(size.x / 2, size.y / 2))


# Free floor cells of the room, nearest the middle first, that hold nothing from the layout.
func _free_cells(layout: RoomLayout, count: int) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	var mid := _middle(layout)
	var size := layout.size_in_cells()
	var cells: Array[Vector2i] = []
	for y in range(1, size.y - 1):
		for x in range(1, size.x - 1):
			if layout.rows[y][x] == "." and posmod(x - mid.x, 2) == 0 and posmod(y - mid.y, 2) == 0:
				cells.append(Vector2i(x, y))
	cells.sort_custom(func(a, b): return a.distance_squared_to(mid) < b.distance_squared_to(mid))
	for cell in cells:
		if found.size() >= count:
			break
		found.append(cell)
	return found


func _lum(c: Color) -> float:
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b


# The mean colour of a small square of the (1x) screenshot around a world point.
func _sample(image: Image, world: Vector2, half := 3) -> Color:
	var screen: Vector2 = view.get_viewport().get_canvas_transform() * world
	var sum := Color(0, 0, 0, 0)
	var n := 0
	for dy in range(-half, half + 1):
		for dx in range(-half, half + 1):
			var x := clampi(int(screen.x) + dx, 0, image.get_width() - 1)
			var y := clampi(int(screen.y) + dy, 0, image.get_height() - 1)
			sum += image.get_pixel(x, y)
			n += 1
	return Color(sum.r / n, sum.g / n, sum.b / n)


func _room_file(floor_id: String, kind: String) -> String:
	var dir: String = scene.debug_floor_def().rooms_dir
	for name in DirAccess.get_files_at(dir):
		if name.begins_with(kind) and name.ends_with(".tres") and not name.contains("small"):
			return dir.path_join(name)
	print("NO %s ROOM on %s" % [kind, floor_id])
	return ""


func _path(floor_id: String) -> void:
	if not await _new_run(floor_id):
		return
	var tag: String = floor_id
	# Combat: the room wakes, then a ground warning goes down beside Harold.
	var layout := await _enter(_room_file(floor_id, "combat_0"), RoomLayout.TYPE_COMBAT)
	var mid := _middle(layout)
	_stand(mid)
	await _wait(0.8)
	_freeze()
	var enemies := get_nodes_in_group("enemies")
	var cells := _free_cells(layout, 12)
	var warn_at := RoomBackdrop.cell_center(cells[min(6, cells.size() - 1)])
	var floor_at := RoomBackdrop.cell_center(cells[min(9, cells.size() - 1)])
	var before := await _shot(tag + "_1_combat_floor")
	if not enemies.is_empty():
		enemies[0].strike_ground(warn_at, 30.0, 2.0)
	await _wait(1.2)
	var image := await _shot(tag + "_1_combat")
	var floor_lit := _sample(before, warn_at)
	var warn_lit := _sample(image, warn_at)
	var other := _sample(image, floor_at)
	var feet: Vector2 = player.global_position + Player.FEET_OFFSET
	var body := _sample(image, feet + Vector2(0, -14), 2)
	print("LUM %s floor %.3f floor2 %.3f warn %.3f (red %.2f vs floor red %.2f) harold %.3f enemies %d" % [
		tag, _lum(floor_lit), _lum(other), _lum(warn_lit), warn_lit.r, floor_lit.r, _lum(body), enemies.size()])
	await _clear()
	# Shop, with a door in each state along its top wall.
	layout = await _enter(_room_file(floor_id, "shop"))
	_add_doors(layout)
	_stand(_middle(layout) + Vector2i(0, 2))
	await _wait(0.4)
	await _shot(tag + "_2_shop")
	# Treasure, with every chest kind beside the rolled ones, one opened, and every pickup.
	layout = await _enter(_room_file(floor_id, "treasure"))
	cells = _free_cells(layout, 14)
	var kinds := [ChestRules.LUNCHBOX, ChestRules.LOCKED, ChestRules.SAFE, ChestRules.URN, ChestRules.LOCKED]
	for i in kinds.size():
		var chest: Chest = view._create_chest(cells[i], kinds[i])
		if i == kinds.size() - 1:
			chest._leave_opened()
			chest.queue_free()
	view._drop_coin(RoomBackdrop.cell_center(cells[6]), 5)
	for kind in [RoomRules.DROP_KEY, RoomRules.DROP_BOMB, RoomRules.DROP_POTION]:
		view._drop_consumable(RoomBackdrop.cell_center(cells[7 + [RoomRules.DROP_KEY, RoomRules.DROP_BOMB, RoomRules.DROP_POTION].find(kind)]), kind)
	view._add_heal(RoomBackdrop.cell_center(cells[10]), 1)
	_stand(cells[12])
	await _wait(0.4)
	await _shot(tag + "_3_treasure")
	# The floor boss's room, with the boss awake and held still.
	layout = await _enter(_room_file(floor_id, "floor_boss"), RoomLayout.TYPE_FLOOR_BOSS)
	_stand(_middle(layout) + Vector2i(0, 2))
	await _wait(1.0)
	_freeze()
	await _shot(tag + "_4_boss")
	await _clear()


# Open, needs a Slip, locked and chained, left to right on the top wall's middle.
func _add_doors(layout: RoomLayout) -> void:
	var mid := _middle(layout)
	var states := [["open", "C"], ["key", "T"], ["locked", "B"], ["chained", "?"]]
	for i in states.size():
		var door := Door.new()
		door.setup(-1, states[i][1], player, RoomLayout.NORTH)
		door.locked = states[i][0] == "locked"
		door.requires_key = states[i][0] == "key"
		door.chained = states[i][0] == "chained"
		door.position = RoomBackdrop.cell_center(Vector2i(mid.x - 3 + i * 2, 0))
		view.add_child(door)


func _waiting_room() -> void:
	var data: ProgressData = progress.data
	data.opening_seen = true
	data.record_floor_cleared(5, "head_office")
	data.departments_seen = {}
	for id in Departments.ALL:
		data.departments_seen[id["id"]] = true
	for id in ["potted_fern", "motivational_poster", "better_chair", "warm_lamps", "fish_tank", "new_carpet"]:
		data.cosmetics_owned[id] = true
	progress.last_run = {}
	change_scene_to_file("res://scenes/waiting_room.tscn")
	await _wait(0.5)
	var hub = current_scene
	player = hub.player
	player.global_position = RoomBackdrop.cell_center(Vector2i(15, 6)) - Player.FEET_OFFSET
	await _wait(0.4)
	await _shot("waiting_room_1_lobby")
	for department in [Departments.EXECUTIVE_SUITE, Departments.TRAINING_YARD, Departments.BOUNTY_OFFICE]:
		hub.debug_enter_department(department)
		await _wait(0.3)
		player.global_position = RoomBackdrop.cell_center(Vector2i(8, 6)) - Player.FEET_OFFSET
		await _wait(0.3)
		await _shot("waiting_room_2_" + department)
