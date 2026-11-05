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


func test_the_right_stick_aims_while_it_is_held() -> void:
	var at := Vector2(100, 50)
	var aimed := Player.pad_aim_point(at, Vector2(0.0, 0.9), Vector2.RIGHT, true, Vector2.LEFT)
	assert_true(aimed.is_equal_approx(at + Vector2.DOWN * PadInput.AIM_REACH))
	aimed = Player.pad_aim_point(at, Vector2(-0.7, 0.0), Vector2.RIGHT, false, Vector2.UP)
	assert_true(aimed.is_equal_approx(at + Vector2.LEFT * PadInput.AIM_REACH), "the stick aims even with Mouse aim off")


func test_a_resting_stick_keeps_the_aim_where_it_was() -> void:
	var at := Vector2(100, 50)
	var aimed := Player.pad_aim_point(at, Vector2(0.05, 0.1), Vector2.UP, true, Vector2.LEFT)
	assert_true(aimed.is_equal_approx(at + Vector2.UP * PadInput.AIM_REACH))


func test_with_mouse_aim_off_a_resting_stick_aims_the_way_he_walks() -> void:
	var at := Vector2(100, 50)
	assert_eq(Player.pad_aim_point(at, Vector2.ZERO, Vector2.UP, false, Vector2.LEFT), Player.move_aim_point(at, Vector2.LEFT))


func test_the_player_aims_with_the_pad_while_a_pad_plays() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	assert_true(source.contains("if ActiveDevice.using_pad:"), "the pad comes before the mouse")
	assert_true(source.contains("Input.get_joy_axis(ActiveDevice.pad_id, JOY_AXIS_RIGHT_X)"))


func test_every_prompt_names_the_active_device() -> void:
	# Prompts go through KeyBindings.with_key or prompt_label, which follow the active device, never
	# through the keyboard-only label_for.
	for path in ["res://scripts/ui/hud.gd", "res://scripts/world/npc.gd", "res://scripts/world/pickup.gd", "res://scripts/world/door.gd", "res://scripts/world/waiting_station.gd", "res://scripts/world/arcade_table.gd", "res://scripts/world/retirement_station.gd", "res://scripts/ui/floor_map_view.gd", "res://scripts/ui/cutscene_player.gd", "res://scripts/ui/card_table_panel.gd"]:
		var source := FileAccess.get_file_as_string(path)
		assert_false(source.contains("KeyBindings.label_for("), path)
		assert_true(source.contains("KeyBindings.with_key(") or source.contains("KeyBindings.prompt_label("), path)
