extends EnemyBehavior

const SWEEP_RANGE := 64.0
const START_RANGE := 54.0
const SWEEP_WINDUP := 0.75
const CHARGE_WINDUP := 0.7
const CHARGE_LENGTH := 280.0
const CHARGE_SPEED := 380.0
const CHARGE_HIT_RANGE := 28.0
const COOLDOWN := 1.0
const SUMMON_EVERY := 9.0
const FIRST_SUMMON := 5.0
const SUMMON_COUNT := 3
const SUMMON_DISTANCE := 88.0
const SUMMON_SPREAD := 0.8
const MAX_ENEMIES := 6

enum Attack { NONE, SWEEP, CHARGE }

var _telegraph := Telegraph.new()
var _dash := BossDash.new()
var _attack := Attack.NONE
var _cooldown := 1.0
var _summon_timer := FIRST_SUMMON


static func choose_attack(near: bool) -> int:
	return Attack.SWEEP if near else Attack.CHARGE


func tick(enemy: Enemy, delta: float) -> void:
	_summon_timer -= delta
	if _summon_timer <= 0.0:
		_summon_timer = SUMMON_EVERY
		if BossMoves.can_summon(enemy.enemies_alive(), MAX_ENEMIES) and enemy.target_in_view():
			enemy.request_summon_at(BossMoves.cutoff_points(enemy.target.global_position, enemy.target_motion(), enemy.global_position, SUMMON_COUNT, SUMMON_DISTANCE, SUMMON_SPREAD), BossMoves.SUMMON_WARNING)
	if _dash.is_active():
		_dash.tick(enemy, delta)
		return
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_finish_attack(enemy)
		return
	_cooldown -= delta
	if not enemy.target_in_view():
		enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed * BossMoves.CATCH_UP_SPEED
		return
	var near := enemy.distance_to_target() <= START_RANGE and enemy.can_strike_target()
	if _cooldown <= 0.0:
		_begin(enemy, choose_attack(near))
		return
	if not near:
		enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed


func _begin(enemy: Enemy, attack: int) -> void:
	_attack = attack
	if attack == Attack.SWEEP:
		_telegraph.start(SWEEP_WINDUP)
		enemy.set_warning(_telegraph, SWEEP_RANGE)
	else:
		_telegraph.start(CHARGE_WINDUP)
		enemy.set_warning(_telegraph, CHARGE_HIT_RANGE)
		enemy.set_warning_lane(enemy.direction_to_target(), CHARGE_LENGTH, CHARGE_HIT_RANGE * 2.0)


func _finish_attack(enemy: Enemy) -> void:
	_cooldown = COOLDOWN
	if _attack == Attack.CHARGE:
		_dash.start(enemy.warning_lane_direction(), CHARGE_LENGTH, CHARGE_SPEED, CHARGE_HIT_RANGE)
		return
	enemy.smash(enemy.global_position, SWEEP_RANGE)
	if enemy.distance_to_target() <= SWEEP_RANGE:
		enemy.hit_target(enemy.def.damage)
