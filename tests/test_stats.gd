extends TestCase


func _no_upgrades() -> Array[UpgradeDef]:
	var list: Array[UpgradeDef] = []
	return list


func _no_items() -> Array[ItemDef]:
	var list: Array[ItemDef] = []
	return list


func test_base_stats() -> void:
	var stats := PlayerStats.compute(_no_upgrades(), {}, _no_items())
	assert_eq(stats.max_pills, 4)
	assert_near(stats.move_speed, 120.0)
	assert_near(stats.dodge_cooldown, 1.0)
	assert_near(stats.damage_mult, 1.0)
	assert_near(stats.pension_mult, 1.0)
	assert_near(stats.warning_fraction, 0.5)


func test_upgrade_applies_once_per_level() -> void:
	var cane := UpgradeDef.new()
	cane.id = "cane"
	cane.damage_bonus = 0.1
	var upgrades: Array[UpgradeDef] = [cane]
	var stats := PlayerStats.compute(upgrades, {"cane": 3}, _no_items())
	assert_near(stats.damage_mult, 1.3)


func test_items_add_to_upgrades() -> void:
	var pills := UpgradeDef.new()
	pills.id = "pills"
	pills.bonus_pills = 1
	var upgrades: Array[UpgradeDef] = [pills]
	var organizer := ItemDef.new()
	organizer.bonus_pills = 1
	var items: Array[ItemDef] = [organizer]
	var stats := PlayerStats.compute(upgrades, {"pills": 2}, items)
	assert_eq(stats.max_pills, 7)


func test_dodge_cooldown_cut_is_capped_at_half() -> void:
	var prune := ItemDef.new()
	prune.dodge_cooldown_cut = 0.9
	var items: Array[ItemDef] = [prune]
	var stats := PlayerStats.compute(_no_upgrades(), {}, items)
	assert_near(stats.dodge_cooldown, 0.5)


func test_warning_fraction_is_capped_at_one() -> void:
	var aid := ItemDef.new()
	aid.warning_bonus = 0.9
	var items: Array[ItemDef] = [aid]
	var stats := PlayerStats.compute(_no_upgrades(), {}, items)
	assert_near(stats.warning_fraction, 1.0)


func test_upgrade_prices() -> void:
	var def := UpgradeDef.new()
	def.prices = PackedInt32Array([10, 20])
	assert_eq(def.max_level(), 2)
	assert_eq(def.price_at(1), 20)
	assert_eq(def.price_at(2), -1)


func test_shipped_content_loads() -> void:
	assert_eq(Content.items().size(), 16)
	assert_eq(Content.upgrades().size(), 7)
	for upgrade in Content.upgrades():
		assert_true(upgrade.max_level() > 0, upgrade.id)


func test_upgrades_default_to_the_black_market() -> void:
	assert_eq(UpgradeDef.new().merchant, "black_market")


func test_upgrades_for_filters_by_merchant() -> void:
	var market := Content.upgrades_for("black_market")
	var optometrist := Content.upgrades_for("optometrist")
	assert_eq(market.size(), 5)
	assert_eq(optometrist.size(), 1)
	assert_eq(optometrist[0].id, "prescription_glasses")
	assert_eq(Content.upgrades_for("nobody").size(), 0)


func test_glasses_content() -> void:
	var glasses: UpgradeDef = null
	for upgrade in Content.upgrades():
		if upgrade.id == "prescription_glasses":
			glasses = upgrade
	assert_true(glasses != null)
	assert_eq(glasses.max_level(), 1)
	assert_eq(glasses.price_at(0), 40)
	assert_true(glasses.reveals_enemy_health)


func test_enemy_health_is_hidden_by_default() -> void:
	var stats := PlayerStats.compute(_no_upgrades(), {}, _no_items())
	assert_false(stats.reveals_enemy_health)


func test_glasses_reveal_enemy_health_only_when_owned() -> void:
	var glasses := UpgradeDef.new()
	glasses.id = "glasses"
	glasses.reveals_enemy_health = true
	var upgrades: Array[UpgradeDef] = [glasses]
	assert_false(PlayerStats.compute(upgrades, {"glasses": 0}, _no_items()).reveals_enemy_health)
	assert_true(PlayerStats.compute(upgrades, {"glasses": 1}, _no_items()).reveals_enemy_health)


func test_a_form_below_its_milestone_adds_only_its_levels() -> void:
	var cane := UpgradeDef.new()
	cane.id = "cane"
	cane.damage_bonus = 0.1
	cane.milestone_level = 2
	cane.option_a = StatEffect.new()
	cane.option_a.damage_bonus = 0.5
	cane.option_b = StatEffect.new()
	var upgrades: Array[UpgradeDef] = [cane]
	assert_near(PlayerStats.compute(upgrades, {"cane": 1}, _no_items()).damage_mult, 1.1)
	assert_near(PlayerStats.compute(upgrades, {"cane": 2}, _no_items()).damage_mult, 1.7, "option A from the milestone on")
	assert_near(PlayerStats.compute(upgrades, {"cane": 2}, _no_items(), {"cane": "b"}).damage_mult, 1.2)
