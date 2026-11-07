extends TestCase

# Every file here lives in the system temp folder, never in the game's user folder.
const FILE := "grandpa_test_settings.cfg"


func _path() -> String:
	return OS.get_temp_dir().path_join(FILE)


func _clean() -> void:
	if FileAccess.file_exists(_path()):
		DirAccess.remove_absolute(_path())


func _write(text: String) -> void:
	var file := FileAccess.open(_path(), FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_defaults_match_the_spec() -> void:
	var s := GameSettings.new()
	assert_eq(s.value(GameSettings.VIDEO, "brightness"), 0)
	assert_eq(s.value(GameSettings.VIDEO, "contrast"), 0)
	assert_eq(s.value(GameSettings.VIDEO, "gamma"), 0)
	assert_eq(s.value(GameSettings.VIDEO, "fullscreen"), false)
	assert_eq(s.value(GameSettings.VIDEO, "vsync"), true)
	assert_eq(s.value(GameSettings.VIDEO, "confine_mouse"), true)
	assert_eq(s.value(GameSettings.VIDEO, "pixel_perfect"), true)
	assert_eq(s.value(GameSettings.AUDIO, "master"), 100)
	assert_eq(s.value(GameSettings.AUDIO, "effects"), 80)
	assert_eq(s.value(GameSettings.AUDIO, "music"), 70)
	assert_eq(s.value(GameSettings.AUDIO, "ambience"), 70)
	assert_eq(s.value(GameSettings.GAME, "screen_shake"), true)
	assert_eq(s.value(GameSettings.GAME, "hit_stop"), true)
	assert_eq(s.value(GameSettings.GAME, "vibration"), true)
	assert_eq(s.value(GameSettings.GAME, "heal_at_full"), false)
	assert_eq(s.value(GameSettings.GAME, "mouse_aim"), true)
	assert_eq(s.value(GameSettings.GAME, "hide_minimap_in_combat"), false)
	assert_eq(s.value(GameSettings.GAME, "minimap_opacity"), 100)
	assert_eq(s.value(GameSettings.GAME, "run_timer"), false)
	assert_eq(s.value(GameSettings.GAME, "language"), "en")


func test_the_resolution_default_is_a_1080p_window() -> void:
	# A screen too small for it gets the best fit instead, worked out when it is applied.
	assert_eq(GameSettings.new().value(GameSettings.VIDEO, "resolution"), "1920x1080")


func test_round_trip_through_the_file() -> void:
	_clean()
	var s := GameSettings.new()
	s.set_value(GameSettings.VIDEO, "brightness", 25)
	s.set_value(GameSettings.AUDIO, "music", 10)
	s.set_value(GameSettings.GAME, "run_timer", true)
	s.set_value(GameSettings.VIDEO, "resolution", "1920x1080")
	assert_true(s.save_to(_path()))
	var loaded := GameSettings.new()
	assert_true(loaded.load_from(_path()))
	assert_eq(loaded.value(GameSettings.VIDEO, "brightness"), 25)
	assert_eq(loaded.value(GameSettings.AUDIO, "music"), 10)
	assert_eq(loaded.value(GameSettings.GAME, "run_timer"), true)
	assert_eq(loaded.value(GameSettings.VIDEO, "resolution"), "1920x1080")
	assert_true(loaded.equals(s))
	_clean()


func test_a_missing_file_loads_the_defaults() -> void:
	_clean()
	var s := GameSettings.new()
	assert_false(s.load_from(_path()))
	assert_true(s.equals(GameSettings.new()))


func test_a_damaged_file_loads_the_defaults() -> void:
	_write("this is [not a config\n=== at all")
	var s := GameSettings.new()
	s.load_from(_path())
	assert_true(s.equals(GameSettings.new()))
	_clean()


func test_bad_values_fall_back_or_clamp() -> void:
	_write("[video]\nbrightness=500\ncontrast=\"loud\"\nfullscreen=3\n[audio]\nmaster=-20\n[game]\nminimap_opacity=5\nlanguage=\"xx\"\nunknown=1\n")
	var s := GameSettings.new()
	s.load_from(_path())
	assert_eq(s.value(GameSettings.VIDEO, "brightness"), 50, "clamped to the slider")
	assert_eq(s.value(GameSettings.VIDEO, "contrast"), 0, "a wrong type keeps the default")
	assert_eq(s.value(GameSettings.VIDEO, "fullscreen"), false, "a number is not a switch")
	assert_eq(s.value(GameSettings.AUDIO, "master"), 0)
	assert_eq(s.value(GameSettings.GAME, "minimap_opacity"), 20, "the minimap never goes below 20")
	assert_eq(s.value(GameSettings.GAME, "language"), "en", "an unknown language falls back")
	_clean()


func test_set_value_clamps_too() -> void:
	var s := GameSettings.new()
	s.set_value(GameSettings.AUDIO, "effects", 140)
	assert_eq(s.value(GameSettings.AUDIO, "effects"), 100)


func test_reset_section_resets_only_that_tab() -> void:
	var s := GameSettings.new()
	s.set_value(GameSettings.VIDEO, "gamma", 30)
	s.set_value(GameSettings.AUDIO, "master", 40)
	s.reset_section(GameSettings.VIDEO)
	assert_eq(s.value(GameSettings.VIDEO, "gamma"), 0)
	assert_eq(s.value(GameSettings.AUDIO, "master"), 40)


func test_equals_by_section() -> void:
	var a := GameSettings.new()
	var b := a.duplicate_settings()
	b.set_value(GameSettings.GAME, "hit_stop", false)
	assert_false(a.equals(b))
	assert_true(a.equals(b, GameSettings.VIDEO))
	assert_false(a.equals(b, GameSettings.GAME))
	assert_eq(a.value(GameSettings.GAME, "hit_stop"), true, "a duplicate is its own copy")


func test_resolutions_are_whole_multiples_that_fit() -> void:
	assert_eq(GameSettings.resolutions_for(Vector2i(1920, 1080)), [Vector2i(1280, 720), Vector2i(1920, 1080)])
	assert_eq(GameSettings.resolutions_for(Vector2i(2560, 1600)), [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440)])
	assert_eq(GameSettings.resolutions_for(Vector2i(3840, 2160)).size(), 4)
	assert_eq(GameSettings.resolutions_for(Vector2i(1024, 768)), [Vector2i(1280, 720)], "the smallest is always offered")
	assert_eq(GameSettings.best_resolution(Vector2i(2560, 1440)), Vector2i(2560, 1440))
	assert_eq(GameSettings.best_resolution(Vector2i(1366, 768)), Vector2i(1280, 720))


