extends TestCase

# Whichever device was used last is the active one: prompts name its buttons and the cursor hides
# while a pad plays.


func _button(index: int, device := 0) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = index as JoyButton
	event.pressed = true
	event.device = device
	return event


func _axis(index: int, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = index as JoyAxis
	event.axis_value = value
	return event


func _key() -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_W
	event.pressed = true
	return event


func test_it_starts_on_the_keyboard_and_mouse() -> void:
	ActiveDevice.reset()
	assert_false(ActiveDevice.using_pad)
	assert_eq(ActiveDevice.pad_id, -1)
	assert_eq(ActiveDevice.family, PadInput.XBOX)


func test_a_pad_press_makes_the_pad_active() -> void:
	ActiveDevice.reset()
	assert_true(ActiveDevice.note(_button(JOY_BUTTON_A, 2)), "the device changed")
	assert_true(ActiveDevice.using_pad)
	assert_eq(ActiveDevice.pad_id, 2)
	assert_false(ActiveDevice.note(_button(JOY_BUTTON_B, 2)), "the same pad again changes nothing")
	ActiveDevice.reset()


func test_drift_never_takes_over() -> void:
	ActiveDevice.reset()
	assert_false(ActiveDevice.note(_axis(JOY_AXIS_RIGHT_X, 0.12)))
	assert_false(ActiveDevice.using_pad)
	assert_true(ActiveDevice.note(_axis(JOY_AXIS_RIGHT_X, 0.9)))
	assert_true(ActiveDevice.using_pad)
	ActiveDevice.reset()


func test_a_key_hands_it_back() -> void:
	ActiveDevice.reset()
	ActiveDevice.note(_button(JOY_BUTTON_A))
	assert_true(ActiveDevice.note(_key()))
	assert_false(ActiveDevice.using_pad)
	assert_eq(ActiveDevice.pad_id, 0, "the pad last used is still known")
	assert_false(ActiveDevice.note(_key()))


func test_the_family_follows_the_pads_name() -> void:
	ActiveDevice.reset()
	ActiveDevice.note_named(_button(JOY_BUTTON_A), "DualSense Wireless Controller")
	assert_eq(ActiveDevice.family, PadInput.PLAYSTATION)
	ActiveDevice.note_named(_button(JOY_BUTTON_A, 1), "Xbox Wireless Controller")
	assert_eq(ActiveDevice.family, PadInput.XBOX)
	assert_eq(ActiveDevice.pad_id, 1)
	ActiveDevice.reset()


func test_losing_the_active_pad_drops_to_the_keyboard() -> void:
	ActiveDevice.reset()
	ActiveDevice.note(_button(JOY_BUTTON_A, 1))
	assert_false(ActiveDevice.lost(3), "another pad leaving is nothing to do with him")
	assert_true(ActiveDevice.using_pad)
	assert_true(ActiveDevice.lost(1))
	assert_false(ActiveDevice.using_pad)
	assert_eq(ActiveDevice.pad_id, -1)


func test_losing_a_pad_not_in_use_changes_nothing() -> void:
	ActiveDevice.reset()
	ActiveDevice.note(_button(JOY_BUTTON_A, 0))
	ActiveDevice.note(_key())
	assert_false(ActiveDevice.lost(0), "he was on the keyboard already")
	ActiveDevice.reset()


func test_the_cursor_hides_while_a_pad_plays() -> void:
	assert_eq(ActiveDevice.hidden_mode(Input.MOUSE_MODE_VISIBLE), Input.MOUSE_MODE_HIDDEN)
	assert_eq(ActiveDevice.hidden_mode(Input.MOUSE_MODE_CONFINED), Input.MOUSE_MODE_CONFINED_HIDDEN)
	assert_eq(ActiveDevice.hidden_mode(Input.MOUSE_MODE_HIDDEN), Input.MOUSE_MODE_HIDDEN)
	assert_eq(ActiveDevice.hidden_mode(Input.MOUSE_MODE_CONFINED_HIDDEN), Input.MOUSE_MODE_CONFINED_HIDDEN)
