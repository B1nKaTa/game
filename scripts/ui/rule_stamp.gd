class_name RuleStamp
extends Control

const ANNOUNCE_TIME := 1.5
const SHRINK_TIME := 0.3
const STAMP_TIME := 1.0
const KIND_VIOLATION := "violation"
const KIND_GOOD := "good"
const KIND_LIFTED := "lifted"
const CENTER := Vector2(320, 150)
const CARD := Vector2(200, 112)
const PAPER := Color("efe6cf")
const KIND_COLORS := {KIND_VIOLATION: Color("c43d2f"), KIND_GOOD: Color("3f8f4a"), KIND_LIFTED: Color("6b6258")}

signal announce_done(rule: String)

var _texture: Texture2D
var _rule := ""
var _sign := ""
var _kind := ""
var _left := 0.0
var _total := 0.0


static func text_of(kind: String) -> String:
	match kind:
		KIND_VIOLATION:
			return "VIOLATION"
		KIND_GOOD:
			return "GOOD CONDUCT"
		KIND_LIFTED:
			return "REGULATION LIFTED"
	return ""


func _init() -> void:
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func announce(rule: String) -> void:
	_texture = RulePictogram.texture(rule)
	_rule = rule
	_sign = tr(RoomRule.sign_text(rule))
	_kind = ""
	_total = ANNOUNCE_TIME + SHRINK_TIME
	_left = _total
	Sfx.play("rule_stamp")
	queue_redraw()


func stamp(kind: String) -> void:
	# A stamp that cuts into the announcement still hands the rule to the icon.
	if _left > 0.0 and _kind.is_empty():
		announce_done.emit(_rule)
	_kind = kind
	_total = STAMP_TIME
	_left = STAMP_TIME
	Sfx.play("rule_stamp")
	queue_redraw()


func is_showing() -> bool:
	return _left > 0.0


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left -= delta
	if _left <= 0.0 and _kind.is_empty():
		announce_done.emit(_rule)
	queue_redraw()


func _draw() -> void:
	if _left <= 0.0:
		return
	var font := HudStyle.font()
	if not _kind.is_empty():
		var word := tr(text_of(_kind))
		var color: Color = KIND_COLORS[_kind]
		var width := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + 24
		draw_set_transform(Vector2(320, 120), deg_to_rad(-8.0))
		draw_rect(Rect2(-width / 2, -18, width, 36), color, false, 3.0)
		draw_string(font, Vector2(-width / 2 + 12, 8), word, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, color)
		draw_set_transform(Vector2.ZERO)
		return
	var elapsed := _total - _left
	var drop := clampf(elapsed / 0.15, 0.0, 1.0)
	var shrink := clampf((elapsed - ANNOUNCE_TIME) / SHRINK_TIME, 0.0, 1.0)
	var scale := lerpf(1.25, 1.0, drop) * lerpf(1.0, 0.15, shrink)
	var center := CENTER.lerp(RuleIcon.AT + Vector2(14, 14), shrink)
	draw_set_transform(center, 0.0, Vector2(scale, scale))
	draw_rect(Rect2(-CARD / 2, CARD), PAPER)
	draw_rect(Rect2(-CARD / 2, CARD), Color("2b2622"), false, 2.0)
	draw_texture_rect(_texture, Rect2(Vector2(-36, -50), Vector2(72, 72)), false)
	var width := font.get_string_size(_sign, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string(font, Vector2(-width / 2, 40), _sign, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("2b2622"))
	draw_set_transform(Vector2.ZERO)
