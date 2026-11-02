extends TestCase


func test_not_invulnerable_is_fully_visible() -> void:
	assert_near(HurtLook.alpha(0.0), 1.0)


func test_stays_solid_while_the_red_flash_plays() -> void:
	assert_near(HurtLook.alpha(Health.INVULN_TIME), 1.0)
	assert_near(HurtLook.alpha(Health.INVULN_TIME - HurtLook.RED_TIME * 0.5), 1.0)


func test_blinks_for_the_rest_of_the_invulnerability() -> void:
	var seen_dim := false
	var seen_solid := false
	var left := Health.INVULN_TIME - HurtLook.RED_TIME - 0.01
	while left > 0.0:
		var alpha := HurtLook.alpha(left)
		assert_true(alpha > 0.0 and alpha <= 1.0, "alpha in range")
		if alpha < 1.0:
			seen_dim = true
		else:
			seen_solid = true
		left -= 0.01
	assert_true(seen_dim and seen_solid, "alternates between dim and solid")


func test_health_reports_invulnerability_left() -> void:
	var health := Health.new(4)
	assert_near(health.invulnerability_left(), 0.0)
	health.hit(1)
	assert_near(health.invulnerability_left(), Health.INVULN_TIME)
	health.tick(0.3)
	assert_near(health.invulnerability_left(), Health.INVULN_TIME - 0.3)
	assert_true(health.is_invulnerable())
