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


func test_chip_is_at_least_as_hard_as_the_reverend_and_crabtree() -> void:
	var def := _load("chip")
	assert_true(def.is_boss)
	assert_true(absf(def.max_hp * GOLF_HEALTH - 760.0) < 0.5, str(def.max_hp * GOLF_HEALTH))
	assert_eq(def.pension_drop, 8)
	for id in ["reverend", "crabtree"]:
		assert_true(def.max_hp * GOLF_HEALTH >= _load(id).max_hp * FLOOR_THREE_HEALTH, id)
	assert_true(def.speed >= _load("crabtree").speed)
	assert_true(ClubProBehavior.COOLDOWN <= ReverendBehavior.COOLDOWN, "rests no longer than the Reverend")
	assert_true(ClubProBehavior.COOLDOWN <= CrabtreeBehavior.COOLDOWN, "or Crabtree")
	var longest := maxf(maxf(ReverendBehavior.EULOGY_WINDUP, ReverendBehavior.PLATE_WINDUP), maxf(CrabtreeBehavior.STAR_WINDUP, CrabtreeBehavior.THUMB_WINDUP))
	for windup in [ClubProBehavior.CHIP_WINDUP, ClubProBehavior.PUTT_WINDUP]:
		assert_true(windup <= longest, "no slower to wind up than they are, %f" % windup)
	assert_eq(ClubProBehavior.MAX_ENEMIES, ReverendBehavior.MAX_ENEMIES)


# --- Club President Thaddeus Fairweather ---

func _doors(cells: Vector2i) -> Array[Vector2i]:
	return [Vector2i(cells.x / 2, 1), Vector2i(cells.x / 2, cells.y - 2), Vector2i(1, cells.y / 2), Vector2i(cells.x - 2, cells.y / 2)]


func test_the_hole_in_one_costs_three_pills_and_its_warning_shows_whole() -> void:
	assert_eq(ClubPresidentBehavior.HOLE_IN_ONE_DAMAGE, Enemy.HEAVIEST_DAMAGE)
	assert_eq(ClubPresidentBehavior.HOLE_IN_ONE_DAMAGE, 3)
	assert_true(ClubPresidentBehavior.HOLE_IN_ONE_SHOWN_WHOLE)
	assert_near(ClubPresidentBehavior.HOLE_IN_ONE_WINDUP, 1.2)
	for phase_two in [false, true]:
		assert_near(ClubPresidentBehavior.windup_for(ClubPresidentBehavior.Attack.HOLE_IN_ONE, phase_two), 1.2, "the second phase never shortens it")
	var boss := Enemy.new()
	boss.setup(_load("thaddeus_fairweather"), null, 0.25)
	var telegraph := Telegraph.new()
	telegraph.start(ClubPresidentBehavior.HOLE_IN_ONE_WINDUP)
	boss.set_warning(telegraph, ClubPresidentBehavior.WARNING_RADIUS, ClubPresidentBehavior.HOLE_IN_ONE_SHOWN_WHOLE)
	assert_near(boss._warning_share(), 1.0, "whatever his warning stat")
	assert_true(telegraph.shows_warning(boss._warning_share()), "it shows from the first instant")
	var room := Node2D.new()
	room.add_child(boss)
	var ball := GiantBallDrop.drop(boss, Vector2(200, 160), ClubPresidentBehavior.HOLE_IN_ONE_RADIUS, ClubPresidentBehavior.HOLE_IN_ONE_WINDUP, ClubPresidentBehavior.HOLE_IN_ONE_DAMAGE)
	assert_true(ball is GroundStrike)
	assert_eq(ball.damage(), 3)
	assert_true(ball.outer_ring() > ball.radius(), "with a second ring outside the first")
	assert_true(RoomView.is_passing_effect(ball))
	assert_near(ball.fill(), 0.0, "its warning fills over its own whole windup")
	ball.advance(ClubPresidentBehavior.HOLE_IN_ONE_WINDUP * 0.5)
	assert_near(ball.fill(), 0.5)
	room.free()


