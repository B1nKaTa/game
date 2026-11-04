class_name PaperShredderBehavior
extends EnemyBehavior

# A shredder on legs. It warns, then charges down a lane at Grandpa, stopping short at anything solid,
# and spits a short trail of shredded paper behind it as it goes. The trail slows whoever walks
# through it for a while (see PaperTrail). Then it grinds to a halt and rests.
const START_RANGE := 200.0
const WINDUP := 0.75
const CHARGE_LENGTH := 230.0
const CHARGE_SPEED := 300.0
const LANE_WIDTH := 28.0
const HIT_RANGE := 16.0
const WARNING_RADIUS := 20.0
const COOLDOWN := 2.6
const FIRST_CHARGE := 1.2
# A scrap of paper falls every this many pixels of the charge.
const SCRAP_EVERY := 30.0
const WALL_GRACE := 0.05
const GRIND_TIME := 0.5
const GRIND_TEXT := "Grrrnnk!"

var _telegraph := Telegraph.new()
var _cooldown := FIRST_CHARGE
var _charge_left := 0.0
var _charged_for := 0.0
var _since_scrap := 0.0
var _grind_left := 0.0
var _way := Vector2.RIGHT
var _has_hit := false
var _trail: PaperTrail


# How many scraps a whole charge drops, so the trail is known to stay short.
static func scraps_per_charge() -> int:
	return floori(CHARGE_LENGTH / SCRAP_EVERY) + 1


func tick(enemy: Enemy, delta: float) -> void:
	if _charge_left > 0.0:
		_charge(enemy, delta)
		return
	if _grind_left > 0.0:
		_grind_left -= delta
		return
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_start_charge(enemy)
		return
	_cooldown -= delta
	if _cooldown <= 0.0 and enemy.distance_to_target() <= START_RANGE and enemy.target_in_view():
		_way = enemy.direction_to_target()
		if _way.is_zero_approx():
			_way = Vector2.RIGHT
		_telegraph.start(WINDUP)
		enemy.set_warning(_telegraph, WARNING_RADIUS)
		enemy.set_warning_lane(_way, CHARGE_LENGTH, LANE_WIDTH, false)
		return
	enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed


func _start_charge(enemy: Enemy) -> void:
	_charge_left = CHARGE_LENGTH
	_charged_for = 0.0
	_since_scrap = SCRAP_EVERY
	_has_hit = false
	_trail = null
	if enemy.is_inside_tree() and enemy.get_parent() != null:
		_trail = PaperTrail.new()
		_trail.setup(enemy.target)
		enemy.get_parent().add_child(_trail)


func _charge(enemy: Enemy, delta: float) -> void:
	if _charged_for > WALL_GRACE and enemy.get_slide_collision_count() > 0:
		_stop(enemy)
		return
	_charged_for += delta
	enemy.hold_lane()
	var step := CHARGE_SPEED * delta
	_charge_left -= step
	_since_scrap += step
	enemy.desired_velocity = _way * CHARGE_SPEED
	if _since_scrap >= SCRAP_EVERY and is_instance_valid(_trail):
		_since_scrap = 0.0
		_trail.add_scrap(enemy.global_position)
	if not _has_hit and enemy.global_position.distance_to(enemy.target_ground()) <= HIT_RANGE:
		_has_hit = true
		enemy.hit_target(enemy.def.damage)
	if _charge_left <= 0.0:
		_stop(enemy)


func _stop(enemy: Enemy) -> void:
	_charge_left = 0.0
	_cooldown = COOLDOWN
	_grind_left = GRIND_TIME
	enemy.say(GRIND_TEXT, GRIND_TIME + 0.3)
