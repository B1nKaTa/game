extends TestCase


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


# A pretend room for the puck: a wall down the line x = wall_x, and another along y = floor_y.
func _walls(wall_x: float, floor_y: float) -> Callable:
	var cast := func(from: Vector2, to: Vector2) -> Dictionary:
		var hits: Array = []
		if (from.x < wall_x) != (to.x < wall_x) and not is_equal_approx(from.x, to.x):
			var t := (wall_x - from.x) / (to.x - from.x)
			hits.append([t, Vector2(wall_x, lerpf(from.y, to.y, t)), Vector2(-signf(to.x - from.x), 0.0)])
		if (from.y < floor_y) != (to.y < floor_y) and not is_equal_approx(from.y, to.y):
			var t := (floor_y - from.y) / (to.y - from.y)
			hits.append([t, Vector2(lerpf(from.x, to.x, t), floor_y), Vector2(0.0, -signf(to.y - from.y))])
		if hits.is_empty():
			return {}
		hits.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		return {"position": hits[0][1], "normal": hits[0][2]}
	return cast


# --- the Early Bird Diners ---

func test_diners_come_in_tables_of_three_and_shuffle_slowly() -> void:
	var def := _load("early_bird_diner")
	assert_eq(def.group_size, 3)
	assert_true(def.speed <= 50.0, "they shuffle")
	assert_eq(DinnerBell.SIZE, 3)
	assert_true(def.behavior_script.new() is EarlyBirdDinerBehavior)
	assert_true(DinnerBell.BELL_TIME >= 0.8, "the bell rings long enough to hear")


func test_each_diner_rushes_down_its_own_lane_toward_him() -> void:
	var target := Vector2(200, 200)
	var spots: Array[Vector2] = [Vector2(100, 200), Vector2(200, 80), Vector2(260, 260)]
	var lanes := DinnerBell.rush_lanes(spots, target)
	assert_eq(lanes.size(), 3)
	for i in spots.size():
		assert_near(lanes[i].length(), 1.0)
		assert_true(lanes[i].is_equal_approx(spots[i].direction_to(target)), "lane %d points at him" % i)
	assert_false(lanes[0].is_equal_approx(lanes[1]), "every lane is its own")
	var standing: Array[Vector2] = [target]
	assert_near(DinnerBell.rush_lanes(standing, target)[0].length(), 1.0, "one standing on him still has a lane")


func test_a_rush_runs_a_little_past_where_he_stood() -> void:
	var target := Vector2(300, 200)
	assert_near(DinnerBell.rush_length(Vector2(200, 200), target), 100.0 + DinnerBell.RUSH_PAST)
	assert_near(DinnerBell.rush_length(target, target), DinnerBell.RUSH_MIN, "never a stand-still rush")
	assert_near(DinnerBell.rush_length(Vector2(-500, 200), target), DinnerBell.RUSH_MAX, "never across the whole ship")


func test_the_dinner_bell_leaves_time_to_step_out_of_a_lane() -> void:
	var walk := PlayerStats.BASE_SPEED * (DinnerBell.BELL_TIME - 0.3)
	assert_true(walk > EarlyBirdDinerBehavior.LANE_WIDTH, "%f" % walk)
	assert_near(EarlyBirdDinerBehavior.BELL_WINDUP, DinnerBell.BELL_TIME)


func test_a_table_only_rings_from_its_first_living_member() -> void:
	var a := Enemy.new()
	a.setup(_load("early_bird_diner"), null, 0.5)
	var b := Enemy.new()
	b.setup(_load("early_bird_diner"), null, 0.5)
	var table := DinnerBell.new()
	table.members.append(a)
	table.members.append(b)
	assert_eq(table.leader(), a)
	a.take_damage(INF, Vector2.ZERO)
	assert_eq(table.leader(), b, "the next one takes over")
	a.free()
	b.free()


# --- the Shuffleboard Shark ---

func test_the_shark_keeps_his_distance() -> void:
	assert_eq(ShuffleboardSharkBehavior.step(60.0), ShuffleboardSharkBehavior.BACK_OFF)
	assert_eq(ShuffleboardSharkBehavior.step(170.0), ShuffleboardSharkBehavior.HOLD)
	assert_eq(ShuffleboardSharkBehavior.step(ShuffleboardSharkBehavior.TOO_FAR + 1.0), ShuffleboardSharkBehavior.CLOSE_IN)


func test_a_puck_with_nothing_in_its_way_runs_straight() -> void:
	var path := ShuffleboardPuck.bounce_path(Vector2(100, 100), Vector2.RIGHT, 300.0, Callable())
	assert_eq(path.size(), 2)
	assert_true(path[1].is_equal_approx(Vector2(400, 100)))
	assert_eq(ShuffleboardPuck.bounces(path), 0)


