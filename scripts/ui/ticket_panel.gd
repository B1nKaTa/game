class_name TicketPanel
extends CanvasLayer

# The lobby's ticket machine: Grandpa's number, the clerk's deal of the visit, and a cursed ticket to
# take or turn down while one is on offer.

signal closed
# The notice to show once the cursed ticket is taken.
signal cursed_taken(text: String)

const PANEL_POSITION := Vector2(100, 48)
const PANEL_SIZE := Vector2(440, 0)
const PANEL_BACK := Color(0.09, 0.07, 0.11)
const PANEL_EDGE := Color("625e6f")
const ROW_FONT := 11
const CURSED_COLOR := Color("e4524f")
const TAKE_CURSED := "Take the cursed ticket"
const NO_THANKS := "No thanks"
const CURSED_TEXT := "A cursed ticket is on offer: tougher enemies and better pay for one run, and Condolences for every floor cleared."
const CURSED_TAKEN := "Your next run is on a cursed ticket. Good luck. You'll need it."

var _title := ""
var _lines: VBoxContainer


func setup(title: String) -> void:
	_title = title


# What the machine says for this save, line by line.
static func lines_for(data: ProgressData, upgrade_defs: Array[UpgradeDef]) -> PackedStringArray:
	var lines := PackedStringArray(["Your ticket: %d" % (data.run_count + 1), "Every fifth number is called."])
	if not data.clerk_deal.is_empty():
		lines.append("Deal of the visit: %s %d%% off" % [form_name(data.clerk_deal, upgrade_defs), roundi(ProgressData.CLERK_DEAL_CUT * 100.0)])
	if data.cursed_offer:
		lines.append(CURSED_TEXT)
	if data.cursed_next_run:
		lines.append(CURSED_TAKEN)
	return lines


static func form_name(form_id: String, upgrade_defs: Array[UpgradeDef]) -> String:
	for def in upgrade_defs:
		if def.id == form_id:
			return def.display_name
	return form_id


func _ready() -> void:
	var panel := PanelContainer.new()
	panel.position = PANEL_POSITION
	panel.custom_minimum_size = PANEL_SIZE
	# Opaque, as every Waiting Room panel is, so the lobby's prompts never show through.
	var back := StyleBoxFlat.new()
	back.bg_color = PANEL_BACK
	back.border_color = PANEL_EDGE
	back.set_border_width_all(1)
	back.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", back)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	var title := Label.new()
	title.text = _title
	column.add_child(title)
	_lines = VBoxContainer.new()
	_lines.add_theme_constant_override("separation", 3)
	column.add_child(_lines)
	var close := Button.new()
	close.text = "Leave"
	close.pressed.connect(func(): closed.emit())
	column.add_child(close)
	_rebuild()


func _rebuild() -> void:
	for child in _lines.get_children():
		_lines.remove_child(child)
		child.queue_free()
	for line in lines_for(Progress.data, Content.upgrades()):
		var label := Label.new()
		label.text = line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = PANEL_SIZE.x - 12.0
		label.add_theme_font_size_override("font_size", ROW_FONT)
		if line == CURSED_TEXT or line == CURSED_TAKEN:
			label.add_theme_color_override("font_color", CURSED_COLOR)
		_lines.add_child(label)
	if Progress.data.cursed_offer:
		var choice := HBoxContainer.new()
		var take := Button.new()
		take.text = TAKE_CURSED
		take.add_theme_font_size_override("font_size", ROW_FONT)
		take.pressed.connect(take_cursed)
		choice.add_child(take)
		var decline := Button.new()
		decline.text = NO_THANKS
		decline.add_theme_font_size_override("font_size", ROW_FONT)
		decline.pressed.connect(turn_down)
		choice.add_child(decline)
		_lines.add_child(choice)


# The two buttons, which the full-loop check also presses.
func take_cursed() -> void:
	if Progress.accept_cursed_ticket():
		cursed_taken.emit(CURSED_TAKEN)
	_rebuild()


func turn_down() -> void:
	Progress.decline_cursed_ticket()
	_rebuild()
