extends SceneTree
# Feedback 13: a door that takes Harold through from far away. Builds real floor-1 runs, clears rooms,
# stands Harold at spots around each door, holds one walk direction and logs every Door.entered with the
# door's position, his feet, the door's own player reference and where his feet went over time.
# Args after --: <runs> <mode: exact|sweep> [pet] [items]
# "exact": only the large rooms, only the spot 70 px along and 70 px in from each door, holding each of
# the four directions. "sweep": every room, spots 40 to 130 px off each door, four directions.
# Headless, refuses the real save folder (run it in an export_copy.ps1 copy).

const HOLD := 2.0
const FAR := 1.5

var _enters: Array = []
var _trace: Array = []
var _frame := 0
var _bad := 0
var _cases := 0


func _initialize() -> void:
	if str(ProjectSettings.get_setting("application/config/name")) == "Grandpa":
		print("door_far_probe.gd: refusing to run against the real save folder; use an exported copy.")
		quit(2)
		return
	_main.call_deferred()


func _physics_process(_d: float) -> bool:
	_frame += 1
	var scene = current_scene
	if scene != null and "player" in scene and is_instance_valid(scene.player) and scene.player.feet() != null:
		_trace.append([_frame, scene.player.feet().global_position, scene.debug_current_id() if scene.has_method("debug_current_id") else -1])
		if _trace.size() > 240:
			_trace.pop_front()
	return false


