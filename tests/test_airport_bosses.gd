extends TestCase

# Departures, Terminal Zero's bosses: Sergeant Wanda, Airport Security, and Augustine, Head of
# Departures. The fourth floor's bosses were built at the same time, so they are compared with the
# spec's targets for them (mini bosses about 760, floor bosses about 1950) and with the third floor's
# real numbers. The numbers check again against the real fourth-floor files once those are merged.
const Wanda := preload("res://scripts/actors/behaviors/security_sergeant_behavior.gd")
const Augustine := preload("res://scripts/actors/behaviors/head_of_departures_behavior.gd")
# Terminal Zero scales health by this, and its bosses hold their final health divided by it.
const TERMINAL_HEALTH := 2.6
# The third floors scale by this.
const FLOOR_THREE_HEALTH := 1.8
# The spec's final health for the fourth floor's bosses.
const FLOOR_FOUR_MINI := 760.0
const FLOOR_FOUR_BOSS := 1950.0
const STAMP := HeadOfDeparturesBehavior.Attack.STAMP
const RUNWAY := HeadOfDeparturesBehavior.Attack.RUNWAY
const GATE := HeadOfDeparturesBehavior.Attack.GATE


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


func _rooms() -> Array[Rect2]:
	var rooms: Array[Rect2] = []
	for cells in [Vector2i(14, 9), Vector2i(20, 11), Vector2i(30, 17)]:
		rooms.append(ForemanBehavior.room_rect(cells))
	return rooms


# --- Sergeant Wanda ---

func test_the_xray_sweep_always_leaves_one_safe_spot_in_reach() -> void:
	for seed_value in 200:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var room: Rect2 = _rooms()[seed_value % 3]
		var feet := Vector2(rng.randf_range(room.position.x, room.end.x), rng.randf_range(room.position.y, room.end.y))
		var safe := Wanda.xray_safe_spot(room, rng, feet)
		assert_true(room.has_point(safe), "seed %d: inside the room" % seed_value)
		assert_true(safe.distance_to(feet) <= Wanda.SAFE_NEAR, "seed %d: near him, %f" % [seed_value, safe.distance_to(feet)])
		assert_true(XRaySweep.spared(safe, safe), "standing on it is safe")


func test_the_safe_spot_keeps_to_open_floor_off_her_body() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var room := ForemanBehavior.room_rect(Vector2i(20, 11))
	var her := Vector2(320, 176)
	var is_open := func(spot: Vector2) -> bool: return spot.distance_to(her) > 60.0 and spot.x > 200.0
	for i in 50:
		var safe := Wanda.xray_safe_spot(room, rng, her, is_open)
		assert_true(safe.distance_to(her) > 60.0 and safe.x > 200.0, str(safe))


func test_he_can_reach_the_mat_before_the_beam_moves() -> void:
	var time_to_reach := Wanda.SAFE_NEAR / PlayerStats.BASE_SPEED
	assert_true(time_to_reach + 0.3 <= Wanda.XRAY_WINDUP + Wanda.XRAY_WARNING, "%f" % time_to_reach)


func test_the_beam_starts_at_the_far_edge_and_crosses_the_whole_room() -> void:
	for room in _rooms():
		var near_left := room.position + Vector2(20, 20)
		var ends := XRaySweep.sweep_ends(room, true, near_left)
		assert_near(ends.x, room.end.x, "it starts at the far side")
		assert_near(ends.y, room.position.x, "and ends at his side")
		var near_bottom := room.end - Vector2(20, 20)
		var upright := XRaySweep.sweep_ends(room, false, near_bottom)
		assert_near(upright.x, room.position.y)
		assert_near(upright.y, room.end.y)
		var long := XRaySweep.duration(room, true, 1.0)
		assert_near(long, 1.0 + room.size.x / XRaySweep.SPEED)


func test_the_beam_passes_over_feet_whatever_the_frame_time() -> void:
	assert_true(XRaySweep.crossed(100.0, 140.0, 120.0, XRaySweep.WIDTH), "between two frames")
	assert_true(XRaySweep.crossed(140.0, 100.0, 95.0, XRaySweep.WIDTH), "inside the beam's width, either way")
	assert_false(XRaySweep.crossed(100.0, 140.0, 200.0, XRaySweep.WIDTH), "not reached yet")
	assert_false(XRaySweep.spared(Vector2(100, 100), Vector2.INF), "no mat, nobody spared")
	assert_true(XRaySweep.spared(Vector2(100, 110), Vector2(100, 100)))
	assert_false(XRaySweep.spared(Vector2(100, 100 + XRaySweep.SAFE_REACH + 1.0), Vector2(100, 100)))


