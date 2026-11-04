extends SceneTree
# A simple simulated player runs real floors through real scenes with simulated input.
# Args after --: <fresh|some|max> <average|good> <runs> <path> <depth> [bosses]
# Estimates only. It walks teleport-free inside rooms but changes rooms directly.
# Version 4 reads the third floor too: extra warned lanes, processions, the collection plate,
# presents, the closing ring, the crescendo's safe spot and perfume clouds.

const WALL_LIMIT_MS := 1700000
const SKILLS := {
	"average": {"reaction": 0.32, "dodge": 0.45, "aim": 14.0, "press": 0.22, "shot_sense": 55.0, "forget": 0.12},
	"good": {"reaction": 0.2, "dodge": 0.85, "aim": 6.0, "press": 0.2, "shot_sense": 80.0, "forget": 0.03},
}
const SAVES := {
	"fresh": {},
	"some": {"black_market_pills": 1, "better_knees": 1, "reinforced_cane": 1},
	"max": {"black_market_pills": 3, "better_knees": 3, "reinforced_cane": 3, "prescription_glasses": 1},
}
const ROOM_STUCK := 45.0

var _start := 0
var _skill: Dictionary
var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	_start = Time.get_ticks_msec()
	_main.call_deferred()


func _process(_d: float) -> bool:
	if Time.get_ticks_msec() - _start > WALL_LIMIT_MS:
		print("PROBE WALL LIMIT, printing partial")
		_print_summary()
		quit(3)
	return false


var _results: Array = []
var _config := ""
var _path := 0


func _main() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var save_name: String = args[0] if args.size() > 0 else "fresh"
	var skill_name: String = args[1] if args.size() > 1 else "average"
	var runs: int = int(args[2]) if args.size() > 2 else 5
	_path = int(args[3]) if args.size() > 3 else 0
	_config = "%s/%s" % [save_name, skill_name]
	_skill = SKILLS[skill_name]
	_rng.seed = 12345
	var progress = root.get_node("Progress")
	progress._store = SaveStore.new("user://probe_%s_%s.json" % [save_name, skill_name])
	progress._store.delete_all()
	progress.reload()
	progress.data.floors_cleared = 1
	progress.data.record_floor_cleared(2, "sunset_shores")
	progress.data.record_floor_cleared(3, "funeral_parlour")
	for key in SAVES[save_name]:
		progress.data.upgrades[key] = SAVES[save_name][key]
	var bosses_only := args.size() > 5 and args[5] == "bosses"
	for i in runs:
		var result: Dictionary = {}
		if bosses_only:
			result = await _run_bosses(progress)
		else:
			result = await _run(progress)
		_results.append(result)
		print("run %d: %s" % [i, str(result)])
	_print_summary()
	progress._store.delete_all()
	quit(0)


func _print_summary() -> void:
	print("hits by source: %s" % str(_sources))
	var n := _results.size()
	if n == 0:
		return
	var sums := {"reached_mini": 0, "beat_mini": 0, "reached_boss": 0, "beat_boss": 0, "income": 0.0, "time": 0.0, "rooms": 0.0, "stuck": 0, "hits": 0.0, "end_pills": 0.0}
	var boss_times: Array = []
	var mini_times: Array = []
	var boss_hits: Array = []
	var mini_hits: Array = []
	for r in _results:
		for key in ["reached_mini", "beat_mini", "reached_boss", "beat_boss"]:
			sums[key] += 1 if r[key] else 0
		sums["income"] += r["income"]
		sums["time"] += r["time"]
		sums["rooms"] += r["rooms"]
		sums["stuck"] += r["stuck"]
		sums["hits"] += r["hits"]
		if r["boss_ttk"] > 0.0:
			boss_times.append(r["boss_ttk"])
			boss_hits.append(r["boss_hits"])
		if r["mini_ttk"] > 0.0:
			mini_times.append(r["mini_ttk"])
			mini_hits.append(r["mini_hits"])
	print("SUMMARY %s runs=%d reached_mini=%d beat_mini=%d reached_boss=%d beat_boss=%d income=%.0f run_minutes=%.1f rooms=%.1f hits=%.1f stuck_rooms=%d mini_ttk=%s mini_hits=%s boss_ttk=%s boss_hits=%s" % [_config, n, sums["reached_mini"], sums["beat_mini"], sums["reached_boss"], sums["beat_boss"], sums["income"] / n, sums["time"] / n / 60.0, sums["rooms"] / float(n), sums["hits"] / n, sums["stuck"], _mean(mini_times), _mean(mini_hits), _mean(boss_times), _mean(boss_hits)])