func _main() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var runs: int = int(args[0]) if args.size() > 0 else 1
	var mode: String = args[1] if args.size() > 1 else "exact"
	var with_pet: bool = args.has("pet")
	var with_items: bool = args.has("items")
	var progress = root.get_node("Progress")
	progress._store = SaveStore.new("user://probe_door_far.json")
	progress._store.delete_all()
	progress.reload()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for run_i in runs:
		change_scene_to_file("res://scenes/floor.tscn")
		await create_timer(0.1).timeout
		var scene = current_scene
		scene.debug_choose_path(0)
		await create_timer(0.1).timeout
		var run: RunState = scene.player.run
		if with_pet:
			for item in Content.all_items():
				if item.id == "rex" or item.id == "sheepdog":
					run.add_item(item)
		if with_items:
			var pool: Array = []
			for item in Content.items():
				if run.can_offer(item):
					pool.append(item)
			for i in 6:
				if pool.is_empty():
					break
				run.add_item(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
		run.health.heal(99)
		var map: FloorMap = scene.debug_map()
		print("RUN %d floor %s rooms %d items %s" % [run_i, scene.debug_floor_def().display_name, map.rooms.size(), str(run.items.map(func(d): return d.id)) if "items" in run else "?"])
		for room in map.rooms:
			if room.layout == null or room.doors.is_empty():
				continue
			var big := room.layout.size_in_cells() == Vector2i(30, 17)
			if mode != "sweep" and not big:
				continue
			if room.room_type == RoomLayout.TYPE_CROSSROADS:
				continue
			await _test_room(scene, room, mode)
			if scene.is_over or scene.debug_map() != map:
				break
	print("PROBE DONE cases %d far enters %d" % [_cases, _bad])
	progress._store.delete_all()
	quit(0)


func _enter_and_clear(scene, room: FloorRoom) -> RoomView:
	if scene.debug_current_id() != room.id:
		scene._enter_room(room.id)
		await create_timer(0.1).timeout
	scene.debug_rules().lift_rule(room.id)
	var view: RoomView = scene.debug_room_view()
	for attempt in 4:
		for enemy in get_nodes_in_group("enemies"):
			if is_instance_valid(enemy):
				enemy.take_damage(INF, Vector2.ZERO)
		await create_timer(0.15).timeout
		if not view.is_fighting():
			break
		await create_timer(RoomView.AUDIT_DELAY + 0.3).timeout
	scene.player.run.health.heal(99)
	return view


func _test_room(scene, room: FloorRoom, mode: String) -> void:
	var view: RoomView = await _enter_and_clear(scene, room)
	var spots: Array[Vector2] = []
	if mode == "exact":
		spots = [Vector2(70, 70), Vector2(-70, 70)]
	elif mode == "band":
		# Harold in the floor row in front of the door (inward 16 is the row's top edge, -9 his feet
		# pressed on the wall), beside the door, as his body would look 20 to 40 px above the opening.
		for along in [23.0, 30.0, 70.0, -23.0, -70.0]:
			for inward in [-9.0, -4.0, 0.0, 6.0, 12.0, 16.0, 22.0]:
				spots.append(Vector2(along, inward))
	else:
		for along in [-130.0, -100.0, -70.0, -40.0, 0.0, 40.0, 70.0, 100.0, 130.0]:
			for inward in [40.0, 70.0, 100.0]:
				spots.append(Vector2(along, inward))
	var dirs := ["move_left", "move_right", "move_up", "move_down"]
	var door_count := view.doors().size()
	for door_i in door_count:
		for spot in spots:
			for dir in dirs:
				# A door into the Crossroads, walked through, chooses a path and builds another floor.
				if scene.is_over or room.id >= scene.debug_map().rooms.size() or scene.debug_map().room(room.id) != room:
					return
				view = await _enter_and_clear(scene, room)
				if door_i >= view.doors().size():
					continue
				var door: Door = view.doors()[door_i]
				if door.side() == Vector2i.ZERO:
					continue
				await _one_case(scene, room, view, door, spot, dir)


# Along runs with the wall (to the right for a south or north door), inward away from it.
func _spot_for(door: Door, spot: Vector2) -> Vector2:
	var side := Vector2(door.side())
	var inward := -side
	var along := Vector2(-side.y, side.x) if side.y == 0 else Vector2(1, 0)
	return door.global_position + along * spot.x + inward * spot.y


func _one_case(scene, room: FloorRoom, view: RoomView, door: Door, spot: Vector2, dir: String) -> void:
	var feet := _spot_for(door, spot)
	if room.layout.is_solid_at(WalkGrid.cell_of(feet)):
		return
	_cases += 1
	_enters.clear()
	var hooks: Array = []
	for d in view.doors():
		var hook := _on_entered.bind(d, scene)
		d.entered.connect(hook)
		hooks.append([d, hook])
	scene.player.velocity = Vector2.ZERO
	scene.player.global_position = feet - Player.FEET_OFFSET
	await create_timer(0.2).timeout
	if scene.debug_current_id() != room.id:
		print("CASE moved before input: room %d %s door side %s spot %s" % [room.id, room.layout.resource_path, str(door.side()), str(spot)])
	var start_feet: Vector2 = scene.player.feet().global_position
	_trace.clear()
	Input.action_press(dir)
	var t := 0.0
	while t < HOLD and scene.debug_current_id() == room.id and not scene.is_over:
		await physics_frame
		t += 1.0 / 60.0
	Input.action_release(dir)
	if OS.get_cmdline_user_args().has("verbose"):
		print("case room %d %s door %s spot %s %s: feet %s -> %s, room now %d, enters %d" % [room.id, room.layout.resource_path.get_file(), str(door.side()), str(spot), dir, str(start_feet), str(scene.player.feet().global_position), scene.debug_current_id(), _enters.size()])
	for pair in hooks:
		if is_instance_valid(pair[0]) and pair[0].entered.is_connected(pair[1]):
			pair[0].entered.disconnect(pair[1])
	for e in _enters:
		var dist: float = e["dist_feet"]
		var flag := "FAR" if dist > Door.ENTER_RADIUS or e["dist_ref"] > Door.ENTER_RADIUS else "ok"
		var expected := spot.length() < 40.0 and mode_is_sweep()
		if flag == "FAR":
			_bad += 1
		if flag == "FAR" or not expected:
			print("ENTER %s room %d %s %dx%d door side %s -> %d (%s) start feet %s spot %s held %s | door at %s feet %s ref %s same_ref %s armed %s near %s in_tree %s views_in_tree %d dist_feet %.1f dist_ref %.1f" % [flag, room.id, room.layout.resource_path.get_file(), room.layout.size_in_cells().x, room.layout.size_in_cells().y, str(e["side"]), e["target"], e["type"], str(start_feet), str(spot), dir, str(e["door_at"]), str(e["feet"]), str(e["ref_at"]), str(e["same_ref"]), str(e["armed"]), str(e["near"]), str(e["in_tree"]), e["views"], dist, e["dist_ref"]])
			var path: Array = []
			for i in range(0, _trace.size(), 6):
				path.append("%d:(%.0f,%.0f)r%d" % [_trace[i][0], _trace[i][1].x, _trace[i][1].y, _trace[i][2]])
			print("   path ", " ".join(path))
	await create_timer(0.05).timeout


func mode_is_sweep() -> bool:
	return OS.get_cmdline_user_args().has("sweep")


func _on_entered(target_id: int, door: Door, scene) -> void:
	var feet: Vector2 = scene.player.feet().global_position
	var ref: Node2D = door._player
	var views := 0
	for child in scene.get_children():
		if child is RoomView:
			views += 1
	_enters.append({
		"target": target_id,
		"type": scene.debug_map().room(target_id).room_type if target_id >= 0 and target_id < scene.debug_map().rooms.size() else "?",
		"side": door.side(),
		"door_at": door.global_position,
		"feet": feet,
		"ref_at": ref.global_position if is_instance_valid(ref) else Vector2.INF,
		"same_ref": ref == scene.player.feet(),
		"armed": door._armed,
		"near": door._near,
		"in_tree": door.is_inside_tree(),
		"views": views,
		"dist_feet": door.global_position.distance_to(feet),
		"dist_ref": door.global_position.distance_to(ref.global_position) if is_instance_valid(ref) else INF,
	})
