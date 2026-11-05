class_name HeadOfDeparturesBehavior
extends EnemyBehavior

# Augustine, Head of Departures. His boarding stamp comes down on a warned spot under Grandpa, the one
# attack that costs three pills, so its warning always shows whole, with a second ring and the stamp's
# growing shadow. His runway lights light warned lanes one after another across the room. His gate
# change raises or drops every queue barrier in the room at once, after the barriers' own chime. Below
# half health he calls Tour Groups, never past five enemies in the room, the barriers cycle twice as
# fast, and once, one runway-lights pattern chains straight into the stamp.
const STAMP_WINDUP := 1.2
const STAMP_RADIUS := 46.0
const STAMP_DAMAGE := Enemy.HEAVIEST_DAMAGE
# The stamp's warning shows for all of its windup, whatever the player's warning stat.
const STAMP_SHOWN_WHOLE := true
const RUNWAY_WINDUP := 0.6
const RUNWAY_WARNING := 0.9
const RUNWAY_STEP := 0.35
# Lanes side by side across the way they run, lit in turn from one end of the band to the other.
const RUNWAY_LANES := 5
const RUNWAY_WIDTH := 40.0
const GATE_WINDUP := 0.6
const GATE_EVERY := 8.0
const FIRST_GATE := 3.0
const WARNING_RADIUS := 40.0
# Shorter than Mortimer's and the Mall Santa's 0.65 and 0.45, as he must be clearly harder.
const BASE_COOLDOWN := 0.5
const PHASE_TWO_COOLDOWN := 0.32
const PHASE_TWO_SPEED := 1.2
const PHASE_TWO_WINDUP_SCALE := 0.8
# Below half health the barriers' timer runs this many times as fast.
const PHASE_TWO_BARRIER_PACE := 2.0
const KEEP_NEAR := 90.0
const MAX_ENEMIES := 5
const SUMMON_COUNT := 3
const FIRST_SUMMON := 1.5
const SUMMON_EVERY := 8.0
const SUMMON_DISTANCE := 100.0
const SAY_TIME := 1.0

enum Attack { NONE, STAMP, RUNWAY, GATE }

var _telegraph := Telegraph.new()
var _attack := Attack.NONE
var _last := Attack.NONE
var _next := Attack.NONE
var _cooldown := 1.2
var _since_gate := GATE_EVERY - FIRST_GATE
var _summon_timer := FIRST_SUMMON
var _across := Vector2.RIGHT
var _phase_two_seen := false
# The one runway pattern of the second phase that chains into the stamp has run.
var _chained := false
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


static func is_phase_two(hp: float, max_hp: float) -> bool:
	return hp <= max_hp * 0.5


static func cooldown_for(phase_two: bool) -> float:
	return PHASE_TWO_COOLDOWN if phase_two else BASE_COOLDOWN


# The second phase quickens his windups, but never the stamp's extra-clear warning.
static func windup_for(attack: int, phase_two: bool) -> float:
	var windup := RUNWAY_WINDUP
	match attack:
		Attack.STAMP:
			return STAMP_WINDUP
		Attack.GATE:
			windup = GATE_WINDUP
	return windup * (PHASE_TWO_WINDUP_SCALE if phase_two else 1.0)


# In the second phase one runway-lights pattern, and only one, chains straight into the stamp.
static func followup(attack: int, phase_two: bool, already_chained: bool) -> int:
	if phase_two and attack == Attack.RUNWAY and not already_chained:
		return Attack.STAMP
	return Attack.NONE


# With no barriers in the room there is no gate change: the runway lights stand in for it.
static func choose_attack(last: int, has_barriers: bool, roll: float) -> int:
	var options: Array[int] = [Attack.STAMP, Attack.RUNWAY]
	if has_barriers:
		options.append(Attack.GATE)
	if options.size() > 1:
		options.erase(last)
	return options[mini(int(roll * options.size()), options.size() - 1)]


# Raise them when most are down, drop them when most are up, so the room always changes.
static func gate_kind(up: int, total: int) -> int:
	return QueueBarrier.DROP if up * 2 > total else QueueBarrier.RISE


# As many Tour Group members as fit under the cap, at most SUMMON_COUNT, never a negative number.
static func summon_count(alive: int, cap: int) -> int:
	return clampi(cap - alive, 0, SUMMON_COUNT)


# One lane of the runway: the length of the room along direction, set beside the others across it.
# The band of lanes lies around center, moved to lie inside the room.
static func runway_slot(room_rect: Rect2, direction: Vector2, slot: int, center := Vector2.INF) -> Rect2:
	var middle_at := room_rect.get_center() if center == Vector2.INF else center
	var band := RUNWAY_WIDTH * RUNWAY_LANES
	var horizontal := absf(direction.x) >= absf(direction.y)
	var low := room_rect.position.y if horizontal else room_rect.position.x
	var high := room_rect.end.y if horizontal else room_rect.end.x
	var middle := middle_at.y if horizontal else middle_at.x
	var start := clampf(middle - band / 2.0, low, maxf(high - band, low))
	var at := start + slot * RUNWAY_WIDTH
	if horizontal:
		return Rect2(room_rect.position.x, at, room_rect.size.x, RUNWAY_WIDTH)
	return Rect2(at, room_rect.position.y, RUNWAY_WIDTH, room_rect.size.y)


