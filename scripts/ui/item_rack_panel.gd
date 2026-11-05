class_name ItemRackPanel
extends CanvasLayer

# The Training Yard's rack: every recipe Grandpa has found, crafted or not, to try on the dummy. What
# he takes is gone again when he leaves the yard.

signal closed
signal taken(item: ItemDef)

const PANEL_POSITION := Vector2(140, 40)
const PANEL_SIZE := Vector2(360, 0)
const PANEL_BACK := Color(0.09, 0.07, 0.11)
const PANEL_EDGE := Color("625e6f")
const ROW_FONT := 10
const NOTHING_YET := "The rack is empty. Find a recipe out there and it turns up here."

var _title := ""
var _run: RunState
var _list: VBoxContainer


# Every found recipe, in Content.recipes() order.
static func rack_items(data: ProgressData) -> Array[ItemDef]:
	var list: Array[ItemDef] = []
	for item in Content.recipes():
		if data.has_recipe(item.id):
			list.append(item)
	return list


func setup(title: String, run: RunState) -> void:
	_title = title
	_run = run


func _ready() -> void:
	var panel := PanelContainer.new()
	panel.position = PANEL_POSITION
	panel.custom_minimum_size = PANEL_SIZE
	# Opaque, so the yard's signs and prompts never show through its buttons.
	var back := StyleBoxFlat.new()
	back.bg_color = PANEL_BACK
	back.border_color = PANEL_EDGE
	back.set_border_width_all(1)
	back.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", back)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	panel.add_child(column)
	var title := Label.new()
	title.text = _title
	column.add_child(title)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 2)
	column.add_child(_list)
	var close := Button.new()
	close.text = "Leave"
	close.pressed.connect(func(): closed.emit())
	column.add_child(close)
	_rebuild()
	# A controller drives it too: the D-pad moves between its buttons, A presses, B leaves.
	add_child(PadFocus.new())


func _rebuild() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var rack := rack_items(Progress.data)
	for item in rack:
		var button := Button.new()
		button.text = "Try %s" % item.display_name
		button.tooltip_text = item.description
		button.disabled = _run != null and _run.has_item(item.id)
		button.add_theme_font_size_override("font_size", ROW_FONT)
		button.pressed.connect(_take.bind(item))
		_list.add_child(button)
	if rack.is_empty():
		var empty := Label.new()
		empty.text = NOTHING_YET
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty.add_theme_font_size_override("font_size", ROW_FONT)
		_list.add_child(empty)


func _take(item: ItemDef) -> void:
	taken.emit(item)
	_rebuild()
