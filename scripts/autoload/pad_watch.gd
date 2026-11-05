extends Node

# Wires the controller rules into the game: every input event goes to ActiveDevice, the cursor hides
# while a pad plays and comes back as it was once the mouse or keyboard is used, and unplugging the pad
# being played with drops play back to the keyboard and says so, which pauses a run. Plugging one in
# needs nothing: its first press makes it the active device.

signal device_changed
signal pad_lost

# While the pad hides the cursor: the mode the scene asked for, and the hidden mode set in its place.
var _wanted := -1
var _set := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _input(event: InputEvent) -> void:
	if ActiveDevice.note(event):
		_on_device_changed()


# A scene may set its own mouse mode at any time (a card table shows the cursor), so while the pad
# plays the cursor is hidden again each frame, and the scene's wish is kept for when the mouse returns.
func _process(_delta: float) -> void:
	if ActiveDevice.using_pad and Input.mouse_mode != _set:
		_wanted = Input.mouse_mode
		_set = ActiveDevice.hidden_mode(_wanted)
		Input.mouse_mode = _set as Input.MouseMode


func _on_device_changed() -> void:
	if not ActiveDevice.using_pad and _wanted != -1:
		if Input.mouse_mode == _set:
			Input.mouse_mode = _wanted as Input.MouseMode
		_wanted = -1
		_set = -1
	device_changed.emit()


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected:
		return
	if ActiveDevice.lost(device):
		_on_device_changed()
		pad_lost.emit()
