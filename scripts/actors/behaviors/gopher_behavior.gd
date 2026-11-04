class_name GopherBehavior
extends EnemyBehavior

# A gopher from under the greens. It burrows after Grandpa as a moving mound nothing can hit, then pops
# up out of a hole right where he stands, under a ring that warns for its whole length, and bites. It sits
# up in the open for a moment, which is the time to bop it, and burrows again. It never chases above
# ground: it waits to be hit or to dig back in.
const RISE_WINDUP := 0.8
const BITE_RADIUS := 26.0
const FIRST_BURROW := 0.9
const BURROW_TIME := 1.4
const BURROW_SPEED_SCALE := 1.8
const UP_TIME := 1.6
const BITE := "Chomp!"
const SAY_TIME := 0.6

enum State { BURROW, RISING, UP }

var _telegraph := Telegraph.new()
var _state := State.BURROW
var _left := FIRST_BURROW


static func next_state(state: int) -> int:
	match state:
		State.BURROW:
			return State.RISING
		State.RISING:
			return State.UP
	return State.BURROW


static func bite_hits(at: Vector2, feet: Vector2) -> bool:
	return at.distance_to(feet) <= BITE_RADIUS


func tick(enemy: Enemy, delta: float) -> void:
	match _state:
		State.BURROW:
			if not enemy.submerged:
				enemy.set_submerged(true)
			enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed * BURROW_SPEED_SCALE
			_left -= delta
			if _left <= 0.0:
				_begin_rising(enemy)
		State.RISING:
			if _telegraph.tick(delta):
				enemy.clear_warning()
				enemy.set_submerged(false)
				enemy.burst_from_ground()
				if bite_hits(enemy.global_position, enemy.target_ground()):
					enemy.say(BITE, SAY_TIME)
					enemy.hit_target(enemy.def.damage)
				_state = next_state(_state)
				_left = UP_TIME
		State.UP:
			_left -= delta
			if _left <= 0.0:
				_state = next_state(_state)
				_left = BURROW_TIME


func _begin_rising(enemy: Enemy) -> void:
	enemy.move_under_target()
	_telegraph.start(RISE_WINDUP)
	enemy.set_warning(_telegraph, BITE_RADIUS, true)
	_state = next_state(_state)
