extends TestCase

# One test per rule of the hundred items' fourth and last batch: the last five vision items, the rooms,
# kills and pace group, the boss items and the silly ones, and the combos they make possible (Early
# Riser, Paper Trail and Family Visit). It also holds the totals of all hundred.

const Mothball := preload("res://scripts/items/mothball_pockets.gd")
const Fortune := preload("res://scripts/items/fortune_card.gd")
const Obituary := preload("res://scripts/items/obituary_clippings.gd")
const Grief := preload("res://scripts/items/grief_counselor.gd")
const EarlyBird := preload("res://scripts/items/early_bird_special.gd")
const Alarm := preload("res://scripts/items/alarm_clock.gd")
const Wreath := preload("res://scripts/items/wreath_of_thorns.gd")
const HallPass := preload("res://scripts/items/bingo_hall_pass.gd")
const Complaint := preload("res://scripts/items/complaint_form.gd")
const Stamp := preload("res://scripts/items/bureaucrats_stamp.gd")
const Glass := preload("res://scripts/items/dentures_in_glass.gd")
const Suit := preload("res://scripts/items/polyester_suit.gd")

# id: [rarity, source, first-clear path or "", cursed]
const BATCH := {
	"mothball_pockets": [ItemDef.RARE, ItemUnlocks.FIRST_CLEAR, "cemetery", false],
	"telescope_cane": [ItemDef.COMMON, ItemUnlocks.START, "", false],
	"fortune_card": [ItemDef.RARE, ItemUnlocks.BOUNTY, "", false],
	"grief_counselor": [ItemDef.RARE, ItemUnlocks.FIRST_CLEAR, "funeral_parlour", false],
	"wreath_of_thorns": [ItemDef.RARE, ItemUnlocks.FIRST_CLEAR, "cemetery", false],
	"bingo_hall_pass": [ItemDef.RARE, ItemUnlocks.FIRST_CLEAR, "floor_1", false],
	"moving_boxes": [ItemDef.COMMON, ItemUnlocks.START, "", false],
	"lawyers_card": [ItemDef.RARE, ItemUnlocks.BOUNTY, "", false],
}
# The posters that pay this batch's bounty items, and the looks they paid before, now sold.
const POSTERS := {
	"doreen": ["bureaucrats_stamp", "power_tie"],
	"sergeant_wanda": ["complaint_form", "aviator_sunglasses"],
	"celestine": ["lawyers_card", "golf_visor"],
	"crabtree": ["fortune_card", "fountain_tiara"],
}
const PATHS := ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "flashback_cinema", "last_resort_cruise", "seance_hotline", "terminal_zero", "head_office"]


func _with_combos(kit: ItemKit, ids: Array) -> RunState:
	var run := kit.make_run()
	run.effects.set_combos(Content.combos())
	for id: String in ids:
		run.add_item(ItemKit.item(id))
	return run


func _player(run: RunState) -> Player:
	var player := Player.new()
	player.setup(run)
	return player


# A stand-in room for effects that ask the room for something: it answers with what the test set.
func _fake_room(source: String) -> Node2D:
	var script := GDScript.new()
	script.source_code = "extends Node2D\n" + source
	script.reload()
	var room := Node2D.new()
	room.set_script(script)
	return room


func _boss(kit: ItemKit, hp := 1000.0) -> Enemy:
	var boss := kit.enemy("regional_reaper")
	boss.hp = hp
	return boss


# --- the batch and the hundred ---

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
		assert_eq(item.cursed, BATCH[id][3], id)
		assert_false(item.tags.is_empty(), id)
		for tag in item.tags:
			assert_true(ItemDef.TAGS.has(tag), "%s's tag %s" % [id, tag])


func test_every_batch_text_is_two_sentences_and_has_a_coach_tip() -> void:
	for id: String in BATCH:
		var item := ItemKit.item(id)
		assert_true(item.description.count(". ") >= 1 and item.description[-1] in [".", "?", "!"], id)
		assert_true(CoachTips.TIPS.has(id), "%s has a tip" % id)
		if item.cursed:
			assert_true(item.description.contains("but"), "%s says its drawback" % id)


# --- vision ---

