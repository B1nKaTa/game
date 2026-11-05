extends TestCase

# Controller focus in a panel: which controls take focus, the first one, where the D-pad goes from
# each, and the gold highlight.


func _button(text: String, parent: Node, disabled := false) -> Button:
	var button := Button.new()
	button.text = text
	button.disabled = disabled
	parent.add_child(button)
	return button


func test_focusables_are_the_visible_focusable_controls_in_tree_order() -> void:
	var root := CanvasLayer.new()
	var column := VBoxContainer.new()
	root.add_child(column)
	var first := _button("first", column)
	var label := Label.new()
	column.add_child(label)
	var hidden := _button("hidden", column)
	hidden.visible = false
	var row := HBoxContainer.new()
	column.add_child(row)
	var second := _button("second", row)
	var off := _button("off", row)
	off.focus_mode = Control.FOCUS_NONE
	var shut := HBoxContainer.new()
	shut.visible = false
	column.add_child(shut)
	_button("inside a hidden box", shut)
	var slider := HSlider.new()
	column.add_child(slider)
	var leave := _button("Leave", root)
	assert_eq(PadFocus.focusables(root), [first, second, slider, leave] as Array[Control])
	root.free()


func test_a_box_asked_over_the_panel_keeps_its_own_controls() -> void:
	var root := CanvasLayer.new()
	var mine := _button("mine", root)
	var confirm := CanvasLayer.new()
	root.add_child(confirm)
	_button("theirs", confirm)
	assert_eq(PadFocus.focusables(root), [mine] as Array[Control])
	root.free()


func test_the_first_focus_skips_disabled_controls() -> void:
	var root := VBoxContainer.new()
	var sold := _button("sold", root, true)
	var buy := _button("buy", root)
	assert_eq(PadFocus.first_of([sold, buy] as Array[Control]), buy)
	assert_eq(PadFocus.first_of([sold] as Array[Control]), sold, "with nothing enabled, the first anyway")
	assert_eq(PadFocus.first_of([] as Array[Control]), null)
	root.free()


func test_after_a_rebuild_focus_returns_to_the_same_place() -> void:
	assert_eq(PadFocus.refocus_index(2, 5), 2)
	assert_eq(PadFocus.refocus_index(4, 3), 2, "a shorter list keeps the last")
	assert_eq(PadFocus.refocus_index(-1, 3), 0)
	assert_eq(PadFocus.refocus_index(1, 0), -1)


# A list of rows, each with a button on the right, and Leave under them on the left.
func _shop_rects() -> Array[Rect2]:
	return [
		Rect2(500, 40, 60, 14),
		Rect2(500, 60, 60, 14),
		Rect2(500, 80, 60, 14),
		Rect2(26, 110, 40, 16),
	] as Array[Rect2]


func test_down_and_up_walk_a_list() -> void:
	var rects := _shop_rects()
	assert_eq(PadFocus.neighbour(rects, 0, Vector2.DOWN), 1)
	assert_eq(PadFocus.neighbour(rects, 1, Vector2.DOWN), 2)
	assert_eq(PadFocus.neighbour(rects, 2, Vector2.UP), 1)
	assert_eq(PadFocus.neighbour(rects, 0, Vector2.UP), -1, "nothing above the top")


func test_down_from_the_last_row_reaches_leave_and_back() -> void:
	var rects := _shop_rects()
	assert_eq(PadFocus.neighbour(rects, 2, Vector2.DOWN), 3, "Leave is below even though it is far left")
	assert_eq(PadFocus.neighbour(rects, 3, Vector2.UP), 2, "up from Leave goes to the nearest row")
	assert_eq(PadFocus.neighbour(rects, 3, Vector2.DOWN), -1)


func test_left_and_right_walk_a_row() -> void:
	var rects: Array[Rect2] = [Rect2(10, 10, 40, 14), Rect2(60, 10, 40, 14), Rect2(110, 10, 40, 14), Rect2(10, 40, 40, 14)]
	assert_eq(PadFocus.neighbour(rects, 0, Vector2.RIGHT), 1)
	assert_eq(PadFocus.neighbour(rects, 1, Vector2.RIGHT), 2)
	assert_eq(PadFocus.neighbour(rects, 2, Vector2.LEFT), 1)
	assert_eq(PadFocus.neighbour(rects, 0, Vector2.LEFT), -1)
	assert_eq(PadFocus.neighbour(rects, 1, Vector2.DOWN), 3)


