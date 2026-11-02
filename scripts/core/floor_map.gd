class_name FloorMap
extends RefCounted

var rooms: Array[FloorRoom] = []
var start_id: int = 0
var boss_id: int = 0
var main_path: Array[int] = []


func room(id: int) -> FloorRoom:
	return rooms[id]


func room_at(cell: Vector2i) -> FloorRoom:
	for candidate in rooms:
		if candidate.cell == cell:
			return candidate
	return null


func main_rooms() -> Array[FloorRoom]:
	var list: Array[FloorRoom] = []
	for candidate in rooms:
		if not candidate.is_detour():
			list.append(candidate)
	return list


func join(a: FloorRoom, b: FloorRoom) -> void:
	var side := b.cell - a.cell
	a.doors[side] = b.id
	b.doors[-side] = a.id


func bounds() -> Rect2i:
	var box := Rect2i(rooms[0].cell, Vector2i.ONE)
	for candidate in rooms:
		box = box.merge(Rect2i(candidate.cell, Vector2i.ONE))
	return box


func has_unvisited_treasure(progress: FloorProgress) -> bool:
	for candidate in rooms:
		if candidate.room_type == RoomLayout.TYPE_TREASURE and not progress.is_visited(candidate.id):
			return true
	return false


# The rooms a player can walk to from the start before ever owning a Thermos.
func reached_without_bomb() -> Dictionary:
	var hidden_ids: Array[int] = []
	for candidate in rooms:
		if candidate.needs_a_bomb():
			hidden_ids.append(candidate.id)
	return walk_from(start_id, hidden_ids)


# Every room except the ones that wait behind a cracked wall or a reinforced stone must be walkable
# without a bomb, so a floor is always fully winnable and fully reachable without either.
func only_hidden_rooms_need_a_bomb() -> bool:
	var reached := reached_without_bomb()
	for candidate in rooms:
		if not candidate.needs_a_bomb() and not reached.has(candidate.id):
			return false
	return true


# A hidden room is a dead end: one door, back to the room it hangs off.
func hidden_rooms_are_dead_ends() -> bool:
	for candidate in rooms:
		if candidate.needs_a_bomb() and candidate.doors.size() != 1:
			return false
	return true


func walk_from(from_id: int, avoid: Array[int] = []) -> Dictionary:
	var seen := {from_id: true}
	var open: Array[int] = [from_id]
	while not open.is_empty():
		for next_id: int in room(open.pop_back()).doors.values():
			if not seen.has(next_id) and not avoid.has(next_id):
				seen[next_id] = true
				open.append(next_id)
	return seen


# The next room on the shortest way between two rooms, or from_id when there is no way.
func next_step(from_id: int, to_id: int) -> int:
	var came_from := {to_id: -1}
	var open: Array[int] = [to_id]
	while not open.is_empty():
		var at: int = open.pop_front()
		if at == from_id:
			return came_from[at] if came_from[at] != -1 else from_id
		for next_id: int in room(at).doors.values():
			if not came_from.has(next_id):
				came_from[next_id] = at
				open.append(next_id)
	return from_id
