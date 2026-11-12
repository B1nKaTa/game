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
	var actives: Array[ItemDef] = []
	# Only items open from the start, since a fresh run has cleared no path. A run holds one active, so
	# the actives are kept apart (below): a second one would swap the first out of the slot.
	for item in Content.items():
		if not item.needs_recipe() and not item.from_bounty and item.first_clear_path.is_empty():
			if item.is_active():
				actives.append(item)
			else:
				all.append(item)
	var run := _run()
	for i in all.size() - 1:
		if i % 2 == 0:
			run.add_item(all[i])
		else:
			run.promise(all[i])
	# He holds one active; the one he held before was swapped out and he no longer owns it.
	assert_true(actives.size() >= 2)
	run.add_item(actives[0])
	run.add_item(actives[1])
	var stock := ShopRules.stock(all, run, _rng())
	assert_eq(stock.size(), 4, "only one item is left to sell")
	assert_eq(stock[0]["item"], all[-1])
	var with_actives := ShopRules.stock([actives[0], actives[1]], run, _rng())
	var offered: Array = []
	for entry in with_actives:
		offered.append(entry["item"])
	assert_false(offered.has(actives[1]), "the held active is never sold")
	assert_true(offered.has(actives[0]), "a swapped-out active can be sold again")


func test_a_promised_item_can_still_be_taken() -> void:
	var run := _run()
	var item: ItemDef = Content.items()[0]
	run.promise(item)
	assert_true(run.is_promised(item.id))
	assert_false(run.has_item(item.id))


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


func _shops() -> Array[RoomLayout]:
	var shops: Array[RoomLayout] = []
	for folder in ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "flashback_cinema", "head_office",
			"terminal_zero"]:
		for layout in RoomCatalog.load_valid("res://data/rooms/%s/" % folder):
			if layout.room_type == RoomLayout.TYPE_SHOP:
				shops.append(layout)
	# The Last Resort Cruise
	for layout in RoomCatalog.load_valid("res://data/rooms/last_resort_cruise/"):
		if layout.room_type == RoomLayout.TYPE_SHOP:
			shops.append(layout)
	# The Seance Hotline.
	for layout in RoomCatalog.load_valid("res://data/rooms/seance_hotline/"):
		if layout.room_type == RoomLayout.TYPE_SHOP:
			shops.append(layout)
	return shops


func test_every_shop_has_its_wares_and_a_plan() -> void:
	var shops := _shops()
	assert_true(shops.size() >= 3, "one shop per floor at least")
	for layout in shops:
		assert_eq(layout.cells_of("S").size(), 5)
		assert_eq(layout.cells_of("P").size(), 1)


func test_every_plan_tier_has_its_own_spot_beside_the_plan() -> void:
	var tiers := ProgressData.RETIREMENT_TIERS.size()
	for layout in _shops():
		var station := layout.cells_of("P")[0]
		var spots := layout.plan_reward_cells(tiers)
		assert_eq(spots.size(), tiers, layout.resource_path)
		var seen := {}
		for spot in spots:
			assert_false(seen.has(spot), "each spot once")
			seen[spot] = true
			assert_eq(layout.symbol_at(spot), RoomLayout.SYMBOL_FLOOR)
			assert_false(layout.touches_a_door(spot))
			# Sunset Shores once put one under the small map, and a long name ran past the right wall.
			assert_true(spot.y > RoomLayout.UNDER_THE_HUD, "%s: %s is under the HUD" % [layout.resource_path, str(spot)])
			assert_true(spot.x + RoomLayout.LABEL_CELLS < layout.size_in_cells().x, "%s: no room for the name at %s" % [layout.resource_path, str(spot)])
		# Its Take prompt and the plan's Pay in never answer the same press.
		var first := spots[0]
		var reach := RetirementStation.USE_RADIUS + Pickup.COLLECT_RADIUS + absf(Player.FEET_OFFSET.y)
		assert_true(Vector2(first - station).length() * RoomBackdrop.TILE > reach, "%s first at %s" % [layout.resource_path, str(first)])
		for spot in spots:
			assert_true(RoomLayout.clear_of_the_plan_text(spot, station), "%s: %s sits on the plan's text" % [layout.resource_path, str(spot)])
		assert_true(maxi(absi(first.x - station.x), absi(first.y - station.y)) <= 4, "right beside the plan")