func test_a_row_beside_a_row_prefers_the_one_in_line() -> void:
	# Two option buttons side by side, rows above and below: down from the left one goes straight down.
	var rects: Array[Rect2] = [Rect2(100, 10, 80, 14), Rect2(100, 30, 80, 14), Rect2(190, 30, 80, 14), Rect2(100, 50, 80, 14)]
	assert_eq(PadFocus.neighbour(rects, 1, Vector2.DOWN), 3)
	assert_eq(PadFocus.neighbour(rects, 2, Vector2.UP), 0)
	assert_eq(PadFocus.neighbour(rects, 1, Vector2.RIGHT), 2)


func test_the_focus_highlight_is_gold() -> void:
	var style := PadFocus.focus_style()
	assert_true(style.border_color.is_equal_approx(MenuStyle.GOLD))
	assert_true(style.border_width_top >= 2)
	assert_false(style.draw_center, "the button's own look shows through")


func test_a_plain_button_gets_the_gold_highlight() -> void:
	var root := VBoxContainer.new()
	var plain := _button("plain", root)
	var styled := MenuStyle.button("styled")
	root.add_child(styled)
	var bar := styled.get_theme_stylebox("focus")
	PadFocus.style_all(PadFocus.focusables(root))
	assert_true(plain.has_theme_stylebox_override("focus"))
	assert_true((plain.get_theme_stylebox("focus") as StyleBoxFlat).border_color.is_equal_approx(MenuStyle.GOLD))
	assert_eq(styled.get_theme_stylebox("focus"), bar, "a menu button keeps its gold bar")
	root.free()


const PANELS := [
	"res://scripts/ui/merchant_panel.gd",
	"res://scripts/ui/refile_panel.gd",
	"res://scripts/ui/craft_panel.gd",
	"res://scripts/ui/potion_panel.gd",
	"res://scripts/ui/decor_panel.gd",
	"res://scripts/ui/bounty_panel.gd",
	"res://scripts/ui/noticeboard_panel.gd",
	"res://scripts/ui/ticket_panel.gd",
	"res://scripts/ui/item_rack_panel.gd",
	"res://scripts/ui/card_table_panel.gd",
	"res://scripts/ui/options_panel.gd",
	"res://scripts/ui/pause_menu.gd",
	"res://scripts/ui/slot_picker.gd",
	"res://scripts/ui/confirm_box.gd",
	"res://scripts/scenes/title_screen.gd",
	"res://scripts/ui/ending_archive_panel.gd",
]


func test_every_panel_takes_controller_focus() -> void:
	for path in PANELS:
		assert_true(FileAccess.get_file_as_string(path).contains("PadFocus.new()"), path)


func test_b_backs_out_of_every_menu_and_panel() -> void:
	for path in ["res://scripts/ui/options_panel.gd", "res://scripts/ui/pause_menu.gd", "res://scripts/ui/slot_picker.gd", "res://scripts/ui/confirm_box.gd", "res://scripts/ui/credits_card.gd", "res://scripts/ui/cutscene_player.gd", "res://scripts/scenes/waiting_room.gd", "res://scripts/scenes/floor_scene.gd"]:
		assert_true(FileAccess.get_file_as_string(path).contains("PadInput.BACK_ACTION"), path)


func test_the_ending_archive_backs_out_of_a_replay_before_it_closes() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/ending_archive_panel.gd")
	var leave := source.substr(source.find("func leave()"), 160)
	assert_true(leave.contains("_cutscene.skip()") and leave.contains("closed.emit()"))


func test_tabs_switch_on_the_shoulder_buttons() -> void:
	for path in ["res://scripts/ui/options_panel.gd", "res://scripts/ui/decor_panel.gd"]:
		assert_true(FileAccess.get_file_as_string(path).contains(".tabs = "), path)


func test_card_tables_take_focus_only_from_a_pad() -> void:
	assert_true(FileAccess.get_file_as_string("res://scripts/ui/card_table_panel.gd").contains("pad_only = true"))
