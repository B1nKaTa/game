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
	assert_eq(Content.items().size(), 6)
	assert_eq(Content.upgrades().size(), 4)
	for upgrade in Content.upgrades():
		assert_true(upgrade.max_level() > 0, upgrade.id)
