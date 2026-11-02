extends TestCase


func test_frame_count_from_strip_width() -> void:
	assert_eq(SpriteVisual.frame_count(128, 32), 4)


func test_frame_count_is_at_least_one() -> void:
	assert_eq(SpriteVisual.frame_count(16, 32), 1)
	assert_eq(SpriteVisual.frame_count(64, 0), 1)
