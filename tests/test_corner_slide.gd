extends TestCase

# A 32 px prop at the origin and Grandpa's 14 by 12 feet beside it.
const PROP := Rect2(0, 0, 32, 32)


func _feet(at: Vector2) -> Rect2:
	return Rect2(at, Player.FEET_BOX_SIZE)


func test_clipping_a_corner_by_a_pixel_or_two_steps_round_it() -> void:
	# Walking right, his feet's top edge 2 px over the prop's bottom edge: step down by 2.
	var feet := _feet(Vector2(-14, 30))
	assert_true(CornerSlide.nudge(feet, PROP, Vector2.RIGHT).is_equal_approx(Vector2(0, 2)))
	# His feet's bottom 3 px into the prop's top: step up by 3.
	feet = _feet(Vector2(-14, -9))
	assert_true(CornerSlide.nudge(feet, PROP, Vector2.RIGHT).is_equal_approx(Vector2(0, -3)))


func test_it_works_the_same_walking_up_or_down() -> void:
	var feet := _feet(Vector2(28, 32))
	assert_true(CornerSlide.nudge(feet, PROP, Vector2.UP).is_equal_approx(Vector2(4, 0)))
	feet = _feet(Vector2(-10, -12))
	assert_true(CornerSlide.nudge(feet, PROP, Vector2.DOWN).is_equal_approx(Vector2(-4, 0)))


func test_a_real_overlap_still_blocks() -> void:
	var feet := _feet(Vector2(-14, 20))
	assert_eq(CornerSlide.nudge(feet, PROP, Vector2.RIGHT), Vector2.ZERO, "12 px into it is a wall, not a corner")
	feet = _feet(Vector2(-14, 26))
	assert_eq(CornerSlide.nudge(feet, PROP, Vector2.RIGHT), Vector2.ZERO, "6 px is more than the reach")
	assert_near(CornerSlide.REACH, 5.0)


func test_only_a_straight_walk_is_helped() -> void:
	var feet := _feet(Vector2(-14, 30))
	assert_eq(CornerSlide.nudge(feet, PROP, Vector2(1, 1).normalized()), Vector2.ZERO, "never on a slant")
	assert_eq(CornerSlide.nudge(feet, PROP, Vector2.ZERO), Vector2.ZERO)


func test_the_step_is_always_sideways_and_away_from_the_prop() -> void:
	for y in range(28, 32):
		var step := CornerSlide.nudge(_feet(Vector2(-14, y)), PROP, Vector2.RIGHT)
		assert_near(step.x, 0.0)
		assert_true(step.y > 0.0, "away from it")
		assert_false(_feet(Vector2(-14, y) + step).grow(-0.01).intersects(PROP), "clear after the step")
