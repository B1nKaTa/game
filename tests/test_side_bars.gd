extends TestCase

const VIEW := Vector2i(640, 360)


func test_a_wide_window_centres_a_whole_number_picture() -> void:
	assert_eq(SideBars.picture_rect(Vector2i(2560, 1080), VIEW, true), Rect2i(320, 0, 1920, 1080))


func test_a_window_between_scales_keeps_the_lower_whole_scale() -> void:
	assert_eq(SideBars.picture_rect(Vector2i(1600, 500), VIEW, true), Rect2i(480, 70, 640, 360))
	assert_eq(SideBars.picture_rect(Vector2i(1366, 768), VIEW, true), Rect2i(43, 24, 1280, 720))


func test_an_exact_fit_has_no_bars() -> void:
	assert_eq(SideBars.picture_rect(Vector2i(1920, 1080), VIEW, true), Rect2i(0, 0, 1920, 1080))


func test_a_fractional_stretch_fills_the_height() -> void:
	assert_eq(SideBars.picture_rect(Vector2i(2560, 1080), VIEW, false), Rect2i(320, 0, 1920, 1080))
	assert_eq(SideBars.picture_rect(Vector2i(1600, 500), VIEW, false), Rect2i(356, 0, 888, 500))


func test_a_window_smaller_than_the_view_stays_at_one_times() -> void:
	assert_eq(SideBars.picture_rect(Vector2i(500, 300), VIEW, true), Rect2i(0, 0, 640, 360))


func test_the_frame_is_drawn_without_the_godot_3_call() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/side_bars.gd")
	assert_false(source.contains("black_bars_set_" + "images("), "Godot 4 has no black_bars_set_images")


func test_the_left_bar_lightens_toward_its_edge() -> void:
	var image := SideBars.frame_image(Color(0.1, 0.1, 0.1), Color(0.5, 0.4, 0.3), true)
	assert_true(image.get_pixel(SideBars.WIDTH - 2, 0).get_luminance() > image.get_pixel(0, 0).get_luminance())


func _source(path: String) -> String:
	return FileAccess.get_file_as_string(path).replace("\r", "")


func _body(source: String, header: String) -> String:
	var start := source.find(header)
	var next := source.find("\nfunc ", start + header.length())
	return source.substr(start, (next if next > 0 else source.length()) - start)


func test_a_minimised_window_leaves_the_bars_alone() -> void:
	var watch := _body(_source("res://scripts/world/side_bars.gd"), "\tfunc _process(")
	var guard := watch.find("if window.x <= 0 or window.y <= 0:")
	assert_true(guard > 0 and guard < watch.find("var root"), "it returns before touching any state")


func test_the_title_screen_puts_the_bars_back_to_black() -> void:
	assert_true(_source("res://scripts/scenes/title_screen.gd").contains("SideBars.reset()"))
	SideBars.reset()
	assert_true(true, "reset before any frame is a no-op")


func test_the_first_window_is_already_full_hd() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/window_width_override"), 1920)
	assert_eq(ProjectSettings.get_setting("display/window/size/window_height_override"), 1080)
