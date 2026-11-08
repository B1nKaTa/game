extends SceneTree
# Opens a real window and shoots the combined branch (exits-warnings, waiting-props, cinema-story):
# every boss with Attack warnings off and a few with them on, the named boss tells (the Matron's Lights
# Out, Zara's swoops, the x-ray sweep, the wheel's blades), the cage lift (shut, folding open, open, in
# the Waiting Room), the Waiting Room's new props, and the Cinema's seats, lobby cards and new films.
# Run only from an exported copy whose config/name is renamed.
# Args after --: bosses | tells | lift | waiting | cinema | all, then optionally the folder.

const DEFAULT_OUT := "D:/grandpa-shots-ad/combined/"
const WALL_LIMIT_MS := 1500000
const FLOORS := {
	"floor_1": 1, "cemetery": 1, "sunset_shores": 2, "furnace_works": 2,
	"funeral_parlour": 3, "flashback_cinema": 3, "last_resort_cruise": 4, "seance_hotline": 4,
	"terminal_zero": 5, "head_office": 5,
}
const NEW_FILMS := ["bus_route", "wedding_day", "prize_marrow", "fishing_trip", "caravan_holiday"]

var OUT := DEFAULT_OUT
var _start := 0
var scene
var view: RoomView
var player: Player
var progress
var _hold := Callable()


func _initialize() -> void:
	_start = Time.get_ticks_msec()
	var user_args := OS.get_cmdline_user_args()
	if user_args.size() > 1:
		OUT = user_args[1].trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(OUT)
	_main.call_deferred()


func _process(_d: float) -> bool:
	if Time.get_ticks_msec() - _start > WALL_LIMIT_MS:
		print("PROBE TIMEOUT")
		quit(3)
	if player != null and is_instance_valid(player) and player.run != null:
		var health: Health = player.run.health
		if health.pills < health.max_pills:
			health.pills = health.max_pills
			health.changed.emit()
	if _hold.is_valid():
		_hold.call()
	return false


func _wait(seconds: float) -> void:
	var began := Time.get_ticks_msec()
	while Time.get_ticks_msec() - began < seconds * 1000.0:
		await process_frame


func _until(check: Callable, limit: float) -> bool:
	var began := Time.get_ticks_msec()
	while not check.call() and Time.get_ticks_msec() - began < limit * 1000.0:
		await process_frame
	var done: bool = check.call()
	if not done:
		print("  (waited out %.1f s)" % limit)
	return done


# Saves the whole view at 1x (k 1) or a crop enlarged k times, and returns the whole image.
func _shot(shot_name: String, crop := Rect2i(), k := 0) -> Image:
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	var out := image
	if k == 0:
		k = 1 if crop.size == Vector2i.ZERO else 4
	if crop.size != Vector2i.ZERO:
		crop = crop.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
		out = image.get_region(crop)
	var big := out.duplicate()
	if k != 1:
		big.resize(out.get_width() * k, out.get_height() * k, Image.INTERPOLATE_NEAREST)
	big.save_png(OUT + shot_name + ".png")
	print("shot %s red %d" % [shot_name, _red_count(image)])
	return image


# Pixels that read as the warning red, below the HUD's top band (the HUD has its own reds).
func _red_count(image: Image) -> int:
	var count := 0
	var w := image.get_width()
	var h := image.get_height()
	var top := int(h * 0.12)
	for y in range(top, h, 2):
		for x in range(0, w, 2):
			var c := image.get_pixel(x, y)
			if c.r > 0.5 and c.r - maxf(c.g, c.b) > 0.3:
				count += 1
	return count


func _screen_of(node: Node2D) -> Vector2:
	return node.get_viewport().get_canvas_transform() * node.global_position


func _crop_round(at: Vector2, size: Vector2i) -> Rect2i:
	return Rect2i(Vector2i(at) - size / 2, size)


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
	for part in ["bosses", "tells", "lift", "waiting", "cinema"]:
		if which == "all" or which == part:
			print("== " + part)
			await call("_" + part)
	AttackWarnings.shown = false
	progress._store.delete_all()
	print("LOOK DONE")
	quit(0)


