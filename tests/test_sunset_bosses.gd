extends TestCase

const Barbara := preload("res://scripts/actors/behaviors/activities_coordinator_behavior.gd")
const Matron := preload("res://scripts/actors/behaviors/matron_behavior.gd")
const SEDATIVE := MatronBehavior.Attack.SEDATIVE
const GURNEY := MatronBehavior.Attack.GURNEY
const LIGHTS_OUT := MatronBehavior.Attack.LIGHTS_OUT
const VISITING := MatronBehavior.Attack.VISITING
# Sunset Shores scales health by this, and its bosses hold their final health divided by it.
const SHORES_HEALTH := 1.4


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)



# --- Barbara ---

func test_the_bingo_grid_always_leaves_one_safe_column() -> void:
	var tiles := Barbara.bingo_grid(Vector2.ZERO, 2)
	assert_eq(tiles.size(), 12, "4 rows of 4, minus the safe column")
	for tile: Vector2 in tiles:
		assert_true(absf(tile.x - Barbara.column_x(Vector2.ZERO, 2)) > 1.0)


func test_the_safe_column_moves_each_time() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var last := 1
	var seen := {}
	for i in 30:
		var next := Barbara.next_safe_column(last, rng)
		assert_true(next != last and next >= 0 and next < 4)
		seen[next] = true
		last = next
	assert_eq(seen.size(), 4, "every column comes up")


func test_the_safe_column_is_really_safe_and_the_rest_is_not() -> void:
	var center := Vector2(200, 200)
	var tiles := Barbara.bingo_grid(center, 0)
	var safe := Vector2(Barbara.column_x(center, 0), Barbara.row_y(center, 1))
	for tile: Vector2 in tiles:
		assert_false(GroundStrike.hits(tile, Barbara.TILE_RADIUS, safe), "the safe column is clear")
	var unsafe := Vector2(Barbara.column_x(center, 2) + 10.0, Barbara.row_y(center, 2) - 8.0)
	var covered := false
	for tile: Vector2 in tiles:
		covered = covered or GroundStrike.hits(tile, Barbara.TILE_RADIUS, unsafe)
	assert_true(covered, "standing between tiles of another column is no escape")


func test_barbara_alternates_her_two_attacks() -> void:
	assert_eq(Barbara.choose_attack(Barbara.Attack.BINGO, 0.1), Barbara.Attack.CAGE)
	assert_eq(Barbara.choose_attack(Barbara.Attack.CAGE, 0.9), Barbara.Attack.BINGO)


func test_the_ball_cage_fans_five_balls_over_fifty_degrees() -> void:
	var directions := BossMoves.fan_directions(Vector2.RIGHT, Barbara.BALLS, Barbara.BALL_SPREAD)
	assert_eq(directions.size(), 5)
	assert_true(directions[2].is_equal_approx(Vector2.RIGHT))
	assert_near(rad_to_deg(directions[4].angle() - directions[0].angle()), 50.0)


func test_barbara_ends_with_five_hundred_health_and_wakes_residents() -> void:
	var def := _load("activities_coordinator")
	assert_true(def.is_boss)
	assert_true(absf(def.max_hp * SHORES_HEALTH - 500.0) < 0.5, str(def.max_hp * SHORES_HEALTH))
	assert_eq(def.pension_drop, 8)
	assert_near(def.speed, 70.0)
	assert_true(def.summon != null and not def.summon.is_boss)


# Played after the first floor, she was too gentle: about a quarter less rest, and a fan of at least four.
func test_barbara_rests_less_and_fans_at_least_four_balls() -> void:
	assert_near(Barbara.COOLDOWN, 0.825)
	assert_true(Barbara.BALLS >= 4)


# --- Matron Mercy ---

func test_lights_out_never_comes_within_fourteen_seconds_of_the_last() -> void:
	for i in 40:
		var roll := i / 40.0
		assert_true(Matron.choose_attack(false, SEDATIVE, 13.9, 0, roll) != LIGHTS_OUT, str(roll))
	var seen := false
	for i in 40:
		seen = seen or Matron.choose_attack(false, SEDATIVE, 14.0, 3, i / 40.0) == LIGHTS_OUT
	assert_true(seen, "once fourteen seconds have passed it can come")


func test_visiting_hours_never_comes_with_three_orderlies_in() -> void:
	for i in 40:
		assert_true(Matron.choose_attack(false, GURNEY, 0.0, 3, i / 40.0) != VISITING)
	var seen := false
	for i in 40:
		seen = seen or Matron.choose_attack(false, GURNEY, 0.0, 2, i / 40.0) == VISITING
	assert_true(seen)


# Played after the first floor, she was easier than the Regional Reaper, so she was made harder.
func test_matron_was_made_harder() -> void:
	assert_eq(Matron.SYRINGES, 5)
	assert_near(rad_to_deg(Matron.SYRINGE_SPREAD), 50.0)
	assert_near(Matron.BASE_COOLDOWN, 0.8)
	assert_near(Matron.PHASE_TWO_COOLDOWN, 0.6)
	assert_near(Matron.GURNEY_SPEED, 460.0)
	assert_eq(Matron.MAX_VISITORS, 3)
	assert_near(Matron.LIGHTS_OUT_EVERY, 14.0)


