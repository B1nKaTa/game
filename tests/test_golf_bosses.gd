extends TestCase

# Fairway's End scales health by this, and its bosses hold their final health divided by it.
const GOLF_HEALTH := 2.2
# The third floors scale by this, so their bosses' final health is their .tres health times it.
const FLOOR_THREE_HEALTH := 1.8


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


func _room(cells: Vector2i) -> Rect2:
	return ForemanBehavior.room_rect(cells)


# --- Chip, Club Pro ---

func test_chipped_balls_land_on_him_near_him_and_apart() -> void:
	assert_eq(ClubProBehavior.CHIPS, 4)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for cells in [Vector2i(20, 11), Vector2i(30, 17), Vector2i(14, 9)]:
		var room := _room(cells)
		for i in 100:
			var feet := Vector2(rng.randf_range(room.position.x, room.end.x), rng.randf_range(room.position.y, room.end.y))
			var spots := ClubProBehavior.chip_spots(feet, rng, room)
			assert_eq(spots.size(), ClubProBehavior.CHIPS, "every ball has a spot")
			assert_true(spots[0].distance_to(feet) < 0.01, "one right on him")
			for a in spots.size():
				assert_true(room.grow(0.01).has_point(spots[a]), "inside the room")
				assert_true(spots[a].distance_to(feet) <= ClubProBehavior.CHIP_REACH + 0.01, "near him")
				for b in range(a + 1, spots.size()):
					assert_true(spots[a].distance_to(spots[b]) >= ClubProBehavior.CHIP_RADIUS * 2.0 - 0.01, "apart")


func test_a_chipped_ball_warns_long_enough_to_walk_out_from_under_it() -> void:
	var walk := PlayerStats.BASE_SPEED * (ClubProBehavior.CHIP_WARNING - 0.2)
	assert_true(walk > ClubProBehavior.CHIP_RADIUS + Player.FEET_BOX_SIZE.x, "%f" % walk)
	assert_true(ClubProBehavior.CHIP_WARNING >= ClubProBehavior.CHIP_WINDUP, "each spot shows longer than his windup")


func test_a_chipped_ball_is_a_ground_strike_thrown_from_him() -> void:
	var chip := Enemy.new()
	chip.setup(_load("chip"), null, 0.5)
	var room := Node2D.new()
	room.add_child(chip)
	chip.position = Vector2(100, 120)
	var ball := GolfBallLob.chip(chip, Vector2(200, 120), ClubProBehavior.CHIP_RADIUS, ClubProBehavior.CHIP_WARNING)
	assert_true(ball != null)
	assert_true(ball is GroundStrike, "it lands, hurts and breaks props as any ground strike")
	assert_true(ball.lobbed_from().is_equal_approx(Vector2(100, 120)), "flying in from him")
	assert_near(ball.radius(), ClubProBehavior.CHIP_RADIUS)
	assert_true(RoomView.is_passing_effect(ball), "a stored room clears it")
	chip.open_ground = func(_spot: Vector2) -> bool: return false
	assert_true(GolfBallLob.chip(chip, Vector2(200, 120), 20.0, 0.9) == null, "a wall or a hole takes no ball")
	room.free()


func test_the_putt_breaks_to_one_side_and_rolls_on_past_him() -> void:
	var from := Vector2(100, 200)
	var to := Vector2(300, 200)
	for bend in [ClubProBehavior.PUTT_BEND, -ClubProBehavior.PUTT_BEND]:
		var path := ClubProBehavior.putt_path(from, to, bend)
		assert_eq(path.size(), ClubProBehavior.PUTT_STEPS)
		assert_true(path[-1].is_equal_approx(to + Vector2.RIGHT * ClubProBehavior.PUTT_PAST), "it ends past him")
		var middle := path[path.size() / 2 - 1]
		assert_true(absf(middle.y - from.y) > absf(bend) * 0.5, "it breaks to the side, %s" % str(middle))
		# A positive bend breaks toward the putt's orthogonal side, a negative one away from it.
		assert_true((middle.y - from.y) * signf(bend) * Vector2.RIGHT.orthogonal().y > 0.0, "to the side it was told")
		assert_true(path[0].distance_to(from) < 40.0, "it starts by his feet")


