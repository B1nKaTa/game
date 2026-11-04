class_name ActiveDevice
extends RefCounted

# Whichever device the player used last: the keyboard and mouse, or a controller. Prompts name the
# active one's buttons, and the cursor hides while a pad plays. The PadWatch autoload feeds it every
# input event; tests and probes call it directly.

static var using_pad := false
# The pad last used, kept after the keyboard takes over, or -1 for none.
static var pad_id := -1
static var family := PadInput.XBOX


static func reset() -> void:
	using_pad = false
	pad_id = -1
	family = PadInput.XBOX


# Returns true when the active device changed.
static func note(event: InputEvent) -> bool:
	var name_of := Input.get_joy_name(event.device) if PadInput.is_pad(event) else ""
	return note_named(event, name_of)


static func note_named(event: InputEvent, joy_name: String) -> bool:
	match PadInput.device_of(event):
		PadInput.DEVICE_PAD:
			var changed := not using_pad or event.device != pad_id
			using_pad = true
			pad_id = event.device
			family = PadInput.family_for(joy_name)
			return changed
		PadInput.DEVICE_KEYS:
			if using_pad:
				using_pad = false
				return true
	return false


# A pad was unplugged. Returns true when it was the one being played with, which hands play back to
# the keyboard and mouse.
static func lost(device: int) -> bool:
	if device != pad_id:
		return false
	var was_playing := using_pad
	using_pad = false
	pad_id = -1
	return was_playing


# The mouse mode that hides the cursor but keeps the mode's confinement.
static func hidden_mode(mode: Input.MouseMode) -> Input.MouseMode:
	if mode == Input.MOUSE_MODE_VISIBLE:
		return Input.MOUSE_MODE_HIDDEN
	if mode == Input.MOUSE_MODE_CONFINED:
		return Input.MOUSE_MODE_CONFINED_HIDDEN
	return mode
