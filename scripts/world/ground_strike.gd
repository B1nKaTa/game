class_name GroundStrike
extends Node2D

# A warned spot on the ground. A faint ring shows it is coming, a red circle fills for its whole
# warning, and then it lands: it breaks props and hurts Grandpa if his feet are inside. It comes
# to nothing if the boss that started it falls first.
const COLOR := Color("e4524f")
const FOLLOW_COLOR := Color("ffd24a")
const DUST_COLOR := Color("b9a97a")
const SHOW_TIME := 0.2
const WAITING_ALPHA := 0.35

var _source: Enemy
var _radius := 20.0
var _delay := 0.0
var _follow_left := 0.0
var _warning := 0.5
var _left := 0.5
var _landed := false
var _show_left := SHOW_TIME
# What landing costs Grandpa. -1 means the enemy's usual damage.
var _damage := -1


static func hits(center: Vector2, radius: float, feet: Vector2) -> bool:
	return center.distance_to(feet) <= radius


# A delay lets a line or a row land one after another. A pit follows him for follow_time before locking in.
func setup(source: Enemy, radius: float, warning: float, delay := 0.0, follow_time := 0.0, damage := -1) -> void:
	_source = source
	# Marks show above the room, the dark of Lights Out included.
	z_index = Projectile.SHOT_Z
	_radius = radius
	_warning = warning
	_left = warning
	_delay = delay
	_follow_left = follow_time
	_damage = damage


func damage() -> int:
	return _damage


func is_following() -> bool:
	return _follow_left > 0.0


# How far the warning has filled, from 0 to 1.
func fill() -> float:
	if _delay > 0.0 or _follow_left > 0.0 or _warning <= 0.0:
		return 0.0
	return clampf(1.0 - _left / _warning, 0.0, 1.0)


# True once, on the moment it lands.
func advance(delta: float) -> bool:
	if _landed:
		return false
	if _delay > 0.0:
		_delay -= delta
		return false
	if _follow_left > 0.0:
		_follow_left -= delta
		return false
	_left -= delta
	if _left <= 0.0:
		_landed = true
		return true
	return false


func _process(delta: float) -> void:
	queue_redraw()
	if _landed:
		_show_left -= delta
		if _show_left <= 0.0:
			queue_free()
		return
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	if is_following():
		global_position = _source.target_ground()
	if advance(delta):
		_source.land_ground_strike(global_position, _radius, _damage)


func _draw() -> void:
	if _landed:
		var progress := 1.0 - maxf(_show_left, 0.0) / SHOW_TIME
		draw_circle(Vector2.ZERO, _radius * minf(0.6 + progress, 1.0), Color(DUST_COLOR, 0.7 * (1.0 - progress)))
		return
	if _delay > 0.0:
		draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 24, Color(COLOR, WAITING_ALPHA), 1.0)
		return
	if is_following():
		draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 24, FOLLOW_COLOR, 2.0)
		draw_line(Vector2(-6, 0), Vector2(6, 0), FOLLOW_COLOR, 1.0)
		draw_line(Vector2(0, -6), Vector2(0, 6), FOLLOW_COLOR, 1.0)
		return
	var filled := fill()
	draw_circle(Vector2.ZERO, _radius * filled, Color(COLOR, 0.15 + 0.3 * filled))
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 24, COLOR, 2.0)
