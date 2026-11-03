extends TestCase

const Klaus := preload("res://scripts/actors/behaviors/foreman_behavior.gd")
# The Furnace Works scales health by this, and its bosses hold their final health divided by it.
const FURNACE_HEALTH := 1.4


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


# --- Foreman Klaus ---

func test_a_shockwave_hurts_in_its_band_and_not_in_its_hollow() -> void:
	var center := Vector2(100, 100)
	assert_true(Klaus.shockwave_hits(center, 90.0, 14.0, center + Vector2(90, 0)), "on the edge")
	assert_true(Klaus.shockwave_hits(center, 90.0, 14.0, center + Vector2(0, -96)), "inside the band")
	assert_false(Klaus.shockwave_hits(center, 90.0, 14.0, center + Vector2(40, 0)), "in the hollow")
	assert_false(Klaus.shockwave_hits(center, 90.0, 14.0, center + Vector2(120, 0)), "not reached yet")


func test_the_ring_grows_from_the_slam_to_its_reach() -> void:
	assert_near(Shockwave.radius_at(Klaus.RING_FROM, Klaus.RING_TO, Klaus.RING_TIME, 0.0), 60.0)
	assert_near(Shockwave.radius_at(Klaus.RING_FROM, Klaus.RING_TO, Klaus.RING_TIME, 0.3), 100.0)
	assert_near(Shockwave.radius_at(Klaus.RING_FROM, Klaus.RING_TO, Klaus.RING_TIME, 9.0), 140.0)
	assert_near(Klaus.SLAM_WINDUP, 0.7)
	assert_near(Klaus.RING_TIME, 0.6)


func test_steam_lines_leave_one_lane_clear_inside_the_room() -> void:
	var room := Klaus.room_rect(Vector2i(20, 11))
	for direction in [Vector2.RIGHT, Vector2.DOWN]:
		for gap in Klaus.LANES:
			for center in [room.get_center(), room.position + Vector2(10, 10), room.end - Vector2(10, 10)]:
				var lanes := Klaus.steam_lanes(room, direction, gap, center)
				assert_eq(lanes.size(), 3, "three lanes blow")
				for lane in lanes:
					assert_true(room.grow(0.5).encloses(lane), "%s inside %s" % [str(lane), str(room)])
				for i in lanes.size():
					for j in range(i + 1, lanes.size()):
						assert_false(lanes[i].intersects(lanes[j]), "lanes lie side by side")


func test_the_clear_lane_really_is_clear_and_runs_beside_the_others() -> void:
	var room := Klaus.room_rect(Vector2i(20, 11))
	var center := room.get_center()
	for gap in Klaus.LANES:
		var lanes := Klaus.steam_lanes(room, Vector2.RIGHT, gap, center)
		var all := Klaus.steam_lanes(room, Vector2.RIGHT, -1, center)
		assert_eq(all.size(), 4)
		var clear: Rect2 = all[gap]
		for lane in lanes:
			assert_false(lane.has_point(clear.get_center()), "the gap is not under any jet")
		assert_true(clear.size.y >= Player.FEET_BOX_SIZE.y * 2.0, "he fits in it")


func test_he_reaches_the_clear_lane_in_time() -> void:
	# From the middle of the band, the furthest gap is a lane and a half away.
	var walk := PlayerStats.BASE_SPEED * (Klaus.STEAM_WARNING - 0.3)
	assert_true(walk >= Klaus.LANE_WIDTH * 1.5, "%f" % walk)


func test_the_gap_moves_each_time() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var last := 2
	var seen := {}
	for i in 40:
		var next := Klaus.next_gap(last, rng)
		assert_true(next != last and next >= 0 and next < Klaus.LANES)
		seen[next] = true
		last = next
	assert_eq(seen.size(), Klaus.LANES)


func test_he_slams_within_the_rings_reach_and_steams_further_off() -> void:
	assert_eq(Klaus.choose_attack(50.0, Klaus.Attack.NONE), Klaus.Attack.SLAM)
	assert_eq(Klaus.choose_attack(50.0, Klaus.Attack.SLAM), Klaus.Attack.STEAM, "never two slams running")
	assert_eq(Klaus.choose_attack(Klaus.RING_TO + 10.0, Klaus.Attack.NONE), Klaus.Attack.STEAM)
	assert_eq(Klaus.choose_attack(Klaus.RING_TO + 10.0, Klaus.Attack.STEAM), Klaus.Attack.STEAM)


