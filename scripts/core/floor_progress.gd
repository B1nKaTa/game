class_name FloorProgress
extends RefCounted

const FIRST_ARRIVAL_SIDES: Array[Vector2i] = [RoomLayout.SOUTH, RoomLayout.WEST, RoomLayout.EAST, RoomLayout.NORTH]

var _map: FloorMap
var _visited: Array[int] = []


func _init(map: FloorMap) -> void:
	_map = map


func enter(room_id: int) -> void:
	if not is_visited(room_id):
		_visited.append(room_id)


func is_visited(room_id: int) -> bool:
	return _visited.has(room_id)


func visited_ids() -> Array[int]:
	return _visited


# Grandpa arrives on the door leading back the way he came.
func arrival_cell(to_id: int, from_id: int) -> Vector2i:
	var to_room := _map.room(to_id)
	var side := to_room.side_towards(from_id)
	if side != Vector2i.ZERO:
		return to_room.layout.door_cell(side)
	for free_side in FIRST_ARRIVAL_SIDES:
		if not to_room.doors.has(free_side):
			return to_room.layout.door_cell(free_side)
	return to_room.layout.door_cell(FIRST_ARRIVAL_SIDES[0])
