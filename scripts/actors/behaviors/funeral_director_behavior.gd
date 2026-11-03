class_name FuneralDirectorBehavior
extends EnemyBehavior

# Mortimer Grimsby, Funeral Director. He slams a coffin down on a warned spot under Grandpa, the one
# attack that costs three pills, so its warning always shows whole, with a second ring and a growing
# shadow. He sends a procession of pallbearers marching across the room in warned lanes with one gap,
# sprays embalming fluid in a warned cone that slows, and plays every organ pipe of his room at once,
# each ring reaching just short of one safe spot. Below half health he climbs into a coffin, and
# between his other attacks it charges down a warned lane, breaking props and stopping short of walls.
const CASKET_WINDUP := 1.2
const CASKET_RADIUS := 44.0
const CASKET_DAMAGE := Enemy.HEAVIEST_DAMAGE
# The casket's warning shows for all of its windup, whatever the player's warning stat.
const CASKET_SHOWN_WHOLE := true
const PROCESSION_WINDUP := 0.6
const PROCESSION_WARNING := 1.0
# Lanes side by side across the way they march: every slot but the gap marches.
const SLOTS := 5
const LANE_WIDTH := 40.0
const SPRAY_WINDUP := 0.9
const SPRAY_ANGLE := 50.0
const SPRAY_LENGTH := 120.0
const SPRAY_START := SPRAY_LENGTH + 10.0
const SPRAY_SLOW := 0.5
const SPRAY_SLOW_TIME := 1.5
const SPRAY_OUTER := Color(0.55, 0.95, 0.75, 0.75)
const SPRAY_INNER := Color(0.88, 1.0, 0.92, 0.85)
const CRESCENDO_WINDUP := 0.6
const CRESCENDO_GLOW := 1.3
const CRESCENDO_STAGGER := 0.1
const CRESCENDO_EVERY := 9.0
const FIRST_CRESCENDO := 5.0
const CRESCENDO_REACH := 240.0
# The safe spot keeps this far from every pipe, so each ring still has a real reach.
const CRESCENDO_MIN_REACH := 48.0
# Every ring stops this far short of the safe spot: half its band and room for his feet.
const SAFE_MARGIN := 26.0
# A safe spot is picked this close to him when there is one, so he can reach it in time.
const SAFE_NEAR := 120.0
# A pipe whose ring would reach less than this keeps quiet instead.
const PLAYS_FROM := 24.0
const CHARGE_WINDUP := 0.9
const CHARGE_LENGTH := 360.0
const CHARGE_SPEED := 420.0
const CHARGE_HIT_RANGE := 28.0
const CHARGE_LANE_WIDTH := 52.0
const WARNING_RADIUS := 40.0
# Shorter than Old Smokey's 0.7 and 0.5 and Matron Mercy's 0.8 and 0.6, as he must be clearly harder.
const BASE_COOLDOWN := 0.65
const PHASE_TWO_COOLDOWN := 0.45
const PHASE_TWO_SPEED := 1.2
const PHASE_TWO_WINDUP_SCALE := 0.8
const KEEP_NEAR := 84.0
const SAY_TIME := 1.0

enum Attack { NONE, CASKET, PROCESSION, SPRAY, CRESCENDO, CHARGE }


# The coffin he climbs into below half health, drawn around him.
class CoffinShell extends Node2D:
	var body := Vector2(42, 50)

	func _draw() -> void:
		var w := body.x / 2.0 + 6.0
		var h := body.y / 2.0 + 6.0
		var shape := PackedVector2Array([Vector2(-w * 0.6, -h), Vector2(w * 0.6, -h), Vector2(w, -h * 0.45), Vector2(w * 0.7, h), Vector2(-w * 0.7, h), Vector2(-w, -h * 0.45)])
		draw_colored_polygon(shape, Color("3a2016"))
		draw_polyline(shape + PackedVector2Array([shape[0]]), Color("c9a25a"), 2.0)


