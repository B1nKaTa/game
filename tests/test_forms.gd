extends TestCase


func _shipped(id: String) -> UpgradeDef:
	for def in Content.upgrades():
		if def.id == id:
			return def
	return null


func _stats(id: String, level: int, choice := "") -> PlayerStats:
	var def := _shipped(id)
	var upgrades: Array[UpgradeDef] = [def]
	var choices := {} if choice.is_empty() else {id: choice}
	var items: Array[ItemDef] = []
	return PlayerStats.compute(upgrades, {id: level}, items, choices)


func _run(id: String, level: int, choice: String) -> RunState:
	var def := _shipped(id)
	var upgrades: Array[UpgradeDef] = [def]
	return RunState.new(upgrades, {id: level}, {id: choice})


func test_every_form_has_a_milestone_with_two_named_options() -> void:
	for def in Content.upgrades():
		assert_true(def.has_choice(), def.id)
		assert_true(def.milestone_level >= 1 and def.milestone_level <= def.max_level(), def.id)
		for choice in [UpgradeDef.OPTION_A, UpgradeDef.OPTION_B]:
			assert_false(def.option_name(choice).is_empty(), "%s %s" % [def.id, choice])
			assert_true(def.option(choice) != null, "%s %s" % [def.id, choice])


func test_nothing_changes_below_the_milestone() -> void:
	assert_near(_stats("reinforced_cane", 1, "b").damage_mult, 1.1)
	assert_near(_stats("reinforced_cane", 1, "b").swing_speed, 1.0)


func test_a_missing_choice_reads_as_option_a() -> void:
	assert_near(_stats("reinforced_cane", 2).damage_mult, 1.0 + 0.2 + 0.15)
	assert_near(_stats("reinforced_cane", 2).swing_speed, 0.9)


func test_option_b_of_each_form() -> void:
	assert_near(_stats("reinforced_cane", 2, "b").swing_speed, 1.2)
	assert_near(_stats("better_knees", 2, "b").dodge_cooldown, PlayerStats.BASE_DODGE_COOLDOWN * (1.0 - 0.2 - 0.15))
	assert_eq(_stats("black_market_pills", 2, "b").heal_bonus, 1)
	assert_near(_stats("bribed_clerk", 2, "b").reward_pension_mult, 1.3)
	assert_true(_stats("prescription_glasses", 1, "b").reveals_secrets)
	assert_near(_stats("denture_adhesive", 2, "b").teeth_return_delay, DentureThrow.RETURN_DELAY - 1.0)
	assert_eq(_stats("thermos_fuel", 2, "b").bonus_bombs, 1)


func test_option_a_of_each_form() -> void:
	assert_near(_stats("better_knees", 2, "a").dodge_length, 1.3)
	assert_eq(_stats("black_market_pills", 2, "a").max_pills, PlayerStats.BASE_PILLS + 3)
	assert_near(_stats("bribed_clerk", 2, "a").enemy_pension_mult, 1.2)
	assert_near(_stats("prescription_glasses", 1, "a").wounded_damage_mult, 1.2)
	assert_near(_stats("denture_adhesive", 2, "a").bite_damage_mult, 1.0 + 0.3 + 0.25)
	assert_near(_stats("thermos_fuel", 2, "a").blast_radius, Thermos.BLAST_RADIUS * 1.3)


func test_the_option_counts_once_at_the_top_level() -> void:
	assert_near(_stats("reinforced_cane", 3, "a").damage_mult, 1.0 + 0.3 + 0.15)


func test_the_quick_return_and_boomerang_never_go_below_a_second() -> void:
	assert_near(_stats("denture_adhesive", 3, "b").teeth_return_delay, PlayerStats.MIN_TEETH_RETURN)


func test_a_spare_can_starts_the_run_with_one_more_thermos() -> void:
	var run := _run("thermos_fuel", 2, "b")
	assert_eq(run.bombs, RunState.STARTING_BOMBS + 1)


func test_a_slower_lock_holds_the_next_swing_longer() -> void:
	var combo := CaneCombo.new()
	combo.lock_time = CaneCombo.LOCK_TIME / 0.9
	combo.try_attack()
	combo.tick(CaneCombo.LOCK_TIME + 0.001)
	assert_eq(combo.try_attack(), 0, "still locked")


func test_a_longer_dodge_lasts_longer() -> void:
	var dodge := DodgeTimer.new()
	dodge.try_start(1.0, DodgeTimer.DURATION * 1.3)
	dodge.tick(DodgeTimer.DURATION + 0.01)
	assert_true(dodge.is_active())


func test_pills_heal_more_never_past_the_maximum() -> void:
	var health := Health.new(4)
	health.heal_bonus = 1
	health.hit(3)
	health.heal(1)
	assert_eq(health.pills, 3)
	health.heal(2)
	assert_eq(health.pills, 4)


func test_a_stronger_dose_reaches_the_run_health() -> void:
	var run := _run("black_market_pills", 2, "b")
	assert_eq(run.health.heal_bonus, 1)