func _mean(list: Array) -> String:
	if list.is_empty():
		return "-"
	var s := 0.0
	for v in list:
		s += v
	return "%.1f" % (s / list.size())


func _run(progress) -> Dictionary:
	change_scene_to_file("res://scenes/floor.tscn")
	await create_timer(0.1).timeout
	var scene = current_scene
	if OS.get_cmdline_user_args().size() > 4:
		scene._depth = int(OS.get_cmdline_user_args()[4])
	scene.debug_choose_path(_path)
	await create_timer(0.05).timeout
	var bot := Bot.new()
	bot.setup(scene, _skill, _rng)
	scene.add_child(bot)
	# A typical haul from two floors: four items, two Slips and a Thermos.
	if OS.get_cmdline_user_args().size() > 5 and OS.get_cmdline_user_args()[5] == "haul":
		var run: RunState = scene.player.run
		var pool: Array = []
		for item in Content.items():
			if run.can_offer(item):
				pool.append(item)
		for i in 4:
			if pool.is_empty():
				break
			run.add_item(pool.pop_at(_rng.randi_range(0, pool.size() - 1)))
		run.add_key()
		run.add_key()
		run.add_bomb()
		run.health.heal(99)
	var pension_before: int = progress.data.pension
	var map: FloorMap = scene.debug_map()
	var r := {"reached_mini": false, "beat_mini": false, "reached_boss": false, "beat_boss": false, "income": 0, "time": 0.0, "rooms": 0, "stuck": 0, "hits": 0, "boss_ttk": 0.0, "mini_ttk": 0.0, "boss_hits": 0, "mini_hits": 0, "death_in": ""}
	scene.player.hurt.connect(func(): r["hits"] += 1; _attribute(scene))
	while true:
		var at: int = scene.debug_current_id()
		var kind: String = map.room(at).room_type
		r["rooms"] += 1
		if kind == RoomLayout.TYPE_MINI_BOSS:
			r["reached_mini"] = true
		if kind == RoomLayout.TYPE_FLOOR_BOSS:
			r["reached_boss"] = true
		var hits_before: int = r["hits"]
		var began: float = bot.clock
		var had_enemies: bool = bot.enemies_here() > 0
		var cleared: bool = await bot.fight_room()
		var took: float = bot.clock - began
		if not cleared and bot.gave_up:
			r["stuck"] += 1
		if scene.is_over and not scene.is_cleared:
			r["death_in"] = kind
			break
		if kind == RoomLayout.TYPE_MINI_BOSS and had_enemies:
			r["beat_mini"] = true
			r["mini_ttk"] = took
			r["mini_hits"] = r["hits"] - hits_before
		if kind == RoomLayout.TYPE_FLOOR_BOSS:
			r["beat_boss"] = true
			r["boss_ttk"] = took
			r["boss_hits"] = r["hits"] - hits_before
			break
		bot.loot(kind)
		await create_timer(0.1).timeout
		if scene.is_over:
			break
		var next := _next_room(scene, map)
		if next == -1:
			break
		scene._enter_room(next)
		await create_timer(0.1).timeout
	r["income"] = progress.data.pension - pension_before
	r["time"] = bot.clock
	bot.release_all()
	return r


var _sources := {}


