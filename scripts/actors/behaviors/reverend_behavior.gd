class_name ReverendBehavior
extends EnemyBehavior

# The Reverend, Officiant of Last Words. His eulogy drops words one after another onto warned spots in
# a line from him through Grandpa, his collection plate flies out down a warned lane and comes back
# along a marked curve, and he calls Weeping Mourners to the service on marked spots.
const EULOGY_WINDUP := 0.5
const WORDS := 6
const WORD_STEP := 0.18
const WORD_WARNING := 0.7
const WORD_RADIUS := 22.0
# The line runs this far past Grandpa, and never shorter than EULOGY_MIN.
const EULOGY_PAST := 60.0
const EULOGY_MIN := 140.0
const PLATE_WINDUP := 0.55
const PLATE_LENGTH := 180.0
const PLATE_BEND := 70.0
const PLATE_LANE_WIDTH := 24.0
const OUT_STEPS := 6
const BACK_STEPS := 10
const WARNING_RADIUS := 34.0
# A little shorter than Barbara's and Klaus's rests, as he must be at least as hard as they are.
const COOLDOWN := 0.6
const KEEP_NEAR := 110.0
const FIRST_SUMMON := 5.0
const SUMMON_EVERY := 9.0
const SUMMON_COUNT := 3
const SUMMON_DISTANCE := 100.0
const MAX_ENEMIES := 5
const SAY_TIME := 1.0
const EULOGY_LINES: Array[String] = ["Dearly beloved...", "Ashes to ashes...", "We are gathered..."]

enum Attack { NONE, EULOGY, PLATE }

var _telegraph := Telegraph.new()
var _attack := Attack.NONE
var _last := Attack.NONE
var _cooldown := 1.0
var _summon_timer := FIRST_SUMMON
var _spots: Array[Vector2] = []
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


# He alternates, so a plate always follows a eulogy and a eulogy a plate.
static func choose_attack(last: int, roll: float) -> int:
	if last == Attack.EULOGY:
		return Attack.PLATE
	if last == Attack.PLATE:
		return Attack.EULOGY
	return Attack.EULOGY if roll < 0.5 else Attack.PLATE


# Spots evenly spaced on the line from him through Grandpa, the last a little past him.
static func eulogy_spots(from: Vector2, to: Vector2, count: int) -> Array[Vector2]:
	var way := from.direction_to(to)
	if way.is_zero_approx():
		way = Vector2.DOWN
	var length := maxf(from.distance_to(to) + EULOGY_PAST, EULOGY_MIN)
	var spots: Array[Vector2] = []
	for i in count:
		spots.append(from + way * length * (i + 1) / float(count))
	return spots


# The plate's flight: straight out along aim for length, then back to the start along a curve that
# swings bend to one side. Given a room, every point is kept inside it.
static func plate_path(from: Vector2, aim: Vector2, length: float, bend: float, room := Rect2()) -> Array[Vector2]:
	var way := aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT
	var side := way.orthogonal()
	var tip := from + way * length
	var points: Array[Vector2] = []
	for i in range(1, OUT_STEPS + 1):
		points.append(from + way * length * i / float(OUT_STEPS))
	for i in range(1, BACK_STEPS + 1):
		var along := i / float(BACK_STEPS)
		points.append(tip.lerp(from, along) + side * bend * sin(along * PI))
	if room.has_area():
		for i in points.size():
			points[i] = points[i].clamp(room.position, room.end)
	return points


# As many mourners as fit under the cap, at most SUMMON_COUNT, never a negative number.
static func summon_count(alive: int, cap: int) -> int:
	return clampi(cap - alive, 0, SUMMON_COUNT)


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
			enemy.say("Let us mourn.", SAY_TIME)
			enemy.request_summon_at(BossMoves.cutoff_points(enemy.target_ground(), enemy.target_motion(), enemy.global_position, count, SUMMON_DISTANCE, 1.0), BossMoves.SUMMON_WARNING)
	if _cooldown <= 0.0:
		_begin(enemy, choose_attack(_last, _rng.randf()))
		return
	if enemy.distance_to_target() > KEEP_NEAR:
		enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed


func _begin(enemy: Enemy, attack: int) -> void:
	_attack = attack
	var feet := enemy.target_ground()
	match attack:
		Attack.EULOGY:
			_telegraph.start(EULOGY_WINDUP)
			_spots = eulogy_spots(enemy.global_position, feet, WORDS)
			var way := enemy.global_position.direction_to(_spots[-1])
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.set_warning_lane(way, enemy.global_position.distance_to(_spots[-1]), WORD_RADIUS * 2.0)
			enemy.say(EULOGY_LINES[_rng.randi_range(0, EULOGY_LINES.size() - 1)], SAY_TIME)
		Attack.PLATE:
			_telegraph.start(PLATE_WINDUP)
			var aim := enemy.global_position.direction_to(feet)
			var bend := PLATE_BEND if _rng.randf() < 0.5 else -PLATE_BEND
			var path := plate_path(enemy.global_position, aim, PLATE_LENGTH, bend, ForemanBehavior.room_rect(enemy.room_cells))
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.set_warning_lane(aim, PLATE_LENGTH, PLATE_LANE_WIDTH)
			var plate := CollectionPlate.new()
			plate.setup(enemy, enemy.global_position, path, PLATE_WINDUP)
			enemy.get_parent().add_child(plate)
			plate.global_position = enemy.global_position


func _finish_attack(enemy: Enemy) -> void:
	_last = _attack
	_cooldown = COOLDOWN
	match _attack:
		Attack.EULOGY:
			enemy.strike_line(_spots, WORD_RADIUS, WORD_WARNING, WORD_STEP)
			_cooldown += WORD_STEP * WORDS
		Attack.PLATE:
			# He waits while the plate is out, as it flies back to where he threw it.
			_cooldown += 0.6
