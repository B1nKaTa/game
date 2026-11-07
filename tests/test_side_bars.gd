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
