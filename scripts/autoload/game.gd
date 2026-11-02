extends Node

const OPENING_SCENE := "res://scenes/opening.tscn"
const WAITING_SCENE := "res://scenes/waiting_room.tscn"
const FLOOR_SCENE := "res://scenes/floor.tscn"


func _ready() -> void:
	InputSetup.ensure()
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


func return_to_waiting() -> void:
	get_tree().change_scene_to_file(WAITING_SCENE)
