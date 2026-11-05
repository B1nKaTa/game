class_name HeadOfDeparturesBehavior
extends EnemyBehavior

# Augustine, Head of Departures, the hardest boss but the Chairman, because his attacks overlap the
# queue barriers. His runway lights light warned lanes one after another across the room, and he runs
# them while the barriers are up, so routes close as lanes light: he picks the pattern from the ones
# that still leave Grandpa a way out (OverlapRoute counts every rope as up), and a green mark shows a
# spot he can reach that stays safe. While the lanes run he may change the gate, every barrier in the
# room rising or dropping at once after the barriers' own chime, and his boarding stamp always follows
# a pattern: the one attack that costs three pills, its warning shown whole for its 1.2 s with a second
# ring and the stamp's growing shadow, never put where it would take the last way out. Below half
# health he calls Tour Groups, never past five enemies in the room, the barriers cycle twice as fast,
# and the stamp follows every pattern without a rest.
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
# When no spot for the stamp leaves a way out, he waits this long and tries again.
const STAMP_RETRY := 0.15

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
# The runway pattern lighting now, how long until its last lane is out, and its green mark.
var _lanes: Array = []
var _runway_left := 0.0
var _mark: SafeSpotMark
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


# The stamp follows every runway pattern, in both phases. Nothing else chains.
static func followup(attack: int, _phase_two: bool) -> int:
	if attack == Attack.RUNWAY:
		return Attack.STAMP
	return Attack.NONE


# In the second phase the stamp follows the pattern without a rest.
static func rest_after_runway(phase_two: bool) -> float:
	return 0.0 if phase_two else BASE_COOLDOWN


# With no barriers in the room there is no gate change: the runway lights stand in for it. With
# ropes up or chiming he lights the runway, so the lanes run while they stand. While a pattern runs
# he changes the gate when it is due, and stamps otherwise.
static func choose_attack(last: int, has_barriers: bool, roll: float, ropes_up := false, running := false) -> int:
	if running:
		return Attack.GATE if has_barriers else Attack.STAMP
	if ropes_up and last != Attack.RUNWAY:
		return Attack.RUNWAY
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


# How long a whole pattern lasts, from the lanes' first warning to the last one going out.
static func runway_time() -> float:
	return runway_light_time(RUNWAY_LANES - 1) + RunwayLane.LIT_TIME


# When each lane of a fresh pattern is lit, in the order they light.
static func runway_windows(elapsed := 0.0) -> Array[Vector2]:
	var windows: Array[Vector2] = []
	for i in RUNWAY_LANES:
		var lights := runway_light_time(i) - elapsed
		windows.append(Vector2(lights, lights + RunwayLane.LIT_TIME))
	return windows


# The floor of a pattern for working out a way out: each lane lit in its window, every rope of the
# room counted as up the whole time (the room's timer or a gate change may raise any of them), his
# body in the way and closed cells.
static func runway_route(room: Rect2, lanes: Array[Rect2], windows: Array[Vector2], ropes: Array[Rect2], body := Rect2(), is_open := Callable()) -> OverlapRoute:
	var route := OverlapRoute.new(room)
	for i in lanes.size():
		if windows[i].y >= 0.0:
			route.add_rect(lanes[i], windows[i].x, windows[i].y)
	for rope in ropes:
		route.add_block(rope)
	if body.has_area():
		route.add_block(body)
	route.set_open(is_open)
	return route


# A mark may not go on his body or just beside it.
static func keep_off_body(body: Rect2) -> Callable:
	var avoid := body.grow(SafeSpotMark.RADIUS)
	return func(spot: Vector2) -> bool: return avoid.has_area() and avoid.has_point(spot)


