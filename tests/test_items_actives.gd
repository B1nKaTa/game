extends TestCase

const IDS := {"hearing_aid_feedback": [3, "rare", "any"], "harmonica": [4, "common", "pills"], "lottery_scratcher": [0, "common", "pension"],
	"walking_frame": [2, "common", "any"], "exchange_desk": [2, "rare", "slip"], "photocopier": [6, "legendary", "any"],
	"megaphone": [2, "rare", "rules"], "dinner_bell": [2, "rare", "pets"]}


func test_the_actives_ship_with_their_charge() -> void:
	for id: String in IDS:
		var item := ItemKit.item(id)
		assert_true(item != null, id)
		if item == null:
			continue
		assert_true(item.is_active(), id)
		assert_eq(item.charge_rooms, IDS[id][0], id)
		assert_eq(item.rarity, IDS[id][1], id)
		assert_eq(item.build, IDS[id][2], id)
	assert_true(ItemKit.item("lottery_scratcher").charge_per_floor)
	assert_false(ItemKit.item("megaphone").needs_rules(), "a rules active works anywhere")
	assert_eq(ItemKit.item("hearing_aid_feedback").display_name, "Hearing Aid")
	assert_true(RetiredContent.is_retired("hearing_aid"))


func test_the_hearing_aid_stuns_the_room_and_waits_for_enemies() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["hearing_aid_feedback"])
	assert_false(run.use_active(), "no one to stun: the charge stays")
	var a := kit.enemy()
	var b := kit.enemy("regional_reaper")
	assert_true(run.use_active())
	assert_true(a.is_stunned())
	assert_true(b.is_stunned())
	kit.free_enemies()


func test_the_harmonica_heals_a_pill_and_waits_at_full() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["harmonica"])
	assert_false(run.use_active(), "full pills")
	run.health.pills = 2
	assert_true(run.use_active())
	assert_eq(run.health.pills, 3)
	assert_true(kit.sounds.has("pill_heal"))


func test_the_scratcher_drops_one_prize_a_floor() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["lottery_scratcher"])
	var lottery := load("res://scripts/items/lottery_scratcher.gd")
	assert_eq(lottery.prize(0.0), "coin")
	assert_eq(lottery.prize(0.45), "key")
	assert_eq(lottery.prize(0.65), "bomb")
	assert_eq(lottery.prize(0.9), "heal")
	assert_eq(lottery.prize(0.97), "item")
	assert_true(run.use_active())
	assert_eq(kit.drops.size(), 1)
	assert_false(run.use_active(), "once a floor")
	run.effects.floor_start()
	assert_true(run.use_active())


func test_the_walking_frame_plants_a_frame() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["walking_frame"])
	assert_true(run.use_active())
	assert_eq(kit.fx_of(WalkingFrame).size(), 1)


func test_the_exchange_desk_swaps_and_waits_on_equal_counts() -> void:
	var run := ItemKit.new().run_with(["exchange_desk"])
	run.keys = 4
	run.bombs = 4
	assert_false(run.use_active())
	run.bombs = 9
	assert_true(run.use_active())
	assert_eq(run.keys, 9)
	assert_eq(run.bombs, 4)


func test_the_photocopier_copies_or_keeps_its_charge() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["photocopier"])
	assert_false(run.use_active(), "nothing to copy")
	kit.can_copy = true
	assert_true(run.use_active())
	assert_eq(kit.copies, 1)


func test_the_megaphone_shoves_and_stuns_what_is_in_front() -> void:
	var megaphone := load("res://scripts/items/megaphone.gd")
	assert_true(megaphone.in_cone(Vector2.ZERO, Vector2.RIGHT, Vector2(100, 30), 150.0, 45.0))
	assert_false(megaphone.in_cone(Vector2.ZERO, Vector2.RIGHT, Vector2(-100, 0), 150.0, 45.0), "behind him")
	assert_false(megaphone.in_cone(Vector2.ZERO, Vector2.RIGHT, Vector2(200, 0), 150.0, 45.0), "too far")
	var kit := ItemKit.new()
	var run := kit.run_with(["megaphone"])
	var front := kit.enemy()
	front.position = Vector2(80, 0)
	var back := kit.enemy()
	back.position = Vector2(-80, 0)
	assert_true(run.use_active())
	assert_true(front.is_stunned())
	assert_true(front.is_pushed())
	assert_false(back.is_stunned())
	kit.free_enemies()


func test_the_dinner_bell_triples_pets_for_five_seconds() -> void:
	var run := ItemKit.new().run_with(["dinner_bell"])
	assert_false(run.use_active(), "no pet to call")
	run.add_item(ItemKit.item("rex"))
	assert_true(run.use_active())
	assert_near(run.pet_damage_mult(), 3.0)
	run.effects.tick(5.1)
	assert_near(run.pet_damage_mult(), 1.0)
