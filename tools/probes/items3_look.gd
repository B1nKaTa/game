extends SceneTree
# Opens a real window and saves screenshots of the third item batch's effects: the Hot Soup Thermos's
# puddle, the Kettle Whistle's stun, a plain blast beside the Pressure Cooker's bigger one, a shop with
# the Coupon Booklet's extra ware and the Haggler's Hat's half price, the Expired Coupon's free shop,
# the Lottery Scratcher's notice, the dark of Lights Out with and without the Night Light and with Night
# Shift, the Eternal Warranty bringing him back to the door, and the words the money items pop up.
# Run only from an exported copy whose config/name is renamed.
# Args after --: <floor id> [part]. Parts: soup kettle blast cooker shop free lottery dark night shift
# warranty words all

const OUT := "D:/grandpa-look-items3/"
const WALL_LIMIT_MS := 300000
const PARTS := ["soup", "kettle", "blast", "cooker", "shop", "free", "lottery", "dark", "night", "shift", "warranty", "words"]

var _start := 0
var scene
var view: RoomView
var player: Player
var progress
var floor_id := "floor_1"
# Whether _process keeps him on full pills. The Eternal Warranty shot wants him hurt.
var keep_full := true


func _initialize() -> void:
	_start = Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(OUT)
	_main.call_deferred()


func _process(_d: float) -> bool:
	if Time.get_ticks_msec() - _start > WALL_LIMIT_MS:
		print("PROBE TIMEOUT")
		quit(3)
	if keep_full and player != null and is_instance_valid(player) and not player.run.health.is_dead():
		player.run.health.pills = player.run.health.max_pills
	return false


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


# Real time, since a real window runs far above 60 frames a second.
func _seconds(seconds: float) -> void:
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		await physics_frame


func _until(test: Callable, limit := 20000) -> bool:
	for i in limit:
		if test.call():
			return true
		await physics_frame
	print("WAIT GAVE UP")
	return false


func _shot(shot_name: String) -> void:
	await process_frame
	var image := root.get_texture().get_image()
	image.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	image.save_png(OUT + floor_id + "_" + shot_name + ".png")
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
	floor_id = args[0] if args.size() > 0 else "floor_1"
	var which: String = args[1] if args.size() > 1 else "all"
	for part in PARTS:
		if which == "all" or which == part:
			await _new_run()
			await call("_" + part)
	progress._store.delete_all()
	print("LOOK DONE")
	quit(0)


func _new_run() -> void:
	keep_full = true
	change_scene_to_file("res://scenes/floor.tscn")
	await _frames(20)
	scene = current_scene
	player = scene.player
	player.aim_source = func(): return player.global_position + Vector2(40, 0)
	scene.debug_choose_path(0)
	await _frames(10)
	scene._floor_def = load("res://data/floors/%s.tres" % floor_id)
	await _open_room(_plain_layout(20, 11))
	for enemy in get_nodes_in_group("enemies"):
		enemy.dismiss()
	await _frames(5)
	_stand(_cell(6, 5))
	player.run.effects.room_enter(view)


func _plain_layout(width: int, height: int) -> RoomLayout:
	var rows := PackedStringArray(["#".repeat(width)])
	for y in range(1, height - 1):
		rows.append("#" + ".".repeat(width - 2) + "#")
	rows.append("#".repeat(width))
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_HEALING
	layout.rows = rows
	return layout


func _open_room(layout: RoomLayout) -> void:
	var map: FloorMap = scene.debug_map()
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.cell = Vector2i(70 + room.id, 70)
	room.room_type = layout.room_type
	room.layout = layout
	room.decor_seed = 7 + room.id
	map.rooms.append(room)
	scene._enter_room(room.id)
	await _frames(10)
	view = scene.debug_room_view()


func _cell(x: int, y: int) -> Vector2:
	return RoomBackdrop.cell_center(Vector2i(x, y))


# A tough enemy, standing still unless told to walk, so the shot shows the effect on it.
func _dummy(at: Vector2, still := true) -> Enemy:
	var enemy: Enemy = view._spawn_enemy(load("res://data/enemies/intern_reaper.tres"), at, true)
	enemy.hp = 5000.0
	if still:
		enemy.set_physics_process(false)
	return enemy


func _take(ids: Array) -> void:
	for id: String in ids:
		player.run.add_item(_item(id))


func _fx(kind: Script) -> Array:
	return get_nodes_in_group(ItemFx.GROUP).filter(func(n): return n.get_script() == kind)


func _thermoses() -> Array:
	return view.get_children().filter(func(n): return n is Thermos)


