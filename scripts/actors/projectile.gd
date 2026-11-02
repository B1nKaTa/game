class_name Projectile
extends Node2D

const HIT_RADIUS := 12.0
const LIFETIME := 5.0

var _velocity := Vector2.ZERO
var _target: Node2D
var _damage := 1
var _age := 0.0


func setup(direction: Vector2, speed: float, target: Node2D, damage: int) -> void:
	_velocity = direction.normalized() * speed
	_target = target
	_damage = damage


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME or not is_instance_valid(_target):
		queue_free()
		return
	var next := global_position + _velocity * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, next, 1)
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		queue_free()
		return
	global_position = next
	if global_position.distance_to(_target.global_position) <= HIT_RADIUS:
		_target.take_hit(_damage)
		queue_free()


func _draw() -> void:
	draw_rect(Rect2(-4, -5, 8, 10), Color("efe8d2"))
	draw_rect(Rect2(-4, -5, 8, 10), Color.BLACK, false, 1.0)
