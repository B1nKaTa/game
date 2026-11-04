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
