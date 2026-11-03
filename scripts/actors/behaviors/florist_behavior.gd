class_name FloristBehavior
extends EnemyBehavior

# Keeps her distance and lobs thorny wreaths at warned spots near Grandpa. Each lands on its spot
# and leaves a ring of thorns there for a while, which hurts whoever stands in it now and then.
const TOO_CLOSE := 130.0
const TOO_FAR := 210.0
const WINDUP := 0.4
const WARNING_RADIUS := 18.0
const THROW_EVERY := 4.0
const FIRST_THROW := 1.2
const WREATH_RADIUS := 26.0
const WREATH_WARNING := 0.9
const THORN_TIME := 2.0
# How far from his feet a wreath may land.
const SPREAD := 40.0

enum { BACK_OFF = -1, HOLD = 0, CLOSE_IN = 1 }

var _telegraph := Telegraph.new()
var _cooldown := FIRST_THROW
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


# Which way she walks for a distance to Grandpa: back off when he is close, close in when far.
static func step(distance: float) -> int:
	if distance < TOO_CLOSE:
		return BACK_OFF
	if distance > TOO_FAR:
		return CLOSE_IN
	return HOLD


# Somewhere near his feet, never more than SPREAD away.
static func wreath_spot(target: Vector2, rng: RandomNumberGenerator) -> Vector2:
	return target + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, SPREAD)


func tick(enemy: Enemy, delta: float) -> void:
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_cooldown = THROW_EVERY - WINDUP
			throw_wreath(enemy, wreath_spot(enemy.target_ground(), _rng))
		return
	_cooldown -= delta
	match step(enemy.distance_to_target()):
		BACK_OFF:
			enemy.desired_velocity = -enemy.direction_to_target() * enemy.def.speed
		CLOSE_IN:
			enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed
	if _cooldown <= 0.0 and enemy.target_in_view():
		_telegraph.start(WINDUP)
		enemy.set_warning(_telegraph, WARNING_RADIUS)


# A wreath flies from her to a marked spot, which then bristles with thorns for THORN_TIME.
static func throw_wreath(enemy: Enemy, at: Vector2) -> void:
	var strike := enemy.strike_ground(at, WREATH_RADIUS, WREATH_WARNING, 0.0, 0.0, -1, THORN_TIME)
	if strike != null:
		strike.throw_from(enemy.global_position)
		strike.set_look(GroundStrike.LOOK_THORNS)
