extends SceneTree
# Opens a real window and saves screenshots of the Seance Hotline (seance_*.png): small, medium and large
# rooms under the floor's light with their enemies; every regular's attack (the Phone Psychic's ring and
# arc, the Crystal Gazer's homing ball and its burst, the Poltergeist's warned lanes and each thing it
# throws, the Ectoplasm's trail, the returning pair); Sister Celestine dealing face down, each turned
# card's symbol and each card's attack warned and landing; Madame Zara's On the Line, the Ouija board's
# path and the planchette sliding, Possession, her summons and safe-spot marks, and the seance circle
# of her second phase with a spirit's swoop; the HUD over the carpet in a large room; and the Tarot
# Headscarf on Harold. Every attack shot is timed by the attack's own state, the bosses held between
# the attacks the probe starts.
# Run only from an exported copy whose config/name is renamed.
# Args after --: rooms | regulars | celestine | zara | hud | scarf | all

const OUT := "D:/grandpa-shots-pr/"
const WALL_LIMIT_MS := 600000
const DIR := "res://data/rooms/seance_hotline/%s.tres"
const PILLS := 8

var _start := 0
var scene
var view: RoomView
var player: Player
var progress
# Called every frame while set, to hold a boss between the attacks the probe starts (lesson 159).
var _hold := Callable()
# Called every frame with the frame's delta while set, to walk Harold for a possession's trail.
var _walker := Callable()
var _aim := Vector2.RIGHT


func _initialize() -> void:
	_start = Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(OUT)
	_main.call_deferred()


func _process(delta: float) -> bool:
	if Time.get_ticks_msec() - _start > WALL_LIMIT_MS:
		print("PROBE TIMEOUT")
		quit(3)
	if player != null and is_instance_valid(player):
		# Kept alive by the run's own fields, never through the heal rules (lesson 61).
		var health: Health = player.run.health
		if health.pills != PILLS or health.max_pills != PILLS:
			health.max_pills = PILLS
			health.pills = PILLS
			# So the HUD shows his pills as they are.
			health.changed.emit()
	if _hold.is_valid():
		_hold.call()
	if _walker.is_valid():
		_walker.call(delta)
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


func _shot(shot_name: String) -> Image:
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	var big := image.duplicate()
	big.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	big.save_png(OUT + "seance_" + shot_name + ".png")
	print("shot " + shot_name)
	return image


# Harold alone, enlarged 8 times, cut from the window.
func _crop_harold(shot_name: String) -> void:
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	var size := Vector2i(48, 56)
	var middle := Vector2i(player.get_global_transform_with_canvas().origin)
	var corner := (middle - size / 2).clamp(Vector2i.ZERO, image.get_size() - size)
	var crop := image.get_region(Rect2i(corner, size))
	crop.resize(size.x * 8, size.y * 8, Image.INTERPOLATE_NEAREST)
	crop.save_png(OUT + "seance_" + shot_name + ".png")
	print("crop " + shot_name)


func _stand(at: Vector2) -> void:
	player.global_position = at - Player.FEET_OFFSET
	player.velocity = Vector2.ZERO


func _feet() -> Vector2:
	return player.feet().global_position


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
	await _new_run()
	for part in ["rooms", "regulars", "celestine", "zara", "hud", "scarf"]:
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
	player.aim_source = func() -> Vector2: return player.global_position + _aim * 60.0
	scene._depth = 4
	var paths: Array = scene._path_defs()
	for index in paths.size():
		if paths[index].id == "seance_hotline":
			scene.debug_choose_path(index)
	await _wait(0.2)
	view = scene.debug_room_view()
	print("floor %s (%s)" % [scene.debug_floor_def().display_name, scene.debug_floor_def().id])
	await _clear()


# Dismisses every enemy and gathers what they and the room dropped, so no coin flies through a later shot.
func _clear() -> void:
	for enemy in get_nodes_in_group("enemies"):
		enemy.dismiss()
	await _wait(0.1)
	for coin in _of(Pickup):
		coin.collect()
	await _wait(0.05)


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


func _of(type) -> Array:
	var found := []
	if view == null:
		return found
	for child in view.get_children():
		if is_instance_of(child, type) and not child.is_queued_for_deletion():
			found.append(child)
	return found


func _spawn(id: String, at: Vector2) -> Enemy:
	return view._spawn_enemy(load("res://data/enemies/%s.tres" % id), at, true)


