class_name StokerBehavior
extends EnemyBehavior

# Keeps a shovel's throw away and lobs coal at where Grandpa stands. The spot is marked while the
# coal flies, and it lands burning, leaving fire on the ground for a while.
const TOO_CLOSE := 90.0
const TOO_FAR := 170.0
const WINDUP := 0.4
const WARNING_RADIUS := 18.0
const COOLDOWN := 2.4
const FIRST_THROW := 1.0
const COAL_RADIUS := 22.0
const COAL_WARNING := 0.8
const BURN_TIME := 1.8

enum { BACK_OFF = -1, HOLD = 0, CLOSE_IN = 1 }

var _telegraph := Telegraph.new()
var _cooldown := FIRST_THROW


# Which way it walks for a distance to Grandpa: back off when he is close, close in when far.
static func step(distance: float) -> int:
	if distance < TOO_CLOSE:
		return BACK_OFF
	if distance > TOO_FAR:
		return CLOSE_IN
	return HOLD


func tick(enemy: Enemy, delta: float) -> void:
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_cooldown = COOLDOWN
			throw_coal(enemy, enemy.target_ground(), COAL_WARNING, BURN_TIME)
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


# A lump of coal flies from the thrower to a marked spot, which then burns for burn_time.
static func throw_coal(enemy: Enemy, at: Vector2, warning: float, burn_time: float, radius := COAL_RADIUS) -> void:
	var strike := enemy.strike_ground(at, radius, warning, 0.0, 0.0, -1, burn_time)
	if strike != null:
		strike.throw_from(enemy.global_position)
