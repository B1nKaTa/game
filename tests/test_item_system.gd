extends TestCase

const Counting := preload("res://tests/support/counting_effect.gd")
const HOOKS := ["floor_start", "room_enter", "room_clear", "hit_damage", "hit", "kill", "dodge", "dodge_end",
	"close_call", "hurt", "lethal", "throw", "bite", "charge_release", "bomb", "accepts_pickup", "pickup",
	"shop_open", "tick"]


func _counting(tag: String) -> ItemEffect:
	var effect: ItemEffect = Counting.new()
	effect.tag = tag
	return effect


func _item(id: String, effect: ItemEffect = null) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	item.display_name = id
	item.effect = effect
	return item


# Every dispatch once, so each hook should count exactly one.
func _fire_all(run: RunState, kit: ItemKit) -> void:
	var enemy := kit.enemy("intern_reaper", 10000.0)
	var stock: Array[Dictionary] = []
	run.effects.floor_start()
	run.effects.room_enter(null)
	run.effects.room_clear(null)
	run.effects.hit_damage(enemy, 1.0, RunEffects.SWING)
	run.effects.hit(enemy, 1.0, RunEffects.SWING)
	run.effects.kill(enemy, RunEffects.SWING)
	run.effects.dodge(Vector2.RIGHT)
	run.effects.dodge_end()
	run.effects.close_call()
	run.effects.hurt(1, RunEffects.HURT_ENEMY)
	run.effects.lethal()
	run.effects.throw()
	run.effects.bite(enemy)
	run.effects.charge_release(true)
	run.effects.bomb(Vector2.ZERO)
	run.effects.accepts_pickup(RunEffects.HEAL)
	run.effects.pickup(RunEffects.PENSION, 3)
	run.effects.shop_open(stock)
	run.effects.tick(0.1)


func test_each_hook_fires_once_for_each_held_item() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.add_item(_item("a", _counting("a")))
	_fire_all(run, kit)
	var effect = run.effects.effect_of("a")
	assert_eq(effect.counts.get("gain", 0), 1, "gain")
	for hook: String in HOOKS:
		assert_eq(effect.counts.get(hook, 0), 1, hook)
	kit.free_enemies()


func test_hooks_run_in_pickup_order() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.add_item(_item("second", _counting("b")))
	run.add_item(_item("first", _counting("a")))
	kit.notices.clear()
	run.effects.dodge(Vector2.UP)
	assert_eq(kit.notices, ["b:dodge", "a:dodge"] as Array[String])


func test_each_run_gets_its_own_copy_of_an_effect() -> void:
	var item := _item("shared", _counting("s"))
	var kit := ItemKit.new()
	var one := kit.make_run()
	var two := kit.make_run()
	one.add_item(item)
	two.add_item(item)
	one.effects.dodge(Vector2.UP)
	one.effects.dodge(Vector2.UP)
	two.effects.dodge(Vector2.UP)
	assert_eq(one.effects.effect_of("shared").counts["dodge"], 2)
	assert_eq(two.effects.effect_of("shared").counts["dodge"], 1)
	assert_false(item.effect.counts.has("dodge"), "the shipped resource itself is never touched")


func test_hurt_chains_the_amounts_and_never_goes_below_zero() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var halver := _counting("h")
	halver.block_to = 1
	run.add_item(_item("h", halver))
	assert_eq(run.effects.hurt(3, RunEffects.HURT_ENEMY), 1)
	var blocker := _counting("z")
	blocker.block_to = 0
	run.add_item(_item("z", blocker))
	assert_eq(run.effects.hurt(3, RunEffects.HURT_ENEMY), 0)


func test_the_pills_lost_in_a_room_reach_its_clear() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.add_item(_item("c", _counting("c")))
	run.effects.room_enter(null)
	run.effects.hurt(1, RunEffects.HURT_ENEMY)
	run.effects.hurt(2, RunEffects.HURT_ENEMY)
	run.effects.room_clear(null)
	assert_eq(run.effects.effect_of("c").counts["damage_seen"], 3)
	run.effects.room_enter(null)
	assert_eq(run.effects.damage_this_room(), 0, "a new room starts again")


