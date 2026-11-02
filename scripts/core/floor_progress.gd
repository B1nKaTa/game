class_name FloorProgress
extends RefCounted

var _map: FloorMap
var _visited: Array[int] = []
var _came_from := {}
var _chosen_in_layer := {}


func _init(map: FloorMap) -> void:
	_map = map


func enter(room_id: int, from_id := -1) -> void:
	if is_visited(room_id):
		return
	_visited.append(room_id)
	_came_from[room_id] = from_id
	var room := _map.room(room_id)
	if room.room_type != RoomLayout.TYPE_SIDE:
		_chosen_in_layer[room.layer] = room_id


func is_visited(room_id: int) -> bool:
	return _visited.has(room_id)


func visited_ids() -> Array[int]:
	return _visited


func is_sealed(room_id: int) -> bool:
	var room := _map.room(room_id)
	if room.room_type == RoomLayout.TYPE_SIDE:
		return false
	return _chosen_in_layer.get(room.layer, room_id) != room_id


func previous_of(room_id: int) -> int:
	var room := _map.room(room_id)
	if room.room_type == RoomLayout.TYPE_SIDE:
		return room.parent_id
	return _came_from.get(room_id, -1)


func back_target(room_id: int) -> int:
	if _map.room(room_id).room_type == RoomLayout.TYPE_FLOOR_BOSS:
		return -1
	return previous_of(room_id)


func arrival_cell(to_id: int, from_id: int) -> Vector2i:
	var to_room := _map.room(to_id)
	if to_room.room_type == RoomLayout.TYPE_SIDE:
		return RoomLayout.SIDE_ROOM_SPAWN
	if from_id == -1:
		return RoomLayout.ENTRY
	var from_room := _map.room(from_id)
	if from_room.room_type == RoomLayout.TYPE_SIDE:
		return RoomLayout.SIDE_DOOR
	if to_room.layer > from_room.layer:
		return RoomLayout.ENTRY
	return RoomLayout.EXIT_CELLS[to_room.exits.find(from_id)]
