extends EnemyBehavior

const TOO_CLOSE := 90.0
const TOO_FAR := 170.0
const WINDUP := 0.5
const COOLDOWN := 2.0
const PROJECTILE_SPEED := 110.0

var _telegraph := Telegraph.new()
var _cooldown := 1.0


func tick(enemy: Enemy, delta: float) -> void:
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			enemy.shoot(enemy.direction_to_target(), PROJECTILE_SPEED)
			_cooldown = COOLDOWN
		return
	_cooldown -= delta
	var distance := enemy.distance_to_target()
	if distance < TOO_CLOSE:
		enemy.desired_velocity = -enemy.direction_to_target() * enemy.def.speed
	elif distance > TOO_FAR:
		enemy.desired_velocity = enemy.direction_to_target() * enemy.def.speed
	if _cooldown <= 0.0:
		_telegraph.start(WINDUP)
		enemy.set_warning(_telegraph, 18.0)
