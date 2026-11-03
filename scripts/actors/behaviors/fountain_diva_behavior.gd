class_name FountainDivaBehavior
extends EnemyBehavior

# Gloria, Mall Fountain Diva. She tosses a spray of wishing-well coins down five warned lanes in a fan,
# sends fountain jets up through warned spots near Grandpa, each leaving the floor around it wet for a
# while, and calls a line of Mall Walkers onto marked spots.
const COIN_WINDUP := 0.7
const COINS := 5
const COIN_SPREAD := PI / 3.0
const COIN_SPEED := 230.0
const COIN_LANE := 240.0
const COIN_LANE_WIDTH := 16.0
const SPLASH_WINDUP := 0.5
const SPLASHES := 3
const SPLASH_WARNING := 0.9
const SPLASH_RADIUS := 26.0
# How far from his cell, in cells, a jet may come up, and how far apart two jets keep.
const SPLASH_REACH := 3
const SPLASH_APART := 2
const SPLASH_TRIES := 40
const WET_TIME := 4.0
const WARNING_RADIUS := 34.0
# Shorter than Barbara's and Klaus's rests, and as short as the Reverend's.
const COOLDOWN := 0.8
const KEEP_NEAR := 120.0
const FIRST_SUMMON := 5.0
const SUMMON_EVERY := 12.0
const SUMMON_COUNT := 3
const SUMMON_DISTANCE := 100.0
const SUMMON_SPREAD := 0.3
const MAX_ENEMIES := 5
const SAY_TIME := 1.0

enum Attack { NONE, COINS, SPLASH }

var _telegraph := Telegraph.new()
var _attack := Attack.NONE
var _last := Attack.NONE
var _cooldown := 1.0
var _summon_timer := FIRST_SUMMON
var _aim := Vector2.RIGHT
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


# She alternates, so a splash always follows a coin toss and a coin toss a splash.
static func choose_attack(last: int, roll: float) -> int:
	if last == Attack.COINS:
		return Attack.SPLASH
	if last == Attack.SPLASH:
		return Attack.COINS
	return Attack.COINS if roll < 0.5 else Attack.SPLASH


static func coin_lanes(aim: Vector2) -> Array[Vector2]:
	return BossMoves.fan_directions(aim, COINS, COIN_SPREAD)


# As many walkers as fit under the cap, at most SUMMON_COUNT, never a negative number.
static func summon_count(alive: int, cap: int) -> int:
	return clampi(cap - alive, 0, SUMMON_COUNT)


# The middles of a room's four doorways, as RoomLayout places them for a room of this size.
static func door_cells(room_cells: Vector2i) -> Array[Vector2i]:
	return [Vector2i(room_cells.x / 2, 1), Vector2i(room_cells.x / 2, room_cells.y - 2), Vector2i(1, room_cells.y / 2), Vector2i(room_cells.x - 2, room_cells.y / 2)]


# Whether a cell may be wet: inside the walls, on open floor, and not on or beside a doorway.
static func can_be_wet(cell: Vector2i, room_cells: Vector2i, is_open: Callable) -> bool:
	if room_cells != Vector2i.ZERO:
		if cell.x < 1 or cell.y < 1 or cell.x > room_cells.x - 2 or cell.y > room_cells.y - 2:
			return false
		for door in door_cells(room_cells):
			if absi(cell.x - door.x) <= 1 and absi(cell.y - door.y) <= 1:
				return false
	return not is_open.is_valid() or is_open.call(RoomBackdrop.cell_center(cell))


