extends TestCase

# One test per rule of the hundred items' first batch: the twelve cane items and the eight denture
# items, and the combos they make possible (Full Set, Dentist's Nightmare, Bingo Night).

const CaneSword := preload("res://scripts/items/cane_sword.gd")
const Dabber := preload("res://scripts/items/bingo_dabber.gd")
const Hinge := preload("res://scripts/items/rusty_hinge.gd")
const Rocking := preload("res://scripts/items/rocking_chair.gd")
const Needles := preload("res://scripts/items/knitting_needles.gd")
const Pin := preload("res://scripts/items/rolling_pin.gd")
const Scythe := preload("res://scripts/items/reapers_scythe.gd")

# id: [rarity, source, first-clear path or ""]
const BATCH := {
	"walker_tennis_balls": [ItemDef.COMMON, ItemUnlocks.START, ""],
	"cane_sword": [ItemDef.RARE, ItemUnlocks.RECIPE, ""],
	"bingo_dabber": [ItemDef.COMMON, ItemUnlocks.FIRST_CLEAR, "sunset_shores"],
	"rusty_hinge": [ItemDef.COMMON, ItemUnlocks.START, ""],
	"reading_glasses": [ItemDef.RARE, ItemUnlocks.START, ""],
	"rocking_chair": [ItemDef.COMMON, ItemUnlocks.START, ""],
	"rubber_ferrule": [ItemDef.COMMON, ItemUnlocks.START, ""],
	"knitting_needles": [ItemDef.RARE, ItemUnlocks.FIRST_CLEAR, "fairways_end"],
	"shoe_horn": [ItemDef.COMMON, ItemUnlocks.START, ""],
	"brass_topper": [ItemDef.RARE, ItemUnlocks.FIRST_CLEAR, "fairways_end"],
	"rolling_pin": [ItemDef.LEGENDARY, ItemUnlocks.RECIPE, ""],
	"reapers_scythe": [ItemDef.LEGENDARY, ItemUnlocks.BOUNTY, ""],
	"glue_gun": [ItemDef.RARE, ItemUnlocks.RECIPE, ""],
	"spare_set": [ItemDef.RARE, ItemUnlocks.RECIPE, ""],
	"boomerang_bite": [ItemDef.COMMON, ItemUnlocks.START, ""],
	"windup_teeth": [ItemDef.RARE, ItemUnlocks.START, ""],
	"overbite": [ItemDef.COMMON, ItemUnlocks.START, ""],
}


func _swing(heavy := false, finisher := false) -> SwingAttack:
	return SwingAttack.new(Vector2.RIGHT, Player.ATTACK_REACH, Player.ATTACK_ANGLE, 10.0, Player.ATTACK_PUSH, heavy, finisher)


func _flying(run: RunState, state := DentureThrow.new()) -> ThrownDentures:
	state.try_throw()
	var teeth := ThrownDentures.new()
	teeth.setup(state, null, Vector2.RIGHT, run.bite_damage_mult(), run.stats.bite_range, run.stats.bites_per_throw)
	teeth.effects = run.effects
	teeth.glue_time = run.stats.teeth_glue_time
	teeth.boomerang = run.stats.teeth_boomerang
	teeth.floor_bite = run.stats.teeth_floor_bite
	return teeth


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
		assert_false(item.cursed, id)
		assert_false(item.tags.is_empty(), id)
		if item.needs_recipe():
			assert_true(item.craft_price >= 150 and item.craft_price <= 400, "%s costs %d" % [id, item.craft_price])


func test_every_batch_text_is_two_sentences_and_has_a_coach_tip() -> void:
	for id: String in BATCH:
		var item := ItemKit.item(id)
		assert_true(item.description.count(". ") >= 1 and item.description[-1] in [".", "?", "!"], id)
		assert_true(CoachTips.TIPS.has(id), "%s has a tip" % id)


func test_walker_tennis_balls_knock_enemies_back_further() -> void:
	var run := ItemKit.new().run_with(["walker_tennis_balls"])
	assert_near(run.stats.swing_push_mult, 1.6)
	assert_near(ItemKit.new().make_run().stats.swing_push_mult, 1.0)
	var player := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	assert_true(player.contains("push * run.stats.swing_push_mult"), "every swing's push is scaled")


func test_cane_sword_sends_a_wave_on_a_full_charge_only() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["cane_sword"])
	run.effects.charge_release(false)
	assert_eq(kit.fx_of(ItemFx.FxWave).size(), 0)
	run.effects.charge_release(true)
	assert_eq(kit.fx_of(ItemFx.FxWave).size(), 1)


