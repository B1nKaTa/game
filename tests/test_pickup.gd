extends TestCase


func test_walk_over_pickup_collects_in_range() -> void:
	assert_true(Pickup.should_collect(false, true, false))
	assert_false(Pickup.should_collect(false, false, false))


func test_interact_pickup_needs_the_button() -> void:
	assert_false(Pickup.should_collect(true, true, false))
	assert_true(Pickup.should_collect(true, true, true))
	assert_false(Pickup.should_collect(true, false, true))


func test_pickup_waits_while_it_cannot_be_taken() -> void:
	var player := Node2D.new()
	var pickup := Pickup.new()
	pickup.setup("Heal", Color.RED, player)
	var taken := [0]
	pickup.collected.connect(func(): taken[0] += 1)
	var allowed := [false]
	pickup.can_take = func(): return allowed[0]
	pickup._process(0.0)
	assert_eq(taken[0], 0)
	allowed[0] = true
	pickup._process(0.0)
	assert_eq(taken[0], 1)
	player.free()
	pickup.free()
