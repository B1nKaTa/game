extends SceneTree
# Opens a real window and shoots the lobby's ticket line: counting on (Harold's 042, serving 041), and
# the one served moment after a run that reached an ending ("Now serving: you.").
# Run only from an exported copy whose config/name is renamed. Args after --: optionally the folder.

const DEFAULT_OUT := "D:/grandpa-shots-ad/ticket/"
const WALL_LIMIT_MS := 120000
const LINE_CROP := Rect2i(300, 0, 340, 22)

var OUT := DEFAULT_OUT
var _start := 0
var progress


func _initialize() -> void:
	_start = Time.get_ticks_msec()
	var user_args := OS.get_cmdline_user_args()
	if user_args.size() > 0:
		OUT = user_args[0].trim_suffix("/") + "/"
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


func _shot(shot_name: String) -> void:
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	image.save_png(OUT + shot_name + ".png")
	var crop := image.get_region(LINE_CROP.intersection(Rect2i(Vector2i.ZERO, image.get_size())))
	crop.resize(crop.get_width() * 3, crop.get_height() * 3, Image.INTERPOLATE_NEAREST)
	crop.save_png(OUT + shot_name + "_line.png")
	print("shot %s %s" % [shot_name, image.get_size()])


func _open_lobby() -> void:
	progress.last_run = {}
	change_scene_to_file("res://scenes/waiting_room.tscn")
	await _wait(1.6)


func _main() -> void:
	await process_frame
	progress = root.get_node("Progress")
	progress._store = SaveStore.new("user://look_save.json")
	progress._store.delete_all()
	progress.reload()
	var data: ProgressData = progress.data
	data.opening_seen = true
	for entry in Departments.ALL:
		data.departments_seen[entry["id"]] = true
	data.run_count = 41
	data.ticket_called = 41
	await _open_lobby()
	print("LINE counting: %s" % current_scene.lobby_ticket_line())
	await _shot("lobby_ticket_line")
	# Run 42 reaches an ending: the next arrival serves his own number, once.
	data.start_run()
	data.ticket_called = data.run_count
	data.record_ending(EndingRules.BRIEFLY_ALIVE)
	await _open_lobby()
	print("LINE served: %s" % current_scene.lobby_ticket_line())
	print("PENDING after: %s" % data.serve_pending())
	await _shot("lobby_served_payoff")
	await _open_lobby()
	print("LINE next visit: %s" % current_scene.lobby_ticket_line())
	progress._store.delete_all()
	print("LOOK DONE")
	quit(0)