func test_the_cane_swords_wave_hits_what_its_crescent_covers_once() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["cane_sword"])
	var ahead := kit.enemy("intern_reaper", 100.0)
	ahead.position = Vector2(8, 0)
	var wing := kit.enemy("intern_reaper", 100.0)
	wing.position = Vector2(-10, 22)
	var clear := kit.enemy("intern_reaper", 100.0)
	clear.position = Vector2(0, 80)
	var wave := ItemFx.make_wave(run.effects.ctx, Vector2.RIGHT, CaneSword.DAMAGE, CaneSword.DISTANCE)
	assert_true(wave._strike())
	assert_near(ahead.hp, 100.0 - CaneSword.DAMAGE)
	assert_near(wing.hp, 100.0 - CaneSword.DAMAGE, "the crescent's tips reach back beside it")
	assert_near(clear.hp, 100.0)
	assert_false(wave._strike(), "each enemy once")
	wave.free()
	kit.free_enemies()


func test_bingo_dabber_bursts_on_the_fifth_mark() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["bingo_dabber"])
	var effect = run.effects.effect_of("bingo_dabber")
	var enemy := kit.enemy("intern_reaper", 1000.0)
	for i in 4:
		run.effects.land(enemy, 1.0, RunEffects.SWING)
	assert_eq(effect.marks_on(enemy), 4)
	run.effects.land(enemy, 1.0, RunEffects.ITEM)
	assert_eq(effect.marks_on(enemy), 4, "an item's hit dabs nothing")
	assert_true(kit.fx_of(ItemFx.FxDabs).size() >= 1, "the marks show")
	run.effects.land(enemy, 1.0, RunEffects.BITE)
	assert_near(enemy.hp, 1000.0 - 6.0 - Dabber.BURST)
	assert_eq(effect.marks_on(enemy), 0, "the card starts again")
	var pops := kit.fx_of(ItemFx.FxPop)
	assert_eq(pops.size(), 1)
	assert_eq(pops[0]["text"], "BINGO!")
	kit.free_enemies()


func test_rusty_hinge_stuns_on_the_combos_third_hit_with_a_rest_between() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["rusty_hinge"])
	var enemy := kit.enemy("intern_reaper", 1000.0)
	run.effects.land(enemy, 1.0, RunEffects.SWING)
	assert_false(enemy.is_stunned())
	run.effects.land(enemy, 1.0, RunEffects.COMBO_3)
	assert_true(enemy.is_stunned() and enemy.is_dazed())
	enemy._stun_left = 0.0
	run.effects.tick(0.5)
	run.effects.land(enemy, 1.0, RunEffects.COMBO_3)
	assert_false(enemy.is_stunned(), "not again so soon")
	run.effects.tick(Hinge.AGAIN_AFTER)
	run.effects.land(enemy, 1.0, RunEffects.COMBO_3)
	assert_true(enemy.is_stunned())
	kit.free_enemies()


func test_an_items_stun_holds_the_enemy_still() -> void:
	var kit := ItemKit.new()
	var enemy := kit.enemy("intern_reaper")
	enemy.stun(0.5)
	assert_true(enemy.is_stunned())
	var source := FileAccess.get_file_as_string("res://scripts/actors/enemy.gd")
	assert_true(source.contains("if _stun_left <= 0.0:\r\n\t\t_behavior.tick(self, delta)") or source.contains("if _stun_left <= 0.0:\n\t\t_behavior.tick(self, delta)"), "a stunned enemy's behavior waits")
	var ctx := FileAccess.get_file_as_string("res://scripts/core/effect_context.gd")
	assert_true(ctx.contains("enemy.stun(seconds)"), "items stun through Enemy.stun")
	kit.free_enemies()


func test_reading_glasses_give_the_dodge_back_after_a_swing_landing_three() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["reading_glasses"])
	var effect = run.effects.effect_of("reading_glasses")
	var enemy := kit.enemy("intern_reaper", 1000.0)
	var swing := _swing()
	run.effects.swing(swing)
	run.effects.land(enemy, 1.0, RunEffects.SWING)
	run.effects.land(enemy, 1.0, RunEffects.SWING)
	run.effects.land(enemy, 1.0, RunEffects.ITEM)
	run.effects.swing_end(swing)
	assert_eq(effect.refunds, 0, "two of his own and an item's are not three")
	run.effects.swing(swing)
	for i in 3:
		run.effects.land(enemy, 1.0, RunEffects.COMBO_3)
	run.effects.swing_end(swing)
	assert_eq(effect.refunds, 1)
	var timer := DodgeTimer.new()
	timer.try_start(1.0)
	timer.tick(0.3)
	timer.clear_cooldown()
	assert_near(timer.cooldown_left(), 0.0)
	assert_true(timer.try_start(1.0), "a refunded dodge starts at once")
	kit.free_enemies()


