extends TestCase

const FRAME := 1.0 / 60.0


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


# An enemy out of the tree, with a plain point for Grandpa, so a behavior can be stepped by hand.
func _enemy(id: String, at: Vector2, grandpa: Node2D) -> Enemy:
	var enemy := Enemy.new()
	enemy.setup(_load(id), grandpa, 0.5)
	enemy.position = at
	return enemy


func _grandpa(at: Vector2) -> Node2D:
	var grandpa := Node2D.new()
	grandpa.position = at
	return grandpa


# One physics frame of a behavior, clearing what Enemy._physics_process clears before each tick.
func _step(behavior: EnemyBehavior, enemy: Enemy) -> void:
	enemy.desired_velocity = Vector2.ZERO
	enemy._holding_lane = false
	behavior.tick(enemy, FRAME)


# --- the Caddie ---

func test_the_caddie_drives_down_a_warned_lane() -> void:
	assert_near(CaddieBehavior.WINDUP, 0.8)
	var walk := PlayerStats.BASE_SPEED * (CaddieBehavior.WINDUP - 0.3)
	assert_true(walk > CaddieBehavior.LANE_WIDTH, "time to step out of the lane")
	assert_true(CaddieBehavior.CHARGE_SPEED > _load("caddie").speed * 3.0, "the cart is much faster than his walk")


func test_he_charges_only_when_ready_near_and_in_view() -> void:
	assert_true(CaddieBehavior.wants_to_charge(0.0, 100.0, true))
	assert_false(CaddieBehavior.wants_to_charge(0.5, 100.0, true), "still resting")
	assert_false(CaddieBehavior.wants_to_charge(0.0, CaddieBehavior.START_RANGE + 1.0, true), "too far")
	assert_false(CaddieBehavior.wants_to_charge(0.0, 100.0, false), "off screen")


func test_his_lane_stops_short_of_a_wall() -> void:
	assert_near(CaddieBehavior.lane_length(Vector2(100, 100), Vector2.RIGHT, Callable()), CaddieBehavior.CHARGE_LENGTH)
	var is_open := func(spot: Vector2) -> bool: return spot.x < 260.0
	var length := CaddieBehavior.lane_length(Vector2(100, 100), Vector2.RIGHT, is_open)
	assert_true(length < 160.0, "short of the wall at 260, got %f" % length)
	assert_true(length > 100.0, "but most of the way there, got %f" % length)


func test_a_caddie_warns_then_runs_holding_his_lane() -> void:
	var grandpa := _grandpa(Vector2(260, 160))
	var caddie := _enemy("caddie", Vector2(160, 160), grandpa)
	var behavior := CaddieBehavior.new()
	var time := 0.0
	while time < CaddieBehavior.FIRST_CHARGE + 0.05:
		_step(behavior, caddie)
		time += FRAME
	assert_true(caddie.warning_lane_length() > 0.0, "he shows his lane first")
	assert_true(caddie.warning_lane_direction().is_equal_approx(Vector2.RIGHT), "aimed at Grandpa")
	assert_true(caddie.desired_velocity.is_zero_approx(), "and waits while he lines up")
	time = 0.0
	while time < CaddieBehavior.WINDUP + 0.05:
		_step(behavior, caddie)
		time += FRAME
	assert_near(caddie.warning_lane_length(), 0.0, "the warning goes as he sets off")
	_step(behavior, caddie)
	assert_true(caddie.desired_velocity.normalized().is_equal_approx(Vector2.RIGHT), "down the lane he showed")
	assert_near(caddie.desired_velocity.length(), CaddieBehavior.CHARGE_SPEED)
	assert_false(caddie.rides_strips(), "a running cart holds its lane")
	caddie.free()
	grandpa.free()


# --- the Club Golfer ---

func test_the_golfer_keeps_a_driving_distance() -> void:
	assert_eq(ClubGolferBehavior.step(60.0), ClubGolferBehavior.BACK_OFF)
	assert_eq(ClubGolferBehavior.step(160.0), ClubGolferBehavior.HOLD)
	assert_eq(ClubGolferBehavior.step(ClubGolferBehavior.TOO_FAR + 1.0), ClubGolferBehavior.CLOSE_IN)


func test_a_drive_is_three_balls_in_a_thirty_degree_fan() -> void:
	assert_eq(ClubGolferBehavior.BALLS, 3)
	for aim: Vector2 in [Vector2.RIGHT, Vector2.UP, Vector2(-1, 1).normalized()]:
		var lanes := ClubGolferBehavior.drive_lanes(aim)
		assert_eq(lanes.size(), 3)
		assert_true(lanes[1].is_equal_approx(aim), "the middle ball goes at him")
		assert_near(rad_to_deg(absf(lanes[0].angle_to(lanes[2]))), 30.0, "thirty degrees edge to edge")


