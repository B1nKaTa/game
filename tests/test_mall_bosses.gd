extends TestCase

const Diva := preload("res://scripts/actors/behaviors/fountain_diva_behavior.gd")
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


# --- Gloria ---

func test_the_coin_toss_fans_five_lanes_over_sixty_degrees() -> void:
	assert_eq(Diva.COINS, 5)
	assert_near(rad_to_deg(Diva.COIN_SPREAD), 60.0)
	assert_near(Diva.COIN_WINDUP, 0.7)
	for aim: Vector2 in [Vector2.RIGHT, Vector2.UP, Vector2(1, 1).normalized()]:
		var lanes := Diva.coin_lanes(aim)
		assert_eq(lanes.size(), 5)
		assert_true(lanes[2].is_equal_approx(aim), "the middle lane is aimed at him")
		assert_near(rad_to_deg(absf(lanes[0].angle_to(lanes[4]))), 60.0, "sixty degrees from edge to edge")
		for i in range(1, 5):
			assert_near(rad_to_deg(absf(lanes[i - 1].angle_to(lanes[i]))), 15.0, "evenly spread")


func test_every_coin_lane_shows_on_her_as_she_winds_up() -> void:
	var gloria := Enemy.new()
	gloria.setup(_load("gloria"), null, 0.5)
	var telegraph := Telegraph.new()
	telegraph.start(Diva.COIN_WINDUP)
	gloria.set_warning(telegraph, Diva.WARNING_RADIUS)
	for way in Diva.coin_lanes(Vector2.RIGHT):
		gloria.add_warning_lane(way, Diva.COIN_LANE, Diva.COIN_LANE_WIDTH, false)
	assert_eq(gloria.warning_lane_count(), 5)
	gloria.clear_warning()
	assert_eq(gloria.warning_lane_count(), 0, "and goes with the warning")
	gloria.free()


func test_splash_spots_lie_near_him_on_open_floor_away_from_doors() -> void:
	var cells := Vector2i(20, 11)
	# A pillar of blocked cells in the room, as props would make.
	var is_open := func(spot: Vector2) -> bool:
		var cell := WalkGrid.cell_of(spot)
		return not (cell.x >= 6 and cell.x <= 7 and cell.y >= 3 and cell.y <= 6)
	for seed_value in 200:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var target := Vector2i(rng.randi_range(1, cells.x - 2), rng.randi_range(1, cells.y - 2))
		var spots := Diva.splash_cells(target, Diva.SPLASHES, rng, cells, is_open)
		assert_true(spots.size() >= 1, "seed %d: at least one jet" % seed_value)
		var seen := {}
		for spot in spots:
			assert_false(seen.has(spot), "seed %d: each spot once" % seed_value)
			seen[spot] = true
			assert_true(spot.x >= 1 and spot.y >= 1 and spot.x <= cells.x - 2 and spot.y <= cells.y - 2, "seed %d: off the walls" % seed_value)
			assert_false(_near_a_door(spot, cells), "seed %d: off the doors at %s" % [seed_value, str(spot)])
			assert_true(is_open.call(RoomBackdrop.cell_center(spot)), "seed %d: on open floor" % seed_value)
			assert_true(maxi(absi(spot.x - target.x), absi(spot.y - target.y)) <= Diva.SPLASH_REACH, "seed %d: near him" % seed_value)
		for patch_spot in spots:
			for cell in Diva.splash_patch(patch_spot, cells, is_open):
				assert_true(maxi(absi(cell.x - patch_spot.x), absi(cell.y - patch_spot.y)) <= 1, "a 3 by 3 patch")
				assert_true(cell.x >= 1 and cell.y >= 1 and cell.x <= cells.x - 2 and cell.y <= cells.y - 2, "no wet wall")
				assert_false(_near_a_door(cell, cells), "no wet door")
				assert_true(is_open.call(RoomBackdrop.cell_center(cell)), "no wet prop")


