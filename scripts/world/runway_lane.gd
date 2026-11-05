class_name RunwayLane
extends Node2D

# One lane of Augustine's runway lights. While it waits its turn it shows a faint outline and a row of
# dim lamps; then it warns, filling red as any warned lane does; then its lamps blaze for a moment, and
# feet in the lane while it is lit cost a pill, once. The lanes of one pattern light one after another,
# so a lane that has just gone out is a safe place to step. It comes to nothing if he falls first.
const COLOR := Color("e4524f")
const LAMP_DIM := Color(1.0, 0.95, 0.6, 0.35)
const LAMP_LIT := Color("fff6c8")
const BLAZE := Color(1.0, 0.95, 0.65, 0.55)
const LIT_TIME := 0.25
const LAMP_EVERY := 24.0

var _source: Enemy
var _direction := Vector2.RIGHT
var _length := 100.0
var _width := 40.0
var _delay := 0.0
var _warning := 0.9
var _left := 0.9
var _lit_left := LIT_TIME
var _damage := -1
var _has_hit := false


# Whether a point lies in a lane that starts at origin and runs length along direction.
static func covers(origin: Vector2, direction: Vector2, length: float, width: float, point: Vector2) -> bool:
	var offset := point - origin
	var along := offset.dot(direction)
	return along >= 0.0 and along <= length and absf(offset.dot(direction.orthogonal())) <= width / 2.0


# The lane starts at its place, waits delay, warns for warning, then lights.
func setup(source: Enemy, direction: Vector2, length: float, width: float, delay: float, warning: float, damage := -1) -> void:
	_source = source
	_direction = direction.normalized()
	_length = length
	_width = width
	_delay = delay
	_warning = warning
	_left = warning
	_damage = damage
	z_index = Projectile.SHOT_Z


func is_waiting() -> bool:
	return _delay > 0.0


func is_lit() -> bool:
	return _delay <= 0.0 and _left <= 0.0 and _lit_left > 0.0


# Moves the lane on. Returns true while it is lit.
func advance(delta: float) -> bool:
	if _delay > 0.0:
		_delay -= delta
		return false
	if _left > 0.0:
		_left -= delta
		return false
	var was_lit := _lit_left > 0.0
	_lit_left -= delta
	return was_lit


# When, counted from now, the lane is lit: x its start and y its end, or (-1, -1) once it is over.
func danger_window() -> Vector2:
	if is_over():
		return Vector2(-1.0, -1.0)
	var lights := maxf(_delay, 0.0) + maxf(_left, 0.0)
	return Vector2(lights, lights + maxf(_lit_left, 0.0))


# The lane's floor as a rectangle in the room, for a lane running right or down.
func lane_rect() -> Rect2:
	var across := _direction.orthogonal().abs()
	var start := global_position - across * _width / 2.0
	return Rect2(start, _direction.abs() * _length + across * _width)


func is_over() -> bool:
	return _delay <= 0.0 and _left <= 0.0 and _lit_left <= 0.0


func _process(delta: float) -> void:
	queue_redraw()
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	var lit := advance(delta)
	if lit and not _has_hit and is_instance_valid(_source.target):
		if covers(global_position, _direction, _length, _width, _source.target_ground()):
			if _source.target.take_hit(_source.attack_damage(_damage)):
				_has_hit = true
	if is_over():
		queue_free()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, _direction.angle())
	var lane := Rect2(0.0, -_width / 2.0, _length, _width)
	var lamp := LAMP_DIM
	if _delay > 0.0:
		draw_rect(lane, Color(COLOR, 0.35), false, 1.0)
	elif _left > 0.0:
		var progress := clampf(1.0 - _left / maxf(_warning, 0.001), 0.0, 1.0)
		draw_rect(Rect2(0.0, -_width / 2.0, _length * progress, _width), Color(COLOR, 0.15 + 0.3 * progress))
		draw_rect(lane, COLOR, false, 2.0)
	elif _lit_left > 0.0:
		draw_rect(lane, BLAZE)
		draw_rect(lane, COLOR, false, 2.0)
		lamp = LAMP_LIT
	var count := floori(_length / LAMP_EVERY)
	for i in count:
		var x := (i + 0.5) * LAMP_EVERY
		for y in [-_width / 2.0 + 5.0, _width / 2.0 - 5.0]:
			draw_circle(Vector2(x, y), 2.5, lamp)
	draw_set_transform(Vector2.ZERO)
