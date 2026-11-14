extends SceneTree
# The playtest-10 screenshot sheet's look probe: windowed shots in an exported copy whose config/name is
# renamed, with Progress kept in a temp-folder file only (never the real save). One section per run.
# Run: godot --path <copy> --script res://tools/probes/sheet_look.gd -- <section> <out folder>
# Sections: maps | leftovers | rooms | ui | ending. Shots are 1280x720 (the 640x360 screen at 2x); crops 4x.

const WALL_LIMIT_MS := 600000
const FLOORS := {"floor_1": 1, "sunset_shores": 2, "seance_hotline": 4, "funeral_parlour": 3}
const TALL_ROOMS := [["combat_large_01", "30x17"], ["combat_01", "20x11"]]
const FRAME := 1.0 / 60.0
const S := preload("res://scripts/core/cutscene_steps.gd")

var OUT := "D:/grandpa-art/playtest-10/"
var _start := 0
var _heal := false
var scene
var player: Player
var progress
var view: RoomView


func _initialize() -> void:
	if str(ProjectSettings.get_setting("application/config/name")) == "Grandpa":
		print("sheet_look.gd: refusing to run against the real save folder")
		quit(2)
		return
	_start = Time.get_ticks_msec()
	var args := OS.get_cmdline_user_args()
	if args.size() > 1:
		OUT = args[1].trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(OUT)
	_main.call_deferred()


func _process(_d: float) -> bool:
	if Time.get_ticks_msec() - _start > WALL_LIMIT_MS:
		print("PROBE TIMEOUT")
		quit(3)
	# A heal every frame fires run.changed, which resets the maps' flags from the held items, so it is
	# only on in the sections that do not look at those flags.
	if _heal and player != null and is_instance_valid(player):
		player.run.health.heal(99)
	return false


func _wait(seconds: float) -> void:
	var began := Time.get_ticks_msec()
	while Time.get_ticks_msec() - began < seconds * 1000.0:
		await process_frame


func _shot(shot_name: String, crop := Rect2i(), k := 2) -> void:
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	var out := image
	if crop.size != Vector2i.ZERO:
		out = image.get_region(crop.intersection(Rect2i(Vector2i.ZERO, image.get_size())))
	var big := out.duplicate()
	big.resize(out.get_width() * k, out.get_height() * k, Image.INTERPOLATE_NEAREST)
	big.save_png(OUT + shot_name + ".png")
	print("shot %s (%dx%d)" % [shot_name, big.get_width(), big.get_height()])


func _press(action: String) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame
	await process_frame


func _main() -> void:
	await process_frame
	progress = root.get_node("Progress")
	var dir := OS.get_temp_dir().path_join("t18_sheet_look")
	DirAccess.make_dir_recursive_absolute(dir)
	progress._store = SaveStore.new(dir.path_join("save.json"))
	progress._store.delete_all()
	progress.reload()
	progress.data.floors_cleared = 1
	progress.data.record_floor_cleared(2, "sunset_shores")
	progress.data.record_floor_cleared(3, "funeral_parlour")
	progress.data.record_floor_cleared(4, "last_resort_cruise")
	print("save store: %s" % dir.path_join("save.json"))
	var args := OS.get_cmdline_user_args()
	var which: String = args[0] if args.size() > 0 else "maps"
	match which:
		"maps":
			for floor_id: String in FLOORS:
				await _floor_maps(floor_id)
		"leftovers":
			await _leftovers()
		"rooms":
			await _rooms()
		"ui":
			await _ui()
		"ending":
			await _ending()
	progress._store.delete_all()
	print("LOOK DONE %s" % which)
	quit(0)


# --- helpers ---

func _open_floor(floor_id: String) -> void:
	change_scene_to_file("res://scenes/floor.tscn")
	await _wait(0.4)
	scene = current_scene
	player = scene.player
	scene._depth = FLOORS[floor_id]
	scene._rng.seed = 1234
	var paths: Array = scene._path_defs()
	for index in paths.size():
		if paths[index].id == floor_id:
			scene.debug_choose_path(index)
	await _wait(0.4)
	if scene.debug_floor_def().id != floor_id:
		print("WRONG FLOOR %s" % scene.debug_floor_def().id)
	view = scene.debug_room_view()


