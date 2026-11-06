class_name CrystalGazerBehavior
extends EnemyBehavior

# A Crystal Gazer keeps her distance, as the Club Golfer did. She winds up over her ball, then lets it go
# (CrystalBall): it homes on Grandpa's feet for 3 s, turning slowly, and bursts in a small warned ring,
# or sooner where it meets cover. She sends one ball at a time, the next only once the last is gone.
const TOO_CLOSE := 110.0
const TOO_FAR := 220.0
const WINDUP := 0.6
const WARNING_RADIUS := 16.0
const RELEASE_EVERY := 2.4
const FIRST_RELEASE := 1.6

enum { BACK_OFF = -1, HOLD = 0, CLOSE_IN = 1 }

var _telegraph := Telegraph.new()
var _cooldown := FIRST_RELEASE
var _ball: CrystalBall


# Which way she walks for a distance to Grandpa: back off when he is close, close in when far.
static func step(distance: float) -> int:
	if distance < TOO_CLOSE:
		return BACK_OFF
	if distance > TOO_FAR:
		return CLOSE_IN
	return HOLD


func ball_out() -> bool:
	return is_instance_valid(_ball) and not _ball.is_queued_for_deletion()


func tick(enemy: Enemy, delta: float) -> void:
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_cooldown = RELEASE_EVERY
			if enemy.is_inside_tree():
				_ball = CrystalBall.release(enemy)
		return
	if not ball_out():
		_cooldown -= delta
	match step(enemy.distance_to_target()):
		BACK_OFF:
			enemy.desired_velocity = enemy.walk_direction_to(enemy.global_position - enemy.direction_to_target() * 40.0) * enemy.def.speed
		CLOSE_IN:
			enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed
	if _cooldown <= 0.0 and not ball_out() and enemy.target_in_view():
		_telegraph.start(WINDUP)
		enemy.set_warning(_telegraph, WARNING_RADIUS)
