extends TestCase

const VIEW := Vector2(640, 360)
const SMALL := Vector2(14 * 32, 9 * 32)
const MEDIUM := Vector2(20 * 32, 11 * 32)
const LARGE := Vector2(30 * 32, 17 * 32)


func test_a_small_room_stays_centered_wherever_he_stands() -> void:
	assert_eq(RoomCamera.center_for(SMALL, Vector2(40, 40), VIEW), SMALL / 2.0)
	assert_eq(RoomCamera.center_for(SMALL, Vector2(400, 250), VIEW), SMALL / 2.0)


func test_a_medium_room_does_not_scroll_along_either_axis() -> void:
	assert_eq(RoomCamera.center_for(MEDIUM, Vector2(40, 40), VIEW), MEDIUM / 2.0)
	assert_eq(RoomCamera.center_for(MEDIUM, Vector2(600, 320), VIEW), MEDIUM / 2.0)


func test_a_large_room_follows_him_in_the_middle() -> void:
	assert_eq(RoomCamera.center_for(LARGE, Vector2(480, 272), VIEW), Vector2(480, 272))


func test_a_large_room_stops_at_its_edges() -> void:
	assert_eq(RoomCamera.center_for(LARGE, Vector2(10, 10), VIEW), VIEW / 2.0)
	assert_eq(RoomCamera.center_for(LARGE, Vector2(5000, 5000), VIEW), LARGE - VIEW / 2.0)


func test_each_axis_is_decided_on_its_own() -> void:
	var wide_only := Vector2(960, 288)
	assert_eq(RoomCamera.center_for(wide_only, Vector2(500, 10), VIEW), Vector2(500, 144))


func test_the_camera_rests_on_whole_pixels() -> void:
	var center := RoomCamera.center_for(LARGE, Vector2(480.4, 272.6), VIEW)
	assert_eq(center, Vector2(480, 273))