func test_in_an_open_room_all_three_jets_come_and_each_patch_is_whole() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var spots := Diva.splash_cells(Vector2i(6, 4), 3, rng, Vector2i(20, 11))
	assert_eq(spots.size(), 3)
	assert_eq(spots[0], Vector2i(6, 4), "the first jet is right under him")
	assert_eq(Diva.splash_patch(Vector2i(6, 4), Vector2i(20, 11)).size(), 9)
	assert_eq(Diva.splash_patch(Vector2i(1, 1), Vector2i(20, 11)).size(), 4, "a patch in a corner keeps off the walls")


func test_the_splash_follows_the_plan() -> void:
	assert_eq(Diva.SPLASHES, 3)
	assert_near(Diva.SPLASH_WARNING, 0.9)
	assert_near(Diva.WET_TIME, 4.0)
	var walk := PlayerStats.BASE_SPEED * (Diva.SPLASH_WARNING - 0.2)
	assert_true(walk > Diva.SPLASH_RADIUS * 2.0, "time to walk out of a jet")


func test_a_splash_puts_wet_floor_down_for_a_while_then_takes_it_up() -> void:
	var cells: Array[Vector2i] = [Vector2i(3, 3), Vector2i(4, 3)]
	var splash := WetSplash.new()
	splash.setup(cells, Diva.WET_TIME)
	splash._ready()
	assert_eq(splash.wet_floors().size(), 2)
	assert_true(WetFloor.any_covers(splash.wet_floors(), RoomBackdrop.cell_center(Vector2i(3, 3))))
	assert_false(splash.advance(Diva.WET_TIME - 0.1))
	assert_true(splash.advance(0.2), "dried out")
	splash.free()


func test_she_calls_a_line_of_walkers_who_pay_nothing() -> void:
	var def := _load("gloria")
	assert_eq(def.summon.id, "mall_walker")
	for alive in 9:
		var count := Diva.summon_count(alive, Diva.MAX_ENEMIES)
		assert_true(count >= 0 and count <= Diva.SUMMON_COUNT)
		assert_true(alive + count <= maxi(Diva.MAX_ENEMIES, alive))
	assert_eq(Diva.summon_count(1, Diva.MAX_ENEMIES), 3, "a whole line")
	assert_near(Diva.SUMMON_EVERY, 12.0)
	var walker := Enemy.new()
	walker.setup(def.summon, null, 0.5)
	walker.is_summon = true
	walker.apply_floor(MALL_HEALTH, 2.0)
	assert_eq(walker.coin_value(), 0)
	walker.free()


func test_she_alternates_her_two_attacks() -> void:
	assert_eq(Diva.choose_attack(Diva.Attack.COINS, 0.1), Diva.Attack.SPLASH)
	assert_eq(Diva.choose_attack(Diva.Attack.SPLASH, 0.9), Diva.Attack.COINS)


func test_gloria_is_at_least_as_hard_as_barbara_klaus_and_the_reverend() -> void:
	var def := _load("gloria")
	assert_true(def.is_boss)
	assert_true(absf(def.max_hp * MALL_HEALTH - 560.0) < 0.5, str(def.max_hp * MALL_HEALTH))
	assert_near(def.speed, 70.0)
	assert_eq(def.pension_drop, 8)
	for id in ["activities_coordinator", "foreman_klaus"]:
		assert_true(def.max_hp * MALL_HEALTH >= _load(id).max_hp * FLOOR_TWO_HEALTH, id)
	assert_true(def.max_hp >= _load("reverend").max_hp - 0.01, "as tough as the Reverend")
	assert_true(Diva.COOLDOWN <= ActivitiesCoordinatorBehavior.COOLDOWN)
	assert_true(Diva.COOLDOWN <= ForemanBehavior.COOLDOWN)
	assert_true(Diva.COOLDOWN <= ReverendBehavior.COOLDOWN)
	assert_true(Diva.SUMMON_COUNT >= ForemanBehavior.SUMMON_COUNT)
