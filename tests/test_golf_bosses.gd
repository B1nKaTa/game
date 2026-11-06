extends TestCase

# Fairway's End scales health by this, and its bosses hold their final health divided by it.
const GOLF_HEALTH := 2.2
# The third floors scale by this, so their bosses' final health is their .tres health times it.
const FLOOR_THREE_HEALTH := 1.8


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


func _room(cells: Vector2i) -> Rect2:
	return ForemanBehavior.room_rect(cells)


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
	var effects: Array[Node] = [BunkerPatch.new(), SprinklerSweep.new(), GiantBallDrop.new()]
	for effect in effects:
		assert_true(RoomView.is_passing_effect(effect), "%s is cleared" % effect.get_script().get_global_name())
		effect.free()