func test_resolution_text() -> void:
	assert_eq(GameSettings.resolution_text(Vector2i(1920, 1080)), "1920x1080")
	assert_eq(GameSettings.parse_resolution("2560x1440"), Vector2i(2560, 1440))
	assert_eq(GameSettings.parse_resolution("rubbish"), Vector2i.ZERO)
	assert_eq(GameSettings.parse_resolution(""), Vector2i.ZERO)


func test_adjustment_numbers() -> void:
	assert_true(GameSettings.is_neutral(0, 0, 0))
	assert_false(GameSettings.is_neutral(0, 1, 0))
	assert_near(GameSettings.brightness_offset(0), 0.0)
	assert_near(GameSettings.brightness_offset(50), 0.2)
	assert_near(GameSettings.contrast_factor(-50), 0.5)
	assert_near(GameSettings.contrast_factor(50), 1.5)
	assert_near(GameSettings.gamma_power(0), 1.0)
	assert_near(GameSettings.gamma_power(50), 2.0)
	assert_near(GameSettings.gamma_power(-50), 0.5)


func test_bus_volume() -> void:
	assert_near(GameSettings.bus_db(100), 0.0)
	assert_true(GameSettings.bus_db(0) <= -79.0, "zero is silent")
	assert_true(GameSettings.bus_db(50) < 0.0 and GameSettings.bus_db(50) > -10.0)


func test_minimap_visibility() -> void:
	assert_true(GameSettings.minimap_visible(false, true, false), "the option off keeps it in a fight")
	assert_false(GameSettings.minimap_visible(true, true, false), "hidden while a fight is on")
	assert_true(GameSettings.minimap_visible(true, false, false))
	assert_false(GameSettings.minimap_visible(false, false, true), "the big map always hides it")
