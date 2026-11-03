extends TestCase


func test_charged_swings_and_bites_freeze_longest() -> void:
	assert_near(HitStop.duration_for(true, false), 0.06)
	assert_near(HitStop.BITE_HIT, 0.06)


func test_finisher_freezes_briefly_and_plain_combo_hits_not_at_all() -> void:
	assert_near(HitStop.duration_for(false, true), 0.03)
	assert_near(HitStop.duration_for(false, false), 0.0)


func test_freeze_counts_down_in_real_time_and_ends() -> void:
	var stop := HitStop.new()
	assert_near(stop.time_scale(), 1.0)
	stop.request(0.06)
	assert_true(stop.is_active())
	assert_near(stop.time_scale(), 0.0)
	stop.tick(0.03)
	assert_true(stop.is_active())
	stop.tick(0.04)
	assert_false(stop.is_active())
	assert_near(stop.time_scale(), 1.0)


func test_overlapping_requests_take_the_longest_not_the_sum() -> void:
	var stop := HitStop.new()
	stop.request(0.06)
	stop.request(0.03)
	stop.tick(0.061)
	assert_false(stop.is_active())


func test_cancel_ends_a_freeze_at_once() -> void:
	var stop := HitStop.new()
	stop.request(0.06)
	stop.cancel()
	assert_near(stop.time_scale(), 1.0)


func test_zero_request_does_nothing() -> void:
	var stop := HitStop.new()
	stop.request(0.0)
	assert_false(stop.is_active())


func test_a_freeze_is_capped() -> void:
	var stop := HitStop.new()
	stop.request(99.0)
	stop.tick(HitStop.MAX_TIME + 0.01)
	assert_false(stop.is_active(), "an absurd request can never freeze the game for long")
