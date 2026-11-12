extends SceneTree
# A simple simulated player runs real floors through real scenes with simulated input.
# Args after --: <fresh|some|max> <average|good> <runs> <path> <depth> [bosses|mini|boss|haul]
# "bosses" fights the mini boss and then the floor boss, "mini" and "boss" fight only one of them, so a
# floor boss is measured 20 times even when the mini boss wins some runs. "haul" plays the whole floor
# with what a run has picked up above: two items per floor already cleared, two Slips and a Thermos.
# Estimates only. It walks teleport-free inside rooms but changes rooms directly.
# Version 4 reads the third floor too: extra warned lanes, processions, the collection plate,
# presents, the closing ring, the crescendo's safe spot and perfume clouds.
# Version 5 reads floors 4 and 5: it walks against the ship's roll (and dodges, which holds), never
# counts on a dodge in sand, treats raised or chiming queue barriers as walls (they block only him),
# dodges through red tape it cannot walk round, steps out of every new lane, ring, sweep, roll and
# mat to the nearest clear spot, stands on marked gaps unless a heavy strike falls there, and dodges
# to snap the Chairman's tether.
# Version 8 counts the Chairman's restructuring rows as a gap attack, so it honours their mark.
# Version 9 reads any hazard node that answers threat_at(p, strict) (0 clear, 1 better avoided, 2 a
# coming hit) and threat_imminent(p), as every hazard of the Flashback Cinema does, with no branch of
# its own: the beam, splice lanes, reel lanes, the burn, the popcorn tub and the film trail.
# Version 10 leaves a marked safe spot on the third floor too once such a hazard covers it (it stood
# on the beam's mark under a reel's pie lane), and names those hazards in the hits by source.
# Version 6 reads the floor-5 bosses' overlaps: the Chairman's desk slam is a warned spot like any
# deep strike, and Augustine's runway mark is honoured while his lanes light, as a gap is while a
# chart or a sweep runs (the mark is skipped whenever a lane or strike covers it, as before).
# Version 7 knows touching a body costs a pill: it keeps its feet a few pixels off every body that
# hurts on touch, sliding round one in its way (an escape from a warned attack slides but never
# stops for one). Touches are named touch_<id> in the hits by source.
# Version 11 knows room rules and film reels. It takes reels with the other pickups, waits out the
# Auditor's walk-in (a room fights while the view says so, not only while enemies stand), and counts
# the rules it meets, breaks and keeps and the Auditors that come. "obey" anywhere after the depth keeps
# a No Cane room's swings and a No Horseplay room's dodges back. "eras" plays fight rooms in turn as old
# Harold, the 1960 footballer and the 1975 bus conductor: before each one it sets the reel, walks within
# 40 px of the door, presses flashback for a frame and goes through. Era attacks use the era's reach.
# It sums enemy health lost (dismissals left out) and fight time (summed physics delta) per combat room,
# and prints old_dps and era_dps on the SUMMARY line.
# Version 12 presses attack only once the last swing's lock is over (a press inside it was lost, and
# old Harold's 0.2 s lock matched the 0.2 s press pace, so about half his presses could be), and adds
# swings per second of fight time to each dps_rooms entry (<rooms>/<s>/<swings per s>sw).

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
	if str(ProjectSettings.get_setting("application/config/name")) == "Grandpa":
		print("bot_probe.gd: refusing to run against the real save folder; use an exported copy with a renamed config/name.")
		quit(2)
		return
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
# Version 11: the case flags, and which self the next fight room is played as (0 old, then each era in
# ERA_TURNS: football 1960, dance hall 1962, bus 1975, allotment 1988).
var _eras := false
var _obey := false
var _era_turn := 0
const ERA_TURNS: Array[String] = ["", Eras.FOOTBALL, Eras.DANCE, Eras.BUS, Eras.ALLOTMENT]
# How near the door (his middle to the door, as Door.is_within measures) he stands to press flashback.
const REEL_DOOR_GAP := 40.0


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
	# Every deep path opens: the cruise counts for the fourth floor, the terminal for the fifth. Only
	# for deep runs, so a floor-3 run keeps the save its numbers were measured on.
	if args.size() > 4 and int(args[4]) >= 4:
		progress.data.record_floor_cleared(4, "last_resort_cruise")
		progress.data.record_floor_cleared(5, "terminal_zero")
	for key in SAVES[save_name]:
		progress.data.upgrades[key] = SAVES[save_name][key]
	var mode: String = args[5] if args.size() > 5 else ""
	_eras = args.slice(5).has("eras")
	_obey = args.slice(5).has("obey")
	var bosses_only := mode == "bosses" or mode == "mini" or mode == "boss"
	for i in runs:
		var result: Dictionary = {}
		if bosses_only:
			result = await _run_bosses(progress, mode)
		else:
			result = await _run(progress)
		_results.append(result)
		print("run %d: %s" % [i, str(result)])
	_print_summary()
	progress._store.delete_all()
	quit(0)


func _print_summary() -> void:
	print("hits by source: %s" % str(_sources))
	print("attacks seen: %s" % str(_kinds))
	var n := _results.size()
	if n == 0:
		return
	var sums := {"reached_mini": 0, "beat_mini": 0, "reached_boss": 0, "beat_boss": 0, "income": 0.0, "time": 0.0, "rooms": 0.0, "stuck": 0, "hits": 0.0, "end_pills": 0.0}
	var boss_times: Array = []
	var mini_times: Array = []
	var boss_hits: Array = []
	var mini_hits: Array = []
	var boss_left: Array = []
	for r in _results:
		if r.has("boss_left"):
			boss_left.append(r["boss_left"])
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
	print("SUMMARY %s runs=%d reached_mini=%d beat_mini=%d reached_boss=%d beat_boss=%d income=%.0f run_minutes=%.1f rooms=%.1f hits=%.1f stuck_rooms=%d mini_ttk=%s mini_hits=%s boss_ttk=%s boss_hits=%s boss_left=%s%s" % [_config, n, sums["reached_mini"], sums["beat_mini"], sums["reached_boss"], sums["beat_boss"], sums["income"] / n, sums["time"] / n / 60.0, sums["rooms"] / float(n), sums["hits"] / n, sums["stuck"], _mean(mini_times), _mean(mini_hits), _mean(boss_times), _mean(boss_hits), _mean(boss_left), _rules_summary()])


