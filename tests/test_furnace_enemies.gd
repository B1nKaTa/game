extends TestCase


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


func _room(changes: Dictionary) -> RoomLayout:
	var rows := ["#".repeat(20)]
	for y in range(1, 10):
		rows.append("#" + ".".repeat(18) + "#")
	rows.append("#".repeat(20))
	for cell: Vector2i in changes:
		var row: String = rows[cell.y]
		rows[cell.y] = row.substr(0, cell.x) + changes[cell] + row.substr(cell.x + 1)
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_COMBAT
	layout.rows = PackedStringArray(rows)
	return layout


func _only(def: EnemyDef) -> FloorDef:
	var floor_def := FloorDef.new()
	floor_def.enemies = [def]
	return floor_def


# --- the steam valve ---

func test_the_valve_turns_through_all_four_lanes_clockwise() -> void:
	var lane := Vector2.UP
	var seen := {}
	for i in 4:
		var next := SteamValveBehavior.next_lane(lane)
		assert_true(next.is_equal_approx(lane.rotated(PI / 2.0)), "a quarter turn clockwise from %s" % str(lane))
		seen[next] = true
		lane = next
	assert_eq(seen.size(), 4)
	assert_true(lane.is_equal_approx(Vector2.UP), "and round again")


func test_its_lanes_follow_the_plan() -> void:
	assert_near(SteamValveBehavior.WINDUP, 0.8)
	assert_near(SteamValveBehavior.LANE_LENGTH, 140.0)
	assert_near(SteamValveBehavior.LANE_WIDTH, 18.0)


func test_a_jet_hits_only_inside_its_lane() -> void:
	assert_true(SteamJet.lane_hits(Vector2.ZERO, Vector2.RIGHT, 140.0, 18.0, Vector2(100, 8)))
	assert_false(SteamJet.lane_hits(Vector2.ZERO, Vector2.RIGHT, 140.0, 18.0, Vector2(100, 10)), "beside it")
	assert_false(SteamJet.lane_hits(Vector2.ZERO, Vector2.RIGHT, 140.0, 18.0, Vector2(150, 0)), "past its end")
	assert_false(SteamJet.lane_hits(Vector2.ZERO, Vector2.RIGHT, 140.0, 18.0, Vector2(-5, 0)), "behind it")
	assert_true(SteamJet.lane_hits(Vector2(10, 10), Vector2.UP, 50.0, 18.0, Vector2(12, -30)))


func test_the_valve_is_fixed_weak_and_counts_toward_the_room() -> void:
	var def := _load("steam_valve")
	assert_true(def.wall_mounted)
	assert_near(def.speed, 0.0)
	assert_true(absf(def.max_hp - _load("notary_public").max_hp) <= 4.0, "about a Notary Public")
	assert_eq(def.pension_drop, 1)
	assert_false(def.is_boss)


func test_a_valve_starts_beside_a_wall() -> void:
	var layout := _room({Vector2i(9, 5): "E", Vector2i(13, 3): "E"})
	for seed_value in 20:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var entries := EnemyPlan.plan(layout, _only(_load("steam_valve")), 0, rng)
		assert_eq(entries.size(), 2)
		var cells := {}
		for entry in entries:
			var cell: Vector2i = entry["cell"]
			assert_true(EnemyPlan.beside_a_wall(layout, cell), "at %s" % str(cell))
			assert_eq(layout.symbol_at(cell), RoomLayout.SYMBOL_FLOOR)
			for side in RoomLayout.SIDES:
				assert_true(Vector2(cell - layout.door_cell(side)).length() >= RoomLayout.MIN_FIGHTER_DOOR_DISTANCE, "clear of the doors")
			cells[cell] = true
		assert_eq(cells.size(), 2, "never two on one cell")


func test_other_enemies_keep_their_cells() -> void:
	var layout := _room({Vector2i(9, 5): "E", Vector2i(13, 3): "E"})
	var entries := EnemyPlan.plan(layout, _only(_load("stoker")), 0, RandomNumberGenerator.new())
	var cells: Array[Vector2i] = []
	for entry in entries:
		cells.append(entry["cell"])
	assert_true(cells.has(Vector2i(9, 5)) and cells.has(Vector2i(13, 3)), str(cells))



# --- the stoker ---

func test_a_stoker_keeps_its_distance() -> void:
	assert_eq(StokerBehavior.step(40.0), StokerBehavior.BACK_OFF)
	assert_eq(StokerBehavior.step(StokerBehavior.TOO_CLOSE - 1.0), StokerBehavior.BACK_OFF)
	assert_eq(StokerBehavior.step(130.0), StokerBehavior.HOLD)
	assert_eq(StokerBehavior.step(StokerBehavior.TOO_FAR + 1.0), StokerBehavior.CLOSE_IN)


func test_its_coal_follows_the_plan() -> void:
	assert_near(StokerBehavior.COAL_WARNING, 0.8)
	assert_near(StokerBehavior.COAL_RADIUS, 22.0)
	assert_near(StokerBehavior.BURN_TIME, 1.8)


func test_a_coal_mark_leaves_time_to_walk_out() -> void:
	var walk := PlayerStats.BASE_SPEED * (StokerBehavior.COAL_WARNING - 0.2)
	assert_true(walk > StokerBehavior.COAL_RADIUS * 2.0, "he can cross the whole mark, %f" % walk)


