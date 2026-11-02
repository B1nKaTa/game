extends EnemyBehavior

const START_RANGE := 30.0
const STRIKE_RANGE := 40.0
const WINDUP := 0.6
const COOLDOWN := 1.0

var _telegraph := Telegraph.new()
var _cooldown := 0.0


func tick(enemy: Enemy, delta: float) -> void:
	var distance := enemy.distance_to_target()
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_cooldown = COOLDOWN
			if distance <= STRIKE_RANGE:
				enemy.hit_target(enemy.def.damage)
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	if distance <= START_RANGE:
		if _cooldown <= 0.0:
			_telegraph.start(WINDUP)
			enemy.set_warning(_telegraph, STRIKE_RANGE)
		return
	enemy.desired_velocity = enemy.direction_to_target() * enemy.def.speed
