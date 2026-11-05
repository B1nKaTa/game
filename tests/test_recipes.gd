extends TestCase


func _run() -> RunState:
	var empty: Array[UpgradeDef] = []
	return RunState.new(empty, {})


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	return rng


func _item(id: String, price := 0) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	item.craft_price = price
	return item


func _data(pension := 1000) -> ProgressData:
	var data := ProgressData.new()
	data.pension = pension
	return data


func test_shipped_recipe_items_have_prices_and_base_items_do_not() -> void:
	# The eight that came first, then the hundred items' batches add theirs.
	assert_eq(Content.recipes().size(), 18)
	for item in Content.recipes():
		assert_true(item.needs_recipe(), item.id)
	var base := 0
	for item in Content.items():
		if not item.needs_recipe() and not item.from_bounty:
			base += 1
	assert_eq(base, 58)


func test_recipe_items_stay_out_of_rotation_until_crafted() -> void:
	var locked := _item("locked", 50)
	var all: Array[ItemDef] = [locked]
	var run := _run()
	assert_eq(RoomRules.pick_items(all, run, 1, _rng()).size(), 0)
	run.unlocked_items = {"locked": true}
	assert_eq(RoomRules.pick_items(all, run, 1, _rng()).size(), 1)


func test_base_items_are_always_in_rotation() -> void:
	var all: Array[ItemDef] = [_item("base")]
	assert_eq(RoomRules.pick_items(all, _run(), 1, _rng()).size(), 1)


func test_finding_a_recipe_is_remembered() -> void:
	var data := _data()
	assert_false(data.has_recipe("hip"))
	data.find_recipe("hip")
	assert_true(data.has_recipe("hip"))


func test_crafting_needs_the_recipe_and_the_money() -> void:
	var data := _data(100)
	assert_false(data.can_craft("hip", 50), "recipe not found")
	data.find_recipe("hip")
	assert_true(data.can_craft("hip", 50))
	assert_false(data.can_craft("hip", 101), "too poor")
	assert_false(data.craft("hip", 101))
	assert_eq(data.pension, 100)


func test_crafting_charges_and_readies_the_item_and_unlocks_it() -> void:
	var data := _data(100)
	data.find_recipe("hip")
	assert_true(data.craft("hip", 60))
	assert_eq(data.pension, 40)
	assert_eq(data.crafted_for_next_run, "hip")
	assert_true(data.is_unlocked("hip"))


func test_only_one_item_can_wait_for_the_next_run() -> void:
	var data := _data()
	data.find_recipe("hip")
	data.find_recipe("beads")
	assert_true(data.craft("hip", 10))
	assert_false(data.can_craft("beads", 10))
	assert_false(data.craft("beads", 10))
	assert_eq(data.crafted_for_next_run, "hip")
	assert_eq(data.pension, 990)


func test_taking_the_crafted_item_empties_the_slot() -> void:
	var data := _data()
	data.find_recipe("hip")
	data.craft("hip", 10)
	assert_eq(data.take_crafted_item(), "hip")
	assert_eq(data.take_crafted_item(), "", "only one run gets it")
	assert_true(data.is_unlocked("hip"), "stays in rotation")


func test_an_item_can_only_be_crafted_once_ever() -> void:
	var data := _data()
	data.find_recipe("hip")
	data.craft("hip", 10)
	data.take_crafted_item()
	assert_false(data.can_craft("hip", 10))
	assert_false(data.craft("hip", 10))
	assert_eq(data.pension, 990, "no second charge")
	assert_eq(data.crafted_for_next_run, "", "no second head start")
	assert_true(data.is_unlocked("hip"), "still in rotation")


func test_a_saved_crafted_item_stays_crafted_after_loading() -> void:
	var data := _data()
	data.find_recipe("hip")
	data.craft("hip", 10)
	data.take_crafted_item()
	var loaded := ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))
	assert_false(loaded.can_craft("hip", 10))


func test_recipes_are_saved_and_loaded() -> void:
	var data := _data()
	data.find_recipe("hip")
	data.find_recipe("beads")
	data.craft("hip", 10)
	var loaded := ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))
	assert_true(loaded.has_recipe("beads"))
	assert_true(loaded.is_unlocked("hip"))
	assert_false(loaded.is_unlocked("beads"))
	assert_eq(loaded.crafted_for_next_run, "hip")


func test_saves_from_before_recipes_still_load() -> void:
	var old := {"version": 1, "pension": 5, "upgrades": {}, "opening_seen": true}
	var loaded := ProgressData.from_dict(old)
	assert_true(loaded != null)
	assert_false(loaded.has_recipe("hip"))
	assert_eq(loaded.crafted_for_next_run, "")


func test_damaged_recipe_fields_are_ignored() -> void:
	var raw := {"version": 1, "pension": 5, "upgrades": {}, "opening_seen": true, "recipes_found": "nope", "items_unlocked": 3, "crafted_for_next_run": 9}
	var loaded := ProgressData.from_dict(raw)
	assert_true(loaded != null)
	assert_false(loaded.has_recipe("nope"))
	assert_eq(loaded.crafted_for_next_run, "")


func test_pick_recipe_skips_found_and_already_offered() -> void:
	var all: Array[ItemDef] = [_item("base"), _item("found", 10), _item("offered", 10), _item("new", 10)]
	var run := _run()
	run.offer_recipe("offered")
	var picked := RoomRules.pick_recipe(all, {"found": true}, run, _rng())
	assert_eq(picked.id, "new")


func test_pick_recipe_with_nothing_left_gives_nothing() -> void:
	var all: Array[ItemDef] = [_item("base"), _item("found", 10)]
	assert_true(RoomRules.pick_recipe(all, {"found": true}, _run(), _rng()) == null)


func test_a_recipe_offered_this_run_is_not_offered_again() -> void:
	var all: Array[ItemDef] = [_item("only", 10)]
	var run := _run()
	assert_eq(RoomRules.pick_recipe(all, {}, run, _rng()).id, "only")
	assert_true(RoomRules.pick_recipe(all, {}, run, _rng()) == null, "picking offers it")