func _warned(enemy: Enemy, share: float) -> bool:
	return is_instance_valid(enemy) and enemy._warning != null and enemy._warning.warning_progress(enemy._warning_share()) > share


func _boss_in_room(id: String) -> Enemy:
	await _until(func(): return not get_nodes_in_group("enemies").is_empty(), 2.0)
	for enemy in get_nodes_in_group("enemies"):
		if enemy.def.id == id:
			return enemy
	print("no " + id)
	return null


func _boss_bar() -> String:
	var hud = scene._hud
	return hud._boss_name.text if hud.is_boss_bar_visible() else "(no boss bar)"


# --- rooms with their enemies ---

func _show_room(file: String, shot_name: String, stand_side := RoomLayout.SOUTH, type := RoomLayout.TYPE_COMBAT) -> void:
	var source := await _enter(file, type)
	_stand(RoomBackdrop.cell_center(source.door_cell(stand_side)) + Vector2(0, -8 if stand_side == RoomLayout.SOUTH else 8))
	await _wait(0.75)
	_freeze_all()
	await _shot(shot_name)
	await _clear()


func _rooms() -> void:
	await _show_room("combat_small_01", "room_small")
	await _show_room("combat_small_02", "room_small_partitions")
	await _show_room("combat_01", "room_medium_north_banks")
	await _show_room("combat_03", "room_medium_stepped")
	await _show_room("combat_large_01", "room_large_south")
	await _show_room("combat_large_03", "room_large_north", RoomLayout.NORTH)
	await _show_room("combat_large_02", "room_large_curtain_lamps")
	await _show_room("healing_01", "room_healing", RoomLayout.SOUTH, RoomLayout.TYPE_HEALING)


# --- the regulars ---

func _quiet(file: String) -> void:
	await _enter(file, RoomLayout.TYPE_COMBAT)
	await _clear()


func _regulars() -> void:
	await _quiet("combat_large_03")
	# The Phone Psychic: its ring on his feet and the cord's arc, mid windup, then the lash.
	_stand(_cell(10, 7))
	var psychic := _spawn("phone_psychic", _cell(15, 7))
	psychic._behavior._cooldown = 0.3
	await _until(func(): return _of(PhoneCordLash).any(func(l): return not l.has_lashed() and l.fill() > 0.5), 5.0)
	await _shot("psychic_ring_and_arc")
	await _until(func(): return _of(PhoneCordLash).any(func(l): return l.has_lashed()), 2.0)
	await _shot("psychic_lash")
	await _clear()
	# The Crystal Gazer: her windup, the ball homing on his feet, then the warned burst where it stops.
	_stand(_cell(14, 7))
	var gazer := _spawn("crystal_gazer", _cell(7, 7))
	gazer._behavior._cooldown = 0.2
	await _until(func(): return _warned(gazer, 0.5), 4.0)
	await _shot("gazer_windup")
	await _until(func(): return not _of(CrystalBall).is_empty(), 2.0)
	if is_instance_valid(gazer):
		gazer.set_physics_process(false)
	var balls := _of(CrystalBall)
	if not balls.is_empty():
		# Stood where the ball runs out of time before it reaches him.
		var ball = balls[0]
		_stand(Vector2(ball.global_position.x + 270.0, _cell(0, 7).y))
		await _until(func(): return is_instance_valid(ball) and ball.home_left() < 1.6, 3.0)
		await _shot("gazer_ball_homing")
		await _until(func(): return is_instance_valid(ball) and ball.state() == CrystalBall.State.WARNING and ball.fill() > 0.5, 4.0)
		await _shot("gazer_burst_warning")
		await _until(func(): return not is_instance_valid(ball) or ball.state() != CrystalBall.State.WARNING, 2.0)
		# The shards fly out over BURST_SHOW: shot midway.
		await _wait(CrystalBall.BURST_SHOW * 0.4)
		await _shot("gazer_burst")
	await _clear()
	# The Poltergeist on Hold: each throw's warned lane, then the stapler, the mug and the fax in flight.
	_stand(_cell(9, 7))
	var ghost := _spawn("poltergeist", _cell(16, 7))
	var pb = ghost._behavior
	pb._cooldown = 0.2
	for thrown in ["stapler", "mug", "fax"]:
		await _until(func(): return _warned(ghost, 0.5), 5.0)
		await _shot("poltergeist_lane_%s" % thrown)
		await _until(func(): return _of(Projectile).any(func(s): return s.look == thrown), 2.0)
		await _wait(0.2)
		await _shot("poltergeist_%s" % thrown)
		if is_instance_valid(ghost):
			pb._cooldown = 0.6
			ghost.global_position = _cell(16, 7)
	await _clear()
	# The Ectoplasm and its trail, then Harold slowed on it.
	_stand(_cell(8, 7))
	_spawn("ectoplasm", _cell(18, 7))
	await _until(func(): return _of(EctoplasmTrail).any(func(t): return t.piece_count() >= 8), 6.0)
	await _shot("ectoplasm_trail")
	await _clear()
	# The returning pair: the Bingo Caller's marks and the Soot Ghost rising beside him.
	_stand(_cell(10, 7))
	var caller := _spawn("seance_bingo_caller", _cell(16, 6))
	caller._behavior._wait = 0.3
	await _until(func(): return _of(GroundStrike).any(func(m): return m.fill() > 0.5), 5.0)
	await _shot("bingo_caller_marks")
	await _clear()
	_stand(_cell(10, 7))
	var soot := _spawn("seance_soot_ghost", _cell(15, 7))
	await _until(func(): return is_instance_valid(soot) and soot._behavior._state == SootGhostBehavior.State.RISING and _warned(soot, 0.5), 6.0)
	await _shot("soot_ghost_rising")
	await _until(func(): return is_instance_valid(soot) and soot._behavior._state == SootGhostBehavior.State.OPEN, 2.0)
	await _wait(0.1)
	await _shot("soot_ghost_open")
	await _clear()


