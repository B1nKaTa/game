extends TestCase

const IDS := {"rex": "rare", "mittens": "rare", "ferret": "rare", "sheepdog": "legendary", "parrot": "rare", "racing_pigeon": "common"}


func test_the_fighting_pets_ship_as_pets() -> void:
	for id: String in IDS:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_eq(item.kind, ItemDef.KIND_PET, id)
		assert_eq(item.build, "pets", id)
		assert_eq(item.rarity, IDS[id], id)
		assert_true(item.effect is PetEffect, id)
	assert_true(RetiredContent.is_retired("penny_jar"))


func test_rex_bites_the_nearest_enemy_every_second() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["rex"])
	var near := kit.enemy()
	near.position = Vector2(100, 0)
	var far := kit.enemy()
	far.position = Vector2(300, 0)
	var before := near.hp
	run.effects.tick(1.0)
	assert_near(before - near.hp, 6.0)
	run.effects.tick(0.5)
	assert_near(before - near.hp, 6.0)
	run.effects.tick(0.5)
	assert_near(before - near.hp, 12.0)
	assert_near(far.hp, far.max_hp(), "out of reach")
	kit.free_enemies()


func test_mittens_finishes_regular_enemies_below_a_quarter() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["mittens"])
	var low := kit.enemy("intern_reaper", 8.0)
	low.position = Vector2(50, 0)
	var healthy := kit.enemy("intern_reaper", 20.0)
	healthy.position = Vector2(40, 0)
	var boss := kit.enemy("regional_reaper")
	boss.hp = boss.max_hp() * 0.1
	boss.position = Vector2(30, 0)
	run.effects.tick(0.5)
	assert_true(low.is_dead())
	assert_false(healthy.is_dead(), "above a quarter")
	assert_false(boss.is_dead(), "never a boss")
	kit.free_enemies()


func test_mittens_only_watches_while_the_full_loop_counts() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["mittens"])
	var low := kit.enemy("intern_reaper", 8.0)
	low.position = Vector2(50, 0)
	run.effects.ctx.counting_exact = true
	run.effects.tick(0.5)
	assert_false(low.is_dead())
	kit.free_enemies()


func test_the_ferret_bites_hard_on_every_dodge() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["ferret"])
	var enemy := kit.enemy()
	enemy.position = Vector2(80, 0)
	var before := enemy.hp
	run.effects.dodge(Vector2.RIGHT)
	assert_near(before - enemy.hp, 15.0)
	kit.free_enemies()


func test_old_shep_herds_regular_enemies_every_six_seconds() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["sheepdog"])
	var stray := kit.enemy()
	stray.position = Vector2(150, 40)
	var boss := kit.enemy("regional_reaper")
	boss.position = Vector2(120, 0)
	run.effects.tick(5.9)
	assert_false(stray.is_pushed())
	run.effects.tick(0.2)
	assert_true(stray.is_pushed())
	assert_true(stray.is_dazed())
	assert_false(boss.is_pushed(), "a boss is not herded")
	kit.free_enemies()


func test_old_shep_only_watches_while_the_full_loop_counts() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["sheepdog"])
	var stray := kit.enemy()
	stray.position = Vector2(150, 40)
	run.effects.ctx.counting_exact = true
	run.effects.tick(6.1)
	assert_false(stray.is_pushed())
	kit.free_enemies()


func test_polly_repeats_a_landed_swing_a_second_later_at_half() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["parrot"])
	var enemy := kit.enemy()
	var swing := SwingAttack.new(Vector2.RIGHT, 44.0, 60.0, 10.0, 60.0, false, false)
	run.effects.swing(swing)
	run.effects.hit(enemy, 10.0, RunEffects.SWING)
	run.effects.swing_end(swing)
	var before := enemy.hp
	run.effects.tick(0.5)
	assert_near(enemy.hp, before)
	run.effects.tick(0.6)
	assert_near(before - enemy.hp, 5.0)
	run.effects.tick(2.0)
	assert_near(before - enemy.hp, 5.0, "once")
	kit.free_enemies()


func test_polly_never_ends_a_boss_fight() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["parrot"])
	var boss := kit.enemy("regional_reaper")
	boss.position = Vector2(30, 0)
	var swing := SwingAttack.new(Vector2.RIGHT, 44.0, 60.0, 10.0, 60.0, false, false)
	run.effects.swing(swing)
	run.effects.hit(boss, 400.0, RunEffects.SWING)
	run.effects.swing_end(swing)
	boss.hp = 2.0
	run.effects.tick(1.1)
	assert_false(boss.is_dead(), "her echo leaves the last blow to him")
	assert_true(boss.hp >= 1.0)
	kit.free_enemies()


func test_the_pigeon_fetches_a_pickup_now_and_then() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["racing_pigeon"])
	kit.can_fetch = true
	run.effects.tick(1.5)
	assert_eq(kit.fetches, 1)
	run.effects.tick(1.0)
	assert_eq(kit.fetches, 1)
	run.effects.tick(0.5)
	assert_eq(kit.fetches, 2)
