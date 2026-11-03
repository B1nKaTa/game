extends EnemyBehavior

const START_RANGE := 180.0
const WINDUP := 0.65
const CHARGE_TIME := 0.7
const CHARGE_SPEED := 280.0
const HIT_RANGE := 16.0
const COOLDOWN := 1.1

var _telegraph := Telegraph.new()
var _cooldown := 1.0
var _charge_left := 0.0
var _direction := Vector2.RIGHT
var _has_hit := false
# What it is really doing, which on a wet floor only eases toward what it wants, so a charge overshoots.
var _moving := Vector2.ZERO


func tick(enemy: Enemy, delta: float) -> void:
	_moving = SlideRule.velocity(_moving, _wanted(enemy, delta), enemy.is_on_wet(), delta)
	enemy.desired_velocity = _moving


func _wanted(enemy: Enemy, delta: float) -> Vector2:
	if _charge_left > 0.0:
		_charge_left -= delta
		if not _has_hit and enemy.distance_to_target() <= HIT_RANGE:
			_has_hit = true
			enemy.hit_target(enemy.def.damage)
		return _direction * CHARGE_SPEED
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_charge_left = CHARGE_TIME
			_cooldown = COOLDOWN
			_has_hit = false
		return Vector2.ZERO
	_cooldown -= delta
	if _cooldown <= 0.0 and enemy.distance_to_target() <= START_RANGE:
		_direction = enemy.direction_to_target()
		_telegraph.start(WINDUP)
		enemy.set_warning(_telegraph, 20.0)
		enemy.set_warning_lane(_direction, CHARGE_TIME * CHARGE_SPEED, HIT_RANGE * 2.0, false)
		return Vector2.ZERO
	return enemy.direction_to_target() * enemy.def.speed
