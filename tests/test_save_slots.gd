extends TestCase

# Every slot here lives in a folder under the system temp folder, never in the game's user folder,
# and the "old save" is a copy of the test fixture.
const FIXTURE := "res://tests/fixtures/save_v1_2026-11-04.json"


func _root() -> String:
	var root := OS.get_temp_dir().path_join("grandpa_test_slots") + "/"
	_wipe(root)
	DirAccess.make_dir_recursive_absolute(root)
	return root


func _wipe(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for sub in DirAccess.get_directories_at(dir):
		_wipe(dir.path_join(sub))
	for file in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(file))
	DirAccess.remove_absolute(dir)


func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _fixture_text() -> String:
	return FileAccess.get_file_as_string(FIXTURE)


func test_slot_paths() -> void:
	assert_eq(SaveSlots.slot_dir("user://", 2), "user://slot_2/")
	assert_eq(SaveSlots.save_path("user://", 1), "user://slot_1/save.json")
	assert_eq(SaveSlots.run_path("user://", 3), "user://slot_3/run.json")
	assert_eq(SaveSlots.COUNT, 3)


func test_migration_copies_the_old_save_into_slot_one() -> void:
	var root := _root()
	_write(root + "save.json", _fixture_text())
	_write(root + "save.json.bak", "backup text")
	var md5_before := FileAccess.get_md5(root + "save.json")
	var bak_before := FileAccess.get_md5(root + "save.json.bak")
	assert_true(SaveSlots.migrate(root))
	assert_eq(FileAccess.get_md5(root + "slot_1/save.json"), md5_before, "a byte for byte copy")
	assert_eq(FileAccess.get_md5(root + "slot_1/save.json.bak"), bak_before)
	assert_eq(FileAccess.get_md5(root + "save.json"), md5_before, "the original is untouched")
	assert_eq(FileAccess.get_md5(root + "save.json.bak"), bak_before)
	assert_true(FileAccess.file_exists(root + "save.json"), "copied, never moved")
	assert_eq(SaveSlots.read_last(root), 1, "slot 1 becomes the last used slot")
	_wipe(root)


func test_migration_never_overwrites_slot_one() -> void:
	var root := _root()
	_write(root + "save.json", _fixture_text())
	_write(root + "slot_1/save.json", "{\"slot one\": true}")
	assert_false(SaveSlots.migrate(root))
	assert_eq(FileAccess.get_file_as_string(root + "slot_1/save.json"), "{\"slot one\": true}")
	_wipe(root)


func test_migration_runs_once() -> void:
	var root := _root()
	_write(root + "save.json", _fixture_text())
	assert_true(SaveSlots.migrate(root))
	_write(root + "slot_1/save.json", "{\"played since\": true}")
	assert_false(SaveSlots.migrate(root))
	assert_eq(FileAccess.get_file_as_string(root + "slot_1/save.json"), "{\"played since\": true}")
	_wipe(root)


func test_no_old_save_means_nothing_to_copy() -> void:
	var root := _root()
	assert_false(SaveSlots.migrate(root))
	assert_false(DirAccess.dir_exists_absolute(root + "slot_1"))
	_wipe(root)


func test_an_empty_slot_reads_as_empty() -> void:
	var root := _root()
	var summary := SaveSlots.summary(root, 2)
	assert_true(summary["empty"])
	assert_eq(summary["run_floor"], 0)
	_wipe(root)


func test_a_slot_summary_reads_its_save() -> void:
	var root := _root()
	_write(SaveSlots.save_path(root, 1), _fixture_text())
	var summary := SaveSlots.summary(root, 1)
	assert_false(summary["empty"])
	assert_eq(summary["floors"], 7, "four first floors, two at depth 2 and one at depth 3")
	assert_eq(summary["deepest"], 3)
	assert_eq(summary["pension"], 312)
	assert_eq(summary["runs"], 23)
	assert_false(String(summary["date"]).is_empty(), "the date the slot was last saved")
	_wipe(root)


func test_a_slot_with_a_checkpoint_says_which_floor() -> void:
	var root := _root()
	_write(SaveSlots.save_path(root, 1), _fixture_text())
	assert_true(RunCheckpoint.write(SaveSlots.run_path(root, 1), {"depth": 4}))
	assert_eq(SaveSlots.summary(root, 1)["run_floor"], 4)
	_wipe(root)


func test_progress_needs_more_than_a_file() -> void:
	var fresh := ProgressData.new()
	assert_false(SaveSlots.has_progress(fresh))
	fresh.opening_seen = true
	assert_true(SaveSlots.has_progress(fresh))
	var played := ProgressData.new()
	played.run_count = 1
	assert_true(SaveSlots.has_progress(played))


func test_deleting_a_slot_removes_only_that_slot() -> void:
	var root := _root()
	_write(SaveSlots.save_path(root, 1), _fixture_text())
	_write(SaveSlots.save_path(root, 2), _fixture_text())
	_write(SaveSlots.save_path(root, 2) + ".bak", _fixture_text())
	RunCheckpoint.write(SaveSlots.run_path(root, 2), {"depth": 2})
	SaveSlots.delete_slot(root, 2)
	assert_true(SaveSlots.summary(root, 2)["empty"])
	assert_false(FileAccess.file_exists(SaveSlots.run_path(root, 2)))
	assert_false(FileAccess.file_exists(SaveSlots.save_path(root, 2) + ".bak"))
	assert_false(SaveSlots.summary(root, 1)["empty"])
	_wipe(root)


func test_the_last_used_slot_round_trips() -> void:
	var root := _root()
	assert_eq(SaveSlots.read_last(root), 1, "slot 1 when nothing was saved")
	SaveSlots.write_last(root, 3)
	assert_eq(SaveSlots.read_last(root), 3)
	_write(root + SaveSlots.LAST_FILE, "nine")
	assert_eq(SaveSlots.read_last(root), 1, "a damaged file falls back to slot 1")
	_wipe(root)


func test_the_title_menu_items() -> void:
	assert_eq(SaveSlots.menu_items(0), ["new", "options", "credits", "quit"], "a fresh install")
	assert_eq(SaveSlots.menu_items(1), ["continue", "new", "options", "credits", "quit"])
	assert_eq(SaveSlots.menu_items(2), ["continue", "new", "load", "options", "credits", "quit"])


func test_continue_takes_the_last_slot_or_the_newest_with_progress() -> void:
	var root := _root()
	assert_eq(SaveSlots.continue_slot(root), 0, "nothing to continue")
	_write(SaveSlots.save_path(root, 2), _fixture_text())
	SaveSlots.write_last(root, 1)
	assert_eq(SaveSlots.continue_slot(root), 2, "the last slot is empty, so the one with progress")
	_write(SaveSlots.save_path(root, 3), _fixture_text())
	SaveSlots.write_last(root, 3)
	assert_eq(SaveSlots.continue_slot(root), 3, "the last used slot")
	_wipe(root)
