class_name MerchantPanel
extends CanvasLayer

# Upgrades as forms: each row shows the form's stamps, the option it runs with, and the price of the
# next filing. At the milestone the row offers both options to file. A filing stamps the row.

signal closed

const PANEL_POSITION := Vector2(20, 16)
const PANEL_SIZE := Vector2(600, 0)
const PANEL_BACK := Color(0.09, 0.07, 0.11)
const PANEL_EDGE := Color("625e6f")
const ROW_FONT := 10
const STAMP_TEXT := "FILED"
const STAMP_COLOR := Color("e4524f")
const STAMP_FONT := 22
const STAMP_FROM := 1.6
const STAMP_TIME := 0.15

var _title := ""
var _merchant_id := ""
var _list: VBoxContainer
var _stamping := false


func setup(title: String, merchant_id: String) -> void:
	_title = title
	_merchant_id = merchant_id


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
	for def in Content.upgrades_for(_merchant_id):
		_list.add_child(_make_row(def))


func _make_row(def: UpgradeDef) -> Control:
	var level := Progress.data.level_of(def.id)
	var price := Progress.data.price_of(def)
	var form := VBoxContainer.new()
	form.add_theme_constant_override("separation", 1)
	var line := HBoxContainer.new()
	form.add_child(line)
	var text := Label.new()
	text.text = FormText.row(def, level, price, Progress.data.choice_of(def))
	text.tooltip_text = def.description
	text.mouse_filter = Control.MOUSE_FILTER_PASS
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_font_size_override("font_size", ROW_FONT)
	line.add_child(text)
	if price < 0:
		return form
	var can_buy := Progress.data.can_buy(def)
	if not (def.has_choice() and level + 1 == def.milestone_level):
		line.add_child(_file_button("File", def.description, can_buy, def, "", form))
		return form
	# The milestone: the two options sit on their own line, each with its text as the tooltip.
	var options := HBoxContainer.new()
	form.add_child(options)
	for choice: String in [UpgradeDef.OPTION_A, UpgradeDef.OPTION_B]:
		var label := "File: %s" % def.option_name(choice)
		options.add_child(_file_button(label, def.option_text(choice), can_buy, def, choice, form))
	return form


func _file_button(label: String, tip: String, enabled: bool, def: UpgradeDef, choice: String, form: Control) -> Button:
	var button := Button.new()
	button.text = label
	button.tooltip_text = tip
	button.disabled = not enabled
	button.add_theme_font_size_override("font_size", ROW_FONT)
	button.pressed.connect(_file.bind(def, choice, form))
	return button


func _file(def: UpgradeDef, choice: String, form: Control) -> void:
	if _stamping or not Progress.buy(def, choice):
		return
	_stamp(form)


# A red FILED lands on the row, shrinking from large to its size, and then the list is rebuilt.
func _stamp(form: Control) -> void:
	_stamping = true
	var stamp := Label.new()
	stamp.text = STAMP_TEXT
	stamp.add_theme_font_size_override("font_size", STAMP_FONT)
	stamp.add_theme_color_override("font_color", STAMP_COLOR)
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stamp)
	var stamp_size := stamp.get_combined_minimum_size()
	stamp.size = stamp_size
	stamp.pivot_offset = stamp_size / 2.0
	stamp.position = form.global_position + form.size / 2.0 - stamp_size / 2.0
	stamp.scale = Vector2.ONE * STAMP_FROM
	var tween := create_tween()
	tween.tween_property(stamp, "scale", Vector2.ONE, STAMP_TIME)
	tween.tween_callback(_after_stamp.bind(stamp))


func _after_stamp(stamp: Label) -> void:
	stamp.queue_free()
	_stamping = false
	_rebuild()