func _clear() -> void:
	for enemy in get_nodes_in_group("enemies"):
		enemy.dismiss()
	await _wait(0.05)
	if view == null:
		return
	for child in view.get_children():
		if child is Pickup and not child.is_queued_for_deletion():
			child.collect()
	await _wait(0.05)


func _walk_to(room_id: int) -> void:
	scene._enter_room(room_id)
	await _wait(0.3)
	view = scene.debug_room_view()
	await _clear()


func _stand(at: Vector2) -> void:
	player.global_position = at - Player.FEET_OFFSET
	player.velocity = Vector2.ZERO


func _middle_of(room_id: int) -> Vector2:
	var layout: RoomLayout = scene.debug_map().room(room_id).layout
	var size := layout.size_in_cells()
	return RoomBackdrop.cell_center(layout.nearest_floor_cell(Vector2i(size.x / 2, size.y / 2)))


# --- maps: floors 1, 2 and 4, a few rooms walked, with unexplored exits ---

func _floor_maps(floor_id: String) -> void:
	await _open_floor(floor_id)
	var map: FloorMap = scene.debug_map()
	for id in map.main_path:
		scene.debug_rules().lift_rule(id)
	await _clear()
	for id: int in map.main_path.slice(1, 4):
		await _walk_to(id)
	await _walk_to(map.main_path[2])
	_stand(_middle_of(map.main_path[2]))
	await _wait(0.8)
	print("%s: %d rooms" % [floor_id, map.rooms.size()])
	await _shot("maps_%s_minimap" % floor_id)
	await _shot("maps_%s_minimap_crop4x" % floor_id, Rect2i(Hud.MAP_PANEL.grow(8)), 4)
	scene.debug_big_map().set_open(true)
	await _wait(0.3)
	await _shot("maps_%s_bigmap" % floor_id)
	scene.debug_big_map().set_open(false)
	await _wait(0.2)
	if floor_id != "floor_1":
		# The Floor Plan, Night Vision and the Fortune Teller's Card on this floor's big map.
		var big_other: FloorMapView = scene.debug_big_map()
		big_other.show_secrets = true
		big_other.show_plan = true
		big_other.boss_names = FloorMapView.boss_names_for(scene.debug_floor_def())
		big_other.set_open(true)
		await _wait(0.4)
		await _shot("maps_%s_plan_bigmap" % floor_id)
		big_other.set_open(false)
		return
	# An enemy on the floor cell nearest the minimap's panel, held still: the scrap fades.
	var layout: RoomLayout = map.room(map.main_path[2]).layout
	var size := layout.size_in_cells()
	var canvas: Transform2D = view.get_viewport().get_canvas_transform()
	var target := Hud.MAP_PANEL.get_center() + Vector2(0, 12)
	var best := Vector2i.ZERO
	var best_d := INF
	for y in size.y:
		for x in size.x:
			var c := Vector2i(x, y)
			if layout.nearest_floor_cell(c) != c:
				continue
			var d := (canvas * RoomBackdrop.cell_center(c)).distance_to(target)
			if d < best_d:
				best_d = d
				best = c
	var enemy: Enemy = view.spawn_fixture(scene.debug_floor_def().enemies[0], best)
	enemy.set_physics_process(false)
	await _wait(0.8)
	await _shot("maps_floor_1_minimap_over_enemy")
	await _shot("maps_floor_1_minimap_over_enemy_crop4x", Rect2i(Hud.MAP_PANEL.grow(8)), 4)
	await _clear()
	# The Floor Plan, Night Vision and the Fortune Teller's Card, on the small map and the big one.
	var mini: FloorMapView = scene.debug_mini_map()
	var big: FloorMapView = scene.debug_big_map()
	for v: FloorMapView in [mini, big]:
		v.show_secrets = true
		v.show_plan = true
		v.boss_names = FloorMapView.boss_names_for(scene.debug_floor_def())
	await _wait(0.8)
	await _shot("maps_floor_1_plan_minimap_crop4x", Rect2i(Hud.MAP_PANEL.grow(8)), 4)
	big.set_open(true)
	await _wait(0.3)
	await _shot("maps_floor_1_plan_bigmap")
	await _shot("maps_floor_1_bigmap_key_crop3x", Rect2i(FloorMapView.KEY_RECT.grow(4)), 3)
	big.set_open(false)


