class_name CartNurseBehavior
extends EnemyBehavior

# Pushes her medicine cart down a warned lane, smashing props on the way. Running into a wall
# stuns her for a moment, when she takes double damage. On a wet floor the cart runs on past.
const START_RANGE := 190.0
const WINDUP := 0.65
const CHARGE_TIME := 0.75
const CHARGE_SPEED := 270.0
const HIT_RANGE := 16.0
const LANE_WIDTH := 32.0
const WARNING_RADIUS := 20.0
const SMASH_AHEAD := 18.0
const SMASH_RADIUS := 18.0
const COOLDOWN := 1.2
const STUN_TIME := 1.2
const STUNNED_DAMAGE := 2.0
const STUN_GRACE := 0.05
const HEAD_ON := 0.5

var _telegraph := Telegraph.new()
var _cooldown := 1.0
var _charge_left := 0.0
var _stun_left := 0.0
var _direction := Vector2.RIGHT
var _has_hit := false
var _charged_for := 0.0
var _moving := Vector2.ZERO


static func damage_taken(amount: float, stunned: bool) -> float:
	return amount * (STUNNED_DAMAGE if stunned else 1.0)


func is_stunned() -> bool:
	return _stun_left > 0.0


func damage_scale(_enemy: Enemy) -> float:
	return damage_taken(1.0, is_stunned())


func tick(enemy: Enemy, delta: float) -> void:
	_moving = SlideRule.velocity(_moving, _wanted(enemy, delta), enemy.is_on_wet(), delta)
	enemy.desired_velocity = _moving


func _wanted(enemy: Enemy, delta: float) -> Vector2:
	if _stun_left > 0.0:
		_stun_left -= delta
		return Vector2.ZERO
	if _charge_left > 0.0:
		return _charging(enemy, delta)
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_charge_left = CHARGE_TIME
			_charged_for = 0.0
			_cooldown = COOLDOWN
			_has_hit = false
		return Vector2.ZERO
	_cooldown -= delta
	if _cooldown <= 0.0 and enemy.distance_to_target() <= START_RANGE and enemy.target_in_view():
		_direction = enemy.direction_to_target()
		_telegraph.start(WINDUP)
		enemy.set_warning(_telegraph, WARNING_RADIUS)
		enemy.set_warning_lane(_direction, CHARGE_TIME * CHARGE_SPEED, LANE_WIDTH)
		return Vector2.ZERO
	return enemy.direction_to_target() * enemy.def.speed


func _charging(enemy: Enemy, delta: float) -> Vector2:
	# Only running into a wall head on counts, and not what she was already leaning on at the start.
	if _charged_for > STUN_GRACE:
		for i in enemy.get_slide_collision_count():
			var collision := enemy.get_slide_collision(i)
			if BossDash.stops_at(collision.get_collider()) and collision.get_normal().dot(_direction) < -HEAD_ON:
				_hit_wall(enemy)
				return Vector2.ZERO
	_charge_left -= delta
	_charged_for += delta
	enemy.smash(enemy.global_position + _direction * SMASH_AHEAD, SMASH_RADIUS)
	if not _has_hit and enemy.distance_to_target() <= HIT_RANGE:
		_has_hit = true
		enemy.hit_target(enemy.def.damage)
	return _direction * CHARGE_SPEED


func _hit_wall(enemy: Enemy) -> void:
	_charge_left = 0.0
	_stun_left = STUN_TIME
	_moving = Vector2.ZERO
	enemy.daze(STUN_TIME)
