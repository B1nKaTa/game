extends TestCase


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


# --- the stoker ---

func test_a_stoker_keeps_its_distance() -> void:
	assert_eq(StokerBehavior.step(40.0), StokerBehavior.BACK_OFF)
	assert_eq(StokerBehavior.step(StokerBehavior.TOO_CLOSE - 1.0), StokerBehavior.BACK_OFF)
	assert_eq(StokerBehavior.step(130.0), StokerBehavior.HOLD)
	assert_eq(StokerBehavior.step(StokerBehavior.TOO_FAR + 1.0), StokerBehavior.CLOSE_IN)


func test_its_coal_follows_the_plan() -> void:
	assert_near(StokerBehavior.COAL_WARNING, 0.8)
	assert_near(StokerBehavior.COAL_RADIUS, 22.0)
	assert_near(StokerBehavior.BURN_TIME, 2.5)


func test_a_coal_mark_leaves_time_to_walk_out() -> void:
	var walk := PlayerStats.BASE_SPEED * (StokerBehavior.COAL_WARNING - 0.2)
	assert_true(walk > StokerBehavior.COAL_RADIUS * 2.0, "he can cross the whole mark, %f" % walk)


func test_a_thrown_coal_marks_the_spot_and_then_burns() -> void:
	var stoker := Enemy.new()
	stoker.setup(_load("stoker"), null, 0.5)
	var strike := GroundStrike.new()
	strike.setup(stoker, StokerBehavior.COAL_RADIUS, StokerBehavior.COAL_WARNING, 0.0, 0.0, -1, StokerBehavior.BURN_TIME)
	strike.throw_from(Vector2(100, 0))
	assert_false(strike.advance(StokerBehavior.COAL_WARNING - 0.1))
	assert_true(strike.advance(0.2))
	assert_true(strike.is_burning())
	strike.free()
	stoker.free()
