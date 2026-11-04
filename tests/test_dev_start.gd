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
