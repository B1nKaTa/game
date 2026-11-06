extends TestCase

# One test per rule of the hundred items' second batch: the ten dodge and movement items and the first
# ten defence and health items, and the combo they make possible (Mobility Scooter).

const BadHip := preload("res://scripts/items/bad_hip.gd")
const Afterimage := preload("res://scripts/items/afterimage.gd")
const Wheels := preload("res://scripts/items/wheelchair_wheels.gd")
const Peel := preload("res://scripts/items/banana_peel.gd")
const Sympathy := preload("res://scripts/items/sympathy_card.gd")
const Bottle := preload("res://scripts/items/hot_water_bottle.gd")
const Scooter := preload("res://scripts/items/mobility_scooter.gd")

# id: [rarity, source, first-clear path or "", cursed]
const BATCH := {
	"bad_hip": [ItemDef.COMMON, ItemUnlocks.START, "", false],
	"afterimage": [ItemDef.RARE, ItemUnlocks.START, "", false],
	"wheelchair_wheels": [ItemDef.RARE, ItemUnlocks.RECIPE, "", false],
	"velcro_shoes": [ItemDef.COMMON, ItemUnlocks.FIRST_CLEAR, "terminal_zero", false],
	"hover_round": [ItemDef.RARE, ItemUnlocks.FIRST_CLEAR, "seance_hotline", false],
	"squeaky_shoes": [ItemDef.COMMON, ItemUnlocks.START, "", true],
	"pogo_cane": [ItemDef.RARE, ItemUnlocks.FIRST_CLEAR, "last_resort_cruise", false],
	"banana_peel": [ItemDef.COMMON, ItemUnlocks.FIRST_CLEAR, "last_resort_cruise", false],
	"bunion_pads": [ItemDef.COMMON, ItemUnlocks.START, "", false],
	"gravity_boots": [ItemDef.RARE, ItemUnlocks.BOUNTY, "", false],
	"life_alert_button": [ItemDef.RARE, ItemUnlocks.RECIPE, "", false],
	"knitted_cardigan": [ItemDef.COMMON, ItemUnlocks.FIRST_CLEAR, "furnace_works", false],
	"casserole_dish": [ItemDef.COMMON, ItemUnlocks.START, "", false],
	"sympathy_card": [ItemDef.COMMON, ItemUnlocks.START, "", false],
	"pill_crusher": [ItemDef.COMMON, ItemUnlocks.START, "", false],
	"hot_water_bottle": [ItemDef.RARE, ItemUnlocks.FIRST_CLEAR, "sunset_shores", false],
	"bubble_wrap": [ItemDef.COMMON, ItemUnlocks.FIRST_CLEAR, "last_resort_cruise", false],
	"thick_skull": [ItemDef.RARE, ItemUnlocks.FIRST_CLEAR, "furnace_works", false],
	"second_opinion": [ItemDef.RARE, ItemUnlocks.FIRST_CLEAR, "sunset_shores", false],
	"hospital_bracelet": [ItemDef.COMMON, ItemUnlocks.START, "", false],
}


func _with_combos(kit: ItemKit, ids: Array) -> RunState:
	var run := kit.make_run()
	run.effects.set_combos(Content.combos())
	for id: String in ids:
		run.add_item(ItemKit.item(id))
	return run


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
		if item.needs_recipe():
			assert_true(item.craft_price >= 150 and item.craft_price <= 400, "%s costs %d" % [id, item.craft_price])


func test_every_batch_text_is_two_sentences_and_has_a_coach_tip() -> void:
	for id: String in BATCH:
		var item := ItemKit.item(id)
		assert_true(item.description.count(". ") >= 1 and item.description[-1] in [".", "?", "!"], id)
		assert_true(CoachTips.TIPS.has(id), "%s has a tip" % id)
	assert_true(ItemKit.item("squeaky_shoes").description.contains("but"), "the curse says its drawback")


