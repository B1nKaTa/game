extends TestCase


func test_starts_held() -> void:
	var cane := CaneThrow.new()
	assert_true(cane.is_held())
	assert_false(cane.is_flying())


func test_throw_makes_it_fly() -> void:
	var cane := CaneThrow.new()
	assert_true(cane.try_throw())
	assert_false(cane.is_held())
	assert_true(cane.is_flying())


func test_second_throw_is_refused_while_away() -> void:
	var cane := CaneThrow.new()
	cane.try_throw()
	assert_false(cane.try_throw(), "flying")
	cane.drop()
	assert_false(cane.try_throw(), "dropped")
	cane.tick(CaneThrow.RETURN_DELAY + 0.1)
	assert_false(cane.try_throw(), "returning")


func test_drop_only_works_from_flying() -> void:
	var cane := CaneThrow.new()
	cane.drop()
	assert_true(cane.is_held(), "held stays held")
	cane.try_throw()
	cane.drop()
	assert_true(cane.is_dropped())
	assert_false(cane.is_flying())


func test_dropped_cane_returns_after_the_timer() -> void:
	var cane := CaneThrow.new()
	cane.try_throw()
	cane.drop()
	cane.tick(CaneThrow.RETURN_DELAY - 0.1)
	assert_true(cane.is_dropped())
	cane.tick(0.2)
	assert_true(cane.is_returning())
	assert_false(cane.is_dropped())


func test_timer_does_not_run_while_flying() -> void:
	var cane := CaneThrow.new()
	cane.try_throw()
	cane.tick(CaneThrow.RETURN_DELAY + 1.0)
	assert_true(cane.is_flying())


func test_catch_returns_it_from_any_state() -> void:
	var cane := CaneThrow.new()
	cane.try_throw()
	cane.catch_cane()
	assert_true(cane.is_held(), "caught in flight")
	cane.try_throw()
	cane.drop()
	cane.catch_cane()
	assert_true(cane.is_held(), "picked up")
	cane.try_throw()
	cane.drop()
	cane.tick(CaneThrow.RETURN_DELAY + 0.1)
	cane.catch_cane()
	assert_true(cane.is_held(), "caught on arrival")
	assert_true(cane.try_throw(), "can throw again")


func test_drop_restarts_the_timer_on_the_next_throw() -> void:
	var cane := CaneThrow.new()
	cane.try_throw()
	cane.drop()
	cane.tick(CaneThrow.RETURN_DELAY - 0.5)
	cane.catch_cane()
	cane.try_throw()
	cane.drop()
	cane.tick(1.0)
	assert_true(cane.is_dropped())


func test_throw_damage_scales_with_damage_mult() -> void:
	assert_near(ThrownCane.hit_damage(1.0), 14.0)
	assert_near(ThrownCane.hit_damage(1.5), 21.0)


func test_a_hit_drops_the_cane_once() -> void:
	var cane := CaneThrow.new()
	cane.try_throw()
	cane.drop()
	cane.drop()
	assert_true(cane.is_dropped())
	assert_false(cane.is_flying(), "a dropped cane can't hit again")


func test_advance_travel_caps_at_max_range() -> void:
	var delta := 1.0 / 60.0
	var travelled := 0.0
	var frames := 0
	while travelled < ThrownCane.MAX_RANGE and frames < 1000:
		travelled = ThrownCane.advance_travel(travelled, delta)
		frames += 1
	assert_eq(frames, 38)
	assert_eq(travelled, ThrownCane.MAX_RANGE, "exactly the max range")
	assert_eq(ThrownCane.advance_travel(travelled, delta), ThrownCane.MAX_RANGE, "stays capped")


func test_travel_completes_from_any_position_and_direction() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var delta := 1.0 / 60.0
	for i in 2000:
		var position := Vector2(rng.randf_range(-700.0, 700.0), rng.randf_range(-400.0, 400.0))
		var direction := Vector2.from_angle(rng.randf_range(0.0, TAU))
		var travelled := 0.0
		var frames := 0
		while travelled < ThrownCane.MAX_RANGE and frames < 100:
			var next := ThrownCane.advance_travel(travelled, delta)
			position += direction * (next - travelled)
			travelled = next
			frames += 1
		assert_true(travelled >= ThrownCane.MAX_RANGE and frames <= 38, "throw %d took %d frames" % [i, frames])
		if not failures.is_empty():
			return


func test_flying_cane_hits_the_outer_part_of_a_big_body() -> void:
	var boss := Rect2(-20, -24, 40, 48)
	assert_true(ThrownCane.touches_body(Vector2(0, 22), boss), "22 from the center, inside the body")


func test_flying_cane_tip_reaches_past_the_body_edge() -> void:
	var body := Rect2(-10, -12, 20, 24)
	assert_true(ThrownCane.touches_body(Vector2(10.0 + ThrownCane.HIT_REACH, 0), body))
	assert_false(ThrownCane.touches_body(Vector2(10.0 + ThrownCane.HIT_REACH + 1.0, 0), body))


func test_flying_cane_reach_is_no_worse_for_regular_enemies() -> void:
	var body := Rect2(-9, -11, 18, 22)
	for i in 36:
		var point := Vector2.from_angle(TAU * i / 36.0) * 16.0
		assert_true(ThrownCane.touches_body(point, body), "16 from the center at step %d" % i)


func test_thrown_cane_announces_the_catch() -> void:
	var state := CaneThrow.new()
	state.try_throw()
	state.drop()
	var cane := ThrownCane.new()
	cane.setup(state, null, Vector2.RIGHT, 1.0)
	var caught := [0]
	cane.caught.connect(func(): caught[0] += 1)
	cane._catch()
	assert_eq(caught[0], 1)
	assert_true(state.is_held())
	cane.free()
