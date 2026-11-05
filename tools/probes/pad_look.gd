extends SceneTree
# Opens a real window and saves screenshots of the controller support: the Input tab with both columns
# in Xbox-style and PlayStation-style names, prompts in both namings and on the keyboard, and the gold
# focus highlight on the title screen, a merchant panel, the bounty board and a card table. The pad is
# driven by synthetic joypad events, as the full loop drives it.
# Run only from an exported copy whose config/name is renamed.

const OUT := "D:/grandpa-verify-pad/shots/"
const WALL_LIMIT_MS := 200000

var _start := 0
var progress
# The family the shots are named in. A real pad plugged into this machine would otherwise name it.
var _family := PadInput.XBOX


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


func _shot(shot_name: String) -> void:
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	image.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	image.save_png(OUT + shot_name + ".png")
	print("shot " + shot_name)


func _pad(button: int) -> void:
	await process_frame
	var down := InputEventJoypadButton.new()
	down.button_index = button as JoyButton
	down.pressed = true
	# Xbox-style shots come from a device id with nothing plugged in, which reads as Xbox-style; the
	# PlayStation ones from pad 0, a DualSense on this machine.
	down.device = 7 if _family == PadInput.XBOX else 0
	Input.parse_input_event(down)
	await physics_frame
	await physics_frame
	var up := InputEventJoypadButton.new()
	up.button_index = button as JoyButton
	up.device = down.device
	Input.parse_input_event(up)
	await physics_frame
	ActiveDevice.family = _family
	await process_frame


func _use_pad(family: String) -> void:
	_family = family
	await _pad(JOY_BUTTON_Y)


func _use_keys() -> void:
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F10
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	var up := InputEventKey.new()
	up.physical_keycode = KEY_F10
	Input.parse_input_event(up)
	await process_frame


func _scene_named(wanted: String) -> Node:
	for i in 200:
		var scene := current_scene
		if scene != null and scene.name == wanted:
			return scene
		await process_frame
	print("PROBE FAIL no scene " + wanted)
	return null


func _main() -> void:
	await process_frame
	print("pads connected: %s, pad 0 is '%s'" % [str(Input.get_connected_joypads()), Input.get_joy_name(0)])
	progress = root.get_node("Progress")
	progress._store = SaveStore.new("user://look_save.json")
	progress._store.delete_all()
	progress.reload()
	progress.data.opening_seen = true
	progress.data.floors_cleared = 1
	progress.data.record_floor_cleared(2, "sunset_shores")
	progress.data.record_floor_cleared(3, "golden_years_mall")
	progress.data.pension = 900
	progress.data.condolences = 40
	await _title()
	await _waiting_room()
	print("PROBE DONE")
	quit(0)


func _title() -> void:
	change_scene_to_file("res://scenes/title.tscn")
	var title := await _scene_named("Title")
	if title == null:
		return
	await _wait(1.0)
	await _use_pad(PadInput.XBOX)
	await _wait(0.3)
	await _pad(JOY_BUTTON_DPAD_DOWN)
	await _wait(0.3)
	await _shot("title_focus_pad")
	title._choose("options")
	await _wait(0.5)
	for i in 3:
		await _pad(JOY_BUTTON_RIGHT_SHOULDER)
		await _wait(0.2)
	await _pad(JOY_BUTTON_DPAD_RIGHT)
	await _wait(0.3)
	await _shot("input_tab_xbox")
	_family = PadInput.PLAYSTATION
	ActiveDevice.family = _family
	await _pad(JOY_BUTTON_LEFT_SHOULDER)
	await _wait(0.2)
	await _pad(JOY_BUTTON_RIGHT_SHOULDER)
	_family = PadInput.PLAYSTATION
	ActiveDevice.family = _family
	await _wait(0.3)
	await _shot("input_tab_playstation")
	await _pad(JOY_BUTTON_LEFT_SHOULDER)
	await _wait(0.3)
	await _shot("game_tab_pad")
	await _pad(JOY_BUTTON_B)
	await _wait(0.5)
	await _shot("title_after_options")


func _waiting_room() -> void:
	change_scene_to_file("res://scenes/waiting_room.tscn")
	var scene := await _scene_named("WaitingRoom")
	if scene == null:
		return
	await _wait(1.0)
	scene.debug_enter_department(Departments.LOBBY)
	var station = scene.station("black_market")
	scene.player.global_position = station.global_position + Vector2(0, RoomBackdrop.TILE) - Player.FEET_OFFSET
	await _use_keys()
	await _wait(0.4)
	await _shot("prompt_keyboard")
	await _use_pad(PadInput.XBOX)
	await _wait(0.4)
	await _shot("prompt_xbox")
	_family = PadInput.PLAYSTATION
	ActiveDevice.family = _family
	await _wait(0.4)
	await _shot("prompt_playstation")
	_family = PadInput.XBOX
	ActiveDevice.family = _family
	await _pad(JOY_BUTTON_X)
	await _wait(0.4)
	await _pad(JOY_BUTTON_DPAD_DOWN)
	await _wait(0.3)
	await _shot("merchant_focus")
	await _use_keys()
	await _wait(0.3)
	await _shot("merchant_keyboard")
	await _use_pad(PadInput.XBOX)
	await _pad(JOY_BUTTON_B)
	await _wait(0.3)
	scene.debug_enter_department(Departments.BOUNTY_OFFICE)
	await _wait(0.3)
	scene.use_station("bounty_board")
	await _wait(0.4)
	await _pad(JOY_BUTTON_DPAD_DOWN)
	await _wait(0.3)
	await _shot("bounty_focus")
	await _pad(JOY_BUTTON_B)
	await _wait(0.3)
	scene.debug_enter_department(Departments.BACK_ROOM)
	await _wait(0.4)
	var tables: Array = scene.debug_room_view().arcade_tables()
	for table in tables:
		if table.game == "blackjack":
			scene._open_card_table(table)
	await _wait(0.4)
	await _pad(JOY_BUTTON_DPAD_RIGHT)
	await _wait(0.3)
	await _shot("card_table_focus")
	await _pad(JOY_BUTTON_B)
	await _wait(0.3)