func test_lorraines_poster_pays_the_gravity_boots_and_her_hat_is_sold() -> void:
	var poster: BountyDef
	for def in BountyBoard.all():
		if def.id == "lorraine":
			poster = def
	assert_eq(poster.extra_kind, BountyDef.EXTRA_ITEM)
	assert_eq(poster.extra_id, "gravity_boots")
	assert_true(CosmeticDef.find("captains_hat", CosmeticDef.all()).is_sold(), "the hat moved to the Decor Office")


func test_bad_hip_leaves_a_cough_that_slows_what_it_touches() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["bad_hip"])
	run.effects.dodge(Vector2.RIGHT)
	assert_eq(kit.fx_of(ItemFx.FxCough).size(), 1)
	var cough := ItemFx.make_cough(BadHip.RADIUS, BadHip.TIME, BadHip.SHARE)
	var inside := kit.enemy()
	inside.position = Vector2(20, 0)
	var outside := kit.enemy()
	outside.position = Vector2(90, 0)
	assert_eq(cough.slow_touching([inside, outside]), 1)
	assert_true(inside.is_slowed())
	assert_false(outside.is_slowed())
	cough.free()
	kit.free_enemies()


func test_afterimage_draws_ordinary_enemies_and_lets_them_go() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["afterimage"])
	run.effects.dodge(Vector2.RIGHT)
	assert_eq(kit.fx_of(ItemFx.FxAfterimage).size(), 1)
	var grandpa := Node2D.new()
	var walker := kit.enemy()
	walker.target = grandpa
	var boss := kit.enemy("regional_reaper")
	boss.target = grandpa
	var ghost := ItemFx.make_afterimage(grandpa, null, Afterimage.TIME)
	assert_eq(ghost.lure_all([walker, boss]), 1, "a boss is never fooled")
	assert_eq(walker.target, ghost)
	assert_eq(boss.target, grandpa)
	assert_false(ghost.take_hit(2), "a blow at the copy does nothing")
	assert_eq(ghost.feet().position, Player.FEET_OFFSET, "ground attacks aim at its feet")
	ghost.release()
	assert_eq(walker.target, grandpa, "they turn back to him")
	var second := ItemFx.make_afterimage(grandpa, null, Afterimage.TIME)
	second.lure(walker)
	second.free()
	assert_eq(walker.target, grandpa, "a copy freed with its room lets them go too")
	ghost.free()
	grandpa.free()
	kit.free_enemies()


func test_wheelchair_wheels_roll_further_and_run_enemies_over_once() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["wheelchair_wheels"])
	assert_near(run.stats.dodge_length, 1.6)
	var effect = run.effects.effect_of("wheelchair_wheels")
	run.effects.dodge(Vector2.RIGHT)
	assert_eq(kit.fx_of(ItemFx.FxWheels).size(), 1, "the wheels show")
	var enemy := kit.enemy("intern_reaper", 1000.0)
	enemy.position = Vector2(6, 0)
	var clear := kit.enemy("intern_reaper", 1000.0)
	clear.position = Vector2(120, 0)
	var body := Rect2(-Wheels.BODY / 2.0, Wheels.BODY)
	assert_eq(effect.roll_over(run.effects.ctx, body), 1)
	assert_near(enemy.hp, 1000.0 - CaneCombo.DAMAGE[0])
	assert_eq(effect.roll_over(run.effects.ctx, body), 0, "once a roll")
	run.effects.dodge(Vector2.LEFT)
	assert_eq(effect.roll_over(run.effects.ctx, body), 1, "and again on the next roll")
	assert_near(clear.hp, 1000.0)
	kit.free_enemies()