func test_he_can_step_out_from_under_the_ball_even_wading() -> void:
	var way_out := ClubPresidentBehavior.HOLE_IN_ONE_RADIUS + Player.FEET_BOX_SIZE.x / 2.0
	var react := 0.2
	assert_true(PlayerStats.BASE_SPEED * (ClubPresidentBehavior.HOLE_IN_ONE_WINDUP - react) > way_out)
	assert_true(PlayerStats.BASE_SPEED * SandRule.SPEED_FACTOR * (ClubPresidentBehavior.HOLE_IN_ONE_WINDUP - react) > way_out, "in sand, with no dodge")


func test_he_can_step_out_of_the_carts_lane_in_time() -> void:
	assert_eq(ClubPresidentBehavior.CART_DAMAGE, Enemy.HEAVY_DAMAGE)
	var walk := PlayerStats.BASE_SPEED * (ClubPresidentBehavior.CART_WINDUP - 0.3)
	assert_true(walk > ClubPresidentBehavior.CART_LANE_WIDTH, "%f" % walk)
	var quick := PlayerStats.BASE_SPEED * (ClubPresidentBehavior.windup_for(ClubPresidentBehavior.Attack.CART, true) - 0.3)
	assert_true(quick > ClubPresidentBehavior.CART_LANE_WIDTH / 2.0 + Player.FEET_BOX_SIZE.x, "even in the second phase, %f" % quick)


func test_the_sprinkler_leaves_the_quarter_behind_him_dry() -> void:
	assert_near(rad_to_deg(SprinklerSweep.SWEEP), 270.0)
	assert_near(rad_to_deg(TAU - SprinklerSweep.SWEEP), 90.0, "one quarter is never swept")
	var center := Vector2(300, 180)
	for turn in [1, -1]:
		for step in 12:
			var to_him := TAU * step / 12.0
			var start := SprinklerSweep.start_angle(to_him, turn)
			var toward := center + Vector2.from_angle(to_him) * 80.0
			var behind := center - Vector2.from_angle(to_him) * 80.0
			assert_false(SprinklerSweep.is_safe(center, start, turn, toward), "his side is swept")
			assert_true(SprinklerSweep.is_safe(center, start, turn, behind), "the boss's back is dry")
			assert_true(SprinklerSweep.is_safe(center, start, turn, center + Vector2.from_angle(to_him) * (SprinklerSweep.REACH + 20.0)), "and out of reach")
			var reached := SprinklerSweep.swept_angle_of(center, start, turn, toward)
			assert_near(rad_to_deg(reached), 135.0, "the jet reaches his side halfway round")


func test_a_fast_sweep_never_skips_him_between_frames() -> void:
	var center := Vector2(300, 180)
	var start := SprinklerSweep.start_angle(0.0, 1)
	var feet := center + Vector2(90, 0)
	for step in [0.004, 0.016, 0.1, 0.5]:
		var hits := 0
		var time := 0.0
		while time < SprinklerSweep.SWEEP_TIME:
			if SprinklerSweep.swept_over(center, start, 1, time, time + step, feet):
				hits += 1
			time += step
		assert_true(hits >= 1, "passed over at %f a frame" % step)
	var dry := center - Vector2(90, 0)
	var clock := 0.0
	while clock < SprinklerSweep.SWEEP_TIME:
		assert_false(SprinklerSweep.swept_over(center, start, 1, clock, clock + 0.05, dry), "never over the dry quarter")
		clock += 0.05
	assert_true(is_equal_approx(SprinklerSweep.arm_angle(start, 1, SprinklerSweep.SWEEP_TIME), start + SprinklerSweep.SWEEP))
	assert_true(is_equal_approx(SprinklerSweep.arm_angle(start, -1, SprinklerSweep.SWEEP_TIME + 1.0), start - SprinklerSweep.SWEEP), "and stops at the end")


func test_the_sweep_leaves_time_to_get_out_of_reach() -> void:
	var to_his_side := SprinklerSweep.SWEEP_TIME * (deg_to_rad(135.0) / SprinklerSweep.SWEEP)
	for phase_two in [false, true]:
		var time := ClubPresidentBehavior.windup_for(ClubPresidentBehavior.Attack.SPRINKLER, phase_two) + to_his_side
		assert_true(PlayerStats.BASE_SPEED * time > SprinklerSweep.REACH + SprinklerSweep.ARM_WIDTH / 2.0, "from right beside him, %f s" % time)


