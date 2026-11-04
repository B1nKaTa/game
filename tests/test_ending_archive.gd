extends TestCase

const FEUD_FOUND := {"eternal_feud": true}


func _data(found: Dictionary) -> ProgressData:
	var data := ProgressData.new()
	data.endings_found = found.duplicate()
	return data


func test_a_found_file_shows_its_number_title_and_cause() -> void:
	var data := _data({"literally": true})
	var row := EndingRules.archive_row(EndingRules.entry(EndingRules.LITERALLY), data)
	assert_eq(row, "27B-7  Back from the Dead (Literally).  Cause of death: pest control.")


func test_a_missing_file_shows_question_marks_and_its_hint() -> void:
	var row := EndingRules.archive_row(EndingRules.entry(EndingRules.SCENIC_ROUTE), _data({}))
	assert_eq(row, "27B-9  ???  Applicant took the long way round.")
	for entry: Dictionary in EndingRules.ALL:
		assert_false(str(entry["hint"]).is_empty(), "%s has a hint" % entry["id"])


func test_repeat_customer_counts_the_quick_deaths_seen() -> void:
	var data := _data({"repeat_customer": true, "eternal_feud": true})
	data.record_repeat_death(2)
	data.record_repeat_death(5)
	var row := EndingRules.archive_row(EndingRules.entry(EndingRules.REPEAT_CUSTOMER), data)
	assert_eq(row, "27B-11  Repeat Customer.  Quick deaths seen: 2/5.")


func test_the_archive_counts_found_files_out_of_eleven() -> void:
	assert_eq(EndingRules.found_line(_data({})), "Endings found: 0/11")
	assert_eq(EndingRules.found_line(_data({"briefly_alive": true, "repeat_customer": true, "nonsense": true})), "Endings found: 2/11")


func test_a_replay_of_repeat_customer_picks_a_death_already_seen() -> void:
	var data := _data({"repeat_customer": true})
	data.record_repeat_death(3)
	for roll: float in [0.0, 0.5, 0.99]:
		assert_eq(EndingRules.replay_death(data, roll), 3)
	data.record_repeat_death(1)
	assert_eq(EndingRules.replay_death(data, 0.0), 1)
	assert_eq(EndingRules.replay_death(data, 0.99), 3)
	var none := _data({"repeat_customer": true})
	var picked := EndingRules.replay_death(none, 0.4)
	assert_true(picked >= 1 and picked <= EndingRules.REPEAT_DEATHS, "any, when none were kept")


func test_the_archive_stands_in_the_executive_suite() -> void:
	var station := Departments.station_entry("ending_archive")
	assert_eq(station.get("department", ""), Departments.EXECUTIVE_SUITE)
	assert_eq(station.get("title", ""), "Ending Archive. Files 27B-1 to 27B-11")


func test_gerald_stands_in_the_lobby_only_after_the_true_ending() -> void:
	var entry := {}
	for npc: Dictionary in Departments.NPCS:
		if npc["id"] == "gerald":
			entry = npc
	assert_eq(entry.get("department", ""), Departments.LOBBY)
	assert_false(Departments.npc_stands(entry, _data({})))
	assert_false(Departments.npc_stands(entry, _data({"briefly_alive": true, "literally": true})))
	assert_true(Departments.npc_stands(entry, _data(FEUD_FOUND)))
	for npc: Dictionary in Departments.NPCS:
		if npc["id"] != "gerald":
			assert_true(Departments.npc_stands(npc, _data({})), npc["id"])


# The lobby is busy: Gerald keeps off the trophy frames' captions, the lanterns, the decor spots, the
# loadout bench, the run door and the row the east and west doors share.
func test_gerald_keeps_clear_of_everything_in_the_lobby() -> void:
	var cell := Vector2i(-1, -1)
	for npc: Dictionary in Departments.NPCS:
		if npc["id"] == "gerald":
			cell = npc["cell"]
	var lobby: RoomLayout = Departments.load_layouts()[Departments.LOBBY]
	assert_true(cell.y >= 3, "below the trophy captions and the HUD row")
	assert_true(cell.y != lobby.door_cell(RoomLayout.EAST).y, "off the way across")
	assert_false(Departments.LOADOUT_BENCH_CELLS.has(cell))
	assert_true(Vector2(cell).distance_to(Vector2(Departments.RUN_DOOR_CELL)) >= 3.0)
	for id in LobbyDecor.SPOTS:
		for spot: Vector2i in LobbyDecor.cells_of(id):
			assert_true(Vector2(cell).distance_to(Vector2(spot)) >= 2.0, "clear of %s" % id)
	assert_true(Vector2(cell).distance_to(Vector2(Player.arrival_position(Departments.RUN_DOOR_CELL + Vector2i.LEFT) / RoomBackdrop.TILE)) >= 3.0, "clear of where he arrives")


func test_geralds_lines_and_moments() -> void:
	var def: NpcDef = load("res://data/npcs/gerald.tres")
	assert_eq(def.id, "gerald")
	assert_true(def.lines.size() >= 12 and def.lines.size() <= 15, "%d lines" % def.lines.size())
	assert_false(def.moment(NpcDef.DIED).is_empty())
	assert_false(def.moment(NpcDef.BOSS_WIN).is_empty())
	assert_eq(def.look, "gerald", "drawn as Gerald, not as a shopkeeper")
	var font := ThemeDB.fallback_font
	for line in def.lines + [def.moment(NpcDef.DIED), def.moment(NpcDef.BOSS_WIN)]:
		assert_true(font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, Npc.FONT_SIZE).x <= 420.0, line)


func test_the_trophy_wall_counts_the_endings_found() -> void:
	var wall := TrophyWall.new()
	wall.setup(_data({"literally": true, "briefly_alive": true}))
	assert_eq(wall.endings_line(), "Endings found: 2/11")
	wall.free()
