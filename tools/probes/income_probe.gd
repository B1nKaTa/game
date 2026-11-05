extends SceneTree
# Measures Pension per full clear with real rooms: kills everything, collects, breaks props.
# Args after --: <path index> [depth] [item ids, comma separated, or "none"] [runs]. Given the third
# argument, the run holds those items from its start and his kills go through the item hooks, as a
# swing's do, so items that pay on kills, clears or floors are counted. Compare against "none".

const RUNS := 30
const WALL_LIMIT_MS := 900000

var _start := 0
var _through_hooks := false


func _initialize() -> void:
	_start = Time.get_ticks_msec()
	_main.call_deferred()


func _process(_d: float) -> bool:
	if Time.get_ticks_msec() - _start > WALL_LIMIT_MS:
		print("PROBE TIMEOUT")
		quit(3)
	return false


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _main() -> void:
	await process_frame
	var progress = root.get_node("Progress")
	progress._store = SaveStore.new("user://probe_save.json")
	progress._store.delete_all()
	progress.reload()
	progress.data.floors_cleared = 1
	progress.data.record_floor_cleared(2, "sunset_shores")
	progress.data.record_floor_cleared(3, "funeral_parlour")
	var totals := {"fights": [], "chests": [], "cane": [], "bomb": [], "combat_rooms": [], "enemies": [], "total": []}
	var args := OS.get_cmdline_user_args()
	var runs := int(args[3]) if args.size() > 3 else RUNS
	for run in runs:
		var r: Dictionary = await _one_run(progress)
		for key in r:
			totals[key].append(r[key])
	for key in totals:
		var list: Array = totals[key]
		var s := 0.0
		var lo := 1e9
		var hi := -1e9
		for v in list:
			s += v
			lo = minf(lo, v)
			hi = maxf(hi, v)
		print("%s: mean %.1f min %d max %d" % [key, s / list.size(), lo, hi])
	progress._store.delete_all()
	quit(0)


func _one_run(progress) -> Dictionary:
	change_scene_to_file("res://scenes/floor.tscn")
	await _wait(0.2)
	var scene = current_scene
	var args := OS.get_cmdline_user_args()
	if args.size() > 1:
		scene._depth = int(args[1])
	_through_hooks = args.size() > 2
	if _through_hooks:
		for id in args[2].split(",", false):
			for item in Content.items():
				if item.id == id:
					scene.player.run.add_item(item)
	var bank_start: int = progress.data.pension
	scene.debug_choose_path(int(args[0]))
	await _wait(0.1)
	var map: FloorMap = scene.debug_map()
	var out := {"fights": 0, "chests": 0, "cane": 0, "bomb": 0, "combat_rooms": 0, "enemies": 0, "total": 0}
	var order: Array = []
	for room in map.rooms:
		if room.id != map.boss_id and room.id != map.start_id and room.room_type != RoomLayout.TYPE_CROSSROADS:
			order.append(room.id)
	order.append(map.boss_id)
	var bank_last: int = progress.data.pension
	var start_room := true
	var ids := [map.start_id] + order
	for id in ids:
		if id != scene.debug_current_id():
			scene._enter_room(id)
			await _wait(0.05)
		var kind: String = map.room(id).room_type
		if kind == RoomLayout.TYPE_COMBAT or kind == RoomLayout.TYPE_SIDE:
			out["combat_rooms"] += 1
		scene.player.run.health.heal(99)
		var is_boss: bool = id == map.boss_id
		if not is_boss:
			# Props first would be no different, but fights are counted on their own.
			pass
		var view: RoomView = scene.debug_room_view()
		if is_boss:
			# Clearing the boss ends the run, so its props are counted before it falls.
			await _break(view, BreakableBlock.SOURCE_CANE, scene)
			out["cane"] += progress.data.pension - bank_last
			bank_last = progress.data.pension
			await _break(view, BreakableBlock.SOURCE_BLAST, scene)
			out["bomb"] += progress.data.pension - bank_last
			bank_last = progress.data.pension
		out["enemies"] += _kill_all(scene)
		await _wait(0.08)
		if not is_boss:
			await _collect(view, scene)
		out["fights"] += progress.data.pension - bank_last
		bank_last = progress.data.pension
		if is_boss:
			out["total"] = progress.data.pension - bank_start
			break
		await _open_chests(view, scene)
		out["chests"] += progress.data.pension - bank_last
		bank_last = progress.data.pension
		await _break(view, BreakableBlock.SOURCE_CANE, scene)
		out["cane"] += progress.data.pension - bank_last
		bank_last = progress.data.pension
		await _break(view, BreakableBlock.SOURCE_BLAST, scene)
		out["bomb"] += progress.data.pension - bank_last
		bank_last = progress.data.pension
	return out


func _kill_all(scene) -> int:
	var n := 0
	for enemy in get_nodes_in_group("enemies"):
		n += 1
		if _through_hooks:
			scene.player.run.effects.land(enemy, INF, RunEffects.SWING)
		else:
			enemy.take_damage(INF, Vector2.ZERO)
	return n


func _open_chests(view: RoomView, scene) -> void:
	# Every chest a player can open: lunchboxes, locked chests and urns with Slips handed over, and
	# safes by the player's Thermos. Mimics are left asleep.
	for child in view.get_children():
		if child is Chest and not child.is_queued_for_deletion():
			match child.kind:
				ChestRules.LUNCHBOX, ChestRules.LOCKED, ChestRules.URN:
					scene.player.run.add_key()
					scene.player.run.add_key()
					child.collect()
				ChestRules.SAFE:
					child.blast_open()
	await _wait(0.05)
	await _collect(view, scene)


func _break(view: RoomView, source: String, scene) -> void:
	for child in view.get_children():
		if child is BreakableBlock and not child is SecretWall and not child is RetirementStation and child.can_break_by(source):
			child.hit_by(source)
	await _wait(0.05)
	await _collect(view, scene)


# Coins left waiting fly by themselves once a room is finished, so they pay at once.
func _collect(view: RoomView, scene) -> void:
	for child in view.get_children():
		if child is Pickup and child.is_inside_tree() and not child.requires_interact and child.flies and not child.is_flying():
			child.fly()
	await _wait(0.02)
