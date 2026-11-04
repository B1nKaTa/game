extends TestCase

# Head Office's regular enemies: the Yes-Men, the Paper Shredder and the HR Representative, and the
# Florist and the Perfume Sprayer back in the office's colours.


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


# --- the Yes-Men ---

func test_yes_men_come_in_threes() -> void:
	var def := _load("yes_man")
	assert_eq(def.group_size, 3)
	assert_eq(YesMenChorus.SIZE, 3)
	assert_eq(def.pension_drop, 1)
	assert_eq(def.behavior_script, load("res://scripts/actors/behaviors/yes_man_behavior.gd"))


func test_the_others_copy_a_lunge_half_a_beat_later() -> void:
	assert_near(YesMenChorus.echo_delay(true), 0.0, "the one who leads lunges at once")
	assert_near(YesMenChorus.echo_delay(false), YesMenChorus.ECHO_DELAY)
	assert_true(YesMenChorus.ECHO_DELAY > 0.1 and YesMenChorus.ECHO_DELAY < YesManBehavior.LUNGE_WINDUP, "half a beat, not a second lunge on top")
	var chorus := YesMenChorus.new()
	var a := Enemy.new()
	a.setup(_load("yes_man"), null, 0.5)
	var b := Enemy.new()
	b.setup(_load("yes_man"), null, 0.5)
	chorus.members.append(a)
	chorus.members.append(b)
	assert_eq(chorus.leads, 0)
	chorus.lead(a)
	assert_eq(chorus.leads, 1, "each lead counts once")
	assert_eq(chorus.last_leader_id, a.get_instance_id())
	assert_eq(chorus.place_of(b), 1)
	assert_eq(chorus.living(), 2)
	a.take_damage(INF, Vector2.ZERO)
	assert_eq(chorus.living(), 1)
	a.free()
	b.free()


func test_each_lunge_warns_whole_and_leaves_time_to_step_out_of_its_lane() -> void:
	assert_true(YesManBehavior.LUNGE_SHOWN_WHOLE, "it starts right beside him")
	var walk := PlayerStats.BASE_SPEED * (YesManBehavior.LUNGE_WINDUP - 0.3)
	assert_true(walk > YesManBehavior.LANE_WIDTH, "%f" % walk)
	assert_true(YesManBehavior.lunge_time() < 0.4, "a short lunge")
	assert_true(YesManBehavior.LUNGE_LENGTH > YesManBehavior.START_RANGE - 20.0, "it reaches him from where it starts")


func test_yes_men_spread_round_him() -> void:
	var seen := {}
	for index in 3:
		seen[snappedf(YesManBehavior.flank_angle(index), 0.01)] = true
	assert_eq(seen.size(), 3, "three sides")
	assert_near(YesManBehavior.flank_angle(3), YesManBehavior.flank_angle(0))


# --- the Paper Shredder ---

func test_the_shredder_charges_down_a_warned_lane() -> void:
	var walk := PlayerStats.BASE_SPEED * (PaperShredderBehavior.WINDUP - 0.3)
	assert_true(walk > PaperShredderBehavior.LANE_WIDTH, "time to step out of the lane")
	assert_true(PaperShredderBehavior.CHARGE_LENGTH <= 260.0)


func test_its_paper_trail_stays_short() -> void:
	var trail := PaperTrail.new()
	trail.setup(null)
	for i in PaperShredderBehavior.scraps_per_charge() + 4:
		trail.add_scrap(Vector2(i * PaperShredderBehavior.SCRAP_EVERY, 100.0))
	assert_eq(trail.scraps().size(), PaperTrail.MOST_SCRAPS, "only the last few scraps stay")
	assert_true(trail.covers(Vector2((PaperShredderBehavior.scraps_per_charge() + 3) * PaperShredderBehavior.SCRAP_EVERY, 100.0)), "the newest scrap")
	assert_false(trail.covers(Vector2(0.0, 100.0)), "the oldest was swept up")
	trail.free()


func test_the_trail_slows_now_and_then_and_never_hurts() -> void:
	var trail := PaperTrail.new()
	trail.setup(null)
	trail.add_scrap(Vector2(100, 100))
	var on := Vector2(105, 100)
	var slows := 0
	for frame in 60:
		if trail.advance(1.0 / 60.0, on):
			slows += 1
	assert_true(slows >= 4 and slows <= 6, "about one slow every %f s, got %d" % [PaperTrail.SLOW_EVERY, slows])
	assert_false(trail.advance(0.016, Vector2(300, 300)), "off the trail nothing happens")
	assert_true(PaperTrail.SLOW > 0.0 and PaperTrail.SLOW < 1.0)
	assert_false(trail.has_method("hit_target") or trail.has_method("damage"), "paper has no way to hurt")
	trail.advance(PaperTrail.LINGER, on)
	assert_false(trail.covers(on), "swept away after a while")
	trail.free()


