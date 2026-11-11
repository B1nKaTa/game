extends TestCase

const RISK := {"photo_of_grandkids": ["rare", false], "nitro_tablets": ["rare", true], "polyester_suit": ["common", true],
	"prune_juice": ["common", true], "unpaid_bill": ["rare", true], "glass_hip": ["rare", true]}
const ANY := {"floor_plan": "common", "magnifying_glass": "common", "alarm_clock": "common", "early_bird_special": "common",
	"bureaucrats_stamp": "legendary", "bifocals": "rare", "last_orders": "rare", "complaint_form": "rare", "cactus_brooch": "rare"}


func test_the_risk_and_any_items_ship_as_the_list_says() -> void:
	for id: String in RISK:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.build, "risk", id)
		assert_eq(item.rarity, RISK[id][0], id)
		assert_eq(item.cursed, RISK[id][1], id)
		if item.cursed:
			assert_true(item.description.contains("but"), "%s names its cost" % id)
	for id: String in ANY:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.build, "any", id)
		assert_eq(item.rarity, ANY[id], id)
	assert_true(RetiredContent.is_retired("wreath_of_thorns"))
	assert_false(ItemKit.item("bifocals").reveals_enemy_health, "the list names no health bars")


func test_the_polyester_suit_hits_harder_and_shocks_for_half_a_second() -> void:
	var run := ItemKit.new().run_with(["polyester_suit"])
	assert_near(run.stats.damage_mult, 1.35)
	var suit := load("res://scripts/items/polyester_suit.gd")
	assert_near(suit.STUN, 0.5)
	assert_near(suit.CHANCE, 0.1)


func test_the_unpaid_bill_hits_harder_and_takes_ten_a_fight_room() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["unpaid_bill"])
	var enemy := kit.enemy()
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 15.0)
	run.pension_at_start = 0
	kit.pension = 25
	run.effects.room_enter(null)
	assert_eq(kit.pension, 15)
	kit.pension = 5
	run.health.pills = 3
	run.effects.room_enter(null)
	run.effects.room_enter(null)
	assert_eq(run.health.pills, 2, "two halves with nothing to pay")
	assert_eq(kit.pension, 5)
	kit.free_enemies()
	run.effects.room_enter(null)
	assert_eq(run.health.pills, 2, "a room with no fight takes nothing")


func test_the_glass_hip_is_quick_and_every_second_hit_costs_a_pill_more() -> void:
	var run := ItemKit.new().run_with(["glass_hip"])
	assert_near(run.stats.move_speed, PlayerStats.BASE_SPEED * 1.3)
	assert_near(run.stats.swing_speed, 1.3)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 2)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1)
	assert_eq(run.effects.hurt(0, RunEffects.HURT_ENEMY), 0, "a blocked hit costs nothing")


func test_the_photo_and_last_orders_scale_his_hits_only() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["photo_of_grandkids", "last_orders"])
	var last := kit.enemy()
	run.health.pills = 1
	assert_near(run.effects.hit_damage(last, 10.0, RunEffects.SWING), 40.0, "last pill and last enemy")
	assert_near(run.effects.hit_damage(last, 10.0, RunEffects.PET), 10.0)
	assert_near(run.effects.hit_damage(last, 10.0, RunEffects.ALLY), 10.0)
	kit.free_enemies()


func test_the_alarm_clock_stuns_a_full_second() -> void:
	assert_near(load("res://scripts/items/alarm_clock.gd").STUN, 1.0)


func test_the_early_bird_rush_is_a_quarter_faster_and_has_no_combo() -> void:
	var bird := load("res://scripts/items/early_bird_special.gd")
	assert_near(bird.BOOST, 1.25)
	assert_false(FileAccess.get_file_as_string("res://scripts/items/early_bird_special.gd").contains("has_combo"))


func test_the_stamp_takes_a_tenth_of_a_boss() -> void:
	assert_near(load("res://scripts/items/bureaucrats_stamp.gd").BOSS_SHARE, 0.1)
	assert_false(FileAccess.get_file_as_string("res://scripts/items/bureaucrats_stamp.gd").contains("has_combo"))


func test_the_bifocals_finish_regular_enemies_below_fifteen_percent() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["bifocals"])
	var low := kit.enemy("intern_reaper", 6.0)
	run.effects.hit(low, 4.0, RunEffects.SWING)
	assert_true(low.is_dead(), "6 of 42 left: finished")
	var high := kit.enemy("intern_reaper", 30.0)
	run.effects.hit(high, 4.0, RunEffects.SWING)
	assert_false(high.is_dead())
	var boss := kit.enemy("regional_reaper")
	boss.hp = boss.max_hp() * 0.1
	run.effects.hit(boss, 1.0, RunEffects.SWING)
	assert_false(boss.is_dead(), "never a boss")
	kit.free_enemies()


func test_the_cactus_brooch_pricks_and_pushes_what_touches_him() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["cactus_brooch"])
	run.effects.room_enter(null)
	var enemy := kit.enemy()
	enemy.position = Vector2(0, -14)
	var before := enemy.hp
	run.effects.tick(0.01)
	assert_near(before - enemy.hp, 6.0)
	assert_true(enemy.is_pushed())
	run.effects.tick(0.1)
	assert_near(before - enemy.hp, 6.0, "once a half second")
	run.effects.tick(0.5)
	assert_near(before - enemy.hp, 12.0)
	kit.free_enemies()