func _attribute(scene) -> void:
	var me: Vector2 = scene.player.global_position
	var best := "?"
	var best_d := 1e9
	for child in scene.debug_room_view().get_children():
		var name := ""
		var d := me.distance_to(child.global_position) if child is Node2D else 1e9
		if child is Projectile and d < 16.0:
			name = "shot"
			d = 0.0
		elif child is FloorVent and child.is_flaring() and FloorVent.covers(child.global_position, scene.player.feet().global_position):
			name = "vent"
			d = 0.0
		elif child is GroundStrike and child.is_burning() and child.global_position.distance_to(scene.player.feet().global_position) <= child.radius():
			name = "fire"
			d = 0.0
		elif child is SteamJet and child.is_blowing() and child.hits(scene.player.feet().global_position):
			name = "steam"
			d = 0.0
		elif child is Shockwave and child.is_growing():
			name = "ring"
			d = 0.0
		elif child is EnemyBlast and d < 70.0:
			name = "blast"
			d = 0.0
		elif child is PipeRing and child.damage() > 0 and absf(child.global_position.distance_to(scene.player.feet().global_position) - child.radius_now()) < 24.0:
			name = "crescendo"
			d = 0.0
		elif child is ClosingRing:
			name = "closing_ring"
			d = 0.0
		elif child is ProcessionLane and child.is_marching():
			name = "procession"
			d = 0.0
		elif child is CollectionPlate and child.is_flying():
			name = "plate"
			d = 0.0
		elif child is PresentDrop and d < 30.0:
			name = "present"
			d = 0.0
		elif child is Enemy:
			name = child.def.id
		if name != "" and d < best_d:
			best_d = d
			best = name
	_sources[best] = _sources.get(best, 0) + 1


# Straight into the mini boss and then the floor boss, each with full pills, so a boss fight is
# measured on its own and not by how often the bot survives the rooms before it.
func _run_bosses(progress) -> Dictionary:
	change_scene_to_file("res://scenes/floor.tscn")
	await create_timer(0.1).timeout
	var scene = current_scene
	scene._depth = int(OS.get_cmdline_user_args()[4])
	scene.debug_choose_path(_path)
	await create_timer(0.05).timeout
	var bot := Bot.new()
	bot.setup(scene, _skill, _rng)
	scene.add_child(bot)
	var map: FloorMap = scene.debug_map()
	var r := {"reached_mini": true, "beat_mini": false, "reached_boss": true, "beat_boss": false, "income": 0, "time": 0.0, "rooms": 2, "stuck": 0, "hits": 0, "boss_ttk": 0.0, "mini_ttk": 0.0, "boss_hits": 0, "mini_hits": 0, "death_in": ""}
	scene.player.hurt.connect(func(): r["hits"] += 1; _attribute(scene))
	for kind in [RoomLayout.TYPE_MINI_BOSS, RoomLayout.TYPE_FLOOR_BOSS]:
		var target := -1
		for room in map.rooms:
			if room.room_type == kind:
				target = room.id
		var health: Health = scene.player.run.health
		health.heal(99)
		scene._enter_room(target)
		await create_timer(0.1).timeout
		var hits_before: int = r["hits"]
		var began: float = bot.clock
		await bot.fight_room()
		var key := "mini" if kind == RoomLayout.TYPE_MINI_BOSS else "boss"
		var won: bool = not scene.is_over or scene.is_cleared
		if health.is_dead():
			won = false
		r["beat_" + key] = won
		r[key + "_ttk"] = bot.clock - began if won else 0.0
		r[key + "_hits"] = r["hits"] - hits_before
		r[key + "_lost_hits"] = r["hits"] - hits_before
		if not won:
			r["death_in"] = kind
			break
	r["time"] = bot.clock
	bot.release_all()
	return r


func _next_room(scene, map: FloorMap) -> int:
	var at: int = scene.debug_current_id()
	var best: int = map.boss_id
	var best_steps := 1000
	var avoid: Array[int] = []
	for room in map.rooms:
		if room.room_type == RoomLayout.TYPE_SECRET:
			avoid.append(room.id)
		if room.room_type == RoomLayout.TYPE_TREASURE and scene.player.run.keys <= 0:
			avoid.append(room.id)
	for room in map.rooms:
		if room.id == map.boss_id or avoid.has(room.id) or scene.debug_progress().is_visited(room.id):
			continue
		var steps := _steps(map, at, room.id)
		if steps < best_steps:
			best = room.id
			best_steps = steps
	return map.next_step(at, best)


