extends TestCase


func _pool() -> Array[RoomLayout]:
	return RoomCatalog.load_valid("res://data/rooms/floor_1/")


func test_a_floor_has_at_most_one_secret_room_on_a_combat_room_without_a_side_room() -> void:
	var pool := _pool()
	var floors_with_one := 0
	for seed_value in 300:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var map := FloorBuilder.build(rng, pool)
		var found := 0
		for room in map.rooms:
			if room.room_type != RoomLayout.TYPE_SECRET:
				continue
			found += 1
			assert_true(room.is_detour())
			var parent := map.room(room.parent_id)
			assert_eq(parent.secret_id, room.id)
			assert_eq(parent.room_type, RoomLayout.TYPE_COMBAT)
			assert_eq(parent.side_id, -1, "seed %d: they would share a spot on the map" % seed_value)
		assert_true(found <= 1, "seed %d" % seed_value)
		floors_with_one += found
	assert_true(floors_with_one > 250, "most floors should have one, had %d" % floors_with_one)


func test_a_secret_room_does_not_count_as_a_main_room() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	for room in FloorBuilder.build(rng, _pool()).main_rooms():
		assert_false(room.is_detour())


func _map_with_secret() -> FloorMap:
	var map := FloorMap.new()
	var parent := FloorRoom.new()
	parent.id = 0
	parent.room_type = RoomLayout.TYPE_COMBAT
	map.rooms.append(parent)
	var secret := FloorRoom.new()
	secret.id = 1
	secret.room_type = RoomLayout.TYPE_SECRET
	secret.parent_id = 0
	map.rooms.append(secret)
	parent.secret_id = 1
	return map


func test_arriving_around_a_secret_room() -> void:
	var progress := FloorProgress.new(_map_with_secret())
	assert_eq(progress.arrival_cell(1, 0), RoomLayout.SIDE_ROOM_SPAWN)
	assert_eq(progress.arrival_cell(0, 1), RoomLayout.SECRET_DOOR)
	assert_eq(progress.back_target(1), 0)
	assert_false(progress.is_sealed(1))


func test_a_secret_room_sits_in_the_side_room_spot_on_the_map() -> void:
	var map := _map_with_secret()
	assert_eq(FloorMapView.map_position(map, map.room(1)), Vector2(0, -0.5))


func test_the_secret_door_is_just_below_the_cracked_wall() -> void:
	assert_eq(RoomLayout.SECRET_WALL + Vector2i(0, 1), RoomLayout.SECRET_DOOR)
	assert_eq(RoomLayout.SECRET_WALL.y, 0, "the crack is in the top wall")


func test_a_blast_beside_the_door_reaches_the_cracked_wall() -> void:
	var wall_center := RoomBackdrop.cell_center(RoomLayout.SECRET_WALL)
	var half := Vector2(RoomBackdrop.TILE, RoomBackdrop.TILE) / 2.0
	var wall := Rect2(wall_center - half, half * 2.0)
	assert_true(Thermos.in_blast(RoomBackdrop.cell_center(RoomLayout.SECRET_DOOR), wall))


func test_every_room_keeps_the_secret_door_cell_reachable() -> void:
	var rows := ["####################"]
	for y in range(1, 10):
		rows.append("#.......E..E.......#" if y == 5 else "#..................#")
	rows.append("####################")
	rows[1] = "#..............#...#"
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_COMBAT
	layout.rows = PackedStringArray(rows)
	assert_true(layout.validate().size() > 0, "a wall on the secret door cell must fail")
