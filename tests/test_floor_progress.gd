extends TestCase

# Layer 0: room 0. Layer 1: rooms 1 and 2. Layer 2: room 3, the floor boss. Room 4 is a side room of room 1.


func _make_map() -> FloorMap:
	var map := FloorMap.new()
	_add(map, 0, RoomLayout.TYPE_COMBAT, [1, 2])
	_add(map, 1, RoomLayout.TYPE_COMBAT, [3])
	_add(map, 1, RoomLayout.TYPE_ITEM, [3])
	_add(map, 2, RoomLayout.TYPE_FLOOR_BOSS, [])
	var side := _add(map, 1, RoomLayout.TYPE_SIDE, [])
	side.parent_id = 1
	map.room(1).side_id = side.id
	map.start_id = 0
	map.boss_id = 3
	return map


func _add(map: FloorMap, layer: int, room_type: String, exits: Array[int]) -> FloorRoom:
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.layer = layer
	room.room_type = room_type
	room.exits = exits
	map.rooms.append(room)
	return room


func test_only_entered_rooms_are_visited() -> void:
	var progress := FloorProgress.new(_make_map())
	assert_false(progress.is_visited(0))
	progress.enter(0)
	assert_true(progress.is_visited(0))
	assert_false(progress.is_visited(1))
	assert_eq(progress.visited_ids(), [0] as Array[int])


func test_choosing_a_route_seals_the_other_one() -> void:
	var progress := FloorProgress.new(_make_map())
	progress.enter(0)
	assert_false(progress.is_sealed(1), "nothing chosen yet")
	assert_false(progress.is_sealed(2), "nothing chosen yet")
	progress.enter(1, 0)
	assert_false(progress.is_sealed(1), "the chosen route stays open")
	assert_true(progress.is_sealed(2))


func test_side_rooms_are_never_sealed() -> void:
	var progress := FloorProgress.new(_make_map())
	progress.enter(0)
	progress.enter(1, 0)
	progress.enter(4, 1)
	assert_false(progress.is_sealed(4))


func test_going_back_keeps_the_route_sealed() -> void:
	var progress := FloorProgress.new(_make_map())
	progress.enter(0)
	progress.enter(2, 0)
	progress.enter(0, 2)
	assert_true(progress.is_sealed(1))
	assert_false(progress.is_sealed(2))


func test_going_back_does_not_change_where_a_room_was_entered_from() -> void:
	var progress := FloorProgress.new(_make_map())
	progress.enter(0)
	progress.enter(1, 0)
	progress.enter(3, 1)
	progress.enter(1, 3)
	assert_eq(progress.previous_of(1), 0)


func test_start_room_has_no_way_back() -> void:
	var progress := FloorProgress.new(_make_map())
	progress.enter(0)
	assert_eq(progress.back_target(0), -1)


func test_main_room_goes_back_to_the_room_it_was_entered_from() -> void:
	var progress := FloorProgress.new(_make_map())
	progress.enter(0)
	progress.enter(2, 0)
	assert_eq(progress.back_target(2), 0)


func test_side_room_goes_back_to_its_parent() -> void:
	var progress := FloorProgress.new(_make_map())
	progress.enter(0)
	progress.enter(1, 0)
	progress.enter(4, 1)
	assert_eq(progress.back_target(4), 1)
	assert_eq(progress.previous_of(4), 1)


func test_floor_boss_room_has_no_way_back() -> void:
	var progress := FloorProgress.new(_make_map())
	progress.enter(0)
	progress.enter(1, 0)
	progress.enter(3, 1)
	assert_eq(progress.back_target(3), -1)
	assert_eq(progress.previous_of(3), 1, "the map still links it to the route")


func test_arriving_forward_starts_at_the_return_door() -> void:
	var progress := FloorProgress.new(_make_map())
	assert_eq(progress.arrival_cell(0, -1), RoomLayout.ENTRY)
	assert_eq(progress.arrival_cell(1, 0), RoomLayout.ENTRY)


func test_arriving_back_starts_at_the_door_you_left_through() -> void:
	var progress := FloorProgress.new(_make_map())
	assert_eq(progress.arrival_cell(0, 1), RoomLayout.EXIT_A)
	assert_eq(progress.arrival_cell(0, 2), RoomLayout.EXIT_B)


func test_arriving_from_a_side_room_starts_at_the_side_door() -> void:
	var progress := FloorProgress.new(_make_map())
	assert_eq(progress.arrival_cell(1, 4), RoomLayout.SIDE_DOOR)


func test_arriving_in_a_side_room_uses_its_spawn_cell() -> void:
	var progress := FloorProgress.new(_make_map())
	assert_eq(progress.arrival_cell(4, 1), RoomLayout.SIDE_ROOM_SPAWN)


func _map_with_treasure() -> FloorMap:
	var map := _make_map()
	var treasure := _add(map, 1, RoomLayout.TYPE_TREASURE, [])
	treasure.parent_id = 1
	map.room(1).treasure_id = treasure.id
	return map


func test_treasure_room_behaves_like_a_detour() -> void:
	var progress := FloorProgress.new(_map_with_treasure())
	progress.enter(0)
	progress.enter(1, 0)
	progress.enter(5, 1)
	assert_false(progress.is_sealed(5))
	assert_false(progress.is_sealed(1), "entering it doesn't choose a route")
	assert_eq(progress.back_target(5), 1)
	assert_eq(progress.previous_of(5), 1)


func test_arriving_around_a_treasure_room() -> void:
	var progress := FloorProgress.new(_map_with_treasure())
	assert_eq(progress.arrival_cell(5, 1), RoomLayout.SIDE_ROOM_SPAWN)
	assert_eq(progress.arrival_cell(1, 5), RoomLayout.TREASURE_DOOR)


func test_a_built_floor_can_be_walked_forward_and_back_without_dead_ends() -> void:
	var pool := RoomCatalog.load_valid("res://data/rooms/floor_1/")
	for seed_value in 50:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var map := FloorBuilder.build(rng, pool)
		var progress := FloorProgress.new(map)
		var current := map.start_id
		progress.enter(current)
		var steps := 0
		while current != map.boss_id:
			var options: Array[int] = []
			for exit_id in map.room(current).exits:
				if not progress.is_sealed(exit_id):
					options.append(exit_id)
			assert_false(options.is_empty(), "seed %d stuck in room %d" % [seed_value, current])
			if options.is_empty():
				return
			var next := options[rng.randi_range(0, options.size() - 1)]
			progress.enter(next, current)
			current = next
			steps += 1
		while progress.back_target(current) != -1 or current == map.boss_id:
			var back := progress.previous_of(current)
			if back == -1:
				break
			assert_false(progress.is_sealed(back), "seed %d back into a sealed room" % seed_value)
			current = back
		assert_eq(current, map.start_id, "seed %d did not walk back to the start" % seed_value)
