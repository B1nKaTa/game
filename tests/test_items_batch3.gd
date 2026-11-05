extends TestCase

# One test per rule of the hundred items' third batch: the last two defence and health items, the
# Thermos and Slips group, the money and shops group and the Night Light, and the combos they make
# possible (Retirement Plan, Soup of the Day, Card Shark, Last Rites and Night Shift).

const Soup := preload("res://scripts/items/hot_soup_thermos.gd")
const Strap := preload("res://scripts/items/second_thermos_strap.gd")
const Kettle := preload("res://scripts/items/kettle_whistle.gd")
const Warranty := preload("res://scripts/items/eternal_warranty.gd")

# id: [rarity, source, first-clear path or "", cursed]
const BATCH := {
	"do_not_resuscitate": [ItemDef.RARE, ItemUnlocks.START, "", true],
	"eternal_warranty": [ItemDef.LEGENDARY, ItemUnlocks.RECIPE, "", false],
	"hot_soup_thermos": [ItemDef.RARE, ItemUnlocks.RECIPE, "", false],
	"second_thermos_strap": [ItemDef.COMMON, ItemUnlocks.START, "", false],
	"forged_signature": [ItemDef.RARE, ItemUnlocks.START, "", false],
	"pressure_cooker": [ItemDef.RARE, ItemUnlocks.RECIPE, "", false],
	"tea_cosy": [ItemDef.COMMON, ItemUnlocks.START, "", false],
	"rubber_stamps": [ItemDef.COMMON, ItemUnlocks.FIRST_CLEAR, "floor_1", false],
	"kettle_whistle": [ItemDef.COMMON, ItemUnlocks.FIRST_CLEAR, "furnace_works", false],
}
const SHOP_DIRS := ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "golden_years_mall", "last_resort_cruise", "fairways_end", "terminal_zero", "head_office"]


func _with_combos(kit: ItemKit, ids: Array) -> RunState:
	var run := kit.make_run()
	run.effects.set_combos(Content.combos())
	for id: String in ids:
		run.add_item(ItemKit.item(id))
	return run


func _player(run: RunState) -> Player:
	var player := Player.new()
	player.setup(run)
	return player


func test_the_batch_ships_with_its_rarity_tags_and_one_source() -> void:
	for id: String in BATCH:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.rarity, BATCH[id][0], id)
		assert_eq(ItemUnlocks.source_of(item), BATCH[id][1], id)
		assert_eq(ItemUnlocks.source_count(item), 0 if BATCH[id][1] == ItemUnlocks.START else 1, id)
		assert_eq(item.first_clear_path, BATCH[id][2], id)
		assert_eq(item.cursed, BATCH[id][3], id)
		assert_false(item.tags.is_empty(), id)
		for tag in item.tags:
			assert_true(ItemDef.TAGS.has(tag), "%s's tag %s" % [id, tag])
		if item.needs_recipe():
			assert_true(item.craft_price >= 150 and item.craft_price <= 400, "%s costs %d" % [id, item.craft_price])


func test_every_batch_text_is_two_sentences_and_has_a_coach_tip() -> void:
	for id: String in BATCH:
		var item := ItemKit.item(id)
		assert_true(item.description.count(". ") >= 1 and item.description[-1] in [".", "?", "!"], id)
		assert_true(CoachTips.TIPS.has(id), "%s has a tip" % id)
		if item.cursed:
			assert_true(item.description.contains("but"), "%s says its drawback" % id)


func test_no_poster_pays_a_batch_item() -> void:
	for def in BountyBoard.all():
		if def.extra_kind == BountyDef.EXTRA_ITEM:
			assert_false(BATCH.has(def.extra_id), "%s pays %s" % [def.id, def.extra_id])


