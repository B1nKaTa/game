class_name BossDash
extends RefCounted

# Breaks what lies just ahead, so the body never has to stop at something breakable.
const SMASH_AHEAD := 22.0
const SMASH_RADIUS := 26.0

var _direction := Vector2.RIGHT
var _left := 0.0
var _speed := 0.0
var _hit_range := 0.0
var _has_hit := false
var _damage := -1


static func stops_at(collider: Object) -> bool:
	return not collider is BreakableBlock


# A damage of -1 costs the boss's usual damage, and a heavy charge passes 2.
func start(direction: Vector2, length: float, speed: float, hit_range: float, damage := -1) -> void:
	_direction = direction
	_left = length
	_speed = speed
	_hit_range = hit_range
	_has_hit = false
	_damage = damage


func is_active() -> bool:
	return _left > 0.0


func stop() -> void:
	_left = 0.0


func tick(enemy: Enemy, delta: float) -> void:
	for i in enemy.get_slide_collision_count():
		if stops_at(enemy.get_slide_collision(i).get_collider()):
			stop()
			return
	_left -= _speed * delta
	enemy.desired_velocity = _direction * _speed
	enemy.smash(enemy.global_position + _direction * SMASH_AHEAD, SMASH_RADIUS)
	if not _has_hit and enemy.distance_to_target() <= _hit_range:
		_has_hit = true
		enemy.hit_target(enemy.attack_damage(_damage))
