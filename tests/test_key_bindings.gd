extends TestCase

# In the temp folder, so a test run never writes into the game's user folder.
var PATH := OS.get_temp_dir().path_join("grandpa_test_keys.json")


func _reset() -> void:
	KeyBindings.reset_to_defaults()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	return event


func _mouse(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	return event


func test_every_action_can_be_rebound() -> void:
	InputSetup.ensure()
	for entry in KeyBindings.ACTIONS:
		assert_true(InputMap.has_action(entry["action"]), entry["action"])
	assert_eq(KeyBindings.ACTIONS.size(), InputMap.get_actions().filter(func(a): return not String(a).begins_with("ui_")).size())


func test_describing_inputs() -> void:
	assert_eq(KeyBindings.describe(_mouse(MOUSE_BUTTON_LEFT)), "Left Click")
	assert_eq(KeyBindings.describe(_mouse(MOUSE_BUTTON_RIGHT)), "Right Click")
	assert_eq(KeyBindings.describe(_key(KEY_E)), "E")
	assert_eq(KeyBindings.describe(null), "?")


func test_rebinding_replaces_the_old_input() -> void:
	_reset()
	KeyBindings.rebind("bomb", _key(KEY_F))
	var keys := InputMap.action_get_events("bomb").filter(func(e): return not PadInput.is_pad(e))
	assert_eq(keys.size(), 1)
	assert_eq(KeyBindings.describe(keys[0]), "F")
	assert_true(PadInput.same(KeyBindings.pad_event("bomb"), PadInput.default_event("bomb")), "the controller binding stays")
	_reset()


func test_taking_a_used_key_swaps_the_two_actions() -> void:
	_reset()
	KeyBindings.rebind("bomb", _key(KEY_E))
	assert_eq(KeyBindings.label_for("bomb"), "E")
	assert_eq(KeyBindings.label_for("interact"), "Q", "no action is ever left without an input")
	_reset()


func test_a_mouse_button_can_replace_a_key() -> void:
	_reset()
	KeyBindings.rebind("dodge", _mouse(MOUSE_BUTTON_MIDDLE))
	assert_eq(KeyBindings.label_for("dodge"), "Mouse 3")
	_reset()


func test_bindings_survive_saving_and_loading() -> void:
	_reset()
	KeyBindings.rebind("bomb", _key(KEY_F))
	KeyBindings.rebind("attack", _mouse(MOUSE_BUTTON_RIGHT))
	assert_true(KeyBindings.save_to(PATH))
	KeyBindings.reset_to_defaults()
	assert_eq(KeyBindings.label_for("bomb"), "Q")
	KeyBindings.load_from(PATH)
	assert_eq(KeyBindings.label_for("bomb"), "F")
	assert_eq(KeyBindings.label_for("attack"), "Right Click")
	assert_eq(KeyBindings.label_for("throw"), "Left Click")
	_reset()


func test_a_missing_or_damaged_file_keeps_the_defaults() -> void:
	_reset()
	KeyBindings.load_from("user://no_such_keys.json")
	assert_eq(KeyBindings.label_for("bomb"), "Q")
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("not json at all")
	file.close()
	KeyBindings.load_from(PATH)
	assert_eq(KeyBindings.label_for("bomb"), "Q")
	file = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("{\"bomb\": {\"type\": \"nonsense\"}, \"not_an_action\": {\"type\": \"key\", \"code\": 70}}")
	file.close()
	KeyBindings.load_from(PATH)
	assert_eq(KeyBindings.label_for("bomb"), "Q")
	assert_false(InputMap.has_action("not_an_action"))
	_reset()


func test_an_older_file_cannot_put_a_new_actions_key_on_two_actions() -> void:
	_reset()
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("{\"interact\": {\"type\": \"key\", \"code\": %d}}" % KEY_H)
	file.close()
	KeyBindings.load_from(PATH)
	assert_eq(KeyBindings.label_for("interact"), "H")
	assert_eq(KeyBindings.label_for("potion"), "E", "the action missing from the file takes the freed key")
	_reset()


func test_the_throw_is_named_for_the_dentures() -> void:
	var label := ""
	for entry in KeyBindings.ACTIONS:
		if entry["action"] == "throw":
			label = entry["label"]
	assert_eq(label, "Throw dentures")
	for entry in KeyBindings.ACTIONS:
		assert_false(String(entry["label"]).to_lower().contains("throw cane"), entry["label"])


func test_a_file_saved_when_the_cane_was_thrown_still_binds_the_throw() -> void:
	# The action kept its id when the cane became dentures, so older files still name it "throw".
	_reset()
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("{\"throw\": {\"type\": \"key\", \"code\": %d}}" % KEY_F)
	file.close()
	KeyBindings.load_from(PATH)
	assert_eq(KeyBindings.label_for("throw"), "F")
	_reset()


func test_prompts_follow_the_bound_key() -> void:
	_reset()
	assert_eq(KeyBindings.with_key("interact", "Buy"), "E: Buy")
	KeyBindings.rebind("interact", _key(KEY_F))
	assert_eq(KeyBindings.with_key("interact", "Buy"), "F: Buy")
	_reset()


func test_a_rebind_names_the_action_it_swapped_with() -> void:
	_reset()
	assert_eq(KeyBindings.rebind("bomb", _key(KEY_E)), "interact")
	assert_eq(KeyBindings.label_for("interact"), "Q")
	assert_eq(KeyBindings.rebind("bomb", _key(KEY_F7)), "", "a free key swaps with nothing")
	_reset()


func test_pause_is_an_action_on_escape() -> void:
	_reset()
	assert_true(InputMap.has_action("pause"))
	assert_eq(KeyBindings.label_for("pause"), "Escape")
	var listed := KeyBindings.ACTIONS.filter(func(entry): return entry["action"] == "pause")
	assert_eq(listed.size(), 1)


func test_a_snapshot_puts_the_bindings_back() -> void:
	_reset()
	var before := KeyBindings.snapshot()
	KeyBindings.rebind("dodge", _key(KEY_F8))
	assert_eq(KeyBindings.label_for("dodge"), "F8")
	KeyBindings.restore(before)
	assert_eq(KeyBindings.label_for("dodge"), "Space")
	_reset()


func test_a_saved_controller_section_is_read_and_written_back() -> void:
	_reset()
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"dodge": {"type": "key", "code": KEY_SPACE}, KeyBindings.PAD_KEY: {"dodge": {"type": "joy_button", "button": 0}}}))
	file.close()
	KeyBindings.load_from(PATH)
	assert_true(KeyBindings.save_to(PATH))
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	assert_true(raw.has(KeyBindings.PAD_KEY), "the controller column survives a save")
	assert_eq(raw[KeyBindings.PAD_KEY]["dodge"]["button"], 0.0)
	_reset()


