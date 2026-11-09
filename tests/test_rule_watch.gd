extends TestCase


func test_only_the_forbidden_action_breaks_it_and_only_once() -> void:
	var watch := RuleWatch.new(RoomRule.NO_HORSEPLAY)
	assert_false(watch.report(RoomRule.ACTION_SWING))
	assert_eq(watch.state, RuleWatch.State.ACTIVE)
	assert_true(watch.report(RoomRule.ACTION_DODGE), "the first dodge breaks it")
	assert_eq(watch.state, RuleWatch.State.BROKEN)
	assert_false(watch.report(RoomRule.ACTION_DODGE), "a second break changes nothing")


func test_loitering_breaks_after_two_and_a_half_still_seconds() -> void:
	var watch := RuleWatch.new(RoomRule.NO_LOITERING)
	for i in 24:
		assert_false(watch.tick_still(0.1, false))
	assert_false(watch.tick_still(0.05, true), "a step resets the clock")
	for i in 24:
		assert_false(watch.tick_still(0.1, false))
	assert_true(watch.tick_still(0.2, false))
	assert_eq(watch.state, RuleWatch.State.BROKEN)


func test_standing_still_only_counts_for_the_loitering_rule() -> void:
	var watch := RuleWatch.new(RoomRule.NO_CANE)
	for i in 100:
		assert_false(watch.tick_still(0.1, false))


func test_the_icon_pulses_while_the_forbidden_button_is_held() -> void:
	var watch := RuleWatch.new(RoomRule.TEETH_IN)
	assert_false(watch.pulsing({"throw": false, "attack": true}))
	assert_true(watch.pulsing({"throw": true}))
	watch.report(RoomRule.ACTION_THROW)
	assert_false(watch.pulsing({"throw": true}), "a broken rule no longer warns")


func test_loitering_pulses_in_its_last_second() -> void:
	var watch := RuleWatch.new(RoomRule.NO_LOITERING)
	watch.tick_still(1.4, false)
	assert_false(watch.pulsing({}))
	watch.tick_still(0.2, false)
	assert_true(watch.pulsing({}))


func test_clearing_the_room_keeps_or_lifts_it() -> void:
	var kept := RuleWatch.new(RoomRule.NO_CANE)
	assert_eq(kept.finish(), RuleWatch.State.KEPT)
	var broken := RuleWatch.new(RoomRule.NO_CANE)
	broken.report(RoomRule.ACTION_SWING)
	assert_eq(broken.finish(), RuleWatch.State.LIFTED)
	assert_false(kept.is_open())
	assert_false(broken.report(RoomRule.ACTION_SWING), "a finished rule cannot break")


func test_it_round_trips_through_a_dictionary() -> void:
	var watch := RuleWatch.new(RoomRule.EXHIBITS)
	watch.announced = true
	watch.report(RoomRule.ACTION_BREAK)
	var copy := RuleWatch.from_dict(watch.to_dict())
	assert_eq(copy.rule, RoomRule.EXHIBITS)
	assert_eq(copy.state, RuleWatch.State.BROKEN)
	assert_true(copy.announced)
	assert_eq(RuleWatch.from_dict({}).rule, "", "an old checkpoint has no rule")
