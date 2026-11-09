class_name PadInput
extends RefCounted

# The controller's rules, through Godot's own joypad input: the default layout, the button names a
# pad's family uses, the right stick's dead zone and aim point, which device an input came from, and
# what may be bound on the Input tab. The D-pad always moves and always moves menu focus, so it is
# never bound to anything else.

const XBOX := "xbox"
const PLAYSTATION := "playstation"
# The older PlayStation pad's View-place button says Share; the newer one's says Create.
const PLAYSTATION_4 := "playstation_4"
const DEVICE_PAD := "pad"
const ALL_DEVICES := -1
const DEVICE_KEYS := "keys"
const TYPE_BUTTON := "joy_button"
const TYPE_AXIS := "joy_axis"
# Below this the right stick counts as resting, so a worn stick never turns his aim.
const STICK_DEAD_ZONE := 0.25
# How far out from Grandpa the right stick aims.
const AIM_REACH := 60.0
# Every action's own dead zone, for the sticks and triggers bound to it.
const ACTION_DEAD_ZONE := 0.25
# A stick or trigger must move this far to make the pad the active device, so drift never does.
const SWITCH_AXIS := 0.5
# And this far to be taken as a new binding on the Input tab.
const CAPTURE_AXIS := 0.6
# A mouse must move this many pixels at once to take over from the pad.
const SWITCH_MOUSE := 4.0
# Menu actions on the pad that are never rebound: B backs out of a panel as its Leave does, and the
# shoulder buttons switch tabs. Esc keeps its own action (pause), so B is never a second Esc.
const BACK_ACTION := "ui_pad_back"
const TAB_PREV_ACTION := "ui_tab_prev"
const TAB_NEXT_ACTION := "ui_tab_next"

const DEFAULT_BUTTONS := {
	"dodge": JOY_BUTTON_A,
	"interact": JOY_BUTTON_X,
	"bomb": JOY_BUTTON_RIGHT_SHOULDER,
	"potion": JOY_BUTTON_LEFT_SHOULDER,
	"flashback": JOY_BUTTON_Y,
	"map": JOY_BUTTON_BACK,
	# The DualSense's touchpad press. An Xbox pad has no such button, so it is named for both and can be rebound.
	"case_file": JOY_BUTTON_TOUCHPAD,
	"pause": JOY_BUTTON_START,
}
# Each as [axis, sign].
const DEFAULT_AXES := {
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"attack": [JOY_AXIS_TRIGGER_RIGHT, 1.0],
	"throw": [JOY_AXIS_TRIGGER_LEFT, 1.0],
}
const D_PAD := {
	"move_up": JOY_BUTTON_DPAD_UP,
	"move_down": JOY_BUTTON_DPAD_DOWN,
	"move_left": JOY_BUTTON_DPAD_LEFT,
	"move_right": JOY_BUTTON_DPAD_RIGHT,
}
const XBOX_NAMES := {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "View",
	JOY_BUTTON_GUIDE: "Guide",
	JOY_BUTTON_START: "Menu",
	JOY_BUTTON_LEFT_STICK: "LS",
	JOY_BUTTON_RIGHT_STICK: "RS",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_MISC1: "Share",
	JOY_BUTTON_TOUCHPAD: "Touchpad",
}
const PLAYSTATION_NAMES := {
	JOY_BUTTON_A: "Cross",
	JOY_BUTTON_B: "Circle",
	JOY_BUTTON_X: "Square",
	JOY_BUTTON_Y: "Triangle",
	JOY_BUTTON_BACK: "Create",
	JOY_BUTTON_GUIDE: "PS",
	JOY_BUTTON_START: "Options",
	JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "L1",
	JOY_BUTTON_RIGHT_SHOULDER: "R1",
	JOY_BUTTON_MISC1: "Mic",
	JOY_BUTTON_TOUCHPAD: "Touchpad",
}
const D_PAD_NAMES := {
	JOY_BUTTON_DPAD_UP: "D-pad Up",
	JOY_BUTTON_DPAD_DOWN: "D-pad Down",
	JOY_BUTTON_DPAD_LEFT: "D-pad Left",
	JOY_BUTTON_DPAD_RIGHT: "D-pad Right",
}
const TRIGGER_NAMES := {
	XBOX: {JOY_AXIS_TRIGGER_LEFT: "LT", JOY_AXIS_TRIGGER_RIGHT: "RT"},
	PLAYSTATION: {JOY_AXIS_TRIGGER_LEFT: "L2", JOY_AXIS_TRIGGER_RIGHT: "R2"},
}


static func default_event(action: String) -> InputEvent:
	if DEFAULT_BUTTONS.has(action):
		return button(DEFAULT_BUTTONS[action])
	if DEFAULT_AXES.has(action):
		return axis(DEFAULT_AXES[action][0], DEFAULT_AXES[action][1])
	return null


# The fixed bindings an action has besides its rebindable one: the D-pad for walking.
static func extras(action: String) -> Array[InputEvent]:
	var list: Array[InputEvent] = []
	if D_PAD.has(action):
		list.append(button(D_PAD[action]))
	return list


# A binding answers every pad (device -1), so a pad that is not the first one plugged in works too.
static func button(index: int) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = ALL_DEVICES
	event.button_index = index as JoyButton
	return event