var _telegraph := Telegraph.new()
var _dash := BossDash.new()
var _attack := Attack.NONE
var _last := Attack.NONE
var _next := Attack.NONE
var _cooldown := 1.2
var _since_crescendo := CRESCENDO_EVERY - FIRST_CRESCENDO
var _aim := Vector2.RIGHT
var _gap := -1
var _across := Vector2.RIGHT
var _shell: CoffinShell
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


static func is_phase_two(hp: float, max_hp: float) -> bool:
	return hp <= max_hp * 0.5


static func cooldown_for(phase_two: bool) -> float:
	return PHASE_TWO_COOLDOWN if phase_two else BASE_COOLDOWN


# The second phase quickens his windups, but never the casket's extra-clear warning, and the coffin
# charge keeps the Pallbearers' 0.9 seconds.
static func windup_for(attack: int, phase_two: bool) -> float:
	match attack:
		Attack.CASKET:
			return CASKET_WINDUP
		Attack.CHARGE:
			return CHARGE_WINDUP
	var windup := SPRAY_WINDUP
	match attack:
		Attack.PROCESSION:
			windup = PROCESSION_WINDUP
		Attack.CRESCENDO:
			windup = CRESCENDO_WINDUP
	return windup * (PHASE_TWO_WINDUP_SCALE if phase_two else 1.0)


# In the second phase the coffin charges between his other attacks.
static func followup(attack: int, phase_two: bool) -> int:
	if phase_two and attack != Attack.CHARGE and attack != Attack.NONE:
		return Attack.CHARGE
	return Attack.NONE


static func choose_attack(distance: float, last: int, has_pipes: bool, since_crescendo: float, roll: float) -> int:
	var options: Array[int] = [Attack.CASKET, Attack.PROCESSION]
	if distance <= SPRAY_START:
		options.append(Attack.SPRAY)
	# In a room without pipes the casket slam stands in for the crescendo.
	if has_pipes and since_crescendo >= CRESCENDO_EVERY:
		options.append(Attack.CRESCENDO)
	if options.size() > 1:
		options.erase(last)
	return options[mini(int(roll * options.size()), options.size() - 1)]


# One slot of the procession: a lane the length of the room along direction, set beside the others
# across it. The band of slots lies around center, moved to lie inside the room.
static func procession_slot(room_rect: Rect2, direction: Vector2, slot: int, center := Vector2.INF) -> Rect2:
	var middle_at := room_rect.get_center() if center == Vector2.INF else center
	var band := LANE_WIDTH * SLOTS
	var horizontal := absf(direction.x) >= absf(direction.y)
	var low := room_rect.position.y if horizontal else room_rect.position.x
	var high := room_rect.end.y if horizontal else room_rect.end.x
	var middle := middle_at.y if horizontal else middle_at.x
	var start := clampf(middle - band / 2.0, low, maxf(high - band, low))
	var at := start + slot * LANE_WIDTH
	if horizontal:
		return Rect2(room_rect.position.x, at, room_rect.size.x, LANE_WIDTH)
	return Rect2(at, room_rect.position.y, LANE_WIDTH, room_rect.size.y)


# Every slot that marches: all but the gap.
static func procession_lanes(room_rect: Rect2, direction: Vector2, gap: int, center := Vector2.INF) -> Array[Rect2]:
	var lanes: Array[Rect2] = []
	for slot in SLOTS:
		if slot != gap:
			lanes.append(procession_slot(room_rect, direction, slot, center))
	return lanes


# Any slot but the last gap, so standing where it was clear never works twice.
static func next_gap(last: int, rng: RandomNumberGenerator) -> int:
	if last < 0 or last >= SLOTS:
		return rng.randi_range(0, SLOTS - 1)
	var gap := rng.randi_range(0, SLOTS - 2)
	return gap + 1 if gap >= last else gap


# Where Grandpa can stand through a crescendo: the middle of a cell of the room far enough from every
# pipe, near him when one is. is_open, when given, says which spots he can stand on.
static func crescendo_safe_spot(pipes: Array[Vector2], room_rect: Rect2, rng: RandomNumberGenerator, near := Vector2.INF, is_open := Callable()) -> Vector2:
	var tile := float(RoomBackdrop.TILE)
	var candidates: Array[Vector2] = []
	for row in floori(room_rect.size.y / tile):
		for column in floori(room_rect.size.x / tile):
			var spot := room_rect.position + Vector2(column + 0.5, row + 0.5) * tile
			if _clear_of_pipes(spot, pipes) and (not is_open.is_valid() or is_open.call(spot)):
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


