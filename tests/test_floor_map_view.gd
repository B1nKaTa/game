extends TestCase


func _add(map: FloorMap, room_type: String, cell: Vector2i) -> FloorRoom:
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.room_type = room_type
	room.cell = cell
	map.rooms.append(room)
	return room


func test_a_room_is_drawn_at_its_grid_cell_from_the_corner_of_the_floor() -> void:
	var map := FloorMap.new()
	_add(map, RoomLayout.TYPE_COMBAT, Vector2i(3, 2))
	var far := _add(map, RoomLayout.TYPE_ITEM, Vector2i(5, 6))
	assert_eq(FloorMapView.map_position(map, far), Vector2(2, 4))


func test_the_big_map_fits_every_built_floor_in_its_panel() -> void:
	var def: FloorDef = load("res://data/floors/floor_1.tres")
	var pool := RoomCatalog.load_valid(def.rooms_dir)
	for seed_value in 100:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var map := FloorBuilder.build_from_pool(rng, def, pool)
		var extent := map.bounds().size
		var spacing := FloorMapView.big_spacing(extent)
		var origin := FloorMapView.big_origin(extent, spacing)
		for room in map.rooms:
			var rect := FloorMapView.room_rect(FloorMapView.map_position(map, room), origin, spacing)
			assert_true(FloorMapView.BIG_AREA.encloses(rect), "seed %d %s" % [seed_value, str(rect)])


func test_the_big_map_keeps_rooms_tall_enough_for_their_icons() -> void:
	var spacing := FloorMapView.big_spacing(FloorDef.new().grid_size)
	assert_true(FloorMapView.room_size(spacing).y >= 16.0, str(spacing))


func test_the_mini_map_centers_on_the_current_room() -> void:
	var origin := FloorMapView.mini_origin(Vector2(4, 2))
	var rect := FloorMapView.room_rect(Vector2(4, 2), origin, FloorMapView.MINI_SPACING)
	assert_eq(rect.get_center(), FloorMapView.MINI_RECT.get_center())


func test_rooms_keep_a_gap_their_door_link_can_show_in() -> void:
	for spacing: Vector2 in [FloorMapView.MINI_SPACING, FloorMapView.BIG_SPACING]:
		var left := FloorMapView.room_rect(Vector2(0, 0), Vector2.ZERO, spacing)
		var right := FloorMapView.room_rect(Vector2(1, 0), Vector2.ZERO, spacing)
		var below := FloorMapView.room_rect(Vector2(0, 1), Vector2.ZERO, spacing)
		assert_true(left.end.x < right.position.x, str(spacing))
		assert_true(left.end.y < below.position.y, str(spacing))


func test_every_room_type_has_a_color() -> void:
	for room_type: String in RoomRules.ICONS:
		assert_true(FloorMapView.ROOM_COLORS.has(room_type), room_type)
