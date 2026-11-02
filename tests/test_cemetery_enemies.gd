extends TestCase

const Riser := preload("res://scripts/actors/behaviors/riser_behavior.gd")
const Groundskeeper := preload("res://scripts/actors/behaviors/groundskeeper_behavior.gd")
const Undertaker := preload("res://scripts/actors/behaviors/undertaker_behavior.gd")
const SLAM := Groundskeeper.Attack.SLAM
const FURROW := Groundskeeper.Attack.FURROW
const CLIPPINGS := Groundskeeper.Attack.CLIPPINGS
const SHOVEL := Undertaker.Attack.SHOVEL
const ROWS := Undertaker.Attack.ROWS
const PITS := Undertaker.Attack.PITS
const WREATHS := Undertaker.Attack.WREATHS
const SUMMON := Undertaker.Attack.SUMMON


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


# --- the numbers ---

func test_the_new_bosses_match_the_first_floors_bosses() -> void:
	var mini := _load("head_groundskeeper")
	var adjuster := _load("senior_adjuster")
	assert_true(mini.is_boss)
	assert_near(mini.max_hp, adjuster.max_hp)
	assert_eq(mini.damage, adjuster.damage)
	assert_eq(mini.pension_drop, adjuster.pension_drop)
	var boss := _load("tired_undertaker")
	var reaper := _load("regional_reaper")
	assert_true(boss.is_boss)
	assert_near(boss.max_hp, reaper.max_hp)
	assert_eq(boss.damage, reaper.damage)
	assert_eq(boss.pension_drop, reaper.pension_drop)
	for def: EnemyDef in [mini, boss]:
		assert_true(def.summon != null and not def.summon.is_boss, def.id)
		assert_true(def.behavior_script.new() is EnemyBehavior, def.id)


func test_the_plot_holder_is_a_regular_enemy_with_a_dark_comedy_name() -> void:
	var def := _load("plot_holder")
	assert_false(def.is_boss)
	assert_false(def.display_name.is_empty())
	assert_eq(def.pension_drop, 1)
	assert_true(def.max_per_room > 0, "a room of nothing but risers would be all waiting")
	assert_true(def.behavior_script.new() is EnemyBehavior)


# --- rising from the ground ---

func test_the_warning_under_grandpa_leaves_time_to_step_out() -> void:
	assert_true(Riser.RISE_WINDUP >= 0.7, "the whole windup shows, and he must react and walk out")
	assert_true(Riser.RISE_RADIUS * 2.0 < PlayerStats.BASE_SPEED * Riser.RISE_WINDUP, "he can walk clear across it in time")


func test_a_riser_tunnels_then_warns_then_stands_then_tunnels_again() -> void:
	assert_eq(Riser.next_state(Riser.State.TUNNEL), Riser.State.RISING)
	assert_eq(Riser.next_state(Riser.State.RISING), Riser.State.UP)
	assert_eq(Riser.next_state(Riser.State.UP), Riser.State.TUNNEL)


func test_a_rise_hits_only_inside_its_warning() -> void:
	assert_true(Riser.rise_hits(Vector2(100, 100), Vector2(100 + Riser.RISE_RADIUS - 1.0, 100)))
	assert_false(Riser.rise_hits(Vector2(100, 100), Vector2(100 + Riser.RISE_RADIUS + 1.0, 100)))


func test_a_submerged_enemy_takes_no_ordinary_damage_but_can_still_be_cleared() -> void:
	var enemy := Enemy.new()
	enemy.setup(_load("plot_holder"), null, 0.5)
	enemy.submerged = true
	var hp := enemy.hp
	enemy.take_damage(10.0, Vector2.ZERO)
	assert_near(enemy.hp, hp, "the cane and blasts pass over the mound")
	assert_true(enemy.take_strike(10.0, Vector2.ZERO, Vector2.RIGHT) == false, "a swing does not land")
	assert_near(enemy.hp, hp)
	enemy.take_damage(INF, Vector2.ZERO)
	assert_true(enemy.hp <= 0.0, "a dismissal still ends it, so a room can always finish")
	enemy.free()


