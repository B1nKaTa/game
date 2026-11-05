class_name KeyBindings
extends RefCounted

# Every action has two bindings, one per column of the Input tab: a key or mouse button, and a
# controller input. The D-pad walks beside the stick and is never rebound (PadInput.extras). Both
# columns live in keys.json, the controller one under PAD_KEY, so an older file without it loads
# unchanged and keeps the controller defaults.

const SAVE_PATH := "user://keys.json"
const ACTIONS := [
	{"action": "move_up", "label": "Move up"},
	{"action": "move_down", "label": "Move down"},
	{"action": "move_left", "label": "Move left"},
	{"action": "move_right", "label": "Move right"},
	{"action": "attack", "label": "Attack, hold to charge"},
	{"action": "throw", "label": "Throw dentures"},
	{"action": "dodge", "label": "Dodge"},
	{"action": "bomb", "label": "Place Thermos"},
	{"action": "potion", "label": "Drink potion"},
	{"action": "interact", "label": "Interact"},
	{"action": "map", "label": "Floor map"},
	{"action": "case_file", "label": "Case file"},
	{"action": "pause", "label": "Pause / back"},
]
const TYPE_KEY := "key"
# The controller column's bindings, under their own key in keys.json.
const PAD_KEY := "pad"
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
	if PadInput.is_pad(event):
		return PadInput.describe(event, ActiveDevice.family)
	return "?"


# The action's key or mouse button.
static func key_event(action: String) -> InputEvent:
	return _slot(action, false)


# The action's rebindable controller input, never the D-pad that walks beside it.
static func pad_event(action: String) -> InputEvent:
	return _slot(action, true)


# The keyboard column's label.
static func label_for(action: String) -> String:
	if not InputMap.has_action(action):
		return "?"
	var event := key_event(action)
	return describe(event) if event != null else "?"


# The controller column's label, in the named family's button names.
static func pad_label_for(action: String, family: String) -> String:
	if not InputMap.has_action(action):
		return "?"
	return PadInput.describe(pad_event(action), family)


# The label a prompt shows: the active device's binding for the action.
static func prompt_label(action: String) -> String:
	return pad_label_for(action, ActiveDevice.family) if ActiveDevice.using_pad else label_for(action)


# "E: Talk" on the keyboard, "X: Talk" or "Square: Talk" on a pad. Every prompt goes through here.
static func with_key(action: String, text: String) -> String:
	return with_device(action, text, ActiveDevice.using_pad, ActiveDevice.family)


static func with_device(action: String, text: String, pad: bool, family: String) -> String:
	var label := pad_label_for(action, family) if pad else label_for(action)
	return "%s: %s" % [label, text]


# Binds the input in its own column. If another action already uses it there, the two swap, so no
# action ever ends up without one. Returns the action it swapped with, or "" when the input was free.
static func rebind(action: String, event: InputEvent) -> String:
	var pad := PadInput.is_pad(event)
	var swapped := ""
	var previous := _slot(action, pad)
	for entry in ACTIONS:
		var other: String = entry["action"]
		if other == action or not InputMap.has_action(other):
			continue
		var other_event := _slot(other, pad)
		if other_event != null and previous != null and _same(other_event, event):
			_set_slot(other, pad, previous)
			swapped = other
	_set_slot(action, pad, event)
	return swapped


# The label an action shows in menus, or the action's own name when it has none.
static func action_label(action: String) -> String:
	for entry in ACTIONS:
		if entry["action"] == action:
			return entry["label"]
	return action


# Every action's bindings as they would be saved, to put back with restore.
static func snapshot() -> Dictionary:
	var raw := {}
	var pads := {}
	for entry in ACTIONS:
		var action: String = entry["action"]
		if not InputMap.has_action(action):
			continue
		var key := key_event(action)
		if key != null:
			raw[action] = _to_raw(key)
		var pad := pad_event(action)
		if pad != null:
			pads[action] = PadInput.to_raw(pad)
	raw[PAD_KEY] = pads
	return raw


# Puts back bindings from snapshot exactly, without swapping.
static func restore(raw: Dictionary) -> void:
	var pads: Variant = raw.get(PAD_KEY, {})
	for entry in ACTIONS:
		var action: String = entry["action"]
		if not InputMap.has_action(action):
			continue
		if raw.has(action):
			var event := _from_raw(raw[action])
			if event != null:
				_set_slot(action, false, event)
		if pads is Dictionary and pads.has(action):
			var pad := PadInput.from_raw(pads[action])
			if pad != null:
				_set_slot(action, true, pad)


static func reset_to_defaults() -> void:
	for entry in ACTIONS:
		if InputMap.has_action(entry["action"]):
			InputMap.erase_action(entry["action"])
	InputSetup.ensure()


static func save_to(path := SAVE_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(snapshot()))
	file.close()
	return true


# Anything missing or damaged in the file just keeps its default. Loading swaps like a rebind,
# so a file older than a new action can't leave that action's default on two actions.
static func load_from(path := SAVE_PATH) -> void:
	if not FileAccess.file_exists(path):
		return
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not raw is Dictionary:
		return
	var pads: Variant = raw.get(PAD_KEY, {})
	for entry in ACTIONS:
		var action: String = entry["action"]
		if not InputMap.has_action(action):
			continue
		if raw.has(action):
			var event := _from_raw(raw[action])
			if event != null:
				rebind(action, event)
		if pads is Dictionary and pads.has(action):
			var pad := PadInput.from_raw(pads[action])
			if pad != null:
				rebind(action, pad)


static func _slot(action: String, pad: bool) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	var extras := PadInput.extras(action)
	for event in InputMap.action_get_events(action):
		if PadInput.is_pad(event) != pad:
			continue
		if pad and extras.any(func(extra: InputEvent) -> bool: return PadInput.same(extra, event)):
			continue
		return event
	return null


# Rewrites the action as its key, its pad input and its fixed extras, in that order.
static func _set_slot(action: String, pad: bool, event: InputEvent) -> void:
	var key := event if not pad else key_event(action)
	var pad_input := event if pad else pad_event(action)
	InputMap.action_erase_events(action)
	if key != null:
		InputMap.action_add_event(action, key)
	if pad_input != null:
		InputMap.action_add_event(action, pad_input)
	for extra in PadInput.extras(action):
		InputMap.action_add_event(action, extra)


static func _same(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		return a.physical_keycode == b.physical_keycode
	if a is InputEventMouseButton and b is InputEventMouseButton:
		return a.button_index == b.button_index
	return PadInput.same(a, b)


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
