extends Node

const OPENING_SCENE := "res://scenes/opening.tscn"
const WAITING_SCENE := "res://scenes/waiting_room.tscn"
const FLOOR_SCENE := "res://scenes/floor.tscn"
const TITLE_SCENE := "res://scenes/title.tscn"


func _ready() -> void:
	InputSetup.ensure()
	KeyBindings.load_from()
	if OS.get_cmdline_user_args().has("--smoke"):
		var driver: Node = load("res://tools/smoke_driver.gd").new()
		add_child(driver)


# After the boot scene: the title screen, except in the full loop, which goes straight in.
func start() -> void:
	if OS.get_cmdline_user_args().has("--smoke"):
		enter_slot()
	else:
		get_tree().change_scene_to_file(TITLE_SCENE)


# Into the selected slot: the opening for a slot that has never seen it, otherwise the Waiting Room.
func enter_slot() -> void:
	if Progress.data.opening_seen:
		return_to_waiting()
	else:
		get_tree().change_scene_to_file(OPENING_SCENE)


# The title's Continue: the last used slot, resuming its run if one was interrupted.
func continue_game() -> void:
	var slot := SaveSlots.continue_slot(Progress.ROOT)
	if slot == 0:
		return
	resume_slot(slot)


# A slot's interrupted run if it has one, otherwise the slot itself.
func resume_slot(slot: int) -> void:
	Progress.select_slot(slot)
	if not Progress.read_checkpoint().is_empty():
		resume_run()
	else:
		enter_slot()


# New Game on a slot: whatever it held is gone, and the opening plays.
func new_game(slot: int) -> void:
	Progress.clear_slot(slot)
	Progress.select_slot(slot)
	enter_slot()


func load_game(slot: int) -> void:
	Progress.select_slot(slot)
	enter_slot()


# Load Game on a slot with an interrupted run, choosing to give it up: it ends as a death would, for
# income and the ticket, and the Waiting Room follows.
func abandon_and_load(slot: int) -> void:
	Progress.select_slot(slot)
	var checkpoint := Progress.read_checkpoint()
	if not checkpoint.is_empty():
		var run := Progress.make_run()
		RunCheckpoint.apply_run(run, checkpoint.get("run", {}), Content.items())
		var parachute := run.parachute_pay(int(checkpoint.get("run_earned", 0)))
		if parachute > 0:
			Progress.add_pension(parachute)
		Progress.last_run = {"died": true, "bosses": int(checkpoint.get("bosses", 0))}
		Progress.clear_checkpoint()
	enter_slot()


# The floor scene reads Progress.resume and rebuilds the run from it instead of starting one.
func resume_run() -> void:
	var checkpoint := Progress.read_checkpoint()
	if checkpoint.is_empty():
		enter_slot()
		return
	Progress.resume = checkpoint
	get_tree().change_scene_to_file(FLOOR_SCENE)


# From the pause menu. Any dev profile ends, so the title always shows the real slots.
func quit_to_title() -> void:
	get_tree().paused = false
	Progress.end_dev_run()
	get_tree().change_scene_to_file(TITLE_SCENE)


func finish_opening() -> void:
	Progress.mark_opening_seen()
	return_to_waiting()


func begin_run() -> void:
	get_tree().change_scene_to_file(FLOOR_SCENE)


# Debug builds only: a fresh run on the landing of start_depth (3 for F3, 4 for F5, 5 for F6) with
# everything bought and every floor above it cleared. See DevStart.
func begin_dev_run(start_depth := DevStart.START_DEPTH) -> void:
	if not DevStart.is_available():
		return
	Progress.begin_dev_run(DevStart.progress(Content.upgrades(), Content.recipes(), false, start_depth), Progress.DEV_PATH, start_depth)
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