func test_magnifying_glass_marks_every_secret_wall_with_a_glint() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["magnifying_glass"])
	var walls: Array = [Node2D.new(), Node2D.new()]
	var room := _fake_room("var walls := []\nfunc secret_walls() -> Array:\n\treturn walls\n")
	room.set("walls", walls)
	run.effects.room_enter(room)
	assert_eq(kit.fx_of(ItemFx.FxGlint).size(), 2)
	run.effects.room_enter(null)
	assert_eq(kit.fx_of(ItemFx.FxGlint).size(), 2, "no room, no walls")
	var glint := ItemFx.make_glint(null)
	glint.age = 0.15
	assert_true(glint.flare() > 0.5, "it flares")
	glint.age = ItemFx.FxGlint.PERIOD * 0.7
	assert_near(glint.flare(), 0.0, "then rests until the next")
	glint.free()
	for wall in walls:
		wall.free()
	room.free()
	var source := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	assert_true(source.contains("func secret_walls() -> Array[SecretWall]:"))


func _floor_map() -> FloorMap:
	var def: FloorDef = load("res://data/floors/floor_1.tres")
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	return FloorBuilder.build_from_pool(rng, def, RoomCatalog.load_valid(def.rooms_dir))


func test_floor_plan_shows_every_room_but_the_hidden_ones_and_not_what_is_in_them() -> void:
	assert_true(ItemKit.new().run_with(["floor_plan"]).stats.shows_floor_plan)
	var map := _floor_map()
	var progress := FloorProgress.new(map)
	progress.enter(map.start_id)
	assert_eq(FloorMapView.shown_ids(map, progress, false).size(), 1, "without it, only where he has been")
	var shown := FloorMapView.shown_ids(map, progress, false, true)
	var hidden := 0
	for room in map.rooms:
		if FloorMapView.HIDDEN_TYPES.has(room.room_type):
			hidden += 1
			assert_false(shown.has(room.id), "a %s room stays hidden" % room.room_type)
	assert_eq(shown.size(), map.rooms.size() - hidden)
	var start := map.room(map.start_id)
	for side: Vector2i in start.doors:
		var other := map.room(start.doors[side])
		assert_eq(FloorMapView.link_shown(start, other, progress, true), not FloorMapView.HIDDEN_TYPES.has(other.room_type))
		assert_false(FloorMapView.link_shown(start, other, progress, false), "no plan, no link to a room not walked into")
	# A room it shows that he never saw a door to is an outline only: neither map draws its sign or dot.
	var told := 0
	for room in map.rooms:
		if shown.has(room.id) and not progress.is_visited(room.id) and not FloorMapView.sign_seen(map, progress, room):
			assert_eq(FloorMapView.drawn_sign(map, progress, room, false), "", "room %d says nothing of what it holds" % room.id)
			told += 1
	assert_true(told > 0, "rooms he never saw a door to were checked")


func test_fortune_teller_names_the_bosses_and_slows_each_ones_first_attack_once() -> void:
	var def: FloorDef = load("res://data/floors/floor_1.tres")
	var names := FloorMapView.boss_names_for(def)
	assert_eq(names[RoomLayout.TYPE_FLOOR_BOSS], def.floor_boss.display_name)
	assert_eq(names[RoomLayout.TYPE_MINI_BOSS], def.mini_boss.display_name)
	var map := _floor_map()
	var progress := FloorProgress.new(map)
	progress.enter(map.start_id)
	var shown := FloorMapView.shown_ids(map, progress, false, false, true)
	for room in map.rooms:
		if room.room_type == RoomLayout.TYPE_FLOOR_BOSS:
			assert_true(shown.has(room.id), "the boss room shows before it is found")
	var kit := ItemKit.new()
	var run := kit.run_with(["fortune_card"])
	assert_true(run.stats.names_bosses)
	var boss := _boss(kit)
	run.effects.tick(0.1)
	assert_eq(kit.slows.size(), 0, "nothing before he winds up")
	var windup := Telegraph.new()
	windup.start(0.8)
	boss.set_warning(windup, 30.0)
	run.effects.tick(0.1)
	run.effects.tick(0.1)
	assert_eq(kit.slows.size(), 1, "once per boss")
	assert_near(kit.slows[0][0], Fortune.SLOW_SHARE)
	var grunt := kit.enemy("intern_reaper")
	grunt.set_warning(windup, 20.0)
	run.effects.tick(0.1)
	assert_eq(kit.slows.size(), 1, "only bosses")
	var loop_kit := ItemKit.new()
	var loop := loop_kit.run_with(["fortune_card"])
	loop.effects.ctx.counting_exact = true
	var other := _boss(loop_kit)
	other.set_warning(windup, 30.0)
	loop.effects.tick(0.1)
	assert_eq(loop_kit.slows.size(), 0, "the loop times warnings as they are")
	kit.free_enemies()
	loop_kit.free_enemies()
	var scene := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	assert_true(scene.contains("view.boss_names = names"), "the maps learn the names")


