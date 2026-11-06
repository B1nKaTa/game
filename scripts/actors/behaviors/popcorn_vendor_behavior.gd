class_name PopcornVendorBehavior
extends EnemyBehavior

# The Popcorn Vendor keeps her distance, as the Perfume Sprayer did, and lobs a tub of popcorn onto a
# warned spot near Grandpa (PopcornTub). It lands on the spot, costing a pill to whoever stands under
# it, and bursts into a ring of six kernels.
const TOO_CLOSE := 110.0
const TOO_FAR := 210.0
const WINDUP := 0.5
const WARNING_RADIUS := 16.0
const LOB_EVERY := 3.4
const FIRST_LOB := 1.4
# How far from his feet a tub may land.
const SPREAD := 24.0
const CALL_TEXT := "Popcorn!"
const SAY_TIME := 0.8

enum { BACK_OFF = -1, HOLD = 0, CLOSE_IN = 1 }

var _telegraph := Telegraph.new()
var _cooldown := FIRST_LOB
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


static func tub_spot(target: Vector2, rng: RandomNumberGenerator) -> Vector2:
	return target + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, SPREAD)


func tick(enemy: Enemy, delta: float) -> void:
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_cooldown = LOB_EVERY - WINDUP
			PopcornTub.lob(enemy, tub_spot(enemy.target_ground(), _rng), _rng.randf() * TAU)
		return
	_cooldown -= delta
	match step(enemy.distance_to_target()):
		BACK_OFF:
			enemy.desired_velocity = enemy.walk_direction_to(enemy.global_position - enemy.direction_to_target() * 40.0) * enemy.def.speed
		CLOSE_IN:
			enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed
	if _cooldown <= 0.0 and enemy.target_in_view():
		_telegraph.start(WINDUP)
		enemy.set_warning(_telegraph, WARNING_RADIUS)
		enemy.say(CALL_TEXT, SAY_TIME)
