extends TestCase


func _run() -> RunState:
	var empty: Array[UpgradeDef] = []
	return RunState.new(empty, {})


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	return rng


func _pool() -> Array[RoomLayout]:
	return RoomCatalog.load_valid("res://data/rooms/floor_1/")


func test_stock_has_two_items_a_heal_a_slip_and_a_thermos() -> void:
	var stock := ShopRules.stock(Content.items(), _run(), _rng())
	var kinds := []
	for entry in stock:
		kinds.append(entry["kind"])
	assert_eq(kinds, [ShopRules.KIND_ITEM, ShopRules.KIND_ITEM, ShopRules.KIND_HEAL, ShopRules.KIND_KEY, ShopRules.KIND_BOMB])
	assert_true(stock[0]["item"] != stock[1]["item"], "two different items")


func test_every_stock_entry_has_a_price() -> void:
	for entry in ShopRules.stock(Content.items(), _run(), _rng()):
		assert_true(entry["price"] > 0)


func test_owned_and_promised_items_are_not_sold() -> void:
	var all: Array[ItemDef] = []
	for item in Content.items():
		if not item.needs_recipe():
			all.append(item)
	var run := _run()
	for i in all.size() - 1:
		if i % 2 == 0:
			run.add_item(all[i])
		else:
			run.promise(all[i])
	var stock := ShopRules.stock(all, run, _rng())
	assert_eq(stock.size(), 4, "only one item is left to sell")
	assert_eq(stock[0]["item"], all[-1])


func test_a_promised_item_can_still_be_taken() -> void:
	var run := _run()
	var item: ItemDef = Content.items()[0]
	run.promise(item)
	assert_true(run.is_promised(item.id))
	assert_false(run.has_item(item.id))


func test_reward_place_only_uses_what_is_still_ahead() -> void:
	assert_eq(ShopRules.reward_place(false, false, 0.0), ShopRules.PLACE_SHOP)
	assert_eq(ShopRules.reward_place(false, false, 0.99), ShopRules.PLACE_SHOP)
	assert_eq(ShopRules.reward_place(true, false, 0.99), ShopRules.PLACE_TREASURE)
	assert_eq(ShopRules.reward_place(false, true, 0.99), ShopRules.PLACE_BOSS)


func test_reward_place_can_be_any_of_the_three() -> void:
	assert_eq(ShopRules.reward_place(true, true, 0.0), ShopRules.PLACE_SHOP)
	assert_eq(ShopRules.reward_place(true, true, 0.5), ShopRules.PLACE_TREASURE)
	assert_eq(ShopRules.reward_place(true, true, 0.99), ShopRules.PLACE_BOSS)


func test_station_text_while_locked() -> void:
	var text := RetirementStation.status_lines(240, 250, false)
	assert_eq(text[0], "Retirement Plan: 240 / 1000")
	assert_eq(text[1], "Next reward at 250")
	assert_eq(text[2], "Locked until your next run")


func test_station_text_when_it_can_be_bombed() -> void:
	var text := RetirementStation.status_lines(1000, -1, true)
	assert_eq(text[1], "All rewards earned")
	assert_eq(text[2], "Bomb it to cash out")


func test_station_text_when_empty() -> void:
	assert_eq(RetirementStation.status_lines(0, 10, false)[2], "Empty")


func test_every_floor_has_one_shop_reachable_without_a_bomb_off_a_middle_room() -> void:
	var pool := _pool()
	var def: FloorDef = load("res://data/floors/floor_1.tres")
	for seed_value in 300:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var map := FloorBuilder.build_from_pool(rng, def, pool)
		var reached := map.reached_without_bomb()
		var shops := 0
		for room in map.rooms:
			if room.room_type != RoomLayout.TYPE_SHOP:
				continue
			shops += 1
			assert_true(room.is_detour())
			assert_true(reached.has(room.id), "seed %d" % seed_value)
			var parent_id: int = room.doors.values()[0]
			assert_true(parent_id != map.start_id and parent_id != map.boss_id)
		assert_eq(shops, 1, "seed %d" % seed_value)


func test_arriving_around_a_shop() -> void:
	var map := FloorMap.new()
	var parent := FloorRoom.new()
	parent.id = 0
	parent.room_type = RoomLayout.TYPE_COMBAT
	parent.layout = _pool()[0]
	map.rooms.append(parent)
	var shop := FloorRoom.new()
	shop.id = 1
	shop.room_type = RoomLayout.TYPE_SHOP
	shop.cell = Vector2i(0, 1)
	shop.layout = _pool()[0]
	map.rooms.append(shop)
	map.join(parent, shop)
	var progress := FloorProgress.new(map)
	assert_eq(progress.arrival_cell(1, 0), shop.layout.door_cell(RoomLayout.NORTH))
	assert_eq(progress.arrival_cell(0, 1), parent.layout.door_cell(RoomLayout.SOUTH))


func test_shop_layout_has_room_for_every_reward() -> void:
	for layout in _pool():
		if layout.room_type == RoomLayout.TYPE_SHOP:
			assert_eq(layout.cells_of("S").size(), 5)
			assert_eq(layout.cells_of("P").size(), 1)
			assert_eq(layout.cells_of("R").size(), ProgressData.RETIREMENT_TIERS.size())


func test_summons_never_land_on_the_plan_station() -> void:
	var layout := RoomLayout.new()
	layout.rows = PackedStringArray(["###", "#P.", "###"])
	assert_eq(layout.nearest_floor_cell(Vector2i(1, 1)), Vector2i(2, 1))
