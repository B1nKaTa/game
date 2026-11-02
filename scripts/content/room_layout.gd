class_name RoomLayout
extends Resource

const TYPE_COMBAT := "combat"
const TYPE_ITEM := "item"
const TYPE_HEALING := "healing"
const TYPE_SIDE := "side"
const TYPE_MINI_BOSS := "mini_boss"
const TYPE_FLOOR_BOSS := "floor_boss"
const WIDTH := 20
const HEIGHT := 11
const ENTRY := Vector2i(1, 5)
const EXIT_A := Vector2i(18, 3)
const EXIT_B := Vector2i(18, 7)
const SIDE_DOOR := Vector2i(10, 1)
const ALLOWED := "#.EIHTB"
const REQUIRED := {
	TYPE_COMBAT: {"E": 2},
	TYPE_ITEM: {"I": 2},
	TYPE_HEALING: {"H": 1},
	TYPE_SIDE: {"T": 1},
	TYPE_MINI_BOSS: {"B": 1},
	TYPE_FLOOR_BOSS: {"B": 1},
}

@export var room_type: String = ""
@export var rows: PackedStringArray = []


func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	if not REQUIRED.has(room_type):
		errors.append("unknown room type '%s'" % room_type)
		return errors
	if rows.size() != HEIGHT:
		errors.append("expected %d rows" % HEIGHT)
		return errors
	for y in HEIGHT:
		if rows[y].length() != WIDTH:
			errors.append("row %d must have %d cells" % [y, WIDTH])
			return errors
		for x in WIDTH:
			var symbol := rows[y][x]
			if not ALLOWED.contains(symbol):
				errors.append("unknown symbol '%s' at %d,%d" % [symbol, x, y])
			var on_border := x == 0 or y == 0 or x == WIDTH - 1 or y == HEIGHT - 1
			if on_border and symbol != "#":
				errors.append("border must be wall at %d,%d" % [x, y])
	if not errors.is_empty():
		return errors
	var required: Dictionary = REQUIRED[room_type]
	for symbol in required:
		if cells_of(symbol).size() < required[symbol]:
			errors.append("needs at least %d '%s'" % [required[symbol], symbol])
	for anchor in [ENTRY, EXIT_A, EXIT_B, SIDE_DOOR]:
		if rows[anchor.y][anchor.x] != ".":
			errors.append("door cell must be floor at %s" % str(anchor))
	if not errors.is_empty():
		return errors
	var reachable := _flood_from_entry()
	for y in HEIGHT:
		for x in WIDTH:
			var cell := Vector2i(x, y)
			if rows[y][x] != "#" and not reachable.has(cell):
				errors.append("cell cannot be reached at %s" % str(cell))
	return errors


func cells_of(symbol: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in rows.size():
		for x in rows[y].length():
			if rows[y][x] == symbol:
				cells.append(Vector2i(x, y))
	return cells


func _flood_from_entry() -> Dictionary:
	var seen := {ENTRY: true}
	var open: Array[Vector2i] = [ENTRY]
	while not open.is_empty():
		var cell: Vector2i = open.pop_back()
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if seen.has(next) or rows[next.y][next.x] == "#":
				continue
			seen[next] = true
			open.append(next)
	return seen
