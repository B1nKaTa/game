extends TestCase


func test_bar_fraction_is_hp_over_max() -> void:
	assert_near(Hud.bar_fraction(50.0, 200.0), 0.25)


func test_bar_fraction_is_clamped() -> void:
	assert_near(Hud.bar_fraction(-5.0, 100.0), 0.0)
	assert_near(Hud.bar_fraction(500.0, 100.0), 1.0)


func test_bar_fraction_handles_zero_max() -> void:
	assert_near(Hud.bar_fraction(10.0, 0.0), 0.0)


func test_the_waiting_room_shows_both_currencies_and_a_run_only_pension() -> void:
	assert_eq(Hud.status_text(12, 3, true), "Pension: 12   Condolences: 3")
	assert_eq(Hud.status_text(12, 3, false), "Pension: 12")
