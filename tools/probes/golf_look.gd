extends SceneTree
# Opens a real window and saves screenshots of Fairway's End Golf Club: its rooms with enemies in them,
# the sand beside the striped fairway, every prop, every enemy and every attack of Chip and the Club
# President, and the lingering effects and the HUD over the palest tile in a large room.
# Run only from an exported copy whose config/name is renamed.
# Args after --: rooms | props | enemies | chip | president | pale | all

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
	for part in ["rooms", "props", "enemies", "chip", "president", "pale"]:
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
	var f := "res://data/rooms/fairways_end/%s.tres"
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


# --- the regular enemies ---

func _enemies() -> void:
	await _new_run()
	var rows := _rows(20, 11)
	_fill(rows, Vector2i(12, 7), Vector2i(15, 8), "s")
	await _enter(rows)
	# The whole roster side by side.
	_stand(_cell(3, 8))
	var ids := ["caddie", "club_golfer", "gopher", "golf_bingo_caller", "golf_soot_ghost"]
	for i in ids.size():
		var e := _spawn(ids[i], _cell(4 + i * 3, 4))
		e.set_physics_process(false)
	await _wait(0.2)
	await _shot("30_roster")
	await _clear()
	# The Caddie: the lane, then the cart.
	_stand(_cell(4, 5))
	var caddie := _spawn("caddie", _cell(11, 5))
	await _until(func(): return _warned(caddie, 0.45), 8.0)
	await _shot("31_caddie_lane")
	await _until(func(): return is_instance_valid(caddie) and caddie._behavior._charge_left > 0.0, 2.0)
	await _wait(0.12)
	await _shot("32_caddie_cart_charge")
	await _wait(0.6)
	await _shot("33_caddie_rest")
	await _clear()
	# The Club Golfer: the fan, then the balls.
	_stand(_cell(4, 5))
	var golfer := _spawn("club_golfer", _cell(10, 5))
	await _until(func(): return _warned(golfer, 0.45), 8.0)
	await _shot("34_golfer_fan")
	await _until(func(): return not _of(GolfBallShot).is_empty(), 2.0)
	await _wait(0.2)
	await _shot("35_golfer_balls")
	await _clear()
	# The Gopher: the mound, the ring, and the bite.
	_stand(_cell(5, 5))
	var gopher := _spawn("gopher", _cell(15, 5))
	await _wait(0.3)
	await _shot("36_gopher_mound")
	await _until(func(): return _warned(gopher, 0.45), 6.0)
	await _shot("37_gopher_ring")
	await _until(func(): return is_instance_valid(gopher) and not gopher.submerged, 2.0)
	await _wait(0.1)
	await _shot("38_gopher_bite")
	# And the same rise on sand.
	_stand(_cell(13, 7))
	await _until(func(): return _warned(gopher, 0.45), 8.0)
	await _shot("39_gopher_ring_on_sand")
	await _clear()


# --- Chip, Club Pro ---

func _chip() -> void:
	await _new_run()
	var layout := await _enter_quiet("res://data/rooms/fairways_end/mini_boss_01.tres")
	var center := _middle(layout)
	_stand(_floor_near(layout, center + Vector2(-100, 20)))
	var chip: Enemy = view._spawn_enemy(load("res://data/enemies/chip.tres"), center, true)
	var b = chip._behavior
	held.append(b)
	b._summon_timer = 99.0
	await _wait(0.1)
	chip.global_position = center
	b._cooldown = 99.0
	b._begin(chip, ClubProBehavior.Attack.CHIP)
	await _wait(ClubProBehavior.CHIP_WARNING * 0.5)
	await _shot("40_chip_chip_spots")
	await _until(func(): return _of(GolfBallLob).any(func(s): return s._landed), 2.0)
	await _shot("41_chip_chip_landing")
	await _wait(0.8)
	b._cooldown = 99.0
	chip.global_position = center
	_stand(_floor_near(layout, center + Vector2(-110, -10)))
	await _wait(0.1)
	b._begin(chip, ClubProBehavior.Attack.PUTT)
	await _wait(ClubProBehavior.PUTT_WINDUP * 0.5)
	await _shot("42_chip_putt_curve")
	await _until(func(): return _of(PuttRoll).any(func(p): return p.is_rolling()), 2.0)
	await _wait(0.2)
	b._cooldown = 99.0
	await _shot("43_chip_putt_rolling")
	await _wait(1.0)
	b._cooldown = 99.0
	b._summon_timer = 0.0
	await _wait(0.4)
	await _shot("44_chip_summon_marks")
	await _wait(1.0)
	b._cooldown = 99.0
	_freeze_all()
	await _shot("45_chip_gophers")
	await _clear()


