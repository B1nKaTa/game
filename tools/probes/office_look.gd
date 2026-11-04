extends SceneTree
# Opens a real window and saves screenshots of Head Office, Eternity Incorporated: its rooms next to
# the Records Basement's, every enemy and attack, both bosses, red tape and every lingering effect on
# the palest carpet tile, each prop, and the HUD over the carpet in a large room.
# Run only from an exported copy whose config/name is renamed.
# Args after --: rooms | roster | tape | props | enemies | doreen | chairman | all

const OUT := "D:/grandpa-look-office/shots/"
const WALL_LIMIT_MS := 280000
const TERMINAL := 0
const OFFICE := 1

var _start := 0
var scene
var view: RoomView
var player: Player
var progress
# A boss behavior kept from starting attacks of its own while the probe drives it.
var _held = null
var _hold_summons := true


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
	if _held != null:
		_held._cooldown = 99.0
		if _hold_summons and "_summon_timer" in _held:
			_held._summon_timer = 99.0
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
	for part in ["rooms", "roster", "tape", "props", "enemies", "doreen", "chairman"]:
		if which == "all" or which == part:
			await call("_" + part)
	progress._store.delete_all()
	print("LOOK DONE")
	quit(0)


func _new_run(depth: int, path: int) -> void:
	_held = null
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


func _put(rows: PackedStringArray, cell: Vector2i, symbol: String) -> void:
	var row := rows[cell.y]
	rows[cell.y] = row.substr(0, cell.x) + symbol + row.substr(cell.x + 1)


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


# The palest floor cell of the room now shown, inside the given cell rectangle, by its carpet colour.
func _palest_cell(layout: RoomLayout, area: Rect2i) -> Vector2i:
	var palette: RoomPalette = scene.debug_floor_def().palette
	var seed_value: int = scene.debug_map().room(scene.debug_current_id()).decor_seed
	var best := area.position
	var best_light := -1.0
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var cell := Vector2i(x, y)
			if layout.symbol_at(cell) != ".":
				continue
			var light := palette.floor_color(cell, seed_value).get_luminance()
			if light > best_light:
				best_light = light
				best = cell
	print("palest cell %s light %.3f" % [str(best), best_light])
	return best


# --- rooms: the office's small, medium and large, then the Records Basement's ---

func _show_room(file: String, type: String, shot_name: String) -> void:
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
	_stand(RoomBackdrop.cell_center(source.door_cell(RoomLayout.SOUTH)))
	_freeze_all()
	await _wait(0.6)
	await _shot(shot_name)
	if source.size_in_cells().x > 20:
		# The far end of a wide room, where the camera's other limit is.
		_stand(RoomBackdrop.cell_center(source.nearest_floor_cell(Vector2i(2, 2))))
		await _wait(0.5)
		await _shot(shot_name + "_topleft")
	await _clear()


func _rooms() -> void:
	await _new_run(5, OFFICE)
	var f := "res://data/rooms/head_office/%s.tres"
	for entry: Array in [["combat_small_01", "combat"], ["combat_01", "combat"], ["combat_large_01", "combat"], ["combat_04", "combat"], ["combat_large_02", "combat"]]:
		await _show_room(f % entry[0], entry[1], "01_office_" + entry[0])
	await _new_run(1, 0)
	var b := "res://data/rooms/floor_1/%s.tres"
	for entry: Array in [["combat_small_01", "combat"], ["combat_01", "combat"], ["combat_large_01", "combat"]]:
		await _show_room(b % entry[0], entry[1], "02_basement_" + entry[0])


# --- every enemy and both bosses side by side, with their marks ---

func _roster() -> void:
	await _new_run(5, OFFICE)
	await _enter(_rows(30, 17))
	_stand(_cell(15, 10))
	var ids := ["yes_man", "paper_shredder", "hr_representative", "office_florist", "office_perfume_sprayer"]
	for i in ids.size():
		_spawn(ids[i], _cell(7 + i * 4, 7))
	_spawn("doreen", _cell(10, 13))
	_spawn("chairman_of_the_board", _cell(20, 13))
	await _wait(0.1)
	_freeze_all()
	await _wait(0.2)
	await _shot("10_roster")
	await _clear()


# --- red tape on the palest carpet tile, cut, held, and the HUD over the carpet ---

