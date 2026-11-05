extends SceneTree
# Opens a real window and saves screenshots of the endings: every scene at four moments on one sheet,
# Repeat Customer's five quick deaths, Augustine's scene, the Ending Archive empty and full, a replay
# from it, and the Lobby with Gerald beside Harold under the trophy wall's count.
# Run only from an exported copy whose config/name is renamed. Args after --: scenes | rooms | all

const OUT := "D:/grandpa-look-endings/"
const WALL_LIMIT_MS := 280000
const FRAME := 1.0 / 60.0
const S := preload("res://scripts/core/cutscene_steps.gd")
# The moments of a long scene shown on its sheet, as shares of its length, and the cause card last.
const MOMENTS := [0.22, 0.48, 0.72]

var _start := 0
var progress


func _initialize() -> void:
	_start = Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(OUT)
	_main.call_deferred()


func _process(_d: float) -> bool:
	if Time.get_ticks_msec() - _start > WALL_LIMIT_MS:
		print("PROBE TIMEOUT")
		quit(3)
	return false


func _wait(seconds: float) -> void:
	var began := Time.get_ticks_msec()
	while Time.get_ticks_msec() - began < seconds * 1000.0:
		await process_frame


func _grab() -> Image:
	await process_frame
	await process_frame
	return root.get_texture().get_image()


func _save(image: Image, shot_name: String) -> void:
	image.save_png(OUT + shot_name + ".png")
	print("shot " + shot_name)


func _shot(shot_name: String) -> void:
	var image := await _grab()
	image.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	_save(image, shot_name)


# Four 640x360 frames on one 1280x720 sheet, left to right and top to bottom.
func _sheet(frames: Array, shot_name: String) -> void:
	var sheet := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	for i in frames.size():
		var frame: Image = frames[i]
		frame.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(frame, Rect2i(0, 0, 640, 360), Vector2i((i % 2) * 640, (i / 2) * 360))
	_save(sheet, shot_name)


func _main() -> void:
	await process_frame
	progress = root.get_node("Progress")
	progress._store = SaveStore.new("user://look_save.json")
	progress._store.delete_all()
	progress.reload()
	var args := OS.get_cmdline_user_args()
	var which: String = args[0] if args.size() > 0 else "all"
	if which == "all" or which == "scenes":
		await _scenes()
	if which == "all" or which == "rooms":
		await _rooms()
	progress._store.delete_all()
	print("LOOK DONE")
	quit(0)


# Steps a scene by hand to a time, so each shot is at the same moment every run.
func _play_to(player: CutscenePlayer, seconds: float) -> void:
	var stepped := 0.0
	while stepped < seconds and not player.is_done():
		player.advance(FRAME, false, false)
		stepped += FRAME


func _scene_sheet(steps: Array, shot_name: String, moments: Array) -> void:
	var length := S.duration_of(steps)
	var frames := []
	for share: float in moments:
		var player := CutscenePlayer.new()
		player.setup(steps, false)
		root.add_child(player)
		player.set_process(false)
		await process_frame
		await _play_to(player, length * share)
		frames.append(await _grab())
		player.queue_free()
		await process_frame
	# The last frame is the cause of death, half way through its card.
	var last := CutscenePlayer.new()
	last.setup(steps, false)
	root.add_child(last)
	last.set_process(false)
	await process_frame
	var card_at := length - S.card_time(_last_card(steps)) * 0.5 - float(steps[steps.size() - 1]["seconds"])
	await _play_to(last, card_at)
	frames.append(await _grab())
	last.queue_free()
	await process_frame
	await _sheet(frames, shot_name)


func _last_card(steps: Array) -> String:
	var text := ""
	for step: Dictionary in steps:
		if step["op"] == "card":
			text = step["text"]
	return text


func _scenes() -> void:
	var number := 1
	for entry: Dictionary in EndingRules.ALL:
		var id: String = entry["id"]
		if id == EndingRules.REPEAT_CUSTOMER:
			for n in range(1, EndingRules.REPEAT_DEATHS + 1):
				await _scene_sheet(S.for_ending(id, n), "%02d_repeat_death_%d" % [entry["number"], n], [0.08, 0.2, 0.32])
		else:
			await _scene_sheet(S.for_ending(id), "%02d_%s" % [entry["number"], id], MOMENTS)
		number += 1
	await _scene_sheet(S.for_ending(EndingRules.AUGUSTINE, 0), "12_augustine_full", [0.25, 0.55, 0.8])
	# Augustine's scenes end on a fade, not a card, so its fourth frame is just before the fade.


