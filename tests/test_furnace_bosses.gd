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
