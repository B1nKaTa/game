class_name SandTrap
extends Area2D

# One cell of a sand bunker on the golf course. Everyone who walks on the floor wades through it slower,
# and Grandpa cannot dodge while he stands in it. It never hurts anyone. Ghosts float over it, and
# anything underground or bolted to a wall never wades. Whether a point is in sand is a plain rectangle
# test, as for a wet floor, so it answers the same on every frame.
#
# Its look is grain: a pale bed scattered with dark and light dots. The course's own fairway is drawn
# only in broad mown stripes, with no dots, so sand never reads as floor and floor never reads as sand.
const GROUP := "sand_traps"
const GRAINS := 14
const LIGHT_GRAINS := 6

var palette: RoomPalette


# Any sand under a point, from a list of sand cells, so tests need no scene tree.
static func any_covers(traps: Array, point: Vector2) -> bool:
	for trap in traps:
		if is_instance_valid(trap) and trap.covers(point):
			return true
	return false


static func is_sand_at(tree: SceneTree, point: Vector2) -> bool:
	if tree == null:
		return false
	return any_covers(tree.get_nodes_in_group(GROUP), point)


# Whether an enemy wades slower here: anything walking on the floor, a boss too. A ghost, a mound and
# a wall fixture never touch the sand.
static func slows(enemy: Enemy) -> bool:
	if not wades(enemy.def, enemy.submerged) or not enemy.is_inside_tree():
		return false
	return is_sand_at(enemy.get_tree(), enemy.global_position)


# Whether a kind of enemy walks through sand at all, as it is now.
static func wades(def: EnemyDef, submerged: bool) -> bool:
	return def != null and not def.ignores_walls and not def.wall_mounted and not submerged


# Where the grains of a cell lie, fixed by the cell, so a bunker never shimmers.
static func grain_spots(cell: Vector2i, count: int) -> Array[Vector2]:
	var spots: Array[Vector2] = []
	var half := RoomBackdrop.TILE / 2.0
	for i in count:
		var x := RoomDecor.noise(cell + Vector2i(i * 7, 3), 211) * (RoomBackdrop.TILE - 4.0) - half + 2.0
		var y := RoomDecor.noise(cell + Vector2i(5, i * 11), 223) * (RoomBackdrop.TILE - 4.0) - half + 2.0
		spots.append(Vector2(x, y))
	return spots


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
	draw_rect(Rect2(-half, -half, RoomBackdrop.TILE, RoomBackdrop.TILE), p.sand)
	var cell: Vector2i = WalkGrid.cell_of(global_position) if is_inside_tree() else WalkGrid.cell_of(position)
	var spots := grain_spots(cell, GRAINS + LIGHT_GRAINS)
	for i in spots.size():
		var color: Color = p.sand_grain if i < GRAINS else p.sand_shine
		draw_rect(Rect2(spots[i], Vector2(1.5, 1.5)), color)
