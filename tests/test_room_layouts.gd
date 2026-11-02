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
	assert_eq(count, 19)


func test_catalog_meets_the_spec_counts() -> void:
	var counts := {}
	for layout in RoomCatalog.load_valid(DIR):
		counts[layout.room_type] = counts.get(layout.room_type, 0) + 1
	assert_eq(counts.get(RoomLayout.TYPE_COMBAT, 0), 9)
	assert_eq(counts.get(RoomLayout.TYPE_ITEM, 0), 2)
	assert_eq(counts.get(RoomLayout.TYPE_HEALING, 0), 2)
	assert_eq(counts.get(RoomLayout.TYPE_SIDE, 0), 2)
	assert_eq(counts.get(RoomLayout.TYPE_MINI_BOSS, 0), 1)
	assert_eq(counts.get(RoomLayout.TYPE_FLOOR_BOSS, 0), 1)
	assert_eq(counts.get(RoomLayout.TYPE_TREASURE, 0), 2)


func test_nearest_floor_cell_keeps_a_floor_cell() -> void:
	var layout := _layout(RoomLayout.TYPE_COMBAT, _open_rows("#.......E..E.......#"))
	assert_eq(layout.nearest_floor_cell(Vector2i(5, 5)), Vector2i(5, 5))


func test_nearest_floor_cell_moves_a_wall_cell_to_floor() -> void:
	var layout := _layout(RoomLayout.TYPE_COMBAT, _open_rows("#.......E..E.......#"))
	assert_eq(layout.nearest_floor_cell(Vector2i(0, 5)), Vector2i(1, 5))
	assert_eq(layout.nearest_floor_cell(Vector2i(-3, 5)), Vector2i(1, 5))
	assert_eq(layout.nearest_floor_cell(Vector2i(25, 0)), Vector2i(18, 1))


func test_side_room_needs_floor_at_the_arrival_cell() -> void:
	var open := _layout(RoomLayout.TYPE_SIDE, _open_rows("#.......T..........#"))
	assert_eq(open.validate().size(), 0)
	var rows := _open_rows("#.#.....T..........#")
	var blocked := _layout(RoomLayout.TYPE_SIDE, rows)
	assert_eq(RoomLayout.SIDE_ROOM_SPAWN, Vector2i(2, 5))
	assert_true(blocked.validate().size() > 0, "wall on the side room spawn cell")
	var regular := _layout(RoomLayout.TYPE_COMBAT, _open_rows("#.#.....E..E.......#"))
	assert_eq(regular.validate().size(), 0, "regular rooms don't need that cell")
