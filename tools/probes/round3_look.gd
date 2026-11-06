extends SceneTree
# Opens a real window and saves screenshots of round 3: the HUD's item row with many items, Harold's
# case file on every tab (40 items held, page 1 and a later page, and the Waiting Room's empty case),
# the Chairman's new attack, the thicker desk slam ring, and a speech bubble near the top wall.
# Run only from an exported copy whose config/name is renamed.
# Args after --: hud | case | chairman | ring | bubble | all

const OUT := "D:/grandpa-shots-r3/"
const WALL_LIMIT_MS := 280000
const OFFICE := 1

var _start := 0
var scene
var view: RoomView
var player: Player
var progress
var _held = null
var _heal := true


func _initialize() -> void:
	_start = Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(OUT)
	_main.call_deferred()


func _process(_d: float) -> bool:
	if Time.get_ticks_msec() - _start > WALL_LIMIT_MS:
		print("PROBE TIMEOUT")
		quit(3)
	if _heal and player != null and is_instance_valid(player) and player.run != null:
		player.run.health.heal(99)
	if _held != null and is_instance_valid(_held):
		_held._cooldown = 99.0
		if "_chart_wait" in _held:
			_held._chart_wait = 99.0
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
	for part in ["hud", "case", "ring", "bubble", "chairman"]:
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
	await _clear()


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


func _give_items(count: int) -> void:
	var all: Array[ItemDef] = Content.items()
	for i in count:
		# A few copies of the first ones, so stacks show their counts.
		player.run.add_item(all[i % 34])
	player.run.refresh_stats()


# A saved history for the Stats, Log, Items and Bestiary tabs: a few finished runs.
func _seed_history() -> void:
	var data: ProgressData = progress.data
	data.run_count = 27
	var all: Array[ItemDef] = Content.items()
	var results := [RunLog.DIED, RunLog.DIED, RunLog.CLEARED, RunLog.ABANDONED, RunLog.DIED, RunLog.CLEARED]
	for n in results.size():
		var found: Array = []
		for i in 6:
			found.append(all[(n * 6 + i) % all.size()].id)
		var entry := {
			"n": 20 + n, "date": "2026-11-0%d 2%d:15:00" % [1 + n % 5, n % 4], "result": results[n],
			"depth": 2 + n % 4, "floor": ["Sunset Shores", "The Funeral Parlour", "Last Resort Cruise", "Terminal Zero"][n % 4],
			"room": "combat", "killer": ["Matron Mercy", "a Pallbearer", "", "", "Lorraine", ""][n], "time": 420.0 + n * 133.0,
			"seeds": ["k3x9-%d" % n, "pq7-%d" % n], "pension": 120 + n * 37,
			"kills": {"intern_reaper": 4 + n, "filing_clerk": 3, "orderly": n, "matron_mercy": 1 if n % 2 == 0 else 0},
			"met": ["intern_reaper", "filing_clerk", "orderly", "matron_mercy", "weeping_mourner", "pallbearer"],
			"found": found, "items": found, "hits": 5 + n, "cursed": n == 4,
		}
		data.record_run(entry)
	data.set_last_ending(EndingRules.BRIEFLY_ALIVE)


# --- the HUD row ---

func _hud() -> void:
	await _new_run(1, 0)
	_give_items(100)
	await _wait(0.3)
	await _shot("h1_hud_row_100_items")


# --- the case file ---

func _case() -> void:
	_seed_history()
	await _new_run(2, 0)
	_give_items(40)
	player.run.keys = 3
	player.run.note_kill("intern_reaper")
	player.run.note_kill("shores_seasonal_temp")
	await _wait(0.3)
	await _shot("c0_hud_row_40_items")
	scene.debug_open_case_file()
	await _wait(0.3)
	var file: CaseFile = scene.debug_case_file()
	await _shot("c1_harold_page1")
	file._turn_page(1)
	await _wait(0.2)
	await _shot("c2_harold_page2")
	file.show_tab_named(CaseFileData.TAB_ITEMS)
	await _wait(0.2)
	await _shot("c3_items_page1")
	file._turn_page(1)
	file._turn_page(1)
	await _wait(0.2)
	await _shot("c4_items_page3")
	file.show_tab_named(CaseFileData.TAB_BESTIARY)
	await _wait(0.2)
	await _shot("c5_bestiary")
	file.show_tab_named(CaseFileData.TAB_STATS)
	await _wait(0.2)
	await _shot("c6_stats")
	file.show_tab_named(CaseFileData.TAB_LOG)
	await _wait(0.2)
	await _shot("c7_log")
	file.close()
	await _wait(0.2)
	print("closed, paused=%s" % str(paused))
	change_scene_to_file("res://scenes/waiting_room.tscn")
	await _wait(0.6)
	player = current_scene.player
	current_scene.open_case_file()
	await _wait(0.3)
	await _shot("c8_waiting_room_no_case")
	current_scene.open_panel().close()
	await _wait(0.2)


