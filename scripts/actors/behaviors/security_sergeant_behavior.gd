class_name SecuritySergeantBehavior
extends EnemyBehavior

# Sergeant Wanda, Airport Security. Her X-ray sweep sends a scanning beam across the whole room after
# a warning, and only the one marked safe spot, the inspection mat, is spared, so Grandpa must reach it
# or dodge through the beam. Her tray toss drops grey security trays onto warned spots around him, one
# after another. She calls Lost Luggage onto marked spots, never past five enemies in the room. She
# alternates her two attacks.
const XRAY_WINDUP := 0.6
# The beam shows where it starts for this long after her windup. Which way it stands, upright or
# across, changes each time.
const XRAY_WARNING := 1.2
const TRAY_WINDUP := 0.5
const TRAYS := 4
const TRAY_RADIUS := 24.0
const TRAY_WARNING := 0.9
const TRAY_STEP := 0.15
# How far from his feet a tray may land.
const TRAY_REACH := 80.0
const TRAY_TRIES := 40
const WARNING_RADIUS := 34.0
# The safe spot is picked this near him when there is one, so he can reach it in time.
const SAFE_NEAR := 120.0
# And never this near her own body, where Grandpa cannot stand.
const SAFE_OFF_BODY := 26.0
# A little shorter than the Reverend's 0.5, as she must be at least as hard as the third floor's.
const COOLDOWN := 0.45
const KEEP_NEAR := 110.0
const FIRST_SUMMON := 5.0
const SUMMON_EVERY := 10.0
const SUMMON_COUNT := 3
const SUMMON_DISTANCE := 100.0
const MAX_ENEMIES := 5
const SAY_TIME := 1.0
const XRAY_LINES: Array[String] = ["Step into the scanner.", "Arms up, please.", "Random screening!"]

enum Attack { NONE, XRAY, TRAYS }

var _telegraph := Telegraph.new()
var _attack := Attack.NONE
var _last := Attack.NONE
var _cooldown := 1.0
var _summon_timer := FIRST_SUMMON
var _along_x := false
var _safe_mark: SafeSpotMark
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


# She alternates, so trays always follow a sweep and a sweep the trays.
static func choose_attack(last: int, roll: float) -> int:
	if last == Attack.XRAY:
		return Attack.TRAYS
	if last == Attack.TRAYS:
		return Attack.XRAY
	return Attack.XRAY if roll < 0.5 else Attack.TRAYS


# As much Lost Luggage as fits under the cap, at most SUMMON_COUNT, never a negative number.
static func summon_count(alive: int, cap: int) -> int:
	return clampi(cap - alive, 0, SUMMON_COUNT)


# Where Grandpa can stand through a sweep: the middle of a cell of the room, near him when one is.
# is_open, when given, says which spots he can stand on.
static func xray_safe_spot(room_rect: Rect2, rng: RandomNumberGenerator, near := Vector2.INF, is_open := Callable()) -> Vector2:
	var tile := float(RoomBackdrop.TILE)
	var candidates: Array[Vector2] = []
	for row in floori(room_rect.size.y / tile):
		for column in floori(room_rect.size.x / tile):
			var spot := room_rect.position + Vector2(column + 0.5, row + 0.5) * tile
			if not is_open.is_valid() or is_open.call(spot):
				candidates.append(spot)
	if candidates.is_empty():
		return room_rect.get_center()
	if near == Vector2.INF:
		return candidates[rng.randi_range(0, candidates.size() - 1)]
	var close: Array[Vector2] = []
	var nearest := candidates[0]
	for spot in candidates:
		if spot.distance_to(near) <= SAFE_NEAR:
			close.append(spot)
		if spot.distance_to(near) < nearest.distance_to(near):
			nearest = spot
	if close.is_empty():
		return nearest
	return close[rng.randi_range(0, close.size() - 1)]


# How long the safe spot stays marked: through the warning and until the beam has crossed the room.
static func safe_mark_time(room_rect: Rect2, along_x: bool) -> float:
	return XRaySweep.duration(room_rect, along_x, XRAY_WARNING) + 0.2


