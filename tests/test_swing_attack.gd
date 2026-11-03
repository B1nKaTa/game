extends TestCase

const AHEAD := Rect2(30, -10, 20, 20)
const FAR_AHEAD := Rect2(80, -10, 20, 20)


func _swing(direction := Vector2.RIGHT) -> SwingAttack:
	return SwingAttack.new(direction, 44.0, 60.0, 10.0, 60.0, false, false)


func test_a_body_in_the_arc_is_hit_once() -> void:
	var swing := _swing()
	assert_true(swing.try_hit(Vector2.ZERO, 1, AHEAD))
	assert_false(swing.try_hit(Vector2.ZERO, 1, AHEAD), "same enemy again")
	assert_true(swing.try_hit(Vector2.ZERO, 2, AHEAD), "a different enemy")


func test_a_new_swing_can_hit_the_same_enemy_again() -> void:
	assert_true(_swing().try_hit(Vector2.ZERO, 1, AHEAD))
	assert_true(_swing().try_hit(Vector2.ZERO, 1, AHEAD))


func test_a_miss_does_not_count_as_landed() -> void:
	var swing := _swing()
	assert_false(swing.try_hit(Vector2.ZERO, 1, FAR_AHEAD))
	assert_false(swing.has_landed())


func test_a_hit_counts_as_landed() -> void:
	var swing := _swing()
	swing.try_hit(Vector2.ZERO, 1, AHEAD)
	assert_true(swing.has_landed())


func test_a_blocked_hit_is_neither_landed_nor_a_miss() -> void:
	var swing := _swing()
	swing.try_hit(Vector2.ZERO, 1, AHEAD)
	swing.mark_blocked()
	assert_false(swing.has_landed())
	assert_true(swing.has_reached_something())
	swing.try_hit(Vector2.ZERO, 2, AHEAD)
	assert_true(swing.has_landed(), "a second enemy with no shield still counts")


func test_an_enemy_moving_in_mid_swing_is_hit() -> void:
	var swing := _swing()
	assert_false(swing.try_hit(Vector2.ZERO, 1, FAR_AHEAD))
	swing.tick(SwingAttack.DURATION / 2.0)
	assert_true(swing.try_hit(Vector2.ZERO, 1, AHEAD))


func test_nothing_is_hit_once_the_swing_ends() -> void:
	var swing := _swing()
	assert_true(swing.is_active())
	swing.tick(SwingAttack.DURATION + 0.01)
	assert_false(swing.is_active())
	assert_false(swing.try_hit(Vector2.ZERO, 1, AHEAD))


func test_a_frozen_frame_does_not_end_the_swing() -> void:
	var swing := _swing()
	swing.tick(0.0)
	assert_true(swing.is_active())


func test_the_swing_keeps_its_own_direction() -> void:
	var swing := _swing(Vector2.LEFT)
	assert_eq(swing.direction, Vector2.LEFT)
	assert_false(swing.try_hit(Vector2.ZERO, 1, AHEAD), "body is on the other side")
