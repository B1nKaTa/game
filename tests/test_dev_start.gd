extends TestCase

const PROGRESS_SCRIPT := preload("res://scripts/autoload/progress.gd")
const REAL_PATH := "user://test_dev_real_save.json"
const DEV_PATH := "user://test_dev_run_save.json"


func _dev_data() -> ProgressData:
	return DevStart.progress(Content.upgrades(), Content.recipes())


# A Progress of its own, outside the tree, whose "real" save is a test file.
func _progress_with_real_save(real: ProgressData) -> Node:
	var store := SaveStore.new(REAL_PATH)
	store.delete_all()
	store.save_progress(real)
	var progress: Node = PROGRESS_SCRIPT.new()
	progress._store = store
	progress.data = store.load_progress()
	return progress


func _real_save_text() -> String:
	return FileAccess.get_file_as_string(REAL_PATH)


func test_the_shortcut_exists_only_in_debug_builds() -> void:
	assert_true(DevStart.allowed(true))
	assert_false(DevStart.allowed(false), "a release export never offers it")
	assert_eq(DevStart.is_available(), OS.is_debug_build())


func test_every_upgrade_is_at_its_top_level() -> void:
	var data := _dev_data()
	var upgrades := Content.upgrades()
	assert_true(upgrades.size() >= 7)
	for def in upgrades:
		assert_eq(data.level_of(def.id), def.max_level(), def.id)
		assert_false(data.can_buy(def), "%s has nothing left to buy" % def.id)
	for id in ["denture_adhesive", "thermos_fuel", "prescription_glasses"]:
		assert_true(data.level_of(id) > 0, id)


func test_the_loadout_makes_a_strong_grandpa() -> void:
	var data := _dev_data()
	var run := RunState.new(Content.upgrades(), data.upgrades)
	var fresh := RunState.new(Content.upgrades(), {})
	assert_true(run.stats.max_pills > fresh.stats.max_pills, "bought pills raise his maximum")
	DevStart.apply_kit(run, Content.items())
	assert_eq(run.keys, DevStart.KEYS)
	assert_eq(run.bombs, DevStart.BOMBS)
	for id: String in DevStart.ITEMS:
		assert_true(run.has_item(id), id)
	assert_eq(run.health.pills, run.health.max_pills, "he starts with every pill")
	assert_eq(data.brewed_potion, DevStart.BREWED_POTION)
	assert_true(Content.potion(DevStart.BREWED_POTION) != null)
	assert_eq(data.pension, DevStart.PENSION)


func test_earlier_floors_count_as_cleared_and_both_third_floor_paths_open() -> void:
	var data := _dev_data()
	assert_eq(data.clears_at(1), 2)
	assert_eq(data.clears_at(2), 2)
	assert_eq(data.clears_at(3), 1)
	for path in ["floor_1", "cemetery", "sunset_shores", "furnace_works"]:
		assert_true(data.has_cleared_path(path), path)
	for path in ["res://data/floors/funeral_parlour.tres", "res://data/floors/golden_years_mall.tres"]:
		var def: FloorDef = load(path)
		assert_eq(def.depth, DevStart.START_DEPTH)
		assert_true(def.is_open_for(data), path)
	for item in Content.recipes():
		assert_true(data.is_unlocked(item.id), item.id)


# F3, F5 and F6 start at floors 3, 4 and 5. F4 stays the dev Waiting Room's.
func test_each_start_key_names_its_depth() -> void:
	assert_eq(DevStart.depth_for_key(KEY_F3), 3)
	assert_eq(DevStart.depth_for_key(KEY_F5), 4)
	assert_eq(DevStart.depth_for_key(KEY_F6), 5)
	assert_eq(DevStart.depth_for_key(KEY_F4), 0, "F4 starts no run")
	assert_eq(DevStart.depth_for_key(KEY_F7), 0)
	assert_eq(DevStart.START_DEPTH, 3, "F3 and the dev Waiting Room's run door still start at floor 3")
	assert_eq(DevStart.depth_for_key(KEY_F3), DevStart.START_DEPTH)


# A deeper start counts every path above it cleared and its own open path once, so both its paths
# are open, and nothing below it is counted.
func test_a_deeper_start_opens_both_paths_of_its_depth_with_every_upgrade_bought() -> void:
	for start_depth in [4, 5]:
		var data := DevStart.progress(Content.upgrades(), Content.recipes(), false, start_depth)
		for def in Content.upgrades():
			assert_eq(data.level_of(def.id), def.max_level(), "%s at depth %d" % [def.id, start_depth])
		assert_eq(data.clears_at(1), 2)
		for depth in range(2, start_depth):
			assert_eq(data.clears_at(depth), 2, "both paths of depth %d" % depth)
			for id: String in ProgressData.PATHS_AT_DEPTH[depth]:
				assert_true(data.has_cleared_path(id), id)
		assert_eq(data.clears_at(start_depth), 1)
		assert_true(data.has_cleared_path(ProgressData.FIRST_PATH_BY_DEPTH[start_depth]))
		assert_false(data.has_cleared_path(ProgressData.PATHS_AT_DEPTH[start_depth][1]), "the locked path is open, not cleared")
		for depth in range(start_depth + 1, 6):
			assert_eq(data.clears_at(depth), 0, "nothing below the start, depth %d" % depth)
		for id: String in ProgressData.PATHS_AT_DEPTH[start_depth]:
			var def: FloorDef = load("res://data/floors/%s.tres" % id)
			assert_eq(def.depth, start_depth)
			assert_true(def.is_open_for(data), id)


