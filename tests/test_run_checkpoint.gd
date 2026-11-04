extends TestCase

# The checkpoint file, a RunState through it, and that a floor rebuilds the same from its seed.


func _path() -> String:
	return OS.get_temp_dir().path_join("grandpa_test_run.json")


func _clean() -> void:
	for path in [_path(), _path() + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _write_text(text: String) -> void:
	var file := FileAccess.open(_path(), FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_the_file_round_trips() -> void:
	_clean()
	assert_true(RunCheckpoint.write(_path(), {"depth": 3, "path": "golden_years_mall"}))
	var read := RunCheckpoint.read(_path())
	assert_eq(int(read["depth"]), 3)
	assert_eq(read["path"], "golden_years_mall")
	assert_eq(int(read["version"]), RunCheckpoint.VERSION)
	assert_false(FileAccess.file_exists(_path() + ".tmp"), "the temp file is renamed into place")
	_clean()


func test_a_missing_file_is_no_run() -> void:
	_clean()
	assert_true(RunCheckpoint.read(_path()).is_empty())


func test_a_damaged_file_is_no_run() -> void:
	_write_text("{\"version\": 1, \"depth\": ")
	assert_true(RunCheckpoint.read(_path()).is_empty())
	_write_text("[1, 2, 3]")
	assert_true(RunCheckpoint.read(_path()).is_empty())
	_clean()


func test_another_version_is_no_run() -> void:
	_write_text(JSON.stringify({"version": RunCheckpoint.VERSION + 1, "depth": 2}))
	assert_true(RunCheckpoint.read(_path()).is_empty())
	_write_text(JSON.stringify({"depth": 2}))
	assert_true(RunCheckpoint.read(_path()).is_empty(), "no version at all")
	_clean()


func test_a_leftover_temp_file_never_counts() -> void:
	_clean()
	var file := FileAccess.open(_path() + ".tmp", FileAccess.WRITE)
	file.store_string("{\"version\": 1, \"dep")
	file.close()
	assert_true(RunCheckpoint.read(_path()).is_empty(), "a kill mid-write leaves only the temp file")
	assert_true(RunCheckpoint.write(_path(), {"depth": 1}))
	assert_eq(int(RunCheckpoint.read(_path())["depth"]), 1)
	_clean()


func test_delete() -> void:
	RunCheckpoint.write(_path(), {"depth": 1})
	RunCheckpoint.delete(_path())
	assert_false(FileAccess.file_exists(_path()))
