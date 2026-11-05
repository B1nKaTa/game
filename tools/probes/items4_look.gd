extends SceneTree
# Opens a real window and saves screenshots of the fourth item batch's effects: the Bureaucrat's Stamp
# filing an enemy and taking its share of a boss, the Complaint Form's meter filling and filed, the big
# map with the Floor Plan, with the Fortune Teller's boss names and with both, the Wreath of Thorns
# pricking, the Harmonica's notes and chord, the Magnifying Glass's glint on a secret wall, the Alarm
# Clock ringing, and the Photo of the Grandkids' doubled hits.
# Run only from an exported copy whose config/name is renamed.
# Args after --: <floor id> [part]. Parts: stamp boss_stamp complaint plan names both wreath harmonica
# glint alarm photo all, or several joined by commas

const OUT := "D:/grandpa-look-items4/"
const WALL_LIMIT_MS := 300000
const PARTS := ["stamp", "boss_stamp", "complaint", "plan", "names", "both", "wreath", "harmonica", "glint", "alarm", "photo"]

var _start := 0
var scene
var view: RoomView
var player: Player
var progress
var floor_id := "floor_1"
# Whether _process keeps him on full pills. The Photo shot wants him on his last.
var keep_full := true
# Called every frame while set, to hold what a shot needs where it is.
var hold := Callable()


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
	if hold.is_valid():
		hold.call()
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
		if which == "all" or which.split(",").has(part):
			hold = Callable()
			await _new_run(part in ["plan", "names", "both"])
			await call("_" + part)
	hold = Callable()
	progress._store.delete_all()
	print("LOOK DONE")
	quit(0)


# A fresh run on the floor's first room, or, for the shots of the map, on the floor as built.
func _new_run(floor_as_built := false) -> void:
	keep_full = true
	if scene != null and is_instance_valid(scene) and scene.debug_big_map() != null:
		scene.debug_big_map().set_open(false)
	paused = false
	change_scene_to_file("res://scenes/floor.tscn")
	await _frames(20)
	scene = current_scene
	player = scene.player
	player.aim_source = func(): return player.global_position + Vector2(40, 0)
	scene.debug_choose_path(0)
	await _frames(10)
	if floor_as_built:
		return
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
func _dummy(at: Vector2, still := true, def_id := "intern_reaper") -> Enemy:
	var enemy: Enemy = view._spawn_enemy(load("res://data/enemies/%s.tres" % def_id), at, true)
	enemy.hp = 5000.0
	if still:
		enemy.set_physics_process(false)
	return enemy


# The floor's own boss, held still, at full health.
func _boss(at: Vector2) -> Enemy:
	var def: FloorDef = load("res://data/floors/%s.tres" % floor_id)
	var boss: Enemy = view._spawn_enemy(def.floor_boss, at, false)
	boss.set_physics_process(false)
	return boss


func _take(ids: Array) -> void:
	for id: String in ids:
		player.run.add_item(_item(id))


func _fx(kind: Script) -> Array:
	return get_nodes_in_group(ItemFx.GROUP).filter(func(n): return n.get_script() == kind)


func _stamp() -> void:
	_take(["bureaucrats_stamp"])
	var enemy := _dummy(_cell(9, 5))
	_dummy(_cell(12, 6))
	player.run.effects.land(enemy, 10.0, RunEffects.SWING)
	print("stamp: filed %s" % enemy.is_dead())
	await _seconds(0.05)
	await _shot("stamp_slam")
	await _seconds(0.4)
	await _shot("stamp_filed")
	# The coin it left would fly at him through later shots.
	for coin in view.get_children().filter(func(n): return n is Pickup):
		coin.queue_free()


func _boss_stamp() -> void:
	_take(["bureaucrats_stamp"])
	var boss := _boss(_cell(11, 5))
	await _frames(3)
	var before := boss.hp
	player.run.effects.land(boss, 10.0, RunEffects.SWING)
	print("boss stamp: %.0f of %.0f -> %.0f" % [before, boss.max_hp(), boss.hp])
	await _seconds(0.3)
	await _shot("stamp_boss")


