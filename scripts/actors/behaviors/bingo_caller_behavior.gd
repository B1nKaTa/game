class_name BingoCallerBehavior
extends EnemyBehavior

# Keeps her distance and calls numbers: each call marks spots close around Grandpa that strike
# after a delay. In a crowded room she marks fewer, so the room never fills with marks.
const KEEP_AWAY := 120.0
const TOO_FAR := 220.0
const CALL_EVERY := 3.5
const FIRST_CALL := 1.6
const CALL_WINDUP := 0.35
const WARNING_RADIUS := 16.0
const MARKS := 3
const CROWDED_MARKS := 2
const CROWD := 2
const MARK_REACH := 48.0
const MARK_GAP := 28.0
const MARK_RADIUS := 18.0
const MARK_WARNING := 0.9
const SAY_TIME := 1.2
const LETTERS := "BINGO"

var _telegraph := Telegraph.new()
var _wait := FIRST_CALL
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


static func mark_count(others_alive: int) -> int:
	return CROWDED_MARKS if others_alive >= CROWD else MARKS


# Spots no further than MARK_REACH from him and at least MARK_GAP apart. When chance finds no such
# set, they stand evenly around him instead, which always fits.
static func bingo_marks(target: Vector2, count: int, rng: RandomNumberGenerator) -> Array[Vector2]:
	var marks: Array[Vector2] = []
	for attempt in 200:
		if marks.size() >= count:
			return marks
		var spot := target + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * MARK_REACH
		var apart := true
		for other in marks:
			apart = apart and other.distance_to(spot) >= MARK_GAP
		if apart:
			marks.append(spot)
	marks.clear()
	var start := rng.randf() * TAU
	for i in count:
		marks.append(target + Vector2.from_angle(start + TAU * i / float(count)) * MARK_REACH * 0.65)
	return marks


static func call_name(rng: RandomNumberGenerator) -> String:
	var column := rng.randi_range(0, LETTERS.length() - 1)
	return "%s-%d!" % [LETTERS[column], column * 15 + rng.randi_range(1, 15)]


func tick(enemy: Enemy, delta: float) -> void:
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_call(enemy)
		return
	_wait -= delta
	var distance := enemy.distance_to_target()
	if distance < KEEP_AWAY:
		enemy.desired_velocity = -enemy.direction_to_target() * enemy.def.speed
	elif distance > TOO_FAR:
		enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed
	if _wait <= 0.0 and enemy.target_in_view():
		_telegraph.start(CALL_WINDUP)
		enemy.set_warning(_telegraph, WARNING_RADIUS, true)
		enemy.say(call_name(_rng), SAY_TIME)


func _call(enemy: Enemy) -> void:
	_wait = CALL_EVERY
	for spot in bingo_marks(enemy.target_ground(), mark_count(enemy.enemies_alive() - 1), _rng):
		enemy.strike_ground(spot, MARK_RADIUS, MARK_WARNING)