func test_rocking_chair_makes_the_first_swing_after_a_dodge_heavy() -> void:
	var run := ItemKit.new().run_with(["rocking_chair"])
	var plain := _swing()
	run.effects.swing(plain)
	assert_near(plain.damage, 10.0, "no dodge, no rhythm")
	run.effects.dodge_end()
	var first := _swing()
	run.effects.swing(first)
	assert_near(first.damage, 10.0 * Rocking.MULT)
	assert_near(first.push, Rocking.PUSH)
	var second := _swing()
	run.effects.swing(second)
	assert_near(second.damage, 10.0, "only the first")
	run.effects.dodge_end()
	run.effects.tick(Rocking.WINDOW + 0.05)
	var late := _swing()
	run.effects.swing(late)
	assert_near(late.damage, 10.0, "too late")


func test_rubber_ferrule_swings_faster_for_a_little_less() -> void:
	var run := ItemKit.new().run_with(["rubber_ferrule"])
	assert_near(run.stats.swing_speed, 1.15)
	assert_near(run.damage_mult(), 0.95)


func test_knitting_needles_poke_two_needles_with_every_swing() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["knitting_needles"])
	run.effects.swing(_swing())
	assert_eq(kit.fx_of(ItemFx.FxNeedle).size(), 2)
	var enemy := kit.enemy("intern_reaper", 100.0)
	enemy.position = Vector2(10, 0)
	var behind := kit.enemy("intern_reaper", 100.0)
	behind.position = Vector2(14, 0)
	var needle := ItemFx.make_needle(run.effects.ctx, Vector2.RIGHT, Needles.DAMAGE, Needles.DISTANCE)
	assert_true(needle._strike())
	assert_near(enemy.hp + behind.hp, 200.0 - Needles.DAMAGE, "a needle stops in the first it pokes")
	needle.free()
	kit.free_enemies()


func test_shoe_horn_hits_harder_while_an_enemy_winds_up() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["shoe_horn"])
	var enemy := kit.enemy()
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 10.0)
	var windup := Telegraph.new()
	windup.start(1.0)
	enemy.set_warning(windup, 30.0)
	assert_true(enemy.is_winding_up())
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.BITE), 13.0)
	windup.tick(1.0)
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 10.0, "the attack is out")
	kit.free_enemies()


func test_brass_topper_turns_a_finisher_into_a_ring() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["brass_topper"])
	var plain := _swing()
	run.effects.swing(plain)
	assert_near(plain.half_angle_deg, Player.ATTACK_ANGLE)
	var heavy := _swing(true)
	run.effects.swing(heavy)
	assert_near(heavy.half_angle_deg, Player.ATTACK_ANGLE)
	var finisher := _swing(false, true)
	run.effects.swing(finisher)
	assert_near(finisher.half_angle_deg, 180.0)
	var behind := Rect2(Vector2(-40, -10), Vector2(20, 20))
	assert_true(finisher.covers(Vector2.ZERO, behind), "it hits behind him")
	assert_false(plain.covers(Vector2.ZERO, behind))
	assert_eq(kit.fx_of(ItemFx.FxShockwave).size(), 1)


func test_rolling_pin_makes_every_plain_swing_a_slow_smash_both_ways() -> void:
	var run := ItemKit.new().run_with(["rolling_pin"])
	assert_near(run.stats.swing_speed, 0.6, "slow")
	var swing := _swing()
	run.effects.swing(swing)
	assert_near(swing.damage, 10.0 * Pin.DAMAGE_MULT)
	assert_near(swing.reach, Pin.REACH)
	assert_true(swing.both_ways)
	assert_eq(swing.style, SwingAttack.STYLE_PIN)
	assert_near(swing.duration, Pin.DURATION)
	assert_true(swing.covers(Vector2.ZERO, Rect2(Vector2(-60, -8), Vector2(16, 16))), "and behind him")
	assert_eq(swing.push_toward(Vector2.ZERO, Vector2(-30, 0)), Vector2.LEFT * swing.push, "pushing what is behind away from him")
	swing.tick(0.12)
	assert_true(swing.is_active(), "it hits for as long as it is drawn")
	var charged := _swing(true)
	run.effects.swing(charged)
	assert_eq(charged.style, SwingAttack.STYLE_ARC)
	assert_false(charged.both_ways)


