extends TestCase

const IDS := {"budgie": ["common", ItemDef.KIND_PET], "tortoise": ["common", ItemDef.KIND_PET], "moths": ["common", ItemDef.KIND_PET],
	"pet_rock": ["common", ItemDef.KIND_PET], "dog_treats": ["common", ItemDef.KIND_PASSIVE], "pet_cemetery_plot": ["legendary", ItemDef.KIND_PASSIVE]}


func test_the_guarding_pets_and_buffs_ship_as_the_list_says() -> void:
	for id: String in IDS:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.build, "pets", id)
		assert_eq(item.rarity, IDS[id][0], id)
		assert_eq(item.kind, IDS[id][1], id)
	assert_eq(ItemKit.item("moths").first_clear_path, "cemetery", "it takes the mothballs' source")
	assert_true(RetiredContent.is_retired("mothball_pockets"))


func test_joey_blocks_a_shot_then_rests_three_seconds() -> void:
	var run := ItemKit.new().run_with(["budgie"])
	var joey = run.effects.effect_of("budgie")
	assert_true(joey.can_block())
	joey.blocked()
	assert_false(joey.can_block())
	run.effects.tick(2.9)
	assert_false(joey.can_block())
	run.effects.tick(0.2)
	assert_true(joey.can_block())
	run.effects.ctx.counting_pills = true
	assert_false(joey.can_block(), "the full loop counts every pill a shot costs")


func test_shelley_plods_and_always_stops_a_shot() -> void:
	var run := ItemKit.new().run_with(["tortoise"])
	var shelley = run.effects.effect_of("tortoise")
	assert_near(shelley.base_speed(), 40.0)
	run.effects.room_enter(null)
	assert_true(shelley.can_block())
	shelley.blocked()
	assert_true(shelley.can_block(), "she never runs out")


func test_the_moths_nibble_what_they_touch_and_each_blocks_one_shot() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["moths"])
	var moths = run.effects.effect_of("moths")
	moths.orbit_speed = 0.0
	run.effects.room_enter(null)
	var enemy := kit.enemy()
	enemy.position = moths.moth_spot(run.effects.ctx, 0)
	var before := enemy.hp
	run.effects.tick(0.01)
	assert_near(before - enemy.hp, 2.0)
	run.effects.tick(0.1)
	assert_near(before - enemy.hp, 2.0, "once a half second per moth")
	run.effects.tick(0.5)
	assert_near(before - enemy.hp, 4.0)
	assert_true(moths.can_block(1))
	moths.blocked(1)
	assert_false(moths.can_block(1))
	assert_true(moths.can_block(0), "the other moth still guards")
	run.effects.tick(4.0)
	assert_true(moths.can_block(1), "it comes back")
	kit.free_enemies()


func test_pet_rock_grows_with_pet_items_and_guards_once_big() -> void:
	var run := ItemKit.new().run_with(["pet_rock"])
	var rock = run.effects.effect_of("pet_rock")
	assert_eq(rock.size(run.effects.ctx), 1)
	assert_false(rock.can_block())
	run.add_item(ItemKit.item("dog_treats"))
	run.add_item(ItemKit.item("rex"))
	assert_eq(rock.size(run.effects.ctx), 3)
	run.effects.room_enter(null)
	assert_true(rock.can_block())


func test_dog_treats_make_pets_hit_harder_and_walk_faster() -> void:
	var run := ItemKit.new().run_with(["dog_treats"])
	assert_near(run.pet_damage_mult(), 1.5)
	assert_near(run.stats.pet_speed_bonus, 0.25)


func test_the_pet_cemetery_plot_adds_eight_percent_per_pet() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["pet_cemetery_plot", "rex", "mittens"])
	var enemy := kit.enemy()
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 11.6)
	kit.free_enemies()