# --- leftovers: a potion and a Slip left in a visited room, then every kind ---

func _leftovers() -> void:
	await _open_floor("floor_1")
	var map: FloorMap = scene.debug_map()
	await _clear()
	var path: Array[int] = map.main_path
	await _walk_to(path[1])
	var left_room: int = path[1]
	var here: RoomView = scene.debug_room_view()
	var spot := player.global_position + Vector2(64, 0)
	here._drop_potion(here.clear_spot(spot), Content.potion("swift_tea"))
	here._drop_consumable(here.clear_spot(spot + Vector2(32, 32)), RoomRules.DROP_KEY)
	await _wait(0.3)
	await _shot("left_live_minimap_crop4x", Rect2i(FloorMapView.MINI_RECT.grow(4.0)), 4)
	await _walk_to(path[2])
	await _walk_to(path[3])
	scene._enter_room(path[2])
	await _wait(0.4)
	await _shot("left_minimap_crop4x", Rect2i(FloorMapView.MINI_RECT.grow(4.0)), 4)
	var big: FloorMapView = scene.debug_big_map()
	big.set_open(true)
	await _wait(0.2)
	await _shot("left_potion_slip_bigmap")
	var rect: Rect2 = big.big_room_rects[left_room]
	await _shot("left_potion_slip_room_crop4x", Rect2i(rect.grow(4.0)), 4)
	await _shot("left_bigmap_key_crop3x", Rect2i(FloorMapView.KEY_RECT.grow(4.0)), 3)
	big.set_open(false)
	await _wait(0.2)
	# Every kind: four in the third room and all six in the fourth (the dots in the last slot).
	var third: RoomView = scene._room_views[path[3]]
	var fourth_id: int = path[4] if path.size() > 4 else path[0]
	await _walk_to(fourth_id)
	var fourth: RoomView = scene.debug_room_view()
	var at := player.global_position + Vector2(48, -48)
	third.drop_reel(third.clear_spot(at), Eras.FOOTBALL, func() -> void: pass)
	third._drop_consumable(third.clear_spot(at + Vector2(32, 0)), RoomRules.DROP_BOMB)
	third._add_heal(third.clear_spot(at + Vector2(64, 0)), 2)
	third._add_item_pickup(third.clear_spot(at + Vector2(96, 0)), Content.items()[3])
	fourth._drop_potion(fourth.clear_spot(at), Content.potion("healing_tonic"))
	fourth._add_item_pickup(fourth.clear_spot(at + Vector2(32, 0)), Content.items()[4])
	fourth.drop_reel(fourth.clear_spot(at + Vector2(64, 0)), Eras.BUS, func() -> void: pass)
	fourth._drop_consumable(fourth.clear_spot(at + Vector2(96, 0)), RoomRules.DROP_KEY)
	fourth._drop_consumable(fourth.clear_spot(at + Vector2(0, 32)), RoomRules.DROP_BOMB)
	fourth._add_heal(fourth.clear_spot(at + Vector2(32, 32)), 2)
	await _wait(0.3)
	big.set_open(true)
	await _wait(0.2)
	await _shot("left_every_kind_bigmap")
	for id: int in [path[3], fourth_id]:
		var box: Rect2 = big.big_room_rects[id]
		await _shot("left_every_kind_room_%d_crop4x" % id, Rect2i(box.grow(4.0)), 4)
	big.set_open(false)


# --- rooms: the top wall, item names, the potion swap prompt, F mid-fight, the quiet first room, facing ---

