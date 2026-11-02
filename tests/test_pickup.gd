extends TestCase


func test_walk_over_pickup_collects_in_range() -> void:
	assert_true(Pickup.should_collect(false, true, false))
	assert_false(Pickup.should_collect(false, false, false))


func test_interact_pickup_needs_the_button() -> void:
	assert_false(Pickup.should_collect(true, true, false))
	assert_true(Pickup.should_collect(true, true, true))
	assert_false(Pickup.should_collect(true, false, true))
