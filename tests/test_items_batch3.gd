extends TestCase

# One test per rule of the hundred items' third batch: the last two defence and health items, the
# Thermos and Slips group, the money and shops group and the Night Light, and the combos they make
# possible (Retirement Plan, Soup of the Day, Card Shark, Last Rites and Night Shift).

const Soup := preload("res://scripts/items/hot_soup_thermos.gd")
const Strap := preload("res://scripts/items/second_thermos_strap.gd")
const Kettle := preload("res://scripts/items/kettle_whistle.gd")
const Lottery := preload("res://scripts/items/lottery_scratcher.gd")
const Statement := preload("res://scripts/items/pension_statement.gd")
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
	"coupon_booklet": [ItemDef.COMMON, ItemUnlocks.FIRST_CLEAR, "flashback_cinema", false],
	"penny_jar": [ItemDef.COMMON, ItemUnlocks.START, "", false],
	"lottery_scratcher": [ItemDef.COMMON, ItemUnlocks.START, "", false],
	"pension_statement": [ItemDef.RARE, ItemUnlocks.FIRST_CLEAR, "head_office", false],
	"loaded_dice": [ItemDef.RARE, ItemUnlocks.FIRST_CLEAR, "flashback_cinema", true],
	"expired_coupon": [ItemDef.RARE, ItemUnlocks.FIRST_CLEAR, "terminal_zero", true],
	"hagglers_hat": [ItemDef.COMMON, ItemUnlocks.FIRST_CLEAR, "flashback_cinema", false],
	"collection_plate": [ItemDef.RARE, ItemUnlocks.FIRST_CLEAR, "head_office", false],
	"inheritance_letter": [ItemDef.COMMON, ItemUnlocks.START, "", false],
	"tax_refund": [ItemDef.RARE, ItemUnlocks.FIRST_CLEAR, "terminal_zero", false],
	"night_light": [ItemDef.COMMON, ItemUnlocks.START, "", false],
}
const SHOP_DIRS := ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "flashback_cinema", "last_resort_cruise", "seance_hotline", "terminal_zero", "head_office"]


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


func _stock(run: RunState, seed_value := 3) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return ShopRules.stock(Content.items(), run, rng)


func _items_for_sale(stock: Array[Dictionary]) -> int:
	var count := 0
	for entry in stock:
		if entry["kind"] == ShopRules.KIND_ITEM:
			count += 1
	return count


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


func test_coupon_booklet_puts_one_more_item_on_the_shelf() -> void:
	var kit := ItemKit.new()
	assert_eq(_items_for_sale(_stock(kit.make_run())), ShopRules.ITEMS_FOR_SALE)
	var run := kit.run_with(["coupon_booklet"])
	assert_eq(_items_for_sale(_stock(run)), ShopRules.ITEMS_FOR_SALE + 1)
	run.effects.ctx.counting_exact = true
	assert_eq(_items_for_sale(_stock(run)), ShopRules.ITEMS_FOR_SALE, "the loop counts the usual stock")


func test_every_shop_has_room_for_an_extra_ware() -> void:
	for dir: String in SHOP_DIRS:
		var layout: RoomLayout = load("res://data/rooms/%s/shop_01.tres" % dir)
		var extra := RoomView.extra_shop_cells(layout, 1)
		assert_eq(extra.size(), 1, dir)
		if extra.is_empty():
			continue
		var cell := extra[0]
		assert_false(layout.cells_of("S").has(cell), dir)
		assert_false(layout.touches_a_door(cell), dir)
		assert_true(RoomView.shop_label_fits(layout, cell), "%s has room for the name at %s" % [dir, cell])
		var plan := layout.cells_of(RoomLayout.SYMBOL_PLAN)[0]
		assert_true(RoomLayout.clear_of_the_plan_text(cell, plan), "%s keeps the plan's text clear" % dir)
		assert_true(cell != layout.merchant_cell(), dir)
		var avoid: Array[Vector2i] = [layout.merchant_cell(), cell]
		var rewards := layout.plan_reward_cells(ProgressData.RETIREMENT_TIERS.size(), avoid)
		assert_false(rewards.has(cell), "%s keeps the plan's rewards off it" % dir)
	assert_eq(RoomView.extra_shop_cells(load("res://data/rooms/floor_1/shop_01.tres"), 0).size(), 0)


