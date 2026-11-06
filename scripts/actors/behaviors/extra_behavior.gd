class_name ExtraBehavior
extends EnemyBehavior

# A film Extra, grey as an old black-and-white picture, who steps out of the screen at a critic's call.
# Fragile and quick: it hurries up to Grandpa and gives him a shove, warned as a short ring round it,
# that costs a pill and pushes him back a step. A heckler, it calls out as it first steps in.
const START_RANGE := 28.0
const STRIKE_RANGE := 36.0
# A crowd of them as quick as Grandpa cornered him at a 0.4 s windup and a 0.8 s rest (Task 6's
# tuning), so each shove warns a little longer and comes less often.
const WINDUP := 0.5
const COOLDOWN := 1.4
const SHOVE := 200.0
const SHOVE_TIME := 0.16
const HECKLES: Array[String] = ["Boo!", "Rubbish!", "Hiss!"]
const SAY_TIME := 0.9
# Two hecklers nearer than this never call out together.
const HECKLE_APART := 120.0

var _telegraph := Telegraph.new()
var _cooldown := 0.0
var _heckled := false


# The shove that sends him back, straight away from the Extra.
static func shove_for(from: Vector2, to: Vector2) -> Vector2:
	var away := to - from
	if away.is_zero_approx():
		away = Vector2.RIGHT
	return away.normalized() * SHOVE


# Whether another Extra close by is calling out already.
func _neighbour_heckling(enemy: Enemy) -> bool:
	if not enemy.is_inside_tree():
		return false
	for other: Enemy in enemy.get_tree().get_nodes_in_group("enemies"):
		if other != enemy and other.def == enemy.def and other._say_left > 0.0 and other.global_position.distance_to(enemy.global_position) < HECKLE_APART:
			return true
	return false


func tick(enemy: Enemy, delta: float) -> void:
	if not _heckled:
		_heckled = true
		if not _neighbour_heckling(enemy):
			enemy.say(HECKLES[enemy.get_instance_id() % HECKLES.size()], SAY_TIME)
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
