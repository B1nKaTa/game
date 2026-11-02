extends TestCase


func _data(pension := 2000) -> ProgressData:
	var data := ProgressData.new()
	data.pension = pension
	return data


func test_tiers_and_cap_match_the_design() -> void:
	assert_eq(ProgressData.RETIREMENT_CAP, 1000)
	assert_eq(ProgressData.RETIREMENT_TIERS, [10, 50, 100, 250, 500, 750, 1000])


func test_depositing_moves_pension_into_the_plan() -> void:
	var data := _data(100)
	data.retirement_deposit(30)
	assert_eq(data.pension, 70)
	assert_eq(data.retirement_balance, 30)


func test_deposit_cannot_exceed_what_you_have() -> void:
	var data := _data(5)
	data.retirement_deposit(10)
	assert_eq(data.pension, 0)
	assert_eq(data.retirement_balance, 5)


func test_deposit_stops_at_the_cap() -> void:
	var data := _data(2000)
	data.retirement_deposit(1500)
	assert_eq(data.retirement_balance, 1000)
	assert_eq(data.pension, 1000, "the rest stays yours")


func test_nothing_to_deposit_earns_nothing() -> void:
	var data := _data(0)
	assert_eq(data.retirement_deposit(10), 0)
	assert_eq(data.retirement_balance, 0)


func test_crossing_a_tier_is_reported() -> void:
	var data := _data()
	assert_eq(data.retirement_deposit(9), 0)
	assert_eq(data.retirement_deposit(1), 1, "reached 10")
	assert_eq(data.retirement_deposit(30), 0, "40 is short of 50")


func test_a_big_deposit_can_cross_several_tiers() -> void:
	var data := _data()
	assert_eq(data.retirement_deposit(250), 4, "10, 50, 100 and 250")
	assert_eq(data.retirement_deposit(750), 3, "500, 750 and 1000")


func test_cashing_out_needs_a_later_run() -> void:
	var data := _data()
	data.retirement_deposit(100)
	assert_false(data.can_release_retirement(), "locked in the run it was deposited")
	assert_eq(data.release_retirement(), 0)
	assert_eq(data.retirement_balance, 100)
	data.start_run()
	assert_true(data.can_release_retirement())


func test_cashing_out_returns_everything() -> void:
	var data := _data(100)
	data.retirement_deposit(60)
	data.start_run()
	assert_eq(data.release_retirement(), 60)
	assert_eq(data.retirement_balance, 0)
	assert_eq(data.pension, 100)
	assert_false(data.can_release_retirement(), "empty")


func test_a_new_deposit_locks_the_plan_again() -> void:
	var data := _data()
	data.retirement_deposit(60)
	data.start_run()
	data.retirement_deposit(10)
	assert_false(data.can_release_retirement())


func test_tiers_cannot_be_earned_twice_by_cashing_out() -> void:
	var data := _data()
	assert_eq(data.retirement_deposit(100), 3)
	data.start_run()
	data.release_retirement()
	data.start_run()
	assert_eq(data.retirement_deposit(100), 0, "same tiers again pay nothing")
	assert_eq(data.retirement_deposit(150), 1, "the next new tier still pays")


func test_next_tier_follows_the_best_ever_reached() -> void:
	var data := _data()
	assert_eq(data.next_retirement_tier(), 10)
	data.retirement_deposit(60)
	assert_eq(data.next_retirement_tier(), 100)
	data.start_run()
	data.release_retirement()
	assert_eq(data.next_retirement_tier(), 100, "cashing out doesn't reset it")
	data.retirement_deposit(1000)
	assert_eq(data.next_retirement_tier(), -1, "all earned")


func test_spending_needs_enough_pension() -> void:
	var data := _data(50)
	assert_false(data.spend(60))
	assert_eq(data.pension, 50)
	assert_true(data.spend(50))
	assert_eq(data.pension, 0)


func test_the_plan_is_saved_and_loaded() -> void:
	var data := _data(500)
	data.retirement_deposit(120)
	data.start_run()
	var loaded := ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))
	assert_eq(loaded.retirement_balance, 120)
	assert_eq(loaded.retirement_peak, 120)
	assert_eq(loaded.run_count, 1)
	assert_true(loaded.can_release_retirement(), "the deposit run is remembered")


func test_saves_from_before_the_plan_still_load() -> void:
	var old := {"version": 1, "pension": 1242, "upgrades": {"better_knees": 3}, "opening_seen": true}
	var loaded := ProgressData.from_dict(old)
	assert_true(loaded != null)
	assert_eq(loaded.pension, 1242)
	assert_eq(loaded.level_of("better_knees"), 3)
	assert_eq(loaded.retirement_balance, 0)
	assert_false(loaded.can_release_retirement())


func test_bad_plan_values_are_made_safe() -> void:
	var raw := {"version": 1, "pension": 5, "upgrades": {}, "opening_seen": true, "retirement_balance": 5000, "retirement_peak": -3}
	var loaded := ProgressData.from_dict(raw)
	assert_eq(loaded.retirement_balance, 1000)
	assert_eq(loaded.retirement_peak, 1000, "never below the balance")
