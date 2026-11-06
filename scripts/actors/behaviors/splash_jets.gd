class_name SplashJets
extends RefCounted

# Jets of water that burst up through warned spots near Grandpa and leave the floor round each wet for
# a while, as the Commodore's deck wash does; and the doorway cells a room keeps clear of anything laid
# on its floor. Pure rules, shared by the bosses that use them.
# How far from his cell, in cells, a jet may come up, and how far apart two jets keep.
const SPLASH_REACH := 3
const SPLASH_APART := 2
const SPLASH_TRIES := 40


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


# Every cell of a room that may be wet, for a whole floor of rain.
static func wet_room(room_cells: Vector2i, is_open := Callable()) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(1, room_cells.y - 1):
		for x in range(1, room_cells.x - 1):
			if can_be_wet(Vector2i(x, y), room_cells, is_open):
				cells.append(Vector2i(x, y))
	return cells