static func _clear_of_pipes(spot: Vector2, pipes: Array[Vector2]) -> bool:
	for pipe in pipes:
		if spot.distance_to(pipe) < CRESCENDO_MIN_REACH + SAFE_MARGIN:
			return false
	return true


# How far each pipe's ring reaches: just short of the safe spot, and never past CRESCENDO_REACH.
static func crescendo_reaches(pipes: Array[Vector2], safe: Vector2) -> Array[float]:
	var reaches: Array[float] = []
	for pipe in pipes:
		reaches.append(clampf(pipe.distance_to(safe) - SAFE_MARGIN, 0.0, CRESCENDO_REACH))
	return reaches


func tick(enemy: Enemy, delta: float) -> void:
	var phase_two := is_phase_two(enemy.hp, enemy.max_hp())
	if phase_two and _shell == null:
		_climb_in(enemy)
	_since_crescendo += delta
	if _dash.is_active():
		_dash.tick(enemy, delta)
		if not _dash.is_active():
			_cooldown = cooldown_for(phase_two)
		return
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_finish_attack(enemy, phase_two)
		return
	_cooldown -= delta
	var distance := enemy.distance_to_target()
	var speed := enemy.def.speed * (PHASE_TWO_SPEED if phase_two else 1.0)
	if not enemy.target_in_view():
		enemy.desired_velocity = enemy.chase_direction() * speed * BossMoves.CATCH_UP_SPEED
		return
	if _cooldown <= 0.0 or (_next != Attack.NONE and _cooldown <= cooldown_for(phase_two) * 0.5):
		var attack := _next
		if attack == Attack.NONE:
			attack = choose_attack(distance, _last, not _pipes(enemy).is_empty(), _since_crescendo, _rng.randf())
		_next = Attack.NONE
		_begin(enemy, attack, phase_two)
		return
	if distance > KEEP_NEAR:
		enemy.desired_velocity = enemy.chase_direction() * speed


# A crescendo that has not chorded yet never does once he falls.
func on_killed(enemy: Enemy) -> void:
	for pipe in _pipes(enemy):
		pipe.cancel_force()


func _climb_in(enemy: Enemy) -> void:
	_shell = CoffinShell.new()
	_shell.body = enemy.def.body_size
	_shell.z_index = -1
	enemy.add_child(_shell)
	enemy.say("Into the box I go!", SAY_TIME)


func _pipes(enemy: Enemy) -> Array[OrganPipe]:
	var pipes: Array[OrganPipe] = []
	if enemy.get_parent() == null:
		return pipes
	for child in enemy.get_parent().get_children():
		if child is OrganPipe:
			pipes.append(child)
	return pipes


func _charge_end(enemy: Enemy) -> Vector2:
	if enemy.open_ground.is_valid():
		return MatronBehavior.charge_end(enemy.global_position, _aim, CHARGE_LENGTH, enemy.open_ground)
	return enemy.global_position + _aim * CHARGE_LENGTH


func _begin(enemy: Enemy, attack: int, phase_two: bool) -> void:
	if attack == Attack.CRESCENDO and _pipes(enemy).is_empty():
		attack = Attack.CASKET
	_attack = attack
	_telegraph.start(windup_for(attack, phase_two))
	match attack:
		Attack.CASKET:
			# The windup on him shows whole too, and the coffin's spot is locked under Grandpa at once.
			enemy.set_warning(_telegraph, WARNING_RADIUS, CASKET_SHOWN_WHOLE)
			enemy.say("Your casket is ready.", SAY_TIME)
			var strike := enemy.strike_ground(enemy.target_ground(), CASKET_RADIUS, CASKET_WINDUP, 0.0, 0.0, CASKET_DAMAGE)
			if strike != null:
				strike.set_look(GroundStrike.LOOK_CASKET)
		Attack.PROCESSION:
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Make way!", SAY_TIME)
		Attack.SPRAY:
			_aim = enemy.direction_to_target()
			enemy.set_warning(_telegraph, WARNING_RADIUS * 0.6)
			enemy.set_warning_cone(_aim, SPRAY_LENGTH, SPRAY_ANGLE)
		Attack.CRESCENDO:
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("A little music!", SAY_TIME)
		Attack.CHARGE:
			_aim = enemy.direction_to_target()
			enemy.set_warning(_telegraph, CHARGE_HIT_RANGE)
			enemy.set_warning_lane(_aim, enemy.global_position.distance_to(_charge_end(enemy)), CHARGE_LANE_WIDTH)


