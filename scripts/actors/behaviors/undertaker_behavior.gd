extends EnemyBehavior

# Digs the room up around Grandpa: a shovel drop up close, rows of plots with one gap each, open
# graves that follow him and then lock in, fans of funeral wreaths, and Plot Holders marked around
# him. Below half health it is quicker and runs attacks together.
const SHOVEL_RANGE := 72.0
const SHOVEL_START := 62.0
const SHOVEL_WINDUP := 0.7
const CROSS_DISTANCE := 112.0
const CROSS_RADIUS := 30.0
const CROSS_WARNING := 0.55
const ROWS_WINDUP := 0.7
const ROWS := 3
const PHASE_TWO_ROWS := 4
const ROW_SPOTS := 7
const ROW_SPACING := 70.0
const ROW_SPOT_GAP := 42.0
const ROW_RADIUS := 24.0
const ROW_WARNING := 0.7
const ROW_STEP := 0.4
const PITS_WINDUP := 0.6
const PITS := 3
const PHASE_TWO_PITS := 4
const PIT_RADIUS := 38.0
const PIT_FOLLOW := 0.4
const PIT_WARNING := 0.6
const PIT_STEP := 0.7
const WREATHS_WINDUP := 0.65
const WREATH_SHOTS := 5
const WREATH_SPREAD := 1.1
const WREATH_SPEED := 150.0
const VOLLEYS := 2
const PHASE_TWO_VOLLEYS := 3
const VOLLEY_GAP := 0.42
const SUMMON_WINDUP := 0.7
const SUMMON_COUNT := 3
const SUMMON_DISTANCE := 112.0
const SUMMON_EVERY := 12.0
const PHASE_TWO_SUMMON_EVERY := 9.0
const MAX_ENEMIES := 6
const WARNING_RADIUS := 40.0
const LANE_WIDTH := 56.0
const BASE_COOLDOWN := 1.05
const PHASE_TWO_COOLDOWN := 0.8
const PHASE_TWO_SPEED := 1.2
const PHASE_TWO_WINDUP_SCALE := 0.8
const NEAR_PITS_CHANCE := 0.25

enum Attack { NONE, SHOVEL, ROWS, PITS, WREATHS, SUMMON }

var _telegraph := Telegraph.new()
var _attack := Attack.NONE
var _last := Attack.NONE
var _next := Attack.NONE
var _cooldown := 1.2
var _summon_wait := 6.0
var _volleys_left := 0
var _volley_wait := 0.0
# Every volley flies down the lane that was shown, so none of them comes unwarned.
var _volley_aim := Vector2.RIGHT
var _row_gap := 0


static func is_phase_two(hp: float, max_hp: float) -> bool:
	return hp <= max_hp * 0.5


static func choose_attack(near: bool, last: int, may_summon: bool, roll: float) -> int:
	if near:
		return Attack.PITS if roll >= 1.0 - NEAR_PITS_CHANCE else Attack.SHOVEL
	var options: Array[int] = []
	for attack: int in [Attack.ROWS, Attack.PITS, Attack.WREATHS, Attack.SUMMON]:
		if attack == last or (attack == Attack.SUMMON and not may_summon):
			continue
		options.append(attack)
	return options[mini(int(roll * options.size()), options.size() - 1)]


static func followup(attack: int, phase_two: bool, roll: float) -> int:
	if not phase_two:
		return Attack.NONE
	match attack:
		Attack.ROWS:
			return Attack.PITS if roll < 0.5 else Attack.WREATHS
		Attack.PITS:
			return Attack.WREATHS if roll < 0.5 else Attack.ROWS
		Attack.WREATHS:
			return Attack.PITS if roll < 0.5 else Attack.NONE
	return Attack.NONE


static func windup_for(attack: int, phase_two: bool) -> float:
	var windup := SHOVEL_WINDUP
	match attack:
		Attack.ROWS:
			windup = ROWS_WINDUP
		Attack.PITS:
			windup = PITS_WINDUP
		Attack.WREATHS:
			windup = WREATHS_WINDUP
		Attack.SUMMON:
			windup = SUMMON_WINDUP
	return windup * (PHASE_TWO_WINDUP_SCALE if phase_two else 1.0)


static func cooldown_for(phase_two: bool) -> float:
	return PHASE_TWO_COOLDOWN if phase_two else BASE_COOLDOWN


static func row_count(phase_two: bool) -> int:
	return PHASE_TWO_ROWS if phase_two else ROWS


static func pit_count(phase_two: bool) -> int:
	return PHASE_TWO_PITS if phase_two else PITS


static func volley_count(phase_two: bool) -> int:
	return PHASE_TWO_VOLLEYS if phase_two else VOLLEYS


# Rows across the way to Grandpa, nearest first. Each leaves out one spot, and the gap moves along.
static func row_points(from: Vector2, direction: Vector2, rows: int, spots: int, gap_start: int) -> Array:
	var across := direction.orthogonal()
	var result := []
	for r in rows:
		var row: Array[Vector2] = []
		var gap := posmod(gap_start + r * 2, spots)
		for spot in spots:
			if spot != gap:
				row.append(from + direction * ROW_SPACING * (r + 1) + across * (spot - (spots - 1) / 2.0) * ROW_SPOT_GAP)
		result.append(row)
	return result