# The pattern to light: across the preferred way first, centred on his feet first, then moved across
# a lane at a time and the other way round, until one leaves him a way out. Moved far enough the band
# misses him and standing still is safe, so one always does in a room the size of his. Returns
# {direction, reverse, center, mark}, with "direction" Vector2.ZERO when none works.
static func runway_plan(room: Rect2, feet: Vector2, prefer: Vector2, reverse_first: bool, ropes: Array[Rect2], body := Rect2(), is_open := Callable()) -> Dictionary:
	var other := Vector2.DOWN if prefer == Vector2.RIGHT else Vector2.RIGHT
	var keep_off := keep_off_body(body)
	for direction: Vector2 in [prefer, other]:
		var axis := Vector2(0, 1) if direction == Vector2.RIGHT else Vector2(1, 0)
		for shift: float in [0.0, 1.0, -1.0, 2.0, -2.0, 3.0, -3.0, 4.0, -4.0, 5.0, -5.0]:
			var center := feet + axis * shift * RUNWAY_WIDTH
			for reverse: bool in [reverse_first, not reverse_first]:
				var lanes := runway_lanes(room, direction, center, reverse)
				var out := runway_route(room, lanes, runway_windows(), ropes, body, is_open).escape(feet, keep_off)
				if out["safe"]:
					var mark: Vector2 = out["pure"] if out["pure"] != Vector2.INF else out["haven"]
					return {"direction": direction, "reverse": reverse, "center": center, "mark": mark}
	return {"direction": Vector2.ZERO, "reverse": false, "center": feet, "mark": Vector2.INF}


# Where the stamp falls while a pattern runs, and where the mark moves: on his feet when that still
# leaves him a way out, otherwise a little off. {spot, mark}, both INF when no spot works.
static func stamp_plan(route: OverlapRoute, feet: Vector2, body := Rect2(), open_at := Callable()) -> Dictionary:
	return route.strike_plan(feet, STAMP_RADIUS, STAMP_WINDUP, open_at, keep_off_body(body))


func tick(enemy: Enemy, delta: float) -> void:
	var phase_two := is_phase_two(enemy.hp, enemy.max_hp())
	if phase_two and not _phase_two_seen:
		_enter_phase_two(enemy)
	_since_gate += delta
	_runway_left = maxf(_runway_left - delta, 0.0)
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
			var gate_due := _has_barriers(enemy) and _since_gate >= GATE_EVERY
			attack = choose_attack(_last, gate_due, _rng.randf(), _ropes_up(enemy), _running())
		_next = Attack.NONE
		_begin(enemy, attack, phase_two)
		return
	# He stands still while his lanes light, so the mark is never under him.
	if not _running() and enemy.distance_to_target() > KEEP_NEAR:
		enemy.desired_velocity = enemy.chase_direction() * speed


func _running() -> bool:
	return _runway_left > 0.0


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


func _ropes_up(enemy: Enemy) -> bool:
	for barrier in _barriers(enemy):
		if is_instance_valid(barrier) and (barrier.is_up() or barrier.is_chiming()):
			return true
	return false


func _ropes(enemy: Enemy) -> Array[Rect2]:
	var ropes: Array[Rect2] = []
	for barrier in _barriers(enemy):
		if is_instance_valid(barrier):
			ropes.append(QueueBarrier.rope_rect(barrier.global_position, barrier.runs_across()))
	return ropes


func _open_cells(enemy: Enemy) -> Callable:
	var grid := enemy.walk_grid
	if grid == null:
		return Callable()
	return func(spot: Vector2) -> bool: return grid.is_open(WalkGrid.cell_of(spot))


# The pattern as it lights this moment, with each lane's own time left.
func _live_route(enemy: Enemy) -> OverlapRoute:
	var lanes: Array[Rect2] = []
	var windows: Array[Vector2] = []
	for lane in _lanes:
		if is_instance_valid(lane):
			lanes.append(lane.lane_rect())
			windows.append(lane.danger_window())
	return runway_route(ForemanBehavior.room_rect(enemy.room_cells), lanes, windows, _ropes(enemy), enemy.body_rect(), _open_cells(enemy))


