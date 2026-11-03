extends TestCase


func test_taking_one_removes_the_others() -> void:
	var group := ChoiceGroup.new()
	var a := Node.new()
	var b := Node.new()
	group.add(a)
	group.add(b)
	group.take(a)
	assert_false(a.is_queued_for_deletion(), "the taken one is left to its own pickup code")
	assert_true(b.is_queued_for_deletion())
	a.free()
	b.free()


func test_taking_twice_does_nothing_more() -> void:
	var group := ChoiceGroup.new()
	var a := Node.new()
	var b := Node.new()
	group.add(a)
	group.add(b)
	group.take(a)
	group.take(b)
	assert_true(group.is_settled())
	a.free()
	b.free()


func test_a_freed_member_is_skipped() -> void:
	var group := ChoiceGroup.new()
	var a := Node.new()
	var b := Node.new()
	group.add(a)
	group.add(b)
	b.free()
	group.take(a)
	assert_true(group.is_settled())
	a.free()


func _open_room() -> RoomLayout:
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_FLOOR_BOSS
	var rows: PackedStringArray = []
	for y in 11:
		var row := ""
		for x in 20:
			row += "#" if x == 0 or y == 0 or x == 19 or y == 10 else "."
		rows.append(row)
	layout.rows = rows
	return layout


func test_spots_near_keep_apart_and_off_the_doors() -> void:
	var layout := _open_room()
	var wanted: Array[Vector2i] = [Vector2i(8, 6), Vector2i(12, 6)]
	var spots := layout.open_spots_near(wanted)
	assert_eq(spots.size(), 2)
	assert_eq(spots[0], Vector2i(8, 6))
	assert_eq(spots[1], Vector2i(12, 6))
	var crowded: Array[Vector2i] = [Vector2i(10, 5), Vector2i(10, 5)]
	spots = layout.open_spots_near(crowded)
	assert_eq(spots.size(), 2)
	assert_true(maxi(absi(spots[0].x - spots[1].x), absi(spots[0].y - spots[1].y)) >= RoomLayout.PICKUP_SPACING, "two wanted on one cell still stand apart")
	var by_door: Array[Vector2i] = [layout.door_cell(RoomLayout.WEST)]
	spots = layout.open_spots_near(by_door)
	var offset := spots[0] - layout.door_cell(RoomLayout.WEST)
	assert_true(absi(offset.x) > 1 or absi(offset.y) > 1, "never on or beside a door cell")


func test_spots_near_keep_clear_of_spots_already_taken() -> void:
	var layout := _open_room()
	var taken: Array[Vector2i] = [Vector2i(10, 5)]
	var wanted: Array[Vector2i] = [Vector2i(10, 5)]
	var spots := layout.open_spots_near(wanted, taken)
	assert_eq(spots.size(), 1)
	assert_true(spots[0] != Vector2i(10, 5))
