class_name ExtraBehavior
extends EnemyBehavior

# A film Extra, grey as an old black-and-white picture, who steps out of the screen at a critic's call.
# Fragile and quick: it hurries up to Grandpa and gives him a shove, warned as a short ring round it,
# that costs a pill and pushes him back a step. A heckler, it calls out as it first steps in.
const START_RANGE := 28.0
const STRIKE_RANGE := 36.0
const WINDUP := 0.4
const COOLDOWN := 0.8
const SHOVE := 200.0
const SHOVE_TIME := 0.16
const HECKLES: Array[String] = ["Boo!", "Rubbish!", "Hiss!"]
const SAY_TIME := 0.9

var _telegraph := Telegraph.new()
var _cooldown := 0.0
var _heckled := false


# The shove that sends him back, straight away from the Extra.
static func shove_for(from: Vector2, to: Vector2) -> Vector2:
	var away := to - from
	if away.is_zero_approx():
		away = Vector2.RIGHT
	return away.normalized() * SHOVE


func tick(enemy: Enemy, delta: float) -> void:
	if not _heckled:
		_heckled = true
		enemy.say(HECKLES[enemy.spawn_index % HECKLES.size()], SAY_TIME)
	var distance := enemy.global_position.distance_to(enemy.target_ground())
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_cooldown = COOLDOWN
			# Only a shove that lands pushes: a dodge passes through both.
			if distance <= STRIKE_RANGE and enemy.target.has_method("take_hit") and enemy.target.take_hit(enemy.def.damage):
				if enemy.target.has_method("push"):
					enemy.target.push(shove_for(enemy.global_position, enemy.target_ground()), SHOVE_TIME)
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	if distance <= START_RANGE:
		if _cooldown <= 0.0:
			_telegraph.start(WINDUP)
			enemy.set_warning(_telegraph, STRIKE_RANGE)
		return
	enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed
