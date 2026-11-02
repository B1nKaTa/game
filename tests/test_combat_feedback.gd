extends TestCase


func _fresh() -> CombatFeedback:
	Engine.time_scale = 1.0
	return CombatFeedback.new()


func test_a_charged_hit_freezes_time_and_shakes_the_camera() -> void:
	var feedback := _fresh()
	var camera := Camera2D.new()
	feedback.setup(camera)
	feedback.on_swing_landed(true, false)
	assert_near(Engine.time_scale, 0.0)
	feedback.tick_real(0.01)
	assert_true(feedback.is_shaking())
	feedback.tick_real(0.2)
	assert_near(Engine.time_scale, 1.0, "freeze ended on its own")
	assert_eq(camera.offset, Vector2.ZERO, "shake ended back at rest")
	feedback.free()
	camera.free()


func test_plain_combo_hits_do_not_freeze_or_shake() -> void:
	var feedback := _fresh()
	feedback.on_swing_landed(false, false)
	assert_near(Engine.time_scale, 1.0)
	assert_false(feedback.is_shaking())
	feedback.free()


func test_a_finisher_freezes_but_does_not_shake() -> void:
	var feedback := _fresh()
	feedback.on_swing_landed(false, true)
	assert_near(Engine.time_scale, 0.0)
	assert_false(feedback.is_shaking())
	feedback.tick_real(0.05)
	assert_near(Engine.time_scale, 1.0)
	feedback.free()


func test_a_cane_hit_freezes() -> void:
	var feedback := _fresh()
	feedback.on_cane_hit()
	assert_near(Engine.time_scale, 0.0)
	feedback.tick_real(0.2)
	assert_near(Engine.time_scale, 1.0)
	feedback.free()


func test_leaving_the_tree_always_restores_time() -> void:
	var feedback := _fresh()
	feedback.on_swing_landed(true, false)
	assert_near(Engine.time_scale, 0.0)
	feedback._exit_tree()
	assert_near(Engine.time_scale, 1.0)
	feedback.free()


func test_the_player_dying_ends_a_freeze() -> void:
	var feedback := _fresh()
	feedback.on_cane_hit()
	feedback.on_player_died()
	assert_near(Engine.time_scale, 1.0)
	feedback.free()


func test_taking_damage_shakes_less_than_a_charged_hit() -> void:
	var feedback := _fresh()
	feedback.on_hurt()
	assert_near(feedback.shake_magnitude(), ScreenShake.HURT)
	feedback.free()


func test_a_boss_dying_shakes_most_and_a_normal_enemy_does_not_shake() -> void:
	var feedback := _fresh()
	feedback.on_enemy_died(Vector2.ZERO, false)
	assert_false(feedback.is_shaking())
	feedback.on_enemy_died(Vector2.ZERO, true)
	assert_near(feedback.shake_magnitude(), ScreenShake.BOSS_DEATH)
	feedback.free()

