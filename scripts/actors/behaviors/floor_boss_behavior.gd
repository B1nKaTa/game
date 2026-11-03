extends EnemyBehavior

const SWEEP_RANGE := 72.0
const SWEEP_START := 64.0
const SWEEP_WINDUP := 0.7
const DASH_WINDUP := 0.75
const RING_WINDUP := 0.65
const SUMMON_WINDUP := 0.7
const PHASE_TWO_WINDUP_SCALE := 0.8
const BASE_COOLDOWN := 0.85
const PHASE_TWO_COOLDOWN := 0.65
const PHASE_TWO_SPEED := 1.2
const DASH_LENGTH := 420.0
const DASH_SPEED := 460.0
const DASH_HIT_RANGE := 28.0
const RING_SHOTS := 12
const PHASE_TWO_RING_SHOTS := 16
const RING_SPEED := 140.0
const RING_WARNING_RADIUS := 40.0
const SUMMON_COUNT := 3
const SUMMON_EVERY := 11.0
const PHASE_TWO_SUMMON_EVERY := 8.0
const SUMMON_DISTANCE := 96.0
const SUMMON_SPREAD := 1.0
const MAX_ENEMIES := 7
const NEAR_DASH_CHANCE := 0.25

enum Attack { NONE, SWEEP, DASH, RING, SUMMON }

var _telegraph := Telegraph.new()
var _dash := BossDash.new()
var _cooldown := 1.2
var _attack := Attack.NONE
var _last := Attack.NONE
var _next := Attack.NONE
var _summon_wait := 5.0


static func is_phase_two(hp: float, max_hp: float) -> bool:
	return hp <= max_hp * 0.5


static func choose_attack(near: bool, last: int, may_summon: bool, roll: float) -> int:
	if near:
		return Attack.DASH if roll >= 1.0 - NEAR_DASH_CHANCE else Attack.SWEEP
	var options: Array[int] = []
	for attack: int in [Attack.DASH, Attack.RING, Attack.SUMMON]:
		if attack == last or (attack == Attack.SUMMON and not may_summon):
			continue
		options.append(attack)
	return options[mini(int(roll * options.size()), options.size() - 1)]


# The harder phase mixes its attacks by running one straight into the next.
static func followup(attack: int, phase_two: bool, roll: float) -> int:
	if not phase_two:
		return Attack.NONE
	match attack:
		Attack.DASH:
			return Attack.RING if roll < 0.5 else Attack.SWEEP
		Attack.RING:
			return Attack.DASH
		Attack.SWEEP:
			return Attack.RING if roll < 0.5 else Attack.NONE
	return Attack.NONE


static func windup_for(attack: int, phase_two: bool) -> float:
	var windup := SWEEP_WINDUP
	match attack:
		Attack.DASH:
			windup = DASH_WINDUP
		Attack.RING:
			windup = RING_WINDUP
		Attack.SUMMON:
			windup = SUMMON_WINDUP
	return windup * (PHASE_TWO_WINDUP_SCALE if phase_two else 1.0)


static func cooldown_for(phase_two: bool) -> float:
	return PHASE_TWO_COOLDOWN if phase_two else BASE_COOLDOWN


static func ring_count(phase_two: bool) -> int:
	return PHASE_TWO_RING_SHOTS if phase_two else RING_SHOTS


func tick(enemy: Enemy, delta: float) -> void:
	var phase_two := is_phase_two(enemy.hp, enemy.max_hp())
	_summon_wait -= delta
	if _dash.is_active():
		_dash.tick(enemy, delta)
		if not _dash.is_active():
			_end_attack(phase_two)
		return
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_finish_attack(enemy, phase_two)
		return
	_cooldown -= delta
	var offset := enemy.target.global_position - enemy.global_position
	var speed := enemy.def.speed * (PHASE_TWO_SPEED if phase_two else 1.0)
	# Far off in a big room it hurries over instead of attacking from beyond the screen.
	if not enemy.target_in_view():
		enemy.desired_velocity = enemy.chase_direction() * speed * BossMoves.CATCH_UP_SPEED
		return
	var near := offset.length() <= SWEEP_START
	if _next != Attack.NONE:
		var chained := _next
		_next = Attack.NONE
		_begin(enemy, chained, phase_two)
		return
	if _cooldown <= 0.0:
		_begin(enemy, choose_attack(near, _last, _may_summon(enemy), randf()), phase_two)
		return
	if not near:
		enemy.desired_velocity = enemy.chase_direction() * speed


func _may_summon(enemy: Enemy) -> bool:
	return _summon_wait <= 0.0 and enemy.def.summon != null and BossMoves.can_summon(enemy.enemies_alive(), MAX_ENEMIES)


func _begin(enemy: Enemy, attack: int, phase_two: bool) -> void:
	_attack = attack
	var windup := windup_for(attack, phase_two)
	_telegraph.start(windup)
	match attack:
		Attack.SWEEP:
			enemy.set_warning(_telegraph, SWEEP_RANGE)
		Attack.DASH:
			enemy.set_warning(_telegraph, DASH_HIT_RANGE)
			enemy.set_warning_lane(enemy.direction_to_target(), DASH_LENGTH, DASH_HIT_RANGE * 2.0)
		Attack.RING:
			enemy.set_warning(_telegraph, RING_WARNING_RADIUS)
		Attack.SUMMON:
			enemy.set_warning(_telegraph, RING_WARNING_RADIUS)


func _finish_attack(enemy: Enemy, phase_two: bool) -> void:
	match _attack:
		Attack.SWEEP:
			enemy.smash(enemy.global_position, SWEEP_RANGE)
			if enemy.distance_to_target() <= SWEEP_RANGE:
				enemy.hit_target(enemy.def.damage)
		Attack.DASH:
			_dash.start(enemy.warning_lane_direction(), DASH_LENGTH, DASH_SPEED, DASH_HIT_RANGE)
			return
		Attack.RING:
			for direction in BossMoves.ring_directions(ring_count(phase_two), randf() * TAU):
				enemy.shoot(direction, RING_SPEED)
		Attack.SUMMON:
			_summon_wait = PHASE_TWO_SUMMON_EVERY if phase_two else SUMMON_EVERY
			enemy.request_summon_at(BossMoves.cutoff_points(enemy.target.global_position, enemy.target_motion(), enemy.global_position, SUMMON_COUNT, SUMMON_DISTANCE, SUMMON_SPREAD), BossMoves.SUMMON_WARNING)
	_end_attack(phase_two)


func _end_attack(phase_two: bool) -> void:
	_cooldown = cooldown_for(phase_two)
	_last = _attack
	_next = followup(_attack, phase_two, randf())
