extends TestCase


func test_a_pickup_gives_what_the_items_make_of_it() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	var take := source.substr(source.find("func _take_consumable"), 400)
	assert_true(take.contains("_run.effects.pickup(kind, 1)"))
	assert_true(take.contains("for i in amount"), "every Slip or Thermos the items say comes")


func test_losing_halves_takes_a_pill_every_second_half_and_never_the_last() -> void:
	var health := Health.new(4)
	health.pills = 2
	assert_false(health.lose_half(), "the first half takes nothing yet")
	assert_eq(health.pills, 2)
	assert_true(health.lose_half())
	assert_eq(health.pills, 1)
	health.lose_half()
	assert_false(health.lose_half(), "never his last pill")
	assert_eq(health.pills, 1)


func test_a_half_heal_bonus_adds_half_a_pill_to_every_heal_once() -> void:
	var health := Health.new(8)
	health.pills = 2
	health.half_heal_bonus = true
	health.heal(1)
	assert_eq(health.pills, 3)
	assert_eq(health.half_pills, 1)
	health.heal(1)
	assert_eq(health.pills, 5, "the second half made a pill, with no half added for it")
	assert_eq(health.half_pills, 0)


func test_the_run_hands_the_half_heal_bonus_to_his_health() -> void:
	var run := ItemKit.new().make_run()
	var hypo := ItemDef.new()
	hypo.id = "hypo"
	hypo.half_heal_bonus = true
	run.add_item(hypo)
	assert_true(run.health.half_heal_bonus)


func test_an_enemy_can_hit_harder_and_pay_more() -> void:
	var kit := ItemKit.new()
	var enemy := kit.enemy()
	assert_eq(enemy.attack_damage(), enemy.def.damage)
	enemy.extra_damage = 1
	assert_eq(enemy.attack_damage(), enemy.def.damage + 1)
	assert_eq(enemy.attack_damage(2), 3)
	var coins := enemy.coin_value()
	enemy.coin_mult = 2.0
	assert_eq(enemy.coin_value(), coins * 2)
	assert_false(enemy.leaves_item)
	kit.free_enemies()


func test_the_context_drops_fetches_copies_and_loses_halves() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var ctx := run.effects.ctx
	var item := ItemDef.new()
	item.id = "free_test"
	ctx.drop_item(item, Vector2(5, 5))
	assert_eq(kit.drops, [["item", Vector2(5, 5)]])
	assert_false(ctx.fetch_pickup())
	kit.can_fetch = true
	assert_true(ctx.fetch_pickup())
	assert_eq(kit.fetches, 1)
	assert_false(ctx.copy_pickup())
	kit.can_copy = true
	assert_true(ctx.copy_pickup())
	run.health.pills = 3
	ctx.lose_half()
	ctx.lose_half()
	assert_eq(run.health.pills, 2)
	ctx.counting_pills = true
	ctx.lose_half()
	ctx.lose_half()
	assert_eq(run.health.pills, 2, "the full loop counts pills itself")


func test_the_nearest_pickup_of_a_kind_that_waits() -> void:
	var coin := Pickup.new()
	coin.fetch_kind = "coin"
	coin.position = Vector2(50, 0)
	var slip := Pickup.new()
	slip.fetch_kind = "key"
	slip.copy_kind = "key"
	slip.position = Vector2(20, 0)
	var item := Pickup.new()
	item.position = Vector2(5, 0)
	var all := [coin, slip, item]
	assert_eq(RoomView.nearest_pickup(all, Vector2.ZERO, ["coin", "key", "bomb"]), slip)
	assert_eq(RoomView.nearest_pickup(all, Vector2.ZERO, ["coin"]), coin)
	assert_eq(RoomView.nearest_copyable(all, Vector2.ZERO), slip, "an item is never copied")
	slip.can_take = func() -> bool: return false
	assert_eq(RoomView.nearest_pickup(all, Vector2.ZERO, ["coin", "key"]), coin, "one he cannot take is left")
	for pickup in all:
		pickup.free()


func test_the_apron_takes_a_slip_off_and_never_below_one() -> void:
	assert_eq(ChestRules.slips_for(ChestRules.URN, 1), 1)
	assert_eq(ChestRules.slips_for(ChestRules.URN, 0), 2)
	assert_eq(ChestRules.slips_for(ChestRules.LOCKED, 1), 1)
	assert_eq(ChestRules.slips_for(ChestRules.LUNCHBOX, 1), 0)
	assert_true(ChestRules.can_open(ChestRules.URN, 1, 1))
	assert_false(ChestRules.can_open(ChestRules.URN, 1, 0))
	assert_eq(ChestRules.prompt_for(ChestRules.URN, 1), ChestRules.prompt_for(ChestRules.LOCKED))
