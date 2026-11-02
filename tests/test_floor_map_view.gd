extends TestCase


func _add(map: FloorMap, layer: int, room_type: String) -> FloorRoom:
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.layer = layer
	room.room_type = room_type
	map.rooms.append(room)
	return room


func test_a_lone_room_sits_in_the_middle_of_its_column() -> void:
	var map := FloorMap.new()
	var room := _add(map, 3, RoomLayout.TYPE_COMBAT)
	assert_eq(FloorMapView.map_position(map, room), Vector2(3, 0.5))


func test_two_rooms_in_a_layer_get_their_own_rows() -> void:
	var map := FloorMap.new()
	var first := _add(map, 1, RoomLayout.TYPE_COMBAT)
	var second := _add(map, 1, RoomLayout.TYPE_ITEM)
	assert_eq(FloorMapView.map_position(map, first), Vector2(1, 0))
	assert_eq(FloorMapView.map_position(map, second), Vector2(1, 1))


func test_side_rooms_sit_outside_their_parent() -> void:
	var map := FloorMap.new()
	var top := _add(map, 1, RoomLayout.TYPE_COMBAT)
	var bottom := _add(map, 1, RoomLayout.TYPE_COMBAT)
	var top_side := _add(map, 1, RoomLayout.TYPE_SIDE)
	top_side.parent_id = top.id
	var bottom_side := _add(map, 1, RoomLayout.TYPE_SIDE)
	bottom_side.parent_id = bottom.id
	assert_eq(FloorMapView.map_position(map, top_side), Vector2(1, -1))
	assert_eq(FloorMapView.map_position(map, bottom_side), Vector2(1, 2))


func test_a_side_room_does_not_count_as_a_row_in_its_layer() -> void:
	var map := FloorMap.new()
	var parent := _add(map, 2, RoomLayout.TYPE_COMBAT)
	var side := _add(map, 2, RoomLayout.TYPE_SIDE)
	side.parent_id = parent.id
	assert_eq(FloorMapView.map_position(map, parent), Vector2(2, 0.5))
	assert_eq(FloorMapView.map_position(map, side), Vector2(2, -0.5))


func test_treasure_room_sits_opposite_a_side_room() -> void:
	var map := FloorMap.new()
	var parent := _add(map, 2, RoomLayout.TYPE_COMBAT)
	var side := _add(map, 2, RoomLayout.TYPE_SIDE)
	side.parent_id = parent.id
	var treasure := _add(map, 2, RoomLayout.TYPE_TREASURE)
	treasure.parent_id = parent.id
	assert_eq(FloorMapView.map_position(map, side), Vector2(2, -0.5))
	assert_eq(FloorMapView.map_position(map, treasure), Vector2(2, 1.5))


func test_every_room_type_has_a_color() -> void:
	for room_type: String in RoomRules.ICONS:
		assert_true(FloorMapView.ROOM_COLORS.has(room_type), room_type)