func test_mothball_pockets_push_ghosts_off_for_two_seconds_after_a_hit() -> void:
	for id: String in ["soot_ghost", "seance_soot_ghost", "poltergeist", "debt_ghost", "weeping_mourner", "airport_weeping_mourner"]:
		assert_true(Mothball.is_ghost(load("res://data/enemies/%s.tres" % id)), id)
	for id: String in ["intern_reaper", "orderly", "regional_reaper"]:
		assert_false(Mothball.is_ghost(load("res://data/enemies/%s.tres" % id)), id)
	var kit := ItemKit.new()
	var run := kit.run_with(["mothball_pockets"])
	var ghost := kit.enemy("weeping_mourner")
	ghost.position = Vector2(30, 0)
	var grunt := kit.enemy("intern_reaper")
	grunt.position = Vector2(-30, 0)
	run.effects.tick(0.1)
	assert_false(ghost.is_pushed(), "nothing before a hit")
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1, "it blocks nothing")
	run.effects.tick(0.1)
	assert_true(ghost.is_pushed())
	assert_false(grunt.is_pushed(), "only ghosts")
	assert_eq(kit.fx_of(ItemFx.FxCloud).size(), 1)
	run.effects.tick(Mothball.KEEP_TIME)
	var late := kit.enemy("soot_ghost")
	late.position = Vector2(0, 30)
	run.effects.tick(0.1)
	assert_false(late.is_pushed(), "two seconds, then they may come")
	kit.free_enemies()


func test_telescope_cane_moves_the_camera_ahead_and_keeps_him_on_screen() -> void:
	var run := ItemKit.new().run_with(["telescope_cane"])
	assert_near(run.stats.look_ahead, 40.0)
	var player := _player(run)
	player.global_position = Vector2(400, 300)
	var feet := player.global_position + Player.FEET_OFFSET
	assert_eq(player.camera_focus(), feet, "it eases over, never jumps")
	player.ease_look_ahead(10.0)
	assert_true(player.camera_focus().distance_to(feet + Vector2(40, 0)) < 0.5, "ahead the way he aims")
	var plain := _player(ItemKit.new().make_run())
	plain.global_position = Vector2(400, 300)
	plain.ease_look_ahead(10.0)
	assert_eq(plain.camera_focus(), plain.global_position + Player.FEET_OFFSET)
	# Whatever the look ahead, the camera's own rule keeps him well inside the view.
	var room := Vector2(30, 20) * RoomBackdrop.TILE
	for way: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		var focus := feet + way * PlayerStats.MAX_LOOK_AHEAD
		var view := BossMoves.view_rect(room, focus)
		assert_true(view.grow(-32.0).has_point(feet), "he stays on screen looking %s" % way)
	player.free()
	plain.free()
	var enemy := FileAccess.get_file_as_string("res://scripts/actors/enemy.gd")
	assert_true(enemy.contains("target.camera_focus() if target.has_method(\"camera_focus\")"), "on screen is what the camera shows")
	for scene: String in ["floor_scene", "waiting_room"]:
		var text := FileAccess.get_file_as_string("res://scripts/scenes/%s.gd" % scene)
		assert_true(text.contains("RoomCamera.center_for(room_size, player.camera_focus(), RoomBackdrop.VIEW_SIZE, Hud.BAND_BOTTOM)"), scene)


# --- rooms, kills and pace ---

func test_grief_counselor_pays_for_a_room_cleared_without_a_scratch() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["grief_counselor"])
	run.effects.room_enter(null)
	run.effects.room_clear(null)
	assert_eq(kit.paid, Grief.PAY)
	run.effects.room_enter(null)
	run.effects.hurt(1, RunEffects.HURT_ENEMY)
	run.effects.room_clear(null)
	assert_eq(kit.paid, Grief.PAY, "a pill lost there, nothing paid")