func test_there_is_always_somewhere_dry_within_a_walk() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var cells := Vector2i(20, 11)
	var room := _room(cells)
	var time := ClubPresidentBehavior.windup_for(ClubPresidentBehavior.Attack.SPRINKLER, true) + SprinklerSweep.SWEEP_TIME * 0.5
	for i in 200:
		var boss := Vector2(rng.randf_range(room.position.x, room.end.x), rng.randf_range(room.position.y, room.end.y))
		var feet := Vector2(rng.randf_range(room.position.x, room.end.x), rng.randf_range(room.position.y, room.end.y))
		var turn := 1 if i % 2 == 0 else -1
		var start := SprinklerSweep.start_angle(boss.direction_to(feet).angle(), turn)
		var nearest := INF
		for y in range(1, cells.y - 1):
			for x in range(1, cells.x - 1):
				var spot := RoomBackdrop.cell_center(Vector2i(x, y))
				if SprinklerSweep.is_safe(boss, start, turn, spot):
					nearest = minf(nearest, spot.distance_to(feet))
		# A cell's middle can lie up to a cell further than the dry ground itself begins.
		assert_true(nearest <= PlayerStats.BASE_SPEED * time + RoomBackdrop.TILE, "seed %d: the nearest dry cell is %f away" % [i, nearest])


func test_bunker_patches_lie_near_him_apart_and_clear_of_walls_doors_and_props() -> void:
	var cells := Vector2i(20, 11)
	var is_open := func(spot: Vector2) -> bool:
		var cell := WalkGrid.cell_of(spot)
		return not (cell.x >= 6 and cell.x <= 7 and cell.y >= 3 and cell.y <= 6)
	for seed_value in 200:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var target := Vector2i(rng.randi_range(1, cells.x - 2), rng.randi_range(1, cells.y - 2))
		var centers := ClubPresidentBehavior.bunker_centers(target, ClubPresidentBehavior.BUNKERS, rng, cells, is_open)
		var seen := {}
		for center in centers:
			assert_true(maxi(absi(center.x - target.x), absi(center.y - target.y)) <= ClubPresidentBehavior.BUNKER_REACH, "seed %d: near him" % seed_value)
			for cell in ClubPresidentBehavior.bunker_patch(center, cells, is_open):
				assert_false(seen.has(cell), "seed %d: patches never overlap" % seed_value)
				seen[cell] = true
				assert_true(cell.x >= 1 and cell.y >= 1 and cell.x <= cells.x - 2 and cell.y <= cells.y - 2, "seed %d: no sand in a wall" % seed_value)
				assert_true(is_open.call(RoomBackdrop.cell_center(cell)), "seed %d: no sand under a prop" % seed_value)
				for door in _doors(cells):
					assert_true(maxi(absi(cell.x - door.x), absi(cell.y - door.y)) > SandRule.DOOR_CLEARANCE, "seed %d: sand at %s too near a door" % [seed_value, str(cell)])


func test_in_an_open_room_three_whole_patches_come_and_the_first_is_under_him() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 6
	var centers := ClubPresidentBehavior.bunker_centers(Vector2i(6, 5), 3, rng, Vector2i(20, 11))
	assert_eq(centers.size(), 3)
	assert_eq(centers[0], Vector2i(6, 5), "the first patch is right under him")
	assert_eq(ClubPresidentBehavior.bunker_patch(Vector2i(6, 5), Vector2i(20, 11)).size(), 9)
	assert_eq(ClubPresidentBehavior.bunker_patch(Vector2i(1, 9), Vector2i(20, 11)).size(), 4, "a patch in a corner keeps off the walls")
	assert_true(ClubPresidentBehavior.bunker_patch(Vector2i(10, 2), Vector2i(20, 11)).is_empty(), "and none lies by a door")


