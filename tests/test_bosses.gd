extends TestCase

const FloorBossBehavior := preload("res://scripts/actors/behaviors/floor_boss_behavior.gd")
const MiniBossBehavior := preload("res://scripts/actors/behaviors/mini_boss_behavior.gd")
const SWEEP := FloorBossBehavior.Attack.SWEEP
const DASH := FloorBossBehavior.Attack.DASH
const RING := FloorBossBehavior.Attack.RING
const SUMMON := FloorBossBehavior.Attack.SUMMON


func test_bosses_are_flagged() -> void:
	for id in ["senior_adjuster", "regional_reaper"]:
		var def: EnemyDef = load("res://data/enemies/%s.tres" % id)
		assert_true(def.is_boss, id)
		assert_true(def.max_hp >= 150.0, id)
		assert_true(def.behavior_script.new() is EnemyBehavior, id)


func test_boss_health_was_raised_for_a_real_fight() -> void:
	assert_true(load("res://data/enemies/regional_reaper.tres").max_hp >= 900.0)
	assert_true(load("res://data/enemies/senior_adjuster.tres").max_hp >= 400.0)


func test_mini_boss_summons_interns() -> void:
	var def: EnemyDef = load("res://data/enemies/senior_adjuster.tres")
	assert_eq(def.summon.id, "intern_reaper")


func test_floor_boss_summons_from_its_data() -> void:
	var def: EnemyDef = load("res://data/enemies/regional_reaper.tres")
	assert_true(def.summon != null)
	assert_false(def.summon.is_boss)


func test_floor_boss_changes_phase_at_half_health() -> void:
	assert_false(FloorBossBehavior.is_phase_two(51.0, 100.0))
	assert_true(FloorBossBehavior.is_phase_two(50.0, 100.0))


func test_a_near_player_is_swept_most_of_the_time() -> void:
	assert_eq(FloorBossBehavior.choose_attack(true, FloorBossBehavior.Attack.NONE, false, 0.1), SWEEP)
	assert_eq(FloorBossBehavior.choose_attack(true, FloorBossBehavior.Attack.NONE, false, 0.95), DASH, "or dashed through now and then")


func test_a_far_player_is_never_swept() -> void:
	for roll in [0.0, 0.3, 0.6, 0.99]:
		assert_true(FloorBossBehavior.choose_attack(false, FloorBossBehavior.Attack.NONE, true, roll) != SWEEP, str(roll))


func test_a_far_attack_never_repeats_itself() -> void:
	for last in [DASH, RING, SUMMON]:
		for i in 20:
			assert_true(FloorBossBehavior.choose_attack(false, last, true, i / 20.0) != last, "%d %d" % [last, i])


func test_summon_is_chosen_only_when_allowed() -> void:
	for i in 20:
		assert_true(FloorBossBehavior.choose_attack(false, DASH, false, i / 20.0) != SUMMON, str(i))
	var seen := {}
	for i in 20:
		seen[FloorBossBehavior.choose_attack(false, FloorBossBehavior.Attack.NONE, true, i / 20.0)] = true
	assert_true(seen.has(DASH) and seen.has(RING) and seen.has(SUMMON), str(seen.keys()))


func test_only_the_second_phase_chains_attacks() -> void:
	for attack in [SWEEP, DASH, RING, SUMMON]:
		assert_eq(FloorBossBehavior.followup(attack, false, 0.0), FloorBossBehavior.Attack.NONE, str(attack))
	assert_true(FloorBossBehavior.followup(DASH, true, 0.2) != FloorBossBehavior.Attack.NONE)
	assert_true(FloorBossBehavior.followup(RING, true, 0.2) != FloorBossBehavior.Attack.NONE)
	assert_eq(FloorBossBehavior.followup(SUMMON, true, 0.2), FloorBossBehavior.Attack.NONE, "a summon never chains")


func test_the_second_phase_is_faster_at_everything() -> void:
	for attack in [SWEEP, DASH, RING, SUMMON]:
		assert_true(FloorBossBehavior.windup_for(attack, true) < FloorBossBehavior.windup_for(attack, false), str(attack))
	assert_true(FloorBossBehavior.cooldown_for(true) < FloorBossBehavior.cooldown_for(false))
	assert_true(FloorBossBehavior.ring_count(true) > FloorBossBehavior.ring_count(false))


func test_every_floor_boss_windup_stays_readable_in_both_phases() -> void:
	for attack in [SWEEP, DASH, RING, SUMMON]:
		for phase_two in [false, true]:
			assert_true(FloorBossBehavior.windup_for(attack, phase_two) * PlayerStats.BASE_WARNING >= 0.2, str(attack))


