extends TestCase

# The Flashback Cinema's bosses: Cornelius Crabtree, Film Critic, and the Projectionist.
const Critic := preload("res://scripts/actors/behaviors/crabtree_behavior.gd")
# The Cinema scales health by this, and its bosses hold their final health divided by it.
const CINEMA_HEALTH := 1.8
# The second floors scale by this, so their bosses' final health is their .tres health times it.
const FLOOR_TWO_HEALTH := 1.4


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


# --- Cornelius Crabtree: the star rating ---

func test_a_rating_throws_that_many_stars_low_narrow_and_fast_high_wide_and_slow() -> void:
	for rating in range(1, 6):
		var lanes := Critic.star_lanes(Vector2.RIGHT, rating)
		assert_eq(lanes.size(), rating, "%d stars for a %d-star rating" % [rating, rating])
		var spread := rad_to_deg(absf(lanes[0].angle_to(lanes[lanes.size() - 1])))
		assert_near(spread, Critic.star_spread(rating), "fan %d" % rating)
	assert_true(Critic.star_lanes(Vector2.RIGHT, 1)[0].is_equal_approx(Vector2.RIGHT), "one star flies straight at him")
	for rating in range(1, 5):
		assert_true(Critic.star_spread(rating + 1) > Critic.star_spread(rating), "a higher rating fans wider")
		assert_true(Critic.star_speed(rating + 1) < Critic.star_speed(rating), "but its stars fly slower")
	assert_near(Critic.star_spread(1), 0.0)
	assert_true(Critic.star_spread(5) >= 60.0, "five stars fan wide")
	assert_true(Critic.star_speed(5) >= 120.0, "and still fly")


func test_he_never_gives_the_same_rating_twice_running() -> void:
	var seen := {}
	for last in range(0, 6):
		for i in 50:
			var rating := Critic.next_rating(last, i / 50.0)
			assert_true(rating >= 1 and rating <= 5)
			assert_true(rating != last, "after %d" % last)
			seen[rating] = true
	assert_eq(seen.size(), 5, "every rating comes up")


func test_every_star_lane_shows_on_him_as_he_winds_up() -> void:
	var crabtree := Enemy.new()
	crabtree.setup(_load("crabtree"), null, 0.5)
	var telegraph := Telegraph.new()
	telegraph.start(Critic.STAR_WINDUP)
	crabtree.set_warning(telegraph, Critic.WARNING_RADIUS)
	for way in Critic.star_lanes(Vector2.RIGHT, 4):
		crabtree.add_warning_lane(way, Critic.STAR_LANE, Critic.STAR_LANE_WIDTH, false)
	assert_eq(crabtree.warning_lane_count(), 4)
	crabtree.clear_warning()
	assert_eq(crabtree.warning_lane_count(), 0, "and goes with the warning")
	crabtree.free()


func test_the_stars_leave_time_to_step_out_of_their_lanes() -> void:
	# The fastest star is the one-star rating's: he still has the windup's shown part and its flight.
	var walk := PlayerStats.BASE_SPEED * (Critic.STAR_WINDUP * PlayerStats.BASE_WARNING + 60.0 / Critic.star_speed(1) - 0.1)
	assert_true(walk > Critic.STAR_LANE_WIDTH, "%f" % walk)
	assert_true(Critic.STAR_WINDUP * PlayerStats.BASE_WARNING >= 0.2)


# --- the thumbs down ---

func test_the_thumbs_down_stamps_a_warned_ring_out_over_the_floor() -> void:
	assert_true(Critic.THUMB_WINDUP * PlayerStats.BASE_WARNING >= 0.2)
	assert_true(Critic.RING_TO > Critic.RING_FROM)
	assert_true(Shockwave.band_hits(Vector2.ZERO, 80.0, Critic.RING_WIDTH, Vector2(80, 0)))
	assert_false(Shockwave.band_hits(Vector2.ZERO, 80.0, Critic.RING_WIDTH, Vector2(40, 0)), "inside its edge is safe")
	# From where the ring starts, a step out of reach takes less than the windup.
	var walk := PlayerStats.BASE_SPEED * (Critic.THUMB_WINDUP - 0.3)
	assert_true(walk > Critic.RING_FROM + Critic.RING_WIDTH, "%f" % walk)


func test_he_alternates_his_two_attacks() -> void:
	assert_eq(Critic.choose_attack(Critic.Attack.STARS, 0.1), Critic.Attack.THUMBS)
	assert_eq(Critic.choose_attack(Critic.Attack.THUMBS, 0.9), Critic.Attack.STARS)


# --- the bad review ---

