class_name RoomLayout
extends Resource

const TYPE_COMBAT := "combat"
const TYPE_ITEM := "item"
const TYPE_HEALING := "healing"
const TYPE_SIDE := "side"
const TYPE_MINI_BOSS := "mini_boss"
const TYPE_FLOOR_BOSS := "floor_boss"
const TYPE_TREASURE := "treasure"
const TYPE_SHOP := "shop"
const TYPE_SECRET := "secret"
# A rich dead end behind a reinforced stone. Nothing the floor needs is ever inside.
const TYPE_VAULT := "vault"
# The small room every run starts in, with one exit per path. It holds nothing to fight or find.
const TYPE_CROSSROADS := "crossroads"
# The safe room at the foot of the stairwell between floors, with one way on to the next Crossroads.
const TYPE_LANDING := "landing"
# A safe dead end with a Dealer and three game tables, rolled on about one floor in four.
const TYPE_ARCADE := "arcade"
# A Waiting Room department. It holds no fight, only the stations the Waiting Room places in it.
const TYPE_DEPARTMENT := "department"
const DEFAULT_SIZE := Vector2i(20, 11)
const NORTH := Vector2i.UP
const SOUTH := Vector2i.DOWN
const WEST := Vector2i.LEFT
const EAST := Vector2i.RIGHT
const SIDES: Array[Vector2i] = [NORTH, EAST, SOUTH, WEST]
const SIZE_SMALL := "small"
const SIZE_MEDIUM := "medium"
const SIZE_LARGE := "large"
const MEDIUM_WIDTH := 20
const LARGE_WIDTH := 30
const MIN_SIZE := Vector2i(10, 7)
# Any door can be the way in, so nothing may jump on Grandpa as he arrives.
const MIN_FIGHTER_DOOR_DISTANCE := 3.0
const FIGHTERS := "EB"
const SYMBOL_WALL := "#"
const SYMBOL_FLOOR := "."
const SYMBOL_BLOCK := "X"
const SYMBOL_PLAN := "P"
# Stage 2 props. A rock breaks to bombs and bosses, a barrel to the cane too, a hole
# is never broken, and a pile of bones is a small breakable that blocks nothing.
const SYMBOL_ROCK := "O"
const SYMBOL_BARREL := "Q"
const SYMBOL_HOLE := "V"
const SYMBOL_PILE := "Z"
# Graveyard props. A gravestone can hide a coin, and a dead tree is only in the way. Both break like a rock.
const SYMBOL_GRAVESTONE := "A"
const SYMBOL_DEAD_TREE := "Y"
# Care home props. Wheelchairs and food trolleys break like barrels, armchairs and beds like rocks,
# and a flower vase blocks nothing and breaks to anything, like grass.
const SYMBOL_WHEELCHAIR := "J"
const SYMBOL_TROLLEY := "F"
const SYMBOL_ARMCHAIR := "K"
const SYMBOL_BED := "D"
const SYMBOL_VASE := "f"
# Boiler hall stock. Coal sacks and crates break like barrels, a coal heap like a rock, and a pipe
# valve blocks nothing and breaks to anything, like a vase.
const SYMBOL_COAL_SACK := "L"
const SYMBOL_CRATE := "R"
const SYMBOL_COAL_HEAP := "M"
const SYMBOL_PIPE_VALVE := "p"
# Decor blocks nothing. Lanterns hang in the border wall, the rest lie on the floor.
const SYMBOL_GRASS := "g"
const SYMBOL_BONES := "n"
const SYMBOL_COBWEB := "w"
const SYMBOL_PUDDLE := "u"
const SYMBOL_CRACK := "k"
const SYMBOL_TORCH := "t"
const SYMBOL_LANTERN := "l"
const SYMBOL_STUMP := "m"
# The Last Resort Cruise adds its buffet tray, Head Office its in-tray, Fairway's End its flag
# pin and Departures, Terminal Zero its suitcase stack, which block nothing.
# The Flashback Cinema adds its lobby cards.
const DECOR_SYMBOLS := "gnwuktlmfprc" + "0" + "y" + "3" + "7" + "i"
# A freshly mopped cell: everyone walks on it, Grandpa and chargers slide. Kept well clear of doors.
const SYMBOL_WET := "W"
const WET_DOOR_CLEARANCE := 2
# A floor vent: walkable, but it flares on a rhythm and hurts whoever stands on it. Kept clear of doors too.
const SYMBOL_VENT := "U"
const VENT_DOOR_CLEARANCE := 2
# An Arcade game table. An arcade room's tables are, in reading order, the slot machine, blackjack and
# draw poker. Solid, like the Retirement Plan, and never broken.
const SYMBOL_GAME := "G"
# An organ pipe set in the border wall, as a lantern is. It chords on a beat and pushes with a ring.
const SYMBOL_ORGAN_PIPE := "o"
# Funeral parlour stock. A hymn-book cart breaks like a barrel, a chapel pew like a rock, and a wreath
# stand and a candle stand block nothing and break to anything, like grass.
const SYMBOL_HYMN_CART := "j"
const SYMBOL_PEW := "h"
const SYMBOL_WREATH := "r"
const SYMBOL_CANDLE := "c"
# The Last Resort Cruise. A deck chair breaks like a barrel and a lifeboat davit like a rock, a buffet
# tray blocks nothing and breaks to anything, like grass, and the pool is never broken, like a hole.
const SYMBOL_DECK_CHAIR := "b"
const SYMBOL_BUFFET_TRAY := "0"
const SYMBOL_POOL := "1"
const SYMBOL_DAVIT := "2"
# Head Office: red tape strung across a lane. Walkable and never harmful, but walking into it holds
# Grandpa a moment and a dodge cuts it (RedTapeRule). Kept well clear of doors, so nobody is held
# in a doorway.
const SYMBOL_RED_TAPE := "x"
const RED_TAPE_DOOR_CLEARANCE := 2
# Head Office stock. A water cooler breaks like a barrel, a cubicle wall like a rock, and an in-tray
# blocks nothing and breaks to anything, like grass.
const SYMBOL_WATER_COOLER := "9"
const SYMBOL_CUBICLE := "N"
const SYMBOL_IN_TRAY := "y"
# Fairway's End. Sand bunkers lie in the fairway: walkable, never harmful, slow to wade through, and kept
# well clear of doors. See SandRule. A flag pin blocks nothing and breaks to anything, like grass. A ball
# washer breaks like a barrel. A hedge is solid and breaks like a rock, and a hedge cell with no hedge
# beside it is a parked golf cart instead (GolfProps.is_parked_cart).
const SYMBOL_SAND := "s"
const SAND_DOOR_CLEARANCE := 2
const SYMBOL_FLAG := "3"
const SYMBOL_BALL_WASHER := "4"
const SYMBOL_HEDGE := "5"
# Departures, Terminal Zero: a queue barrier line marked on the carpet. While it is down it is plain
# floor. On a timer, after a chime and a flash, its rope rises, and while it is up it blocks Grandpa
# and his dentures only: staff duck under the rope, so enemies and their shots pass and the walk grid
# never changes. Kept well clear of doors, so a raised barrier never cuts one off.
const SYMBOL_BARRIER := "="
const BARRIER_DOOR_CLEARANCE := 2
# Departures, Terminal Zero stock. A luggage trolley breaks like a barrel, a row of departure seats
# like a rock, and a stack of suitcases blocks nothing and breaks to anything, like grass.
const SYMBOL_LUGGAGE_TROLLEY := "6"
const SYMBOL_SUITCASES := "7"
const SYMBOL_SEATS := "8"
# The Flashback Cinema. A row of seats is solid cover that blocks walkers and shots and breaks like a
# rock, to blasts and bosses only. A pillar is solid and never broken, like a wall, so no route may
# need to pass one.
const SYMBOL_SEAT := "-"
const SYMBOL_PILLAR := "|"
# A lobby card on its easel (LifeSign): it blocks nothing, breaks to nothing, and shows a line of
# Harold's life while he stands near. Kept off the cells touching a door, so no line greets him there.
const SYMBOL_LIFE_SIGN := "i"
# Each new path adds its props at the end of each list: the Last Resort Cruise, Head Office,
# Fairway's End, Departures, Terminal Zero and the Flashback Cinema, in that order.
const ALLOWED := "#.EIHTBXCSPOQVZAYgnwuktlmWJFKDfULRMpGojhrc" + "b012" + "x9Ny" + "s345" + "=678" + "-|i"
# Nothing can walk through these, so nothing may be dropped or summoned on them.
const SOLID_SYMBOLS := "#lXOQVPAYJFKDLRMGojh" + "b12" + "9N" + "45" + "68" + "-|"
# Routes may not need a hole or a wall, and may not need a bomb for a crate or a rock.
const WALL_LIKE := "#lo"
const WALLS := "#lVo" + "1" + "|"
const WALLS_AND_BOMB_ONLY := "#lVXOAYKDMoh" + "12" + "N" + "5" + "8" + "-|"
const MUST_REACH_WITHOUT_BREAKING := "EBIHSPG"
# A vault lays this many labeled pickups out in the open, this many cells apart so names never overlap.
const VAULT_EXTRAS := 3
const PICKUP_SPACING := 3
# A long name is wider than three cells, so two on one row stand further apart.
const SAME_ROW_SPACING := 4
# A plan reward above the station counts as this much further away, squared in cells.
const ABOVE_THE_PLAN := 100.0
# A free item's label is about this many cells long and starts at the item, so it needs that much
# floor to its right. The top row sits under the HUD and the small map.
const LABEL_CELLS := 4
const UNDER_THE_HUD := 1
# Plan rewards keep the full label spacing only this near the station, in cells.
const PLAN_NEAR := 4
const MERCHANT_DOOR_CLEARANCE := 2
# Enemy cells a combat room holds by size when no floor says otherwise, as on the first floor.
const ENEMIES_BY_SIZE := {SIZE_SMALL: 4, SIZE_MEDIUM: 6, SIZE_LARGE: 11}
const REQUIRED := {
	TYPE_COMBAT: {"E": 2},
	TYPE_ITEM: {"I": 2},
	TYPE_HEALING: {"H": 1},
	TYPE_SIDE: {"T": 1},
	TYPE_MINI_BOSS: {"B": 1},
	TYPE_FLOOR_BOSS: {"B": 1},
	TYPE_TREASURE: {"I": 3},
	TYPE_SHOP: {"S": 5, "P": 1},
	TYPE_SECRET: {"T": 2},
	TYPE_VAULT: {"I": 3, "T": 3},
	TYPE_CROSSROADS: {},
	TYPE_LANDING: {},
	TYPE_ARCADE: {SYMBOL_GAME: 3},
	TYPE_DEPARTMENT: {},
}

