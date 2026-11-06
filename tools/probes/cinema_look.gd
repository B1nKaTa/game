extends SceneTree
# Opens a real window and saves screenshots of the Flashback Cinema: small, medium and large rooms with
# their enemies, the screen at two moments of its flicker (and cut to black, flashed and burning, as
# the Projectionist will drive it), a lobby card's line near the top of a room and lower down, and the
# projector's beam in an empty room at both ends of a large one; and every attack of the Cinema's
# enemies and bosses (cinema_attack_*.png), each shot timed by the attack's own state.
# Run only from an exported copy whose config/name is renamed.
# Args after --: rooms | screen | signs | beam | attacks | all

const OUT := "D:/grandpa-shots-pr/"
const WALL_LIMIT_MS := 420000
const DIR := "res://data/rooms/flashback_cinema/%s.tres"

var _start := 0
var scene
var view: RoomView
var player: Player
var progress
# Called every frame while set, to hold a boss between the attacks the probe starts (lesson 159).
var _hold := Callable()


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
	if _hold.is_valid():
		_hold.call()
	return false


func _wait(seconds: float) -> void:
	var began := Time.get_ticks_msec()
	while Time.get_ticks_msec() - began < seconds * 1000.0:
		await process_frame


func _shot(shot_name: String) -> Image:
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	var big := image.duplicate()
	big.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	big.save_png(OUT + "cinema_" + shot_name + ".png")
	print("shot " + shot_name)
	return image


# The screen alone, enlarged, cut from a shot.
func _crop_screen(image: Image, shot_name: String) -> void:
	var screen := CinemaScreen.in_room(view)
	if screen == null:
		print("no screen to crop")
		return
	var rect := screen.picture_rect().grow(10.0)
	var canvas := view.get_viewport().get_canvas_transform()
	var on_screen := Rect2(canvas * rect.position, rect.size * canvas.get_scale())
	var scale_x := float(image.get_width()) / RoomBackdrop.VIEW_SIZE.x
	var region := Rect2i(Vector2i(on_screen.position * scale_x), Vector2i(on_screen.size * scale_x)).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var crop := image.get_region(region)
	crop.resize(crop.get_width() * 4, crop.get_height() * 4, Image.INTERPOLATE_NEAREST)
	crop.save_png(OUT + "cinema_" + shot_name + ".png")
	print("crop " + shot_name)


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
	var args := OS.get_cmdline_user_args()
	var which: String = args[0] if args.size() > 0 else "all"
	await _new_run()
	for part in ["rooms", "screen", "signs", "beam", "attacks"]:
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
	scene._depth = 3
	for index in 2:
		if scene._path_defs()[index].id == "flashback_cinema":
			scene.debug_choose_path(index)
	await _wait(0.2)
	view = scene.debug_room_view()
	print("floor %s" % scene.debug_floor_def().display_name)
	await _clear()


func _clear() -> void:
	for enemy in get_nodes_in_group("enemies"):
		enemy.dismiss()
	await _wait(0.1)


func _freeze_all() -> void:
	for e in get_nodes_in_group("enemies"):
		e.set_physics_process(false)


func _enter(file: String, type: String, seed_value := 7) -> RoomLayout:
	var source: RoomLayout = load(DIR % file)
	var map: FloorMap = scene.debug_map()
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.cell = Vector2i(90 + room.id, 90)
	room.room_type = type
	room.layout = source
	room.decor_seed = seed_value + room.id
	map.rooms.append(room)
	scene._enter_room(room.id)
	await _wait(0.15)
	view = scene.debug_room_view()
	return source


func _show_room(file: String, shot_name: String, stand_side := RoomLayout.SOUTH) -> void:
	var source := await _enter(file, RoomLayout.TYPE_COMBAT)
	_stand(RoomBackdrop.cell_center(source.door_cell(stand_side)) + Vector2(0, -8 if stand_side == RoomLayout.SOUTH else 8))
	await _wait(0.75)
	_freeze_all()
	await _shot(shot_name)
	await _clear()


# --- rooms with their enemies ---

func _rooms() -> void:
	await _show_room("combat_small_01", "room_small")
	await _show_room("combat_small_02", "room_small_pillars")
	await _show_room("combat_01", "room_medium")
	await _show_room("combat_04", "room_medium_pillars")
	await _show_room("combat_large_01", "room_large_south")
	await _show_room("combat_large_03", "room_large_north", RoomLayout.NORTH)
	await _show_room("floor_boss_large_01", "room_boss_large_north", RoomLayout.NORTH)


# --- the screen ---

