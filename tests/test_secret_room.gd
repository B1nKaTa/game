extends TestCase


func _def() -> FloorDef:
	return load("res://data/floors/floor_1.tres")


func _pool() -> Array[RoomLayout]:
	return RoomCatalog.load_valid(_def().rooms_dir)


func _build(seed_value: int, pool: Array[RoomLayout]) -> FloorMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return FloorBuilder.build_from_pool(rng, _def(), pool)


func test_a_floor_has_at_most_one_secret_room_off_a_combat_room() -> void:
	var pool := _pool()
	var floors_with_one := 0
	for seed_value in 300:
		var map := _build(seed_value, pool)
		var found := 0
		for room in map.rooms:
			if room.room_type != RoomLayout.TYPE_SECRET:
				continue
			found += 1
			assert_true(room.is_detour())
			assert_eq(room.doors.size(), 1, "seed %d" % seed_value)
			assert_eq(map.room(room.doors.values()[0]).room_type, RoomLayout.TYPE_COMBAT)
		assert_true(found <= 1, "seed %d" % seed_value)
		floors_with_one += found
	assert_true(floors_with_one > 250, "most floors should have one, had %d" % floors_with_one)


func test_nothing_but_a_secret_room_needs_a_bomb_to_reach() -> void:
	var pool := _pool()
	for seed_value in 100:
		var map := _build(seed_value, pool)
		for room in map.rooms:
			if room.room_type == RoomLayout.TYPE_SECRET:
				assert_false(map.reached_without_bomb().has(room.id), "seed %d" % seed_value)


func test_a_secret_room_does_not_count_as_a_main_room() -> void:
	for room in _build(2, _pool()).main_rooms():
		assert_false(room.is_detour())


func _layout(room_type: String) -> RoomLayout:
	var rows := PackedStringArray(["####################"])
	for y in range(1, 10):
		rows.append("#..................#")
	rows.append("####################")
	var layout := RoomLayout.new()
	layout.room_type = room_type
	layout.rows = rows
	return layout


func _map_with_secret() -> FloorMap:
	var map := FloorMap.new()
	var parent := FloorRoom.new()
	parent.id = 0
	parent.room_type = RoomLayout.TYPE_COMBAT
	parent.layout = _layout(RoomLayout.TYPE_COMBAT)
	map.rooms.append(parent)
	var secret := FloorRoom.new()
	secret.id = 1
	secret.room_type = RoomLayout.TYPE_SECRET
	secret.cell = Vector2i(1, 0)
	secret.layout = _layout(RoomLayout.TYPE_SECRET)
	map.rooms.append(secret)
	map.join(parent, secret)
	return map


func test_arriving_around_a_secret_room() -> void:
	var map := _map_with_secret()
	var progress := FloorProgress.new(map)
	assert_eq(progress.arrival_cell(1, 0), map.room(1).layout.door_cell(RoomLayout.WEST))
	assert_eq(progress.arrival_cell(0, 1), map.room(0).layout.door_cell(RoomLayout.EAST))


func test_a_secret_room_sits_at_its_own_cell_on_the_map() -> void:
	var map := _map_with_secret()
	assert_eq(FloorMapView.map_position(map, map.room(1)), Vector2(1, 0))


func test_the_crack_sits_in_the_wall_just_past_the_door_on_every_side() -> void:
	var layout := _layout(RoomLayout.TYPE_COMBAT)
	for side in RoomLayout.SIDES:
		assert_eq(layout.wall_cell(side) - side, layout.door_cell(side))
		var wall := layout.wall_cell(side)
		assert_eq(layout.rows[wall.y][wall.x], "#", "the crack is in the wall on side %s" % str(side))


func test_a_blast_beside_the_door_reaches_the_cracked_wall_on_every_side() -> void:
	var layout := _layout(RoomLayout.TYPE_COMBAT)
	var half := Vector2(RoomBackdrop.TILE, RoomBackdrop.TILE) / 2.0
	for side in RoomLayout.SIDES:
		var wall_center := RoomBackdrop.cell_center(layout.wall_cell(side))
		var wall := Rect2(wall_center - half, half * 2.0)
		assert_true(Thermos.in_blast(RoomBackdrop.cell_center(layout.door_cell(side)), wall), str(side))


func test_every_room_keeps_the_door_cell_a_secret_door_would_use_reachable() -> void:
	var rows := ["####################"]
	for y in range(1, 10):
		rows.append("#.......E..E.......#" if y == 5 else "#..................#")
	rows.append("####################")
	rows[1] = "#.........#........#"
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_COMBAT
	layout.rows = PackedStringArray(rows)
	assert_true(layout.validate().size() > 0, "a wall on the door cell must fail")
