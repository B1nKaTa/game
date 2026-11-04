extends SceneTree
# Opens a real window and saves screenshots of Departures, Terminal Zero: its rooms beside earlier
# carpet floors, the queue barriers on the palest carpet, every enemy, both bosses' attacks, the props
# and departure boards, the lingering effects and the HUD over the palest tile.
# Run only from an exported copy whose config/name is renamed.
# Args after --: rooms | compare | barriers | enemies | props | wanda | augustine | all

const OUT := "D:/grandpa-look-airport/shots/"
const WALL_LIMIT_MS := 400000
const AIRPORT := 0

var _start := 0
var scene
var view: RoomView
var player: Player
var progress
var palette: RoomPalette


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
	for part in ["rooms", "compare", "barriers", "enemies", "props", "wanda", "augustine"]:
		if which == "all" or which == part:
			await call("_" + part)
	progress._store.delete_all()
	print("LOOK DONE")
	quit(0)


func _new_run(depth: int, path: int) -> void:
	change_scene_to_file("res://scenes/floor.tscn")
	await _wait(0.3)
	scene = current_scene
	player = scene.player
	scene._depth = depth
	scene.debug_choose_path(path)
	await _wait(0.2)
	view = scene.debug_room_view()
	palette = scene.debug_floor_def().room_palette()
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


# A decor seed that lays the palest carpet tone (floor_b, patch 1) on as many of these cells as it can.
func _pale_seed(cells: Array) -> int:
	# Tones come in 3x3 patches, so one cell per patch is enough to test.
	var blocks := {}
	for c: Vector2i in cells:
		blocks[Vector2i(floori(c.x / 3.0), floori(c.y / 3.0))] = c
	var best := 7
	var best_count := -1
	for s in range(1, 8000):
		var count := 0
		for c: Vector2i in blocks.values():
			if palette.patch_of(c, s) == 1:
				count += 1
		if count > best_count:
			best_count = count
			best = s
			if count == blocks.size():
				break
	print("pale seed %d covers %d of %d patches" % [best, best_count, blocks.size()])
	return best


func _cells_in(from: Vector2i, to: Vector2i) -> Array:
	var cells := []
	for y in range(from.y, to.y + 1):
		for x in range(from.x, to.x + 1):
			cells.append(Vector2i(x, y))
	return cells


func _enter_layout(layout: RoomLayout, decor_seed := -1) -> void:
	var map: FloorMap = scene.debug_map()
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.cell = Vector2i(70 + room.id, 70)
	room.room_type = layout.room_type
	room.layout = layout
	room.decor_seed = decor_seed if decor_seed >= 0 else 7 + room.id
	map.rooms.append(room)
	scene._enter_room(room.id)
	await _wait(0.15)
	view = scene.debug_room_view()


func _enter(rows: PackedStringArray, decor_seed := -1) -> RoomLayout:
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_HEALING
	layout.rows = rows
	await _enter_layout(layout, decor_seed)
	return layout


# A real layout with its props and barriers, but entered as a quiet room so nothing of its own spawns.
func _enter_quiet(file: String, decor_seed := -1) -> RoomLayout:
	var source: RoomLayout = load(file)
	var layout: RoomLayout = source.duplicate()
	layout.room_type = RoomLayout.TYPE_HEALING
	await _enter_layout(layout, decor_seed)
	await _clear()
	# The dismissed enemies' coins are taken at once, so they never show in a shot.
	for coin in _of(Pickup):
		if coin._label.begins_with("+"):
			coin.collect()
	await _wait(0.2)
	return layout


func _clear() -> void:
	player.aim_source = Callable()
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


func _freeze_enemies() -> void:
	for e in get_nodes_in_group("enemies"):
		e.set_physics_process(false)


func _barriers_at(time: float) -> void:
	for barrier in QueueBarrier.barriers_in(self):
		barrier._time = time
		barrier._forced = -1
		barrier._pending = -1
		barrier._pending_left = 0.0
		barrier._forced_left = 0.0


func _show_room(file: String, shot_name: String, decor_seed := -1, stand_cell := Vector2i(-1, -1)) -> void:
	var source: RoomLayout = load(file)
	var map: FloorMap = scene.debug_map()
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.cell = Vector2i(90 + room.id, 90)
	room.room_type = source.room_type
	room.layout = source
	room.decor_seed = decor_seed if decor_seed >= 0 else 7 + room.id
	map.rooms.append(room)
	scene._enter_room(room.id)
	await _wait(0.15)
	view = scene.debug_room_view()
	if stand_cell.x >= 0:
		_stand(_cell(stand_cell.x, stand_cell.y))
	else:
		_stand(RoomBackdrop.cell_center(source.door_cell(RoomLayout.SOUTH)))
	_freeze_enemies()
	await _wait(0.6)
	await _shot(shot_name)
	await _clear()


