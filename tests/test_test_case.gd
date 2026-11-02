extends TestCase


func test_assert_eq_records_mismatch() -> void:
	var probe := TestCase.new()
	probe.assert_eq(1, 2, "numbers")
	assert_eq(probe.failures.size(), 1)


func test_assert_eq_passes_on_match() -> void:
	var probe := TestCase.new()
	probe.assert_eq("a", "a")
	assert_eq(probe.failures.size(), 0)


func test_assert_eq_handles_mixed_types() -> void:
	var probe := TestCase.new()
	probe.assert_eq(1, "one")
	assert_eq(probe.failures.size(), 1)


func test_assert_near_allows_small_difference() -> void:
	var probe := TestCase.new()
	probe.assert_near(1.0, 1.00001)
	assert_eq(probe.failures.size(), 0)