func test_a_sweep_waits_out_its_warning_then_moves_at_its_speed() -> void:
	var room := ForemanBehavior.room_rect(Vector2i(20, 11))
	var sweep := XRaySweep.new()
	sweep.setup(null, room, true, room.position + Vector2(10, 10), Vector2.INF, 1.0)
	assert_false(sweep.advance(0.9))
	assert_false(sweep.is_sweeping(), "still warning")
	assert_near(sweep.beam_at(), room.end.x)
	sweep.advance(0.1)
	sweep.advance(0.5)
	assert_near(sweep.beam_at(), room.end.x - XRaySweep.SPEED * 0.5)
	var done := false
	for i in 200:
		done = sweep.advance(0.05)
		if done:
			break
	assert_true(done, "it crosses the room and ends")
	sweep.free()


# In a room wider than the view the beam starts off screen, so its warning is the whole stretch it
# has still to cross: all the room during the warning, then what lies ahead of the beam.
func test_the_sweep_warns_over_all_the_room_it_has_still_to_cross() -> void:
	for room in _rooms():
		for along_x in [true, false]:
			var feet := room.position + Vector2(40, 40)
			var ends := XRaySweep.sweep_ends(room, along_x, feet)
			var whole := XRaySweep.ahead_rect(room, along_x, ends.x, ends.y)
			assert_true(whole.is_equal_approx(room), "the warning covers the room: %s" % str(whole))
			var middle := (ends.x + ends.y) / 2.0
			var half := XRaySweep.ahead_rect(room, along_x, middle, ends.y)
			assert_true(half.has_point(feet), "feet the beam has not reached are inside it")
			var behind := room.end - Vector2(10, 10)
			assert_false(half.has_point(behind), "what it has passed is not")
	assert_true(XRaySweep.AHEAD_ALPHA_FROM > 0.0 and XRaySweep.AHEAD_ALPHA_TO > XRaySweep.AHEAD_ALPHA_FROM, "it shows from the start and clears up")


func test_the_mat_stays_marked_until_the_beam_has_crossed() -> void:
	for room in _rooms():
		for along_x in [true, false]:
			assert_true(Wanda.safe_mark_time(room, along_x) >= XRaySweep.duration(room, along_x, Wanda.XRAY_WARNING))


func test_trays_land_around_him_apart_and_in_the_room() -> void:
	for seed_value in 200:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var room: Rect2 = _rooms()[seed_value % 3]
		var feet := Vector2(rng.randf_range(room.position.x, room.end.x), rng.randf_range(room.position.y, room.end.y))
		var spots := Wanda.tray_spots(feet, rng, room)
		assert_eq(spots.size(), Wanda.TRAYS, "seed %d" % seed_value)
		assert_true(spots[0].is_equal_approx(feet.clamp(room.position, room.end)), "the first right under him")
		for i in spots.size():
			assert_true(room.grow(0.01).has_point(spots[i]), "seed %d spot %d" % [seed_value, i])
			assert_true(spots[i].distance_to(feet) <= Wanda.TRAY_REACH + 0.01)
			for j in range(i + 1, spots.size()):
				assert_true(spots[i].distance_to(spots[j]) >= Wanda.TRAY_RADIUS * 2.0 - 0.01, "apart")


func test_trays_find_four_spots_even_in_a_corner() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for room in _rooms():
		for corner in [room.position, Vector2(room.end.x, room.position.y), room.end, Vector2(room.position.x, room.end.y)]:
			for i in 20:
				assert_eq(Wanda.tray_spots(corner, rng, room).size(), Wanda.TRAYS, "%s in %s" % [str(corner), str(room)])


func test_a_tray_mark_leaves_time_to_walk_out() -> void:
	var walk := PlayerStats.BASE_SPEED * (Wanda.TRAY_WARNING - 0.3)
	assert_true(walk > Wanda.TRAY_RADIUS * 2.0, "%f" % walk)
	var strike := TerminalStrike.new()
	strike.setup(null, Wanda.TRAY_RADIUS, Wanda.TRAY_WARNING, 0.15)
	strike.kind = TerminalStrike.LOOK_TRAY
	assert_false(strike.advance(0.15), "it waits its turn")
	assert_false(strike.advance(Wanda.TRAY_WARNING - 0.1))
	assert_true(strike.advance(0.2), "then lands")
	strike.free()