func _tape() -> void:
	await _new_run(5, OFFICE)
	var layout := await _enter(_rows(30, 17))
	var pale := _palest_cell(layout, Rect2i(4, 4, 22, 9))
	var strand: Array[RedTape] = []
	for dx in range(-2, 3):
		var tape := RedTape.new()
		tape.across = true
		tape.position = RoomBackdrop.cell_center(pale + Vector2i(dx, 0))
		view.add_child(tape)
		strand.append(tape)
	var down: Array[RedTape] = []
	for dy in range(-2, 3):
		if dy == 0:
			continue
		var tape := RedTape.new()
		tape.across = false
		tape.position = RoomBackdrop.cell_center(pale + Vector2i(4, dy))
		view.add_child(tape)
		down.append(tape)
	_stand(RoomBackdrop.cell_center(pale + Vector2i(0, 3)))
	await _wait(0.4)
	await _shot("20_tape_strung_palest")
	strand[2].cut()
	strand[3].cut()
	await _wait(0.1)
	await _shot("21_tape_cut_palest")
	_stand(RoomBackdrop.cell_center(pale + Vector2i(-2, 0)))
	await _wait(0.12)
	print("held %s" % player.is_taped())
	await _shot("22_tape_grandpa_held")
	# A paper trail and a write-up on the same pale tile, with an HR Representative to own it.
	for tape in strand + down:
		tape.queue_free()
	var trail := PaperTrail.new()
	trail.setup(player, 30.0)
	view.add_child(trail)
	for i in 6:
		trail.add_scrap(RoomBackdrop.cell_center(pale) + Vector2(-60 + i * 18, 0))
	var rep := _spawn("hr_representative", _cell(25, 4))
	rep.set_physics_process(false)
	var mark := HrRepBehavior.throw_memo(rep, RoomBackdrop.cell_center(pale + Vector2i(0, 2)))
	_stand(RoomBackdrop.cell_center(pale + Vector2i(-4, 2)))
	await _until(func(): return mark.fill() > 0.5, 2.0)
	await _shot("23_writeup_warning_palest")
	await _until(func(): return mark.has_landed(), 2.0)
	await _wait(0.25)
	await _shot("24_writeup_lying_and_trail_palest")
	_stand(RoomBackdrop.cell_center(pale + Vector2i(0, 2)))
	await _wait(0.4)
	await _shot("25_writeup_sting_filling")
	_stand(RoomBackdrop.cell_center(pale))
	await _wait(0.3)
	await _shot("26_grandpa_in_paper_trail")
	await _clear()
	# A perfume cloud landing on him where he stands on the pale tile.
	_stand(RoomBackdrop.cell_center(pale))
	_spawn("office_perfume_sprayer", RoomBackdrop.cell_center(pale + Vector2i(7, 0)))
	await _until(func(): return _of(PerfumeCloud).any(func(c): return not c.has_landed()), 8.0)
	await _wait(0.5)
	await _shot("27_perfume_warning_palest")
	await _until(func(): return _of(PerfumeCloud).any(func(c): return c.has_landed()), 3.0)
	var clouds := _of(PerfumeCloud)
	if not clouds.is_empty():
		_stand(clouds[0].global_position)
	await _wait(0.8)
	_freeze_all()
	await _shot("28_perfume_haze_palest")
	await _clear()
	# The HUD with a boss bar up, over the carpet of a large room.
	var large := await _enter_quiet("res://data/rooms/head_office/combat_large_03.tres")
	_stand(_middle(large) + Vector2(0, -60))
	var boss := _spawn("chairman_of_the_board", _middle(large) + Vector2(120, 60))
	_held = boss._behavior
	await _wait(0.6)
	await _shot("29_hud_large_room_boss_bar")
	_held = null
	await _clear()


# --- the props ---

func _props() -> void:
	await _new_run(5, OFFICE)
	var rows := _rows(20, 11)
	for x in range(3, 8):
		_put(rows, Vector2i(x, 3), "N")
	for y in range(3, 7):
		_put(rows, Vector2i(3, y), "N")
	for cell: Vector2i in [Vector2i(10, 3), Vector2i(10, 7), Vector2i(16, 5)]:
		_put(rows, cell, "9")
	for cell: Vector2i in [Vector2i(13, 3), Vector2i(13, 7), Vector2i(6, 6), Vector2i(16, 8)]:
		_put(rows, cell, "y")
	for x in range(12, 16):
		_put(rows, Vector2i(x, 5), "x")
	_put(rows, Vector2i(6, 8), "x")
	_put(rows, Vector2i(6, 7), "x")
	await _enter(rows)
	_stand(_cell(9, 9))
	await _wait(0.5)
	await _shot("30_props")


# --- the regular enemies' attacks ---

