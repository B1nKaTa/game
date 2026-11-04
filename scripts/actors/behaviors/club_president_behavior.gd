class_name ClubPresidentBehavior
extends EnemyBehavior

# Club President Thaddeus Fairweather. His hole in one drops a giant ball onto a warned spot under
# Grandpa, the one attack that costs three pills, so its warning always shows whole, with a second ring.
# He charges in his cart down a warned lane, holding it whatever lies on it. His sprinkler sweeps a jet
# of water round him through a warned arc, leaving one marked quarter dry. His bunker spread turns warned
# patches of the course to sand for a while. Below half health he calls Caddies, never more than three of
# his at once, and every cart charge chains straight into a bunker spread.
const HOLE_IN_ONE_WINDUP := 1.2
const HOLE_IN_ONE_DAMAGE := Enemy.HEAVIEST_DAMAGE
# The hole in one's warning shows for all of its windup, whatever the player's warning stat.
const HOLE_IN_ONE_SHOWN_WHOLE := true
const HOLE_IN_ONE_RADIUS := 44.0
const CART_WINDUP := 0.9
const CART_DAMAGE := Enemy.HEAVY_DAMAGE
const CART_LENGTH := 360.0
const CART_SPEED := 400.0
const CART_HIT_RANGE := 28.0
const CART_LANE_WIDTH := 52.0
const CART_SCALE := 1.7
const SPRINKLER_WINDUP := 0.8
const BUNKER_WINDUP := 0.6
const BUNKERS := 3
# How far from his cell, in cells, a patch's middle may lie, and how far apart two middles keep, so
# patches never overlap.
const BUNKER_REACH := 3
const BUNKER_APART := 3
const BUNKER_TRIES := 40
const WARNING_RADIUS := 40.0
# Shorter than Mortimer's and the Mall Santa's 0.65 and 0.45.
const BASE_COOLDOWN := 0.6
const PHASE_TWO_COOLDOWN := 0.42
const PHASE_TWO_SPEED := 1.2
const PHASE_TWO_WINDUP_SCALE := 0.8
const KEEP_NEAR := 100.0
const MAX_CADDIES := 3
const FIRST_CADDIES := 1.5
const CADDIE_EVERY := 9.0
const CADDIE_DISTANCE := 110.0
const SAY_TIME := 1.0

enum Attack { NONE, HOLE_IN_ONE, CART, SPRINKLER, BUNKER }

var _telegraph := Telegraph.new()
var _dash := BossDash.new()
var _attack := Attack.NONE
var _last := Attack.NONE
var _next := Attack.NONE
var _cooldown := 1.2
var _caddie_timer := FIRST_CADDIES
var _aim := Vector2.RIGHT
var _cart: CaddieBehavior.Cart
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


static func is_phase_two(hp: float, max_hp: float) -> bool:
	return hp <= max_hp * 0.5


static func cooldown_for(phase_two: bool) -> float:
	return PHASE_TWO_COOLDOWN if phase_two else BASE_COOLDOWN


static func calls_caddies(phase_two: bool) -> bool:
	return phase_two


# As many caddies as fit under the cap of three, never a negative number.
static func caddies_to_call(alive: int) -> int:
	return clampi(MAX_CADDIES - alive, 0, MAX_CADDIES)


# The second phase quickens his windups, but never the hole in one's extra-clear warning.
static func windup_for(attack: int, phase_two: bool) -> float:
	var windup := BUNKER_WINDUP
	match attack:
		Attack.HOLE_IN_ONE:
			return HOLE_IN_ONE_WINDUP
		Attack.CART:
			windup = CART_WINDUP
		Attack.SPRINKLER:
			windup = SPRINKLER_WINDUP
	return windup * (PHASE_TWO_WINDUP_SCALE if phase_two else 1.0)


# In the second phase every cart charge chains straight into a bunker spread.
static func followup(attack: int, phase_two: bool) -> int:
	if phase_two and attack == Attack.CART:
		return Attack.BUNKER
	return Attack.NONE


# Any of his four, never the same one twice running.
static func choose_attack(last: int, roll: float) -> int:
	var options: Array[int] = [Attack.HOLE_IN_ONE, Attack.CART, Attack.SPRINKLER, Attack.BUNKER]
	options.erase(last)
	return options[mini(int(roll * options.size()), options.size() - 1)]


