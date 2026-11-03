extends EnemyBehavior

const TOO_CLOSE := 120.0
const TOO_FAR := 210.0
const WINDUP := 0.6
const COOLDOWN := 1.7
const SHOTS := 3
const SHOT_GAP := 0.15
const PROJECTILE_SPEED := 175.0
const LANE_LENGTH := 200.0
const LANE_WIDTH := 10.0
const WARNING_RADIUS := 18.0

var _telegraph := Telegraph.new()
var _cooldown := 1.2
var _shots_left := 0
var _shot_wait := 0.0
var _aim := Vector2.RIGHT


func tick(enemy: Enemy, delta: float) -> void:
	if _shots_left > 0:
		_shot_wait -= delta
		if _shot_wait <= 0.0:
			enemy.shoot(_aim, PROJECTILE_SPEED)
			_shots_left -= 1
			_shot_wait = SHOT_GAP
		return
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_cooldown = COOLDOWN
			_shots_left = SHOTS
			_shot_wait = 0.0
		return
	_cooldown -= delta
	var distance := enemy.distance_to_target()
	if distance < TOO_CLOSE:
		enemy.desired_velocity = -enemy.direction_to_target() * enemy.def.speed
	elif distance > TOO_FAR:
		enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed
	if _cooldown <= 0.0 and enemy.target_in_view():
		_aim = enemy.direction_to_target()
		_telegraph.start(WINDUP)
		enemy.set_warning(_telegraph, WARNING_RADIUS)
		enemy.set_warning_lane(_aim, LANE_LENGTH, LANE_WIDTH, false)
