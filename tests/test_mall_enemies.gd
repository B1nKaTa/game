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
	assert_near(WalkerLine.BREAK_TIME, 2.5)
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


# --- the Mall Cop ---

func test_the_mall_cop_charges_down_a_warned_lane() -> void:
	assert_near(MallCopBehavior.WINDUP, 0.8)
	assert_near(MallCopBehavior.CHARGE_LENGTH, 260.0)
	var walk := PlayerStats.BASE_SPEED * (MallCopBehavior.WINDUP - 0.3)
	assert_true(walk > MallCopBehavior.LANE_WIDTH, "time to step out of the lane")


func test_his_whistle_finds_the_nearest_other_enemy() -> void:
	var spots: Array[Vector2] = [Vector2(100, 100), Vector2(400, 100), Vector2(130, 120), Vector2(90, 300)]
	assert_eq(MallCopBehavior.nearest_other(spots, 0), 2)
	assert_eq(MallCopBehavior.nearest_other(spots, 2), 0)
	assert_eq(MallCopBehavior.nearest_other(spots, 1), 2)
	var alone: Array[Vector2] = [Vector2(10, 10)]
	assert_eq(MallCopBehavior.nearest_other(alone, 0), -1, "alone he calls no one")
	var none: Array[Vector2] = []
	assert_eq(MallCopBehavior.nearest_other(none, 0), -1)


func test_a_called_enemy_hurries_to_grandpa_for_two_seconds() -> void:
	assert_near(Enemy.RALLY_SPEED, 1.5)
	assert_near(MallCopBehavior.RALLY_TIME, 2.0)
	var enemy := Enemy.new()
	enemy.setup(_load("intern_reaper"), null, 0.5)
	assert_false(enemy.is_rallied())
	enemy.rally(MallCopBehavior.RALLY_TIME)
	assert_true(enemy.is_rallied())
	var boss := Enemy.new()
	boss.setup(_load("reverend"), null, 0.5)
	boss.rally(MallCopBehavior.RALLY_TIME)
	assert_false(boss.is_rallied(), "a boss answers no whistle")
	enemy.free()
	boss.free()


# --- the Perfume Sprayer ---

func test_the_sprayer_keeps_her_distance() -> void:
	assert_eq(PerfumeSprayerBehavior.step(60.0), PerfumeSprayerBehavior.BACK_OFF)
	assert_eq(PerfumeSprayerBehavior.step(119.0), PerfumeSprayerBehavior.BACK_OFF)
	assert_eq(PerfumeSprayerBehavior.step(150.0), PerfumeSprayerBehavior.HOLD)
	assert_eq(PerfumeSprayerBehavior.step(PerfumeSprayerBehavior.TOO_FAR + 1.0), PerfumeSprayerBehavior.CLOSE_IN)
	assert_true(PerfumeSprayerBehavior.TOO_CLOSE >= 120.0)


func test_her_clouds_follow_the_plan() -> void:
	assert_near(PerfumeCloud.WARNING, 0.9)
	assert_near(PerfumeCloud.LINGER, 4.0)
	assert_near(PerfumeCloud.RADIUS, 40.0)
	assert_near(PerfumeHaze.LIGHT_RADIUS_IN_CLOUD, 55.0)


func test_a_cloud_covers_its_circle_only_once_it_lands_and_until_it_fades() -> void:
	var cloud := PerfumeCloud.new()
	cloud.setup(null, PerfumeCloud.WARNING, PerfumeCloud.LINGER, PerfumeCloud.RADIUS)
	cloud.position = Vector2(200, 200)
	var clouds := [cloud]
	assert_false(PerfumeCloud.any_covers(clouds, Vector2(200, 200)), "not while it is only a warning")
	cloud.advance(PerfumeCloud.WARNING + 0.05)
	assert_true(cloud.has_landed())
	assert_true(PerfumeCloud.any_covers(clouds, Vector2(200, 200)))
	assert_true(PerfumeCloud.any_covers(clouds, Vector2(235, 210)), "inside its radius")
	assert_false(PerfumeCloud.any_covers(clouds, Vector2(245, 200)), "outside it")
	cloud.advance(PerfumeCloud.LINGER)
	assert_false(PerfumeCloud.any_covers(clouds, Vector2(200, 200)), "faded")
	assert_true(cloud.is_finished())
	assert_true(PerfumeCloud.covers_point(Vector2.ZERO, 40.0, Vector2(0, 40)))
	assert_false(PerfumeCloud.covers_point(Vector2.ZERO, 40.0, Vector2(0, 40.5)))
	cloud.free()


func test_a_cloud_never_costs_a_pill_and_its_warning_leaves_time_to_walk_out() -> void:
	var cloud := PerfumeCloud.new()
	assert_false(cloud.has_method("hit_target") or cloud.has_method("damage"))
	cloud.free()
	var walk := PlayerStats.BASE_SPEED * (PerfumeCloud.WARNING - 0.2)
	assert_true(walk > PerfumeCloud.RADIUS, "%f" % walk)


func test_the_haze_shows_only_in_a_cloud_and_warnings_draw_above_it() -> void:
	assert_true(PerfumeHaze.Z < Enemy.WARNING_Z, "warnings stay above the haze")
	assert_true(PerfumeHaze.Z < Projectile.SHOT_Z, "and shots and marks too")
	assert_near(PerfumeHaze.shade_toward(0.0, true, 1.0), PerfumeHaze.DARKNESS, "in a cloud it closes in")
	assert_near(PerfumeHaze.shade_toward(PerfumeHaze.DARKNESS, false, 1.0), 0.0, "and clears outside one")
	assert_true(PerfumeHaze.shade_toward(0.0, true, 0.05) > 0.0)
	assert_true(PerfumeHaze.shade_toward(0.0, true, 0.05) < PerfumeHaze.DARKNESS, "it eases in")


# --- the returning pair ---

func test_the_returning_basement_enemies_keep_their_ways_in_the_malls_colours() -> void:
	for pair in [["mall_intern_reaper", "intern_reaper"], ["mall_notary_public", "notary_public"]]:
		var mine := _load(pair[0])
		var theirs := _load(pair[1])
		assert_eq(mine.behavior_script, theirs.behavior_script, pair[0])
		assert_near(mine.max_hp, theirs.max_hp, pair[0])
		assert_eq(mine.pension_drop, theirs.pension_drop, pair[0])
		assert_true(mine.color != theirs.color, "%s wears the mall's colours" % pair[0])
		assert_eq(mine.display_name, theirs.display_name)


func test_each_new_enemy_has_its_own_mark() -> void:
	for id in ["mall_walker", "mall_cop", "perfume_sprayer"]:
		var def := _load(id)
		assert_false(def.mark.is_empty(), id)
		assert_eq(def.pension_drop, 1, id)
