class_name CrossroadsView
extends RoomView

# The small first room of every run. Each path gets one exit and one sign, west and east. The door's
# target id is the path's index, because the floor it leads to is only built once it is chosen.
const SIDES_OF_PATHS: Array[Vector2i] = [RoomLayout.WEST, RoomLayout.EAST]
const SIGN_INSET := Vector2i(2, -1)

var _paths: Array[FloorDef] = []
var _floors_cleared := 0
var _signs: Array[PathSign] = []


static func sign_cell(layout: RoomLayout, side: Vector2i) -> Vector2i:
	return layout.door_cell(side) + Vector2i(-side.x * SIGN_INSET.x, SIGN_INSET.y)


func setup_paths(paths: Array[FloorDef], floors_cleared: int) -> void:
	_paths = paths
	_floors_cleared = floors_cleared


func side_of_path(index: int) -> Vector2i:
	return SIDES_OF_PATHS[index]


func sign_of_path(index: int) -> PathSign:
	return _signs[index]


func _create_doors() -> void:
	for i in _paths.size():
		var side := SIDES_OF_PATHS[i]
		var door := _add_door(i, "<" if side == RoomLayout.WEST else ">", side)
		door.chained = not _paths[i].is_open(_floors_cleared)
		var path_sign := PathSign.new()
		path_sign.setup(_paths[i], not door.chained, _player.feet(), side)
		path_sign.position = RoomBackdrop.cell_center(sign_cell(_room.layout, side))
		add_child(path_sign)
		_signs.append(path_sign)