func _new_run(floor_id: String) -> bool:
	_hold = Callable()
	player = null
	change_scene_to_file("res://scenes/floor.tscn")
	await _wait(0.3)
	scene = current_scene
	player = scene.player
	scene._depth = FLOORS[floor_id]
	var paths: Array = scene._path_defs()
	for index in paths.size():
		if paths[index].id == floor_id:
			scene.debug_choose_path(index)
	await _wait(0.2)
	view = scene.debug_room_view()
	var got: String = scene.debug_floor_def().id
	if got != floor_id:
		print("WRONG FLOOR %s for %s" % [got, floor_id])
		return false
	await _clear()
	return true


func _clear() -> void:
	for enemy in get_nodes_in_group("enemies"):
		enemy.dismiss()
	await _wait(0.1)
	for coin in _of(Pickup):
		coin.collect()
	await _wait(0.05)


func _of(type) -> Array:
	var found := []
	if view == null or not is_instance_valid(view):
		return found
	for child in view.get_children():
		if is_instance_of(child, type) and not child.is_queued_for_deletion():
			found.append(child)
	return found


func _enter(file: String, room_type: String, seed_value := 7) -> RoomLayout:
	var source: RoomLayout = load(scene.debug_floor_def().rooms_dir.path_join(file + ".tres"))
	var map: FloorMap = scene.debug_map()
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.cell = Vector2i(90 + room.id, 90)
	room.room_type = room_type
	room.layout = source
	room.decor_seed = seed_value
	map.rooms.append(room)
	scene._enter_room(room.id)
	await _wait(0.2)
	view = scene.debug_room_view()
	return source


func _stand(at: Vector2) -> void:
	player.global_position = at - Player.FEET_OFFSET
	player.velocity = Vector2.ZERO


func _stand_cell(cell: Vector2i) -> void:
	_stand(RoomBackdrop.cell_center(cell))


func _middle(layout: RoomLayout) -> Vector2i:
	var size := layout.size_in_cells()
	return layout.nearest_floor_cell(Vector2i(size.x / 2, size.y / 2))


func _rooms_starting(prefix: String) -> Array[String]:
	var dir: String = scene.debug_floor_def().rooms_dir
	var names := DirAccess.get_files_at(dir)
	names.sort()
	var found: Array[String] = []
	for name in names:
		if name.begins_with(prefix) and name.ends_with(".tres"):
			found.append(name.trim_suffix(".tres"))
	return found


func _boss() -> Enemy:
	await _until(func(): return not get_nodes_in_group("enemies").is_empty(), 2.0)
	var best: Enemy = null
	for enemy: Enemy in get_nodes_in_group("enemies"):
		if enemy.is_summon:
			continue
		if best == null or enemy.max_hp() > best.max_hp():
			best = enemy
	return best


# --- every boss with warnings off, and a few with them on ---

func _bosses() -> void:
	for floor_id in FLOORS:
		for prefix in ["mini_boss", "floor_boss"]:
			await _fight(floor_id, prefix, false, 2)
	for spec: Array in [["floor_1", "floor_boss"], ["funeral_parlour", "floor_boss"], ["terminal_zero", "mini_boss"], ["head_office", "floor_boss"]]:
		await _fight(spec[0], spec[1], true, 1)
	AttackWarnings.shown = false


# Lets a boss fight run and shoots its warnings mid-windup, `count` times.
func _fight(floor_id: String, prefix: String, shown: bool, count: int) -> void:
	AttackWarnings.shown = shown
	if not await _new_run(floor_id):
		return
	var files := _rooms_starting(prefix)
	if files.is_empty():
		print("BOSS no %s room on %s" % [prefix, floor_id])
		return
	var own: RoomLayout = load(scene.debug_floor_def().rooms_dir.path_join(files[0] + ".tres"))
	var layout := await _enter(files[0], own.room_type)
	var boss := await _boss()
	if boss == null:
		print("BOSS none in %s %s" % [floor_id, files[0]])
		return
	_stand_cell(layout.nearest_floor_cell(_middle(layout) + Vector2i(0, 3)))
	var tag := "%s_%s_%s" % ["on" if shown else "off", floor_id, boss.def.id]
	var shots := 0
	var began := Time.get_ticks_msec()
	while shots < count and Time.get_ticks_msec() - began < 16000 and is_instance_valid(boss):
		var winding := boss.is_winding_up() or _warning_nodes() > 0
		if winding:
			await _wait(0.35)
			await _shot("boss_%s_%d" % [tag, shots])
			shots += 1
			await _wait(1.6)
		else:
			await process_frame
	print("BOSS %s shots %d" % [tag, shots])
	await _clear()


