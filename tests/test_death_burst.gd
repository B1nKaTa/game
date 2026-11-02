extends TestCase


func test_burst_expands_and_fades() -> void:
	assert_near(DeathBurst.progress_radius(0.0, 20.0), 0.0)
	assert_true(DeathBurst.progress_radius(0.5 * DeathBurst.DURATION, 20.0) > 0.0)
	assert_near(DeathBurst.progress_radius(DeathBurst.DURATION, 20.0), 20.0)
	assert_near(DeathBurst.progress_alpha(0.0), 1.0)
	assert_near(DeathBurst.progress_alpha(DeathBurst.DURATION), 0.0)


func test_burst_radius_never_shrinks() -> void:
	var last := -1.0
	for i in 11:
		var radius := DeathBurst.progress_radius(DeathBurst.DURATION * i / 10.0, 20.0)
		assert_true(radius >= last, "step %d" % i)
		last = radius


func test_burst_progress_is_clamped() -> void:
	assert_near(DeathBurst.progress_radius(5.0, 20.0), 20.0)
	assert_near(DeathBurst.progress_alpha(5.0), 0.0)
	assert_near(DeathBurst.progress_alpha(-1.0), 1.0)


func test_bosses_get_a_bigger_burst() -> void:
	assert_true(DeathBurst.particle_count(true) > DeathBurst.particle_count(false))
	assert_true(DeathBurst.max_radius(true) > DeathBurst.max_radius(false))


func test_burst_frees_itself_when_done() -> void:
	var burst := DeathBurst.new()
	burst.setup(Color.RED, false)
	burst._process(DeathBurst.DURATION + 0.01)
	assert_true(burst.is_queued_for_deletion())
	burst.free()
