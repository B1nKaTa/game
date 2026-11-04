extends TestCase

const PATHS := ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "golden_years_mall",
	"last_resort_cruise", "fairways_end", "terminal_zero", "head_office"]


func _item(id: String) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	item.display_name = id.capitalize()
	return item


func _run() -> RunState:
	var none: Array[UpgradeDef] = []
	return RunState.new(none, {})


func test_every_shipped_item_has_exactly_one_source() -> void:
	for item in Content.items():
		assert_true(ItemUnlocks.source_count(item) <= 1, "%s claims %d sources" % [item.id, ItemUnlocks.source_count(item)])


func test_every_bounty_item_is_paid_by_exactly_one_poster() -> void:
	var posters := BountyBoard.all()
	for item in Content.items():
		var paying := 0
		for poster in posters:
			if poster.extra_kind == BountyDef.EXTRA_ITEM and poster.extra_id == item.id:
				paying += 1
		if item.from_bounty:
			assert_eq(paying, 1, "%s is a poster's reward" % item.id)
		else:
			assert_eq(paying, 0, "%s is not a poster item, so no poster pays it" % item.id)


func test_every_recipe_poster_names_a_recipe_item() -> void:
	var by_id := {}
	for item in Content.items():
		by_id[item.id] = item
	for poster in BountyBoard.all():
		if poster.extra_kind == BountyDef.EXTRA_RECIPE:
			assert_true(by_id.has(poster.extra_id) and by_id[poster.extra_id].needs_recipe(), poster.id)


func test_first_clear_items_name_a_real_path() -> void:
	for item in Content.items():
		if not item.first_clear_path.is_empty():
			assert_true(PATHS.has(item.first_clear_path), "%s: %s" % [item.id, item.first_clear_path])
	for depth in ProgressData.PATHS_AT_DEPTH:
		for path: String in ProgressData.PATHS_AT_DEPTH[depth]:
			assert_true(PATHS.has(path), "the list knows %s" % path)


func test_the_source_is_read_from_the_item() -> void:
	var start := _item("start")
	var recipe := _item("recipe")
	recipe.craft_price = 100
	var bounty := _item("bounty")
	bounty.from_bounty = true
	var cleared := _item("cleared")
	cleared.first_clear_path = "cemetery"
	assert_eq(ItemUnlocks.source_of(start), ItemUnlocks.START)
	assert_eq(ItemUnlocks.source_of(recipe), ItemUnlocks.RECIPE)
	assert_eq(ItemUnlocks.source_of(bounty), ItemUnlocks.BOUNTY)
	assert_eq(ItemUnlocks.source_of(cleared), ItemUnlocks.FIRST_CLEAR)
	var both := _item("both")
	both.craft_price = 50
	both.first_clear_path = "cemetery"
	assert_eq(ItemUnlocks.source_count(both), 2, "the source test would catch this one")


func test_a_first_clear_item_joins_once_its_path_is_cleared() -> void:
	var cleared := _item("cleared")
	cleared.first_clear_path = "cemetery"
	var run := _run()
	assert_false(run.can_offer(cleared))
	run.paths_cleared = {"floor_1": true}
	assert_false(run.can_offer(cleared))
	run.paths_cleared = {"cemetery": true}
	assert_true(run.can_offer(cleared))


func test_recipe_and_bounty_items_wait_for_items_unlocked() -> void:
	var recipe := _item("recipe")
	recipe.craft_price = 100
	var bounty := _item("bounty")
	bounty.from_bounty = true
	var run := _run()
	assert_false(run.can_offer(recipe))
	assert_false(run.can_offer(bounty))
	run.unlocked_items = {"recipe": true, "bounty": true}
	assert_true(run.can_offer(recipe))
	assert_true(run.can_offer(bounty))
	assert_true(run.can_offer(_item("start")))


func test_a_cleared_path_announces_its_items_once() -> void:
	var a := _item("bubble_wrap")
	a.first_clear_path = "last_resort_cruise"
	var b := _item("banana_peel")
	b.first_clear_path = "last_resort_cruise"
	var c := _item("floor_plan")
	c.first_clear_path = "floor_1"
	var items: Array[ItemDef] = [a, b, c]
	var data := ProgressData.new()
	assert_true(ItemUnlocks.unannounced(items, data).is_empty())
	data.record_floor_cleared(4, "last_resort_cruise")
	var news := ItemUnlocks.unannounced(items, data)
	assert_eq(news.keys(), ["last_resort_cruise"])
	assert_eq(ItemUnlocks.notice_for(news["last_resort_cruise"]), "Lost and found: Bubble Wrap, Banana Peel")
	data.item_paths_seen["last_resort_cruise"] = true
	assert_true(ItemUnlocks.unannounced(items, data).is_empty())


func test_item_paths_seen_survives_a_save_and_old_saves_start_empty() -> void:
	var data := ProgressData.new()
	data.item_paths_seen = {"cemetery": true}
	var again := ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))
	assert_true(again.item_paths_seen.has("cemetery"))
	var old := data.to_dict()
	old.erase("item_paths_seen")
	assert_true(ProgressData.from_dict(old).item_paths_seen.is_empty())


func test_the_waiting_room_announces_new_items() -> void:
	var room := FileAccess.get_file_as_string("res://scripts/scenes/waiting_room.gd")
	assert_true(room.contains("ItemUnlocks.unannounced(") and room.contains("Progress.mark_item_paths_seen("))