func _begin(enemy: Enemy, attack: int, phase_two: bool) -> void:
	if attack == Attack.GATE and not _has_barriers(enemy):
		attack = Attack.STAMP if _running() else Attack.RUNWAY
	var stamp_at := enemy.target_ground()
	if attack == Attack.STAMP and _running():
		var plan := stamp_plan(_live_route(enemy), enemy.target_ground(), enemy.body_rect(), enemy.open_ground)
		if plan["spot"] == Vector2.INF:
			# No spot leaves him a way out while the lanes light, so the stamp waits.
			_next = Attack.STAMP
			_cooldown = STAMP_RETRY
			return
		stamp_at = plan["spot"]
		_place_mark(enemy, plan["mark"], maxf(_runway_left, STAMP_WINDUP + 0.3))
	_attack = attack
	_telegraph.start(windup_for(attack, phase_two))
	match attack:
		Attack.STAMP:
			# The windup on him shows whole too, and the stamp's spot is locked at once.
			enemy.set_warning(_telegraph, WARNING_RADIUS, STAMP_SHOWN_WHOLE)
			enemy.say("Stamped and departed!", SAY_TIME)
			TerminalStrike.strike(enemy, stamp_at, STAMP_RADIUS, STAMP_WINDUP, 0.0, STAMP_DAMAGE, TerminalStrike.LOOK_STAMP)
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
			if _light_runway(enemy):
				_cooldown = rest_after_runway(phase_two)
				_last = Attack.RUNWAY
				_next = followup(Attack.RUNWAY, phase_two)
				return
		Attack.GATE:
			_since_gate = 0.0
			var barriers := _barriers(enemy)
			var up := 0
			for barrier in barriers:
				up += 1 if barrier.is_up() else 0
			var kind := gate_kind(up, barriers.size())
			for barrier in barriers:
				barrier.take_control(kind)
			# While lanes light he goes straight on to the stamp; otherwise he waits out the chime.
			busy = 0.0 if _running() else QueueBarrier.CHIME
	_cooldown = cooldown_for(phase_two) + busy
	_last = _attack
	_next = followup(_attack, phase_two)


# The lanes run across the way to him, turning each time, and light from one end of the band, in the
# first pattern that leaves him a way out. False when none does, and then nothing lights.
func _light_runway(enemy: Enemy) -> bool:
	_across = Vector2.DOWN if _across == Vector2.RIGHT else Vector2.RIGHT
	var room := ForemanBehavior.room_rect(enemy.room_cells)
	var plan := runway_plan(room, enemy.target_ground(), _across, _rng.randf() < 0.5, _ropes(enemy), enemy.body_rect(), _open_cells(enemy))
	var direction: Vector2 = plan["direction"]
	if direction == Vector2.ZERO:
		return false
	_across = direction
	var lanes := runway_lanes(room, direction, plan["center"], plan["reverse"])
	_lanes.clear()
	for i in lanes.size():
		var lane := lanes[i]
		var length := lane.size.x if direction == Vector2.RIGHT else lane.size.y
		var origin := lane.get_center() - direction * length / 2.0
		var row := RunwayLane.new()
		row.setup(enemy, direction, length, RUNWAY_WIDTH, i * RUNWAY_STEP, RUNWAY_WARNING)
		enemy.get_parent().add_child(row)
		row.global_position = origin
		_lanes.append(row)
	_runway_left = runway_time()
	_place_mark(enemy, plan["mark"], _runway_left)
	return true


func _place_mark(enemy: Enemy, spot: Vector2, seconds: float) -> void:
	if spot == Vector2.INF:
		return
	if not is_instance_valid(_mark):
		_mark = SafeSpotMark.new()
		_mark.setup(seconds)
		enemy.get_parent().add_child(_mark)
	else:
		_mark.setup(maxf(_mark.time_left(), seconds))
	_mark.global_position = spot