# The middles of a room's four doorways, as RoomLayout places them for a room of this size.
static func door_cells(room_cells: Vector2i) -> Array[Vector2i]:
	return [Vector2i(room_cells.x / 2, 1), Vector2i(room_cells.x / 2, room_cells.y - 2), Vector2i(1, room_cells.y / 2), Vector2i(room_cells.x - 2, room_cells.y / 2)]


# Whether a cell may turn to sand: inside the walls, on open floor, and as far from every doorway as a
# layout's own bunkers keep.
static func can_be_sand(cell: Vector2i, room_cells: Vector2i, is_open: Callable) -> bool:
	if room_cells != Vector2i.ZERO:
		if cell.x < 1 or cell.y < 1 or cell.x > room_cells.x - 2 or cell.y > room_cells.y - 2:
			return false
		for door in door_cells(room_cells):
			if absi(cell.x - door.x) <= SandRule.DOOR_CLEARANCE and absi(cell.y - door.y) <= SandRule.DOOR_CLEARANCE:
				return false
	return not is_open.is_valid() or is_open.call(RoomBackdrop.cell_center(cell))


# Where the patches go: the first under him when it can be, the rest near him and apart.
static func bunker_centers(target_cell: Vector2i, count: int, rng: RandomNumberGenerator, room_cells := Vector2i.ZERO, is_open := Callable()) -> Array[Vector2i]:
	var centers: Array[Vector2i] = []
	if can_be_sand(target_cell, room_cells, is_open):
		centers.append(target_cell)
	var tries := 0
	while centers.size() < count and tries < BUNKER_TRIES:
		tries += 1
		var cell := target_cell + Vector2i(rng.randi_range(-BUNKER_REACH, BUNKER_REACH), rng.randi_range(-BUNKER_REACH, BUNKER_REACH))
		if not can_be_sand(cell, room_cells, is_open):
			continue
		var apart := true
		for center in centers:
			if maxi(absi(center.x - cell.x), absi(center.y - cell.y)) < BUNKER_APART:
				apart = false
				break
		if apart:
			centers.append(cell)
	return centers


# The 3 by 3 cells a patch turns to sand, less any that may not be sand.
static func bunker_patch(center: Vector2i, room_cells := Vector2i.ZERO, is_open := Callable()) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(-1, 2):
		for x in range(-1, 2):
			var cell := center + Vector2i(x, y)
			if can_be_sand(cell, room_cells, is_open):
				cells.append(cell)
	return cells


func tick(enemy: Enemy, delta: float) -> void:
	var phase_two := is_phase_two(enemy.hp, enemy.max_hp())
	if calls_caddies(phase_two):
		_call_caddies(enemy, delta)
	if _dash.is_active():
		_dash.tick(enemy, delta)
		if not _dash.is_active():
			_cooldown = cooldown_for(phase_two)
			_park()
		return
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_finish_attack(enemy, phase_two)
		return
	_cooldown -= delta
	var speed := enemy.def.speed * (PHASE_TWO_SPEED if phase_two else 1.0)
	if not enemy.target_in_view():
		enemy.desired_velocity = enemy.chase_direction() * speed * BossMoves.CATCH_UP_SPEED
		return
	if _cooldown <= 0.0 or (_next != Attack.NONE and _cooldown <= cooldown_for(phase_two) * 0.5):
		var attack := _next
		if attack == Attack.NONE:
			attack = choose_attack(_last, _rng.randf())
		_next = Attack.NONE
		_begin(enemy, attack, phase_two)
		return
	if enemy.distance_to_target() > KEEP_NEAR:
		enemy.desired_velocity = enemy.chase_direction() * speed


func _call_caddies(enemy: Enemy, delta: float) -> void:
	_caddie_timer -= delta
	if _caddie_timer > 0.0 or not enemy.target_in_view():
		return
	_caddie_timer = CADDIE_EVERY
	var alive := _caddies(enemy)
	var count := caddies_to_call(alive)
	if BossMoves.can_summon(alive, MAX_CADDIES) and count > 0:
		enemy.say("Caddies! My clubs!", SAY_TIME)
		enemy.request_summon_at(BossMoves.cutoff_points(enemy.target_ground(), enemy.target_motion(), enemy.global_position, count, CADDIE_DISTANCE, 0.8), BossMoves.SUMMON_WARNING)