# Version 11: deaths, the rules met, broken and kept, the Auditors, reels taken, and in "eras" mode the
# damage per second of each self over the combat rooms he cleared as it.
func _rules_summary() -> String:
	var deaths := 0
	var seen := 0
	var broken := 0
	var kept := 0
	var auditors := 0
	var reels := 0
	var by_rule := {}
	var dealt := {}
	var fought := {}
	var rooms := {}
	var swung := {}
	var readied := 0
	var fallback := 0
	for r in _results:
		if str(r.get("death_in", "")) != "":
			deaths += 1
		seen += int(r.get("rules_seen", 0))
		broken += int(r.get("rules_broken", 0))
		kept += int(r.get("rules_kept", 0))
		auditors += int(r.get("auditors", 0))
		reels += int(r.get("reels_taken", 0))
		readied += int(r.get("reels_readied", 0))
		fallback += int(r.get("ready_fallback", 0))
		for rule in r.get("broken_by", {}):
			by_rule[rule] = by_rule.get(rule, 0) + r["broken_by"][rule]
		for era in r.get("dealt", {}):
			dealt[era] = dealt.get(era, 0.0) + r["dealt"][era]
			fought[era] = fought.get(era, 0.0) + r["fought"][era]
			rooms[era] = rooms.get(era, 0) + r["dps_rooms"][era]
			swung[era] = swung.get(era, 0) + r.get("swings", {}).get(era, 0)
	var parts: Array[String] = []
	for rule in by_rule:
		parts.append("%s:%d" % [rule, by_rule[rule]])
	var out := " deaths=%d rules_seen=%d rules_broken=%d rules_kept=%d broken_by=%s auditors=%d reels_taken=%d" % [deaths, seen, broken, kept, ",".join(parts) if not parts.is_empty() else "-", auditors, reels]
	if not _eras:
		return out
	var era_parts: Array[String] = []
	var room_parts: Array[String] = []
	for era in Eras.STARTING:
		era_parts.append("%s:%s" % [era, _dps(dealt, fought, era)])
		room_parts.append("%s:%d/%.0fs/%.2fsw" % [era, rooms.get(era, 0), fought.get(era, 0.0), swung.get(era, 0) / maxf(fought.get(era, 0.0), 0.001)])
	room_parts.push_front("old:%d/%.0fs/%.2fsw" % [rooms.get("", 0), fought.get("", 0.0), swung.get("", 0) / maxf(fought.get("", 0.0), 0.001)])
	return out + " old_dps=%s era_dps=%s dps_rooms=%s reels_readied=%d ready_fallback=%d" % [_dps(dealt, fought, ""), ",".join(era_parts), ",".join(room_parts), readied, fallback]


# One entry per self (old Harold as "", then each era) holding the same starting value.
func _per_self(start: Variant) -> Dictionary:
	var out := {"": start}
	for era in Eras.STARTING:
		out[era] = start
	return out


func _dps(dealt: Dictionary, fought: Dictionary, era: String) -> String:
	if fought.get(era, 0.0) <= 0.0:
		return "-"
	return "%.1f" % (dealt[era] / fought[era])


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
	bot.kinds = _kinds
	scene.add_child(bot)
	# A typical haul: two items for each floor above (four on the third floor, as v4 used), two Slips
	# and a Thermos.
	if OS.get_cmdline_user_args().size() > 5 and OS.get_cmdline_user_args()[5] == "haul":
		var run: RunState = scene.player.run
		var pool: Array = []
		for item in Content.items():
			if run.can_offer(item):
				pool.append(item)
		for i in 2 * (scene._depth - 1):
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
	r.merge({"rules_seen": 0, "rules_broken": 0, "rules_kept": 0, "broken_by": {}, "auditors": 0, "reels_taken": 0, "reels_readied": 0, "ready_fallback": 0, "dealt": _per_self(0.0), "fought": _per_self(0.0), "dps_rooms": _per_self(0), "swings": _per_self(0)})
	scene.player.hurt.connect(func(): r["hits"] += 1; _attribute(scene); _trace(bot))
	var rules: RuleKeeper = scene.debug_rules()
	bot.rules = rules
	bot.obey = _obey
	rules.rule_broken.connect(func(_view): r["rules_broken"] += 1)
	var reel_was := ""
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
		var watch: RuleWatch = rules.watch_of(at)
		var rule_open: bool = watch != null and watch.is_open()
		if rule_open:
			r["rules_seen"] += 1
		var era: String = scene.player.era()
		bot.begin_count()
		var cleared: bool = await bot.fight_room()
		var took: float = bot.clock - began
		r["auditors"] += bot.auditors
		if rule_open:
			if watch.state == RuleWatch.State.KEPT:
				r["rules_kept"] += 1
			elif watch.state == RuleWatch.State.BROKEN or watch.state == RuleWatch.State.LIFTED:
				r["broken_by"][watch.rule] = r["broken_by"].get(watch.rule, 0) + 1
		# Damage per second over combat rooms he cleared, by the self he played them as.
		if cleared and had_enemies and kind == RoomLayout.TYPE_COMBAT and r["dealt"].has(era):
			r["dealt"][era] += bot.dealt
			r["fought"][era] += bot.fought
			r["dps_rooms"][era] += 1
			r["swings"][era] += bot.swings
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
		var run: RunState = scene.player.run
		if run.held_reel != "" and run.held_reel != reel_was:
			r["reels_taken"] += 1
		reel_was = run.held_reel
		var next := _next_room(scene, map)
		if next == -1:
			break
		if _eras and not scene.debug_progress().is_visited(next) and RuleKeeper.FIGHT_ROOMS.has(map.room(next).room_type):
			var self_for: String = ERA_TURNS[_era_turn % ERA_TURNS.size()]
			_era_turn += 1
			if self_for != "":
				# A DEV give, as F7 would: the reel for this turn's era.
				run.held_reel = self_for
				reel_was = self_for
				var readied: int = await bot.ready_reel_at(next)
				if readied == 2:
					r["ready_fallback"] += 1
				if readied > 0:
					r["reels_readied"] += 1
				if scene.debug_current_id() != at:
					# A door on the way took him through on its own; that room is fought next.
					continue
		scene._enter_room(next)
		await create_timer(0.1).timeout
	r["income"] = progress.data.pension - pension_before
	r["time"] = bot.clock
	bot.release_all()
	return r


