extends SceneTree
# Opens a real window and shoots the polish pass (docs/art/art-direction-notes.md, "Polish pass"):
# Harold's swing in every cardigan, the Chairman in his fight and in Under New Management, the four props
# drawn by hand and the hotline's partitions, warnings under the small map (MapFade), the
# planchette's path in the large room, the Projectionist's burn after a teleport, and the faint ground
# cue of hidden regular attacks on dark and pale floors.
# Run only from an exported copy whose config/name is renamed.
# Args after --: swing | chairman | props | minimap | zara | burn | cue | all, then optionally the folder.

const DEFAULT_OUT := "D:/grandpa-shots-ad/polish/"
const WALL_LIMIT_MS := 900000
const FLOORS := {
	"floor_1": 1, "cemetery": 1, "sunset_shores": 2, "furnace_works": 2,
	"funeral_parlour": 3, "flashback_cinema": 3, "last_resort_cruise": 4, "seance_hotline": 4,
	"terminal_zero": 5, "head_office": 5,
}
const S := preload("res://scripts/core/cutscene_steps.gd")
const FRAME := 1.0 / 60.0

var OUT := DEFAULT_OUT
var _start := 0
var scene
var view: RoomView
var player: Player
var progress
# Called every frame while set, to hold a boss between the attacks the probe starts.
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
	if player != null and is_instance_valid(player):
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


func _shot(shot_name: String, crop := Rect2i(), k := 0) -> Image:
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	var out := image
	if k == 0:
		k = 2 if crop.size == Vector2i.ZERO else 4
	if crop.size != Vector2i.ZERO:
		crop = crop.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
		out = image.get_region(crop)
	var big := out.duplicate()
	big.resize(out.get_width() * k, out.get_height() * k, Image.INTERPOLATE_NEAREST)
	big.save_png(OUT + shot_name + ".png")
	print("shot " + shot_name)
	return image


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
	for part in ["swing", "chairman", "props", "minimap", "zara", "burn", "cue"]:
		if which == "all" or which == part:
			await call("_" + part)
	progress._store.delete_all()
	print("LOOK DONE")
	quit(0)


func _new_run(floor_id: String) -> bool:
	_hold = Callable()
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


func _freeze() -> void:
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)


func _of(type) -> Array:
	var found := []
	if view == null:
		return found
	for child in view.get_children():
		if is_instance_of(child, type) and not child.is_queued_for_deletion():
			found.append(child)
	return found


# Enters a room of this floor's rooms_dir by file name, with a decor seed, and returns its layout.
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


func _boss_in_room(id: String) -> Enemy:
	await _until(func(): return not get_nodes_in_group("enemies").is_empty(), 2.0)
	for enemy in get_nodes_in_group("enemies"):
		if enemy.def.id == id:
			return enemy
	print("no " + id)
	return null


# --- Harold's swing in every cardigan ---

func _swing() -> void:
	if not await _new_run("floor_1"):
		return
	var layout := await _enter("combat_01", RoomLayout.TYPE_COMBAT)
	await _clear()
	var cell := _middle(layout) + Vector2i(0, 1)
	for id in ["none", "burgundy_cardigan", "mustard_cardigan", "bingo_teal"]:
		player.set_physics_process(true)
		player.run.look = {} if id == "none" else {"cardigan": load("res://data/cosmetics/%s.tres" % id)}
		player.refresh_look()
		_stand_cell(cell)
		await _wait(0.1)
		player.set_physics_process(false)
		print("CARDIGAN %s wears %s" % [id, player._visual.art_id()])
		for way in [1.0, -1.0]:
			var side := "east" if way > 0.0 else "west"
			player._visual.set_facing_left(way < 0.0)
			player._visual.play("idle")
			await _wait(0.2)
			player._visual.play_once("attack", CaneCombo.LOCK_TIME)
			var seen := {}
			var began := Time.get_ticks_msec()
			while player._visual.is_playing_once() and Time.get_ticks_msec() - began < 1000:
				var frame: int = player._visual.sprite().frame if player._visual.sprite() != null else -1
				if not seen.has(frame) and frame >= 0 and frame <= 1:
					seen[frame] = true
					var at := _screen_of(player)
					await _shot("swing_%s_%s_f%d" % [id, side, frame], Rect2i(int(at.x) - 30, int(at.y) - 34, 60, 64))
				await process_frame
			print("SWING %s %s frames shot %s" % [id, side, seen.keys()])
			await _wait(0.3)
	player.set_physics_process(true)
	player.run.look = {}
	player.refresh_look()