# --- rooms of each size, with their own enemies ---

func _rooms() -> void:
	await _new_run(5, AIRPORT)
	var f := "res://data/rooms/terminal_zero/%s.tres"
	for name in ["combat_small_01", "combat_01", "combat_large_01", "combat_large_02"]:
		await _show_room(f % name, "01_room_" + name)
	# The large room with the HUD over the palest carpet: Grandpa mid-room, so the top row is floor.
	var dseed := _pale_seed(_cells_in(Vector2i(5, 3), Vector2i(25, 3)))
	await _show_room(f % "combat_large_01", "02_large_room_hud_pale_floor", dseed, Vector2i(15, 8))


func _compare() -> void:
	await _new_run(2, 0)
	await _show_room("res://data/rooms/sunset_shores/combat_01.tres", "05_compare_sunset_combat_01")
	await _new_run(3, 0)
	await _show_room("res://data/rooms/funeral_parlour/combat_01.tres", "06_compare_parlour_combat_01")
	await _show_room("res://data/rooms/funeral_parlour/combat_large_01.tres", "07_compare_parlour_combat_large_01")


# --- the queue barriers, on the palest carpet ---

func _barriers() -> void:
	await _new_run(5, AIRPORT)
	var dseed := _pale_seed(_cells_in(Vector2i(4, 6), Vector2i(12, 6)) + _cells_in(Vector2i(4, 10), Vector2i(12, 10)))
	var layout := await _enter_quiet("res://data/rooms/terminal_zero/combat_large_01.tres", dseed)
	_stand(_cell(8, 8))
	# Enemies in the room, as the palette lesson asks.
	for entry: Array in [["tour_group", Vector2i(6, 7)], ["baggage_handler", Vector2i(11, 9)], ["lost_luggage", Vector2i(3, 9)]]:
		_spawn(entry[0], _cell(entry[1].x, entry[1].y))
	await _wait(0.1)
	_freeze_enemies()
	print("barriers %d" % QueueBarrier.barriers_in(self).size())
	_barriers_at(0.5)
	await _wait(0.2)
	await _shot("10_barriers_down_pale")
	_barriers_at(6.31)
	await _shot("11_barriers_chime_flash")
	_barriers_at(6.16)
	await _shot("12_barriers_chime_between_flashes")
	_barriers_at(7.5)
	await _wait(0.1)
	await _shot("13_barriers_up_pale")
	# A rope rising under his feet.
	_barriers_at(0.5)
	await _wait(0.1)
	_stand(_cell(6, 6))
	await _wait(0.1)
	var before: Vector2 = player.feet().global_position
	_barriers_at(6.95)
	await _wait(0.3)
	print("rope push: feet %s -> %s" % [str(before), str(player.feet().global_position)])
	await _shot("14_barrier_rose_under_grandpa")
	_barriers_at(0.5)
	await _clear()
	# The HUD in this room, Grandpa mid-room with every counter as the run has it.
	_stand(_cell(15, 8))
	await _wait(0.3)
	await _shot("15_hud_large_room")


# --- every enemy ---

