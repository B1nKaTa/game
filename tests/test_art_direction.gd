extends TestCase

# The depth look (docs/art/art-direction-notes.md) and the shared pieces it brought: contact shadows,
# door openings with signs, and the HUD's clear middle.


func test_only_the_records_basement_is_drawn_in_the_depth_look() -> void:
	for file in DirAccess.get_files_at("res://data/floors"):
		if not file.ends_with(".tres"):
			continue
		var def: FloorDef = load("res://data/floors/" + file)
		var wanted := DepthLook.STYLE if def.id == "floor_1" else ""
		assert_eq(def.art_style, wanted, def.id)
	assert_true(DepthLook.for_floor(load("res://data/floors/floor_1.tres")) != null, "its depth art is all there")
	assert_eq(DepthLook.for_floor(load("res://data/floors/cemetery.tres")), null)


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
			assert_true(absi(cell.x - width / 2) > DepthLook.DOOR_CLEAR, "width %d: %s" % [width, str(cell)])


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
