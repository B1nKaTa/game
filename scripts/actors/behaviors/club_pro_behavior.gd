class_name ClubProBehavior
extends EnemyBehavior

# Chip, Club Pro. His chip shot lobs golf balls high onto warned spots around Grandpa, one right on him,
# each landing a moment after the last. His putt rolls a ball along a warned curve that breaks to one
# side, the whole curve marked before it rolls. He alternates the two, and calls Gophers up onto marked
# spots, never past five enemies in the room.
const CHIP_WINDUP := 0.6
const CHIPS := 4
const CHIP_RADIUS := 22.0
const CHIP_WARNING := 0.9
# Each ball lands this long after the one before.
const CHIP_STEP := 0.12
# How far from his feet a ball may land.
const CHIP_REACH := 80.0
const CHIP_TRIES := 40
const PUTT_WINDUP := 0.7
# The putt rolls this far past Grandpa, breaking this far to one side at its middle.
const PUTT_PAST := 80.0
const PUTT_BEND := 70.0
const PUTT_STEPS := 14
const WARNING_RADIUS := 34.0
# As short as the Reverend's rest, and shorter than Gloria's.
const COOLDOWN := 0.4
const KEEP_NEAR := 110.0
const FIRST_SUMMON := 5.0
const SUMMON_EVERY := 8.0
const SUMMON_COUNT := 2
const SUMMON_DISTANCE := 90.0
const SUMMON_SPREAD := 0.9
const MAX_ENEMIES := 5
const SAY_TIME := 1.0
const CHIP_LINES: Array[String] = ["Nice and soft...", "Up and over!", "Watch the follow-through."]
const PUTT_LINES: Array[String] = ["Read the break...", "It's all in the wrists.", "Never up, never in!"]

enum Attack { NONE, CHIP, PUTT }

var _telegraph := Telegraph.new()
var _attack := Attack.NONE
var _last := Attack.NONE
var _cooldown := 1.0
var _summon_timer := FIRST_SUMMON
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


# He alternates, so a putt always follows a chip and a chip a putt.
static func choose_attack(last: int, roll: float) -> int:
	if last == Attack.CHIP:
		return Attack.PUTT
	if last == Attack.PUTT:
		return Attack.CHIP
	return Attack.CHIP if roll < 0.5 else Attack.PUTT


# As many gophers as fit under the cap, at most SUMMON_COUNT, never a negative number.
static func summon_count(alive: int, cap: int) -> int:
	return clampi(cap - alive, 0, SUMMON_COUNT)


# Where the chipped balls land: one right on him, the rest near him, apart from each other and inside
# the room.
static func chip_spots(feet: Vector2, rng: RandomNumberGenerator, room := Rect2()) -> Array[Vector2]:
	var inside := func(point: Vector2) -> Vector2: return point.clamp(room.position, room.end) if room.has_area() else point
	var spots: Array[Vector2] = [inside.call(feet)]
	var tries := 0
	while spots.size() < CHIPS and tries < CHIP_TRIES:
		tries += 1
		var spot: Vector2 = inside.call(feet + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(CHIP_RADIUS * 2.0, CHIP_REACH))
		if _apart(spot, spots) and spot.distance_to(feet) <= CHIP_REACH:
			spots.append(spot)
	# A cramped corner: walk round him at set distances until every ball has a spot.
	for reach: float in [CHIP_REACH, CHIP_REACH * 0.75, CHIP_REACH * 0.55]:
		for step in 24:
			if spots.size() >= CHIPS:
				return spots
			var spot: Vector2 = inside.call(feet + Vector2.from_angle(TAU * step / 24.0) * reach)
			if _apart(spot, spots) and spot.distance_to(feet) <= CHIP_REACH:
				spots.append(spot)
	return spots


static func _apart(spot: Vector2, others: Array[Vector2]) -> bool:
	for other in others:
		if spot.distance_to(other) < CHIP_RADIUS * 2.0:
			return false
	return true


# The putt's curve: from him to a little past Grandpa, breaking bend to one side at its middle, as a
# list of points that leaves out the start. Given a room, every point is kept inside it.
static func putt_path(from: Vector2, to: Vector2, bend: float, room := Rect2()) -> Array[Vector2]:
	var way := from.direction_to(to)
	if way.is_zero_approx():
		way = Vector2.DOWN
	var end := to + way * PUTT_PAST
	var control := from.lerp(end, 0.5) + way.orthogonal() * bend * 2.0
	var points: Array[Vector2] = []
	for i in range(1, PUTT_STEPS + 1):
		var t := i / float(PUTT_STEPS)
		var point := from.lerp(control, t).lerp(control.lerp(end, t), t)
		if room.has_area():
			point = point.clamp(room.position, room.end)
		points.append(point)
	return points


func tick(enemy: Enemy, delta: float) -> void:
	_summon_timer -= delta
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_finish_attack()
		return
	_cooldown -= delta
	if not enemy.target_in_view():
		enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed * BossMoves.CATCH_UP_SPEED
		return
	if _summon_timer <= 0.0:
		_summon_timer = SUMMON_EVERY
		var count := summon_count(enemy.enemies_alive(), MAX_ENEMIES)
		if BossMoves.can_summon(enemy.enemies_alive(), MAX_ENEMIES) and count > 0:
			enemy.say("Gophers on the green!", SAY_TIME)
			enemy.request_summon_at(BossMoves.cutoff_points(enemy.target_ground(), enemy.target_motion(), enemy.global_position, count, SUMMON_DISTANCE, SUMMON_SPREAD), BossMoves.SUMMON_WARNING)
	if _cooldown <= 0.0:
		_begin(enemy, choose_attack(_last, _rng.randf()))
		return
	if enemy.distance_to_target() > KEEP_NEAR:
		enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed


func _begin(enemy: Enemy, attack: int) -> void:
	_attack = attack
	var feet := enemy.target_ground()
	var room := ForemanBehavior.room_rect(enemy.room_cells)
	match attack:
		Attack.CHIP:
			_telegraph.start(CHIP_WINDUP)
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say(CHIP_LINES[_rng.randi_range(0, CHIP_LINES.size() - 1)], SAY_TIME)
			# Every spot shows at once and fills for its own warning, so each one is read in time.
			var spots := chip_spots(feet, _rng, room)
			for i in spots.size():
				GolfBallLob.chip(enemy, spots[i], CHIP_RADIUS, CHIP_WARNING, i * CHIP_STEP)
		Attack.PUTT:
			_telegraph.start(PUTT_WINDUP)
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say(PUTT_LINES[_rng.randi_range(0, PUTT_LINES.size() - 1)], SAY_TIME)
			var bend := PUTT_BEND if _rng.randf() < 0.5 else -PUTT_BEND
			var putt := PuttRoll.new()
			putt.setup(enemy, enemy.global_position, putt_path(enemy.global_position, feet, bend, room), PUTT_WINDUP)
			enemy.get_parent().add_child(putt)
			putt.global_position = enemy.global_position


func _finish_attack() -> void:
	_last = _attack
	_cooldown = COOLDOWN
	# He waits while his chipped balls come down.
	if _attack == Attack.CHIP:
		_cooldown += CHIP_WARNING + (CHIPS - 1) * CHIP_STEP - CHIP_WINDUP
