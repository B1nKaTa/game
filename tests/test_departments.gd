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


func test_merchants_keep_their_rules_and_name_a_department() -> void:
	for entry: Dictionary in Departments.MERCHANTS:
		assert_true(Departments.index_of(entry["department"]) >= 0, entry["id"])
	assert_eq(MerchantRules.open_ones(Departments.MERCHANTS, _data()).map(func(e): return e["id"]), ["black_market", "optometrist"])


func test_the_loadout_bench_space_is_plain_floor() -> void:
	var back: RoomLayout = Departments.load_layouts()[Departments.BACK_ROOM]
	for cell in Departments.LOADOUT_BENCH_CELLS:
		assert_eq(back.symbol_at(cell), RoomLayout.SYMBOL_FLOOR, str(cell))