func _complaint() -> void:
	_take(["complaint_form"])
	var boss := _boss(_cell(11, 5))
	await _frames(3)
	var full := boss.max_hp() * 0.2
	player.run.effects.land(boss, full * 0.6, RunEffects.SWING)
	await _seconds(0.3)
	await _shot("complaint_meter")
	player.run.effects.land(boss, full * 0.5, RunEffects.SWING)
	boss.set_physics_process(true)
	hold = func(): boss.desired_velocity = Vector2.ZERO
	print("complaint: stunned %s" % boss.is_stunned())
	await _seconds(0.3)
	await _shot("complaint_filed")


func _open_map(ids: Array) -> void:
	_take(ids)
	await _frames(3)
	scene.debug_big_map().set_open(true)
	await _frames(3)


func _plan() -> void:
	await _open_map(["floor_plan"])
	await _shot("map_plan")
	scene.debug_big_map().set_open(false)
	await _frames(3)
	await _shot("map_plan_corner")


func _names() -> void:
	await _open_map(["fortune_card"])
	await _shot("map_boss_names")


func _both() -> void:
	await _open_map(["floor_plan", "fortune_card"])
	await _shot("map_plan_and_names")


func _wreath() -> void:
	_take(["wreath_of_thorns"])
	player.run.effects.room_enter(view)
	await _seconds(0.3)
	await _shot("wreath")
	_dummy(player.global_position + Vector2(14, 0))
	await _until(func(): return not _fx(ItemFx.FxSparks).is_empty())
	await _shot("wreath_prick")


func _harmonica() -> void:
	_take(["harmonica"])
	var harmonica = player.run.effects.effect_of("harmonica")
	keep_full = false
	player.run.health.pills = 2
	harmonica.play(player.run.effects.ctx)
	await _seconds(0.3)
	harmonica.play(player.run.effects.ctx)
	await _seconds(0.25)
	await _shot("harmonica_notes")
	harmonica.play(player.run.effects.ctx)
	await _seconds(0.2)
	await _shot("harmonica_chord")


func _glint() -> void:
	_take(["magnifying_glass"])
	var wall := SecretWall.new()
	wall.position = _cell(14, 0)
	view.add_child(wall)
	var other := SecretWall.new()
	other.position = _cell(19, 7)
	view.add_child(other)
	player.run.effects.room_enter(view)
	var glints := _fx(ItemFx.FxGlint)
	print("glints: %d" % glints.size())
	if glints.is_empty():
		return
	var glint = glints[0]
	await _until(func(): return glint.flare() > 0.9)
	await _shot("glint_flare")
	await _until(func(): return glint.flare() <= 0.0)
	await _shot("glint_rest")


func _alarm() -> void:
	_take(["alarm_clock"])
	var near := _dummy(_cell(10, 5))
	var far := _dummy(_cell(14, 7))
	near.set_physics_process(true)
	far.set_physics_process(true)
	hold = func():
		for enemy in [near, far]:
			if is_instance_valid(enemy):
				enemy.desired_velocity = Vector2.ZERO
	player.run.effects.room_enter(view)
	print("alarm: stunned %s %s" % [near.is_stunned(), far.is_stunned()])
	await _seconds(0.15)
	await _shot("alarm_ring")
	await _seconds(0.5)
	await _shot("alarm_late")


func _photo() -> void:
	_take(["photo_of_grandkids"])
	keep_full = false
	player.run.health.pills = 1
	var enemy := _dummy(_cell(9, 5))
	var before := enemy.hp
	player.run.effects.land(enemy, 10.0, RunEffects.SWING)
	print("photo: a 10 hit took %.0f" % (before - enemy.hp))
	await _seconds(0.25)
	await _shot("photo_double")
