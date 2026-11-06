extends SceneTree
# Opens a real window and shoots the art-direction slice (docs/art/art-direction-notes.md): on the
# Records Basement a combat room, a fight with shots and a ground warning, a shut and an open door, the
# treasure room, the shop with a door in each state, the boss room, Harold standing and walking, and the
# HUD filled; then one combat room on every other floor. Prints the lit luminance of each awake enemy's
# body and of Harold, measured as the pixels that change when the body is hidden (LESSONS 2026-11-05).
# Run only from an exported copy whose config/name is renamed.
# Args after --: floor_1 | combat | others | all, then optionally the folder to save into.

const DEFAULT_OUT := "D:/grandpa-shots-ad/"
const WALL_LIMIT_MS := 560000
const FLOORS := {
	"floor_1": [1, 0], "cemetery": [1, 1], "sunset_shores": [2, 0], "furnace_works": [2, 1],
	"funeral_parlour": [3, 0], "flashback_cinema": [3, 1], "last_resort_cruise": [4, 0], "seance_hotline": [4, 1],
	"terminal_zero": [5, 0], "head_office": [5, 1],
}
const OTHERS := ["cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "flashback_cinema",
	"last_resort_cruise", "seance_hotline", "terminal_zero", "head_office"]

var OUT := DEFAULT_OUT
var _start := 0
var scene
var view: RoomView
var player: Player
var progress
var _walk := false


func _initialize() -> void:
	_start = Time.get_ticks_msec()
	var user_args := OS.get_cmdline_user_args()
	if user_args.size() > 1:
		OUT = user_args[1].trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(OUT)
	physics_frame.connect(_hold_keys)
	_main.call_deferred()


func _process(_d: float) -> bool:
	if Time.get_ticks_msec() - _start > WALL_LIMIT_MS:
		print("PROBE TIMEOUT")
		quit(3)
	if player != null and is_instance_valid(player):
		player.run.health.heal(99)
	return false


func _hold_keys() -> void:
	if _walk:
		Input.action_press("move_right")


func _wait(seconds: float) -> void:
	var began := Time.get_ticks_msec()
	while Time.get_ticks_msec() - began < seconds * 1000.0:
		await process_frame


func _shot(shot_name: String, crop := Rect2i()) -> Image:
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	var out := image
	var k := 2
	if crop.size != Vector2i.ZERO:
		out = image.get_region(crop)
		k = 4
	var big := out.duplicate()
	big.resize(out.get_width() * k, out.get_height() * k, Image.INTERPOLATE_NEAREST)
	big.save_png(OUT + shot_name + ".png")
	print("shot " + shot_name)
	return image


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
	if which == "combat":
		await _combat_only()
	if which == "all" or which == "options":
		change_scene_to_file("res://scenes/title.tscn")
		await _wait(1.2)
		current_scene.call("_choose", "options")
		await _wait(0.5)
		for node in root.find_children("*", "", true, false):
			if is_instance_valid(node) and node.has_method("_show_tab") and node.get("_tab") != null:
				node.call("_show_tab", GameSettings.GAME)
		await _wait(0.3)
		await _shot("options_game")
	if which == "all" or which == "lineup":
		await _lineup("floor_1", ["intern_reaper", "filing_clerk", "debt_ghost", "seasonal_temp", "notary_public",
			"burnt_out_auditor", "denial_officer", "senior_adjuster", "regional_reaper"], "lineup_floor_1")
	if which == "all" or which == "variants":
		await _lineup("floor_1", ["cinema_intern_reaper", "furnace_intern_reaper", "furnace_burnt_out_auditor",
			"parlour_seasonal_temp", "shores_seasonal_temp", "shores_denial_officer"], "lineup_variants")
	if which == "all" or which == "bars":
		await _lineup("floor_1", ["seasonal_temp", "intern_reaper", "denial_officer", "notary_public", "debt_ghost"], "bars_floor_1", true)
		await _lineup("cemetery", ["plot_holder", "intern_reaper", "denial_officer"], "bars_cemetery", true)
		await _lineup("funeral_parlour", ["pallbearer", "weeping_mourner", "parlour_seasonal_temp"], "bars_parlour", true)
	if which == "all" or which == "floor_1":
		await _floor_one()
	if which == "all" or which == "others":
		for floor_id in OTHERS:
			await _other(floor_id)
	progress._store.delete_all()
	print("LOOK DONE")
	quit(0)


