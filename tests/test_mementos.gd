extends TestCase


func test_every_floor_boss_has_a_frame_and_its_floor_names_it() -> void:
	assert_eq(Mementos.ALL.size(), 6)
	for entry: Dictionary in Mementos.ALL:
		var floor_path := "res://data/floors/%s.tres" % entry["path"]
		var def: FloorDef = load(floor_path)
		assert_eq(def.floor_boss.id, entry["boss"], entry["path"])


func test_a_fresh_save_hangs_nothing() -> void:
	assert_eq(Mementos.hung(ProgressData.new()).size(), 0)
	assert_eq(Mementos.perks(ProgressData.new()).size(), 0)


func test_a_cleared_path_hangs_its_memento_and_grants_its_perk() -> void:
	var data := ProgressData.new()
	data.record_floor_cleared(1, "cemetery")
	assert_eq(Mementos.hung(data).size(), 1)
	assert_true(Mementos.perks(data).has(Mementos.PROP_COINS_PERK))
	assert_false(Mementos.perks(data).has(Mementos.START_PENSION_PERK))


func test_looking_at_the_wall_lists_each_memento_or_says_it_is_empty() -> void:
	assert_eq(Mementos.wall_lines(ProgressData.new()), PackedStringArray([Mementos.EMPTY_WALL_TEXT]))
	var data := ProgressData.new()
	data.record_floor_cleared(1, "floor_1")
	data.record_floor_cleared(2, "furnace_works")
	var lines := Mementos.wall_lines(data)
	assert_eq(lines.size(), 2)
	assert_true(lines[0].begins_with("Name badge"), lines[0])
	assert_true(lines[1].begins_with("Coal shovel"), lines[1])


# The frames hang on the lobby's top wall, so none may cover the north door or a lantern.
func test_the_frames_keep_clear_of_the_north_door_and_the_lanterns() -> void:
	var lobby: RoomLayout = Departments.load_layouts()[Departments.LOBBY]
	var middle := RoomBackdrop.cell_center(Vector2i(Departments.TROPHY_WALL_COLUMN, 0)).x
	var left := middle + TrophyWall.frame_center(0).x - TrophyWall.FRAME_SIZE.x / 2.0
	var right := middle + TrophyWall.frame_center(Mementos.ALL.size() - 1).x + TrophyWall.FRAME_SIZE.x / 2.0
	var blocked: Array[int] = [lobby.door_cell(RoomLayout.NORTH).x]
	for cell in lobby.cells_of(RoomLayout.SYMBOL_LANTERN):
		blocked.append(cell.x)
	for x in blocked:
		var cell_left := float(x * RoomBackdrop.TILE)
		assert_true(right <= cell_left or left >= cell_left + RoomBackdrop.TILE, "column %d" % x)
