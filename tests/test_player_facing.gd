extends TestCase

# Harold faces where he walks, and turns to his aim only while he is using it (feedback P2-2).


func test_aiming_faces_the_aim() -> void:
	assert_true(Player.face_left(1.0, -1.0, true, false), "walking right but aiming left")
	assert_false(Player.face_left(-1.0, 1.0, true, true), "walking left but aiming right")


func test_not_aiming_faces_the_walk() -> void:
	assert_true(Player.face_left(-1.0, 1.0, false, false), "walking away from the mouse")
	assert_false(Player.face_left(1.0, -1.0, false, true))


func test_standing_still_keeps_the_last_facing() -> void:
	assert_true(Player.face_left(0.0, 1.0, false, true))
	assert_false(Player.face_left(0.0, -1.0, false, false))


func test_a_swing_with_the_mouse_behind_him_turns_him_to_the_aim() -> void:
	var player := Player.new()
	player._aim = Vector2.LEFT
	assert_false(player.visual_facing_left(1.0), "walking right with the mouse behind: faces the walk")
	player._active_swing = SwingAttack.new(Vector2.LEFT, 44.0, 60.0, 10.0, 60.0, false, false)
	assert_true(player.visual_facing_left(1.0), "swinging at the mouse behind: faces the aim")
	player._active_swing = null
	assert_false(player.visual_facing_left(1.0), "swing over: back to the walk")
	player.free()


func test_the_aim_window_after_the_mouse_moved_turns_him_then_lapses() -> void:
	var player := Player.new()
	player._aim = Vector2.LEFT
	player._aim_face_left = Player.FACE_AIM_TIME
	assert_true(player.visual_facing_left(1.0))
	player._track_aim_input(Player.FACE_AIM_TIME + 0.01)
	assert_false(player.visual_facing_left(1.0))
	player.free()


func test_a_throw_turns_him_to_the_aim_for_a_moment() -> void:
	var player := Player.new()
	player._aim = Vector2.LEFT
	player._throw_face_left = Player.THROW_FACE_TIME
	assert_true(player.visual_facing_left(1.0))
	player.free()
