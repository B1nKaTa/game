extends TestCase


func _layout(rows: Array) -> RoomLayout:
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_HEALING
	layout.rows = PackedStringArray(rows)
	return layout


func _room_with(changes: Dictionary) -> RoomLayout:
	var rows := ["#".repeat(20)]
	for y in range(1, 10):
		rows.append("#" + ".".repeat(18) + "#")
	rows.append("#".repeat(20))
	rows[5] = "#" + ".".repeat(18) + "#"
	rows[4] = rows[4].substr(0, 9) + "H" + rows[4].substr(10)
	for cell: Vector2i in changes:
		var row: String = rows[cell.y]
		rows[cell.y] = row.substr(0, cell.x) + changes[cell] + row.substr(cell.x + 1)
	return _layout(rows)


# --- slows ---

func test_a_slow_fades_when_its_time_runs_out() -> void:
	var slow := SlowEffect.new()
	slow.apply(0.5, 1.0)
	assert_near(slow.speed_factor(), 0.5)
	assert_true(slow.is_active())
	slow.tick(1.01)
	assert_near(slow.speed_factor(), 1.0)
	assert_false(slow.is_active())


func test_the_strongest_slow_wins_and_never_stops_him() -> void:
	var slow := SlowEffect.new()
	slow.apply(0.3, 2.0)
	slow.apply(0.9, 0.5)
	assert_near(slow.speed_factor(), 0.4, "capped so he can always move")
	slow.tick(0.6)
	assert_near(slow.speed_factor(), 0.7)


func test_a_new_slow_never_shortens_one_already_running() -> void:
	var slow := SlowEffect.new()
	slow.apply(0.5, 2.0)
	slow.apply(0.5, 0.2)
	slow.tick(1.0)
	assert_near(slow.speed_factor(), 0.5)


func test_a_player_can_be_slowed() -> void:
	var player := Player.new()
	player.slow(0.5, 1.0)
	assert_near(player.slow_factor(), 0.5)
	player.free()


# --- sliding ---

func test_dry_ground_answers_at_once_and_wet_ground_slides() -> void:
	var dry := SlideRule.velocity(Vector2(100, 0), Vector2.ZERO, false, 0.1)
	assert_eq(dry, Vector2.ZERO)
	var wet := SlideRule.velocity(Vector2(100, 0), Vector2.ZERO, true, 0.1)
	assert_true(wet.x > 0.0 and wet.x < 100.0, "keeps some speed after letting go")


func test_wet_ground_still_comes_to_rest() -> void:
	var moving := Vector2(120, 0)
	for i in 60:
		moving = SlideRule.velocity(moving, Vector2.ZERO, true, 1.0 / 60.0)
	assert_true(moving.length() < 5.0, "a second later he has all but stopped, %f" % moving.length())


func test_wet_ground_turns_slowly_toward_the_new_way() -> void:
	var turned := SlideRule.velocity(Vector2(100, 0), Vector2(0, 100), true, 0.1)
	assert_true(turned.x > 0.0 and turned.y > 0.0 and turned.y < 100.0)


# --- wet floors in a room ---

func test_wet_cells_are_a_known_symbol_that_blocks_nothing() -> void:
	assert_true(RoomLayout.ALLOWED.contains(RoomLayout.SYMBOL_WET))
	assert_false(RoomLayout.SOLID_SYMBOLS.contains(RoomLayout.SYMBOL_WET))
	assert_false(RoomLayout.WALLS_AND_BOMB_ONLY.contains(RoomLayout.SYMBOL_WET))
	var layout := _room_with({Vector2i(9, 6): "W", Vector2i(10, 6): "W"})
	assert_eq(layout.validate().size(), 0, str(layout.validate()))


func test_wet_floor_keeps_two_cells_clear_of_every_door() -> void:
	var near := _room_with({Vector2i(3, 5): "W"})
	assert_true(near.validate().size() > 0, "two cells from the west door is too close")
	var clear := _room_with({Vector2i(4, 5): "W"})
	assert_eq(clear.validate().size(), 0, str(clear.validate()))


func test_a_wet_floor_covers_its_own_cell_only() -> void:
	var wet := WetFloor.new()
	wet.position = RoomBackdrop.cell_center(Vector2i(4, 4))
	assert_true(wet.covers(RoomBackdrop.cell_center(Vector2i(4, 4)) + Vector2(15, -15)))
	assert_false(wet.covers(RoomBackdrop.cell_center(Vector2i(5, 4))))
	assert_true(WetFloor.any_covers([wet], RoomBackdrop.cell_center(Vector2i(4, 4))))
	assert_false(WetFloor.any_covers([wet], Vector2.ZERO))
	wet.free()


func test_each_wet_patch_gets_one_caution_sign_beside_it() -> void:
	var layout := _room_with({Vector2i(6, 7): "W", Vector2i(7, 7): "W", Vector2i(14, 3): "W"})
	var signs: Array[Vector2i] = WetFloor.sign_cells(layout)
	assert_eq(signs.size(), 2, "two patches, two signs")
	for cell in signs:
		assert_eq(layout.symbol_at(cell), RoomLayout.SYMBOL_FLOOR)
		var touches := false
		for side in RoomLayout.SIDES:
			touches = touches or layout.symbol_at(cell + side) == RoomLayout.SYMBOL_WET
		assert_true(touches, "the sign stands beside its patch")


func test_the_caution_sign_is_decor_anything_can_break() -> void:
	var caution := WetSign.new()
	assert_false(caution.is_solid())
	for source in [BreakableBlock.SOURCE_CANE, BreakableBlock.SOURCE_BLAST, BreakableBlock.SOURCE_BOSS]:
		assert_true(caution.can_break_by(source), source)
	caution.free()