func _enemies() -> void:
	await _new_run(5, OFFICE)
	await _enter(_rows(20, 11))
	# The Yes-Men: one leads a warned lunge, the other two echo it.
	_stand(_cell(5, 5))
	var men: Array[Enemy] = []
	for i in 3:
		men.append(_spawn("yes_man", _cell(9, 3 + i * 2)))
	await _until(func(): return men.any(func(m): return _warned(m, 0.4)), 8.0)
	await _shot("40_yesman_lead_warning")
	await _wait(0.3)
	await _shot("41_yesmen_echo_warnings")
	await _until(func(): return men.any(func(m): return is_instance_valid(m) and m._behavior._lunge_left > 0.0), 2.0)
	await _shot("42_yesmen_lunge")
	await _clear()
	# The Paper Shredder: its lane, the charge, and the trail behind it.
	_stand(_cell(4, 5))
	var shredder := _spawn("paper_shredder", _cell(14, 5))
	await _until(func(): return _warned(shredder, 0.5), 8.0)
	await _shot("43_shredder_lane")
	await _until(func(): return is_instance_valid(shredder) and shredder._behavior._charge_left > 0.0, 2.0)
	await _wait(0.25)
	await _shot("44_shredder_charge")
	await _wait(0.5)
	shredder.set_physics_process(false)
	await _shot("45_shredder_paper_trail")
	await _clear()
	# The HR Representative: her windup, the memo flying in, the landing.
	_stand(_cell(5, 5))
	var rep := _spawn("hr_representative", _cell(12, 5))
	await _until(func(): return _warned(rep, 0.5), 8.0)
	await _shot("46_hr_windup")
	await _until(func(): return _of(WriteUpMark).any(func(m): return m.fill() > 0.5), 3.0)
	await _shot("47_hr_memo_flying")
	await _until(func(): return _of(WriteUpMark).any(func(m): return m.has_landed()), 3.0)
	await _shot("48_hr_memo_lands")
	await _clear()
	# The office Florist's wreath.
	_stand(_cell(5, 6))
	_spawn("office_florist", _cell(16, 6))
	await _until(func(): return _of(GroundStrike).any(func(s): return s.fill() > 0.5), 8.0)
	await _shot("49_florist_wreath_mark")
	_stand(_cell(4, 2))
	await _until(func(): return _of(GroundStrike).any(func(s): return s.is_burning()), 3.0)
	await _wait(0.2)
	await _shot("50_florist_thorns")
	await _clear()


# --- Doreen ---

func _doreen() -> void:
	await _new_run(5, OFFICE)
	var layout := await _enter_quiet("res://data/rooms/head_office/mini_boss_large_01.tres")
	var center := _middle(layout)
	_stand(_floor_near(layout, center + Vector2(-110, 10)))
	var doreen: Enemy = _spawn("doreen", center)
	var b = doreen._behavior
	_held = b
	await _wait(0.1)
	doreen.global_position = center
	b._begin(doreen, DoreenBehavior.Attack.MEMOS)
	await _wait(DoreenBehavior.MEMO_WINDUP * 0.5)
	await _shot("60_doreen_memo_windup")
	await _until(func(): return _of(LaneDrop).any(func(d): return d.fill() > 0.5), 2.0)
	await _shot("61_doreen_memo_lanes_mid")
	await _until(func(): return _of(LaneDrop).any(func(d): return d.has_landed()), 2.0)
	await _wait(0.05)
	await _shot("62_doreen_memos_landing")
	await _wait(1.0)
	doreen.global_position = center
	b._begin(doreen, DoreenBehavior.Attack.MUSIC)
	await _wait(DoreenBehavior.MUSIC_WINDUP * 0.5)
	await _shot("63_doreen_music_spiral_warning")
	await _wait(DoreenBehavior.MUSIC_WINDUP * 0.5 + 0.5)
	await _shot("64_doreen_music_notes")
	await _wait(1.0)
	await _shot("65_doreen_music_notes_spread")
	await _wait(1.5)
	_hold_summons = false
	b._summon_timer = 0.0
	await _wait(0.4)
	await _shot("66_doreen_summon_marks")
	_hold_summons = true
	await _wait(1.2)
	_freeze_all()
	await _shot("67_doreen_yesmen")
	_held = null
	await _clear()


# --- the Chairman of the Board ---

