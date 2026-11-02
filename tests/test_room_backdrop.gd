extends TestCase


func test_overdraw_covers_the_view_plus_the_biggest_shake_on_every_side() -> void:
	var rect := RoomBackdrop.overdraw_rect()
	var reach := ScreenShake.BOSS_DEATH
	assert_true(rect.position.x < -reach, "left")
	assert_true(rect.position.y < -reach, "top")
	assert_true(rect.end.x > RoomBackdrop.VIEW_SIZE.x + reach, "right")
	assert_true(rect.end.y > RoomBackdrop.VIEW_SIZE.y + reach, "bottom")