func test_the_floor_3_profile_is_as_it_was() -> void:
	assert_eq(DevStart.clears_by_depth(), {1: 2, 2: 2, 3: 1})
	assert_eq(", ".join(DevStart.paths_cleared()), "floor_1, cemetery, sunset_shores, furnace_works, funeral_parlour")


# The start depth rides on Progress for the run's scene and falls back to floor 3 when the run ends.
func test_progress_carries_the_start_depth_only_while_the_dev_run_lasts() -> void:
	var progress := _progress_with_real_save(ProgressData.new())
	assert_eq(progress.dev_start_depth, DevStart.START_DEPTH)
	progress.begin_dev_run(DevStart.progress(Content.upgrades(), Content.recipes(), false, 5), DEV_PATH, 5)
	assert_eq(progress.dev_start_depth, 5)
	progress.end_dev_run()
	assert_eq(progress.dev_start_depth, DevStart.START_DEPTH)
	progress.begin_dev_run(_waiting_data(), DEV_PATH)
	assert_eq(progress.dev_start_depth, DevStart.START_DEPTH, "the dev Waiting Room's run door starts at floor 3")
	progress.end_dev_run()
	progress.free()
	SaveStore.new(REAL_PATH).delete_all()


# The scene starts a dev run at the depth Progress carries, and the Waiting Room reads every start key.
func test_the_scene_and_the_waiting_room_use_the_chosen_depth() -> void:
	var scene := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	assert_true(scene.contains("_depth = Progress.dev_start_depth"))
	var room := FileAccess.get_file_as_string("res://scripts/scenes/waiting_room.gd")
	assert_true(room.contains("DevStart.depth_for_key(key.physical_keycode)"))
	var game := FileAccess.get_file_as_string("res://scripts/autoload/game.gd")
	var begin := game.substr(game.find("func begin_dev_run"), 120)
	assert_true(begin.contains("if not DevStart.is_available():"), "Game checks the gate first")


func _waiting_data() -> ProgressData:
	return DevStart.progress(Content.upgrades(), Content.recipes(), true)


func test_the_dev_waiting_room_profile_opens_every_department() -> void:
	var data := _waiting_data()
	for id in ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "golden_years_mall"]:
		assert_true(data.has_cleared_path(id), id)
	for each: Dictionary in Departments.ALL:
		assert_true(Departments.is_open(each["id"], data), each["id"])
	assert_eq(data.clears_at(3), _dev_data().clears_at(3), "only path ids are added, not clears")
	assert_false(_dev_data().has_cleared_path("golden_years_mall"), "the Floor 3 run's profile leaves the Mall uncleared")
	assert_true(PROGRESS_SCRIPT.DEV_PATH != PROGRESS_SCRIPT.SAVE_PATH, "the dev profile has its own file")


func test_the_dev_waiting_room_has_its_own_key_and_hint() -> void:
	assert_false(DevStart.START_KEYS.has(DevStart.WAITING_KEY), "F3, F5 and F6 still start their runs")
	assert_false(DevStart.WAITING_HINT.is_empty())
	assert_false(DevStart.WAITING_HINT_ON.is_empty())
	assert_eq(DevStart.PROFILE_LABEL, "DEV PROFILE")


# Release exports are not debug builds, and both ways in check the gate before anything else.
func test_the_dev_waiting_room_is_gated_on_debug_builds() -> void:
	assert_false(DevStart.allowed(false))
	var game := FileAccess.get_file_as_string("res://scripts/autoload/game.gd")
	var toggle := game.substr(game.find("func toggle_dev_waiting_room"), 120)
	assert_true(toggle.contains("if not DevStart.is_available():"), "Game checks the gate first")
	var scene := FileAccess.get_file_as_string("res://scripts/scenes/waiting_room.gd")
	var keys := scene.substr(scene.find("func _unhandled_input"), 120)
	assert_true(keys.contains("if not DevStart.is_available()"), "the Waiting Room checks the gate before reading F4")


# Every way the Waiting Room's panels and arrival can touch the save, done under the dev profile.
func _use_the_waiting_room(progress: Node) -> void:
	progress.add_pension(500)
	progress.spend(20)
	progress.buy(Content.upgrades()[0])
	progress.refile(Content.upgrades()[0])
	progress.add_condolences(30)
	progress.spend_condolences(5)
	progress.mark_departments_seen(["back_room", "decor_office"])
	progress.mark_coach_met()
	progress.read_letter("floor_1")
	progress.retirement_deposit(50)
	progress.take_brewed_potion()
	progress.call_ticket()


