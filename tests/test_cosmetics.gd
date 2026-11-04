extends TestCase


func _cosmetic(id: String) -> CosmeticDef:
	for def in CosmeticDef.all():
		if def.id == id:
			return def
	return null


func test_the_set_is_complete_and_every_bounty_cosmetic_exists() -> void:
	assert_eq(CosmeticDef.all().size(), 16)
	for poster in BountyBoard.all():
		if poster.extra_kind == BountyDef.EXTRA_COSMETIC:
			var def := _cosmetic(poster.extra_id)
			assert_true(def != null, poster.extra_id)
			if def != null:
				assert_eq(def.price, 0, "%s is never sold" % poster.extra_id)
				assert_true(def.slot != CosmeticDef.SLOT_DECOR, "%s is worn" % poster.extra_id)


func test_only_the_bounty_cosmetics_are_never_sold() -> void:
	var never_sold := []
	for def in CosmeticDef.all():
		if not def.is_sold():
			never_sold.append(def.id)
	never_sold.sort()
	assert_eq(never_sold, ["bingo_teal", "fountain_tiara", "reaper_hood", "sooty_cane"])


func test_condolences_buy_and_bounty_ones_are_never_for_sale() -> void:
	var data := ProgressData.new()
	data.condolences = 100
	assert_true(data.buy_cosmetic(_cosmetic("flat_cap")))
	assert_eq(data.condolences, 70)
	assert_false(data.buy_cosmetic(_cosmetic("flat_cap")), "owned already")
	assert_false(data.buy_cosmetic(_cosmetic("reaper_hood")))
	assert_eq(data.condolences, 70)


func test_a_purchase_needs_enough_condolences() -> void:
	var data := ProgressData.new()
	data.condolences = 59
	assert_false(data.buy_cosmetic(_cosmetic("fish_tank")))
	assert_eq(data.condolences, 59)
	assert_false(data.owns_cosmetic("fish_tank"))


func test_one_worn_per_slot_and_decor_is_never_worn() -> void:
	var data := ProgressData.new()
	data.cosmetics_owned = {"flat_cap": true, "party_hat": true, "potted_fern": true}
	assert_true(data.wear(_cosmetic("flat_cap")))
	assert_true(data.wear(_cosmetic("party_hat")))
	assert_eq(data.cosmetics_worn, {CosmeticDef.SLOT_HAT: "party_hat"})
	assert_false(data.wear(_cosmetic("potted_fern")))
	assert_false(data.wear(_cosmetic("candy_stripe")), "not owned")
	data.take_off(CosmeticDef.SLOT_HAT)
	assert_eq(data.cosmetics_worn, {})


func test_cosmetics_carry_no_stats() -> void:
	# Condolences buy looks only. CosmeticDef is not a StatEffect, so nothing can add it to the stats.
	var made: Variant = CosmeticDef.new()
	assert_false(made is StatEffect)


func test_every_decor_item_has_a_spot_on_lobby_floor_clear_of_stations() -> void:
	var lobby: RoomLayout = Departments.load_layouts()[Departments.LOBBY]
	var station_cells := []
	var stations: Array = Departments.MERCHANTS.duplicate()
	stations.append_array(Departments.STATIONS)
	for entry: Dictionary in stations:
		if entry["department"] == Departments.LOBBY:
			station_cells.append(entry["cell"])
	for def in CosmeticDef.all():
		if def.slot != CosmeticDef.SLOT_DECOR or def.id == LobbyDecor.CARPET:
			continue
		assert_false(LobbyDecor.cells_of(def.id).is_empty(), "%s has a spot" % def.id)
		for cell: Vector2i in LobbyDecor.cells_of(def.id):
			assert_false(station_cells.has(cell), def.id)
			assert_true(cell.x > 0 and cell.x < lobby.size_in_cells().x - 1, def.id)
			assert_true(cell.y > 0 and cell.y < lobby.size_in_cells().y - 1, def.id)
			assert_eq(lobby.symbol_at(cell), RoomLayout.SYMBOL_FLOOR, "%s on floor" % def.id)
			assert_true(cell != Departments.RUN_DOOR_CELL, "%s off the run door" % def.id)
			for side in RoomLayout.SIDES:
				assert_true(cell != lobby.door_cell(side), "%s off a door cell" % def.id)


func test_the_decor_counter_stands_in_the_decor_office() -> void:
	var entry := Departments.station_entry("decor_counter")
	assert_eq(entry.get("department", ""), Departments.DECOR_OFFICE)


func test_the_panel_buttons_say_what_a_press_does() -> void:
	var data := ProgressData.new()
	assert_eq(DecorPanel.decor_button_text(_cosmetic("potted_fern"), data), "Buy (20 Condolences)")
	assert_eq(DecorPanel.look_button_text(_cosmetic("flat_cap"), data), "Buy (30)")
	assert_eq(DecorPanel.look_button_text(_cosmetic("reaper_hood"), data), DecorPanel.BOUNTY_REWARD)
	data.cosmetics_owned = {"potted_fern": true, "flat_cap": true, "reaper_hood": true}
	assert_eq(DecorPanel.decor_button_text(_cosmetic("potted_fern"), data), DecorPanel.PLACED)
	assert_eq(DecorPanel.look_button_text(_cosmetic("flat_cap"), data), DecorPanel.WEAR)
	data.wear(_cosmetic("reaper_hood"))
	assert_eq(DecorPanel.look_button_text(_cosmetic("reaper_hood"), data), DecorPanel.TAKE_OFF)


func test_the_two_tabs_split_decor_from_looks() -> void:
	var defs := CosmeticDef.all()
	assert_eq(DecorPanel.rows_for(defs, true).size(), 6)
	var looks := DecorPanel.rows_for(defs, false)
	assert_eq(looks.size(), 10)
	assert_eq(looks[0].slot, CosmeticDef.SLOT_HAT)
	assert_eq(looks[looks.size() - 1].slot, CosmeticDef.SLOT_CANE)