# --- Club President Thaddeus Fairweather ---

func _president() -> void:
	await _new_run()
	var layout := await _enter_quiet("res://data/rooms/fairways_end/floor_boss_01.tres")
	var center := _middle(layout)
	_stand(_floor_near(layout, center + Vector2(-120, 10)))
	var boss: Enemy = view._spawn_enemy(load("res://data/enemies/thaddeus_fairweather.tres"), center, true)
	var b = boss._behavior
	held.append(b)
	b._caddie_timer = 99.0
	await _wait(0.1)
	boss.global_position = center
	b._cooldown = 99.0
	# Hold him still so his windups stay where they began.
	b._begin(boss, ClubPresidentBehavior.Attack.HOLE_IN_ONE, false)
	await _wait(0.15)
	await _shot("50_president_hole_in_one_early")
	await _wait(ClubPresidentBehavior.HOLE_IN_ONE_WINDUP * 0.5 - 0.15)
	await _shot("51_president_hole_in_one_mid")
	await _until(func(): return _of(GiantBallDrop).any(func(s): return s._landed), 2.0)
	await _shot("52_president_hole_in_one_lands")
	await _wait(0.8)
	b._cooldown = 99.0
	boss.global_position = center
	_stand(_floor_near(layout, center + Vector2(-140, 0)))
	await _wait(0.1)
	b._begin(boss, ClubPresidentBehavior.Attack.CART, false)
	await _wait(ClubPresidentBehavior.CART_WINDUP * 0.5)
	await _shot("53_president_cart_lane")
	await _until(func(): return b._dash.is_active(), 2.0)
	await _wait(0.12)
	await _shot("54_president_cart_charging")
	await _wait(1.0)
	b._cooldown = 99.0
	boss.global_position = center
	_stand(_floor_near(layout, center + Vector2(-90, 20)))
	await _wait(0.1)
	b._begin(boss, ClubPresidentBehavior.Attack.SPRINKLER, false)
	await _wait(ClubPresidentBehavior.SPRINKLER_WINDUP * 0.5)
	await _shot("55_president_sprinkler_windup")
	await _until(func(): return _of(SprinklerSweep).any(func(s): return s.is_sweeping()), 2.0)
	await _wait(0.5)
	b._cooldown = 99.0
	await _shot("56_president_sprinkler_sweeping")
	await _wait(1.3)
	b._cooldown = 99.0
	boss.global_position = center
	_stand(_floor_near(layout, center + Vector2(-90, 0)))
	await _wait(0.1)
	for old in _of(BunkerPatch):
		old.queue_free()
	await _wait(0.05)
	b._begin(boss, ClubPresidentBehavior.Attack.BUNKER, false)
	await _wait(BunkerPatch.WARNING * 0.5)
	await _shot("57_president_bunker_warning")
	await _until(func(): return _of(BunkerPatch).any(func(p): return p.is_laid()), 2.0)
	await _wait(0.2)
	b._cooldown = 99.0
	await _shot("58_president_bunker_sand")
	_stand(_floor_near(layout, center + Vector2(-90, 0)))
	await _wait(0.3)
	b._cooldown = 99.0
	await _shot("59_president_grandpa_in_spread_sand")
	await _wait(0.5)
	# The second phase: caddies, then a cart charge chained into a bunker spread.
	boss.hp = boss.max_hp() * 0.4
	boss.health_changed.emit(boss.hp)
	b._caddie_timer = 0.0
	for old in _of(BunkerPatch):
		old.queue_free()
	await _wait(0.4)
	b._cooldown = 99.0
	await _shot("60_president_phase2_caddie_marks")
	await _wait(1.0)
	b._cooldown = 99.0
	_freeze_all()
	await _shot("61_president_phase2_caddies")
	for e in get_nodes_in_group("enemies"):
		if e != boss:
			e.dismiss()
	boss.set_physics_process(true)
	b._caddie_timer = 99.0
	boss.global_position = center
	_stand(_floor_near(layout, center + Vector2(-140, 0)))
	await _wait(0.1)
	held.erase(b)
	b._cooldown = 99.0
	b._begin(boss, ClubPresidentBehavior.Attack.CART, true)
	await _until(func(): return b._dash.is_active(), 2.0)
	await _until(func(): return not b._dash.is_active(), 2.0)
	await _until(func(): return not _of(BunkerPatch).is_empty(), 2.0)
	await _wait(0.3)
	await _shot("62_president_phase2_cart_into_bunkers")
	await _clear()


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
	# Every effect over the sand: the hole in one, the chip spots, the putt, the bunker warning, the
	# sprinkler, the golfer's fan and the gopher's ring.
	_stand(_cell(10, 6))
	var boss: Enemy = view._spawn_enemy(load("res://data/enemies/thaddeus_fairweather.tres"), _cell(18, 6), true)
	var b = boss._behavior
	held.append(b)
	b._caddie_timer = 99.0
	await _wait(0.1)
	b._cooldown = 99.0
	b._begin(boss, ClubPresidentBehavior.Attack.HOLE_IN_ONE, false)
	await _wait(ClubPresidentBehavior.HOLE_IN_ONE_WINDUP * 0.5)
	await _shot("71_pale_hole_in_one")
	await _wait(1.2)
	b._cooldown = 99.0
	boss.global_position = _cell(18, 6)
	b._begin(boss, ClubPresidentBehavior.Attack.SPRINKLER, false)
	await _wait(ClubPresidentBehavior.SPRINKLER_WINDUP * 0.5)
	await _shot("72_pale_sprinkler_windup")
	await _wait(1.0)
	b._cooldown = 99.0
	await _shot("73_pale_sprinkler_jet")
	await _wait(1.2)
	b._cooldown = 99.0
	boss.global_position = _cell(18, 6)
	b._begin(boss, ClubPresidentBehavior.Attack.BUNKER, false)
	await _wait(BunkerPatch.WARNING * 0.6)
	await _shot("74_pale_bunker_warning_on_sand")
	await _until(func(): return _of(BunkerPatch).any(func(p): return p.is_laid()), 2.0)
	await _wait(0.2)
	await _shot("75_pale_bunker_laid_on_sand")
	boss.dismiss()
	await _wait(0.2)
	var chip: Enemy = view._spawn_enemy(load("res://data/enemies/chip.tres"), _cell(18, 6), true)
	var c = chip._behavior
	held.append(c)
	c._summon_timer = 99.0
	await _wait(0.1)
	c._cooldown = 99.0
	c._begin(chip, ClubProBehavior.Attack.CHIP)
	await _wait(ClubProBehavior.CHIP_WARNING * 0.5)
	await _shot("76_pale_chip_spots")
	await _wait(1.2)
	c._cooldown = 99.0
	chip.global_position = _cell(18, 6)
	c._begin(chip, ClubProBehavior.Attack.PUTT)
	await _wait(ClubProBehavior.PUTT_WINDUP * 0.5)
	await _shot("77_pale_putt_curve")
	await _wait(0.6)
	c._cooldown = 99.0
	await _shot("78_pale_putt_rolling")
	chip.dismiss()
	await _wait(0.2)
	var golfer := _spawn("club_golfer", _cell(17, 5))
	await _until(func(): return _warned(golfer, 0.45), 8.0)
	await _shot("79_pale_golfer_fan")
	await _until(func(): return not _of(GolfBallShot).is_empty(), 2.0)
	await _wait(0.15)
	await _shot("80_pale_golfer_balls")
	golfer.dismiss()
	var gopher := _spawn("gopher", _cell(20, 8))
	await _wait(0.3)
	await _shot("81_pale_gopher_mound")
	await _until(func(): return _warned(gopher, 0.45), 6.0)
	await _shot("82_pale_gopher_ring")
	gopher.dismiss()
	var caddie := _spawn("caddie", _cell(17, 6))
	await _until(func(): return _warned(caddie, 0.45), 8.0)
	await _shot("83_pale_caddie_lane")
	await _clear()
