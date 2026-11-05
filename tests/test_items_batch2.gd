extends TestCase

# One test per rule of the hundred items' second batch: the ten dodge and movement items.

const BadHip := preload("res://scripts/items/bad_hip.gd")
const Afterimage := preload("res://scripts/items/afterimage.gd")
const Wheels := preload("res://scripts/items/wheelchair_wheels.gd")
const Peel := preload("res://scripts/items/banana_peel.gd")

# id: [rarity, source, first-clear path or "", cursed]
const BATCH := {
	"bad_hip": [ItemDef.COMMON, ItemUnlocks.START, "", false],
	"afterimage": [ItemDef.RARE, ItemUnlocks.START, "", false],
	"wheelchair_wheels": [ItemDef.RARE, ItemUnlocks.RECIPE, "", false],
	"velcro_shoes": [ItemDef.COMMON, ItemUnlocks.FIRST_CLEAR, "terminal_zero", false],
	"hover_round": [ItemDef.RARE, ItemUnlocks.FIRST_CLEAR, "fairways_end", false],
	"squeaky_shoes": [ItemDef.COMMON, ItemUnlocks.START, "", true],
	"pogo_cane": [ItemDef.RARE, ItemUnlocks.FIRST_CLEAR, "last_resort_cruise", false],
	"banana_peel": [ItemDef.COMMON, ItemUnlocks.FIRST_CLEAR, "last_resort_cruise", false],
	"bunion_pads": [ItemDef.COMMON, ItemUnlocks.START, "", false],
	"gravity_boots": [ItemDef.RARE, ItemUnlocks.BOUNTY, "", false],
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
