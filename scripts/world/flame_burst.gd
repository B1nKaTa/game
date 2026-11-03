class_name FlameBurst
extends Node2D

# The fire of a breath, shown for a moment over the cone that was warned. It hurts nothing itself:
# the breath decides its hit as it starts.
const SHOW_TIME := 0.4
const OUTER := Color(1.0, 0.55, 0.12, 0.8)
const INNER := Color(1.0, 0.92, 0.55, 0.9)

var _direction := Vector2.RIGHT
var _length := 130.0
var _angle := 60.0
var _left := SHOW_TIME


func setup(direction: Vector2, length: float, angle_deg: float) -> void:
	_direction = direction
	_length = length
	_angle = angle_deg
	z_index = Projectile.SHOT_Z


func _process(delta: float) -> void:
	_left -= delta
	queue_redraw()
	if _left <= 0.0:
		queue_free()


func _draw() -> void:
	var fade := clampf(_left / SHOW_TIME, 0.0, 1.0)
	var t := Time.get_ticks_msec() / 1000.0
	var half := deg_to_rad(_angle) / 2.0
	var outer := PackedVector2Array([Vector2.ZERO])
	var inner := PackedVector2Array([Vector2.ZERO])
	for i in 9:
		var a := _direction.angle() - half + half * 2.0 * i / 8.0
		var wobble := 1.0 - 0.12 * absf(sin(t * 24.0 + i * 1.7))
		outer.append(Vector2.from_angle(a) * _length * wobble)
		inner.append(Vector2.from_angle(_direction.angle() + (a - _direction.angle()) * 0.55) * _length * 0.65 * wobble)
	draw_colored_polygon(outer, Color(OUTER, OUTER.a * fade))
	draw_colored_polygon(inner, Color(INNER, INNER.a * fade))