func _screen() -> void:
	await _enter("combat_02", RoomLayout.TYPE_COMBAT)
	await _clear()
	_stand(_cell(10, 6))
	await _wait(0.5)
	var first := await _shot("screen_medium_a")
	_crop_screen(first, "screen_crop_a")
	await _wait(3.3)
	var second := await _shot("screen_medium_b")
	_crop_screen(second, "screen_crop_b")
	var screen := CinemaScreen.in_room(view)
	screen.flash()
	await _wait(0.05)
	_crop_screen(await _shot("screen_flash"), "screen_crop_flash")
	screen.cut_to_black(1.5)
	await _wait(0.4)
	await _shot("screen_cut_to_black")
	await _wait(1.6)
	screen.set_burning(0.45)
	await _wait(0.2)
	_crop_screen(await _shot("screen_burning"), "screen_crop_burning")
	screen.set_burning(0.0)
	await _enter("combat_small_03", RoomLayout.TYPE_COMBAT)
	await _clear()
	_stand(_cell(7, 5))
	await _wait(0.4)
	_crop_screen(await _shot("screen_small"), "screen_crop_small")


# --- the lobby cards ---

func _sign_in(file: String, shot_name: String) -> void:
	var own: RoomLayout = load(DIR % file)
	var layout := await _enter(file, own.room_type)
	await _clear()
	var card := layout.cells_of(RoomLayout.SYMBOL_LIFE_SIGN)[0]
	_stand(RoomBackdrop.cell_center(card) + Vector2(14, 22))
	await _wait(0.5)
	var shown := ""
	for child in view.get_children():
		if child is LifeSign:
			shown = child.showing_text()
	print("card %s shows: %s" % [file, shown])
	await _shot(shot_name)


func _signs() -> void:
	await _sign_in("combat_01", "sign_near_the_top")
	await _sign_in("combat_large_02", "sign_low_in_a_large_room")
	await _sign_in("healing_small_01", "sign_small_room_east")
	await _sign_in("vault_large_01", "sign_large_room_corner")
	# Walking away hides it again.
	_stand(_cell(10, 8))
	await _wait(0.4)
	await _shot("sign_walked_away")
	print("seen in the save: %s" % str(progress.data.life_signs_seen))


# --- the beam ---

func _beam() -> void:
	await _enter("combat_03", RoomLayout.TYPE_COMBAT)
	await _clear()
	_stand(_cell(17, 9))
	await _wait(0.6)
	await _shot("beam_medium_empty")
	await _enter("combat_large_02", RoomLayout.TYPE_COMBAT)
	await _clear()
	_stand(_cell(6, 14))
	await _wait(0.6)
	await _shot("beam_large_south")
	_stand(_cell(6, 3))
	await _wait(0.8)
	await _shot("beam_large_north")


# --- every attack of the Cinema's enemies and bosses ---

func _until(check: Callable, limit: float) -> bool:
	var began := Time.get_ticks_msec()
	while not check.call() and Time.get_ticks_msec() - began < limit * 1000.0:
		await process_frame
	return check.call()


func _spawn(id: String, at: Vector2) -> Enemy:
	return view._spawn_enemy(load("res://data/enemies/%s.tres" % id), at, true)


func _of(type) -> Array:
	var found := []
	for child in view.get_children():
		if is_instance_of(child, type) and not child.is_queued_for_deletion():
			found.append(child)
	return found


func _warned(enemy: Enemy, share: float) -> bool:
	return is_instance_valid(enemy) and enemy._warning != null and enemy._warning.warning_progress(enemy._warning_share()) > share


func _attack_shot(shot_name: String) -> void:
	await _shot("attack_" + shot_name)


func _quiet_combat(file: String) -> RoomLayout:
	var layout := await _enter(file, RoomLayout.TYPE_COMBAT)
	await _clear()
	for coin in _of(Pickup):
		coin.collect()
	return layout


func _boss_in_room(id: String) -> Enemy:
	await _until(func(): return not get_nodes_in_group("enemies").is_empty(), 2.0)
	for enemy in get_nodes_in_group("enemies"):
		if enemy.def.id == id:
			return enemy
	print("no " + id)
	return null


func _attacks() -> void:
	await _regulars()
	await _crabtree()
	await _projectionist()