func test_velcro_shoes_give_two_dodges_back_to_back_on_a_longer_cooldown() -> void:
	var run := ItemKit.new().run_with(["velcro_shoes"])
	assert_eq(run.stats.dodge_charges, 2)
	assert_near(run.stats.dodge_cooldown, 1.3)
	assert_eq(ItemKit.new().make_run().stats.dodge_charges, 1)
	var timer := DodgeTimer.new()
	timer.charges = 2
	assert_true(timer.try_start(1.3))
	assert_false(timer.try_start(1.3), "not while the first is under way")
	timer.tick(DodgeTimer.DURATION)
	assert_true(timer.try_start(1.3), "the second, straight after")
	timer.tick(DodgeTimer.DURATION)
	assert_false(timer.try_start(1.3), "then both are spent")
	timer.tick(1.3)
	assert_eq(timer.charges_ready(), 1, "one comes back at a time")
	assert_true(timer.try_start(1.3))
	var player := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	assert_true(player.contains("_dodge.charges = run.stats.dodge_charges"), "the count is read at every dodge")


func test_a_plain_dodge_still_waits_out_its_cooldown() -> void:
	var timer := DodgeTimer.new()
	assert_true(timer.try_start(1.0))
	timer.tick(DodgeTimer.DURATION)
	assert_false(timer.try_start(1.0))
	timer.tick(0.5)
	assert_near(timer.cooldown_left(), 0.5)
	assert_false(timer.try_start(1.0))
	timer.tick(0.5)
	assert_near(timer.cooldown_left(), 0.0)
	assert_true(timer.try_start(1.0))
	timer.clear_cooldown()
	timer.tick(DodgeTimer.DURATION)
	assert_true(timer.try_start(1.0), "a refund gives it back at once")


func test_hover_round_keeps_his_walk_while_he_charges() -> void:
	assert_true(ItemKit.new().run_with(["hover_round"]).stats.charge_full_speed)
	assert_false(ItemKit.new().make_run().stats.charge_full_speed)
	var player := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	assert_true(player.contains("if _charge.is_charging() and not run.stats.charge_full_speed:"), "the charge slowdown checks it")


func test_squeaky_shoes_are_faster_but_he_is_noticed_twice_as_soon() -> void:
	var run := ItemKit.new().run_with(["squeaky_shoes"])
	assert_near(run.move_speed(), PlayerStats.BASE_SPEED * 1.15)
	assert_near(run.stats.notice_mult, 2.0)
	var kit := ItemKit.new()
	var enemy := kit.enemy()
	enemy.notice_mult = run.stats.notice_mult
	enemy.wait_for_room_start()
	assert_near(enemy._wake_left, Enemy.ROOM_WAKE_TIME / 2.0, "a room's wait is cut short")
	var plain := kit.enemy()
	plain.wait_for_room_start()
	assert_near(plain._wake_left, Enemy.ROOM_WAKE_TIME)
	var sunbather := FileAccess.get_file_as_string("res://scripts/actors/behaviors/sunbather_behavior.gd")
	var luggage := FileAccess.get_file_as_string("res://scripts/actors/behaviors/lost_luggage_behavior.gd")
	assert_true(sunbather.contains("enemy.distance_to_target() / enemy.notice_mult"), "sleepers wake from further")
	assert_true(luggage.contains("enemy.target_ground()) / enemy.notice_mult"), "lost luggage too")
	var room := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	assert_true(room.contains("enemy.notice_mult = _run.stats.notice_mult"), "every enemy a room spawns hears it")
	kit.free_enemies()


func test_pogo_cane_gives_the_dodge_back_on_a_close_call() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["pogo_cane"])
	run.effects.close_call()
	assert_eq(run.effects.effect_of("pogo_cane").resets, 1)
	assert_eq(kit.fx_of(ItemFx.FxPop).size(), 1)
	var source := FileAccess.get_file_as_string("res://scripts/items/pogo_cane.gd")
	assert_true(source.contains("ctx.player.refund_dodge()"))


