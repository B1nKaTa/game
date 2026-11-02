extends EnemyBehavior

const TURN_SPEED := 1.4
const START_RANGE := 36.0
const STRIKE_RANGE := 42.0
const WINDUP := 0.9
const COOLDOWN := 1.3

var _telegraph := Telegraph.new()
var _cooldown := 0.8
var _facing_set := false


static func turned(facing: Vector2, wanted: Vector2, max_turn: float) -> Vector2:
	var angle := facing.angle_to(wanted)
	return facing.rotated(clampf(angle, -max_turn, max_turn))


func tick(enemy: Enemy, delta: float) -> void:
	if not _facing_set:
		_facing_set = true
		enemy.facing = enemy.direction_to_target()
	# Its back stays open while it winds up, since it stops turning.
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_cooldown = COOLDOWN
			if enemy.distance_to_target() <= STRIKE_RANGE:
				enemy.hit_target(enemy.def.damage)
		return
	var wanted := enemy.direction_to_target()
	enemy.facing = turned(enemy.facing, wanted, TURN_SPEED * delta)
	_cooldown = maxf(_cooldown - delta, 0.0)
	if enemy.distance_to_target() <= START_RANGE:
		if _cooldown <= 0.0:
			_telegraph.start(WINDUP)
			enemy.set_warning(_telegraph, STRIKE_RANGE)
		return
	enemy.desired_velocity = enemy.facing * enemy.def.speed
