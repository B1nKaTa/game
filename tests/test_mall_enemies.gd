extends TestCase


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


func _room(cells: Vector2i) -> Rect2:
	return ForemanBehavior.room_rect(cells)


# --- the Mall Walkers ---

func test_walkers_come_in_lines_of_three() -> void:
	var def := _load("mall_walker")
	assert_eq(def.group_size, 3)
	assert_eq(WalkerLine.SIZE, 3)
	assert_eq(def.pension_drop, 1)


func test_a_walkers_loop_is_a_closed_rectangle_of_four_by_three_cells() -> void:
	var tile := float(RoomBackdrop.TILE)
	var loop := MallWalkerBehavior.walker_loop(Vector2(200, 150), Vector2i(20, 11))
	assert_eq(loop.size(), 4, "four corners")
	var xs := {}
	var ys := {}
	for corner in loop:
		xs[snappedf(corner.x, 0.01)] = true
		ys[snappedf(corner.y, 0.01)] = true
	assert_eq(xs.size(), 2, "two columns of corners")
	assert_eq(ys.size(), 2, "two rows of corners")
	var width := absf(loop[1].x - loop[0].x) + absf(loop[1].y - loop[0].y)
	var height := absf(loop[2].x - loop[1].x) + absf(loop[2].y - loop[1].y)
	assert_near(width, MallWalkerBehavior.LOOP_CELLS.x * tile)
	assert_near(height, MallWalkerBehavior.LOOP_CELLS.y * tile)
	for i in 4:
		var edge := loop[(i + 1) % 4] - loop[i]
		assert_true(is_zero_approx(edge.x) or is_zero_approx(edge.y), "edge %d runs straight" % i)
	var perimeter := MallWalkerBehavior.loop_length(loop)
	assert_near(perimeter, 2.0 * (4.0 + 3.0) * tile, "closed back to the start")
	assert_true(MallWalkerBehavior.point_along(loop, perimeter).is_equal_approx(loop[0]), "a full lap ends where it began")
	assert_true(MallWalkerBehavior.point_along(loop, perimeter + 10.0).is_equal_approx(MallWalkerBehavior.point_along(loop, 10.0)))


func test_a_walkers_loop_stays_inside_the_room() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for cells in [Vector2i(14, 9), Vector2i(20, 11), Vector2i(30, 17), Vector2i(10, 7)]:
		var room := _room(cells)
		for i in 60:
			var origin := Vector2(rng.randf_range(room.position.x, room.end.x), rng.randf_range(room.position.y, room.end.y))
			for corner in MallWalkerBehavior.walker_loop(origin, cells):
				assert_true(room.grow(0.01).has_point(corner), "%s outside %s" % [str(corner), str(room)])


func test_a_loop_avoids_blocked_cells_when_it_can() -> void:
	# Open only up to x 340, so a loop running right from its start would cross blocked cells.
	var is_open := func(spot: Vector2) -> bool: return spot.x <= 340.0
	var loop := MallWalkerBehavior.walker_loop(Vector2(320, 150), Vector2i(20, 11), is_open)
	for i in 4:
		var from: Vector2 = loop[i]
		var to: Vector2 = loop[(i + 1) % 4]
		for step in 9:
			assert_true(from.lerp(to, step / 8.0).x <= 340.0, "the loop turned away from the blocked side")


func test_a_loop_moves_to_open_floor_when_no_turn_of_it_is_open() -> void:
	# Open only from x 400, far right of the start, so all four turns at the start cross something.
	var is_open := func(spot: Vector2) -> bool: return spot.x >= 400.0
	var loop := MallWalkerBehavior.walker_loop(Vector2(100, 150), Vector2i(20, 11), is_open)
	assert_near(MallWalkerBehavior.loop_length(loop), 2.0 * (4.0 + 3.0) * RoomBackdrop.TILE, "still a full loop")
	for corner in loop:
		assert_true(corner.x >= 400.0, "%s lies on open floor" % str(corner))
	assert_true(loop[0].x <= 400.0 + RoomBackdrop.TILE, "the open loop nearest the start")


func test_a_loop_with_nowhere_open_stays_where_it_started() -> void:
	var is_open := func(_spot: Vector2) -> bool: return false
	var loop := MallWalkerBehavior.walker_loop(Vector2(200, 150), Vector2i(20, 11), is_open)
	assert_eq(loop.size(), 4)
	for corner in loop:
		assert_true(corner.is_equal_approx(Vector2(200, 150)), "marks time at the start, not through props")
	assert_true(MallWalkerBehavior.point_along(loop, 50.0).is_equal_approx(Vector2(200, 150)))


func test_walkers_hurt_on_contact_at_most_once_in_0_8_seconds() -> void:
	var clock := MallWalkerBehavior.ContactClock.new()
	var hits := 0
	for frame in 120:
		if clock.touch(1.0 / 60.0, true):
			hits += 1
	assert_eq(hits, 3, "two seconds of touching hurts at 0, 0.8 and 1.6")
	var apart := MallWalkerBehavior.ContactClock.new()
	assert_false(apart.touch(0.1, false), "not touching never hurts")
	assert_near(MallWalkerBehavior.CONTACT_EVERY, 0.8)


func test_the_whistle_warns_then_the_line_breaks_off() -> void:
	assert_near(WalkerLine.WHISTLE_TIME, 0.8)
	assert_near(WalkerLine.BREAK_TIME, 2.0)
	var walk := PlayerStats.BASE_SPEED * (WalkerLine.WHISTLE_TIME - 0.3)
	assert_true(walk > MallWalkerBehavior.WARNING_RADIUS, "time to step aside")


func test_a_line_whistles_only_from_its_first_living_member() -> void:
	var a := Enemy.new()
	a.setup(_load("mall_walker"), null, 0.5)
	var b := Enemy.new()
	b.setup(_load("mall_walker"), null, 0.5)
	var line := WalkerLine.new()
	line.members.append(a)
	line.members.append(b)
	assert_eq(line.leader(), a)
	assert_eq(line.place_of(b), 1)
	a.take_damage(INF, Vector2.ZERO)
	assert_eq(line.leader(), b, "the next one takes over")
	a.free()
	b.free()