func test_a_thrown_coal_marks_the_spot_and_then_burns() -> void:
	var stoker := Enemy.new()
	stoker.setup(_load("stoker"), null, 0.5)
	var strike := GroundStrike.new()
	strike.setup(stoker, StokerBehavior.COAL_RADIUS, StokerBehavior.COAL_WARNING, 0.0, 0.0, -1, StokerBehavior.BURN_TIME)
	strike.throw_from(Vector2(100, 0))
	assert_false(strike.advance(StokerBehavior.COAL_WARNING - 0.1))
	assert_true(strike.advance(0.2))
	assert_true(strike.is_burning())
	strike.free()
	stoker.free()


# --- the soot ghost ---

func test_smoke_always_leads_back_out() -> void:
	assert_eq(SootGhostBehavior.next_state(SootGhostBehavior.State.SMOKE), SootGhostBehavior.State.RISING)
	assert_eq(SootGhostBehavior.next_state(SootGhostBehavior.State.RISING), SootGhostBehavior.State.OPEN)
	assert_eq(SootGhostBehavior.next_state(SootGhostBehavior.State.OPEN), SootGhostBehavior.State.SMOKE)


func test_its_timing_follows_the_plan() -> void:
	assert_near(SootGhostBehavior.SMOKE_TIME, 1.5)
	assert_near(SootGhostBehavior.RISE_WINDUP, 0.85)
	assert_near(SootGhostBehavior.SWIPE_RANGE, 28.0)
	assert_near(SootGhostBehavior.OPEN_TIME, 2.5)
	assert_eq(_load("soot_ghost").max_per_room, 3)
	assert_eq(_load("soot_ghost").hidden_look, "smoke")


func test_it_comes_out_beside_him_inside_its_swipe() -> void:
	var feet := Vector2(200, 200)
	for side in [-1.0, 1.0]:
		var spot := SootGhostBehavior.beside(feet, side)
		assert_true(spot.distance_to(feet) > 10.0, "not right under him")
		assert_true(SootGhostBehavior.swipe_hits(spot, feet), "standing still is a hit")
	assert_false(SootGhostBehavior.swipe_hits(feet, feet + Vector2(30, 0)))


func test_the_warning_beside_him_leaves_time_to_step_out() -> void:
	var walk := PlayerStats.BASE_SPEED * (SootGhostBehavior.RISE_WINDUP - 0.25)
	var needed := SootGhostBehavior.SWIPE_RANGE + SootGhostBehavior.BESIDE
	assert_true(walk > needed, "%f against %f" % [walk, needed])


# Mirrors the Plot Holder's rule: nothing reaches it in the smoke, but a room can still be cleared.
func test_in_the_smoke_it_takes_no_ordinary_damage_but_can_still_be_cleared() -> void:
	var ghost := Enemy.new()
	ghost.setup(_load("soot_ghost"), null, 0.5)
	ghost.set_submerged(true)
	var hp := ghost.hp
	ghost.take_damage(50.0, Vector2.ZERO)
	assert_near(ghost.hp, hp)
	assert_false(ghost.take_strike(50.0, Vector2.ZERO, Vector2.RIGHT))
	ghost.take_damage(INF, Vector2.ZERO)
	assert_true(ghost.is_dead())
	ghost.free()


func test_a_ghost_goes_round_the_whole_cycle_on_its_own_timers() -> void:
	var behavior := SootGhostBehavior.new()
	var total := SootGhostBehavior.FIRST_SMOKE + SootGhostBehavior.RISE_WINDUP + SootGhostBehavior.OPEN_TIME + SootGhostBehavior.SMOKE_TIME
	assert_true(total < 6.0, "it is out at least once every %f seconds" % total)
	assert_eq(behavior.state(), SootGhostBehavior.State.SMOKE)


# --- the returning enemies ---

func test_returning_enemies_keep_their_numbers_and_take_the_floors_colors() -> void:
	for id in ["intern_reaper", "burnt_out_auditor"]:
		var mine := _load("furnace_" + id)
		var theirs := _load(id)
		assert_near(mine.max_hp, theirs.max_hp, id)
		assert_near(mine.speed, theirs.speed, id)
		assert_eq(mine.pension_drop, theirs.pension_drop, id)
		assert_eq(mine.behavior_script, theirs.behavior_script, id)
		assert_eq(mine.display_name, theirs.display_name, id)
		assert_eq(mine.max_per_room, theirs.max_per_room, id)
		assert_true(mine.id != theirs.id and mine.color != theirs.color, id)


# --- the numbers ---

func test_new_enemies_match_the_first_floor_role_they_fill() -> void:
	var pairs := {"stoker": "filing_clerk", "steam_valve": "notary_public", "soot_ghost": "plot_holder"}
	for id: String in pairs:
		var def := _load(id)
		var theirs := _load(pairs[id])
		assert_false(def.is_boss, id)
		assert_false(def.display_name.is_empty(), id)
		assert_eq(def.pension_drop, theirs.pension_drop, id)
		assert_true(absf(def.max_hp - theirs.max_hp) <= 4.0, id)
		assert_true(def.behavior_script.new() is EnemyBehavior, id)
