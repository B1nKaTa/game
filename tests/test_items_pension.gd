extends TestCase

const IDS := {"money_belt": "legendary", "piggy_bank": "rare", "compound_interest": "rare", "senior_discount": "rare",
	"hagglers_hat": "common", "coupon_booklet": "common", "gold_fillings": "common", "coin_purse_cane": "rare",
	"inheritance_letter": "common"}


func _swing() -> SwingAttack:
	return SwingAttack.new(Vector2.RIGHT, 44.0, 60.0, 10.0, 60.0, false, false)


func test_the_pension_items_ship_as_the_list_says() -> void:
	for id: String in IDS:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.build, "pension", id)
		assert_eq(item.rarity, IDS[id], id)
	assert_eq(ItemKit.item("hagglers_hat").display_name, "Haggler's Hat")
	assert_eq(ItemKit.item("coupon_booklet").display_name, "Coupon Booklet")
	assert_eq(ItemKit.item("compound_interest").first_clear_path, "head_office")
	assert_true(RetiredContent.is_retired("pension_statement"))


func test_money_belt_adds_five_percent_per_fifty_in_the_purse_up_to_half() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["money_belt"])
	var enemy := kit.enemy()
	run.pension_at_start = 100
	kit.pension = 260
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 11.5, "160 in the purse: three fifties")
	kit.pension = 5000
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 15.0, "at most half again")
	kit.free_enemies()


func test_piggy_bank_pays_twenty_a_pill_from_the_purse_instead() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["piggy_bank"])
	run.pension_at_start = 0
	kit.pension = 50
	assert_eq(run.effects.hurt(2, RunEffects.HURT_ENEMY), 0)
	assert_eq(kit.pension, 10)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1, "the purse cannot cover it")
	assert_eq(kit.pension, 10)
	kit.pension = 40
	run.effects.ctx.counting_pills = true
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1, "the full loop counts every pill")


func test_compound_interest_pays_fifteen_percent_of_the_purse_each_floor() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["compound_interest"])
	run.pension_at_start = 0
	kit.pension = 210
	run.effects.floor_start()
	assert_eq(kit.paid, 31)


func test_senior_discount_takes_a_quarter_off() -> void:
	assert_near(ItemKit.new().run_with(["senior_discount"]).stats.shop_discount, 0.25)


func test_hagglers_hat_makes_the_cheapest_item_free() -> void:
	var run := ItemKit.new().run_with(["hagglers_hat"])
	var cheap := ItemKit.item("tea_cosy")
	var dear := ItemKit.item("tea_urn")
	var stock: Array[Dictionary] = [
		{"kind": ShopRules.KIND_ITEM, "price": 175, "item": dear},
		{"kind": ShopRules.KIND_ITEM, "price": 35, "item": cheap},
		{"kind": ShopRules.KIND_HEAL, "price": 20, "item": null},
	]
	run.effects.shop_open(stock)
	assert_eq(stock[1]["price"], 0)
	assert_eq(stock[0]["price"], 175)
	assert_eq(stock[2]["price"], 20, "only items")


func test_coupon_booklet_adds_a_ware() -> void:
	assert_eq(ItemKit.new().run_with(["coupon_booklet"]).stats.shop_extra_items, 1)


func test_gold_fillings_knock_a_coin_loose_one_bite_in_four() -> void:
	var gold := load("res://scripts/items/gold_fillings.gd")
	assert_near(gold.CHANCE, 0.25)


func test_coin_purse_cane_loads_a_coin_per_ten_and_fires_one_a_swing() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["coin_purse_cane"])
	var purse = run.effects.effect_of("coin_purse_cane")
	run.effects.pickup(RunEffects.PENSION, 7)
	assert_eq(purse.loaded, 0)
	run.effects.pickup(RunEffects.PENSION, 25)
	assert_eq(purse.loaded, 3, "at most three")
	run.effects.swing(_swing())
	assert_eq(purse.loaded, 2)
	assert_eq(kit.fx_of(ItemFx.FxNeedle).size(), 1)
	assert_eq(purse.save_state()["loaded"], 2)


func test_inheritance_letter_pays_seventy_five_once() -> void:
	var kit := ItemKit.new()
	kit.run_with(["inheritance_letter"])
	assert_eq(kit.paid, 75)


func test_inheritance_letter_pays_nothing_in_the_training_yard() -> void:
	var yard_kit := ItemKit.new()
	var yard := yard_kit.make_run()
	yard.effects.ctx.pay_pension = Callable()
	yard.add_item(ItemKit.item("inheritance_letter"))
	assert_eq(yard_kit.paid, 0, "the Training Yard's run has no bank, so it pays nothing there")


func test_gold_fillings_still_drop_at_most_a_room_s_worth_and_nothing_from_summons() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["gold_fillings"])
	var effect = run.effects.effect_of("gold_fillings")
	var enemy := kit.enemy()
	run.effects.room_enter(null)
	for i in 50:
		effect.knock_out(run.effects.ctx, enemy)
	assert_eq(kit.drops.size(), effect.ROOM_LIMIT, "a room's worth at most")
	var summon := kit.enemy()
	summon.is_summon = true
	run.effects.room_enter(null)
	assert_false(effect.knock_out(run.effects.ctx, summon), "a summon pays nothing")
	kit.free_enemies()
