extends TestCase

# Head Office's red tape: walking into it holds Grandpa for a moment, a dodge cuts it for a while,
# enemies ignore it, it never hurts, and it keeps clear of doors.


func _room_with(changes: Dictionary) -> RoomLayout:
	var rows := ["#".repeat(20)]
	for y in range(1, 10):
		rows.append("#" + ".".repeat(18) + "#")
	rows.append("#".repeat(20))
	rows[4] = rows[4].substr(0, 9) + "H" + rows[4].substr(10)
	for cell: Vector2i in changes:
		var row: String = rows[cell.y]
		rows[cell.y] = row.substr(0, cell.x) + changes[cell] + row.substr(cell.x + 1)
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_HEALING
	layout.rows = PackedStringArray(rows)
	return layout


func _tape_at(cell: Vector2i) -> RedTape:
	var tape := RedTape.new()
	tape.position = RoomBackdrop.cell_center(cell)
	return tape


# Seconds held when he walks onto tape and keeps standing there, stepping by delta.
func _held_for(delta: float) -> float:
	var rule := RedTapeRule.new()
	var held := 0.0
	rule.step(false, false, delta)
	for frame in ceili(3.0 / delta):
		if rule.step(true, false, delta):
			held += delta
	return held


# --- the hold ---

func test_walking_into_tape_holds_him_for_0_6_seconds_whatever_the_frame_times() -> void:
	assert_near(RedTapeRule.HOLD, 0.6)
	for delta: float in [1.0 / 30.0, 1.0 / 60.0, 1.0 / 144.0, 0.05]:
		var held := _held_for(delta)
		assert_true(absf(held - RedTapeRule.HOLD) <= delta + 0.001, "held %f at a frame of %f" % [held, delta])


func test_once_it_lets_go_he_walks_on_through() -> void:
	var rule := RedTapeRule.new()
	assert_false(rule.step(false, false, 0.1), "clear floor holds no one")
	assert_true(rule.step(true, false, 0.1), "walking onto it holds him")
	for i in 6:
		rule.step(true, false, 0.1)
	assert_false(rule.step(true, false, 0.1), "after the hold he walks on, still standing on it")
	assert_false(rule.is_holding())
	assert_false(rule.step(true, false, 0.1), "and it does not catch him again on the same tape")
	assert_false(rule.step(false, false, 0.1), "off it")
	assert_true(rule.step(true, false, 0.1), "stepping onto tape again holds him again")


func test_a_dodge_is_never_held_and_frees_him_from_a_hold() -> void:
	var rule := RedTapeRule.new()
	rule.step(false, false, 0.016)
	assert_false(rule.step(true, true, 0.016), "dodging onto tape")
	var held := RedTapeRule.new()
	held.step(false, false, 0.016)
	assert_true(held.step(true, false, 0.016))
	assert_false(held.step(true, true, 0.016), "a dodge breaks the hold at once")
	assert_near(held.hold_left(), 0.0)


# --- cutting it ---

func test_a_dodge_through_tape_cuts_it_and_it_is_strung_again_six_seconds_later() -> void:
	assert_near(RedTapeRule.CUT_TIME, 6.0)
	var tape := _tape_at(Vector2i(5, 5))
	var tapes := [tape]
	var on := RoomBackdrop.cell_center(Vector2i(5, 5))
	assert_true(RedTape.touch_among(tapes, on, false), "walking, it holds")
	assert_false(tape.is_cut(), "walking never cuts it")
	assert_false(RedTape.touch_among(tapes, on, true), "dodging, it never holds")
	assert_true(tape.is_cut(), "the dodge cut it")
	assert_false(RedTape.any_holds(tapes, on), "cut tape holds no one")
	assert_false(RedTape.touch_among(tapes, on, false), "not even someone walking")
	assert_false(tape.advance(RedTapeRule.CUT_TIME - 0.1), "still cut just before six seconds")
	assert_true(tape.is_cut())
	assert_true(tape.advance(0.2), "strung again")
	assert_false(tape.is_cut())
	assert_true(RedTape.any_holds(tapes, on))
	tape.free()


func test_a_dodge_cuts_only_the_tape_under_his_feet() -> void:
	var near := _tape_at(Vector2i(5, 5))
	var far := _tape_at(Vector2i(6, 5))
	RedTape.touch_among([near, far], RoomBackdrop.cell_center(Vector2i(5, 5)), true)
	assert_true(near.is_cut())
	assert_false(far.is_cut(), "the next cell along stays strung, so the cut is a gap he made")
	near.free()
	far.free()


func test_tape_covers_its_own_cell_only() -> void:
	var tape := _tape_at(Vector2i(3, 3))
	var tapes := [tape]
	assert_true(RedTape.any_holds(tapes, RoomBackdrop.cell_center(Vector2i(3, 3))))
	assert_true(RedTape.any_holds(tapes, Vector2(3 * 32 + 1, 3 * 32 + 1)), "the corner of its cell")
	assert_false(RedTape.any_holds(tapes, RoomBackdrop.cell_center(Vector2i(4, 3))), "the next cell")
	assert_false(RedTape.any_holds([], Vector2.ZERO))
	assert_false(RedTape.touch(null, Vector2.ZERO, false), "no room, no tape")
	tape.free()


# --- what it is not ---

