extends TestCase

const Lasting := preload("res://tests/support/lasting_effect.gd")


func _potion(id: String, action: String, rarity := "common") -> PotionDef:
	var def := PotionDef.new()
	def.id = id
	def.display_name = id.capitalize()
	def.short_name = id
	def.action = action
	def.run_rarity = rarity
	return def


func _drink(run: RunState, def: PotionDef) -> bool:
	run.potion = null
	run.give_potion(def)
	return run.drink_potion()


func test_doubling_never_passes_the_cap_and_waits_while_it_would_do_nothing() -> void:
	var run := ItemKit.new().make_run()
	var brew := _potion("double_test", PotionDef.ACTION_DOUBLE_BOMBS, "rare")
	run.bombs = 0
	assert_false(_drink(run, brew), "doubling nothing waits in the slot")
	run.bombs = 60
	assert_true(_drink(run, brew))
	assert_eq(run.bombs, RunState.MAX_CONSUMABLE)
	run.keys = 4
	assert_true(_drink(run, _potion("tonic_test", PotionDef.ACTION_DOUBLE_SLIPS, "rare")))
	assert_eq(run.keys, 8)


func test_the_swap_waits_on_equal_counts() -> void:
	var run := ItemKit.new().make_run()
	var swap := _potion("swap_test", PotionDef.ACTION_SWAP)
	run.keys = 3
	run.bombs = 3
	assert_false(_drink(run, swap))
	run.bombs = 7
	assert_true(_drink(run, swap))
	assert_eq(run.keys, 7)
	assert_eq(run.bombs, 3)


func test_cash_in_pays_ten_each_counted_up_to_twenty_and_keeps_them() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.keys = 30
	run.bombs = 2
	assert_true(_drink(run, _potion("milk_test", PotionDef.ACTION_CASH_IN, "rare")))
	assert_eq(kit.paid, PotionActions.CASH_PER * (20 + 2))
	assert_eq(run.keys, 30, "he keeps them")
	run.keys = 0
	run.bombs = 0
	assert_false(_drink(run, _potion("milk_test", PotionDef.ACTION_CASH_IN, "rare")))


func test_pet_food_waits_for_a_pet() -> void:
	var run := ItemKit.new().make_run()
	var food := _potion("food_test", PotionDef.ACTION_PET_FOOD)
	assert_false(_drink(run, food))
	var dog := ItemDef.new()
	dog.id = "dog_test"
	dog.kind = ItemDef.KIND_PET
	run.add_item(dog)
	assert_true(_drink(run, food))


func test_a_plain_heal_still_waits_for_a_missing_pill() -> void:
	var run := ItemKit.new().make_run()
	var small := _potion("small_potion", "", "")
	small.heal = 1
	assert_false(_drink(run, small), "full pills")
	run.health.pills -= 1
	assert_true(_drink(run, small))


func test_a_lasting_part_hears_hooks_until_spent_and_is_saved() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var salts := _potion("salts_test", PotionDef.ACTION_SALTS)
	salts.effect = Lasting.new()
	assert_true(_drink(run, salts))
	assert_eq(kit.notices, ["drunk"] as Array[String])
	assert_eq(run.effects.lasting_entries().size(), 1)
	var saved: Dictionary = run.effects.save_state()
	assert_eq(saved["lasting"][0]["id"], "salts_test")
	run.effects.room_clear(null)
	assert_eq(run.effects.lasting_entries().size(), 0, "spent after its room")


func test_the_potion_pool_rolls_small_common_and_rare() -> void:
	var small := _potion("small_potion", "", "")
	small.heal = 1
	var common := _potion("common_test", PotionDef.ACTION_SWAP, "common")
	var rare := _potion("rare_test", PotionDef.ACTION_DOUBLE_BOMBS, "rare")
	var all: Array[PotionDef] = [small, common, rare]
	assert_eq(PotionPool.roll(all, 0.0, 0.5), small)
	assert_eq(PotionPool.roll(all, 0.54, 0.5), small)
	assert_eq(PotionPool.roll(all, 0.56, 0.5), common)
	assert_eq(PotionPool.roll(all, 0.86, 0.5), rare)
	var only_small: Array[PotionDef] = [small]
	assert_eq(PotionPool.roll(only_small, 0.9, 0.5), small, "no run potion: the small one")
	assert_eq(PotionPool.shop_roll(all, 0.69, 0.0), common)
	assert_eq(PotionPool.shop_roll(all, 0.71, 0.0), rare)
	assert_true(PotionPool.shop_roll(only_small, 0.1, 0.0) == null)
	assert_eq(PotionPool.shop_price(common, 1.0), 25)
	assert_eq(PotionPool.shop_price(rare, 2.0), 80)