# --- Sister Celestine ---

func _celestine() -> void:
	var seen := {}
	await _hand("mini_boss_01", [CelestineBehavior.Card.TOWER, CelestineBehavior.Card.DEATH, CelestineBehavior.Card.WHEEL], seen, Vector2(-40, 110))
	await _hand("mini_boss_large_01", [CelestineBehavior.Card.STAR, CelestineBehavior.Card.TOWER, CelestineBehavior.Card.STAR], seen, Vector2(-120, 60))


func _hand(file: String, hand: Array, seen: Dictionary, stand_at: Vector2) -> void:
	await _enter(file, RoomLayout.TYPE_MINI_BOSS)
	var boss := await _boss_in_room("celestine")
	if boss == null:
		return
	var b = boss._behavior
	var center: Vector2 = boss.global_position
	_hold = func():
		if is_instance_valid(boss) and b.step() == CelestineBehavior.Step.REST:
			b._cooldown = 99.0
	_stand(center + stand_at)
	_aim = (center - _feet()).normalized()
	await _wait(0.8)
	print("boss bar: " + _boss_bar())
	b.forced_hand = hand
	b._cooldown = 0.0
	_hold = Callable()
	await _until(func(): return is_instance_valid(boss) and b.step() == CelestineBehavior.Step.DEAL, 2.0)
	_hold = func():
		if is_instance_valid(boss) and b.step() == CelestineBehavior.Step.REST:
			b._cooldown = 99.0
	await _until(func(): return b.cards().size() == 3 and b.cards().all(func(c): return is_instance_valid(c) and c.is_dealt()), 2.0)
	await _shot("celestine_dealt_%s" % file)
	for index in hand.size():
		var card: int = hand[index]
		var label: String = ["tower", "death", "wheel", "star"][card]
		await _until(func(): return is_instance_valid(boss) and b._index == index and b.step() == CelestineBehavior.Step.TURN and b.cards()[index].shows_symbol(), 4.0)
		await _wait(0.15)
		if seen.has(label):
			await _until(func(): return not is_instance_valid(boss) or (b._index == index and b.step() == CelestineBehavior.Step.GAP), 6.0)
			continue
		seen[label] = true
		await _shot("celestine_card_%s" % label)
		await _until(func(): return is_instance_valid(boss) and b.step() == CelestineBehavior.Step.ACT and b.effect() != null and _effect_fill(b.effect()) > 0.5, 3.0)
		await _shot("celestine_%s_warning" % label)
		await _until(func(): return not is_instance_valid(boss) or b.effect() == null or _effect_landed(b.effect()), 4.0)
		await _wait(0.04 if card == CelestineBehavior.Card.DEATH else 0.1)
		await _shot("celestine_%s_landing" % label)
		await _until(func(): return not is_instance_valid(boss) or b.step() != CelestineBehavior.Step.ACT, 4.0)
	await _until(func(): return not is_instance_valid(boss) or b.step() == CelestineBehavior.Step.REST, 4.0)
	_hold = Callable()
	await _clear()


