class_name DecorPanel
extends CanvasLayer

# The Decor Office's counter: decor for the lobby and looks for Grandpa, bought with Condolences. Two
# tabs switch the list. Looks are worn and taken off here too. Nothing here changes a stat.

signal closed

const PANEL_POSITION := Vector2(20, 16)
const PANEL_SIZE := Vector2(600, 0)
const PANEL_BACK := Color(0.09, 0.07, 0.11)
const PANEL_EDGE := Color("625e6f")
const ROW_FONT := 9
const BUTTON_WIDTH := 132.0
# Past this the list scrolls, so ten rows still leave the Leave button on the 360 pixel screen.
const ROW_HEIGHT := 20.0
const LIST_MAX_HEIGHT := 220.0
const TAB_ROOM := "For the Waiting Room"
const TAB_GRANDPA := "For Grandpa"
const PLACED := "Placed"
const WEAR := "Wear"
const TAKE_OFF := "Take off"
const BOUNTY_REWARD := "Bounty reward"
# Gerald's Hat comes only from the true ending.
const ENDING_REWARD := "Ending reward"
const SLOT_NAMES := {CosmeticDef.SLOT_HAT: "Hat", CosmeticDef.SLOT_CARDIGAN: "Cardigan", CosmeticDef.SLOT_CANE: "Cane", CosmeticDef.SLOT_DECOR: "Lobby"}

var _title := ""
var _showing_decor := true
var _status: Label
var _scroll: ScrollContainer
var _list: VBoxContainer
var _tab_room: Button
var _tab_grandpa: Button


func setup(title: String) -> void:
	_title = title


static func decor_button_text(def: CosmeticDef, data: ProgressData) -> String:
	if data.owns_cosmetic(def.id):
		return PLACED
	return "Buy (%d Condolences)" % def.price


static func look_button_text(def: CosmeticDef, data: ProgressData) -> String:
	if data.owns_cosmetic(def.id):
		return TAKE_OFF if data.is_worn(def) else WEAR
	if not def.is_sold():
		return ENDING_REWARD if def.id == ProgressData.GERALDS_HAT else BOUNTY_REWARD
	return "Buy (%d)" % def.price


# The rows of one tab: the decor, or Grandpa's looks grouped by slot in the order he wears them.
static func rows_for(defs: Array[CosmeticDef], decor: bool) -> Array[CosmeticDef]:
	var rows: Array[CosmeticDef] = []
	if decor:
		for def in defs:
			if def.is_decor():
				rows.append(def)
		return rows
	for slot in CosmeticDef.WORN_SLOTS:
		for def in defs:
			if def.slot == slot:
				rows.append(def)
	return rows


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
	var tabs := HBoxContainer.new()
	column.add_child(tabs)
	_tab_room = _make_tab(TAB_ROOM, true)
	tabs.add_child(_tab_room)
	_tab_grandpa = _make_tab(TAB_GRANDPA, false)
	tabs.add_child(_tab_grandpa)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", ROW_FONT)
	column.add_child(_status)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 2)
	_scroll.add_child(_list)
	var close := Button.new()
	close.text = "Leave"
	close.set_meta("sfx", "")
	close.pressed.connect(func(): closed.emit())
	column.add_child(close)
	_rebuild()
	# A controller drives it too, and the shoulder buttons switch the two tabs.
	var focus := PadFocus.new()
	focus.tabs = _switch_tab
	add_child(focus)


func _make_tab(text: String, decor: bool) -> Button:
	var tab := Button.new()
	tab.text = text
	tab.toggle_mode = true
	tab.add_theme_font_size_override("font_size", ROW_FONT + 1)
	tab.pressed.connect(_show_tab.bind(decor))
	return tab


func _switch_tab(_step: int) -> void:
	_show_tab(not _showing_decor)


func _show_tab(decor: bool) -> void:
	_showing_decor = decor
	_rebuild()


func _rebuild() -> void:
	_tab_room.button_pressed = _showing_decor
	_tab_grandpa.button_pressed = not _showing_decor
	_status.text = "Condolences: %d   Looks only. Nothing here makes Grandpa any stronger." % Progress.data.condolences
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var rows := rows_for(CosmeticDef.all(), _showing_decor)
	for def in rows:
		_list.add_child(_make_row(def))
	_scroll.custom_minimum_size.y = minf(maxi(rows.size(), 1) * ROW_HEIGHT, LIST_MAX_HEIGHT)


func _make_row(def: CosmeticDef) -> Control:
	var line := HBoxContainer.new()
	var swatch := ColorRect.new()
	swatch.color = def.color
	swatch.custom_minimum_size = Vector2(10, 10)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(swatch)
	var text := Label.new()
	text.text = "%s  (%s)  %s" % [def.display_name, SLOT_NAMES.get(def.slot, def.slot), def.description]
	text.tooltip_text = def.description
	text.mouse_filter = Control.MOUSE_FILTER_PASS
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text.add_theme_font_size_override("font_size", ROW_FONT)
	line.add_child(text)
	var button := Button.new()
	var label := decor_button_text(def, Progress.data) if def.is_decor() else look_button_text(def, Progress.data)
	button.text = label
	button.custom_minimum_size.x = BUTTON_WIDTH
	button.add_theme_font_size_override("font_size", ROW_FONT)
	if label == PLACED or label == BOUNTY_REWARD:
		button.disabled = true
	elif not Progress.data.owns_cosmetic(def.id):
		button.disabled = not Progress.data.can_buy_cosmetic(def)
	button.set_meta("sfx", "")
	button.pressed.connect(_press.bind(def))
	line.add_child(button)
	return line


# Condolences are spent with a soft chime; trying a look on or off is a plain press.
func _press(def: CosmeticDef) -> void:
	if not Progress.data.owns_cosmetic(def.id):
		Sfx.play("condolence" if Progress.buy_cosmetic(def) else "ui_denied")
	elif Progress.data.is_worn(def):
		Sfx.play("ui_confirm")
		Progress.take_off(def.slot)
	elif not def.is_decor():
		Sfx.play("ui_confirm")
		Progress.wear(def)
	_rebuild()