# World attack nodes that are in their warning now.
func _warning_nodes() -> int:
	var count := 0
	for child in _of(Node2D):
		if child.has_method("is_warning") and child.is_warning():
			count += 1
	return count


# --- the named tells ---

func _tells() -> void:
	for shown in [false, true]:
		AttackWarnings.shown = shown
		var tag := "on" if shown else "off"
		await _matron(tag)
		await _zara_swoops(tag)
		await _xray(tag)
		await _wheel(tag)
	AttackWarnings.shown = false


func _boss_room(floor_id: String, boss_id: String) -> Array:
	for prefix in ["floor_boss", "mini_boss"]:
		if not await _new_run(floor_id):
			return []
		for file in _rooms_starting(prefix):
			var own: RoomLayout = load(scene.debug_floor_def().rooms_dir.path_join(file + ".tres"))
			var layout := await _enter(file, own.room_type)
			var boss := await _boss()
			if boss != null and boss.def.id == boss_id:
				return [layout, boss]
			print("  %s holds %s" % [file, boss.def.id if boss != null else "nobody"])
			break
	print("TELL no room for %s" % boss_id)
	return []


func _matron(tag: String) -> void:
	var found := await _boss_room("sunset_shores", "matron_mercy")
	if found.is_empty():
		return
	var layout: RoomLayout = found[0]
	var boss: Enemy = found[1]
	var b = boss._behavior
	_stand_cell(layout.nearest_floor_cell(_middle(layout) + Vector2i(0, 3)))
	_hold = func():
		if is_instance_valid(boss) and not b._telegraph.is_active() and not b.is_dark():
			b._cooldown = 99.0
	await _wait(0.4)
	b._begin(boss, MatronBehavior.Attack.LIGHTS_OUT, false)
	await _until(func(): return not is_instance_valid(boss) or b.is_dark(), 4.0)
	_hold = Callable()
	b._cooldown = 0.0
	var shots := 0
	var began := Time.get_ticks_msec()
	while shots < 2 and Time.get_ticks_msec() - began < 8000 and is_instance_valid(boss):
		if boss.is_winding_up():
			await _wait(0.25 + 0.2 * shots)
			print("MATRON dark %s winding %s" % [b.is_dark(), boss.is_winding_up()])
			await _shot("tell_%s_matron_lights_out_%d" % [tag, shots])
			await _shot("tell_%s_matron_lights_out_%d_close" % [tag, shots], _crop_round(_screen_of(boss), Vector2i(200, 140)), 3)
			shots += 1
			await _wait(1.0)
		else:
			await process_frame
	print("MATRON shots %d" % shots)
	await _clear()


func _zara_swoops(tag: String) -> void:
	var found := await _boss_room("seance_hotline", "madame_zara")
	if found.is_empty():
		return
	var layout: RoomLayout = found[0]
	var boss: Enemy = found[1]
	var b = boss._behavior
	b.forced_phase_two = true
	_stand_cell(layout.nearest_floor_cell(_middle(layout) + Vector2i(0, 3)))
	await _until(func(): return not is_instance_valid(boss) or b.circle() != null, 3.0)
	await _wait(0.8)
	var circle = b.circle()
	if circle == null:
		print("ZARA no circle")
		return
	# Stand him well outside the ring of light, so the spirits come.
	var size := layout.size_in_cells()
	var best := Vector2i(2, size.y - 3)
	var best_d := -1.0
	for cell: Vector2i in [Vector2i(2, 3), Vector2i(size.x - 3, 3), Vector2i(2, size.y - 3), Vector2i(size.x - 3, size.y - 3)]:
		var at := RoomBackdrop.cell_center(layout.nearest_floor_cell(cell))
		var d := at.distance_to(circle.global_position)
		if d > best_d:
			best_d = d
			best = layout.nearest_floor_cell(cell)
	_stand_cell(best)
	var shots := 0
	var began := Time.get_ticks_msec()
	while shots < 2 and Time.get_ticks_msec() - began < 10000:
		var swoops := _of(SpiritSwoop)
		if not swoops.is_empty():
			var s = swoops[0]
			await _until(func(): return not is_instance_valid(s) or s.fill() > 0.4 + 0.3 * shots, 2.0)
			await _shot("tell_%s_zara_swoop_%d" % [tag, shots])
			if is_instance_valid(s):
				await _shot("tell_%s_zara_swoop_%d_close" % [tag, shots], _crop_round(_screen_of(view) + s.spot(), Vector2i(160, 110)), 3)
			shots += 1
			await _wait(0.8)
		else:
			_stand_cell(best)
			await process_frame
	print("ZARA swoop shots %d" % shots)
	await _clear()


