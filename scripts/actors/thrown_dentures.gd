class_name ThrownDentures
extends Node2D

# Grandpa's false teeth in flight. They chatter forward, bite the first enemy they reach (or the
# first few, with Extra Strong Dentures), then drop and keep chattering until they come back.
signal hit_enemy
signal caught

const FLY_SPEED := 320.0
const DAMAGE := 14.0
const PUSH := 80.0
const PICKUP_RADIUS := 18.0
const RETURN_SPEED := 400.0
const CATCH_RADIUS := 8.0
const WALL_LAYER := 1
# What stops them in flight: walls and props, and a raised queue barrier (Departures, Terminal Zero).
const BLOCKED_BY := WALL_LAYER | QueueBarrier.LAYER
const WALL_BACKOFF := 4.0
# How far ahead of him they leave his hand.
const SPAWN_AHEAD := 20.0
# How far from their middle a bite reaches, the same as the thrown cane's tip did.
const HIT_REACH := 10.0
const GUM_COLOR := Color("d9707a")
const TOOTH_COLOR := Color("f4f1e6")
const OUTLINE_COLOR := Color("3a1c20")
const JAW_WIDTH := 12.0
const JAW_OPEN := 3.0
const CHATTER_SPEED := 26.0
const REST_CHATTER_SPEED := 10.0
const REST_HOP := 1.5

var _state: DentureThrow
var _player: Node2D
var _direction := Vector2.RIGHT
# What a bite is multiplied by against a wounded enemy, as the Bifocals option gives. Set after setup.
var wounded_mult := 1.0
# What a bite is multiplied by against a boss, as the gold gavel gives. Set after setup.
var boss_mult := 1.0
# The run's items, which hear every bite. Set after setup. Without it a bite is plain damage.
var effects: RunEffects
var _damage := DAMAGE
var _range := DentureThrow.BASE_RANGE
var _bites_allowed := 1
var _bitten := {}
var _travelled := 0.0
var _time := 0.0


func setup(state: DentureThrow, player: Node2D, direction: Vector2, bite_mult: float, max_range := DentureThrow.BASE_RANGE, bites := 1) -> void:
	_state = state
	_player = player
	_direction = direction
	_damage = bite_damage(bite_mult)
	_range = max_range
	_bites_allowed = maxi(bites, 1)


static func advance_travel(travelled: float, delta: float, max_range := DentureThrow.BASE_RANGE) -> float:
	return minf(travelled + FLY_SPEED * delta, max_range)


static func bite_damage(bite_mult: float) -> float:
	return DAMAGE * bite_mult


static func touches_body(point: Vector2, body: Rect2) -> bool:
	return point.distance_to(MeleeArc.closest_point(body, point)) <= HIT_REACH


# Whether a flight that has bitten so many times keeps going. Without Extra Strong Dentures one bite ends it.
static func keeps_flying(bites_done: int, bites_allowed: int) -> bool:
	return bites_done < maxi(bites_allowed, 1)


func _physics_process(delta: float) -> void:
	_time += delta
	if _state.is_flying():
		_fly(delta)
	elif _state.is_dropped():
		_state.tick(delta)
		_try_pick_up()
	elif _state.is_returning():
		_return_to_player(delta)
	queue_redraw()


func _fly(delta: float) -> void:
	var new_travel := advance_travel(_travelled, delta, _range)
	var step := new_travel - _travelled
	var from := global_position
	var to := from + _direction * step
	var wall_hit := false
	var query := PhysicsRayQueryParameters2D.create(from, to, BLOCKED_BY)
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
		_bitten[enemy.get_instance_id()] = true
		var bite := PlayerStats.strike_damage(_damage, enemy.hp / maxf(enemy.max_hp(), 1.0), wounded_mult)
		var amount := PlayerStats.boss_damage(bite, enemy.def.is_boss, boss_mult)
		if effects != null:
			effects.land(enemy, amount, RunEffects.BITE, _direction * PUSH)
			effects.bite(enemy)
		else:
			enemy.take_damage(amount, _direction * PUSH)
		hit_enemy.emit()

		if not keeps_flying(_bitten.size(), _bites_allowed):
			_state.drop()
			return
	if wall_hit or _travelled >= _range:
		_state.drop()


# Piles and grass block nothing, so the teeth meet them by touch, as the thrown cane did.
func _break_loose_things_in_reach() -> void:
	for block: BreakableBlock in get_tree().get_nodes_in_group("breakable"):
		if not block.is_solid() and not block.is_queued_for_deletion() and touches_body(global_position, block.body_rect()):
			block.hit_by(BreakableBlock.SOURCE_CANE)


# The nearest enemy in reach that these teeth have not bitten yet on this flight.
func _enemy_in_reach() -> Enemy:
	var best: Enemy = null
	var best_distance := INF
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_queued_for_deletion() or enemy.submerged or _bitten.has(enemy.get_instance_id()):
			continue
		if not touches_body(global_position, enemy.body_rect()):
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
	_state.catch_teeth()
	caught.emit()
	queue_free()


# A small set of teeth seen from the side: pink gums top and bottom, white teeth between, the jaw
# snapping open and shut. Fast in the air, slower with a little hop while they lie waiting.
func _draw() -> void:
	var resting := _state != null and _state.is_dropped()
	var speed := REST_CHATTER_SPEED if resting else CHATTER_SPEED
	var open := (0.5 + 0.5 * sin(_time * speed)) * JAW_OPEN
	var hop := -absf(sin(_time * speed * 0.5)) * REST_HOP if resting else 0.0
	var flip := -1.0 if _direction.x < 0.0 else 1.0
	draw_set_transform(Vector2(0.0, hop), 0.0, Vector2(flip, 1.0))
	var half := JAW_WIDTH / 2.0
	var upper := Rect2(-half, -4.0 - open / 2.0, JAW_WIDTH, 3.0)
	var lower := Rect2(-half, 1.0 + open / 2.0, JAW_WIDTH, 3.0)
	draw_rect(upper, GUM_COLOR)
	draw_rect(lower, GUM_COLOR)
	for i in 4:
		var x := -half + 1.0 + i * 2.7
		draw_rect(Rect2(x, upper.end.y, 2.0, 2.0), TOOTH_COLOR)
		draw_rect(Rect2(x, lower.position.y - 2.0, 2.0, 2.0), TOOTH_COLOR)
	draw_rect(upper, OUTLINE_COLOR, false, 1.0)
	draw_rect(lower, OUTLINE_COLOR, false, 1.0)
	# The hinge at the back, so the two halves read as one set.
	draw_line(Vector2(-half, upper.end.y), Vector2(-half, lower.position.y), GUM_COLOR, 2.0)
	draw_set_transform(Vector2.ZERO)
