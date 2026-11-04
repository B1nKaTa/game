extends TestCase

# OptionsPanel names the Settings autoload, so tests read it as source text (see LESSONS).
const SOURCE := "res://scripts/ui/options_panel.gd"


func _source() -> String:
	return FileAccess.get_file_as_string(SOURCE)


func test_every_setting_has_a_row_and_a_label() -> void:
	var source := _source()
	for section: String in GameSettings.SECTIONS:
		for key: String in GameSettings.DEFAULTS[section]:
			assert_true(source.contains("\"%s\": \"" % key), "%s has a label" % key)
			assert_true(source.count("\"%s\"" % key) >= 2, "%s is on a tab" % key)


func test_four_tabs_in_the_spec_order() -> void:
	assert_true(_source().contains("const TABS: Array[String] = [GameSettings.VIDEO, GameSettings.AUDIO, GameSettings.GAME, GameSettings.INPUT]"))


func test_the_panel_has_its_own_opaque_backing() -> void:
	assert_true(_source().contains("add_child(MenuStyle.backing())"))
	assert_eq(MenuStyle.BACK.a, 1.0)


func test_the_panel_fits_the_view() -> void:
	var source := _source()
	assert_true(source.contains("const AT := Vector2(30, 12)") and source.contains("const SIZE := Vector2(580, 336)"))
	assert_true(30 + 580 <= 640 and 12 + 336 <= 360)


func test_menu_strings_go_through_tr() -> void:
	var source := _source()
	for text in ["\"Options\"", "\"Defaults\"", "\"OK\"", "\"Discard changes?\"", "\"coming\""]:
		assert_true(source.contains("tr(%s)" % text), text)


func test_the_controller_column_waits_for_stage_two() -> void:
	assert_true(_source().contains("tr(\"Controller\")"))
	assert_eq(KeyBindings.PAD_KEY, "pad")