func test_penny_jar_calls_coins_from_twice_as_far() -> void:
	var run := ItemKit.new().run_with(["penny_jar"])
	assert_near(run.stats.coin_reach_mult, 2.0)
	var reach := Pickup.MAGNET_RADIUS * run.stats.coin_reach_mult
	assert_true(Pickup.should_magnet(true, Pickup.MAGNET_RADIUS * 1.9, reach))
	assert_false(Pickup.should_magnet(true, Pickup.MAGNET_RADIUS * 1.9))
	var room := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	assert_true(room.contains("coin.magnet_radius = Pickup.MAGNET_RADIUS * _run.stats.coin_reach_mult"))


func test_lottery_scratcher_pays_zero_to_a_hundred_each_floor() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["lottery_scratcher"])
	var lottery = run.effects.effect_of("lottery_scratcher")
	lottery.rng.seed = 4
	var total := 0
	for i in 400:
		var won: int = lottery.scratch(run.effects.ctx)
		assert_true(won >= 0 and won <= Lottery.MOST, "won %d" % won)
		total += won
	assert_eq(kit.paid, total)
	assert_true(total > 400 * 24 and total < 400 * 36, "about 30 a floor, got %d" % total)
	kit.notices.clear()
	run.effects.floor_start()
	assert_eq(kit.notices.size(), 1, "each new floor scratches once")
	assert_eq(Lottery.notice_for(0), "Lottery Scratcher: not a winner. Better luck next floor.")


func test_pension_statement_pays_a_share_of_the_run_on_each_clear() -> void:
	assert_eq(Statement.pay_for(0), 0)
	assert_eq(Statement.pay_for(99), 0)
	assert_eq(Statement.pay_for(320), 3)
	assert_eq(Statement.pay_for(5000), Statement.MOST, "never more than 5 at a time")
	var kit := ItemKit.new()
	var run := kit.run_with(["pension_statement"])
	run.pension_earned = 420
	run.effects.room_clear(null)
	assert_eq(kit.paid, 4)


func test_loaded_dice_pay_more_at_the_arcade_and_charge_more_in_shops() -> void:
	var run := ItemKit.new().run_with(["loaded_dice"])
	var rare := ItemKit.item("pension_statement")
	assert_eq(ShopRules.item_price(rare, 1.0, run.stats.shop_discount - run.stats.shop_markup), 72)
	for entry in _stock(run):
		if entry["kind"] == ShopRules.KIND_HEAL:
			assert_eq(entry["price"], ShopRules.price_after(ShopRules.HEAL_PRICE, -0.2))
	assert_near(ArcadeOdds.win_bonus(ArcadeOdds.SLOT, run.stats.arcade_win_bonus, run.stats.poker_win_bonus), 0.1)
	assert_near(ArcadeOdds.win_bonus(ArcadeOdds.BLACKJACK, run.stats.arcade_win_bonus, run.stats.poker_win_bonus), 0.05)
	assert_eq(ArcadeOdds.boosted(50, 10, 0.1), 54, "a win pays a tenth more of its winnings")
	assert_eq(ArcadeOdds.boosted(100, 50, 0.05), 102, "in whole Pension, rounded down")
	assert_eq(ArcadeOdds.boosted(10, 10, 0.1), 10, "a push pays as it was")
	assert_eq(ArcadeOdds.boosted(0, 10, 0.1), 0)
	var panel := FileAccess.get_file_as_string("res://scripts/ui/card_table_panel.gd")
	assert_eq(panel.count("ArcadeOdds.boosted("), 3, "every table pays through the bonus")


func test_the_house_still_wins_with_the_dice_and_the_card_shark() -> void:
	# Each game keeps a share of the bets even at its best bonus, at every bet. The rounds keep the
	# noise (about 0.3% for the card games) well under the gap to the ceiling.
	var rounds := {"slot": 40000, "blackjack": 120000, "poker": 120000}
	var dice_alone := ArcadeOdds.win_bonus(ArcadeOdds.POKER, 0.1, 0.0)
	for game: String in rounds:
		var best := ArcadeOdds.win_bonus(game, 0.1, 0.1)
		var plain := ArcadeOdds.simulated_return(game, rounds[game], _rng(21))
		for bet_index in ([0] if game == ArcadeOdds.SLOT else [0, 1, 2]):
			var lucky := ArcadeOdds.simulated_return(game, rounds[game], _rng(21), best, bet_index)
			assert_true(lucky < 0.98, "%s returns %f with the dice, bet %d" % [game, lucky, bet_index])
		var top := ArcadeOdds.simulated_return(game, rounds[game], _rng(21), best, 2 if game != ArcadeOdds.SLOT else 0)
		assert_true(top > plain, "%s pays more with the dice" % game)
	assert_true(dice_alone < ArcadeOdds.win_bonus(ArcadeOdds.POKER, 0.1, 0.1), "Card Shark adds at the poker table")


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_expired_coupon_frees_one_shop_a_floor_and_takes_a_pill_each_floor() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["expired_coupon"])
	var start := run.health.max_pills
	var stock := _stock(run)
	run.effects.shop_open(stock)
	for entry in stock:
		assert_eq(entry["price"], 0, "the first shop is free")
	var second := _stock(run, 5)
	run.effects.shop_open(second)
	assert_true(int(second[0]["price"]) > 0, "only one shop a floor")
	run.effects.floor_start()
	assert_eq(run.health.max_pills, start - 1)
	var third := _stock(run, 6)
	run.effects.shop_open(third)
	assert_eq(third[0]["price"], 0, "a new floor, a new free shop")
	for i in 10:
		run.effects.floor_start()
	assert_eq(run.health.max_pills, 1, "never the last pill")
	assert_true(run.health.pills >= 1)
	run.clear_items()
	assert_eq(run.health.max_pills, PlayerStats.BASE_PILLS, "dropping the items gives the pills back")