func test_banana_peel_drops_once_a_fight_room_and_trips_the_first_onto_it() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["banana_peel"])
	run.effects.room_enter(null)
	run.effects.dodge(Vector2.RIGHT)
	assert_eq(kit.fx_of(ItemFx.FxPeel).size(), 0, "no peel with nobody to trip")
	var first := kit.enemy()
	first.position = Vector2(4, 0)
	run.effects.dodge(Vector2.RIGHT)
	run.effects.dodge(Vector2.RIGHT)
	assert_eq(kit.fx_of(ItemFx.FxPeel).size(), 1, "one peel a room")
	run.effects.room_enter(null)
	run.effects.dodge(Vector2.RIGHT)
	assert_eq(kit.fx_of(ItemFx.FxPeel).size(), 2)
	var peel := ItemFx.make_peel(run.effects.ctx, Peel.TRIP_TIME)
	var far := kit.enemy()
	far.position = Vector2(80, 0)
	assert_eq(peel.trip_first([far]), null)
	assert_eq(peel.trip_first([far, first]), first)
	assert_true(first.is_stunned())
	assert_false(far.is_stunned())
	var second := kit.enemy()
	assert_eq(peel.trip_first([second]), null, "one trip a peel")
	peel.free()
	kit.free_enemies()


func test_bunion_pads_are_faster_and_let_a_dodge_round_corners() -> void:
	var run := ItemKit.new().run_with(["bunion_pads"])
	assert_near(run.move_speed(), PlayerStats.BASE_SPEED * 1.08)
	assert_true(run.stats.dodge_rounds_corners)
	assert_eq(Player.straightened(Vector2(1.0, 0.1)), Vector2.RIGHT, "a hair off straight counts as straight")
	assert_eq(Player.straightened(Vector2(1.0, 1.0)), Vector2(1.0, 1.0), "a slant is left alone")
	var player := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	assert_true(player.contains("_round_corners(velocity, straightened(_dodge_direction), DODGE_SPEED, DODGE_CORNER_REACH)"))


func test_gravity_boots_take_the_slide_out_of_every_push_and_roll() -> void:
	var run := ItemKit.new().run_with(["gravity_boots"])
	assert_near(run.slide_mult(), 0.0)
	var player := Player.new()
	player.setup(run)
	player.push(Vector2(200, 0), 0.5)
	assert_false(player.is_pushed(), "a gust, a ring or a pull moves nothing")
	player.free()
	var source := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	assert_true(source.contains("ShipDeck.slide_at(get_tree(), _feet.global_position) * run.slide_mult()"), "nor does a rolling deck")


func test_life_alert_button_blocks_the_first_hit_in_every_room() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["life_alert_button"])
	run.effects.room_enter(null)
	assert_eq(run.effects.hurt(2, RunEffects.HURT_ENEMY), 0)
	assert_eq(kit.fx_of(ItemFx.FxPop).size(), 1, "the block shows")
	assert_eq(run.effects.hurt(1, RunEffects.HURT_FIRE), 1, "only the first")
	run.effects.room_enter(null)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_BLAST), 0, "every room")


func test_knitted_cardigan_halves_fire_and_steam() -> void:
	var run := ItemKit.new().run_with(["knitted_cardigan"])
	assert_eq(run.effects.hurt(1, RunEffects.HURT_FIRE), 0)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_FIRE), 1, "two burns cost one pill")
	assert_eq(run.effects.hurt(2, RunEffects.HURT_FIRE), 1)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1, "nothing else")
	assert_eq(run.effects.hurt(2, RunEffects.HURT_BLAST), 2)


func test_casserole_dish_heals_half_a_pill_on_a_rooms_first_kill() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["casserole_dish"])
	run.health.pills = 2
	var enemy := kit.enemy()
	run.effects.room_enter(null)
	run.effects.kill(enemy, RunEffects.SWING)
	assert_eq(run.health.half_pills, 1)
	run.effects.kill(enemy, RunEffects.SWING)
	assert_eq(run.health.half_pills, 1, "only the first kill")
	run.effects.room_enter(null)
	run.effects.kill(enemy, RunEffects.BITE)
	assert_eq(run.health.pills, 3, "two rooms, a whole pill")
	kit.free_enemies()