func test_shops_sell_one_run_potion_when_there_are_any() -> void:
	var run := ItemKit.new().make_run()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var small := _potion("small_potion", "", "")
	var all: Array[PotionDef] = [small, _potion("common_test", PotionDef.ACTION_SWAP), _potion("rare_test", PotionDef.ACTION_DOUBLE_BOMBS, "rare")]
	var stock := ShopRules.stock(Content.items(), run, rng, 1.0, all)
	var potions := stock.filter(func(entry): return entry["kind"] == ShopRules.KIND_POTION)
	assert_eq(potions.size(), 1)
	assert_true((potions[0]["potion"] as PotionDef).is_run_potion())
	var plain := ShopRules.stock(Content.items(), run, rng, 1.0)
	assert_eq(plain.filter(func(entry): return entry["kind"] == ShopRules.KIND_POTION).size(), 0)


func test_the_room_rolls_its_potion_drops_and_sells_potions() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	assert_true(source.contains("PotionPool.roll(Content.potions(), _rng.randf(), _rng.randf())"))
	assert_true(source.contains("ShopRules.KIND_POTION:"))
	assert_true(source.contains("ShopRules.stock(Content.items(), _run, _rng, _floor_def.pension_mult, Content.potions())"))


func test_a_carried_potion_keeps_its_id() -> void:
	var lying := Pickup.new()
	lying.carry_kind = RoomRules.DROP_POTION
	lying.carry_id = "rare_test"
	var record := RoomView.carry_record(lying)
	assert_eq(record["kind"], RoomRules.DROP_POTION)
	assert_eq(record["id"], "rare_test")
	var plain := Pickup.new()
	plain.carry_kind = RoomRules.DROP_KEY
	assert_eq(RoomView.carry_record(plain)["id"], "", "other pickups carry no potion id")
	lying.free()
	plain.free()
	var boxes := FileAccess.get_file_as_string("res://scripts/items/moving_boxes.gd")
	assert_true(boxes.contains("ctx.drop(box[\"kind\"], at, int(box[\"amount\"]), str(box.get(\"id\", \"\")))"), "the box hands the id on")
	var room := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	assert_true(room.contains("elif kind == RoomRules.DROP_POTION and Content.potion(id) != null:"), "the next room lays that potion, else rolls")
	assert_true(room.contains("potion.carry_id = def.id"))


func test_a_lasting_effect_comes_back_once_from_a_checkpoint() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var salts := _potion("salts_test", PotionDef.ACTION_SALTS)
	var part := Lasting.new()
	part.rooms = 3
	salts.effect = part
	assert_true(_drink(run, salts))
	run.effects.room_clear(null)
	var raw: Dictionary = JSON.parse_string(JSON.stringify(RunCheckpoint.run_to_dict(run)))
	var back_kit := ItemKit.new()
	var back := back_kit.make_run()
	RunCheckpoint.apply_run(back, raw, Content.items())
	var potions: Array[PotionDef] = [salts]
	RunCheckpoint.restore_lasting(back, raw["effects"]["lasting"], potions)
	assert_eq(back.effects.lasting_entries().size(), 1, "back exactly once")
	assert_eq(back.effects.lasting_entries()[0][1].left, 2, "its state, not a fresh drink")
	assert_eq(back_kit.notices.size(), 0, "on_drink did not run again")
	var unknown: Array[PotionDef] = []
	var other := back_kit.make_run()
	RunCheckpoint.restore_lasting(other, raw["effects"]["lasting"], unknown)
	assert_eq(other.effects.lasting_entries().size(), 0, "an id no potion has is skipped")


func test_a_spent_lasting_effect_is_gone_after_the_next_hook() -> void:
	var run := ItemKit.new().make_run()
	var salts := _potion("salts_test", PotionDef.ACTION_SALTS)
	salts.effect = Lasting.new()
	var potions: Array[PotionDef] = [salts]
	RunCheckpoint.restore_lasting(run, [{"id": "salts_test", "state": {"left": 0}}], potions)
	assert_eq(run.effects.lasting_entries().size(), 1)
	run.effects.room_enter(null)
	assert_eq(run.effects.lasting_entries().size(), 0)


func test_cash_in_pays_nothing_while_counting_exact() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.keys = 5
	run.bombs = 5
	run.effects.ctx.counting_exact = true
	assert_true(_drink(run, _potion("milk_test", PotionDef.ACTION_CASH_IN, "rare")))
	assert_eq(kit.paid, 0)