func _new_run(floor_id: String) -> bool:
	change_scene_to_file("res://scenes/floor.tscn")
	await _wait(0.3)
	scene = current_scene
	player = scene.player
	scene._depth = FLOORS[floor_id][0]
	scene.debug_choose_path(FLOORS[floor_id][1])
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


func _freeze() -> void:
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)


func _enter(file: String, room_type := "") -> RoomLayout:
	var source: RoomLayout = load(file)
	var layout: RoomLayout = source.duplicate()
	if not room_type.is_empty():
		layout.room_type = room_type
	var map: FloorMap = scene.debug_map()
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.cell = Vector2i(70 + room.id, 70)
	room.room_type = layout.room_type
	room.layout = layout
	room.decor_seed = 7
	# Doors on every side to rooms of four kinds, so each shot shows an opening, and a sign, in each wall.
	var kinds := [RoomLayout.TYPE_SHOP, RoomLayout.TYPE_FLOOR_BOSS, RoomLayout.TYPE_ITEM, RoomLayout.TYPE_HEALING]
	map.rooms.append(room)
	for i in RoomLayout.SIDES.size():
		var beyond := FloorRoom.new()
		beyond.id = map.rooms.size()
		beyond.cell = Vector2i(90 + beyond.id, 90)
		beyond.room_type = kinds[i]
		beyond.layout = layout
		map.rooms.append(beyond)
		room.doors[RoomLayout.SIDES[i]] = beyond.id
	scene._enter_room(room.id)
	await _wait(0.2)
	view = scene.debug_room_view()
	return layout


func _stand(cell: Vector2i) -> void:
	player.global_position = RoomBackdrop.cell_center(cell) - Player.FEET_OFFSET
	player.velocity = Vector2.ZERO


func _middle(layout: RoomLayout) -> Vector2i:
	var size := layout.size_in_cells()
	return layout.nearest_floor_cell(Vector2i(size.x / 2, size.y / 2))


func _room_file(kind: String) -> String:
	var dir: String = scene.debug_floor_def().rooms_dir
	var names := DirAccess.get_files_at(dir)
	names.sort()
	for name in names:
		if name.begins_with(kind) and name.ends_with(".tres") and not name.contains("small") and not name.contains("large"):
			return dir.path_join(name)
	for name in names:
		if name.begins_with(kind) and name.ends_with(".tres"):
			return dir.path_join(name)
	print("NO %s ROOM" % kind)
	return ""


func _lum(c: Color) -> float:
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b


# Each body's lit luminance: the mean of the pixels that change when it is hidden, leaving out the
# near-black outline (under 0.08).
func _bodies(tag: String) -> void:
	await process_frame
	var shown := root.get_texture().get_image()
	var bodies: Array = get_nodes_in_group("enemies")
	bodies.append(player)
	# Only the sprite hides, so its read glow and shadow stay and only the body's own pixels change.
	for body in bodies:
		body._visual.visible = false
	await process_frame
	await process_frame
	var hidden := root.get_texture().get_image()
	for body in bodies:
		body._visual.visible = true
	var canvas := view.get_viewport().get_canvas_transform()
	var worst := 1.0
	for body in bodies:
		var box: Rect2 = body.body_rect() if body.has_method("body_rect") else Rect2(body.global_position - Vector2(12, 18), Vector2(24, 42))
		box = box.grow(2)
		var sum := 0.0
		var n := 0
		var top_left: Vector2 = canvas * box.position
		for y in range(int(top_left.y), int(top_left.y + box.size.y)):
			for x in range(int(top_left.x), int(top_left.x + box.size.x)):
				if x < 0 or y < 0 or x >= shown.get_width() or y >= shown.get_height():
					continue
				var a := shown.get_pixel(x, y)
				var b := hidden.get_pixel(x, y)
				if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) < 0.12 or _lum(a) < 0.08:
					continue
				sum += _lum(a)
				n += 1
		if n > 0:
			var lum := sum / n
			worst = minf(worst, lum)
			var who: String = "harold" if body == player else body.def.id
			print("BODY %s %s lum %.3f px %d" % [tag, who, lum, n])
	print("BODY %s worst %.3f" % [tag, worst])


func _combat_only() -> void:
	if not await _new_run("floor_1"):
		return
	var layout := await _enter(_room_file("combat_0"), RoomLayout.TYPE_COMBAT)
	_stand(_middle(layout))
	await _wait(0.8)
	_freeze()
	await _shot("floor_1_combat")
	await _bodies("floor_1_combat")