# --- the Chairman: his fight, and Under New Management ---

func _chairman() -> void:
	AttackWarnings.shown = false
	if not await _new_run("head_office"):
		return
	# Alone in a quiet room, his idle, walk, windup and slam played on his own sprite, measured each time.
	var layout := await _enter("healing_01", RoomLayout.TYPE_HEALING)
	await _clear()
	var mid := _middle(layout)
	_stand_cell(layout.nearest_floor_cell(mid + Vector2i(-3, 0)))
	var chairman: Enemy = view.spawn_fixture(load("res://data/enemies/chairman_of_the_board.tres"), mid)
	chairman.set_physics_process(false)
	await _wait(0.5)
	var visual: SpriteVisual = chairman._visual
	for anim in ["idle", "walk", "windup", "attack"]:
		visual.play(anim)
		for i in 3:
			await _wait(0.12)
			var at := _screen_of(chairman)
			var image := await _shot("chairman_%s_%d" % [anim, i], _crop_round(at + Vector2(0, -20), Vector2i(110, 110)))
			var width: int = await _body_width(image, chairman)
			print("CHAIRMAN %s %d frame %d width %d" % [anim, i, visual.sprite().frame, width])
	# Harold beside him for size.
	_stand(chairman.global_position + Vector2(-34, 0))
	visual.play("idle")
	await _wait(0.2)
	await _shot("chairman_beside_harold", _crop_round(_screen_of(chairman) + Vector2(-17, -20), Vector2i(130, 100)))
	await _clear()
	# His real fight: windup and slam as they come.
	layout = await _enter("floor_boss_01", RoomLayout.TYPE_FLOOR_BOSS)
	_stand_cell(_middle(layout) + Vector2i(0, 2))
	var boss := await _boss_in_room("chairman_of_the_board")
	var shots := 0
	var began := Time.get_ticks_msec()
	var last_anim := ""
	while boss != null and is_instance_valid(boss) and shots < 8 and Time.get_ticks_msec() - began < 20000:
		var anim: String = boss._visual.shown_anim()
		if anim != last_anim and (anim == "windup" or anim == "attack" or anim.begins_with("slam")):
			await _shot("chairman_fight_%d_%s" % [shots, anim])
			shots += 1
		last_anim = anim
		await process_frame
	print("CHAIRMAN fight shots %d" % shots)
	await _clear()
	# Under New Management, stepped by hand.
	var steps: Array = S.for_ending(EndingRules.NEW_MANAGEMENT)
	var length := S.duration_of(steps)
	var cut := CutscenePlayer.new()
	cut.setup(steps, false)
	root.add_child(cut)
	cut.set_process(false)
	await process_frame
	var stepped := 0.0
	var n := 0
	while stepped < length and not cut.is_done() and n < 14:
		var target := length * (n + 1) / 15.0
		while stepped < target and not cut.is_done():
			cut.advance(FRAME, false, false)
			stepped += FRAME
		await process_frame
		await process_frame
		var actor := _find_actor(cut, "chairman")
		var note := ""
		if actor != null:
			var sv: SpriteVisual = _find_visual(actor)
			note = "art %s left %s anim %s at %s" % [sv.art_id() if sv != null else "(code)", sv.is_facing_left() if sv != null else "-", sv.shown_anim() if sv != null else "-", actor.position]
		var image := root.get_texture().get_image()
		var big := image.duplicate()
		big.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
		big.save_png(OUT + "new_management_%02d.png" % n)
		print("NEW_MANAGEMENT %02d t=%.1f %s" % [n, stepped, note])
		n += 1
	cut.queue_free()
	await process_frame
	# His bow, a turn of his whole figure, caught at its deepest.
	var bow := CutscenePlayer.new()
	bow.setup(steps, false)
	root.add_child(bow)
	bow.set_process(false)
	await process_frame
	var t := 0.0
	while t < length and not bow.is_done():
		bow.advance(FRAME, false, false)
		t += FRAME
		var who := _find_actor(bow, "chairman")
		if who != null and absf(who.rotation) > 0.4:
			await _shot("new_management_bow")
			print("NEW_MANAGEMENT bow at t=%.1f rotation %.2f" % [t, who.rotation])
			break
	bow.queue_free()
	await process_frame


