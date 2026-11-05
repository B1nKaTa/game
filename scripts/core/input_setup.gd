class_name InputSetup
extends RefCounted

# Every action's default bindings: one key or mouse button, one controller input (PadInput's layout),
# and the D-pad beside the stick for walking. The menus get the pad too: A confirms, B backs out and
# the shoulder buttons switch tabs.


static func ensure() -> void:
	_action("move_left", _key(KEY_A))
	_action("move_right", _key(KEY_D))
	_action("move_up", _key(KEY_W))
	_action("move_down", _key(KEY_S))
	_action("dodge", _key(KEY_SPACE))
	_action("interact", _key(KEY_E))
	_action("map", _key(KEY_M))
	_action("case_file", _key(KEY_TAB))
	_action("bomb", _key(KEY_Q))
	_action("potion", _key(KEY_H))
	_action("pause", _key(KEY_ESCAPE))
	_action("attack", _mouse(MOUSE_BUTTON_LEFT))
	_action("throw", _mouse(MOUSE_BUTTON_RIGHT))
	_menu("ui_accept", JOY_BUTTON_A)
	_menu(PadInput.BACK_ACTION, JOY_BUTTON_B)
	_menu(PadInput.TAB_PREV_ACTION, JOY_BUTTON_LEFT_SHOULDER)
	_menu(PadInput.TAB_NEXT_ACTION, JOY_BUTTON_RIGHT_SHOULDER)


static func _action(action: String, event: InputEvent) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, PadInput.ACTION_DEAD_ZONE)
	InputMap.action_add_event(action, event)
	var pad := PadInput.default_event(action)
	if pad != null:
		InputMap.action_add_event(action, pad)
	for extra in PadInput.extras(action):
		InputMap.action_add_event(action, extra)


static func _menu(action: String, index: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := PadInput.button(index)
	for existing in InputMap.action_get_events(action):
		if PadInput.same(existing, event):
			return
	InputMap.action_add_event(action, event)


static func _key(key: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = key
	return event


static func _mouse(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	return event