func _chairman() -> void:
	await _new_run(5, OFFICE)
	var layout := await _enter_quiet("res://data/rooms/head_office/floor_boss_large_01.tres")
	var center := _middle(layout)
	_stand(_floor_near(layout, center + Vector2(-100, 20)))
	var boss: Enemy = _spawn("chairman_of_the_board", center)
	var b = boss._behavior
	_held = b
	await _wait(0.1)
	boss.global_position = center
	# The gavel, the three-pill attack: its warning shown whole, early, late, and landing.
	b._begin(boss, ChairmanBehavior.Attack.GAVEL, false)
	var gavels := _of(GavelStrike)
	await _until(func(): return gavels.any(func(s): return is_instance_valid(s) and s.fill() > 0.25), 2.0)
	await _shot("70_chairman_gavel_early")
	await _until(func(): return gavels.any(func(s): return is_instance_valid(s) and s.fill() > 0.5), 2.0)
	await _shot("71_chairman_gavel_mid")
	await _until(func(): return gavels.any(func(s): return is_instance_valid(s) and s.fill() > 0.85), 2.0)
	await _shot("72_chairman_gavel_late")
	await _until(func(): return gavels.any(func(s): return is_instance_valid(s) and s._landed), 1.0)
	await _shot("73_chairman_gavel_lands")
	await _wait(1.0)
	# The quarterly projections and the green gap.
	boss.global_position = center
	_stand(_floor_near(layout, center + Vector2(-100, 20)))
	await _wait(0.1)
	b._begin(boss, ChairmanBehavior.Attack.PROJECTIONS, false)
	await _wait(0.45)
	await _shot("74_chairman_projections_first_warning")
	await _until(func(): return _of(LaneDrop).any(func(d): return d.has_landed()), 2.0)
	await _wait(0.05)
	await _shot("75_chairman_projections_first_bar")
	await _wait(0.6)
	await _shot("76_chairman_projections_rising")
	await _wait(0.9)
	await _shot("77_chairman_projections_late")
	await _wait(1.5)
	# The hostile takeover: the tether, the pull, the charge lane and the charge.
	boss.global_position = center
	_stand(_floor_near(layout, center + Vector2(-180, 0)))
	await _wait(0.1)
	b._begin(boss, ChairmanBehavior.Attack.TAKEOVER, false)
	await _wait(ChairmanBehavior.TETHER_WINDUP * 0.5)
	await _shot("78_chairman_tether_mid")
	await _wait(ChairmanBehavior.TETHER_WINDUP * 0.5 + 0.12)
	await _shot("79_chairman_pull")
	await _until(func(): return b._attack == ChairmanBehavior.Attack.CHARGE and _warned(boss, 0.5), 2.0)
	await _shot("80_chairman_charge_lane")
	await _until(func(): return b._dash.is_active(), 1.0)
	await _wait(0.1)
	await _shot("81_chairman_charging")
	await _wait(1.2)
	# A snapped tether: Grandpa dodges in the windup.
	boss.global_position = center
	_stand(_floor_near(layout, center + Vector2(-180, 0)))
	await _wait(0.1)
	b._begin(boss, ChairmanBehavior.Attack.TAKEOVER, false)
	await _wait(0.3)
	Input.action_press("dodge")
	await process_frame
	await process_frame
	Input.action_release("dodge")
	await _wait(0.05)
	await _shot("82_chairman_tether_snapped")
	await _wait(1.0)
	# The second phase: the tape spread, warned then strung, and a projection chained into a gavel.
	boss.hp = boss.max_hp() * 0.4
	boss.global_position = center
	_stand(_floor_near(layout, center + Vector2(-100, 0)))
	await _wait(0.2)
	b._begin(boss, ChairmanBehavior.Attack.TAPE, true)
	await _wait(0.5)
	await _shot("83_chairman_tape_spread_warning")
	await _until(func(): return _of(TapeSpread).any(func(s): return s.is_strung()), 2.0)
	await _wait(0.1)
	await _shot("84_chairman_tape_spread_strung")
	await _wait(0.5)
	boss.global_position = center
	_stand(_floor_near(layout, center + Vector2(-100, 30)))
	await _wait(0.1)
	b._begin(boss, ChairmanBehavior.Attack.PROJECTIONS, true)
	await _wait(0.6)
	await _shot("85_chairman_phase2_projections")
	_held = null
	b._cooldown = 0.0
	await _until(func(): return b._attack == ChairmanBehavior.Attack.GAVEL and b._telegraph.is_active(), 4.0)
	_held = b
	await _wait(0.5)
	await _shot("86_chairman_phase2_chained_gavel")
	await _wait(1.0)
	_held = null
	await _clear()