func _find_actor(node: Node, actor_id: String) -> Node2D:
	for child in node.find_children("*", "", true, false):
		if child is CutsceneActor and child.id == actor_id:
			return child
	return null


func _find_visual(node: Node) -> SpriteVisual:
	return node.get("_sprite") as SpriteVisual


# The width of the body's opaque pixels on his middle row band, measured by hiding his sprite.
func _body_width(image: Image, enemy: Enemy) -> int:
	enemy._visual.visible = false
	await process_frame
	await process_frame
	var bare := root.get_texture().get_image()
	enemy._visual.visible = true
	var at := _screen_of(enemy)
	var lo := 9999
	var hi := -1
	for y in range(int(at.y) - 30, int(at.y) - 8):
		for x in range(int(at.x) - 50, int(at.x) + 50):
			if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
				continue
			var a := image.get_pixel(x, y)
			var b := bare.get_pixel(x, y)
			if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.12:
				lo = mini(lo, x)
				hi = maxi(hi, x)
	return hi - lo + 1 if hi >= 0 else 0


# --- the four hand-drawn props and the hotline's partitions ---

func _props() -> void:
	for spec: Array in [["sunset_shores", RoomDecor.IV_STAND, "drip_stand"], ["furnace_works", RoomDecor.GAUGE, "gauge"]]:
		if not await _new_run(spec[0]):
			continue
		var found := _decor_room(spec[1])
		if found.is_empty():
			print("PROPS no %s room" % spec[1])
			continue
		await _enter(found["file"], RoomLayout.TYPE_COMBAT, found["seed"])
		await _clear()
		_stand_cell(found["cell"] + Vector2i(-2, 1))
		await _wait(0.4)
		var at := _screen_of(view) + RoomBackdrop.cell_center(found["cell"])
		await _shot("prop_%s_room" % spec[2])
		await _shot("prop_%s_close" % spec[2], _crop_round(at, Vector2i(120, 80)))
	# The parlour's candelabra: a room laid with candle stands.
	if await _new_run("funeral_parlour"):
		var file := _room_with(RoomLayout.SYMBOL_CANDLE)
		if not file.is_empty():
			var layout := await _enter(file, RoomLayout.TYPE_COMBAT)
			await _clear()
			var cell: Vector2i = layout.cells_of(RoomLayout.SYMBOL_CANDLE)[0]
			_stand_cell(layout.nearest_floor_cell(cell + Vector2i(-2, 1)))
			await _wait(0.4)
			await _shot("prop_candelabra_room")
			await _shot("prop_candelabra_close", _crop_round(_screen_of(view) + RoomBackdrop.cell_center(cell), Vector2i(120, 80)))
	# The Cinema's aisle lights at the row ends beside the seats.
	if await _new_run("flashback_cinema"):
		var file := _room_with(RoomLayout.SYMBOL_SEAT)
		if not file.is_empty():
			var layout := await _enter(file, RoomLayout.TYPE_COMBAT)
			await _clear()
			var spots := CinemaProps.aisle_light_spots(layout)
			_stand_cell(_middle(layout))
			await _wait(0.4)
			await _shot("prop_aisle_lights_room")
			if not spots.is_empty():
				await _shot("prop_aisle_light_close", _crop_round(_screen_of(view) + spots[0], Vector2i(100, 70)))
			print("AISLE lights %d" % _of(AisleLight).size())
	# The hotline's partitions: a run and a lone panel.
	if await _new_run("seance_hotline"):
		for file in ["combat_small_02", "combat_02", "combat_large_02"]:
			var layout := await _enter(file, RoomLayout.TYPE_COMBAT)
			await _clear()
			var cells := layout.cells_of(RoomLayout.SYMBOL_PARTITION)
			if cells.is_empty():
				continue
			_stand_cell(layout.nearest_floor_cell(cells[0] + Vector2i(0, 2)))
			await _wait(0.4)
			await _shot("partitions_%s" % file)
			await _shot("partitions_%s_close" % file, _crop_round(_screen_of(view) + RoomBackdrop.cell_center(cells[0]), Vector2i(160, 90)))