func test_reapers_scythe_makes_a_full_charge_a_spinning_sweep() -> void:
	var run := ItemKit.new().run_with(["reapers_scythe"])
	var plain := _swing()
	run.effects.swing(plain)
	assert_eq(plain.style, SwingAttack.STYLE_ARC)
	var charged := _swing(true)
	run.effects.swing(charged)
	assert_eq(charged.style, SwingAttack.STYLE_SWEEP)
	assert_near(charged.half_angle_deg, 180.0)
	assert_near(charged.reach, Scythe.REACH)
	assert_near(charged.damage, 10.0 * Scythe.DAMAGE_MULT)
	assert_true(charged.covers(Vector2.ZERO, Rect2(Vector2(-8, 50), Vector2(16, 16))), "all the way round")
	charged.tick(Scythe.DURATION - 0.05)
	assert_true(charged.is_active())
	var player := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	assert_true(player.contains("run.effects.swing(_active_swing)") and player.contains("_draw_sweep(swing)"), "drawn as it hits")


func test_glue_gun_keeps_the_teeth_biting_for_two_seconds() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["glue_gun"])
	assert_near(run.stats.teeth_glue_time, 2.0)
	var enemy := kit.enemy("intern_reaper", 1000.0)
	var state := DentureThrow.new()
	var teeth := _flying(run, state)
	assert_true(teeth.try_glue(enemy))
	for i in 4:
		teeth.hold_glue(0.5)
	assert_near(enemy.hp, 1000.0 - 4.0 * ThrownDentures.DAMAGE * ThrownDentures.GLUE_SHARE)
	assert_false(teeth.is_glued(), "the glue gives after two seconds")
	assert_true(state.is_dropped())
	assert_false(teeth.try_glue(enemy), "once a throw")
	teeth.free()
	kit.free_enemies()


func test_spare_set_throws_two_sets_and_the_spare_holds_nothing_back() -> void:
	var run := ItemKit.new().run_with(["spare_set"])
	assert_eq(run.stats.teeth_sets, 2)
	assert_eq(ItemKit.new().make_run().stats.teeth_sets, 1)
	var state := DentureThrow.new()
	state.try_throw()
	state.drop()
	var spare := ThrownDentures.new()
	spare.setup(state, null, Vector2.RIGHT, 1.0)
	spare.spare = true
	var caught := [0]
	spare.caught.connect(func(): caught[0] += 1)
	spare._catch()
	assert_eq(caught[0], 0, "a spare's catch is no catch of his")
	spare.free()
	var player := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	assert_true(player.contains("for i in sets - 1:") and player.contains("_free_spares()"), "spares fly and are recalled with the room")


func test_boomerang_bite_turns_home_and_bites_on_the_way() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["boomerang_bite"])
	assert_true(run.stats.teeth_boomerang)
	var enemy := kit.enemy("intern_reaper", 1000.0)
	enemy.position = Vector2(6, 0)
	var state := DentureThrow.new()
	var teeth := _flying(run, state)
	var home := Node2D.new()
	home.position = Vector2(200, 0)
	teeth._player = home
	teeth.end_flight()
	assert_true(state.is_returning(), "no lying about")
	teeth._return_to_player(0.001)
	assert_near(enemy.hp, 1000.0 - ThrownDentures.DAMAGE)
	teeth._return_to_player(0.001)
	assert_near(enemy.hp, 1000.0 - ThrownDentures.DAMAGE, "once on the way back")
	var plain := _flying(ItemKit.new().make_run())
	plain.effects = run.effects
	plain._player = home
	plain.end_flight()
	plain._state.recall()
	plain._return_to_player(0.001)
	assert_near(enemy.hp, 1000.0 - ThrownDentures.DAMAGE, "plain teeth coming home bite nothing")
	teeth.free()
	plain.free()
	home.free()
	kit.free_enemies()


func test_windup_teeth_bite_what_walks_over_them_now_and_then() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["windup_teeth"])
	assert_true(run.stats.teeth_floor_bite)
	var enemy := kit.enemy("intern_reaper", 1000.0)
	enemy.position = Vector2(5, 0)
	var state := DentureThrow.new()
	var teeth := _flying(run, state)
	state.drop()
	teeth.bite_on_floor(0.1)
	assert_near(enemy.hp, 1000.0 - ThrownDentures.DAMAGE * ThrownDentures.FLOOR_SHARE)
	teeth.bite_on_floor(0.3)
	assert_near(enemy.hp, 1000.0 - ThrownDentures.DAMAGE * ThrownDentures.FLOOR_SHARE, "not every frame")
	teeth.bite_on_floor(ThrownDentures.FLOOR_BITE_EVERY)
	assert_near(enemy.hp, 1000.0 - 2.0 * ThrownDentures.DAMAGE * ThrownDentures.FLOOR_SHARE)
	teeth.free()
	kit.free_enemies()


func test_overbite_throws_forty_percent_further() -> void:
	var run := ItemKit.new().run_with(["overbite"])
	assert_near(run.stats.bite_range, DentureThrow.BASE_RANGE * 1.4)