func test_the_dev_waiting_room_never_writes_the_real_save() -> void:
	var real := ProgressData.new()
	real.pension = 17
	real.condolences = 4
	real.opening_seen = true
	var progress := _progress_with_real_save(real)
	var before := _real_save_text()
	var kept: Dictionary = progress.data.to_dict().duplicate(true)
	progress.begin_dev_run(_waiting_data(), DEV_PATH)
	assert_true(progress.is_dev_run())
	_use_the_waiting_room(progress)
	assert_eq(_real_save_text(), before, "the real save is untouched while the dev Waiting Room is on")
	# F4 again ends it, as Game.toggle_dev_waiting_room does.
	progress.end_dev_run()
	assert_false(progress.is_dev_run())
	assert_eq(_real_save_text(), before, "the real save is untouched after leaving")
	assert_false(FileAccess.file_exists(DEV_PATH), "the dev file is thrown away")
	assert_eq(progress.data.to_dict(), kept, "the real progress is back exactly as it was")
	assert_eq(progress.data.pension, 17, "Pension earned or spent there is thrown away")
	assert_eq(progress.data.condolences, 4, "Condolences earned or spent there are thrown away")
	progress.free()
	SaveStore.new(REAL_PATH).delete_all()


# F3 in the dev Waiting Room swaps its profile for the Floor 3 run's, and that run ends on return.
func test_starting_the_floor_3_run_from_the_dev_waiting_room_keeps_the_real_progress() -> void:
	var real := ProgressData.new()
	real.pension = 17
	var progress := _progress_with_real_save(real)
	var before := _real_save_text()
	var kept: Dictionary = progress.data.to_dict().duplicate(true)
	progress.begin_dev_run(_waiting_data(), DEV_PATH)
	progress.add_pension(40)
	progress.begin_dev_run(_dev_data(), DEV_PATH)
	assert_true(progress.is_dev_run())
	assert_false(progress.data.has_cleared_path("golden_years_mall"), "the Floor 3 run's own profile")
	progress.start_run()
	progress.end_dev_run()
	assert_eq(_real_save_text(), before)
	assert_eq(progress.data.to_dict(), kept, "the real progress waited, not the dev Waiting Room's")
	progress.free()
	SaveStore.new(REAL_PATH).delete_all()


func test_quitting_ends_the_dev_waiting_room() -> void:
	var real := ProgressData.new()
	real.pension = 17
	var progress := _progress_with_real_save(real)
	var before := _real_save_text()
	var kept: Dictionary = progress.data.to_dict().duplicate(true)
	progress.begin_dev_run(_waiting_data(), DEV_PATH)
	_use_the_waiting_room(progress)
	progress._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	assert_false(progress.is_dev_run(), "closing the window ends it")
	assert_false(FileAccess.file_exists(DEV_PATH))
	assert_eq(progress.data.to_dict(), kept)
	progress.begin_dev_run(_waiting_data(), DEV_PATH)
	progress.add_pension(40)
	progress._exit_tree()
	assert_false(progress.is_dev_run(), "the game tearing down ends it")
	assert_false(FileAccess.file_exists(DEV_PATH))
	assert_eq(progress.data.to_dict(), kept)
	assert_eq(_real_save_text(), before, "the real save is never written on the way out")
	progress.free()
	SaveStore.new(REAL_PATH).delete_all()


func test_a_dev_run_never_writes_the_real_save() -> void:
	var real := ProgressData.new()
	real.pension = 17
	real.opening_seen = true
	var progress := _progress_with_real_save(real)
	var before := _real_save_text()
	progress.begin_dev_run(_dev_data(), DEV_PATH)
	assert_true(progress.is_dev_run())
	progress.start_run()
	progress.add_pension(500)
	progress.buy(Content.upgrades()[0])
	progress.record_floor_cleared(3, "golden_years_mall")
	progress.find_recipe("anything")
	progress.retirement_deposit(50)
	progress.take_brewed_potion()
	assert_eq(_real_save_text(), before, "the real save is untouched during the run")
	assert_true(FileAccess.file_exists(DEV_PATH), "the dev run saves to its own file")
	progress.end_dev_run()
	assert_false(progress.is_dev_run())
	assert_eq(_real_save_text(), before, "the real save is untouched after the run")
	assert_false(FileAccess.file_exists(DEV_PATH), "the dev file is thrown away")
	assert_eq(progress.data.pension, 17, "Pension earned in the dev run is not kept")
	assert_eq(progress.data.clears_at(3), 0, "the dev run's clears are not kept")
	assert_eq(progress.data.run_count, 0)
	progress.add_pension(1)
	assert_true(_real_save_text() != before, "saving goes back to the real file afterwards")
	assert_eq(SaveStore.new(REAL_PATH).load_progress().pension, 18)
	progress.free()
	SaveStore.new(REAL_PATH).delete_all()


func test_ending_without_a_dev_run_changes_nothing() -> void:
	var real := ProgressData.new()
	real.pension = 5
	var progress := _progress_with_real_save(real)
	var kept: ProgressData = progress.data
	progress.end_dev_run()
	assert_true(progress.data == kept)
	assert_false(progress.is_dev_run())
	progress.free()
	SaveStore.new(REAL_PATH).delete_all()