func test_lethal_is_saved_when_any_effect_says_so() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.add_item(_item("plain", _counting("p")))
	assert_false(run.effects.lethal())
	var saver := _counting("s")
	saver.saves = true
	run.add_item(_item("saver", saver))
	assert_true(run.effects.lethal())


func test_pickup_chains_amounts() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.add_item(_item("a", _counting("a")))
	run.add_item(_item("b", _counting("b")))
	assert_eq(run.effects.pickup(RunEffects.PENSION, 3), 12, "each counting effect doubles it")


func test_items_without_an_effect_add_nothing_to_the_list() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["golden_parachute"])
	assert_eq(run.effects.effect_of("golden_parachute"), null)
	assert_eq(run.effects.hurt(2, RunEffects.HURT_ENEMY), 2)


func test_clearing_items_clears_their_effects() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.add_item(_item("a", _counting("a")))
	run.clear_items()
	assert_eq(run.effects.effect_of("a"), null)


func test_land_fires_hit_and_kill_once_and_applies_hit_damage() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var effect := _counting("a")
	effect.bonus = 5.0
	run.add_item(_item("a", effect))
	var enemy := kit.enemy("intern_reaper", 20.0)
	assert_true(run.effects.land(enemy, 10.0, RunEffects.SWING))
	assert_near(enemy.hp, 5.0, "hit_damage added its bonus")
	var copy = run.effects.effect_of("a")
	assert_eq(copy.counts.get("hit", 0), 1)
	assert_eq(copy.counts.get("kill", 0), 0)
	assert_true(run.effects.land(enemy, 10.0, RunEffects.BITE))
	assert_eq(copy.counts.get("kill", 0), 1, "the hit that killed it")
	assert_eq(copy.counts["last_source"], RunEffects.BITE)
	assert_false(run.effects.land(enemy, 10.0, RunEffects.SWING), "a dead enemy takes no more hits")
	assert_eq(copy.counts.get("kill", 0), 1)
	kit.free_enemies()


func test_item_hits_from_hooks_stop_two_levels_deep() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var echo := GDScript.new()
	echo.source_code = "extends ItemEffect\nvar hits := 0\nfunc on_hit(ctx, enemy, amount, source):\n\thits += 1\n\tctx.hit_enemy(enemy, 1.0)\n"
	echo.reload()
	var effect: ItemEffect = echo.new()
	run.add_item(_item("echo", effect))
	var enemy := kit.enemy("intern_reaper", 1000.0)
	run.effects.land(enemy, 1.0, RunEffects.SWING)
	assert_eq(run.effects.effect_of("echo").hits, RunEffects.MAX_HIT_DEPTH, "each level fires once, then it stops")
	kit.free_enemies()


func test_play_calls_every_hook() -> void:
	var player := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	for call: String in ["effects.dodge(", "effects.dodge_end(", "effects.close_call(", "effects.hurt(",
			"effects.lethal(", "effects.throw(", "effects.charge_release(", "effects.tick(", "effects.land("]:
		assert_true(player.contains(call), "player.gd calls %s" % call)
	var room := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	for call: String in ["effects.room_clear(", "effects.pickup(", "effects.shop_open(", "effects.accepts_pickup(", "effects.bomb"]:
		assert_true(room.contains(call), "room_view.gd calls %s" % call)
	var scene := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	for call: String in ["effects.room_enter(", "effects.floor_start("]:
		assert_true(scene.contains(call), "floor_scene.gd calls %s" % call)
	var teeth := FileAccess.get_file_as_string("res://scripts/actors/thrown_dentures.gd")
	assert_true(teeth.contains("effects.land(") and teeth.contains("effects.bite("), "bites go through the hooks")
	var thermos := FileAccess.get_file_as_string("res://scripts/world/thermos.gd")
	assert_true(thermos.contains("effects.land("), "a Thermos's hits go through the hooks")