# A combat room of this floor and a decor seed whose decor holds this kind, and its cell.
func _decor_room(kind: String) -> Dictionary:
	var def: FloorDef = scene.debug_floor_def()
	var names := DirAccess.get_files_at(def.rooms_dir)
	names.sort()
	for name in names:
		if not name.begins_with("combat_0") or not name.ends_with(".tres"):
			continue
		var layout: RoomLayout = load(def.rooms_dir.path_join(name))
		for seed_value in range(1, 60):
			for item: Dictionary in RoomDecor.plan(layout, def.room_palette(), seed_value):
				if item.get("kind", "") == kind:
					return {"file": name.trim_suffix(".tres"), "seed": seed_value, "cell": item["cell"]}
	return {}


func _room_with(symbol: String) -> String:
	var dir: String = scene.debug_floor_def().rooms_dir
	var names := DirAccess.get_files_at(dir)
	names.sort()
	for name in names:
		if name.begins_with("combat") and name.ends_with(".tres"):
			var layout: RoomLayout = load(dir.path_join(name))
			if not layout.cells_of(symbol).is_empty():
				return name.trim_suffix(".tres")
	print("no room with %s" % symbol)
	return ""


# --- warnings under the small map ---

func _minimap() -> void:
	for floor_id in ["funeral_parlour", "floor_1", "seance_hotline"]:
		if not await _new_run(floor_id):
			continue
		var layout := await _enter("combat_large_01", RoomLayout.TYPE_COMBAT)
		await _clear()
		var size := layout.size_in_cells()
		_stand_cell(layout.nearest_floor_cell(Vector2i(size.x - 5, 4)))
		await _wait(0.6)
		# No warning: the map must stay whole.
		await _map_state("minimap_%s_quiet" % floor_id)
		AttackWarnings.shown = true
		var regular: Enemy = view.spawn_fixture(scene.debug_floor_def().enemies[0], layout.nearest_floor_cell(Vector2i(size.x / 2, size.y - 3)))
		regular.set_physics_process(false)
		var inverse := view.get_viewport().get_canvas_transform().affine_inverse()
		# A warning away from the map leaves it whole.
		regular.strike_ground(inverse * Vector2(200, 250), 30.0, 3.0)
		await _wait(0.8)
		await _map_state("minimap_%s_warning_elsewhere" % floor_id)
		# A ring under the map, and one half under it.
		regular.strike_ground(inverse * Vector2(585, 45), 30.0, 3.0)
		regular.strike_ground(inverse * Vector2(515, 60), 26.0, 3.0)
		await _wait(0.8)
		await _map_state("minimap_%s_rings" % floor_id)
		await _clear()
		await _wait(0.6)
		await _map_state("minimap_%s_after" % floor_id)
		# A lane from the far side of the view that runs under the map.
		regular = view.spawn_fixture(scene.debug_floor_def().enemies[0], layout.nearest_floor_cell(Vector2i(size.x / 2, size.y - 3)))
		regular.set_physics_process(false)
		var lane := RunwayLane.new()
		lane.setup(regular, Vector2.RIGHT, 700.0, 24.0, 0.0, 3.0)
		view.add_child(lane)
		lane.global_position = inverse * Vector2(0, 40)
		await _wait(0.8)
		await _map_state("minimap_%s_lane" % floor_id)
		# What the check costs, in this room, per frame.
		var area := MapFade.world_rect(view.get_viewport().get_canvas_transform())
		var began := Time.get_ticks_usec()
		for i in 200:
			MapFade.covered(view, area)
		print("MAPFADE %s check %.1f us with %d room children" % [floor_id, (Time.get_ticks_usec() - began) / 200.0, view.get_child_count()])
		# The big map still covers everything.
		scene.debug_big_map().set_open(true)
		await _wait(0.3)
		await _shot("minimap_%s_big_map" % floor_id)
		scene.debug_big_map().set_open(false)
		await _wait(0.2)
		await _clear()
		AttackWarnings.shown = false