func _pad(index: int) -> InputEventJoypadButton:
	return PadInput.button(index)


func test_a_controller_rebind_changes_only_the_controller_column() -> void:
	_reset()
	# A button no action uses (Y is the flashback's now).
	assert_eq(KeyBindings.rebind("dodge", _pad(JOY_BUTTON_RIGHT_STICK)), "")
	assert_eq(KeyBindings.pad_label_for("dodge", PadInput.XBOX), "RS")
	assert_eq(KeyBindings.label_for("dodge"), "Space", "the key stays")
	_reset()


func test_a_used_controller_button_swaps_with_its_action() -> void:
	_reset()
	assert_eq(KeyBindings.rebind("dodge", _pad(JOY_BUTTON_X)), "interact")
	assert_eq(KeyBindings.pad_label_for("dodge", PadInput.XBOX), "X")
	assert_eq(KeyBindings.pad_label_for("interact", PadInput.XBOX), "A", "no action is ever left without a button")
	assert_eq(KeyBindings.label_for("interact"), "E", "the keyboard column is untouched")
	_reset()


func test_a_trigger_can_take_a_buttons_place() -> void:
	_reset()
	assert_eq(KeyBindings.rebind("bomb", PadInput.axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)), "attack")
	assert_eq(KeyBindings.pad_label_for("bomb", PadInput.XBOX), "RT")
	assert_eq(KeyBindings.pad_label_for("attack", PadInput.XBOX), "RB")
	_reset()