# Where the jets come up: the first under him when it can be, the rest near him and apart.
static func splash_cells(target_cell: Vector2i, count: int, rng: RandomNumberGenerator, room_cells := Vector2i.ZERO, is_open := Callable()) -> Array[Vector2i]:
	var spots: Array[Vector2i] = []
	if can_be_wet(target_cell, room_cells, is_open):
		spots.append(target_cell)
	var tries := 0
	while spots.size() < count and tries < SPLASH_TRIES:
		tries += 1
		var cell := target_cell + Vector2i(rng.randi_range(-SPLASH_REACH, SPLASH_REACH), rng.randi_range(-SPLASH_REACH, SPLASH_REACH))
		if not can_be_wet(cell, room_cells, is_open):
			continue
		var apart := true
		for spot in spots:
			if maxi(absi(spot.x - cell.x), absi(spot.y - cell.y)) < SPLASH_APART:
				apart = false
				break
		if apart:
			spots.append(cell)
	return spots


# The 3 by 3 cells a jet wets, less any that may not be wet.
static func splash_patch(center: Vector2i, room_cells := Vector2i.ZERO, is_open := Callable()) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(-1, 2):
		for x in range(-1, 2):
			var cell := center + Vector2i(x, y)
			if can_be_wet(cell, room_cells, is_open):
				cells.append(cell)
	return cells


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
			enemy.say("Walkers, warm up!", SAY_TIME)
			enemy.request_summon_at(BossMoves.cutoff_points(enemy.target_ground(), enemy.target_motion(), enemy.global_position, count, SUMMON_DISTANCE, SUMMON_SPREAD), BossMoves.SUMMON_WARNING)
	if _cooldown <= 0.0:
		_begin(enemy, choose_attack(_last, _rng.randf()))
		return
	if enemy.distance_to_target() > KEEP_NEAR:
		enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed


func _begin(enemy: Enemy, attack: int) -> void:
	_attack = attack
	match attack:
		Attack.COINS:
			_telegraph.start(COIN_WINDUP)
			_aim = enemy.direction_to_target()
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			for way in coin_lanes(_aim):
				enemy.add_warning_lane(way, COIN_LANE, COIN_LANE_WIDTH, false)
			enemy.say("Make a wish!", SAY_TIME)
		Attack.SPLASH:
			_telegraph.start(SPLASH_WINDUP)
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Splish splash!", SAY_TIME)
			_splash(enemy)


func _finish_attack(enemy: Enemy) -> void:
	_last = _attack
	_cooldown = COOLDOWN
	match _attack:
		Attack.COINS:
			for way in coin_lanes(_aim):
				enemy.shoot(way, COIN_SPEED).look = Projectile.LOOK_COIN
		Attack.SPLASH:
			# She waits while the jets come up.
			_cooldown += SPLASH_WARNING - SPLASH_WINDUP


# Each jet's spot is marked at once, under and around him, and wets its patch when it comes up.
func _splash(enemy: Enemy) -> void:
	var is_open := _open_floor(enemy)
	var target := WalkGrid.cell_of(enemy.target_ground())
	for cell in splash_cells(target, SPLASHES, _rng, enemy.room_cells, is_open):
		var strike := enemy.strike_ground(RoomBackdrop.cell_center(cell), SPLASH_RADIUS, SPLASH_WARNING)
		if strike == null:
			continue
		strike.set_look(GroundStrike.LOOK_SPLASH)
		strike.landed.connect(_wet.bind(enemy.get_parent(), splash_patch(cell, enemy.room_cells, is_open)))


# Open floor, and not an escalator strip, which already moves whoever stands on it.
static func _open_floor(enemy: Enemy) -> Callable:
	var grid := enemy.walk_grid
	var tree := enemy.get_tree() if enemy.is_inside_tree() else null
	return func(spot: Vector2) -> bool:
		if grid != null and not grid.is_open(WalkGrid.cell_of(spot)):
			return false
		return ConveyorStrip.carry_at(tree, spot).is_zero_approx()


static func _wet(_at: Vector2, room: Node, cells: Array[Vector2i]) -> void:
	if not is_instance_valid(room) or cells.is_empty():
		return
	var splash := WetSplash.new()
	var palette: RoomPalette = room.room_palette() if room.has_method("room_palette") else null
	splash.setup(cells, WET_TIME, palette)
	room.add_child(splash)
