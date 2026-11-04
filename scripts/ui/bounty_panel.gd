class_name BountyPanel
extends CanvasLayer

# The Bounty Office's wanted posters: one row per poster on the board, each with one button to take
# it, to collect it once its boss has fallen, or saying why it can't be taken.

signal closed
# The notice to show once a poster is collected.
signal paid(text: String)

const PANEL_POSITION := Vector2(20, 16)
const PANEL_SIZE := Vector2(600, 0)
const PANEL_BACK := Color(0.09, 0.07, 0.11)
const PANEL_EDGE := Color("625e6f")
const ROW_FONT := 9
# One row's height with its separation, to size the list. Past LIST_MAX_HEIGHT the list scrolls, so
# twelve posters still leave the Leave button on the 360 pixel screen.
const ROW_HEIGHT := 20.0
const LIST_MAX_HEIGHT := 250.0
const BUTTON_WIDTH := 112.0
const TAKE := "Take"
const TAKEN := "Taken: go get them"
const COLLECT := "Collect"
const ONE_AT_A_TIME := "One at a time"
const NOBODY := "Nobody is wanted right now. Clear a new floor and check back."

var _title := ""
var _scroll: ScrollContainer
var _list: VBoxContainer


func setup(title: String) -> void:
	_title = title


static func extra_text(def: BountyDef) -> String:
	if def.extra_kind == BountyDef.EXTRA_RECIPE:
		return "a recipe for Agnes"
	if def.extra_kind == BountyDef.EXTRA_ITEM:
		return "a unique item"
	return "something to wear"


static func row_text(def: BountyDef) -> String:
	return "WANTED: %s  %d Pension, %d Condolences, + %s" % [def.boss_name, def.pension, def.condolences, extra_text(def)]


# What the poster's one button says for this save.
static func button_text(def: BountyDef, data: ProgressData) -> String:
	if BountyBoard.can_collect(def, data):
		return COLLECT
	if BountyBoard.is_taken(def, data):
		return TAKEN
	if BountyBoard.can_take(def, data):
		return TAKE
	return ONE_AT_A_TIME


# The notice for a collected poster. A recipe Agnes already had pays half again in Pension instead.
static func paid_text(def: BountyDef, paid_out: Dictionary) -> String:
	var amounts := "%d Pension, %d Condolences" % [int(paid_out["pension"]), int(paid_out["condolences"])]
	if paid_out["extra_was_new"]:
		return "Paid: %s, and %s" % [amounts, extra_text(def)]
	return "Paid: %s. You had that one already, so a little extra Pension." % amounts


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
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 2)
	_scroll.add_child(_list)
	var close := Button.new()
	close.text = "Leave"
	close.pressed.connect(func(): closed.emit())
	column.add_child(close)
	_rebuild()


func _rebuild() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var posters := BountyBoard.showing(Progress.data)
	for def in posters:
		_list.add_child(_make_row(def))
	if posters.is_empty():
		var empty := Label.new()
		empty.text = NOBODY
		empty.add_theme_font_size_override("font_size", ROW_FONT)
		_list.add_child(empty)
	_scroll.custom_minimum_size.y = minf(maxi(posters.size(), 1) * ROW_HEIGHT, LIST_MAX_HEIGHT)


func _make_row(def: BountyDef) -> Control:
	var line := HBoxContainer.new()
	var text := Label.new()
	text.text = row_text(def)
	text.tooltip_text = row_text(def)
	text.mouse_filter = Control.MOUSE_FILTER_PASS
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# A long name trims rather than pushing the button off the panel.
	text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text.add_theme_font_size_override("font_size", ROW_FONT)
	line.add_child(text)
	var button := Button.new()
	var label := button_text(def, Progress.data)
	button.text = label
	button.custom_minimum_size.x = BUTTON_WIDTH
	button.disabled = label == TAKEN or label == ONE_AT_A_TIME
	button.add_theme_font_size_override("font_size", ROW_FONT)
	button.pressed.connect(_press.bind(def))
	line.add_child(button)
	return line


func _press(def: BountyDef) -> void:
	if BountyBoard.can_collect(def, Progress.data):
		var paid_out := Progress.collect_bounty(def)
		if not paid_out.is_empty():
			paid.emit(paid_text(def, paid_out))
	else:
		Progress.take_bounty(def)
	_rebuild()
