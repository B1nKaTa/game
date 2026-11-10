class_name AuditorBehavior
extends EnemyBehavior

# The Auditor walks Harold down. Close in, a clipboard swing; further off, a thrown FINED stamp that
# leaves a slowing ink blot where it lands (InkBlot). Only a broken room rule sends him.

const SWING_RANGE := 34.0
const SWING_WINDUP := 0.5
const SWING_COOLDOWN := 1.1
const THROW_RANGE := 160.0
const THROW_WINDUP := 0.6
const THROW_COOLDOWN := 2.4
const STAMP_SPEED := 120.0
const ARRIVAL_LINE := "Rules are rules."
const ARRIVAL_TIME := 1.4

# Deeper floors' regulars press harder, so does he: shorter rests between attacks, never shorter windups,
# so his warnings read the same. Floor 1 is exactly as before.
const DEPTH_STEP := 0.06
const MIN_TEMPO := 0.76

var tempo := 1.0
var _swing := Telegraph.new()
var _throw := Telegraph.new()
var _swing_cooldown := 0.8
var _throw_cooldown := 1.5


static func cooldown_mult(depth: int) -> float:
	return clampf(1.0 - DEPTH_STEP * float(depth - 1), MIN_TEMPO, 1.0)


func on_ready(enemy: Enemy) -> void:
	enemy.say(enemy.tr(ARRIVAL_LINE), ARRIVAL_TIME)


func tick(enemy: Enemy, delta: float) -> void:
	if _swing.is_active():
		if _swing.tick(delta):
			enemy.clear_warning()
			if enemy.distance_to_target() <= SWING_RANGE + 8.0:
				enemy.hit_target(enemy.def.damage)
			_swing_cooldown = SWING_COOLDOWN * tempo
		return
	if _throw.is_active():
		if _throw.tick(delta):
			enemy.clear_warning()
			var shot := enemy.shoot(enemy.direction_to_target(), STAMP_SPEED)
			if shot != null:
				shot.look = Projectile.LOOK_FINED
				shot.landed_at.connect(InkBlot.spawn_at.bind(enemy.get_parent(), enemy.target))
			_throw_cooldown = THROW_COOLDOWN * tempo
		return
	_swing_cooldown -= delta
	_throw_cooldown -= delta
	var distance := enemy.distance_to_target()
	enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed
	if distance <= SWING_RANGE and _swing_cooldown <= 0.0:
		_swing.start(SWING_WINDUP)
		enemy.set_warning(_swing, SWING_RANGE)
	elif distance <= THROW_RANGE and _throw_cooldown <= 0.0 and enemy.target_in_view():
		_throw.start(THROW_WINDUP)
		enemy.set_warning(_throw, 18.0)
