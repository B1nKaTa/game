extends SceneTree
# Opens a real window and saves one screenshot of each part the last integration round meets in: the
# title screen, the Lobby, a run's HUD, a shop with a legendary and a cursed item, a real combo's
# banner, the big map with the Floor Plan and the Fortune Teller's tags, and the Ending Archive with
# its controller focus. Run only from an exported copy whose config/name is renamed.

const OUT := "D:/grandpa-look-final/"
const WALL_LIMIT_MS := 200000

var _start := 0
var progress


func _initialize() -> void:
	_start = Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(OUT)
	_main.call_deferred()


func _process(_d: float) -> bool:
	if Time.get_ticks_msec() - _start > WALL_LIMIT_MS:
		print("PROBE TIMEOUT")
		quit(3)
	return false


func _wait(seconds: float) -> void:
	var began := Time.get_ticks_msec()
	while Time.get_ticks_msec() - began < seconds * 1000.0:
		await process_frame


func _shot(shot_name: String) -> void:
	await process_frame
	var image := root.get_texture().get_image()
	image.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	image.save_png(OUT + shot_name + ".png")
	print("shot " + shot_name)


func _item(id: String) -> ItemDef:
	for item in Content.items():
		if item.id == id:
			return item
	return null


func _main() -> void:
	await process_frame
	progress = root.get_node("Progress")
	progress._store = SaveStore.new("user://look_save.json")
	progress._store.delete_all()
	progress.reload()
	progress.data.pension = 500
	progress.data.opening_seen = true
	change_scene_to_file("res://scenes/title.tscn")
	await _wait(1.5)
	await _shot("01_title")
	progress.last_run = {}
	change_scene_to_file("res://scenes/waiting_room.tscn")
	await _wait(1.2)
	await _shot("02_lobby")
	await _floor()
	await _archive()
	progress._store.delete_all()
	print("LOOK DONE")
	quit(0)


func _floor() -> void:
	change_scene_to_file("res://scenes/floor.tscn")
	await _wait(0.4)
	var scene := current_scene
	var player: Player = scene.player
	player.aim_source = func(): return player.global_position + Vector2(40, 0)
	scene.debug_choose_path(0)
	await _wait(0.3)
	# The floor's first room is a live fight behind the map, so he is kept from dying in the shots.
	player.run.health.lethal_saves = 99
	# The real floor's big map, with the Floor Plan's rooms and the Fortune Teller's boss tags.
	player.run.add_item(_item("floor_plan"))
	player.run.add_item(_item("fortune_card"))
	await _wait(0.2)
	scene.debug_big_map().set_open(true)
	await _wait(0.3)
	await _shot("06_map_plan_and_tags")
	scene.debug_big_map().set_open(false)
	await _wait(0.2)
	var source: RoomLayout = load("res://data/rooms/floor_1/combat_02.tres")
	player.run.health.heal(player.run.health.max_pills)
	await _enter_layout(scene, source.duplicate())
	await _wait(1.2)
	await _shot("03_run_hud")
	for enemy in get_nodes_in_group("enemies"):
		enemy.dismiss()
	await _wait(0.2)
	var shop: RoomLayout = load("res://data/rooms/floor_1/shop_01.tres")
	await _enter_layout(scene, shop.duplicate())
	var view: RoomView = scene.debug_room_view()
	var cells: Array[Vector2i] = view._room.layout.cells_of("S")
	var floor_mult: float = scene.debug_floor_def().pension_mult
	for child in view.get_children():
		if child is Pickup and child._label.contains(":") and not (child._label.begins_with("Heal") or child._label.begins_with(RoomRules.KEY_NAME) or child._label.begins_with(RoomRules.BOMB_NAME)):
			child.queue_free()
	var wares := ["rolling_pin", "nitro_tablets"]
	for i in wares.size():
		var item := _item(wares[i])
		view._add_shop_entry(RoomBackdrop.cell_center(cells[i]), {"kind": ShopRules.KIND_ITEM, "price": ShopRules.item_price(item, floor_mult, 0.0), "item": item})
	player.global_position = RoomBackdrop.cell_center(cells[0]) + Vector2(RoomBackdrop.TILE * 2, RoomBackdrop.TILE * 2) - Player.FEET_OFFSET
	await _wait(0.4)
	await _shot("04_shop_legendary_cursed")
	# A real combo: Titanium Hip and Wheelchair Wheels make the Mobility Scooter.
	player.run.add_item(_item("titanium_hip"))
	player.run.add_item(_item("wheelchair_wheels"))
	# A few frames, not real time: with --fixed-fps the game runs ahead of the clock, and the banner
	# lasts 2.5 s of game time.
	for i in 6:
		await process_frame
	print("scooter combo: %s" % player.run.effects.has_combo("mobility_scooter"))
	await _shot("05_combo_banner")


# The archive with three files found, focus moved onto it as a pad would.
func _archive() -> void:
	var data: ProgressData = progress.data
	data.record_floor_cleared(5, "head_office")
	data.departments_seen = {}
	for id in Departments.ALL:
		data.departments_seen[id["id"]] = true
	data.endings_found = {"briefly_alive": true, "literally": true, "eternal_feud": true}
	progress.last_run = {}
	change_scene_to_file("res://scenes/waiting_room.tscn")
	await _wait(0.5)
	var scene := current_scene
	scene.debug_enter_department(Departments.EXECUTIVE_SUITE)
	await _wait(0.2)
	scene.player.global_position = RoomBackdrop.cell_center(Vector2i(14, 8)) - Player.FEET_OFFSET
	await _wait(0.3)
	scene.use_station("ending_archive")
	await _wait(0.3)
	var event := InputEventAction.new()
	event.action = "ui_down"
	event.pressed = true
	Input.parse_input_event(event)
	await _wait(0.3)
	await _shot("07_ending_archive")


func _enter_layout(scene: Node, layout: RoomLayout) -> void:
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
