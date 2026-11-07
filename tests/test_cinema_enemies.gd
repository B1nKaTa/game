extends TestCase

# The Flashback Cinema's regulars: the Usher, the Popcorn Vendor and the Runaway Film Reel, the summon
# that steps out of the screen, and the returning pair in the Cinema's colours.


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


func _difference(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


# --- the Usher ---

func test_his_torch_beam_covers_what_lies_ahead_inside_its_angle() -> void:
	var at := Vector2(100, 100)
	var reach := UsherBehavior.TORCH_LENGTH
	assert_true(UsherBehavior.in_beam(at, Vector2.RIGHT, reach, UsherBehavior.TORCH_HALF_ANGLE, at + Vector2(100, 0)), "straight ahead")
	assert_true(UsherBehavior.in_beam(at, Vector2.RIGHT, reach, UsherBehavior.TORCH_HALF_ANGLE, at + Vector2.from_angle(deg_to_rad(20.0)) * 80.0), "inside the angle")
	assert_false(UsherBehavior.in_beam(at, Vector2.RIGHT, reach, UsherBehavior.TORCH_HALF_ANGLE, at + Vector2.from_angle(deg_to_rad(30.0)) * 80.0), "outside the angle")
	assert_false(UsherBehavior.in_beam(at, Vector2.RIGHT, reach, UsherBehavior.TORCH_HALF_ANGLE, at + Vector2(reach + 5.0, 0)), "beyond the beam")
	assert_false(UsherBehavior.in_beam(at, Vector2.RIGHT, reach, UsherBehavior.TORCH_HALF_ANGLE, at + Vector2(-60, 0)), "behind him")


func test_he_spots_grandpa_after_0_6_seconds_in_the_beam() -> void:
	assert_near(UsherBehavior.SPOT_TIME, 0.6)
	var seen := 0.0
	var frames := 0
	while not UsherBehavior.is_spotted(seen):
		seen = UsherBehavior.notice(seen, true, 1.0 / 60.0)
		frames += 1
		assert_true(frames < 100, "he spots him in the end")
		if frames >= 100:
			return
	assert_true(absf(frames / 60.0 - 0.6) <= 1.5 / 60.0, "spotted after %d frames" % frames)
	# Stepping out ebbs the notice as fast as it built.
	seen = 0.5
	for i in 30:
		seen = UsherBehavior.notice(seen, false, 1.0 / 60.0)
	assert_true(seen < 0.01, "%f" % seen)
	seen = UsherBehavior.notice(0.55, false, 0.1)
	assert_false(UsherBehavior.is_spotted(UsherBehavior.notice(seen, true, 0.1)), "a dip out of the beam sets it back")


func test_his_charge_down_the_beam_line_leaves_time_to_step_out() -> void:
	var walk := PlayerStats.BASE_SPEED * (UsherBehavior.WINDUP - 0.3)
	assert_true(walk > UsherBehavior.LANE_WIDTH, "%f" % walk)
	assert_true(UsherBehavior.WINDUP * PlayerStats.BASE_WARNING >= 0.2)
	var usher := Enemy.new()
	usher.setup(_load("usher"), null, 0.5)
	var telegraph := Telegraph.new()
	telegraph.start(UsherBehavior.WINDUP)
	usher.set_warning(telegraph, UsherBehavior.WARNING_RADIUS)
	usher.set_warning_lane(Vector2.RIGHT, UsherBehavior.CHARGE_LENGTH, UsherBehavior.LANE_WIDTH, false)
	assert_eq(usher.warning_lane_count(), 1, "the charge's lane is warned")
	assert_near(usher.warning_lane_length(), UsherBehavior.CHARGE_LENGTH)
	usher.free()


func test_his_torch_is_on_him_from_his_first_frame() -> void:
	var usher := Enemy.new()
	usher.setup(_load("usher"), null, 0.5)
	usher._ready()
	var torches := 0
	for child in usher.get_children():
		if child is UsherTorch:
			torches += 1
			assert_true(child.z_index < 0 and not child.z_as_relative, "flat on the floor under the bodies")
	assert_eq(torches, 1)
	usher.free()


func test_his_torch_stops_at_the_rooms_walls() -> void:
	var room := Rect2(32, 32, 320, 192)
	assert_near(UsherTorch.reach_in(Vector2(100, 100), Vector2.RIGHT, room, 150.0), 150.0, "whole inside the room")
	assert_near(UsherTorch.reach_in(Vector2(300, 100), Vector2.RIGHT, room, 150.0), 52.0, "cut at the east wall")
	assert_near(UsherTorch.reach_in(Vector2(100, 200), Vector2.DOWN, room, 150.0), 24.0, "cut at the south wall")
	assert_near(UsherTorch.reach_in(Vector2(100, 100), Vector2.LEFT, Rect2(), 150.0), 150.0, "no room, no cut")


# --- the Popcorn Vendor ---

func test_the_vendor_keeps_her_distance() -> void:
	assert_eq(PopcornVendorBehavior.step(60.0), PopcornVendorBehavior.BACK_OFF)
	assert_eq(PopcornVendorBehavior.step(150.0), PopcornVendorBehavior.HOLD)
	assert_eq(PopcornVendorBehavior.step(PopcornVendorBehavior.TOO_FAR + 1.0), PopcornVendorBehavior.CLOSE_IN)


func test_a_tub_lands_near_him_and_bursts_into_a_ring_of_six_kernels() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 100:
		var spot := PopcornVendorBehavior.tub_spot(Vector2(200, 200), rng)
		assert_true(spot.distance_to(Vector2(200, 200)) <= PopcornVendorBehavior.SPREAD + 0.01)
	assert_eq(PopcornTub.KERNELS, 6)
	var ways := PopcornTub.kernel_directions(0.4)
	assert_eq(ways.size(), 6)
	for k in 6:
		assert_near(rad_to_deg(absf(ways[k].angle_to(ways[(k + 1) % 6]))), 60.0, "a ring of six, evenly spread")


func test_the_tub_mark_leaves_time_to_walk_out_and_lands_once() -> void:
	var walk := PlayerStats.BASE_SPEED * (PopcornTub.WARNING - 0.2)
	assert_true(walk > PopcornTub.RADIUS * 2.0, "%f" % walk)
	assert_true(PopcornVendorBehavior.WINDUP * PlayerStats.BASE_WARNING >= 0.2)
	var tub := PopcornTub.new()
	tub.setup(null, PopcornTub.WARNING, 0.0)
	tub.position = Vector2(100, 100)
	assert_eq(tub.threat_at(Vector2(100, 100), false), 2, "under it is a coming hit")
	assert_eq(tub.threat_at(Vector2(100 + PopcornTub.RADIUS + 30.0, 100), false), 1, "along the spokes is better avoided")
	assert_eq(tub.threat_at(Vector2(300, 300), false), 0)
	assert_false(tub.advance(PopcornTub.WARNING - 0.05))
	assert_true(tub.threat_imminent(Vector2(100, 100)))
	assert_true(tub.advance(0.1), "it lands")
	assert_false(tub.advance(0.1), "once")
	assert_eq(tub.threat_at(Vector2(100, 100), true), 0, "landed, the kernels are the danger now")
	assert_true(PopcornTub.hits(Vector2.ZERO, Vector2(0, PopcornTub.RADIUS - 1.0)))
	assert_false(PopcornTub.hits(Vector2.ZERO, Vector2(0, PopcornTub.RADIUS + 1.0)))
	tub.free()


# --- the Runaway Film Reel ---

func test_its_first_leg_rolls_along_the_row_or_column_toward_him() -> void:
	assert_eq(FilmReelBehavior.axis_toward(Vector2(50, 10)), Vector2.RIGHT)
	assert_eq(FilmReelBehavior.axis_toward(Vector2(-50, 10)), Vector2.LEFT)
	assert_eq(FilmReelBehavior.axis_toward(Vector2(5, 60)), Vector2.DOWN)
	assert_eq(FilmReelBehavior.axis_toward(Vector2(5, -60)), Vector2.UP)


func test_on_each_bounce_it_turns_90_degrees_toward_him() -> void:
	assert_eq(FilmReelBehavior.bounce_turn(Vector2.RIGHT, Vector2(-10, 80)), Vector2.DOWN, "rolling east, he is south")
	assert_eq(FilmReelBehavior.bounce_turn(Vector2.RIGHT, Vector2(-10, -80)), Vector2.UP)
	assert_eq(FilmReelBehavior.bounce_turn(Vector2.UP, Vector2(90, 5)), Vector2.RIGHT)
	assert_eq(FilmReelBehavior.bounce_turn(Vector2.UP, Vector2(-90, 5)), Vector2.LEFT)
	assert_eq(FilmReelBehavior.bounce_turn(Vector2.LEFT, Vector2(0, 40)), Vector2.DOWN)
	assert_eq(FilmReelBehavior.bounce_turn(Vector2.DOWN, Vector2(40, 0)), Vector2.RIGHT)
	for way: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		for to: Vector2 in [Vector2(30, 70), Vector2(-70, 20), Vector2(5, -90)]:
			var turned := FilmReelBehavior.bounce_turn(way, to)
			assert_near(absf(turned.dot(way)), 0.0, "a right angle")
			assert_true(turned.dot(to) >= 0.0, "toward him")


func test_a_blocked_side_turns_it_the_other_way_or_back() -> void:
	var south_blocked := func(way: Vector2) -> bool: return way != Vector2.DOWN
	assert_eq(FilmReelBehavior.bounce_turn(Vector2.RIGHT, Vector2(0, 80), south_blocked), Vector2.UP, "the other side")
	var both_blocked := func(way: Vector2) -> bool: return way == Vector2.LEFT
	assert_eq(FilmReelBehavior.bounce_turn(Vector2.RIGHT, Vector2(0, 80), both_blocked), Vector2.LEFT, "back the way it came")


func test_it_bounces_only_off_what_it_runs_into_head_on() -> void:
	var wall_ahead: Array[Vector2] = [Vector2.LEFT]
	assert_true(FilmReelBehavior.ran_into(Vector2.RIGHT, wall_ahead), "a wall across its way")
	var wall_beside: Array[Vector2] = [Vector2.RIGHT]
	assert_false(FilmReelBehavior.ran_into(Vector2.DOWN, wall_beside), "a seat it rolls along")
	var none: Array[Vector2] = []
	assert_false(FilmReelBehavior.ran_into(Vector2.DOWN, none))


func test_its_next_leg_is_warned_long_enough_to_step_aside() -> void:
	assert_true(FilmReelBehavior.WINDUP * PlayerStats.BASE_WARNING >= 0.2)
	# It must still roll its own length to reach the spot right ahead of it.
	var walk := PlayerStats.BASE_SPEED * (FilmReelBehavior.WINDUP + 20.0 / FilmReelBehavior.ROLL_SPEED - 0.3)
	assert_true(walk > FilmReelBehavior.LANE_WIDTH, "%f" % walk)
	assert_true(_load("film_reel").contact_damage > 0, "touching it costs a pill")


func test_the_film_trail_slows_him_while_he_stands_on_it() -> void:
	var trail := FilmTrail.new()
	trail.setup(null)
	trail.add_piece(Vector2(100, 100), Vector2.RIGHT)
	trail.add_piece(Vector2(112, 100), Vector2.RIGHT)
	assert_true(trail.covers(Vector2(105, 103)))
	assert_false(trail.covers(Vector2(105, 120)), "beside the strip")
	assert_true(trail.advance(0.02, Vector2(105, 100)), "a slow is laid on him")
	assert_false(trail.advance(0.02, Vector2(105, 100)), "not again at once")
	assert_true(trail.advance(FilmTrail.SLOW_EVERY, Vector2(105, 100)), "then again while he stands on it")
	assert_false(trail.advance(0.02, Vector2(300, 300)), "nothing off it")
	assert_eq(trail.threat_at(Vector2(105, 100), false), 1, "better avoided, never a hit")
	assert_false(trail.threat_imminent(Vector2(105, 100)))
	assert_true(FilmTrail.SLOW > 0.0 and FilmTrail.SLOW < 1.0 - SlowEffect.MIN_FACTOR + 0.01)
	trail.free()


func test_each_piece_of_film_fades_4_seconds_after_it_was_laid() -> void:
	assert_near(FilmTrail.LINGER, 4.0)
	var trail := FilmTrail.new()
	trail.setup(null)
	trail.add_piece(Vector2(100, 100), Vector2.DOWN)
	trail.advance(2.0, Vector2.INF)
	trail.add_piece(Vector2(100, 112), Vector2.DOWN)
	trail.advance(1.9, Vector2.INF)
	assert_true(trail.covers(Vector2(100, 100)), "3.9 s old")
	trail.advance(0.2, Vector2.INF)
	assert_false(trail.covers(Vector2(100, 100)), "gone at 4 s")
	assert_true(trail.covers(Vector2(100, 112)), "the younger piece lingers")
	trail.advance(2.0, Vector2.INF)
	assert_false(trail.covers(Vector2(100, 112)))
	assert_eq(trail.piece_count(), 0)
	trail.free()


func test_the_trail_keeps_to_a_fixed_length() -> void:
	var trail := FilmTrail.new()
	trail.setup(null)
	for i in FilmTrail.MOST_PIECES + 10:
		trail.add_piece(Vector2(i * FilmTrail.PIECE, 0), Vector2.RIGHT)
	assert_eq(trail.piece_count(), FilmTrail.MOST_PIECES)
	trail.free()


# --- the Extra, who steps out of the screen ---

func test_the_extra_is_fragile_and_quick() -> void:
	var extra := _load("extra")
	assert_eq(extra.id, "extra")
	assert_eq(extra.art(), "extra")
	assert_true(CinemaMarks.draws(extra.mark))
	assert_true(extra.max_hp <= _load("seasonal_temp").max_hp, "as fragile as the first floor's weakest")
	assert_true(extra.speed >= 120.0, "and quick")
	assert_true(extra.color.s < 0.05, "grey as black-and-white film")


func test_the_extras_shove_is_warned_and_pushes_him_away() -> void:
	assert_true(ExtraBehavior.WINDUP * PlayerStats.BASE_WARNING >= 0.2)
	var walk := PlayerStats.BASE_SPEED * (ExtraBehavior.WINDUP - 0.2)
	assert_true(walk + ExtraBehavior.START_RANGE > ExtraBehavior.STRIKE_RANGE, "a step back clears the shove")
	var push := ExtraBehavior.shove_for(Vector2(100, 100), Vector2(130, 100))
	assert_near(push.length(), ExtraBehavior.SHOVE)
	assert_true(push.x > 0.0, "away from the Extra")
	assert_near(ExtraBehavior.shove_for(Vector2.ZERO, Vector2.ZERO).length(), ExtraBehavior.SHOVE, "even right on top of him")


func test_a_summoned_extra_pays_nothing() -> void:
	var extra := Enemy.new()
	extra.setup(_load("extra"), null, 0.5)
	extra.is_summon = true
	extra.apply_floor(1.8, 2.0)
	assert_eq(extra.coin_value(), 0)
	extra.free()


# --- the returning pair ---

func test_returning_enemies_keep_their_numbers_and_take_the_floors_colors() -> void:
	for id in ["intern_reaper", "notary_public"]:
		var mine := _load("cinema_" + id)
		var theirs := _load(id)
		assert_near(mine.max_hp, theirs.max_hp, id)
		assert_near(mine.speed, theirs.speed, id)
		assert_eq(mine.pension_drop, theirs.pension_drop, id)
		assert_eq(mine.damage, theirs.damage, id)
		assert_eq(mine.behavior_script, theirs.behavior_script, id)
		assert_eq(mine.display_name, theirs.display_name, id)
		assert_eq(mine.body_size, theirs.body_size, id)
		assert_eq(mine.mark, theirs.mark, id)
		assert_true(_difference(mine.color, theirs.color) > 0.2, "%s wears the Cinema's colours" % id)
	var reaper := _load("cinema_intern_reaper")
	assert_eq(reaper.art(), "cinema_intern_reaper", "the reaper wears its own usher art")
	assert_true(reaper.art_hue_width > 0.0 and not is_equal_approx(reaper.art_hue_to, reaper.art_hue_from), "recoloured")


# --- all of them ---

func test_new_enemies_match_the_first_floor_role_they_fill() -> void:
	var pairs := {"usher": "debt_ghost", "popcorn_vendor": "filing_clerk", "film_reel": "seasonal_temp"}
	for id: String in pairs:
		var def := _load(id)
		var theirs := _load(pairs[id])
		assert_eq(def.id, id)
		assert_false(def.is_boss, id)
		assert_false(def.display_name.is_empty(), id)
		assert_true(CinemaMarks.draws(def.mark), "%s has a mark of its own" % id)
		assert_eq(def.art(), id, "%s wears its own art" % id)
		assert_eq(def.pension_drop, theirs.pension_drop, id)
		assert_true(absf(def.max_hp - theirs.max_hp) <= 4.0, id)
		assert_true(def.behavior_script.new() is EnemyBehavior, id)


func test_the_regulars_match_the_spec() -> void:
	assert_eq(_load("usher").body_size, Vector2(20, 26))
	assert_eq(_load("popcorn_vendor").body_size, Vector2(18, 24))
	assert_eq(_load("film_reel").body_size, Vector2(18, 18))


func test_the_cinemas_new_enemies_can_be_told_apart() -> void:
	var ids := ["usher", "popcorn_vendor", "film_reel", "extra", "cinema_intern_reaper", "cinema_notary_public"]
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a := _load(ids[i])
			var b := _load(ids[j])
			var gap := _difference(SpriteVisual.readable(a.color), SpriteVisual.readable(b.color))
			assert_true(gap >= 0.25 or (a.body_size - b.body_size).length() >= 12.0, "%s and %s" % [ids[i], ids[j]])


func test_their_effects_are_cleared_from_a_stored_room() -> void:
	var effects: Array[Node] = [PopcornTub.new(), FilmTrail.new()]
	for effect in effects:
		assert_true(RoomView.is_passing_effect(effect), "%s is cleared" % effect.get_script().get_global_name())
		effect.free()