# --- the desk slam ring ---

func _ring() -> void:
	await _new_run(5, OFFICE)
	var layout := await _enter_quiet("res://data/rooms/head_office/floor_boss_large_01.tres")
	var center := _middle(layout)
	var boss: Enemy = _spawn("chairman_of_the_board", center)
	var b = boss._behavior
	_held = b
	await _wait(0.1)
	boss.global_position = center
	_stand(center + Vector2(-50, 20))
	await _wait(0.1)
	b._begin(boss, ChairmanBehavior.Attack.SLAM, false)
	var slams := _of(DeskSlam)
	await _until(func(): return slams.any(func(s): return is_instance_valid(s) and s.fill() > 0.3), 2.0)
	await _shot("r1_desk_slam_ring_early")
	await _until(func(): return slams.any(func(s): return is_instance_valid(s) and s.fill() > 0.7), 2.0)
	await _shot("r2_desk_slam_ring_late")
	await _wait(0.6)
	b._begin(boss, ChairmanBehavior.Attack.GAVEL, false)
	await _wait(0.6)
	await _shot("r3_gavel_for_comparison")
	_held = null
	await _clear()


# --- a speech bubble near the top wall ---

func _bubble() -> void:
	# Someone stood right under the top wall of a large room, talking, with the camera scrolled.
	await _new_run(1, 0)
	var rows := PackedStringArray(["#".repeat(30)])
	for y in range(1, 16):
		rows.append("#" + ".".repeat(28) + "#")
	rows.append("#".repeat(30))
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_HEALING
	layout.rows = rows
	await _enter_layout(layout)
	var defs := DirAccess.get_files_at("res://data/npcs/")
	var def: NpcDef = null
	for file in defs:
		var loaded = load("res://data/npcs/" + file.trim_suffix(".remap"))
		if loaded is NpcDef and not loaded.lines.is_empty():
			def = loaded
			break
	if def == null:
		print("no npcs")
		return
	var npc := Npc.new()
	npc.setup(def, player)
	view.add_child(npc)
	npc.global_position = _cell(15, 1) + Vector2(0, 6)
	_stand(_cell(15, 3))
	await _wait(0.5)
	npc.talk()
	await _wait(1.5)
	await _shot("u1_bubble_near_top_wall")
	var boss: Enemy = _spawn("chairman_of_the_board", _cell(8, 2))
	_held = boss._behavior
	await _wait(0.2)
	boss.say("Restructuring!", 3.0)
	await _wait(0.3)
	await _shot("u2_boss_words_near_top_wall")
	_held = null
	await _clear()


# --- the Chairman's new attack (filled in with the attack) ---

func _chairman() -> void:
	await _new_run(5, OFFICE)
	var layout := await _enter_quiet("res://data/rooms/head_office/floor_boss_large_01.tres")
	var center := _middle(layout)
	for phase_two in [false, true]:
		var boss: Enemy = _spawn("chairman_of_the_board", center + Vector2(0, -60))
		var b = boss._behavior
		_held = b
		await _wait(0.1)
		if phase_two:
			boss.hp = boss.max_hp() * 0.4
			boss.health_changed.emit(boss.hp)
		_stand(_floor_near(layout, center + Vector2(-120, 50)))
		await _wait(0.1)
		b._begin(boss, ChairmanBehavior.Attack.PROJECTIONS, phase_two)
		await _until(func(): return not b._telegraph.is_active(), 2.0)
		await _wait(0.15)
		b._begin(boss, ChairmanBehavior.Attack.RESTRUCTURE, phase_two)
		var tag := "p2" if phase_two else "p1"
		var rows: Array = b._rows
		await _until(func(): return rows.any(func(r): return is_instance_valid(r) and not r.is_waiting() and r.fill() > 0.5), 3.0)
		await _shot("k1_%s_restructure_rows_warning" % tag)
		await _until(func(): return rows.any(func(r): return is_instance_valid(r) and r.has_landed()), 3.0)
		await _wait(0.05)
		await _shot("k2_%s_restructure_drawers_out" % tag)
		await _wait(1.0)
		await _shot("k3_%s_restructure_later" % tag)
		await _wait(2.5)
		_held = null
		await _clear()
		await _wait(0.5)
