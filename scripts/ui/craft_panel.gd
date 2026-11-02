class_name CraftPanel
extends CanvasLayer

signal closed

var _title := ""
var _status: Label
var _list: VBoxContainer


static func status_text(ready_name: String, found: int, total: int) -> String:
	var recipes := "%d of %d recipes found." % [found, total]
	if ready_name.is_empty():
		return "%s One item can be crafted for your next run." % recipes
	return "%s Ready for your next run: %s" % [recipes, ready_name]


func setup(title: String) -> void:
	_title = title


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
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 11)
	column.add_child(_status)
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
	var all := Content.recipes()
	var found := 0
	var ready_name := ""
	for item in all:
		if item.id == Progress.data.crafted_for_next_run:
			ready_name = item.display_name
		if not Progress.data.has_recipe(item.id):
			continue
		found += 1
		_list.add_child(_make_button(item))
	_status.text = status_text(ready_name, found, all.size())
	if found == 0:
		var empty := Label.new()
		empty.text = "No recipes yet. Bring me some from out there, dear."
		_list.add_child(empty)


func _make_button(item: ItemDef) -> Button:
	var button := Button.new()
	if Progress.data.is_unlocked(item.id):
		button.text = "%s  Crafted, now in rotation" % item.display_name
	else:
		button.text = "%s  %d Pension" % [item.display_name, item.craft_price]
	button.tooltip_text = item.description
	button.disabled = not Progress.data.can_craft(item.id, item.craft_price)
	button.pressed.connect(_craft.bind(item))
	return button


func _craft(item: ItemDef) -> void:
	if Progress.craft(item):
		_rebuild()
