class_name SafeSpotMark
extends Node2D

# Where a floor boss's organ crescendo leaves room to stand: a calm green ring on the floor for as long
# as the pipes glow and their rings pass. Among a dozen red reaches the one gap is otherwise hard to
# find in time. It is drawn above the room, as every mark is, and never hurts.
const RADIUS := 18.0
const COLOR := Color("7fe0a0")
const CORE := Color(0.5, 1.0, 0.7, 0.28)
const PULSE_SPEED := 8.0

var _left := 1.0
var _age := 0.0


func setup(seconds: float) -> void:
	_left = seconds
	z_index = Projectile.SHOT_Z


func time_left() -> float:
	return _left


func _process(delta: float) -> void:
	_age += delta
	_left -= delta
	queue_redraw()
	if _left <= 0.0:
		queue_free()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_age * PULSE_SPEED)
	draw_circle(Vector2.ZERO, RADIUS, CORE)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 24, COLOR, 2.0)
	draw_arc(Vector2.ZERO, RADIUS * (0.4 + 0.2 * pulse), 0.0, TAU, 16, Color(COLOR, 0.85), 1.5)
