extends TestCase

const FIXTURE := "res://tests/fixtures/save_v1_2026-11-04.json"


func _today() -> ProgressData:
	var json := JSON.new()
	assert_eq(json.parse(FileAccess.get_file_as_string(FIXTURE)), OK, "the fixture is valid JSON")
	return ProgressData.from_dict(json.data)


func test_a_save_in_todays_format_loads() -> void:
	var data := _today()
	assert_true(data != null, "loads")
	assert_eq(data.pension, 312)
	assert_eq(data.run_count, 23)
	assert_eq(data.brewed_potion, "swift_tea")


func test_bought_upgrades_carry_over() -> void:
	var data := _today()
	assert_eq(data.level_of("reinforced_cane"), 3)
	assert_eq(data.level_of("black_market_pills"), 2)
	assert_eq(data.level_of("denture_adhesive"), 0)


func test_new_fields_start_empty() -> void:
	var data := _today()
	assert_eq(data.condolences, 0)
	assert_eq(data.form_choices.size(), 0)
	assert_eq(data.bounty_taken, "")
	assert_false(data.cursed_next_run)
	assert_eq(data.ticket_called, 23, "no ticket event fires back-dated")


func test_a_round_trip_keeps_every_new_field() -> void:
	var data := _today()
	data.condolences = 7
	data.form_choices = {"reinforced_cane": "b"}
	data.bounty_taken = "regional_reaper"
	data.cosmetics_worn = {"hat": "flat_cap"}
	var again := ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))
	assert_eq(again.condolences, 7)
	assert_eq(again.form_choices["reinforced_cane"], "b")
	assert_eq(again.bounty_taken, "regional_reaper")
	assert_eq(again.cosmetics_worn["hat"], "flat_cap")


func test_a_save_from_before_paths_gets_its_first_paths() -> void:
	var raw := {"version": 1, "pension": 0, "upgrades": {}, "opening_seen": true, "floors_cleared": 2, "deep_clears": {"2": 1}}
	var data := ProgressData.from_dict(raw)
	assert_true(data.has_cleared_path("floor_1"))
	assert_true(data.has_cleared_path("sunset_shores"))
	assert_false(data.has_cleared_path("cemetery"), "a second first-floor clear may have been the same path")


func test_bad_new_fields_fall_back() -> void:
	var raw := {"version": 1, "pension": 0, "upgrades": {}, "opening_seen": true, "condolences": -5, "form_choices": {"reinforced_cane": "z"}, "bounty_taken": 3}
	var data := ProgressData.from_dict(raw)
	assert_eq(data.condolences, 0)
	assert_false(data.form_choices.has("reinforced_cane"), "only a or b is kept")
	assert_eq(data.bounty_taken, "")


func test_old_saves_open_the_departments_of_their_cleared_floors() -> void:
	var open := Departments.open_ids(_today())
	for id in [Departments.BOUNTY_OFFICE, Departments.TRAINING_YARD, Departments.APOTHECARY_WING, Departments.BOILER_ROOM, Departments.DECOR_OFFICE]:
		assert_true(open.has(id), id)
	assert_false(open.has(Departments.BACK_ROOM), "the Mall was never cleared")


func test_old_saves_hang_the_mementos_of_floors_already_cleared() -> void:
	assert_eq(Mementos.hung(_today()).size(), 5)


func test_old_saves_read_option_a_with_one_free_switch() -> void:
	var data := _today()
	for def in Content.upgrades():
		if data.level_of(def.id) >= def.milestone_level:
			assert_eq(data.choice_of(def), UpgradeDef.OPTION_A, def.id)
			assert_eq(data.refile_price(def), 0, def.id)
	assert_eq(data.choice_of(_find("better_knees")), "", "level 1 is below its milestone")


func _find(id: String) -> UpgradeDef:
	for def in Content.upgrades():
		if def.id == id:
			return def
	return null


func test_old_saves_receive_the_letters_of_floors_already_cleared() -> void:
	assert_eq(LetterBook.unread(_today()).size(), 5)


# The plaque's count is optional: an older save counts each path it cleared once, and a count survives.
func test_path_clears_fall_back_to_one_per_cleared_path_and_survive_a_save() -> void:
	var raw := {"version": 1, "pension": 0, "upgrades": {}, "opening_seen": true, "paths_cleared": {"head_office": true}}
	var data := ProgressData.from_dict(raw)
	assert_eq(data.clears_of_path("head_office"), 1)
	assert_eq(data.clears_of_path("terminal_zero"), 0)
	data.record_floor_cleared(5, "head_office")
	assert_eq(data.clears_of_path("head_office"), 2)
	var again := ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))
	assert_eq(again.clears_of_path("head_office"), 2)
	var fresh := ProgressData.new()
	fresh.record_floor_cleared(5, "head_office")
	assert_eq(fresh.clears_of_path("head_office"), 1, "a first clear counts once")


func test_the_ending_card_is_optional_and_remembered() -> void:
	var raw := {"version": 1, "pension": 0, "upgrades": {}, "opening_seen": true}
	assert_false(ProgressData.from_dict(raw).ending_seen, "an older save has not seen it")
	raw["ending_seen"] = "yes"
	assert_false(ProgressData.from_dict(raw).ending_seen, "a bad value falls back")
	var data := ProgressData.new()
	data.ending_seen = true
	assert_true(ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict()))).ending_seen)


func test_the_ending_card_shows_for_the_chairman_once() -> void:
	assert_true(EndingCard.is_due("chairman_of_the_board", false))
	assert_false(EndingCard.is_due("chairman_of_the_board", true), "only the first time")
	assert_false(EndingCard.is_due("augustine", false))
	var head_office: FloorDef = load("res://data/floors/head_office.tres")
	assert_eq(head_office.floor_boss.id, EndingCard.BOSS_ID)
	var source := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	var ending := source.substr(source.find("func _end_run"), 900)
	assert_true(ending.find("_show_ending_card()") < ending.find("Game.return_to_waiting()"), "before the Waiting Room")
