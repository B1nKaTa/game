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
	assert_eq(count, 17)


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