func _enter_made(file: String) -> RoomLayout:
	var source: RoomLayout = load(scene.debug_floor_def().rooms_dir.path_join(file + ".tres"))
	var map: FloorMap = scene.debug_map()
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.cell = Vector2i(90 + room.id, 90)
	room.room_type = "combat"
	room.layout = source
	room.decor_seed = 7
	map.rooms.append(room)
	scene._enter_room(room.id)
	await _wait(0.3)
	view = scene.debug_room_view()
	await _clear()
	return source


func _rooms() -> void:
	await _open_floor("floor_1")
	_heal = true
	var map: FloorMap = scene.debug_map()
	# The quiet first room with its two doors, as he arrives.
	await _wait(0.5)
	print("first room %d quiet=%s enemies=%d, doors %d" % [scene.debug_current_id(), str(map.room(scene.debug_current_id()).quiet), get_nodes_in_group("enemies").size(), map.room(scene.debug_current_id()).links.size() if "links" in map.room(scene.debug_current_id()) else -1])
	await _shot("room_first_quiet")
	# One shot standing a little way in front of each of its doors.
	var door_n := 0
	for door: Door in view.doors():
		var toward := Vector2(0, 70) if door.global_position.y < 200 else Vector2(0, -70)
		if absf(door.global_position.x - _middle_of(scene.debug_current_id()).x) > 300:
			toward = Vector2(-70 if door.global_position.x > _middle_of(scene.debug_current_id()).x else 70, 0)
		_stand(door.global_position + toward)
		await _wait(0.6)
		print("door %d at %s" % [door_n, str(door.global_position)])
		await _shot("room_first_quiet_door_%d" % door_n)
		door_n += 1
	# Tall rooms: his feet at the top and at the foot, the wall below the HUD band.
	for spec: Array in TALL_ROOMS:
		var layout := await _enter_made(spec[0])
		var size := layout.size_in_cells()
		for end: String in ["top", "foot"]:
			var cell := layout.nearest_floor_cell(Vector2i(size.x / 2, 1 if end == "top" else size.y - 2))
			player.global_position = Player.arrival_position(cell)
			player.velocity = Vector2.ZERO
			await _wait(0.5)
			var canvas := root.get_canvas_transform()
			print("room %s %s: top wall at screen y %.0f, foot at %.0f, cells %s" % [spec[0], end, (canvas * Vector2.ZERO).y, (canvas * (Vector2(size) * RoomBackdrop.TILE)).y, str(size)])
			await _shot("room_%s_%s" % [spec[1], end])
	# Item names: an item room, near one pedestal and far from all.
	var item_id := -1
	for room: FloorRoom in map.rooms:
		if room.room_type == RoomLayout.TYPE_ITEM:
			item_id = room.id
			break
	if item_id >= 0:
		await _walk_to_keep(item_id)
		var pedestals := _name_pickups()
		print("item room %d: %d named pickups" % [item_id, pedestals.size()])
		if pedestals.size() > 0:
			_stand(pedestals[0].global_position + Vector2(0, 20))
			await _wait(0.5)
			await _shot("names_item_room_near")
			var far: Pickup = pedestals[pedestals.size() - 1]
			_stand(far.global_position + Vector2(0, 150) if far.global_position.y < 150 else far.global_position - Vector2(0, 150))
			await _wait(0.5)
			await _shot("names_item_room_far")
	# A boss's choice of items.
	await _enter_made("combat_01")
	var b: RoomView = scene.debug_room_view()
	_stand(_middle_of(scene.debug_current_id()))
	b._drop_boss_choice(player.global_position + Vector2(0, -40))
	await _wait(0.4)
	var choice := _name_pickups()
	print("boss choice: %d pickups" % choice.size())
	if choice.size() > 0:
		_stand(choice[0].global_position + Vector2(0, 20))
		await _wait(0.5)
		await _shot("names_boss_choice_near")
		_stand(_middle_of(scene.debug_current_id()) + Vector2(0, 90))
		await _wait(0.5)
		await _shot("names_boss_choice_far")
	# A treasure room, when this floor has one.
	var treasure_id := -1
	for room: FloorRoom in map.rooms:
		if room.room_type == RoomLayout.TYPE_TREASURE or room.room_type == RoomLayout.TYPE_VAULT:
			treasure_id = room.id
			break
	if treasure_id >= 0:
		await _walk_to_keep(treasure_id)
		var chests := _name_pickups()
		print("treasure room %d: %d named pickups" % [treasure_id, chests.size()])
		if chests.size() > 0:
			_stand(chests[0].global_position + Vector2(0, 20))
			await _wait(0.5)
			await _shot("names_treasure_near")
	else:
		print("no treasure room on this floor")
	# The potion swap prompt: a potion carried, another on the floor under his feet.
	await _enter_made("combat_01")
	var swap_view: RoomView = scene.debug_room_view()
	player.run.give_potion(Content.potion("swift_tea"))
	_stand(_middle_of(scene.debug_current_id()))
	swap_view._drop_potion(swap_view.clear_spot(player.global_position + Vector2(0, 30)), Content.potion("healing_tonic"))
	await _wait(0.6)
	await _shot("potion_swap_prompt")
	await _shot("potion_swap_prompt_crop3x", Rect2i(Rect2(root.get_canvas_transform() * (player.global_position + Vector2(0, 30)) - Vector2(80, 80), Vector2(160, 120))), 3)
	# F mid-fight: a fight is on, a reel is held, the key plays it at once.
	_heal = true
	await _walk_to_fight(map)
	player.run.give_reel(Eras.FOOTBALL)
	await _wait(0.2)
	print("fighting before F: %s, alive %d" % [str(scene.debug_room_view().is_fighting()), scene.debug_room_view().debug_alive()])
	await _shot("f_before")
	var played: bool = scene.debug_rules().try_play_reel()
	print("try_play_reel -> %s" % str(played))
	await _wait(0.6)
	await _shot("f_mid_fight")
	await _wait(1.5)
	await _shot("f_mid_fight_later")
	# Harold faces the way he walks, the cursor behind him.
	_heal = true
	await _enter_made("combat_01")
	_stand(_middle_of(scene.debug_current_id()))
	Input.warp_mouse(_window_at(Vector2(500, 200)))
	await _wait(1.0)
	Input.action_press("move_left")
	await _wait(0.5)
	await _shot("face_walk_left_cursor_right")
	Input.action_release("move_left")
	await _wait(0.2)
	Input.warp_mouse(_window_at(Vector2(150, 200)))
	await _wait(1.0)
	Input.action_press("move_right")
	await _wait(0.5)
	await _shot("face_walk_right_cursor_left")
	Input.action_release("move_right")


