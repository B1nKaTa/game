extends TestCase

# A boss starts on its B cell with a collision box of 0.8 of its body, as Enemy._ready makes it.
# A big body wider or taller than a cell must not start inside a pew, a fountain or a wall, or
# move_and_slide shoves it out somewhere unplanned or pins it there.
const FLOORS_DIR := "res://data/floors/"
const BOX_SCALE := 0.8


func _boss_for(floor_def: FloorDef, layout: RoomLayout) -> EnemyDef:
	if layout.room_type == RoomLayout.TYPE_MINI_BOSS:
		return floor_def.mini_boss
	if layout.room_type == RoomLayout.TYPE_FLOOR_BOSS:
		return floor_def.floor_boss
	return null


# Every solid cell the box at this spawn cell overlaps. Touching an edge is not overlapping.
static func solid_cells_under(layout: RoomLayout, cell: Vector2i, body_size: Vector2) -> Array[Vector2i]:
	var tile := float(RoomBackdrop.TILE)
	var size := body_size * BOX_SCALE
	var box := Rect2(RoomBackdrop.cell_center(cell) - size / 2.0, size)
	var hits: Array[Vector2i] = []
	for y in range(floori(box.position.y / tile), floori(box.end.y / tile) + 1):
		for x in range(floori(box.position.x / tile), floori(box.end.x / tile) + 1):
			var other := Vector2i(x, y)
			if not layout.is_solid_at(other):
				continue
			if box.intersects(Rect2(Vector2(other) * tile, Vector2(tile, tile))):
				hits.append(other)
	return hits


func test_a_box_overlapping_a_pew_is_caught() -> void:
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_FLOOR_BOSS
	layout.rows = PackedStringArray([
		"####################",
		"#..................#",
		"#..................#",
		"#..................#",
		"#.......hh.hh......#",
		"#.........B........#",
		"#.......hh.hh......#",
		"#..................#",
		"#..................#",
		"#..................#",
		"####################",
	])
	var cell := layout.cells_of("B")[0]
	assert_eq(solid_cells_under(layout, cell, Vector2(42, 50)).size(), 4)
	assert_eq(solid_cells_under(layout, cell, Vector2(32, 32)).size(), 0, "a one-cell body fits")


func test_every_boss_starts_clear_of_solid_cells() -> void:
	var checked := 0
	for file in DirAccess.get_files_at(FLOORS_DIR):
		var name := file.trim_suffix(".remap")
		if not name.ends_with(".tres"):
			continue
		var floor_def: FloorDef = load(FLOORS_DIR + name)
		if floor_def.rooms_dir.is_empty():
			continue
		for room_file in DirAccess.get_files_at(floor_def.rooms_dir):
			var room_name := room_file.trim_suffix(".remap")
			if not room_name.ends_with(".tres"):
				continue
			var layout: RoomLayout = load(floor_def.rooms_dir + room_name)
			var boss := _boss_for(floor_def, layout)
			if boss == null or boss.ignores_walls:
				continue
			for cell in layout.cells_of("B"):
				checked += 1
				var hits := solid_cells_under(layout, cell, boss.body_size)
				assert_eq(hits.size(), 0, "%s %s: %s at %s overlaps %s" % [floor_def.id, room_name, boss.id, str(cell), str(hits)])
	assert_true(checked > 10, "found the boss rooms (%d)" % checked)


# The Flashback Cinema's bosses are bigger than the Mall's were: Crabtree's 32 by 40 box and the
# Projectionist's 44 by 52 must start clear of every seat row and pillar in their own rooms.
func test_the_cinemas_bosses_start_clear_in_their_rooms() -> void:
	var floor_def: FloorDef = load(FLOORS_DIR + "flashback_cinema.tres")
	assert_eq(floor_def.mini_boss.body_size, Vector2(32, 40))
	assert_eq(floor_def.floor_boss.body_size, Vector2(44, 52))
	var checked := {}
	for room_file in DirAccess.get_files_at(floor_def.rooms_dir):
		var room_name := room_file.trim_suffix(".remap")
		if not room_name.ends_with(".tres"):
			continue
		var layout: RoomLayout = load(floor_def.rooms_dir + room_name)
		var boss := _boss_for(floor_def, layout)
		if boss == null:
			continue
		for cell in layout.cells_of("B"):
			checked[boss.id] = int(checked.get(boss.id, 0)) + 1
			assert_eq(solid_cells_under(layout, cell, boss.body_size).size(), 0, "%s in %s" % [boss.id, room_name])
	assert_eq(checked.get("crabtree", 0), 2, "both of Crabtree's rooms")
	assert_eq(checked.get("projectionist", 0), 2, "both of the Projectionist's rooms")


# Sister Celestine's 32 by 40 box must start clear of every desk, table and partition in her own rooms.
func test_the_hotlines_mini_boss_starts_clear_in_her_rooms() -> void:
	var floor_def: FloorDef = load(FLOORS_DIR + "seance_hotline.tres")
	assert_eq(floor_def.mini_boss.id, "celestine")
	assert_eq(floor_def.mini_boss.body_size, Vector2(32, 40))
	var checked := 0
	for room_file in DirAccess.get_files_at(floor_def.rooms_dir):
		var room_name := room_file.trim_suffix(".remap")
		if not room_name.ends_with(".tres"):
			continue
		var layout: RoomLayout = load(floor_def.rooms_dir + room_name)
		if layout.room_type != RoomLayout.TYPE_MINI_BOSS:
			continue
		for cell in layout.cells_of("B"):
			checked += 1
			assert_eq(solid_cells_under(layout, cell, floor_def.mini_boss.body_size).size(), 0, "celestine in %s" % room_name)
	assert_eq(checked, 2, "both of her rooms")


# Madame Zara's 44 by 52 box must start clear of every desk, table and partition in her own rooms.
func test_the_hotlines_floor_boss_starts_clear_in_her_rooms() -> void:
	var floor_def: FloorDef = load(FLOORS_DIR + "seance_hotline.tres")
	assert_eq(floor_def.floor_boss.id, "madame_zara")
	assert_eq(floor_def.floor_boss.body_size, Vector2(44, 52))
	var checked := 0
	for room_file in DirAccess.get_files_at(floor_def.rooms_dir):
		var room_name := room_file.trim_suffix(".remap")
		if not room_name.ends_with(".tres"):
			continue
		var layout: RoomLayout = load(floor_def.rooms_dir + room_name)
		if layout.room_type != RoomLayout.TYPE_FLOOR_BOSS:
			continue
		for cell in layout.cells_of("B"):
			checked += 1
			assert_eq(solid_cells_under(layout, cell, floor_def.floor_boss.body_size).size(), 0, "madame_zara in %s" % room_name)
	assert_eq(checked, 2, "both of her rooms")