func _finish_attack(enemy: Enemy, phase_two: bool) -> void:
	var busy := 0.0
	match _attack:
		Attack.PROCESSION:
			_march(enemy)
			busy = PROCESSION_WARNING
		Attack.SPRAY:
			var spray := FlameBurst.new()
			spray.setup(_aim, SPRAY_LENGTH, SPRAY_ANGLE)
			spray.tint(SPRAY_OUTER, SPRAY_INNER)
			enemy.get_parent().add_child(spray)
			spray.global_position = enemy.global_position
			if ChiefStokerBehavior.in_cone(enemy.global_position, _aim, SPRAY_ANGLE, SPRAY_LENGTH, enemy.target_ground()):
				if enemy.target.has_method("take_hit") and enemy.target.take_hit(enemy.def.damage) and enemy.target.has_method("slow"):
					enemy.target.slow(SPRAY_SLOW, SPRAY_SLOW_TIME)
		Attack.CRESCENDO:
			busy = _play_crescendo(enemy)
			_since_crescendo = 0.0
		Attack.CHARGE:
			_dash.start(_aim, enemy.global_position.distance_to(_charge_end(enemy)), CHARGE_SPEED, CHARGE_HIT_RANGE, Enemy.HEAVY_DAMAGE)
	_cooldown = cooldown_for(phase_two) + busy
	_last = _attack
	_next = followup(_attack, phase_two)


# The lanes run across the way to him, turning each time, and the gap moves each time.
func _march(enemy: Enemy) -> void:
	_across = Vector2.DOWN if _across == Vector2.RIGHT else Vector2.RIGHT
	_gap = next_gap(_gap, _rng)
	var room := ForemanBehavior.room_rect(enemy.room_cells)
	var way := _across if _rng.randf() < 0.5 else -_across
	for lane in procession_lanes(room, _across, _gap, enemy.target_ground()):
		var length := lane.size.x if _across == Vector2.RIGHT else lane.size.y
		var middle := lane.get_center()
		var origin := middle - way * length / 2.0
		var row := ProcessionLane.new()
		row.setup(enemy, way, length, LANE_WIDTH, PROCESSION_WARNING)
		enemy.get_parent().add_child(row)
		row.global_position = origin


# Every pipe glows, one after another, and chords with a ring that stops just short of one safe spot.
# A pipe that would barely reach keeps quiet through it. Returns how long it keeps him busy.
func _play_crescendo(enemy: Enemy) -> float:
	var pipes := _pipes(enemy)
	var origins: Array[Vector2] = []
	for pipe in pipes:
		origins.append(pipe.ring_origin())
	var grid := enemy.walk_grid
	var is_open := Callable()
	if grid != null:
		is_open = func(spot: Vector2) -> bool: return grid.is_open(WalkGrid.cell_of(spot))
	var safe := crescendo_safe_spot(origins, ForemanBehavior.room_rect(enemy.room_cells), _rng, enemy.target_ground(), is_open)
	var reaches := crescendo_reaches(origins, safe)
	var longest := CRESCENDO_GLOW
	for i in pipes.size():
		var glow := CRESCENDO_GLOW + i * CRESCENDO_STAGGER
		if reaches[i] >= PLAYS_FROM:
			pipes[i].force_chord(glow, reaches[i], enemy.def.damage)
		else:
			pipes[i].hold(glow + PipeRing.GROW_TIME * 2.0)
		longest = maxf(longest, glow)
	return longest