func _map_state(shot_name: String) -> void:
	await _shot(shot_name)
	await _shot(shot_name + "_corner", Rect2i(Hud.MAP_PANEL.grow(30)).intersection(Rect2i(0, 0, 640, 360)), 4)
	print("MAPFADE %s alpha %.2f" % [shot_name, scene._hud.map_alpha()])
	var area := MapFade.world_rect(view.get_viewport().get_canvas_transform())
	for child in view.get_children():
		for shape in MapFade.shapes_of(child):
			if MapFade._overlaps(shape, area):
				print("  under the map: %s %s %s" % [child.name, child.get_script().resource_path if child.get_script() != null else child.get_class(), shape])


# --- Madame Zara's planchette with Harold in the large room's south half ---

func _zara() -> void:
	if not await _new_run("seance_hotline"):
		return
	var layout := await _enter("floor_boss_large_01", RoomLayout.TYPE_FLOOR_BOSS)
	var boss := await _boss_in_room("madame_zara")
	if boss == null:
		return
	var b = boss._behavior
	_hold = func():
		if is_instance_valid(boss) and not b._telegraph.is_active():
			b._cooldown = 99.0
			b._summon_timer = maxf(b._summon_timer, 1.0)
	var size := layout.size_in_cells()
	var room_size := Vector2(size) * RoomBackdrop.TILE
	var shown := 0
	var tries := 0
	for spot: Vector2i in [Vector2i(5, size.y - 4), Vector2i(size.x / 2, size.y - 3), Vector2i(size.x - 6, size.y - 4)]:
		var center: Vector2 = RoomBackdrop.cell_center(_middle(layout))
		boss.global_position = center
		_stand_cell(layout.nearest_floor_cell(spot))
		await _wait(0.6)
		b._begin(boss, MadameZaraBehavior.Attack.OUIJA, false)
		var plan = b.planchette()
		if plan == null:
			print("ZARA no plan at %s" % spot)
			continue
		await _until(func(): return not is_instance_valid(plan) or (plan.is_warning() and plan.fill() > 0.5), 2.0)
		var clear := BossMoves.clear_view(room_size, player.feet().global_position)
		var path: Array[Vector2] = plan.path()
		var ok := OuijaPlanchette.path_shown(path, clear)
		tries += 1
		if ok:
			shown += 1
		print("ZARA spot %s word %s path shown clear of the HUD: %s" % [spot, plan.word(), ok])
		await _shot("zara_planchette_%d" % tries)
		await _until(func(): return not is_instance_valid(plan) or plan.is_spent(), 6.0)
		await _wait(0.4)
	print("ZARA %d of %d paths shown" % [shown, tries])
	_hold = Callable()
	await _clear()


# --- the Projectionist's burn after a teleport out and back ---

