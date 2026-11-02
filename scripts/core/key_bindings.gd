class_name KeyBindings
extends RefCounted

const SAVE_PATH := "user://keys.json"
const ACTIONS := [
	{"action": "move_up", "label": "Move up"},
	{"action": "move_down", "label": "Move down"},
	{"action": "move_left", "label": "Move left"},
	{"action": "move_right", "label": "Move right"},
	{"action": "attack", "label": "Attack, hold to charge"},
	{"action": "throw", "label": "Throw cane"},
	{"action": "dodge", "label": "Dodge"},
	{"action": "bomb", "label": "Place Thermos"},
	{"action": "interact", "label": "Interact"},
	{"action": "map", "label": "Floor map"},
]
const TYPE_KEY := "key"
const TYPE_MOUSE := "mouse"


static func describe(event: InputEvent) -> String:
	if event is InputEventKey:
		return OS.get_keycode_string(event.physical_keycode)
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				return "Left Click"
			MOUSE_BUTTON_RIGHT:
				return "Right Click"
			_:
				return "Mouse %d" % event.button_index
	return "?"


static func label_for(action: String) -> String:
	if not InputMap.has_action(action):
		return "?"
	var events := InputMap.action_get_events(action)
	return describe(events[0]) if not events.is_empty() else "?"


static func with_key(action: String, text: String) -> String:
	return "%s: %s" % [label_for(action), text]


# If another action already uses this input, the two swap, so no action ever ends up without one.
static func rebind(action: String, event: InputEvent) -> void:
	var previous: InputEvent = null
	var current := InputMap.action_get_events(action)
	if not current.is_empty():
		previous = current[0]
	for entry in ACTIONS:
		var other: String = entry["action"]
		if other == action or not InputMap.has_action(other):
			continue
		for other_event in InputMap.action_get_events(other):
			if _same(other_event, event) and previous != null:
				_set_event(other, previous)
	_set_event(action, event)


static func reset_to_defaults() -> void:
	for entry in ACTIONS:
		if InputMap.has_action(entry["action"]):
			InputMap.erase_action(entry["action"])
	InputSetup.ensure()


static func save_to(path := SAVE_PATH) -> bool:
	var raw := {}
	for entry in ACTIONS:
		var action: String = entry["action"]
		if not InputMap.has_action(action):
			continue
		var events := InputMap.action_get_events(action)
		if not events.is_empty():
			raw[action] = _to_raw(events[0])
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(raw))
	file.close()
	return true


# Anything missing or damaged in the file just keeps its default.
static func load_from(path := SAVE_PATH) -> void:
	if not FileAccess.file_exists(path):
		return
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not raw is Dictionary:
		return
	for entry in ACTIONS:
		var action: String = entry["action"]
		if raw.has(action) and InputMap.has_action(action):
			var event := _from_raw(raw[action])
			if event != null:
				_set_event(action, event)


static func _set_event(action: String, event: InputEvent) -> void:
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)


static func _same(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		return a.physical_keycode == b.physical_keycode
	if a is InputEventMouseButton and b is InputEventMouseButton:
		return a.button_index == b.button_index
	return false


static func _to_raw(event: InputEvent) -> Dictionary:
	if event is InputEventMouseButton:
		return {"type": TYPE_MOUSE, "button": int(event.button_index)}
	return {"type": TYPE_KEY, "code": int(event.physical_keycode)}


static func _from_raw(raw: Variant) -> InputEvent:
	if not raw is Dictionary:
		return null
	if raw.get("type") == TYPE_KEY and raw.has("code"):
		var key := InputEventKey.new()
		key.physical_keycode = int(raw["code"]) as Key
		return key
	if raw.get("type") == TYPE_MOUSE and raw.has("button"):
		var mouse := InputEventMouseButton.new()
		mouse.button_index = int(raw["button"]) as MouseButton
		return mouse
	return null
