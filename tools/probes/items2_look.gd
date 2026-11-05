extends SceneTree
# Opens a real window and saves screenshots of the second item batch's effects: Bad Hip's cough, the
# Afterimage drawing enemies, Wheelchair Wheels rolling over them, the Banana Peel lying and tripping,
# the Mobility Scooter's fire trail, the Life Alert Button's block, Bubble Wrap popping, the Sympathy
# Card's heal and the words the other items pop up (Pogo Cane, Knitted Cardigan, Thick Skull, Casserole
# Dish, Second Opinion).
# Run only from an exported copy whose config/name is renamed.
# Args after --: <floor id> [part]. Parts: cough afterimage wheels peel scooter alert bubble sympathy
# words all

const OUT := "D:/grandpa-look-items2/"
const WALL_LIMIT_MS := 240000
const PARTS := ["cough", "afterimage", "wheels", "peel", "scooter", "alert", "bubble", "sympathy", "words"]

var _start := 0
var scene
var view: RoomView
var player: Player
var progress
var floor_id := "floor_1"
# Whether _process keeps him on full pills. The Second Opinion shot wants him hurt.
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
	await _open_room(20, 11)
	for enemy in get_nodes_in_group("enemies"):
		enemy.dismiss()
	await _frames(5)
	_stand(_cell(6, 5))
	player.run.effects.room_enter(view)


func _open_room(width: int, height: int) -> void:
	var rows := PackedStringArray(["#".repeat(width)])
	for y in range(1, height - 1):
		rows.append("#" + ".".repeat(width - 2) + "#")
	rows.append("#".repeat(width))
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_HEALING
	layout.rows = rows
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


func _cough() -> void:
	_take(["bad_hip"])
	_dummy(player.global_position + Vector2(-10, 30), false)
	_dummy(player.global_position + Vector2(-40, -6), false)
	await _frames(3)
	player.start_dodge(Vector2.RIGHT)
	await _seconds(0.45)
	await _shot("cough_cloud")


func _afterimage() -> void:
	_take(["afterimage"])
	for offset: Vector2 in [Vector2(-90, -30), Vector2(-100, 40), Vector2(60, 70)]:
		_dummy(player.global_position + offset, false)
	await _seconds(0.8)
	player.start_dodge(Vector2.RIGHT)
	await _seconds(0.4)
	await _shot("afterimage_lure")
	await _until(func(): return _fx(ItemFx.FxAfterimage).is_empty())
	await _seconds(0.4)
	await _shot("afterimage_after")


func _wheels() -> void:
	_take(["wheelchair_wheels"])
	_dummy(player.global_position + Vector2(40, 0))
	_dummy(player.global_position + Vector2(78, 4))
	await _frames(3)
	player.start_dodge(Vector2.RIGHT)
	await _frames(6)
	await _shot("wheels_roll")
	await _until(func(): return not player.is_dodging())
	await _frames(2)
	await _shot("wheels_after")


func _peel() -> void:
	_take(["banana_peel"])
	_stand(_cell(10, 5))
	var walker := _dummy(_cell(3, 5), false)
	walker.set_physics_process(false)
	await _frames(3)
	player.start_dodge(Vector2.RIGHT)
	await _until(func(): return not player.is_dodging())
	await _seconds(0.2)
	await _shot("peel_lying")
	walker.set_physics_process(true)
	await _until(func(): return walker.is_stunned())
	await _frames(4)
	await _shot("peel_trip")


func _scooter() -> void:
	_take(["titanium_hip", "wheelchair_wheels"])
	print("scooter combo: %s" % player.run.effects.has_combo("mobility_scooter"))
	_dummy(player.global_position + Vector2(130, 18))
	await _frames(3)
	player.start_dodge(Vector2.RIGHT)
	await _until(func(): return not player.is_dodging())
	await _frames(4)
	await _shot("scooter_trail")


func _alert() -> void:
	_take(["life_alert_button"])
	_dummy(player.global_position + Vector2(36, 0))
	await _frames(3)
	print("alert blocked: %s" % (not player.take_hit(1)))
	await _seconds(0.12)
	await _shot("life_alert_block")


func _bubble() -> void:
	_take(["bubble_wrap"])
	var shooter := _dummy(player.global_position + Vector2(140, 0))
	await _frames(3)
	var shot := shooter.shoot(Vector2.LEFT, 260.0)
	await _until(func(): return not is_instance_valid(shot))
	await _seconds(0.1)
	await _shot("bubble_pop")


func _sympathy() -> void:
	_take(["sympathy_card"])
	view._last_death_at = _cell(10, 6)
	player.run.effects.effect_of("sympathy_card").send(player.run.effects.ctx, view)
	await _seconds(0.25)
	await _shot("sympathy_heal")


func _words() -> void:
	_take(["pogo_cane", "knitted_cardigan", "thick_skull", "casserole_dish", "second_opinion"])
	player.run.effects.close_call()
	await _seconds(0.2)
	await _shot("words_pogo")
	await _seconds(0.9)
	player.take_fire_hit(1)
	await _seconds(0.2)
	await _shot("words_cardigan")
	await _seconds(0.9)
	player.take_hit(2, RunEffects.HURT_BLAST)
	await _seconds(0.2)
	await _shot("words_skull")
	await _seconds(0.9)
	var enemy := _dummy(player.global_position + Vector2(40, 0))
	player.run.effects.land(enemy, 99999.0, RunEffects.SWING)
	await _seconds(0.2)
	await _shot("words_casserole")
	await _seconds(0.9)
	keep_full = false
	player.run.health.pills = 1
	view._add_heal(player.feet().global_position + Vector2(30, 0), RoomView.HEAL_AMOUNT)
	_stand(player.feet().global_position + Vector2(30, 0))
	await _seconds(0.2)
	await _shot("words_second_opinion")
	print("second opinion: pills %d" % player.run.health.pills)