func test_a_bad_review_calls_two_or_three_hecklers_never_over_the_cap() -> void:
	for alive in 9:
		for roll in [0.1, 0.9]:
			var count := Critic.hecklers(alive, Critic.MAX_ENEMIES, roll)
			assert_true(count >= 0 and count <= Critic.MOST_HECKLERS)
			assert_true(alive + count <= maxi(Critic.MAX_ENEMIES, alive), "%d alive, %d called" % [alive, count])
	assert_eq(Critic.hecklers(1, Critic.MAX_ENEMIES, 0.1), 2)
	assert_eq(Critic.hecklers(1, Critic.MAX_ENEMIES, 0.9), 3)
	assert_eq(Critic.hecklers(4, Critic.MAX_ENEMIES, 0.9), 1, "only what the cap leaves")
	assert_eq(Critic.MAX_ENEMIES, 5)
	assert_false(BossMoves.can_summon(Critic.MAX_ENEMIES, Critic.MAX_ENEMIES))


func test_his_hecklers_are_extras_who_pay_nothing() -> void:
	var def := _load("crabtree")
	assert_eq(def.summon.id, "extra")
	var heckler := Enemy.new()
	heckler.setup(def.summon, null, 0.5)
	heckler.is_summon = true
	heckler.apply_floor(CINEMA_HEALTH, 2.0)
	assert_eq(heckler.coin_value(), 0)
	heckler.free()


# --- his numbers ---

func test_crabtree_is_at_least_as_hard_as_barbara_klaus_and_the_reverend() -> void:
	var def := _load("crabtree")
	assert_true(def.is_boss)
	assert_eq(def.display_name, "Cornelius Crabtree, Film Critic")
	assert_eq(def.body_size, Vector2(32, 40))
	assert_eq(def.art(), "crabtree")
	assert_true(absf(def.max_hp * CINEMA_HEALTH - 640.0) < 0.5, str(def.max_hp * CINEMA_HEALTH))
	assert_eq(def.pension_drop, 8)
	for id in ["activities_coordinator", "foreman_klaus"]:
		assert_true(def.max_hp * CINEMA_HEALTH >= _load(id).max_hp * FLOOR_TWO_HEALTH, id)
	assert_true(def.max_hp >= _load("reverend").max_hp - 0.01, "as tough as the Reverend")
	assert_true(Critic.COOLDOWN <= ActivitiesCoordinatorBehavior.COOLDOWN)
	assert_true(Critic.COOLDOWN <= ForemanBehavior.COOLDOWN)
	assert_true(Critic.MOST_HECKLERS >= ForemanBehavior.SUMMON_COUNT)


# --- what they leave in a room ---

func test_their_effects_are_cleared_from_a_stored_room() -> void:
	var effects: Array[Node] = [Shockwave.new(), SummonMark.new(), Projectile.new()]
	for effect in effects:
		assert_true(RoomView.is_passing_effect(effect), "%s is cleared" % effect.get_script().get_global_name())
		effect.free()


# --- the Projectionist: the lens beam, his heaviest attack ---

const Projector := preload("res://scripts/actors/behaviors/projectionist_behavior.gd")
# Matron Mercy, Old Smokey and Mortimer: the floor bosses he must be harder than, or no tougher than.
const BOSS_ROOMS := ["floor_boss_01", "floor_boss_large_01"]


func _cinema_layout(name: String) -> RoomLayout:
	return load("res://data/rooms/flashback_cinema/%s.tres" % name)


func _open_spot(layout: RoomLayout, rng: RandomNumberGenerator, room: Rect2) -> Vector2:
	for i in 400:
		var spot := Vector2(rng.randf_range(room.position.x + 10.0, room.end.x - 10.0), rng.randf_range(room.position.y + 10.0, room.end.y - 10.0))
		var box := Rect2(spot - Player.FEET_BOX_SIZE / 2.0, Player.FEET_BOX_SIZE)
		var clear := true
		for corner in [box.position, box.end, Vector2(box.position.x, box.end.y), Vector2(box.end.x, box.position.y)]:
			if layout.is_solid_at(WalkGrid.cell_of(corner)):
				clear = false
		if clear:
			return spot
	return room.get_center()


func _is_open(layout: RoomLayout) -> Callable:
	return func(spot: Vector2) -> bool: return not layout.is_solid_at(WalkGrid.cell_of(spot))


