extends TestCase

# The depth look (docs/art/art-direction-notes.md) and the shared pieces it brought: contact shadows,
# door openings with signs, and the HUD's clear middle.


func test_every_area_is_drawn_in_the_depth_look_with_its_art_there() -> void:
	for file in DirAccess.get_files_at("res://data/floors"):
		if not file.ends_with(".tres"):
			continue
		var def: FloorDef = load("res://data/floors/" + file)
		assert_eq(def.art_style, DepthLook.STYLE, def.id)
		assert_true(DepthLook.for_floor(def) != null, "%s has its depth art (art/tiles/%s/depth)" % [def.id, def.art()])


func test_the_ground_picks_its_wang_tile_from_the_four_corners() -> void:
	for y in 6:
		for x in 8:
			var cell := Vector2i(x, y)
			var index := DepthLook.ground_index(cell, 7)
			assert_true(index >= 0 and index < 16)
			# A neighbour shares two corners, so the tiles always join.
			var right := DepthLook.ground_index(cell + Vector2i.RIGHT, 7)
			assert_eq((index >> 2) & 1, (right >> 3) & 1, "NE of %s is NW of its right" % str(cell))
			assert_eq(index & 1, (right >> 1) & 1, "SE of %s is SW of its right" % str(cell))


func test_the_ground_has_patches_but_is_mostly_its_base() -> void:
	var patches := 0
	var total := 0
	for y in 40:
		for x in 40:
			total += 1
			if DepthLook.is_patch(Vector2i(x, y), 3):
				patches += 1
	assert_true(patches > total / 20, "some patches: %d of %d" % [patches, total])
	assert_true(patches < total / 2, "but the base terrain leads: %d of %d" % [patches, total])


func test_a_wall_shows_its_face_only_over_open_floor() -> void:
	var rows := PackedStringArray(["#####", "#.#.#", "#.#.#", "#...#", "#####"])
	assert_true(DepthLook.is_face(rows, Vector2i(1, 0)))
	assert_false(DepthLook.is_face(rows, Vector2i(2, 1)), "wall below it")
	assert_true(DepthLook.is_face(rows, Vector2i(2, 2)))
	assert_false(DepthLook.is_face(rows, Vector2i(0, 2)), "a side wall shows its top")
	assert_false(DepthLook.is_face(rows, Vector2i(2, 4)), "the south wall shows its top")


func test_sconces_stay_off_the_north_door() -> void:
	for width in [10, 20, 30]:
		var rows := PackedStringArray()
		rows.append("#".repeat(width))
		for i in 5:
			rows.append("#" + ".".repeat(width - 2) + "#")
		rows.append("#".repeat(width))
		var cells := DepthLook.sconce_cells(rows)
		assert_true(cells.size() >= 1, "width %d" % width)
		for cell in cells:
			if cell.y == 0:
				assert_true(absi(cell.x - width / 2) > DepthLook.DOOR_CLEAR, "width %d: %s" % [width, str(cell)])


func test_the_room_s_own_wall_blocks_carry_a_couple_of_sconces() -> void:
	var rows := PackedStringArray(["####################", "#..................#", "#..##..........##..#", "#..##..........##..#",
		"#..................#", "#..................#", "####################"])
	var inner := 0
	for cell in DepthLook.sconce_cells(rows):
		assert_true(DepthLook.is_face(rows, cell), str(cell))
		if cell.y > 0:
			inner += 1
	assert_true(inner >= 1 and inner <= DepthLook.INNER_SCONCES, "%d on the blocks" % inner)


func test_every_room_type_beyond_a_door_has_a_sign_or_none_on_purpose() -> void:
	for type in RoomRules.ICONS:
		var icon: String = RoomRules.ICONS[type]
		if DoorSign.NONE.has(icon):
			assert_false(DoorSign.has_sign(icon), type)
		else:
			assert_true(DoorSign.has_sign(icon), "%s (%s) has a sign" % [type, icon])
	for icon in DoorSign.PICTURES:
		for row: String in DoorSign.PICTURES[icon]:
			assert_eq(row.length(), DoorSign.SIZE, "sign %s rows are %d wide" % [icon, DoorSign.SIZE])