func test_the_plan_reward_spots_keep_off_the_wares() -> void:
	var layout := RoomLayout.new()
	layout.rows = PackedStringArray([
		"##############",
		"#............#",
		"#............#",
		"#...P........#",
		"#............#",
		"#....S.......#",
		"#............#",
		"##############"])
	var spots := layout.plan_reward_cells(2)
	assert_eq(spots.size(), 2)
	for spot in spots:
		assert_true(maxi(absi(spot.x - 5), absi(spot.y - 5)) >= RoomLayout.PICKUP_SPACING, "apart from the ware at 5,5: %s" % str(spot))
		assert_true(maxi(absi(spot.x - 4), absi(spot.y - 3)) >= RoomLayout.PICKUP_SPACING, "apart from the plan: %s" % str(spot))


func test_summons_never_land_on_the_plan_station() -> void:
	var layout := RoomLayout.new()
	layout.rows = PackedStringArray(["###", "#P.", "###"])
	assert_eq(layout.nearest_floor_cell(Vector2i(1, 1)), Vector2i(2, 1))


func test_a_discount_takes_its_share_off_and_never_goes_below_one() -> void:
	assert_eq(ShopRules.price_after(60, 0.0), 60)
	assert_eq(ShopRules.price_after(60, 0.15), 51)
	assert_eq(ShopRules.price_after(20, 0.15), 17)
	assert_eq(ShopRules.price_after(25, 0.15), 21)
	assert_eq(ShopRules.price_after(1, 0.5), 1)


func test_frequent_flyer_miles_cut_every_price_in_the_stock() -> void:
	var miles: UpgradeDef = load("res://data/upgrades/frequent_flyer_miles.tres")
	var upgrades: Array[UpgradeDef] = [miles]
	var run := RunState.new(upgrades, {miles.id: 3})
	var plain := ShopRules.stock(Content.items(), _run(), _rng())
	var cheap := ShopRules.stock(Content.items(), run, _rng())
	# Three levels and the milestone's Air Miles, which a missing choice reads as.
	assert_near(run.stats.shop_discount, 0.2)
	assert_eq(plain.size(), cheap.size())
	for i in plain.size():
		assert_eq(cheap[i]["price"], ShopRules.price_after(plain[i]["price"], 0.2), str(i))
		assert_true(cheap[i]["price"] < plain[i]["price"], str(i))


# --- Potion swap (playtest 10, note 4) ---

const SwapBank := preload("res://tests/support/stub_bank.gd")


func _swap_rig(pension: int) -> Dictionary:
	InputSetup.ensure()
	var room := FloorRoom.new()
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_COMBAT
	var rows := ["####################"]
	for y in range(1, 10):
		rows.append("#..................#")
	rows.append("####################")
	layout.rows = PackedStringArray(rows)
	room.layout = layout
	room.room_type = RoomLayout.TYPE_COMBAT
	var bank := SwapBank.new()
	bank.data.pension = pension
	var run := ItemKit.new().make_run()
	var player := Player.new()
	player.setup(run)
	var view := RoomView.new()
	view.setup(room, null, load("res://data/floors/floor_1.tres"), run, player, _rng(), null, bank)
	view._ready()
	return {"view": view, "run": run, "player": player, "bank": bank}


func _free_swap_rig(rig: Dictionary) -> void:
	for key in ["view", "player", "bank"]:
		rig[key].free()


func _floor_potions(view: RoomView) -> Array[Pickup]:
	var found: Array[Pickup] = []
	for child in view.get_children():
		if child is Pickup and child.carry_kind == RoomRules.DROP_POTION and not child.is_queued_for_deletion():
			found.append(child)
	return found


func test_a_floor_potion_with_an_empty_slot_is_taken_by_walking_as_before() -> void:
	var rig := _swap_rig(0)
	var view: RoomView = rig["view"]
	var run: RunState = rig["run"]
	var tea := Content.potion("swift_tea")
	var lying := view._drop_potion(Vector2(100, 100), tea)
	assert_false(lying.needs_press(), "no press with an empty slot")
	lying.collect()
	assert_eq(run.potion, tea)
	assert_eq(_floor_potions(view).size(), 0, "nothing is left lying")
	_free_swap_rig(rig)


func test_a_floor_potion_with_a_full_slot_needs_the_press_and_swaps() -> void:
	var rig := _swap_rig(0)
	var view: RoomView = rig["view"]
	var run: RunState = rig["run"]
	var tea := Content.potion("swift_tea")
	var tonic := Content.potion("healing_tonic")
	run.give_potion(tea)
	var lying := view._drop_potion(Vector2(100, 100), tonic)
	assert_true(lying.needs_press(), "a full slot waits for the press")
	assert_false(Pickup.should_collect(lying.needs_press(), true, false), "walking over it takes nothing")
	assert_true(Pickup.should_collect(lying.needs_press(), true, true))
	lying.collect()
	assert_eq(run.potion, tonic, "the lying one is carried now")
	var left := _floor_potions(view)
	assert_eq(left.size(), 1, "the old one lies where the new one lay")
	assert_eq(left[0].carry_id, tea.id)
	assert_eq(left[0].position, Vector2(100, 100))
	assert_true(left[0].needs_press(), "and obeys the same rule, so walking never swaps back")
	_free_swap_rig(rig)


