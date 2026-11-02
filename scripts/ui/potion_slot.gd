class_name PotionSlot
extends Control

# The HUD's potion slot, always on screen: a flask that is empty or full, the key that drinks
# it, and the short name of whatever is inside. A running buff shows its time left beneath.
const SIZE := Vector2(110, 30)
const FLASK_AT := Vector2(0, 0)
const TEXT_AT := Vector2(14, -2)
const BUFF_TEXT_AT := Vector2(14, 12)
const EMPTY_COLOR := Color(0.7, 0.7, 0.78, 0.55)
const NAME_FONT := 11
const BUFF_FONT := 9

var _flask_color := EMPTY_COLOR
var _filled := false
var _name_label: Label
var _buff_label: Label


static func name_text(key: String, potion: PotionDef) -> String:
	return "[%s] %s" % [key, potion.short_name if potion != null else "-"]


static func buff_text(buff: PotionDef, seconds_left: float) -> String:
	if buff == null or seconds_left <= 0.0:
		return ""
	return "%s %ds" % [buff.short_name, ceili(seconds_left)]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = SIZE
	size = SIZE
	_name_label = _add_label(TEXT_AT, NAME_FONT)
	_buff_label = _add_label(BUFF_TEXT_AT, BUFF_FONT)
	show_potion(null, "H")


func show_potion(potion: PotionDef, key: String) -> void:
	_filled = potion != null
	_flask_color = potion.color if potion != null else EMPTY_COLOR
	if _name_label != null:
		_name_label.text = name_text(key, potion)
	queue_redraw()


func show_buff(buff: PotionDef, seconds_left: float) -> void:
	if _buff_label != null:
		_buff_label.text = buff_text(buff, seconds_left)


func _add_label(at: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.size = Vector2(SIZE.x - at.x, 14)
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	add_child(label)
	return label


func _draw() -> void:
	var neck := Rect2(FLASK_AT + Vector2(4, 0), Vector2(4, 3))
	var belly := Rect2(FLASK_AT + Vector2(1, 3), Vector2(10, 10))
	draw_rect(neck, Color("625e6f"))
	if _filled:
		draw_rect(belly, _flask_color)
	else:
		draw_rect(belly, Color(0.0, 0.0, 0.0, 0.35))
	draw_rect(belly, Color.BLACK if _filled else _flask_color, false, 1.0)
	if _filled:
		draw_line(FLASK_AT + Vector2(3, 5), FLASK_AT + Vector2(3, 10), Color(1.0, 1.0, 1.0, 0.5), 1.0)