# --- the Waiting Room: the archive empty and full, a replay, and Gerald in the Lobby ---

func _waiting(found: Dictionary) -> Node:
	var data: ProgressData = progress.data
	data.opening_seen = true
	data.record_floor_cleared(5, "head_office")
	data.departments_seen = {}
	for id in Departments.ALL:
		data.departments_seen[id["id"]] = true
	data.endings_found = found.duplicate()
	data.repeat_deaths_seen = {"2": true, "4": true}
	progress.last_run = {}
	change_scene_to_file("res://scenes/waiting_room.tscn")
	await _wait(0.4)
	return current_scene


func _open_archive(scene: Node) -> CanvasLayer:
	scene.debug_enter_department(Departments.EXECUTIVE_SUITE)
	await _wait(0.2)
	scene.player.global_position = RoomBackdrop.cell_center(Vector2i(14, 8)) - Player.FEET_OFFSET
	await _wait(0.3)
	scene.use_station("ending_archive")
	await _wait(0.3)
	return scene.open_panel()


func _rooms() -> void:
	var scene := await _waiting({})
	scene.player.global_position = RoomBackdrop.cell_center(Vector2i(14, 8)) - Player.FEET_OFFSET
	scene.debug_enter_department(Departments.EXECUTIVE_SUITE)
	await _wait(0.2)
	scene.player.global_position = RoomBackdrop.cell_center(Vector2i(14, 8)) - Player.FEET_OFFSET
	await _wait(0.4)
	await _shot("20_executive_suite_cabinet")
	var panel := await _open_archive(scene)
	print("archive open: %s" % str(panel != null))
	await _shot("21_archive_empty")
	var all := {}
	for entry: Dictionary in EndingRules.ALL:
		all[entry["id"]] = true
	scene = await _waiting(all)
	panel = await _open_archive(scene)
	await _shot("22_archive_full")
	if panel != null:
		var scroll: ScrollContainer = _find(panel, "ScrollContainer")
		if scroll != null:
			scroll.scroll_vertical = 1000
			await _wait(0.2)
			await _shot("23_archive_full_scrolled")
		panel.call("replay", EndingRules.EXCESS_BAGGAGE)
		await _wait(6.0)
		await _shot("24_archive_replay")
		var replaying = panel.call("replay_scene")
		if replaying != null:
			replaying.call("_finish")
		await _wait(0.4)
		await _shot("25_archive_after_replay")
	# The Lobby with Gerald, Harold in Gerald's hat, and the trophy wall's count.
	progress.data.cosmetics_owned[ProgressData.GERALDS_HAT] = true
	progress.data.cosmetics_worn["hat"] = ProgressData.GERALDS_HAT
	scene = await _waiting({"eternal_feud": true, "literally": true, "briefly_alive": true})
	progress.last_run = {}
	scene.player.global_position = RoomBackdrop.cell_center(Vector2i(19, 5)) - Player.FEET_OFFSET
	await _wait(0.6)
	await _shot("26_lobby_gerald")
	for npc in get_nodes_in_group("npcs"):
		if npc.def != null and npc.def.id == "gerald":
			npc.talk()
	await _wait(0.3)
	await _shot("27_lobby_gerald_talks")
	scene.player.global_position = RoomBackdrop.cell_center(Vector2i(14, 5)) - Player.FEET_OFFSET
	for npc in get_nodes_in_group("npcs"):
		if npc.def != null and npc.def.id == "gerald":
			npc.say_moment("died")
	await _wait(0.6)
	await _shot("28_lobby_gerald_from_the_left")
	scene.use_station("trophy_wall")
	scene.player.global_position = RoomBackdrop.cell_center(Vector2i(20, 4)) - Player.FEET_OFFSET
	await _wait(0.5)
	await _shot("29_lobby_trophy_wall_count")


func _find(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name:
		return node
	for child in node.get_children():
		var found := _find(child, type_name)
		if found != null:
			return found
	return null
