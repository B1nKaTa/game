extends TestCase

const RARITY := {"double_brew": "rare", "locksmiths_tonic": "rare", "topsy_turvy": "common", "gold_top": "rare",
	"smelling_salts": "common", "dutch_courage": "rare", "pet_food": "common"}


func _drink(run: RunState, id: String) -> bool:
	run.potion = null
	run.give_potion(Content.potion(id))
	return run.drink_potion()


func test_the_run_potions_ship_and_the_merchant_never_sells_them() -> void:
	assert_eq(Content.run_potions().size(), RARITY.size())
	for id: String in RARITY:
		var def := Content.potion(id)
		assert_true(def != null, id)
		if def == null:
			continue
		assert_eq(def.run_rarity, RARITY[id], id)
		assert_false(def.is_for_sale(), "%s is found in runs, never brewed" % id)
		assert_false(def.short_name.is_empty(), id)


func test_the_count_potions_do_what_they_say() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.bombs = 3
	assert_true(_drink(run, "double_brew"))
	assert_eq(run.bombs, 6)
	run.keys = 5
	assert_true(_drink(run, "locksmiths_tonic"))
	assert_eq(run.keys, 10)
	assert_true(_drink(run, "topsy_turvy"))
	assert_eq(run.keys, 6)
	assert_eq(run.bombs, 10)
	assert_true(_drink(run, "gold_top"))
	assert_eq(kit.paid, 160)


func test_smelling_salts_stun_the_next_fight_room_once() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	assert_true(_drink(run, "smelling_salts"))
	run.effects.room_enter(null)
	assert_eq(run.effects.lasting_entries().size(), 1, "no fight in an empty room")
	var enemy := kit.enemy()
	run.effects.room_enter(null)
	assert_true(enemy.is_stunned())
	assert_eq(run.effects.lasting_entries().size(), 0)
	kit.free_enemies()


func test_dutch_courage_hits_harder_hurts_double_for_two_clears() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var enemy := kit.enemy()
	assert_true(_drink(run, "dutch_courage"))
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 16.0)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 2)
	run.effects.room_clear(null)
	assert_eq(run.effects.lasting_entries().size(), 1)
	var raw: Dictionary = JSON.parse_string(JSON.stringify(RunCheckpoint.run_to_dict(run)))
	var back := ItemKit.new().make_run()
	RunCheckpoint.apply_run(back, raw, Content.items())
	assert_eq(back.effects.lasting_entries().size(), 1, "it survives a resume")
	run.effects.room_clear(null)
	assert_eq(run.effects.lasting_entries().size(), 0)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1)
	kit.free_enemies()


func test_pet_food_doubles_pets_until_the_floor_ends() -> void:
	var run := ItemKit.new().run_with(["rex"])
	assert_true(_drink(run, "pet_food"))
	assert_near(run.pet_damage_mult(), 2.0)
	run.effects.room_clear(null)
	assert_near(run.pet_damage_mult(), 2.0)
	run.effects.floor_start()
	assert_near(run.pet_damage_mult(), 1.0)
