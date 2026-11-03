class_name WetSplash
extends Node2D

# The wet floor a fountain jet leaves: a patch of mopped-looking cells that Grandpa and chargers slide
# on, as on any wet floor, until it dries and the patch takes itself up. It lies at the room's origin,
# with each wet cell at its own cell's middle.
var _cells: Array[Vector2i] = []
var _left := 4.0
var _palette: RoomPalette


func setup(cells: Array[Vector2i], seconds: float, palette: RoomPalette = null) -> void:
	_cells = cells
	_left = seconds
	_palette = palette


func _ready() -> void:
	for cell in _cells:
		var wet := WetFloor.new()
		wet.palette = _palette
		wet.position = RoomBackdrop.cell_center(cell)
		add_child(wet)


func wet_floors() -> Array:
	var floors: Array = []
	for child in get_children():
		if child is WetFloor:
			floors.append(child)
	return floors


# True once, as it dries.
func advance(delta: float) -> bool:
	if _left <= 0.0:
		return false
	_left -= delta
	return _left <= 0.0


func _process(delta: float) -> void:
	if advance(delta):
		queue_free()
