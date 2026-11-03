class_name PipeRing
extends Node2D

# The ring an organ pipe's chord sends out into the room. Its band rolls outward from the pipe and
# shoves whoever it passes away from the pipe, Grandpa and enemies alike, once each. The pipes'
# own beat does no damage. A dodge passes through, since a dodge breaks free of any push. A floor
# boss's crescendo plays the same rings with a damage, and those cost a pill like any band.
const PUSH_SPEED := 220.0
const PUSH_TIME := 0.35
const FROM := 12.0
const REACH := 150.0
const GROW_TIME := 0.7
const WIDTH := 16.0
const RING := Color(1.0, 0.86, 0.55, 0.75)
const RING_EDGE := Color(0.95, 0.55, 0.9, 0.9)
const HURT_EDGE := Color("e4524f")

var _inward := Vector2.DOWN
var _reach := REACH
var _time := GROW_TIME
var _width := WIDTH
var _grown := 0.0
var _damage := 0
var _pushed := {}


# The push a point gets as the band passes: straight away from the pipe at the given strength
# while the band covers it, and nothing in the ring's hollow or past its edge.
static func push_for(center: Vector2, radius_now: float, width: float, point: Vector2, strength: float) -> Vector2:
	if not Shockwave.band_hits(center, radius_now, width, point):
		return Vector2.ZERO
	var away := point - center
	if away.is_zero_approx():
		return Vector2.ZERO
	return away.normalized() * strength


# Inward is the way into the room from the wall the pipe stands in, so the ring is drawn on the
# room's side only. A damage of 0 is the beat's own ring, which only pushes.
func setup(inward: Vector2, reach := REACH, grow_time := GROW_TIME, damage := 0) -> void:
	_inward = inward
	_reach = reach
	_time = grow_time
	_damage = damage
	z_index = Projectile.SHOT_Z


func radius_now() -> float:
	return Shockwave.radius_at(FROM, _reach, _time, _grown)


func damage() -> int:
	return _damage


func _center() -> Vector2:
	return global_position if is_inside_tree() else position


func reach() -> float:
	return _reach


func _process(delta: float) -> void:
	_grown += delta
	queue_redraw()
	if _grown >= _time:
		queue_free()
		return
	if not is_inside_tree():
		return
	for player in get_tree().get_nodes_in_group("player"):
		if player.has_method("feet") and player.feet() != null:
			touch_player(player, player.feet().global_position)
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.is_dead():
			touch_enemy(enemy)


# Grandpa is shoved once as the band passes his feet. Only a crescendo's ring costs a pill.
func touch_player(player, feet: Vector2) -> void:
	var id: int = player.get_instance_id()
	if _pushed.has(id):
		return
	var shove := push_for(_center(), radius_now(), _width, feet, PUSH_SPEED)
	if shove == Vector2.ZERO:
		return
	_pushed[id] = true
	player.push(shove, PUSH_TIME)
	if _damage > 0 and player.has_method("take_hit"):
		player.take_hit(_damage)


func touch_enemy(enemy: Enemy) -> void:
	var id := enemy.get_instance_id()
	if _pushed.has(id):
		return
	var shove := push_for(_center(), radius_now(), _width, enemy.global_position, PUSH_SPEED)
	if shove == Vector2.ZERO:
		return
	_pushed[id] = true
	enemy.apply_push(shove, PUSH_TIME)


func _draw() -> void:
	var fade := 1.0 - clampf(_grown / maxf(_time, 0.001), 0.0, 1.0) * 0.6
	var radius := radius_now()
	var start := _inward.angle() - PI / 2.0
	var end := _inward.angle() + PI / 2.0
	draw_arc(Vector2.ZERO, radius, start, end, 32, Color(RING, RING.a * fade), _width * 0.6)
	var edge := HURT_EDGE if _damage > 0 else RING_EDGE
	draw_arc(Vector2.ZERO, radius + _width / 2.0, start, end, 32, Color(edge, edge.a * fade), 2.0)
	draw_arc(Vector2.ZERO, radius - _width / 2.0, start, end, 32, Color(edge, edge.a * fade * 0.6), 1.0)