func test_sympathy_card_leaves_a_one_pill_heal_one_clear_in_four() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["sympathy_card"])
	var effect = run.effects.effect_of("sympathy_card")
	effect.rng.seed = 5
	for i in 2000:
		run.effects.room_clear(null)
	assert_true(absf(kit.drops.size() / 2000.0 - Sympathy.CHANCE) < 0.03, "about one in four, got %d" % kit.drops.size())
	assert_eq(kit.drops[0][0], RoomRules.DROP_HEAL)
	var room := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	assert_true(room.contains("elif kind == RoomRules.DROP_HEAL:\r\n\t\t_add_heal(spot, amount)") or room.contains("elif kind == RoomRules.DROP_HEAL:\n\t\t_add_heal(spot, amount)"), "a room lays the heal out")


func test_pill_crusher_adds_half_a_pill_and_wants_him_right_on_the_heal() -> void:
	var run := ItemKit.new().run_with(["pill_crusher"])
	run.health.pills = 1
	assert_eq(run.effects.pickup(RunEffects.HEAL, 2), 2)
	assert_eq(run.health.half_pills, 1, "half a pill waits")
	assert_eq(run.effects.pickup(RunEffects.HEAL, 2), 3, "the second half comes with the next heal")
	assert_eq(run.health.half_pills, 0)
	run.health.pills = run.health.max_pills
	assert_eq(run.effects.pickup(RunEffects.HEAL, 2), 2, "nothing at full")
	assert_eq(run.effects.pickup(RunEffects.PENSION, 2), 2)
	assert_near(run.stats.heal_reach_mult, 0.4)
	var room := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	assert_true(room.contains("heal.collect_radius = Pickup.COLLECT_RADIUS * _run.stats.heal_reach_mult"), "every heal on the floor")


func test_hot_water_bottle_heals_only_when_he_keeps_still_in_a_fight() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["hot_water_bottle"])
	var effect = run.effects.effect_of("hot_water_bottle")
	var ctx := run.effects.ctx
	run.health.pills = 1
	run.effects.room_enter(null)
	for i in 100:
		assert_false(effect.warm(ctx, true, 0.1), "no fight, no warmth")
	var enemy := kit.enemy()
	run.effects.room_enter(null)
	effect.warm(ctx, true, Bottle.STILL_AFTER - 0.1)
	assert_near(effect.warmth(), 0.0, "it waits for him to settle")
	effect.warm(ctx, true, 0.1)
	effect.warm(ctx, true, Bottle.EVERY - 0.5)
	effect.warm(ctx, false, 0.1)
	assert_false(effect.warm(ctx, true, Bottle.STILL_AFTER - 0.1), "settling again first")
	assert_true(effect.warm(ctx, true, 0.5), "walking keeps the warmth, standing again finishes it")
	assert_eq(run.health.half_pills, 1)
	effect.warm(ctx, true, Bottle.EVERY - 1.0)
	run.effects.hurt(1, RunEffects.HURT_ENEMY)
	assert_near(effect.warmth(), 0.0, "a hit cools it right down")
	assert_false(effect.warm(ctx, true, Bottle.STILL_AFTER - 0.1))
	effect.warm(ctx, true, 0.1)
	assert_true(effect.warm(ctx, true, Bottle.EVERY))
	effect.warm(ctx, true, Bottle.EVERY)
	assert_false(effect.warm(ctx, true, Bottle.EVERY), "a pill a room at most")
	kit.free_enemies()


func test_bubble_wrap_pops_the_first_shot_each_floor() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["bubble_wrap"])
	run.effects.floor_start()
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1, "a swat is no shot")
	assert_eq(run.effects.hurt(1, RunEffects.HURT_PROJECTILE), 0)
	assert_true(kit.fx_of(ItemFx.FxPop).size() == 1 and kit.fx_of(ItemFx.FxPop)[0]["text"] == "POP!")
	assert_eq(run.effects.hurt(1, RunEffects.HURT_PROJECTILE), 1, "one a floor")
	run.effects.floor_start()
	assert_eq(run.effects.hurt(2, RunEffects.HURT_PROJECTILE), 0)


