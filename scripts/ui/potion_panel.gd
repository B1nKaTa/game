class_name PotionPanel
extends CanvasLayer

# Brews are bought for the next run only, and one waits at a time, like Agnes's crafted item.
signal closed

const BUTTON_FONT_SIZE := 12
const NOTE_FONT_SIZE := 10

var _title := ""
var _status: Label
var _list: VBoxContainer


static func status_text(waiting_name: String) -> String:
	if waiting_name.is_empty():
		return "One brew can wait for your next run. Drink it with the potion key."
	return "Waiting for your next run: %s. One at a time, dear." % waiting_name


static func button_text(def: PotionDef) -> String:
	return "%s   %d Pension" % [def.display_name, def.price]


func setup(title: String) -> void:
	_title = title


func _ready() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(100, 40)
	panel.custom_minimum_size = Vector2(440, 260)
	# Opaque, like the Waiting Room's other panels, so the room's signs and Grandpa never show through.
	var back := StyleBoxFlat.new()
	back.bg_color = MerchantPanel.PANEL_BACK
	back.border_color = MerchantPanel.PANEL_EDGE
	back.set_border_width_all(1)
	back.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", back)
	add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var title := Label.new()
	title.text = _title
	column.add_child(title)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 11)
	column.add_child(_status)
	_list = VBoxContainer.new()
	column.add_child(_list)
	var close := Button.new()
	close.text = "Leave"
	close.set_meta("sfx", "")
	close.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	close.pressed.connect(func(): closed.emit())
	column.add_child(close)
	_rebuild()


func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()
	var waiting := Content.potion(Progress.data.brewed_potion)
	_status.text = status_text(waiting.display_name if waiting != null else "")
	for def in Content.potions_for_sale():
		var button := Button.new()
		button.text = button_text(def)
		button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
		button.disabled = not Progress.data.can_brew(def.price)
		button.set_meta("sfx", "")
		button.pressed.connect(_brew.bind(def))
		_list.add_child(button)
		var note := Label.new()
		note.text = "   " + def.description
		note.add_theme_font_size_override("font_size", NOTE_FONT_SIZE)
		_list.add_child(note)


func _brew(def: PotionDef) -> void:
	if Progress.brew(def):
		Sfx.play("ui_ching")
		Sfx.play_later("brew", 0.15)
		_rebuild()
