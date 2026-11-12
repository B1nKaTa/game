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


func test_the_rod_draws_a_bolt_then_a_blast() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["lightning_rod"])
	var enemy := kit.enemy("intern_reaper", 60.0)
	run.effects.charge_release(true)
	run.effects.hit(enemy, 30.0, RunEffects.CHARGE)
	assert_eq(kit.fx_of(ItemFx.FxBolt).size(), 1, "one bolt falls on the enemy")
	var rod := load("res://scripts/items/lightning_rod.gd")
	assert_near(rod.HEIGHT, 160.0, "falling from 160 px up")
	assert_near(rod.RADIUS, 14.0, "and the existing blast follows it")
	kit.free_enemies()


func test_a_bolt_is_a_zig_zag_that_never_crosses() -> void:
	var bolt := ItemFx.make_bolt(160.0, Color("cfe8ff"))
	assert_near(bolt.life, 0.25)
	var points := ItemFx.bolt_points(160.0)
	assert_true(points.size() >= 6 and points.size() <= 8, "5 to 7 segments")
	assert_near(points[0].y, -160.0, "it starts 160 px above")
	assert_near(points[-1].x, 0.0, "it ends on the enemy")
	assert_near(points[-1].y, 0.0)
	var last_side := 0.0
	for i in points.size() - 1:
		var step: Vector2 = points[i + 1] - points[i]
		assert_true(step.y > 0.0, "always downward, so no stroke can cross another")
		assert_true(rad_to_deg(atan2(absf(step.x), step.y)) >= 20.0, "each at least 20 degrees off vertical")
		assert_true(step.x * last_side <= 0.0, "alternating sides")
		last_side = signf(step.x)
	bolt.free()


func test_a_charged_swings_release_reaches_the_items_before_its_first_strike() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	var swing := source.substr(source.find("func _swing("), 1800)
	var release := swing.find("run.effects.charge_release(true)")
	assert_true(release > 0, "the swing sends the release")
	assert_true(release < swing.find("_strike_enemies()"), "before the first frame's strike")
	var attacks := source.substr(source.find("func _handle_attacks("), 3000)
	assert_false(attacks.contains("charge_release"), "and only the swing sends it")


func test_a_first_frame_charged_hit_lands_the_bolt() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["lightning_rod"])
	var enemy := kit.enemy("intern_reaper", 60.0)
	# The order a charged swing now sends: the release, then the strike through land.
	run.effects.charge_release(true)
	run.effects.land(enemy, 30.0, RunEffects.CHARGE)
	assert_near(enemy.hp, 10.0, "30 for the swing and 20 for the bolt")
	run.effects.swing_end(null)
	kit.free_enemies()
