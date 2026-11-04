class_name HrRepBehavior
extends EnemyBehavior

# An HR Representative. She keeps her distance and throws memos at warned spots near Grandpa. Each
# lands as any warned spot does and leaves a write-up lying there for a while, which stings him if he
# stands in it for a moment (see WriteUpMark).
const TOO_CLOSE := 130.0
const TOO_FAR := 210.0
const WINDUP := 0.4
const WARNING_RADIUS := 18.0
const THROW_EVERY := 3.8
const FIRST_THROW := 1.3
# How far from his feet a memo may land.
const SPREAD := 36.0
const SAY_TIME := 0.8
const LINES: Array[String] = ["Noted.", "Per my last memo...", "This goes in your file."]

enum { BACK_OFF = -1, HOLD = 0, CLOSE_IN = 1 }

var _telegraph := Telegraph.new()
var _cooldown := FIRST_THROW
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


# Somewhere near his feet, never more than SPREAD away.
static func memo_spot(target: Vector2, rng: RandomNumberGenerator) -> Vector2:
	return target + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, SPREAD)


func tick(enemy: Enemy, delta: float) -> void:
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_cooldown = THROW_EVERY - WINDUP
			throw_memo(enemy, memo_spot(enemy.target_ground(), _rng))
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
		if _rng.randf() < 0.5:
			enemy.say(LINES[_rng.randi_range(0, LINES.size() - 1)], SAY_TIME)


# A memo flies from her to a marked spot, and the write-up it leaves lies there a while.
static func throw_memo(enemy: Enemy, at: Vector2) -> WriteUpMark:
	if enemy.open_ground.is_valid() and not enemy.open_ground.call(at):
		return null
	var mark := WriteUpMark.new()
	mark.setup(enemy)
	mark.throw_from(enemy.global_position)
	enemy.get_parent().add_child(mark)
	mark.global_position = at
	return mark
