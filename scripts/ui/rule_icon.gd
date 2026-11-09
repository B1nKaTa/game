class_name RuleIcon
extends Control

# The room's rule in the HUD corner under the minimap, while its fight lasts. It pulses when Harold is
# about to break it and greys out once he has.

const AT := Vector2(588, 78)
const PULSE_COLOR := Color("ffd34f")
const BROKEN_COLOR := Color("8a8580")
const PULSE_SPEED := 9.0

var _texture: Texture2D
var _pulse := false
var _broken := false
var _time := 0.0


func _init() -> void:
	position = AT
	size = Vector2(RulePictogram.SIZE + 4, RulePictogram.SIZE + 4)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func show_rule(rule: String) -> void:
	_texture = RulePictogram.texture(rule)
	_broken = false
	_pulse = false
	visible = true
	queue_redraw()


func set_pulse(on: bool) -> void:
	if on != _pulse:
		_pulse = on
		queue_redraw()


func set_broken() -> void:
	_broken = true
	_pulse = false
	queue_redraw()


func clear() -> void:
	visible = false


func _process(delta: float) -> void:
	if _pulse:
		_time += delta
		queue_redraw()


func _draw() -> void:
	if _texture == null:
		return
	if _pulse:
		var glow := 0.5 + 0.5 * sin(_time * PULSE_SPEED)
		draw_rect(Rect2(Vector2.ZERO, size), Color(PULSE_COLOR, 0.35 + 0.5 * glow))
	var tint := Color(BROKEN_COLOR) if _broken else Color.WHITE
	draw_texture(_texture, Vector2(2, 2), tint)