func _enemies() -> void:
	await _new_run(5, AIRPORT)
	var dseed := _pale_seed(_cells_in(Vector2i(1, 1), Vector2i(18, 9)))
	await _enter(_rows(20, 11), dseed)
	# The roster side by side.
	_stand(_cell(3, 7))
	var ids := ["tour_group", "baggage_handler", "lost_luggage", "airport_weeping_mourner", "airport_mall_cop"]
	for i in ids.size():
		_spawn(ids[i], _cell(6 + i * 3, 4))
	await _wait(0.1)
	_freeze_enemies()
	await _shot("20_airport_roster")
	await _clear()
	# The Tour Group: the guide's flag, the call with every lane, the rush, then the lost followers.
	_stand(_cell(4, 5))
	var tourists: Array[Enemy] = []
	for at in [Vector2i(13, 4), Vector2i(13, 6), Vector2i(14, 5)]:
		tourists.append(_spawn("tour_group", _cell(at.x, at.y)))
	await _wait(1.0)
	await _shot("21_tour_guide_flag")
	await _until(func(): return tourists.any(func(t): return _warned(t, 0.45)), 10.0)
	await _shot("22_tour_call_lanes")
	await _until(func(): return not tourists.any(func(t): return is_instance_valid(t) and t._warning != null), 2.0)
	await _wait(0.12)
	await _shot("23_tour_rush")
	await _wait(0.5)
	var group = tourists[0].get_meta(TourGroup.META) if tourists[0].has_meta(TourGroup.META) else null
	if group != null and is_instance_valid(group.guide):
		group.guide.take_damage(9999.0, Vector2.ZERO)
	await _wait(0.4)
	await _shot("24_tour_followers_lost")
	await _clear()
	# The Baggage Handler: lane, cart run, and the daze after a wall.
	_stand(_cell(2, 5))
	var handler := _spawn("baggage_handler", _cell(8, 5))
	await _wait(0.2)
	handler.global_position = _cell(8, 5)
	await _until(func(): return _warned(handler, 0.5), 8.0)
	await _shot("25_handler_lane")
	await _until(func(): return is_instance_valid(handler) and handler._warning == null, 2.0)
	await _wait(0.12)
	await _shot("26_handler_cart_run")
	var dazed := await _until(func(): return is_instance_valid(handler) and handler._behavior.is_dazed(), 3.0)
	print("handler dazed %s" % dazed)
	await _shot("27_handler_dazed")
	await _clear()
	# Lost Luggage: lying still, the bite warned whole, the bite, then awake.
	_stand(_cell(4, 5))
	var bag := _spawn("lost_luggage", _cell(12, 5))
	await _wait(0.5)
	await _shot("28_luggage_lying")
	_stand(_cell(10, 5))
	await _until(func(): return _warned(bag, 0.4), 3.0)
	await _shot("29_luggage_bite_warning")
	await _until(func(): return is_instance_valid(bag) and bag._warning == null, 2.0)
	await _shot("30_luggage_bite")
	_stand(_cell(5, 5))
	await _wait(0.8)
	await _shot("31_luggage_awake")
	await _clear()
	# The returning pair in their airport colours: the wail and the scooter lane.
	_stand(_cell(4, 5))
	var mourners: Array[Enemy] = []
	for i in 3:
		mourners.append(_spawn("airport_weeping_mourner", _cell(13, 3 + i * 2)))
	await _until(func(): return mourners.any(func(m): return _warned(m, 0.5)), 8.0)
	await _shot("32_mourners_wail_warning")
	await _clear()
	_stand(_cell(4, 5))
	var cop := _spawn("airport_mall_cop", _cell(14, 5))
	await _until(func(): return _warned(cop, 0.5), 8.0)
	await _shot("33_cop_lane")
	await _clear()


# --- props and departure boards ---

func _props() -> void:
	await _new_run(5, AIRPORT)
	var rows := _rows(20, 11)
	for x in range(3, 7):
		_put(rows, Vector2i(x, 3), "8")
	for x in range(3, 7):
		_put(rows, Vector2i(x, 7), "8")
	_put(rows, Vector2i(9, 3), "6")
	_put(rows, Vector2i(11, 3), "6")
	_put(rows, Vector2i(9, 7), "7")
	_put(rows, Vector2i(11, 7), "7")
	for x in range(13, 18):
		_put(rows, Vector2i(x, 5), "=")
	var dseed := _pale_seed(_cells_in(Vector2i(2, 2), Vector2i(17, 8)))
	await _enter(rows, dseed)
	var items: Array[Dictionary] = []
	for i in 4:
		items.append({"kind": RoomDecor.DEPARTURE_BOARD, "cell": Vector2i(3 + i * 2, 9), "variant": i, "offset": Vector2.ZERO})
	items.append({"kind": RoomDecor.FLUORESCENT, "cell": Vector2i(13, 8), "variant": 0, "offset": Vector2.ZERO})
	items.append({"kind": "plant", "cell": Vector2i(15, 8), "variant": 0, "offset": Vector2.ZERO})
	var layer := DecorLayer.new()
	layer.setup(items, palette)
	view.add_child(layer)
	_stand(_cell(10, 5))
	_spawn("tour_group", _cell(15, 3))
	_spawn("lost_luggage", _cell(15, 7))
	await _wait(0.1)
	_freeze_enemies()
	await _wait(0.3)
	await _shot("40_props_and_boards")
	# Broken: a trolley and a suitcase stack, and their debris.
	for prop in _of(LuggageTrolley) + _of(SuitcaseStack):
		if prop.global_position.x < 340.0:
			prop.take_blast()
	await _wait(0.3)
	await _shot("41_props_broken")


