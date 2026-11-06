extends SceneTree
# Opens a real window and saves screenshots of Harold's new art: beside Gerald, the Dealer and Dolores
# in the Waiting Room (he stands a little shorter), Ingrid in Duty Free, the Shopkeeper in a floor-1
# shop, a walk and a swing frame by frame in a fight room, and every Decor Office look he can wear,
# facing each way. A 4x crop round him sits beside each shot.
# Run only from an exported copy whose config/name is renamed.
# Args after --: waiting | shop | fight | looks | all

const OUT := "D:/grandpa-shots-r6/"
const WALL_LIMIT_MS := 280000
const CROP := Vector2i(120, 80)

var _start := 0
var scene
var view: RoomView
var player: Player
var progress
var aim := Vector2.RIGHT
# Actions held down. In a window something lets go of Input.action_press after a frame, so they are
# pressed again just before every physics step.
var held: Array[String] = []


func _initialize() -> void:
	_start = Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(OUT)
	physics_frame.connect(func() -> void:
		for action in held:
			Input.action_press(action))
	_main.call_deferred()


func _process(_d: float) -> bool:
	if Time.get_ticks_msec() - _start > WALL_LIMIT_MS:
		print("PROBE TIMEOUT")
		quit(3)
	if player != null and is_instance_valid(player) and player.run != null:
		player.run.health.heal(99)
	return false


func _wait(seconds: float) -> void:
	var began := Time.get_ticks_msec()
	while Time.get_ticks_msec() - began < seconds * 1000.0:
		await process_frame


func _frames(count: int) -> void:
	for i in count:
		await process_frame


# The whole view at 2x (unless crop_only), and a 4x crop round at.
func _shot(shot_name: String, at: Node2D = null, crop_only := false) -> void:
	await process_frame
	var image := root.get_texture().get_image()
	if at != null:
		var middle := Vector2i(at.get_global_transform_with_canvas().origin)
		var corner := (middle - CROP / 2).clamp(Vector2i.ZERO, image.get_size() - CROP)
		var crop := image.get_region(Rect2i(corner, CROP))
		crop.resize(CROP.x * 4, CROP.y * 4, Image.INTERPOLATE_NEAREST)
		crop.save_png(OUT + shot_name + "_x4.png")
	if not crop_only:
		image.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
		image.save_png(OUT + shot_name + ".png")
	print("shot " + shot_name)


func _stand(feet: Vector2) -> void:
	player.global_position = feet - Player.FEET_OFFSET
	player.velocity = Vector2.ZERO


func _press(action: String) -> void:
	held.append(action)
	Input.action_press(action)


func _release(action: String) -> void:
	held.erase(action)
	Input.action_release(action)


func _hold_aim() -> void:
	player.aim_source = func() -> Vector2: return player.global_position + aim * 60.0


func _npcs_in(node: Node) -> Array[Npc]:
	var found: Array[Npc] = []
	for child in node.get_children():
		if child is Npc:
			found.append(child as Npc)
	return found


func _main() -> void:
	await process_frame
	progress = root.get_node("Progress")
	progress._store = SaveStore.new("user://look_save.json")
	progress._store.delete_all()
	progress.reload()
	progress.data.floors_cleared = 1
	progress.data.record_floor_cleared(1, "")
	progress.data.record_floor_cleared(2, "flashback_cinema")
	progress.data.record_floor_cleared(3, "funeral_parlour")
	progress.data.record_floor_cleared(4, "last_resort_cruise")
	progress.data.record_floor_cleared(4, "seance_hotline")
	progress.data.record_floor_cleared(5, "terminal_zero")
	# Gerald stands in the lobby once this ending is found.
	progress.data.endings_found[EndingRules.ETERNAL_FEUD] = true
	var args := OS.get_cmdline_user_args()
	var which: String = args[0] if args.size() > 0 else "all"
	for part in ["waiting", "shop", "fight", "looks"]:
		if which == "all" or which == part:
			await call("_" + part)
	progress._store.delete_all()
	print("LOOK DONE")
	quit(0)


# Harold side by side with each person, his feet on the same row as theirs, facing them.
func _beside(tag: String) -> void:
	for npc in _npcs_in(view):
		var feet := npc.global_position + Vector2(0, npc.def.body_size.y / 2.0)
		print("%s: %s feet %s top %.0f height %.0f" % [tag, npc.def.id, str(feet), npc.head_top(), npc.art().height if npc.has_art() else -1.0])
		# His soles on the same row as theirs.
		_stand(feet + Vector2(-24, -Player.FEET_BOX_SIZE.y / 2.0))
		aim = Vector2.RIGHT
		await _wait(0.6)
		print("  harold at %s, his feet box bottom %s, npc at %s, canvas %s vs %s" % [str(player.global_position), str(player.global_position + Player.FEET_OFFSET + Vector2(0, Player.FEET_BOX_SIZE.y / 2.0)), str(npc.global_position), str(player.get_global_transform_with_canvas().origin), str(npc.get_global_transform_with_canvas().origin)])
		await _shot("%s_%s_beside" % [tag, npc.def.id], npc)


