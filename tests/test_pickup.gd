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


func test_coin_magnet_pulls_only_within_range() -> void:
	assert_true(Pickup.should_magnet(true, Pickup.MAGNET_RADIUS))
	assert_false(Pickup.should_magnet(true, Pickup.MAGNET_RADIUS + 1.0))
	assert_false(Pickup.should_magnet(false, 1.0), "only coins fly")


func test_fly_speed_speeds_up_then_caps() -> void:
	assert_true(Pickup.fly_speed(0.2) > Pickup.fly_speed(0.0))
	assert_near(Pickup.fly_speed(100.0), Pickup.FLY_MAX_SPEED)


func test_fly_step_moves_toward_the_target_without_overshooting() -> void:
	assert_eq(Pickup.fly_step(Vector2.ZERO, Vector2(100, 0), 50.0, 1.0), Vector2(50, 0))
	assert_eq(Pickup.fly_step(Vector2.ZERO, Vector2(10, 0), 500.0, 1.0), Vector2(10, 0))


func test_flying_coin_pays_at_once_and_only_once() -> void:
	var player := Node2D.new()
	player.position = Vector2(500, 0)
	var coin := Pickup.new()
	coin.flies = true
	coin.setup("+5", Color.YELLOW, player)
	var paid := [0]
	coin.collected.connect(func(): paid[0] += 1)
	coin.fly()
	assert_eq(paid[0], 1, "paid when it starts flying")
	assert_true(coin.is_flying())
	coin.fly()
	coin.collect()
	assert_eq(paid[0], 1, "no double payment")
	player.free()
	coin.free()


func test_coin_inside_the_magnet_range_starts_flying_on_its_own() -> void:
	var player := Node2D.new()
	var coin := Pickup.new()
	coin.flies = true
	coin.setup("+5", Color.YELLOW, player)
	coin.position = Vector2(Pickup.MAGNET_RADIUS - 4.0, 0)
	var paid := [0]
	coin.collected.connect(func(): paid[0] += 1)
	coin._process(0.016)
	assert_true(coin.is_flying())
	assert_eq(paid[0], 1)
	player.free()
	coin.free()


func test_flying_coin_frees_itself_on_arrival_without_paying_again() -> void:
	var player := Node2D.new()
	var coin := Pickup.new()
	coin.flies = true
	coin.setup("+5", Color.YELLOW, player)
	coin.position = Vector2(30, 0)
	var paid := [0]
	coin.collected.connect(func(): paid[0] += 1)
	coin.fly()
	for i in 60:
		coin._process(0.016)
	assert_true(coin.is_queued_for_deletion())
	assert_eq(paid[0], 1)
	player.free()
	coin.free()