func test_a_puck_bounces_once_off_the_first_wall_and_stops_at_the_next() -> void:
	var walls := _walls(300.0, 1000.0)
	var path := ShuffleboardPuck.bounce_path(Vector2(100, 100), Vector2(1, 1).normalized(), 400.0, walls)
	assert_eq(path.size(), 3)
	assert_eq(ShuffleboardPuck.bounces(path), 1)
	assert_true(path[1].x < 300.0 and path[1].x > 290.0, "it turns just short of the wall, %s" % str(path[1]))
	var out := path[0].direction_to(path[1])
	var back := path[1].direction_to(path[2])
	assert_true(back.x < 0.0 and back.y > 0.0, "it comes back off the wall, %s" % str(back))
	assert_near(back.y, out.y, "keeping its way along the wall")
	var legs: Array[Vector2] = [path[1] - path[0], path[2] - path[0]]
	assert_true(CollectionPlate.path_length(legs) <= 400.0 + 0.01, "never further than a puck slides")
	var corner := ShuffleboardPuck.bounce_path(Vector2(250, 900), Vector2(1, 1).normalized(), 2000.0, walls)
	assert_eq(corner.size(), 3, "a second wall stops it, with no second bounce")
	assert_true(corner[2].y < 1000.0 and corner[2].x < 300.0, "still inside the room, %s" % str(corner[2]))


func test_the_puck_lanes_leave_time_to_step_aside() -> void:
	var walk := PlayerStats.BASE_SPEED * (ShuffleboardSharkBehavior.WINDUP - 0.3)
	assert_true(walk > ShuffleboardSharkBehavior.LANE_WIDTH, "%f" % walk)
	assert_true(ShuffleboardPuck.HIT_RANGE <= ShuffleboardSharkBehavior.LANE_WIDTH, "the warned lane covers where it hits")


# --- the Sunburnt Sunbather ---

func test_the_sunbather_lies_asleep_until_he_is_touched_or_hit() -> void:
	assert_true(SunbatherBehavior.new().is_asleep(), "he starts as a deck chair")
	assert_false(SunbatherBehavior.should_wake(200.0, false))
	assert_true(SunbatherBehavior.should_wake(SunbatherBehavior.WAKE_RANGE - 1.0, false), "near enough to touch")
	assert_true(SunbatherBehavior.should_wake(400.0, true), "a hit wakes him from afar")


func test_his_snap_leaves_time_to_step_away() -> void:
	assert_true(SunbatherBehavior.snap_hits(Vector2(100, 100), Vector2(120, 110)))
	assert_false(SunbatherBehavior.snap_hits(Vector2(100, 100), Vector2(100, 100 + SunbatherBehavior.SNAP_RADIUS + 1.0)))
	var walk := PlayerStats.BASE_SPEED * (SunbatherBehavior.SNAP_WINDUP - 0.3)
	assert_true(walk > SunbatherBehavior.SNAP_RADIUS, "%f" % walk)
	assert_true(SunbatherBehavior.WAKE_RANGE > SunbatherBehavior.SNAP_RADIUS, "he wakes before the snap could reach")


func test_the_chair_he_lies_as_is_the_one_the_deck_has() -> void:
	var chair := DeckChair.new()
	assert_true(chair.is_solid())
	assert_true(chair.can_break_by(BreakableBlock.SOURCE_CANE), "a deck chair breaks like a barrel")
	chair.free()
	var look := SunbatherBehavior.ChairLook.new()
	assert_true(look is Node2D)
	look.free()


# --- the returning enemies ---

func test_returning_enemies_keep_their_numbers_and_take_the_floors_colors() -> void:
	for id in ["orderly", "stoker"]:
		var mine := _load("cruise_" + id)
		var theirs := _load(id)
		assert_near(mine.max_hp, theirs.max_hp, id)
		assert_near(mine.speed, theirs.speed, id)
		assert_eq(mine.pension_drop, theirs.pension_drop, id)
		assert_eq(mine.behavior_script, theirs.behavior_script, id)
		assert_eq(mine.display_name, theirs.display_name, id)
		assert_eq(mine.max_per_room, theirs.max_per_room, id)
		assert_eq(mine.group_size, theirs.group_size, id)
		assert_eq(mine.mark, theirs.mark, id)
		assert_true(mine.id != theirs.id and mine.color != theirs.color, id)


# --- the numbers ---

func test_new_enemies_match_the_first_floor_role_they_fill() -> void:
	var pairs := {"early_bird_diner": "seasonal_temp", "shuffleboard_shark": "filing_clerk", "sunburnt_sunbather": "plot_holder"}
	for id: String in pairs:
		var def := _load(id)
		var theirs := _load(pairs[id])
		assert_eq(def.id, id)
		assert_false(def.is_boss, id)
		assert_false(def.display_name.is_empty(), id)
		assert_true(CruiseMarks.draws(def.mark), "%s has a mark of its own" % id)
		assert_eq(def.pension_drop, theirs.pension_drop, id)
		assert_true(absf(def.max_hp - theirs.max_hp) <= 4.0, id)
		assert_true(def.behavior_script.new() is EnemyBehavior, id)
