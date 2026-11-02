extends EnemyBehavior

# Works the ground rather than chasing: a spade slam up close, a furrow that tears along a line
# toward Grandpa, clippings that land on and around him, and Plot Holders marked on the ground.
const SLAM_RANGE := 70.0
const SLAM_START := 60.0
const SLAM_WINDUP := 0.7
const FURROW_WINDUP := 0.65
const FURROW_SPOTS := 8
const FURROW_SPACING := 42.0
const FURROW_RADIUS := 26.0
const FURROW_WARNING := 0.5
const FURROW_STEP := 0.09
const CLIPPINGS_WINDUP := 0.6
const CLIPPINGS_COUNT := 4
const CLIPPINGS_DISTANCE := 72.0
const CLIPPINGS_RADIUS := 32.0
const CLIPPINGS_WARNING := 0.8
const LANE_WIDTH := 52.0
const WARNING_RADIUS := 34.0
const COOLDOWN := 1.05
const FIRST_SUMMON := 6.0
const SUMMON_EVERY := 11.0
const SUMMON_COUNT := 2
const SUMMON_DISTANCE := 110.0
const MAX_ENEMIES := 5

enum Attack { NONE, SLAM, FURROW, CLIPPINGS }

var _telegraph := Telegraph.new()
var _attack := Attack.NONE
var _last := Attack.NONE
var _cooldown := 1.0
var _summon_timer := FIRST_SUMMON


static func choose_attack(near: bool, last: int, roll: float) -> int:
	if near:
		return Attack.SLAM
	if last == Attack.FURROW:
		return Attack.CLIPPINGS
	if last == Attack.CLIPPINGS:
		return Attack.FURROW
	return Attack.FURROW if roll < 0.5 else Attack.CLIPPINGS


static func furrow_points(from: Vector2, direction: Vector2, count: int, spacing: float) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for i in count:
		points.append(from + direction * spacing * (i + 1))
	return points


# The first lands on him, and the rest around him, leaving ways out between them.
static func scatter_points(center: Vector2, count: int, distance: float, start_angle: float) -> Array[Vector2]:
	var points: Array[Vector2] = [center]
	for i in count - 1:
		points.append(center + Vector2.from_angle(start_angle + TAU * i / float(count - 1)) * distance)
	return points


func tick(enemy: Enemy, delta: float) -> void:
	_summon_timer -= delta
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_finish_attack(enemy)
		return
	_cooldown -= delta
	var offset := enemy.target.global_position - enemy.global_position
	# Far off in a big room it walks over, and starts nothing he cannot see.
	if not BossMoves.in_view(offset):
		enemy.desired_velocity = offset.normalized() * enemy.def.speed * BossMoves.CATCH_UP_SPEED
		return
	if _summon_timer <= 0.0:
		_summon_timer = SUMMON_EVERY
		if BossMoves.can_summon(enemy.enemies_alive(), MAX_ENEMIES):
			enemy.request_summon_at(scatter_points(enemy.target_ground(), SUMMON_COUNT + 1, SUMMON_DISTANCE, randf() * TAU).slice(1), BossMoves.SUMMON_WARNING)
	var near := offset.length() <= SLAM_START
	if _cooldown <= 0.0:
		_begin(enemy, choose_attack(near, _last, randf()))
		return
	if not near:
		enemy.desired_velocity = offset.normalized() * enemy.def.speed


func _begin(enemy: Enemy, attack: int) -> void:
	_attack = attack
	match attack:
		Attack.SLAM:
			_telegraph.start(SLAM_WINDUP)
			enemy.set_warning(_telegraph, SLAM_RANGE)
		Attack.FURROW:
			_telegraph.start(FURROW_WINDUP)
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.set_warning_lane(enemy.direction_to_target(), FURROW_SPOTS * FURROW_SPACING, LANE_WIDTH)
		Attack.CLIPPINGS:
			_telegraph.start(CLIPPINGS_WINDUP)
			enemy.set_warning(_telegraph, WARNING_RADIUS)


func _finish_attack(enemy: Enemy) -> void:
	_last = _attack
	_cooldown = COOLDOWN
	match _attack:
		Attack.SLAM:
			enemy.smash(enemy.global_position, SLAM_RANGE)
			if enemy.distance_to_target() <= SLAM_RANGE:
				enemy.hit_target(enemy.def.damage)
		Attack.FURROW:
			var points := furrow_points(enemy.global_position, enemy.warning_lane_direction(), FURROW_SPOTS, FURROW_SPACING)
			enemy.strike_line(points, FURROW_RADIUS, FURROW_WARNING, FURROW_STEP)
			_cooldown += FURROW_STEP * FURROW_SPOTS
		Attack.CLIPPINGS:
			for point in scatter_points(enemy.target_ground(), CLIPPINGS_COUNT, CLIPPINGS_DISTANCE, randf() * TAU):
				enemy.strike_ground(point, CLIPPINGS_RADIUS, CLIPPINGS_WARNING)