func test_a_slowed_grandpa_still_walks_out() -> void:
	var slow := SlowEffect.new()
	slow.apply(PaperTrail.SLOW, PaperTrail.SLOW_TIME)
	assert_true(slow.speed_factor() >= SlowEffect.MIN_FACTOR)
	assert_near(slow.speed_factor(), 1.0 - PaperTrail.SLOW)


# --- the HR Representative ---

func test_hr_keeps_her_distance() -> void:
	assert_eq(HrRepBehavior.step(60.0), HrRepBehavior.BACK_OFF)
	assert_eq(HrRepBehavior.step(170.0), HrRepBehavior.HOLD)
	assert_eq(HrRepBehavior.step(HrRepBehavior.TOO_FAR + 1.0), HrRepBehavior.CLOSE_IN)


func test_her_memos_land_near_him() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 100:
		var spot := HrRepBehavior.memo_spot(Vector2(200, 200), rng)
		assert_true(spot.distance_to(Vector2(200, 200)) <= HrRepBehavior.SPREAD + 0.01)


func test_a_memos_warning_leaves_time_to_walk_out() -> void:
	var walk := PlayerStats.BASE_SPEED * (WriteUpMark.WARNING - 0.2)
	assert_true(walk > WriteUpMark.RADIUS * 2.0, "%f" % walk)


func test_a_write_up_covers_its_spot_only_once_it_lands_and_until_it_is_filed() -> void:
	var mark := WriteUpMark.new()
	mark.setup(null)
	mark.position = Vector2(200, 200)
	assert_false(mark.covers(Vector2(200, 200)), "not while it is only a warning")
	assert_false(mark.advance(WriteUpMark.WARNING - 0.1))
	assert_true(mark.advance(0.2), "it lands")
	assert_true(mark.covers(Vector2(210, 205)))
	assert_false(mark.covers(Vector2(230, 200)), "outside its reach")
	mark.advance(WriteUpMark.LINGER)
	assert_true(mark.is_finished())
	assert_false(mark.covers(Vector2(200, 200)))
	mark.free()


func test_a_write_up_stings_only_after_standing_in_it_a_moment() -> void:
	var mark := WriteUpMark.new()
	mark.setup(null)
	var stings := 0
	for frame in 30:
		if mark.stand(1.0 / 60.0, true):
			stings += 1
	assert_eq(stings, 0, "half a second in it is still safe")
	for frame in 12:
		if mark.stand(1.0 / 60.0, true):
			stings += 1
	assert_eq(stings, 1, "a moment longer stings")
	var stepping := WriteUpMark.new()
	stepping.setup(null)
	for frame in 300:
		if stepping.stand(1.0 / 60.0, frame % 30 < 20):
			stings += 1
	assert_eq(stings, 1, "stepping in and out never stands long enough")
	assert_true(WriteUpMark.STING_AFTER >= 0.5)
	assert_eq(WriteUpMark.STING_DAMAGE, 1)
	mark.free()
	stepping.free()


func test_office_effects_are_cleared_from_a_stored_room() -> void:
	var effects: Array[Node] = [PaperTrail.new(), WriteUpMark.new()]
	for effect in effects:
		assert_true(RoomView.is_passing_effect(effect), "%s is cleared" % effect.get_script().get_global_name())
		effect.free()


# --- the returning pair ---

func test_returning_enemies_keep_their_numbers_and_take_the_floors_colors() -> void:
	for id in ["florist", "perfume_sprayer"]:
		var mine := _load("office_" + id)
		var theirs := _load(id)
		assert_near(mine.max_hp, theirs.max_hp, id)
		assert_near(mine.speed, theirs.speed, id)
		assert_eq(mine.pension_drop, theirs.pension_drop, id)
		assert_eq(mine.behavior_script, theirs.behavior_script, id)
		assert_eq(mine.display_name, theirs.display_name, id)
		assert_eq(mine.max_per_room, theirs.max_per_room, id)
		assert_eq(mine.group_size, theirs.group_size, id)
		assert_eq(mine.body_size, theirs.body_size, id)
		assert_eq(mine.mark, theirs.mark, id)
		assert_true(mine.id != theirs.id and mine.color != theirs.color, id)


# --- the numbers ---

func test_new_enemies_match_the_first_floor_role_they_fill() -> void:
	var pairs := {"yes_man": "seasonal_temp", "hr_representative": "filing_clerk", "paper_shredder": "debt_ghost"}
	for id: String in pairs:
		var def := _load(id)
		var theirs := _load(pairs[id])
		assert_false(def.is_boss, id)
		assert_false(def.display_name.is_empty(), id)
		assert_false(def.mark.is_empty(), id)
		assert_eq(def.pension_drop, theirs.pension_drop, id)
		assert_true(absf(def.max_hp - theirs.max_hp) <= 4.0, id)
		assert_true(def.behavior_script.new() is EnemyBehavior, id)
