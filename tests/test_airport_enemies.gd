extends TestCase

# Departures, Terminal Zero's regular enemies: the Tour Group, the Baggage Handler and Lost Luggage,
# with the Weeping Mourner and the Mall Cop back in the departure hall's colours.


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


# --- the Tour Group ---

func test_a_tour_group_is_a_guide_and_two_followers() -> void:
	var def := _load("tour_group")
	assert_eq(def.group_size, 3)
	assert_eq(TourGroup.SIZE, 3)
	assert_eq(def.pension_drop, 1)
	assert_near(TourGroup.CALL_TIME, 0.9)
	assert_near(TourGroupBehavior.CALL_WINDUP, TourGroup.CALL_TIME)


func test_the_whole_group_rushes_the_guides_way() -> void:
	var guide := Vector2(100, 100)
	var target := Vector2(300, 100)
	assert_true(TourGroup.rush_lane(guide, target).is_equal_approx(Vector2.RIGHT), "straight at him")
	assert_near(TourGroup.rush_lane(guide, Vector2(130, 140)).length(), 1.0)
	assert_true(TourGroup.rush_lane(guide, guide).is_equal_approx(Vector2.DOWN), "a guide on top of him still has a lane")


func test_followers_keep_behind_the_guide_one_each_side() -> void:
	var guide := Vector2(200, 200)
	var facing := Vector2.RIGHT
	var first := TourGroup.follow_spot(guide, facing, 1)
	var second := TourGroup.follow_spot(guide, facing, 2)
	assert_true(first.x < guide.x and second.x < guide.x, "both behind")
	assert_true(signf(first.y - guide.y) != signf(second.y - guide.y), "one to each side")
	assert_true(first.distance_to(guide) <= TourGroup.FOLLOW_GAP * 1.5)
	assert_true(TourGroup.follow_spot(guide, Vector2.ZERO, 1).y < guide.y, "with no facing they keep above")


func test_followers_scatter_only_once_the_guide_is_gone() -> void:
	assert_false(TourGroup.scatters(true, false), "the guide still leads")
	assert_true(TourGroup.scatters(false, false), "lost without the guide")
	assert_false(TourGroup.scatters(false, true), "the guide never scatters from itself")
	assert_true(TourGroupBehavior.SCATTER_SPEED < 1.0, "scattered, they only wander slowly")


func test_only_the_guide_runs_the_groups_clock() -> void:
	var guide := Enemy.new()
	guide.setup(_load("tour_group"), null, 0.5)
	var follower := Enemy.new()
	follower.setup(_load("tour_group"), null, 0.5)
	var group := TourGroup.new()
	group.guide = guide
	group.members.append(guide)
	group.members.append(follower)
	group.advance(follower, 10.0)
	assert_eq(group.calls, 0, "a follower's tick moves nothing")
	assert_eq(group.place_of(guide), 0)
	assert_eq(group.place_of(follower), 1)
	assert_true(group.has_guide())
	guide.take_damage(INF, Vector2.ZERO)
	assert_false(group.has_guide(), "a fallen guide leads no more")
	guide.free()
	follower.free()


func test_the_call_leaves_time_to_step_out_of_the_lanes() -> void:
	var walk := PlayerStats.BASE_SPEED * (TourGroup.CALL_TIME - 0.3)
	assert_true(walk > TourGroupBehavior.LANE_WIDTH * 2.0, "%f" % walk)


# --- the Baggage Handler ---

func test_the_baggage_handler_runs_only_when_rested_near_and_in_view() -> void:
	assert_true(BaggageHandlerBehavior.should_charge(150.0, 0.0, true))
	assert_false(BaggageHandlerBehavior.should_charge(150.0, 0.5, true), "still resting")
	assert_false(BaggageHandlerBehavior.should_charge(BaggageHandlerBehavior.START_RANGE + 1.0, 0.0, true), "too far")
	assert_false(BaggageHandlerBehavior.should_charge(150.0, 0.0, false), "not in view")


func test_his_cart_stops_only_at_what_will_not_break_struck_head_on() -> void:
	assert_true(BaggageHandlerBehavior.runs_into(Vector2.LEFT, Vector2.RIGHT, true), "a wall ahead")
	assert_false(BaggageHandlerBehavior.runs_into(Vector2.LEFT, Vector2.RIGHT, false), "a prop is smashed, not stopped at")
	assert_false(BaggageHandlerBehavior.runs_into(Vector2.UP, Vector2.RIGHT, true), "a wall alongside only scrapes")


