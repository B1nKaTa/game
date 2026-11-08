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
	z_index = Projectile.SHOT_Z
	_left = duration


func _process(delta: float) -> void:
	_left -= delta
	queue_redraw()
	if _left <= 0.0:
		finished.emit()
		queue_free()


func _draw() -> void:
	var progress := 1.0 - maxf(_left, 0.0) / _duration
	# With Attack warnings off (AttackWarnings) the spot where a summoned one appears is the faint dark
	# cue, with its cross, not red.
	if not AttackWarnings.shown:
		AttackWarnings.draw_cue_circle(self, Vector2.ZERO, RADIUS, progress)
		var cue := AttackWarnings.cue_color(1.0)
		draw_line(Vector2(-5, -5), Vector2(5, 5), cue, 2.0)
		draw_line(Vector2(5, -5), Vector2(-5, 5), cue, 2.0)
		return
	draw_circle(Vector2.ZERO, RADIUS * progress, Color(COLOR, 0.15 + 0.3 * progress))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 20, COLOR, 2.0)
	draw_line(Vector2(-5, -5), Vector2(5, 5), COLOR, 2.0)
	draw_line(Vector2(5, -5), Vector2(-5, 5), COLOR, 2.0)