func test_she_never_calls_over_the_cap() -> void:
	for alive in 9:
		var count := Wanda.summon_count(alive, Wanda.MAX_ENEMIES)
		assert_true(count >= 0 and count <= Wanda.SUMMON_COUNT)
		assert_true(alive + count <= maxi(Wanda.MAX_ENEMIES, alive), "%d alive, %d called" % [alive, count])
	assert_eq(Wanda.MAX_ENEMIES, 5)
	assert_true(BossMoves.can_summon(4, Wanda.MAX_ENEMIES))
	assert_false(BossMoves.can_summon(5, Wanda.MAX_ENEMIES))


func test_she_calls_lost_luggage_that_pays_nothing() -> void:
	var def := _load("sergeant_wanda")
	assert_eq(def.summon.id, "lost_luggage")
	var suitcase := Enemy.new()
	suitcase.setup(def.summon, null, 0.5)
	suitcase.is_summon = true
	suitcase.apply_floor(TERMINAL_HEALTH, 3.0)
	assert_eq(suitcase.coin_value(), 0)
	suitcase.free()


func test_she_alternates_her_two_attacks() -> void:
	assert_eq(Wanda.choose_attack(Wanda.Attack.XRAY, 0.1), Wanda.Attack.TRAYS)
	assert_eq(Wanda.choose_attack(Wanda.Attack.TRAYS, 0.9), Wanda.Attack.XRAY)


func test_wanda_is_at_least_as_hard_as_the_last_depths_mini_bosses() -> void:
	var def := _load("sergeant_wanda")
	assert_true(def.is_boss)
	var final := def.max_hp * TERMINAL_HEALTH
	assert_true(absf(final - 880.0) < 0.5, str(final))
	assert_true(final > FLOOR_FOUR_MINI, "the spec's fourth-floor mini bosses end at about 760")
	for id in ["reverend", "gloria"]:
		assert_true(final >= _load(id).max_hp * FLOOR_THREE_HEALTH * 1.3, id)
	assert_eq(def.pension_drop, 8)
	assert_true(Wanda.COOLDOWN <= ReverendBehavior.COOLDOWN)
	assert_true(Wanda.COOLDOWN <= FountainDivaBehavior.COOLDOWN)
	assert_true(Wanda.SUMMON_COUNT >= ReverendBehavior.SUMMON_COUNT)


# --- Augustine ---

func test_the_boarding_stamp_costs_three_pills_and_its_warning_shows_whole() -> void:
	assert_eq(Augustine.STAMP_DAMAGE, Enemy.HEAVIEST_DAMAGE)
	assert_eq(Enemy.HEAVIEST_DAMAGE, 3)
	assert_true(Augustine.STAMP_SHOWN_WHOLE)
	assert_near(Augustine.STAMP_WINDUP, 1.2)
	for phase_two in [false, true]:
		assert_near(Augustine.windup_for(STAMP, phase_two), 1.2, "the second phase never shortens it")
	var augustine := Enemy.new()
	augustine.setup(_load("augustine"), null, 0.25)
	var telegraph := Telegraph.new()
	telegraph.start(Augustine.STAMP_WINDUP)
	augustine.set_warning(telegraph, Augustine.WARNING_RADIUS, Augustine.STAMP_SHOWN_WHOLE)
	assert_near(augustine._warning_share(), 1.0, "whatever his warning stat")
	assert_true(telegraph.shows_warning(augustine._warning_share()), "it shows from the first instant")
	augustine.free()


func test_the_stamp_mark_fills_over_its_whole_windup_and_lands_for_three() -> void:
	var strike := TerminalStrike.new()
	strike.setup(null, Augustine.STAMP_RADIUS, Augustine.STAMP_WINDUP, 0.0, 0.0, Augustine.STAMP_DAMAGE)
	strike.kind = TerminalStrike.LOOK_STAMP
	assert_eq(strike.damage(), 3)
	assert_true(TerminalStrike.STAMP_RING_GAP > 0.0, "a second ring outside the first")
	assert_false(strike.advance(0.6))
	assert_near(strike.fill(), 0.5, "half filled at half the windup")
	assert_true(strike.advance(0.61))
	strike.free()