func test_rebinding_walking_keeps_the_d_pad() -> void:
	_reset()
	KeyBindings.rebind("move_up", _pad(JOY_BUTTON_Y))
	assert_eq(KeyBindings.pad_label_for("move_up", PadInput.XBOX), "Y")
	var events := InputMap.action_get_events("move_up")
	assert_true(events.any(func(e): return PadInput.same(e, _pad(JOY_BUTTON_DPAD_UP))), "the D-pad still walks")
	assert_eq(events.filter(func(e): return PadInput.is_pad(e)).size(), 2)
	_reset()


func test_both_columns_survive_saving_and_loading() -> void:
	_reset()
	KeyBindings.rebind("dodge", _pad(JOY_BUTTON_B))
	KeyBindings.rebind("throw", _pad(JOY_BUTTON_Y))
	KeyBindings.rebind("bomb", _key(KEY_F))
	assert_true(KeyBindings.save_to(PATH))
	KeyBindings.reset_to_defaults()
	assert_eq(KeyBindings.pad_label_for("dodge", PadInput.XBOX), "A")
	KeyBindings.load_from(PATH)
	assert_eq(KeyBindings.pad_label_for("dodge", PadInput.XBOX), "B")
	assert_eq(KeyBindings.pad_label_for("throw", PadInput.XBOX), "Y")
	assert_eq(KeyBindings.label_for("bomb"), "F")
	_reset()


func test_an_old_file_keeps_the_controller_defaults() -> void:
	_reset()
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("{\"dodge\": {\"type\": \"key\", \"code\": %d}}" % KEY_F)
	file.close()
	KeyBindings.load_from(PATH)
	assert_eq(KeyBindings.label_for("dodge"), "F")
	for entry in KeyBindings.ACTIONS:
		assert_true(PadInput.same(KeyBindings.pad_event(entry["action"]), PadInput.default_event(entry["action"])), entry["action"])
	_reset()


func test_a_damaged_controller_entry_keeps_its_default() -> void:
	_reset()
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({KeyBindings.PAD_KEY: {"dodge": {"type": "joy_button", "button": 99}, "bomb": "junk", "interact": {"type": "joy_button", "button": JOY_BUTTON_DPAD_UP}, "map": {"type": "key", "code": KEY_F}}}))
	file.close()
	KeyBindings.load_from(PATH)
	for action in ["dodge", "bomb", "interact", "map"]:
		assert_true(PadInput.same(KeyBindings.pad_event(action), PadInput.default_event(action)), action)
	var broken := FileAccess.open(PATH, FileAccess.WRITE)
	broken.store_string(JSON.stringify({KeyBindings.PAD_KEY: "not a section"}))
	broken.close()
	KeyBindings.load_from(PATH)
	assert_true(PadInput.same(KeyBindings.pad_event("dodge"), PadInput.default_event("dodge")))
	_reset()


func test_a_snapshot_holds_and_restores_the_controller_column() -> void:
	_reset()
	var before := KeyBindings.snapshot()
	assert_true(before.has(KeyBindings.PAD_KEY))
	KeyBindings.rebind("dodge", _pad(JOY_BUTTON_Y))
	assert_true(KeyBindings.snapshot() != before, "a controller change shows as a change")
	KeyBindings.restore(before)
	assert_eq(KeyBindings.pad_label_for("dodge", PadInput.XBOX), "A")
	assert_eq(KeyBindings.snapshot(), before)
	_reset()


func test_prompts_name_the_active_devices_button() -> void:
	_reset()
	assert_eq(KeyBindings.with_device("interact", "Talk", false, PadInput.XBOX), "E: Talk")
	assert_eq(KeyBindings.with_device("interact", "Talk", true, PadInput.XBOX), "X: Talk")
	assert_eq(KeyBindings.with_device("interact", "Talk", true, PadInput.PLAYSTATION), "Square: Talk")
	assert_eq(KeyBindings.with_device("map", "close", true, PadInput.PLAYSTATION_4), "Share: close")
	ActiveDevice.reset()
	var press := _pad(JOY_BUTTON_A)
	press.pressed = true
	ActiveDevice.note_named(press, "PS5 Controller")
	assert_eq(KeyBindings.with_key("interact", "Talk"), "Square: Talk", "with_key follows the active device")
	assert_eq(KeyBindings.prompt_label("potion"), "L1")
	ActiveDevice.reset()
	assert_eq(KeyBindings.with_key("interact", "Talk"), "E: Talk")
	assert_eq(KeyBindings.prompt_label("potion"), "H")