func _effect_fill(effect) -> float:
	if effect is StarFall:
		return effect.fill(0)
	return effect.fill()


func _effect_landed(effect) -> bool:
	if effect is TowerTiles:
		return effect.has_fallen()
	if effect is ScytheSweep:
		return effect.is_sweeping()
	if effect is WheelRing:
		return effect.is_spinning() and effect._spun > 0.6
	if effect is StarFall:
		return effect.has_landed(0)
	return true


# --- Madame Zara ---

func _zara_hold(boss: Enemy, b) -> void:
	_hold = func():
		if is_instance_valid(boss) and not b._telegraph.is_active():
			b._cooldown = 99.0
			b._summon_timer = maxf(b._summon_timer, 1.0)


func _zara_settle(b) -> void:
	await _until(func(): return b.tether() == null or b.tether().is_over(), 6.0)
	await _until(func(): return b.planchette() == null or b.planchette().is_spent(), 6.0)
	await _until(func(): return b.ghost() == null or b.ghost().is_spent(), 6.0)
	await _wait(0.5)


func _zara() -> void:
	await _enter("floor_boss_large_01", RoomLayout.TYPE_FLOOR_BOSS)
	var boss := await _boss_in_room("madame_zara")
	if boss == null:
		return
	var b = boss._behavior
	var center: Vector2 = boss.global_position
	_zara_hold(boss, b)
	_stand(center + Vector2(-130, 40))
	await _wait(1.0)
	print("boss bar: " + _boss_bar())
	await _shot("zara_boss_bar_and_board")
	# On the Line: the circle and the cord warned, then the line held with her other attack alongside.
	b._begin(boss, MadameZaraBehavior.Attack.LINE, false)
	print("line started: %s" % str(b.tether() != null))
	await _until(func(): return b.tether() != null and b.tether().is_warning() and b.tether().fill() > 0.5, 2.0)
	await _shot("zara_line_warning")
	await _until(func(): return b.tether() == null or b.tether().is_held() or b.tether().is_over(), 2.0)
	await _wait(0.35)
	print("line held: %s, alongside: planchette %s, ghost %s, marks %d" % [str(b.tether() != null and b.tether().is_held()), str(b.planchette() != null), str(b.ghost() != null), _of(SafeSpotMark).size()])
	await _shot("zara_line_held")
	await _zara_settle(b)
	# The Ouija board, her heaviest attack: the path warned (outlined twice), then the planchette sliding.
	boss.global_position = center
	_stand(center + Vector2(-90, 70))
	await _wait(0.3)
	b._begin(boss, MadameZaraBehavior.Attack.OUIJA, false)
	var plan = b.planchette()
	print("ouija word: %s" % (plan.word() if plan != null else "(none)"))
	await _until(func(): return plan != null and is_instance_valid(plan) and plan.is_warning() and plan.fill() > 0.5, 2.0)
	print("safe-spot marks: %d" % _of(SafeSpotMark).size())
	await _shot("zara_ouija_path_warning")
	# He steps onto her safe-spot mark, as a player would.
	for mark in _of(SafeSpotMark):
		_stand(mark.global_position)
	await _until(func(): return plan == null or not is_instance_valid(plan) or (plan.is_sliding() and plan._time > 0.6), 4.0)
	await _shot("zara_ouija_planchette_sliding")
	await _zara_settle(b)
	# Possession: Harold walks to and fro, then the copy's trail warned and the copy walking it.
	boss.global_position = center
	var from := center + Vector2(-170, 60)
	var to := center + Vector2(-60, 110)
	_stand(from)
	var walk := {"t": 0.0}
	_walker = func(delta: float):
		walk["t"] += delta
		var share := pingpong(walk["t"] * 0.6, 1.0)
		_stand(from.lerp(to, share))
	await _wait(2.6)
	b._begin(boss, MadameZaraBehavior.Attack.POSSESSION, false)
	_walker = Callable()
	var copy = b.ghost()
	print("possession cast: %s" % str(copy != null))
	await _until(func(): return copy != null and is_instance_valid(copy) and copy.is_warning() and copy.fill() > 0.5, 2.0)
	await _shot("zara_possession_warning")
	for mark in _of(SafeSpotMark):
		_stand(mark.global_position)
	await _until(func(): return copy == null or not is_instance_valid(copy) or (copy.is_walking() and copy.walked() > 1.0), 4.0)
	await _shot("zara_possession_copy")
	await _zara_settle(b)
	# Her Ectoplasm: the summon marks, then the pair oozing with their trails.
	_stand(center + Vector2(-130, 40))
	await _wait(0.2)
	b._summon_timer = 0.0
	_hold = func():
		if is_instance_valid(boss) and not b._telegraph.is_active():
			b._cooldown = 99.0
	await _until(func(): return not _of(SummonMark).is_empty(), 2.0)
	await _wait(0.3)
	await _shot("zara_ectoplasm_marks")
	await _until(func(): return _of(SummonMark).is_empty(), 3.0)
	await _until(func(): return _of(EctoplasmTrail).any(func(t): return t.piece_count() >= 5), 4.0)
	await _shot("zara_ectoplasm_oozing")
	for enemy in get_nodes_in_group("enemies"):
		if enemy != boss:
			enemy.dismiss()
	_zara_hold(boss, b)
	await _wait(0.3)
	for coin in _of(Pickup):
		coin.collect()
	# Phase two: the seance circle with Harold in the light, then out of it under a spirit's swoop.
	b.forced_phase_two = true
	await _until(func(): return b.circle() != null and b.circle().current_shade() > SeanceCircle.DIM * 0.9, 3.0)
	var circle = b.circle()
	if circle == null:
		print("no seance circle")
	else:
		_stand(circle.center() + Vector2(-30, 20))
		await _wait(0.3)
		await _shot("zara_seance_circle_in_light")
		# A phase-two board planned inside the light.
		b._begin(boss, MadameZaraBehavior.Attack.OUIJA, true)
		var lit_plan = b.planchette()
		await _until(func(): return lit_plan != null and is_instance_valid(lit_plan) and lit_plan.fill() > 0.5, 2.0)
		await _shot("zara_seance_circle_ouija")
		await _zara_settle(b)
		# Out in the dark: the spirits swoop.
		var away: Vector2 = circle.center() + (circle.center() - boss.global_position).normalized() * (SeanceCircle.LIGHT_RADIUS + 50.0)
		var room := ForemanBehavior.room_rect(boss.room_cells).grow(-40.0)
		away = away.clamp(room.position, room.end)
		if SeanceCircle.in_light(circle.center(), away):
			away = circle.center() + Vector2(SeanceCircle.LIGHT_RADIUS + 50.0, 0.0)
			away = away.clamp(room.position, room.end)
		_stand(away)
		_walker = func(_delta: float):
			if is_instance_valid(circle) and SeanceCircle.in_light(circle.center(), _feet()):
				_stand(away)
		await _until(func(): return _of(SpiritSwoop).any(func(s): return s.fill() > 0.5 and not s.has_landed()), 4.0)
		await _shot("zara_spirit_swoop_warning")
		await _until(func(): return _of(SpiritSwoop).any(func(s): return s.has_landed()), 2.0)
		await _shot("zara_spirit_swoop_landed")
		_walker = Callable()
		# A line called in the dim room.
		_stand(circle.center() + Vector2(20, 10))
		await _wait(0.4)
		b._begin(boss, MadameZaraBehavior.Attack.LINE, true)
		await _until(func(): return b.tether() != null and b.tether().is_held(), 2.0)
		await _wait(0.3)
		await _shot("zara_seance_circle_line_held")
		await _zara_settle(b)
	_hold = Callable()
	await _clear()


# --- the HUD over the carpet in a large room ---

func _hud() -> void:
	var source := await _enter("combat_large_03", RoomLayout.TYPE_COMBAT)
	_stand(_cell(14, 6))
	await _wait(0.8)
	_freeze_all()
	await _shot("hud_large_middle")
	_stand(_cell(4, 2))
	await _wait(0.6)
	await _shot("hud_large_north_west")
	_stand(_cell(25, 2))
	await _wait(0.6)
	await _shot("hud_large_north_east")
	await _clear()
	if source == null:
		print("no layout")


# --- the Tarot Headscarf ---

func _scarf() -> void:
	await _quiet("combat_large_03")
	_stand(_cell(14, 7))
	var scarf := CosmeticDef.find("golf_visor", CosmeticDef.all())
	print("cosmetic: %s" % (scarf.display_name if scarf != null else "(none)"))
	if scarf == null:
		return
	player.run.look = {scarf.slot: scarf}
	player.refresh_look()
	for dir in [1, -1]:
		_aim = Vector2.RIGHT * dir
		await _wait(0.4)
		await _crop_harold("scarf_%s" % ("east" if dir > 0 else "west"))
	await _shot("scarf_in_room")
	player.run.look = {}
	player.refresh_look()