@export var room_type: String = ""
@export var rows: PackedStringArray = []
# The Last Resort Cruise: the room's deck rolls every few seconds, after a horn. It lays no tile, so it
# has no symbol. Old layouts never roll.
@export var ship_rolls: bool = false


func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	if not REQUIRED.has(room_type):
		errors.append("unknown room type '%s'" % room_type)
		return errors
	var size := size_in_cells()
	if size.x < MIN_SIZE.x or size.y < MIN_SIZE.y:
		errors.append("must be at least %d by %d" % [MIN_SIZE.x, MIN_SIZE.y])
		return errors
	for y in size.y:
		if rows[y].length() != size.x:
			errors.append("row %d must have %d cells" % [y, size.x])
			return errors
		for x in size.x:
			var symbol := rows[y][x]
			if not ALLOWED.contains(symbol):
				errors.append("unknown symbol '%s' at %d,%d" % [symbol, x, y])
			var on_border := x == 0 or y == 0 or x == size.x - 1 or y == size.y - 1
			if on_border and symbol != SYMBOL_WALL and symbol != SYMBOL_LANTERN and symbol != SYMBOL_ORGAN_PIPE:
				errors.append("border must be wall at %d,%d" % [x, y])
			if symbol == SYMBOL_LANTERN and not _lantern_spot_ok(Vector2i(x, y), size):
				errors.append("a lantern needs a plain border wall cell at %d,%d" % [x, y])
			if symbol == SYMBOL_ORGAN_PIPE and not _lantern_spot_ok(Vector2i(x, y), size):
				errors.append("an organ pipe needs a plain border wall cell at %d,%d" % [x, y])
	if not errors.is_empty():
		return errors
	var required: Dictionary = REQUIRED[room_type]
	for symbol in required:
		if cells_of(symbol).size() < required[symbol]:
			errors.append("needs at least %d '%s'" % [required[symbol], symbol])
	for side in SIDES:
		var cell := door_cell(side)
		if rows[cell.y][cell.x] != SYMBOL_FLOOR:
			errors.append("door cell must be floor at %s" % str(cell))
	if not errors.is_empty():
		return errors
	var reachable := _flood_from_door(WALLS)
	var open := _flood_from_door(WALLS_AND_BOMB_ONLY)
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			var symbol := rows[y][x]
			if not WALLS.contains(symbol) and not reachable.has(cell):
				errors.append("cell cannot be reached at %s" % str(cell))
			if MUST_REACH_WITHOUT_BREAKING.contains(symbol) and not open.has(cell):
				errors.append("needs a bomb to reach '%s' at %s" % [symbol, str(cell)])
			if not (SYMBOL_WALL + SYMBOL_FLOOR + SYMBOL_BLOCK + DECOR_SYMBOLS).contains(symbol):
				errors.append_array(_door_clearance_errors(cell, symbol))
			if symbol == SYMBOL_WET and _within_of_a_door(cell, WET_DOOR_CLEARANCE):
				errors.append("wet floor at %s is within %d cells of a door" % [str(cell), WET_DOOR_CLEARANCE])
			if symbol == SYMBOL_VENT and _within_of_a_door(cell, VENT_DOOR_CLEARANCE):
				errors.append("vent at %s is within %d cells of a door" % [str(cell), VENT_DOOR_CLEARANCE])
			if symbol == SYMBOL_RED_TAPE and _within_of_a_door(cell, RED_TAPE_DOOR_CLEARANCE):
				errors.append("red tape at %s is within %d cells of a door" % [str(cell), RED_TAPE_DOOR_CLEARANCE])
			if symbol == SYMBOL_SAND and _within_of_a_door(cell, SAND_DOOR_CLEARANCE):
				errors.append("sand at %s is within %d cells of a door" % [str(cell), SAND_DOOR_CLEARANCE])
			# Departures, Terminal Zero.
			if symbol == SYMBOL_BARRIER and _within_of_a_door(cell, BARRIER_DOOR_CLEARANCE):
				errors.append("barrier at %s is within %d cells of a door" % [str(cell), BARRIER_DOOR_CLEARANCE])
			# The Flashback Cinema.
			if symbol == SYMBOL_LIFE_SIGN and _touches_a_door(cell):
				errors.append("a lobby card at %s touches a door" % str(cell))
	for side in SIDES:
		if not open.has(door_cell(side)):
			errors.append("needs a bomb to reach the door at %s" % str(door_cell(side)))
	# Departures, Terminal Zero.
	errors.append_array(_barrier_errors())
	if room_type == TYPE_VAULT and vault_extra_cells(VAULT_EXTRAS).size() < VAULT_EXTRAS:
		errors.append("no room for %d open pickups clear of the doors" % VAULT_EXTRAS)
	if room_type == TYPE_ARCADE:
		if not cells_of("E").is_empty() or not cells_of("B").is_empty():
			errors.append("an arcade room holds no fight")
		if merchant_cell() == Vector2i(-1, -1):
			errors.append("no spot for the Dealer clear of the doors")
	return errors


