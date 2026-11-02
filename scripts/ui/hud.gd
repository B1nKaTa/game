class_name Hud
extends CanvasLayer

var _run: RunState
var _status: Label
var _items: Label
var _message: Label
var _pension := 0


func setup(run: RunState) -> void:
	_run = run


func _ready() -> void:
	_status = _add_label(Vector2(8, 4), 12)
	_items = _add_label(Vector2(8, 340), 9)
	_message = _add_label(Vector2(0, 150), 20)
	_message.size = Vector2(640, 40)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _run != null:
		_run.changed.connect(_refresh)
	_refresh()


func set_pension(amount: int) -> void:
	_pension = amount
	if _status != null:
		_refresh()


func show_message(text: String) -> void:
	_message.text = text


func _add_label(at: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	add_child(label)
	return label


func _refresh() -> void:
	var text := "Pension: %d" % _pension
	if _run != null:
		var pills := "■".repeat(_run.health.pills) + "□".repeat(_run.health.max_pills - _run.health.pills)
		text = "Pills: %s   %s" % [pills, text]
		var names: PackedStringArray = []
		for item in _run.items:
			names.append(item.display_name)
		_items.text = ", ".join(names)
	_status.text = text