# The window pixel for a point of the 640x360 screen (warp_mouse takes window pixels).
func _window_at(screen_point: Vector2) -> Vector2:
	return screen_point * Vector2(DisplayServer.window_get_size()) / root.get_visible_rect().size


func _walk_to_keep(room_id: int) -> void:
	scene._enter_room(room_id)
	await _wait(0.4)
	view = scene.debug_room_view()
	for enemy in get_nodes_in_group("enemies"):
		enemy.dismiss()
	await _wait(0.2)


func _walk_to_fight(map: FloorMap) -> void:
	var target := -1
	for room: FloorRoom in map.rooms:
		if room.room_type == RoomLayout.TYPE_COMBAT and not room.quiet and room.id != scene.debug_current_id():
			target = room.id
			break
	scene._enter_room(target)
	await _wait(0.6)
	view = scene.debug_room_view()


func _name_pickups() -> Array[Pickup]:
	var found: Array[Pickup] = []
	for child in view.get_children():
		if child is Pickup and child.names_near_only and not child.is_queued_for_deletion():
			found.append(child)
	return found


# --- ui: lobby portraits, the case file, the tester panel, the pause menu's tester line ---

func _ui() -> void:
	var data: ProgressData = progress.data
	data.opening_seen = true
	for entry: Dictionary in Mementos.ALL:
		data.record_floor_cleared(1, entry["path"])
	data.departments_seen = {}
	for entry in Departments.ALL:
		data.departments_seen[entry["id"]] = true
	progress.last_run = {}
	change_scene_to_file("res://scenes/waiting_room.tscn")
	await _wait(0.8)
	var lobby_player = current_scene.player
	lobby_player.global_position = RoomBackdrop.cell_center(Vector2i(19, 6)) - Player.FEET_OFFSET
	lobby_player.velocity = Vector2.ZERO
	await _wait(0.6)
	await _shot("lobby_portraits")
	# The case file's stats.
	await _open_floor("floor_1")
	_heal = true
	await _clear()
	for item in Content.items().slice(0, 6):
		player.run.add_item(item)
	await _wait(0.3)
	scene.debug_open_case_file()
	await _wait(0.4)
	await _shot("case_file_first_tab")
	var case_file: CaseFile = scene.debug_case_file()
	for tab_id: String in [CaseFileData.TAB_STATS, CaseFileData.TAB_ITEMS]:
		case_file.show_tab_named(tab_id)
		await _wait(0.3)
		print("case file tab %s" % case_file.current_tab())
		await _shot("case_file_tab_%s" % case_file.current_tab())
	case_file.close()
	await _wait(0.3)
	# The tester panel and its first-cheat confirm, then the pause menu's tester-run line.
	scene.debug_open_tester_panel()
	await _wait(0.3)
	await _shot("tester_panel_open")
	for i in 3:
		await _press("ui_down")
	await _wait(0.1)
	await _shot("tester_panel_focus")
	var panel: TesterPanel = scene.debug_tester_panel()
	panel.set_god_mode(true)
	await _wait(0.2)
	await _shot("tester_first_cheat_confirm")
	panel.answer(true)
	await _wait(0.1)
	await _shot("tester_after_confirm")
	panel.close()
	await _wait(0.3)
	scene._open_pause()
	await _wait(0.3)
	await _shot("pause_tester_run_line")
	scene._close_pause()
	await _wait(0.1)
	progress.end_dev_run(false)


