extends TestCase

# Saves and checkpoints from before the new list load cleanly: renamed ids become their new items, retired
# ones are left out, and a crafted item whose recipe left is paid back.


func _old_profile(extra: Dictionary) -> Dictionary:
	var raw := {"version": 1, "pension": 100, "upgrades": {}, "opening_seen": true}
	raw.merge(extra, true)
	return raw


func test_a_checkpoint_with_old_ids_resumes_with_their_new_items() -> void:
	var back := ItemKit.new().make_run()
	var raw := {"items": ["second_thermos_strap", "bingo_card", "hearing_aid", "tea_cosy"], "pills": 3, "max_pills": 4,
		"keys": 1, "bombs": 2, "effects": {"items": {"bingo_card": {"_count": 3}}}}
	RunCheckpoint.apply_run(back, raw, Content.items())
	var ids: Array = []
	for item in back.items:
		ids.append(item.id)
	assert_eq(ids, ["flask_holster", "tea_cosy"])
	assert_eq(back.active.id, "hearing_aid_feedback", "a renamed active goes to the active slot")
	assert_eq(back.bombs, 2, "a renamed item never pays its on_gain again")


func test_an_old_profile_maps_renamed_ids_and_refunds_a_retired_craft() -> void:
	var data := ProgressData.from_dict(_old_profile({
		"crafted_for_next_run": "golden_parachute",
		"recipes_found": {"rubber_stamps": true, "tea_cosy": true},
		"items_unlocked": {"rubber_stamps": true, "neck_pillow": true},
		"items_seen": {"penny_jar": 2},
	}))
	assert_true(data != null)
	assert_eq(data.pension, 210, "the parachute's 110 comes back")
	assert_eq(data.crafted_for_next_run, "")
	assert_true(data.recipes_found.has("rubber_stamp_collection"))
	assert_true(data.items_unlocked.has("rubber_stamp_collection"))
	assert_eq(int(data.items_seen.get("racing_pigeon", 0)), 2)


func test_a_crafted_kept_item_still_waits() -> void:
	var data := ProgressData.from_dict(_old_profile({"crafted_for_next_run": "rolling_pin"}))
	assert_eq(data.crafted_for_next_run, "rolling_pin")
	assert_eq(data.pension, 100)


func test_the_shipped_old_save_fixture_still_loads() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/save_v1_2026-11-04.json"))
	assert_true(ProgressData.from_dict(raw) != null)


func test_a_room_snapshot_skips_retired_items_and_maps_renamed_ones() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	var find := source.substr(source.find("func _item_by_id"), 400)
	assert_true(find.contains("RetiredContent.current_id("))


func test_a_retired_id_with_no_replacement_is_left_out_and_the_rest_of_the_run_stays() -> void:
	var back := ItemKit.new().make_run()
	var raw := {"items": ["banana_peel", "tea_cosy", "from_a_future_build", "wreath_of_thorns"], "pills": 3, "max_pills": 4,
		"keys": 2, "bombs": 1, "promised": ["bingo_card"], "offered": ["penny_jar"]}
	RunCheckpoint.apply_run(back, raw, Content.items())
	var ids: Array = []
	for item in back.items:
		ids.append(item.id)
	assert_eq(ids, ["tea_cosy", "cactus_brooch"])
	assert_eq(back.health.pills, 3)
	assert_eq(back.keys, 2)
	assert_eq(back.bombs, 1)


func test_a_retired_or_renamed_active_id_in_the_active_slot_is_handled() -> void:
	var back := ItemKit.new().make_run()
	RunCheckpoint.apply_run(back, {"items": [], "active": "hearing_aid", "active_charge": 1}, Content.items())
	assert_true(back.active != null and back.active.id == "hearing_aid_feedback")
	var other := ItemKit.new().make_run()
	RunCheckpoint.apply_run(other, {"items": [], "active": "banana_peel"}, Content.items())
	assert_true(other.active == null)


func test_a_checkpoint_that_recorded_a_formed_combo_loads() -> void:
	var back := ItemKit.new().make_run()
	var raw := {"items": ["bingo_card", "hearing_aid", "bifocals"], "pills": 3, "max_pills": 4,
		"effects": {"items": {}, "combos": {"bingo_night": {"_count": 2}}, "formed_sets": ["no_such_set"], "sets": {"x": {"a": 1}}}}
	RunCheckpoint.apply_run(back, raw, Content.items())
	assert_eq(back.health.pills, 3)
	assert_eq(back.effects.active_combos().size(), 0)
	assert_true(back.has_item("bifocals"))


func test_a_refund_is_paid_once_across_repeated_loads() -> void:
	var first := ProgressData.from_dict(_old_profile({"crafted_for_next_run": "alert_bracelet"}))
	assert_eq(first.pension, 200)
	var again := ProgressData.from_dict(JSON.parse_string(JSON.stringify(first.to_dict())))
	assert_eq(again.pension, 200, "the saved profile has no craft left to pay back")
	assert_eq(again.crafted_for_next_run, "")


func test_a_renamed_crafted_item_waits_as_its_new_item() -> void:
	var data := ProgressData.from_dict(_old_profile({"crafted_for_next_run": "rubber_stamps"}))
	assert_eq(data.crafted_for_next_run, "rubber_stamp_collection")
	assert_eq(data.pension, 100)


func test_a_profile_with_retired_history_loads_and_the_case_file_names_every_run_item() -> void:
	var data := ProgressData.from_dict(_old_profile({
		"items_seen": {"banana_peel": 3, "from_a_future_build": 1},
		"items_unlocked": {"banana_peel": true, "gravity_boots": true},
		"run_log": [{"n": 1, "result": "died", "items": ["banana_peel", "penny_jar", "bifocals"], "found": ["banana_peel", "bingo_card"]}],
	}))
	assert_true(data != null)
	assert_eq(data.run_log.size(), 1)
	var cells := CaseFileData.catalog(Content.items(), data.items_seen, null)
	for cell in cells:
		assert_true(cell["item"] != null)
	var names := CaseFileData.names_by_id(Content.all_items(), [])
	var lines := CaseFileData.log_detail(data.run_log[0], names)
	var text := "
".join(PackedStringArray(lines.map(func(l: Variant) -> String: return str(l))))
	assert_true(text.contains("Banana"), "a retired item shows its name: " + text)