var _sources := {}
# How many of each attack node appeared in rooms, so a fight with no hits can be told from one with no
# attacks.
var _kinds := {}


func _attribute(scene) -> void:
	var me: Vector2 = scene.player.global_position
	# A touch is named by the body it came from, since its own attacks may be running too.
	if scene.player.last_hurt_source == RunEffects.HURT_CONTACT:
		var box := ContactRule.feet_box(scene.player.feet().global_position, Player.FEET_BOX_SIZE)
		var toucher := "touch"
		for enemy in scene.get_tree().get_nodes_in_group("enemies"):
			if ContactRule.touches(enemy.body_rect(), box):
				toucher = "touch_" + enemy.def.id
		_sources[toucher] = _sources.get(toucher, 0) + 1
		return
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
		elif child is ProcessionLane and child.is_marching():
			name = "procession"
			d = 0.0
		elif child is CollectionPlate and child.is_flying():
			name = "plate"
			d = 0.0
		elif child is AnchorDrop or child is QuoitRing or child is WriteUpMark or child is GroundStrike:
			if d < 60.0:
				name = child.get_class() if child.get_script() == null else str(child.get_script().get_global_name())
				d = 0.0
		elif child is DeckLane and child.is_moving() and DeckLane.row_hits(child.global_position, child._direction, child._width + 16.0, minf(child._front, child._length) + 8.0, DeckLane.row_for(child.look()) + 16.0, scene.player.feet().global_position):
			name = "deck_lane_" + child.look()
			d = 1.0
		elif child is RunwayLane and child.is_lit():
			name = "runway"
			d = 0.0
		elif child is LaneDrop and child.has_landed() and child.strip().grow(14.0).has_point(scene.player.feet().global_position):
			name = "lane_drop_" + child.look()
			d = 0.0
		elif child is XRaySweep and child.is_sweeping() and absf((scene.player.feet().global_position.x if child._along_x else scene.player.feet().global_position.y) - child.beam_at()) < 30.0:
			name = "xray"
			d = 2.0
		elif child is ShuffleboardPuck and child.is_sliding() and scene.player.feet().global_position.distance_to(child.global_position + CollectionPlate.point_along(child._path, child._travelled)) < 30.0:
			name = "puck"
			d = 1.0
		elif child.has_method("threat_at") and not (child is LineTether or child is SeanceCircle) and (child.threat_imminent(scene.player.feet().global_position) or child.threat_at(scene.player.feet().global_position, false) >= 2):
			# Version 9's hazards name themselves when his feet are under a coming hit.
			name = str(child.get_script().get_global_name())
			d = 0.5
		elif child is Enemy:
			name = child.def.id
		if name != "" and d < best_d:
			best_d = d
			best = name
	_sources[best] = _sources.get(best, 0) + 1


# With "trace" after the mode, every hit prints what the bot was doing and what it saw.
func _trace(bot) -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 6 and args[6] == "trace":
		print("HIT " + bot.debug_state())


# Straight into the mini boss and then the floor boss, each with full pills, so a boss fight is
# measured on its own and not by how often the bot survives the rooms before it.
func _run_bosses(_progress, mode := "bosses") -> Dictionary:
	change_scene_to_file("res://scenes/floor.tscn")
	await create_timer(0.1).timeout
	var scene = current_scene
	scene._depth = int(OS.get_cmdline_user_args()[4])
	scene.debug_choose_path(_path)
	await create_timer(0.05).timeout
	var bot := Bot.new()
	bot.setup(scene, _skill, _rng)
	bot.kinds = _kinds
	scene.add_child(bot)
	var map: FloorMap = scene.debug_map()
	var kinds: Array = [RoomLayout.TYPE_MINI_BOSS, RoomLayout.TYPE_FLOOR_BOSS]
	if mode == "mini":
		kinds = [RoomLayout.TYPE_MINI_BOSS]
	elif mode == "boss":
		kinds = [RoomLayout.TYPE_FLOOR_BOSS]
	var r := {"reached_mini": kinds.has(RoomLayout.TYPE_MINI_BOSS), "beat_mini": false, "reached_boss": kinds.has(RoomLayout.TYPE_FLOOR_BOSS), "beat_boss": false, "income": 0, "time": 0.0, "rooms": kinds.size(), "stuck": 0, "hits": 0, "boss_ttk": 0.0, "mini_ttk": 0.0, "boss_hits": 0, "mini_hits": 0, "death_in": ""}
	scene.player.hurt.connect(func(): r["hits"] += 1; _attribute(scene); _trace(bot))
	for kind in kinds:
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
		# How much of the boss is left when he falls: tells hard bosses apart when few fights are won.
		r[key + "_left"] = 0.0 if won else _boss_left(scene) * 100.0
		if not won:
			r["death_in"] = kind
			break
	r["time"] = bot.clock
	bot.release_all()
	return r


