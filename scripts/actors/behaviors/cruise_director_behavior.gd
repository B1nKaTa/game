class_name CruiseDirectorBehavior
extends EnemyBehavior

# Lorraine, Cruise Director. She calls a conga line, whose rows of dancers cross the deck in warned
# lanes with one gap, marked where it lies nearest Grandpa. She sings a karaoke number that bursts out
# of her in a warned cone, and she tosses quoits onto warned spots, where each lies a while and slows
# him while he stands in it. She calls Early Bird Diners to the buffet on marked spots, never more than
# five enemies in the room, and they pay nothing.
const CONGA_WINDUP := 0.6
const CONGA_WARNING := 1.0
# The gap's mark keeps this far inside the gap's edges.
const GAP_MARGIN := 10.0
const KARAOKE_WINDUP := 0.8
const KARAOKE_ANGLE := 60.0
const KARAOKE_LENGTH := 150.0
const KARAOKE_START := KARAOKE_LENGTH + 20.0
const KARAOKE_OUTER := Color(1.0, 0.45, 0.85, 0.75)
const KARAOKE_INNER := Color(1.0, 0.92, 0.55, 0.85)
const QUOIT_WINDUP := 0.6
const QUOITS := 3
# The first quoit lands right on him and the rest this far out, at least QUOIT_APART from each other.
const QUOIT_SPREAD := 72.0
const QUOIT_APART := 50.0
const QUOIT_TRIES := 30
const WARNING_RADIUS := 34.0
# As short as the Reverend's rest, and shorter than Gloria's, so she is at least as hard as either.
const COOLDOWN := 0.5
const KEEP_NEAR := 110.0
const FIRST_SUMMON := 5.0
const SUMMON_EVERY := 10.0
const SUMMON_COUNT := 3
const SUMMON_DISTANCE := 100.0
const SUMMON_SPREAD := 0.9
const MAX_ENEMIES := 5
const SAY_TIME := 1.0

enum Attack { NONE, CONGA, KARAOKE, QUOITS }

var _telegraph := Telegraph.new()
var _attack := Attack.NONE
var _last := Attack.NONE
var _cooldown := 1.0
var _summon_timer := FIRST_SUMMON
var _gap := -1
var _across := Vector2.RIGHT
var _aim := Vector2.RIGHT
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


# Never the same number twice running. The karaoke cone only when he is near enough to hear it.
static func choose_attack(distance: float, last: int, roll: float) -> int:
	var options: Array[int] = [Attack.CONGA, Attack.QUOITS]
	if distance <= KARAOKE_START:
		options.append(Attack.KARAOKE)
	if options.size() > 1:
		options.erase(last)
	return options[mini(int(roll * options.size()), options.size() - 1)]


# As many diners as fit under the cap, at most SUMMON_COUNT, never a negative number.
static func summon_count(alive: int, cap: int) -> int:
	return clampi(cap - alive, 0, SUMMON_COUNT)


# Where the quoits land: the first on his feet, the rest around him and apart, all inside the room.
static func quoit_spots(feet: Vector2, count: int, rng: RandomNumberGenerator, room := Rect2()) -> Array[Vector2]:
	var inner := room.grow(-QuoitRing.RADIUS) if room.has_area() else Rect2()
	var spots: Array[Vector2] = [_inside(feet, inner)]
	var tries := 0
	while spots.size() < count and tries < QUOIT_TRIES * count:
		tries += 1
		var spot := _inside(feet + Vector2.from_angle(rng.randf() * TAU) * QUOIT_SPREAD, inner)
		var apart := true
		for other in spots:
			if other.distance_to(spot) < QUOIT_APART:
				apart = false
				break
		if apart:
			spots.append(spot)
	return spots


static func _inside(point: Vector2, room: Rect2) -> Vector2:
	return point.clamp(room.position, room.end) if room.has_area() else point


# Where the gap of a conga line is marked: on the gap's lane, level with Grandpa.
static func gap_spot(gap: Rect2, feet: Vector2) -> Vector2:
	var inner := gap.grow(-GAP_MARGIN) if gap.size.x > GAP_MARGIN * 2.0 and gap.size.y > GAP_MARGIN * 2.0 else gap
	return feet.clamp(inner.position, inner.end)


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
			enemy.say("Buffet's open, folks!", SAY_TIME)
			enemy.request_summon_at(BossMoves.cutoff_points(enemy.target_ground(), enemy.target_motion(), enemy.global_position, count, SUMMON_DISTANCE, SUMMON_SPREAD), BossMoves.SUMMON_WARNING)
	if _cooldown <= 0.0:
		_begin(enemy, choose_attack(enemy.distance_to_target(), _last, _rng.randf()))
		return
	if enemy.distance_to_target() > KEEP_NEAR:
		enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed


