extends TestCase

# The Mall scales health by this, and its bosses hold their final health divided by it.
const MALL_HEALTH := 1.8
# The second floors scale by this, so their bosses' final health is their .tres health times it.
const FLOOR_TWO_HEALTH := 1.4


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


func _doors(cells: Vector2i) -> Array[Vector2i]:
	return [Vector2i(cells.x / 2, 1), Vector2i(cells.x / 2, cells.y - 2), Vector2i(1, cells.y / 2), Vector2i(cells.x - 2, cells.y / 2)]


func _near_a_door(cell: Vector2i, cells: Vector2i) -> bool:
	for door in _doors(cells):
		if absi(cell.x - door.x) <= 1 and absi(cell.y - door.y) <= 1:
			return true
	return false


# --- the Mall Santa ---

func test_the_sleigh_run_costs_three_pills_and_its_warning_shows_whole() -> void:
	assert_eq(MallSantaBehavior.SLEIGH_DAMAGE, Enemy.HEAVIEST_DAMAGE)
	assert_eq(MallSantaBehavior.SLEIGH_DAMAGE, 3)
	assert_true(MallSantaBehavior.SLEIGH_SHOWN_WHOLE)
	assert_near(MallSantaBehavior.SLEIGH_WINDUP, 1.2)
	for phase_two in [false, true]:
		assert_near(MallSantaBehavior.windup_for(MallSantaBehavior.Attack.SLEIGH, phase_two), 1.2, "the second phase never shortens it")
	var santa := Enemy.new()
	santa.setup(_load("mall_santa"), null, 0.25)
	var telegraph := Telegraph.new()
	telegraph.start(MallSantaBehavior.SLEIGH_WINDUP)
	santa.set_warning(telegraph, MallSantaBehavior.SLEIGH_HIT_RANGE, MallSantaBehavior.SLEIGH_SHOWN_WHOLE)
	santa.set_warning_lane(Vector2.RIGHT, MallSantaBehavior.SLEIGH_LENGTH, MallSantaBehavior.SLEIGH_LANE_WIDTH)
	santa.mark_lane_heaviest()
	assert_near(santa._warning_share(), 1.0, "whatever his warning stat")
	assert_true(telegraph.shows_warning(santa._warning_share()), "it shows from the first instant")
	assert_true(santa.lane_is_heaviest(), "with a second outer outline")
	santa.clear_warning()
	assert_false(santa.lane_is_heaviest(), "which goes with the warning")
	santa.free()


func test_he_can_step_out_of_the_sleighs_lane_in_time() -> void:
	var walk := PlayerStats.BASE_SPEED * (MallSantaBehavior.SLEIGH_WINDUP - 0.3)
	assert_true(walk > MallSantaBehavior.SLEIGH_LANE_WIDTH, "%f" % walk)


func test_never_more_than_three_elves() -> void:
	for alive in 8:
		var calls := MallSantaBehavior.elves_to_call(alive)
		assert_true(calls >= 0, "%d alive" % alive)
		assert_true(alive + calls <= maxi(MallSantaBehavior.MAX_ELVES, alive), "%d alive, %d called" % [alive, calls])
	assert_eq(MallSantaBehavior.elves_to_call(0), 3)
	assert_eq(MallSantaBehavior.elves_to_call(2), 1)
	assert_eq(MallSantaBehavior.MAX_ELVES, 3)


func test_his_elves_are_fast_melee_helpers_who_pay_nothing() -> void:
	var santa := _load("mall_santa")
	var elf := santa.summon
	assert_eq(elf.id, "mall_elf")
	assert_eq(elf.behavior_script, _load("intern_reaper").behavior_script, "the melee behavior")
	assert_near(elf.speed, 140.0)
	var body := Enemy.new()
	body.setup(elf, null, 0.5)
	body.is_summon = true
	body.apply_floor(MALL_HEALTH, 2.0)
	assert_eq(body.coin_value(), 0)
	body.free()


func test_only_the_second_phase_calls_elves() -> void:
	assert_false(MallSantaBehavior.calls_elves(false))
	assert_true(MallSantaBehavior.calls_elves(true))
	assert_true(MallSantaBehavior.is_phase_two(800.0, 1700.0))
	assert_false(MallSantaBehavior.is_phase_two(900.0, 1700.0))


func test_the_ring_closes_from_120_to_20() -> void:
	assert_near(ClosingRing.closing_radius(0.0), 120.0)
	assert_near(ClosingRing.closing_radius(ClosingRing.CLOSE_TIME), 20.0, "it reaches 20 at the end")
	assert_near(ClosingRing.closing_radius(ClosingRing.CLOSE_TIME + 1.0), 20.0, "and stays shut")
	assert_near(ClosingRing.CLOSE_TIME, 1.4)
	var last := INF
	for step in 15:
		var radius := ClosingRing.closing_radius(step * 0.1)
		assert_true(radius < last, "it only closes")
		last = radius


func test_the_ring_hurts_in_its_band_and_inside_when_it_shuts() -> void:
	var center := Vector2(200, 200)
	assert_true(ClosingRing.hits(center, 80.0, ClosingRing.WIDTH, center + Vector2(80, 0), false), "in the band")
	assert_false(ClosingRing.hits(center, 80.0, ClosingRing.WIDTH, center + Vector2(40, 0), false), "inside but not yet reached")
	assert_false(ClosingRing.hits(center, 80.0, ClosingRing.WIDTH, center + Vector2(120, 0), false), "outside it")
	assert_true(ClosingRing.hits(center, 20.0, ClosingRing.WIDTH, center + Vector2(5, 0), true), "still inside when it shuts")
	assert_false(ClosingRing.hits(center, 20.0, ClosingRing.WIDTH, center + Vector2(60, 0), true), "out before it shut")


