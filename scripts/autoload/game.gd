extends Node

const OPENING_SCENE := "res://scenes/opening.tscn"
const WAITING_SCENE := "res://scenes/waiting_room.tscn"
const FLOOR_SCENE := "res://scenes/floor.tscn"


func _ready() -> void:
	InputSetup.ensure()
	KeyBindings.load_from()
	if OS.get_cmdline_user_args().has("--smoke"):
		var driver: Node = load("res://tools/smoke_driver.gd").new()
		add_child(driver)


func start() -> void:
	if Progress.data.opening_seen:
		return_to_waiting()
	else:
		get_tree().change_scene_to_file(OPENING_SCENE)


func finish_opening() -> void:
	Progress.mark_opening_seen()
	return_to_waiting()


func begin_run() -> void:
	get_tree().change_scene_to_file(FLOOR_SCENE)


# Debug builds only: a fresh run on the Floor 3 landing with everything bought. See DevStart.
func begin_dev_run() -> void:
	if not DevStart.is_available():
		return
	Progress.begin_dev_run(DevStart.progress(Content.upgrades(), Content.recipes()))
	begin_run()


# Debug builds only: the Waiting Room again under a throwaway profile with every department open, or,
# when a dev profile is already on, the real Waiting Room again with the real progress as it was. Only
# the dev Waiting Room can have a dev profile on in the Waiting Room, since return_to_waiting ends any
# other. See DevStart.
func toggle_dev_waiting_room() -> void:
	if not DevStart.is_available():
		return
	# The scene being left still runs until the change, so it is stopped first: nothing in it can save
	# into whichever progress is swapped in.
	var leaving := get_tree().current_scene
	if leaving != null:
		leaving.process_mode = Node.PROCESS_MODE_DISABLED
	if Progress.is_dev_run():
		Progress.end_dev_run()
	else:
		Progress.begin_dev_run(DevStart.progress(Content.upgrades(), Content.recipes(), true))
	get_tree().change_scene_to_file(WAITING_SCENE)


# A dev run ends here however it ended, so its progress is gone before the Waiting Room reads any. A
# run started from the dev Waiting Room is a dev run on its profile, so it ends here too.
func return_to_waiting() -> void:
	Progress.end_dev_run()
	get_tree().change_scene_to_file(WAITING_SCENE)
