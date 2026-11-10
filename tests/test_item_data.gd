extends TestCase

# The new list's item fields, the retired registry, the 20-count rule, the purse and the run's own
# rule and flashback counters.


func test_new_item_fields_default_to_a_plain_passive() -> void:
	var item := ItemDef.new()
	assert_eq(item.build, "any")
	assert_eq(item.kind, ItemDef.KIND_PASSIVE)
	assert_false(item.is_active())
	assert_false(item.is_pet())
	assert_false(item.needs_rules())
	item.build = "rules"
	assert_true(item.needs_rules())
	item.build = "memory"
	assert_true(item.needs_rules())
	item.kind = ItemDef.KIND_ACTIVE
	assert_true(item.is_active())
	item.kind = ItemDef.KIND_PET
	assert_true(item.is_pet())
	for build: String in ItemDef.BUILDS:
		assert_true(ItemDef.TAGS.has(build), "%s is a tag too" % build)


func _named(id: String) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	return item


func test_the_pool_leaves_retired_ids_out() -> void:
	var all: Array[ItemDef] = [_named("kept_a"), _named("gone_b"), _named("kept_c")]
	var pool := Content.pool_of(all, ["gone_b"])
	assert_eq(pool.size(), 2)
	assert_eq(pool[0].id, "kept_a")
	assert_eq(pool[1].id, "kept_c")
	assert_eq(Content.pool_of(all, []).size(), 3)
	assert_eq(Content.items().size(), Content.pool_of(Content.all_items(), RetiredContent.RETIRED_ITEMS).size())
	assert_eq(RetiredContent.current_id("second_thermos_strap"), "flask_holster")
	assert_eq(RetiredContent.current_id("dentures"), "strong_dentures")
	assert_eq(RetiredContent.current_id("tea_cosy"), "tea_cosy", "a kept id maps to itself")


func test_scaled_counts_stop_at_twenty_and_the_bonus_raises_the_thermos_cap() -> void:
	var run := ItemKit.new().make_run()
	run.bombs = 50
	run.keys = 50
	assert_eq(run.scaled_bombs(), PlayerStats.SCALE_CAP)
	assert_eq(run.scaled_keys(), 20)
	var bonus := ItemDef.new()
	bonus.id = "test_scale"
	bonus.thermos_scale_bonus = 4
	run.add_item(bonus)
	assert_eq(run.scaled_bombs(), 24)
	assert_eq(run.scaled_keys(), 20, "nothing raises the Slip cap")
	run.bombs = 3
	assert_eq(run.scaled_bombs(), 3)


func test_adding_many_never_passes_the_hold_cap() -> void:
	var run := ItemKit.new().make_run()
	run.bombs = 97
	run.add_bombs(5)
	assert_eq(run.bombs, RunState.MAX_CONSUMABLE)
	run.keys = 0
	run.add_keys(3)
	assert_eq(run.keys, 3)
	run.add_keys(0)
	assert_eq(run.keys, 3)


func test_the_purse_is_what_the_bank_gained_this_run() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	kit.pension = 500
	run.pension_at_start = 400
	assert_eq(run.effects.ctx.purse(), 100)
	kit.pension = 300
	assert_eq(run.effects.ctx.purse(), 0, "never below zero")
	run.pension_at_start = 0
	kit.pension = 30
	assert_true(run.effects.ctx.spend_from_purse(20))
	assert_eq(kit.pension, 10)
	assert_false(run.effects.ctx.spend_from_purse(20), "the purse cannot cover it")
	assert_eq(kit.pension, 10)
	run.pension_at_start = -1
	assert_eq(run.effects.ctx.purse(), 10, "an unknown start counts the whole bank, never more")


func test_new_stats_add_up_from_items() -> void:
	var a := ItemDef.new()
	a.id = "a"
	a.extra_reels = 1
	a.pet_damage_bonus = 0.5
	a.bonus_teeth_sets = 1
	a.thermos_scale_bonus = 3
	var b := ItemDef.new()
	b.id = "b"
	b.extra_reels = 1
	b.teeth_sets = 2
	b.extra_rule_rooms = 1
	b.bonus_kept_reels = 1
	b.half_heal_bonus = true
	b.throws_thermos = true
	b.slip_cost_cut = 1
	b.extra_pets = 1
	b.pet_speed_bonus = 0.25
	b.extra_era_rooms = 1
	b.thermos_scale_bonus = 4
	var none: Array[UpgradeDef] = []
	var items: Array[ItemDef] = [a, b]
	var stats := PlayerStats.compute(none, {}, items)
	assert_eq(stats.extra_reels, 2)
	assert_near(stats.pet_damage_bonus, 0.5)
	assert_eq(stats.teeth_sets, 3, "the largest set count plus the bonus")
	assert_eq(stats.extra_rule_rooms, 1)
	assert_eq(stats.bonus_kept_reels, 1)
	assert_true(stats.half_heal_bonus)
	assert_true(stats.throws_thermos)
	assert_eq(stats.slip_cost_cut, 1)
	assert_eq(stats.extra_pets, 1)
	assert_near(stats.pet_speed_bonus, 0.25)
	assert_eq(stats.extra_era_rooms, 1)
	assert_eq(stats.thermos_scale_bonus, 7)
	var plain := PlayerStats.compute(none, {}, [] as Array[ItemDef])
	assert_eq(plain.teeth_sets, 1)
	assert_false(plain.throws_thermos)


func test_the_run_counters_and_purse_start_survive_the_checkpoint() -> void:
	var run := ItemKit.new().make_run()
	run.pension_at_start = 250
	run.floor_depth = 3
	run.rules_kept = 2
	run.rules_broken = 1
	run.flashbacks_played = 4
	var raw: Dictionary = JSON.parse_string(JSON.stringify(RunCheckpoint.run_to_dict(run)))
	var back := ItemKit.new().make_run()
	RunCheckpoint.apply_run(back, raw, Content.items())
	assert_eq(back.pension_at_start, 250)
	assert_eq(back.floor_depth, 3)
	assert_eq(back.rules_kept, 2)
	assert_eq(back.rules_broken, 1)
	assert_eq(back.flashbacks_played, 4)
	var old := ItemKit.new().make_run()
	RunCheckpoint.apply_run(old, {}, Content.items())
	assert_eq(old.rules_kept, 0, "an older checkpoint starts at zero")
	assert_eq(old.pension_at_start, -1, "unknown until the floor scene reads the bank")


func test_the_floor_scene_sets_the_purse_and_depth() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	assert_true(source.contains("_run.pension_at_start = Progress.data.pension"))
	assert_true(source.contains("ctx.pension_balance = _bank_balance"))
	assert_true(source.contains("_run.floor_depth = def.depth"))
	assert_true(source.contains("_run.floor_depth = _depth"))
