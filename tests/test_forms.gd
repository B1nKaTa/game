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
