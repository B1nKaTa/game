extends TestCase

# One test per rule of the hundred items' first batch: the twelve cane items and the eight denture
# items, and the combos they make possible (Full Set, Dentist's Nightmare, Bingo Night).

const Hinge := preload("res://scripts/items/rusty_hinge.gd")

# id: [rarity, source, first-clear path or ""]
const BATCH := {
	"walker_tennis_balls": [ItemDef.COMMON, ItemUnlocks.START, ""],
	"rusty_hinge": [ItemDef.COMMON, ItemUnlocks.START, ""],
	"rubber_ferrule": [ItemDef.COMMON, ItemUnlocks.START, ""],
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


func test_rubber_ferrule_swings_faster_for_a_little_less() -> void:
	var run := ItemKit.new().run_with(["rubber_ferrule"])
	assert_near(run.stats.swing_speed, 1.15)
	assert_near(run.damage_mult(), 0.95)