func _player(run: RunState) -> Player:
	var player := Player.new()
	player.setup(run)
	return player


func test_a_blocked_hit_keeps_his_pills_and_lands_nothing() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var blocker := _counting("b")
	blocker.block_to = 0
	run.add_item(_item("b", blocker))
	var player := _player(run)
	var pills := run.health.pills
	assert_false(player.take_hit(1))
	assert_eq(run.health.pills, pills)
	assert_true(run.health.is_invulnerable(), "a shrugged hit still keeps the next one off for a moment")
	player.free()


func test_a_saving_effect_leaves_him_one_pill() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var saver := _counting("s")
	saver.saves = true
	run.add_item(_item("s", saver))
	var player := _player(run)
	assert_true(player.take_hit(run.health.pills + 3))
	assert_eq(run.health.pills, 1)
	assert_false(run.health.is_dead())
	player.free()


func test_a_life_jacket_is_spent_before_an_item_is_asked() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["life_jacket"])
	var saver := _counting("s")
	saver.saves = true
	run.add_item(_item("s", saver))
	var player := _player(run)
	player.take_hit(99)
	assert_eq(run.effects.effect_of("s").counts.get("lethal", 0), 0)
	assert_eq(run.health.pills, 1)
	player.free()


func test_a_close_call_fires_once_per_dodge() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.add_item(_item("c", _counting("c")))
	var player := _player(run)
	player.start_dodge(Vector2.RIGHT)
	assert_false(player.take_hit(1), "a dodge still lets nothing land")
	player.take_hit(1)
	assert_eq(run.effects.effect_of("c").counts.get("close_call", 0), 1)
	assert_eq(run.effects.effect_of("c").counts.get("dodge", 0), 1)
	player.free()


func test_every_item_fx_is_cleared_with_a_rooms_passing_effects() -> void:
	var made: Array[Node2D] = [ItemFx.make_shockwave(40.0, Color.WHITE), ItemFx.make_cloud(20.0, 2.0),
		ItemFx.make_puddle(20.0, 3.0), ItemFx.make_sparks(Color.WHITE), ItemFx.make_pop("BINGO!"), ItemFx.make_blast(50.0)]
	for node in made:
		assert_true(node.is_in_group(ItemFx.GROUP), str(node))
		assert_true(RoomView.is_passing_effect(node), str(node))
		assert_eq(node.process_mode, Node.PROCESS_MODE_ALWAYS)
		node.free()


func test_an_fx_frees_itself_at_the_end_of_its_life() -> void:
	var cloud := ItemFx.make_cloud(20.0, 1.0)
	assert_near(cloud.life, 1.0)
	cloud.age = 0.5
	assert_near(cloud.progress(), 0.5)
	cloud.free()


func test_offscreen_arrows_stand_on_the_edge_toward_the_enemy() -> void:
	var view := Rect2(Vector2.ZERO, Vector2(640, 360))
	assert_eq(ItemFx.OffscreenArrows.edge_point(view, Vector2(300, 200)), Vector2.INF, "an enemy in view needs no arrow")
	var right := ItemFx.OffscreenArrows.edge_point(view, Vector2(1000, 192))
	assert_near(right.x, 640.0 - ItemFx.OffscreenArrows.MARGIN)
	var up := ItemFx.OffscreenArrows.edge_point(view, Vector2(325, -500))
	assert_true(up.y >= ItemFx.OffscreenArrows.TOP_ROW, "below the HUD's top row")
	assert_true(view.has_point(up))


func test_the_context_places_fx_and_frees_them_without_a_room() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var pop := ItemFx.make_pop("hi")
	assert_eq(run.effects.ctx.add_fx(pop, Vector2.ZERO), null)
	assert_eq(kit.fx.size(), 1, "the listener still saw it")
