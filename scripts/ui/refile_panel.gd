class_name RefilePanel
extends CanvasLayer

# The forms counter: every form past its milestone can switch to its other option, free the first
# time and ProgressData.REFILE_FEE after.

signal closed

const PANEL_POSITION := Vector2(60, 24)
const PANEL_SIZE := Vector2(520, 0)
const PANEL_BACK := Color(0.09, 0.07, 0.11)
const PANEL_EDGE := Color("625e6f")
const ROW_FONT := 11
const NOTHING_YET := "Nothing to refile yet. File a form to its milestone first."

var _title := ""
var _list: VBoxContainer


func setup(title: String) -> void:
	_title = title


func _ready() -> void:
	var panel := PanelContainer.new()
	panel.position = PANEL_POSITION
	panel.custom_minimum_size = PANEL_SIZE
	# It covers most of the screen, so it gets its own opaque backing.
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
		child.queue_free()
	var shown := 0
	for def in Content.upgrades():
		var choice := Progress.data.choice_of(def)
		if choice.is_empty():
			continue
		var price := Progress.data.refile_price(def)
		var button := Button.new()
		button.text = FormText.refile_row(def, choice, price)
		var other := UpgradeDef.OPTION_B if choice == UpgradeDef.OPTION_A else UpgradeDef.OPTION_A
		button.tooltip_text = def.option_text(other)
		button.disabled = Progress.data.pension < price
		button.add_theme_font_size_override("font_size", ROW_FONT)
		button.pressed.connect(_refile.bind(def))
		_list.add_child(button)
		shown += 1
	if shown == 0:
		var empty := Label.new()
		empty.text = NOTHING_YET
		empty.add_theme_font_size_override("font_size", ROW_FONT)
		_list.add_child(empty)


func _refile(def: UpgradeDef) -> void:
	if Progress.refile(def):
		_rebuild()