# --- ending: the Departures desk scene (Augustine), the text box against the 640x360 screen ---

func _ending() -> void:
	var steps: Array = S.for_ending(EndingRules.AUGUSTINE, 0)
	var targets: Array = ["Congratulations, passenger. Your connection is ready.", "ETERNAL REST. ONE WAY.", "I'm not resting. I have business."]
	var n := 0
	for text: String in targets:
		var player_node := CutscenePlayer.new()
		player_node.setup(steps, false)
		root.add_child(player_node)
		player_node.set_process(false)
		await process_frame
		var guard := 0
		while player_node._text != text and not player_node.is_done() and guard < 20000:
			player_node.advance(FRAME, false, false)
			guard += 1
		for i in 20:
			player_node.advance(FRAME, false, false)
		await process_frame
		await process_frame
		var screen := Rect2(Vector2.ZERO, CutscenePlayer.SCREEN)
		var box_rect := Rect2(player_node._box.global_position, player_node._box.size)
		var name_rect := Rect2(player_node._name_label.global_position, player_node._name_label.size)
		var line_rect := Rect2(player_node._line_label.global_position, player_node._line_label.size)
		var font: Font = player_node._name_label.get_theme_font("font")
		var name_w := font.get_string_size(player_node._speaker, HORIZONTAL_ALIGNMENT_LEFT, -1, CutscenePlayer.NAME_SIZE).x
		var line_w := font.get_string_size(player_node._text, HORIZONTAL_ALIGNMENT_LEFT, -1, CutscenePlayer.TEXT_SIZE).x
		print("ENDING %d '%s': viewport %s, box %s inside=%s, name %s (text %.0f px wide), line %s (text %.0f px, lines %d)" % [
			n, text, str(root.get_visible_rect().size), str(box_rect), str(screen.encloses(box_rect)), str(name_rect), name_w, str(line_rect), line_w, player_node._line_label.get_line_count()])
		await _shot("ending_departures_%d" % n)
		await _shot("ending_departures_%d_box_crop3x" % n, Rect2i(0, 280, 640, 80), 3)
		player_node.queue_free()
		await process_frame
		n += 1