# --- Sergeant Wanda ---

func _wanda() -> void:
	await _new_run(5, AIRPORT)
	var dseed := _pale_seed(_cells_in(Vector2i(8, 5), Vector2i(22, 11)))
	var layout := await _enter_quiet("res://data/rooms/terminal_zero/mini_boss_large_01.tres", dseed)
	var center := _cell(15, 8)
	_stand(center + Vector2(-110, 0))
	var wanda: Enemy = view._spawn_enemy(load("res://data/enemies/sergeant_wanda.tres"), center, true)
	var b = wanda._behavior
	b._summon_timer = 99.0
	await _wait(0.1)
	wanda.global_position = center
	b._cooldown = 99.0
	_barriers_at(0.5)
	b._begin(wanda, SecuritySergeantBehavior.Attack.XRAY)
	await _wait(SecuritySergeantBehavior.XRAY_WINDUP * 0.5)
	await _shot("50_wanda_xray_windup")
	await _wait(SecuritySergeantBehavior.XRAY_WINDUP * 0.5 + SecuritySergeantBehavior.XRAY_WARNING * 0.6)
	b._cooldown = 99.0
	await _shot("51_wanda_xray_warning_and_mat")
	var marks := _of(SafeSpotMark)
	if not marks.is_empty():
		_stand(marks[0].global_position)
	await _until(func(): return _of(XRaySweep).any(func(s): return s.is_sweeping()), 2.0)
	await _wait(0.45)
	b._cooldown = 99.0
	await _shot("52_wanda_xray_sweeping_on_mat")
	await _until(func(): return _of(XRaySweep).is_empty(), 5.0)
	b._cooldown = 99.0
	wanda.global_position = center
	_stand(center + Vector2(-90, 40))
	await _wait(0.3)
	b._begin(wanda, SecuritySergeantBehavior.Attack.XRAY)
	await _wait(SecuritySergeantBehavior.XRAY_WINDUP + SecuritySergeantBehavior.XRAY_WARNING * 0.5)
	b._cooldown = 99.0
	await _shot("53_wanda_xray_second_way_warning")
	await _until(func(): return _of(XRaySweep).any(func(s): return s.is_sweeping()), 2.0)
	await _wait(0.4)
	b._cooldown = 99.0
	await _shot("54_wanda_xray_second_way_sweeping")
	await _until(func(): return _of(XRaySweep).is_empty(), 5.0)
	# Trays.
	b._cooldown = 99.0
	wanda.global_position = center
	_stand(center + Vector2(-100, 10))
	await _wait(0.3)
	b._begin(wanda, SecuritySergeantBehavior.Attack.TRAYS)
	await _wait(SecuritySergeantBehavior.TRAY_WINDUP * 0.5)
	await _shot("55_wanda_trays_windup")
	await _wait(SecuritySergeantBehavior.TRAY_WINDUP * 0.5 + SecuritySergeantBehavior.TRAY_WARNING * 0.55)
	b._cooldown = 99.0
	await _shot("56_wanda_trays_warned")
	await _until(func(): return _of(TerminalStrike).any(func(s): return s._landed), 2.0)
	await _wait(0.08)
	b._cooldown = 99.0
	await _shot("57_wanda_trays_landing")
	await _wait(0.5)
	b._cooldown = 99.0
	# Summons.
	b._summon_timer = 0.0
	await _wait(0.4)
	b._cooldown = 99.0
	await _shot("58_wanda_summon_marks")
	await _wait(1.2)
	b._cooldown = 99.0
	_freeze_enemies()
	await _shot("59_wanda_lost_luggage")
	await _clear()


# --- Augustine ---

