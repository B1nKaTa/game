extends TestCase

# Contact damage: walking into an enemy's body costs a pill and shoves him out, with its exceptions, and
# how the items that hear what hurt him take a touch.

const Mothball := preload("res://scripts/items/mothball_pockets.gd")
const Wreath := preload("res://scripts/items/wreath_of_thorns.gd")
const GHOSTS := ["soot_ghost", "golf_soot_ghost", "debt_ghost", "weeping_mourner", "airport_weeping_mourner"]


func _def(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


func _player(run: RunState) -> Player:
	var player := Player.new()
	player.setup(run)
	return player


# --- the rule ---

func test_every_body_costs_one_pill_by_default_bosses_too() -> void:
	assert_eq(EnemyDef.new().contact_damage, 1)
	assert_eq(ContactRule.damage_of(_def("intern_reaper")), 1)
	assert_eq(ContactRule.damage_of(_def("regional_reaper")), 1, "a boss costs one")
	assert_eq(ContactRule.damage_of(_def("mortimer_grimsby")), 1)
	assert_eq(ContactRule.damage_of(null), 0)


func test_every_shipped_enemy_costs_at_most_one_to_touch() -> void:
	for file in DirAccess.get_files_at("res://data/enemies/"):
		if not file.ends_with(".tres"):
			continue
		var def: EnemyDef = load("res://data/enemies/" + file)
		assert_true(ContactRule.damage_of(def) <= 1, def.id)


func test_ghosts_pass_through_him_unless_a_def_opts_in() -> void:
	for id: String in GHOSTS:
		assert_true(ContactRule.is_ghost(_def(id)), id)
		assert_eq(ContactRule.damage_of(_def(id)), 0, id)
	var haunting: EnemyDef = _def("debt_ghost").duplicate()
	haunting.ghost_contact = true
	assert_eq(ContactRule.damage_of(haunting), 1, "a ghost that opts in hurts")
	assert_false(ContactRule.is_ghost(_def("regional_reaper")), "bosses never count as ghosts")
	for id: String in GHOSTS:
		assert_eq(Mothball.is_ghost(_def(id)), ContactRule.is_ghost(_def(id)), "the mothballs keep off the same ghosts")


func test_a_def_can_opt_out_and_the_dummy_and_walkers_do() -> void:
	var soft: EnemyDef = _def("intern_reaper").duplicate()
	soft.contact_damage = 0
	assert_eq(ContactRule.damage_of(soft), 0)
	assert_eq(ContactRule.damage_of(_def("training_dummy")), 0, "the Training Yard dummy")
	assert_eq(ContactRule.damage_of(_def("mall_walker")), 0, "the Mall Walkers hurt on touch by their own clock")
	var walker := FileAccess.get_file_as_string("res://scripts/actors/behaviors/mall_walker_behavior.gd")
	assert_true(walker.contains("if _contact.touch(delta,"), "and that clock still runs")


func test_its_moment_can_make_a_body_harmless() -> void:
	var def := _def("intern_reaper")
	assert_eq(ContactRule.damage(def, false, false, false, false), 1)
	assert_eq(ContactRule.damage(def, true, false, false, false), 0, "dead, dying or dismissed")
	assert_eq(ContactRule.damage(def, false, true, false, false), 0, "still waiting out the room's start")
	assert_eq(ContactRule.damage(def, false, false, true, false), 0, "underground or in smoke")
	assert_eq(ContactRule.damage(def, false, false, false, true), 0, "an ambusher asleep")


func test_an_enemy_reads_its_own_moment() -> void:
	var enemy := Enemy.new()
	enemy.setup(_def("intern_reaper"), null, 0.5)
	assert_eq(enemy.contact_damage(), 1)
	enemy.wait_for_room_start()
	assert_eq(enemy.contact_damage(), 0, "a room's enemies, and a mimic just out of its chest, wait first")
	enemy._wake_left = 0.0
	enemy.set_submerged(true)
	assert_eq(enemy.contact_damage(), 0, "a mound underground")
	enemy.set_submerged(false)
	enemy.dismiss()
	assert_eq(enemy.contact_damage(), 0, "dismissed")
	enemy.free()
	var dying := Enemy.new()
	dying.setup(_def("intern_reaper"), null, 0.5)
	dying.take_damage(INF, Vector2.ZERO)
	assert_eq(dying.contact_damage(), 0, "dead")
	dying.free()
	var boss := Enemy.new()
	boss.setup(_def("regional_reaper"), null, 0.5)
	assert_eq(boss.contact_damage(), 1, "a boss")
	boss.free()


func test_sleeping_ambushers_are_harmless_until_they_wake() -> void:
	var sunbather := Enemy.new()
	sunbather.setup(_def("sunburnt_sunbather"), null, 0.5)
	assert_eq(sunbather.contact_damage(), 0, "the Sunbather in his chair")
	sunbather._behavior._state = SunbatherBehavior.State.AWAKE
	assert_eq(sunbather.contact_damage(), 1, "awake, he hurts")
	sunbather.free()
	var luggage := Enemy.new()
	luggage.setup(_def("lost_luggage"), null, 0.5)
	assert_eq(luggage.contact_damage(), 0, "Lost Luggage lying on the carpet")
	luggage._behavior._state = LostLuggageBehavior.State.AWAKE
	assert_eq(luggage.contact_damage(), 1)
	luggage.free()
	var mimic := Enemy.new()
	mimic.setup(_def("mimic"), null, 0.5)
	assert_eq(mimic.contact_damage(), 1, "a woken mimic hurts once its wait is over")
	mimic.free()
	var room := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	assert_true(room.contains("mimic.wait_for_room_start()"), "and a mimic waits as it wakes")


func test_npcs_and_summon_marks_are_no_enemies() -> void:
	for path: String in ["res://scripts/world/npc.gd", "res://scripts/world/summon_mark.gd"]:
		var source := FileAccess.get_file_as_string(path)
		assert_false(source.contains("\"enemies\""), path)
		assert_false(source.contains("extends Enemy"), path)


func test_a_touch_is_his_feet_box_against_the_drawn_body() -> void:
	var body := Rect2(Vector2(-10, -12), Vector2(20, 24))
	var size := Player.FEET_BOX_SIZE
	assert_true(ContactRule.touches(body, ContactRule.feet_box(Vector2(0, 0), size)))
	assert_true(ContactRule.touches(body, ContactRule.feet_box(Vector2(16, 0), size)), "the drawn body, wider than its collision box")
	assert_false(ContactRule.touches(body, ContactRule.feet_box(Vector2(18, 0), size)))
	assert_false(ContactRule.touches(body, ContactRule.feet_box(Vector2(0, 19), size)))


func test_the_shove_carries_him_out_of_any_body() -> void:
	var shove := ContactRule.shove(Vector2.ZERO, Vector2(4, 0), Vector2.RIGHT)
	assert_true(shove.normalized().is_equal_approx(Vector2.RIGHT), "straight away from its middle")
	assert_true(ContactRule.shove(Vector2.ZERO, Vector2.ZERO, Vector2.RIGHT).normalized().is_equal_approx(Vector2.LEFT), "right on it, back the way he faces")
	var reach := ContactRule.SHOVE * ContactRule.SHOVE_TIME
	var biggest := 0.0
	for file in DirAccess.get_files_at("res://data/enemies/"):
		if file.ends_with(".tres"):
			var def: EnemyDef = load("res://data/enemies/" + file)
			if not def.is_boss and ContactRule.damage_of(def) > 0:
				biggest = maxf(biggest, maxf(def.body_size.x, def.body_size.y))
	assert_true(reach >= biggest / 2.0 + Player.FEET_BOX_SIZE.x / 2.0 - 2.0, "from its middle he clears any enemy's edge, %.0f px against %.0f" % [reach, biggest])
	assert_true(reach <= 40.0, "but only a small shove")


# --- Grandpa ---

func test_a_touch_goes_through_take_hit_as_a_contact_hit() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var player := _player(run)
	var pills := run.health.pills
	assert_true(player.take_hit(1, RunEffects.HURT_CONTACT))
	assert_eq(run.health.pills, pills - 1)
	assert_false(player.take_hit(1, RunEffects.HURT_CONTACT), "the grace after a hit holds")
	assert_eq(run.health.pills, pills - 1, "one touch never costs several pills")
	player.free()


func test_player_touches_bodies_each_frame_and_a_dodge_passes_through() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	assert_true(source.contains("\t_handle_movement()\n\ttouch_bodies()") or source.contains("\t_handle_movement()\r\n\ttouch_bodies()"), "after he moves, every frame")
	assert_true(source.contains("if _dodge.is_active() or run.health.is_dead() or run.health.is_invulnerable():"), "a dodge passes through, and no close call is spent on a body")
	assert_true(source.contains("take_hit(cost, RunEffects.HURT_CONTACT)"))
	assert_true(source.contains("push(ContactRule.shove("), "the shove goes through push, so the Boots and the anchor hold")
	assert_true(source.contains("run.effects.ctx.contact_off"), "the full loop's switch")
	assert_eq((1 | Hole.LAYER | QueueBarrier.LAYER) & 4, 0, "enemies stay off his mask, so bodies never box him in")
	assert_true(source.contains("collision_mask = 1 | Hole.LAYER | QueueBarrier.LAYER"))


func test_the_shove_follows_the_push_rules() -> void:
	var run := ItemKit.new().make_run()
	var player := _player(run)
	player.push(ContactRule.shove(Vector2.ZERO, Vector2(3, 0), Vector2.RIGHT), ContactRule.SHOVE_TIME)
	assert_true(player.is_pushed())
	assert_near(player._push.x, ContactRule.SHOVE)
	player.end_push()
	run.stats.steady_feet = true
	player.push(ContactRule.shove(Vector2.ZERO, Vector2(3, 0), Vector2.RIGHT), ContactRule.SHOVE_TIME)
	assert_false(player.is_pushed(), "Gravity Boots: nothing shoves him, a body's shove neither")
	player.free()


# --- the items that hear what hurt him ---

func test_life_alert_button_blocks_a_touch_as_any_first_hit() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["life_alert_button"])
	run.effects.room_enter(null)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_CONTACT), 0)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_CONTACT), 1, "only the first")
	var player := _player(run)
	run.effects.room_enter(null)
	var pills := run.health.pills
	assert_false(player.take_hit(1, RunEffects.HURT_CONTACT))
	assert_eq(run.health.pills, pills)
	assert_true(run.health.is_invulnerable(), "the blocked touch still gives him his grace, and so its shove")
	player.free()


