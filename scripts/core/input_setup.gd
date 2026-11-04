class_name InputSetup
extends RefCounted


static func ensure() -> void:
	_key("move_left", KEY_A)
	_key("move_right", KEY_D)
	_key("move_up", KEY_W)
	_key("move_down", KEY_S)
	_key("dodge", KEY_SPACE)
	_key("interact", KEY_E)
	_key("map", KEY_M)
	_key("bomb", KEY_Q)
	_key("potion", KEY_H)
	_key("pause", KEY_ESCAPE)
	_mouse("attack", MOUSE_BUTTON_LEFT)
	_mouse("throw", MOUSE_BUTTON_RIGHT)


static func _key(action: String, key: Key) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)


static func _mouse(action: String, button: MouseButton) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var event := InputEventMouseButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)
