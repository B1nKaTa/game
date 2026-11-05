extends TestCase


func test_combo_runs_three_hits_with_a_stronger_finish() -> void:
	var combo := CaneCombo.new()
	assert_eq(combo.try_attack(), 10)
	combo.tick(CaneCombo.LOCK_TIME + 0.01)
	assert_eq(combo.try_attack(), 10)
	combo.tick(CaneCombo.LOCK_TIME + 0.01)
	assert_eq(combo.try_attack(), 18)
	combo.tick(CaneCombo.LOCK_TIME + 0.01)
	assert_eq(combo.try_attack(), 10, "wraps to the first hit")


func test_combo_is_locked_during_a_swing() -> void:
	var combo := CaneCombo.new()
	combo.try_attack()
	assert_eq(combo.try_attack(), 0)


func test_combo_resets_after_the_window() -> void:
	var combo := CaneCombo.new()
	combo.try_attack()
	combo.tick(CaneCombo.LOCK_TIME + CaneCombo.WINDOW + 0.01)
	assert_eq(combo.step(), 0)


func test_charge_needs_full_time() -> void:
	var charge := ChargeSwing.new()
	charge.start()
	charge.tick(ChargeSwing.CHARGE_TIME - 0.1)
	assert_false(charge.release())
	assert_false(charge.is_charging())
	charge.start()
	charge.tick(ChargeSwing.CHARGE_TIME + 0.01)
	assert_near(charge.progress(), 1.0)
	assert_true(charge.release())


func test_dodge_has_duration_and_cooldown() -> void:
	var dodge := DodgeTimer.new()
	assert_true(dodge.try_start(1.0))
	assert_true(dodge.is_active())
	assert_false(dodge.try_start(1.0))
	dodge.tick(DodgeTimer.DURATION + 0.01)
	assert_false(dodge.is_active())
	assert_false(dodge.try_start(1.0), "cooling down")
	dodge.tick(1.0)
	assert_true(dodge.try_start(1.0))


func _arc_hits(center: Vector2, size := Vector2(20, 24)) -> bool:
	var body := Rect2(center - size / 2.0, size)
	return MeleeArc.hits_body(Vector2.ZERO, Vector2.RIGHT, 44.0, 60.0, body)


func test_arc_hits_a_body_whose_center_is_inside() -> void:
	assert_true(_arc_hits(Vector2(30, 0)))


func test_arc_hits_a_body_whose_center_is_past_the_reach() -> void:
	assert_true(_arc_hits(Vector2(50, 0)), "near edge is at 40 of 44")


func test_arc_misses_a_body_entirely_past_the_reach() -> void:
	assert_false(_arc_hits(Vector2(60, 0)), "near edge is at 50 of 44")


func test_arc_misses_a_body_behind_the_swing() -> void:
	assert_false(_arc_hits(Vector2(-30, 0)))


func test_arc_hits_a_body_on_top_of_the_swinger() -> void:
	assert_true(_arc_hits(Vector2.ZERO))
	assert_true(_arc_hits(Vector2(-5, 0)), "still overlaps when centered slightly behind")


func test_arc_hits_a_body_corner_inside_the_arc() -> void:
	assert_true(_arc_hits(Vector2(40, 40)), "nearest corner is 41 away at about 43 degrees")
	assert_false(_arc_hits(Vector2(45, 45)), "nearest corner is 48 away")


func test_arc_hits_a_big_body_that_only_crosses_its_side_edge() -> void:
	assert_true(_arc_hits(Vector2(-5, 30), Vector2(40, 48)), "nearest point is outside the angle")


func test_arc_misses_a_body_just_beside_its_side_edge() -> void:
	assert_false(_arc_hits(Vector2(0, 30)))


func test_closest_point_on_a_body() -> void:
	var body := Rect2(10, 10, 20, 20)
	assert_eq(MeleeArc.closest_point(body, Vector2.ZERO), Vector2(10, 10))
	assert_eq(MeleeArc.closest_point(body, Vector2(15, 20)), Vector2(15, 20), "inside stays put")


func test_telegraph_finishes_once() -> void:
	var telegraph := Telegraph.new()
	telegraph.start(1.0)
	assert_true(telegraph.is_active())
	assert_false(telegraph.tick(0.5))
	assert_true(telegraph.tick(0.6))
	assert_false(telegraph.is_active())
	assert_false(telegraph.tick(0.1))


