class_name ClubGolferBehavior
extends EnemyBehavior

# A club member who keeps a driving distance from Grandpa. Every few seconds he lines up a drive,
# shouts "FORE!" and shows three lanes in a narrow fan, then drives a ball down each one. The balls stop
# at walls and props, as any shot does.
const TOO_CLOSE := 120.0
const TOO_FAR := 210.0
const WINDUP := 0.8
const WARNING_RADIUS := 18.0
const DRIVE_EVERY := 3.4
const FIRST_DRIVE := 1.6
const BALLS := 3
# The whole fan, edge to edge: thirty degrees.
const SPREAD := PI / 6.0
const BALL_SPEED := 240.0
const LANE := 280.0
const LANE_WIDTH := 14.0
const SHOUT := "FORE!"
const SAY_TIME := 0.9

enum { BACK_OFF = -1, HOLD = 0, CLOSE_IN = 1 }

var _telegraph := Telegraph.new()
var _cooldown := FIRST_DRIVE
var _aim := Vector2.RIGHT


# Which way he walks for a distance to Grandpa: back off when he is close, close in when far.
static func step(distance: float) -> int:
	if distance < TOO_CLOSE:
		return BACK_OFF
	if distance > TOO_FAR:
		return CLOSE_IN
	return HOLD


# The lanes of one drive, the middle one aimed at Grandpa.
static func drive_lanes(aim: Vector2) -> Array[Vector2]:
	return BossMoves.fan_directions(aim, BALLS, SPREAD)


func tick(enemy: Enemy, delta: float) -> void:
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_cooldown = DRIVE_EVERY - WINDUP
			for way in drive_lanes(_aim):
				GolfBallShot.fire(enemy, way, BALL_SPEED)
		return
	_cooldown -= delta
	match step(enemy.distance_to_target()):
		BACK_OFF:
			enemy.desired_velocity = -enemy.direction_to_target() * enemy.def.speed
		CLOSE_IN:
			enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed
	if _cooldown <= 0.0 and enemy.target_in_view():
		_aim = enemy.direction_to_target()
		_telegraph.start(WINDUP)
		enemy.set_warning(_telegraph, WARNING_RADIUS)
		for way in drive_lanes(_aim):
			enemy.add_warning_lane(way, LANE, LANE_WIDTH, false)
		enemy.say(SHOUT, SAY_TIME)
