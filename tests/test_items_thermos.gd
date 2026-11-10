extends TestCase

const IDS := {"tea_urn": "legendary", "flask_holster": "common", "bottomless_flask": "rare", "hot_soup_thermos": "rare",
	"pressure_cooker": "rare", "tea_cosy": "common", "second_brew": "rare", "thermos_lob": "legendary", "tea_break": "rare"}


func test_the_thermos_items_ship_as_the_list_says() -> void:
	for id: String in IDS:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.build, "thermos", id)
		assert_eq(item.kind, ItemDef.KIND_PASSIVE, id)
		assert_eq(item.rarity, IDS[id], id)
		assert_eq(Array(item.tags), ["thermos"], id)
		assert_false(item.cursed, id)
	assert_eq(ItemKit.item("thermos_lob").display_name, "Overarm Bowler")
	assert_eq(ItemKit.item("tea_urn").description, "Every Thermos you carry makes all your hits 5% harder.")
	assert_true(RetiredContent.is_retired("second_thermos_strap"))


func test_tea_urn_adds_five_percent_per_thermos_counted() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["tea_urn"])
	var enemy := kit.enemy()
	run.bombs = 4
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 12.0)
	run.bombs = 50
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.BITE), 20.0, "at most 20 count")
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.PET), 10.0, "a pet's bite is not his hit")
	run.effects.ctx.counting_exact = true
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 10.0)
	kit.free_enemies()


func test_flask_holster_gives_two_and_lets_four_more_count() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var before := run.bombs
	run.add_item(ItemKit.item("flask_holster"))
	assert_eq(run.bombs, before + 2)
	run.bombs = 50
	assert_eq(run.scaled_bombs(), 24)
	run.add_item(ItemKit.item("tea_urn"))
	var enemy := kit.enemy()
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 22.0)
	kit.free_enemies()


func test_bottomless_flask_gives_a_thermos_every_second_clear() -> void:
	var run := ItemKit.new().run_with(["bottomless_flask"])
	run.bombs = 0
	run.effects.room_clear(null)
	assert_eq(run.bombs, 0)
	run.effects.room_clear(null)
	assert_eq(run.bombs, 1)
	run.effects.room_clear(null)
	run.effects.room_clear(null)
	assert_eq(run.bombs, 2)
	assert_eq(run.effects.effect_of("bottomless_flask").save_state(), {"cleared": 4})


func test_hot_soup_lays_a_three_second_puddle_on_every_blast() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["hot_soup_thermos"])
	run.effects.bomb(Vector2.ZERO)
	assert_eq(kit.fx_of(ItemFx.FxSoup).size(), 1)
	assert_near(run.effects.effect_of("hot_soup_thermos").puddle_time(run.effects.ctx), 3.0)


func test_pressure_cooker_is_half_again_as_wide_with_a_longer_fuse() -> void:
	var run := ItemKit.new().run_with(["pressure_cooker"])
	assert_near(run.stats.blast_radius, PlayerStats.BASE_BLAST_RADIUS * 1.5)
	assert_near(run.stats.fuse_bonus, 0.3)


func test_tea_cosy_spares_him_his_own_blasts_only() -> void:
	var run := ItemKit.new().run_with(["tea_cosy"])
	assert_eq(run.effects.hurt(1, RunEffects.HURT_OWN_BLAST), 0)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1)


func test_second_brew_throws_three_bomblets_for_half_the_blast() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["second_brew"])
	run.effects.bomb(Vector2.ZERO)
	assert_eq(kit.fx_of(Bomblet).size(), Bomblet.COUNT)
	run.effects.ctx.counting_exact = true
	run.effects.bomb(Vector2.ZERO)
	assert_eq(kit.fx_of(Bomblet).size(), Bomblet.COUNT, "none while the full loop counts")


func test_overarm_bowler_throws_the_thermos() -> void:
	assert_true(ItemKit.new().run_with(["thermos_lob"]).stats.throws_thermos)
	assert_false(ItemKit.new().make_run().stats.throws_thermos)


func test_tea_break_heals_half_a_pill_for_three_or_more_hit() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["tea_break"])
	run.health.pills = 2
	run.effects.blast_hits(Vector2.ZERO, 2)
	assert_eq(run.health.half_pills, 0)
	run.effects.blast_hits(Vector2.ZERO, 3)
	assert_eq(run.health.half_pills, 1)
	run.effects.blast_hits(Vector2.ZERO, 5)
	assert_eq(run.health.pills, 3)
	assert_eq(kit.fx_of(ItemFx.FxPop).size(), 2)
