extends TestCase

# Depths 4 and 5: their paths, locks, difficulty and landings. The four paths are placeholders that
# borrow the third floor's rooms, enemies and bosses until each is built, but their numbers are real.

const WEST := 0
const EAST := 1
# Each depth's paths, west then east, as floor_scene.gd's PATHS_BY_DEPTH lists them.
const PATHS := {
	4: ["last_resort_cruise", "fairways_end"],
	5: ["terminal_zero", "head_office"],
}
const NAMES := {
	"last_resort_cruise": "The Last Resort Cruise",
	"fairways_end": "Fairway's End Golf Club at Midnight",
	"terminal_zero": "Departures, Terminal Zero",
	"head_office": "Head Office, Eternity Incorporated",
}
const DANGER := {"last_resort_cruise": 5, "fairways_end": 6, "terminal_zero": 7, "head_office": 8}
const HINTS := {4: "Beat a fourth-floor boss first", 5: "Beat a fifth-floor boss first"}
const HEALTH_MULT := {4: 2.2, 5: 2.6}
const PENSION_MULT := {4: 2.5, 5: 3.5}
const ROOM_SIZES := {
	4: {"small": 7, "medium": 9, "large": 14},
	5: {"small": 8, "medium": 10, "large": 15},
}
const CHESTS := {
	4: {"lunchbox": 26, "locked": 22, "safe": 20, "urn": 16, "mimic": 16},
	5: {"lunchbox": 20, "locked": 20, "safe": 22, "urn": 19, "mimic": 19},
}
const TREASURE := {4: 20, 5: 24}


func _def(id: String) -> FloorDef:
	return load("res://data/floors/%s.tres" % id)


func test_each_west_path_is_open_on_arrival_and_each_east_path_waits_for_a_clear_at_its_depth() -> void:
	for depth: int in PATHS:
		var west := _def(PATHS[depth][WEST])
		var east := _def(PATHS[depth][EAST])
		var data := ProgressData.new()
		assert_true(west.is_open_for(data), west.id)
		assert_false(east.is_open_for(data), east.id)
		data.record_floor_cleared(depth - 1, ProgressData.FIRST_PATH_BY_DEPTH[depth - 1])
		assert_false(east.is_open_for(data), "a clear one depth up is not enough for %s" % east.id)
		data.record_floor_cleared(depth, west.id)
		assert_eq(data.clears_at(depth), 1)
		assert_true(east.is_open_for(data), east.id)
		assert_eq(east.closed_hint, HINTS[depth])
		assert_eq(east.open_after_depth, depth)
		assert_eq(east.clears_to_open, 1)
		assert_eq(west.open_after_depth, depth - 1)
		assert_eq(west.clears_to_open, 0)


func test_deep_clears_survive_a_save_and_an_old_save_has_none() -> void:
	var data := ProgressData.new()
	data.record_floor_cleared(4, "fairways_end")
	data.record_floor_cleared(5, "head_office")
	data.record_floor_cleared(5, "terminal_zero")
	var loaded := ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))
	assert_eq(loaded.clears_at(4), 1)
	assert_eq(loaded.clears_at(5), 2)
	for id in ["fairways_end", "head_office", "terminal_zero"]:
		assert_true(loaded.has_cleared_path(id), id)
	var old := ProgressData.from_dict({"version": ProgressData.VERSION, "pension": 0, "upgrades": {}, "opening_seen": true, "floors_cleared": 2, "deep_clears": {"2": 1, "3": 1}})
	assert_eq(old.clears_at(4), 0)
	assert_eq(old.clears_at(5), 0)


# An old save with a deep clear but no path ids counts the open path of that depth as the one cleared.
func test_a_deep_clear_without_path_ids_is_the_open_paths() -> void:
	var old := ProgressData.from_dict({"version": ProgressData.VERSION, "pension": 0, "upgrades": {}, "opening_seen": true, "floors_cleared": 1, "deep_clears": {"4": 1, "5": 1}})
	assert_true(old.has_cleared_path("last_resort_cruise"))
	assert_true(old.has_cleared_path("terminal_zero"))
	assert_false(old.has_cleared_path("fairways_end"))
	assert_false(old.has_cleared_path("head_office"))