func _xray(tag: String) -> void:
	var found := await _boss_room("terminal_zero", "sergeant_wanda")
	if found.is_empty():
		return
	var layout: RoomLayout = found[0]
	var boss: Enemy = found[1]
	var b = boss._behavior
	_stand_cell(layout.nearest_floor_cell(_middle(layout) + Vector2i(0, 3)))
	_hold = func():
		if is_instance_valid(boss) and not b._telegraph.is_active():
			b._cooldown = 99.0
	await _wait(0.4)
	b._begin(boss, SecuritySergeantBehavior.Attack.XRAY)
	await _wait(0.5)
	await _shot("tell_%s_xray_windup" % tag)
	await _until(func(): return not _of(XRaySweep).is_empty(), 4.0)
	await _wait(0.4)
	await _shot("tell_%s_xray_sweep" % tag)
	await _wait(0.6)
	await _shot("tell_%s_xray_sweep_late" % tag)
	_hold = Callable()
	await _clear()


func _wheel(tag: String) -> void:
	var found := await _boss_room("seance_hotline", "celestine")
	if found.is_empty():
		found = await _boss_room("head_office", "celestine")
	if found.is_empty():
		return
	var layout: RoomLayout = found[0]
	var boss: Enemy = found[1]
	var b = boss._behavior
	b.forced_hand = [CelestineBehavior.Card.WHEEL, CelestineBehavior.Card.STAR, CelestineBehavior.Card.WHEEL]
	_stand_cell(layout.nearest_floor_cell(_middle(layout) + Vector2i(0, 3)))
	var shots := 0
	var began := Time.get_ticks_msec()
	while shots < 3 and Time.get_ticks_msec() - began < 14000:
		var wheels := _of(WheelRing)
		if not wheels.is_empty():
			await _wait(0.3 + 0.35 * shots)
			await _shot("tell_%s_wheel_%d" % [tag, shots])
			shots += 1
		else:
			await process_frame
	print("WHEEL shots %d" % shots)
	await _clear()


# --- the cage lift ---

func _lift() -> void:
	AttackWarnings.shown = false
	for floor_id in ["floor_1", "seance_hotline", "head_office"]:
		if not await _new_run(floor_id):
			continue
		var file := _rooms_starting("floor_boss")[0]
		var own: RoomLayout = load(scene.debug_floor_def().rooms_dir.path_join(file + ".tres"))
		var layout := await _enter(file, own.room_type)
		var boss := await _boss()
		_stand_cell(layout.nearest_floor_cell(_middle(layout) + Vector2i(-3, 3)))
		await _wait(0.3)
		if boss != null:
			boss.take_damage(INF, Vector2.ZERO)
		await _until(func(): return view.stairwell() != null, 4.0)
		var lift: Door = view.stairwell()
		if lift == null:
			print("LIFT none on %s" % floor_id)
			continue
		var cell := Vector2i(lift.position / RoomBackdrop.TILE)
		print("LIFT %s cell %s gate %.2f" % [floor_id, cell, lift.gate()])
		var at := _screen_of(lift)
		var crop := _crop_round(at + Vector2(0, -20), Vector2i(150, 120))
		await _shot("lift_%s_closed" % floor_id, crop, 4)
		await _until(func(): return lift.gate() >= 0.3, 1.5)
		await _shot("lift_%s_half" % floor_id, crop, 4)
		await _until(func(): return lift.gate() >= 1.0, 1.5)
		await _wait(0.2)
		await _shot("lift_%s_open_room" % floor_id)
		await _shot("lift_%s_open" % floor_id, crop, 4)
		await _shot("lift_%s_open_1x" % floor_id, crop, 1)
		# Harold in front of it from the south, and behind it from the north, held still.
		player.set_physics_process(false)
		_stand(lift.position + Vector2(10, 22))
		await _wait(0.2)
		await _shot("lift_%s_harold_south" % floor_id, crop, 4)
		_stand(lift.position + Vector2(10, -40))
		await _wait(0.2)
		await _shot("lift_%s_harold_north" % floor_id, crop, 4)
		player.set_physics_process(true)
	# The Waiting Room's run door.
	await _open_waiting_room()
	var hub = current_scene
	var door: Door = null
	for child in hub.debug_room_view().get_children():
		if child is Door and child.lift:
			door = child
	if door == null:
		print("LIFT no run door")
		return
	_stand(door.position + Vector2(-40, 30))
	await _wait(0.4)
	await _shot("lift_waiting_room")
	await _shot("lift_waiting_room_close", _crop_round(_screen_of(door) + Vector2(0, -20), Vector2i(150, 120)), 4)
	print("LIFT waiting room cell %s gate %.2f" % [Vector2i(door.position / RoomBackdrop.TILE), door.gate()])


