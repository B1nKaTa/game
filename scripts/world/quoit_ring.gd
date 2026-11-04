class_name QuoitRing
extends Node2D

# A deck quoit, a rope ring thrown onto a warned spot. A red circle fills for its warning, then it lands:
# it breaks props, as any boss attack does, and costs Grandpa a pill if his feet are inside. Then it
# lies on the deck for a few seconds, and while his feet are inside it he is slowed. It comes to nothing
# if the boss who threw it falls before it lands. One already lying stays until it is picked up.
const COLOR := Color("e4524f")
const ROPE := Color("d9b77a")
const ROPE_DARK := Color("7a5a2a")
const SLOW_RING := Color(0.62, 0.86, 1.0, 0.8)
const RADIUS := 22.0
const WARNING := 0.9
const LIE_TIME := 3.0
const SLOW := 0.5
# Each moment inside slows him for this long, so stepping out frees him almost at once.
const SLOW_REFRESH := 0.3
const DROP_HEIGHT := 50.0

var _source: Enemy
var _target: Node2D
var _warning := WARNING
var _left := WARNING
var _lie_left := LIE_TIME
var _landed := false
var _damage := -1


static func inside(center: Vector2, radius: float, feet: Vector2) -> bool:
	return center.distance_to(feet) <= radius


func setup(source: Enemy, warning := WARNING, lie_time := LIE_TIME, damage := -1) -> void:
	_source = source
	_target = source.target if source != null else null
	_warning = warning
	_left = warning
	_lie_left = lie_time
	_damage = damage
	z_index = Projectile.SHOT_Z


func is_lying() -> bool:
	return _landed and _lie_left > 0.0


# How far the warning has filled, from 0 to 1.
func fill() -> float:
	if _warning <= 0.0:
		return 1.0
	return clampf(1.0 - _left / _warning, 0.0, 1.0)


# True once, on the moment it lands.
func advance(delta: float) -> bool:
	if _landed:
		return false
	_left -= delta
	if _left <= 0.0:
		_landed = true
		return true
	return false


# Counts down how long it lies there. True once, as it is gone.
func lie(delta: float) -> bool:
	if not _landed or _lie_left <= 0.0:
		return false
	_lie_left -= delta
	return _lie_left <= 0.0


func _process(delta: float) -> void:
	queue_redraw()
	if not _landed:
		if not is_instance_valid(_source) or _source.is_dead():
			queue_free()
			return
		if advance(delta):
			_source.land_ground_strike(global_position, RADIUS, _damage)
		return
	if lie(delta):
		queue_free()
		return
	if not is_instance_valid(_target) or not _target.has_method("slow"):
		return
	var feet: Vector2 = _target.feet().global_position if _target.has_method("feet") else _target.global_position
	if inside(global_position, RADIUS, feet):
		_target.slow(SLOW, SLOW_REFRESH)


func _draw() -> void:
	if _landed:
		draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 24, SLOW_RING, 2.0)
		_draw_rope(Vector2.ZERO)
		return
	var filled := fill()
	draw_circle(Vector2.ZERO, RADIUS * filled, Color(COLOR, 0.15 + 0.3 * filled))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 24, COLOR, 2.0)
	_draw_rope(Vector2(0.0, -DROP_HEIGHT * (1.0 - filled)))


func _draw_rope(at: Vector2) -> void:
	draw_arc(at, RADIUS * 0.6, 0.0, TAU, 20, ROPE_DARK, 6.0)
	draw_arc(at, RADIUS * 0.6, 0.0, TAU, 20, ROPE, 4.0)