func test_lawyers_card_blocks_a_bosss_first_touch_in_each_phase() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["lawyers_card"])
	assert_eq(run.effects.hurt(1, RunEffects.HURT_CONTACT), 1, "no boss, no lawyer")
	var boss := kit.enemy("regional_reaper")
	assert_eq(run.effects.hurt(1, RunEffects.HURT_CONTACT), 0, "walking into the boss is the phase's first hit")
	assert_eq(run.effects.hurt(1, RunEffects.HURT_CONTACT), 1)
	boss.hp = boss.max_hp() * 0.4
	assert_eq(run.effects.hurt(1, RunEffects.HURT_CONTACT), 0, "and the second phase's")
	kit.free_enemies()


func test_bubble_wrap_keeps_its_pop_for_a_shot() -> void:
	var run := ItemKit.new().run_with(["bubble_wrap"])
	run.effects.floor_start()
	assert_eq(run.effects.hurt(1, RunEffects.HURT_CONTACT), 1, "a body is no shot")
	assert_eq(run.effects.hurt(1, RunEffects.HURT_PROJECTILE), 0, "still wrapped for the first shot")


func test_thick_skull_leaves_a_touch_alone() -> void:
	var run := ItemKit.new().run_with(["thick_skull"])
	assert_eq(run.effects.hurt(1, RunEffects.HURT_CONTACT), 1)
	assert_eq(run.effects.hurt(2, RunEffects.HURT_CONTACT), 2, "blasts only")