func test_never_more_than_three_caddies_and_only_in_the_second_phase() -> void:
	for alive in 8:
		var calls := ClubPresidentBehavior.caddies_to_call(alive)
		assert_true(calls >= 0, "%d alive" % alive)
		assert_true(alive + calls <= maxi(ClubPresidentBehavior.MAX_CADDIES, alive), "%d alive, %d called" % [alive, calls])
	assert_eq(ClubPresidentBehavior.caddies_to_call(0), 3)
	assert_eq(ClubPresidentBehavior.MAX_CADDIES, 3)
	assert_false(ClubPresidentBehavior.calls_caddies(false))
	assert_true(ClubPresidentBehavior.calls_caddies(true))
	assert_true(ClubPresidentBehavior.is_phase_two(900.0, 1950.0))
	assert_false(ClubPresidentBehavior.is_phase_two(1000.0, 1950.0))
	var def := _load("thaddeus_fairweather")
	assert_eq(def.summon.id, "caddie")
	var caddie := Enemy.new()
	caddie.setup(def.summon, null, 0.5)
	caddie.is_summon = true
	caddie.apply_floor(GOLF_HEALTH, 2.5)
	assert_eq(caddie.coin_value(), 0, "his caddies pay nothing")
	caddie.free()


func test_phase_two_chains_the_cart_into_a_bunker_spread() -> void:
	var cart := ClubPresidentBehavior.Attack.CART
	var bunker := ClubPresidentBehavior.Attack.BUNKER
	assert_eq(ClubPresidentBehavior.followup(cart, true), bunker)
	assert_eq(ClubPresidentBehavior.followup(cart, false), ClubPresidentBehavior.Attack.NONE)
	for attack in [ClubPresidentBehavior.Attack.HOLE_IN_ONE, ClubPresidentBehavior.Attack.SPRINKLER, bunker]:
		assert_eq(ClubPresidentBehavior.followup(attack, true), ClubPresidentBehavior.Attack.NONE)
	for attack in [cart, ClubPresidentBehavior.Attack.SPRINKLER, bunker]:
		assert_true(ClubPresidentBehavior.windup_for(attack, true) < ClubPresidentBehavior.windup_for(attack, false), "his other windups quicken")
	assert_true(ClubPresidentBehavior.PHASE_TWO_COOLDOWN < ClubPresidentBehavior.BASE_COOLDOWN)


func test_he_never_does_the_same_thing_twice_running_and_uses_all_four() -> void:
	var seen := {}
	for last in [ClubPresidentBehavior.Attack.NONE, ClubPresidentBehavior.Attack.HOLE_IN_ONE, ClubPresidentBehavior.Attack.CART, ClubPresidentBehavior.Attack.SPRINKLER, ClubPresidentBehavior.Attack.BUNKER]:
		for i in 50:
			var attack := ClubPresidentBehavior.choose_attack(last, i / 50.0)
			assert_true(attack != last, "not %d twice" % last)
			seen[attack] = true
	assert_eq(seen.size(), 4)


func test_fairweather_is_clearly_harder_than_mortimer_and_the_projectionist() -> void:
	var def := _load("thaddeus_fairweather")
	assert_true(def.is_boss)
	assert_true(absf(def.max_hp * GOLF_HEALTH - 1950.0) < 0.5, str(def.max_hp * GOLF_HEALTH))
	assert_eq(def.pension_drop, 16)
	for id in ["mortimer_grimsby", "projectionist"]:
		assert_true(def.max_hp * GOLF_HEALTH >= _load(id).max_hp * FLOOR_THREE_HEALTH * 1.1, id)
	assert_true(def.body_size.x >= _load("mortimer_grimsby").body_size.x)
	assert_true(ClubPresidentBehavior.BASE_COOLDOWN < FuneralDirectorBehavior.BASE_COOLDOWN)
	assert_true(ClubPresidentBehavior.BASE_COOLDOWN < ProjectionistBehavior.BASE_COOLDOWN)
	assert_true(ClubPresidentBehavior.PHASE_TWO_COOLDOWN < FuneralDirectorBehavior.PHASE_TWO_COOLDOWN)
	assert_true(ClubPresidentBehavior.PHASE_TWO_COOLDOWN < ProjectionistBehavior.PHASE_TWO_COOLDOWN)
	assert_true(ClubPresidentBehavior.HOLE_IN_ONE_DAMAGE > Enemy.HEAVY_DAMAGE)


func test_every_lingering_attack_of_the_floor_is_cleared_from_a_stored_room() -> void:
	var effects: Array[Node] = [BunkerPatch.new(), PuttRoll.new(), SprinklerSweep.new(), GolfBallLob.new(), GiantBallDrop.new()]
	for effect in effects:
		assert_true(RoomView.is_passing_effect(effect), "%s is cleared" % effect.get_script().get_global_name())
		effect.free()
