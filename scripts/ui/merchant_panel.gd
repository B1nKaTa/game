class_name MerchantPanel
extends CanvasLayer

signal closed

var _title := ""
var _merchant_id := ""
var _list: VBoxContainer


func setup(title: String, merchant_id: String) -> void:
	_title = title
	_merchant_id = merchant_id


func _ready() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(100, 40)
	panel.custom_minimum_size = Vector2(440, 260)
	add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var title := Label.new()
	title.text = _title
	column.add_child(title)
	_list = VBoxContainer.new()
	column.add_child(_list)
	var close := Button.new()
	close.text = "Leave"
	close.pressed.connect(func(): closed.emit())
	column.add_child(close)
	_rebuild()


func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()
	for def in Content.upgrades_for(_merchant_id):
		var button := Button.new()
		var level := Progress.data.level_of(def.id)
		var price := def.price_at(level)
		var cost_text := "SOLD OUT" if price < 0 else "%d Pension" % price
		button.text = "%s  Lv %d/%d  %s" % [def.display_name, level, def.max_level(), cost_text]
		button.tooltip_text = def.description
		button.disabled = not Progress.data.can_buy(def)
		button.pressed.connect(_buy.bind(def))
		_list.add_child(button)


func _buy(def: UpgradeDef) -> void:
	if Progress.buy(def):
		_rebuild()
