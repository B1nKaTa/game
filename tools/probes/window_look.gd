extends Node
# The window checks that need a normal run, since Settings leaves the window alone in --script runs:
# F11 and Alt+Enter with Options open (the draft follows, OK keeps it, Discard puts it back, a waiting
# key cell ignores it), a dragged window staying put while sliders move, display_log.txt written only on
# a real change, and the side bars through minimise and restore and back at the title.
# Never run it in the worktree. Add it as an autoload to an exported copy whose config/name is renamed
# (tools/probes/window_look.ps1 does that), then start that copy normally; it quits when done.

const OUT := "D:/grandpa-shots-ad/polish/"
const LOG := "user://display_log.txt"

var _lines: PackedStringArray = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(OUT)
	_run.call_deferred()


func _note(text: String) -> void:
	print("WINDOW " + text)
	_lines.append(text)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _state() -> String:
	var modes := {0: "windowed", 1: "minimized", 2: "maximized", 3: "fullscreen", 4: "exclusive"}
	return "%s size %s at %s" % [modes.get(DisplayServer.window_get_mode(), "?"), DisplayServer.window_get_size(), DisplayServer.window_get_position()]


func _log_info() -> String:
	if not FileAccess.file_exists(LOG):
		return "no display_log"
	var text := FileAccess.get_file_as_string(LOG)
	return "display_log modified %d first line '%s'" % [FileAccess.get_modified_time(LOG), text.split("\n")[0]]


func _key(code: Key, alt := false) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.alt_pressed = alt
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame


# The game's own picture, and the desktop round the window (to show where it stands and its bars).
func _shoot(shot_name: String, desktop := false) -> void:
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	image.save_png(OUT + shot_name + ".png")
	if desktop:
		var screen := DisplayServer.window_get_current_screen()
		var grab := DisplayServer.screen_get_image(screen)
		if grab != null:
			grab.save_png(OUT + shot_name + "_desktop.png")
	_note("shot %s (%s)" % [shot_name, _state()])


func _grab_window(shot_name: String) -> void:
	await get_tree().process_frame
	var grab := DisplayServer.screen_get_image_rect(Rect2i(DisplayServer.window_get_position(), DisplayServer.window_get_size()))
	if grab != null:
		grab.save_png(OUT + shot_name + ".png")
		var w := grab.get_width()
		var h := grab.get_height()
		_note("grab %s %dx%d left %s mid %s right %s" % [shot_name, w, h, grab.get_pixel(3, h / 2), grab.get_pixel(w / 2, h / 2), grab.get_pixel(w - 4, h / 2)])


func _panel() -> OptionsPanel:
	for node in get_tree().root.find_children("*", "", true, false):
		if node is OptionsPanel:
			return node
	return null


func _open_options() -> OptionsPanel:
	get_tree().current_scene.call("_choose", "options")
	await _wait(0.6)
	return _panel()


func _run() -> void:
	await _wait(3.0)
	_note("first window: %s; screen %d usable %s; %s" % [_state(), DisplayServer.window_get_current_screen(), DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen()), _log_info()])
	_note("build label '%s'" % BuildInfo.label())
	await _shoot("win_title_first", true)
	await _f11_in_options()
	await _steady_window()
	await _side_bars()
	var file := FileAccess.open(OUT + "window_log.txt", FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(_lines) + "\n")
	_note("DONE")
	get_tree().quit(0)


