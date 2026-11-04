class_name PauseMenu
extends CanvasLayer

# Esc during a run or in the Waiting Room. The scene that opens it pauses the tree; this menu runs
# anyway, as do Options and any question it asks. Esc again resumes. The scene does the saving and
# quitting the buttons ask for: in a run, "Save and Quit" writes the run checkpoint first.

signal resumed
signal quit_wanted(to_desktop: bool)

const LAYER := 50
const WIDTH := 200.0

var _in_run := true
var _opened_frame := -1
var _options: OptionsPanel
var _options_closed_frame := -1
var _first: Button
var _done := false


func setup(in_run: bool) -> void:
	_in_run = in_run


# The scenes' own Esc handling leaves this alone, since it answers Esc itself.
func handles_pause_key() -> bool:
	return true


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_opened_frame = Engine.get_process_frames()
	add_child(MenuStyle.backing(MenuStyle.SHADE))
	var holder := PanelContainer.new()
	holder.add_theme_stylebox_override("panel", MenuStyle.box(MenuStyle.BACK, MenuStyle.GOLD))
	add_child(holder)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.custom_minimum_size.x = WIDTH
	holder.add_child(column)
	var title := MenuStyle.label(tr("Paused"), MenuStyle.TITLE_FONT, MenuStyle.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_first = _add(column, tr("Resume"), _resume)
	_add(column, tr("Options"), _open_options)
	_add(column, tr("Save and Quit to Title") if _in_run else tr("Quit to Title"), _quit.bind(false))
	_add(column, tr("Quit to Desktop"), _quit.bind(true))
	holder.reset_size()
	holder.position = ((Vector2(GameSettings.VIEW) - holder.get_combined_minimum_size()) / 2.0).floor()
	_first.grab_focus.call_deferred()


func _add(column: VBoxContainer, text: String, action: Callable) -> Button:
	var button := MenuStyle.button(text, 12)
	button.pressed.connect(action)
	column.add_child(button)
	return button


func _process(_delta: float) -> void:
	var frame := Engine.get_process_frames()
	if _options != null or frame == _opened_frame or frame == _options_closed_frame:
		return
	if Input.is_action_just_pressed("pause"):
		_resume()


func _open_options() -> void:
	if _options != null:
		return
	_options = OptionsPanel.new()
	_options.closed.connect(_close_options)
	add_child(_options)


func _close_options() -> void:
	if _options == null:
		return
	_options.queue_free()
	_options = null
	_options_closed_frame = Engine.get_process_frames()
	_first.grab_focus.call_deferred()


func _resume() -> void:
	if _done:
		return
	_done = true
	resumed.emit()


func _quit(to_desktop: bool) -> void:
	if _done:
		return
	_done = true
	quit_wanted.emit(to_desktop)
