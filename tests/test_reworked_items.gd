extends TestCase

# One test per rule of the twenty items reworked by the hundred-items design. Every id is the one old
# saves, recipes and posters already know.

const NaughtyList := preload("res://scripts/items/naughty_list.gd")
const Nitro := preload("res://scripts/items/nitro_tablets.gd")
const TitaniumHip := preload("res://scripts/items/titanium_hip.gd")
const IDS := ["alert_bracelet", "bifocals", "bingo_card", "comfort_care_lanyard", "dentures", "golden_parachute",
	"hearing_aid", "life_jacket", "lucky_tee", "naughty_list", "neck_pillow", "nitro_tablets", "pill_organizer",
	"pocket_watch", "prune_juice", "slippers", "support_stockings", "titanium_hip", "undertakers_gloves"]


func _room_view(room_type: String) -> RoomView:
	var room := FloorRoom.new()
	room.room_type = room_type
	var view := RoomView.new()
	view.setup(room, null, null, null, null, null, null, null)
	return view


func test_every_old_item_id_still_ships() -> void:
	var shipped := {}
	for item in Content.items():
		shipped[item.id] = item
	for id: String in IDS:
		assert_true(shipped.has(id), id)
	assert_true(shipped.size() >= IDS.size())


func test_rarity_curses_and_sources_follow_the_design() -> void:
	var rare := ["alert_bracelet", "bifocals", "comfort_care_lanyard", "dentures", "golden_parachute", "life_jacket",
		"naughty_list", "nitro_tablets", "pocket_watch", "titanium_hip"]
	var recipes := ["alert_bracelet", "bifocals", "golden_parachute", "lucky_tee", "nitro_tablets", "support_stockings", "titanium_hip"]
	var bounties := ["comfort_care_lanyard", "life_jacket", "naughty_list", "neck_pillow", "pocket_watch", "undertakers_gloves"]
	for id: String in IDS:
		var item := ItemKit.item(id)
		assert_eq(item.rarity, ItemDef.RARE if rare.has(id) else ItemDef.COMMON, id)
		assert_eq(item.cursed, id == "nitro_tablets" or id == "prune_juice", id)
		var source := ItemUnlocks.START
		if recipes.has(id):
			source = ItemUnlocks.RECIPE
		elif bounties.has(id):
			source = ItemUnlocks.BOUNTY
		assert_eq(ItemUnlocks.source_of(item), source, id)


func test_every_text_is_two_sentences_and_cursed_ones_name_their_drawback() -> void:
	for id: String in IDS:
		var item := ItemKit.item(id)
		assert_true(item.description.count(". ") >= 1 and item.description[-1] in [".", "?", "!"], id)
		if item.cursed:
			assert_true(item.description.contains(" but "), "%s says its drawback" % id)


func test_alert_bracelet_stuns_nearby_enemies_on_the_drop_to_one_pill_once_a_room() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["alert_bracelet"])
	assert_eq(run.stats.max_pills, PlayerStats.BASE_PILLS + 1)
	var near := kit.enemy()
	near.position = Vector2(40, 0)
	var far := kit.enemy()
	far.position = Vector2(400, 0)
	run.effects.room_enter(null)
	run.health.pills = 2
	run.effects.tick(0.1)
	assert_false(near.is_dazed(), "two pills is no alarm")
	run.health.pills = 1
	run.effects.tick(0.1)
	assert_true(near.is_dazed())
	assert_false(far.is_dazed(), "out of reach")
	assert_eq(kit.sounds, ["alarm"] as Array[String])
	run.health.pills = 3
	run.effects.tick(0.1)
	run.health.pills = 1
	run.effects.tick(0.1)
	assert_eq(kit.sounds.size(), 1, "once a room")
	run.health.pills = 3
	run.effects.room_enter(null)
	run.health.pills = 1
	run.effects.tick(0.1)
	assert_eq(kit.sounds.size(), 2, "and again in the next room")
	kit.free_enemies()


func test_bifocals_show_health_and_hit_the_nearly_dead_harder() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["bifocals"])
	assert_true(run.stats.reveals_enemy_health)
	var enemy := kit.enemy()
	enemy.hp = enemy.max_hp() * 0.2
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.SWING), 15.0)
	enemy.hp = enemy.max_hp() * 0.5
	assert_near(run.effects.hit_damage(enemy, 10.0, RunEffects.BITE), 10.0)
	kit.free_enemies()


func test_bingo_card_pays_every_fifth_pension_pickup_five_times_with_a_pop() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["bingo_card"])
	assert_near(run.stats.pension_mult, 1.0, "no flat Pension bonus any more")
	for i in 4:
		assert_eq(run.effects.pickup(RunEffects.PENSION, 3), 3)
	assert_eq(run.effects.pickup(RunEffects.HEAL, 2), 2, "only Pension counts")
	assert_eq(run.effects.pickup(RunEffects.PENSION, 3), 15)
	var pops := kit.fx_of(ItemFx.FxPop)
	assert_eq(pops.size(), 1)
	assert_eq(pops[0]["text"], "BINGO!")
	assert_eq(run.effects.pickup(RunEffects.PENSION, 3), 3, "the count starts again")


