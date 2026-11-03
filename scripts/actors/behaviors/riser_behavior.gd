extends EnemyBehavior

# Digs in, tunnels after Grandpa as a moving mound nothing can hit, then rises under him after a
# warning that shows for its whole length. It stands in the open for a while, which is the time to
# hit it, and digs in again.
const RISE_WINDUP := 0.85
const RISE_RADIUS := 30.0
const FIRST_TUNNEL := 0.7
const TUNNEL_TIME := 1.2
const TUNNEL_SPEED_SCALE := 1.7
const UP_TIME := 2.8

enum State { TUNNEL, RISING, UP }

var _telegraph := Telegraph.new()
var _state := State.TUNNEL
var _left := FIRST_TUNNEL


static func next_state(state: int) -> int:
	match state:
		State.TUNNEL:
			return State.RISING
		State.RISING:
			return State.UP
	return State.TUNNEL


static func rise_hits(at: Vector2, feet: Vector2) -> bool:
	return at.distance_to(feet) <= RISE_RADIUS


func tick(enemy: Enemy, delta: float) -> void:
	match _state:
		State.TUNNEL:
			if not enemy.submerged:
				enemy.set_submerged(true)
			enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed * TUNNEL_SPEED_SCALE
			_left -= delta
			if _left <= 0.0:
				_begin_rising(enemy)
		State.RISING:
			if _telegraph.tick(delta):
				enemy.clear_warning()
				enemy.set_submerged(false)
				enemy.burst_from_ground()
				if rise_hits(enemy.global_position, enemy.target_ground()):
					enemy.hit_target(enemy.def.damage)
				_state = next_state(_state)
				_left = UP_TIME
		State.UP:
			enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed
			_left -= delta
			if _left <= 0.0:
				_state = next_state(_state)
				_left = TUNNEL_TIME


func _begin_rising(enemy: Enemy) -> void:
	enemy.move_under_target()
	_telegraph.start(RISE_WINDUP)
	enemy.set_warning(_telegraph, RISE_RADIUS, true)
	_state = next_state(_state)