# --- the Waiting Room ---

func _open_waiting_room() -> void:
	player = null
	var data: ProgressData = progress.data
	data.opening_seen = true
	data.record_floor_cleared(5, "head_office")
	for id in ["floor_1", "cemetery", "furnace_works", "flashback_cinema", "seance_hotline"]:
		data.record_floor_cleared(FLOORS[id], id)
	data.departments_seen = {}
	for entry in Departments.ALL:
		data.departments_seen[entry["id"]] = true
	progress.last_run = {}
	change_scene_to_file("res://scenes/waiting_room.tscn")
	await _wait(0.6)
	player = current_scene.player
	view = current_scene.debug_room_view()


func _waiting() -> void:
	await _open_waiting_room()
	var hub = current_scene
	# The lobby: the trophy wall, the Black Market and Dr. Squint, Agnes.
	_stand_cell(Vector2i(19, 5))
	await _wait(0.5)
	await _shot("waiting_lobby_trophy_wall")
	var wall_at := _screen_of(hub.debug_room_view()) + Vector2(Departments.TROPHY_WALL_X, Departments.TROPHY_WALL_Y + 10)
	await _shot("waiting_trophy_wall_close", _crop_round(wall_at, Vector2i(270, 70)), 3)
	for spec: Array in [["black_market", Vector2i(6, 3)], ["optometrist", Vector2i(6, 7)], ["crafter", Vector2i(11, 7)]]:
		await _face_shots(hub, spec[0], spec[1])
	# The merchants in their wings.
	for spec: Array in [[Departments.APOTHECARY_WING, "potion_merchant", Vector2i(4, 3)], [Departments.BOILER_ROOM, "bomb_merchant", Vector2i(4, 3)]]:
		hub.debug_enter_department(spec[0])
		await _wait(0.4)
		view = hub.debug_room_view()
		await _face_shots(hub, spec[1], spec[2])
		await _shot("waiting_%s_room" % spec[0])
	# The Crystal Counter and its cobwebs.
	for department in [Departments.CRYSTAL_COUNTER, Departments.DECOR_OFFICE, Departments.TRAINING_YARD, Departments.BACK_ROOM]:
		hub.debug_enter_department(department)
		await _wait(0.4)
		view = hub.debug_room_view()
		_stand_cell(Vector2i(6, 6))
		await _wait(0.3)
		await _shot("waiting_%s" % department)
		await _shot("waiting_%s_top_left" % department, Rect2i(0, 20, 160, 90), 3)
		await _shot("waiting_%s_top_right" % department, Rect2i(480, 20, 160, 90), 3)
	# The Bounty Office: its board in every stamp state.
	hub.debug_enter_department(Departments.BOUNTY_OFFICE)
	await _wait(0.4)
	view = hub.debug_room_view()
	_stand_cell(Vector2i(6, 4))
	await _wait(0.3)
	var board: PosterBoard = hub._poster_board
	await _shot("waiting_bounty_board_fresh")
	var defs := BountyBoard.all()
	var states := [BountyBoard.POSTER_OPEN, BountyBoard.POSTER_TAKEN, BountyBoard.POSTER_WON, BountyBoard.POSTER_CLOSED]
	var hung: Array[Dictionary] = []
	for i in mini(defs.size(), PosterBoard.MAX_PAPERS):
		hung.append({"id": defs[i].id, "state": states[i % 4]})
	board.show_posters(hung)
	await _wait(0.2)
	await _shot("waiting_bounty_board_states")
	var board_at := _screen_of(board)
	await _shot("waiting_bounty_board_states_1x", _crop_round(board_at, Vector2i(270, 92)), 1)
	await _shot("waiting_bounty_board_states_x4", _crop_round(board_at, Vector2i(270, 92)), 4)
	var left := board_at + PosterBoard.paper_rect(0).position
	await _shot("waiting_bounty_board_four_states_x8", Rect2i(Vector2i(left) - Vector2i(2, 2), Vector2i(104, 32)), 8)
	print("BOARD posters %s" % str(hung.slice(0, 4)))
	# Harold in front of the board.
	_stand(board.position + Vector2(-40, 30))
	await _wait(0.3)
	await _shot("waiting_bounty_board_harold", _crop_round(board_at, Vector2i(270, 120)), 3)


