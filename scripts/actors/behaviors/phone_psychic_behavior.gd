class_name PhonePsychicBehavior
extends EnemyBehavior

# A Phone Psychic keeps a middle distance from Grandpa. Every few seconds it holds still, says "I sense
# you..." and marks the spot his feet stand on with a red ring, with the band its phone cord will sweep
# warned beside it (PhoneCordLash); 0.7 s later the cord lashes in an arc through that spot. A step out
# of the band, in or out from the psychic, is enough.
const TOO_CLOSE := 80.0
const TOO_FAR := 150.0
# It senses for the lash's whole warning, standing still.
const WINDUP := PhoneCordLash.WARNING
const WARNING_RADIUS := 12.0
const LASH_EVERY := 3.2
const FIRST_LASH := 1.2
const CALL_TEXT := "I sense you..."
const SAY_TIME := 1.0

enum { BACK_OFF = -1, HOLD = 0, CLOSE_IN = 1 }

var _telegraph := Telegraph.new()
var _cooldown := FIRST_LASH
var _lash: PhoneCordLash


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
			_cooldown = LASH_EVERY
		return
	_cooldown -= delta
	match step(enemy.distance_to_target()):
		BACK_OFF:
			enemy.desired_velocity = enemy.walk_direction_to(enemy.global_position - enemy.direction_to_target() * 40.0) * enemy.def.speed
		CLOSE_IN:
			enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed
	var spot := enemy.target_ground()
	if _cooldown <= 0.0 and PhoneCordLash.reaches(enemy.global_position.distance_to(spot)) and enemy.target_in_view():
		enemy.desired_velocity = Vector2.ZERO
		_telegraph.start(WINDUP)
		enemy.set_warning(_telegraph, WARNING_RADIUS)
		enemy.say(CALL_TEXT, SAY_TIME)
		if enemy.is_inside_tree():
			_lash = PhoneCordLash.sense(enemy, spot)
