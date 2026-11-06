extends TestCase

# The Seance Hotline's regulars: the Phone Psychic, the Crystal Gazer and the Poltergeist on Hold, the
# Ectoplasm that Madame Zara calls up, and the returning pair in the hotline's colours.

const FRAME := 1.0 / 60.0
const Mothball := preload("res://scripts/items/mothball_pockets.gd")


# A stand-in for Grandpa that counts the hits it takes.
class Target extends Node2D:
	var hits := 0

	func take_hit(_amount: int, _source = null) -> bool:
		hits += 1
		return true


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


func _difference(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


func _enemy(id: String, at: Vector2, grandpa: Node2D) -> Enemy:
	var enemy := Enemy.new()
	enemy.setup(_load(id), grandpa, 0.5)
	enemy.position = at
	return enemy


# One physics frame of a behavior, clearing what Enemy._physics_process clears before each tick.
func _step(behavior: EnemyBehavior, enemy: Enemy) -> void:
	enemy.desired_velocity = Vector2.ZERO
	enemy._holding_lane = false
	behavior.tick(enemy, FRAME)


# --- the Phone Psychic ---

func test_the_psychic_keeps_a_middle_distance() -> void:
	assert_eq(PhonePsychicBehavior.step(50.0), PhonePsychicBehavior.BACK_OFF)
	assert_eq(PhonePsychicBehavior.step(120.0), PhonePsychicBehavior.HOLD)
	assert_eq(PhonePsychicBehavior.step(PhonePsychicBehavior.TOO_FAR + 1.0), PhonePsychicBehavior.CLOSE_IN)
	assert_true(PhonePsychicBehavior.TOO_FAR < PhoneCordLash.REACH, "where it holds, the cord reaches him")
	assert_true(PhonePsychicBehavior.TOO_CLOSE > PhoneCordLash.NEAREST)


func test_the_cord_lashes_the_band_through_his_spot_and_nothing_beside_it() -> void:
	var origin := Vector2(100, 100)
	var spot := Vector2(200, 100)
	assert_true(PhoneCordLash.in_band(origin, spot, spot), "his marked spot")
	assert_true(PhoneCordLash.in_band(origin, spot, origin + Vector2.from_angle(deg_to_rad(30.0)) * 100.0), "along the arc")
	assert_true(PhoneCordLash.in_band(origin, spot, origin + Vector2(100.0 + PhoneCordLash.BAND / 2.0 - 1.0, 0)), "at the band's outer edge")
	assert_false(PhoneCordLash.in_band(origin, spot, origin + Vector2(100.0 + PhoneCordLash.BAND / 2.0 + 2.0, 0)), "just past it")
	assert_false(PhoneCordLash.in_band(origin, spot, origin + Vector2(100.0 - PhoneCordLash.BAND / 2.0 - 2.0, 0)), "just short of it")
	assert_false(PhoneCordLash.in_band(origin, spot, origin + Vector2.from_angle(deg_to_rad(50.0)) * 100.0), "past the arc's end")
	assert_false(PhoneCordLash.in_band(origin, spot, origin - Vector2(100, 0)), "behind the psychic")
	assert_false(PhoneCordLash.in_band(origin, spot, origin), "the psychic itself")
	assert_true(PhoneCordLash.reaches(120.0))
	assert_false(PhoneCordLash.reaches(PhoneCordLash.REACH + 1.0), "too far for the cord")
	assert_false(PhoneCordLash.reaches(PhoneCordLash.NEAREST - 1.0), "too near to swing")


func test_the_lash_is_warned_0_7_seconds_with_time_to_step_out() -> void:
	assert_near(PhoneCordLash.WARNING, 0.7)
	assert_true(PhonePsychicBehavior.WINDUP * PlayerStats.BASE_WARNING >= 0.2)
	# A step in or out from the psychic leaves the band, from anywhere in it.
	var walk := PlayerStats.BASE_SPEED * (PhoneCordLash.WARNING - 0.3)
	assert_true(walk > PhoneCordLash.BAND + Player.FEET_BOX_SIZE.y, "%f" % walk)
	var lash := PhoneCordLash.new()
	lash.setup(null, Vector2(100, 0), PhoneCordLash.WARNING)
	lash.position = Vector2(50, 50)
	assert_eq(lash.threat_at(Vector2(150, 50), false), 2, "the marked spot is a coming hit")
	assert_eq(lash.threat_at(Vector2(150, 50 + 100.0 * sin(deg_to_rad(35.0))), false) > 0, true, "and the band along the arc")
	assert_eq(lash.threat_at(Vector2(300, 300), false), 0)
	assert_false(lash.threat_imminent(Vector2(150, 50)))
	assert_false(lash.advance(PhoneCordLash.WARNING - 0.05))
	assert_true(lash.threat_imminent(Vector2(150, 50)))
	assert_true(lash.advance(0.1), "it lashes")
	assert_false(lash.advance(0.1), "once")
	assert_eq(lash.threat_at(Vector2(150, 50), true), 0, "and then it is over")
	lash.free()


func test_the_lash_costs_a_pill_once_and_only_in_its_band() -> void:
	for case: Array in [[Vector2(260, 160), 1], [Vector2(290, 160), 0], [Vector2(230, 160), 0]]:
		var grandpa := Target.new()
		grandpa.position = Vector2(260, 160)
		var psychic := _enemy("phone_psychic", Vector2(160, 160), grandpa)
		var lash := PhoneCordLash.new()
		lash.setup(psychic, Vector2(100, 0), PhoneCordLash.WARNING)
		lash.position = psychic.position
		# He stays on his spot, or steps out of the band while it fills.
		grandpa.position = case[0]
		var time := 0.0
		while time < PhoneCordLash.WARNING + PhoneCordLash.LASH_SHOW * 0.5:
			lash._process(FRAME)
			time += FRAME
		assert_eq(grandpa.hits, case[1], "standing at %s" % str(case[0]))
		lash.free()
		psychic.free()
		grandpa.free()


func test_the_psychic_holds_still_says_it_senses_him_and_winds_up() -> void:
	assert_eq(PhonePsychicBehavior.CALL_TEXT, "I sense you...")
	var grandpa := Target.new()
	grandpa.position = Vector2(270, 160)
	var psychic := _enemy("phone_psychic", Vector2(160, 160), grandpa)
	var behavior := PhonePsychicBehavior.new()
	var time := 0.0
	while time < PhonePsychicBehavior.FIRST_LASH + 0.05:
		_step(behavior, psychic)
		time += FRAME
	assert_true(psychic.is_winding_up(), "it senses him")
	assert_eq(psychic._say_text, PhonePsychicBehavior.CALL_TEXT)
	_step(behavior, psychic)
	assert_true(psychic.desired_velocity.is_zero_approx(), "and holds still while it does")
	psychic.free()
	grandpa.free()


func test_the_lash_shows_its_band_to_a_planner() -> void:
	var lash := PhoneCordLash.new()
	lash.setup(null, Vector2(100, 0), PhoneCordLash.WARNING)
	var shapes := lash.route_circles()
	assert_true(shapes.size() > 5)
	for shape: Array in shapes:
		var circle: Vector3 = shape[0]
		var window: Vector2 = shape[1]
		assert_true(PhoneCordLash.in_band(Vector2.ZERO, Vector2(100, 0), Vector2(circle.x, circle.y), 1.0), "on the arc")
		assert_near(window.x, PhoneCordLash.WARNING)
	# Every point of the band lies in some circle.
	for i in 9:
		var point := Vector2.from_angle(lerpf(-PhoneCordLash.HALF_ARC, PhoneCordLash.HALF_ARC, i / 8.0)) * (100.0 + PhoneCordLash.BAND / 2.0 - 0.5)
		var inside := false
		for shape: Array in shapes:
			var circle: Vector3 = shape[0]
			if Vector2(circle.x, circle.y).distance_to(point) <= circle.z:
				inside = true
		assert_true(inside, "the band's edge at %s" % str(point))
	lash.advance(PhoneCordLash.WARNING + 0.1)
	assert_eq(lash.route_circles().size(), 0, "nothing once it has lashed")
	lash.free()


# --- the Crystal Gazer ---

func test_the_gazer_keeps_her_distance() -> void:
	assert_eq(CrystalGazerBehavior.step(60.0), CrystalGazerBehavior.BACK_OFF)
	assert_eq(CrystalGazerBehavior.step(160.0), CrystalGazerBehavior.HOLD)
	assert_eq(CrystalGazerBehavior.step(CrystalGazerBehavior.TOO_FAR + 1.0), CrystalGazerBehavior.CLOSE_IN)
	assert_true(CrystalGazerBehavior.WINDUP * PlayerStats.BASE_WARNING >= 0.2)


func test_the_ball_turns_no_faster_than_its_turn_rate() -> void:
	var turned := CrystalBall.steer(Vector2.RIGHT, Vector2.LEFT + Vector2(0, 0.01), 0.1)
	assert_near(absf(Vector2.RIGHT.angle_to(turned)), CrystalBall.TURN_RATE * 0.1)
	var slight := Vector2.from_angle(0.01)
	assert_true(CrystalBall.steer(Vector2.RIGHT, slight, 0.1).is_equal_approx(slight), "a small turn is made whole")
	assert_true(CrystalBall.TURN_RATE < PI, "a step aside leaves it curving after him")
	assert_true(CrystalBall.SPEED >= 70.0 and CrystalBall.SPEED <= 80.0, "slow")
	assert_true(CrystalBall.SPEED < PlayerStats.BASE_SPEED * 0.7, "he can walk away from it")


func test_the_ball_homes_on_him_for_3_seconds_then_bursts_in_a_warned_ring() -> void:
	assert_near(CrystalBall.HOME_TIME, 3.0)
	var ball := CrystalBall.new()
	ball.setup(null, null, Vector2.RIGHT)
	var feet := Vector2(0, 2000)
	var time := 0.0
	while time < CrystalBall.HOME_TIME - 0.05:
		ball.advance(FRAME, feet)
		time += FRAME
	assert_true(ball.is_homing(), "still after him at %f s" % time)
	assert_true(ball.way().y > 0.99, "turned toward his feet")
	while time < CrystalBall.HOME_TIME + 0.05:
		ball.advance(FRAME, feet)
		time += FRAME
	assert_eq(ball.state(), CrystalBall.State.WARNING, "then it stops and its ring fills")
	var at := ball.position
	ball.advance(CrystalBall.BURST_WARNING * 0.5, feet)
	assert_true(ball.position.is_equal_approx(at), "the ring stays where it stopped")
	assert_true(ball.fill() > 0.5 and ball.fill() < 0.7, "half filled, %f" % ball.fill())
	var inside := at + Vector2(CrystalBall.BURST_RADIUS - 2.0, 0)
	assert_eq(ball.threat_at(inside, false), 2)
	assert_eq(ball.advance(CrystalBall.BURST_WARNING, inside), "burst", "it bursts over his feet")
	assert_eq(ball.state(), CrystalBall.State.BURST)
	assert_eq(ball.advance(FRAME, inside), "", "once")
	ball.free()


func test_a_burst_misses_feet_outside_its_ring() -> void:
	var ball := CrystalBall.new()
	ball.setup(null, null, Vector2.RIGHT)
	ball.blocked = func(_from: Vector2, _to: Vector2) -> bool: return true
	ball.advance(FRAME, Vector2(500, 0))
	assert_eq(ball.state(), CrystalBall.State.WARNING)
	assert_eq(ball.advance(CrystalBall.BURST_WARNING + 0.01, Vector2(CrystalBall.BURST_RADIUS + 2.0, 0)), "")
	ball.free()


func test_the_ball_bursts_early_where_it_meets_cover() -> void:
	var ball := CrystalBall.new()
	ball.setup(null, null, Vector2.RIGHT)
	ball.blocked = func(_from: Vector2, to: Vector2) -> bool: return to.x > 40.0
	var feet := Vector2(400, 0)
	var time := 0.0
	while time < 1.0:
		ball.advance(FRAME, feet)
		time += FRAME
	assert_eq(ball.state(), CrystalBall.State.WARNING, "it stops at the cover")
	assert_true(ball.position.x <= 40.0 and ball.position.x > 30.0, "against it, at %s" % str(ball.position))
	assert_true(ball.home_left() > 2.0, "long before its 3 s are up")
	assert_true(CrystalBall.burst_hits(ball.position, ball.position + Vector2(0, CrystalBall.BURST_RADIUS - 1.0)))
	ball.free()


func test_the_burst_is_warned_long_enough_to_step_out() -> void:
	assert_true(CrystalBall.BURST_WARNING >= 0.5)
	var walk := PlayerStats.BASE_SPEED * (CrystalBall.BURST_WARNING - 0.2)
	assert_true(walk > CrystalBall.BURST_RADIUS, "%f" % walk)
	var ball := CrystalBall.new()
	ball.setup(null, null, Vector2.RIGHT)
	ball.blocked = func(_from: Vector2, _to: Vector2) -> bool: return true
	ball.advance(FRAME, Vector2(500, 0))
	assert_false(ball.threat_imminent(Vector2.ZERO))
	var circles := ball.route_circles()
	assert_eq(circles.size(), 1)
	assert_true((circles[0][0] as Vector3).z >= CrystalBall.BURST_RADIUS, "a planner sees the whole ring")
	ball.advance(CrystalBall.BURST_WARNING - 0.05, Vector2(500, 0))
	assert_true(ball.threat_imminent(Vector2.ZERO))
	ball.free()


func test_hitting_him_directly_costs_a_pill_with_no_burst_after() -> void:
	var ball := CrystalBall.new()
	ball.setup(null, null, Vector2.RIGHT)
	var outcome := ""
	var time := 0.0
	while outcome.is_empty() and time < 1.0:
		outcome = ball.advance(FRAME, Vector2(40, 0))
		time += FRAME
	assert_eq(outcome, "hit")
	assert_eq(ball.state(), CrystalBall.State.GONE, "it pops")
	assert_eq(ball.advance(CrystalBall.BURST_WARNING + 0.1, Vector2(40, 0)), "", "and never bursts on top")
	ball.free()


func test_the_gazer_winds_up_before_she_lets_her_ball_go() -> void:
	var grandpa := Target.new()
	grandpa.position = Vector2(320, 160)
	var gazer := _enemy("crystal_gazer", Vector2(160, 160), grandpa)
	var room := Node2D.new()
	room.add_child(gazer)
	var behavior := CrystalGazerBehavior.new()
	var time := 0.0
	while time < CrystalGazerBehavior.FIRST_RELEASE + 0.05:
		_step(behavior, gazer)
		time += FRAME
	assert_true(gazer.is_winding_up(), "she winds up first")
	room.free()
	grandpa.free()


# --- the Poltergeist on Hold ---

func test_the_poltergeist_hurls_a_stapler_a_mug_and_a_fax_in_turn() -> void:
	var seen: Array[String] = []
	for i in 6:
		seen.append(PoltergeistBehavior.object_for(i))
	assert_eq(seen, [Projectile.LOOK_STAPLER, Projectile.LOOK_MUG, Projectile.LOOK_FAX, Projectile.LOOK_STAPLER, Projectile.LOOK_MUG, Projectile.LOOK_FAX])
	var looks := {Projectile.LOOK_STAPLER: true, Projectile.LOOK_MUG: true, Projectile.LOOK_FAX: true, Projectile.LOOK_PAPER: true}
	assert_eq(looks.size(), 4, "each object looks like itself, never a plain sheet")


func test_the_poltergeist_is_a_faint_ghost_that_never_hurts_by_touch() -> void:
	var def := _load("poltergeist")
	assert_true(ContactRule.is_ghost(def))
	assert_eq(ContactRule.damage_of(def), 0, "it passes through him")
	assert_false(def.ghost_contact, "and does not opt in to a ghost's touch")
	assert_true(Mothball.is_ghost(def), "the mothballs keep it off as any ghost")
	var ghost := Enemy.new()
	ghost.setup(def, null, 0.5)
	ghost._ready()
	var alpha := ghost.visual().get_alpha()
	assert_true(alpha < 0.8 and alpha >= 0.5, "faint but readable, %f" % alpha)
	ghost.free()


func test_each_throw_is_warned_down_a_lane_with_time_to_step_out() -> void:
	assert_true(PoltergeistBehavior.WINDUP * PlayerStats.BASE_WARNING >= 0.2)
	var walk := PlayerStats.BASE_SPEED * (PoltergeistBehavior.WINDUP - 0.3)
	assert_true(walk > PoltergeistBehavior.LANE_WIDTH, "%f" % walk)
	var grandpa := Target.new()
	grandpa.position = Vector2(320, 160)
	var ghost := _enemy("poltergeist", Vector2(160, 160), grandpa)
	var room := Node2D.new()
	room.add_child(ghost)
	var behavior := PoltergeistBehavior.new()
	var thrown: Array[String] = []
	var time := 0.0
	while thrown.size() < 3 and time < 12.0:
		var was_winding := ghost.is_winding_up()
		_step(behavior, ghost)
		time += FRAME
		if not was_winding and ghost.is_winding_up():
			assert_eq(ghost.warning_lane_count(), 1, "the lane is warned")
			assert_true(ghost.warning_lane_direction().is_equal_approx(Vector2.RIGHT), "at him")
		for child in room.get_children():
			if child is Projectile and not child.has_meta("seen"):
				child.set_meta("seen", true)
				thrown.append(child.look)
				assert_true(RoomView.is_passing_effect(child), "a shot a room clears")
	assert_eq(thrown, [Projectile.LOOK_STAPLER, Projectile.LOOK_MUG, Projectile.LOOK_FAX])
	room.free()
	grandpa.free()


# --- the Ectoplasm ---

func test_the_ectoplasm_is_a_slow_fragile_blob_that_hurts_by_touch() -> void:
	var def := _load("ectoplasm")
	assert_eq(def.art(), "ectoplasm")
	assert_true(SeanceMarks.draws(def.mark))
	assert_true(def.speed < 50.0, "slow")
	assert_true(def.max_hp <= _load("plot_holder").max_hp * 0.4, "fragile")
	assert_eq(ContactRule.damage_of(def), 1, "touching it costs a pill")
	assert_false(def.flips, "drawn from one side only")
	assert_true(def.behavior_script.new() is EctoplasmBehavior)
	var blob := Enemy.new()
	blob.setup(def, null, 0.5)
	blob.is_summon = true
	blob.apply_floor(2.2, 2.5)
	assert_eq(blob.coin_value(), 0, "a summon pays nothing")
	blob.free()


func test_its_trail_slows_him_while_he_stands_on_it() -> void:
	var trail := EctoplasmTrail.new()
	trail.setup(null)
	trail.add_piece(Vector2(100, 100))
	trail.add_piece(Vector2(110, 100))
	assert_true(trail.covers(Vector2(105, 103)))
	assert_false(trail.covers(Vector2(105, 120)), "beside the goo")
	assert_true(trail.advance(0.02, Vector2(105, 100)), "a slow is laid on him")
	assert_false(trail.advance(0.02, Vector2(105, 100)), "not again at once")
	assert_true(trail.advance(EctoplasmTrail.SLOW_EVERY, Vector2(105, 100)), "then again while he stands on it")
	assert_false(trail.advance(0.02, Vector2(300, 300)), "nothing off it")
	assert_eq(trail.threat_at(Vector2(105, 100), false), 1, "better avoided, never a hit")
	assert_false(trail.threat_imminent(Vector2(105, 100)))
	assert_true(EctoplasmTrail.SLOW > 0.0 and EctoplasmTrail.SLOW < 1.0 - SlowEffect.MIN_FACTOR + 0.01)
	trail.free()


func test_its_goo_fades_within_three_seconds_and_keeps_to_a_short_length() -> void:
	assert_true(EctoplasmTrail.LINGER >= 2.0 and EctoplasmTrail.LINGER <= 3.0)
	var trail := EctoplasmTrail.new()
	trail.setup(null)
	trail.add_piece(Vector2(100, 100))
	trail.advance(1.0, Vector2.INF)
	trail.add_piece(Vector2(100, 110))
	trail.advance(EctoplasmTrail.LINGER - 1.1, Vector2.INF)
	assert_true(trail.covers(Vector2(100, 100)), "just short of its time")
	trail.advance(0.2, Vector2.INF)
	assert_false(trail.covers(Vector2(100, 100)), "gone")
	assert_true(trail.covers(Vector2(100, 110)), "the younger blob lingers")
	trail.advance(1.0, Vector2.INF)
	assert_eq(trail.piece_count(), 0)
	for i in EctoplasmTrail.MOST_PIECES + 10:
		trail.add_piece(Vector2(i * 10.0, 0))
	assert_eq(trail.piece_count(), EctoplasmTrail.MOST_PIECES, "a short trail")
	assert_true(EctoplasmTrail.MOST_PIECES * EctoplasmBehavior.LAY_EVERY <= 120.0, "no longer than a few steps")
	trail.free()


func test_its_goo_is_the_hotlines_deep_green_far_from_the_mint() -> void:
	var palette: RoomPalette = (load("res://data/floors/seance_hotline.tres") as FloorDef).room_palette()
	assert_true(EctoplasmTrail.GOO.is_equal_approx(palette.ectoplasm))
	assert_true(EctoplasmTrail.GOO.is_equal_approx(Color("1f6b45")))
	assert_true(_difference(EctoplasmTrail.GOO, SafeSpotMark.COLOR) > 0.45)
	assert_true(EctoplasmTrail.Z < 0, "flat on the floor under the bodies")


# --- the returning pair ---

func test_returning_enemies_keep_their_numbers_and_take_the_floors_colors() -> void:
	var golf_colors := {"bingo_caller": Color(0.35, 0.75, 0.98), "soot_ghost": Color(0.6, 0.5, 0.9)}
	for id: String in golf_colors:
		var mine := _load("seance_" + id)
		var theirs := _load(id)
		assert_near(mine.max_hp, theirs.max_hp, id)
		assert_near(mine.speed, theirs.speed, id)
		assert_eq(mine.pension_drop, theirs.pension_drop, id)
		assert_eq(mine.damage, theirs.damage, id)
		assert_eq(mine.behavior_script, theirs.behavior_script, id)
		assert_eq(mine.display_name, theirs.display_name, id)
		assert_eq(mine.max_per_room, theirs.max_per_room, id)
		assert_eq(mine.group_size, theirs.group_size, id)
		assert_eq(mine.mark, theirs.mark, id)
		assert_eq(mine.hidden_look, theirs.hidden_look, id)
		assert_eq(mine.body_size, theirs.body_size, id)
		assert_eq(mine.art(), id, "%s wears its base's art" % id)
		assert_true(_difference(mine.color, theirs.color) > 0.2, "%s wears the hotline's colours" % id)
		assert_true(_difference(mine.color, golf_colors[id]) > 0.2, "%s left the golf course's behind" % id)
	assert_true(ContactRule.is_ghost(_load("seance_soot_ghost")), "the soot ghost is still a ghost")


# --- all of them ---

func test_new_enemies_match_the_first_floor_role_they_fill() -> void:
	var pairs := {"phone_psychic": "plot_holder", "crystal_gazer": "filing_clerk", "poltergeist": "debt_ghost"}
	for id: String in pairs:
		var def := _load(id)
		var theirs := _load(pairs[id])
		assert_eq(def.id, id)
		assert_false(def.is_boss, id)
		assert_false(def.display_name.is_empty(), id)
		assert_true(SeanceMarks.draws(def.mark), "%s has a mark of its own" % id)
		assert_eq(def.art(), id, "%s wears its own art" % id)
		assert_eq(def.pension_drop, theirs.pension_drop, id)
		assert_true(absf(def.max_hp - theirs.max_hp) <= 4.0, id)
		assert_true(def.behavior_script.new() is EnemyBehavior, id)


func test_the_regulars_match_the_spec() -> void:
	var spec := {
		"phone_psychic": ["Phone Psychic", Vector2(18, 24), 44.0, 58.0, PhonePsychicBehavior],
		"crystal_gazer": ["Crystal Gazer", Vector2(18, 24), 30.0, 66.0, CrystalGazerBehavior],
		"poltergeist": ["Poltergeist on Hold", Vector2(18, 22), 36.0, 64.0, PoltergeistBehavior],
	}
	for id: String in spec:
		var def := _load(id)
		var row: Array = spec[id]
		assert_eq(def.display_name, row[0], id)
		assert_eq(def.body_size, row[1], id)
		assert_near(def.max_hp, row[2], id)
		assert_near(def.speed, row[3], id)
		assert_eq(def.pension_drop, 1, id)
		assert_eq(def.max_per_room, 3, id)
		assert_true(is_instance_of(def.behavior_script.new(), row[4]), id)
	assert_false(_load("poltergeist").ignores_walls, "it drifts round cover, as the soot ghosts do")


func test_the_hotlines_new_enemies_can_be_told_apart() -> void:
	var ids := ["phone_psychic", "crystal_gazer", "poltergeist", "ectoplasm", "seance_bingo_caller", "seance_soot_ghost"]
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a := _load(ids[i])
			var b := _load(ids[j])
			var gap := _difference(SpriteVisual.readable(a.color), SpriteVisual.readable(b.color))
			assert_true(gap >= 0.25 or (a.body_size - b.body_size).length() >= 12.0, "%s and %s" % [ids[i], ids[j]])


func test_every_hazard_tells_a_simulated_player_what_it_threatens() -> void:
	var nodes: Array[Node] = [PhoneCordLash.new(), CrystalBall.new(), EctoplasmTrail.new()]
	for node in nodes:
		assert_true(node.has_method("threat_at") and node.has_method("threat_imminent"), node.get_script().get_global_name())
		node.free()
	var timed: Array[Node] = [PhoneCordLash.new(), CrystalBall.new()]
	for node in timed:
		assert_true(node.has_method("route_circles"), "%s shows a planner its shapes" % node.get_script().get_global_name())
		node.free()


func test_their_effects_are_cleared_from_a_stored_room() -> void:
	var effects: Array[Node] = [PhoneCordLash.new(), CrystalBall.new(), EctoplasmTrail.new()]
	for effect in effects:
		assert_true(SeanceProps.is_passing_effect(effect), "the hotline knows %s lingers" % effect.get_script().get_global_name())
		assert_true(RoomView.is_passing_effect(effect), "%s is cleared" % effect.get_script().get_global_name())
		effect.free()