# Where the trays land: one right under him, the rest near him, apart from each other and in the room.
static func tray_spots(feet: Vector2, rng: RandomNumberGenerator, room := Rect2()) -> Array[Vector2]:
	var inside := func(point: Vector2) -> Vector2: return point.clamp(room.position, room.end) if room.has_area() else point
	var spots: Array[Vector2] = [inside.call(feet)]
	var tries := 0
	while spots.size() < TRAYS and tries < TRAY_TRIES:
		tries += 1
		var spot: Vector2 = inside.call(feet + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(TRAY_RADIUS * 2.0, TRAY_REACH))
		if _apart(spot, spots) and spot.distance_to(feet) <= TRAY_REACH:
			spots.append(spot)
	# A cramped corner: walk round him at set distances until every tray has a spot.
	for reach: float in [TRAY_REACH, TRAY_REACH * 0.75, TRAY_REACH * 0.5]:
		for step in 24:
			if spots.size() >= TRAYS:
				return spots
			var spot: Vector2 = inside.call(feet + Vector2.from_angle(TAU * step / 24.0) * reach)
			if _apart(spot, spots) and spot.distance_to(feet) <= TRAY_REACH:
				spots.append(spot)
	return spots


static func _apart(spot: Vector2, others: Array[Vector2]) -> bool:
	for other in others:
		if spot.distance_to(other) < TRAY_RADIUS * 2.0:
			return false
	return true


func tick(enemy: Enemy, delta: float) -> void:
	_summon_timer -= delta
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_finish_attack(enemy)
		return
	_cooldown -= delta
	if not enemy.target_in_view():
		enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed * BossMoves.CATCH_UP_SPEED
		return
	if _summon_timer <= 0.0:
		_summon_timer = SUMMON_EVERY
		var count := summon_count(enemy.enemies_alive(), MAX_ENEMIES)
		if BossMoves.can_summon(enemy.enemies_alive(), MAX_ENEMIES) and count > 0:
			enemy.say("Unattended baggage!", SAY_TIME)
			enemy.request_summon_at(BossMoves.cutoff_points(enemy.target_ground(), enemy.target_motion(), enemy.global_position, count, SUMMON_DISTANCE, 1.0), BossMoves.SUMMON_WARNING)
	if _cooldown <= 0.0:
		_begin(enemy, choose_attack(_last, _rng.randf()))
		return
	if enemy.distance_to_target() > KEEP_NEAR:
		enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed


# A sweep that has not crossed yet never does once she falls, and its mat goes with it.
func on_killed(_enemy: Enemy) -> void:
	if is_instance_valid(_safe_mark):
		_safe_mark.queue_free()


func _begin(enemy: Enemy, attack: int) -> void:
	_attack = attack
	match attack:
		Attack.XRAY:
			_telegraph.start(XRAY_WINDUP)
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say(XRAY_LINES[_rng.randi_range(0, XRAY_LINES.size() - 1)], SAY_TIME)
			_sweep(enemy)
		Attack.TRAYS:
			_telegraph.start(TRAY_WINDUP)
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Trays out, please!", SAY_TIME)


func _finish_attack(enemy: Enemy) -> void:
	_last = _attack
	_cooldown = COOLDOWN
	match _attack:
		Attack.XRAY:
			# She waits while the beam crosses, so nothing else lands on the way to the mat.
			_cooldown += XRaySweep.duration(ForemanBehavior.room_rect(enemy.room_cells), _along_x, XRAY_WARNING)
		Attack.TRAYS:
			_toss_trays(enemy)
			_cooldown += TRAY_STEP * TRAYS


# The beam's warning and the mat go down at once, so the whole windup is time to reach the mat.
func _sweep(enemy: Enemy) -> void:
	_along_x = not _along_x
	var room := ForemanBehavior.room_rect(enemy.room_cells)
	var grid := enemy.walk_grid
	var body_at := enemy.global_position
	var keep_off := maxf(enemy.def.body_size.x, enemy.def.body_size.y) / 2.0 + SAFE_OFF_BODY
	var is_open := func(spot: Vector2) -> bool:
		return spot.distance_to(body_at) > keep_off and (grid == null or grid.is_open(WalkGrid.cell_of(spot)))
	var feet := enemy.target_ground()
	var safe := xray_safe_spot(room, _rng, feet, is_open)
	var sweep := XRaySweep.new()
	sweep.setup(enemy, room, _along_x, feet, safe, XRAY_WINDUP + XRAY_WARNING)
	enemy.get_parent().add_child(sweep)
	sweep.position = Vector2.ZERO
	_safe_mark = SafeSpotMark.new()
	_safe_mark.setup(safe_mark_time(room, _along_x) + XRAY_WINDUP)
	enemy.get_parent().add_child(_safe_mark)
	_safe_mark.global_position = safe


func _toss_trays(enemy: Enemy) -> void:
	var spots := tray_spots(enemy.target_ground(), _rng, ForemanBehavior.room_rect(enemy.room_cells))
	for i in spots.size():
		TerminalStrike.strike(enemy, spots[i], TRAY_RADIUS, TRAY_WARNING, i * TRAY_STEP, -1, TerminalStrike.LOOK_TRAY)
