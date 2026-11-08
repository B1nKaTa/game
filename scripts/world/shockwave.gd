class_name Shockwave
extends Node2D

# A ring that grows out from a hammer blow. While the blow winds up, a faint ring shows how far it
# will reach. Then the ring runs outward, and Grandpa's feet in its band as it passes cost a pill,
# once. Inside the ring, behind its edge, is safe, and a dodge passes through it as through any hit.
# It comes to nothing if the enemy that started it falls before the blow lands.
const COLOR := Color("e4524f")
const RING := Color("ffd9a8")
const RING_EDGE := Color("ff8a2a")

var _source: Enemy
var _from := 60.0
var _to := 140.0
var _time := 0.6
var _width := 14.0
var _warning := 0.7
var _left := 0.7
var _grown := 0.0
var _damage := -1
var _has_hit := false


# Whether a point lies in the band a ring of this radius covers.
static func band_hits(center: Vector2, radius_now: float, width: float, point: Vector2) -> bool:
	return absf(center.distance_to(point) - radius_now) <= width / 2.0


static func radius_at(from: float, to: float, time: float, grown: float) -> float:
	return lerpf(from, to, clampf(grown / maxf(time, 0.001), 0.0, 1.0))


func setup(source: Enemy, from_radius: float, to_radius: float, grow_time: float, width: float, warning: float, damage := -1) -> void:
	_source = source
	_from = from_radius
	_to = to_radius
	_time = grow_time
	_width = width
	_warning = warning
	_left = warning
	_damage = damage
	z_index = Projectile.SHOT_Z


func is_growing() -> bool:
	return _left <= 0.0 and _grown < _time


func radius_now() -> float:
	return radius_at(_from, _to, _time, _grown)


func width() -> float:
	return _width


func _process(delta: float) -> void:
	queue_redraw()
	if _left > 0.0:
		if not is_instance_valid(_source) or _source.is_dead():
			queue_free()
			return
		_left -= delta
		return
	_grown += delta
	if _grown >= _time:
		queue_free()
		return
	if _has_hit or not is_instance_valid(_source) or not is_instance_valid(_source.target):
		return
	if band_hits(global_position, radius_now(), _width, _source.target_ground()):
		if _source.target.take_hit(_source.attack_damage(_damage)):
			_has_hit = true


func _draw() -> void:
	if _left > 0.0:
		var progress := clampf(1.0 - _left / maxf(_warning, 0.001), 0.0, 1.0)
		if not AttackWarnings.drawn_by(_source):
			# Warnings hidden (AttackWarnings): the faint cue of how far the ring will reach.
			var cue := AttackWarnings.cue_color(progress)
			draw_arc(Vector2.ZERO, _to, 0.0, TAU, 48, cue, 2.0)
			draw_arc(Vector2.ZERO, lerpf(_from, _to, progress), 0.0, TAU, 48, cue, AttackWarnings.CUE_LINE)
			return
		draw_arc(Vector2.ZERO, _to, 0.0, TAU, 48, Color(COLOR, 0.35 + 0.5 * progress), 2.0)
		draw_arc(Vector2.ZERO, lerpf(_from, _to, progress), 0.0, TAU, 48, Color(COLOR, 0.25), 1.0)
		return
	var fade := 1.0 - clampf(_grown / _time, 0.0, 1.0) * 0.5
	var radius := radius_now()
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(RING, 0.85 * fade), _width)
	draw_arc(Vector2.ZERO, radius + _width / 2.0, 0.0, TAU, 48, Color(RING_EDGE, fade), 2.0)
	draw_arc(Vector2.ZERO, radius - _width / 2.0, 0.0, TAU, 48, Color(RING_EDGE, fade), 2.0)
