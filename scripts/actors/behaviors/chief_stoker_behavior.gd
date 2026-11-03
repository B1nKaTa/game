class_name ChiefStokerBehavior
extends EnemyBehavior

# Keeps the boilers roaring: a cone of fire breath that costs two pills, coal raining on marked
# spots that burn, the room's vents flaring all at once but for one safe way through, and the
# bellows, a warned lane that pulls Grandpa in toward the fire. Below half health he is quicker,
# the vents flare more often, the burning ground lasts longer, and the bellows run straight into
# his fire breath.
const BREATH_WINDUP := 0.9
const BREATH_ANGLE := 60.0
const BREATH_LENGTH := 130.0
# He breathes fire only when Grandpa is about within its reach.
const BREATH_START := BREATH_LENGTH + 10.0
const RAIN_WINDUP := 0.5
const RAIN_NEAR := 3
const RAIN_FAR := 2
const RAIN_SPREAD := 40.0
const RAIN_RADIUS := 24.0
const RAIN_WARNING := 0.9
const RAIN_BURN := 3.0
const GRID_WINDUP := 0.6
const GRID_WARN := 1.0
const GRID_FLARE := 0.6
# The safe way through the vent grid leads to a cell at least this many cells from where he stands.
const SAFE_REACH := 4
const BELLOWS_WINDUP := 0.8
const BELLOWS_LENGTH := 240.0
const BELLOWS_WIDTH := 56.0
const BELLOWS_PULL := 260.0
const BELLOWS_TIME := 0.5
# The bellows are for drawing him in, so not when he is already close.
const BELLOWS_START := 100.0
const WARNING_RADIUS := 40.0
# A little shorter than Matron Mercy's rests: measured with the simulated player, the same rests left him easier.
const BASE_COOLDOWN := 0.7
const PHASE_TWO_COOLDOWN := 0.5
const PHASE_TWO_SPEED := 1.2
const PHASE_TWO_WINDUP_SCALE := 0.8
const PHASE_TWO_VENT_PERIOD := 0.75
const PHASE_TWO_BURN := 1.5
const SAY_TIME := 1.0

enum Attack { NONE, BREATH, RAIN, GRID, BELLOWS }

var _telegraph := Telegraph.new()
var _attack := Attack.NONE
var _last := Attack.NONE
var _next := Attack.NONE
var _cooldown := 1.2
var _aim := Vector2.RIGHT
var _hot_vents := false
# How far the warned bellows lane really runs, since it stops at the first wall.
var _bellows_length := BELLOWS_LENGTH
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


static func is_phase_two(hp: float, max_hp: float) -> bool:
	return hp <= max_hp * 0.5


static func vent_period_scale(phase_two: bool) -> float:
	return PHASE_TWO_VENT_PERIOD if phase_two else 1.0


static func burn_scale(phase_two: bool) -> float:
	return PHASE_TWO_BURN if phase_two else 1.0


static func cooldown_for(phase_two: bool) -> float:
	return PHASE_TWO_COOLDOWN if phase_two else BASE_COOLDOWN


static func windup_for(attack: int, phase_two: bool) -> float:
	var windup := BREATH_WINDUP
	match attack:
		Attack.RAIN:
			windup = RAIN_WINDUP
		Attack.GRID:
			windup = GRID_WINDUP
		Attack.BELLOWS:
			windup = BELLOWS_WINDUP
	return windup * (PHASE_TWO_WINDUP_SCALE if phase_two else 1.0)


# The bellows pull him in, and in the second phase straight into the fire. A vent grid always has
# coal after it, so standing still on the safe way is not enough.
static func followup(attack: int, phase_two: bool) -> int:
	if attack == Attack.GRID:
		return Attack.RAIN
	if phase_two and attack == Attack.BELLOWS:
		return Attack.BREATH
	return Attack.NONE


static func choose_attack(distance: float, last: int, has_vents: bool, roll: float) -> int:
	var options: Array[int] = [Attack.RAIN]
	if distance <= BREATH_START:
		options.append(Attack.BREATH)
	if has_vents:
		options.append(Attack.GRID)
	if distance >= BELLOWS_START:
		options.append(Attack.BELLOWS)
	if options.size() > 1:
		options.erase(last)
	return options[mini(int(roll * options.size()), options.size() - 1)]


# Whether a point lies in a cone of the given total angle and length.
static func in_cone(origin: Vector2, direction: Vector2, angle_deg: float, length: float, point: Vector2) -> bool:
	var offset := point - origin
	if offset.length() > length:
		return false
	if offset.is_zero_approx():
		return true
	return absf(direction.angle_to(offset)) <= deg_to_rad(angle_deg) / 2.0