func _floor_one() -> void:
	if not await _new_run("floor_1"):
		return
	# The combat room, its doors shut by the fight.
	var layout := await _enter(_room_file("combat_0"), RoomLayout.TYPE_COMBAT)
	var mid := _middle(layout)
	_stand(mid)
	await _wait(0.8)
	_freeze()
	await _shot("floor_1_combat")
	await _bodies("floor_1_combat")
	# The fight: everyone moves and shoots for a while, then a ground warning goes down by Harold and
	# a few shots fly at him.
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(true)
	await _wait(2.0)
	var enemies := get_nodes_in_group("enemies")
	if not enemies.is_empty():
		enemies[0].strike_ground(player.global_position + Vector2(40, 10), 30.0, 2.0)
	for i in mini(3, enemies.size()):
		enemies[i].shoot(enemies[i].global_position.direction_to(player.global_position), 60.0)
	await _wait(0.5)
	_freeze()
	await _shot("floor_1_fight")
	await _bodies("floor_1_fight")
	# A shut door, Harold beside it.
	var north := layout.door_cell(RoomLayout.NORTH)
	_stand(north + Vector2i(1, 2))
	await _wait(0.3)
	await _shot("floor_1_door_locked", Rect2i(240, 0, 160, 110))
	await _clear()
	await _wait(1.0)
	await _shot("floor_1_door_open", Rect2i(240, 0, 160, 110))
	await _shot("floor_1_combat_cleared")
	# Harold standing (three moments of his breath) and walking.
	_stand(mid)
	await _wait(0.4)
	var at: Vector2 = view.get_viewport().get_canvas_transform() * player.global_position
	var crop := Rect2i(int(at.x) - 30, int(at.y) - 34, 60, 64)
	for i in 3:
		await _shot("harold_idle_%d" % i, crop)
		await _wait(0.13)
	_walk = true
	await _wait(0.3)
	for i in 4:
		at = view.get_viewport().get_canvas_transform() * player.global_position
		await _shot("harold_walk_%d" % i, Rect2i(int(at.x) - 30, int(at.y) - 34, 60, 64))
		await _wait(0.09)
	_walk = false
	Input.action_release("move_right")
	# Treasure, with every chest kind and every pickup.
	layout = await _enter(_room_file("treasure"))
	var cells := _free_cells(layout, 14)
	var kinds := [ChestRules.LUNCHBOX, ChestRules.LOCKED, ChestRules.SAFE, ChestRules.URN]
	for i in kinds.size():
		view._create_chest(cells[i], kinds[i])
	view._drop_coin(RoomBackdrop.cell_center(cells[5]), 5)
	for i in 3:
		view._drop_consumable(RoomBackdrop.cell_center(cells[6 + i]), [RoomRules.DROP_KEY, RoomRules.DROP_BOMB, RoomRules.DROP_POTION][i])
	view._add_heal(RoomBackdrop.cell_center(cells[10]), 1)
	_stand(cells[12])
	await _wait(0.5)
	await _shot("floor_1_treasure")
	# The shop, with a door in each state on its top wall.
	layout = await _enter(_room_file("shop"))
	_add_doors(layout)
	_stand(_middle(layout) + Vector2i(0, 2))
	await _wait(0.6)
	await _shot("floor_1_shop")
	for node in view.find_children("ContactShadow", "", true, false):
		var owner_node: Node = node.get_parent()
		print("SHADOW %s %s at %s" % [owner_node.get_class(), owner_node.get_script().resource_path.get_file() if owner_node.get_script() else "", str(node.global_position)])
	# The boss, awake and held still.
	layout = await _enter(_room_file("floor_boss"), RoomLayout.TYPE_FLOOR_BOSS)
	_stand(_middle(layout) + Vector2i(0, 2))
	await _wait(1.0)
	_freeze()
	await _shot("floor_1_boss")
	await _bodies("floor_1_boss")
	await _clear()
	# The HUD with every slot filled.
	await _hud()


