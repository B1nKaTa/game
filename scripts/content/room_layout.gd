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
# Decor blocks nothing. Lanterns hang in the border wall, the rest lie on the floor.
const SYMBOL_GRASS := "g"
const SYMBOL_BONES := "n"
const SYMBOL_COBWEB := "w"
const SYMBOL_PUDDLE := "u"
const SYMBOL_CRACK := "k"
const SYMBOL_TORCH := "t"
const SYMBOL_LANTERN := "l"
const DECOR_SYMBOLS := "gnwuktl"
const ALLOWED := "#.EIHTBXCSPROQVZgnwuktl"
# Nothing can walk through these, so nothing may be dropped or summoned on them.
const SOLID_SYMBOLS := "#lXOQVP"
# Routes may not need a hole or a wall, and may not need a bomb for a crate or a rock.
const WALL_LIKE := "#l"
const WALLS := "#lV"
const WALLS_AND_BOMB_ONLY := "#lVXO"
const MUST_REACH_WITHOUT_BREAKING := "EBIHSPR"
const REQUIRED := {
	TYPE_COMBAT: {"E": 2},
	TYPE_ITEM: {"I": 2},
	TYPE_HEALING: {"H": 1},
	TYPE_SIDE: {"T": 1},
	TYPE_MINI_BOSS: {"B": 1},
	TYPE_FLOOR_BOSS: {"B": 1},
	TYPE_TREASURE: {"I": 3},
	TYPE_SHOP: {"S": 5, "P": 1, "R": 7},
	TYPE_SECRET: {"T": 2},
}

@export var room_type: String = ""
@export var rows: PackedStringArray = []


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
			if on_border and symbol != SYMBOL_WALL and symbol != SYMBOL_LANTERN:
				errors.append("border must be wall at %d,%d" % [x, y])
			if symbol == SYMBOL_LANTERN and not _lantern_spot_ok(Vector2i(x, y), size):
				errors.append("a lantern needs a plain border wall cell at %d,%d" % [x, y])
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
	for side in SIDES:
		if not open.has(door_cell(side)):
			errors.append("needs a bomb to reach the door at %s" % str(door_cell(side)))
	return errors


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