# A landing's dust lasts a fifth of a second, too short to read a word, so the stamp's ink stays.
func test_the_departed_ink_stays_long_enough_to_read() -> void:
	assert_true(TerminalStrike.shown_after_landing(TerminalStrike.LOOK_STAMP) >= 0.8)
	assert_near(TerminalStrike.shown_after_landing(TerminalStrike.LOOK_TRAY), GroundStrike.SHOW_TIME, "a tray lands as any strike does")
	assert_true(TerminalStrike.INK_FADE < TerminalStrike.INK_TIME, "it fades only at the end")
	var strike := TerminalStrike.new()
	strike.kind = TerminalStrike.LOOK_STAMP
	assert_false(strike.ink_fades(GroundStrike.SHOW_TIME + 0.1), "still there after the dust")
	assert_true(strike.ink_fades(TerminalStrike.INK_TIME), "then gone")
	strike.free()


func test_he_can_step_out_from_under_the_stamp_in_time() -> void:
	var walk := PlayerStats.BASE_SPEED * (Augustine.STAMP_WINDUP - 0.3)
	assert_true(walk > Augustine.STAMP_RADIUS * 2.0, "%f" % walk)


func test_the_runway_lanes_lie_side_by_side_inside_the_room() -> void:
	for room in _rooms():
		for direction in [Vector2.RIGHT, Vector2.DOWN]:
			for center in [room.get_center(), room.position + Vector2(5, 5), room.end - Vector2(5, 5)]:
				for reverse in [false, true]:
					var lanes := Augustine.runway_lanes(room, direction, center, reverse)
					assert_eq(lanes.size(), Augustine.RUNWAY_LANES)
					for i in lanes.size():
						assert_true(room.grow(0.5).encloses(lanes[i]), "%s in %s" % [str(lanes[i]), str(room)])
						assert_true(lanes[i].size.x >= Player.FEET_BOX_SIZE.x * 2.0 and lanes[i].size.y >= Player.FEET_BOX_SIZE.y * 2.0, "he fits in a lane")
						if i > 0:
							var step := lanes[i].get_center() - lanes[i - 1].get_center()
							assert_near(step.length(), Augustine.RUNWAY_WIDTH, "each lane lights beside the last")


func test_each_runway_lane_lights_after_the_last_has_gone_out() -> void:
	for i in range(1, Augustine.RUNWAY_LANES):
		var gap := Augustine.runway_light_time(i) - Augustine.runway_light_time(i - 1)
		assert_true(gap >= RunwayLane.LIT_TIME, "a lit lane goes out before the next one lights")
		assert_true(Augustine.RUNWAY_WIDTH / PlayerStats.BASE_SPEED <= gap, "he can follow the lights a lane at a time")
	assert_near(Augustine.runway_light_time(0), Augustine.RUNWAY_WARNING)
	var walk := PlayerStats.BASE_SPEED * (Augustine.RUNWAY_WARNING - 0.3)
	assert_true(walk > Augustine.RUNWAY_WIDTH, "time to step out of the first lane: %f" % walk)


func test_a_runway_lane_lights_once_after_its_turn_and_warning() -> void:
	assert_true(RunwayLane.covers(Vector2.ZERO, Vector2.RIGHT, 200.0, 40.0, Vector2(100, 15)))
	assert_false(RunwayLane.covers(Vector2.ZERO, Vector2.RIGHT, 200.0, 40.0, Vector2(100, 25)), "beside the lane")
	assert_false(RunwayLane.covers(Vector2.ZERO, Vector2.RIGHT, 200.0, 40.0, Vector2(-5, 0)), "before it starts")
	var lane := RunwayLane.new()
	lane.setup(null, Vector2.RIGHT, 200.0, 40.0, 0.35, 0.9)
	assert_true(lane.is_waiting())
	assert_false(lane.advance(0.4), "waiting its turn")
	assert_false(lane.advance(0.95), "warning")
	var lit_frames := 0
	for i in 60:
		if lane.advance(1.0 / 60.0):
			lit_frames += 1
	assert_true(lit_frames > 0, "it lights")
	assert_true(lit_frames <= ceili(RunwayLane.LIT_TIME * 60.0) + 1, "for a moment only: %d" % lit_frames)
	assert_true(lane.is_over())
	lane.free()


func test_there_is_no_gate_change_without_barriers() -> void:
	for roll in [0.0, 0.3, 0.6, 0.99]:
		assert_true(Augustine.choose_attack(HeadOfDeparturesBehavior.Attack.NONE, false, roll) != GATE)
	var seen := {}
	for i in 100:
		seen[Augustine.choose_attack(HeadOfDeparturesBehavior.Attack.NONE, true, i / 100.0)] = true
	assert_true(seen.has(GATE), "with barriers it comes")
	for i in 100:
		assert_true(Augustine.choose_attack(STAMP, true, i / 100.0) != STAMP, "never the same attack twice running")


