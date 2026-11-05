extends SceneTree
# Opens a real window and saves screenshots of round 2: contact damage (the touch, the shove out and a
# dodge through a body) on the first floor and the midnight course, the floor-5 bosses' overlaps (a
# gavel planned during a chart with the gap mark moved, the same in phase two with the tape, the desk
# slam's ring, burst and shove; Augustine's runway with the ropes up and its mark, a stamp and a gate
# change during a pattern), and the midnight golf course's risky spots (warnings far from any light,
# a Gopher on the grass, the Crossroads sign and both maps with the long name).
# Run only from an exported copy whose config/name is renamed.
# Args after --: contact | chairman | augustine | golf | all

const OUT := "D:/grandpa-shots-r2/"
const WALL_LIMIT_MS := 280000
const GOLF := 1
const AIRPORT := 0
const OFFICE := 1

var _start := 0
var scene
var view: RoomView
var player: Player
var progress
# A boss behavior kept from starting attacks of its own while the probe drives it.
var _held = null
# Whether Grandpa is healed every frame; off while a shot must show a pill lost.
var _heal := true


func _initialize() -> void:
	_start = Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(OUT)
	_main.call_deferred()


func _process(_d: float) -> bool:
	if Time.get_ticks_msec() - _start > WALL_LIMIT_MS:
		print("PROBE TIMEOUT")
		quit(3)
	if _heal and player != null and is_instance_valid(player):
		player.run.health.heal(99)
	if _held != null:
		_held._cooldown = 99.0
		if "_summon_timer" in _held:
			_held._summon_timer = 99.0
		if "_chart_wait" in _held:
			_held._chart_wait = 99.0
		if "_since_gate" in _held:
			_held._since_gate = -99.0
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
	progress.data.record_floor_cleared(5, "terminal_zero")
	var args := OS.get_cmdline_user_args()
	var which: String = args[0] if args.size() > 0 else "all"
	for part in ["contact", "chairman", "augustine", "golf"]:
		if which == "all" or which == part:
			await call("_" + part)
	progress._store.delete_all()
	print("LOOK DONE")
	quit(0)


func _new_run(depth: int, path: int) -> void:
	_held = null
	_heal = true
	change_scene_to_file("res://scenes/floor.tscn")
	await _wait(0.3)
	scene = current_scene
	player = scene.player
	scene._depth = depth
	scene.debug_choose_path(path)
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


func _enter(rows: PackedStringArray) -> RoomLayout:
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_HEALING
	layout.rows = rows
	await _enter_layout(layout)
	return layout


func _enter_quiet(file: String) -> RoomLayout:
	var source: RoomLayout = load(file)
	var layout: RoomLayout = source.duplicate()
	layout.room_type = RoomLayout.TYPE_HEALING
	await _enter_layout(layout)
	await _clear()
	for coin in _of(Pickup):
		if coin._label.begins_with("+"):
			coin.collect()
	await _wait(0.2)
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


func _feet() -> Vector2:
	return player.feet().global_position


# --- contact damage ---

func _contact() -> void:
	await _new_run(1, 0)
	await _contact_shots("c1")
	await _new_run(4, GOLF)
	await _contact_shots("c2")


func _contact_shots(tag: String) -> void:
	await _enter(_rows(20, 11))
	var center := _cell(10, 6)
	var grunt := _spawn("intern_reaper" if tag == "c1" else "club_golfer", center)
	await _wait(0.8)
	grunt.set_physics_process(false)
	grunt._wake_left = 0.0
	# Pinned back on its spot, since it walked while the room woke; feet go by its body.
	grunt.global_position = center
	center = grunt.body_rect().get_center()
	_heal = false
	_stand(center + Vector2(-80, 0))
	await _until(func(): return player.run.health.invulnerability_left() <= 0.0, 3.0)
	var pills: int = player.run.health.pills
	_stand(center + Vector2(6, 0))
	await _until(func(): return player.run.health.pills != pills, 0.6)
	print("%s touch: pills %d to %d, feet %s" % [tag, pills, player.run.health.pills, str(_feet())])
	await _shot(tag + "_contact_touch")
	await _until(func(): return not player.is_pushed(), 0.5)
	print("%s after shove: feet %s" % [tag, str(_feet())])
	await _shot(tag + "_contact_after_shove")
	_heal = true
	await _until(func(): return player.run.health.invulnerability_left() <= 0.0 and player.dodge_cooldown_left() <= 0.0, 3.0)
	_stand(center + Vector2(-36, 0))
	await process_frame
	player.start_dodge(Vector2.RIGHT)
	await _until(func(): return ContactRule.touches(grunt.body_rect(), ContactRule.feet_box(_feet(), Player.FEET_BOX_SIZE)), 0.5)
	await _shot(tag + "_contact_dodge_through")
	await _wait(0.6)
	await _clear()


# --- the Chairman of the Board: overlaps ---

