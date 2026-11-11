extends TestCase

const DODGE := {"pocket_watch": "rare", "wheelchair_wheels": "rare", "titanium_hip": "rare", "pogo_cane": "rare",
	"velcro_shoes": "common", "afterimage": "rare", "bad_hip": "common", "rocking_chair": "common"}
const PILLS := {"heart_monitor": "legendary", "hospital_bracelet": "common", "comfort_care_lanyard": "rare",
	"pill_organizer": "common", "casserole_dish": "common", "life_alert_button": "rare", "life_jacket": "rare",
	"eternal_warranty": "legendary"}


func test_the_dodge_and_pill_items_ship_as_the_list_says() -> void:
	for id: String in DODGE:
		var item := ItemKit.item(id)
		assert_eq(item.build, "dodge", id)
		assert_eq(item.rarity, DODGE[id], id)
	for id: String in PILLS:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.build, "pills", id)
		assert_eq(item.rarity, PILLS[id], id)


func test_the_titanium_hip_hits_for_a_whole_swing() -> void:
	assert_near(load("res://scripts/items/titanium_hip.gd").SHARE, 1.0)


func test_velcro_shoes_add_a_dodge_with_no_longer_cooldown() -> void:
	var run := ItemKit.new().run_with(["velcro_shoes"])
	assert_eq(run.stats.dodge_charges, 2)
	assert_near(run.stats.dodge_cooldown, PlayerStats.BASE_DODGE_COOLDOWN)


func test_the_bad_hip_cough_is_bigger_and_longer() -> void:
	var hip := load("res://scripts/items/bad_hip.gd")
	assert_near(hip.RADIUS, 36.0)
	assert_near(hip.TIME, 3.0)
	assert_near(hip.SHARE, 0.5)


func test_the_heart_monitor_adds_six_percent_a_pill_of_maximum() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["heart_monitor", "hospital_bracelet"])
	var enemy := kit.enemy()
	assert_eq(run.health.max_pills, PlayerStats.BASE_PILLS + 1)
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 13.0)
	kit.free_enemies()


func test_the_organizer_stores_three_heals_and_each_soaks_a_whole_hit() -> void:
	var run := ItemKit.new().run_with(["pill_organizer"])
	assert_eq(run.stats.max_pills, PlayerStats.BASE_PILLS, "no extra pill any more")
	var organizer = run.effects.effect_of("pill_organizer")
	assert_true(run.effects.accepts_pickup(RunEffects.HEAL))
	for i in 4:
		run.effects.pickup(RunEffects.HEAL, 1)
	assert_eq(organizer.stored, 3)
	assert_eq(run.effects.hurt(2, RunEffects.HURT_ENEMY), 0, "a whole hit, however big")
	assert_eq(organizer.stored, 2)
	run.effects.ctx.counting_pills = true
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1)


func test_the_kept_pill_rules_stand() -> void:
	var kit := ItemKit.new()
	assert_eq(kit.run_with(["hospital_bracelet"]).stats.max_pills, PlayerStats.BASE_PILLS + 1)
	var lanyard := kit.run_with(["comfort_care_lanyard"])
	assert_eq(lanyard.stats.max_pills, PlayerStats.BASE_PILLS + 1)
	assert_eq(lanyard.stats.heal_bonus, 1)
	assert_eq(kit.run_with(["life_jacket"]).stats.floor_lethal_saves, 1)
