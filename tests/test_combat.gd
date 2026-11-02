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


func test_melee_arc() -> void:
	var o := Vector2.ZERO
	assert_true(MeleeArc.hits(o, Vector2.RIGHT, 40.0, 60.0, Vector2(30, 0)))
	assert_false(MeleeArc.hits(o, Vector2.RIGHT, 40.0, 60.0, Vector2(50, 0)), "too far")
	assert_false(MeleeArc.hits(o, Vector2.RIGHT, 40.0, 60.0, Vector2(-30, 0)), "behind")
	assert_true(MeleeArc.hits(o, Vector2.RIGHT, 40.0, 60.0, Vector2.ZERO), "same spot")


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
	for action in ["move_left", "move_right", "move_up", "move_down", "attack", "throw", "dodge", "interact"]:
		assert_true(InputMap.has_action(action), action)
		assert_eq(InputMap.action_get_events(action).size(), 1, action)


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
