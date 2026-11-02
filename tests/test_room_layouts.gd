extends TestCase

const DIR := "res://data/rooms/floor_1/"


func _layout(type: String, rows: Array) -> RoomLayout:
	var layout := RoomLayout.new()
	layout.room_type = type
	layout.rows = PackedStringArray(rows)
	return layout


func _open_rows(middle: String) -> Array:
	var rows := ["####################"]
	for y in range(1, 10):
		rows.append(middle if y == 5 else "#..................#")
	rows.append("####################")
	return rows


func test_valid_combat_room_passes() -> void:
	var layout := _layout(RoomLayout.TYPE_COMBAT, _open_rows("#.......E..E.......#"))
	assert_eq(layout.validate().size(), 0)


func test_wrong_size_fails() -> void:
	var layout := _layout(RoomLayout.TYPE_COMBAT, ["###"])
	assert_true(layout.validate().size() > 0)


func test_open_border_fails() -> void:
	var rows := _open_rows("#.......E..E.......#")
	rows[0] = "#########.##########"
	assert_true(_layout(RoomLayout.TYPE_COMBAT, rows).validate().size() > 0)


func test_blocked_entry_fails() -> void:
	var rows := _open_rows("##......E..E.......#")
	assert_true(_layout(RoomLayout.TYPE_COMBAT, rows).validate().size() > 0)


func test_unreachable_enemy_fails() -> void:
	var rows := _open_rows("#.......E..E.......#")
	rows[8] = "#...###............#"
	rows[9] = "#...#E#............#"
	rows[10] = "####################"
	assert_true(_layout(RoomLayout.TYPE_COMBAT, rows).validate().size() > 0)


func test_required_symbols_by_type() -> void:
	var empty := _open_rows("#..................#")
	assert_true(_layout(RoomLayout.TYPE_COMBAT, empty).validate().size() > 0)
	assert_true(_layout(RoomLayout.TYPE_ITEM, empty).validate().size() > 0)
	assert_true(_layout(RoomLayout.TYPE_HEALING, empty).validate().size() > 0)
	assert_true(_layout(RoomLayout.TYPE_SIDE, empty).validate().size() > 0)
	assert_true(_layout(RoomLayout.TYPE_MINI_BOSS, empty).validate().size() > 0)
	assert_true(_layout(RoomLayout.TYPE_FLOOR_BOSS, empty).validate().size() > 0)
	assert_true(_layout(RoomLayout.TYPE_TREASURE, empty).validate().size() > 0)


func test_treasure_door_cell_must_be_floor_and_reachable() -> void:
	var rows := _open_rows("#.......E..E.......#")
	rows[9] = "#.........#........#"
	assert_true(_layout(RoomLayout.TYPE_COMBAT, rows).validate().size() > 0)
	rows[9] = "#........X.X.......#"
	rows[8] = "#.........X........#"
	assert_true(_layout(RoomLayout.TYPE_COMBAT, rows).validate().size() > 0, "blocked by breakable blocks")


func test_unknown_type_fails() -> void:
	assert_true(_layout("spa", _open_rows("#.......E..E.......#")).validate().size() > 0)


func test_all_shipped_rooms_are_valid() -> void:
	var files := DirAccess.get_files_at(DIR)
	var count := 0
	for file in files:
		var name := file.trim_suffix(".remap")
		if not name.ends_with(".tres"):
			continue
		count += 1
		var layout: RoomLayout = load(DIR + name)
		assert_eq(layout.validate().size(), 0, "%s: %s" % [name, str(layout.validate())])
	assert_eq(count, 44)


func test_catalog_meets_the_spec_counts() -> void:
	var counts := {}
	for layout in RoomCatalog.load_valid(DIR):
		counts[layout.room_type] = counts.get(layout.room_type, 0) + 1
	assert_eq(counts.get(RoomLayout.TYPE_COMBAT, 0), 19)
	assert_eq(counts.get(RoomLayout.TYPE_ITEM, 0), 4)
	assert_eq(counts.get(RoomLayout.TYPE_HEALING, 0), 3)
	assert_eq(counts.get(RoomLayout.TYPE_SIDE, 0), 4)
	assert_eq(counts.get(RoomLayout.TYPE_MINI_BOSS, 0), 2)
	assert_eq(counts.get(RoomLayout.TYPE_FLOOR_BOSS, 0), 2)
	assert_eq(counts.get(RoomLayout.TYPE_TREASURE, 0), 3)
	assert_eq(counts.get(RoomLayout.TYPE_SHOP, 0), 1)
	assert_eq(counts.get(RoomLayout.TYPE_SECRET, 0), 3)
	assert_eq(counts.get(RoomLayout.TYPE_VAULT, 0), 3)


func test_nearest_floor_cell_keeps_a_floor_cell() -> void:
	var layout := _layout(RoomLayout.TYPE_COMBAT, _open_rows("#.......E..E.......#"))
	assert_eq(layout.nearest_floor_cell(Vector2i(5, 5)), Vector2i(5, 5))


func test_nearest_floor_cell_moves_a_wall_cell_to_floor() -> void:
	var layout := _layout(RoomLayout.TYPE_COMBAT, _open_rows("#.......E..E.......#"))
	assert_eq(layout.nearest_floor_cell(Vector2i(0, 5)), Vector2i(1, 5))
	assert_eq(layout.nearest_floor_cell(Vector2i(-3, 5)), Vector2i(1, 5))
	assert_eq(layout.nearest_floor_cell(Vector2i(25, 0)), Vector2i(18, 1))