func _soup() -> void:
	_take(["hot_soup_thermos"])
	var at := _cell(12, 5)
	_dummy(at + Vector2(10, 4))
	_dummy(at + Vector2(-22, -6))
	view.place_bomb(at)
	await _until(func(): return not _fx(ItemFx.FxSoup).is_empty())
	await _seconds(0.5)
	await _shot("soup_puddle")
	await _seconds(1.5)
	await _shot("soup_puddle_late")


func _kettle() -> void:
	_take(["kettle_whistle"])
	var at := _cell(12, 5)
	var first := _dummy(at + Vector2(24, 0))
	var second := _dummy(at + Vector2(-20, 14))
	view.place_bomb(at)
	await _until(func(): return first.is_stunned())
	# Ticking again, so their stars are drawn while the stun holds them still.
	first.set_physics_process(true)
	second.set_physics_process(true)
	await _seconds(0.15)
	await _shot("kettle_stun")
	await _seconds(0.5)
	await _shot("kettle_stun_late")


# A blast at the moment it goes off, with a dummy standing just past the plain reach.
func _blast_shot(shot_name: String) -> void:
	var at := _cell(12, 5)
	_dummy(at + Vector2(66, 0))
	_dummy(at + Vector2(0, -50))
	view.place_bomb(at)
	var thermos: Thermos = _thermoses()[0]
	await _until(func(): return not is_instance_valid(thermos) or not thermos.is_fuse_burning())
	await _frames(2)
	await _shot(shot_name)


func _blast() -> void:
	await _blast_shot("blast_plain")


func _cooker() -> void:
	_take(["pressure_cooker"])
	print("cooker radius %.1f fuse %.2f" % [player.run.stats.blast_radius, Thermos.FUSE_TIME + player.run.stats.fuse_bonus])
	await _blast_shot("blast_cooker")


func _shop_room(ids: Array) -> void:
	_take(ids)
	var layout: RoomLayout = load("res://data/rooms/%s/shop_01.tres" % floor_id)
	await _open_room(layout)
	_stand(_cell(4, 8))
	await _seconds(0.4)


func _shop() -> void:
	await _shop_room(["coupon_booklet", "hagglers_hat"])
	await _shot("shop_coupon_haggle")


func _free() -> void:
	await _shop_room(["expired_coupon", "loaded_dice"])
	await _shot("shop_free")


func _lottery() -> void:
	_take(["lottery_scratcher"])
	var lottery = player.run.effects.effect_of("lottery_scratcher")
	lottery.rng.seed = 3
	player.run.effects.floor_start()
	await _seconds(0.3)
	await _shot("lottery_notice")


func _lights_out(seconds_dark := 6.0) -> void:
	var source := _dummy(_cell(16, 3))
	var dark := LightsOut.new()
	dark.setup(source, player, 0.2, seconds_dark)
	view.add_child(dark)
	_dummy(_cell(10, 5))
	_dummy(_cell(3, 8))
	await _until(func(): return dark.is_dark())
	await _seconds(0.3)


func _dark() -> void:
	await _lights_out()
	await _shot("dark_plain")


func _night() -> void:
	_take(["night_light"])
	await _lights_out()
	await _shot("dark_night_light")


func _shift() -> void:
	_take(["hearing_aid", "night_light"])
	print("night shift combo: %s" % player.run.effects.has_combo("night_shift"))
	await _lights_out()
	await _shot("dark_night_shift")


func _warranty() -> void:
	_take(["eternal_warranty"])
	var ctx := player.run.effects.ctx
	ctx.arrival = _cell(2, 5) - Player.FEET_OFFSET
	_stand(_cell(13, 6))
	_dummy(_cell(14, 6))
	keep_full = false
	player.run.health.pills = 1
	await _frames(3)
	print("warranty: hit landed %s" % player.take_hit(5))
	await _seconds(0.2)
	await _shot("warranty_door")
	print("warranty: pills %d of %d" % [player.run.health.pills, player.run.health.max_pills])


func _words() -> void:
	_take(["rubber_stamps", "pension_statement", "tax_refund"])
	player.run.keys = 1
	player.run.use_key()
	await _seconds(0.2)
	await _shot("words_stamp")
	await _seconds(0.9)
	player.run.pension_earned = 700
	player.run.effects.room_clear(view)
	await _seconds(0.2)
	await _shot("words_statement")
	await _seconds(0.9)
	player.run.effects.effect_of("tax_refund").leave_shop(player.run.effects.ctx, 1, 0)
	await _seconds(0.3)
	await _shot("words_tax_refund")