func test_the_lens_beam_costs_three_pills_and_its_warning_shows_whole() -> void:
	assert_eq(Projector.BEAM_DAMAGE, Enemy.HEAVIEST_DAMAGE)
	assert_eq(Projector.BEAM_DAMAGE, 3)
	assert_true(Projector.BEAM_SHOWN_WHOLE)
	assert_near(Projector.BEAM_WINDUP, 1.2)
	for phase_two in [false, true]:
		assert_near(Projector.windup_for(Projector.Attack.BEAM, phase_two), 1.2, "the second phase never shortens it")
	var boss := Enemy.new()
	boss.setup(_load("projectionist"), null, 0.25)
	var telegraph := Telegraph.new()
	telegraph.start(Projector.BEAM_WINDUP)
	boss.set_warning(telegraph, Projector.WARNING_RADIUS, Projector.BEAM_SHOWN_WHOLE)
	assert_near(boss._warning_share(), 1.0, "whatever his warning stat")
	assert_true(telegraph.shows_warning(boss._warning_share()), "it shows from the first instant")
	boss.free()
	var beam := LensBeam.new()
	beam.setup(null, 0.0, deg_to_rad(LensBeam.ARC_DEG), Projector.BEAM_WINDUP, Projector.BEAM_DAMAGE)
	assert_true(beam.is_warning())
	assert_false(beam.advance(Projector.BEAM_WINDUP - 0.01).size() > 0, "nothing turns in the windup")
	assert_true(absf(beam.fill() - 1.0) < 0.02, "its start line has filled over the whole windup")
	beam.free()


func test_the_beam_covers_its_lane_and_nothing_beside_it() -> void:
	var at := Vector2(200, 200)
	assert_true(LensBeam.covers(at, 0.0, at + Vector2(150, 0)))
	assert_true(LensBeam.covers(at, 0.0, at + Vector2(150, LensBeam.WIDTH / 2.0 - 1.0)))
	assert_false(LensBeam.covers(at, 0.0, at + Vector2(150, LensBeam.WIDTH / 2.0 + 1.0)), "beside it")
	assert_false(LensBeam.covers(at, 0.0, at + Vector2(LensBeam.LENGTH + 5.0, 0)), "beyond its reach")
	assert_false(LensBeam.covers(at, 0.0, at + Vector2(-20, 0)), "behind the lens")


func test_the_sweep_passes_over_feet_whatever_the_frame_time() -> void:
	var at := Vector2(100, 100)
	var feet := at + Vector2.from_angle(deg_to_rad(40.0)) * 200.0
	assert_true(LensBeam.swept_over(at, 0.0, deg_to_rad(80.0), feet), "one long frame across him")
	assert_false(LensBeam.swept_over(at, 0.0, deg_to_rad(20.0), feet), "not reached yet")
	assert_true(LensBeam.swept_over(at, deg_to_rad(80.0), 0.0, feet), "either way round")
	var beam := LensBeam.new()
	beam.setup(null, 0.0, deg_to_rad(LensBeam.ARC_DEG), 0.1)
	var crossed := false
	var turned := 0.0
	for i in 200:
		var step := beam.advance(1.0 / 60.0)
		if step.is_empty():
			continue
		turned = step[1]
		if LensBeam.swept_over(at, step[0], step[1], feet):
			crossed = true
	assert_true(crossed, "the sweep crosses him")
	assert_true(absf(rad_to_deg(turned) - LensBeam.ARC_DEG) < 0.5, "and turns through its whole arc")
	assert_true(beam.is_over())
	assert_true(absf(LensBeam.angle_at(0.0, 1.0, LensBeam.SWEEP_TIME * 2.0) - 1.0) < 0.001, "and stops at its end")
	beam.free()


func test_the_beam_warns_over_all_it_has_still_to_cross() -> void:
	var beam := LensBeam.new()
	beam.setup(null, 0.0, deg_to_rad(90.0), 0.5)
	beam.position = Vector2(100, 100)
	var ahead := Vector2(100, 100) + Vector2.from_angle(deg_to_rad(60.0)) * 150.0
	var behind := Vector2(100, 100) + Vector2.from_angle(deg_to_rad(-40.0)) * 150.0
	assert_eq(beam.threat_at(ahead, false), 2, "the arc it will cross is a coming hit")
	assert_eq(beam.threat_at(behind, false), 0, "outside the arc is clear")
	for i in 60:
		beam.advance(1.0 / 30.0)
	assert_eq(beam.threat_at(Vector2(100, 100) + Vector2.from_angle(deg_to_rad(5.0)) * 150.0, false), 0, "where it has passed is clear again")
	beam.free()