func test_klaus_ends_with_five_hundred_health_and_calls_stokers() -> void:
	var def := _load("foreman_klaus")
	assert_true(def.is_boss)
	assert_true(absf(def.max_hp * FURNACE_HEALTH - 500.0) < 0.5, str(def.max_hp * FURNACE_HEALTH))
	assert_eq(def.pension_drop, 8)
	assert_near(def.speed, 75.0)
	assert_eq(def.summon.id, "stoker")
	assert_eq(Klaus.SUMMON_COUNT, 2)
	assert_near(Klaus.SUMMON_EVERY, 12.0)


func test_klaus_rests_no_longer_than_barbara() -> void:
	assert_true(Klaus.COOLDOWN <= ActivitiesCoordinatorBehavior.COOLDOWN)


# --- Old Smokey ---

func _open_room(width: int, height: int) -> Dictionary:
	var open := {}
	for y in range(1, height - 1):
		for x in range(1, width - 1):
			open[Vector2i(x, y)] = true
	return open


func _safe_way_exists(open: Dictionary, flaring: Array[Vector2i], from: Vector2i) -> bool:
	var seen := {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		if maxi(absi(cell.x - from.x), absi(cell.y - from.y)) >= ChiefStokerBehavior.SAFE_REACH:
			return true
		for side in RoomLayout.SIDES:
			var next: Vector2i = cell + side
			if open.has(next) and not seen.has(next) and not flaring.has(next):
				seen[next] = true
				queue.append(next)
	return false


func test_a_cone_covers_what_lies_inside_its_angle_and_reach() -> void:
	var origin := Vector2(100, 100)
	assert_true(ChiefStokerBehavior.in_cone(origin, Vector2.RIGHT, 60.0, 130.0, origin + Vector2(100, 0)))
	assert_true(ChiefStokerBehavior.in_cone(origin, Vector2.RIGHT, 60.0, 130.0, origin + Vector2.from_angle(deg_to_rad(28.0)) * 120.0))
	assert_false(ChiefStokerBehavior.in_cone(origin, Vector2.RIGHT, 60.0, 130.0, origin + Vector2.from_angle(deg_to_rad(35.0)) * 80.0), "outside the angle")
	assert_false(ChiefStokerBehavior.in_cone(origin, Vector2.RIGHT, 60.0, 130.0, origin + Vector2(135, 0)), "past its reach")
	assert_false(ChiefStokerBehavior.in_cone(origin, Vector2.RIGHT, 60.0, 130.0, origin + Vector2(-40, 0)), "behind him")


func test_the_breath_follows_the_plan_and_costs_two_pills() -> void:
	assert_near(ChiefStokerBehavior.BREATH_WINDUP, 0.9)
	assert_near(ChiefStokerBehavior.BREATH_ANGLE, 60.0)
	assert_near(ChiefStokerBehavior.BREATH_LENGTH, 130.0)
	assert_eq(Enemy.HEAVY_DAMAGE, 2)


func test_the_vent_grid_always_leaves_a_safe_way_and_flares_at_least_half() -> void:
	var open := _open_room(16, 11)
	var vents: Array[Vector2i] = []
	for cell: Vector2i in open:
		vents.append(cell)
	for seed_value in 200:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var from := Vector2i(rng.randi_range(1, 14), rng.randi_range(1, 9))
		var flaring := ChiefStokerBehavior.safe_pattern(vents, open, from, rng)
		assert_false(flaring.has(from), "never under him, seed %d" % seed_value)
		assert_true(_safe_way_exists(open, flaring, from), "seed %d" % seed_value)
		assert_true(flaring.size() * 2 >= vents.size(), "seed %d flares %d of %d" % [seed_value, flaring.size(), vents.size()])


func test_the_safe_way_changes_from_time_to_time() -> void:
	var open := _open_room(16, 11)
	var vents: Array[Vector2i] = []
	for cell: Vector2i in open:
		vents.append(cell)
	var patterns := {}
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in 10:
		patterns[str(ChiefStokerBehavior.safe_pattern(vents, open, Vector2i(8, 5), rng))] = true
	assert_true(patterns.size() > 3, "%d different ways" % patterns.size())


func test_the_second_phase_flares_faster_and_burns_longer() -> void:
	assert_near(ChiefStokerBehavior.vent_period_scale(false), 1.0)
	assert_near(ChiefStokerBehavior.vent_period_scale(true), 0.75)
	assert_near(ChiefStokerBehavior.burn_scale(false), 1.0)
	assert_near(ChiefStokerBehavior.burn_scale(true), 1.5)
	assert_true(ChiefStokerBehavior.cooldown_for(true) < ChiefStokerBehavior.cooldown_for(false))
	assert_true(ChiefStokerBehavior.windup_for(ChiefStokerBehavior.Attack.BREATH, true) < ChiefStokerBehavior.BREATH_WINDUP)


func test_coal_rain_lands_three_near_him_and_two_in_the_room() -> void:
	var room := ForemanBehavior.room_rect(Vector2i(30, 17))
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var feet := Vector2(300, 250)
	for i in 30:
		var spots := ChiefStokerBehavior.rain_spots(feet, room, rng)
		assert_eq(spots.size(), 5)
		for n in 3:
			assert_true(spots[n].distance_to(feet) <= ChiefStokerBehavior.RAIN_SPREAD + 0.1)
		for n in range(3, 5):
			assert_true(room.has_point(spots[n]))
	assert_near(ChiefStokerBehavior.RAIN_WARNING, 0.9)
	assert_near(ChiefStokerBehavior.RAIN_BURN, 3.0)


func test_the_bellows_pull_toward_him_and_cost_nothing() -> void:
	assert_near(ChiefStokerBehavior.BELLOWS_WINDUP, 0.8)
	assert_near(ChiefStokerBehavior.BELLOWS_PULL, 260.0)
	assert_near(ChiefStokerBehavior.BELLOWS_TIME, 0.5)
	assert_eq(ChiefStokerBehavior.followup(ChiefStokerBehavior.Attack.BELLOWS, true), ChiefStokerBehavior.Attack.BREATH, "in the second phase, into the fire")
	assert_eq(ChiefStokerBehavior.followup(ChiefStokerBehavior.Attack.BELLOWS, false), ChiefStokerBehavior.Attack.NONE)
	assert_eq(ChiefStokerBehavior.followup(ChiefStokerBehavior.Attack.GRID, false), ChiefStokerBehavior.Attack.RAIN, "coal makes him move along the safe way")


func test_he_picks_only_what_fits_and_never_the_same_twice() -> void:
	for roll in [0.0, 0.3, 0.6, 0.99]:
		var near := ChiefStokerBehavior.choose_attack(60.0, ChiefStokerBehavior.Attack.NONE, false, roll)
		assert_true(near in [ChiefStokerBehavior.Attack.RAIN, ChiefStokerBehavior.Attack.BREATH], "no bellows up close, no grid without vents")
		var far := ChiefStokerBehavior.choose_attack(300.0, ChiefStokerBehavior.Attack.RAIN, true, roll)
		assert_true(far in [ChiefStokerBehavior.Attack.GRID, ChiefStokerBehavior.Attack.BELLOWS], "no breath from afar, no rain twice")


func test_old_smokey_is_at_least_as_tough_as_matron_mercy() -> void:
	var def := _load("old_smokey")
	var matron := _load("matron_mercy")
	assert_true(def.is_boss)
	assert_true(def.max_hp * FURNACE_HEALTH >= matron.max_hp * 1.4 - 0.5, str(def.max_hp * FURNACE_HEALTH))
	assert_eq(def.pension_drop, 16)
	assert_near(def.speed, 70.0)
	assert_true(ChiefStokerBehavior.BASE_COOLDOWN <= MatronBehavior.BASE_COOLDOWN)
	assert_true(ChiefStokerBehavior.PHASE_TWO_COOLDOWN <= MatronBehavior.PHASE_TWO_COOLDOWN)


func test_a_gust_pushes_him_for_its_time() -> void:
	var player := Player.new()
	assert_false(player.is_pushed())
	player.push(Vector2(-260, 0), 0.5)
	assert_true(player.is_pushed())
	player.free()
