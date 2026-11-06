extends SceneTree
# Opens a real window with vsync off and no frame cap, walks into a large combat room on each floor
# asked for, lets the fight run, and prints the frame time and FPS it measured, with the engine's own
# monitors (process, physics, draw calls, objects, nodes). Harold is healed every frame so the fight
# never ends early. Run only from an exported copy whose config/name is renamed.
# Args after --: floor ids, comma separated (default floor_1,seance_hotline).

const WALL_LIMIT_MS := 240000
const WARM_MS := 2000
const MEASURE_MS := 6000
const FLOORS := {
	"floor_1": [1, 0], "cemetery": [1, 1], "sunset_shores": [2, 0], "furnace_works": [2, 1],
	"funeral_parlour": [3, 0], "flashback_cinema": [3, 1], "last_resort_cruise": [4, 0], "seance_hotline": [4, 1],
	"terminal_zero": [5, 0], "head_office": [5, 1],
}

var _start := 0
var scene
var player: Player
var progress


func _initialize() -> void:
	_start = Time.get_ticks_msec()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	_main.call_deferred()


func _process(_d: float) -> bool:
	if Time.get_ticks_msec() - _start > WALL_LIMIT_MS:
		print("PROBE TIMEOUT")
		quit(3)
	if player != null and is_instance_valid(player):
		player.run.health.heal(99)
	return false


func _wait(seconds: float) -> void:
	var began := Time.get_ticks_msec()
	while Time.get_ticks_msec() - began < seconds * 1000.0:
		await process_frame


func _main() -> void:
	await process_frame
	progress = root.get_node("Progress")
	progress._store = SaveStore.new("user://perf_save.json")
	progress._store.delete_all()
	progress.reload()
	progress.data.floors_cleared = 1
	progress.data.record_floor_cleared(2, "sunset_shores")
	progress.data.record_floor_cleared(3, "funeral_parlour")
	progress.data.record_floor_cleared(4, "last_resort_cruise")
	progress.data.record_floor_cleared(5, "terminal_zero")
	var args := OS.get_cmdline_user_args()
	var which: PackedStringArray = (args[0] if args.size() > 0 else "floor_1,seance_hotline").split(",")
	for floor_id in which:
		await _measure(floor_id)
	progress._store.delete_all()
	print("PERF DONE")
	quit(0)


func _measure(floor_id: String) -> void:
	change_scene_to_file("res://scenes/floor.tscn")
	await _wait(0.4)
	scene = current_scene
	player = scene.player
	scene._depth = FLOORS[floor_id][0]
	scene.debug_choose_path(FLOORS[floor_id][1])
	await _wait(0.3)
	if scene.debug_floor_def().id != floor_id:
		print("WRONG FLOOR for %s" % floor_id)
		return
	for enemy in get_nodes_in_group("enemies"):
		enemy.dismiss()
	var dir: String = scene.debug_floor_def().rooms_dir
	var file := ""
	for name in DirAccess.get_files_at(dir):
		if name.begins_with("combat_large") and name.ends_with(".tres"):
			file = dir.path_join(name)
			break
	var layout: RoomLayout = (load(file) as RoomLayout).duplicate()
	var map: FloorMap = scene.debug_map()
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.cell = Vector2i(70 + room.id, 70)
	room.room_type = RoomLayout.TYPE_COMBAT
	room.layout = layout
	room.decor_seed = 7
	map.rooms.append(room)
	scene._enter_room(room.id)
	var size := layout.size_in_cells()
	player.global_position = RoomBackdrop.cell_center(layout.nearest_floor_cell(size / 2)) - Player.FEET_OFFSET
	# The frames right after the room is built: spawning enemies, lights and shaders shows here.
	var began := Time.get_ticks_msec()
	var entry_worst := 0.0
	var entry_last := Time.get_ticks_usec()
	while Time.get_ticks_msec() - began < WARM_MS:
		await process_frame
		var entry_now := Time.get_ticks_usec()
		entry_worst = maxf(entry_worst, (entry_now - entry_last) / 1000.0)
		entry_last = entry_now
	var frames := 0
	var worst := 0.0
	var proc_sum := 0.0
	var phys_sum := 0.0
	var draws_sum := 0.0
	var last := Time.get_ticks_usec()
	var first := last
	while Time.get_ticks_usec() - first < MEASURE_MS * 1000:
		await process_frame
		var now := Time.get_ticks_usec()
		var dt := (now - last) / 1000.0
		last = now
		worst = maxf(worst, dt)
		frames += 1
		proc_sum += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		phys_sum += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		draws_sum += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var total_ms := (last - first) / 1000.0
	var lights := 0
	for node in scene.debug_room_view().get_children():
		if node is PointLight2D:
			lights += 1
	print("PERF %s room %s enemies %d lights %d: fps %.1f frame %.2f ms worst %.2f ms entry worst %.2f ms process %.2f ms physics %.2f ms draws %.0f objects %d nodes %d" % [
		floor_id, file.get_file(), get_nodes_in_group("enemies").size(), lights, frames / (total_ms / 1000.0), total_ms / frames, worst, entry_worst,
		proc_sum / frames, phys_sum / frames, draws_sum / frames, Performance.get_monitor(Performance.OBJECT_COUNT),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