func _chairman() -> void:
	await _new_run(5, OFFICE)
	var layout := await _enter_quiet("res://data/rooms/head_office/floor_boss_large_01.tres")
	var center := _middle(layout)
	var boss: Enemy = _spawn("chairman_of_the_board", center)
	var b = boss._behavior
	_held = b
	await _wait(0.1)
	boss.global_position = center
	# A chart, then a gavel planned while its bars run.
	_stand(_floor_near(layout, center + Vector2(-140, 40)))
	await _wait(0.1)
	b._begin(boss, ChairmanBehavior.Attack.PROJECTIONS, false)
	await _until(func(): return not _of(LaneDrop).is_empty(), 2.0)
	var feet := _feet()
	b._begin(boss, ChairmanBehavior.Attack.GAVEL, false)
	var gavels := _of(GavelStrike)
	print("gavel at %s, feet %s, mark %s" % [str(gavels[0].global_position) if not gavels.is_empty() else "none", str(feet), str(b._mark.global_position) if is_instance_valid(b._mark) else "none"])
	await _until(func(): return gavels.any(func(s): return is_instance_valid(s) and s.fill() > 0.3), 2.0)
	await _shot("b1_chart_gavel_planned")
	await _until(func(): return gavels.any(func(s): return is_instance_valid(s) and s.fill() > 0.75), 2.0)
	await _shot("b2_chart_gavel_late")
	await _until(func(): return _of(LaneDrop).is_empty(), 5.0)
	await _wait(0.5)
	# Boxed in against the wall at the bars' far end, so the gavel cannot fall on him.
	boss.global_position = center
	_stand(_floor_near(layout, Vector2(layout.size_in_cells().x * RoomBackdrop.TILE - 56, center.y)))
	await _wait(0.1)
	b._begin(boss, ChairmanBehavior.Attack.PROJECTIONS, false)
	await _until(func(): return not _of(LaneDrop).is_empty(), 2.0)
	await _wait(0.9)
	feet = _feet()
	b._begin(boss, ChairmanBehavior.Attack.GAVEL, false)
	gavels = _of(GavelStrike)
	print("late gavel at %s, feet %s" % [str(gavels[0].global_position) if not gavels.is_empty() else "none (held back)", str(feet)])
	await _until(func(): return gavels.any(func(s): return is_instance_valid(s) and s.fill() > 0.4), 2.0)
	await _shot("b3_chart_gavel_second")
	await _until(func(): return _of(LaneDrop).is_empty(), 5.0)
	await _wait(0.5)
	# Phase two: the tape goes up with the chart, and the gavel follows.
	boss.hp = boss.max_hp() * 0.4
	boss.health_changed.emit(boss.hp)
	b._since_tape = 99.0
	boss.global_position = center
	_stand(_floor_near(layout, center + Vector2(-140, 40)))
	await _wait(0.2)
	b._begin(boss, ChairmanBehavior.Attack.PROJECTIONS, true)
	await _until(func(): return not _of(LaneDrop).is_empty(), 2.0)
	b._begin(boss, ChairmanBehavior.Attack.GAVEL, true)
	gavels = _of(GavelStrike)
	await _until(func(): return gavels.any(func(s): return is_instance_valid(s) and s.fill() > 0.4), 2.0)
	await _shot("b4_phase2_chart_tape_gavel")
	await _until(func(): return _of(LaneDrop).is_empty(), 5.0)
	await _wait(0.5)
	for spread in _of(TapeSpread):
		spread.queue_free()
	await _wait(0.1)
	# The desk slam up close: the ring mid-windup, the papers, and Grandpa shoved out.
	boss.global_position = center
	_stand(center + Vector2(-50, 20))
	await _wait(0.1)
	b._begin(boss, ChairmanBehavior.Attack.SLAM, true)
	var slams := _of(DeskSlam)
	await _until(func(): return slams.any(func(s): return is_instance_valid(s) and s.fill() > 0.5), 2.0)
	await _shot("b5_desk_slam_ring")
	await _until(func(): return slams.any(func(s): return is_instance_valid(s) and s._landed), 2.0)
	await _shot("b6_desk_slam_papers")
	await _wait(0.15)
	await _shot("b7_desk_slam_shoved")
	await _wait(0.5)
	_held = null
	await _clear()


# --- Augustine: overlaps ---

func _ropes_up() -> void:
	var barriers := QueueBarrier.barriers_in(self)
	for step in 200:
		for barrier in barriers:
			barrier._time = step * 0.05
			barrier._forced = -1
			barrier._pending = -1
			barrier._pending_left = 0.0
			barrier._forced_left = 0.0
		await process_frame
		if barriers.all(func(q): return q.is_up() and not q.is_chiming()):
			return


