class_name MatronBehavior
extends EnemyBehavior

# Runs the ward: fans of sedative syringes that slow Grandpa, a gurney charge that smashes props
# and costs two pills, Lights Out, when the room goes dark but for a circle around him and she
# only throws syringes, and Visiting Hours, when Orderlies come in, two at most. Below half health
# she is quicker and her gurney charge runs straight into a volley.
const NEAR := 60.0
const SEDATIVE_WINDUP := 0.7
const SYRINGES := 3
const SYRINGE_SPREAD := deg_to_rad(30.0)
const SYRINGE_SPEED := 170.0
const SEDATIVE_LANE := 180.0
const SEDATIVE_LANE_WIDTH := 48.0
const GURNEY_WINDUP := 0.9
const GURNEY_LENGTH := 220.0
const GURNEY_SPEED := 360.0
const GURNEY_HIT_RANGE := 26.0
const GURNEY_LANE_WIDTH := 52.0
# She pulls up this far short of a wall, about half her body.
const WALL_MARGIN := 22.0
const STEP := 4.0
const LIGHTS_OUT_WINDUP := 0.5
const LIGHTS_OUT_WARNING := 1.0
const LIGHTS_OUT_TIME := 4.0
const LIGHTS_OUT_EVERY := 20.0
# The first Lights Out waits a while, so the fight opens in the light.
const FIRST_LIGHTS_OUT := 8.0
const DARK_COOLDOWN := 1.3
const VISITING_WINDUP := 0.7
const MAX_VISITORS := 2
const VISIT_DISTANCE := 100.0
const WARNING_RADIUS := 40.0
const BASE_COOLDOWN := 1.1
const PHASE_TWO_COOLDOWN := 0.85
const PHASE_TWO_SPEED := 1.2
const PHASE_TWO_WINDUP_SCALE := 0.8
const SAY_TIME := 1.2

enum Attack { NONE, SEDATIVE, GURNEY, LIGHTS_OUT, VISITING }

var _telegraph := Telegraph.new()
var _dash := BossDash.new()
var _attack := Attack.NONE
var _last := Attack.NONE
var _next := Attack.NONE
var _cooldown := 1.2
var _since_lights_out := LIGHTS_OUT_EVERY - FIRST_LIGHTS_OUT
var _dark_left := 0.0
# Every syringe flies down the lane that was shown.
var _aim := Vector2.RIGHT
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


static func is_phase_two(hp: float, max_hp: float) -> bool:
	return hp <= max_hp * 0.5


static func choose_attack(near: bool, last: int, since_lights_out: float, visitors_alive: int, roll: float) -> int:
	var options: Array[int] = [Attack.SEDATIVE, Attack.GURNEY]
	if since_lights_out >= LIGHTS_OUT_EVERY:
		options.append(Attack.LIGHTS_OUT)
	if visitors_alive < MAX_VISITORS:
		options.append(Attack.VISITING)
	if near:
		# Close up a charge has no room to run, so she fills a syringe fan or calls for help.
		options.erase(Attack.GURNEY)
	if options.size() > 1:
		options.erase(last)
	return options[mini(int(roll * options.size()), options.size() - 1)]


static func followup(attack: int, phase_two: bool) -> int:
	if phase_two and attack == Attack.GURNEY:
		return Attack.SEDATIVE
	return Attack.NONE


static func windup_for(attack: int, phase_two: bool) -> float:
	var windup := SEDATIVE_WINDUP
	match attack:
		Attack.GURNEY:
			windup = GURNEY_WINDUP
		Attack.LIGHTS_OUT:
			windup = LIGHTS_OUT_WINDUP
		Attack.VISITING:
			windup = VISITING_WINDUP
	return windup * (PHASE_TWO_WINDUP_SCALE if phase_two else 1.0)


static func cooldown_for(phase_two: bool) -> float:
	return PHASE_TWO_COOLDOWN if phase_two else BASE_COOLDOWN


# Where a charge from a point ends: its full length, or just short of the first wall or hole.
static func charge_end(from: Vector2, direction: Vector2, length: float, is_open: Callable) -> Vector2:
	var travelled := STEP
	while travelled <= length:
		if not is_open.call(from + direction * travelled):
			return from + direction * maxf(travelled - WALL_MARGIN, 0.0)
		travelled += STEP
	return from + direction * length


func is_dark() -> bool:
	return _dark_left > 0.0


