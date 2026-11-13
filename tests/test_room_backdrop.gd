extends TestCase

const SIZES: Array[Vector2i] = [Vector2i(14, 9), Vector2i(20, 10), Vector2i(20, 11), Vector2i(30, 17)]


func _pixels(cells: Vector2i) -> Vector2:
	return Vector2(cells) * RoomBackdrop.TILE


func test_overdraw_covers_the_view_plus_the_biggest_shake_at_every_camera_rest() -> void:
	var reach := ScreenShake.BOSS_DEATH
	var half_view := RoomBackdrop.VIEW_SIZE / 2.0
	for cells in SIZES:
		var room := _pixels(cells)
		var rect := RoomBackdrop.overdraw_rect(room)
		for focus: Vector2 in [Vector2.ZERO, room, Vector2(0, room.y), Vector2(room.x, 0)]:
			var center := RoomCamera.center_for(room, focus, RoomBackdrop.VIEW_SIZE, Hud.BAND_BOTTOM)
			assert_true(rect.position.x < center.x - half_view.x - reach, "left %s" % str(cells))
			assert_true(rect.position.y < center.y - half_view.y - reach, "top %s" % str(cells))
			assert_true(rect.end.x > center.x + half_view.x + reach, "right %s" % str(cells))
			assert_true(rect.end.y > center.y + half_view.y + reach, "bottom %s" % str(cells))


func test_the_wall_rim_reaches_past_the_room_by_more_than_the_biggest_shake() -> void:
	var rim := RoomBackdrop.wall_rim_rect(_pixels(Vector2i(30, 17)))
	assert_true(rim.position.x < -ScreenShake.BOSS_DEATH)
	assert_true(rim.end.y > 17 * RoomBackdrop.TILE + ScreenShake.BOSS_DEATH)


func test_a_small_room_has_darkness_past_its_rim() -> void:
	var room := _pixels(Vector2i(14, 9))
	var rim := RoomBackdrop.wall_rim_rect(room)
	var center := RoomCamera.center_for(room, Vector2.ZERO, RoomBackdrop.VIEW_SIZE, Hud.BAND_BOTTOM)
	assert_true(rim.position.x > center.x - RoomBackdrop.VIEW_SIZE.x / 2.0)
	assert_true(rim.end.y < center.y + RoomBackdrop.VIEW_SIZE.y / 2.0)


func test_a_floor_can_override_the_room_colors() -> void:
	var def := FloorDef.new()
	assert_eq(def.room_palette().wall, RoomPalette.new().wall, "a floor without a palette uses the default")
	var moss := RoomPalette.new()
	moss.wall = Color("2f4a33")
	def.palette = moss
	assert_eq(def.room_palette().wall, Color("2f4a33"))


func test_torches_sit_in_the_walls_of_any_size() -> void:
	for cells in SIZES:
		var torches := Lighting.torch_cells(cells)
		assert_true(torches.size() >= 4, str(cells))
		for torch in torches:
			var in_room := torch.x >= 0 and torch.y >= 0 and torch.x < cells.x and torch.y < cells.y
			var on_edge := torch.x == 0 or torch.y == 0 or torch.x == cells.x - 1 or torch.y == cells.y - 1
			assert_true(in_room and on_edge, "%s %s" % [str(cells), str(torch)])


func test_bigger_rooms_get_more_torches() -> void:
	assert_true(Lighting.torch_cells(Vector2i(30, 17)).size() > Lighting.torch_cells(Vector2i(20, 11)).size())
