extends TestCase

# The controller's pure rules: the default layout, button names by family, the stick's dead zone and
# aim point, and which device an input event belongs to.


func _button(index: int, pressed := true) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = index as JoyButton
	event.pressed = pressed
	return event


func _axis(axis: int, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis as JoyAxis
	event.axis_value = value
	return event


func _pad_events(action: String) -> Array[InputEvent]:
	var found: Array[InputEvent] = []
	for event in InputMap.action_get_events(action):
		if PadInput.is_pad(event):
			found.append(event)
	return found


func test_no_action_is_left_without_a_controller_binding() -> void:
	KeyBindings.reset_to_defaults()
	for entry in KeyBindings.ACTIONS:
		var action: String = entry["action"]
		assert_true(PadInput.default_event(action) != null, "%s has a default pad binding" % action)
		assert_false(_pad_events(action).is_empty(), "%s is bound on the controller" % action)


func test_no_two_actions_share_a_controller_binding() -> void:
	var seen: Array[InputEvent] = []
	for entry in KeyBindings.ACTIONS:
		var event := PadInput.default_event(entry["action"])
		for other in seen:
			assert_false(PadInput.same(event, other), "%s shares its pad binding" % entry["action"])
		seen.append(event)


func test_the_default_layout_follows_the_spec() -> void:
	var xbox := PadInput.XBOX
	assert_eq(PadInput.describe(PadInput.default_event("attack"), xbox), "RT")
	assert_eq(PadInput.describe(PadInput.default_event("throw"), xbox), "LT")
	assert_eq(PadInput.describe(PadInput.default_event("dodge"), xbox), "A")
	assert_eq(PadInput.describe(PadInput.default_event("interact"), xbox), "X")
	assert_eq(PadInput.describe(PadInput.default_event("bomb"), xbox), "RB")
	assert_eq(PadInput.describe(PadInput.default_event("potion"), xbox), "LB")
	assert_eq(PadInput.describe(PadInput.default_event("map"), xbox), "View")
	assert_eq(PadInput.describe(PadInput.default_event("pause"), xbox), "Menu")
	assert_eq(PadInput.describe(PadInput.default_event("move_left"), xbox), "Left Stick Left")
	assert_eq(PadInput.describe(PadInput.default_event("move_down"), xbox), "Left Stick Down")


func test_the_d_pad_always_moves_as_well_as_the_stick() -> void:
	KeyBindings.reset_to_defaults()
	var ways := {"move_up": JOY_BUTTON_DPAD_UP, "move_down": JOY_BUTTON_DPAD_DOWN, "move_left": JOY_BUTTON_DPAD_LEFT, "move_right": JOY_BUTTON_DPAD_RIGHT}
	for action: String in ways:
		var extras := PadInput.extras(action)
		assert_eq(extras.size(), 1)
		assert_true(PadInput.same(extras[0], _button(ways[action])), action)
		assert_eq(_pad_events(action).size(), 2, "%s has the stick and the D-pad" % action)
	assert_true(PadInput.extras("dodge").is_empty())


func test_menus_confirm_back_out_and_switch_tabs_on_the_pad() -> void:
	KeyBindings.reset_to_defaults()
	var has := func(action: String, button: int) -> bool:
		return InputMap.action_get_events(action).any(func(e): return PadInput.same(e, _button(button)))
	assert_true(has.call("ui_accept", JOY_BUTTON_A), "A confirms")
	assert_true(has.call(PadInput.BACK_ACTION, JOY_BUTTON_B), "B backs out")
	assert_true(has.call(PadInput.TAB_PREV_ACTION, JOY_BUTTON_LEFT_SHOULDER))
	assert_true(has.call(PadInput.TAB_NEXT_ACTION, JOY_BUTTON_RIGHT_SHOULDER))
	assert_false(InputMap.action_get_events("ui_cancel").any(func(e): return PadInput.is_pad(e)), "B is never a second Esc")


func test_xbox_style_names() -> void:
	var names := {JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y", JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB", JOY_BUTTON_BACK: "View", JOY_BUTTON_START: "Menu"}
	for button: int in names:
		assert_eq(PadInput.button_name(button, PadInput.XBOX), names[button])
	assert_eq(PadInput.axis_name(JOY_AXIS_TRIGGER_LEFT, 1.0, PadInput.XBOX), "LT")
	assert_eq(PadInput.axis_name(JOY_AXIS_TRIGGER_RIGHT, 1.0, PadInput.XBOX), "RT")


func test_playstation_style_names() -> void:
	var names := {JOY_BUTTON_A: "Cross", JOY_BUTTON_B: "Circle", JOY_BUTTON_X: "Square", JOY_BUTTON_Y: "Triangle", JOY_BUTTON_LEFT_SHOULDER: "L1", JOY_BUTTON_RIGHT_SHOULDER: "R1", JOY_BUTTON_BACK: "Create", JOY_BUTTON_START: "Options"}
	for button: int in names:
		assert_eq(PadInput.button_name(button, PadInput.PLAYSTATION), names[button])
	assert_eq(PadInput.button_name(JOY_BUTTON_BACK, PadInput.PLAYSTATION_4), "Share", "the older pad's button says Share")
	assert_eq(PadInput.button_name(JOY_BUTTON_A, PadInput.PLAYSTATION_4), "Cross")
	assert_eq(PadInput.axis_name(JOY_AXIS_TRIGGER_LEFT, 1.0, PadInput.PLAYSTATION), "L2")
	assert_eq(PadInput.axis_name(JOY_AXIS_TRIGGER_RIGHT, 1.0, PadInput.PLAYSTATION), "R2")


func test_the_family_comes_from_the_pad_name() -> void:
	assert_eq(PadInput.family_for("Xbox Series Controller"), PadInput.XBOX)
	assert_eq(PadInput.family_for("PS5 Controller"), PadInput.PLAYSTATION)
	assert_eq(PadInput.family_for("DualSense Wireless Controller"), PadInput.PLAYSTATION)
	assert_eq(PadInput.family_for("Sony Interactive Entertainment Wireless Controller"), PadInput.PLAYSTATION)
	assert_eq(PadInput.family_for("PS4 Controller"), PadInput.PLAYSTATION_4)
	assert_eq(PadInput.family_for("DUALSHOCK 4 Wireless Controller"), PadInput.PLAYSTATION_4)
	assert_eq(PadInput.family_for("Nintendo Switch Pro Controller"), PadInput.XBOX, "anything else gets Xbox-style names")
	assert_eq(PadInput.family_for(""), PadInput.XBOX)


func test_describing_anything_else_says_so() -> void:
	assert_eq(PadInput.describe(null, PadInput.XBOX), "?")
	assert_eq(PadInput.describe(InputEventKey.new(), PadInput.XBOX), "?")
	assert_eq(PadInput.describe(_axis(JOY_AXIS_RIGHT_Y, -1.0), PadInput.XBOX), "Right Stick Up")
	assert_eq(PadInput.describe(_button(JOY_BUTTON_DPAD_UP), PadInput.PLAYSTATION), "D-pad Up")
	assert_eq(PadInput.describe(_button(JOY_BUTTON_LEFT_STICK), PadInput.XBOX), "LS")
	assert_eq(PadInput.describe(_button(JOY_BUTTON_LEFT_STICK), PadInput.PLAYSTATION), "L3")


func test_the_stick_has_a_dead_zone() -> void:
	assert_eq(PadInput.stick_dir(Vector2(0.1, -0.15)), Vector2.ZERO)
	assert_eq(PadInput.stick_dir(Vector2.ZERO), Vector2.ZERO)
	assert_true(PadInput.stick_dir(Vector2(0.5, 0.0)).is_equal_approx(Vector2.RIGHT))
	assert_true(PadInput.stick_dir(Vector2(0.3, 0.3)).is_equal_approx(Vector2(1, 1).normalized()))


func test_the_stick_aims_at_a_point_a_fixed_way_out() -> void:
	var from := Vector2(100, 50)
	assert_true(PadInput.aim_point(from, Vector2(0.0, -1.0), Vector2.RIGHT).is_equal_approx(from + Vector2.UP * PadInput.AIM_REACH))
	assert_true(PadInput.aim_point(from, Vector2(0.4, 0.4), Vector2.RIGHT).is_equal_approx(from + Vector2(1, 1).normalized() * PadInput.AIM_REACH))
	assert_true(PadInput.aim_point(from, Vector2(0.05, 0.0), Vector2.LEFT).is_equal_approx(from + Vector2.LEFT * PadInput.AIM_REACH), "a resting stick keeps the aim where it was")
	assert_true(PadInput.aim_point(from, Vector2.ZERO, Vector2.ZERO).is_equal_approx(from + Vector2.RIGHT * PadInput.AIM_REACH))


func test_which_device_an_event_comes_from() -> void:
	assert_eq(PadInput.device_of(_button(JOY_BUTTON_A)), PadInput.DEVICE_PAD)
	assert_eq(PadInput.device_of(_button(JOY_BUTTON_A, false)), "", "a release changes nothing")
	assert_eq(PadInput.device_of(_axis(JOY_AXIS_LEFT_X, 0.9)), PadInput.DEVICE_PAD)
	assert_eq(PadInput.device_of(_axis(JOY_AXIS_LEFT_X, 0.1)), "", "stick drift changes nothing")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	assert_eq(PadInput.device_of(key), PadInput.DEVICE_KEYS)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	assert_eq(PadInput.device_of(click), PadInput.DEVICE_KEYS)
	var move := InputEventMouseMotion.new()
	move.relative = Vector2(12, 0)
	assert_eq(PadInput.device_of(move), PadInput.DEVICE_KEYS)
	var jitter := InputEventMouseMotion.new()
	jitter.relative = Vector2(1, 0)
	assert_eq(PadInput.device_of(jitter), "", "a nudged mouse changes nothing")


func test_capturing_a_new_binding() -> void:
	var taken := PadInput.capture(_button(JOY_BUTTON_Y))
	assert_true(taken is InputEventJoypadButton and taken.button_index == JOY_BUTTON_Y)
	assert_true(PadInput.capture(_button(JOY_BUTTON_Y, false)) == null, "releases are skipped")
	assert_true(PadInput.capture(_button(JOY_BUTTON_DPAD_UP)) == null, "the D-pad is never bound")
	assert_true(PadInput.capture(_axis(JOY_AXIS_TRIGGER_LEFT, 0.3)) == null, "a half press is skipped")
	var trigger := PadInput.capture(_axis(JOY_AXIS_TRIGGER_LEFT, 0.95))
	assert_true(trigger is InputEventJoypadMotion and trigger.axis == JOY_AXIS_TRIGGER_LEFT and trigger.axis_value == 1.0)
	var stick := PadInput.capture(_axis(JOY_AXIS_RIGHT_Y, -0.8))
	assert_true(stick is InputEventJoypadMotion and stick.axis_value == -1.0)
	assert_true(PadInput.capture(InputEventKey.new()) == null)


func test_pad_bindings_round_trip_as_raw() -> void:
	for event: InputEvent in [_button(JOY_BUTTON_X), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0), _axis(JOY_AXIS_LEFT_Y, -1.0)]:
		var back := PadInput.from_raw(JSON.parse_string(JSON.stringify(PadInput.to_raw(event))))
		assert_true(back != null and PadInput.same(back, event), str(PadInput.to_raw(event)))
	assert_true(PadInput.from_raw({"type": "joy_button"}) == null)
	assert_true(PadInput.from_raw("junk") == null)
	assert_true(PadInput.from_raw({"type": "joy_axis", "axis": 1, "sign": 0}) == null)


func test_a_synthetic_trigger_press_swings() -> void:
	KeyBindings.reset_to_defaults()
	Input.parse_input_event(_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0))
	Input.flush_buffered_events()
	assert_true(Input.is_action_pressed("attack"), "the right trigger holds attack")
	Input.parse_input_event(_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0))
	Input.flush_buffered_events()
	assert_false(Input.is_action_pressed("attack"))


func test_the_left_stick_walks() -> void:
	KeyBindings.reset_to_defaults()
	Input.parse_input_event(_axis(JOY_AXIS_LEFT_X, -1.0))
	Input.flush_buffered_events()
	assert_true(Input.get_vector("move_left", "move_right", "move_up", "move_down").x < -0.9)
	Input.parse_input_event(_axis(JOY_AXIS_LEFT_X, 0.0))
	Input.flush_buffered_events()
	assert_eq(Input.get_vector("move_left", "move_right", "move_up", "move_down"), Vector2.ZERO)