# Spread evenly over a total angle, with the middle one aimed at him.
static func fan_directions(aim: Vector2, count: int, spread: float) -> Array[Vector2]:
	var directions: Array[Vector2] = []
	for i in count:
		directions.append(aim.rotated(spread * (i / float(count - 1) - 0.5)))
	return directions


static func corner_points(center: Vector2, count: int, distance: float, start_angle: float) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for i in count:
		points.append(center + Vector2.from_angle(start_angle + TAU * i / float(count)) * distance)
	return points


func tick(enemy: Enemy, delta: float) -> void:
	var phase_two := is_phase_two(enemy.hp, enemy.max_hp())
	_summon_wait -= delta
	if _volleys_left > 0:
		_volley_wait -= delta
		if _volley_wait <= 0.0:
			_fire_volley(enemy)
		return
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_finish_attack(enemy, phase_two)
		return
	_cooldown -= delta
	var offset := enemy.target.global_position - enemy.global_position
	var speed := enemy.def.speed * (PHASE_TWO_SPEED if phase_two else 1.0)
	# Far off in a big room it walks over, and starts nothing he cannot see.
	if not enemy.target_in_view():
		enemy.desired_velocity = enemy.chase_direction() * speed * BossMoves.CATCH_UP_SPEED
		return
	var near := offset.length() <= SHOVEL_START and enemy.can_strike_target()
	if _cooldown <= 0.0:
		var attack := _next if _next != Attack.NONE else choose_attack(near, _last, _may_summon(enemy), randf())
		_next = Attack.NONE
		_begin(enemy, attack, phase_two)
		return
	if not near:
		enemy.desired_velocity = enemy.chase_direction() * speed


func _may_summon(enemy: Enemy) -> bool:
	return _summon_wait <= 0.0 and enemy.def.summon != null and BossMoves.can_summon(enemy.enemies_alive(), MAX_ENEMIES)


func _begin(enemy: Enemy, attack: int, phase_two: bool) -> void:
	_attack = attack
	_telegraph.start(windup_for(attack, phase_two))
	match attack:
		Attack.SHOVEL:
			enemy.set_warning(_telegraph, SHOVEL_RANGE)
		Attack.WREATHS:
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			_volley_aim = enemy.direction_to_target()
			enemy.set_warning_lane(_volley_aim, WREATH_SPEED, LANE_WIDTH, false)
		_:
			enemy.set_warning(_telegraph, WARNING_RADIUS)
	# Looks only: his own move plays over the windup and the moment it lands.
	match attack:
		Attack.WREATHS:
			enemy.play_anim("wreath_throw", windup_for(attack, phase_two) + EnemyAnim.ATTACK_TIME)
		Attack.PITS:
			enemy.play_anim("point", windup_for(attack, phase_two) + EnemyAnim.ATTACK_TIME)


func _finish_attack(enemy: Enemy, phase_two: bool) -> void:
	# The boss waits out whatever it has set going, so patterns never pile up unreadably.
	var busy := 0.0
	match _attack:
		Attack.SHOVEL:
			enemy.smash(enemy.global_position, SHOVEL_RANGE)
			if enemy.distance_to_target() <= SHOVEL_RANGE:
				enemy.hit_target(enemy.def.damage)
			for point in corner_points(enemy.global_position, 4, CROSS_DISTANCE, randf() * TAU):
				enemy.strike_ground(point, CROSS_RADIUS, CROSS_WARNING)
		Attack.ROWS:
			var rows := row_points(enemy.global_position, enemy.direction_to_target(), row_count(phase_two), ROW_SPOTS, _row_gap)
			_row_gap = randi() % ROW_SPOTS
			for r in rows.size():
				for point: Vector2 in rows[r]:
					enemy.strike_ground(point, ROW_RADIUS, ROW_WARNING, r * ROW_STEP)
			busy = ROW_STEP * rows.size()
		Attack.PITS:
			var count := pit_count(phase_two)
			for i in count:
				enemy.strike_ground(enemy.target_ground(), PIT_RADIUS, PIT_WARNING, i * PIT_STEP, PIT_FOLLOW)
			busy = PIT_STEP * count
		Attack.WREATHS:
			_volleys_left = volley_count(phase_two)
			_volley_wait = 0.0
		Attack.SUMMON:
			_summon_wait = PHASE_TWO_SUMMON_EVERY if phase_two else SUMMON_EVERY
			enemy.request_summon_at(corner_points(enemy.target_ground(), SUMMON_COUNT, SUMMON_DISTANCE, randf() * TAU), BossMoves.SUMMON_WARNING)
	_cooldown = cooldown_for(phase_two) + busy
	_last = _attack
	_next = followup(_attack, phase_two, randf())


func _fire_volley(enemy: Enemy) -> void:
	_volleys_left -= 1
	_volley_wait = VOLLEY_GAP
	for direction in fan_directions(_volley_aim, WREATH_SHOTS, WREATH_SPREAD):
		enemy.shoot(direction, WREATH_SPEED)
