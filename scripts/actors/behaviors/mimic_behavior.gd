class_name MimicBehavior
extends EnemyBehavior

# A chest that was never a chest. Woken, it hops after Grandpa and lunges with its lid wide open
# along a short warned lane, snapping shut on whatever is at the end of it.
const START_RANGE := 90.0
const WINDUP := 0.6
const LUNGE_TIME := 0.3
const LUNGE_SPEED := 260.0
const HIT_RANGE := 18.0
const LANE_WIDTH := 28.0
const WARNING_RADIUS := 18.0
const COOLDOWN := 1.0
const FIRST_LUNGE := 0.4

var _telegraph := Telegraph.new()
var _cooldown := FIRST_LUNGE
var _lunge_left := 0.0
var _direction := Vector2.RIGHT
var _has_hit := false


# It lunges only once its rest is over and Grandpa is near enough for the lane to reach him.
static func should_lunge(distance: float, cooldown: float) -> bool:
	return cooldown <= 0.0 and distance <= START_RANGE


static func lane_length() -> float:
	return LUNGE_TIME * LUNGE_SPEED


func tick(enemy: Enemy, delta: float) -> void:
	if _lunge_left > 0.0:
		_lunge_left -= delta
		enemy.desired_velocity = _direction * LUNGE_SPEED
		if not _has_hit and enemy.distance_to_target() <= HIT_RANGE:
			_has_hit = true
			enemy.hit_target(enemy.def.damage)
		return
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_lunge_left = LUNGE_TIME
			_cooldown = COOLDOWN
			_has_hit = false
		return
	_cooldown -= delta
	if should_lunge(enemy.distance_to_target(), _cooldown):
		_direction = enemy.direction_to_target()
		enemy.facing = _direction
		_telegraph.start(WINDUP)
		enemy.set_warning(_telegraph, WARNING_RADIUS)
		enemy.set_warning_lane(_direction, lane_length(), LANE_WIDTH, false)
		return
	enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed
