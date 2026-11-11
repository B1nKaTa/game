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


func test_copying_does_nothing_while_the_full_loop_counts() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var ctx := run.effects.ctx
	kit.can_copy = true
	ctx.counting_pills = true
	assert_false(ctx.copy_pickup(), "a copied heal would add pills the loop did not count")
	ctx.counting_pills = false
	ctx.counting_exact = true
	assert_false(ctx.copy_pickup(), "a copied coin would add uncounted Pension")
	assert_eq(kit.copies, 0)
	ctx.counting_exact = false
	assert_true(ctx.copy_pickup())


func test_fetching_does_nothing_while_the_full_loop_counts() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var ctx := run.effects.ctx
	kit.can_fetch = true
	ctx.counting_pills = true
	assert_false(ctx.fetch_pickup(), "a fetched heal would add pills the loop did not count")
	ctx.counting_pills = false
	ctx.counting_exact = true
	assert_false(ctx.fetch_pickup(), "a fetched coin would add uncounted Pension")
	assert_eq(kit.fetches, 0)
	ctx.counting_exact = false
	assert_true(ctx.fetch_pickup())
	assert_eq(kit.fetches, 1)


func test_the_half_heal_bonus_reads_the_counting_flag_at_the_heal() -> void:
	var run := ItemKit.new().make_run()
	var hypo := ItemDef.new()
	hypo.id = "hypo"
	hypo.half_heal_bonus = true
	run.add_item(hypo)
	run.health.max_pills = 20
	run.health.pills = 1
	run.health.heal(1)
	assert_eq(run.health.half_pills, 1, "the bonus applies normally")
	run.effects.ctx.counting_pills = true
	run.health.heal(1)
	assert_eq(run.health.half_pills, 1, "no bonus once the loop counts, with no stats refresh")
	run.effects.ctx.counting_pills = false
	run.health.heal(1)
	assert_eq(run.health.half_pills, 0, "the bonus is back when the flag clears (second half made a pill)")


func test_a_coin_in_a_sealed_pocket_is_never_fetched_or_copied() -> void:
	var sealed := Pickup.new()
	sealed.position = Vector2(1, 0)
	var open := Pickup.new()
	open.fetch_kind = "coin"
	open.copy_kind = "coin"
	open.position = Vector2(90, 0)
	var all := [sealed, open]
	assert_eq(RoomView.nearest_pickup(all, Vector2.ZERO, ["coin"]), open)
	assert_eq(RoomView.nearest_copyable(all, Vector2.ZERO), open)
	var source := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	var place := source.substr(source.find("func _place_coin"), 1200)
	assert_true(place.find("coin_can_fly_from") < place.find("coin.fetch_kind"), "kinds are set after the pocket check")
	assert_true(place.find("coin_can_fly_from") < place.find("coin.copy_kind"))
	for pickup in all:
		pickup.free()


func test_a_cut_of_nothing_changes_no_chest_and_a_cut_never_goes_below_one() -> void:
	for kind in ChestRules.KINDS:
		var old := ChestRules.slips_needed(kind)
		assert_eq(ChestRules.slips_for(kind), old, kind)
		assert_eq(ChestRules.slips_for(kind, 0), old, kind)
		assert_eq(ChestRules.can_open(kind, old), ChestRules.can_open(kind, old, 0), kind)
		assert_eq(ChestRules.prompt_for(kind), ChestRules.prompt_for(kind, 0), kind)
		var cut := ChestRules.slips_for(kind, 1)
		if old <= 1:
			assert_eq(cut, old, "a cost of 0 or 1 is not changed: " + kind)
		else:
			assert_true(cut >= 1 and cut < old, kind)
		assert_true(ChestRules.slips_for(kind, 99) >= mini(old, 1), kind)
