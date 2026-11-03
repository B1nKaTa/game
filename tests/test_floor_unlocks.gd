extends TestCase


func _old_save(clears: int) -> Dictionary:
	return {"version": ProgressData.VERSION, "pension": 0, "upgrades": {}, "opening_seen": true, "floors_cleared": clears}


func test_first_floor_clears_stay_in_floors_cleared() -> void:
	var data := ProgressData.new()
	data.record_floor_cleared(1, "floor_1")
	assert_eq(data.floors_cleared, 1)
	assert_eq(data.clears_at(1), 1)
	assert_eq(data.clears_at(2), 0)


func test_second_floor_clears_are_counted_apart() -> void:
	var data := ProgressData.new()
	data.record_floor_cleared(2, "sunset_shores")
	assert_eq(data.floors_cleared, 0, "a deeper clear never opens first-floor rules")
	assert_eq(data.clears_at(2), 1)
	assert_true(data.has_cleared_path("sunset_shores"))
	assert_false(data.has_cleared_path("furnace_works"))


func test_clears_and_paths_survive_a_save() -> void:
	var data := ProgressData.new()
	data.record_floor_cleared(2, "furnace_works")
	var loaded := ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))
	assert_eq(loaded.clears_at(2), 1)
	assert_true(loaded.has_cleared_path("furnace_works"))
	assert_eq(loaded.legacy_clears, 0, "a save written by this version is not an old one")


func test_an_old_save_freezes_its_clears_for_merchants() -> void:
	var loaded := ProgressData.from_dict(_old_save(3))
	assert_eq(loaded.legacy_clears, 3)
	assert_eq(loaded.clears_at(2), 0)
	loaded.record_floor_cleared(1, "floor_1")
	var again := ProgressData.from_dict(JSON.parse_string(JSON.stringify(loaded.to_dict())))
	assert_eq(again.legacy_clears, 3, "only the first load of an old save sets it")


func test_damaged_depth_fields_fall_back() -> void:
	var raw := _old_save(1)
	raw["deep_clears"] = {"2": -5, "3": 2}
	raw["paths_cleared"] = "not a set"
	raw["legacy_clears"] = -1
	var data := ProgressData.from_dict(raw)
	assert_true(data != null)
	assert_eq(data.clears_at(2), 0)
	assert_eq(data.clears_at(3), 2)
	assert_false(data.has_cleared_path("sunset_shores"))
	assert_eq(data.legacy_clears, 0)


func test_a_path_opens_on_the_clears_of_the_depth_it_names() -> void:
	var furnace := FloorDef.new()
	furnace.depth = 2
	furnace.open_after_depth = 2
	furnace.clears_to_open = 1
	var data := ProgressData.new()
	data.record_floor_cleared(1, "floor_1")
	assert_false(furnace.is_open_for(data))
	data.record_floor_cleared(2, "sunset_shores")
	assert_true(furnace.is_open_for(data))


func test_merchants_open_by_depth_by_paths_or_by_an_old_save() -> void:
	var murk := {"id": "potion_merchant", "depth": 2, "clears": 1, "legacy_clears": 1}
	var bernard := {"id": "bomb_merchant", "paths": ["sunset_shores", "furnace_works"], "legacy_clears": 3}
	var data := ProgressData.new()
	data.record_floor_cleared(1, "floor_1")
	assert_false(MerchantRules.is_open(murk, data), "a first-floor clear no longer opens her")
	data.record_floor_cleared(2, "sunset_shores")
	assert_true(MerchantRules.is_open(murk, data))
	assert_false(MerchantRules.is_open(bernard, data))
	data.record_floor_cleared(2, "furnace_works")
	assert_true(MerchantRules.is_open(bernard, data))
	var old := ProgressData.from_dict(_old_save(3))
	assert_true(MerchantRules.is_open(murk, old), "kept open from the old rules")
	assert_true(MerchantRules.is_open(bernard, old))
	assert_true(MerchantRules.is_open({"id": "black_market"}, ProgressData.new()), "no rule means always open")


func test_an_old_save_with_one_clear_keeps_only_murk() -> void:
	var old := ProgressData.from_dict(_old_save(1))
	var murk := {"id": "potion_merchant", "depth": 2, "clears": 1, "legacy_clears": 1}
	var bernard := {"id": "bomb_merchant", "paths": ["sunset_shores", "furnace_works"], "legacy_clears": 3}
	assert_true(MerchantRules.is_open(murk, old))
	assert_false(MerchantRules.is_open(bernard, old))
	assert_false(MerchantRules.is_open(murk, ProgressData.from_dict(_old_save(0))), "an old save with no clears opened nothing")
