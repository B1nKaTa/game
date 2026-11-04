class_name LostLuggageBehavior
extends EnemyBehavior

# A suitcase left lying on the carpet, which is waiting for its owner. When Grandpa comes close it
# springs open with a warned bite around itself, shown whole since it starts right beside him. After
# that it is awake: it shuffles after him on its little wheels and bites again whenever he is near.
const WAKE_RANGE := 72.0
const BITE_WINDUP := 0.7
const BITE_RADIUS := 34.0
const COOLDOWN := 1.6
const SHUFFLE_SCALE := 1.0
const WAKE_TEXT := "Is that you?"
const SAY_TIME := 1.0

enum State { LYING, BITING, AWAKE }

var _telegraph := Telegraph.new()
var _state := State.LYING
var _cooldown := 0.0


# It lies still until Grandpa comes this close.
static func wakes(distance: float) -> bool:
	return distance <= WAKE_RANGE


static func bite_hits(at: Vector2, feet: Vector2) -> bool:
	return at.distance_to(feet) <= BITE_RADIUS


static func next_state(state: int) -> int:
	match state:
		State.LYING:
			return State.BITING
		State.BITING:
			return State.AWAKE
	return State.BITING


func state() -> int:
	return _state


func is_lying() -> bool:
	return _state == State.LYING


func tick(enemy: Enemy, delta: float) -> void:
	match _state:
		State.LYING:
			if wakes(enemy.global_position.distance_to(enemy.target_ground())):
				enemy.say(WAKE_TEXT, SAY_TIME)
				_begin_bite(enemy)
		State.BITING:
			if _telegraph.tick(delta):
				enemy.clear_warning()
				if bite_hits(enemy.global_position, enemy.target_ground()):
					enemy.hit_target(enemy.def.damage)
				_state = next_state(_state)
				_cooldown = COOLDOWN
		State.AWAKE:
			_cooldown -= delta
			if _cooldown <= 0.0 and wakes(enemy.global_position.distance_to(enemy.target_ground())):
				_begin_bite(enemy)
				return
			enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed * SHUFFLE_SCALE


func _begin_bite(enemy: Enemy) -> void:
	_telegraph.start(BITE_WINDUP)
	# It snaps open right beside him, so its warning shows for the whole windup, whatever his stats.
	enemy.set_warning(_telegraph, BITE_RADIUS, true)
	_state = State.BITING
