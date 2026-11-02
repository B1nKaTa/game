extends TestCase

const PATH := "user://test_keys.json"


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
	var events := InputMap.action_get_events("bomb")
	assert_eq(events.size(), 1)
	assert_eq(KeyBindings.describe(events[0]), "F")
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


func test_prompts_follow_the_bound_key() -> void:
	_reset()
	assert_eq(KeyBindings.with_key("interact", "Buy"), "E: Buy")
	KeyBindings.rebind("interact", _key(KEY_F))
	assert_eq(KeyBindings.with_key("interact", "Buy"), "F: Buy")
	_reset()
