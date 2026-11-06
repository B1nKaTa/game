class_name PoltergeistBehavior
extends EnemyBehavior

# A Poltergeist on Hold, a faint ghost who drifts at a distance and hurls the office at Grandpa: a
# stapler, then a mug, then a fax machine, and round again. Each throw is warned as a lane, and the
# object flies down it as a shot, stopping at walls and cover.
# A ghost, it passes through him harmlessly (ContactRule.is_ghost), and it is drawn faint.
const TOO_CLOSE := 100.0
const TOO_FAR := 200.0
const WINDUP := 0.6
const WARNING_RADIUS := 14.0
const THROW_EVERY := 2.8
const FIRST_THROW := 1.4
const THROW_SPEED := 190.0
const LANE := 260.0
const LANE_WIDTH := 20.0
# How see-through it is drawn: faint, but still read.
const ALPHA := 0.6
const OBJECTS: Array[String] = [Projectile.LOOK_STAPLER, Projectile.LOOK_MUG, Projectile.LOOK_FAX]
const CALL_TEXT := "Please hold..."
const SAY_TIME := 0.9
# It says so once every this many throws.
const CALL_EVERY := 3

enum { BACK_OFF = -1, HOLD = 0, CLOSE_IN = 1 }

var _telegraph := Telegraph.new()
var _cooldown := FIRST_THROW
var _aim := Vector2.RIGHT
var _thrown := 0


static func step(distance: float) -> int:
	if distance < TOO_CLOSE:
		return BACK_OFF
	if distance > TOO_FAR:
		return CLOSE_IN
	return HOLD


# What its throw number index hurls: the stapler, the mug and the fax machine in turn.
static func object_for(index: int) -> String:
	return OBJECTS[posmod(index, OBJECTS.size())]


func next_object() -> String:
	return object_for(_thrown)


func on_ready(enemy: Enemy) -> void:
	if enemy.visual() != null:
		enemy.visual().set_alpha(ALPHA)


func tick(enemy: Enemy, delta: float) -> void:
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_cooldown = THROW_EVERY
			var shot := enemy.shoot(_aim, THROW_SPEED)
			shot.look = next_object()
			_thrown += 1
		return
	_cooldown -= delta
	match step(enemy.distance_to_target()):
		BACK_OFF:
			enemy.desired_velocity = enemy.walk_direction_to(enemy.global_position - enemy.direction_to_target() * 40.0) * enemy.def.speed
		CLOSE_IN:
			enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed
	if _cooldown <= 0.0 and enemy.target_in_view():
		_aim = enemy.direction_to_target()
		_telegraph.start(WINDUP)
		enemy.set_warning(_telegraph, WARNING_RADIUS)
		enemy.set_warning_lane(_aim, LANE, LANE_WIDTH, false)
		if _thrown % CALL_EVERY == 0:
			enemy.say(CALL_TEXT, SAY_TIME)
