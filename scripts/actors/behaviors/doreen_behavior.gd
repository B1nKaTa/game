class_name DoreenBehavior
extends EnemyBehavior

# Doreen, Executive Assistant. Her memo storm drops paper down three warned lanes across the room, one
# right on Grandpa and one each side with a gap between, and her hold music sends slow notes out from
# her along a warned spiral (see HoldMusic). She alternates the two, and every so often she calls a
# few Yes-Men onto marked spots, never past five enemies in the room.
const MEMO_WINDUP := 0.5
const MEMO_LANES := 3
const MEMO_LANE_WIDTH := 48.0
# The open floor left between two lanes, wide enough to stand in.
const MEMO_GAP := 40.0
const MEMO_WARNING := 1.0
const MEMO_STAGGER := 0.15
const MUSIC_WINDUP := 0.55
const MUSIC_ARMS := 3
const MUSIC_NOTES := 7
const MUSIC_EVERY := 0.15
const MUSIC_TURN := 0.3
const NOTE_SPEED := 90.0
const WARNING_RADIUS := 36.0
# As short as the Reverend's rest, the shortest of the third floor's mini bosses.
const COOLDOWN := 0.5
const KEEP_NEAR := 120.0
const FIRST_SUMMON := 5.0
const SUMMON_EVERY := 9.0
const SUMMON_COUNT := 3
const SUMMON_DISTANCE := 100.0
const SUMMON_SPREAD := 0.8
const MAX_ENEMIES := 5
const SAY_TIME := 1.0
const MEMO_LINES: Array[String] = ["Per my last memo!", "Circulating now!", "Please initial each page."]
const MUSIC_LINES: Array[String] = ["Please hold.", "Your call is important to us.", "Hold, please."]

enum Attack { NONE, MEMOS, MUSIC }

var _telegraph := Telegraph.new()
var _attack := Attack.NONE
var _last := Attack.NONE
var _cooldown := 1.0
var _summon_timer := FIRST_SUMMON
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


# She alternates, so hold music always follows a memo storm and a storm the music.
static func choose_attack(last: int, roll: float) -> int:
	if last == Attack.MEMOS:
		return Attack.MUSIC
	if last == Attack.MUSIC:
		return Attack.MEMOS
	return Attack.MEMOS if roll < 0.5 else Attack.MUSIC


# As many Yes-Men as fit under the cap, at most SUMMON_COUNT, never a negative number.
static func summon_count(alive: int, cap: int) -> int:
	return clampi(cap - alive, 0, SUMMON_COUNT)


# The storm's lanes, each running the whole height of the room when down is true, or its whole width
# otherwise: the middle one centred on Grandpa, the others a lane and a gap to each side. Every lane
# lies inside the room's floor; one that would cross a wall is moved in, and one with no room left
# is dropped, so the gaps between them always stay open floor.
static func memo_lanes(feet: Vector2, room: Rect2, down: bool) -> Array[Rect2]:
	var lanes: Array[Rect2] = []
	var low := room.position.x if down else room.position.y
	var high := room.end.x if down else room.end.y
	var across := feet.x if down else feet.y
	var pitch := MEMO_LANE_WIDTH + MEMO_GAP
	var middle := clampf(across, low + MEMO_LANE_WIDTH / 2.0, high - MEMO_LANE_WIDTH / 2.0)
	for i in MEMO_LANES:
		var offset := (i - (MEMO_LANES - 1) / 2.0) * pitch
		var center := middle + offset
		if center - MEMO_LANE_WIDTH / 2.0 < low - 0.01 or center + MEMO_LANE_WIDTH / 2.0 > high + 0.01:
			continue
		var start := center - MEMO_LANE_WIDTH / 2.0
		if down:
			lanes.append(Rect2(start, room.position.y, MEMO_LANE_WIDTH, room.size.y))
		else:
			lanes.append(Rect2(room.position.x, start, room.size.x, MEMO_LANE_WIDTH))
	return lanes


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
			enemy.say("Send in the yes-men.", SAY_TIME)
			enemy.request_summon_at(BossMoves.cutoff_points(enemy.target_ground(), enemy.target_motion(), enemy.global_position, count, SUMMON_DISTANCE, SUMMON_SPREAD), BossMoves.SUMMON_WARNING)
	if _cooldown <= 0.0:
		_begin(enemy, choose_attack(_last, _rng.randf()))
		return
	if enemy.distance_to_target() > KEEP_NEAR:
		enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed


func _begin(enemy: Enemy, attack: int) -> void:
	_attack = attack
	match attack:
		Attack.MEMOS:
			_telegraph.start(MEMO_WINDUP)
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say(MEMO_LINES[_rng.randi_range(0, MEMO_LINES.size() - 1)], SAY_TIME)
			var room := ForemanBehavior.room_rect(enemy.room_cells)
			var lanes := memo_lanes(enemy.target_ground(), room, _rng.randf() < 0.5)
			for i in lanes.size():
				var drop := LaneDrop.new()
				drop.setup(enemy, lanes[i], MEMO_WARNING, i * MEMO_STAGGER)
				enemy.get_parent().add_child(drop)
		Attack.MUSIC:
			_telegraph.start(MUSIC_WINDUP)
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say(MUSIC_LINES[_rng.randi_range(0, MUSIC_LINES.size() - 1)], SAY_TIME)
			var music := HoldMusic.new()
			music.setup(enemy, MUSIC_WINDUP, _rng.randf() * TAU, MUSIC_ARMS, MUSIC_NOTES, MUSIC_EVERY, MUSIC_TURN, NOTE_SPEED)
			enemy.get_parent().add_child(music)
			music.global_position = enemy.global_position


func _finish_attack() -> void:
	_last = _attack
	_cooldown = COOLDOWN
	match _attack:
		Attack.MEMOS:
			# She waits while the paper comes down.
			_cooldown += maxf(MEMO_WARNING + MEMO_STAGGER * (MEMO_LANES - 1) - MEMO_WINDUP, 0.0)
		Attack.MUSIC:
			_cooldown += HoldMusic.play_time(MUSIC_NOTES, MUSIC_EVERY)
