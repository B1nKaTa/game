extends TestCase

const TestActive := preload("res://tests/support/test_active_effect.gd")
# What the slot must leave for the item's name after the key, in pixels.
const NAME_ROOM := 20.0


func _active(id: String, item_name: String) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	item.display_name = item_name
	item.kind = ItemDef.KIND_ACTIVE
	item.charge_rooms = 2
	item.effect = TestActive.new()
	return item


func test_the_use_item_action_is_r_and_pad_b() -> void:
	InputSetup.ensure()
	KeyBindings.reset_to_defaults()
	assert_true(InputMap.has_action("use_item"))
	assert_eq(KeyBindings.label_for("use_item"), "R")
	assert_eq(KeyBindings.pad_label_for("use_item", PadInput.XBOX), "B")
	assert_eq(KeyBindings.action_label("use_item"), "Use item")


func test_no_two_actions_share_a_default_binding() -> void:
	InputSetup.ensure()
	KeyBindings.reset_to_defaults()
	var keys := {}
	var pads := {}
	for entry in KeyBindings.ACTIONS:
		var action: String = entry["action"]
		var key := KeyBindings.label_for(action)
		var pad := KeyBindings.pad_label_for(action, PadInput.XBOX)
		assert_false(keys.has(key), "%s and %s share %s" % [action, keys.get(key, ""), key])
		assert_false(pads.has(pad), "%s and %s share %s" % [action, pads.get(pad, ""), pad])
		keys[key] = action
		pads[pad] = action


func test_the_slot_text_and_charge() -> void:
	var item := _active("hearing", "Hearing Aid")
	assert_eq(ActiveSlot.label_text("R", item), "[R] Hearing Aid")
	assert_eq(ActiveSlot.label_text("R", null), "")
	assert_near(ActiveSlot.charge_fraction(1, 3), 1.0 / 3.0)
	assert_near(ActiveSlot.charge_fraction(5, 3), 1.0)
	assert_near(ActiveSlot.charge_fraction(0, 0), 0.0)


func test_the_slot_sits_in_the_top_band_between_the_panels() -> void:
	var rect := ActiveSlot.slot_rect(Hud.LEFT_PANEL_AT.x + Hud.LEFT_PANEL_MIN_WIDTH)
	assert_true(rect.position.x >= Hud.LEFT_PANEL_AT.x + Hud.LEFT_PANEL_MIN_WIDTH)
	assert_true(rect.end.x <= Hud.RIGHT_PANEL.position.x)
	assert_true(rect.end.y <= Hud.TOP_BAND_SIZE.y)
	var wide := ActiveSlot.slot_rect(380.0)
	assert_true(wide.size.x >= ActiveSlot.MIN_WIDTH, "a wide left panel still leaves the icon and bar")


func test_every_default_key_label_fits_the_slot_beside_the_icon() -> void:
	InputSetup.ensure()
	KeyBindings.reset_to_defaults()
	var rect := ActiveSlot.slot_rect(Hud.LEFT_PANEL_AT.x + Hud.LEFT_PANEL_MIN_WIDTH)
	var room := rect.size.x - ActiveSlot.TEXT_AT.x
	var font := HudStyle.font()
	var labels: Array[String] = [KeyBindings.label_for("use_item")]
	for family in [PadInput.XBOX, PadInput.PLAYSTATION]:
		labels.append(KeyBindings.pad_label_for("use_item", family))
	for label in labels:
		var width := font.get_string_size("[%s]" % label, HORIZONTAL_ALIGNMENT_LEFT, -1, HudStyle.SMALL).x
		assert_true(width + NAME_ROOM <= room, "[%s] is %d px of %d, leaving a name no room" % [label, width, room])


# The unpause notification, as a real Player gets it when the tree unpauses.
func test_a_player_refuses_a_use_press_right_after_the_tree_unpaused() -> void:
	var player := Player.new()
	assert_true(player.use_press_allowed(), "never paused")
	player.notification(Node.NOTIFICATION_UNPAUSED)
	assert_false(player.use_press_allowed(), "the press that unpaused")
	player.free()


# Scenes that close a panel without unpausing (the card table, a Waiting Room panel) stamp it by hand.
func test_a_player_refuses_a_use_press_right_after_a_panel_closed_without_unpausing() -> void:
	var player := Player.new()
	player.note_panel_closed()
	assert_false(player.use_press_allowed())
	player.free()
	var floor_scene := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	var close_table := floor_scene.substr(floor_scene.find("func _close_card_table"))
	assert_true(close_table.substr(0, close_table.find("\n\n\n")).contains("player.note_panel_closed()"))
	var waiting := FileAccess.get_file_as_string("res://scripts/scenes/waiting_room.gd")
	var close_panel := waiting.substr(waiting.find("func _close_panel"))
	assert_true(close_panel.substr(0, close_panel.find("\n\n\n")).contains("player.note_panel_closed()"))


func test_the_hud_shows_the_held_active_only_while_held() -> void:
	var run := ItemKit.new().make_run()
	var hud := Hud.new()
	hud.setup(run)
	hud._ready()
	assert_eq(hud.active_label(), "")
	run.add_item(_active("bell", "Dinner Bell"))
	assert_eq(hud.active_label(), "[%s] Dinner Bell" % KeyBindings.prompt_label("use_item"))
	run.clear_items()
	assert_eq(hud.active_label(), "")
	hud.free()


func test_the_case_file_shows_the_active_first() -> void:
	var tea := ItemDef.new()
	tea.id = "tea_cosy"
	tea.display_name = "Tea Cosy"
	var items: Array[ItemDef] = [tea]
	var cells := CaseFileData.held_cells(items, _active("bell", "Dinner Bell"))
	assert_eq(cells.size(), 2)
	assert_eq(cells[0]["id"], "bell")
	assert_true(cells[0]["use"])
	assert_false(cells[1].get("use", false))


func test_a_b_press_that_closed_a_menu_never_uses_the_active() -> void:
	assert_false(Player.use_press_counts(100, 100), "the press that unpaused")
	assert_false(Player.use_press_counts(101, 100), "the frame after it")
	assert_true(Player.use_press_counts(102, 100))
	assert_true(Player.use_press_counts(5, -10), "never paused")


func test_the_player_uses_the_active_and_the_floor_drops_a_swapped_one() -> void:
	var player := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	assert_true(player.contains("Input.is_action_just_pressed(\"use_item\")"))
	assert_true(player.contains("active_used.emit("))
	var floor_scene := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	assert_true(floor_scene.contains("_run.active_swapped.connect(_on_active_swapped)"))
	var room := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	assert_true(room.contains("func drop_active("))