func test_red_tape_never_costs_a_pill() -> void:
	var empty: Array[UpgradeDef] = []
	var run := RunState.new(empty, {})
	var pills := run.health.pills
	var rule := RedTapeRule.new()
	var tape := _tape_at(Vector2i(2, 2))
	for i in 300:
		rule.step(i % 40 < 20, i % 90 == 0, 0.05)
		tape.advance(0.05)
	RedTape.touch_among([tape], RoomBackdrop.cell_center(Vector2i(2, 2)), true)
	assert_eq(run.health.pills, pills)
	assert_false(tape.has_method("hit_target") or tape.has_method("damage") or tape.has_method("take_hit"), "tape has no way to hurt")
	tape.free()


func test_enemies_walk_over_tape_as_over_floor() -> void:
	var layout := _room_with({Vector2i(6, 6): "x", Vector2i(7, 6): "x", Vector2i(8, 6): "x"})
	var grid := WalkGrid.from_layout(layout)
	for x in range(6, 9):
		assert_true(grid.is_open(Vector2i(x, 6)), "the walk grid is open at %d,6" % x)
	assert_false(RoomLayout.SOLID_SYMBOLS.contains(RoomLayout.SYMBOL_RED_TAPE))
	var enemy_source := FileAccess.get_file_as_string("res://scripts/actors/enemy.gd")
	assert_false(enemy_source.contains("RedTape"), "no enemy is ever held by it")


func test_a_held_grandpa_is_shown_tangled() -> void:
	var empty: Array[UpgradeDef] = []
	var player := Player.new()
	player.setup(RunState.new(empty, {}))
	assert_false(player.is_taped())
	assert_false(player.is_dodging())
	player._tape.step(false, false, 0.016)
	player._tape.step(true, false, 0.016)
	assert_true(player.is_taped())
	player._dodge.try_start(0.0)
	assert_true(player.is_dodging())
	player.free()


# --- in a layout ---

func test_tape_is_walkable_floor_kept_clear_of_doors() -> void:
	var symbol := RoomLayout.SYMBOL_RED_TAPE
	assert_eq(symbol, "x")
	assert_true(RoomLayout.ALLOWED.contains(symbol))
	assert_false(RoomLayout.WALLS_AND_BOMB_ONLY.contains(symbol))
	assert_false(RoomLayout.DECOR_SYMBOLS.contains(symbol))
	assert_eq(RoomLayout.RED_TAPE_DOOR_CLEARANCE, 2)
	var good := _room_with({Vector2i(5, 3): "x", Vector2i(6, 3): "x", Vector2i(7, 3): "x", Vector2i(14, 6): "x", Vector2i(14, 7): "x"})
	assert_eq(good.validate().size(), 0, str(good.validate()))
	assert_true(_room_with({Vector2i(10, 3): "x"}).validate().size() > 0, "two cells below the north door is too close")
	assert_true(_room_with({Vector2i(3, 5): "x"}).validate().size() > 0, "two cells from the west door is too close")
	assert_true(_room_with({Vector2i(16, 4): "x"}).validate().size() > 0, "two cells from the east door, a row off, is too close")
	assert_eq(_room_with({Vector2i(10, 4): "x"}).validate().size(), 0, "three cells away is fine")


func test_a_strand_runs_the_way_its_cells_run() -> void:
	var layout := _room_with({Vector2i(5, 3): "x", Vector2i(6, 3): "x", Vector2i(14, 6): "x", Vector2i(14, 7): "x", Vector2i(4, 7): "x"})
	assert_true(RedTape.runs_across(layout, Vector2i(5, 3)), "along its row")
	assert_true(RedTape.runs_across(layout, Vector2i(6, 3)))
	assert_false(RedTape.runs_across(layout, Vector2i(14, 6)), "down its column")
	assert_false(RedTape.runs_across(layout, Vector2i(14, 7)))
	assert_true(RedTape.runs_across(layout, Vector2i(4, 7)), "a single cell runs across")


func test_old_layouts_hold_no_tape() -> void:
	for path in ["res://data/rooms/floor_1/combat_01.tres", "res://data/rooms/golden_years_mall/combat_01.tres"]:
		var layout: RoomLayout = load(path)
		assert_true(layout.cells_of(RoomLayout.SYMBOL_RED_TAPE).is_empty(), path)


# --- tape the Chairman lays ---

func test_laid_tape_warns_first_then_holds_for_ten_seconds_then_comes_down() -> void:
	assert_near(TapeSpread.WARNING, 1.0)
	assert_near(TapeSpread.LAST, 10.0)
	var cells: Array[Vector2i] = [Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3)]
	var spread := TapeSpread.new()
	spread.setup(cells, true)
	spread._ready()
	var tapes := spread.tapes()
	assert_eq(tapes.size(), 3)
	var on := RoomBackdrop.cell_center(Vector2i(4, 3))
	assert_false(RedTape.any_holds(tapes, on), "only a warning at first")
	assert_false(spread.advance(TapeSpread.WARNING - 0.1))
	assert_false(RedTape.any_holds(tapes, on), "still a warning")
	assert_true(spread.advance(0.2), "strung once the warning ends")
	assert_true(RedTape.any_holds(tapes, on))
	assert_false(spread.is_done())
	spread.advance(TapeSpread.LAST - 0.3)
	assert_false(spread.is_done(), "it lasts its ten seconds")
	spread.advance(0.5)
	assert_true(spread.is_done(), "then comes down")
	spread.free()


func test_laid_tape_is_cleared_from_a_stored_room_and_strung_tape_is_kept() -> void:
	var spread := TapeSpread.new()
	assert_true(RoomView.is_passing_effect(spread), "an attack's tape goes when Grandpa leaves")
	spread.free()
	var tape := RedTape.new()
	assert_false(RoomView.is_passing_effect(tape), "the room's own tape stays strung")
	tape.free()
