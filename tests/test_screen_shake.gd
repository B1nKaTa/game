extends TestCase


func test_falloff_goes_from_one_to_zero() -> void:
	assert_near(ScreenShake.falloff(0.15, 0.15), 1.0)
	assert_near(ScreenShake.falloff(0.0, 0.15), 0.0)
	assert_near(ScreenShake.falloff(-1.0, 0.15), 0.0)
	assert_near(ScreenShake.falloff(1.0, 0.0), 0.0, "no duration is no shake")


func test_falloff_eases_out() -> void:
	assert_true(ScreenShake.falloff(0.075, 0.15) < 0.5, "quadratic, so below linear")
	assert_true(ScreenShake.falloff(0.075, 0.15) > 0.0)


func test_a_shake_starts_at_full_magnitude_and_dies_out() -> void:
	var shake := ScreenShake.new()
	assert_false(shake.is_active())
	shake.start(4.0, 0.15)
	assert_true(shake.is_active())
	assert_near(shake.current_magnitude(), 4.0)
	shake.tick(0.075)
	assert_true(shake.current_magnitude() < 4.0)
	shake.tick(0.1)
	assert_false(shake.is_active())
	assert_near(shake.current_magnitude(), 0.0)


func test_a_weaker_shake_does_not_cut_a_stronger_one_short() -> void:
	var shake := ScreenShake.new()
	shake.start(8.0, 0.4)
	shake.start(3.0, 0.12)
	assert_near(shake.current_magnitude(), 8.0)
	shake.tick(0.39)
	shake.start(3.0, 0.12)
	assert_near(shake.current_magnitude(), 3.0, "the old shake had faded below it")


func test_offset_stays_within_the_magnitude_and_on_whole_pixels() -> void:
	var shake := ScreenShake.new()
	shake.start(4.0, 0.15)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 200:
		var offset := shake.offset(rng)
		assert_true(absf(offset.x) <= 4.0 and absf(offset.y) <= 4.0, "in range")
		assert_eq(offset, offset.round(), "whole pixels")


func test_no_offset_when_idle() -> void:
	var rng := RandomNumberGenerator.new()
	assert_eq(ScreenShake.new().offset(rng), Vector2.ZERO)


func test_boss_death_shakes_most_and_damage_shakes_less_than_a_charged_hit() -> void:
	assert_true(ScreenShake.BOSS_DEATH > ScreenShake.CHARGED_HIT)
	assert_true(ScreenShake.HURT < ScreenShake.CHARGED_HIT)
	assert_near(ScreenShake.CHARGED_HIT, 4.0)
	assert_near(ScreenShake.CHARGED_TIME, 0.15)