func _begin(enemy: Enemy, attack: int) -> void:
	_attack = attack
	match attack:
		Attack.CONGA:
			_telegraph.start(CONGA_WINDUP)
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Everybody conga!", SAY_TIME)
		Attack.KARAOKE:
			_telegraph.start(KARAOKE_WINDUP)
			_aim = enemy.direction_to_target()
			enemy.set_warning(_telegraph, WARNING_RADIUS * 0.6)
			enemy.set_warning_cone(_aim, KARAOKE_LENGTH, KARAOKE_ANGLE)
			enemy.say("Hit it, maestro!", SAY_TIME)
		Attack.QUOITS:
			_telegraph.start(QUOIT_WINDUP)
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Ringers, everyone!", SAY_TIME)
			_toss_quoits(enemy)


func _finish_attack(enemy: Enemy) -> void:
	_last = _attack
	_cooldown = COOLDOWN
	match _attack:
		Attack.CONGA:
			_dance(enemy)
			_cooldown += CONGA_WARNING
		Attack.KARAOKE:
			var song := FlameBurst.new()
			song.setup(_aim, KARAOKE_LENGTH, KARAOKE_ANGLE)
			song.tint(KARAOKE_OUTER, KARAOKE_INNER)
			enemy.get_parent().add_child(song)
			song.global_position = enemy.global_position
			if ChiefStokerBehavior.in_cone(enemy.global_position, _aim, KARAOKE_ANGLE, KARAOKE_LENGTH, enemy.target_ground()):
				enemy.hit_target(enemy.def.damage)
		Attack.QUOITS:
			# She waits while the quoits come down.
			_cooldown += maxf(QuoitRing.WARNING - QUOIT_WINDUP, 0.0)


# The quoits' spots are marked at once, under and around him, each filling for its own warning.
func _toss_quoits(enemy: Enemy) -> void:
	var room := ForemanBehavior.room_rect(enemy.room_cells)
	for spot in quoit_spots(enemy.target_ground(), QUOITS, _rng, room):
		if enemy.open_ground.is_valid() and not enemy.open_ground.call(spot):
			continue
		var quoit := QuoitRing.new()
		quoit.setup(enemy, QuoitRing.WARNING + QUOIT_WINDUP)
		enemy.get_parent().add_child(quoit)
		quoit.global_position = spot


# Rows of dancers cross the room around him in the lanes the Mortimer procession uses: every slot but
# one dances, the gap moves each time and the lanes turn each time. The gap is marked where he can
# reach it soonest.
func _dance(enemy: Enemy) -> void:
	_across = Vector2.DOWN if _across == Vector2.RIGHT else Vector2.RIGHT
	_gap = FuneralDirectorBehavior.next_gap(_gap, _rng)
	var room := ForemanBehavior.room_rect(enemy.room_cells)
	var feet := enemy.target_ground()
	var way := _across if _rng.randf() < 0.5 else -_across
	for lane in FuneralDirectorBehavior.procession_lanes(room, _across, _gap, feet):
		var length := lane.size.x if _across == Vector2.RIGHT else lane.size.y
		var row := DeckLane.new()
		row.setup(enemy, way, length, FuneralDirectorBehavior.LANE_WIDTH, CONGA_WARNING, DeckLane.LOOK_CONGA)
		enemy.get_parent().add_child(row)
		row.global_position = lane.get_center() - way * length / 2.0
	var gap := FuneralDirectorBehavior.procession_slot(room, _across, _gap, feet)
	var spot := gap_spot(gap, feet)
	if enemy.walk_grid == null or enemy.walk_grid.is_open(WalkGrid.cell_of(spot)):
		var mark := SafeSpotMark.new()
		mark.setup(CONGA_WARNING + room.size.length() / DeckLane.CONGA_SPEED)
		enemy.get_parent().add_child(mark)
		mark.global_position = spot