func _augustine() -> void:
	await _new_run(5, AIRPORT)
	var layout := await _enter_quiet("res://data/rooms/terminal_zero/floor_boss_large_01.tres")
	var center := _cell(16, 8)
	var boss: Enemy = view._spawn_enemy(load("res://data/enemies/augustine.tres"), center, true)
	var b = boss._behavior
	_held = b
	await _wait(0.1)
	boss.global_position = center
	# The ropes first: each one rising under him would push him on.
	await _ropes_up()
	_stand(_cell(12, 8))
	await _wait(0.1)
	b._begin(boss, HeadOfDeparturesBehavior.Attack.RUNWAY, false)
	await _until(func(): return not _of(RunwayLane).is_empty(), 2.0)
	await _until(func(): return _of(RunwayLane).any(func(l): return l.is_lit()), 2.0)
	await _shot("a1_runway_ropes_up_mark")
	# A stamp while the pattern runs, with its mark beside it.
	b._begin(boss, HeadOfDeparturesBehavior.Attack.STAMP, false)
	var stamp_at := func(share: float) -> bool: return _of(TerminalStrike).any(func(s): return s._landed or s.fill() >= share)
	await _until(stamp_at.bind(0.5), 2.0)
	await _shot("a2_stamp_during_runway")
	await _until(func(): return _of(RunwayLane).is_empty(), 4.0)
	await _wait(0.6)
	# A gate change while the lanes light: the ropes' own chime.
	boss.global_position = center
	await _ropes_up()
	_stand(_cell(12, 8))
	await _wait(0.1)
	b._begin(boss, HeadOfDeparturesBehavior.Attack.RUNWAY, false)
	await _until(func(): return not _of(RunwayLane).is_empty(), 2.0)
	b._begin(boss, HeadOfDeparturesBehavior.Attack.GATE, false)
	await _until(func(): return QueueBarrier.barriers_in(self).any(func(q): return q.is_chiming()), 2.0)
	await _wait(0.3)
	await _shot("a3_gate_change_during_runway")
	await _until(func(): return _of(RunwayLane).is_empty(), 4.0)
	_held = null
	await _clear()


# --- the midnight course ---

func _golf() -> void:
	# The Crossroads sign with the long name, reached from the third floor.
	await _new_run(1, 0)
	scene._depth = 3
	scene._go_down()
	await _wait(0.6)
	var map: FloorMap = scene.debug_map()
	for room in map.rooms:
		if room.room_type == RoomLayout.TYPE_CROSSROADS:
			scene._enter_room(room.id)
	await _wait(0.4)
	view = scene.debug_room_view()
	if view is CrossroadsView:
		var sign_node = view.sign_of_path(GOLF)
		_stand(sign_node.global_position + Vector2(0, 16))
		await _wait(0.4)
		await _shot("g1_crossroads_golf_sign")
	# The mini map's top row and the big map with the long name.
	await _new_run(4, GOLF)
	await _wait(0.3)
	await _shot("g2_minimap_long_name")
	scene.debug_big_map().set_open(true)
	await _wait(0.2)
	await _shot("g3_big_map_long_name")
	scene.debug_big_map().set_open(false)
	await _wait(0.2)
	# Warnings far from any fill light, in the corners of a large room.
	await _enter(_rows(30, 17))
	_stand(_cell(2, 14))
	var gopher := _spawn("gopher", _cell(5, 14))
	await _until(func(): return _warned(gopher, 0.45), 8.0)
	await _shot("g4_dark_corner_gopher_ring")
	await _clear()
	_stand(_cell(3, 13))
	var golfer := _spawn("club_golfer", _cell(8, 14))
	await _until(func(): return _warned(golfer, 0.45), 8.0)
	await _shot("g5_dark_corner_golfer_fan")
	await _clear()
	_stand(_cell(27, 2))
	var caddie := _spawn("caddie", _cell(21, 2))
	await _until(func(): return _warned(caddie, 0.45), 8.0)
	await _shot("g6_dark_corner_caddie_lane")
	await _clear()
	_stand(_cell(3, 3))
	var chip: Enemy = _spawn("chip", _cell(8, 4))
	var c = chip._behavior
	_held = c
	await _wait(0.1)
	c._begin(chip, ClubProBehavior.Attack.CHIP)
	await _wait(ClubProBehavior.CHIP_WARNING * 0.5)
	await _shot("g7_dark_corner_chip_spots")
	await _wait(1.2)
	_held = null
	await _clear()
	_stand(_cell(26, 14))
	var boss: Enemy = _spawn("thaddeus_fairweather", _cell(21, 13))
	var t = boss._behavior
	_held = t
	t._caddie_timer = 99.0
	await _wait(0.1)
	t._begin(boss, ClubPresidentBehavior.Attack.HOLE_IN_ONE, false)
	await _wait(ClubPresidentBehavior.HOLE_IN_ONE_WINDUP * 0.5)
	await _shot("g8_dark_corner_hole_in_one")
	await _wait(1.2)
	# Phase two navy, mid room.
	boss.hp = boss.max_hp() * 0.4
	boss.health_changed.emit(boss.hp)
	boss.global_position = _cell(15, 8)
	_stand(_cell(11, 8))
	await _wait(0.4)
	await _shot("g9_president_phase2_navy")
	_held = null
	await _clear()
	# A Gopher up on the grass in the middle of the room.
	_stand(_cell(12, 8))
	var up := _spawn("gopher", _cell(15, 8))
	await _until(func(): return is_instance_valid(up) and not up.submerged, 8.0)
	up.set_physics_process(false)
	await _wait(0.1)
	await _shot("g10_gopher_on_grass")
	await _clear()
