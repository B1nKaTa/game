class_name OrderlyBehavior
extends EnemyBehavior

# Keeps a little way off and fires one sedative dart at a time down a warned lane. A dart that
# lands costs a pill and slows Grandpa for a while.
const TOO_CLOSE := 110.0
const TOO_FAR := 200.0
const WINDUP := 0.6
const COOLDOWN := 1.9
const DART_SPEED := 190.0
const LANE_LENGTH := 200.0
const LANE_WIDTH := 10.0
const WARNING_RADIUS := 18.0
const SLOW := 0.5
const SLOW_TIME := 1.5

var _telegraph := Telegraph.new()
var _cooldown := 1.2
var _aim := Vector2.RIGHT


static func fire_dart(enemy: Enemy, direction: Vector2, speed: float) -> Projectile:
	var dart := enemy.shoot(direction, speed)
	dart.make_dart(SLOW, SLOW_TIME)
	return dart


func tick(enemy: Enemy, delta: float) -> void:
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_cooldown = COOLDOWN
			fire_dart(enemy, _aim, DART_SPEED)
		return
	_cooldown -= delta
	var distance := enemy.distance_to_target()
	if distance < TOO_CLOSE:
		enemy.desired_velocity = -enemy.direction_to_target() * enemy.def.speed
	elif distance > TOO_FAR:
		enemy.desired_velocity = enemy.direction_to_target() * enemy.def.speed
	if _cooldown <= 0.0 and enemy.target_in_view():
		_aim = enemy.direction_to_target()
		_telegraph.start(WINDUP)
		enemy.set_warning(_telegraph, WARNING_RADIUS)
		enemy.set_warning_lane(_aim, LANE_LENGTH, LANE_WIDTH, false)
