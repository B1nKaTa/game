class_name WalkGrid
extends RefCounted

# Which cells of a room an enemy can walk, and the way around whatever stands between it and
# Grandpa. Props count as blocked even once broken, which at worst makes a route a little longer.
const NO_CELL := Vector2i(-1, -1)
const UNREACHED := -1
# Straight steps first, so a tie goes the plain way. A diagonal step may not cut a blocked corner.
const STEPS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
# A straight line is checked this often, in pixels, so it never skips the corner of a cell.
const LINE_STEP := 8.0

var size := Vector2i.ZERO
var _solid := PackedByteArray()
# Steps from every cell to the last goal, kept until the goal moves, so a room's enemies share it.
var _goal := NO_CELL
var _steps := PackedInt32Array()


static func from_layout(layout: RoomLayout) -> WalkGrid:
	return from_rows(layout.rows, RoomLayout.SOLID_SYMBOLS)


static func from_rows(rows: PackedStringArray, solid_symbols: String) -> WalkGrid:
	var grid := WalkGrid.new()
	grid.size = Vector2i(rows[0].length() if not rows.is_empty() else 0, rows.size())
	grid._solid.resize(grid.size.x * grid.size.y)
	for y in grid.size.y:
		for x in grid.size.x:
			grid._solid[y * grid.size.x + x] = 1 if solid_symbols.contains(rows[y][x]) else 0
	return grid


static func cell_of(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / RoomBackdrop.TILE), floori(point.y / RoomBackdrop.TILE))


func is_open(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= size.x or cell.y >= size.y:
		return false
	return _solid[cell.y * size.x + cell.x] == 0


# A broken prop no longer blocks. Routes are worked out again on the next ask.
func open_cell(cell: Vector2i) -> void:
	if cell.x < 0 or cell.y < 0 or cell.x >= size.x or cell.y >= size.y:
		return
	_solid[cell.y * size.x + cell.x] = 0
	_steps = PackedInt32Array()


# Whether a body this wide could walk the straight line without touching a blocked cell.
func line_is_clear(from: Vector2, to: Vector2, half_width: float) -> bool:
	var along := to - from
	var side := along.orthogonal().normalized() * half_width if not along.is_zero_approx() else Vector2.ZERO
	var count := maxi(1, ceili(along.length() / LINE_STEP))
	for i in count + 1:
		var point := from + along * (i / float(count))
		if not (is_open(cell_of(point)) and is_open(cell_of(point - side)) and is_open(cell_of(point + side))):
			return false
	return true


# The neighbouring cell to walk to next on a shortest way to the goal, or NO_CELL when there is none.
func next_cell(from: Vector2i, goal: Vector2i) -> Vector2i:
	if from == goal:
		return goal
	_flood(goal)
	var best := NO_CELL
	var best_steps := steps_to_goal(from) if is_open(from) else UNREACHED
	for step in STEPS:
		var cell := from + step
		var steps := steps_to_goal(cell)
		if steps == UNREACHED:
			continue
		# Standing somewhere counted as blocked, such as a broken prop's cell, any open neighbour will do.
		if is_open(from) and not _can_step(from, step):
			continue
		if best_steps == UNREACHED or steps < best_steps:
			best = cell
			best_steps = steps
	return best


# Where in a cell a body of this half size should aim, so it fits between whatever blocks the
# cells beside it. A body taller than a cell aims off the middle of a two-cell gap, since aiming
# at a cell's middle would press its head into the wall above and stop it there for good.
func fit_point(cell: Vector2i, half_size: Vector2) -> Vector2:
	var tile := float(RoomBackdrop.TILE)
	var center := RoomBackdrop.cell_center(cell)
	var left := cell.x * tile if not is_open(cell + Vector2i.LEFT) else (cell.x - 1) * tile
	var right := (cell.x + 1) * tile if not is_open(cell + Vector2i.RIGHT) else (cell.x + 2) * tile
	var top := cell.y * tile if not is_open(cell + Vector2i.UP) else (cell.y - 1) * tile
	var bottom := (cell.y + 1) * tile if not is_open(cell + Vector2i.DOWN) else (cell.y + 2) * tile
	return Vector2(_fit(center.x, left, right, half_size.x), _fit(center.y, top, bottom, half_size.y))


static func _fit(middle: float, low: float, high: float, half: float) -> float:
	if high - low < half * 2.0:
		return (low + high) / 2.0
	return clampf(middle, low + half, high - half)


# How many steps a cell is from the goal last asked for, or UNREACHED.
func steps_to_goal(cell: Vector2i) -> int:
	if cell.x < 0 or cell.y < 0 or cell.x >= size.x or cell.y >= size.y or _steps.is_empty():
		return UNREACHED
	return _steps[cell.y * size.x + cell.x]


func _can_step(cell: Vector2i, step: Vector2i) -> bool:
	if not is_open(cell + step):
		return false
	if step.x != 0 and step.y != 0:
		return is_open(cell + Vector2i(step.x, 0)) and is_open(cell + Vector2i(0, step.y))
	return true


# A breadth-first fill out from the goal. The goal itself counts even if blocked, since Grandpa
# can stand where a prop once was.
func _flood(goal: Vector2i) -> void:
	if goal == _goal and not _steps.is_empty():
		return
	_goal = goal
	_steps = PackedInt32Array()
	_steps.resize(size.x * size.y)
	_steps.fill(UNREACHED)
	if goal.x < 0 or goal.y < 0 or goal.x >= size.x or goal.y >= size.y:
		return
	_steps[goal.y * size.x + goal.x] = 0
	var queue: Array[Vector2i] = [goal]
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		var here := _steps[cell.y * size.x + cell.x]
		for step in STEPS:
			var next := cell + step
			if not _can_step(cell, step) or _steps[next.y * size.x + next.x] != UNREACHED:
				continue
			_steps[next.y * size.x + next.x] = here + 1
			queue.append(next)