func test_do_not_resuscitate_triples_his_damage_and_leaves_him_one_pill() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["hospital_bracelet", "do_not_resuscitate"])
	assert_eq(run.stats.max_pills, 1, "no pill added gets past it")
	assert_eq(run.health.max_pills, 1)
	assert_eq(run.health.pills, 1)
	var enemy := kit.enemy("intern_reaper", 100.0)
	assert_near(run.effects.hit_damage(enemy, 4.0, RunEffects.SWING), 12.0)
	assert_near(run.effects.hit_damage(enemy, 4.0, RunEffects.THERMOS), 12.0, "every hit of his")
	run.effects.ctx.counting_exact = true
	assert_near(run.effects.hit_damage(enemy, 4.0, RunEffects.SWING), 4.0, "the loop measures plain damage")
	kit.free_enemies()


func test_the_full_loop_keeps_his_pills_whole() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.effects.ctx.counting_pills = true
	run.add_item(ItemKit.item("do_not_resuscitate"))
	assert_eq(run.stats.max_pills, PlayerStats.BASE_PILLS, "the loop counts every pill")


func test_eternal_warranty_brings_him_back_once_with_every_pill() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["eternal_warranty"])
	var player := _player(run)
	run.health.pills = 1
	assert_true(player.take_hit(3))
	assert_false(run.health.is_dead())
	assert_eq(run.health.pills, run.health.max_pills, "back with every pill")
	assert_true(kit.notices.has(Warranty.NOTICE))
	run.health.tick(5.0)
	player.take_hit(99)
	assert_true(run.health.is_dead(), "once per run")
	player.free()


func test_eternal_warranty_waits_behind_the_life_jacket() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["life_jacket", "eternal_warranty"])
	var player := _player(run)
	player.take_hit(99)
	assert_eq(run.health.pills, 1, "the jacket goes first")
	assert_false(run.effects.effect_of("eternal_warranty").used)
	run.health.tick(5.0)
	player.take_hit(99)
	assert_eq(run.health.pills, run.health.max_pills)
	assert_true(run.effects.effect_of("eternal_warranty").used)
	player.free()
	var scene := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	assert_true(scene.contains("ctx.arrival = player.global_position"), "every arrival is kept for the door")


func test_hot_soup_lays_a_burning_puddle_that_spares_nobody_but_him() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["hot_soup_thermos"])
	run.effects.bomb(Vector2.ZERO)
	assert_eq(kit.fx_of(ItemFx.FxSoup).size(), 1)
	assert_near(run.effects.effect_of("hot_soup_thermos").puddle_time(run.effects.ctx), Soup.TIME)
	var soup := ItemFx.make_soup(run.effects.ctx, Soup.RADIUS, Soup.TIME, Soup.DAMAGE)
	var inside := kit.enemy("intern_reaper", 100.0)
	inside.position = Vector2(20, 0)
	var outside := kit.enemy("intern_reaper", 100.0)
	outside.position = Vector2(120, 0)
	assert_eq(soup.burn_touching([inside, outside]), 1)
	assert_near(inside.hp, 100.0 - Soup.DAMAGE)
	soup.free()
	run.effects.ctx.counting_exact = true
	run.effects.bomb(Vector2.ZERO)
	assert_eq(kit.fx_of(ItemFx.FxSoup).size(), 1, "the loop measures plain blasts")
	kit.free_enemies()


func test_second_thermos_strap_gives_two_now_and_one_each_floor() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var before := run.bombs
	run.add_item(ItemKit.item("second_thermos_strap"))
	assert_eq(run.bombs, before + Strap.AT_ONCE)
	run.effects.floor_start()
	assert_eq(run.bombs, before + Strap.AT_ONCE + Strap.EACH_FLOOR)


func test_forged_signature_keeps_about_one_slip_in_four() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["forged_signature"])
	run.effects.effect_of("forged_signature").rng.seed = 11
	var kept := 0
	for i in 4000:
		run.keys = 1
		assert_true(run.use_key())
		kept += run.keys
	assert_true(kept > 900 and kept < 1100, "kept %d of 4000" % kept)
	run.effects.ctx.counting_exact = true
	run.keys = 50
	for i in 50:
		run.use_key()
	assert_eq(run.keys, 0, "the loop counts every Slip spent")


