class_name TitleBubble
extends Node2D

# A ghost's small speech bubble on the title screen, in view pixels: pale paper with a dark edge, a tail
# down to the speaker's head and the line in the pixel font, in at most two rows. It pops in, holds and
# fades. Its position is the point of its tail.

const PAD := Vector2(4, 3)
const ROW := 9.0
const WRAP := 20
const PAPER := Color("e9e4d6")
const EDGE := Color("1c1620")
const INK := Color("2a2230")
const POP_TIME := 0.12
const FADE_TIME := 0.3
const LIFT := 6.0

var text := ""
var hold := 2.4
var _rows: PackedStringArray = []
var _age := 0.0


# Two rows at most, split at the space nearest the middle when the line is longer than WRAP.
static func wrap_line(line: String) -> PackedStringArray:
	if line.length() <= WRAP:
		return PackedStringArray([line])
	var best := -1
	for i in line.length():
		if line[i] == " " and (best < 0 or absi(i - line.length() / 2) < absi(best - line.length() / 2)):
			best = i
	if best < 0:
		return PackedStringArray([line])
	return PackedStringArray([line.substr(0, best), line.substr(best + 1)])


func say(line: String, seconds: float) -> void:
	text = line
	hold = seconds
	_rows = wrap_line(line)
	_age = 0.0
	visible = true
	queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	_age += delta
	if _age > hold + FADE_TIME:
		visible = false
	queue_redraw()


func size() -> Vector2:
	var font := HudStyle.font()
	var width := 0.0
	for row in _rows:
		width = maxf(width, font.get_string_size(row, HORIZONTAL_ALIGNMENT_LEFT, -1, HudStyle.SMALL).x)
	return Vector2(ceilf(width), ROW * _rows.size() - 1.0) + PAD * 2.0


func _draw() -> void:
	if _rows.is_empty():
		return
	var alpha := 1.0
	if _age > hold:
		alpha = clampf(1.0 - (_age - hold) / FADE_TIME, 0.0, 1.0)
	var pop := clampf(_age / POP_TIME, 0.0, 1.0)
	modulate.a = alpha
	var box_size := size()
	# Kept inside the view across, so a bubble at either end of the row never runs off it.
	var left := clampf(-box_size.x / 2.0, -global_position.x + 2.0, GameSettings.VIEW.x - global_position.x - box_size.x - 2.0)
	var box := Rect2(Vector2(round(left), round(-box_size.y - LIFT - (1.0 - pop) * 3.0)), box_size)
	draw_rect(box.grow(1), EDGE)
	draw_rect(box, PAPER)
	# The tail: a small stepped wedge down from the bubble's bottom edge to the point.
	var tail_x := clampf(0.0, box.position.x + 4.0, box.end.x - 6.0)
	for step in int(LIFT):
		var half := maxf(2.0 - step * 0.4, 0.0)
		draw_rect(Rect2(Vector2(round(tail_x - half - 1.0), box.end.y + step), Vector2(round(half * 2.0) + 2.0, 1)), EDGE)
		draw_rect(Rect2(Vector2(round(tail_x - half), box.end.y + step - (1 if step == 0 else 0)), Vector2(round(half * 2.0), 1)), PAPER)
	var font := HudStyle.font()
	for i in _rows.size():
		var row := _rows[i]
		var width := font.get_string_size(row, HORIZONTAL_ALIGNMENT_LEFT, -1, HudStyle.SMALL).x
		var at := Vector2(round(box.position.x + (box.size.x - width) / 2.0), box.position.y + PAD.y + ROW * i + 7.0)
		draw_string(font, at, row, HORIZONTAL_ALIGNMENT_LEFT, -1, HudStyle.SMALL, INK)
