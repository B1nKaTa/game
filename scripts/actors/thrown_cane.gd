class_name ThrownCane
extends Node2D

signal hit_enemy
signal caught

const FLY_SPEED := 320.0
const MAX_RANGE := 200.0
const DAMAGE := 14.0
const PUSH := 80.0
const PICKUP_RADIUS := 18.0
const RETURN_SPEED := 400.0
const CATCH_RADIUS := 8.0
const WALL_LAYER := 1
const WALL_BACKOFF := 4.0
const SPIN_SPEED := 18.0
const LENGTH := 20.0
const HIT_REACH := LENGTH * 0.5

var _state: CaneThrow
var _player: Node2D
var _direction := Vector2.RIGHT
var _damage := DAMAGE
var _travelled := 0.0
var _spin := 0.0


func setup(state: CaneThrow, player: Node2D, direction: Vector2, damage_mult: float) -> void:
	_state = state
	_player = player
	_direction = direction
	_damage = hit_damage(damage_mult)


static func advance_travel(travelled: float, delta: float) -> float:
	return minf(travelled + FLY_SPEED * delta, MAX_RANGE)


static func hit_damage(damage_mult: float) -> float:
	return DAMAGE * damage_mult


static func touches_body(point: Vector2, body: Rect2) -> bool:
	return point.distance_to(MeleeArc.closest_point(body, point)) <= HIT_REACH


func _physics_process(delta: float) -> void:
	if _state.is_flying():
		_fly(delta)
	elif _state.is_dropped():
		_state.tick(delta)
		_try_pick_up()
	elif _state.is_returning():
		_return_to_player(delta)
	queue_redraw()


func _fly(delta: float) -> void:
	_spin += SPIN_SPEED * delta
	var new_travel := advance_travel(_travelled, delta)
	var step := new_travel - _travelled
	var from := global_position
	var to := from + _direction * step
	var wall_hit := false
	var query := PhysicsRayQueryParameters2D.create(from, to, WALL_LAYER)
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		wall_hit = true
		var collider: Object = result.get("collider")
		if collider is BreakableBlock:
			collider.hit_by(BreakableBlock.SOURCE_CANE)
		to = result["position"] + result["normal"] * WALL_BACKOFF
	_travelled = new_travel
	global_position = to
	_break_loose_things_in_reach()
	var enemy := _enemy_in_reach()
	if enemy != null:
		enemy.take_damage(_damage, _direction * PUSH)
		_state.drop()
		hit_enemy.emit()
	elif wall_hit or _travelled >= MAX_RANGE:
		_state.drop()


# Piles and grass block nothing, so the cane meets them by touch.
func _break_loose_things_in_reach() -> void:
	for block: BreakableBlock in get_tree().get_nodes_in_group("breakable"):
		if not block.is_solid() and not block.is_queued_for_deletion() and touches_body(global_position, block.body_rect()):
			block.hit_by(BreakableBlock.SOURCE_CANE)


func _enemy_in_reach() -> Enemy:
	var best: Enemy = null
	var best_distance := INF
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_queued_for_deletion() or enemy.submerged or not touches_body(global_position, enemy.body_rect()):
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best


func _try_pick_up() -> void:
	if is_instance_valid(_player) and global_position.distance_to(_player.global_position) <= PICKUP_RADIUS:
		_catch()


func _return_to_player(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	var to_player := _player.global_position - global_position
	var step := RETURN_SPEED * delta
	if to_player.length() <= maxf(step, CATCH_RADIUS):
		_catch()
		return
	global_position += to_player.normalized() * step


func _catch() -> void:
	_state.catch_cane()
	caught.emit()
	queue_free()


func _draw() -> void:
	var angle := _spin if _state.is_flying() else _direction.angle()
	var half := Vector2.from_angle(angle) * LENGTH * 0.5
	draw_line(-half, half, Color("a8692f"), 3.0)
