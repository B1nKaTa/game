extends EnemyBehavior

const FLANK_DISTANCE := 34.0
const FLANK_FROM := 210.0
const START_RANGE := 24.0
const STRIKE_RANGE := 30.0
const WINDUP := 0.45
const COOLDOWN := 1.0
const WARNING_RADIUS := 30.0
# Spreads members of a pack around Grandpa without them having to know each other.
const SIDES := 5

var _telegraph := Telegraph.new()
var _cooldown := 0.3
var _flank := 0.0
var _flank_set := false


static func flank_angle(index: int, sides: int) -> float:
	return TAU * posmod(index, sides) / float(sides)


func tick(enemy: Enemy, delta: float) -> void:
	if not _flank_set:
		_flank_set = true
		_flank = flank_angle(enemy.spawn_index, SIDES)
	var distance := enemy.distance_to_target()
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_cooldown = COOLDOWN
			if enemy.distance_to_target() <= STRIKE_RANGE:
				enemy.hit_target(enemy.def.damage)
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	if distance <= START_RANGE:
		if _cooldown <= 0.0:
			_telegraph.start(WINDUP)
			enemy.set_warning(_telegraph, WARNING_RADIUS)
		return
	var spot: Vector2 = enemy.target.global_position
	if distance > FLANK_DISTANCE and distance < FLANK_FROM:
		spot += Vector2.from_angle(_flank) * FLANK_DISTANCE
	enemy.desired_velocity = enemy.global_position.direction_to(spot) * enemy.def.speed