func test_pressure_cooker_widens_the_blast_and_lengthens_the_fuse() -> void:
	var run := ItemKit.new().run_with(["pressure_cooker"])
	assert_near(run.stats.blast_radius, PlayerStats.BASE_BLAST_RADIUS * 1.35)
	assert_near(run.stats.fuse_bonus, 0.3)
	var thermos := Thermos.new()
	thermos.fuse_time = Thermos.FUSE_TIME + run.stats.fuse_bonus
	thermos._ready()
	assert_false(thermos.tick_fuse(Thermos.FUSE_TIME + 0.1), "not yet at the plain fuse")
	assert_true(thermos.tick_fuse(0.25))
	thermos.free()
	var room := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	assert_true(room.contains("thermos.fuse_time = Thermos.FUSE_TIME + _run.stats.fuse_bonus"), "the room lights the longer fuse")


func test_tea_cosy_takes_only_his_own_blasts() -> void:
	var run := ItemKit.new().run_with(["tea_cosy"])
	assert_eq(run.effects.hurt(1, RunEffects.HURT_OWN_BLAST), 0)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_BLAST), 1, "an enemy's blast still hurts")


func test_rubber_stamps_pay_for_every_slip_handed_over() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["rubber_stamps"])
	run.keys = 3
	run.use_key()
	run.use_key()
	assert_eq(kit.paid, 20)
	assert_eq(kit.fx_of(ItemFx.FxPop).size(), 2)
	run.keys = 0
	assert_false(run.use_key())
	assert_eq(kit.paid, 20, "no Slip, no stamp")
	run.keys = 1
	run.effects.ctx.counting_exact = true
	run.use_key()
	assert_eq(kit.paid, 20, "the loop counts Pension exactly")


func test_kettle_whistle_stuns_what_the_blast_reached() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["kettle_whistle"])
	var near := kit.enemy()
	near.position = Vector2(40, 0)
	var far := kit.enemy()
	far.position = Vector2(200, 0)
	run.effects.bomb(Vector2.ZERO)
	assert_true(near.is_stunned())
	assert_false(far.is_stunned())
	assert_eq(kit.fx_of(ItemFx.FxPop).size(), 1)
	assert_eq(kit.fx_of(ItemFx.FxPop)[0]["text"], Kettle.TEXT)
	kit.free_enemies()


func test_soup_of_the_day_keeps_the_puddles_twice_as_long() -> void:
	var kit := ItemKit.new()
	var run := _with_combos(kit, ["hot_soup_thermos", "second_thermos_strap"])
	assert_true(run.effects.has_combo("soup_of_the_day"))
	assert_near(run.effects.effect_of("hot_soup_thermos").puddle_time(run.effects.ctx), Soup.TIME * 2.0)


func test_last_rites_makes_the_life_jacket_work_twice_a_floor() -> void:
	var kit := ItemKit.new()
	var run := _with_combos(kit, ["do_not_resuscitate", "life_jacket"])
	assert_true(run.effects.has_combo("last_rites"))
	assert_eq(run.health.lethal_saves, 2, "both saves work on the floor it formed on")
	var player := _player(run)
	player.take_hit(5)
	run.health.tick(5.0)
	player.take_hit(5)
	assert_false(run.health.is_dead())
	run.health.tick(5.0)
	player.take_hit(5)
	assert_true(run.health.is_dead())
	run.start_floor()
	assert_eq(run.health.lethal_saves, 2)
	player.free()


func test_while_the_loop_counts_exactly_items_pay_nothing() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var ctx := run.effects.ctx
	ctx.counting_exact = true
	ctx.pay(50)
	ctx.drop(RoomRules.DROP_COIN, Vector2.ZERO, 3)
	assert_eq(kit.paid, 0)
	assert_eq(kit.drops.size(), 0)
	ctx.counting_exact = false
	ctx.pay(5)
	assert_eq(kit.paid, 5)
	var driver := FileAccess.get_file_as_string("res://tools/smoke_driver.gd")
	assert_true(driver.contains("run.effects.ctx.counting_exact = true"), "the full loop sets it")