func _augustine() -> void:
	await _new_run(5, AIRPORT)
	var dseed := _pale_seed(_cells_in(Vector2i(9, 6), Vector2i(21, 11)))
	var layout := await _enter_quiet("res://data/rooms/terminal_zero/floor_boss_large_01.tres", dseed)
	var center := _cell(16, 8)
	_stand(_cell(12, 8))
	var boss: Enemy = view._spawn_enemy(load("res://data/enemies/augustine.tres"), center, true)
	var b = boss._behavior
	b._summon_timer = 99.0
	b._since_gate = -99.0
	await _wait(0.1)
	boss.global_position = center
	b._cooldown = 99.0
	_barriers_at(0.5)
	# The boarding stamp: the three-pill attack.
	b._begin(boss, HeadOfDeparturesBehavior.Attack.STAMP, false)
	# Timed by the mark's own fill, since a shot takes a while in a real window.
	var stamp_at := func(share: float) -> bool: return _of(TerminalStrike).any(func(s): return s._landed or s.fill() >= share)
	await _until(stamp_at.bind(0.25), 2.0)
	await _shot("60_aug_stamp_early")
	await _until(stamp_at.bind(0.5), 2.0)
	await _shot("61_aug_stamp_mid")
	await _until(stamp_at.bind(0.85), 2.0)
	await _shot("62_aug_stamp_late")
	await _until(func(): return _of(TerminalStrike).any(func(s): return s._landed), 1.0)
	b._cooldown = 99.0
	await _shot("63_aug_stamp_landed")
	await _wait(0.4)
	b._cooldown = 99.0
	await _shot("64_aug_departed_ink_later")
	await _wait(1.0)
	# The runway lights.
	b._cooldown = 99.0
	boss.global_position = center
	_stand(_cell(12, 8))
	await _wait(0.1)
	b._begin(boss, HeadOfDeparturesBehavior.Attack.RUNWAY, false)
	await _wait(HeadOfDeparturesBehavior.RUNWAY_WINDUP * 0.5)
	await _shot("65_aug_runway_windup")
	await _until(func(): return not _of(RunwayLane).is_empty(), 1.0)
	await _wait(HeadOfDeparturesBehavior.RUNWAY_WARNING * 0.5)
	b._cooldown = 99.0
	await _shot("66_aug_runway_warning")
	await _until(func(): return _of(RunwayLane).any(func(l): return l.is_lit()), 1.5)
	b._cooldown = 99.0
	await _shot("67_aug_runway_first_lit")
	await _wait(HeadOfDeparturesBehavior.RUNWAY_STEP * 2.0)
	b._cooldown = 99.0
	await _shot("68_aug_runway_third_lit")
	await _until(func(): return _of(RunwayLane).is_empty(), 3.0)
	# The gate change: every barrier down, then the chime, then every rope up.
	b._cooldown = 99.0
	boss.global_position = center
	_stand(_cell(13, 8))
	_barriers_at(0.5)
	await _wait(0.1)
	b._begin(boss, HeadOfDeparturesBehavior.Attack.GATE, false)
	await _wait(HeadOfDeparturesBehavior.GATE_WINDUP * 0.5)
	await _shot("69_aug_gate_windup")
	await _until(func(): return QueueBarrier.barriers_in(self).any(func(q): return q.is_chiming()), 1.0)
	await _wait(0.45)
	b._cooldown = 99.0
	await _shot("70_aug_gate_chime")
	await _until(func(): return QueueBarrier.barriers_in(self).all(func(q): return q.is_up()), 2.0)
	await _wait(0.1)
	b._cooldown = 99.0
	await _shot("71_aug_gate_all_up")
	await _wait(0.5)
	b._cooldown = 99.0
	_barriers_at(0.5)
	# The second phase: the line, Tour Groups, faster barriers, and the runway chained into the stamp.
	boss.hp = boss.max_hp() * 0.4
	await _wait(0.15)
	b._cooldown = 99.0
	await _shot("72_aug_phase2_now_boarding")
	b._summon_timer = 0.0
	await _wait(0.4)
	b._cooldown = 99.0
	await _shot("73_aug_phase2_summon_marks")
	await _wait(1.2)
	b._cooldown = 99.0
	_freeze_enemies()
	await _shot("74_aug_phase2_tour_groups")
	for e in get_nodes_in_group("enemies"):
		if e != boss:
			e.dismiss()
	b._summon_timer = 99.0
	boss.set_physics_process(true)
	var fast = QueueBarrier.barriers_in(self)[0].cycle() if not QueueBarrier.barriers_in(self).is_empty() else null
	if fast != null:
		print("phase two barrier period %.2f up %.2f chime %.2f" % [fast.period, fast.up_time, fast.chime])
		_barriers_at(fast.rise_at() - fast.chime + 0.3)
		await _shot("75_aug_phase2_fast_barrier_chime")
		_barriers_at(0.0)
	boss.global_position = center
	_stand(_cell(12, 8))
	await _wait(0.1)
	b._chained = false
	b._begin(boss, HeadOfDeparturesBehavior.Attack.RUNWAY, true)
	await _until(func(): return _of(TerminalStrike).any(func(s): return s.kind == TerminalStrike.LOOK_STAMP), 4.0)
	await _wait(0.3)
	await _shot("76_aug_phase2_runway_into_stamp")
	await _wait(0.5)
	await _shot("77_aug_phase2_chained_stamp_late")
	await _clear()
