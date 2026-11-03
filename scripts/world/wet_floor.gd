class_name WetFloor
extends Area2D

# A freshly mopped cell. It never hurts anyone, but Grandpa and charging enemies slide on it.
# Whether a point is wet is a plain rectangle test, so it answers the same on every frame.
const GROUP := "wet_floors"
const SHEEN_LINES := 3

var palette: RoomPalette


# Any wet cell under a point, from a list of wet floors, so tests need no scene tree.
static func any_covers(floors: Array, point: Vector2) -> bool:
	for wet in floors:
		if is_instance_valid(wet) and wet.covers(point):
			return true
	return false


static func is_wet_at(tree: SceneTree, point: Vector2) -> bool:
	if tree == null:
		return false
	return any_covers(tree.get_nodes_in_group(GROUP), point)


# One "Caution: Wet" sign per patch of touching wet cells, on plain floor right beside it.
# A patch with no plain floor beside it, clear of the doors, gets none.
static func sign_cells(layout: RoomLayout) -> Array[Vector2i]:
	var signs: Array[Vector2i] = []
	var seen := {}
	for start in layout.cells_of(RoomLayout.SYMBOL_WET):
		if seen.has(start):
			continue
		var patch: Array[Vector2i] = []
		var open: Array[Vector2i] = [start]
		seen[start] = true
		while not open.is_empty():
			var cell: Vector2i = open.pop_back()
			patch.append(cell)
			for side in RoomLayout.SIDES:
				var next: Vector2i = cell + side
				if not seen.has(next) and layout.symbol_at(next) == RoomLayout.SYMBOL_WET:
					seen[next] = true
					open.append(next)
		patch.sort()
		var found := false
		for cell in patch:
			for side: Vector2i in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
				var spot: Vector2i = cell + side
				if layout.symbol_at(spot) == RoomLayout.SYMBOL_FLOOR and not layout.touches_a_door(spot) and not signs.has(spot):
					signs.append(spot)
					found = true
					break
			if found:
				break
	return signs


func _ready() -> void:
	add_to_group(GROUP)
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(RoomBackdrop.TILE, RoomBackdrop.TILE)
	shape.shape = rect
	add_child(shape)
	z_index = -9
	queue_redraw()


func covers(point: Vector2) -> bool:
	var half := RoomBackdrop.TILE / 2.0
	return Rect2(global_position - Vector2(half, half), Vector2(RoomBackdrop.TILE, RoomBackdrop.TILE)).has_point(point)


func _draw() -> void:
	var p := palette if palette != null else RoomPalette.new()
	var half := RoomBackdrop.TILE / 2.0
	draw_rect(Rect2(-half, -half, RoomBackdrop.TILE, RoomBackdrop.TILE), p.wet)
	# A few bright streaks read as a shine on the floor, not as a hole or a puddle.
	for i in SHEEN_LINES:
		var y := -half + 7.0 + i * 9.0
		var x := -half + 4.0 + (i % 2) * 6.0
		draw_line(Vector2(x, y + 4.0), Vector2(x + 12.0, y), p.wet_shine, 1.0)
