class_name ConfirmBox
extends CanvasLayer

# A small question over whatever panel asked it, such as "Discard changes?". Its choices are buttons;
# Esc picks the last one, which is always the safe one (Cancel, Keep editing). It runs while the game
# is paused, since the pause menu and Options ask questions too.

signal chosen(index: int)

const LAYER := 90
const WIDTH := 300.0

var _question := ""
var _choices: PackedStringArray = []
var _opened_frame := -1
var _done := false
var _first: Button


func setup(question: String, choices: PackedStringArray) -> void:
	_question = question
	_choices = choices


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_opened_frame = Engine.get_process_frames()
	add_child(MenuStyle.backing(MenuStyle.SHADE))
	var holder := PanelContainer.new()
	holder.add_theme_stylebox_override("panel", MenuStyle.box(MenuStyle.BACK, MenuStyle.GOLD))
	add_child(holder)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	holder.add_child(column)
	var text := MenuStyle.label(_question)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD
	text.custom_minimum_size.x = WIDTH
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(text)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	for i in _choices.size():
		var button := MenuStyle.button(_choices[i])
		button.pressed.connect(_choose.bind(i))
		row.add_child(button)
		if _first == null:
			_first = button
	# The box sizes itself to its text, then sits in the middle of the view.
	holder.reset_size()
	holder.position = ((Vector2(GameSettings.VIEW) - holder.get_combined_minimum_size()) / 2.0).floor()
	_first.grab_focus.call_deferred()


func _process(_delta: float) -> void:
	if Engine.get_process_frames() != _opened_frame and Input.is_action_just_pressed("pause"):
		_choose(_choices.size() - 1)


func _choose(index: int) -> void:
	if _done:
		return
	_done = true
	chosen.emit(index)
	queue_free()
