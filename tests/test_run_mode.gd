extends TestCase

# A test or probe run is started with --script or its short form -s. Every autoload that would read or
# write files in the user folder asks RunMode, so neither form can touch the real save or settings.


func test_both_forms_of_the_script_flag_count() -> void:
	assert_true(RunMode.is_script_args(PackedStringArray(["--headless", "--script", "res://tests/run_tests.gd"])))
	assert_true(RunMode.is_script_args(PackedStringArray(["--headless", "-s", "res://tests/run_tests.gd"])))
	assert_false(RunMode.is_script_args(PackedStringArray(["--path", "."])), "a real run")
	assert_false(RunMode.is_script_args(PackedStringArray([])))


func test_this_run_is_a_script_run() -> void:
	assert_true(RunMode.is_script_run(), "the tests run under --script")


func test_every_autoload_guard_asks_run_mode() -> void:
	for path in ["res://scripts/autoload/progress.gd", "res://scripts/autoload/settings.gd", "res://scripts/autoload/music_player.gd", "res://scripts/autoload/sounds.gd"]:
		var source := FileAccess.get_file_as_string(path)
		assert_false(source.contains("has(\"--script\")"), "%s matches only the long flag" % path)
		assert_true(source.contains("RunMode.is_script_run()"), path)