func test_he_shouts_fore_and_shows_every_lane_before_he_drives() -> void:
	assert_eq(ClubGolferBehavior.SHOUT, "FORE!")
	var walk := PlayerStats.BASE_SPEED * (ClubGolferBehavior.WINDUP - 0.3)
	assert_true(walk > ClubGolferBehavior.LANE_WIDTH, "time to step out of a lane")
	var grandpa := _grandpa(Vector2(330, 160))
	var golfer := _enemy("club_golfer", Vector2(170, 160), grandpa)
	var behavior := ClubGolferBehavior.new()
	var time := 0.0
	while time < ClubGolferBehavior.FIRST_DRIVE + 0.05:
		_step(behavior, golfer)
		time += FRAME
	assert_eq(golfer.warning_lane_count(), ClubGolferBehavior.BALLS, "a lane for every ball")
	golfer.free()
	grandpa.free()


func test_a_driven_ball_is_a_shot_that_a_room_clears() -> void:
	var ball := GolfBallShot.new()
	assert_true(ball is Projectile)
	assert_true(RoomView.is_passing_effect(ball))
	ball.free()


# --- the Gopher ---

func test_the_gopher_burrows_rises_and_sits_up_in_turn() -> void:
	var burrow := GopherBehavior.State.BURROW
	var rising := GopherBehavior.State.RISING
	var up := GopherBehavior.State.UP
	assert_eq(GopherBehavior.next_state(burrow), rising)
	assert_eq(GopherBehavior.next_state(rising), up)
	assert_eq(GopherBehavior.next_state(up), burrow)


func test_its_bite_reaches_only_its_ring() -> void:
	assert_true(GopherBehavior.bite_hits(Vector2(100, 100), Vector2(120, 100)))
	assert_false(GopherBehavior.bite_hits(Vector2(100, 100), Vector2(100 + GopherBehavior.BITE_RADIUS + 1.0, 100)))
	var walk := PlayerStats.BASE_SPEED * (GopherBehavior.RISE_WINDUP - 0.2)
	assert_true(walk > GopherBehavior.BITE_RADIUS + Player.FEET_BOX_SIZE.x, "time to walk out of the ring")
	var wading := walk * SandRule.SPEED_FACTOR
	assert_true(wading > GopherBehavior.BITE_RADIUS, "even wading out of a bunker")


func test_it_rises_right_where_he_stands_under_a_whole_warning() -> void:
	var grandpa := _grandpa(Vector2(300, 200))
	var gopher := _enemy("gopher", Vector2(100, 100), grandpa)
	# Its puff of earth needs a room to land in.
	var room := Node2D.new()
	room.add_child(gopher)
	var behavior := GopherBehavior.new()
	var time := 0.0
	while time < GopherBehavior.FIRST_BURROW + 0.05:
		_step(behavior, gopher)
		time += FRAME
	assert_true(gopher.submerged, "it tunnels while it comes")
	assert_true(gopher.global_position.distance_to(grandpa.global_position) < 1.0, "it comes up under him")
	assert_near(gopher._warning_share(), 1.0, "its ring shows for the whole windup")
	time = 0.0
	while time < GopherBehavior.RISE_WINDUP + 0.05:
		_step(behavior, gopher)
		time += FRAME
	assert_false(gopher.submerged, "then it is up and can be hit")
	room.free()
	grandpa.free()


# --- the returning pair ---

func test_returning_enemies_keep_their_numbers_and_take_the_floors_colors() -> void:
	for id in ["bingo_caller", "soot_ghost"]:
		var mine := _load("golf_" + id)
		var theirs := _load(id)
		assert_near(mine.max_hp, theirs.max_hp, id)
		assert_near(mine.speed, theirs.speed, id)
		assert_eq(mine.pension_drop, theirs.pension_drop, id)
		assert_eq(mine.behavior_script, theirs.behavior_script, id)
		assert_eq(mine.display_name, theirs.display_name, id)
		assert_eq(mine.max_per_room, theirs.max_per_room, id)
		assert_eq(mine.group_size, theirs.group_size, id)
		assert_eq(mine.mark, theirs.mark, id)
		assert_eq(mine.hidden_look, theirs.hidden_look, id)
		assert_eq(mine.body_size, theirs.body_size, id)
		assert_true(mine.id != theirs.id and mine.color != theirs.color, id)


# --- the numbers ---

func test_new_enemies_match_the_first_floor_role_they_fill() -> void:
	var pairs := {"caddie": "debt_ghost", "club_golfer": "filing_clerk", "gopher": "plot_holder"}
	for id: String in pairs:
		var def := _load(id)
		var theirs := _load(pairs[id])
		assert_false(def.is_boss, id)
		assert_false(def.display_name.is_empty(), id)
		assert_false(def.mark.is_empty(), id)
		assert_true(GolfMarks.draws(def.mark), "%s has a mark of its own" % id)
		assert_eq(def.pension_drop, theirs.pension_drop, id)
		assert_true(absf(def.max_hp - theirs.max_hp) <= 4.0, id)
		assert_true(def.behavior_script.new() is EnemyBehavior, id)


func test_each_behavior_says_what_it_is() -> void:
	assert_true(_load("caddie").behavior_script.new() is CaddieBehavior)
	assert_true(_load("club_golfer").behavior_script.new() is ClubGolferBehavior)
	assert_true(_load("gopher").behavior_script.new() is GopherBehavior)
