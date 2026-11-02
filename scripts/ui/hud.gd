class_name Hud
extends CanvasLayer

const BOSS_BAR_SIZE := Vector2(480, 10)
const BOSS_BAR_TOP := 336.0
const BOSS_NAME_TOP := 314.0

var _run: RunState
var _status: Label
var _items: Label
var _message: Label
var _boss_name: Label
var _boss_back: ColorRect
var _boss_fill: ColorRect
var _boss_max_hp := 1.0
var _pension := 0


static func bar_fraction(hp: float, max_hp: float) -> float:
	if max_hp <= 0.0:
		return 0.0
	return clampf(hp / max_hp, 0.0, 1.0)


func setup(run: RunState) -> void:
	_run = run


func _ready() -> void:
	_status = _add_label(Vector2(8, 4), 12)
	_items = _add_label(Vector2(8, 22), 9)
	_message = _add_label(Vector2(0, 150), 20)
	_message.size = Vector2(640, 40)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name = _add_label(Vector2(0, BOSS_NAME_TOP), 16)
	_boss_name.size = Vector2(640, 20)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var left := (640.0 - BOSS_BAR_SIZE.x) / 2.0
	_boss_back = _add_rect(Vector2(left, BOSS_BAR_TOP), BOSS_BAR_SIZE, Color("1a1214"))
	_boss_fill = _add_rect(Vector2(left, BOSS_BAR_TOP), BOSS_BAR_SIZE, Color("e4524f"))
	hide_boss_bar()
	if _run != null:
		_run.changed.connect(_refresh)
	_refresh()


func set_pension(amount: int) -> void:
	_pension = amount
	if _status != null:
		_refresh()


func show_message(text: String) -> void:
	_message.text = text


func show_boss_bar(display_name: String, max_hp: float) -> void:
	_boss_max_hp = max_hp
	_boss_name.text = display_name
	_boss_name.visible = true
	_boss_back.visible = true
	_boss_fill.visible = true
	set_boss_health(max_hp)


func set_boss_health(hp: float) -> void:
	_boss_fill.size.x = BOSS_BAR_SIZE.x * bar_fraction(hp, _boss_max_hp)


func hide_boss_bar() -> void:
	_boss_name.visible = false
	_boss_back.visible = false
	_boss_fill.visible = false


func is_boss_bar_visible() -> bool:
	return _boss_back != null and _boss_back.visible


func _add_rect(at: Vector2, size: Vector2, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = at
	rect.size = size
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	return rect


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