# The Regional Reaper's body, centered on a point.
func _reaper_at(center: Vector2) -> Rect2:
	return Rect2(center - Vector2(20, 24), Vector2(40, 48))


func test_in_a_room_the_screen_holds_whole_the_camera_does_not_follow_grandpa() -> void:
	var room := Vector2(20, 11) * RoomBackdrop.TILE
	assert_true(BossMoves.in_view(_reaper_at(Vector2(320, 280)), room, Vector2(320, 100)), "180 px below him and on screen")
	assert_true(BossMoves.in_view(_reaper_at(Vector2(560, 290)), room, Vector2(48, 48)), "he stands in a corner, the boss across the room")
	assert_false(BossMoves.in_view(_reaper_at(Vector2(625, 176)), room, Vector2(320, 176)), "part of its body is past the side")


func test_in_a_big_room_the_view_follows_grandpa() -> void:
	var room := Vector2(30, 17) * RoomBackdrop.TILE
	var feet := Vector2(64, 64)
	assert_true(BossMoves.in_view(_reaper_at(Vector2(600, 300)), room, feet))
	assert_false(BossMoves.in_view(_reaper_at(Vector2(800, 450)), room, feet), "off the screen")
	assert_false(BossMoves.in_view(_reaper_at(Vector2(620, 180)), room, feet), "half off the screen")


func test_at_a_big_room_s_edge_the_view_stops_and_shows_more_of_the_room() -> void:
	var room := Vector2(30, 17) * RoomBackdrop.TILE
	var feet := Vector2(900, 500)
	assert_true(BossMoves.in_view(_reaper_at(Vector2(360, 300)), room, feet), "540 px away, yet the camera stopped at the wall")
	assert_false(BossMoves.in_view(_reaper_at(Vector2(340, 300)), room, feet), "its body crosses the view's edge")
	assert_true(BossMoves.view_rect(room, feet).end.is_equal_approx(room), "the view ends at the room's corner")


func test_a_ring_points_all_the_way_around() -> void:
	var directions := BossMoves.ring_directions(8, 0.0)
	assert_eq(directions.size(), 8)
	var sum := Vector2.ZERO
	for direction in directions:
		sum += direction
		assert_near(direction.length(), 1.0)
	assert_true(sum.length() < 0.01, "evenly spaced")


func test_a_ring_leaves_gaps_wide_enough_to_stand_in() -> void:
	var count := FloorBossBehavior.ring_count(true)
	# Grandpa is hit within Projectile.HIT_RADIUS of a shot's center, so he needs twice that between two.
	var at_sweep_range := TAU * FloorBossBehavior.SWEEP_RANGE / count
	assert_true(at_sweep_range >= Projectile.HIT_RADIUS * 2.0, str(at_sweep_range))


func test_cutoff_summons_land_ahead_of_a_moving_player() -> void:
	var points := BossMoves.cutoff_points(Vector2(100, 100), Vector2.RIGHT, Vector2(0, 100), 3, 90.0, 0.7)
	assert_eq(points.size(), 3)
	for point in points:
		assert_true(point.x > 100.0, str(point))
		assert_near(point.distance_to(Vector2(100, 100)), 90.0)


func test_cutoff_summons_land_behind_a_still_player_from_the_boss() -> void:
	var points := BossMoves.cutoff_points(Vector2(100, 100), Vector2.ZERO, Vector2(0, 100), 3, 90.0, 0.7)
	for point in points:
		assert_true(point.x > 100.0, "the far side from the boss, %s" % str(point))


func test_summons_stop_at_the_cap() -> void:
	assert_true(BossMoves.can_summon(2, 5))
	assert_false(BossMoves.can_summon(5, 5))
	assert_false(BossMoves.can_summon(9, 5))


func test_the_mini_boss_sweeps_up_close_and_charges_from_afar() -> void:
	assert_eq(MiniBossBehavior.choose_attack(true), MiniBossBehavior.Attack.SWEEP)
	assert_eq(MiniBossBehavior.choose_attack(false), MiniBossBehavior.Attack.CHARGE)


func test_a_dash_stops_only_at_things_that_do_not_break() -> void:
	assert_true(BossDash.stops_at(StaticBody2D.new()) == true)
	var crate := BreakableBlock.new()
	assert_false(BossDash.stops_at(crate), "a crate is broken in passing")
	crate.free()
