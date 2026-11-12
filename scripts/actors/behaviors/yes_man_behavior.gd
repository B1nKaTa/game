class_name YesManBehavior
extends EnemyBehavior

# A Yes-Man, one of three who copy one another (see YesMenChorus). Each closes in on Grandpa from its
# own side and, once near, makes a warned lunge down a short lane. Whenever one lunges, the other two
# start the same warned lunge half a beat later, each down its own lane, wherever they are.
const START_RANGE := 72.0
const LUNGE_WINDUP := 0.55
# The lunge starts right beside him, so its warning always shows whole.
const LUNGE_SHOWN_WHOLE := true
const LUNGE_LENGTH := 64.0
const LUNGE_SPEED := 256.0
const LANE_WIDTH := 24.0
const HIT_RANGE := 18.0
const WARNING_RADIUS := 20.0
const COOLDOWN := 1.8
const FIRST_LUNGE := 0.8
const FLANK_DISTANCE := 40.0
const FLANK_FROM := 220.0
const SIDES := 3
# A member of a group waits this long for its leader to gather it before it gathers a chorus itself.
const CHORUS_GRACE := 0.3
const WALL_GRACE := 0.05
const SAY_TIME := 0.8
const LINES: Array[String] = ["Yes!", "Agreed!", "Absolutely!"]

var _chorus: YesMenChorus
var _wait := CHORUS_GRACE
var _telegraph := Telegraph.new()
var _cooldown := FIRST_LUNGE
var _seen_lead := 0
var _echo_left := -1.0
var _lunge_left := 0.0
var _lunged_for := 0.0
var _way := Vector2.RIGHT
var _has_hit := false
var _flank := 0.0
var _flank_set := false


# Each member keeps to its own side of Grandpa, a third of a turn from the next.
static func flank_angle(index: int) -> float:
	return TAU * posmod(index, SIDES) / float(SIDES)


# How long a lunge lasts, from its length and speed.
static func lunge_time() -> float:
	return LUNGE_LENGTH / LUNGE_SPEED


func tick(enemy: Enemy, delta: float) -> void:
	if not _flank_set:
		_flank_set = true
		_flank = flank_angle(enemy.spawn_index)
	if _chorus == null:
		_join(enemy, delta)
	# Another member's lunge is copied half a beat later, unless this one is busy with its own.
	if _chorus != null and _chorus.leads != _seen_lead:
		_seen_lead = _chorus.leads
		var busy := _lunge_left > 0.0 or _telegraph.is_active()
		if not busy and _chorus.last_leader_id != enemy.get_instance_id():
			_echo_left = YesMenChorus.echo_delay(false)
	if _lunge_left > 0.0:
		_lunge(enemy, delta)
		return
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_lunge_left = LUNGE_LENGTH
			_lunged_for = 0.0
			_has_hit = false
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _echo_left >= 0.0:
		_echo_left -= delta
		if _echo_left < 0.0:
			_begin(enemy, false)
			return
	elif _cooldown <= 0.0 and enemy.distance_to_target() <= START_RANGE and enemy.target_in_view() and enemy.can_strike_target():
		_begin(enemy, true)
		return
	_walk(enemy)


func _join(enemy: Enemy, delta: float) -> void:
	if enemy.has_meta(YesMenChorus.META):
		_chorus = enemy.get_meta(YesMenChorus.META)
		_seen_lead = _chorus.leads
		return
	_wait -= delta
	if enemy.is_group_follower and _wait > 0.0:
		return
	_chorus = YesMenChorus.gather(enemy)
	_seen_lead = _chorus.leads


func _begin(enemy: Enemy, leads: bool) -> void:
	_way = enemy.direction_to_target()
	if _way.is_zero_approx():
		_way = Vector2.DOWN
	_cooldown = COOLDOWN
	_telegraph.start(LUNGE_WINDUP)
	enemy.set_warning(_telegraph, WARNING_RADIUS, LUNGE_SHOWN_WHOLE)
	enemy.set_warning_lane(_way, LUNGE_LENGTH, LANE_WIDTH, false)
	enemy.say(LINES[posmod(enemy.spawn_index, LINES.size())], SAY_TIME)
	if leads and _chorus != null:
		_chorus.lead(enemy)
		_seen_lead = _chorus.leads


func _lunge(enemy: Enemy, delta: float) -> void:
	if _lunged_for > WALL_GRACE and enemy.get_slide_collision_count() > 0:
		_lunge_left = 0.0
		return
	_lunged_for += delta
	enemy.hold_lane()
	_lunge_left -= LUNGE_SPEED * delta
	enemy.desired_velocity = _way * LUNGE_SPEED
	if not _has_hit and enemy.global_position.distance_to(enemy.target_ground()) <= HIT_RANGE:
		_has_hit = true
		enemy.hit_target(enemy.def.damage)


# Toward its own side of him while some way off, then straight in, round props by the walk grid.
func _walk(enemy: Enemy) -> void:
	var spot := enemy.target_ground()
	var distance := enemy.distance_to_target()
	if distance > FLANK_DISTANCE and distance < FLANK_FROM:
		spot += Vector2.from_angle(_flank) * FLANK_DISTANCE
	enemy.desired_velocity = enemy.walk_direction_to(spot) * enemy.def.speed
