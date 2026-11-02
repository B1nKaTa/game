extends TestCase


func test_a_door_arms_once_the_player_is_out_of_range() -> void:
	assert_true(Door.next_armed(false, false))
	assert_false(Door.next_armed(false, true), "still standing in the doorway")
	assert_true(Door.next_armed(true, true), "stays armed when walking back in")


func test_an_armed_open_door_is_entered_when_in_range() -> void:
	assert_true(Door.should_enter(false, false, false, true, true))


func test_arriving_on_a_door_does_not_enter_it() -> void:
	assert_false(Door.should_enter(false, false, false, false, true))


func test_a_locked_door_is_not_entered() -> void:
	assert_false(Door.should_enter(true, false, false, true, true))


func test_a_sealed_door_is_not_entered() -> void:
	assert_false(Door.should_enter(false, true, false, true, true))


func test_a_used_door_is_not_entered_twice() -> void:
	assert_false(Door.should_enter(false, false, true, true, true))


func test_out_of_range_is_not_entered() -> void:
	assert_false(Door.should_enter(false, false, false, true, false))


func test_rearming_lets_a_door_be_used_after_returning() -> void:
	var door := Door.new()
	door._used = true
	door._armed = true
	door.rearm()
	assert_false(door._used)
	assert_false(door._armed, "must be left before it can fire again")
	door.free()
