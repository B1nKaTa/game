class_name SootGhostBehavior
extends EnemyBehavior

# Fades into smoke, where nothing can hit it, drifts after Grandpa, then comes out right beside him
# after a warning that shows for its whole length and swipes. It stays out in the open for a
# while, which is the time to hit it, and fades again. It always comes back out of the smoke, so
# a room can always be finished.
const FIRST_SMOKE := 0.8
const SMOKE_TIME := 1.5
const SMOKE_SPEED_SCALE := 1.4
const RISE_WINDUP := 0.85
const SWIPE_RANGE := 28.0
const BESIDE := 20.0
const OPEN_TIME := 2.5

enum State { SMOKE, RISING, OPEN }

var _telegraph := Telegraph.new()
var _state := State.SMOKE
var _left := FIRST_SMOKE
var _side := 1.0


# Every state leads on to the next on its timer, and smoke always leads back out.
static func next_state(state: int) -> int:
	match state:
		State.SMOKE:
			return State.RISING
		State.RISING:
			return State.OPEN
	return State.SMOKE


static func swipe_hits(at: Vector2, feet: Vector2) -> bool:
	return at.distance_to(feet) <= SWIPE_RANGE


# Where it comes out: a little to one side of his feet, never right under him.
static func beside(feet: Vector2, side: float) -> Vector2:
	return feet + Vector2(BESIDE * side, -4.0)


func state() -> int:
	return _state


func tick(enemy: Enemy, delta: float) -> void:
	match _state:
		State.SMOKE:
			if not enemy.submerged:
				enemy.set_submerged(true)
			enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed * SMOKE_SPEED_SCALE
			_left -= delta
			if _left <= 0.0:
				_begin_rising(enemy)
		State.RISING:
			if _telegraph.tick(delta):
				enemy.clear_warning()
				enemy.set_submerged(false)
				enemy.burst_from_ground()
				if swipe_hits(enemy.global_position, enemy.target_ground()):
					enemy.hit_target(enemy.def.damage)
				_state = next_state(_state)
				_left = OPEN_TIME
		State.OPEN:
			enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed
			_left -= delta
			if _left <= 0.0:
				_state = next_state(_state)
				_left = SMOKE_TIME


func _begin_rising(enemy: Enemy) -> void:
	_side = -_side
	var spot := beside(enemy.target_ground(), _side)
	# Open floor keeps the spot. Only one inside something solid moves to the nearest floor.
	if enemy.summon_spot.is_valid():
		var floor_spot: Vector2 = enemy.summon_spot.call(spot)
		if floor_spot.distance_to(spot) > RoomBackdrop.TILE * Enemy.SAME_CELL_REACH:
			spot = floor_spot
	enemy.global_position = spot
	_telegraph.start(RISE_WINDUP)
	enemy.set_warning(_telegraph, SWIPE_RANGE, true)
	_state = next_state(_state)