func test_the_prompt_follows_the_slot_while_he_stands_there() -> void:
	var rig := _swap_rig(0)
	var view: RoomView = rig["view"]
	var run: RunState = rig["run"]
	var lying := view._drop_potion(Vector2(100, 100), Content.potion("healing_tonic"))
	assert_false(lying.needs_press())
	run.give_potion(Content.potion("swift_tea"))
	assert_true(lying.needs_press(), "the slot filled")
	run.potion = null
	assert_false(lying.needs_press(), "the slot emptied")
	_free_swap_rig(rig)


func test_a_laid_potion_survives_a_save_and_quit() -> void:
	var rig := _swap_rig(0)
	var view: RoomView = rig["view"]
	var run: RunState = rig["run"]
	var tea := Content.potion("swift_tea")
	run.give_potion(tea)
	view._drop_potion(Vector2(100, 100), Content.potion("healing_tonic")).collect()
	var shot: Dictionary = JSON.parse_string(JSON.stringify(view.snapshot()))
	var kept: Array = shot["keep"].filter(func(entry): return entry["kind"] == RoomView.KEEP_POTION)
	assert_eq(kept.size(), 1, "only the laid potion is kept, not the one taken")
	assert_eq(kept[0]["id"], tea.id)
	var back := _swap_rig(0)
	var again: RoomView = back["view"]
	again.restore = shot
	again._restore_contents()
	var left := _floor_potions(again)
	assert_eq(left.size(), 1)
	assert_eq(left[0].carry_id, tea.id)
	_free_swap_rig(rig)
	_free_swap_rig(back)


func _potion_entry(view: RoomView, id: String, price: int) -> Pickup:
	view._add_shop_entry(Vector2(200, 100), {"kind": ShopRules.KIND_POTION, "price": price, "item": null,
			"potion": Content.potion(id), "half": false})
	var ware: Pickup = null
	for child in view.get_children():
		if child is Pickup and child.requires_interact:
			ware = child
	return ware


func test_buying_a_shop_potion_with_one_carried_swaps_and_takes_the_price_once() -> void:
	var rig := _swap_rig(50)
	var view: RoomView = rig["view"]
	var run: RunState = rig["run"]
	var bank = rig["bank"]
	var tea := Content.potion("swift_tea")
	var tonic := Content.potion("healing_tonic")
	run.give_potion(tea)
	var ware := _potion_entry(view, tonic.id, 20)
	assert_true(ware.can_take.call(), "it can be bought with a potion carried")
	ware.collect()
	assert_eq(bank.data.pension, 30, "the price was taken once")
	assert_eq(run.potion, tonic)
	var left := _floor_potions(view)
	assert_eq(left.size(), 1)
	assert_eq(left[0].carry_id, tea.id, "the old potion lies on the ware's cell")
	assert_eq(left[0].position, Vector2(200, 100))
	assert_false(left[0].requires_interact, "it is not a ware")
	assert_true(left[0].get_meta(RoomView.KEEP)["kind"] == RoomView.KEEP_POTION, "it is free floor stock, not a priced ware")
	_free_swap_rig(rig)


func test_a_shop_potion_costs_nothing_when_it_would_give_nothing() -> void:
	var rig := _swap_rig(50)
	var view: RoomView = rig["view"]
	var run: RunState = rig["run"]
	var tonic := Content.potion("healing_tonic")
	run.give_potion(tonic)
	var ware := _potion_entry(view, tonic.id, 20)
	assert_false(ware.can_take.call(), "the same potion again gives nothing, so it is not for sale")
	var poor := _swap_rig(5)
	poor["run"].give_potion(Content.potion("swift_tea"))
	var dear := _potion_entry(poor["view"], tonic.id, 20)
	assert_false(dear.can_take.call(), "and Pension must still cover it")
	_free_swap_rig(rig)
	_free_swap_rig(poor)


func test_a_shop_potion_with_an_empty_slot_is_bought_as_before() -> void:
	var rig := _swap_rig(50)
	var view: RoomView = rig["view"]
	var run: RunState = rig["run"]
	var bank = rig["bank"]
	var tonic := Content.potion("healing_tonic")
	var ware := _potion_entry(view, tonic.id, 20)
	assert_true(ware.can_take.call())
	ware.collect()
	assert_eq(bank.data.pension, 30)
	assert_eq(run.potion, tonic)
	assert_eq(_floor_potions(view).size(), 0, "nothing to lay down")
	_free_swap_rig(rig)