func test_comfort_care_lanyard_adds_a_pill_and_a_pill_to_every_heal() -> void:
	var run := ItemKit.new().run_with(["comfort_care_lanyard"])
	assert_eq(run.stats.max_pills, PlayerStats.BASE_PILLS + 1)
	assert_eq(run.stats.heal_bonus, 1)
	run.health.pills = 1
	run.health.heal(1)
	assert_eq(run.health.pills, 3)


func test_the_unchanged_four_keep_their_rules() -> void:
	var kit := ItemKit.new()
	var dentures := kit.run_with(["dentures"])
	assert_near(dentures.stats.bite_damage_mult, 1.5)
	assert_eq(dentures.stats.bites_per_throw, 2)
	assert_near(kit.run_with(["golden_parachute"]).stats.death_pension_bonus, 0.25)
	assert_eq(kit.run_with(["life_jacket"]).stats.floor_lethal_saves, 1)
	assert_near(kit.run_with(["lucky_tee"]).stats.lucky_swing_chance, 0.1)


func test_hearing_aid_warns_earlier_and_shows_off_screen_arrows() -> void:
	var run := ItemKit.new().run_with(["hearing_aid"])
	assert_true(run.stats.warning_fraction > PlayerStats.BASE_WARNING)
	assert_true(run.stats.shows_offscreen_enemies)
	assert_false(ItemKit.new().make_run().stats.shows_offscreen_enemies)


func test_naughty_list_presents_come_from_summons_two_a_room_at_most() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["naughty_list"])
	assert_near(run.stats.pension_mult, 1.0)
	var effect = run.effects.effect_of("naughty_list")
	effect.rng.seed = 11
	var plain := kit.enemy()
	for i in 30:
		run.effects.kill(plain, RunEffects.SWING)
	assert_eq(kit.drops.size(), 0, "only summons")
	var summon := kit.enemy()
	summon.is_summon = true
	run.effects.room_enter(null)
	for i in 30:
		run.effects.kill(summon, RunEffects.SWING)
	assert_eq(kit.drops.size(), NaughtyList.ROOM_LIMIT)
	for drop in kit.drops:
		assert_true(NaughtyList.PRESENTS.has(drop[0]), str(drop))
	var given := 0
	effect._given = 0
	for i in 3000:
		if effect.rng.randf() < NaughtyList.CHANCE:
			given += 1
	assert_true(absf(given / 3000.0 - 1.0 / 3.0) < 0.03, "one in three")
	kit.free_enemies()


func test_neck_pillow_heals_fully_on_a_landing_only() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["neck_pillow"])
	assert_eq(run.stats.max_pills, PlayerStats.BASE_PILLS + 1)
	var floor_room := _room_view(RoomLayout.TYPE_COMBAT)
	run.effects.ctx.room = floor_room
	run.health.pills = 1
	run.effects.floor_start()
	assert_eq(run.health.pills, 1, "a new floor is no landing")
	var landing := _room_view(RoomLayout.TYPE_LANDING)
	run.effects.ctx.room = landing
	run.effects.floor_start()
	assert_eq(run.health.pills, run.health.max_pills)
	floor_room.free()
	landing.free()


func test_nitro_tablets_go_off_on_a_heavy_hit_and_spare_him() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["nitro_tablets"])
	assert_near(run.damage_mult(), 1.4)
	var near := kit.enemy("intern_reaper", 100.0)
	near.position = Vector2(30, 0)
	var far := kit.enemy("intern_reaper", 100.0)
	far.position = Vector2(300, 0)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1)
	assert_near(near.hp, 100.0, "one pill sets nothing off")
	assert_eq(run.effects.hurt(2, RunEffects.HURT_ENEMY), 2, "he still takes the hit")
	assert_near(near.hp, 100.0 - Nitro.DAMAGE)
	assert_near(far.hp, 100.0)
	assert_eq(kit.fx_of(ItemFx.FxBlast).size(), 1)
	kit.free_enemies()


