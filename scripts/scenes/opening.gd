extends Node2D

const LINES := [
	"Harold, 87. Cause of death: stairs.",
	"\"Welcome to the afterlife. Please take a number.\"",
	"\"I'm not dead.\"",
	"\"Sir, you are extremely dead.\"",
	"\"I have a 40-year feud with my neighbor to finish.\"",
	"\"That's not how this works.\"",
	"He picks up his cane.",
]

const HINT := "Click or press %s to continue. %s to skip."

var _index := 0
var _label: Label
var _done := false


static func next_index(index: int, skip: bool) -> int:
	return LINES.size() if skip else mini(index + 1, LINES.size())


# The hint names the buttons of the device in use, a pad's own names on a pad.
static func hint_text() -> String:
	return TranslationServer.translate(HINT) % [KeyBindings.prompt_label("dodge"), KeyBindings.prompt_label("pause")]


func _ready() -> void:
	MusicPlayer.play(MusicRules.opening())
	var layer := CanvasLayer.new()
	add_child(layer)
	var background := ColorRect.new()
	background.color = Color("100e14")
	background.size = Vector2(640, 360)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(background)
	_label = Label.new()
	_label.position = Vector2(40, 150)
	_label.size = Vector2(560, 60)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	layer.add_child(_label)
	_label.text = LINES[0]
	var hint := Label.new()
	hint.text = hint_text()
	hint.position = Vector2(40, 325)
	hint.size = Vector2(560, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(1, 1, 1, 0.5)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hint)


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	var skip := event.is_action_pressed("pause") or event.is_action_pressed(PadInput.BACK_ACTION) or event.is_action_pressed("ui_cancel")
	var next := event.is_action_pressed("attack") or event.is_action_pressed("dodge") or event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")
	if not skip and not next:
		return
	_index = next_index(_index, skip)
	if _index >= LINES.size():
		_done = true
		Game.finish_opening()
	else:
		_label.text = LINES[_index]
