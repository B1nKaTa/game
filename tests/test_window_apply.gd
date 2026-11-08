extends TestCase

# The window is set up only when its own settings change, F11 inside Options changes the panel's draft,
# and the display log and the bars beside the picture follow real changes only. Settings and
# OptionsPanel name autoloads, so they are read as source text (see LESSONS).


func _source(path: String) -> String:
	return FileAccess.get_file_as_string(path).replace("\r", "")


func _body(source: String, header: String) -> String:
	var start := source.find(header)
	var next := source.find("\nfunc ", start + header.length())
	return source.substr(start, (next if next > 0 else source.length()) - start)


func test_only_the_window_keys_set_up_the_window() -> void:
	var settings := GameSettings.new()
	var before := GameSettings.window_keys(settings)
	for key in ["brightness", "contrast", "gamma", "vsync", "confine_mouse"]:
		var next := settings.duplicate_settings()
		var now: Variant = next.value(GameSettings.VIDEO, key)
		next.set_value(GameSettings.VIDEO, key, (not now) if now is bool else now + 1)
		assert_eq(GameSettings.window_keys(next), before, key + " leaves the window alone")
	for key in ["fullscreen", "pixel_perfect"]:
		var next := settings.duplicate_settings()
		next.set_value(GameSettings.VIDEO, key, not next.value(GameSettings.VIDEO, key))
		assert_true(GameSettings.window_keys(next) != before, key + " sets the window up again")
	var sized := settings.duplicate_settings()
	sized.set_value(GameSettings.VIDEO, "resolution", "1920x1080")
	settings.set_value(GameSettings.VIDEO, "resolution", "1280x720")
	assert_true(GameSettings.window_keys(sized) != GameSettings.window_keys(settings), "resolution sets the window up again")


func test_a_slider_tick_never_moves_the_window() -> void:
	var video := _body(_source("res://scripts/autoload/settings.gd"), "func _apply_video(")
	var gate := video.find("if keys == _window_keys:")
	assert_true(gate > 0, "it compares the window keys with what it applied")
	assert_true(video.find("window_set_size(") > gate and video.find("window_set_position(") > gate and video.find("window_set_mode(") > gate)
	assert_true(video.contains("if resized or not was_windowed:"), "a dragged window is placed again only when its size or mode changed")


func test_the_display_log_follows_real_changes_only() -> void:
	var source := _source("res://scripts/autoload/settings.gd")
	assert_false(source.contains("_log_display.call_deferred()"), "never on every apply")
	assert_true(source.contains("_log_display_if_changed.call_deferred()"))
	var guard := _body(source, "func _log_display_if_changed(")
	assert_true(guard.contains("window_get_mode()") and guard.contains("window_get_size()") and guard.contains("if now == _logged_window:"))


func test_f11_in_options_changes_the_draft() -> void:
	var settings := _source("res://scripts/autoload/settings.gd")
	var keys := _body(settings, "func _input(")
	assert_true(keys.find("fullscreen_asked.emit()") > 0 and keys.find("fullscreen_asked.emit()") < keys.find("commit(next)"), "a listening panel is asked first")
	var panel := _source("res://scripts/ui/options_panel.gd")
	assert_true(panel.contains("Settings.fullscreen_asked.connect(_toggle_fullscreen)"))
	assert_true(_body(panel, "func _exit_tree(").contains("Settings.fullscreen_asked.disconnect(_toggle_fullscreen)"), "a closed panel stops listening")
	var toggle := _body(panel, "func _toggle_fullscreen(")
	assert_true(toggle.contains("_draft.set_value(GameSettings.VIDEO, \"fullscreen\""), "it changes the draft")
	assert_true(toggle.contains("toggle.text = _on_off("), "and the toggle's text")
	assert_false(toggle.contains("commit("), "OK or Esc decides, as for the toggle")