func test_mothball_pockets_air_out_after_a_touch() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["mothball_pockets"])
	var ghost := kit.enemy("soot_ghost")
	ghost.position = Vector2(30, 0)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_CONTACT), 1, "it blocks nothing")
	run.effects.tick(0.1)
	assert_true(ghost.is_pushed(), "a touch that costs a pill sets them off as any hit")
	kit.free_enemies()


func test_wreath_of_thorns_pricks_whatever_costs_him_a_touch() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["wreath_of_thorns"])
	var wreath = run.effects.effect_of("wreath_of_thorns")
	var center := Vector2(200, 200)
	var feet := center + Player.FEET_OFFSET
	var box := ContactRule.feet_box(feet, Player.FEET_BOX_SIZE)
	var reach := Wreath.body_of(center, feet)
	assert_true(reach.encloses(box), "his feet box is body to the thorns")
	# Every spot round his feet where a body touches them.
	for offset: Vector2 in [Vector2(0, 17), Vector2(16, 0), Vector2(-16, 6), Vector2(0, -20), Vector2(14, 16)]:
		var enemy := kit.enemy("intern_reaper", 100.0)
		enemy.position = feet + offset
		if not ContactRule.touches(enemy.body_rect(), box):
			kit.free_enemies()
			continue
		assert_eq(wreath.prick(run.effects.ctx, reach), 1, "a body touching his feet at %s is pricked" % str(offset))
		kit.free_enemies()
	var source := FileAccess.get_file_as_string("res://scripts/items/wreath_of_thorns.gd")
	assert_true(source.contains("prick(ctx, body_of(ctx.player.global_position, ctx.feet()))"))


func test_the_full_loop_sets_bodies_aside_but_checks_a_touch() -> void:
	var driver := FileAccess.get_file_as_string("res://tools/smoke_driver.gd")
	assert_true(driver.contains("run.effects.ctx.contact_off = not _contact_check"))
	assert_true(driver.contains("await _check_contact(scene)"))
	var ctx := EffectContext.new()
	assert_false(ctx.contact_off, "bodies hurt in play")