func test_deep_difficulty_follows_the_spec() -> void:
	for depth: int in PATHS:
		for id: String in PATHS[depth]:
			var def := _def(id)
			assert_eq(def.depth, depth, id)
			assert_near(def.health_mult, HEALTH_MULT[depth], id)
			assert_near(def.pension_mult, PENSION_MULT[depth], id)
			assert_eq(def.enemies_by_size, ROOM_SIZES[depth], id)
			assert_eq(def.chest_weights, CHESTS[depth], id)
			assert_eq(def.treasure_pension, TREASURE[depth], id)
			assert_true(def.mimic != null, "%s rolls mimics" % id)
			assert_true(def.mini_boss != null and def.floor_boss != null, "%s has both bosses" % id)


func test_each_floor_is_harder_than_the_one_above() -> void:
	var third := _def("funeral_parlour")
	var fourth := _def("last_resort_cruise")
	var fifth := _def("terminal_zero")
	assert_true(fourth.health_mult > third.health_mult and fifth.health_mult > fourth.health_mult)
	assert_true(fourth.pension_mult > third.pension_mult and fifth.pension_mult > fourth.pension_mult)
	assert_true(float(fourth.chest_odds()[ChestRules.MIMIC]) > float(third.chest_odds()[ChestRules.MIMIC]))
	assert_true(float(fifth.chest_odds()[ChestRules.MIMIC]) > float(fourth.chest_odds()[ChestRules.MIMIC]))


func test_the_paths_have_their_names_ids_and_danger() -> void:
	for id: String in NAMES:
		var def := _def(id)
		assert_eq(def.id, id)
		assert_eq(def.display_name, NAMES[id])
		assert_eq(def.danger, DANGER[id], id)


func test_the_fourth_and_fifth_landings_name_their_floors() -> void:
	for depth in [4, 5]:
		var landing: FloorDef = load("res://data/floors/landing_%d.tres" % depth)
		assert_eq(landing.id, "landing_%d" % depth)
		assert_eq(landing.display_name, "Floor %d" % depth)
		assert_eq(landing.depth, depth)


# ProgressData must not load FloorDefs, so its lists mirror the scene's by id. The scene names
# autoloads and cannot be loaded here, so its source is read instead.
func test_the_save_rules_and_the_scene_list_the_same_paths() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	assert_true(source.contains("const LAST_DEPTH := 5"), "a floor-5 boss ends the run")
	for depth: int in PATHS:
		assert_eq(ProgressData.PATHS_AT_DEPTH[depth], PATHS[depth])
		assert_eq(ProgressData.FIRST_PATH_BY_DEPTH[depth], PATHS[depth][WEST])
		var listed := '%d: ["res://data/floors/%s.tres", "res://data/floors/%s.tres"]' % [depth, PATHS[depth][WEST], PATHS[depth][EAST]]
		assert_true(source.contains(listed), listed)
		assert_true(source.contains('%d: "res://data/floors/landing_%d.tres"' % [depth, depth]), "landing %d" % depth)
	assert_eq(ProgressData.PATHS_AT_DEPTH.size(), 5, "one entry per depth down to the last")


func test_deep_signs_show_one_skull_and_a_number() -> void:
	for id: String in DANGER:
		var def := _def(id)
		assert_eq(PathSign.skulls_for(def), DANGER[id])
		assert_eq(PathSign.skull_row_for(def), 1, id)
		assert_eq(PathSign.skull_number_for(def), "x%d" % DANGER[id])
	for id in ["floor_1", "cemetery", "funeral_parlour", "golden_years_mall"]:
		var shallow := _def(id)
		assert_eq(PathSign.skull_row_for(shallow), shallow.danger, "%s draws its skulls in a row" % id)
		assert_eq(PathSign.skull_number_for(shallow), "", id)
