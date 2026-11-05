extends SceneTree
# Opens a real window and saves screenshots of the first item batch's effects: the Cane Sword's wave,
# the Knitting Needles, the Brass Cane Topper's ring, Grandma's Rolling Pin, The Reaper's Other Scythe,
# the Bingo Dabber's marks, the glued dentures, the Spare Set's two sets, Boomerang Bite on its way home,
# the Fizzy Cleaning Tablet's fizz, the Wind-Up Teeth and the Shark Tooth's bleeding.
# Run only from an exported copy whose config/name is renamed.
# Args after --: <floor id> [part]. Parts: wave needles ring pin scythe dabs glue spare boomerang fizz
# windup bleed all

const OUT := "D:/grandpa-look-items1/"
const WALL_LIMIT_MS := 240000
const PARTS := ["wave", "needles", "ring", "pin", "scythe", "dabs", "glue", "spare", "boomerang", "fizz", "windup", "bleed"]

var _start := 0
var scene
var view: RoomView
var player: Player
var progress
var floor_id := "floor_1"


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


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


# Waits until a test holds, a frame at a time, up to a limit of frames. Returns whether it held.
func _until(test: Callable, limit := 240) -> bool:
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


# A tough enemy standing still, so the shot shows the effect on it and it never dies mid-shot.
func _dummy(at: Vector2, still := true) -> Enemy:
	var enemy: Enemy = view._spawn_enemy(load("res://data/enemies/intern_reaper.tres"), at, true)
	enemy.hp = 5000.0
	if still:
		enemy.set_physics_process(false)
	return enemy


func _aim_at(at: Vector2) -> void:
	player.aim_source = func(): return at


func _take(ids: Array) -> void:
	for id: String in ids:
		player.run.add_item(_item(id))


func _charged() -> void:
	player._swing(ChargeSwing.DAMAGE * player.run.charge_damage_mult(), Player.CHARGE_REACH, Player.CHARGE_ANGLE, ChargeSwing.KNOCKBACK, true, false)
	player.run.effects.charge_release(true)


func _wave() -> void:
	_take(["cane_sword"])
	_dummy(player.global_position + Vector2(130, 0))
	_dummy(player.global_position + Vector2(110, 26))
	_aim_at(player.global_position + Vector2(100, 0))
	await _frames(3)
	_charged()
	await _until(func(): return not get_nodes_in_group(ItemFx.GROUP).filter(func(n): return n is ItemFx.FxWave and n.travelled > 60.0).is_empty())
	await _shot("wave")


func _needles() -> void:
	_take(["knitting_needles"])
	_dummy(player.global_position + Vector2(110, -20))
	_aim_at(player.global_position + Vector2(100, 0))
	await _frames(3)
	player._swing(10.0, Player.ATTACK_REACH, Player.ATTACK_ANGLE, Player.ATTACK_PUSH, false, false)
	await _until(func(): return not get_nodes_in_group(ItemFx.GROUP).filter(func(n): return n is ItemFx.FxNeedle and n.travelled > 50.0).is_empty())
	await _shot("needles")


func _ring() -> void:
	_take(["brass_topper"])
	for offset: Vector2 in [Vector2(34, 0), Vector2(-34, 4), Vector2(0, 34)]:
		_dummy(player.global_position + offset)
	_aim_at(player.global_position + Vector2(100, 0))
	await _frames(3)
	player._swing(18.0, Player.ATTACK_REACH, Player.ATTACK_ANGLE, Player.ATTACK_PUSH, false, true)
	await _frames(2)
	await _shot("ring_finisher")


func _pin() -> void:
	_take(["rolling_pin"])
	for offset: Vector2 in [Vector2(46, 0), Vector2(-48, 6)]:
		_dummy(player.global_position + offset)
	_aim_at(player.global_position + Vector2(100, 0))
	await _frames(3)
	player._swing(10.0, Player.ATTACK_REACH, Player.ATTACK_ANGLE, Player.ATTACK_PUSH, false, false)
	await _until(func(): return player._active_swing != null and player._active_swing.progress() >= 0.45)
	await _shot("rolling_pin")


func _scythe() -> void:
	_take(["reapers_scythe"])
	for offset: Vector2 in [Vector2(56, 0), Vector2(-50, 20), Vector2(10, -54)]:
		_dummy(player.global_position + offset)
	_aim_at(player.global_position + Vector2(100, 0))
	await _frames(3)
	_charged()
	await _until(func(): return player._active_swing != null and player._active_swing.progress() >= 0.4)
	await _shot("scythe_sweep")


func _dabs() -> void:
	_take(["bingo_dabber"])
	var enemy := _dummy(player.global_position + Vector2(60, 0))
	for i in 3:
		player.run.effects.land(enemy, 1.0, RunEffects.SWING)
	await _frames(4)
	await _shot("dabber_marks")


func _glue() -> void:
	_take(["glue_gun"])
	var enemy := _dummy(player.global_position + Vector2(110, 0), false)
	_aim_at(enemy.global_position)
	await _frames(3)
	player._throw_teeth()
	await _until(func(): return player.teeth_out().size() > 0 and player.teeth_out()[0].is_glued())
	await _frames(25)
	await _shot("glued_dentures")


func _spare() -> void:
	_take(["spare_set"])
	_aim_at(player.global_position + Vector2(200, 0))
	await _frames(3)
	player._throw_teeth()
	await _frames(14)
	await _shot("two_sets")


func _boomerang() -> void:
	_take(["boomerang_bite"])
	_dummy(player.global_position + Vector2(90, 30))
	_aim_at(player.global_position + Vector2(200, 0))
	await _frames(3)
	player._throw_teeth()
	await _until(func(): return player.teeth_out().size() > 0 and player.teeth_out()[0]._state.is_returning())
	await _frames(8)
	await _shot("boomerang")


func _fizz() -> void:
	_take(["fizzy_tablet"])
	var enemy := _dummy(player.global_position + Vector2(90, 0))
	_aim_at(enemy.global_position)
	await _frames(3)
	player._throw_teeth()
	await _until(func(): return not get_nodes_in_group(ItemFx.GROUP).filter(func(n): return n is ItemFx.FxFizz).is_empty())
	await _frames(12)
	await _shot("fizz")


func _windup() -> void:
	_take(["windup_teeth"])
	_aim_at(player.global_position + Vector2(120, 0))
	await _frames(3)
	player._throw_teeth()
	await _until(func(): return player.teeth_out().size() > 0 and player.teeth_out()[0]._state.is_dropped())
	var walker := _dummy(player.teeth_out()[0].global_position + Vector2(40, -4), false)
	walker.target = player
	await _frames(30)
	await _shot("windup_teeth")


func _bleed() -> void:
	_take(["shark_tooth"])
	var enemy := _dummy(player.global_position + Vector2(70, 0))
	player.run.effects.bite(enemy)
	player.run.effects.bite(enemy)
	await _frames(40)
	await _shot("bleeding")
	print("bleed: enemy at %.0f of %.0f after 2 bites and about 0.7 s" % [enemy.hp, 5000.0])
