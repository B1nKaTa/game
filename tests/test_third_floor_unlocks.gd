extends TestCase


func _parlour() -> FloorDef:
	return load("res://data/floors/funeral_parlour.tres")


func _mall() -> FloorDef:
	return load("res://data/floors/golden_years_mall.tres")


func test_the_parlour_is_always_open_and_the_mall_waits_for_a_third_floor_clear() -> void:
	var data := ProgressData.new()
	assert_true(_parlour().is_open_for(data))
	assert_false(_mall().is_open_for(data))
	data.record_floor_cleared(2, "sunset_shores")
	assert_false(_mall().is_open_for(data), "a second-floor clear is not enough")
	data.record_floor_cleared(3, "funeral_parlour")
	assert_eq(data.clears_at(3), 1)
	assert_true(_mall().is_open_for(data))
	assert_eq(_mall().closed_hint, "Beat a third-floor boss first")


func test_third_floor_clears_survive_a_save_and_an_old_save_has_none() -> void:
	var data := ProgressData.new()
	data.record_floor_cleared(3, "golden_years_mall")
	var loaded := ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))
	assert_eq(loaded.clears_at(3), 1)
	assert_true(loaded.has_cleared_path("golden_years_mall"))
	var old := ProgressData.from_dict({"version": ProgressData.VERSION, "pension": 0, "upgrades": {}, "opening_seen": true, "floors_cleared": 2})
	assert_eq(old.clears_at(3), 0)


func test_third_floor_difficulty_follows_the_spec() -> void:
	for def: FloorDef in [_parlour(), _mall()]:
		assert_eq(def.depth, 3)
		assert_near(def.health_mult, 1.8)
		assert_near(def.pension_mult, 2.0)
		assert_eq(def.enemies_by_size, {"small": 6, "medium": 8, "large": 13})
		assert_true(float(def.chest_odds()[ChestRules.MIMIC]) >= 13.0)


func test_the_third_landing_names_floor_3() -> void:
	var landing: FloorDef = load("res://data/floors/landing_3.tres")
	assert_eq(landing.display_name, "Floor 3")
	assert_eq(landing.depth, 3)


func test_the_paths_have_their_names_and_ids() -> void:
	assert_eq(_parlour().id, "funeral_parlour")
	assert_eq(_parlour().display_name, "Eternal Rest Funeral Parlour")
	assert_eq(_parlour().danger, 3)
	assert_eq(_mall().id, "golden_years_mall")
	assert_eq(_mall().display_name, "Golden Years Mall at 7 a.m.")
	assert_eq(_mall().danger, 4)
	assert_eq(_mall().open_after_depth, 3)