func _face_shots(hub, station_id: String, cell: Vector2i) -> void:
	var station: WaitingStation = hub._stations.get(station_id)
	if station == null:
		print("STATION none %s" % station_id)
		return
	# One cell off each side and below: inside WaitingStation.USE_RADIUS (48 px), where he turns.
	for side: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1)]:
		_stand_cell(cell + side)
		await _wait(0.4)
		var person: NpcSprite = station.person()
		print("STATION %s Harold at %s near %s facing frame %s art %s" % [station_id, side, station.is_near(), person.frame() if person != null else -1, station.art_id()])
		await _shot("waiting_%s_harold_%d_%d" % [station_id, side.x, side.y], _crop_round(_screen_of(station) + Vector2(0, -10), Vector2i(130, 90)), 3)
	_stand_cell(cell + Vector2i(6, 3))
	await _wait(0.4)
	await _shot("waiting_%s_away" % station_id, _crop_round(_screen_of(station) + Vector2(0, -10), Vector2i(130, 90)), 3)


# --- the Cinema ---

func _cinema() -> void:
	AttackWarnings.shown = false
	if not await _new_run("flashback_cinema"):
		return
	# Every screen room: the card's line must belong to the film the screen plays.
	var checked := 0
	var matched := 0
	for prefix in ["combat", "mini_boss", "floor_boss"]:
		for file in _rooms_starting(prefix):
			var own: RoomLayout = load(scene.debug_floor_def().rooms_dir.path_join(file + ".tres"))
			var cards := own.cells_of(RoomLayout.SYMBOL_LIFE_SIGN)
			if cards.is_empty():
				continue
			var layout := await _enter(file, own.room_type, 11 + checked)
			await _clear()
			_stand(RoomBackdrop.cell_center(cards[0]) + Vector2(14, 22))
			await _wait(0.4)
			var screen := CinemaScreen.in_room(view)
			var text := ""
			for child in view.get_children():
				if child is LifeSign:
					text = child.showing_text()
			var film := screen.scene_id if screen != null else ""
			var line_film := ""
			for entry: Dictionary in LifeSigns.ALL:
				if entry["text"] == text:
					line_film = entry["scene"]
			checked += 1
			if line_film == film and not film.is_empty():
				matched += 1
			print("CARD %s card %s film %s line film %s: %s" % [file, cards[0], film, line_film, text])
			if file in ["combat_small_01", "combat_01", "combat_large_01", "combat_large_03"]:
				await _shot("cinema_card_%s" % file)
	print("CINEMA cards matching their film %d of %d" % [matched, checked])
	# Big seats beside Harold, in each room size.
	for file in ["combat_small_01", "combat_01", "combat_large_01"]:
		var layout := await _enter(file, RoomLayout.TYPE_COMBAT)
		await _clear()
		var seats := layout.cells_of(RoomLayout.SYMBOL_SEAT)
		print("SEATS %s %d" % [file, seats.size()])
		if seats.is_empty():
			continue
		_stand_cell(layout.nearest_floor_cell(seats[0] + Vector2i(0, 1)))
		await _wait(0.4)
		await _shot("cinema_seats_%s" % file)
		await _shot("cinema_seats_%s_close" % file, _crop_round(_screen_of(player), Vector2i(160, 100)), 3)
	# The five new films on a screen.
	var layout := await _enter("combat_01", RoomLayout.TYPE_COMBAT)
	await _clear()
	_stand_cell(_middle(layout))
	for film in NEW_FILMS:
		var old := CinemaScreen.in_room(view)
		if old != null:
			old.queue_free()
		await process_frame
		var screen := CinemaProps.add_screen(view, layout, scene.debug_floor_def().room_palette(), film, 7)
		await _wait(0.5)
		var rect := screen.picture_rect()
		var at := _screen_of(view) + rect.get_center()
		await _shot("cinema_film_%s_a" % film, _crop_round(at, Vector2i(int(rect.size.x) + 20, int(rect.size.y) + 20)), 3)
		await _wait(1.6)
		await _shot("cinema_film_%s_b" % film, _crop_round(at, Vector2i(int(rect.size.x) + 20, int(rect.size.y) + 20)), 3)
