extends TestCase

const RULES := {"model_citizen": "rare", "repeat_offender": "rare", "fine_print": "common", "brown_envelope": "rare",
	"turned_auditor": "legendary", "gold_star": "common"}
const MEMORY := {"photo_album": "rare", "old_projector": "rare", "those_were_the_days": "common", "rose_tinted": "rare", "scrapbook": "legendary"}


func test_the_rules_and_memory_items_ship_and_wait_for_rule_floors() -> void:
	for id: String in RULES:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.build, "rules", id)
		assert_eq(item.rarity, RULES[id], id)
		assert_true(item.needs_rules(), id)
	for id: String in MEMORY:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.build, "memory", id)
		assert_eq(item.rarity, MEMORY[id], id)
	assert_eq(ItemKit.item("turned_auditor").display_name, "Clipboard of Your Own")


func test_kept_and_broken_rules_this_run_add_six_percent_each() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["model_citizen", "repeat_offender"])
	var enemy := kit.enemy()
	run.rules_kept = 2
	run.rules_broken = 1
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 10.0 * 1.12 * 1.06)
	kit.free_enemies()


func test_the_auditor_hits_harder_for_a_repeat_offender_and_pays_double_with_an_envelope() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["repeat_offender", "brown_envelope"])
	var auditor := kit.enemy("auditor")
	run.effects.auditor(auditor)
	assert_eq(auditor.extra_damage, 1)
	assert_near(auditor.coin_mult, 2.0)
	assert_true(auditor.leaves_item)
	kit.free_enemies()


func test_fine_print_lets_one_break_a_floor_off() -> void:
	var run := ItemKit.new().run_with(["fine_print"])
	assert_true(run.effects.excuses_rule_break())
	assert_false(run.effects.excuses_rule_break())
	run.effects.floor_start()
	assert_true(run.effects.excuses_rule_break(), "a new floor, a new warning")


func test_the_clipboard_takes_his_side() -> void:
	assert_true(ItemKit.new().run_with(["turned_auditor"]).effects.sides_with_you())


func test_a_gold_star_drops_a_pill_for_a_kept_rule() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["gold_star"])
	run.effects.event(RunEffects.EVENT_RULE_KEPT)
	assert_eq(kit.drops.size(), 1)
	assert_eq(kit.drops[0][0], RoomRules.DROP_HEAL)
	run.effects.event(RunEffects.EVENT_RULE_BROKEN)
	assert_eq(kit.drops.size(), 1)


func test_the_album_and_projector_add_a_reel_and_a_room() -> void:
	var kit := ItemKit.new()
	assert_eq(kit.run_with(["photo_album"]).reel_cap(), 2)
	assert_eq(kit.run_with(["old_projector"]).stats.extra_era_rooms, 1)


func test_a_flashback_ending_heals_a_pill() -> void:
	var run := ItemKit.new().run_with(["those_were_the_days"])
	run.health.pills = 2
	run.effects.event(RunEffects.EVENT_FLASHBACK_END)
	assert_eq(run.health.pills, 3)


func test_rose_tint_helps_young_harold_and_the_scrapbook_old_harold() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["rose_tinted", "scrapbook"])
	var enemy := kit.enemy()
	run.flashbacks_played = 2
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 11.6, "old Harold: the scrapbook alone")
	run.era = Eras.FOOTBALL
	assert_near(run.effects.hit_damage(enemy, 10.0, "era"), 13.0, "young Harold: the glasses alone")
	kit.free_enemies()