func _waiting() -> void:
	change_scene_to_file("res://scenes/waiting_room.tscn")
	await _wait(0.8)
	scene = current_scene
	player = scene.player
	_hold_aim()
	for id in [Departments.LOBBY, Departments.BACK_ROOM, Departments.BOUNTY_OFFICE, Departments.DUTY_FREE]:
		scene.debug_enter_department(id)
		await _wait(0.5)
		view = scene.debug_room_view()
		_hold_aim()
		await _beside("w_" + id)


func _shop() -> void:
	await _floor()
	var layout: RoomLayout = (load("res://data/rooms/floor_1/shop_01.tres") as RoomLayout).duplicate()
	await _enter_layout(layout)
	await _beside("s_floor_1_shop")


func _floor() -> void:
	if scene != null and is_instance_valid(scene) and scene.scene_file_path.ends_with("floor.tscn"):
		return
	change_scene_to_file("res://scenes/floor.tscn")
	await _wait(0.5)
	scene = current_scene
	player = scene.player
	_hold_aim()
	await _wait(0.2)


func _fight_layout() -> RoomLayout:
	for layout in RoomCatalog.load_valid("res://data/rooms/floor_1/"):
		if layout.room_type == RoomLayout.TYPE_COMBAT:
			return layout.duplicate()
	return null


func _fight() -> void:
	await _floor()
	var layout := _fight_layout()
	await _enter_layout(layout, false)
	var middle := _middle(layout)
	_stand(middle + Vector2(-60, 0))
	for enemy in get_nodes_in_group("enemies"):
		enemy.global_position = middle + Vector2(140, 0)
		enemy.set_physics_process(false)
	aim = Vector2.RIGHT
	await _wait(0.4)
	await _shot("f_idle", player)
	# A walk east, one shot every 0.1 s (one frame of the hobble each).
	_press("move_right")
	for i in 8:
		await _wait(0.1)
		await _shot("f_walk_%d" % i, player, i != 3)
	_release("move_right")
	var foe: Node2D = null
	for enemy in get_nodes_in_group("enemies"):
		if foe == null:
			foe = enemy
		else:
			enemy.dismiss()
	if foe != null:
		foe.global_position = player.global_position + Vector2(34, 0)
	await _wait(0.4)
	# A swing at the enemy, frame by frame: it hits and shows its arc for 0.1 s of the 0.2 s.
	_press("attack")
	await physics_frame
	await physics_frame
	_release("attack")
	for i in 7:
		await _shot("f_swing_%02dms" % int(i * 3 * 1000 / 60.0), player, i != 2)
		await _frames(2)
	await _wait(0.4)
	aim = Vector2.LEFT
	_press("move_left")
	await _wait(0.35)
	await _shot("f_walk_west", player)
	_release("move_left")


func _looks() -> void:
	await _floor()
	var layout := _fight_layout()
	await _enter_layout(layout)
	var middle := _middle(layout)
	_stand(middle)
	var worn := 0
	for def in CosmeticDef.all():
		if not def.slot in CosmeticDef.WORN_SLOTS:
			continue
		worn += 1
		player.run.look = {def.slot: def}
		player.refresh_look()
		for dir in [1, -1]:
			aim = Vector2.RIGHT * dir
			await _wait(0.35)
			await _shot("l_%s_%s" % [def.id, "east" if dir > 0 else "west"], player, dir < 0)
		if def.slot == CosmeticDef.SLOT_CANE:
			_press("move_right")
			await _wait(0.3)
			await _shot("l_%s_walk" % def.id, player, true)
			_release("move_right")
			await _wait(0.2)
	# Everything at once.
	player.run.look = {
		CosmeticDef.SLOT_HAT: CosmeticDef.find("captains_hat", CosmeticDef.all()),
		CosmeticDef.SLOT_CARDIGAN: CosmeticDef.find("power_tie", CosmeticDef.all()),
		CosmeticDef.SLOT_CANE: CosmeticDef.find("candy_stripe", CosmeticDef.all()),
	}
	player.refresh_look()
	aim = Vector2.RIGHT
	await _wait(0.35)
	await _shot("l_all_three", player)
	print("worn looks: %d" % worn)
	player.run.look = {}
	player.refresh_look()


func _middle(layout: RoomLayout) -> Vector2:
	var size := layout.size_in_cells()
	return RoomBackdrop.cell_center(layout.nearest_floor_cell(Vector2i(size.x / 2, size.y / 2)))


func _enter_layout(layout: RoomLayout, quiet := true) -> void:
	var map: FloorMap = scene.debug_map()
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.cell = Vector2i(70 + room.id, 70)
	room.room_type = layout.room_type
	room.layout = layout
	room.decor_seed = 7 + room.id
	map.rooms.append(room)
	scene._enter_room(room.id)
	await _wait(0.4)
	view = scene.debug_room_view()
	if quiet:
		for enemy in get_nodes_in_group("enemies"):
			enemy.dismiss()
