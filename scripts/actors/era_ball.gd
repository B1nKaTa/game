class_name EraBall
extends Node2D

# The football: it flies, bounces off up to three walls, hurts what it passes through, then rests until
# Harold walks over it. It pays nothing and spawns nothing; its hits go through Player.era_hit.

const SPEED := 260.0
const DAMAGE := 12.0
const BOUNCES := 3
const RADIUS := 6.0
const PICKUP_RADIUS := 16.0
const SLOWDOWN := 0.9
# A ball that finds no wall this long after its last one (out through a gap) stops, so it never flies on for ever.
const FLIGHT_TIME := 3.0

var direction := Vector2.RIGHT
var _bounces_left := BOUNCES
var _speed := SPEED
var _flown := 0.0
var _hit := {}


func is_resting() -> bool:
	return _speed <= 0.0


func bounces_used() -> int:
	return BOUNCES - _bounces_left


# A wall's normal; returns whether it bounced.
func bounce(normal: Vector2) -> bool:
	if _bounces_left <= 0:
		_speed = 0.0
		return false
	_bounces_left -= 1
	direction = direction.bounce(normal)
	_speed *= SLOWDOWN
	_flown = 0.0
	_hit.clear()
	return true


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if is_resting():
		if player != null and player.feet().global_position.distance_to(global_position) <= PICKUP_RADIUS:
			queue_free()
		return
	_flown += delta
	if _flown >= FLIGHT_TIME:
		_speed = 0.0
		queue_redraw()
		return
	var step := direction * _speed * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + step + direction * RADIUS, ThrownDentures.BLOCKED_BY)
	var wall := get_world_2d().direct_space_state.intersect_ray(query)
	if not wall.is_empty():
		bounce(wall["normal"])
		return
	global_position += step
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		var id := enemy.get_instance_id()
		if _hit.has(id) or enemy.is_queued_for_deletion() or enemy.submerged or not enemy.body_rect().grow(RADIUS).has_point(global_position):
			continue
		_hit[id] = true
		if player != null:
			player.era_hit(enemy, DAMAGE, direction * 60.0, global_position)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color("f2efe6"))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 16, Color("2b2622"), 1.0)
	draw_circle(Vector2(-1, -1), 2.0, Color("2b2622"))
