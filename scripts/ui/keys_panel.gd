class_name KeysPanel
extends CanvasLayer

signal closed

const WAITING_TEXT := "Press a key..."
const BUTTON_FONT_SIZE := 12
const BUTTON_WIDTH := 270.0

var _list: GridContainer
var _waiting_action := ""


func _ready() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(40, 40)
	add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var title := Label.new()
	title.text = "Key Settings. Esc cancels a change."
	column.add_child(title)
	# Two columns, because ten actions in one column run off the 360 pixel screen.
	_list = GridContainer.new()
	_list.columns = 2
	column.add_child(_list)
	var reset := _make_button("Reset to defaults")
	reset.pressed.connect(_reset)
	column.add_child(reset)
	var close := _make_button("Leave")
	close.pressed.connect(func(): closed.emit())
	column.add_child(close)
	_rebuild()


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	return button


func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()
	for entry in KeyBindings.ACTIONS:
		var action: String = entry["action"]
		var bound := WAITING_TEXT if action == _waiting_action else KeyBindings.label_for(action)
		var button := _make_button("%s:  %s" % [entry["label"], bound])
		button.custom_minimum_size.x = BUTTON_WIDTH
		button.pressed.connect(_start_waiting.bind(action))
		_list.add_child(button)


func _start_waiting(action: String) -> void:
	_waiting_action = action
	_rebuild()


func _reset() -> void:
	_waiting_action = ""
	KeyBindings.reset_to_defaults()
	KeyBindings.save_to()
	_rebuild()


# This runs before the buttons see the input, so the next press is taken as the new binding.
func _input(event: InputEvent) -> void:
	if _waiting_action.is_empty() or not event.is_pressed() or event.is_echo():
		return
	if not (event is InputEventKey or event is InputEventMouseButton):
		return
	get_viewport().set_input_as_handled()
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
		_waiting_action = ""
		_rebuild()
		return
	KeyBindings.rebind(_waiting_action, _clean_copy(event))
	KeyBindings.save_to()
	_waiting_action = ""
	_rebuild()


func _clean_copy(event: InputEvent) -> InputEvent:
	if event is InputEventKey:
		var key := InputEventKey.new()
		key.physical_keycode = event.physical_keycode
		return key
	var mouse := InputEventMouseButton.new()
	mouse.button_index = event.button_index
	return mouse