func test_wreath_of_thorns_pricks_what_touches_him_now_and_then() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["wreath_of_thorns"])
	var wreath = run.effects.effect_of("wreath_of_thorns")
	var near := kit.enemy("intern_reaper", 100.0)
	near.position = Vector2(14, 0)
	var far := kit.enemy("intern_reaper", 100.0)
	far.position = Vector2(120, 0)
	var body := Rect2(-Wreath.BODY / 2.0, Wreath.BODY)
	assert_eq(wreath.prick(run.effects.ctx, body), 1)
	assert_near(near.hp, 100.0 - Wreath.DAMAGE)
	assert_near(far.hp, 100.0)
	assert_eq(wreath.prick(run.effects.ctx, body), 0, "not every frame")
	run.effects.tick(Wreath.AGAIN_AFTER + 0.01)
	assert_eq(wreath.prick(run.effects.ctx, body), 1)
	kit.free_enemies()


func test_bingo_hall_pass_weakens_the_room_after_every_three_clears() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["bingo_hall_pass"])
	for i in 2:
		run.effects.room_clear(null)
	var early := kit.enemy("intern_reaper", 100.0)
	run.effects.room_enter(null)
	assert_near(early.hp, 100.0, "two clears are not enough")
	run.effects.room_clear(null)
	kit.free_enemies()
	run.effects.room_enter(null)
	assert_true(run.effects.effect_of("bingo_hall_pass").has_pass(), "an empty room keeps the pass")
	var enemy := kit.enemy("intern_reaper", 100.0)
	run.effects.room_enter(null)
	assert_near(enemy.hp, 100.0 * (1.0 - HallPass.CUT))
	assert_false(run.effects.effect_of("bingo_hall_pass").has_pass(), "spent")
	assert_eq(kit.fx_of(ItemFx.FxPop).size(), 1)
	kit.free_enemies()


func test_moving_boxes_carry_the_cheapest_pickup_left_into_the_next_room() -> void:
	var slip := Pickup.new()
	slip.carry_kind = RoomRules.DROP_KEY
	var heal := Pickup.new()
	heal.carry_kind = RoomRules.DROP_HEAL
	heal.carry_amount = 2
	var coin := Pickup.new()
	assert_eq(RoomView.cheapest_waiting([slip, heal, coin]), heal)
	heal._done = true
	assert_eq(RoomView.cheapest_waiting([slip, heal, coin]), slip, "a taken one is not left")
	assert_eq(RoomView.cheapest_waiting([coin]), null, "coins, items and wares stay")
	for pickup in [slip, heal, coin]:
		pickup.free()
	var kit := ItemKit.new()
	var run := kit.run_with(["moving_boxes"])
	var room := _fake_room("func take_leftover() -> Dictionary:\n\treturn {\"kind\": \"heal\", \"amount\": 2}\n")
	run.effects.room_leave(room)
	run.effects.room_enter(null)
	assert_eq(kit.drops.size(), 1)
	assert_eq(kit.drops[0][0], RoomRules.DROP_HEAL)
	run.effects.room_enter(null)
	assert_eq(kit.drops.size(), 1, "one box, set down once")
	run.effects.ctx.counting_pills = true
	run.effects.room_leave(room)
	run.effects.room_enter(null)
	assert_eq(kit.drops.size(), 1, "the loop counts every pickup where it lies")
	room.free()
	var scene := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	assert_true(scene.contains("_run.effects.room_leave(_room_view)\n\t\t_room_view.clear_passing_effects()") or scene.contains("_run.effects.room_leave(_room_view)\r\n\t\t_room_view.clear_passing_effects()"), "it takes from the room before the room is put away")


func test_last_orders_doubles_the_last_enemy_but_never_a_boss() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["last_orders"])
	var first := kit.enemy("intern_reaper", 100.0)
	var second := kit.enemy("intern_reaper", 100.0)
	assert_near(run.effects.hit_damage(first, 10.0, RunEffects.SWING), 10.0)
	second.take_damage(999.0, Vector2.ZERO)
	assert_near(run.effects.hit_damage(first, 10.0, RunEffects.SWING), 20.0, "last orders")
	kit.free_enemies()
	var boss := _boss(kit)
	assert_near(run.effects.hit_damage(boss, 10.0, RunEffects.SWING), 10.0, "a boss alone is still a boss")
	kit.free_enemies()


# --- bosses ---

func test_photo_of_the_grandkids_doubles_his_damage_on_his_last_pill() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["photo_of_grandkids"])
	var enemy := kit.enemy("intern_reaper", 100.0)
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 10.0)
	run.health.pills = 1
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 20.0)
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.BITE), 20.0, "every hit of his")
	assert_eq(kit.fx_of(ItemFx.FxPop).size(), 1, "one x2 at a time")
	run.effects.ctx.counting_exact = true
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 10.0, "the loop measures plain damage")
	kit.free_enemies()


