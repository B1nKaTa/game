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


func test_a_fresh_save_opens_only_the_lobby_and_the_corridors() -> void:
	assert_eq(Departments.open_ids(_data()), [Departments.LOBBY, Departments.HALLWAY, Departments.ANNEXE, Departments.UPPER_LANDING])
	assert_eq(Departments.corridor_ids(), Departments.open_ids(_data()))


func test_each_department_opens_on_its_floors_first_clear() -> void:
	var cases := {"floor_1": Departments.BOUNTY_OFFICE, "cemetery": Departments.TRAINING_YARD, "sunset_shores": Departments.APOTHECARY_WING, "furnace_works": Departments.BOILER_ROOM, "funeral_parlour": Departments.DECOR_OFFICE, "golden_years_mall": Departments.BACK_ROOM,
		"last_resort_cruise": Departments.PURSERS_OFFICE, "fairways_end": Departments.PRO_SHOP, "terminal_zero": Departments.DUTY_FREE, "head_office": Departments.EXECUTIVE_SUITE}
	assert_eq(cases.size(), Departments.ALL.size() - Departments.corridor_ids().size(), "every department that opens is here")
	for path in cases:
		assert_true(Departments.is_open(cases[path], _data([path])), path)
		assert_eq(Departments.open_ids(_data([path])).size(), Departments.corridor_ids().size() + 1, "only one more opens for %s" % path)
		assert_false(Departments.closed_hint(cases[path]).contains("a floor"), "%s names its floor" % path)


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
	# runs only through the lobby, the corridors, the department itself and the annexe's gate, which
	# every save opens first (test_the_annexe_gate_opens_before_anything_else).
	var always: Array[int] = [Departments.index_of(Departments.ANNEXE_GATE)]
	for id in Departments.corridor_ids():
		always.append(Departments.index_of(id))
	for entry: Dictionary in Departments.ALL:
		var avoid: Array[int] = []
		for other: Dictionary in Departments.ALL:
			var other_id := Departments.index_of(other["id"])
			if other["id"] != entry["id"] and not always.has(other_id):
				avoid.append(other_id)
		assert_true(map.walk_from(map.start_id, avoid).has(Departments.index_of(entry["id"])), entry["id"])


# The Records Basement is the one path open before any clear, so the gate's floor is cleared first in
# every save, and the annexe is open by the time any of its departments can be.
func test_the_annexe_gate_opens_before_anything_else() -> void:
	assert_eq(Departments.entry(Departments.ANNEXE_GATE)["opens_on"], ProgressData.FIRST_PATH_BY_DEPTH[1])
	var map := Departments.build_map(Departments.load_layouts())
	var annexe := map.room(Departments.index_of(Departments.ANNEXE))
	assert_true(annexe.doors.values().has(Departments.index_of(Departments.ANNEXE_GATE)), "the annexe's door is in the gate")
	for id in [Departments.PURSERS_OFFICE, Departments.PRO_SHOP, Departments.DUTY_FREE, Departments.EXECUTIVE_SUITE]:
		var opens_on: String = Departments.entry(id)["opens_on"]
		assert_false(ProgressData.PATHS_AT_DEPTH[1].has(opens_on), "%s opens on a deeper floor" % id)


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
		"New departments open: Purser's Office, Pro Shop, Duty Free.",
		"New departments open: Executive Suite.",
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


# A keeper stands far enough from his counter that no spot is in reach of both, so one press never
# both opens the counter and talks.
func test_a_keeper_stands_out_of_reach_of_every_counter_in_his_department() -> void:
	var counters: Array = Departments.MERCHANTS.duplicate()
	counters.append_array(Departments.STATIONS)
	for npc: Dictionary in Departments.NPCS:
		for counter: Dictionary in counters:
			if counter["department"] != npc["department"]:
				continue
			var apart := RoomBackdrop.cell_center(npc["cell"]).distance_to(RoomBackdrop.cell_center(counter["cell"]))
			assert_true(apart > WaitingStation.USE_RADIUS + Npc.TALK_RADIUS, "%s and %s" % [npc["id"], counter["id"]])


func test_the_deep_floors_counters_open_on_their_own_floors() -> void:
	var cases := {"pro_shop": "fairways_end", "duty_free": "terminal_zero", "severance_desk": "head_office"}
	for id in cases:
		var merchant := Departments.merchant_entry(id)
		assert_false(merchant.is_empty(), id)
		assert_false(MerchantRules.is_open(merchant, _data()), "%s waits" % id)
		assert_true(MerchantRules.is_open(merchant, _data([cases[id]])), "%s opens" % id)
		assert_eq(Departments.entry(merchant["department"])["opens_on"], cases[id], "%s stands in its floor's department" % id)


func test_the_plaque_counts_head_office_clears() -> void:
	assert_true(Departments.plaque_text(0).contains("vacant"))
	assert_true(Departments.plaque_text(1).contains("once"))
	assert_true(Departments.plaque_text(3).contains("3 times"))
	var data := _data()
	data.record_floor_cleared(5, "head_office")
	data.record_floor_cleared(5, "head_office")
	assert_eq(data.clears_of_path("head_office"), 2)