func test_thick_skull_takes_a_pill_off_blasts_but_never_all() -> void:
	var run := ItemKit.new().run_with(["thick_skull"])
	assert_eq(run.effects.hurt(2, RunEffects.HURT_BLAST), 1)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_BLAST), 1, "never none")
	assert_eq(run.effects.hurt(3, RunEffects.HURT_OWN_BLAST), 2, "his own Thermos too")
	assert_eq(run.effects.hurt(2, RunEffects.HURT_ENEMY), 2)


func test_second_opinion_doubles_the_first_heal_of_each_floor() -> void:
	var run := ItemKit.new().run_with(["second_opinion"])
	run.effects.floor_start()
	run.health.pills = run.health.max_pills
	assert_eq(run.effects.pickup(RunEffects.HEAL, 2), 2, "a heal taken at full is not the one")
	run.health.pills = 1
	assert_eq(run.effects.pickup(RunEffects.HEAL, 2), 4)
	assert_eq(run.effects.pickup(RunEffects.HEAL, 2), 2, "once a floor")
	run.effects.floor_start()
	assert_eq(run.effects.pickup(RunEffects.HEAL, 1), 2)


func test_hospital_bracelet_adds_a_pill() -> void:
	var run := ItemKit.new().run_with(["hospital_bracelet"])
	assert_eq(run.stats.max_pills, PlayerStats.BASE_PILLS + 1)


func test_while_the_loop_counts_pills_items_neither_block_nor_heal() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["life_alert_button", "casserole_dish", "second_opinion", "sympathy_card"])
	var ctx := run.effects.ctx
	ctx.counting_pills = true
	run.effects.room_enter(null)
	run.effects.floor_start()
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1)
	run.health.pills = 1
	var enemy := kit.enemy()
	run.effects.kill(enemy, RunEffects.SWING)
	ctx.heal_half()
	ctx.heal(1)
	assert_eq(run.health.half_pills, 0)
	assert_eq(run.health.pills, 1)
	assert_eq(run.effects.pickup(RunEffects.HEAL, 2), 2)
	run.effects.effect_of("sympathy_card").send(ctx, null)
	assert_eq(kit.drops.size(), 0, "no heal is dropped")
	ctx.counting_pills = false
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 0, "the block was kept for later")
	var driver := FileAccess.get_file_as_string("res://tools/smoke_driver.gd")
	assert_true(driver.contains("run.effects.ctx.counting_pills = true"), "the full loop sets it")
	kit.free_enemies()


func test_mobility_scooter_lays_a_fire_trail_that_burns_now_and_then() -> void:
	var kit := ItemKit.new()
	var run := _with_combos(kit, ["titanium_hip", "wheelchair_wheels"])
	assert_true(run.effects.has_combo("mobility_scooter"))
	assert_false(_with_combos(kit, ["wheelchair_wheels"]).effects.has_combo("mobility_scooter"))
	var scooter := Scooter.new()
	assert_true(scooter.trail(run.effects.ctx, Vector2.ZERO))
	assert_false(scooter.trail(run.effects.ctx, Vector2(Scooter.STEP - 1.0, 0)), "not every frame")
	assert_true(scooter.trail(run.effects.ctx, Vector2(Scooter.STEP, 0)))
	assert_eq(kit.fx_of(ItemFx.FxBurn).size(), 2)
	var burn := ItemFx.make_burn(run.effects.ctx, Scooter.RADIUS, Scooter.TIME, Scooter.DAMAGE)
	var enemy := kit.enemy("intern_reaper", 100.0)
	enemy.position = Vector2(4, 0)
	assert_eq(burn.burn_touching([enemy]), 1)
	assert_near(enemy.hp, 100.0 - Scooter.DAMAGE)
	assert_eq(burn.burn_touching([enemy]), 0, "not again at once")
	burn.age += ItemFx.FxBurn.BURN_EVERY
	assert_eq(burn.burn_touching([enemy]), 1)
	burn.free()
	kit.free_enemies()
