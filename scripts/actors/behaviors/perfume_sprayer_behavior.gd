class_name PerfumeSprayerBehavior
extends EnemyBehavior

# Keeps her distance and sprays perfume onto warned spots near Grandpa. Each lands as a cloud that
# hangs there for a while, and inside one his view closes in. See PerfumeCloud and PerfumeHaze.
const TOO_CLOSE := 120.0
const TOO_FAR := 200.0
const WINDUP := 0.4
const WARNING_RADIUS := 18.0
const SPRAY_EVERY := 3.6
const FIRST_SPRAY := 1.5
# How far from his feet a cloud may land.
const SPREAD := 30.0

enum { BACK_OFF = -1, HOLD = 0, CLOSE_IN = 1 }

var _telegraph := Telegraph.new()
var _cooldown := FIRST_SPRAY
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


static func cloud_spot(target: Vector2, rng: RandomNumberGenerator) -> Vector2:
	return target + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, SPREAD)


func tick(enemy: Enemy, delta: float) -> void:
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_cooldown = SPRAY_EVERY - WINDUP
			spray(enemy, cloud_spot(enemy.target_ground(), _rng))
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


static func spray(enemy: Enemy, at: Vector2) -> PerfumeCloud:
	if enemy.open_ground.is_valid() and not enemy.open_ground.call(at):
		return null
	var cloud := PerfumeCloud.new()
	cloud.setup(enemy, PerfumeCloud.WARNING, PerfumeCloud.LINGER, PerfumeCloud.RADIUS)
	enemy.get_parent().add_child(cloud)
	cloud.global_position = at
	return cloud
