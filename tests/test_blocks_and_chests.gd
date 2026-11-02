extends TestCase


func _layout(room_type: String, rows: Array) -> RoomLayout:
	var layout := RoomLayout.new()
	layout.room_type = room_type
	layout.rows = PackedStringArray(rows)
	return layout


func _rows(overrides: Dictionary) -> Array:
	var rows := ["####################"]
	for y in range(1, 10):
		rows.append(overrides.get(y, "#..................#"))
	rows.append("####################")
	return rows


func test_blocks_and_chests_are_allowed_symbols() -> void:
	var rows := _rows({5: "#.......E..E.......#", 3: "#...X.....C........#"})
	assert_eq(_layout(RoomLayout.TYPE_COMBAT, rows).validate().size(), 0)


func test_a_loot_pocket_behind_blocks_is_allowed() -> void:
	var rows := _rows({1: "#TX................#", 2: "#X.................#", 5: "#.......E..E.......#"})
	assert_eq(_layout(RoomLayout.TYPE_COMBAT, rows).validate().size(), 0)


func test_blocks_must_not_be_needed_to_reach_an_exit() -> void:
	var wall_off := "#..............X...#"
	var overrides := {}
	for y in range(1, 10):
		overrides[y] = wall_off
	overrides[5] = "#.......E..E...X...#"
	var layout := _layout(RoomLayout.TYPE_COMBAT, _rows(overrides))
	assert_true(layout.validate().size() > 0)


func test_blocks_must_not_be_needed_to_reach_an_enemy() -> void:
	var rows := _rows({1: "#EX................#", 2: "#X.................#", 5: "#.......E..E.......#"})
	assert_true(_layout(RoomLayout.TYPE_COMBAT, rows).validate().size() > 0)


func test_a_cell_sealed_by_real_walls_still_fails() -> void:
	var rows := _rows({1: "#T#................#", 2: "##.................#", 5: "#.......E..E.......#"})
	assert_true(_layout(RoomLayout.TYPE_COMBAT, rows).validate().size() > 0)


func test_open_without_breaking_tells_pockets_apart() -> void:
	var rows := _rows({1: "#TX................#", 2: "#X.................#", 3: "#.T................#", 5: "#.......E..E.......#"})
	var layout := _layout(RoomLayout.TYPE_COMBAT, rows)
	assert_false(layout.is_open_without_breaking(Vector2i(1, 1)))
	assert_true(layout.is_open_without_breaking(Vector2i(2, 3)))


func test_summons_never_land_on_a_block() -> void:
	var rows := _rows({5: "#....X..E..E.......#"})
	var layout := _layout(RoomLayout.TYPE_COMBAT, rows)
	assert_true(layout.nearest_floor_cell(Vector2i(5, 5)) != Vector2i(5, 5))


func test_block_drop_follows_the_chances() -> void:
	assert_eq(RoomRules.block_drop(0.0), RoomRules.DROP_COIN)
	assert_eq(RoomRules.block_drop(RoomRules.BLOCK_COIN_CHANCE + 0.001), RoomRules.DROP_BOMB)
	assert_eq(RoomRules.block_drop(RoomRules.BLOCK_COIN_CHANCE + RoomRules.BLOCK_BOMB_CHANCE + 0.001), RoomRules.DROP_KEY)
	assert_eq(RoomRules.block_drop(0.99), RoomRules.DROP_NONE)


func test_some_shipped_rooms_have_blocks_chests_and_pockets() -> void:
	var blocks := 0
	var chests := 0
	var pockets := 0
	for layout in RoomCatalog.load_valid("res://data/rooms/floor_1/"):
		blocks += layout.cells_of("X").size()
		chests += layout.cells_of("C").size()
		for cell in layout.cells_of("T"):
			if not layout.is_open_without_breaking(cell):
				pockets += 1
	assert_true(blocks >= 10, "had %d blocks" % blocks)
	assert_true(chests >= 3, "had %d chests" % chests)
	assert_true(pockets >= 2, "had %d pockets" % pockets)


func test_pickup_prompt_can_be_changed() -> void:
	var pickup := Pickup.new()
	assert_eq(pickup.prompt, Pickup.PROMPT_TEXT)
	pickup.free()
