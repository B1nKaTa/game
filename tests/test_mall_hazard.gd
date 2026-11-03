extends TestCase


func _room_with(changes: Dictionary, reverse := false) -> RoomLayout:
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
	layout.strips_reverse = reverse
	return layout


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


# --- the carry ---

func test_walking_against_a_strip_is_slow_and_with_it_fast() -> void:
	var carry := ConveyorRule.carry(Vector2.RIGHT, 60.0)
	assert_true(carry.is_equal_approx(Vector2(60, 0)), str(carry))
	assert_near((Vector2.LEFT * 120.0 + carry).length(), 60.0, "against it nets 60")
	assert_near((Vector2.RIGHT * 120.0 + carry).length(), 180.0, "with it 180")


func test_walking_across_a_strip_drifts_along_it() -> void:
	var moved := Vector2.DOWN * 120.0 + ConveyorRule.carry(Vector2.RIGHT, 60.0)
	assert_near(moved.y, 120.0, "the walk across is kept")
	assert_near(moved.x, 60.0, "and the strip carries him along")


func test_the_carry_follows_the_strip_whatever_its_way() -> void:
	for way: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2(3, 0)]:
		var carry := ConveyorRule.carry(way, ConveyorRule.SPEED)
		assert_near(carry.length(), ConveyorRule.SPEED)
		assert_true(carry.normalized().is_equal_approx(way.normalized()))


# --- the reversing cycle ---

func test_the_sign_flips_each_period() -> void:
	var cycle := ConveyorCycle.new(6.0, 1.0)
	assert_eq(cycle.direction_sign_at(0.5), 1)
	assert_eq(cycle.direction_sign_at(5.9), 1)
	assert_eq(cycle.direction_sign_at(6.1), -1)
	assert_eq(cycle.direction_sign_at(11.9), -1)
	assert_eq(cycle.direction_sign_at(12.1), 1)
	for lap in 6:
		assert_true(cycle.direction_sign_at(lap * 6.0 + 3.0) != cycle.direction_sign_at((lap + 1) * 6.0 + 3.0), "lap %d" % lap)


func test_the_chime_always_comes_before_each_reversal() -> void:
	var cycle := ConveyorCycle.new(6.0, 1.0)
	for lap in range(1, 8):
		var reversal := lap * 6.0
		assert_true(cycle.is_chiming(reversal - 0.05), "it chimes just before reversal %d" % lap)
		assert_true(cycle.is_chiming(reversal - 0.95), "for the whole chime")
		assert_false(cycle.is_chiming(reversal - 1.05), "but not long before")
		assert_false(cycle.is_chiming(reversal + 0.05), "and not after")
	var time := 0.0
	var last := cycle.direction_sign_at(0.0)
	var chimed := false
	while time < 60.0:
		time += 0.016
		chimed = chimed or cycle.is_chiming(time)
		var now := cycle.direction_sign_at(time)
		if now != last:
			assert_true(chimed, "a reversal at %f came without a chime" % time)
			chimed = false
			last = now


# --- strips in a room ---

func test_a_strip_carries_whatever_stands_on_it() -> void:
	var strip := ConveyorStrip.new()
	strip.setup(Vector2.RIGHT, false)
	strip.position = Vector2(48, 48)
	var strips := [strip]
	assert_true(ConveyorStrip.carry_from(strips, Vector2(50, 50)).is_equal_approx(Vector2(ConveyorRule.SPEED, 0)))
	assert_eq(ConveyorStrip.carry_from(strips, Vector2(90, 50)), Vector2.ZERO, "off the strip nothing moves")
	assert_eq(ConveyorStrip.carry_from([], Vector2(50, 50)), Vector2.ZERO)
	strip.free()


func test_a_reversing_strip_turns_round_after_its_chime() -> void:
	var strip := ConveyorStrip.new()
	strip.setup(Vector2.UP, true)
	assert_true(strip.direction().is_equal_approx(Vector2.UP))
	strip.advance(ConveyorStrip.PERIOD - ConveyorStrip.CHIME + 0.1)
	assert_true(strip.is_chiming(), "it chimes first")
	assert_true(strip.direction().is_equal_approx(Vector2.UP), "still the old way")
	strip.advance(ConveyorStrip.CHIME)
	assert_true(strip.direction().is_equal_approx(Vector2.DOWN), "then reverses")
	var steady := ConveyorStrip.new()
	steady.setup(Vector2.UP, false)
	steady.advance(ConveyorStrip.PERIOD * 3.5)
	assert_true(steady.direction().is_equal_approx(Vector2.UP), "a steady strip never turns")
	assert_false(steady.is_chiming())
	strip.free()
	steady.free()