func test_every_point_of_a_putt_stays_in_the_room() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for cells in [Vector2i(20, 11), Vector2i(14, 9)]:
		var room := _room(cells)
		for i in 200:
			var from := Vector2(rng.randf_range(room.position.x, room.end.x), rng.randf_range(room.position.y, room.end.y))
			var to := Vector2(rng.randf_range(room.position.x, room.end.x), rng.randf_range(room.position.y, room.end.y))
			var bend := ClubProBehavior.PUTT_BEND if i % 2 == 0 else -ClubProBehavior.PUTT_BEND
			for point in ClubProBehavior.putt_path(from, to, bend, room):
				assert_true(room.grow(0.01).has_point(point), "%s outside %s" % [str(point), str(room)])


func test_the_putts_curve_is_marked_before_it_rolls_and_leaves_time_to_step_off() -> void:
	var path: Array[Vector2] = [Vector2(150, 100), Vector2(200, 120), Vector2(250, 100)]
	var putt := PuttRoll.new()
	putt.setup(null, Vector2(100, 100), path, ClubProBehavior.PUTT_WINDUP)
	assert_false(putt.is_rolling(), "marked first")
	assert_true(putt.length() > 150.0)
	assert_true(putt.ball_at(0.0).is_zero_approx(), "the ball starts at his feet")
	assert_true(putt.ball_at(putt.length()).is_equal_approx(Vector2(150, 0)), "and ends at the cup")
	assert_true(RoomView.is_passing_effect(putt), "a stored room clears it")
	putt.free()
	var walk := PlayerStats.BASE_SPEED * (ClubProBehavior.PUTT_WINDUP - 0.3)
	assert_true(walk > PuttRoll.HIT_RANGE * 2.0, "time to step off the curve")


func test_he_calls_gophers_who_pay_nothing_and_never_past_five() -> void:
	var def := _load("chip")
	assert_eq(def.summon.id, "gopher")
	for alive in 9:
		var count := ClubProBehavior.summon_count(alive, ClubProBehavior.MAX_ENEMIES)
		assert_true(count >= 0 and count <= ClubProBehavior.SUMMON_COUNT)
		assert_true(alive + count <= maxi(ClubProBehavior.MAX_ENEMIES, alive), "%d alive" % alive)
	assert_eq(ClubProBehavior.MAX_ENEMIES, 5)
	assert_false(BossMoves.can_summon(5, ClubProBehavior.MAX_ENEMIES))
	var gopher := Enemy.new()
	gopher.setup(def.summon, null, 0.5)
	gopher.is_summon = true
	gopher.apply_floor(GOLF_HEALTH, 2.5)
	assert_eq(gopher.coin_value(), 0)
	gopher.free()


func test_he_alternates_his_two_attacks() -> void:
	assert_eq(ClubProBehavior.choose_attack(ClubProBehavior.Attack.CHIP, 0.1), ClubProBehavior.Attack.PUTT)
	assert_eq(ClubProBehavior.choose_attack(ClubProBehavior.Attack.PUTT, 0.9), ClubProBehavior.Attack.CHIP)
	var first := ClubProBehavior.choose_attack(ClubProBehavior.Attack.NONE, 0.2)
	assert_true(first == ClubProBehavior.Attack.CHIP or first == ClubProBehavior.Attack.PUTT)


func test_chip_is_at_least_as_hard_as_the_reverend_and_gloria() -> void:
	var def := _load("chip")
	assert_true(def.is_boss)
	assert_true(absf(def.max_hp * GOLF_HEALTH - 760.0) < 0.5, str(def.max_hp * GOLF_HEALTH))
	assert_eq(def.pension_drop, 8)
	for id in ["reverend", "gloria"]:
		assert_true(def.max_hp * GOLF_HEALTH >= _load(id).max_hp * FLOOR_THREE_HEALTH, id)
	assert_true(def.speed >= _load("gloria").speed)
	assert_true(ClubProBehavior.COOLDOWN <= ReverendBehavior.COOLDOWN, "rests no longer than the Reverend")
	assert_true(ClubProBehavior.COOLDOWN <= FountainDivaBehavior.COOLDOWN, "or Gloria")
	var longest := maxf(maxf(ReverendBehavior.EULOGY_WINDUP, ReverendBehavior.PLATE_WINDUP), maxf(FountainDivaBehavior.COIN_WINDUP, FountainDivaBehavior.SPLASH_WINDUP))
	for windup in [ClubProBehavior.CHIP_WINDUP, ClubProBehavior.PUTT_WINDUP]:
		assert_true(windup <= longest, "no slower to wind up than they are, %f" % windup)
	assert_eq(ClubProBehavior.MAX_ENEMIES, ReverendBehavior.MAX_ENEMIES)