func test_a_ring_is_beaten_by_a_dodge_through_its_band() -> void:
	var empty: Array[UpgradeDef] = []
	var run := RunState.new(empty, {})
	var player := Player.new()
	player.setup(run)
	var pills := run.health.pills
	player._dodge.try_start(0.0)
	assert_false(player.take_hit(MallSantaBehavior.RING_DAMAGE), "a dodge passes through")
	assert_eq(run.health.pills, pills)
	player.free()


func test_the_present_drop_follows_the_plan() -> void:
	assert_eq(MallSantaBehavior.PRESENTS, 4)
	assert_near(PresentDrop.WARNING, 0.9)
	assert_eq(PresentDrop.SHOTS, 6)
	var directions := PresentDrop.shot_directions(0.3)
	assert_eq(directions.size(), 6)
	for i in 6:
		assert_near(rad_to_deg(absf(directions[i].angle_to(directions[(i + 1) % 6]))), 60.0, "a ring of six")
	var walk := PlayerStats.BASE_SPEED * (PresentDrop.WARNING - 0.2)
	assert_true(walk > PresentDrop.RADIUS * 2.0)


func test_presents_land_near_him_and_apart() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var room := ForemanBehavior.room_rect(Vector2i(20, 11))
	for i in 100:
		var feet := Vector2(rng.randf_range(room.position.x, room.end.x), rng.randf_range(room.position.y, room.end.y))
		var spots := MallSantaBehavior.present_spots(feet, rng, room)
		assert_eq(spots.size(), MallSantaBehavior.PRESENTS)
		assert_true(spots[0].distance_to(feet) < 0.01, "one right on him")
		for a in spots.size():
			assert_true(room.grow(0.01).has_point(spots[a]), "inside the room")
			assert_true(spots[a].distance_to(feet) <= MallSantaBehavior.PRESENT_REACH + 0.01, "near him")
			for b in range(a + 1, spots.size()):
				assert_true(spots[a].distance_to(spots[b]) >= PresentDrop.RADIUS * 2.0 - 0.01, "apart")


func test_phase_two_chains_the_sleigh_into_a_present_drop() -> void:
	var sleigh := MallSantaBehavior.Attack.SLEIGH
	var presents := MallSantaBehavior.Attack.PRESENTS
	assert_eq(MallSantaBehavior.followup(sleigh, true), presents)
	assert_eq(MallSantaBehavior.followup(sleigh, false), MallSantaBehavior.Attack.NONE)
	for attack in [presents, MallSantaBehavior.Attack.RING, MallSantaBehavior.Attack.CONVEYOR]:
		assert_eq(MallSantaBehavior.followup(attack, true), MallSantaBehavior.Attack.NONE)
	assert_true(MallSantaBehavior.windup_for(MallSantaBehavior.Attack.RING, true) < MallSantaBehavior.windup_for(MallSantaBehavior.Attack.RING, false), "his other windups quicken")


func test_without_strips_there_is_no_conveyor_control() -> void:
	for roll in [0.0, 0.3, 0.6, 0.99]:
		var attack := MallSantaBehavior.choose_attack(MallSantaBehavior.Attack.NONE, false, roll)
		assert_true(attack != MallSantaBehavior.Attack.CONVEYOR)
	var seen := {}
	for i in 100:
		seen[MallSantaBehavior.choose_attack(MallSantaBehavior.Attack.NONE, true, i / 100.0)] = true
	assert_true(seen.has(MallSantaBehavior.Attack.CONVEYOR), "with strips it comes")
	assert_eq(seen.size(), 4)


func test_the_mall_santa_is_clearly_harder_than_matron_and_smokey_and_no_tougher_than_mortimer() -> void:
	var def := _load("mall_santa")
	assert_true(def.is_boss)
	assert_true(absf(def.max_hp * MALL_HEALTH - 1650.0) < 0.5, str(def.max_hp * MALL_HEALTH))
	assert_near(def.speed, 80.0)
	assert_eq(def.pension_drop, 16)
	for id in ["matron_mercy", "old_smokey"]:
		assert_true(def.max_hp * MALL_HEALTH >= _load(id).max_hp * FLOOR_TWO_HEALTH * 1.1, id)
	assert_true(def.max_hp <= _load("mortimer_grimsby").max_hp, "no more health than Mortimer, whose attacks are easier to read")
	assert_true(MallSantaBehavior.BASE_COOLDOWN <= FuneralDirectorBehavior.BASE_COOLDOWN)
	assert_true(MallSantaBehavior.PHASE_TWO_COOLDOWN <= FuneralDirectorBehavior.PHASE_TWO_COOLDOWN)
	assert_true(MallSantaBehavior.BASE_COOLDOWN < MatronBehavior.BASE_COOLDOWN)
	assert_true(MallSantaBehavior.BASE_COOLDOWN < ChiefStokerBehavior.BASE_COOLDOWN)
	assert_true(MallSantaBehavior.SLEIGH_DAMAGE > Enemy.HEAVY_DAMAGE)