func test_the_beam_sampled_for_a_plan_covers_the_beam_at_every_moment() -> void:
	var origin := Vector2(400, 300)
	var start := 0.3
	var turn := deg_to_rad(LensBeam.ARC_DEG)
	var shapes := LensBeam.plan_circles(origin, start, turn, 0.5)
	assert_true(shapes.size() > 100 and shapes.size() < 1500, "%d circles" % shapes.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 300:
		var t := rng.randf_range(0.0, LensBeam.SWEEP_TIME)
		var angle := LensBeam.angle_at(start, turn, t)
		var point := origin + Vector2.from_angle(angle) * rng.randf_range(0.0, LensBeam.LENGTH) + Vector2.from_angle(angle).orthogonal() * rng.randf_range(-LensBeam.WIDTH / 2.0, LensBeam.WIDTH / 2.0)
		var found := false
		for shape: Array in shapes:
			var circle: Vector3 = shape[0]
			var window: Vector2 = shape[1]
			if t + 0.5 >= window.x - 0.001 and t + 0.5 <= window.y + 0.001 and point.distance_to(Vector2(circle.x, circle.y)) <= circle.z:
				found = true
				break
		assert_true(found, "t %f at %s" % [t, str(point)])


# Over 200 beams in both of his rooms, with him and Grandpa anywhere, half of them over a pie lane or
# the burn already under way: whenever Grandpa still has a way out of what is under way, a beam is found
# that leaves him one and a mark that nothing ever covers.
func test_every_lens_beam_leaves_a_way_out_and_a_marked_spot() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var planned := 0
	var on_him := 0
	var lost := 0
	var slowest := 0
	for seed_value in 200:
		var layout := _cinema_layout(BOSS_ROOMS[seed_value % 2])
		var room := ForemanBehavior.room_rect(layout.size_in_cells())
		var is_open := _is_open(layout)
		var feet := _open_spot(layout, rng, room)
		var boss_at := _open_spot(layout, rng, room)
		if boss_at.distance_to(feet) < 60.0:
			boss_at = feet + (Vector2(90, 0) if feet.x < room.get_center().x else Vector2(-90, 0))
		var body := Rect2(boss_at - Vector2(22, 26), Vector2(44, 52))
		var base := {"rects": [], "circles": []}
		if seed_value % 4 == 1:
			var line := Projector.lane_line(room, feet, true, rng.randi_range(-2, 2))
			base["rects"] = ReelLane.plan_rects(Vector2(room.position.x, line.y), Vector2.RIGHT, room.size.x, ReelLane.WIDTH, rng.randf_range(0.0, 0.9), ReelLane.PIE_SPEED)
		elif seed_value % 4 == 3:
			var burn := Projector.burn_center(room)
			base["circles"] = [[Vector3(burn.x, burn.y, rng.randf_range(40.0, BurnRing.cap_for(room.size.y))), Vector2(0.0, 4.0)]]
		if not Projector.route_with(room, base, body, is_open).escape(feet)["safe"]:
			lost += 1
			continue
		var began := Time.get_ticks_usec()
		var plan := Projector.beam_plan(room, boss_at, feet, base, body, is_open, seed_value % 2 == 0)
		slowest = maxi(slowest, Time.get_ticks_usec() - began)
		assert_true(plan["start"] != INF, "seed %d: a beam is found" % seed_value)
		if plan["start"] == INF:
			continue
		planned += 1
		var circles := LensBeam.plan_circles(boss_at, plan["start"], plan["turn"], Projector.BEAM_WINDUP)
		var shapes := Projector._with(base, [], circles)
		var route := Projector.route_with(room, shapes, body, is_open)
		assert_true(route.escape(feet)["safe"], "seed %d: it leaves a way out" % seed_value)
		var mark: Vector2 = plan["mark"]
		assert_true(mark != Vector2.INF, "seed %d: and a mark" % seed_value)
		assert_false(body.grow(SafeSpotMark.RADIUS).has_point(mark), "seed %d: off his body" % seed_value)
		assert_false(route.is_blocked_at(mark), "seed %d: on open floor" % seed_value)
		assert_near(route.danger_end_at(mark), 0.0, "seed %d: the mark is never under the beam" % seed_value)
		# The arc's middle aimed at him: the beam sweeps right over where he stands.
		var aim := (feet - boss_at).angle()
		if absf(angle_difference(aim, plan["start"] + plan["turn"] / 2.0)) < 0.01:
			on_him += 1
	print("lens beam: %d planned, %d over him, %d lost before it, slowest %d us" % [planned, on_him, lost, slowest])
	assert_true(planned + lost == 200)
	assert_true(lost <= 40, "most states are not lost already: %d" % lost)
	assert_true(on_him >= planned * 0.7, "most beams sweep right over him: %d of %d" % [on_him, planned])
	assert_true(slowest < 400000, "a plan takes %d us at worst" % slowest)


# --- the splice ---

func test_splice_lanes_lie_across_the_room_a_pitch_apart() -> void:
	var room := ForemanBehavior.room_rect(Vector2i(30, 17))
	for count in [2, 3]:
		for across_rows in [true, false]:
			for center: Vector2 in [room.get_center(), room.position + Vector2(5, 5), room.end - Vector2(5, 5)]:
				var lanes := Projector.splice_lanes(room, across_rows, center, count)
				assert_eq(lanes.size(), count)
				for lane in lanes:
					assert_true(room.grow(0.01).encloses(lane), "inside the room: %s" % str(lane))
					assert_near(lane.size.y if across_rows else lane.size.x, SpliceLane.WIDTH)
					assert_near(lane.size.x if across_rows else lane.size.y, room.size.x if across_rows else room.size.y, "right across it")
				for k in range(1, count):
					var gap := (lanes[k].get_center() - lanes[k - 1].get_center()).length()
					assert_near(gap, Projector.SPLICE_PITCH)
	assert_eq(Projector.splice_count(true, 0.1), 3, "always three in the second phase")
	assert_eq(Projector.splice_count(false, 0.1), 2)
	assert_eq(Projector.splice_count(false, 0.9), 3)


func test_a_splice_lane_warns_then_snaps_shut_once() -> void:
	var lane := SpliceLane.new()
	var strip := Rect2(32, 100, 400, SpliceLane.WIDTH)
	lane.setup(null, strip, Projector.SPLICE_WARNING)
	assert_eq(lane.threat_at(strip.get_center(), false), 2)
	assert_eq(lane.threat_at(strip.get_center() + Vector2(0, 60), false), 0)
	assert_near(lane.danger_window().x, Projector.SPLICE_WARNING)
	assert_eq(lane.route_rects().size(), 1)
	assert_false(lane.advance(Projector.SPLICE_WARNING - 0.05))
	assert_true(lane.threat_imminent(strip.get_center()))
	assert_true(lane.advance(0.1), "it snaps")
	assert_false(lane.advance(0.1), "once")
	assert_true(lane.has_snapped())
	assert_eq(lane.threat_at(strip.get_center(), true), 0, "snapped, it is over")
	assert_eq(lane.danger_window(), Vector2(-1, -1))
	assert_true(SpliceLane.hits(strip, strip.get_center()))
	assert_false(SpliceLane.hits(strip, strip.position - Vector2(0, 2)))
	lane.free()


func test_a_splice_leaves_time_to_step_out_of_a_lane_in_both_phases() -> void:
	for phase_two in [false, true]:
		var walk := PlayerStats.BASE_SPEED * (Projector.splice_warning(phase_two) - 0.3)
		assert_true(walk > SpliceLane.WIDTH, "%f" % walk)
	assert_true(Projector.splice_warning(true) < Projector.splice_warning(false), "faster in the second phase")
	assert_true(Projector.SPLICE_PITCH - SpliceLane.WIDTH > Player.FEET_BOX_SIZE.x * 2.0, "room to stand between lanes")


# Over 200 splices in both of his rooms, alone, over a beam still sweeping or over pie lanes and the
# burn: whenever Grandpa still has a way out of what is under way, the splice leaves him one, and a mark.
func test_every_splice_leaves_a_way_out_over_what_is_under_way() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	var planned := 0
	var lost := 0
	var slowest := 0
	for seed_value in 200:
		var layout := _cinema_layout(BOSS_ROOMS[seed_value % 2])
		var room := ForemanBehavior.room_rect(layout.size_in_cells())
		var is_open := _is_open(layout)
		var feet := _open_spot(layout, rng, room)
		var boss_at := _open_spot(layout, rng, room)
		if boss_at.distance_to(feet) < 60.0:
			boss_at = feet + (Vector2(90, 0) if feet.x < room.get_center().x else Vector2(-90, 0))
		var body := Rect2(boss_at - Vector2(22, 26), Vector2(44, 52))
		var base := {"rects": [], "circles": []}
		match seed_value % 3:
			1:
				# The tail of a beam, its last half still to sweep, off his own line.
				var aim := (feet - boss_at).angle() + deg_to_rad(rng.randf_range(40.0, 140.0)) * (1.0 if rng.randf() < 0.5 else -1.0)
				base["circles"] = LensBeam.plan_circles(boss_at, aim, deg_to_rad(LensBeam.ARC_DEG / 2.0), 0.0)
				for shape: Array in base["circles"]:
					shape[1] = (shape[1] as Vector2) * 0.5
			2:
				var line := Projector.lane_line(room, feet, false, rng.randi_range(-2, 2))
				base["rects"] = ReelLane.plan_rects(Vector2(line.x, room.position.y), Vector2.DOWN, room.size.y, ReelLane.WIDTH, rng.randf_range(0.0, 0.9), ReelLane.PIE_SPEED)
				var burn := Projector.burn_center(room)
				base["circles"] = [[Vector3(burn.x, burn.y, rng.randf_range(30.0, 120.0)), Vector2(0.0, 4.0)]]
		if not Projector.route_with(room, base, body, is_open).escape(feet)["safe"]:
			lost += 1
			continue
		var phase_two := seed_value % 2 == 1
		var count := Projector.splice_count(phase_two, rng.randf())
		var warning := Projector.splice_warning(phase_two)
		var began := Time.get_ticks_usec()
		var plan := Projector.splice_plan(room, feet, count, warning, rng.randf() < 0.5, base, body, is_open)
		slowest = maxi(slowest, Time.get_ticks_usec() - began)
		var lanes: Array = plan["lanes"]
		assert_false(lanes.is_empty(), "seed %d: a splice is found" % seed_value)
		if lanes.is_empty():
			continue
		planned += 1
		assert_eq(lanes.size(), count)
		var rects: Array = []
		for lane: Rect2 in lanes:
			assert_true(room.grow(0.01).encloses(lane), "seed %d: inside the room" % seed_value)
			rects.append([lane, Vector2(warning, warning + SpliceLane.SNAP_TIME)])
		var route := Projector.route_with(room, Projector._with(base, rects, []), body, is_open)
		assert_true(route.escape(feet)["safe"], "seed %d: it leaves a way out" % seed_value)
		var mark: Vector2 = plan["mark"]
		assert_true(mark != Vector2.INF, "seed %d: and a mark" % seed_value)
		assert_false(body.grow(SafeSpotMark.RADIUS).has_point(mark), "seed %d: off his body" % seed_value)
		for lane: Rect2 in lanes:
			assert_false(lane.has_point(mark), "seed %d: the mark is off every lane" % seed_value)
	print("splice: %d planned, %d lost before it, slowest %d us" % [planned, lost, slowest])
	assert_true(planned + lost == 200)
	assert_true(lost <= 30, "most states are not lost already: %d" % lost)
	assert_true(slowest < 250000, "a plan takes %d us at worst" % slowest)


# --- the reel change ---

func test_reels_never_come_twice_running() -> void:
	var seen := {}
	for last in [-1, ReelChange.Genre.RAIN, ReelChange.Genre.COMEDY, ReelChange.Genre.WESTERN]:
		for i in 30:
			var kind := ReelChange.next_genre(last, i / 30.0)
			assert_true(kind != last, "after %d" % last)
			seen[kind] = true
	assert_eq(seen.size(), 3, "all three genres come up")
	# A long run of reels, each picked after the one before.
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var last := -1
	for i in 200:
		var kind := ReelChange.next_genre(last, rng.randf())
		assert_true(kind != last)
		last = kind
	for kind in [ReelChange.Genre.RAIN, ReelChange.Genre.COMEDY, ReelChange.Genre.WESTERN]:
		assert_false(ReelChange.title(kind).is_empty())


func test_a_reel_runs_about_eight_seconds() -> void:
	assert_near(ReelChange.TIME, 8.0)
	var reel := ReelChange.new()
	reel.setup(null, ReelChange.Genre.COMEDY, Rect2(32, 32, 576, 288))
	assert_true(reel.is_running())
	assert_false(reel.advance(7.9))
	assert_true(reel.advance(0.2), "it ends")
	assert_false(reel.is_running())
	assert_eq(reel.threat_at(Vector2(100, 100), true), 0, "a reel hurts no one by itself")
	reel.free()


func test_he_changes_reels_when_one_is_due_and_never_twice_running() -> void:
	assert_eq(Projector.choose_attack(Projector.Attack.BEAM, true, 0.5), Projector.Attack.REEL)
	assert_true(Projector.choose_attack(Projector.Attack.REEL, true, 0.5) != Projector.Attack.REEL, "never two reel changes running")
	for last in [Projector.Attack.NONE, Projector.Attack.BEAM, Projector.Attack.SPLICE, Projector.Attack.REEL]:
		for roll in [0.0, 0.4, 0.99]:
			var attack := Projector.choose_attack(last, false, roll)
			assert_true(attack != last and attack != Projector.Attack.REEL, "%d then %d" % [last, attack])
	assert_true(Projector.REEL_WINDUP * PlayerStats.BASE_WARNING >= 0.2)
	assert_true(Projector.reel_every(true) < Projector.reel_every(false), "reels change faster in the second phase")


func test_the_rain_reel_wets_the_floor_by_the_wet_floors_rules() -> void:
	var cells := SplashJets.wet_room(Vector2i(20, 11))
	assert_true(cells.size() > 100, "most of the floor")
	for cell in cells:
		assert_true(SplashJets.can_be_wet(cell, Vector2i(20, 11), Callable()), "never a doorway or a wall")
	var splash := WetSplash.new()
	splash.setup(cells, ReelChange.TIME)
	splash._ready()
	assert_true(WetFloor.any_covers(splash.wet_floors(), RoomBackdrop.cell_center(Vector2i(6, 5))), "slippery underfoot")
	splash.free()


func test_pies_and_tumbleweeds_come_down_warned_lanes_he_can_step_out_of() -> void:
	for look in [ReelLane.LOOK_PIE, ReelLane.LOOK_TUMBLEWEED]:
		var walk := PlayerStats.BASE_SPEED * (ReelLane.WARNING - 0.3)
		assert_true(walk > ReelLane.WIDTH, "%s: %f" % [look, walk])
	assert_true(ReelLane.speed_of(ReelLane.LOOK_TUMBLEWEED) < ReelLane.speed_of(ReelLane.LOOK_PIE), "tumbleweeds roll slower than pies fly")
	var lane := ReelLane.new()
	lane.setup(null, Vector2.RIGHT, 500.0, ReelLane.LOOK_PIE)
	lane.position = Vector2(32, 200)
	assert_eq(lane.threat_at(Vector2(300, 205), false), 2, "the lane ahead is a coming hit")
	assert_eq(lane.threat_at(Vector2(300, 260), false), 0, "beside it is clear")
	assert_true(lane.advance(ReelLane.WARNING - 0.05) < 0.0, "still warning")
	lane.advance(0.05 + 100.0 / ReelLane.PIE_SPEED)
	assert_true(absf(lane.travelled() - 100.0) < 2.0, "then it flies at its speed: %f" % lane.travelled())
	assert_eq(lane.threat_at(Vector2(32 + 40, 200), false), 0, "where the pie has passed is clear")
	assert_true(lane.threat_imminent(Vector2(32 + 120, 200)), "just ahead of it is a moment away")
	assert_true(ReelLane.hits(Vector2(32, 200), Vector2.RIGHT, 100.0, ReelLane.WIDTH, Vector2(32 + 108, 205)))
	assert_false(ReelLane.hits(Vector2(32, 200), Vector2.RIGHT, 100.0, ReelLane.WIDTH, Vector2(32 + 140, 205)))
	lane.free()


func test_a_lanes_plan_pieces_cover_the_thing_as_it_passes() -> void:
	var origin := Vector2(32, 200)
	var shapes := ReelLane.plan_rects(origin, Vector2.RIGHT, 500.0, ReelLane.WIDTH, 0.9, ReelLane.PIE_SPEED)
	for k in 50:
		var along := k * 10.0
		var t := 0.9 + along / ReelLane.PIE_SPEED
		var point := origin + Vector2(along, 6.0)
		var found := false
		for shape: Array in shapes:
			var window: Vector2 = shape[1]
			if (shape[0] as Rect2).has_point(point) and t >= window.x - 0.001 and t <= window.y + 0.001:
				found = true
		assert_true(found, "at %f" % along)


func test_every_thrown_lane_leaves_a_way_out() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var thrown := 0
	for seed_value in 200:
		var layout := _cinema_layout(BOSS_ROOMS[seed_value % 2])
		var room := ForemanBehavior.room_rect(layout.size_in_cells())
		var is_open := _is_open(layout)
		var feet := _open_spot(layout, rng, room)
		var look := ReelLane.LOOK_PIE if seed_value % 2 == 0 else ReelLane.LOOK_TUMBLEWEED
		var plan := Projector.lane_plan(room, feet, look, {"rects": [], "circles": []}, rng, Rect2(), is_open)
		if plan.is_empty():
			continue
		thrown += 1
		var rects := ReelLane.plan_rects(plan["origin"], plan["direction"], plan["length"], ReelLane.WIDTH, ReelLane.WARNING, ReelLane.speed_of(look))
		assert_true(Projector.route_with(room, {"rects": rects, "circles": []}, Rect2(), is_open).escape(feet)["safe"], "seed %d" % seed_value)
		if look == ReelLane.LOOK_TUMBLEWEED:
			assert_true(absf((plan["direction"] as Vector2).y) < 0.01, "tumbleweeds roll along rows")
	assert_true(thrown >= 190, "a lane is nearly always thrown: %d" % thrown)


# --- the second phase: the film catches fire ---

func test_the_burn_grows_slowly_from_the_screen_to_a_cap() -> void:
	assert_true(BurnRing.GROW_SPEED <= 10.0, "slowly")
	var cap := BurnRing.cap_for(15 * 32.0)
	assert_true(cap <= 15 * 32.0 * 0.5, "it always leaves most of the room")
	assert_near(BurnRing.radius_after(10.0, cap), BurnRing.GROW_SPEED * 10.0)
	assert_near(BurnRing.radius_after(1000.0, cap), cap)
	var ring := BurnRing.new()
	ring.setup(null, cap)
	ring.position = Vector2(300, 64)
	assert_false(ring.advance(1.0, Vector2(300, 200)), "not reached yet")
	for i in 40:
		ring.advance(1.0, Vector2(900, 900))
	assert_true(ring.radius() > 200.0 or is_equal_approx(ring.radius(), cap))
	assert_true(ring.advance(0.1, Vector2(300, 100)), "inside, it burns")
	assert_false(ring.advance(0.1, Vector2(300, 100)), "not again at once")
	assert_eq(ring.threat_at(Vector2(300, 100), false), 2)
	assert_near(ring.progress(), ring.radius() / cap)
	var circles := ring.route_circles(2.0)
	assert_eq(circles.size(), 1)
	assert_true((circles[0][0] as Vector3).z >= ring.radius())
	ring.free()


func test_phase_two_quickens_reels_and_splices_but_never_the_beam() -> void:
	assert_true(Projector.is_phase_two(800.0, 1650.0))
	assert_false(Projector.is_phase_two(900.0, 1650.0))
	for attack in [Projector.Attack.SPLICE, Projector.Attack.REEL]:
		assert_true(Projector.windup_for(attack, true) < Projector.windup_for(attack, false))
		assert_true(Projector.windup_for(attack, true) * PlayerStats.BASE_WARNING >= 0.2 - 0.001)
	assert_near(Projector.windup_for(Projector.Attack.BEAM, true), Projector.windup_for(Projector.Attack.BEAM, false))
	assert_true(Projector.cooldown_for(true) < Projector.cooldown_for(false))
	for kind in [ReelChange.Genre.COMEDY, ReelChange.Genre.WESTERN]:
		assert_true(Projector.lane_every(kind, true) < Projector.lane_every(kind, false))
	var room := ForemanBehavior.room_rect(Vector2i(30, 17))
	var picture := Rect2(64, 4, 160, 56)
	assert_eq(Projector.burn_center(room, picture), Vector2(144, 64), "the burn starts at the screen's foot")


# --- his numbers ---

func test_the_projectionist_is_clearly_harder_than_matron_and_smokey_and_no_tougher_than_mortimer() -> void:
	var def := _load("projectionist")
	assert_true(def.is_boss)
	assert_eq(def.display_name, "The Projectionist")
	assert_eq(def.body_size, Vector2(44, 52))
	assert_eq(def.art(), "projectionist")
	assert_true(absf(def.max_hp * CINEMA_HEALTH - 1650.0) < 0.5, str(def.max_hp * CINEMA_HEALTH))
	assert_near(def.speed, 80.0)
	assert_eq(def.pension_drop, 16)
	for id in ["matron_mercy", "old_smokey"]:
		assert_true(def.max_hp * CINEMA_HEALTH >= _load(id).max_hp * FLOOR_TWO_HEALTH * 1.1, id)
	assert_true(def.max_hp <= _load("mortimer_grimsby").max_hp, "no more health than Mortimer, whose attacks are easier to read")
	assert_true(Projector.BASE_COOLDOWN <= FuneralDirectorBehavior.BASE_COOLDOWN)
	assert_true(Projector.PHASE_TWO_COOLDOWN <= FuneralDirectorBehavior.PHASE_TWO_COOLDOWN)
	assert_true(Projector.BASE_COOLDOWN < MatronBehavior.BASE_COOLDOWN)
	assert_true(Projector.BASE_COOLDOWN < ChiefStokerBehavior.BASE_COOLDOWN)
	assert_true(Projector.BEAM_DAMAGE > Enemy.HEAVY_DAMAGE)
	assert_eq(def.summon, null, "he calls no one")


func test_the_cinemas_bosses_are_on_its_floor_with_their_posters_and_memento() -> void:
	var floor_def: FloorDef = load("res://data/floors/flashback_cinema.tres")
	assert_eq(floor_def.mini_boss.id, "crabtree")
	assert_eq(floor_def.floor_boss.id, "projectionist")
	for id in ["crabtree", "projectionist"]:
		assert_true(ResourceLoader.exists("res://data/bounties/%s.tres" % id), "%s has a poster" % id)
		assert_false(PendingBosses.BY_OLD.values().has(id), "%s needs no stand-in" % id)
	var found := false
	for entry: Dictionary in Mementos.ALL:
		if entry["boss"] == "projectionist":
			found = true
			assert_eq(entry["path"], "flashback_cinema")
	assert_true(found, "his memento")


func test_the_projectionists_effects_are_cleared_from_a_stored_room() -> void:
	var effects: Array[Node] = [LensBeam.new(), SpliceLane.new(), ReelLane.new(), ReelChange.new(), BurnRing.new(), SafeSpotMark.new(), WetSplash.new()]
	for effect in effects:
		assert_true(RoomView.is_passing_effect(effect), "%s is cleared" % effect.get_script().get_global_name())
		effect.free()


func test_every_hazard_he_leaves_answers_a_simulated_players_questions() -> void:
	var nodes: Array[Node] = [LensBeam.new(), SpliceLane.new(), ReelLane.new(), ReelChange.new(), BurnRing.new(), PopcornTub.new(), FilmTrail.new()]
	for node in nodes:
		assert_true(node.has_method("threat_at") and node.has_method("threat_imminent"), node.get_script().get_global_name())
		node.free()