# A row's drawn extent [first, last] in a sign picture, or [] for an empty row.
func _extent(row: String) -> Array:
	var first := -1
	var last := -1
	for x in row.length():
		if row[x] != ".":
			if first < 0:
				first = x
			last = x
	return [] if first < 0 else [first, last]


# A plus silhouette: a thin stem (3 wide or less, 2 rows or more) above and below a band that reaches 2 or
# more cells past the stem on both sides; a round shape's single narrow end row is no stem. The healing sign was a medical plus and the Crossroads signpost's post ran
# through its board, and both read as a cross at 1x, which the game must never show.
func _reads_as_a_cross(rows: Array) -> bool:
	for b in rows.size():
		var band := _extent(rows[b])
		if band.is_empty():
			continue
		var above := 0
		var below := 0
		for other in rows.size():
			var stem := _extent(rows[other])
			if other == b or stem.is_empty() or stem[1] - stem[0] + 1 > 3:
				continue
			if stem[0] - band[0] >= 2 and band[1] - stem[1] >= 2:
				if other < b:
					above += 1
				else:
					below += 1
		if above >= 2 and below >= 2:
			return true
	return false


func test_no_door_sign_reads_as_a_cross() -> void:
	assert_true(_reads_as_a_cross(["...###...", "...#o#...", "#########", "#ooooooo#", "#########", "...#o#...", "...###..."]), "the check sees a plus")
	assert_false(_reads_as_a_cross([".........", "..#####..", ".#ooooo#.", "#ooooooo#", "#ooooooo#", ".#ooooo#.", "..#####.."]), "a disc is no plus")
	for icon in DoorSign.PICTURES:
		var rows: Array = DoorSign.PICTURES[icon]
		assert_false(_reads_as_a_cross(rows), "sign %s reads as a cross" % icon)
		# Turned on its side too, so a lying cross is caught as well.
		var turned: Array = []
		for x in DoorSign.SIZE:
			var column := ""
			for row: String in rows:
				column += row[x]
			turned.append(column)
		assert_false(_reads_as_a_cross(turned), "sign %s on its side reads as a cross" % icon)


# The big map drew the Crossroads' letter, a literal "+", in its room. Both maps are painted into an image
# with the Crossroads walked and a corridor on every side: nothing is inked inside its square, and the
# pixel cross finder sees no crossing strokes anywhere on either map.
func test_neither_map_draws_a_plus_for_the_crossroads() -> void:
	var map := FloorMap.new()
	var rooms := {}
	for cell: Vector2i in [Vector2i(1, 1), Vector2i(1, 0), Vector2i(2, 1), Vector2i(1, 2), Vector2i(0, 1)]:
		var room := FloorRoom.new()
		room.id = map.rooms.size()
		room.cell = cell
		room.room_type = RoomLayout.TYPE_CROSSROADS if cell == Vector2i(1, 1) else RoomLayout.TYPE_ITEM
		map.rooms.append(room)
		rooms[cell] = room
	var progress := FloorProgress.new(map)
	for cell: Vector2i in rooms:
		if cell != Vector2i(1, 1):
			map.join(rooms[Vector2i(1, 1)], rooms[cell])
		progress.enter(rooms[cell].id)
	var crossroads: FloorRoom = rooms[Vector2i(1, 1)]
	var finder = load("res://tests/test_floor_map_view.gd").new()
	for is_big in [true, false]:
		var view := FloorMapView.new()
		view.setup(map, progress, is_big, "The Crossroads")
		view.set_current(rooms[Vector2i(1, 0)].id)
		var image := Image.create(640, 360, false, Image.FORMAT_RGBA8)
		if is_big:
			view.paint_big(image)
		else:
			view.paint_mini(image)
		var rect: Rect2 = view.big_room_rects[crossroads.id] if is_big else view.mini_room_rects[crossroads.id]
		var spacing := FloorMapView.big_spacing(map.bounds().size) if is_big else FloorMapView.MINI_SPACING
		var inside := Rect2i(rect.grow(-float(MapPaper.outline_width(FloorMapView.room_size(spacing)))))
		var floor_pixels := 0
		for y in range(inside.position.y, inside.end.y):
			for x in range(inside.position.x, inside.end.x):
				assert_true(image.get_pixel(x, y).is_equal_approx(MapPaper.ROOM_FILL), "big %s: nothing drawn in the Crossroads at %d,%d" % [str(is_big), x, y])
				floor_pixels += 1
		assert_true(floor_pixels > 0, "the Crossroads was painted")
		var area := FloorMapView.SHEET if is_big else FloorMapView.MINI_RECT
		assert_true(finder._crossings(image, area).is_empty(), "big %s: a crossing" % str(is_big))
		view.free()


