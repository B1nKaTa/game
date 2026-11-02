class_name FloorMap
extends RefCounted

var rooms: Array[FloorRoom] = []
var start_id: int = 0
var boss_id: int = 0


func room(id: int) -> FloorRoom:
	return rooms[id]


func main_rooms() -> Array[FloorRoom]:
	var list: Array[FloorRoom] = []
	for candidate in rooms:
		if not candidate.is_detour():
			list.append(candidate)
	return list


func has_unvisited_treasure(progress: FloorProgress) -> bool:
	for candidate in rooms:
		if candidate.room_type == RoomLayout.TYPE_TREASURE and not progress.is_visited(candidate.id):
			return true
	return false


func reaches_boss_from_everywhere() -> bool:
	var from_start := _walk(start_id)
	for candidate in main_rooms():
		if not from_start.has(candidate.id):
			return false
		if not _walk(candidate.id).has(boss_id):
			return false
	return true


func _walk(from_id: int) -> Dictionary:
	var seen := {from_id: true}
	var open: Array[int] = [from_id]
	while not open.is_empty():
		for exit_id in room(open.pop_back()).exits:
			if not seen.has(exit_id):
				seen[exit_id] = true
				open.append(exit_id)
	return seen
