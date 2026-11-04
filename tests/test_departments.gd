extends TestCase


func _data(paths: Array = []) -> ProgressData:
	var data := ProgressData.new()
	for id in paths:
		data.paths_cleared[id] = true
	return data


func test_every_layout_is_valid() -> void:
	var layouts := Departments.load_layouts()
	assert_eq(layouts.size(), Departments.ALL.size())
	for id in layouts:
		assert_eq((layouts[id] as RoomLayout).validate(), PackedStringArray(), id)


func test_a_fresh_save_opens_only_the_lobby_and_hallway() -> void:
	assert_eq(Departments.open_ids(_data()), [Departments.LOBBY, Departments.HALLWAY])


func test_each_department_opens_on_its_floors_first_clear() -> void:
	var cases := {"floor_1": Departments.BOUNTY_OFFICE, "cemetery": Departments.TRAINING_YARD, "sunset_shores": Departments.APOTHECARY_WING, "furnace_works": Departments.BOILER_ROOM, "funeral_parlour": Departments.DECOR_OFFICE, "golden_years_mall": Departments.BACK_ROOM}
	for path in cases:
		assert_true(Departments.is_open(cases[path], _data([path])), path)
		assert_eq(Departments.open_ids(_data([path])).size(), 3, "only one more opens for %s" % path)


func test_a_legacy_merchant_is_never_behind_a_closed_door() -> void:
	var data := _data()
	data.legacy_clears = 3
	assert_true(Departments.is_open(Departments.APOTHECARY_WING, data))
	assert_true(Departments.is_open(Departments.BOILER_ROOM, data))


func test_the_map_joins_every_department_and_each_is_reachable_on_its_own() -> void:
	var map := Departments.build_map(Departments.load_layouts())
	assert_eq(map.rooms.size(), Departments.ALL.size())
	assert_eq(map.start_id, Departments.index_of(Departments.LOBBY))
	# Opening any one department alone must never need another closed one: each path from the lobby
	# runs only through the lobby, the hallway and the department itself.
	var always := [Departments.index_of(Departments.LOBBY), Departments.index_of(Departments.HALLWAY)]
	for entry: Dictionary in Departments.ALL:
		var avoid: Array[int] = []
		for other: Dictionary in Departments.ALL:
			var other_id := Departments.index_of(other["id"])
			if other["id"] != entry["id"] and not always.has(other_id):
				avoid.append(other_id)
		assert_true(map.walk_from(map.start_id, avoid).has(Departments.index_of(entry["id"])), entry["id"])


func test_newly_opened_skips_seen_ones_and_the_always_open_rooms() -> void:
	var data := _data(["floor_1", "cemetery"])
	assert_eq(Departments.newly_opened(data), [Departments.BOUNTY_OFFICE, Departments.TRAINING_YARD])
	data.departments_seen[Departments.BOUNTY_OFFICE] = true
	assert_eq(Departments.newly_opened(data), [Departments.TRAINING_YARD])


func test_opening_news_comes_three_names_a_line_and_fits_the_notice() -> void:
	var data := _data(DevStart.ALL_PATHS)
	var lines := Departments.opening_notices(Departments.newly_opened(data))
	assert_eq(lines, [
		"New departments open: Bounty Office, Training Yard, Apothecary Wing.",
		"New departments open: Boiler Room, Decor Office, Back Room.",
	])
	for line in lines:
		var width := ThemeDB.fallback_font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		assert_true(width < 600.0, "%s is %d px" % [line, width])
	assert_eq(Departments.opening_notices([Departments.BOUNTY_OFFICE]), ["New departments open: Bounty Office."])
	assert_eq(Departments.opening_notices([]), [])


func test_merchants_keep_their_rules_and_name_a_department() -> void:
	for entry: Dictionary in Departments.MERCHANTS:
		assert_true(Departments.index_of(entry["department"]) >= 0, entry["id"])
	assert_eq(MerchantRules.open_ones(Departments.MERCHANTS, _data()).map(func(e): return e["id"]), ["black_market", "optometrist"])


func test_the_loadout_bench_space_is_plain_floor() -> void:
	var back: RoomLayout = Departments.load_layouts()[Departments.BACK_ROOM]
	for cell in Departments.LOADOUT_BENCH_CELLS:
		assert_eq(back.symbol_at(cell), RoomLayout.SYMBOL_FLOOR, str(cell))


func test_stations_stand_on_open_floor_clear_of_doors_and_each_other() -> void:
	var layouts := Departments.load_layouts()
	var all: Array = Departments.MERCHANTS.duplicate()
	all.append_array(Departments.STATIONS)
	var taken := {}
	for entry: Dictionary in all:
		var layout: RoomLayout = layouts[entry["department"]]
		var cell: Vector2i = entry["cell"]
		assert_eq(layout.symbol_at(cell), RoomLayout.SYMBOL_FLOOR, "%s on floor" % entry["id"])
		for side in RoomLayout.SIDES:
			assert_true(Vector2(cell).distance_to(Vector2(layout.door_cell(side))) >= 3.0, "%s clear of doors" % entry["id"])
		var key := "%s %s" % [entry["department"], str(cell)]
		assert_false(taken.has(key), "%s shares a cell" % entry["id"])
		taken[key] = true
		assert_true(cell.y >= RoomLayout.UNDER_THE_HUD + 1, "%s clear of the HUD row" % entry["id"])


func test_a_closed_department_says_what_opens_it() -> void:
	assert_eq(Departments.closed_hint(Departments.BOUNTY_OFFICE), "Opens when The Records Basement is cleared")


func test_the_run_door_stands_on_lobby_floor_off_the_way_across() -> void:
	var lobby: RoomLayout = Departments.load_layouts()[Departments.LOBBY]
	assert_eq(lobby.symbol_at(Departments.RUN_DOOR_CELL), RoomLayout.SYMBOL_FLOOR)
	for side in RoomLayout.SIDES:
		assert_true(Vector2(Departments.RUN_DOOR_CELL).distance_to(Vector2(lobby.door_cell(side))) >= 3.0, str(side))
	assert_true(Departments.RUN_DOOR_CELL.y != lobby.door_cell(RoomLayout.EAST).y, "not on the row between the east and west doors")


func test_a_sign_keeps_its_text_inside_the_room() -> void:
	assert_near(DepartmentSign.text_left(100.0, 40.0, 32.0, 600.0), 80.0)
	assert_near(DepartmentSign.text_left(48.0, 200.0, 32.0, 600.0), 32.0)
	assert_near(DepartmentSign.text_left(590.0, 100.0, 32.0, 608.0), 508.0)


func test_npcs_stand_on_open_floor_clear_of_doors_and_stations() -> void:
	var layouts := Departments.load_layouts()
	var taken := {}
	for entry: Dictionary in Departments.STATIONS:
		taken["%s %s" % [entry["department"], str(entry["cell"])]] = true
	for entry: Dictionary in Departments.NPCS:
		var layout: RoomLayout = layouts[entry["department"]]
		var cell: Vector2i = entry["cell"]
		assert_eq(layout.symbol_at(cell), RoomLayout.SYMBOL_FLOOR, "%s on floor" % entry["id"])
		for side in RoomLayout.SIDES:
			assert_true(Vector2(cell).distance_to(Vector2(layout.door_cell(side))) >= 3.0, "%s clear of doors" % entry["id"])
		assert_false(taken.has("%s %s" % [entry["department"], str(cell)]), "%s shares a cell" % entry["id"])
		assert_true(load(entry["def"]) is NpcDef, entry["id"])
