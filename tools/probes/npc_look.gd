extends SceneTree
# Opens a real window and saves screenshots of the NPCs in their art: each Waiting Room department's
# people (Gerald in the lobby, Dolores, Bertram, the back room's Dealer, and the deep floors' keepers),
# the floor-1 shop's Shopkeeper and an Arcade's Dealer, each once with Harold away, so he idles, and
# once with Harold beside him, so he turns, with a line up. A 4x crop of each sits beside the shot.
# Run only from an exported copy whose config/name is renamed.
# Args after --: waiting | shop | all

const OUT := "D:/grandpa-shots-r4/"
const WALL_LIMIT_MS := 280000
const CROP := Vector2i(140, 90)

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
	if player != null and is_instance_valid(player) and player.run != null:
		player.run.health.heal(99)
	return false


func _wait(seconds: float) -> void:
	var began := Time.get_ticks_msec()
	while Time.get_ticks_msec() - began < seconds * 1000.0:
		await process_frame


# The whole view at 2x, and a 4x crop round npc so his pixels can be read.
func _shot(shot_name: String, npc: Node2D = null) -> void:
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	if npc != null:
		var at := Vector2i(npc.get_global_transform_with_canvas().origin)
		var corner := (at - CROP / 2).clamp(Vector2i.ZERO, image.get_size() - CROP)
		var crop := image.get_region(Rect2i(corner, CROP))
		crop.resize(CROP.x * 4, CROP.y * 4, Image.INTERPOLATE_NEAREST)
		crop.save_png(OUT + shot_name + "_x4.png")
	image.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	image.save_png(OUT + shot_name + ".png")
	print("shot " + shot_name)


func _stand(at: Vector2) -> void:
	player.global_position = at - Player.FEET_OFFSET
	player.velocity = Vector2.ZERO


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
	progress.data.record_floor_cleared(5, "head_office")
	progress.data.endings_found[EndingRules.ETERNAL_FEUD] = true
	var args := OS.get_cmdline_user_args()
	var which: String = args[0] if args.size() > 0 else "all"
	for part in ["waiting", "shop"]:
		if which == "all" or which == part:
			await call("_" + part)
	progress._store.delete_all()
	print("LOOK DONE")
	quit(0)


func _show_people(tag: String) -> void:
	for npc in _npcs_in(view):
		var feet := npc.global_position + Vector2(0, npc.def.body_size.y / 2.0)
		print("%s: %s art=%s at %s feet %s top %.0f" % [tag, npc.def.id, str(npc.has_art()), str(npc.global_position), str(feet), npc.head_top()])
		# Away, he idles facing out.
		_stand(feet + Vector2(0, 70))
		await _wait(0.4)
		await _shot("%s_%s_idle" % [tag, npc.def.id], npc)
		# Beside him, he turns to Harold, and says his line.
		_stand(feet + Vector2(-30, 4))
		await _wait(0.3)
		npc.talk()
		await _wait(1.2)
		await _shot("%s_%s_talking" % [tag, npc.def.id], npc)
		_stand(feet + Vector2(28, -6))
		await _wait(0.3)
		await _shot("%s_%s_facing_east" % [tag, npc.def.id], npc)


func _waiting() -> void:
	change_scene_to_file("res://scenes/waiting_room.tscn")
	await _wait(0.8)
	scene = current_scene
	player = scene.player
	for id in [Departments.LOBBY, Departments.BOUNTY_OFFICE, Departments.TRAINING_YARD, Departments.BACK_ROOM,
			Departments.PURSERS_OFFICE, Departments.PRO_SHOP, Departments.DUTY_FREE, Departments.EXECUTIVE_SUITE]:
		scene.debug_enter_department(id)
		await _wait(0.5)
		view = scene.debug_room_view()
		await _show_people("w_" + id)
	# The lobby whole, with Harold by Gerald for scale.
	scene.debug_enter_department(Departments.LOBBY)
	await _wait(0.5)
	view = scene.debug_room_view()
	for npc in _npcs_in(view):
		_stand(npc.global_position + Vector2(-40, npc.def.body_size.y / 2.0))
	await _wait(0.5)
	await _shot("w_lobby_whole")


func _shop() -> void:
	change_scene_to_file("res://scenes/floor.tscn")
	await _wait(0.4)
	scene = current_scene
	player = scene.player
	await _wait(0.2)
	for file in ["res://data/rooms/floor_1/shop_01.tres"]:
		var layout: RoomLayout = (load(file) as RoomLayout).duplicate()
		await _enter_layout(layout)
		await _show_people("s_floor_1_shop")
	var arcade := _first_of(RoomLayout.TYPE_ARCADE)
	if arcade != null:
		await _enter_layout(arcade.duplicate())
		await _show_people("s_arcade")


func _first_of(room_type: String) -> RoomLayout:
	for folder in DirAccess.get_directories_at("res://data/rooms/"):
		for layout in RoomCatalog.load_valid("res://data/rooms/%s/" % folder):
			if layout.room_type == room_type:
				return layout
	return null


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
	await _wait(0.3)
	view = scene.debug_room_view()
	for enemy in get_nodes_in_group("enemies"):
		enemy.dismiss()