func _steps(map: FloorMap, from_id: int, to_id: int) -> int:
	var steps := 0
	var cursor := from_id
	while cursor != to_id and steps < map.rooms.size():
		cursor = map.next_step(cursor, to_id)
		steps += 1
	return steps


class Bot extends Node:
	var scene
	var skill: Dictionary
	var rng: RandomNumberGenerator
	var clock := 0.0
	var gave_up := false
	var _player: Player
	var _aim_at := Vector2.ZERO
	var _seen := {}
	var _press_wait := 0.0
	var _pressed := false
	var _dodge_pressed := false
	var _path_wait := 0.0
	var _path: Array[Vector2i] = []
	var _dodged_for := {}
	var _dodge_wish := false
	var _move := Vector2.ZERO
	var _last_hp_total := 0.0
	var _since_progress := 0.0
	var _fighting := false

	func setup(s, sk: Dictionary, r: RandomNumberGenerator) -> void:
		scene = s
		skill = sk
		rng = r
		_player = s.player
		process_physics_priority = -10

	func _ready() -> void:
		_player.aim_source = _aim

	func _aim() -> Vector2:
		return _aim_at

	func enemies_here() -> int:
		return get_tree().get_nodes_in_group("enemies").size()

	func fight_room() -> bool:
		_fighting = true
		gave_up = false
		_since_progress = 0.0
		_last_hp_total = -1.0
		while enemies_here() > 0 and not scene.is_over:
			await get_tree().physics_frame
			if _since_progress > ROOM_STUCK:
				gave_up = true
				for stuck_enemy in get_tree().get_nodes_in_group("enemies"):
					print("STUCK with %s hp %.0f at %s under %s, Grandpa at %s, room %s" % [stuck_enemy.def.id, stuck_enemy.hp, str(stuck_enemy.global_position), str(stuck_enemy.submerged), str(_player.global_position), scene.debug_map().room(scene.debug_current_id()).layout.resource_path])
				for enemy in get_tree().get_nodes_in_group("enemies"):
					enemy.dismiss()
				break
		_fighting = false
		release_all()
		return not gave_up and not scene.is_over

	func release_all() -> void:
		for action in ["move_left", "move_right", "move_up", "move_down", "attack", "dodge"]:
			Input.action_release(action)
		_pressed = false
		_dodge_pressed = false

	func loot(kind: String) -> void:
		var run: RunState = _player.run
		var view: RoomView = scene.debug_room_view()
		var took_item := false
		for child in view.get_children():
			if not child is Pickup or child.is_queued_for_deletion() or child.flies:
				continue
			if child is Chest:
				# A player opens lunchboxes and, with a Slip, locked chests; urns, safes and mimics wait.
				if child.kind == ChestRules.LUNCHBOX or (child.kind == ChestRules.LOCKED and run.keys > 0):
					child.collect()
			elif child.requires_interact:
				if child.prompt == Pickup.PROMPT_TEXT and not took_item:
					if not child.can_take.is_valid() or child.can_take.call():
						took_item = true
						child.collect()
			elif not child.can_take.is_valid() or child.can_take.call():
				child.collect()

	func _physics_process(delta: float) -> void:
		Engine.time_scale = 1.0
		clock += delta
		if not _fighting or scene.is_over or not is_instance_valid(_player):
			return
		_track_progress(delta)
		_move = Vector2.ZERO
		var threat := _read_threats(delta)
		var target := _pick_target()
		if target != null:
			_aim_at = _aimed(target)
		if threat != Vector2.ZERO:
			_move = threat
		elif target != null:
			_move = _around_fire(_player.feet().global_position, _approach(target, delta))
		var safe := safe_spot()
		if safe != Vector2.INF:
			_move = _walk_to(safe)
		_press_move(_move)
		_handle_dodge()
		_handle_attack(target, delta)

	func _track_progress(delta: float) -> void:
		var total := 0.0
		for enemy in get_tree().get_nodes_in_group("enemies"):
			total += enemy.hp
		if _last_hp_total < 0.0 or total < _last_hp_total - 0.01:
			_since_progress = 0.0
		else:
			_since_progress += delta
		_last_hp_total = total

	func _pick_target() -> Enemy:
		var best: Enemy = null
		var best_score := INF
		for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.submerged:
				continue
			var score := _player.global_position.distance_to(enemy.global_position)
			if enemy.def.max_hp < 20.0:
				score -= 30.0
			if enemy.def.is_boss:
				score += 60.0
			if score < best_score:
				best_score = score
				best = enemy
		return best

	func _aimed(target: Enemy) -> Vector2:
		var to := target.global_position - _player.global_position
		return _player.global_position + to

	func _read_threats(_delta: float) -> Vector2:
		var me := _player.global_position
		var escape := Vector2.ZERO
		for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
			var telegraph: Telegraph = enemy._warning
			if telegraph == null or not telegraph.shows_warning(enemy._warning_share() if enemy.has_method("_warning_share") else enemy._warning_fraction):
				_seen.erase(enemy.get_instance_id())
				continue
			var id := enemy.get_instance_id()
			if not _seen.has(id):
				_seen[id] = clock
				_dodged_for.erase(id)
				# Now and then a player simply misses a warning in the crowd.
				if rng.randf() < skill["forget"]:
					_seen[id] = clock + 10.0
			if clock - _seen[id] < skill["reaction"]:
				continue
			var from: Vector2 = enemy.global_position
			if enemy._lane_length > 0.0:
				var along: Vector2 = enemy._lane_direction
				var offset := me - from
				var forward := offset.dot(along)
				var side := offset - along * forward
				if forward > -30.0 and forward < enemy._lane_length + 30.0 and side.length() < enemy._lane_width / 2.0 + 14.0:
					var out := side.normalized() if side.length() > 1.0 else along.orthogonal()
					escape += out
					_want_dodge(id)
			# A fan of coins warns down several lanes at once.
			for lane in enemy._extra_lanes:
				var way: Vector2 = lane[0]
				var off := me - from
				var ahead := off.dot(way)
				var aside := off - way * ahead
				if ahead > -30.0 and ahead < float(lane[1]) + 30.0 and aside.length() < float(lane[2]) / 2.0 + 14.0:
					escape += aside.normalized() if aside.length() > 1.0 else way.orthogonal()
					_want_dodge(id)
			var radius: float = enemy._warning_radius
			if me.distance_to(from) < radius + 10.0:
				escape += from.direction_to(me)
				_want_dodge(id)
		for child in scene.debug_room_view().get_children():
			if child is Projectile:
				var velocity: Vector2 = child._velocity
				var to_me: Vector2 = me - child.global_position
				if to_me.length() < skill["shot_sense"] and velocity.dot(to_me) > 0.0:
					var side: Vector2 = to_me - velocity.normalized() * to_me.dot(velocity.normalized())
					if side.length() < 22.0:
						escape += side.normalized() if side.length() > 1.0 else velocity.orthogonal().normalized()
		# Marks on the ground, read with the same reaction time and the same chance to miss.
		for strike in scene.debug_room_view().get_children():
			if not strike is GroundStrike or strike._landed:
				continue
			var strike_id: int = strike.get_instance_id()
			if not _seen.has(strike_id):
				_seen[strike_id] = clock + (10.0 if rng.randf() < skill["forget"] else 0.0)
				_dodged_for.erase(strike_id)
			if clock - _seen[strike_id] < skill["reaction"] or strike._delay > 0.0 or strike.is_following():
				continue
			var feet: Vector2 = _player.feet().global_position
			if feet.distance_to(strike.global_position) < strike._radius + 10.0:
				var away: Vector2 = strike.global_position.direction_to(feet)
				escape += away if away != Vector2.ZERO else Vector2.RIGHT
				_want_dodge(strike_id)
		escape += _read_furnace(enemy_free_feet(), me)
		escape += _read_floor3(enemy_free_feet())
		return escape.normalized() if escape != Vector2.ZERO else Vector2.ZERO

	func _seen_for(node: Node) -> bool:
		var id: int = node.get_instance_id()
		if not _seen.has(id):
			_seen[id] = clock + (10.0 if rng.randf() < skill["forget"] else 0.0)
			_dodged_for.erase(id)
		return clock - _seen[id] >= skill["reaction"]

	# The crescendo's marked safe spot, once noticed: everything else waits until he stands on it.
	func safe_spot() -> Vector2:
		for child in scene.debug_room_view().get_children():
			if child is SafeSpotMark and not child.is_queued_for_deletion() and _seen_for(child):
				return child.global_position
		return Vector2.INF

	# Processions, plates, presents, the closing ring, hurting organ rings and perfume clouds.
	func _read_floor3(feet: Vector2) -> Vector2:
		var escape := Vector2.ZERO
		var view: RoomView = scene.debug_room_view()
		for child in view.get_children():
			if child is ProcessionLane:
				if not _seen_for(child):
					continue
				var way: Vector2 = child._direction
				var off: Vector2 = feet - child.global_position
				var ahead := off.dot(way)
				var aside := off - way * ahead
				if ahead > -20.0 and ahead < child._length + 20.0 and aside.length() < child._width / 2.0 + 12.0:
					escape += _clear_of_processions(view, feet, way.orthogonal()) * 2.0
					if child.is_marching():
						_want_dodge(child.get_instance_id())
			elif child is CollectionPlate:
				if not _seen_for(child):
					continue
				for point in child._path:
					var at: Vector2 = child.global_position + point
					if feet.distance_to(at) < CollectionPlate.HIT_RANGE + 14.0:
						var away: Vector2 = at.direction_to(feet)
						escape += away if away != Vector2.ZERO else Vector2.RIGHT
						break
			elif child is PresentDrop and not child._landed:
				if _seen_for(child) and feet.distance_to(child.global_position) < PresentDrop.RADIUS + 12.0:
					var away2: Vector2 = child.global_position.direction_to(feet)
					escape += away2 if away2 != Vector2.ZERO else Vector2.RIGHT
					_want_dodge(child.get_instance_id())
			elif child is ClosingRing:
				if not _seen_for(child):
					continue
				var d: float = feet.distance_to(child.global_position)
				var r: float = child.radius_now()
				if d < r + 10.0:
					var out: Vector2 = child.global_position.direction_to(feet)
					escape += out if out != Vector2.ZERO else Vector2.RIGHT
					if child._left <= 0.0 and absf(d - r) < 22.0:
						_want_dodge(child.get_instance_id() + int(r / 20.0))
			elif child is PipeRing and child.damage() > 0:
				var d2: float = feet.distance_to(child.global_position)
				if d2 > child.radius_now() and d2 - child.radius_now() < 20.0 and d2 < child.reach():
					_want_dodge(child.get_instance_id())
			elif child is PerfumeCloud and child.has_landed():
				if feet.distance_to(child.global_position) < PerfumeCloud.RADIUS + 6.0:
					escape += child.global_position.direction_to(feet) * 0.5
		return escape

	func _clear_of_processions(view: Node, feet: Vector2, across: Vector2) -> Vector2:
		for step in range(0, 220, 4):
			for way in [1.0, -1.0]:
				var spot: Vector2 = feet + across * way * step
				var clear := true
				for lane in view.get_children():
					if lane is ProcessionLane:
						var dir: Vector2 = lane._direction
						var off: Vector2 = spot - lane.global_position
						var ahead := off.dot(dir)
						var aside := off - dir * ahead
						if ahead > -20.0 and ahead < lane._length + 20.0 and aside.length() < lane._width / 2.0 + 12.0:
							clear = false
							break
				if clear:
					return across * way if step > 0 else Vector2.ZERO
		return Vector2.ZERO

	# The nearest spot straight across every warned lane, searched both ways, as a player reads lanes.
	func _clear_of_jets(view: Node, feet: Vector2, across: Vector2) -> Vector2:
		for step in range(0, 200, 4):
			for way in [1.0, -1.0]:
				var spot: Vector2 = feet + across * way * step
				var clear := true
				for jet in view.get_children():
					if jet is SteamJet and (jet.is_warning() or jet.is_blowing()) and SteamJet.lane_hits(jet.global_position, jet.direction(), jet.length(), jet.width() + 16.0, spot):
						clear = false
						break
				if clear:
					return across * way if step > 0 else Vector2.ZERO
		return Vector2.ZERO

	# Steps round burning ground rather than through it.
	func _around_fire(feet: Vector2, way: Vector2) -> Vector2:
		for child in scene.debug_room_view().get_children():
			if child is GroundStrike and child.is_burning():
				var ahead: Vector2 = feet + way * 20.0
				if ahead.distance_to(child.global_position) < child.radius() + 8.0:
					var side: Vector2 = way.orthogonal()
					return side if side.dot(feet - child.global_position) >= 0.0 else -side
		return way

	func enemy_free_feet() -> Vector2:
		return _player.feet().global_position

	# The boiler hall's hazards, read like any other warning: vents, fire, steam lanes, cones and rings.
	func _read_furnace(feet: Vector2, me: Vector2) -> Vector2:
		var escape := Vector2.ZERO
		var view: RoomView = scene.debug_room_view()
		for child in view.get_children():
			if child is FloorVent:
				var hot: bool = child.is_flaring() or (child.is_warning() and child.warn_progress() > 0.25)
				if hot and feet.distance_to(child.global_position) < FloorVent.REACH + 12.0:
					var away: Vector2 = child.global_position.direction_to(feet)
					escape += away if away != Vector2.ZERO else Vector2.RIGHT
			elif child is GroundStrike and child.is_burning():
				if feet.distance_to(child.global_position) < child.radius() + 10.0:
					var away2: Vector2 = child.global_position.direction_to(feet)
					escape += away2 if away2 != Vector2.ZERO else Vector2.RIGHT
			elif child is SteamJet and (child.is_warning() or child.is_blowing()):
				var id: int = child.get_instance_id()
				if not _seen.has(id):
					_seen[id] = clock + (10.0 if rng.randf() < skill["forget"] else 0.0)
				if clock - _seen[id] < skill["reaction"]:
					continue
				if SteamJet.lane_hits(child.global_position, child.direction(), child.length(), child.width() + 16.0, feet):
					escape += _clear_of_jets(view, feet, child.direction().orthogonal()) * 2.0
			elif child is Shockwave:
				var d: float = feet.distance_to(child.global_position)
				if d < ForemanBehavior.RING_TO + 16.0:
					escape += child.global_position.direction_to(feet)
					if child.is_growing() and absf(d - child.radius_now()) < 24.0:
						_want_dodge(child.get_instance_id() + int(child.radius_now() / 30.0))
		for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.warning_cone_length() > 0.0 and enemy._warning != null:
				var id3 := enemy.get_instance_id() + 7
				if not _seen.has(id3):
					_seen[id3] = clock
				if clock - _seen[id3] < skill["reaction"]:
					continue
				if ChiefStokerBehavior.in_cone(enemy.global_position, enemy.warning_cone_direction(), enemy.warning_cone_angle() + 20.0, enemy.warning_cone_length() + 20.0, feet):
					var side2: Vector2 = enemy.warning_cone_direction().orthogonal()
					escape += side2 * signf((feet - enemy.global_position).dot(side2) + 0.01) + enemy.global_position.direction_to(feet) * 0.5
					_want_dodge(id3)
		return escape

	func _want_dodge(id: int) -> void:
		if _dodged_for.has(id):
			return
		_dodged_for[id] = true
		if rng.randf() < skill["dodge"]:
			_dodge_wish = true

	func _approach(target: Enemy, delta: float) -> Vector2:
		var me := _player.global_position
		var goal := target.global_position
		if target.def.shield_half_angle > 0.0:
			goal = target.global_position - target.facing * 46.0
		var distance := me.distance_to(target.global_position)
		if target.def.shield_half_angle <= 0.0 and distance < _reach(target) - 8.0:
			return Vector2.ZERO
		_path_wait -= delta
		var layout: RoomLayout = scene.debug_map().room(scene.debug_current_id()).layout
		var feet: Vector2 = _player.feet().global_position
		if _path_wait <= 0.0:
			_path_wait = 0.2
			_path = _find_path(layout, _cell(feet), _cell(goal + Player.FEET_OFFSET))
		while _path.size() > 1 and RoomBackdrop.cell_center(_path[0]).distance_to(feet) < 10.0:
			_path.pop_front()
		if _path.size() >= 2:
			return feet.direction_to(RoomBackdrop.cell_center(_path[1] if RoomBackdrop.cell_center(_path[0]).distance_to(feet) < 18.0 else _path[0]))
		return me.direction_to(goal)

	func _walk_to(goal: Vector2) -> Vector2:
		var feet: Vector2 = _player.feet().global_position
		if feet.distance_to(goal) < 5.0:
			return Vector2.ZERO
		var layout: RoomLayout = scene.debug_map().room(scene.debug_current_id()).layout
		var path := _find_path(layout, _cell(feet), _cell(goal))
		if path.size() >= 3:
			return feet.direction_to(RoomBackdrop.cell_center(path[1]))
		return feet.direction_to(goal)

	func _reach(target: Enemy) -> float:
		return Player.ATTACK_REACH + minf(target.def.body_size.x, target.def.body_size.y) / 2.0

	func _cell(at: Vector2) -> Vector2i:
		return Vector2i(floori(at.x / RoomBackdrop.TILE), floori(at.y / RoomBackdrop.TILE))

	func _solid(layout: RoomLayout, cell: Vector2i) -> bool:
		if not layout.is_solid_at(cell):
			return false
		var symbol := layout.symbol_at(cell)
		if RoomLayout.WALLS.contains(symbol):
			return true
		# A broken prop leaves its cell free.
		var view: RoomView = scene.debug_room_view()
		return not view._broken_cells.has(cell)

	func _find_path(layout: RoomLayout, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
		var size := layout.size_in_cells()
		var goal := to
		if _solid(layout, goal):
			goal = layout.nearest_floor_cell(goal)
		var came := {from: from}
		var open: Array[Vector2i] = [from]
		var head := 0
		while head < open.size():
			var cell := open[head]
			head += 1
			if cell == goal:
				break
			for step: Vector2i in RoomLayout.SIDES:
				var next: Vector2i = cell + step
				if came.has(next) or next.x < 0 or next.y < 0 or next.x >= size.x or next.y >= size.y or _solid(layout, next):
					continue
				came[next] = cell
				open.append(next)
		var path: Array[Vector2i] = []
		if not came.has(goal):
			return path
		var cursor := goal
		while cursor != from:
			path.push_front(cursor)
			cursor = came[cursor]
		path.push_front(from)
		return path

	func _press_move(direction: Vector2) -> void:
		_set_axis("move_left", "move_right", direction.x)
		_set_axis("move_up", "move_down", direction.y)

	func _set_axis(negative: String, positive: String, value: float) -> void:
		if value > 0.05:
			Input.action_press(positive, value)
			Input.action_release(negative)
		elif value < -0.05:
			Input.action_press(negative, -value)
			Input.action_release(positive)
		else:
			Input.action_release(negative)
			Input.action_release(positive)

	func _handle_dodge() -> void:
		if _dodge_pressed:
			Input.action_release("dodge")
			_dodge_pressed = false
		if _dodge_wish:
			_dodge_wish = false
			if _move != Vector2.ZERO:
				Input.action_press("dodge")
				_dodge_pressed = true

	func _handle_attack(target: Enemy, delta: float) -> void:
		if _pressed:
			Input.action_release("attack")
			_pressed = false
		_press_wait -= delta
		if target == null or _press_wait > 0.0:
			return
		var rect := target.body_rect()
		var me := _player.global_position
		if me.distance_to(MeleeArc.closest_point(rect, me)) > Player.ATTACK_REACH - 4.0:
			return
		if target.def.shield_half_angle > 0.0 and Enemy.shield_covers(target.facing, me - target.global_position, target.def.shield_half_angle):
			return
		_press_wait = skill["press"]
		var error := deg_to_rad(rng.randf_range(-skill["aim"], skill["aim"]))
		_aim_at = me + (target.global_position - me).rotated(error)
		Input.action_press("attack")
		_pressed = true