# Every lane in the order they light: from one end of the band to the other.
static func runway_lanes(room_rect: Rect2, direction: Vector2, center: Vector2, reverse: bool) -> Array[Rect2]:
	var lanes: Array[Rect2] = []
	for i in RUNWAY_LANES:
		lanes.append(runway_slot(room_rect, direction, RUNWAY_LANES - 1 - i if reverse else i, center))
	return lanes


# When each lane of a pattern lights, counted from the end of his windup.
static func runway_light_time(order: int) -> float:
	return RUNWAY_WARNING + order * RUNWAY_STEP


func tick(enemy: Enemy, delta: float) -> void:
	var phase_two := is_phase_two(enemy.hp, enemy.max_hp())
	if phase_two and not _phase_two_seen:
		_enter_phase_two(enemy)
	_since_gate += delta
	if phase_two:
		_call_tour_groups(enemy, delta)
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_finish_attack(enemy, phase_two)
		return
	_cooldown -= delta
	var speed := enemy.def.speed * (PHASE_TWO_SPEED if phase_two else 1.0)
	if not enemy.target_in_view():
		enemy.desired_velocity = enemy.chase_direction() * speed * BossMoves.CATCH_UP_SPEED
		return
	if _cooldown <= 0.0 or (_next != Attack.NONE and _cooldown <= cooldown_for(phase_two) * 0.5):
		var attack := _next
		if attack == Attack.NONE:
			attack = choose_attack(_last, _has_barriers(enemy) and _since_gate >= GATE_EVERY, _rng.randf())
		_next = Attack.NONE
		_begin(enemy, attack, phase_two)
		return
	if enemy.distance_to_target() > KEEP_NEAR:
		enemy.desired_velocity = enemy.chase_direction() * speed


func _enter_phase_two(enemy: Enemy) -> void:
	_phase_two_seen = true
	enemy.say("Now boarding: everyone!", SAY_TIME)
	for barrier in _barriers(enemy):
		barrier.cycle_faster(PHASE_TWO_BARRIER_PACE)


func _call_tour_groups(enemy: Enemy, delta: float) -> void:
	_summon_timer -= delta
	if _summon_timer > 0.0 or not enemy.target_in_view():
		return
	_summon_timer = SUMMON_EVERY
	var count := summon_count(enemy.enemies_alive(), MAX_ENEMIES)
	if BossMoves.can_summon(enemy.enemies_alive(), MAX_ENEMIES) and count > 0:
		enemy.say("Group C, this way!", SAY_TIME)
		enemy.request_summon_at(BossMoves.cutoff_points(enemy.target_ground(), enemy.target_motion(), enemy.global_position, count, SUMMON_DISTANCE, 0.6), BossMoves.SUMMON_WARNING)


func _barriers(enemy: Enemy) -> Array:
	return QueueBarrier.barriers_in(enemy.get_tree()) if enemy.is_inside_tree() else []


func _has_barriers(enemy: Enemy) -> bool:
	return not _barriers(enemy).is_empty()


func _begin(enemy: Enemy, attack: int, phase_two: bool) -> void:
	if attack == Attack.GATE and not _has_barriers(enemy):
		attack = Attack.RUNWAY
	_attack = attack
	_telegraph.start(windup_for(attack, phase_two))
	match attack:
		Attack.STAMP:
			# The windup on him shows whole too, and the stamp's spot is locked under Grandpa at once.
			enemy.set_warning(_telegraph, WARNING_RADIUS, STAMP_SHOWN_WHOLE)
			enemy.say("Stamped and departed!", SAY_TIME)
			TerminalStrike.strike(enemy, enemy.target_ground(), STAMP_RADIUS, STAMP_WINDUP, 0.0, STAMP_DAMAGE, TerminalStrike.LOOK_STAMP)
		Attack.RUNWAY:
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Clear the runway!", SAY_TIME)
		Attack.GATE:
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Gate change!", SAY_TIME)


func _finish_attack(enemy: Enemy, phase_two: bool) -> void:
	var busy := 0.0
	match _attack:
		Attack.RUNWAY:
			_light_runway(enemy)
			busy = runway_light_time(RUNWAY_LANES - 1)
		Attack.GATE:
			_since_gate = 0.0
			var barriers := _barriers(enemy)
			var up := 0
			for barrier in barriers:
				up += 1 if barrier.is_up() else 0
			var kind := gate_kind(up, barriers.size())
			for barrier in barriers:
				barrier.take_control(kind)
			busy = QueueBarrier.CHIME
	_cooldown = cooldown_for(phase_two) + busy
	_last = _attack
	_next = followup(_attack, phase_two, _chained)
	if _next == Attack.STAMP:
		# Straight into it: the chained stamp starts as the last lane lights.
		_chained = true
		_cooldown = busy


# The lanes run across the way to him, turning each time, and light from one end of the band.
func _light_runway(enemy: Enemy) -> void:
	_across = Vector2.DOWN if _across == Vector2.RIGHT else Vector2.RIGHT
	var room := ForemanBehavior.room_rect(enemy.room_cells)
	var lanes := runway_lanes(room, _across, enemy.target_ground(), _rng.randf() < 0.5)
	for i in lanes.size():
		var lane := lanes[i]
		var length := lane.size.x if _across == Vector2.RIGHT else lane.size.y
		var origin := lane.get_center() - _across * length / 2.0
		var row := RunwayLane.new()
		row.setup(enemy, _across, length, RUNWAY_WIDTH, i * RUNWAY_STEP, RUNWAY_WARNING)
		enemy.get_parent().add_child(row)
		row.global_position = origin
