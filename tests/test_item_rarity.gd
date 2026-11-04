extends TestCase

const SOURCES := [ItemRarity.SHOP, ItemRarity.ITEM_ROOM, ItemRarity.ARCADE, ItemRarity.TREASURE, ItemRarity.URN, ItemRarity.VAULT, ItemRarity.BOSS]


func _run() -> RunState:
	var none: Array[UpgradeDef] = []
	return RunState.new(none, {})


func _item(id: String, rarity := ItemDef.COMMON, cursed := false) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	item.rarity = rarity
	item.cursed = cursed
	return item


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_the_weights_match_the_design_and_sum_to_a_hundred() -> void:
	assert_eq(ItemRarity.WEIGHTS[ItemRarity.SHOP], [70, 27, 3])
	assert_eq(ItemRarity.WEIGHTS[ItemRarity.ITEM_ROOM], [60, 35, 5])
	assert_eq(ItemRarity.WEIGHTS[ItemRarity.ARCADE], [60, 35, 5])
	assert_eq(ItemRarity.WEIGHTS[ItemRarity.TREASURE], [50, 40, 10])
	assert_eq(ItemRarity.WEIGHTS[ItemRarity.URN], [40, 45, 15])
	assert_eq(ItemRarity.WEIGHTS[ItemRarity.VAULT], [30, 50, 20])
	assert_eq(ItemRarity.WEIGHTS[ItemRarity.BOSS], [20, 50, 30])
	for source: String in SOURCES:
		var weights: Array = ItemRarity.WEIGHTS[source]
		assert_eq(weights[0] + weights[1] + weights[2], 100, source)


func test_a_roll_lands_on_the_edges_of_its_weights() -> void:
	assert_eq(ItemRarity.roll(ItemRarity.SHOP, 0.0), ItemDef.COMMON)
	assert_eq(ItemRarity.roll(ItemRarity.SHOP, 0.6999), ItemDef.COMMON)
	assert_eq(ItemRarity.roll(ItemRarity.SHOP, 0.7001), ItemDef.RARE)
	assert_eq(ItemRarity.roll(ItemRarity.SHOP, 0.9699), ItemDef.RARE)
	assert_eq(ItemRarity.roll(ItemRarity.SHOP, 0.9701), ItemDef.LEGENDARY)
	assert_eq(ItemRarity.roll(ItemRarity.BOSS, 0.9999), ItemDef.LEGENDARY)


# Over many seeds, a pool with plenty of each rarity is picked at each source's weights.
func test_picks_follow_each_sources_weights_over_seeds() -> void:
	var all: Array[ItemDef] = []
	for rarity: String in ItemRarity.ORDER:
		for i in 3:
			all.append(_item("%s_%d" % [rarity, i], rarity))
	var run := _run()
	for source: String in SOURCES:
		var counts := {ItemDef.COMMON: 0, ItemDef.RARE: 0, ItemDef.LEGENDARY: 0}
		var picks := 6000
		for seed_value in picks:
			var picked := RoomRules.pick_items(all, run, 1, _rng(seed_value * 7 + 1), source)
			counts[picked[0].rarity] += 1
		var weights: Array = ItemRarity.WEIGHTS[source]
		for i in 3:
			var share: float = 100.0 * counts[ItemRarity.ORDER[i]] / picks
			assert_true(absf(share - weights[i]) < 2.0, "%s %s: %.1f%% against %d%%" % [source, ItemRarity.ORDER[i], share, weights[i]])


func test_a_rarity_with_nothing_left_falls_to_another() -> void:
	var all: Array[ItemDef] = [_item("only_common")]
	for seed_value in 50:
		var picked := RoomRules.pick_items(all, _run(), 1, _rng(seed_value), ItemRarity.BOSS)
		assert_eq(picked.size(), 1, "seed %d" % seed_value)
	var two: Array[ItemDef] = [_item("c"), _item("r", ItemDef.RARE)]
	assert_eq(RoomRules.pick_items(two, _run(), 3, _rng(3), ItemRarity.SHOP).size(), 2, "a short pool gives what it has")


func test_bosses_and_vaults_never_offer_a_cursed_item() -> void:
	var all: Array[ItemDef] = [_item("plain"), _item("cursed", ItemDef.COMMON, true)]
	for source: String in [ItemRarity.BOSS, ItemRarity.VAULT]:
		assert_false(ItemRarity.allows_cursed(source))
		for seed_value in 30:
			for item in RoomRules.pick_items(all, _run(), 2, _rng(seed_value), source):
				assert_false(item.cursed, source)
	assert_eq(RoomRules.offerable(all, _run(), ItemRarity.SHOP).size(), 2, "a shop may sell it")
	assert_eq(RoomRules.offerable(all, _run(), ItemRarity.BOSS).size(), 1)


func test_shop_prices_keep_the_ratios_and_scale_by_the_floor() -> void:
	var common := _item("c")
	var rare := _item("r", ItemDef.RARE)
	var legendary := _item("l", ItemDef.LEGENDARY)
	assert_eq(ItemRarity.price(rare, 1.0), ShopRules.ITEM_PRICE, "a rare costs what an item did")
	assert_eq(ItemRarity.price(common, 1.0), 35)
	assert_eq(ItemRarity.price(legendary, 1.0), 175)
	assert_true(absf(float(ItemRarity.price(common, 1.0)) / ItemRarity.price(rare, 1.0) - 30.0 / 55.0) < 0.05, "common is a bit over half a rare")
	assert_true(absf(float(ItemRarity.price(legendary, 1.0)) / ItemRarity.price(rare, 1.0) - 160.0 / 55.0) < 0.02, "legendary is about three rares")
	assert_eq(ItemRarity.price(rare, 2.5), 150)
	assert_eq(ShopRules.item_price(rare, 2.0, 0.25), 90)


func test_the_shop_prices_its_items_by_rarity_and_floor() -> void:
	var all: Array[ItemDef] = [_item("r", ItemDef.RARE)]
	var stock := ShopRules.stock(all, _run(), _rng(1), 3.0)
	assert_eq(stock[0]["kind"], ShopRules.KIND_ITEM)
	assert_eq(stock[0]["price"], 180)
	assert_eq(stock[1]["price"], ShopRules.HEAL_PRICE, "heals keep their price")


func test_names_show_rarity_and_curses() -> void:
	assert_true(ItemRarity.name_color(_item("c")).is_equal_approx(ItemRarity.COMMON_COLOR))
	assert_true(ItemRarity.name_color(_item("r", ItemDef.RARE)).is_equal_approx(ItemRarity.RARE_COLOR))
	assert_true(ItemRarity.name_color(_item("l", ItemDef.LEGENDARY)).is_equal_approx(ItemRarity.LEGENDARY_COLOR))
	assert_true(ItemRarity.name_color(_item("x", ItemDef.RARE, true)).is_equal_approx(ItemRarity.CURSED_COLOR), "purple whatever the rarity")
	var room := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	assert_true(room.contains("pickup.label_color = ItemRarity.name_color(item)") and room.contains("pickup.skull = item.cursed"))


func test_every_item_source_rolls_its_own_table() -> void:
	var room := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	for source: String in ["ItemRarity.ARCADE", "ItemRarity.BOSS", "ItemRarity.URN", "ItemRarity.VAULT", "ItemRarity.TREASURE", "ItemRarity.ITEM_ROOM"]:
		assert_true(room.contains(source), source)
	var shop := FileAccess.get_file_as_string("res://scripts/core/shop_rules.gd")
	assert_true(shop.contains("ItemRarity.SHOP"))
