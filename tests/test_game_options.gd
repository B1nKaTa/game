extends TestCase

# The Game tab's options that change play, each through the flag its owner reads.


func _run() -> RunState:
	return RunState.new([] as Array[UpgradeDef], {})


func test_move_aim_points_the_way_he_last_walked() -> void:
	var at := Vector2(100, 50)
	assert_eq(Player.move_aim_point(at, Vector2.LEFT), at + Vector2.LEFT * Player.MOVE_AIM_REACH)
	assert_eq(Player.move_aim_point(at, Vector2(3, 4)), at + Vector2(0.6, 0.8) * Player.MOVE_AIM_REACH)


func test_move_aim_with_no_walk_yet_points_right() -> void:
	assert_eq(Player.move_aim_point(Vector2.ZERO, Vector2.ZERO), Vector2.RIGHT * Player.MOVE_AIM_REACH)


func test_mouse_aim_is_on_by_default() -> void:
	var player := Player.new()
	assert_true(player.mouse_aim)
	player.free()


func test_heals_wait_on_the_floor_at_full_pills_by_default() -> void:
	var run := _run()
	assert_false(run.heals_at_full)
	assert_false(run.can_take_heal(), "full pills")
	run.health.hit(1)
	assert_true(run.can_take_heal(), "short of a pill")


func test_heals_can_be_picked_up_at_full_pills_when_asked() -> void:
	var run := _run()
	run.heals_at_full = true
	assert_true(run.can_take_heal())


func test_room_view_heals_ask_the_run() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	assert_true(source.contains("heal.can_take = _run.can_take_heal"), "the floor's heal pickups follow the option")


func test_timer_text() -> void:
	assert_eq(Hud.timer_text(0.0), "0:00")
	assert_eq(Hud.timer_text(65.9), "1:05")
	assert_eq(Hud.timer_text(3723.0), "1:02:03")


func test_the_timer_is_hidden_by_default() -> void:
	var hud := Hud.new()
	assert_false(hud.show_timer)
	hud.free()