func _boss_left(scene) -> float:
	var left := 0.0
	for enemy in scene.get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.def != null and enemy.def.is_boss and enemy.max_hp() > 0.0:
			left = maxf(left, enemy.hp / enemy.max_hp())
	return left


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
	# How far ahead a walk is checked for a body, and how far off bodies the feet are kept (v7).
	const BODY_LOOKAHEAD := 6.0
	const BODY_MARGIN := 3.0
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
	# Floors 4 and 5: where he is stepping to out of a new hazard, and the cells raised or chiming
	# barriers block this frame.
	var _deep_goal := Vector2.INF
	var _barrier_cells := {}
	var _soft_cells := {}
	var _dodge_against := Vector2.ZERO
	var _zones: Array = []
	var _kept_goal := Vector2.INF
	var _kept_left := 0.0
	var _threat := Vector2.ZERO
	# Version 11: the floor's rules, whether he keeps a No Cane or No Horseplay rule, the Auditors that
	# came this room, enemy health lost and fight time this room, and a door he walks up to.
	var rules: RuleKeeper
	var obey := false
	var auditors := 0
	var dealt := 0.0
	var fought := 0.0
	var swings := 0
	var _hp_seen := {}
	var _walk_goal := Vector2.INF

	func begin_count() -> void:
		auditors = 0
		swings = 0
		dealt = 0.0
		fought = 0.0

	# Every enemy's health as last seen; a drop counts as damage dealt unless it left by dismissal (a
	# boss's fall, or the bot giving up). Overkill below 0 is not counted.
	func _watch_health() -> void:
		for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
			var id := enemy.get_instance_id()
			if _hp_seen.has(id):
				continue
			_hp_seen[id] = enemy.hp
			if enemy.def != null and enemy.def.id == "auditor":
				auditors += 1
			enemy.health_changed.connect(_on_enemy_health.bind(enemy))

	func _on_enemy_health(hp: float, enemy: Enemy) -> void:
		var id := enemy.get_instance_id()
		var last: float = _hp_seen.get(id, hp)
		_hp_seen[id] = hp
		if enemy._dismissed or is_inf(hp) or is_nan(hp):
			return
		var lost := maxf(last, 0.0) - maxf(hp, 0.0)
		if lost > 0.0:
			dealt += lost

	# The rule of the room he stands in, while it is still open ("" when none).
	func _open_rule() -> String:
		if rules == null:
			return ""
		var watch: RuleWatch = rules.watch_of(scene.debug_current_id())
		return watch.rule if watch != null and watch.is_open() else ""

	# Walks within REEL_DOOR_GAP of the door into a room and presses flashback for one frame. Returns 0
	# when no reel was readied, 1 when the press readied it, 2 when only a direct call did (the press
	# missed; counted on the SUMMARY line so a broken press shows).
	func ready_reel_at(target_id: int) -> int:
		var view: RoomView = scene.debug_room_view()
		var door: Door = view.door_to(target_id)
		if door == null:
			return 0
		var at: int = scene.debug_current_id()
		_walk_goal = door.global_position
		var waited := 0.0
		while not door.is_within(REEL_DOOR_GAP) and waited < 10.0 and scene.debug_current_id() == at and not scene.is_over:
			await get_tree().physics_frame
			waited += get_physics_process_delta_time()
		_walk_goal = Vector2.INF
		release_all()
		if scene.debug_current_id() != at or scene.is_over:
			return 0
		if not door.is_within(REEL_DOOR_GAP):
			print("REEL DOOR not reached in %.1f s, Grandpa at %s, door at %s" % [waited, str(_player.global_position), str(door.global_position)])
			return 0
		Input.action_press("flashback")
		await get_tree().process_frame
		await get_tree().physics_frame
		Input.action_release("flashback")
		await get_tree().process_frame
		if rules.readied_door() == target_id:
			return 1
		if rules.try_ready_reel(view, scene.debug_progress(), scene.debug_map()) and rules.readied_door() == target_id:
			return 2
		return 0

	func setup(s, sk: Dictionary, r: RandomNumberGenerator) -> void:
		scene = s
		skill = sk
		rng = r
		_player = s.player
		process_physics_priority = -10

	func _ready() -> void:
		_player.aim_source = _aim
		_player.swing_started.connect(_on_swing)

	func _on_swing() -> void:
		if _fighting:
			swings += 1

	func _aim() -> Vector2:
		return _aim_at

	func enemies_here() -> int:
		return get_tree().get_nodes_in_group("enemies").size()

	func fight_room() -> bool:
		_fighting = true
		gave_up = false
		_since_progress = 0.0
		_last_hp_total = -1.0
		# A room the view still fights in has an Auditor walking in (v11), though no enemy stands yet.
		while (enemies_here() > 0 or scene.debug_room_view().is_fighting()) and not scene.is_over:
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
		for action in ["move_left", "move_right", "move_up", "move_down", "attack", "dodge", "flashback"]:
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
			elif child.needs_press():
				continue
			elif not child.can_take.is_valid() or child.can_take.call():
				child.collect()

	func _physics_process(delta: float) -> void:
		Engine.time_scale = 1.0
		clock += delta
		if _walk_goal != Vector2.INF and not _fighting and is_instance_valid(_player) and not scene.is_over:
			_press_move(_walk_to(_walk_goal))
			return
		if not _fighting or scene.is_over or not is_instance_valid(_player):
			return
		fought += delta
		_watch_health()
		_track_progress(delta)
		_count_kinds()
		_move = Vector2.ZERO
		_read_cells()
		var threat := _read_threats(delta)
		_threat = threat
		var target := _pick_target()
		if target != null:
			_aim_at = _aimed(target)
		if threat != Vector2.ZERO:
			_move = threat
		elif target != null:
			_move = _around_fire(_player.feet().global_position, _approach(target, delta))
		if _deep_goal != Vector2.INF:
			var to_goal: Vector2 = _deep_goal - _player.feet().global_position
			_move = to_goal.normalized() if to_goal.length() > 2.0 else Vector2.ZERO
		elif threat == Vector2.ZERO and _steps_into_hit(_player.feet().global_position, _move):
			# He waits at the edge of a warned spot or lane rather than walking into it.
			_move = Vector2.ZERO
		var safe := safe_spot()
		if safe != Vector2.INF:
			_move = _walk_to(safe)
		_cut_tape_ahead()
		if _dodge_against != Vector2.ZERO and _dodge_wish:
			_move = _dodge_against
		elif safe == Vector2.INF and _deep_goal == Vector2.INF and threat == Vector2.ZERO:
			_move = _keep_off_bodies(_move)
		else:
			# An escape slides round a body in its way rather than walk through it, and never stops.
			var kept := _keep_off_bodies(_move)
			if kept != Vector2.ZERO:
				_move = kept
		_press_move(_move)
		_handle_dodge()
		_handle_attack(target, delta)

	var _counted := {}

	func debug_state() -> String:
		var feet: Vector2 = _player.feet().global_position
		var parts: Array[String] = []
		parts.append("t=%.2f feet=%s move=%s goal=%s safe=%s dodging=%s taped=%s cool=%.2f" % [clock, str(feet.round()), str(_move.snapped(Vector2(0.01, 0.01))), str(_deep_goal.round()) if _deep_goal != Vector2.INF else "-", str(safe_spot().round()) if safe_spot() != Vector2.INF else "-", str(_player.is_dodging()), str(_player.is_taped()), _player._dodge._cooldown])
		for child in scene.debug_room_view().get_children():
			if child.is_queued_for_deletion():
				continue
			if _is_deep(child) or child is GroundStrike or child is SafeSpotMark or child is XRaySweep or child is TakeoverTether:
				var seen: String = "%.2f" % (clock - _seen[child.get_instance_id()]) if _seen.has(child.get_instance_id()) else "unseen"
				var zone := _deep_zone(child, feet) if _is_deep(child) else -1
				parts.append("  %s at %s d=%.0f zone=%d seen=%s left=%s" % [str(child.get_script().get_global_name()), str(child.global_position.round()), feet.distance_to(child.global_position), zone, seen, str(child.get("_left"))])
		for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.global_position.distance_to(feet) < 120.0:
				var shows: bool = enemy._warning != null and enemy._warning.shows_warning(enemy._warning_share() if enemy.has_method("_warning_share") else enemy._warning_fraction)
				parts.append("  enemy %s d=%.0f warn=%s lane=%.0f radius=%.0f vel=%s" % [enemy.def.id, enemy.global_position.distance_to(feet), str(shows), enemy._lane_length, enemy._warning_radius, str(enemy.velocity.round())])
		return "\n".join(parts)
	var kinds := {}

	func _count_kinds() -> void:
		for child in scene.debug_room_view().get_children():
			var id: int = child.get_instance_id()
			if _counted.has(id):
				continue
			_counted[id] = true
			var script: Script = child.get_script()
			if script == null or child is Enemy or child is Pickup or child is BreakableBlock:
				continue
			var kind := str(script.get_global_name())
			if kind != "":
				kinds[kind] = kinds.get(kind, 0) + 1
		for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy._warning != null:
				var wid: int = enemy._warning.get_instance_id()
				if not _counted.has(wid):
					_counted[wid] = true
					var wk := "warn_" + enemy.def.id
					kinds[wk] = kinds.get(wk, 0) + 1

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
			# Bites hit his feet, 17 px below his middle, and swings his middle, so he clears both (v4 read only his middle).
			var ring_feet: Vector2 = _player.feet().global_position
			if ring_feet.distance_to(from) < radius + 10.0 or me.distance_to(from) < radius + 10.0:
				escape += from.direction_to(me) if me != from else Vector2.RIGHT
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
		_read_deep(enemy_free_feet())
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
				if _heavy_strike_on(child.global_position) or (scene.debug_floor_def().depth >= 4 and _spot_hurts(child.global_position, _zones, false)):
					continue
				# Version 10: on any floor, a mark a later hazard covers (a reel's lane over the beam's
				# mark) is no longer safe.
				if _threat_hurts(child.global_position):
					continue
				if scene.debug_floor_def().depth >= 4 and (not _gap_attack_on() or _threat != Vector2.ZERO):
					continue
				return child.global_position
		return Vector2.INF

	# The deep attacks that leave a marked gap: conga rows, the X-ray beam, the Chairman's bars and
	# Augustine's runway lights.
	func _gap_attack_on() -> bool:
		for child in scene.debug_room_view().get_children():
			if child.is_queued_for_deletion():
				continue
			if child is DeckLane and child.look() == DeckLane.LOOK_CONGA:
				return true
			if child is XRaySweep or (child is LaneDrop and (child.look() == LaneDrop.LOOK_BAR or child.look() == LaneDrop.LOOK_DRAWERS) and not child.is_finished()):
				return true
			if child is RunwayLane and not child.is_over():
				return true
		return false

	# Whether one of the deep floors' heavy strikes (an anchor, a stamp, a gavel) is
	# falling on a spot, so a marked gap there is no longer safe.
	func _heavy_strike_on(spot: Vector2) -> bool:
		for child in scene.debug_room_view().get_children():
			if child is AnchorDrop and not child._landed and spot.distance_to(child.global_position) < AnchorDrop.RADIUS + 12.0:
				return true
			if (child is GavelStrike or child is TerminalStrike) and not child._landed and child._delay <= 0.0 and spot.distance_to(child.global_position) < child._radius + 12.0:
				return true
		return false

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

	# Floors 4 and 5. Cells the walk avoids or cannot use this frame: raised or chiming barriers block
	# only him, and strung tape is walked round when there is another way.
	func _read_cells() -> void:
		_barrier_cells.clear()
		_soft_cells.clear()
		var tree := get_tree()
		for barrier in QueueBarrier.barriers_in(tree):
			if is_instance_valid(barrier) and (barrier.is_up() or barrier.is_chiming()):
				_barrier_cells[barrier._cell] = true
		for tape in tree.get_nodes_in_group(RedTape.GROUP):
			if is_instance_valid(tape) and tape.is_strung() and not tape.is_cut():
				_soft_cells[_cell(tape.global_position)] = true

	func _is_deep(child: Node) -> bool:
		return child.has_method("threat_at") or child is DeckLane or child is RunwayLane or child is LaneDrop or child is ShuffleboardPuck or child is AnchorDrop or child is QuoitRing or child is WriteUpMark or child is PaperTrail or child is TapeSpread or _is_deep_strike(child)

	# The deep floors' own marks on the ground: a gavel, a stamp or tray.
	func _is_deep_strike(child: Node) -> bool:
		return child is GavelStrike or child is TerminalStrike or child is DeskSlam

	# 0 for clear, 1 for somewhere better avoided (it slows or will warn soon), 2 for a coming hit.
	func _deep_zone(child: Node, p: Vector2, strict := false) -> int:
		if child.has_method("threat_at"):
			return int(child.threat_at(p, strict))
		if child is DeckLane:
			var off: Vector2 = p - child.global_position
			var along: float = off.dot(child._direction)
			var side: float = absf(off.dot(child._direction.orthogonal()))
			if side > child._width / 2.0 + 12.0 or along < -12.0 or along > child._length + 12.0:
				return 0
			if not strict and child.is_moving() and along < child._front - DeckLane.row_for(child.look()) - 12.0:
				return 0
			return 2
		if child is RunwayLane:
			if child.is_over():
				return 0
			var off2: Vector2 = p - child.global_position
			var along2: float = off2.dot(child._direction)
			if along2 < -10.0 or along2 > child._length + 10.0 or absf(off2.dot(child._direction.orthogonal())) > child._width / 2.0 + 12.0:
				return 0
			return 1 if child.is_waiting() else 2
		if child is LaneDrop:
			if child.is_finished() or not child.strip().grow(12.0).has_point(p):
				return 0
			if child.is_waiting():
				return 1
			if not child.has_landed():
				return 2
			return 2 if child._stand_left > 0.0 else 0
		if child is ShuffleboardPuck:
			var from: float = child._travelled
			var d := from
			while d <= child._total:
				if p.distance_to(child.global_position + CollectionPlate.point_along(child._path, d)) < 13.0 + 12.0:
					return 2
				d += 8.0
			return 0
		if _is_deep_strike(child):
			return 2 if not child._landed and child._delay <= 0.0 and not child.is_following() and p.distance_to(child.global_position) < child._radius + 12.0 else 0
		if child is AnchorDrop:
			return 2 if not child._landed and p.distance_to(child.global_position) < AnchorDrop.RADIUS + 12.0 else 0
		if child is QuoitRing:
			var dq := p.distance_to(child.global_position)
			if not child._landed:
				return 2 if dq < QuoitRing.RADIUS + 12.0 else 0
			return 1 if child.is_lying() and dq < QuoitRing.RADIUS + 4.0 else 0
		if child is WriteUpMark:
			var dw := p.distance_to(child.global_position)
			if not child.has_landed():
				return 2 if dw < WriteUpMark.RADIUS + 12.0 else 0
			return 2 if child.covers(p) or (child._linger > 0.0 and dw < WriteUpMark.RADIUS + 4.0) else 0
		if child is PaperTrail:
			return 1 if child.covers(p) else 0
		if child is TapeSpread:
			return 1 if not child.is_strung() and child._cells.has(_cell(p)) else 0
		return 0

	# Whether a hit is a moment away, when a dodge's own cover helps.
	func _deep_imminent(child: Node, p: Vector2) -> bool:
		if child.has_method("threat_imminent"):
			return bool(child.threat_imminent(p))
		if child is DeckLane:
			if not child.is_moving():
				return false
			var ahead: float = (p - child.global_position).dot(child._direction) - child._front
			return ahead < 40.0 and ahead > -DeckLane.row_for(child.look())
		if child is RunwayLane:
			return not child.is_waiting() and (child._left < 0.12 or child.is_lit())
		if child is LaneDrop:
			return not child.is_waiting() and not child.has_landed() and child._left < 0.12
		if child is ShuffleboardPuck:
			var moving: bool = child.is_sliding()
			return moving and p.distance_to(child.global_position + CollectionPlate.point_along(child._path, child._travelled)) < 40.0
		if child is AnchorDrop or child is QuoitRing or child is WriteUpMark or _is_deep_strike(child):
			return not child._landed and child._left < 0.12
		return false

	# Steps out of the deep floors' lanes, rings, sweeps, rolls and mats to the nearest clear spot, and
	# dodges when a hit is a moment away. Also snaps the Chairman's tether, dodges an X-ray beam with no
	# gap to stand in, and dodges uphill when a forced roll carries him into a hit.
	func _read_deep(feet: Vector2) -> void:
		_deep_goal = Vector2.INF
		if _kept_goal != Vector2.INF and _kept_left <= 0.0:
			_kept_goal = Vector2.INF
		_kept_left -= get_physics_process_delta_time()
		_dodge_against = Vector2.ZERO
		var view: RoomView = scene.debug_room_view()
		var zones: Array = []
		var hard: Array = []
		for child in view.get_children():
			if child.is_queued_for_deletion():
				continue
			if child is TakeoverTether:
				if not child.is_snapped() and _seen_for(child):
					_want_dodge(child.get_instance_id())
				continue
			if child is XRaySweep:
				if _seen_for(child) and child.is_sweeping() and not XRaySweep.spared(feet, child._safe):
					var mine: float = feet.x if child._along_x else feet.y
					var gap: float = (mine - child.beam_at()) * signf(child._to - child._from)
					if gap > -XRaySweep.WIDTH and gap < 36.0:
						_want_dodge(child.get_instance_id() + 1)
				continue
			if not _is_deep(child) or not _seen_for(child):
				continue
			zones.append(child)
			if _deep_zone(child, feet) == 2:
				hard.append(child)
		var slide: Vector2 = ShipDeck.slide_at(get_tree(), feet)
		if slide.length() > ShipRoll.SPEED + 1.0:
			var down := feet + slide.normalized() * 60.0
			if _spot_hurts(down, zones):
				_dodge_against = -slide.normalized()
				_want_dodge(900000 + int(clock * 2.0))
		_zones = zones
		if hard.is_empty():
			return
		# He keeps to the spot he chose while it stays clear, as a player commits to a way out.
		if _kept_goal != Vector2.INF and feet.distance_to(_kept_goal) < 260.0 and feet.distance_to(_kept_goal) > 6.0 and not _spot_hurts(_kept_goal, zones):
			_deep_goal = _kept_goal
		else:
			_deep_goal = _nearest_clear(feet, zones)
			if _deep_goal == Vector2.INF:
				# Nowhere is clear of everything: he gets clear of what falls or lands in place and
				# leaves the passing rows and lanes to a dodge.
				var fixed: Array = zones.filter(func(z): return is_instance_valid(z) and not (z is DeckLane or z is RunwayLane or z is LaneDrop))
				_deep_goal = _nearest_clear(feet, fixed)
		_kept_goal = _deep_goal
		_kept_left = 0.3
		if OS.get_cmdline_user_args().size() > 6 and OS.get_cmdline_user_args()[6] == "trace": print("DEEP t=%.2f feet=%s goal=%s hard=%s" % [clock, str(feet.round()), str(_deep_goal), str(hard.map(func(h): return h.get_script().get_global_name()))])
		for child in hard:
			# A dodge out of a mark that falls in place helps; out of a sweep or a moving row it is
			# better kept for the moment it arrives.
			var sweeps: bool = child is DeckLane or child is ShuffleboardPuck or child is OuijaPlanchette or child is PossessionGhost
			if not sweeps and _deep_goal != Vector2.INF and feet.distance_to(_deep_goal) > 30.0:
				_want_dodge(child.get_instance_id())
			if _deep_imminent(child, feet):
				_want_dodge(child.get_instance_id() + 1)

	# Whether a hazard read through threat_at has a coming hit on a spot.
	func _threat_hurts(p: Vector2) -> bool:
		for zone in _zones:
			if is_instance_valid(zone) and zone.has_method("threat_at") and int(zone.threat_at(p, true)) == 2:
				return true
		return false

	func _spot_hurts(p: Vector2, zones: Array, with_enemies := true) -> bool:
		if with_enemies and _enemy_warning_at(p):
			return true
		for zone in zones:
			if is_instance_valid(zone) and _deep_zone(zone, p, true) == 2:
				return true
		for strike in scene.debug_room_view().get_children():
			if strike is GroundStrike and not strike._landed and strike._delay <= 0.0 and p.distance_to(strike.global_position) < strike._radius + 10.0:
				return true
		return false

	# Whether a shown enemy warning (a lane, a fan, a ring or a cone) covers a spot.
	func _enemy_warning_at(p: Vector2) -> bool:
		for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
			var telegraph: Telegraph = enemy._warning
			if telegraph == null or not telegraph.shows_warning(enemy._warning_share() if enemy.has_method("_warning_share") else enemy._warning_fraction):
				continue
			var from: Vector2 = enemy.global_position
			var body := p - Player.FEET_OFFSET
			if enemy._lane_length > 0.0:
				var off := body - from
				var forward := off.dot(enemy._lane_direction)
				var side := off - enemy._lane_direction * forward
				if forward > -30.0 and forward < enemy._lane_length + 30.0 and side.length() < enemy._lane_width / 2.0 + 14.0:
					return true
			for lane in enemy._extra_lanes:
				var way: Vector2 = lane[0]
				var off2 := body - from
				var ahead := off2.dot(way)
				var aside := off2 - way * ahead
				if ahead > -30.0 and ahead < float(lane[1]) + 30.0 and aside.length() < float(lane[2]) / 2.0 + 14.0:
					return true
			if enemy._warning_radius > 0.0 and (p.distance_to(from) < enemy._warning_radius + 10.0 or body.distance_to(from) < enemy._warning_radius + 10.0):
				return true
			if enemy.warning_cone_length() > 0.0 and ChiefStokerBehavior.in_cone(from, enemy.warning_cone_direction(), enemy.warning_cone_angle() + 20.0, enemy.warning_cone_length() + 20.0, p):
				return true
		return false

	# The nearest open spot clear of every hit coming, preferring spots off tape and slowing mats.
	func _nearest_clear(feet: Vector2, zones: Array) -> Vector2:
		var layout: RoomLayout = scene.debug_map().room(scene.debug_current_id()).layout
		var size := layout.size_in_cells()
		var best := Vector2.INF
		var best_score := INF
		for step in range(1, 31):
			var r := step * 8.0
			if r > best_score:
				break
			for k in 16:
				var p: Vector2 = feet + Vector2.from_angle(TAU * k / 16.0 + step * 0.4) * r
				var cell := _cell(p)
				if cell.x < 1 or cell.y < 1 or cell.x >= size.x - 1 or cell.y >= size.y - 1 or _solid(layout, cell):
					continue
				if _spot_hurts(p, zones) or _through_boss(feet, p):
					continue
				var score := r
				if _soft_cells.has(cell):
					score += 40.0
				for zone in zones:
					if is_instance_valid(zone) and _deep_zone(zone, p) == 1:
						score += 40.0
				if score < best_score and _way_clear(feet, p, zones):
					best_score = score
					best = p
		return best

	# Whether the straight walk to a spot stays out of every coming hit he is not already standing in.
	func _way_clear(feet: Vector2, to: Vector2, zones: Array) -> bool:
		var inside: Array = []
		for zone in zones:
			if is_instance_valid(zone) and _deep_zone(zone, feet, true) == 2:
				inside.append(zone)
		var length := feet.distance_to(to)
		var layout: RoomLayout = scene.debug_map().room(scene.debug_current_id()).layout
		var step := 8.0
		while step < length + 8.0:
			var p := feet.lerp(to, minf(step / length, 1.0))
			if _solid(layout, _cell(p)):
				return false
			for zone in zones:
				if is_instance_valid(zone) and not inside.has(zone) and _deep_zone(zone, p, true) == 2:
					return false
			step += 8.0
		return true

	func _through_boss(from: Vector2, to: Vector2) -> bool:
		for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
			if not enemy.def.is_boss:
				continue
			var reach := maxf(enemy.def.body_size.x, enemy.def.body_size.y) / 2.0 + 12.0
			if from.distance_to(enemy.global_position) < reach:
				# Already beside him: only spots on his far side are through him.
				if from.direction_to(to).dot(from.direction_to(enemy.global_position)) > 0.3:
					return true
				continue
			var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, from, to)
			if closest.distance_to(enemy.global_position) < reach:
				return true
		return false

	# Whether a step from here walks into a deep floor's coming hit he is not already standing in.
	func _steps_into_hit(feet: Vector2, way: Vector2) -> bool:
		if way == Vector2.ZERO:
			return false
		var ahead := feet + way.normalized() * 16.0
		if _zones.is_empty():
			return false
		for zone in _zones:
			if is_instance_valid(zone) and _deep_zone(zone, ahead, true) == 2 and _deep_zone(zone, feet, true) != 2:
				return true
		return false

	# Strung tape just ahead with no way round: a dodge cuts it rather than being held. Held already, a
	# dodge frees him when something is coming.
	func _cut_tape_ahead() -> void:
		if _player.is_dodging() or _move == Vector2.ZERO:
			return
		var feet: Vector2 = _player.feet().global_position
		var tapes := get_tree().get_nodes_in_group(RedTape.GROUP)
		if tapes.is_empty():
			return
		var can_dodge: bool = _player._dodge._cooldown <= 0.0
		if _player.is_taped():
			if can_dodge and _deep_goal != Vector2.INF:
				_dodge_wish = true
			return
		var ahead := feet + _move.normalized() * 14.0
		if can_dodge and RedTape.any_holds(tapes, ahead) and not RedTape.any_holds(tapes, feet):
			_dodge_wish = true

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

	# A player keeps his feet off bodies that cost a pill to touch: a move heading into one loses the
	# part that goes in, and feet already close step straight out. Dodges pass through, as in the game.
	func _keep_off_bodies(move: Vector2) -> Vector2:
		if _player.is_dodging():
			return move
		var feet: Vector2 = _player.feet().global_position
		var box := ContactRule.feet_box(feet, Player.FEET_BOX_SIZE)
		var ahead := box
		if move != Vector2.ZERO:
			ahead.position += move.normalized() * BODY_LOOKAHEAD
		for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.contact_damage() <= 0:
				continue
			var body := enemy.body_rect().grow(BODY_MARGIN)
			if body.intersects(box):
				var out := body.get_center().direction_to(feet)
				return out if not out.is_zero_approx() else Vector2.DOWN
			if move != Vector2.ZERO and body.intersects(ahead):
				var toward := feet.direction_to(body.get_center())
				var slid := move - toward * maxf(move.dot(toward), 0.0)
				move = slid.normalized() if slid.length() > 0.2 else Vector2.ZERO
		return move

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
		return _attack_reach() + minf(target.def.body_size.x, target.def.body_size.y) / 2.0

	# An era's kick or punch reaches its own distance (v11); old Harold's cane ATTACK_REACH.
	func _attack_reach() -> float:
		var moves: EraMoves = _player._era_moves
		return moves.reach if moves != null else Player.ATTACK_REACH

	func _cell(at: Vector2) -> Vector2i:
		return Vector2i(floori(at.x / RoomBackdrop.TILE), floori(at.y / RoomBackdrop.TILE))

	func _solid(layout: RoomLayout, cell: Vector2i) -> bool:
		if _barrier_cells.has(cell):
			return true
		if not layout.is_solid_at(cell):
			return false
		var symbol := layout.symbol_at(cell)
		if RoomLayout.WALLS.contains(symbol):
			return true
		# A broken prop leaves its cell free.
		var view: RoomView = scene.debug_room_view()
		return not view._broken_cells.has(cell)

	# Round tape when there is a way round, through it when there is not.
	func _find_path(layout: RoomLayout, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
		if not _soft_cells.is_empty():
			var around := _find_path_avoiding(layout, from, to, true)
			if not around.is_empty():
				return around
		return _find_path_avoiding(layout, from, to, false)

	func _find_path_avoiding(layout: RoomLayout, from: Vector2i, to: Vector2i, avoid_soft: bool) -> Array[Vector2i]:
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
				if avoid_soft and next != goal and _soft_cells.has(next):
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
		# On a rolling deck he walks against the slide, so he goes where he means to or stands still.
		var slide: Vector2 = ShipDeck.slide_at(get_tree(), _player.feet().global_position) * _player.run.slide_mult()
		if slide != Vector2.ZERO and not _player.is_dodging():
			var speed := _player.run.move_speed()
			var want: Vector2 = direction.normalized() * speed if direction != Vector2.ZERO else Vector2.ZERO
			direction = (want - slide) / speed
			if direction.length() > 1.0:
				direction = direction.normalized()
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
			if obey and _open_rule() == RoomRule.NO_HORSEPLAY:
				return
			if _move != Vector2.ZERO:
				Input.action_press("dodge")
				if OS.get_cmdline_user_args().size() > 6 and OS.get_cmdline_user_args()[6] == "trace": print("DODGE t=%.2f move=%s cool=%.2f" % [clock, str(_move), _player._dodge._cooldown])
				_dodge_pressed = true

	func _handle_attack(target: Enemy, delta: float) -> void:
		if _pressed:
			Input.action_release("attack")
			_pressed = false
		_press_wait -= delta
		# v12: a press while the last swing still locks is lost (just_pressed), so he waits it out.
		if target == null or _press_wait > 0.0 or _player._combo._lock > 0.0:
			return
		var rect := target.body_rect()
		var me := _player.global_position
		if me.distance_to(MeleeArc.closest_point(rect, me)) > _attack_reach() - 4.0:
			return
		if obey and _open_rule() == RoomRule.NO_CANE:
			return
		if target.def.shield_half_angle > 0.0 and Enemy.shield_covers(target.facing, me - target.global_position, target.def.shield_half_angle):
			return
		_press_wait = skill["press"]
		var error := deg_to_rad(rng.randf_range(-skill["aim"], skill["aim"]))
		_aim_at = me + (target.global_position - me).rotated(error)
		Input.action_press("attack")
		_pressed = true
