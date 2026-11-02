extends EnemyBehavior

const START_RANGE := 180.0
const WINDUP := 0.7
const CHARGE_TIME := 0.7
const CHARGE_SPEED := 240.0
const HIT_RANGE := 16.0
const COOLDOWN := 1.5

var _telegraph := Telegraph.new()
var _cooldown := 1.0
var _charge_left := 0.0
var _direction := Vector2.RIGHT
var _has_hit := false


func tick(enemy: Enemy, delta: float) -> void:
	if _charge_left > 0.0:
		_charge_left -= delta
		enemy.desired_velocity = _direction * CHARGE_SPEED
		if not _has_hit and enemy.distance_to_target() <= HIT_RANGE:
			_has_hit = true
			enemy.hit_target(enemy.def.damage)
		return
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_charge_left = CHARGE_TIME
			_cooldown = COOLDOWN
			_has_hit = false
		return
	_cooldown -= delta
	enemy.desired_velocity = enemy.direction_to_target() * enemy.def.speed
	if _cooldown <= 0.0 and enemy.distance_to_target() <= START_RANGE:
		_direction = enemy.direction_to_target()
		_telegraph.start(WINDUP)
		enemy.set_warning(_telegraph, 20.0)