func test_pill_organizer_stores_heals_taken_at_full_and_soaks_the_next_hit() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["pill_organizer"])
	assert_eq(run.stats.max_pills, PlayerStats.BASE_PILLS + 1)
	run.health.pills = run.health.max_pills - 1
	assert_false(run.effects.accepts_pickup(RunEffects.HEAL), "short of pills, a heal just heals")
	run.health.pills = run.health.max_pills
	assert_true(run.effects.accepts_pickup(RunEffects.HEAL))
	run.effects.pickup(RunEffects.HEAL, 2)
	assert_eq(run.effects.effect_of("pill_organizer").stored, 2)
	assert_false(run.effects.accepts_pickup(RunEffects.HEAL), "two at most")
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 0)
	assert_eq(run.effects.hurt(3, RunEffects.HURT_ENEMY), 2)
	assert_eq(run.effects.hurt(1, RunEffects.HURT_ENEMY), 1, "the store is spent")
	var room := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	assert_true(room.contains("heal.can_take = _can_take_heal") and room.contains("allowed = _can_take_heal"), "heals and shop heals ask the items")


func test_pocket_watch_slows_time_on_a_close_call() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["pocket_watch"])
	run.effects.close_call()
	assert_eq(kit.slows, [[0.4, 1.0]])


func test_prune_juice_halves_the_cooldown_and_each_dodge_costs_a_pension() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["prune_juice"])
	assert_near(run.stats.dodge_cooldown, PlayerStats.BASE_DODGE_COOLDOWN * 0.5)
	kit.pension = 2
	run.effects.dodge(Vector2.RIGHT)
	run.effects.dodge(Vector2.RIGHT)
	run.effects.dodge(Vector2.RIGHT)
	assert_eq(kit.spent, 2)
	assert_eq(kit.pension, 0, "never below zero")


func test_senior_discount_takes_a_quarter_off_shop_prices() -> void:
	var run := ItemKit.new().run_with(["senior_discount"])
	assert_near(run.stats.shop_discount, 0.25)
	assert_near(run.stats.pension_mult, 1.0)
	var rare := ItemKit.item("bifocals")
	assert_eq(ShopRules.item_price(rare, 1.0, run.stats.shop_discount), 45)


func test_orthopedic_slippers_are_faster_and_grip_the_wet() -> void:
	var run := ItemKit.new().run_with(["slippers"])
	assert_near(run.stats.move_speed, PlayerStats.BASE_SPEED * 1.1)
	assert_true(run.stats.wet_grip)
	var player := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	assert_true(player.contains("var slides := on_wet and not run.stats.wet_grip"))


func test_support_stockings_hold_his_speed_above_seventy_percent() -> void:
	var run := ItemKit.new().run_with(["support_stockings"])
	assert_near(run.stats.min_slow_factor, 0.7)
	assert_near(run.stats.dodge_cooldown, PlayerStats.BASE_DODGE_COOLDOWN, "no dodge cut any more")
	var player := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	assert_true(player.contains("maxf(_slow.speed_factor(), run.stats.min_slow_factor)"))


func test_titanium_hip_hits_what_he_dodges_through_once_a_dodge() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["titanium_hip"])
	var effect = run.effects.effect_of("titanium_hip")
	var enemy := kit.enemy("intern_reaper", 100.0)
	enemy.position = Vector2(5, 0)
	var away := kit.enemy("intern_reaper", 100.0)
	away.position = Vector2(200, 0)
	var body := Rect2(Vector2(-10, -14), TitaniumHip.BODY)
	run.effects.dodge(Vector2.RIGHT)
	effect.strike_through(run.effects.ctx, body)
	effect.strike_through(run.effects.ctx, body)
	var half := CaneCombo.DAMAGE[0] * 0.5
	assert_near(enemy.hp, 100.0 - half, "once a dodge")
	assert_near(away.hp, 100.0)
	run.effects.dodge(Vector2.RIGHT)
	effect.strike_through(run.effects.ctx, body)
	assert_near(enemy.hp, 100.0 - half * 2.0, "and again on the next dodge")
	kit.free_enemies()


func test_undertakers_gloves_hit_harder_and_finish_quietly() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["undertakers_gloves"])
	assert_near(run.damage_mult(), 1.2)
	var enemy := kit.enemy("intern_reaper", 5.0)
	run.effects.land(enemy, 2.0, RunEffects.SWING)
	assert_false(enemy.harmless_death, "a hit it lives through leaves it as it was")
	run.effects.land(enemy, 10.0, RunEffects.SWING)
	assert_true(enemy.harmless_death)
	for path: String in ["res://scripts/actors/behaviors/exploder_behavior.gd", "res://scripts/actors/behaviors/pallbearer_behavior.gd"]:
		assert_true(FileAccess.get_file_as_string(path).contains("enemy.harmless_death"), path)
	kit.free_enemies()


func test_every_shipped_item_has_a_known_rarity_and_tags() -> void:
	for item in Content.items():
		assert_true(ItemRarity.ORDER.has(item.rarity), item.id)
		assert_false(item.tags.is_empty(), "%s has tags" % item.id)
		for tag in item.tags:
			assert_true(ItemDef.TAGS.has(tag), "%s: %s" % [item.id, tag])