func test_a_second_phase_volley_is_two_fans() -> void:
	assert_eq(Matron.fans_for(false), 1)
	assert_eq(Matron.fans_for(true), 2)


func test_a_wide_fan_still_leaves_room_between_syringes() -> void:
	var directions := BossMoves.fan_directions(Vector2.RIGHT, Matron.SYRINGES, Matron.SYRINGE_SPREAD)
	assert_eq(directions.size(), 5)
	assert_true(directions[2].is_equal_approx(Vector2.RIGHT), "the middle one flies down the warned lane")
	# Where the warned lane ends, two darts are further apart than either one reaches.
	var gap := Matron.SEDATIVE_LANE * directions[0].angle_to(directions[1])
	assert_true(gap >= Projectile.HIT_RADIUS * 2.0, str(gap))


func test_she_never_repeats_an_attack_and_never_charges_from_up_close() -> void:
	for i in 40:
		var roll := i / 40.0
		assert_true(Matron.choose_attack(false, GURNEY, 30.0, 0, roll) != GURNEY)
		assert_true(Matron.choose_attack(true, SEDATIVE, 30.0, 0, roll) != GURNEY)


func test_a_gurney_charge_stops_before_walls() -> void:
	var open := func(at: Vector2) -> bool: return at.x < 300.0
	var end := Matron.charge_end(Vector2(100, 50), Vector2.RIGHT, Matron.GURNEY_LENGTH, open)
	assert_true(end.x < 300.0 and end.x > 250.0, "pulls up short of the wall, %f" % end.x)
	var free := Matron.charge_end(Vector2(0, 50), Vector2.RIGHT, Matron.GURNEY_LENGTH, func(_at: Vector2) -> bool: return true)
	assert_near(free.x, Matron.GURNEY_LENGTH, "a clear run goes its whole length")
	var stuck := Matron.charge_end(Vector2(290, 50), Vector2.RIGHT, Matron.GURNEY_LENGTH, open)
	assert_near(stuck.x, 290.0, "against a wall she goes nowhere")


func test_only_the_second_phase_chains_the_gurney_into_a_volley() -> void:
	assert_eq(Matron.followup(GURNEY, true), SEDATIVE)
	assert_eq(Matron.followup(GURNEY, false), Matron.Attack.NONE)
	for attack in [SEDATIVE, LIGHTS_OUT, VISITING]:
		assert_eq(Matron.followup(attack, true), Matron.Attack.NONE)


func test_the_second_phase_is_quicker_and_still_readable() -> void:
	for attack in [SEDATIVE, GURNEY, LIGHTS_OUT, VISITING]:
		assert_near(Matron.windup_for(attack, true), Matron.windup_for(attack, false) * 0.8)
		assert_true(Matron.windup_for(attack, true) * PlayerStats.BASE_WARNING >= 0.2, str(attack))
	assert_true(Matron.cooldown_for(true) < Matron.cooldown_for(false))
	assert_true(Matron.is_phase_two(50.0, 100.0) and not Matron.is_phase_two(51.0, 100.0))


func test_the_gurney_is_her_two_pill_attack() -> void:
	assert_eq(Enemy.HEAVY_DAMAGE, 2)
	assert_near(Matron.GURNEY_WINDUP, 0.9)
	assert_near(Matron.GURNEY_LENGTH, 420.0)


func test_lights_out_warns_then_goes_dark_then_lifts() -> void:
	assert_near(LightsOut.shade_at(0.0, 1.0, 4.0, LightsOut.DARK), 0.0)
	var warning := LightsOut.shade_at(0.9, 1.0, 4.0, LightsOut.DARK)
	assert_true(warning > 0.0 and warning < LightsOut.DARK, "the room dims during the warning")
	assert_near(LightsOut.shade_at(1.0, 1.0, 4.0, LightsOut.DARK), LightsOut.DARK)
	assert_near(LightsOut.shade_at(4.9, 1.0, 4.0, LightsOut.DARK), LightsOut.DARK)
	assert_near(LightsOut.shade_at(5.0 + LightsOut.FADE_OUT, 1.0, 4.0, LightsOut.DARK), 0.0)
	assert_near(LightsOut.DARK, 0.85, "the room drops to 15%")
	assert_near(LightsOut.LIGHT_RADIUS, 70.0)


func test_matron_ends_with_fifteen_hundred_health_and_calls_orderlies() -> void:
	var def := _load("matron_mercy")
	assert_true(def.is_boss)
	assert_true(absf(def.max_hp * SHORES_HEALTH - 1500.0) < 0.5, str(def.max_hp * SHORES_HEALTH))
	assert_eq(def.pension_drop, 16)
	assert_near(def.speed, 80.0)
	assert_eq(def.summon.id, "orderly")
