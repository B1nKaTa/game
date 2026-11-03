class_name ForemanBehavior
extends EnemyBehavior

# Runs the shift with a hammer: a slam around him that sends a shockwave ring rolling outward,
# steam lines that blow across the room in parallel lanes with one lane always left clear, and
# Stokers called in on marked spots.
const SLAM_RANGE := 60.0
const SLAM_WINDUP := 0.7
const RING_FROM := 60.0
const RING_TO := 140.0
const RING_TIME := 0.6
const RING_WIDTH := 14.0
# Close enough that the ring will reach him, with room to spare.
const SLAM_START := RING_TO - 20.0
const STEAM_WINDUP := 0.35
const STEAM_WARNING := 0.9
const LANES := 4
const LANE_WIDTH := 36.0
const WARNING_RADIUS := 34.0
const COOLDOWN := 0.825
const KEEP_NEAR := 90.0
const FIRST_SUMMON := 6.0
const SUMMON_EVERY := 12.0
const SUMMON_COUNT := 2
const SUMMON_DISTANCE := 100.0
const MAX_ENEMIES := 5
const SAY_TIME := 1.0

enum Attack { NONE, SLAM, STEAM }

var _telegraph := Telegraph.new()
var _attack := Attack.NONE
var _last := Attack.NONE
var _cooldown := 1.0
var _summon_timer := FIRST_SUMMON
var _gap := -1
var _across := Vector2.RIGHT
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


# Within the ring's reach he slams, but never twice running. Further off he lets off steam.
static func choose_attack(distance: float, last: int) -> int:
	if distance <= SLAM_START and last != Attack.SLAM:
		return Attack.SLAM
	return Attack.STEAM


static func shockwave_hits(center: Vector2, radius_now: float, width: float, point: Vector2) -> bool:
	return Shockwave.band_hits(center, radius_now, width, point)


# Parallel lanes running the length of the room along direction, side by side across it around
# center, every slot but the gap. The band of slots is moved to lie inside the room.
static func steam_lanes(room_rect: Rect2, direction: Vector2, gap_index: int, center: Vector2) -> Array[Rect2]:
	var lanes: Array[Rect2] = []
	var band := LANE_WIDTH * LANES
	var horizontal := absf(direction.x) >= absf(direction.y)
	var low := room_rect.position.y if horizontal else room_rect.position.x
	var high := room_rect.end.y if horizontal else room_rect.end.x
	var middle := center.y if horizontal else center.x
	var start := clampf(middle - band / 2.0, low, maxf(high - band, low))
	for slot in LANES:
		if slot == gap_index:
			continue
		var at := start + slot * LANE_WIDTH
		if horizontal:
			lanes.append(Rect2(room_rect.position.x, at, room_rect.size.x, LANE_WIDTH))
		else:
			lanes.append(Rect2(at, room_rect.position.y, LANE_WIDTH, room_rect.size.y))
	return lanes


# Any slot but the last gap, so standing where it was clear never works twice.
static func next_gap(last: int, rng: RandomNumberGenerator) -> int:
	if last < 0 or last >= LANES:
		return rng.randi_range(0, LANES - 1)
	var gap := rng.randi_range(0, LANES - 2)
	return gap + 1 if gap >= last else gap


static func room_rect(cells: Vector2i) -> Rect2:
	var tile := float(RoomBackdrop.TILE)
	return Rect2(tile, tile, (cells.x - 2) * tile, (cells.y - 2) * tile)


func tick(enemy: Enemy, delta: float) -> void:
	_summon_timer -= delta
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_finish_attack(enemy)
		return
	_cooldown -= delta
	var distance := enemy.distance_to_target()
	if not enemy.target_in_view():
		enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed * BossMoves.CATCH_UP_SPEED
		return
	if _summon_timer <= 0.0:
		_summon_timer = SUMMON_EVERY
		if BossMoves.can_summon(enemy.enemies_alive(), MAX_ENEMIES):
			enemy.request_summon_at(BossMoves.cutoff_points(enemy.target_ground(), enemy.target_motion(), enemy.global_position, SUMMON_COUNT, SUMMON_DISTANCE, 1.2), BossMoves.SUMMON_WARNING)
	if _cooldown <= 0.0:
		_begin(enemy, choose_attack(distance, _last))
		return
	if distance > KEEP_NEAR:
		enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed


func _begin(enemy: Enemy, attack: int) -> void:
	_attack = attack
	match attack:
		Attack.SLAM:
			_telegraph.start(SLAM_WINDUP)
			enemy.set_warning(_telegraph, SLAM_RANGE)
			var ring := Shockwave.new()
			ring.setup(enemy, RING_FROM, RING_TO, RING_TIME, RING_WIDTH, SLAM_WINDUP)
			enemy.get_parent().add_child(ring)
			ring.global_position = enemy.global_position
		Attack.STEAM:
			_telegraph.start(STEAM_WINDUP)
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Pressure's up!", SAY_TIME)


func _finish_attack(enemy: Enemy) -> void:
	_last = _attack
	_cooldown = COOLDOWN
	match _attack:
		Attack.SLAM:
			enemy.smash(enemy.global_position, SLAM_RANGE)
			if enemy.distance_to_target() <= SLAM_RANGE:
				enemy.hit_target(enemy.def.damage)
			_cooldown += RING_TIME
		Attack.STEAM:
			# Lanes run across the way to him, turning each time, so the clear lane is never the same line.
			_across = Vector2.DOWN if _across == Vector2.RIGHT else Vector2.RIGHT
			_gap = next_gap(_gap, _rng)
			var lanes := steam_lanes(room_rect(enemy.room_cells), _across, _gap, enemy.target_ground())
			for lane in lanes:
				var jet := SteamJet.new()
				var length := lane.size.x if _across == Vector2.RIGHT else lane.size.y
				var origin := lane.position + (Vector2(0.0, lane.size.y / 2.0) if _across == Vector2.RIGHT else Vector2(lane.size.x / 2.0, 0.0))
				jet.setup(enemy, _across, length, LANE_WIDTH, STEAM_WARNING)
				enemy.get_parent().add_child(jet)
				jet.global_position = origin
			_cooldown += STEAM_WARNING