func test_complaint_form_stuns_a_boss_when_full_and_never_twice_in_a_row() -> void:
	assert_near(Complaint.fill_of(100.0, 1000.0), 0.5)
	assert_near(Complaint.fill_of(900.0, 1000.0), 1.0)
	var kit := ItemKit.new()
	var run := kit.run_with(["complaint_form"])
	var form = run.effects.effect_of("complaint_form")
	var boss := _boss(kit, 0.0)
	boss.hp = boss.max_hp()
	var full := boss.max_hp() * Complaint.FILL_SHARE
	run.effects.hit(boss, full * 0.75, RunEffects.SWING)
	assert_false(boss.is_stunned(), "three quarters full")
	assert_eq(kit.fx_of(ItemFx.FxMeter).size(), 1, "its form shows over the boss")
	run.effects.hit(boss, full * 0.3, RunEffects.SWING)
	assert_true(boss.is_stunned(), "full: two seconds")
	assert_eq(kit.fx_of(ItemFx.FxStamp).size(), 1)
	run.effects.tick(Complaint.STUN + 0.1)
	boss._stun_left = 0.0
	run.effects.hit(boss, full * 5.0, RunEffects.SWING)
	assert_false(boss.is_stunned(), "it rests after a stun, so it can never chain")
	assert_true(form.is_resting(boss))
	run.effects.tick(Complaint.REST)
	assert_false(form.is_resting(boss))
	run.effects.hit(boss, full * 0.75, RunEffects.SWING)
	assert_false(boss.is_stunned(), "and starts again from empty")
	var grunt := kit.enemy("intern_reaper", 9999.0)
	run.effects.hit(grunt, 9999.0, RunEffects.SWING)
	assert_false(grunt.is_stunned(), "only bosses")
	kit.free_enemies()


func test_bureaucrats_stamp_files_an_enemy_for_good_every_thirty_seconds() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["bureaucrats_stamp", "casserole_dish"])
	var stamp = run.effects.effect_of("bureaucrats_stamp")
	run.health.pills = 2
	var enemy := kit.enemy("intern_reaper", 500.0)
	var paid_before := enemy.coin_value()
	var fell := []
	enemy.defeated.connect(func(e): fell.append(e))
	assert_true(run.effects.land(enemy, 10.0, RunEffects.SWING))
	assert_true(enemy.is_dead(), "filed")
	assert_eq(fell.size(), 1, "the room hears it fall, so it still clears")
	assert_eq(enemy.coin_value(), paid_before, "it pays what it pays, nothing more")
	assert_eq(run.health.half_pills, 1, "it counts as a kill")
	assert_eq(kit.fx_of(ItemFx.FxStamp).size(), 1)
	var next := kit.enemy("intern_reaper", 500.0)
	run.effects.land(next, 10.0, RunEffects.SWING)
	assert_false(next.is_dead(), "spent until it recharges")
	run.effects.tick(Stamp.RECHARGE + 0.1)
	assert_true(stamp.ready)
	run.effects.land(next, 10.0, RunEffects.ITEM)
	assert_false(next.is_dead(), "item hits never set it off")
	run.effects.ctx.counting_exact = true
	run.effects.land(next, 10.0, RunEffects.SWING)
	assert_false(next.is_dead(), "the loop counts its enemies")
	kit.free_enemies()

func test_lawyers_card_blocks_a_bosss_first_hit_in_each_phase() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["lawyers_card"])
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1, "no boss, no lawyer")
	var boss := _boss(kit, 0.0)
	boss.hp = boss.max_hp()
	assert_eq(run.effects.hurt(2, RunEffects.HURT_ENEMY), 0, "the first hit of the first phase")
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1)
	boss.hp = boss.max_hp() * 0.4
	assert_eq(run.effects.hurt(1, RunEffects.HURT_BLAST), 0, "the first of the second")
	assert_eq(run.effects.hurt(1, RunEffects.HURT_BLAST), 1)
	run.effects.ctx.counting_pills = true
	boss.hp = boss.max_hp()
	kit.free_enemies()
	var fresh := _boss(kit, 0.0)
	fresh.hp = fresh.max_hp()
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1, "the loop counts every pill")
	kit.free_enemies()


# --- the silly ones ---
