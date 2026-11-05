class_name ShuffleboardSharkBehavior
extends EnemyBehavior

# A shuffleboard hustler who keeps his distance and slides pucks at Grandpa along warned lanes. Each
# puck bounces once off the first wall or prop in its way, and its lane after the bounce is warned as
# well, so the turn reads before it comes. See ShuffleboardPuck.
const TOO_CLOSE := 120.0
const TOO_FAR := 220.0
const WINDUP := 0.9
const WARNING_RADIUS := 18.0
const SHOT_EVERY := 3.4
const FIRST_SHOT := 1.4
const LANE_WIDTH := 20.0
const PUCK_LENGTH := 420.0
const PUCK_SPEED := 250.0
const SAY_TEXT := "Ten off!"
const SAY_TIME := 0.8

enum { BACK_OFF = -1, HOLD = 0, CLOSE_IN = 1 }

var _telegraph := Telegraph.new()
var _cooldown := FIRST_SHOT


# Which way he walks for a distance to Grandpa: back off when he is close, close in when far.
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
			_cooldown = SHOT_EVERY - WINDUP
		return
	_cooldown -= delta
	match step(enemy.distance_to_target()):
		BACK_OFF:
			enemy.desired_velocity = -enemy.direction_to_target() * enemy.def.speed
		CLOSE_IN:
			enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed
	if _cooldown <= 0.0 and enemy.target_in_view():
		_aim_and_wind_up(enemy)


# The puck marks its whole way at once, the bounce too, and slides when the windup ends.
func _aim_and_wind_up(enemy: Enemy) -> void:
	var aim := enemy.global_position.direction_to(enemy.target_ground())
	if aim.is_zero_approx():
		aim = Vector2.DOWN
	enemy.facing = aim
	_telegraph.start(WINDUP)
	enemy.set_warning(_telegraph, WARNING_RADIUS)
	enemy.say(SAY_TEXT, SAY_TIME)
	send_puck(enemy, aim, WINDUP)


static func send_puck(enemy: Enemy, aim: Vector2, warning: float) -> ShuffleboardPuck:
	var cast := Callable()
	if enemy.is_inside_tree():
		var space := enemy.get_world_2d().direct_space_state
		cast = func(from: Vector2, to: Vector2) -> Dictionary:
			return space.intersect_ray(PhysicsRayQueryParameters2D.create(from, to, 1))
	var path := ShuffleboardPuck.bounce_path(enemy.global_position, aim, PUCK_LENGTH, cast)
	var puck := ShuffleboardPuck.new()
	puck.setup(enemy, path, warning, PUCK_SPEED, LANE_WIDTH)
	enemy.get_parent().add_child(puck)
	puck.global_position = path[0]
	return puck
