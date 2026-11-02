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

var _index := 0
var _label: Label


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var background := ColorRect.new()
	background.color = Color("100e14")
	background.size = Vector2(640, 360)
	layer.add_child(background)
	_label = Label.new()
	_label.position = Vector2(40, 150)
	_label.size = Vector2(560, 60)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	layer.add_child(_label)
	_label.text = LINES[0]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") or event.is_action_pressed("dodge") or event.is_action_pressed("interact"):
		_index += 1
		if _index >= LINES.size():
			Game.finish_opening()
		else:
			_label.text = LINES[_index]