func _regulars() -> void:
	# The Usher: his torch beam on patrol, then "Shh!" with the beam line warned, then the charge.
	await _quiet_combat("combat_02")
	_stand(_cell(5, 7))
	var usher := _spawn("usher", _cell(13, 7))
	await _wait(0.8)
	await _attack_shot("usher_torch_patrol")
	var b = usher._behavior
	b._look = usher.global_position.direction_to(player.feet().global_position)
	b._patrol = usher.global_position
	b._seen = UsherBehavior.SPOT_TIME * 0.9
	await _until(func(): return _warned(usher, 0.5), 3.0)
	await _attack_shot("usher_shh_lane")
	await _until(func(): return b._charge_left > 0.0 and b._charged_for > 0.1, 2.0)
	await _attack_shot("usher_charge")
	await _clear()
	# The Popcorn Vendor: the tub's mark and spokes as it flies in, then the six kernels.
	_stand(_cell(6, 7))
	var vendor := _spawn("popcorn_vendor", _cell(14, 5))
	vendor._behavior._cooldown = 0.0
	await _until(func(): return _of(PopcornTub).any(func(tub): return tub.fill() > 0.55), 6.0)
	await _attack_shot("popcorn_tub_mark")
	await _until(func(): return _of(PopcornTub).any(func(tub): return tub.has_landed()), 2.0)
	await _wait(0.12)
	await _attack_shot("popcorn_kernels")
	await _clear()
	# The Runaway Film Reel: its warned leg, the strip it lays, and the turn toward him at a bounce.
	_stand(_cell(10, 8))
	var reel := _spawn("film_reel", _cell(4, 4))
	await _until(func(): return _warned(reel, 0.4), 3.0)
	await _attack_shot("film_reel_first_leg")
	await _until(func(): return _of(FilmTrail).any(func(trail): return trail.piece_count() > 14), 6.0)
	await _attack_shot("film_reel_trail")
	var first_way: Vector2 = reel._behavior._way
	await _until(func(): return is_instance_valid(reel) and reel._behavior._way != first_way and _warned(reel, 0.3), 8.0)
	await _attack_shot("film_reel_bounce_turn")
	var trails := _of(FilmTrail)
	if not trails.is_empty() and trails[0].piece_count() > 0:
		var trail = trails[0]
		_stand(trail._pieces[trail.piece_count() - 1][0])
		await _wait(0.3)
		await _attack_shot("film_reel_trail_slows")
	await _clear()
	# The Extra: grey, with its shove warned.
	_stand(_cell(9, 7))
	var extra := _spawn("extra", _cell(12, 7))
	await _until(func(): return _warned(extra, 0.4), 4.0)
	await _attack_shot("extra_shove")
	await _clear()
	await _wait(0.5)


func _crabtree() -> void:
	await _enter("mini_boss_01", RoomLayout.TYPE_MINI_BOSS)
	var boss := await _boss_in_room("crabtree")
	if boss == null:
		return
	var b = boss._behavior
	var center: Vector2 = boss.global_position
	_hold = func():
		if is_instance_valid(boss) and not b._telegraph.is_active():
			b._cooldown = 99.0
			b._review_timer = maxf(b._review_timer, 0.5)
	_stand(center + Vector2(-110, 30))
	await _wait(0.8)
	for rating in [1, 5]:
		b.forced_rating = rating
		b._begin(boss, CrabtreeBehavior.Attack.STARS)
		await _until(func(): return _warned(boss, 0.6), 2.0)
		await _attack_shot("crabtree_stars_%d_lanes" % rating)
		await _until(func(): return not b._telegraph.is_active(), 2.0)
		await _wait(0.18)
		await _attack_shot("crabtree_stars_%d_flying" % rating)
		await _wait(1.2)
	b._begin(boss, CrabtreeBehavior.Attack.THUMBS)
	await _until(func(): return _warned(boss, 0.6), 2.0)
	await _attack_shot("crabtree_thumbs_down_warned")
	await _until(func(): return _of(Shockwave).any(func(ring): return ring.is_growing() and ring.radius_now() > 70.0), 2.0)
	await _attack_shot("crabtree_thumbs_down_ring")
	await _wait(0.8)
	_hold = func():
		if is_instance_valid(boss) and not b._telegraph.is_active():
			b._cooldown = 99.0
	b._review_timer = 0.0
	await _until(func(): return not _of(SummonMark).is_empty(), 2.0)
	await _wait(0.3)
	await _attack_shot("crabtree_bad_review_marks")
	await _until(func(): return _of(SummonMark).is_empty(), 2.0)
	await _wait(0.4)
	await _attack_shot("crabtree_hecklers")
	_hold = Callable()
	await _clear()


