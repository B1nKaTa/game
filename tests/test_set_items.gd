extends TestCase

const BUILDS := {"set_tea_lady": "thermos", "set_civil_servant": "slip", "set_penny_pincher": "pension", "set_animal_lover": "pets",
	"set_full_set": "bite", "set_old_soldier": "cane", "set_spry": "dodge", "set_hypochondriac": "pills", "set_daredevil": "risk",
	"set_rulebook": "rules", "set_nostalgic": "memory"}


func _set_run(ids: Array) -> RunState:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.effects.set_sets(Content.sets())
	for id: String in ids:
		run.add_item(ItemKit.item(id))
	return run


func test_eleven_sets_ship_one_per_build_but_any() -> void:
	var sets := Content.sets()
	assert_eq(sets.size(), 11)
	for def in sets:
		assert_eq(def.build, BUILDS.get(def.id, ""), def.id)
		assert_eq(def.needed, 3, def.id)
		assert_false(def.description.is_empty(), def.id)


func test_tea_lady_counts_three_more_and_widens_blasts() -> void:
	var run := _set_run(["tea_cosy", "pressure_cooker", "tea_break"])
	assert_true(run.effects.has_set("set_tea_lady"))
	run.bombs = 50
	assert_eq(run.scaled_bombs(), 23)
	assert_near(run.stats.blast_radius, PlayerStats.BASE_BLAST_RADIUS * (1.0 + 0.5 + 0.25))


func test_the_stat_sets_add_what_they_say() -> void:
	assert_near(_set_run(["money_belt", "piggy_bank", "coupon_booklet"]).stats.coin_reach_mult, 21.0)
	assert_eq(_set_run(["boomerang_bite", "glue_gun", "windup_teeth"]).stats.teeth_sets, 2)
	assert_eq(_set_run(["spare_set", "glue_gun", "windup_teeth"]).stats.teeth_sets, 3)
	var spry := _set_run(["afterimage", "bad_hip", "rocking_chair"])
	assert_eq(spry.stats.dodge_charges, 2)
	assert_near(spry.stats.dodge_length, 1.3)
	var hypo := _set_run(["casserole_dish", "life_jacket", "hospital_bracelet"])
	assert_eq(hypo.stats.max_pills, PlayerStats.BASE_PILLS + 2)
	assert_true(hypo.health.half_heal_bonus)
	var book := _set_run(["fine_print", "gold_star", "brown_envelope"])
	assert_eq(book.stats.extra_rule_rooms, 1)
	assert_eq(book.stats.bonus_kept_reels, 1)
	assert_eq(_set_run(["photo_album", "scrapbook", "rose_tinted"]).reel_cap(), 3)


func test_the_animal_lover_adds_a_stray_cat_that_scratches() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.effects.set_sets(Content.sets())
	for id in ["rex", "mittens", "budgie"]:
		run.add_item(ItemKit.item(id))
	assert_true(run.effects.has_set("set_animal_lover"))
	assert_eq(run.pet_count(), 4)
	var enemy := kit.enemy()
	enemy.position = Vector2(300, 0)
	var near := kit.enemy()
	near.position = Vector2(60, 0)
	var before := near.hp
	var mult := run.pet_damage_mult()
	run.effects.tick(1.5)
	assert_true(before - near.hp >= 4.0 * mult - 0.01, "the cat scratched")
	kit.free_enemies()


func test_the_civil_servant_drops_a_slip_about_one_clear_in_three() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.effects.set_sets(Content.sets())
	for id in ["in_triplicate", "key_cutter", "desk_drawer"]:
		run.add_item(ItemKit.item(id))
	var servant = run.effects.effect_of("set_civil_servant")
	servant.rng.seed = 7
	for i in 60:
		run.effects.room_clear(null)
	var slips := kit.drops.filter(func(drop): return drop[0] == RoomRules.DROP_KEY).size()
	assert_true(slips >= 10 and slips <= 30, "about a third: %d of 60" % slips)


func test_the_old_soldier_sends_a_wave_with_every_finisher() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.effects.set_sets(Content.sets())
	for id in ["cane_hook", "rusty_hinge", "bingo_dabber"]:
		run.add_item(ItemKit.item(id))
	run.effects.swing(SwingAttack.new(Vector2.RIGHT, 44.0, 60.0, 18.0, 60.0, false, true))
	assert_eq(kit.fx_of(ItemFx.FxWave).size(), 1)
	run.effects.swing(SwingAttack.new(Vector2.RIGHT, 44.0, 60.0, 10.0, 60.0, false, false))
	assert_eq(kit.fx_of(ItemFx.FxWave).size(), 1)


func test_the_old_soldier_sends_nothing_while_the_loop_counts_damage() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.effects.set_sets(Content.sets())
	for id in ["cane_hook", "rusty_hinge", "bingo_dabber"]:
		run.add_item(ItemKit.item(id))
	run.effects.ctx.counting_exact = true
	run.effects.swing(SwingAttack.new(Vector2.RIGHT, 44.0, 60.0, 18.0, 60.0, false, true))
	assert_eq(kit.fx_of(ItemFx.FxWave).size(), 0)


func test_the_daredevil_heals_half_a_pill_on_a_rooms_first_kill() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.effects.set_sets(Content.sets())
	for id in ["photo_of_grandkids", "unpaid_bill", "glass_hip"]:
		run.add_item(ItemKit.item(id))
	run.health.pills = 2
	run.effects.room_enter(null)
	run.effects.kill(kit.enemy(), RunEffects.SWING)
	run.effects.kill(kit.enemy(), RunEffects.SWING)
	assert_eq(run.health.half_pills, 1, "once a room")
	kit.free_enemies()


func test_a_set_keeps_its_bonus_after_an_active_leaves() -> void:
	var run := _set_run(["tea_cosy", "pressure_cooker", "tea_break"])
	run.items.clear()
	run.refresh_stats()
	assert_true(run.effects.has_set("set_tea_lady"), "a formed set stays")
	assert_near(run.stats.blast_radius, PlayerStats.BASE_BLAST_RADIUS * 1.25)


func test_every_pet_has_a_sprite_the_prop_art_can_load() -> void:
	var pets := 0
	for item in Content.all_items():
		if not item.is_pet():
			continue
		pets += 1
		var look := str(item.effect.get("look"))
		assert_false(look.is_empty(), item.id)
		assert_true(PropArt.texture("pet_" + look) != null, "pet_%s.png loads" % look)
	assert_true(pets >= 10, "ten pets: %d" % pets)