func test_warning_shows_for_the_given_fraction() -> void:
	var telegraph := Telegraph.new()
	telegraph.start(1.0)
	assert_false(telegraph.shows_warning(0.5))
	assert_true(telegraph.shows_warning(1.0))
	telegraph.tick(0.6)
	assert_true(telegraph.shows_warning(0.5))


func test_input_actions_exist() -> void:
	InputSetup.ensure()
	InputSetup.ensure()
	for action in ["move_left", "move_right", "move_up", "move_down", "attack", "throw", "dodge", "interact", "map", "bomb"]:
		assert_true(InputMap.has_action(action), action)
		# One key or mouse button, one controller input, and the D-pad beside the stick, never twice.
		assert_eq(InputMap.action_get_events(action).size(), 2 + PadInput.extras(action).size(), action)


func test_charge_only_shows_after_the_hold_delay() -> void:
	var charge := ChargeSwing.new()
	charge.start()
	assert_true(charge.is_holding())
	assert_false(charge.is_charging(), "a tap is not a charge")
	charge.tick(ChargeSwing.HOLD_DELAY - 0.01)
	assert_false(charge.is_charging())
	charge.tick(0.02)
	assert_true(charge.is_charging())
	assert_true(charge.progress() < 0.1, "indicator starts empty")


func test_releasing_a_tap_does_nothing() -> void:
	var charge := ChargeSwing.new()
	charge.start()
	charge.tick(0.1)
	assert_false(charge.release())
	assert_false(charge.is_holding())


func test_charge_cancel_stops_it() -> void:
	var charge := ChargeSwing.new()
	charge.start()
	charge.tick(ChargeSwing.CHARGE_TIME + 0.1)
	charge.cancel()
	assert_false(charge.is_holding())
	assert_false(charge.is_charging())
	assert_false(charge.release(), "cancelled charge never fires")


func test_player_cancel_charge_clears_a_held_charge() -> void:
	var player := Player.new()
	player._charge.start()
	player._charge.tick(ChargeSwing.CHARGE_TIME)
	assert_true(player._charge.is_charging())
	player.cancel_charge()
	assert_false(player._charge.is_holding())
	assert_false(player._charge.is_charging())
	player.free()


func test_feet_box_ends_at_the_bottom_of_the_sprite() -> void:
	assert_near(Player.FEET_OFFSET.y + Player.FEET_BOX_SIZE.y / 2.0, Player.SPRITE_FEET_Y)


func test_arrival_puts_the_feet_on_the_cell() -> void:
	var cell := Vector2i(1, 5)
	assert_eq(Player.arrival_position(cell) + Player.FEET_OFFSET, RoomBackdrop.cell_center(cell))


func test_warning_progress_is_zero_before_the_warning_shows() -> void:
	var telegraph := Telegraph.new()
	telegraph.start(1.0)
	assert_near(telegraph.warning_progress(0.5), 0.0)
	assert_near(Telegraph.new().warning_progress(0.5), 0.0, "idle")


func test_warning_progress_grows_to_one_as_the_attack_lands() -> void:
	var telegraph := Telegraph.new()
	telegraph.start(1.0)
	telegraph.tick(0.5)
	assert_near(telegraph.warning_progress(0.5), 0.0)
	telegraph.tick(0.25)
	assert_near(telegraph.warning_progress(0.5), 0.5)
	telegraph.tick(0.2)
	assert_true(telegraph.warning_progress(0.5) > 0.85)


func test_a_longer_warning_window_starts_filling_earlier() -> void:
	var telegraph := Telegraph.new()
	telegraph.start(1.0)
	telegraph.tick(0.4)
	assert_near(telegraph.warning_progress(0.5), 0.0, "default window not open yet")
	assert_true(telegraph.warning_progress(0.8) > 0.0, "hearing aid window is open")


# The Golf Glove shortens the charge, and its ring fills in the shorter time.
func test_a_shorter_charge_time_is_ready_sooner() -> void:
	var charge := ChargeSwing.new()
	charge.charge_time = ChargeSwing.CHARGE_TIME * 0.7
	charge.start()
	charge.tick(ChargeSwing.CHARGE_TIME * 0.7 + 0.01)
	assert_near(charge.progress(), 1.0)
	assert_true(charge.release())
	var plain := ChargeSwing.new()
	plain.start()
	plain.tick(ChargeSwing.CHARGE_TIME * 0.7 + 0.01)
	assert_false(plain.release(), "the usual charge is not ready yet")