func test_a_gate_change_always_changes_the_room() -> void:
	assert_eq(Augustine.gate_kind(0, 6), QueueBarrier.RISE, "all down, so they rise")
	assert_eq(Augustine.gate_kind(6, 6), QueueBarrier.DROP, "all up, so they drop")
	assert_eq(Augustine.gate_kind(2, 6), QueueBarrier.RISE)
	assert_eq(Augustine.gate_kind(4, 6), QueueBarrier.DROP)


func test_phase_two_chains_one_runway_pattern_straight_into_the_stamp() -> void:
	assert_eq(Augustine.followup(RUNWAY, true, false), STAMP, "the first runway of the second phase")
	assert_eq(Augustine.followup(RUNWAY, true, true), HeadOfDeparturesBehavior.Attack.NONE, "only once")
	assert_eq(Augustine.followup(RUNWAY, false, false), HeadOfDeparturesBehavior.Attack.NONE, "never in the first phase")
	for attack in [STAMP, GATE]:
		assert_eq(Augustine.followup(attack, true, false), HeadOfDeparturesBehavior.Attack.NONE)
	assert_true(Augustine.windup_for(RUNWAY, true) < Augustine.RUNWAY_WINDUP, "his other windups quicken")
	assert_true(Augustine.windup_for(GATE, true) < Augustine.GATE_WINDUP)
	assert_true(Augustine.is_phase_two(1100.0, 2250.0))
	assert_false(Augustine.is_phase_two(1200.0, 2250.0))
	assert_near(Augustine.PHASE_TWO_BARRIER_PACE, 2.0, "the barriers cycle twice as fast")


func test_he_never_calls_over_the_cap_and_his_tour_groups_pay_nothing() -> void:
	for alive in 9:
		var count := Augustine.summon_count(alive, Augustine.MAX_ENEMIES)
		assert_true(count >= 0 and count <= Augustine.SUMMON_COUNT)
		assert_true(alive + count <= maxi(Augustine.MAX_ENEMIES, alive))
	assert_eq(Augustine.MAX_ENEMIES, 5)
	var def := _load("augustine")
	assert_eq(def.summon.id, "tour_group")
	var tourist := Enemy.new()
	tourist.setup(def.summon, null, 0.5)
	tourist.is_summon = true
	tourist.apply_floor(TERMINAL_HEALTH, 3.0)
	assert_eq(tourist.coin_value(), 0)
	tourist.free()


func test_augustine_is_clearly_harder_than_the_last_depths_floor_bosses() -> void:
	var def := _load("augustine")
	assert_true(def.is_boss)
	var final := def.max_hp * TERMINAL_HEALTH
	# 2400 since the balance pass of 2026-11-05: just below the Chairman.
	assert_true(absf(final - 2400.0) < 0.5, str(final))
	assert_true(final >= FLOOR_FOUR_BOSS * 1.1, "the spec's fourth-floor floor bosses end at about 1950")
	for id in ["mortimer_grimsby", "mall_santa"]:
		assert_true(final >= _load(id).max_hp * FLOOR_THREE_HEALTH * 1.3, id)
	assert_eq(def.pension_drop, 16)
	assert_true(Augustine.BASE_COOLDOWN < FuneralDirectorBehavior.BASE_COOLDOWN)
	assert_true(Augustine.BASE_COOLDOWN < MallSantaBehavior.BASE_COOLDOWN)
	assert_true(Augustine.PHASE_TWO_COOLDOWN < FuneralDirectorBehavior.PHASE_TWO_COOLDOWN)
	assert_true(Augustine.PHASE_TWO_COOLDOWN < MallSantaBehavior.PHASE_TWO_COOLDOWN)
	assert_true(Augustine.STAMP_DAMAGE > Enemy.HEAVY_DAMAGE)


# --- what they leave in a room ---

func test_their_effects_are_cleared_from_a_stored_room() -> void:
	var effects: Array[Node] = [XRaySweep.new(), RunwayLane.new(), TerminalStrike.new(), SafeSpotMark.new()]
	for effect in effects:
		assert_true(RoomView.is_passing_effect(effect), "%s is cleared" % effect.get_script().get_global_name())
		effect.free()
	var barrier := QueueBarrier.new()
	assert_false(RoomView.is_passing_effect(barrier), "a barrier belongs to the room and is remembered")
	barrier.free()