static func axis(index: int, sign_of: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device = ALL_DEVICES
	event.axis = index as JoyAxis
	event.axis_value = 1.0 if sign_of > 0.0 else -1.0
	return event


static func family_for(joy_name: String) -> String:
	var lower := joy_name.to_lower()
	if lower.contains("ps4") or lower.contains("dualshock"):
		return PLAYSTATION_4
	for word in ["ps5", "ps3", "playstation", "dualsense", "sony"]:
		if lower.contains(word):
			return PLAYSTATION
	return XBOX


static func _is_playstation(family: String) -> bool:
	return family == PLAYSTATION or family == PLAYSTATION_4


static func button_name(index: int, family: String) -> String:
	if D_PAD_NAMES.has(index):
		return D_PAD_NAMES[index]
	if family == PLAYSTATION_4 and index == JOY_BUTTON_BACK:
		return "Share"
	var names: Dictionary = PLAYSTATION_NAMES if _is_playstation(family) else XBOX_NAMES
	return names.get(index, "Button %d" % index)


static func axis_name(index: int, sign_of: float, family: String) -> String:
	var triggers: Dictionary = TRIGGER_NAMES[PLAYSTATION if _is_playstation(family) else XBOX]
	if triggers.has(index):
		return triggers[index]
	var stick := "Left Stick" if index == JOY_AXIS_LEFT_X or index == JOY_AXIS_LEFT_Y else "Right Stick"
	var horizontal := index == JOY_AXIS_LEFT_X or index == JOY_AXIS_RIGHT_X
	if index > JOY_AXIS_TRIGGER_RIGHT:
		return "Axis %d%s" % [index, "+" if sign_of > 0.0 else "-"]
	if horizontal:
		return "%s %s" % [stick, "Right" if sign_of > 0.0 else "Left"]
	return "%s %s" % [stick, "Down" if sign_of > 0.0 else "Up"]


static func describe(event: InputEvent, family: String) -> String:
	if event is InputEventJoypadButton:
		return button_name(event.button_index, family)
	if event is InputEventJoypadMotion:
		return axis_name(event.axis, event.axis_value, family)
	return "?"


static func is_pad(event: InputEvent) -> bool:
	return event is InputEventJoypadButton or event is InputEventJoypadMotion


static func same(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index
	if a is InputEventJoypadMotion and b is InputEventJoypadMotion:
		return a.axis == b.axis and signf(a.axis_value) == signf(b.axis_value)
	return false


static func to_raw(event: InputEvent) -> Dictionary:
	if event is InputEventJoypadMotion:
		return {"type": TYPE_AXIS, "axis": int(event.axis), "sign": 1 if event.axis_value > 0.0 else -1}
	return {"type": TYPE_BUTTON, "button": int(event.button_index)}


static func from_raw(raw: Variant) -> InputEvent:
	if not raw is Dictionary:
		return null
	if raw.get("type") == TYPE_BUTTON and _is_number(raw.get("button")):
		var index := int(raw["button"])
		if index < 0 or index >= JOY_BUTTON_SDL_MAX or D_PAD_NAMES.has(index):
			return null
		return button(index)
	if raw.get("type") == TYPE_AXIS and _is_number(raw.get("axis")) and _is_number(raw.get("sign")):
		var index := int(raw["axis"])
		var sign_of := float(raw["sign"])
		if index < 0 or index >= JOY_AXIS_SDL_MAX or sign_of == 0.0:
			return null
		return axis(index, sign_of)
	return null


# A snapshot holds whole numbers and a file read back holds floats; both are fine.
static func _is_number(value: Variant) -> bool:
	return value is int or value is float


# The way a stick points, or ZERO while it rests inside the dead zone.
static func stick_dir(stick: Vector2) -> Vector2:
	if stick.length() < STICK_DEAD_ZONE:
		return Vector2.ZERO
	return stick.normalized()


# Where the right stick aims: AIM_REACH out from him the way it points. A resting stick keeps the
# way it last pointed, so the aim stays where it was.
static func aim_point(from: Vector2, stick: Vector2, last_dir: Vector2) -> Vector2:
	var way := stick_dir(stick)
	if way == Vector2.ZERO:
		way = last_dir.normalized() if not last_dir.is_zero_approx() else Vector2.RIGHT
	return from + way * AIM_REACH


# Which device an event shows the player using, or "" when it shows nothing (a release, drift, a nudge).
static func device_of(event: InputEvent) -> String:
	if event is InputEventJoypadButton:
		return DEVICE_PAD if event.pressed else ""
	if event is InputEventJoypadMotion:
		return DEVICE_PAD if absf(event.axis_value) >= SWITCH_AXIS else ""
	if event is InputEventKey or event is InputEventMouseButton:
		return DEVICE_KEYS if event.pressed else ""
	if event is InputEventMouseMotion:
		return DEVICE_KEYS if event.relative.length() >= SWITCH_MOUSE else ""
	return ""


# A clean pad event to bind from what was just pressed, or null for anything that may not be bound.
static func capture(event: InputEvent) -> InputEvent:
	if event is InputEventJoypadButton:
		if not event.pressed or D_PAD_NAMES.has(int(event.button_index)):
			return null
		return button(event.button_index)
	if event is InputEventJoypadMotion and absf(event.axis_value) >= CAPTURE_AXIS:
		return axis(event.axis, event.axis_value)
	return null
