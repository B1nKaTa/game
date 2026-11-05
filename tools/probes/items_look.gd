extends SceneTree
# Opens a real window and saves screenshots of the item system: the shop with rarity colours and a
# cursed item's skull, the combo banner and the paused map's combo list, the Lucky Bingo Card's pop,
# the Hearing Aid's off-screen arrows and the Nitroglycerin Tablets' blast.
# Run only from an exported copy whose config/name is renamed.
# Args after --: shop | combo | bingo | arrows | nitro | all

const OUT := "D:/grandpa-look-items/"
const WALL_LIMIT_MS := 200000

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
	if player != null and is_instance_valid(player) and not player.run.health.is_dead():
		player.run.health.pills = player.run.health.max_pills
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


func _stand(at: Vector2) -> void:
	player.global_position = at - Player.FEET_OFFSET


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
	var args := OS.get_cmdline_user_args()
	var which: String = args[0] if args.size() > 0 else "all"
	for part in ["shop", "combo", "bingo", "arrows", "nitro"]:
		if which == "all" or which == part:
			await _new_run()
			await call("_" + part)
	progress._store.delete_all()
	print("LOOK DONE")
	quit(0)


func _new_run() -> void:
	change_scene_to_file("res://scenes/floor.tscn")
	await _wait(0.3)
	scene = current_scene
	player = scene.player
	player.aim_source = func(): return player.global_position + Vector2(40, 0)
	scene.debug_choose_path(0)
	await _wait(0.2)
	view = scene.debug_room_view()
	await _clear()


func _clear() -> void:
	for enemy in get_nodes_in_group("enemies"):
		enemy.dismiss()
	await _wait(0.1)


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


func _open_room(width: int, height: int) -> void:
	var rows := PackedStringArray(["#".repeat(width)])
	for y in range(1, height - 1):
		rows.append("#" + ".".repeat(width - 2) + "#")
	rows.append("#".repeat(width))
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_HEALING
	layout.rows = rows
	await _enter_layout(layout)


func _spawn(id: String, at: Vector2) -> Enemy:
	var enemy: Enemy = view._spawn_enemy(load("res://data/enemies/%s.tres" % id), at, true)
	return enemy


# A shop whose two items for sale are a common and a cursed rare, with a free rare beside them.
func _shop() -> void:
	var source: RoomLayout = load("res://data/rooms/floor_1/shop_01.tres")
	await _enter_layout(source.duplicate())
	for child in view.get_children():
		if child is Pickup and child._label.contains(":") and not (child._label.begins_with("Heal") or child._label.begins_with(RoomRules.KEY_NAME) or child._label.begins_with(RoomRules.BOMB_NAME)):
			child.queue_free()
	var cells: Array[Vector2i] = view._room.layout.cells_of("S")
	var floor_mult: float = scene.debug_floor_def().pension_mult
	for i in 2:
		var item := _item(["bingo_card", "nitro_tablets"][i])
		view._add_shop_entry(RoomBackdrop.cell_center(cells[i]), {"kind": ShopRules.KIND_ITEM, "price": ShopRules.item_price(item, floor_mult, 0.0), "item": item})
	var spot: Vector2 = RoomBackdrop.cell_center(cells[0]) + Vector2(0, RoomBackdrop.TILE * 3)
	view._add_free_item(spot, _item("bifocals"))
	_stand(RoomBackdrop.cell_center(cells[0]) + Vector2(RoomBackdrop.TILE * 2, RoomBackdrop.TILE * 2))
	await _wait(0.3)
	await _shot("shop_rarity")


# A combo made in the probe from two shipped items, so the real signal shows the real banner.
func _combo() -> void:
	await _open_room(20, 11)
	var combo := ComboDef.new()
	combo.id = "probe_card_shark"
	combo.display_name = "Card Shark"
	combo.item_a = "bingo_card"
	combo.item_b = "lucky_tee"
	var combos: Array[ComboDef] = [combo]
	player.run.effects.set_combos(combos)
	_stand(RoomBackdrop.cell_center(Vector2i(10, 6)))
	player.run.add_item(_item("bingo_card"))
	player.run.add_item(_item("lucky_tee"))
	await _wait(0.3)
	await _shot("combo_banner")
	scene.debug_big_map().set_open(true)
	await _wait(0.2)
	await _shot("combo_map_list")
	scene.debug_big_map().set_open(false)


func _bingo() -> void:
	await _open_room(20, 11)
	player.run.add_item(_item("bingo_card"))
	_stand(RoomBackdrop.cell_center(Vector2i(10, 6)))
	await _wait(0.2)
	for i in 5:
		view._collect_pension(3)
	await _wait(0.25)
	await _shot("bingo_pop")


# A large room with Grandpa in one corner and enemies out of view in the others.
func _arrows() -> void:
	await _open_room(44, 26)
	player.run.add_item(_item("hearing_aid"))
	_stand(RoomBackdrop.cell_center(Vector2i(5, 5)))
	for at: Vector2i in [Vector2i(40, 4), Vector2i(38, 22), Vector2i(6, 23), Vector2i(22, 13)]:
		var enemy := _spawn("intern_reaper", RoomBackdrop.cell_center(at))
		enemy.set_physics_process(false)
	await _wait(0.4)
	await _shot("offscreen_arrows")


func _nitro() -> void:
	await _open_room(20, 11)
	player.run.add_item(_item("nitro_tablets"))
	_stand(RoomBackdrop.cell_center(Vector2i(10, 6)))
	var enemies: Array[Enemy] = []
	for offset: Vector2 in [Vector2(40, 0), Vector2(-36, 20), Vector2(0, -50), Vector2(150, 0)]:
		var enemy := _spawn("intern_reaper", player.feet().global_position + offset)
		enemy.set_physics_process(false)
		enemies.append(enemy)
	await _wait(0.2)
	var hp_before: float = enemies[0].hp
	player.take_hit(2)
	await _wait(0.08)
	await _shot("nitro_blast")
	var near_left: float = enemies[0].hp if is_instance_valid(enemies[0]) else 0.0
	print("nitro: near enemy %.0f -> %.0f, far enemy %.0f of %.0f" % [hp_before, near_left, enemies[3].hp, enemies[3].max_hp()])