func test_pension_by_source() -> void:
	var run := _run("bribed_clerk", 2, "a")
	assert_eq(run.pension_amount(10, RunState.PENSION_ENEMY), ceili(10 * 1.2 * 1.2))
	assert_eq(run.pension_amount(10, RunState.PENSION_REWARD), ceili(10 * 1.2))
	assert_eq(run.pension_amount(10), ceili(10 * 1.2))


func test_the_weak_spot_only_counts_below_half_health() -> void:
	assert_near(PlayerStats.strike_damage(10.0, 0.6, 1.2), 10.0)
	assert_near(PlayerStats.strike_damage(10.0, 0.4, 1.2), 12.0)


func test_a_thermos_reaches_as_far_as_its_radius() -> void:
	var body := Rect2(Thermos.BLAST_RADIUS + 5.0, -10, 20, 20)
	assert_false(Thermos.in_blast(Vector2.ZERO, body))
	assert_true(Thermos.in_blast(Vector2.ZERO, body, Thermos.BLAST_RADIUS * 1.3))


func _data_with(pension: int, levels := {}) -> ProgressData:
	var data := ProgressData.new()
	data.pension = pension
	data.upgrades = levels.duplicate()
	return data


func test_filing_the_milestone_stores_the_choice() -> void:
	var cane := _shipped("reinforced_cane")
	var data := _data_with(1000, {"reinforced_cane": 1})
	assert_eq(data.choice_of(cane), "")
	assert_false(data.buy(cane, "z"))
	assert_true(data.buy(cane, "b"))
	assert_eq(data.choice_of(cane), "b")
	assert_eq(data.level_of("reinforced_cane"), 2)


func test_filing_without_a_choice_takes_option_a() -> void:
	var cane := _shipped("reinforced_cane")
	var data := _data_with(1000, {"reinforced_cane": 1})
	assert_true(data.buy(cane))
	assert_eq(data.choice_of(cane), "a")


func test_filing_past_the_milestone_keeps_the_choice() -> void:
	var cane := _shipped("reinforced_cane")
	var data := _data_with(1000, {"reinforced_cane": 2})
	data.form_choices["reinforced_cane"] = "b"
	assert_true(data.buy(cane, "a"), "an option off the milestone is ignored")
	assert_eq(data.choice_of(cane), "b")


func test_the_first_refile_is_free_and_the_next_costs_the_fee() -> void:
	var cane := _shipped("reinforced_cane")
	var data := _data_with(100, {"reinforced_cane": 2})
	assert_eq(data.refile_price(cane), 0)
	assert_true(data.refile(cane))
	assert_eq(data.choice_of(cane), "b")
	assert_eq(data.pension, 100)
	assert_eq(data.refile_price(cane), ProgressData.REFILE_FEE)
	assert_true(data.refile(cane))
	assert_eq(data.choice_of(cane), "a")
	assert_eq(data.pension, 100 - ProgressData.REFILE_FEE)


func test_a_refile_waits_for_the_fee() -> void:
	var cane := _shipped("reinforced_cane")
	var data := _data_with(ProgressData.REFILE_FEE - 1, {"reinforced_cane": 2})
	data.free_refile_used["reinforced_cane"] = true
	assert_false(data.refile(cane))
	assert_eq(data.choice_of(cane), "a")


func test_nothing_to_refile_below_the_milestone() -> void:
	var cane := _shipped("reinforced_cane")
	var data := _data_with(100, {"reinforced_cane": 1})
	assert_eq(data.refile_price(cane), -1)
	assert_false(data.refile(cane))


func test_the_clerk_deal_takes_a_quarter_off_one_form() -> void:
	var cane := _shipped("reinforced_cane")
	var data := _data_with(1000)
	data.clerk_deal = "reinforced_cane"
	assert_eq(data.price_of(cane), ceili(50 * 0.75))
	assert_eq(data.price_of(_shipped("better_knees")), 30, "only the form on deal")
	assert_true(data.buy(cane))
	assert_eq(data.pension, 1000 - ceili(50 * 0.75))


func test_a_form_row_shows_its_stamps() -> void:
	assert_eq(FormText.stamps(_shipped("reinforced_cane"), 2), "[FILED] [FILED] [ ]")


func test_a_form_row_names_its_option_and_price() -> void:
	var cane := _shipped("reinforced_cane")
	var text := FormText.row(cane, 2, 240, "b")
	assert_true(text.contains("Reinforced Cane"), text)
	assert_true(text.contains("Lightweight"), text)
	assert_true(text.contains("240 Pension"), text)
	assert_true(FormText.row(cane, 3, -1, "b").contains(FormText.FILED_IN_FULL))


func test_a_refile_row_names_both_options_and_the_price() -> void:
	var cane := _shipped("reinforced_cane")
	assert_eq(FormText.refile_row(cane, "a", 0), "Reinforced Cane: Heavy Head -> Lightweight  Free")
	assert_eq(FormText.refile_row(cane, "b", 40), "Reinforced Cane: Lightweight -> Heavy Head  40 Pension")