func _burn() -> void:
	if not await _new_run("flashback_cinema"):
		return
	await _enter("floor_boss_large_01", RoomLayout.TYPE_FLOOR_BOSS)
	var boss_room: int = scene.debug_current_id()
	var boss := await _boss_in_room("projectionist")
	if boss == null:
		return
	var b = boss._behavior
	_hold = func():
		if is_instance_valid(boss) and not b._telegraph.is_active():
			b._cooldown = 99.0
			b._since_reel = -99.0
	_stand(boss.global_position + Vector2(-120, 60))
	boss.hp = boss.max_hp() * 0.45
	await _until(func(): return b.burn() != null, 1.5)
	if b.burn() == null:
		print("BURN never came")
		return
	b.burn()._radius = b.burn().cap() * 0.6
	await _wait(0.5)
	var screen := CinemaScreen.in_room(view)
	print("BURN before: reach %.1f of %.1f, screen burning %.2f" % [b.burn().radius(), b.burn().cap(), screen.burning() if screen != null else -1.0])
	await _shot("burn_before_teleport")
	# Out to another room and back, as a teleport does.
	await _enter("healing_01", RoomLayout.TYPE_HEALING)
	await _wait(0.5)
	print("BURN away: valid %s" % (b.burn() != null))
	scene._enter_room(boss_room)
	await _wait(0.1)
	view = scene.debug_room_view()
	await _until(func(): return b.burn() != null, 1.5)
	await _wait(0.4)
	screen = CinemaScreen.in_room(view)
	var rings := _of(BurnRing).size()
	print("BURN after: reach %.1f, rings %d, screen burning %.2f, boss bar %s" % [b.burn().radius() if b.burn() != null else -1.0, rings, screen.burning() if screen != null else -1.0, scene._hud.is_boss_bar_visible()])
	# The ring and the burning screen, with Harold walked up under them.
	if b.burn() != null:
		_stand(b.burn().global_position + Vector2(0, 90))
	await _wait(0.4)
	await _shot("burn_after_teleport_ring")
	await _shot("burn_after_teleport")
	_hold = Callable()
	await _clear()


# --- the faint ground cue of hidden regular attacks ---

func _cue() -> void:
	AttackWarnings.shown = false
	for floor_id in ["seance_hotline", "funeral_parlour", "sunset_shores", "head_office", "floor_1"]:
		if not await _new_run(floor_id):
			continue
		var layout := await _enter("healing_01", RoomLayout.TYPE_HEALING)
		await _clear()
		var mid := _middle(layout)
		_stand_cell(mid)
		var regular: Enemy = view.spawn_fixture(scene.debug_floor_def().enemies[0], layout.nearest_floor_cell(mid + Vector2i(4, 2)))
		regular.set_physics_process(false)
		await _wait(0.3)
		var strike: GroundStrike = regular.strike_ground(player.global_position + Vector2(36, 12), 26.0, 2.0)
		var at := _screen_of(player) + Vector2(36, 12)
		await _until(func(): return not is_instance_valid(strike) or strike.fill() > 0.35, 2.0)
		print("CUE %s %s" % [floor_id, strike.cue() if is_instance_valid(strike) else "gone"])
		await _shot("cue_%s_mid" % floor_id, _crop_round(at, Vector2i(140, 90)))
		await _until(func(): return not is_instance_valid(strike) or strike.fill() > 0.9, 2.0)
		await _shot("cue_%s_late" % floor_id, _crop_round(at, Vector2i(140, 90)))
		await _clear()
	# The regulars whose attacks are only a ground cue with the setting off: shot mid windup.
	for spec: Array in [["furnace_works", "steam_valve"], ["seance_hotline", "phone_psychic"], ["seance_hotline", "seance_bingo_caller"], ["floor_1", "bingo_caller"]]:
		if not await _new_run(spec[0]):
			continue
		var layout := await _enter("healing_01", RoomLayout.TYPE_HEALING)
		await _clear()
		var mid := _middle(layout)
		_stand_cell(mid)
		var path := "res://data/enemies/%s.tres" % spec[1]
		if not ResourceLoader.exists(path):
			print("CUE no %s" % spec[1])
			continue
		var enemy: Enemy = view.spawn_fixture(load(path), layout.nearest_floor_cell(mid + Vector2i(3, 0)))
		for i in 2:
			await _until(func(): return not is_instance_valid(enemy) or enemy.is_winding_up(), 8.0)
			await _wait(0.25 + 0.3 * i)
			await _shot("cue_%s_%s_%d" % [spec[0], spec[1], i])
			await _wait(1.5)
		await _clear()