func test_the_cart_run_follows_the_plan() -> void:
	assert_near(BaggageHandlerBehavior.WINDUP, 0.8)
	assert_near(BaggageHandlerBehavior.CHARGE_LENGTH, 260.0)
	assert_near(BaggageHandlerBehavior.CHARGE_SPEED, 300.0)
	assert_near(BaggageHandlerBehavior.LANE_WIDTH, 32.0)
	var walk := PlayerStats.BASE_SPEED * (BaggageHandlerBehavior.WINDUP - 0.3)
	assert_true(walk > BaggageHandlerBehavior.LANE_WIDTH, "time to step out of the lane: %f" % walk)


# --- Lost Luggage ---

func test_lost_luggage_lies_still_until_he_comes_close() -> void:
	assert_false(LostLuggageBehavior.wakes(LostLuggageBehavior.WAKE_RANGE + 1.0))
	assert_true(LostLuggageBehavior.wakes(LostLuggageBehavior.WAKE_RANGE - 1.0))
	var behavior := LostLuggageBehavior.new()
	assert_true(behavior.is_lying(), "it starts as a suitcase on the floor")


func test_its_bite_shows_whole_and_reaches_only_around_it() -> void:
	assert_true(LostLuggageBehavior.bite_hits(Vector2(100, 100), Vector2(120, 110)))
	assert_false(LostLuggageBehavior.bite_hits(Vector2(100, 100), Vector2(100, 100 + LostLuggageBehavior.BITE_RADIUS + 1.0)))
	var suitcase := Enemy.new()
	suitcase.setup(_load("lost_luggage"), null, 0.25)
	var behavior := LostLuggageBehavior.new()
	behavior._begin_bite(suitcase)
	assert_near(suitcase._warning_share(), 1.0, "whatever his warning stat, it starts right beside him")
	assert_eq(behavior.state(), LostLuggageBehavior.State.BITING)
	suitcase.free()


func test_it_springs_open_then_stays_awake() -> void:
	assert_eq(LostLuggageBehavior.next_state(LostLuggageBehavior.State.LYING), LostLuggageBehavior.State.BITING)
	assert_eq(LostLuggageBehavior.next_state(LostLuggageBehavior.State.BITING), LostLuggageBehavior.State.AWAKE)
	assert_eq(LostLuggageBehavior.next_state(LostLuggageBehavior.State.AWAKE), LostLuggageBehavior.State.BITING, "awake, it bites again")


func test_its_bite_leaves_time_to_step_away() -> void:
	var walk := PlayerStats.BASE_SPEED * (LostLuggageBehavior.BITE_WINDUP - 0.3)
	assert_true(walk > LostLuggageBehavior.BITE_RADIUS, "even from right on top of it: %f" % walk)


# --- the returning enemies ---

func test_returning_enemies_keep_their_numbers_and_take_the_floors_colors() -> void:
	for id in ["weeping_mourner", "mall_cop"]:
		var mine := _load("airport_" + id)
		var theirs := _load(id)
		assert_near(mine.max_hp, theirs.max_hp, id)
		assert_near(mine.speed, theirs.speed, id)
		assert_eq(mine.pension_drop, theirs.pension_drop, id)
		assert_eq(mine.damage, theirs.damage, id)
		assert_eq(mine.behavior_script, theirs.behavior_script, id)
		assert_eq(mine.display_name, theirs.display_name, id)
		assert_eq(mine.max_per_room, theirs.max_per_room, id)
		assert_eq(mine.group_size, theirs.group_size, id)
		assert_eq(mine.body_size, theirs.body_size, id)
		assert_true(mine.id != theirs.id and mine.color != theirs.color, id)


# --- the numbers ---

func test_new_enemies_match_the_first_floor_role_they_fill() -> void:
	var pairs := {"tour_group": "seasonal_temp", "baggage_handler": "debt_ghost", "lost_luggage": "plot_holder"}
	for id: String in pairs:
		var def := _load(id)
		var theirs := _load(pairs[id])
		assert_false(def.is_boss, id)
		assert_false(def.display_name.is_empty(), id)
		assert_false(def.mark.is_empty(), id)
		assert_eq(def.pension_drop, theirs.pension_drop, id)
		assert_true(absf(def.max_hp - theirs.max_hp) <= 4.0, id)
		assert_true(def.behavior_script.new() is EnemyBehavior, id)
