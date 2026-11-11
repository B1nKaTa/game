extends TestCase

const IDS := {"strong_dentures": "rare", "boomerang_bite": "common", "spare_set": "rare", "shark_tooth": "legendary",
	"glue_gun": "rare", "chattering_bounce": "rare", "windup_teeth": "rare", "fizzy_tablet": "common", "dentures_in_glass": "common"}


func test_the_denture_items_ship_as_the_list_says() -> void:
	for id: String in IDS:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.build, "bite", id)
		assert_eq(item.rarity, IDS[id], id)
		assert_eq(Array(item.tags), ["bite"], id)
	assert_true(RetiredContent.is_retired("dentures"))


func test_extra_strong_dentures_bite_harder_and_through_two() -> void:
	var run := ItemKit.new().run_with(["strong_dentures"])
	assert_near(run.stats.bite_damage_mult, 1.5)
	assert_eq(run.stats.bites_per_throw, 2)


func test_the_kept_denture_rules_stand() -> void:
	var kit := ItemKit.new()
	assert_true(kit.run_with(["boomerang_bite"]).stats.teeth_boomerang)
	assert_eq(kit.run_with(["spare_set"]).stats.teeth_sets, 2)
	assert_near(kit.run_with(["glue_gun"]).stats.teeth_glue_time, 2.0)
	assert_true(kit.run_with(["windup_teeth"]).stats.teeth_floor_bite)


func test_the_chatter_jumps_to_three_more_enemies_then_stops() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["chattering_bounce"])
	var line: Array[Enemy] = []
	for i in 5:
		var enemy := kit.enemy()
		enemy.position = Vector2(100 * i, 0)
		line.append(enemy)
	var bite := ThrownDentures.bite_damage(run.bite_damage_mult())
	run.effects.throw()
	run.effects.bite(line[0])
	for i in range(1, 4):
		assert_near(line[i].max_hp() - line[i].hp, bite, "jump %d" % i)
	assert_near(line[4].hp, line[4].max_hp(), "three jumps a throw")
	kit.free_enemies()


func test_the_fizz_slows_for_two_seconds() -> void:
	var fizzy := load("res://scripts/items/fizzy_tablet.gd")
	assert_near(fizzy.TIME, 2.0)
	assert_near(fizzy.SHARE, 0.5)


func test_dentures_in_a_glass_swing_a_quarter_faster() -> void:
	var glass := load("res://scripts/items/dentures_in_glass.gd")
	assert_near(glass.PACE, 1.25)
