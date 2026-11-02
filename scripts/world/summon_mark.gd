class_name SummonMark
extends Node2D

# Summons are telegraphed like any attack: a circle fills where each will stand.
signal finished

const RADIUS := 16.0
const COLOR := Color("e4524f")

var _duration := 0.5
var _left := 0.5


func setup(duration: float) -> void:
	_duration = duration
	_left = duration


func _process(delta: float) -> void:
	_left -= delta
	queue_redraw()
	if _left <= 0.0:
		finished.emit()
		queue_free()


func _draw() -> void:
	var progress := 1.0 - maxf(_left, 0.0) / _duration
	draw_circle(Vector2.ZERO, RADIUS * progress, Color(COLOR, 0.15 + 0.3 * progress))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 20, COLOR, 2.0)
	draw_line(Vector2(-5, -5), Vector2(5, 5), COLOR, 2.0)
	draw_line(Vector2(5, -5), Vector2(-5, 5), COLOR, 2.0)