func _f11_in_options() -> void:
	var panel := await _open_options()
	if panel == null:
		_note("no options panel")
		return
	panel._show_tab(GameSettings.VIDEO)
	await _wait(0.3)
	await _shoot("options_before_f11")
	await _key(KEY_F11)
	await _wait(1.5)
	var toggle: Button = panel._toggles.get("fullscreen")
	_note("F11 in Options: %s, toggle '%s', draft %s, kept %s" % [_state(), toggle.text if toggle != null else "-", panel._draft.value(GameSettings.VIDEO, "fullscreen"), Settings.current.value(GameSettings.VIDEO, "fullscreen")])
	await _shoot("options_f11_fullscreen")
	await _key(KEY_F11)
	await _wait(1.5)
	_note("F11 again: %s, toggle '%s'" % [_state(), toggle.text if toggle != null else "-"])
	await _key(KEY_ENTER, true)
	await _wait(1.5)
	_note("Alt+Enter: %s, toggle '%s'" % [_state(), toggle.text if toggle != null else "-"])
	await _shoot("options_alt_enter_fullscreen")
	panel.leave()
	await _wait(0.4)
	await _shoot("options_discard_box")
	if panel._confirm != null:
		panel._confirm.chosen.emit(0)
	await _wait(1.5)
	_note("Discard: %s, kept fullscreen %s" % [_state(), Settings.current.value(GameSettings.VIDEO, "fullscreen")])
	await _shoot("options_after_discard", true)
	# A key cell waiting for a key: F11 must not switch the window.
	panel = await _open_options()
	panel._show_tab(GameSettings.INPUT)
	await _wait(0.3)
	panel._start_waiting("move_up")
	await _wait(0.2)
	await _key(KEY_F11)
	await _wait(1.0)
	_note("F11 while a key cell waits: %s, still waiting %s, move_up keys %s" % [_state(), panel._is_waiting(), InputMap.action_get_events("move_up").map(func(e): return e.as_text())])
	await _shoot("options_f11_while_waiting")
	if panel._is_waiting():
		panel._stop_waiting()
	# F11 then OK keeps fullscreen.
	panel._show_tab(GameSettings.VIDEO)
	await _key(KEY_F11)
	await _wait(1.5)
	panel._keep_and_close()
	await _wait(0.5)
	_note("F11 then OK: %s, kept fullscreen %s" % [_state(), Settings.current.value(GameSettings.VIDEO, "fullscreen")])
	# And F11 with Options closed switches back and keeps that.
	await _key(KEY_F11)
	await _wait(1.5)
	_note("F11 on the title: %s, kept fullscreen %s" % [_state(), Settings.current.value(GameSettings.VIDEO, "fullscreen")])


func _steady_window() -> void:
	var area := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var dragged := area.position + Vector2i(40, 60)
	DisplayServer.window_set_position(dragged)
	await _wait(1.0)
	_note("dragged to %s: %s; %s" % [dragged, _state(), _log_info()])
	var panel := await _open_options()
	panel._show_tab(GameSettings.VIDEO)
	await _wait(0.3)
	var before := FileAccess.get_modified_time(LOG)
	var sliders := panel.find_children("*", "HSlider", true, false)
	_note("video sliders %d" % sliders.size())
	for slider: HSlider in sliders:
		slider.value = slider.value + slider.step * 3.0
		await _wait(0.3)
	await _wait(1.5)
	panel._show_tab(GameSettings.AUDIO)
	await _wait(0.3)
	for slider: HSlider in panel.find_children("*", "HSlider", true, false):
		slider.value = slider.min_value + (slider.max_value - slider.min_value) * 0.4
		await _wait(0.3)
	await _wait(1.2)
	var after := FileAccess.get_modified_time(LOG)
	_note("after slider moves: %s; still at the dragged spot %s; display_log rewritten %s" % [_state(), DisplayServer.window_get_position() == dragged, after != before])
	await _shoot("window_dragged_after_sliders", true)
	# A resolution change re-centres it and writes the log.
	panel._show_tab(GameSettings.VIDEO)
	await _wait(0.3)
	var choices: Array = Settings.resolution_choices()
	var now := DisplayServer.window_get_size()
	var other: Vector2i = choices[0]
	for size: Vector2i in choices:
		if size != now:
			other = size
	panel._draft.set_value(GameSettings.VIDEO, "resolution", GameSettings.resolution_text(other))
	Settings.apply(panel._draft)
	await _wait(2.2)
	_note("resolution %s: %s; display_log rewritten %s" % [other, _state(), FileAccess.get_modified_time(LOG) != after])
	await _shoot("window_after_resolution", true)
	panel.leave()
	await _wait(0.3)
	if panel._confirm != null:
		panel._confirm.chosen.emit(0)
	await _wait(1.5)
	_note("discarded back: %s" % _state())


func _side_bars() -> void:
	# A wide window, so the picture has bars beside it, in a run on the parlour.
	var area := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	DisplayServer.window_set_size(Vector2i(mini(1800, area.size.x - 40), 700))
	DisplayServer.window_set_position(area.position + Vector2i(20, 40))
	await _wait(1.0)
	await _grab_window("bars_title_wide_before_run")
	var palette: RoomPalette = load("res://data/floors/funeral_parlour.tres").room_palette()
	get_tree().change_scene_to_file("res://scenes/floor.tscn")
	await _wait(2.5)
	_note("in a run: scene %s" % get_tree().current_scene.name if get_tree().current_scene != null else "none")
	await _grab_window("bars_in_run")
	SideBars.show_for(palette)
	await _wait(0.5)
	await _grab_window("bars_in_run_parlour")
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
	await _wait(1.5)
	_note("minimised: %s" % _state())
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	await _wait(1.5)
	_note("restored: %s" % _state())
	await _grab_window("bars_after_restore")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title.tscn")
	await _wait(2.0)
	await _grab_window("bars_back_at_title")