func _hud() -> void:
	var run: RunState = player.run
	for i in 3:
		run.add_key()
		run.add_bomb()
	for id in ["hearing_aid", "floor_plan", "fortune_card", "lucky_tee"]:
		var item := _item(id)
		if item != null:
			run.add_item(item)
	var potions := DirAccess.get_files_at("res://data/potions/")
	for name in potions:
		if name.ends_with(".tres"):
			run.give_potion(load("res://data/potions/" + name))
			break
	run.health.pills = maxi(1, run.health.max_pills - 2)
	run.changed.emit()
	await _wait(0.3)
	await _shot("hud")
	await _shot("hud_top", Rect2i(0, 0, 640, 60))
	# What he wears still sits on the redrawn Harold: a cap, then aviators, each with a cardigan band.
	for hat in ["flat_cap", "aviator_sunglasses"]:
		run.look = {"hat": load("res://data/cosmetics/%s.tres" % hat), "cardigan": load("res://data/cosmetics/burgundy_cardigan.tres")}
		player.refresh_look()
		await _wait(0.2)
		var at: Vector2 = view.get_viewport().get_canvas_transform() * player.global_position
		await _shot("harold_" + hat, Rect2i(int(at.x) - 30, int(at.y) - 34, 60, 64))


func _item(id: String) -> ItemDef:
	for item in Content.items():
		if item.id == id:
			return item
	return null


# Needs a Slip, chained, open and locked, along the bottom wall, clear of the room's own south door.
func _add_doors(layout: RoomLayout) -> void:
	var size := layout.size_in_cells()
	var width := size.x
	var spots := [3, 6, width - 7, width - 4]
	var states := [["key", "T"], ["chained", "?"], ["open", "$"], ["locked", "B"]]
	for i in states.size():
		var door := Door.new()
		door.setup(-1, states[i][1], player, RoomLayout.SOUTH)
		door.locked = states[i][0] == "locked"
		door.requires_key = states[i][0] == "key"
		door.chained = states[i][0] == "chained"
		door.set("palette", view.get("_palette"))
		door.set("depth", view.get("_depth"))
		door.position = RoomBackdrop.cell_center(Vector2i(spots[i], size.y - 2))
		view.add_child(door)


func _free_cells(layout: RoomLayout, count: int, step := 3) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	var mid := _middle(layout)
	var size := layout.size_in_cells()
	var cells: Array[Vector2i] = []
	for y in range(2, size.y - 2):
		for x in range(2, size.x - 2):
			if layout.rows[y][x] == "." and posmod(x - mid.x, step) == 0 and posmod(y - mid.y, 2) == 0:
				cells.append(Vector2i(x, y))
	cells.sort_custom(func(a, b): return a.distance_squared_to(mid) < b.distance_squared_to(mid))
	for cell in cells:
		if found.size() >= count:
			break
		found.append(cell)
	if found.size() < count and step > 1:
		return _free_cells(layout, count, step - 1)
	return found


# Every enemy named stands in a row in an empty room on that floor, held still, each with its name under
# it (and its health bar with bars), and the row is shot.
func _lineup(floor_id: String, ids: Array, shot_name: String, bars := false) -> void:
	if not await _new_run(floor_id):
		return
	var layout := await _enter(_room_file("healing"))
	_stand(Vector2i(1, layout.size_in_cells().y - 2))
	var size := layout.size_in_cells()
	var step := maxf(2.0, float(size.x - 2) / ids.size())
	for i in ids.size():
		var path := "res://data/enemies/%s.tres" % ids[i]
		if not ResourceLoader.exists(path):
			print("NO ENEMY %s" % ids[i])
			continue
		var cell := Vector2i(1 + int(step * (i + 0.5)), size.y / 2)
		var enemy: Enemy = view.spawn_fixture(load(path), cell)
		enemy.set_physics_process(false)
		if bars:
			enemy._show_bar = true
			enemy.hp = enemy.max_hp() * 0.6
			enemy._bar_layer.queue_redraw()
		var label := Label.new()
		label.text = String(ids[i]).replace("_", " ")
		label.add_theme_font_size_override("font_size", 8)
		label.add_theme_constant_override("outline_size", 3)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.position = RoomBackdrop.cell_center(cell) + Vector2(-30, 26 + (i % 2) * 10)
		label.size = Vector2(60, 10)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.z_index = 70
		view.add_child(label)
	await _wait(0.6)
	await _shot(shot_name)
	await _clear()


func _other(floor_id: String) -> void:
	if not await _new_run(floor_id):
		return
	var layout := await _enter(_room_file("combat_0"), RoomLayout.TYPE_COMBAT)
	_stand(_middle(layout))
	await _wait(0.8)
	_freeze()
	var enemies := get_nodes_in_group("enemies")
	if not enemies.is_empty():
		enemies[0].strike_ground(player.global_position + Vector2(40, 10), 30.0, 2.0)
	await _wait(0.6)
	await _shot("other_" + floor_id)
	await _clear()
