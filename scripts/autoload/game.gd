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


# A dev run ends here however it ended, so its progress is gone before the Waiting Room reads any.
func return_to_waiting() -> void:
	Progress.end_dev_run()
	get_tree().change_scene_to_file(WAITING_SCENE)
