extends TestCase

const SEEDS := 300


func _pool() -> Array[RoomLayout]:
	return RoomCatalog.load_valid("res://data/rooms/floor_1/")


func _build(seed_value: int, pool: Array[RoomLayout]) -> FloorMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return FloorBuilder.build(rng, pool)


func test_room_count_is_between_10_and_12() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var count := _build(seed_value, pool).main_rooms().size()
		assert_true(count >= 10 and count <= 12, "seed %d had %d rooms" % [seed_value, count])


func test_every_generated_floor_can_be_completed() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		assert_true(map.reaches_boss_from_everywhere(), "seed %d" % seed_value)


func test_exits_are_within_limits() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		for room in map.main_rooms():
			if room.id == map.boss_id:
				assert_eq(room.exits.size(), 0)
			else:
				assert_true(room.exits.size() >= 1 and room.exits.size() <= 2, "seed %d" % seed_value)


func test_every_room_has_a_way_in() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		var entered := {map.start_id: true}
		for room in map.main_rooms():
			for exit_id in room.exits:
				entered[exit_id] = true
		for room in map.main_rooms():
			assert_true(entered.has(room.id), "seed %d room %d" % [seed_value, room.id])


func test_layers_have_one_or_two_rooms() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var widths := {}
		for room in _build(seed_value, pool).main_rooms():
			widths[room.layer] = widths.get(room.layer, 0) + 1
		for layer in widths:
			assert_true(widths[layer] == 1 or widths[layer] == 2, "seed %d" % seed_value)


func test_structure_has_one_mini_boss_and_ends_with_the_floor_boss() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		var mini_bosses := 0
		for room in map.main_rooms():
			if room.room_type == RoomLayout.TYPE_MINI_BOSS:
				mini_bosses += 1
		assert_eq(mini_bosses, 1)
		assert_eq(map.room(map.boss_id).room_type, RoomLayout.TYPE_FLOOR_BOSS)
		assert_eq(map.room(map.start_id).room_type, RoomLayout.TYPE_COMBAT)


func test_layouts_match_room_types() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		for room in _build(seed_value, pool).rooms:
			assert_eq(room.layout.room_type, room.room_type)


func test_side_rooms_hang_off_combat_rooms_and_return() -> void:
	var pool := _pool()
	var found := 0
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		for room in map.rooms:
			if room.side_id == -1:
				continue
			found += 1
			assert_eq(room.room_type, RoomLayout.TYPE_COMBAT)
			var side := map.room(room.side_id)
			assert_eq(side.room_type, RoomLayout.TYPE_SIDE)
			assert_eq(side.parent_id, room.id)
	assert_true(found > 0, "some floors have side rooms")


func test_same_seed_gives_same_floor() -> void:
	var pool := _pool()
	var first := _build(99, pool)
	var second := _build(99, pool)
	assert_eq(first.rooms.size(), second.rooms.size())
	for i in first.rooms.size():
		assert_eq(first.rooms[i].layout, second.rooms[i].layout)
		assert_eq(first.rooms[i].exits, second.rooms[i].exits)


func test_missing_room_type_returns_null() -> void:
	var pool: Array[RoomLayout] = []
	for layout in _pool():
		if layout.room_type != RoomLayout.TYPE_FLOOR_BOSS:
			pool.append(layout)
	assert_true(_build(1, pool) == null)


func test_floor_data_loads() -> void:
	var def: FloorDef = load("res://data/floors/floor_1.tres")
	assert_eq(def.enemies.size(), 3)
	assert_eq(def.mini_boss.id, "senior_adjuster")
	assert_eq(def.floor_boss.id, "regional_reaper")