func test_hagglers_hat_halves_the_cheapest_item() -> void:
	var run := ItemKit.new().run_with(["hagglers_hat"])
	var stock: Array[Dictionary] = [
		{"kind": ShopRules.KIND_ITEM, "price": 60, "item": null},
		{"kind": ShopRules.KIND_ITEM, "price": 35, "item": null},
		{"kind": ShopRules.KIND_HEAL, "price": 20, "item": null},
	]
	run.effects.shop_open(stock)
	assert_eq(stock[0]["price"], 60)
	assert_eq(stock[1]["price"], 18)
	assert_true(stock[1].get("half", false))
	assert_eq(stock[2]["price"], 20, "a heal is not an item")


func test_collection_plate_drops_a_coin_for_each_paying_kill() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["collection_plate"])
	var enemy := kit.enemy()
	run.effects.kill(enemy, RunEffects.SWING)
	assert_eq(kit.drops.size(), 1)
	assert_eq(kit.drops[0][0], RoomRules.DROP_COIN)
	var summon := kit.enemy()
	summon.is_summon = true
	run.effects.kill(summon, RunEffects.SWING)
	assert_eq(kit.drops.size(), 1, "summons pay nothing, so they cannot be farmed")
	for i in 5:
		run.effects.kill(enemy, RunEffects.SWING)
	assert_eq(kit.drops.size(), 3, "three a room")
	run.effects.room_enter(null)
	run.effects.ctx.counting_exact = true
	run.effects.kill(enemy, RunEffects.SWING)
	assert_eq(kit.drops.size(), 3, "the loop counts Pension exactly")
	run.effects.ctx.counting_exact = false
	run.effects.kill(enemy, RunEffects.SWING)
	assert_eq(kit.drops.size(), 4, "a new room pays again")
	kit.free_enemies()


func test_inheritance_letter_pays_once_on_taking() -> void:
	var kit := ItemKit.new()
	kit.run_with(["inheritance_letter"])
	assert_eq(kit.paid, 60)
	var yard_kit := ItemKit.new()
	var yard := yard_kit.make_run()
	yard.effects.ctx.pay_pension = Callable()
	yard.add_item(ItemKit.item("inheritance_letter"))
	assert_eq(yard_kit.paid, 0, "the Training Yard's run has no bank, so it pays nothing there")


func test_tax_refund_pays_for_a_shop_left_empty_handed_once() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["tax_refund"])
	var refund = run.effects.effect_of("tax_refund")
	assert_false(refund.leave_shop(run.effects.ctx, 1, 2), "nothing for a shop he bought in")
	assert_true(refund.leave_shop(run.effects.ctx, 3, 0))
	assert_false(refund.leave_shop(run.effects.ctx, 3, 0), "once a shop")
	assert_eq(kit.paid, 15)
	var room := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	assert_true(room.contains("shop_purchases += 1"), "the shop counts what he buys")


func test_night_light_doubles_his_light_in_the_dark() -> void:
	var kit := ItemKit.new()
	var plain := _player(kit.make_run())
	assert_near(LightsOut.light_scale(plain), 1.0)
	var run := kit.run_with(["night_light"])
	var lit := _player(run)
	assert_near(LightsOut.light_scale(lit), 2.0)
	assert_false(LightsOut.kept_lit(lit))
	var lamp := Node2D.new()
	assert_near(LightsOut.light_scale(lamp), 1.0, "anything without a run keeps the usual light")
	lamp.free()
	plain.free()
	lit.free()


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
