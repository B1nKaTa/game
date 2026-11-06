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
