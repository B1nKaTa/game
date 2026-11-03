extends TestCase


func _run(levels := {}) -> RunState:
	var pills := UpgradeDef.new()
	pills.id = "pills"
	pills.bonus_pills = 1
	var upgrades: Array[UpgradeDef] = [pills]
	return RunState.new(upgrades, levels)


func test_hit_removes_pills_and_grants_invulnerability() -> void:
	var health := Health.new(4)
	assert_true(health.hit(1))
	assert_eq(health.pills, 3)
	assert_false(health.hit(1), "invulnerable")
	assert_eq(health.pills, 3)
	health.tick(Health.INVULN_TIME + 0.01)
	assert_true(health.hit(1))
	assert_eq(health.pills, 2)


func test_death_signal_fires_once() -> void:
	var health := Health.new(1)
	var deaths := [0]
	health.died.connect(func(): deaths[0] += 1)
	health.hit(5)
	health.tick(Health.INVULN_TIME + 0.01)
	health.hit(1)
	assert_eq(deaths[0], 1)
	assert_true(health.is_dead())
	assert_eq(health.pills, 0)


func test_heal_stops_at_max() -> void:
	var health := Health.new(4)
	health.hit(3)
	health.heal(2)
	assert_eq(health.pills, 3)
	health.heal(5)
	assert_eq(health.pills, 4)


func test_raise_max_adds_the_difference() -> void:
	var health := Health.new(4)
	health.hit(2)
	health.raise_max(5)
	assert_eq(health.max_pills, 5)
	assert_eq(health.pills, 3)


func test_a_lower_max_never_leaves_more_pills_than_it_allows() -> void:
	var health := Health.new(34)
	health.raise_max(4)
	assert_eq(health.max_pills, 4)
	assert_eq(health.pills, 4)
	var hurt := Health.new(6)
	hurt.hit(4)
	hurt.raise_max(4)
	assert_eq(hurt.pills, 2, "a lower maximum takes nothing he is not holding")


func test_run_starts_with_upgrades_applied() -> void:
	var run := _run({"pills": 2})
	assert_eq(run.stats.max_pills, 6)
	assert_eq(run.health.pills, 6)


func test_extra_pill_item_raises_and_restores() -> void:
	var run := _run()
	var organizer := ItemDef.new()
	organizer.id = "organizer"
	organizer.bonus_pills = 1
	run.add_item(organizer)
	assert_eq(run.stats.max_pills, 5)
	assert_eq(run.health.pills, 5)
	assert_true(run.has_item("organizer"))


func test_item_changes_stats_and_signals() -> void:
	var run := _run()
	var calls := [0]
	run.changed.connect(func(): calls[0] += 1)
	var dentures := ItemDef.new()
	dentures.damage_bonus = 0.5
	run.add_item(dentures)
	assert_near(run.stats.damage_mult, 1.5)
	assert_eq(calls[0], 1)


func test_pension_amount_rounds_up() -> void:
	var run := _run()
	var card := ItemDef.new()
	card.pension_bonus = 0.25
	run.add_item(card)
	assert_eq(run.pension_amount(5), 7)
