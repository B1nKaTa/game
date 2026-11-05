class_name ThrownDentures
extends Node2D

# Grandpa's false teeth in flight. They chatter forward, bite the first enemy they reach (or the
# first few, with Extra Strong Dentures), then drop and keep chattering until they come back.
# The denture items change that: glued, they hang on to the first enemy biting (Denture Glue Gun);
# as a boomerang they fly straight back biting on the way (Boomerang Bite); lying on the floor they
# bite whatever walks over them (Chattering Wind-Up Teeth). The Spare Set's second set is one of these
# with spare set, which nothing waits on.
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
# Glued, they bite this often for this share of a bite.
const GLUE_BITE_EVERY := 0.5
const GLUE_SHARE := 0.4
# Lying on the floor wound up, they bite each enemy at most this often, for this share of a bite.
const FLOOR_BITE_EVERY := 0.6
const FLOOR_SHARE := 0.5
const GUM_COLOR := Color("d9707a")
const TOOTH_COLOR := Color("f4f1e6")
const OUTLINE_COLOR := Color("3a1c20")
const GLUE_COLOR := Color("f3e58c")
const KEY_COLOR := Color("e8b84a")
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
# The denture items, set after setup from the run's stats.
var glue_time := 0.0
var boomerang := false
var floor_bite := false
# The Spare Set's second set: caught, it simply goes, since no throw waits on it.
var spare := false
var _damage := DAMAGE
var _range := DentureThrow.BASE_RANGE
var _bites_allowed := 1
var _bitten := {}
var _travelled := 0.0
var _time := 0.0
# Glued: to what, where on it, for how much longer, and the waits to the next bite and next whole second.
var _glued: Enemy
var _glue_offset := Vector2.ZERO
var _glue_left := 0.0
var _glue_bite_wait := 0.0
var _glue_second_wait := 0.0
var _glue_done := false
# On the way back as a boomerang, which enemies it has bitten since turning.
var _bitten_back := {}
# Lying wound up: instance id -> seconds until it may bite that enemy again.
var _floor_wait := {}


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


func is_glued() -> bool:
	return _glued != null


func glued_to() -> Enemy:
	return _glued


func _physics_process(delta: float) -> void:
	_time += delta
	if _glued != null:
		hold_glue(delta)
	elif _state.is_flying():
		_fly(delta)
	elif _state.is_dropped():
		_state.tick(delta)
		if floor_bite:
			bite_on_floor(delta)
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
	var enemy := _enemy_in_reach(_bitten)
	if enemy != null:
		_bitten[enemy.get_instance_id()] = true
		bite_enemy(enemy, 1.0, _direction * PUSH)
		if try_glue(enemy):
			return
		if not keeps_flying(_bitten.size(), _bites_allowed):
			end_flight()
			return
	if wall_hit or _travelled >= _range:
		end_flight()


# One bite, through the run's items when there are any.
func bite_enemy(enemy: Enemy, share: float, push := Vector2.ZERO) -> void:
	var bite := PlayerStats.strike_damage(_damage, enemy.hp / maxf(enemy.max_hp(), 1.0), wounded_mult)
	var amount := PlayerStats.boss_damage(bite, enemy.def.is_boss, boss_mult) * share
	if effects != null:
		effects.land(enemy, amount, RunEffects.BITE, push)
		effects.bite(enemy)
	else:
		enemy.take_damage(amount, push)
	hit_enemy.emit()


# The flight is over: a boomerang turns for home, anything else drops where it is.
func end_flight() -> void:
	if boomerang:
		_bitten_back.clear()
		_state.recall()
	else:
		_state.drop()


# With the Glue Gun, the first enemy bitten keeps them. Returns whether they stuck.
func try_glue(enemy: Enemy) -> bool:
	if glue_time <= 0.0 or _glue_done or enemy.is_dead():
		return false
	_glued = enemy
	_glue_offset = (global_position - enemy.global_position).limit_length(enemy.def.body_size.x * 0.4)
	_glue_left = glue_time
	_glue_bite_wait = GLUE_BITE_EVERY
	_glue_second_wait = 1.0
	return true


# Hangs on and bites on, telling the items each whole second, until the glue gives or the enemy falls.
func hold_glue(delta: float) -> void:
	var enemy := _glued
	if not is_instance_valid(enemy) or enemy.is_dead() or enemy.submerged:
		_unglue()
		return
	if enemy.is_inside_tree() and is_inside_tree():
		global_position = enemy.global_position + _glue_offset
	_glue_left -= delta
	_glue_bite_wait -= delta
	_glue_second_wait -= delta
	if _glue_bite_wait <= 0.0:
		_glue_bite_wait += GLUE_BITE_EVERY
		bite_enemy(enemy, GLUE_SHARE)
	if _glue_second_wait <= 0.0 and is_instance_valid(enemy) and not enemy.is_dead():
		_glue_second_wait += 1.0
		if effects != null:
			effects.glue_tick(enemy)
	if _glue_left <= 0.0 or not is_instance_valid(enemy) or enemy.is_dead():
		_unglue()


