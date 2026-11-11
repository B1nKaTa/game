extends TestCase

const IDS := {"cane_sword": "rare", "brass_topper": "rare", "lightning_rod": "rare", "rolling_pin": "legendary",
	"reapers_scythe": "legendary", "knitting_needles": "rare", "cane_hook": "common", "rusty_hinge": "common",
	"bingo_dabber": "common", "obituary_clippings": "common"}


func test_the_cane_items_ship_as_the_list_says() -> void:
	for id: String in IDS:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.build, "cane", id)
		assert_eq(item.rarity, IDS[id], id)
	assert_eq(ItemKit.item("brass_topper").display_name, "Brass Cane Topper")
	assert_eq(ItemKit.item("knitting_needles").display_name, "Knitting Needles")
	assert_eq(ItemKit.item("cane_hook").display_name, "Shepherd's Crook Handle")


func test_the_lightning_rod_strikes_what_a_full_charge_hits() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["lightning_rod"])
	var enemy := kit.enemy("intern_reaper", 40.0)
	run.effects.charge_release(true)
	run.effects.hit(enemy, 30.0, RunEffects.CHARGE)
	assert_near(enemy.hp, 20.0, "a bolt of 20")
	run.effects.charge_release(false)
	run.effects.hit(enemy, 30.0, RunEffects.CHARGE)
	assert_near(enemy.hp, 20.0, "a half charge calls no bolt")
	kit.free_enemies()


func test_the_crook_pulls_what_a_finisher_hits() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["cane_hook"])
	var enemy := kit.enemy()
	enemy.position = Vector2(60, 0)
	var boss := kit.enemy("regional_reaper")
	boss.position = Vector2(60, 20)
	run.effects.hit(enemy, 18.0, RunEffects.SWING)
	assert_false(enemy.is_pushed(), "only the finisher hooks")
	run.effects.hit(enemy, 18.0, RunEffects.COMBO_3)
	run.effects.hit(boss, 18.0, RunEffects.COMBO_3)
	assert_true(enemy.is_pushed())
	assert_false(boss.is_pushed(), "never a boss")
	kit.free_enemies()


func test_the_rusty_hinge_stuns_a_full_second() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["rusty_hinge"])
	var hinge := load("res://scripts/items/rusty_hinge.gd")
	assert_near(hinge.STUN_TIME, 1.0)
	assert_near(hinge.AGAIN_AFTER, 2.5)
	var enemy := kit.enemy()
	run.effects.hit(enemy, 18.0, RunEffects.COMBO_3)
	assert_true(enemy.is_stunned())
	kit.free_enemies()


func test_obituaries_add_five_percent_a_kill_up_to_half_and_say_so() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["obituary_clippings"])
	var enemy := kit.enemy()
	run.effects.room_enter(null)
	for i in 3:
		run.effects.kill(kit.enemy(), RunEffects.SWING)
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 11.5)
	var pops := kit.fx_of(ItemFx.FxPop)
	assert_eq(pops.size(), 3)
	assert_eq(pops[2]["text"], "+15%")
	for i in 12:
		run.effects.kill(kit.enemy(), RunEffects.SWING)
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 15.0)
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.PET), 10.0, "a pet's bite is not his hit")
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.ALLY), 10.0, "an ally's hit is not his")
	kit.free_enemies()
