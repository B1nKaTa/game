class_name TrainingDummy
extends Node2D

# Shows each hit on the Training Yard's dummy as a number that rises above its head and fades. It
# stands where the dummy stands, and draws above the speech bubbles.

const RISE := 18.0
const LIFE := 0.8
const NUMBER_Z := 50
const FONT_SIZE := 10
const NUMBER_COLOR := Color("ffe9a8")
# Numbers start just above the dummy's head.
const HEAD_GAP := 6.0
# Hits close together step sideways, so their numbers don't sit on one another.
const STAGGER := 7.0

var _enemy: Enemy
# Each showing number: {"text", "age", "x"}. Left untyped, since filter hands back a plain Array.
var _numbers: Array = []
var _next_side := 0


func _ready() -> void:
	z_index = NUMBER_Z


func watch(enemy: Enemy) -> void:
	_enemy = enemy
	enemy.health_changed.connect(_on_health_changed)


static func hit_amount(before: float, after: float) -> int:
	return roundi(before - after)


# Each hit is measured from full health, and the dummy is put back to full at once, so even two hits in
# one frame show apart and no hit can ever take it below zero.
func _on_health_changed(hp: float) -> void:
	if not is_instance_valid(_enemy) or is_inf(hp) or is_nan(hp):
		return
	var amount := hit_amount(_enemy.max_hp(), hp)
	_enemy.hp = _enemy.max_hp()
	if amount <= 0:
		return
	var offset := float((_next_side % 3) - 1) * STAGGER
	_next_side += 1
	_numbers.append({"text": str(amount), "age": 0.0, "x": offset})


func numbers_showing() -> int:
	return _numbers.size()


func _process(delta: float) -> void:
	if _numbers.is_empty():
		return
	for number in _numbers:
		number["age"] += delta
	_numbers = _numbers.filter(func(number: Dictionary): return number["age"] < LIFE)
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var head := -(_enemy.def.body_size.y / 2.0 if is_instance_valid(_enemy) else 16.0) - HEAD_GAP
	for number in _numbers:
		var share: float = number["age"] / LIFE
		var text: String = number["text"]
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		var x: float = number["x"]
		var at := Vector2(x - width / 2.0, head - RISE * share)
		var color := NUMBER_COLOR
		color.a = 1.0 - share
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 3, Color(0, 0, 0, color.a))
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