func test_a_door_gate_is_shut_while_the_room_is_shut_and_rises_after() -> void:
	var door := Door.new()
	door.locked = true
	door._update_gate(0.0)
	assert_near(door.gate(), 0.0)
	door.locked = false
	door._update_gate(Door.GATE_TIME / 2.0)
	assert_near(door.gate(), 0.5)
	door._update_gate(Door.GATE_TIME)
	assert_near(door.gate(), 1.0)
	door.requires_key = true
	door._update_gate(0.01)
	assert_near(door.gate(), 0.0, "a Slip's lock drops the gate at once")
	door.free()


func test_a_door_that_starts_open_starts_with_its_gate_up() -> void:
	var door := Door.new()
	door.locked = false
	door._update_gate(0.0)
	assert_near(door.gate(), 1.0)
	door.free()


func test_the_hud_leaves_the_top_middle_clear_for_the_north_door() -> void:
	var opening := Rect2(320.0 - DoorOpening.HALF_WIDTH, 0.0, DoorOpening.HALF_WIDTH * 2.0, 36.0)
	assert_false(Rect2(Hud.LEFT_PANEL_AT, Vector2(Hud.LEFT_PANEL_MIN_WIDTH, 34)).intersects(opening), "left panel")
	assert_false(Hud.RIGHT_PANEL.intersects(opening), "right panel")
	assert_true(Hud.ITEM_ROW_END <= opening.position.x, "the item row stops before it")
	assert_true(Hud.RIGHT_PANEL.end.x <= Hud.MAP_PANEL.position.x, "the potion panel stops before the map's")


func test_a_contact_shadow_is_flat_and_sits_under_bodies() -> void:
	var texture := ContactShadow.ellipse(20)
	assert_eq(texture.get_width(), 20)
	assert_true(texture.get_height() < texture.get_width() / 2)
	assert_true(ContactShadow.Z < 0, "under the bodies")
	assert_true(ContactShadow.Z > -10, "over the backdrop")
	var node := Node2D.new()
	var shadow := ContactShadow.add_to(node, 20.0, Vector2(0, 12))
	assert_false(shadow.z_as_relative)
	assert_eq(shadow.position, Vector2(0, 12))
	node.free()


func test_set_in_walls_casts_no_shadow() -> void:
	var stone := ReinforcedRock.new()
	var crack := SecretWall.new()
	assert_false(stone.casts_shadow())
	assert_false(crack.casts_shadow())
	var crate := BreakableBlock.new()
	assert_true(crate.casts_shadow())
	crate.free()
	stone.free()
	crack.free()


func test_warnings_in_a_depth_room_keep_their_colour() -> void:
	var mark := Node2D.new()
	mark.z_index = Enemy.WARNING_Z
	DepthLook.active = false
	DepthLook.keep_vivid(mark)
	assert_true(mark.material == null, "the flat look keeps its warnings as they were")
	DepthLook.active = true
	DepthLook.keep_vivid(mark)
	assert_eq(mark.material, DepthLook.unshaded())
	var body := Node2D.new()
	DepthLook.keep_vivid(body)
	assert_true(body.material == null, "bodies and props at z 0 are not touched")
	DepthLook.active = false
	mark.free()
	body.free()