# Which vents flare: all of them but those along one way through, from his cell to a cell at least
# SAFE_REACH away. The way is a shortest walk over open cells, so it never needs a wall or a prop,
# and the far cell is picked at random so the way changes every time. Open holds every cell
# anyone can walk on, vents included.
static func safe_pattern(vent_cells: Array[Vector2i], open: Dictionary, from: Vector2i, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var came := {from: from}
	var queue: Array[Vector2i] = [from]
	var head := 0
	var far: Array[Vector2i] = []
	while head < queue.size():
		var cell := queue[head]
		head += 1
		if maxi(absi(cell.x - from.x), absi(cell.y - from.y)) >= SAFE_REACH:
			far.append(cell)
		var sides: Array[Vector2i] = RoomLayout.SIDES.duplicate()
		for i in range(sides.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var swap := sides[i]
			sides[i] = sides[j]
			sides[j] = swap
		for side in sides:
			var next: Vector2i = cell + side
			if came.has(next) or not open.has(next):
				continue
			came[next] = cell
			queue.append(next)
	var safe := {from: true}
	if not far.is_empty():
		var cursor := far[rng.randi_range(0, far.size() - 1)]
		while cursor != from:
			safe[cursor] = true
			cursor = came[cursor]
	var flaring: Array[Vector2i] = []
	for vent in vent_cells:
		if not safe.has(vent):
			flaring.append(vent)
	return flaring


func tick(enemy: Enemy, delta: float) -> void:
	var phase_two := is_phase_two(enemy.hp, enemy.max_hp())
	if phase_two and not _hot_vents:
		_hot_vents = true
		for vent in _vents(enemy):
			vent.set_period_scale(vent_period_scale(true))
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
			attack = choose_attack(distance, _last, not _vents(enemy).is_empty(), _rng.randf())
		_next = Attack.NONE
		_begin(enemy, attack, phase_two)
		return
	if distance > BREATH_LENGTH * 0.7:
		enemy.desired_velocity = enemy.chase_direction() * speed


func _vents(enemy: Enemy) -> Array:
	var vents := []
	if enemy.get_parent() == null:
		return vents
	for child in enemy.get_parent().get_children():
		if child is FloorVent:
			vents.append(child)
	return vents


func _begin(enemy: Enemy, attack: int, phase_two: bool) -> void:
	_attack = attack
	_telegraph.start(windup_for(attack, phase_two))
	match attack:
		Attack.BREATH:
			_aim = enemy.direction_to_target()
			enemy.set_warning(_telegraph, WARNING_RADIUS * 0.6)
			enemy.set_warning_cone(_aim, BREATH_LENGTH, BREATH_ANGLE)
		Attack.RAIN:
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("More coal!", SAY_TIME)
		Attack.GRID:
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Open the vents!", SAY_TIME)
		Attack.BELLOWS:
			_aim = enemy.direction_to_target()
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.set_warning_lane(_aim, BELLOWS_LENGTH, BELLOWS_WIDTH, false)
			_bellows_length = enemy.warning_lane_length()


func _finish_attack(enemy: Enemy, phase_two: bool) -> void:
	var busy := 0.0
	match _attack:
		Attack.BREATH:
			var flame := FlameBurst.new()
			flame.setup(_aim, BREATH_LENGTH, BREATH_ANGLE)
			enemy.get_parent().add_child(flame)
			flame.global_position = enemy.global_position
			for step in 3:
				enemy.smash(enemy.global_position + _aim * BREATH_LENGTH * (step + 1) / 3.0, 22.0)
			if in_cone(enemy.global_position, _aim, BREATH_ANGLE, BREATH_LENGTH, enemy.target_ground()):
				enemy.hit_target(Enemy.HEAVY_DAMAGE)
		Attack.RAIN:
			var burn := RAIN_BURN * burn_scale(phase_two)
			for spot in rain_spots(enemy.target_ground(), ForemanBehavior.room_rect(enemy.room_cells), _rng):
				StokerBehavior.throw_coal(enemy, spot, RAIN_WARNING, burn, RAIN_RADIUS)
			busy = RAIN_WARNING * 0.5
		Attack.GRID:
			_flare_grid(enemy)
			busy = GRID_WARN
		Attack.BELLOWS:
			if SteamJet.lane_hits(enemy.global_position, _aim, _bellows_length, BELLOWS_WIDTH, enemy.target_ground()):
				if enemy.target.has_method("push"):
					enemy.target.push(-_aim * BELLOWS_PULL, BELLOWS_TIME)
			# The gust only shows the air moving. It costs nothing.
			var gust := SteamJet.new()
			gust.setup(enemy, _aim, _bellows_length, BELLOWS_WIDTH, 0.0, 0)
			enemy.get_parent().add_child(gust)
			gust.global_position = enemy.global_position
			busy = BELLOWS_TIME
	_cooldown = cooldown_for(phase_two) + busy
	_last = _attack
	_next = followup(_attack, phase_two)


# Three marks close around him and two anywhere in the room.
static func rain_spots(feet: Vector2, room: Rect2, rng: RandomNumberGenerator) -> Array[Vector2]:
	var spots: Array[Vector2] = []
	var start := rng.randf() * TAU
	for i in RAIN_NEAR:
		spots.append(feet + Vector2.from_angle(start + TAU * i / RAIN_NEAR) * RAIN_SPREAD * (0.4 if i == 0 else 1.0))
	for i in RAIN_FAR:
		spots.append(Vector2(rng.randf_range(room.position.x, room.end.x), rng.randf_range(room.position.y, room.end.y)))
	return spots


func _flare_grid(enemy: Enemy) -> void:
	var vents := _vents(enemy)
	if vents.is_empty():
		return
	var cells: Array[Vector2i] = []
	for vent in vents:
		cells.append(Vector2i(floori(vent.position.x / RoomBackdrop.TILE), floori(vent.position.y / RoomBackdrop.TILE)))
	var feet := enemy.target_ground()
	var from := Vector2i(floori(feet.x / RoomBackdrop.TILE), floori(feet.y / RoomBackdrop.TILE))
	var open := {}
	if enemy.walk_grid != null:
		for y in enemy.walk_grid.size.y:
			for x in enemy.walk_grid.size.x:
				if enemy.walk_grid.is_open(Vector2i(x, y)):
					open[Vector2i(x, y)] = true
	var flaring := safe_pattern(cells, open, from, _rng)
	for i in vents.size():
		if flaring.has(cells[i]):
			vents[i].force_flare(GRID_WARN, GRID_FLARE)
		else:
			vents[i].hold(GRID_WARN + GRID_FLARE)
