extends TestCase

# The build id comes from res://build_info.txt, written by tools/stamp_build.ps1 before an export, and
# reads "dev" wherever that file is missing, as it is in the editor and in tests.


func test_a_stamped_file_gives_the_commit_and_the_date() -> void:
	assert_eq(BuildInfo.parse("commit=291126a\ndate=2026-11-08\n"), "build 291126a (2026-11-08)")


func test_the_lines_may_come_in_any_order_with_windows_endings_and_spaces() -> void:
	assert_eq(BuildInfo.parse("date = 2026-11-08\r\n  commit=291126A \r\n"), "build 291126a (2026-11-08)")


func test_other_lines_are_ignored() -> void:
	assert_eq(BuildInfo.parse("# stamped\ncommit=abc1234\nbranch=art-direction\ndate=2026-11-08"), "build abc1234 (2026-11-08)")


func test_a_missing_or_odd_date_is_left_out() -> void:
	assert_eq(BuildInfo.parse("commit=abc1234\n"), "build abc1234")
	assert_eq(BuildInfo.parse("commit=abc1234\ndate=yesterday\n"), "build abc1234")
	assert_eq(BuildInfo.parse("commit=abc1234\ndate=2026-1-08\n"), "build abc1234")


func test_a_missing_or_odd_commit_reads_as_dev() -> void:
	assert_eq(BuildInfo.parse(""), BuildInfo.DEV)
	assert_eq(BuildInfo.parse("date=2026-11-08\n"), BuildInfo.DEV)
	assert_eq(BuildInfo.parse("commit=\ndate=2026-11-08\n"), BuildInfo.DEV)
	assert_eq(BuildInfo.parse("commit=not-a-hash\n"), BuildInfo.DEV)
	assert_eq(BuildInfo.parse("commit=ab1\n"), BuildInfo.DEV)
	assert_eq(BuildInfo.parse("291126a 2026-11-08"), BuildInfo.DEV)


func test_a_missing_file_reads_as_dev() -> void:
	assert_eq(BuildInfo.read(OS.get_temp_dir().path_join("grandpa_no_build_info.txt")), BuildInfo.DEV)


func test_a_written_file_is_read_back() -> void:
	var path := OS.get_temp_dir().path_join("grandpa_test_build_info.txt")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("commit=0f1e2d3\ndate=2026-11-08\n")
	file.close()
	assert_eq(BuildInfo.read(path), "build 0f1e2d3 (2026-11-08)")
	DirAccess.remove_absolute(path)


# Tests run from an unstamped copy, so the game's own label is "dev" here.
func test_an_unstamped_project_is_dev() -> void:
	if FileAccess.file_exists(BuildInfo.PATH):
		return
	assert_eq(BuildInfo.label(), BuildInfo.DEV)


func test_the_export_takes_the_stamp_along() -> void:
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	assert_true(presets.contains("include_filter=\"build_info.txt\""), "build_info.txt is a plain file, so the export must include it by name")
	assert_true(FileAccess.get_file_as_string("res://.gitignore").contains("build_info.txt"), "the stamp is generated, never committed")


func test_the_id_shows_where_bug_reports_look() -> void:
	assert_true(FileAccess.get_file_as_string("res://scripts/scenes/title_screen.gd").contains("HudStyle.build_label()"))
	assert_true(FileAccess.get_file_as_string("res://scripts/ui/pause_menu.gd").contains("HudStyle.build_label()"))
	var settings := FileAccess.get_file_as_string("res://scripts/autoload/settings.gd")
	var log_at := settings.find("func _log_display")
	var first_line := settings.find("file.store_line(", log_at)
	assert_true(log_at >= 0 and settings.substr(first_line, 40).contains("BuildInfo.label()"), "the build id is display_log.txt's first line")