# Where a vault's open pickups lie: below its item row and spread out, on plain floor. Standing on a
# pickup takes it, and Grandpa arrives standing on a door, so none may touch any of the four door cells.
func vault_extra_cells(count: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var items := cells_of("I")
	var anchor: Vector2i = items[0] if not items.is_empty() else size_in_cells() / 2
	for i in count:
		var wanted := anchor + Vector2i(i * PICKUP_SPACING, 3 + i % 2)
		var found := _nearest_open_spot(wanted, cells)
		if found == Vector2i(-1, -1):
			break
		cells.append(found)
	return cells


# Where a shop's merchant stands: the plain floor nearest the middle of his wares, as far from each
# ware and the Retirement Plan as labels stand apart, so no two of them answer one press, and two
# steps clear of every door. A crowded room drops the spacing rather than leave him out. A room with
# no wares, as an arcade is, places its Dealer by the game tables the same way.
func merchant_cell() -> Vector2i:
	var wares := cells_of("S")
	if wares.is_empty():
		wares = cells_of(SYMBOL_GAME)
	if wares.is_empty():
		return Vector2i(-1, -1)
	var middle := Vector2.ZERO
	for cell in wares:
		middle += Vector2(cell)
	middle /= wares.size()
	var taken: Array[Vector2i] = wares.duplicate()
	taken.append_array(cells_of(SYMBOL_PLAN))
	var best := Vector2i(-1, -1)
	var fallback := Vector2i(-1, -1)
	var best_distance := INF
	var fallback_distance := INF
	for cell in cells_of(SYMBOL_FLOOR):
		var distance := Vector2(cell).distance_squared_to(middle)
		if _within_of_a_door(cell, MERCHANT_DOOR_CLEARANCE):
			continue
		if distance < fallback_distance:
			fallback_distance = distance
			fallback = cell
		if distance < best_distance and _spaced_from(cell, taken):
			best_distance = distance
			best = cell
	return best if best != Vector2i(-1, -1) else fallback


# Where a shop's Retirement Plan lays its free items, one spot per tier: the nearest plain floor to
# the station, clear of the doors, the wares and whatever stands in avoid, such as the merchant, and
# far enough that its Take prompt never shares the station's reach. Spots below come first, since the
# plan's own text stands above it. Being near the plan matters more than the wide label spacing, so
# past PLAN_NEAR cells a spot only a row or two from a ware will do, and when even that runs out each
# item still gets a spot of its own.
func plan_reward_cells(count: int, avoid: Array[Vector2i] = []) -> Array[Vector2i]:
	var plans := cells_of(SYMBOL_PLAN)
	if plans.is_empty():
		return []
	var station := plans[0]
	var keep_clear: Array[Vector2i] = avoid.duplicate()
	keep_clear.append(station)
	var taken: Array[Vector2i] = cells_of("S")
	taken.append_array(keep_clear)
	var found: Array[Vector2i] = []
	for i in count:
		var picks := [Vector2i(-1, -1), Vector2i(-1, -1), Vector2i(-1, -1)]
		var distances := [INF, INF, INF]
		for cell in cells_of(SYMBOL_FLOOR):
			if _touches_a_door(cell) or taken.has(cell) or not _spaced_from(cell, keep_clear) or not _label_fits(cell) or not clear_of_the_plan_text(cell, station):
				continue
			var distance := Vector2(cell - station).length_squared() + (ABOVE_THE_PLAN if cell.y < station.y else 0.0)
			var near := maxi(absi(cell.x - station.x), absi(cell.y - station.y)) <= PLAN_NEAR
			var fits := [near and _spaced_from(cell, taken), _spaced_loosely(cell, taken), true]
			for tier in 3:
				if fits[tier] and distance < distances[tier]:
					distances[tier] = distance
					picks[tier] = cell
		var spot := Vector2i(-1, -1)
		for pick: Vector2i in picks:
			if pick != Vector2i(-1, -1):
				spot = pick
				break
		if spot == Vector2i(-1, -1):
			break
		taken.append(spot)
		found.append(spot)
	return found


# Labels a row or two apart still read, if no two share a row too closely.
func _spaced_loosely(cell: Vector2i, others: Array[Vector2i]) -> bool:
	for other in others:
		if maxi(absi(cell.x - other.x), absi(cell.y - other.y)) < 2 or (cell.y == other.y and absi(cell.x - other.x) < SAME_ROW_SPACING):
			return false
	return true


# Out from under the HUD, with room for a long name before the wall on the right.
func _label_fits(cell: Vector2i) -> bool:
	return cell.y > UNDER_THE_HUD and cell.x + LABEL_CELLS < size_in_cells().x


# The plan writes three lines in the two rows above itself, from two cells left of it to two right,
# so no free item or its name may sit there.
static func clear_of_the_plan_text(cell: Vector2i, station: Vector2i) -> bool:
	var offset := cell - station
	return not (offset.y >= -2 and offset.y <= -1 and offset.x >= -1 - LABEL_CELLS and offset.x <= 2)


# Plain floor cells as near each wanted cell as the spacing allows, kept off the door cells and apart
# from each other and from taken. A wanted cell with no such spot left is skipped.
func open_spots_near(wanted: Array[Vector2i], taken: Array[Vector2i] = []) -> Array[Vector2i]:
	var avoid: Array[Vector2i] = taken.duplicate()
	var found: Array[Vector2i] = []
	for cell in wanted:
		var spot := _nearest_open_spot(cell, avoid)
		if spot == Vector2i(-1, -1):
			continue
		avoid.append(spot)
		found.append(spot)
	return found


func _nearest_open_spot(wanted: Vector2i, taken: Array[Vector2i]) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_distance := INF
	for cell in cells_of(SYMBOL_FLOOR):
		var distance := Vector2(cell - wanted).length_squared()
		if distance < best_distance and not _touches_a_door(cell) and _spaced_from(cell, taken):
			best_distance = distance
			best = cell
	return best


func _touches_a_door(cell: Vector2i) -> bool:
	return _within_of_a_door(cell, 1)


func touches_a_door(cell: Vector2i) -> bool:
	return _within_of_a_door(cell, 1)


func _within_of_a_door(cell: Vector2i, cells: int) -> bool:
	for side in SIDES:
		var offset := cell - door_cell(side)
		if absi(offset.x) <= cells and absi(offset.y) <= cells:
			return true
	return false


func _spaced_from(cell: Vector2i, others: Array[Vector2i]) -> bool:
	for other in others:
		if maxi(absi(cell.x - other.x), absi(cell.y - other.y)) < PICKUP_SPACING or (cell.y == other.y and absi(cell.x - other.x) < SAME_ROW_SPACING):
			return false
	return true


# The crack for a secret room needs the wall cell past each door, and a corner shows nothing.
func _lantern_spot_ok(cell: Vector2i, size: Vector2i) -> bool:
	var on_edge_x := cell.x == 0 or cell.x == size.x - 1
	var on_edge_y := cell.y == 0 or cell.y == size.y - 1
	if on_edge_x == on_edge_y:
		return false
	for side in SIDES:
		if wall_cell(side) == cell:
			return false
	return true


func _door_clearance_errors(cell: Vector2i, symbol: String) -> PackedStringArray:
	var errors: PackedStringArray = []
	for side in SIDES:
		var offset := cell - door_cell(side)
		var touching: bool = absi(offset.x) <= 1 and absi(offset.y) <= 1
		var too_close: bool = FIGHTERS.contains(symbol) and Vector2(offset).length() < MIN_FIGHTER_DOOR_DISTANCE
		if touching or too_close:
			errors.append("'%s' at %s is too close to a door" % [symbol, str(cell)])
	return errors


func size_in_cells() -> Vector2i:
	if rows.is_empty():
		return Vector2i.ZERO
	return Vector2i(rows[0].length(), rows.size())


# A combat room holds as many enemy cells as its floor asks for its size. Pass a floor's
# enemies_by_size, or nothing for the first floor's numbers. Other room types are not counted.
func enemy_count_errors(by_size: Dictionary = {}) -> PackedStringArray:
	var errors: PackedStringArray = []
	if room_type != TYPE_COMBAT:
		return errors
	var wanted: Dictionary = by_size if not by_size.is_empty() else ENEMIES_BY_SIZE
	var size := size_class()
	var count := cells_of("E").size()
	if wanted.has(size) and count != int(wanted[size]):
		errors.append("a %s combat room needs %d enemy cells, has %d" % [size, int(wanted[size]), count])
	return errors


func size_class() -> String:
	var width := size_in_cells().x
	if width < MEDIUM_WIDTH:
		return SIZE_SMALL
	return SIZE_LARGE if width >= LARGE_WIDTH else SIZE_MEDIUM


# The floor cell just inside the middle of a wall. Doors stand here so Grandpa can stand on them.
func door_cell(side: Vector2i) -> Vector2i:
	var size := size_in_cells()
	match side:
		NORTH:
			return Vector2i(size.x / 2, 1)
		SOUTH:
			return Vector2i(size.x / 2, size.y - 2)
		WEST:
			return Vector2i(1, size.y / 2)
	return Vector2i(size.x - 2, size.y / 2)


func wall_cell(side: Vector2i) -> Vector2i:
	return door_cell(side) + side


# The way into the room from a cell of its border wall, as an organ pipe faces.
func inward_of(cell: Vector2i) -> Vector2:
	var size := size_in_cells()
	if cell.x <= 0:
		return Vector2.RIGHT
	if cell.x >= size.x - 1:
		return Vector2.LEFT
	if cell.y <= 0:
		return Vector2.DOWN
	return Vector2.UP


func cells_of(symbol: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in rows.size():
		for x in rows[y].length():
			if rows[y][x] == symbol:
				cells.append(Vector2i(x, y))
	return cells


func nearest_floor_cell(cell: Vector2i) -> Vector2i:
	var size := size_in_cells()
	var from := Vector2i(clampi(cell.x, 0, size.x - 1), clampi(cell.y, 0, size.y - 1))
	var best := from
	var best_distance := INF
	for y in rows.size():
		for x in rows[y].length():
			if SOLID_SYMBOLS.contains(rows[y][x]):
				continue
			var distance := Vector2(x - from.x, y - from.y).length_squared()
			if distance < best_distance:
				best_distance = distance
				best = Vector2i(x, y)
	return best


# Open cells an extra enemy may start on: walkable without breaking anything, and as far from
# every door as a placed enemy has to be.
func spare_fighter_cells() -> Array[Vector2i]:
	var open := _flood_from_door(WALLS_AND_BOMB_ONLY)
	var cells: Array[Vector2i] = []
	for y in rows.size():
		for x in rows[y].length():
			var cell := Vector2i(x, y)
			if rows[y][x] == SYMBOL_FLOOR and open.has(cell) and _far_from_every_door(cell):
				cells.append(cell)
	return cells


func _far_from_every_door(cell: Vector2i) -> bool:
	for side in SIDES:
		if Vector2(cell - door_cell(side)).length() < MIN_FIGHTER_DOOR_DISTANCE:
			return false
	return true


func symbol_at(cell: Vector2i) -> String:
	var size := size_in_cells()
	if cell.x < 0 or cell.y < 0 or cell.x >= size.x or cell.y >= size.y:
		return SYMBOL_WALL
	return rows[cell.y][cell.x]


func is_solid_at(cell: Vector2i) -> bool:
	return SOLID_SYMBOLS.contains(symbol_at(cell))


func is_open_without_breaking(cell: Vector2i) -> bool:
	return _flood_from_door(WALLS_AND_BOMB_ONLY).has(cell)


# A coin that flies to Grandpa would cross whatever stands between, so one lying in a
# pocket that only a bomb opens stays put. A cell beside open floor is not in a pocket.
func coin_can_fly_from(cell: Vector2i) -> bool:
	var open := _flood_from_door(WALLS_AND_BOMB_ONLY)
	if open.has(cell):
		return true
	for step: Vector2i in SIDES:
		if open.has(cell + step):
			return true
	return false


func _flood_from_door(blocked: String) -> Dictionary:
	var start := door_cell(WEST)
	var seen := {start: true}
	var open: Array[Vector2i] = [start]
	while not open.is_empty():
		var cell: Vector2i = open.pop_back()
		for step: Vector2i in SIDES:
			var next: Vector2i = cell + step
			if seen.has(next) or blocked.contains(rows[next.y][next.x]):
				continue
			seen[next] = true
			open.append(next)
	return seen


# --- Departures, Terminal Zero ---

# A raised barrier is a wall to Grandpa alone, so with every barrier up he must still reach every
# door, everything he has to reach and every other open cell: a barrier line is something to walk
# round, never a fence that shuts him in.
func _barrier_errors() -> PackedStringArray:
	var errors: PackedStringArray = []
	if cells_of(SYMBOL_BARRIER).is_empty():
		return errors
	var roped := _flood_from_door(WALLS + SYMBOL_BARRIER)
	var roped_open := _flood_from_door(WALLS_AND_BOMB_ONLY + SYMBOL_BARRIER)
	var size := size_in_cells()
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			var symbol := rows[y][x]
			if symbol == SYMBOL_BARRIER or WALLS.contains(symbol):
				continue
			if not roped.has(cell):
				errors.append("raised barriers shut off %s" % str(cell))
			elif MUST_REACH_WITHOUT_BREAKING.contains(symbol) and not roped_open.has(cell):
				errors.append("raised barriers shut off '%s' at %s" % [symbol, str(cell)])
	for side in SIDES:
		if not roped_open.has(door_cell(side)):
			errors.append("raised barriers shut off the door at %s" % str(door_cell(side)))
	return errors


# Which way a barrier's rope runs: across, unless its line runs up and down.
func barrier_runs_across(cell: Vector2i) -> bool:
	var beside := symbol_at(cell + WEST) == SYMBOL_BARRIER or symbol_at(cell + EAST) == SYMBOL_BARRIER
	var above_below := symbol_at(cell + NORTH) == SYMBOL_BARRIER or symbol_at(cell + SOUTH) == SYMBOL_BARRIER
	return beside or not above_below
