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


# --- the HUD's band (Hud.BAND_BOTTOM) as the top inset ---

const INSET := Hud.BAND_BOTTOM


# Where a room's world y shows on screen with the camera resting at center.
func _screen_y(world_y: float, center: Vector2) -> float:
	return world_y - center.y + VIEW.y / 2.0


func test_the_inset_is_the_hud_band() -> void:
	assert_eq(INSET, 36.0)


func test_a_tall_room_starts_its_top_wall_below_the_hud() -> void:
	for room: Vector2 in [LARGE, MEDIUM]:
		var top := RoomCamera.center_for(room, Vector2(room.x / 2.0, 10), VIEW, INSET)
		assert_eq(_screen_y(0.0, top), INSET, "the top wall at the band's foot, %s" % str(room))
		var bottom := RoomCamera.center_for(room, Vector2(room.x / 2.0, room.y - 10), VIEW, INSET)
		assert_eq(_screen_y(room.y, bottom), VIEW.y, "the bottom wall at the screen's foot, %s" % str(room))


func test_a_tall_room_follows_him_in_the_middle_of_the_space_under_the_hud() -> void:
	var center := RoomCamera.center_for(LARGE, Vector2(480, 272), VIEW, INSET)
	assert_eq(center, Vector2(480, 272 - INSET / 2.0))
	assert_eq(_screen_y(272, center), INSET + (VIEW.y - INSET) / 2.0)


func test_a_short_room_is_centred_below_the_hud() -> void:
	for focus: Vector2 in [Vector2(40, 40), Vector2(400, 250)]:
		var center := RoomCamera.center_for(SMALL, focus, VIEW, INSET)
		var top := _screen_y(0.0, center)
		var bottom := _screen_y(SMALL.y, center)
		assert_eq(top, 54.0)
		assert_eq(top - INSET, VIEW.y - bottom, "as much space above it as below")


func test_a_room_exactly_the_space_under_the_hud_fills_it() -> void:
	var fits := Vector2(640, 324)
	for focus: Vector2 in [Vector2(320, 10), Vector2(320, 314)]:
		var center := RoomCamera.center_for(fits, focus, VIEW, INSET)
		assert_eq(_screen_y(0.0, center), INSET)
		assert_eq(_screen_y(fits.y, center), VIEW.y)


func test_a_room_exactly_the_view_s_height_scrolls_under_the_hud() -> void:
	var exact := Vector2(640, 360)
	var top := RoomCamera.center_for(exact, Vector2(320, 0), VIEW, INSET)
	assert_eq(_screen_y(0.0, top), INSET, "his end of the room shows from the band down")
	var bottom := RoomCamera.center_for(exact, Vector2(320, 360), VIEW, INSET)
	assert_eq(_screen_y(exact.y, bottom), VIEW.y, "the far end stops at the screen's foot")
	assert_eq(bottom.y - top.y, INSET, "it scrolls by the band's height")


func test_the_inset_leaves_the_x_axis_alone() -> void:
	for room: Vector2 in [SMALL, MEDIUM, LARGE, Vector2(960, 288)]:
		for focus: Vector2 in [Vector2(10, 10), Vector2(500, 200), Vector2(5000, 5000)]:
			assert_eq(RoomCamera.center_for(room, focus, VIEW, INSET).x, RoomCamera.center_for(room, focus, VIEW).x)


func test_he_never_stands_under_the_hud_in_any_room() -> void:
	for height in range(256, 640, 8):
		var room := Vector2(640, height)
		for y in range(0, height + 1, 4):
			var center := RoomCamera.center_for(room, Vector2(320, y), VIEW, INSET)
			var at := _screen_y(y, center)
			assert_true(at >= INSET and at <= VIEW.y, "room %d tall, him at %d shows at %f" % [height, y, at])