func _unglue() -> void:
	_glued = null
	_glue_done = true
	if _state.is_flying():
		end_flight()


# Lying wound up, they bite whatever walks over them, each enemy at most every FLOOR_BITE_EVERY.
func bite_on_floor(delta: float) -> void:
	for key: int in _floor_wait.keys():
		_floor_wait[key] -= delta
		if _floor_wait[key] <= 0.0:
			_floor_wait.erase(key)
	for node in _enemies():
		var enemy := node as Enemy
		if enemy == null or not is_instance_valid(enemy) or enemy.is_dead() or enemy.submerged:
			continue
		var key := enemy.get_instance_id()
		if _floor_wait.has(key) or not touches_body(global_position, enemy.body_rect()):
			continue
		_floor_wait[key] = FLOOR_BITE_EVERY
		bite_enemy(enemy, FLOOR_SHARE)


func _enemies() -> Array:
	if effects != null and effects.ctx.enemy_source.is_valid():
		return effects.ctx.enemy_source.call()
	if not is_inside_tree():
		return []
	return get_tree().get_nodes_in_group("enemies")


# Piles and grass block nothing, so the teeth meet them by touch, as the thrown cane did.
func _break_loose_things_in_reach() -> void:
	for block: BreakableBlock in get_tree().get_nodes_in_group("breakable"):
		if not block.is_solid() and not block.is_queued_for_deletion() and touches_body(global_position, block.body_rect()):
			block.hit_by(BreakableBlock.SOURCE_CANE)


# The nearest enemy in reach that these teeth have not bitten yet, by the ids in already.
func _enemy_in_reach(already: Dictionary) -> Enemy:
	var best: Enemy = null
	var best_distance := INF
	for node in _enemies():
		var enemy := node as Enemy
		if enemy == null or not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or enemy.is_dead():
			continue
		if enemy.submerged or already.has(enemy.get_instance_id()):
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
	# A boomerang bites on the way home, as many as it may bite on the way out.
	if boomerang and _bitten_back.size() < _bites_allowed:
		var enemy := _enemy_in_reach(_bitten_back)
		if enemy != null:
			_bitten_back[enemy.get_instance_id()] = true
			bite_enemy(enemy, 1.0, to_player.normalized() * PUSH)


func _catch() -> void:
	_state.catch_teeth()
	if not spare:
		caught.emit()
	queue_free()


# A small set of teeth seen from the side: pink gums top and bottom, white teeth between, the jaw
# snapping open and shut. Fast in the air, slower with a little hop while they lie waiting. Glued they
# chomp fast in a blob of glue; wound up they carry a turning key; a boomerang spins on the way home.
func _draw() -> void:
	var resting := _state != null and _state.is_dropped()
	var speed := REST_CHATTER_SPEED if resting and not floor_bite else CHATTER_SPEED
	if _glued != null:
		speed = CHATTER_SPEED * 1.5
	var open := (0.5 + 0.5 * sin(_time * speed)) * JAW_OPEN
	var hop := -absf(sin(_time * speed * 0.5)) * REST_HOP if resting else 0.0
	var flip := -1.0 if _direction.x < 0.0 else 1.0
	var spin := _time * 14.0 if boomerang and _state != null and _state.is_returning() else 0.0
	if _glued != null:
		_draw_glue()
	draw_set_transform(Vector2(0.0, hop), spin, Vector2(flip, 1.0))
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
	if resting and floor_bite:
		_draw_key(upper.position.y)
	draw_set_transform(Vector2.ZERO)


# Glue: pale yellow blobs round the teeth and a drip under them.
func _draw_glue() -> void:
	for i in 5:
		var at := Vector2.from_angle(i * 1.3 + 0.4) * Vector2(9.0, 6.0)
		draw_circle(at, 4.4, OUTLINE_COLOR)
		draw_circle(at, 3.4, GLUE_COLOR)
	var drip := 4.0 + fmod(_time * 6.0, 5.0)
	draw_line(Vector2(2, 5), Vector2(2, 5 + drip), OUTLINE_COLOR, 3.5)
	draw_line(Vector2(2, 5), Vector2(2, 5 + drip), GLUE_COLOR, 2.0)


# A wind-up key on top, turning.
func _draw_key(top: float) -> void:
	var stem := Vector2(0, top - 4.0)
	draw_line(Vector2(0, top), stem, OUTLINE_COLOR, 3.0)
	draw_line(Vector2(0, top), stem, KEY_COLOR, 1.5)
	var turn := absf(cos(_time * 6.0))
	var wing := Vector2(5.0 * turn + 1.0, 0.0)
	for side: float in [-1.0, 1.0]:
		var at := stem + wing * side + Vector2(0, -1)
		draw_circle(at, 3.0, OUTLINE_COLOR)
		draw_circle(at, 2.0, KEY_COLOR)