func _projectionist() -> void:
	await _enter("floor_boss_large_01", RoomLayout.TYPE_FLOOR_BOSS)
	var boss := await _boss_in_room("projectionist")
	if boss == null:
		return
	var b = boss._behavior
	var center: Vector2 = boss.global_position
	_hold = func():
		if is_instance_valid(boss) and not b._telegraph.is_active():
			b._cooldown = 99.0
			b._since_reel = -99.0
	_stand(center + Vector2(-120, 40))
	await _wait(0.9)
	await _attack_shot("projectionist_boss_bar")
	var screen := CinemaScreen.in_room(view)
	# The reel changes, with the screen in view: the cut to black and the flash, then each reel's hazard.
	_stand(_cell(9, 5))
	await _wait(0.6)
	for kind in [ReelChange.Genre.RAIN, ReelChange.Genre.COMEDY, ReelChange.Genre.WESTERN]:
		b.forced_reel = kind
		b._begin(boss, ProjectionistBehavior.Attack.REEL, false)
		if kind == ReelChange.Genre.RAIN:
			await _until(func(): return screen != null and screen.darkness() > 0.9, 1.0)
			await _attack_shot("reel_change_black_screen")
			await _until(func(): return b.reel() != null, 1.5)
			await _attack_shot("reel_change_flash")
			await _wait(0.8)
			await _attack_shot("reel_rain_floor")
			# Warnings must still read on the wet floor.
			b._begin(boss, ProjectionistBehavior.Attack.SPLICE, false)
			await _until(func(): return _of(SpliceLane).any(func(lane): return lane.fill() > 0.6), 2.0)
			await _attack_shot("reel_rain_with_splice")
			await _until(func(): return _of(SpliceLane).is_empty(), 2.0)
		else:
			await _until(func(): return b.reel() != null, 1.5)
			var look := "pie" if kind == ReelChange.Genre.COMEDY else "tumbleweed"
			await _until(func(): return _of(ReelLane).any(func(lane): return lane.is_warning() and lane.fill() > 0.6), 3.0)
			await _attack_shot("reel_%s_lanes" % look)
			await _until(func(): return _of(ReelLane).any(func(lane): return not lane.is_warning() and lane.travelled() > 160.0), 3.0)
			await _attack_shot("reel_%s_flying" % look)
		var running = b.reel()
		if running != null:
			running._left = 0.05
		for wet in _of(WetSplash):
			wet._left = 0.05
		await _until(func(): return _of(ReelLane).is_empty(), 4.0)
		await _wait(0.3)
	# The lens beam, the heaviest attack: early and late in its windup, then sweeping.
	boss.global_position = center
	_stand(center + Vector2(-120, 40))
	await _wait(0.2)
	b._begin(boss, ProjectionistBehavior.Attack.BEAM, false)
	await _until(func(): return _of(LensBeam).any(func(beam): return beam.fill() > 0.3), 2.0)
	await _attack_shot("lens_beam_warning_early")
	await _until(func(): return _of(LensBeam).any(func(beam): return beam.fill() > 0.85), 2.0)
	await _attack_shot("lens_beam_warning_late")
	await _until(func(): return _of(LensBeam).any(func(beam): return beam.is_sweeping() and beam._swept > LensBeam.SWEEP_TIME * 0.45), 4.0)
	await _attack_shot("lens_beam_sweeping")
	await _until(func(): return _of(LensBeam).is_empty(), 4.0)
	# The splice: the film lanes warned, then snapping shut.
	await _wait(0.3)
	b._begin(boss, ProjectionistBehavior.Attack.SPLICE, false)
	await _until(func(): return _of(SpliceLane).any(func(lane): return lane.fill() > 0.6), 2.0)
	await _attack_shot("splice_lanes_warned")
	await _until(func(): return _of(SpliceLane).any(func(lane): return lane.has_snapped()), 2.0)
	await _wait(0.05)
	await _attack_shot("splice_snapped")
	await _wait(0.6)
	# Phase two: the film catches fire, and a splice over the burn.
	boss.hp = boss.max_hp() * 0.45
	await _until(func(): return b.burn() != null, 1.0)
	if b.burn() != null:
		b.burn()._radius = b.burn().cap() * 0.6
	_stand(_cell(10, 6))
	await _wait(0.5)
	await _attack_shot("phase_two_burn_ring")
	_stand(center + Vector2(-60, 90))
	await _wait(0.2)
	b._begin(boss, ProjectionistBehavior.Attack.SPLICE, true)
	await _until(func(): return _of(SpliceLane).any(func(lane): return lane.fill() > 0.6), 2.0)
	await _attack_shot("phase_two_splice_over_burn")
	await _wait(0.8)
	_hold = Callable()
	await _clear()