func test_a_boss_reverses_or_speeds_strips_only_after_their_chime() -> void:
	var strip := ConveyorStrip.new()
	strip.setup(Vector2.RIGHT, false)
	strip.take_control(ConveyorStrip.REVERSE)
	assert_true(strip.is_chiming(), "the strips chime first")
	strip.advance(ConveyorStrip.CHIME - 0.1)
	assert_true(strip.direction().is_equal_approx(Vector2.RIGHT), "nothing changes during the chime")
	strip.advance(0.2)
	assert_true(strip.direction().is_equal_approx(Vector2.LEFT), "then they reverse")
	var fast := ConveyorStrip.new()
	fast.setup(Vector2.RIGHT, false)
	fast.take_control(ConveyorStrip.SPEED_UP)
	fast.advance(ConveyorStrip.CHIME + 0.1)
	assert_near(fast.speed(), ConveyorRule.SPEED * ConveyorStrip.BOOST)
	fast.advance(ConveyorStrip.BOOST_TIME)
	assert_near(fast.speed(), ConveyorRule.SPEED, "the boost wears off")
	assert_near(ConveyorStrip.BOOST, 1.5)
	assert_near(ConveyorStrip.BOOST_TIME, 4.0)
	strip.free()
	fast.free()


func test_ghosts_mounds_and_wall_fixtures_are_not_carried() -> void:
	var walker := Enemy.new()
	walker.setup(_load("intern_reaper"), null, 0.5)
	assert_true(walker.rides_strips())
	walker.submerged = true
	assert_false(walker.rides_strips(), "underground it is not carried")
	var ghost := Enemy.new()
	ghost.setup(_load("debt_ghost"), null, 0.5)
	assert_false(ghost.rides_strips(), "a ghost floats over")
	var valve := Enemy.new()
	valve.setup(_load("steam_valve"), null, 0.5)
	assert_false(valve.rides_strips(), "bolted to the wall")
	walker.free()
	ghost.free()
	valve.free()


func test_a_strip_never_costs_a_pill() -> void:
	var empty: Array[UpgradeDef] = []
	var run := RunState.new(empty, {})
	var strip := ConveyorStrip.new()
	strip.setup(Vector2.RIGHT, true)
	var pills := run.health.pills
	for i in 600:
		strip.advance(0.05)
	strip.take_control(ConveyorStrip.SPEED_UP)
	strip.advance(6.0)
	assert_eq(run.health.pills, pills)
	assert_false(strip.has_method("hit_target") or strip.has_method("damage"), "a strip has no way to hurt")
	strip.free()


func test_strips_are_walkable_floor_kept_clear_of_doors() -> void:
	for symbol in RoomLayout.STRIP_SYMBOLS:
		assert_true(RoomLayout.ALLOWED.contains(symbol), symbol)
		assert_false(RoomLayout.SOLID_SYMBOLS.contains(symbol), symbol)
		assert_false(RoomLayout.WALLS_AND_BOMB_ONLY.contains(symbol), symbol)
		assert_false(RoomLayout.DECOR_SYMBOLS.contains(symbol), symbol)
	assert_eq(RoomLayout.strip_direction(">"), Vector2i.RIGHT)
	assert_eq(RoomLayout.strip_direction("<"), Vector2i.LEFT)
	assert_eq(RoomLayout.strip_direction("^"), Vector2i.UP)
	assert_eq(RoomLayout.strip_direction("v"), Vector2i.DOWN)
	var good := _room_with({Vector2i(5, 3): ">", Vector2i(6, 3): ">", Vector2i(7, 3): ">", Vector2i(14, 6): "^", Vector2i(14, 7): "^"})
	assert_eq(good.validate().size(), 0, str(good.validate()))
	assert_true(_room_with({Vector2i(10, 3): "v"}).validate().size() > 0, "two cells below the north door is too close")
	assert_true(_room_with({Vector2i(3, 5): "<"}).validate().size() > 0, "two cells from the west door is too close")
	assert_eq(_room_with({Vector2i(10, 4): "v"}).validate().size(), 0, "three cells away is fine")


func test_old_layouts_neither_reverse_nor_hold_strips() -> void:
	var layout: RoomLayout = load("res://data/rooms/floor_1/combat_01.tres")
	assert_false(layout.strips_reverse)
	for symbol in RoomLayout.STRIP_SYMBOLS:
		assert_true(layout.cells_of(symbol).is_empty())