# Only his own caddies count toward the cap of three.
func _caddies(enemy: Enemy) -> int:
	var count := 0
	if not enemy.is_inside_tree():
		return count
	for other: Enemy in enemy.get_tree().get_nodes_in_group("enemies"):
		if other != enemy and other.is_summon and not other.is_dead() and other.def == enemy.def.summon:
			count += 1
	return count


func _cart_end(enemy: Enemy) -> Vector2:
	if enemy.open_ground.is_valid():
		return MatronBehavior.charge_end(enemy.global_position, _aim, CART_LENGTH, enemy.open_ground)
	return enemy.global_position + _aim * CART_LENGTH


func _begin(enemy: Enemy, attack: int, phase_two: bool) -> void:
	_attack = attack
	var windup := windup_for(attack, phase_two)
	_telegraph.start(windup)
	match attack:
		Attack.HOLE_IN_ONE:
			# His windup and the spot both show whole, the spot with a second ring.
			enemy.set_warning(_telegraph, WARNING_RADIUS, HOLE_IN_ONE_SHOWN_WHOLE)
			enemy.say("Hole in one!", SAY_TIME)
			GiantBallDrop.drop(enemy, enemy.target_ground(), HOLE_IN_ONE_RADIUS, HOLE_IN_ONE_WINDUP, HOLE_IN_ONE_DAMAGE)
		Attack.CART:
			_aim = enemy.direction_to_target()
			enemy.set_warning(_telegraph, CART_HIT_RANGE)
			enemy.set_warning_lane(_aim, enemy.global_position.distance_to(_cart_end(enemy)), CART_LANE_WIDTH)
			enemy.say("Out of my way!", SAY_TIME)
			_show_cart(enemy)
		Attack.SPRINKLER:
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Water the greens!", SAY_TIME)
			var sweep := SprinklerSweep.new()
			sweep.setup(enemy, enemy.global_position.direction_to(enemy.target_ground()).angle(), 1 if _rng.randf() < 0.5 else -1, windup)
			enemy.get_parent().add_child(sweep)
			sweep.global_position = enemy.global_position
		Attack.BUNKER:
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Bunkers, men!", SAY_TIME)
			_spread_bunkers(enemy)


func _finish_attack(enemy: Enemy, phase_two: bool) -> void:
	var busy := 0.0
	match _attack:
		Attack.CART:
			_dash.start(_aim, enemy.global_position.distance_to(_cart_end(enemy)), CART_SPEED, CART_HIT_RANGE, CART_DAMAGE)
			# Hemmed in by a wall, there is nowhere to drive.
			if not _dash.is_active():
				_park()
		Attack.SPRINKLER:
			busy = SprinklerSweep.SWEEP_TIME
		Attack.BUNKER:
			busy = maxf(BunkerPatch.WARNING - windup_for(Attack.BUNKER, phase_two), 0.0)
	_cooldown = cooldown_for(phase_two) + busy
	_last = _attack
	_next = followup(_attack, phase_two)


# Each patch is marked at once, under and around him, and turns to sand when its warning runs out.
func _spread_bunkers(enemy: Enemy) -> void:
	var is_open := _open_floor(enemy)
	var room := enemy.get_parent()
	var palette: RoomPalette = room.room_palette() if room.has_method("room_palette") else null
	for center in bunker_centers(WalkGrid.cell_of(enemy.target_ground()), BUNKERS, _rng, enemy.room_cells, is_open):
		var cells := bunker_patch(center, enemy.room_cells, is_open)
		if cells.is_empty():
			continue
		var patch := BunkerPatch.new()
		patch.setup(cells, BunkerPatch.WARNING, BunkerPatch.LAST, palette, enemy)
		room.add_child(patch)


static func _open_floor(enemy: Enemy) -> Callable:
	var grid := enemy.walk_grid
	return func(spot: Vector2) -> bool: return grid == null or grid.is_open(WalkGrid.cell_of(spot))


func _show_cart(enemy: Enemy) -> void:
	if _cart == null:
		_cart = CaddieBehavior.Cart.new()
		_cart.z_index = -1
		_cart.scale = Vector2(CART_SCALE, CART_SCALE)
		enemy.add_child(_cart)
	_cart.way = _aim
	_cart.visible = true
	_cart.queue_redraw()


func _park() -> void:
	if _cart != null:
		_cart.visible = false
