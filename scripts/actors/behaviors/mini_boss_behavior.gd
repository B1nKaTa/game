extends EnemyBehavior

const SWEEP_RANGE := 64.0
const START_RANGE := 54.0
const WINDUP := 0.8
const COOLDOWN := 1.3
const SUMMON_EVERY := 8.0
const SUMMON_COUNT := 2
const MAX_ENEMIES := 5

var _telegraph := Telegraph.new()
var _cooldown := 1.0
var _summon_timer := SUMMON_EVERY


func tick(enemy: Enemy, delta: float) -> void:
	_summon_timer -= delta
	if _summon_timer <= 0.0:
		_summon_timer = SUMMON_EVERY
		if enemy.get_tree().get_nodes_in_group("enemies").size() < MAX_ENEMIES:
			enemy.request_summon(SUMMON_COUNT)
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_cooldown = COOLDOWN
			enemy.smash(enemy.global_position, SWEEP_RANGE)
			if enemy.distance_to_target() <= SWEEP_RANGE:
				enemy.hit_target(enemy.def.damage)
		return
	_cooldown -= delta
	if enemy.distance_to_target() <= START_RANGE:
		if _cooldown <= 0.0:
			_telegraph.start(WINDUP)
			enemy.set_warning(_telegraph, SWEEP_RANGE)
		return
	enemy.desired_velocity = enemy.direction_to_target() * enemy.def.speed
