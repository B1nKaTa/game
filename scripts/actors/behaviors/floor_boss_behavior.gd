extends EnemyBehavior

const SWEEP_RANGE := 72.0
const SWEEP_START := 64.0
const SWEEP_WINDUP := 0.8
const FAN_WINDUP := 0.6
const PROJECTILE_SPEED := 120.0
const FAN_SPREAD := 0.35
const BASE_COOLDOWN := 1.4
const PHASE_TWO_COOLDOWN := 0.9
const PHASE_TWO_SPEED := 1.3
const FAN_SHOTS := 5
const PHASE_TWO_SHOTS := 7

enum Attack { NONE, SWEEP, FAN }

var _telegraph := Telegraph.new()
var _cooldown := 1.5
var _attack := Attack.NONE


static func is_phase_two(hp: float, max_hp: float) -> bool:
	return hp <= max_hp * 0.5


func tick(enemy: Enemy, delta: float) -> void:
	var phase_two := is_phase_two(enemy.hp, enemy.def.max_hp)
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_finish_attack(enemy, phase_two)
		return
	_cooldown -= delta
	var distance := enemy.distance_to_target()
	if _cooldown <= 0.0:
		if distance <= SWEEP_START:
			_attack = Attack.SWEEP
			_telegraph.start(SWEEP_WINDUP)
			enemy.set_warning(_telegraph, SWEEP_RANGE)
		else:
			_attack = Attack.FAN
			_telegraph.start(FAN_WINDUP)
			enemy.set_warning(_telegraph, 30.0)
		return
	if distance > SWEEP_START:
		var speed := enemy.def.speed * (PHASE_TWO_SPEED if phase_two else 1.0)
		enemy.desired_velocity = enemy.direction_to_target() * speed


func _finish_attack(enemy: Enemy, phase_two: bool) -> void:
	_cooldown = PHASE_TWO_COOLDOWN if phase_two else BASE_COOLDOWN
	if _attack == Attack.SWEEP:
		enemy.smash(enemy.global_position, SWEEP_RANGE)
		if enemy.distance_to_target() <= SWEEP_RANGE:
			enemy.hit_target(enemy.def.damage)
		return
	var shots := PHASE_TWO_SHOTS if phase_two else FAN_SHOTS
	var aim := enemy.direction_to_target()
	for i in shots:
		var offset := (i - (shots - 1) / 2.0) * FAN_SPREAD
		enemy.shoot(aim.rotated(offset), PROJECTILE_SPEED)