func test_a_summoned_riser_pays_nothing() -> void:
	var enemy := Enemy.new()
	enemy.setup(_load("plot_holder"), null, 0.5)
	assert_eq(enemy.coin_value(), 1)
	enemy.is_summon = true
	assert_eq(enemy.coin_value(), 0)
	enemy.free()


# --- ground strikes ---

func test_a_strike_waits_then_warns_for_its_whole_time_then_lands_once() -> void:
	var strike := GroundStrike.new()
	strike.setup(null, 20.0, 0.5, 0.2)
	assert_false(strike.advance(0.1))
	assert_near(strike.fill(), 0.0, "still waiting its turn")
	assert_false(strike.advance(0.1))
	assert_false(strike.advance(0.25))
	assert_near(strike.fill(), 0.5)
	assert_true(strike.advance(0.3))
	assert_false(strike.advance(0.3), "only once")
	strike.free()


func test_a_pit_follows_him_before_it_locks_in() -> void:
	var strike := GroundStrike.new()
	strike.setup(null, 20.0, 0.5, 0.0, 0.3)
	assert_true(strike.is_following())
	assert_false(strike.advance(0.31))
	assert_false(strike.is_following())
	assert_false(strike.advance(0.49))
	assert_true(strike.advance(0.02))
	strike.free()


func test_a_strike_hits_by_the_feet_inside_its_radius() -> void:
	assert_true(GroundStrike.hits(Vector2.ZERO, 20.0, Vector2(19, 0)))
	assert_false(GroundStrike.hits(Vector2.ZERO, 20.0, Vector2(21, 0)))


# --- the groundskeeper ---

func test_the_groundskeeper_slams_up_close_and_works_the_ground_from_afar() -> void:
	assert_eq(Groundskeeper.choose_attack(true, FURROW, 0.0), SLAM)
	for last in [Groundskeeper.Attack.NONE, SLAM, FURROW, CLIPPINGS]:
		for i in 10:
			var picked: int = Groundskeeper.choose_attack(false, last, i / 10.0)
			assert_true(picked != SLAM, "far")
			assert_true(picked != last or last == Groundskeeper.Attack.NONE, "never the same ground attack twice")


func test_a_furrow_runs_in_a_line_from_the_boss() -> void:
	var points: Array[Vector2] = Groundskeeper.furrow_points(Vector2(100, 100), Vector2.RIGHT, 4, 40.0)
	assert_eq(points.size(), 4)
	for i in 4:
		assert_near(points[i].x, 100.0 + 40.0 * (i + 1))
		assert_near(points[i].y, 100.0)


func test_clippings_land_on_him_and_around_him_with_room_to_leave() -> void:
	var points: Array[Vector2] = Groundskeeper.scatter_points(Vector2(50, 50), Groundskeeper.CLIPPINGS_COUNT, Groundskeeper.CLIPPINGS_DISTANCE, 0.3)
	assert_eq(points.size(), Groundskeeper.CLIPPINGS_COUNT)
	assert_eq(points[0], Vector2(50, 50))
	for i in range(1, points.size()):
		assert_near(points[i].distance_to(points[0]), Groundskeeper.CLIPPINGS_DISTANCE)
	var gap := points[1].distance_to(points[2])
	assert_true(gap > Groundskeeper.CLIPPINGS_RADIUS * 2.0, "a way out between two of them, gap %f" % gap)


# --- the undertaker ---

func test_the_undertaker_changes_phase_at_half_health() -> void:
	assert_false(Undertaker.is_phase_two(51.0, 100.0))
	assert_true(Undertaker.is_phase_two(50.0, 100.0))


func test_the_undertaker_mostly_swings_up_close_and_never_from_afar() -> void:
	assert_eq(Undertaker.choose_attack(true, Undertaker.Attack.NONE, false, 0.1), SHOVEL)
	assert_eq(Undertaker.choose_attack(true, Undertaker.Attack.NONE, false, 0.95), PITS, "standing close is no safe spot")
	for i in 20:
		assert_true(Undertaker.choose_attack(false, Undertaker.Attack.NONE, true, i / 20.0) != SHOVEL)


