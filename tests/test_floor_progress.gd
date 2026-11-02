extends TestCase

# Room 0 at (1, 1) is joined to room 1 to its north, room 2 to its east, room 3 to its south and room 4 to its west.


func _layout(room_type: String, width := 20, height := 11) -> RoomLayout:
	var rows := PackedStringArray(["#".repeat(width)])
	for y in range(1, height - 1):
		rows.append("#" + ".".repeat(width - 2) + "#")
	rows.append("#".repeat(width))
	var layout := RoomLayout.new()
	layout.room_type = room_type
	layout.rows = rows
	return layout


func _add(map: FloorMap, room_type: String, cell: Vector2i, width := 20, height := 11) -> FloorRoom:
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.room_type = room_type
	room.cell = cell
	room.layout = _layout(room_type, width, height)
	map.rooms.append(room)
	return room


func _make_map() -> FloorMap:
	var map := FloorMap.new()
	var center := _add(map, RoomLayout.TYPE_COMBAT, Vector2i(1, 1))
	map.join(center, _add(map, RoomLayout.TYPE_COMBAT, Vector2i(1, 0), 14, 9))
	map.join(center, _add(map, RoomLayout.TYPE_ITEM, Vector2i(2, 1), 30, 17))
	map.join(center, _add(map, RoomLayout.TYPE_SIDE, Vector2i(1, 2)))
	map.join(center, _add(map, RoomLayout.TYPE_FLOOR_BOSS, Vector2i(0, 1)))
	map.start_id = 0
	map.boss_id = 4
	return map


func test_only_entered_rooms_are_visited() -> void:
	var progress := FloorProgress.new(_make_map())
	assert_false(progress.is_visited(0))
	progress.enter(0)
	assert_true(progress.is_visited(0))
	assert_false(progress.is_visited(1))
	assert_eq(progress.visited_ids(), [0] as Array[int])


func test_returning_to_a_room_does_not_list_it_twice() -> void:
	var progress := FloorProgress.new(_make_map())
	progress.enter(0)
	progress.enter(1)
	progress.enter(0)
	assert_eq(progress.visited_ids(), [0, 1] as Array[int])


func test_going_north_arrives_at_the_south_door_of_the_room_above() -> void:
	var map := _make_map()
	var progress := FloorProgress.new(map)
	assert_eq(progress.arrival_cell(1, 0), map.room(1).layout.door_cell(RoomLayout.SOUTH))


func test_going_each_way_arrives_at_the_opposite_door() -> void:
	var map := _make_map()
	var progress := FloorProgress.new(map)
	assert_eq(progress.arrival_cell(2, 0), map.room(2).layout.door_cell(RoomLayout.WEST))
	assert_eq(progress.arrival_cell(3, 0), map.room(3).layout.door_cell(RoomLayout.NORTH))
	assert_eq(progress.arrival_cell(4, 0), map.room(4).layout.door_cell(RoomLayout.EAST))


func test_arriving_back_starts_at_the_door_you_left_through() -> void:
	var map := _make_map()
	var progress := FloorProgress.new(map)
	var center := map.room(0).layout
	assert_eq(progress.arrival_cell(0, 1), center.door_cell(RoomLayout.NORTH))
	assert_eq(progress.arrival_cell(0, 2), center.door_cell(RoomLayout.EAST))
	assert_eq(progress.arrival_cell(0, 3), center.door_cell(RoomLayout.SOUTH))
	assert_eq(progress.arrival_cell(0, 4), center.door_cell(RoomLayout.WEST))


func test_the_arrival_cell_follows_the_size_of_the_room_entered() -> void:
	var progress := FloorProgress.new(_make_map())
	assert_eq(progress.arrival_cell(1, 0), Vector2i(7, 7), "small room's south door")
	assert_eq(progress.arrival_cell(2, 0), Vector2i(1, 8), "large room's west door")


func test_the_first_arrival_avoids_a_real_door_when_a_wall_is_free() -> void:
	var map := FloorMap.new()
	var start := _add(map, RoomLayout.TYPE_COMBAT, Vector2i(1, 1))
	map.join(start, _add(map, RoomLayout.TYPE_COMBAT, Vector2i(1, 2)))
	var cell := FloorProgress.new(map).arrival_cell(0, -1)
	assert_true(cell != start.layout.door_cell(RoomLayout.SOUTH), "not on the real door")
	assert_true(cell in [start.layout.door_cell(RoomLayout.WEST), start.layout.door_cell(RoomLayout.NORTH), start.layout.door_cell(RoomLayout.EAST)])


func test_the_first_arrival_still_lands_on_a_door_cell_with_a_door_on_every_wall() -> void:
	var map := _make_map()
	var layout := map.room(0).layout
	var cell := FloorProgress.new(map).arrival_cell(0, -1)
	assert_true(cell in [layout.door_cell(RoomLayout.NORTH), layout.door_cell(RoomLayout.EAST), layout.door_cell(RoomLayout.SOUTH), layout.door_cell(RoomLayout.WEST)])


func test_a_built_floor_can_be_walked_through_every_door_and_back() -> void:
	var def: FloorDef = load("res://data/floors/floor_1.tres")
	var pool := RoomCatalog.load_valid(def.rooms_dir)
	for seed_value in 50:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var map := FloorBuilder.build_from_pool(rng, def, pool)
		var progress := FloorProgress.new(map)
		for room in map.rooms:
			for side: Vector2i in room.doors:
				var other := map.room(room.doors[side])
				assert_eq(progress.arrival_cell(other.id, room.id), other.layout.door_cell(-side), "seed %d" % seed_value)
				assert_eq(progress.arrival_cell(room.id, other.id), room.layout.door_cell(side), "seed %d" % seed_value)


func test_the_map_knows_about_unvisited_treasure() -> void:
	var map := _make_map()
	var treasure := _add(map, RoomLayout.TYPE_TREASURE, Vector2i(2, 0))
	map.join(map.room(1), treasure)
	var progress := FloorProgress.new(map)
	assert_true(map.has_unvisited_treasure(progress))
	progress.enter(treasure.id)
	assert_false(map.has_unvisited_treasure(progress))
