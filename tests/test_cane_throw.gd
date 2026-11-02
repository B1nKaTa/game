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