func test_a_far_undertaker_never_repeats_and_summons_only_when_allowed() -> void:
	var seen := {}
	for i in 20:
		seen[Undertaker.choose_attack(false, Undertaker.Attack.NONE, true, i / 20.0)] = true
		assert_true(Undertaker.choose_attack(false, ROWS, true, i / 20.0) != ROWS)
		assert_true(Undertaker.choose_attack(false, PITS, false, i / 20.0) != SUMMON)
	for attack in [ROWS, PITS, WREATHS, SUMMON]:
		assert_true(seen.has(attack), str(attack))


func test_only_the_second_phase_chains_and_never_after_a_summon() -> void:
	for attack in [SHOVEL, ROWS, PITS, WREATHS, SUMMON]:
		assert_eq(Undertaker.followup(attack, false, 0.0), Undertaker.Attack.NONE)
	assert_true(Undertaker.followup(PITS, true, 0.2) != Undertaker.Attack.NONE)
	assert_eq(Undertaker.followup(SUMMON, true, 0.2), Undertaker.Attack.NONE)


func test_the_second_phase_is_harder_at_everything() -> void:
	for attack in [SHOVEL, ROWS, PITS, WREATHS, SUMMON]:
		assert_true(Undertaker.windup_for(attack, true) < Undertaker.windup_for(attack, false), str(attack))
		assert_true(Undertaker.windup_for(attack, true) * PlayerStats.BASE_WARNING >= 0.2, str(attack))
	assert_true(Undertaker.cooldown_for(true) < Undertaker.cooldown_for(false))
	assert_true(Undertaker.row_count(true) > Undertaker.row_count(false))
	assert_true(Undertaker.pit_count(true) > Undertaker.pit_count(false))
	assert_true(Undertaker.volley_count(true) > Undertaker.volley_count(false))


func test_every_row_of_plots_leaves_a_gap_he_can_stand_in() -> void:
	var rows: Array = Undertaker.row_points(Vector2.ZERO, Vector2.RIGHT, 4, 7, 2)
	assert_eq(rows.size(), 4)
	var gaps := {}
	for r in rows.size():
		var row: Array = rows[r]
		assert_eq(row.size(), 6, "one spot of seven is left out")
		for point: Vector2 in row:
			assert_near(point.x, Undertaker.ROW_SPACING * (r + 1))
		var missing := -1
		for spot in 7:
			var y := (spot - 3) * Undertaker.ROW_SPOT_GAP
			var found := false
			for point: Vector2 in row:
				found = found or absf(point.y - y) < 0.01
			if not found:
				missing = spot
		assert_true(missing != -1)
		gaps[missing] = true
	assert_true(gaps.size() > 1, "the gap moves from row to row")
	assert_true(Undertaker.ROW_SPOT_GAP * 2.0 - Undertaker.ROW_RADIUS * 2.0 >= 30.0, "wide enough at a walk")


func test_neighboring_spots_of_a_row_leave_no_way_through() -> void:
	assert_true(Undertaker.ROW_SPOT_GAP <= Undertaker.ROW_RADIUS * 2.0, "only the gap is safe")


func test_a_fan_centers_on_him() -> void:
	var directions: Array[Vector2] = Undertaker.fan_directions(Vector2.RIGHT, 5, 1.0)
	assert_eq(directions.size(), 5)
	assert_true(directions[2].is_equal_approx(Vector2.RIGHT))
	assert_near(directions[0].angle(), -0.5)
	assert_near(directions[4].angle(), 0.5)


func test_summons_stand_around_him_not_on_him() -> void:
	var points: Array[Vector2] = Undertaker.corner_points(Vector2(10, 10), 4, 100.0, 0.0)
	assert_eq(points.size(), 4)
	for point in points:
		assert_near(point.distance_to(Vector2(10, 10)), 100.0)