func _sized_rows(width: int, height: int, middle: String) -> Array:
	var rows := ["#".repeat(width)]
	for y in range(1, height - 1):
		rows.append(middle if y == height / 2 else "#" + ".".repeat(width - 2) + "#")
	rows.append("#".repeat(width))
	return rows


func test_size_is_read_from_the_rows() -> void:
	var small := _layout(RoomLayout.TYPE_COMBAT, _sized_rows(14, 9, "#...E....E...#"))
	assert_eq(small.size_in_cells(), Vector2i(14, 9))
	assert_eq(small.size_class(), RoomLayout.SIZE_SMALL)
	assert_eq(small.validate().size(), 0)
	var medium := _layout(RoomLayout.TYPE_COMBAT, _open_rows("#.......E..E.......#"))
	assert_eq(medium.size_in_cells(), Vector2i(20, 11))
	assert_eq(medium.size_class(), RoomLayout.SIZE_MEDIUM)
	var large := _layout(RoomLayout.TYPE_COMBAT, _sized_rows(30, 17, "#.....E...............E......#"))
	assert_eq(large.size_in_cells(), Vector2i(30, 17))
	assert_eq(large.size_class(), RoomLayout.SIZE_LARGE)
	assert_eq(large.validate().size(), 0)


func test_uneven_rows_fail() -> void:
	var rows := _open_rows("#.......E..E.......#")
	rows[3] = "#.................#"
	assert_true(_layout(RoomLayout.TYPE_COMBAT, rows).validate().size() > 0)


func test_door_cells_sit_at_the_middle_of_each_wall() -> void:
	var medium := _layout(RoomLayout.TYPE_COMBAT, _open_rows("#.......E..E.......#"))
	assert_eq(medium.door_cell(RoomLayout.NORTH), Vector2i(10, 1))
	assert_eq(medium.door_cell(RoomLayout.SOUTH), Vector2i(10, 9))
	assert_eq(medium.door_cell(RoomLayout.WEST), Vector2i(1, 5))
	assert_eq(medium.door_cell(RoomLayout.EAST), Vector2i(18, 5))
	var small := _layout(RoomLayout.TYPE_COMBAT, _sized_rows(14, 9, "#...E....E...#"))
	assert_eq(small.door_cell(RoomLayout.NORTH), Vector2i(7, 1))
	assert_eq(small.door_cell(RoomLayout.SOUTH), Vector2i(7, 7))
	assert_eq(small.door_cell(RoomLayout.WEST), Vector2i(1, 4))
	assert_eq(small.door_cell(RoomLayout.EAST), Vector2i(12, 4))


func test_the_wall_cell_is_just_past_the_door_cell() -> void:
	var layout := _layout(RoomLayout.TYPE_COMBAT, _open_rows("#.......E..E.......#"))
	for side in RoomLayout.SIDES:
		var wall := layout.wall_cell(side)
		assert_eq(wall - side, layout.door_cell(side))
		assert_eq(layout.rows[wall.y][wall.x], "#", str(side))


func test_all_four_door_cells_must_be_floor() -> void:
	for side in RoomLayout.SIDES:
		var layout := _layout(RoomLayout.TYPE_COMBAT, _open_rows("#.......E..E.......#"))
		var cell := layout.door_cell(side)
		var rows: Array = Array(layout.rows)
		var row: String = rows[cell.y]
		rows[cell.y] = row.substr(0, cell.x) + "#" + row.substr(cell.x + 1)
		assert_true(_layout(RoomLayout.TYPE_COMBAT, rows).validate().size() > 0, str(side))


func test_all_four_door_cells_must_be_reachable_without_a_bomb() -> void:
	var rows := _open_rows("#.......E..E.......#")
	rows[1] = "#........X.X.......#"
	rows[2] = "#.........X........#"
	assert_true(_layout(RoomLayout.TYPE_COMBAT, rows).validate().size() > 0, "north door behind blocks")


func test_an_enemy_right_beside_a_door_fails_because_any_door_can_be_the_way_in() -> void:
	var rows := _open_rows("#.......E..E.......#")
	rows[3] = "#.........E........#"
	assert_true(_layout(RoomLayout.TYPE_COMBAT, rows).validate().size() > 0)


func test_a_pickup_touching_a_door_fails_because_reaching_it_could_walk_through_the_door() -> void:
	var rows := _open_rows("#.......E..E.......#")
	rows[9] = "#........C.........#"
	assert_true(_layout(RoomLayout.TYPE_COMBAT, rows).validate().size() > 0)


func test_every_size_exists_across_room_types() -> void:
	var small_types := {}
	var large_types := {}
	var small := 0
	var large := 0
	for layout in RoomCatalog.load_valid(DIR):
		if layout.size_class() == RoomLayout.SIZE_SMALL:
			small += 1
			small_types[layout.room_type] = true
		elif layout.size_class() == RoomLayout.SIZE_LARGE:
			large += 1
			large_types[layout.room_type] = true
	assert_true(small >= 4, "small rooms: %d" % small)
	assert_true(large >= 4, "large rooms: %d" % large)
	assert_true(small_types.size() >= 2, "small rooms across types")
	assert_true(large_types.size() >= 2, "large rooms across types")


func test_a_floor_uses_rooms_of_every_size() -> void:
	var def: FloorDef = load("res://data/floors/floor_1.tres")
	var pool := RoomCatalog.load_valid(DIR)
	var sizes := {}
	for seed_value in 50:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		for room in FloorBuilder.build_from_pool(rng, def, pool).rooms:
			sizes[room.layout.size_class()] = true
	assert_eq(sizes.size(), 3, str(sizes.keys()))