func tick(enemy: Enemy, delta: float) -> void:
	var phase_two := is_phase_two(enemy.hp, enemy.max_hp())
	_since_lights_out += delta
	_dark_left = maxf(_dark_left - delta, 0.0)
	if _dash.is_active():
		_dash.tick(enemy, delta)
		if not _dash.is_active():
			_cooldown = cooldown_for(phase_two)
		return
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_finish_attack(enemy, phase_two)
		return
	_cooldown -= delta
	var offset := enemy.target.global_position - enemy.global_position
	var speed := enemy.def.speed * (PHASE_TWO_SPEED if phase_two else 1.0)
	if not enemy.target_in_view():
		enemy.desired_velocity = enemy.chase_direction() * speed * BossMoves.CATCH_UP_SPEED
		return
	var near := offset.length() <= NEAR
	if _cooldown <= 0.0 or (_next != Attack.NONE and _cooldown <= cooldown_for(phase_two) * 0.5):
		var attack := _next
		if attack == Attack.NONE:
			# In the dark she only throws syringes.
			attack = Attack.SEDATIVE if is_dark() else choose_attack(near, _last, _since_lights_out, _visitors(enemy), _rng.randf())
		_next = Attack.NONE
		_begin(enemy, attack, phase_two)
		return
	if not near:
		enemy.desired_velocity = enemy.chase_direction() * speed


func _visitors(enemy: Enemy) -> int:
	var count := 0
	for other: Enemy in enemy.get_tree().get_nodes_in_group("enemies"):
		if other != enemy and other.is_summon and not other.is_dead() and other.def == enemy.def.summon:
			count += 1
	return count


func _begin(enemy: Enemy, attack: int, phase_two: bool) -> void:
	_attack = attack
	_telegraph.start(windup_for(attack, phase_two))
	match attack:
		Attack.SEDATIVE:
			_aim = enemy.direction_to_target()
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.set_warning_lane(_aim, SEDATIVE_LANE, SEDATIVE_LANE_WIDTH, false)
		Attack.GURNEY:
			_aim = enemy.direction_to_target()
			var end := charge_end(enemy.global_position, _aim, GURNEY_LENGTH, enemy.open_ground) if enemy.open_ground.is_valid() else enemy.global_position + _aim * GURNEY_LENGTH
			enemy.set_warning(_telegraph, GURNEY_HIT_RANGE)
			enemy.set_warning_lane(_aim, enemy.global_position.distance_to(end), GURNEY_LANE_WIDTH)
		Attack.LIGHTS_OUT:
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Lights out, dearie.", SAY_TIME)
		Attack.VISITING:
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Visiting hours!", SAY_TIME)


func _finish_attack(enemy: Enemy, phase_two: bool) -> void:
	_last = _attack
	_cooldown = DARK_COOLDOWN if is_dark() else cooldown_for(phase_two)
	_next = followup(_attack, phase_two)
	match _attack:
		Attack.SEDATIVE:
			for direction in BossMoves.fan_directions(_aim, SYRINGES, SYRINGE_SPREAD):
				OrderlyBehavior.fire_dart(enemy, direction, SYRINGE_SPEED)
		Attack.GURNEY:
			var end := charge_end(enemy.global_position, _aim, GURNEY_LENGTH, enemy.open_ground) if enemy.open_ground.is_valid() else enemy.global_position + _aim * GURNEY_LENGTH
			_dash.start(_aim, enemy.global_position.distance_to(end), GURNEY_SPEED, GURNEY_HIT_RANGE, Enemy.HEAVY_DAMAGE)
		Attack.LIGHTS_OUT:
			_since_lights_out = 0.0
			_dark_left = LIGHTS_OUT_WARNING + LIGHTS_OUT_TIME
			var dark := LightsOut.new()
			dark.setup(enemy, enemy.target, LIGHTS_OUT_WARNING, LIGHTS_OUT_TIME)
			enemy.get_parent().add_child(dark)
			# She waits out the warning, then starts throwing in the dark.
			_cooldown = LIGHTS_OUT_WARNING
		Attack.VISITING:
			var room := MAX_VISITORS - _visitors(enemy)
			if room > 0:
				var points := BossMoves.cutoff_points(enemy.target_ground(), enemy.target_motion(), enemy.global_position, room, VISIT_DISTANCE, 1.0)
				enemy.request_summon_at(points, BossMoves.SUMMON_WARNING)
