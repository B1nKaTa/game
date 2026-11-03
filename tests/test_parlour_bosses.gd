extends TestCase

const Reverend := preload("res://scripts/actors/behaviors/reverend_behavior.gd")
# The Funeral Parlour scales health by this, and its bosses hold their final health divided by it.
const PARLOUR_HEALTH := 1.8
# The second floors scale by this, so their bosses' final health is their .tres health times it.
const FLOOR_TWO_HEALTH := 1.4
const CASKET := FuneralDirectorBehavior.Attack.CASKET
const PROCESSION := FuneralDirectorBehavior.Attack.PROCESSION
const SPRAY := FuneralDirectorBehavior.Attack.SPRAY
const CRESCENDO := FuneralDirectorBehavior.Attack.CRESCENDO
const CHARGE := FuneralDirectorBehavior.Attack.CHARGE


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


# --- the Reverend ---

func test_the_eulogy_drops_six_words_evenly_along_a_line_through_him() -> void:
	var from := Vector2(100, 100)
	for to in [Vector2(300, 100), Vector2(140, 180), Vector2(100, 400), Vector2(110, 105)]:
		var spots := Reverend.eulogy_spots(from, to, Reverend.WORDS)
		assert_eq(spots.size(), 6)
		var gap := from.distance_to(spots[0])
		var way := from.direction_to(spots[0])
		for i in range(1, spots.size()):
			assert_near(spots[i - 1].distance_to(spots[i]), gap, "evenly spaced toward %s" % str(to))
			assert_true(from.direction_to(spots[i]).is_equal_approx(way), "on one line")
		assert_true(from.distance_to(spots[-1]) >= from.distance_to(to), "the line runs through him")
		assert_true(way.is_equal_approx(from.direction_to(to)), "aimed at him")


func test_the_eulogy_follows_the_plan() -> void:
	assert_eq(Reverend.WORDS, 6)
	assert_near(Reverend.WORD_STEP, 0.18)
	assert_near(Reverend.WORD_WARNING, 0.8)


func test_every_point_of_the_plates_flight_stays_in_the_room() -> void:
	var room := ForemanBehavior.room_rect(Vector2i(20, 11))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 200:
		var from := Vector2(rng.randf_range(room.position.x, room.end.x), rng.randf_range(room.position.y, room.end.y))
		var aim := Vector2.from_angle(rng.randf() * TAU)
		var bend := Reverend.PLATE_BEND * (1.0 if i % 2 == 0 else -1.0)
		var path := Reverend.plate_path(from, aim, Reverend.PLATE_LENGTH, bend, room)
		assert_eq(path.size(), Reverend.OUT_STEPS + Reverend.BACK_STEPS)
		for point in path:
			assert_true(room.grow(0.01).has_point(point), "%s outside %s" % [str(point), str(room)])


func test_the_plate_goes_out_and_comes_back() -> void:
	var from := Vector2(300, 200)
	var path := Reverend.plate_path(from, Vector2.RIGHT, 180.0, 70.0)
	assert_true(path[Reverend.OUT_STEPS - 1].is_equal_approx(from + Vector2(180, 0)), "out to its length")
	assert_true(path[-1].is_equal_approx(from), "and back to his hand")
	var middle: Vector2 = path[Reverend.OUT_STEPS + Reverend.BACK_STEPS / 2 - 1]
	assert_true(absf(middle.y - from.y) > 40.0, "along a curve, not the lane it went out on")


func test_a_plate_flies_along_its_path() -> void:
	var path: Array[Vector2] = [Vector2(100, 0), Vector2(100, 50)]
	assert_true(CollectionPlate.point_along(path, 50.0).is_equal_approx(Vector2(50, 0)))
	assert_true(CollectionPlate.point_along(path, 125.0).is_equal_approx(Vector2(100, 25)))
	assert_near(CollectionPlate.path_length(path), 150.0)


func test_he_never_summons_over_the_cap() -> void:
	for alive in 9:
		var count := Reverend.summon_count(alive, Reverend.MAX_ENEMIES)
		assert_true(count >= 0 and count <= Reverend.SUMMON_COUNT)
		assert_true(alive + count <= maxi(Reverend.MAX_ENEMIES, alive), "%d alive, %d called" % [alive, count])
	assert_eq(Reverend.summon_count(1, Reverend.MAX_ENEMIES), 3, "alone he calls all three")
	assert_eq(Reverend.MAX_ENEMIES, 5)
	assert_near(Reverend.SUMMON_EVERY, 12.0)


func test_he_calls_mourners_who_pay_nothing() -> void:
	var def := _load("reverend")
	assert_eq(def.summon.id, "weeping_mourner")
	var mourner := Enemy.new()
	mourner.setup(def.summon, null, 0.5)
	mourner.is_summon = true
	mourner.apply_floor(PARLOUR_HEALTH, 2.0)
	assert_eq(mourner.coin_value(), 0)
	mourner.free()


func test_he_alternates_his_two_attacks() -> void:
	assert_eq(Reverend.choose_attack(Reverend.Attack.EULOGY, 0.1), Reverend.Attack.PLATE)
	assert_eq(Reverend.choose_attack(Reverend.Attack.PLATE, 0.9), Reverend.Attack.EULOGY)


func test_the_reverend_is_at_least_as_hard_as_barbara_and_klaus() -> void:
	var def := _load("reverend")
	assert_true(def.is_boss)
	assert_true(absf(def.max_hp * PARLOUR_HEALTH - 560.0) < 0.5, str(def.max_hp * PARLOUR_HEALTH))
	assert_near(def.speed, 75.0)
	assert_eq(def.pension_drop, 8)
	for id in ["activities_coordinator", "foreman_klaus"]:
		assert_true(def.max_hp * PARLOUR_HEALTH >= _load(id).max_hp * FLOOR_TWO_HEALTH, id)
	assert_true(Reverend.COOLDOWN <= ActivitiesCoordinatorBehavior.COOLDOWN)
	assert_true(Reverend.COOLDOWN <= ForemanBehavior.COOLDOWN)
	assert_true(Reverend.SUMMON_COUNT >= ForemanBehavior.SUMMON_COUNT)


# --- Mortimer Grimsby ---

func _walls_of(cells: Vector2i, rng: RandomNumberGenerator, count: int) -> Array[Vector2]:
	# Ring origins on the inner face of the border walls, as organ pipes have them.
	var size := Vector2(cells) * RoomBackdrop.TILE
	var tile := float(RoomBackdrop.TILE)
	var pipes: Array[Vector2] = []
	for i in count:
		match rng.randi_range(0, 3):
			0:
				pipes.append(Vector2(rng.randf_range(tile * 2.0, size.x - tile * 2.0), tile))
			1:
				pipes.append(Vector2(rng.randf_range(tile * 2.0, size.x - tile * 2.0), size.y - tile))
			2:
				pipes.append(Vector2(tile, rng.randf_range(tile * 2.0, size.y - tile * 2.0)))
			_:
				pipes.append(Vector2(size.x - tile, rng.randf_range(tile * 2.0, size.y - tile * 2.0)))
	return pipes


func test_the_casket_slam_costs_three_pills_and_its_warning_shows_whole() -> void:
	assert_eq(Enemy.HEAVIEST_DAMAGE, 3)
	assert_eq(FuneralDirectorBehavior.CASKET_DAMAGE, 3)
	assert_true(FuneralDirectorBehavior.CASKET_SHOWN_WHOLE)
	assert_near(FuneralDirectorBehavior.CASKET_WINDUP, 1.2)
	assert_near(FuneralDirectorBehavior.CASKET_RADIUS, 44.0)
	for phase_two in [false, true]:
		assert_near(FuneralDirectorBehavior.windup_for(FuneralDirectorBehavior.Attack.CASKET, phase_two), 1.2, "the second phase never shortens it")
	var mortimer := Enemy.new()
	mortimer.setup(_load("mortimer_grimsby"), null, 0.25)
	var telegraph := Telegraph.new()
	telegraph.start(FuneralDirectorBehavior.CASKET_WINDUP)
	mortimer.set_warning(telegraph, FuneralDirectorBehavior.WARNING_RADIUS, FuneralDirectorBehavior.CASKET_SHOWN_WHOLE)
	assert_near(mortimer._warning_share(), 1.0, "whatever his warning stat")
	assert_true(telegraph.shows_warning(mortimer._warning_share()), "it shows from the first instant")
	mortimer.free()


func test_the_casket_mark_fills_over_its_whole_windup_and_lands_for_three() -> void:
	var strike := GroundStrike.new()
	strike.setup(null, FuneralDirectorBehavior.CASKET_RADIUS, FuneralDirectorBehavior.CASKET_WINDUP, 0.0, 0.0, FuneralDirectorBehavior.CASKET_DAMAGE)
	strike.set_look(GroundStrike.LOOK_CASKET)
	assert_eq(strike.damage(), 3)
	assert_false(strike.advance(0.6))
	assert_near(strike.fill(), 0.5, "half filled at half the windup")
	assert_true(strike.advance(0.61))
	strike.free()


func test_he_can_step_out_of_the_casket_in_time() -> void:
	var walk := PlayerStats.BASE_SPEED * (FuneralDirectorBehavior.CASKET_WINDUP - 0.3)
	assert_true(walk > FuneralDirectorBehavior.CASKET_RADIUS * 2.0, "%f" % walk)


func test_the_procession_leaves_its_gap_inside_the_room() -> void:
	for cells in [Vector2i(14, 9), Vector2i(20, 11), Vector2i(30, 17)]:
		var room := ForemanBehavior.room_rect(cells)
		for direction in [Vector2.RIGHT, Vector2.DOWN]:
			for gap in FuneralDirectorBehavior.SLOTS:
				for center in [room.get_center(), room.position + Vector2(5, 5), room.end - Vector2(5, 5)]:
					var lanes := FuneralDirectorBehavior.procession_lanes(room, direction, gap, center)
					assert_eq(lanes.size(), 4, "four lanes march")
					var clear := FuneralDirectorBehavior.procession_slot(room, direction, gap, center)
					assert_true(room.grow(0.5).encloses(clear), "the gap %s lies in %s" % [str(clear), str(room)])
					assert_true(clear.size.x >= Player.FEET_BOX_SIZE.x * 2.0 and clear.size.y >= Player.FEET_BOX_SIZE.y * 2.0, "he fits in it")
					for lane in lanes:
						assert_true(room.grow(0.5).encloses(lane))
						assert_false(lane.has_point(clear.get_center()), "the gap is clear")


func test_the_procession_gap_moves_each_time() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var last := 1
	var seen := {}
	for i in 60:
		var next := FuneralDirectorBehavior.next_gap(last, rng)
		assert_true(next != last and next >= 0 and next < FuneralDirectorBehavior.SLOTS)
		seen[next] = true
		last = next
	assert_eq(seen.size(), FuneralDirectorBehavior.SLOTS)


func test_a_procession_row_hits_only_where_it_has_marched() -> void:
	assert_true(ProcessionLane.row_hits(Vector2.ZERO, Vector2.RIGHT, 40.0, 100.0, Vector2(80, 10)))
	assert_false(ProcessionLane.row_hits(Vector2.ZERO, Vector2.RIGHT, 40.0, 100.0, Vector2(140, 0)), "not reached yet")
	assert_false(ProcessionLane.row_hits(Vector2.ZERO, Vector2.RIGHT, 40.0, 100.0, Vector2(20, 0)), "already passed")
	assert_false(ProcessionLane.row_hits(Vector2.ZERO, Vector2.RIGHT, 40.0, 100.0, Vector2(80, 30)), "beside the lane")


func test_the_crescendo_always_leaves_a_safe_spot() -> void:
	for seed_value in 200:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var cells: Vector2i = [Vector2i(14, 9), Vector2i(20, 11), Vector2i(30, 17)][seed_value % 3]
		var room := ForemanBehavior.room_rect(cells)
		var pipes := _walls_of(cells, rng, rng.randi_range(2, 8))
		var feet := Vector2(rng.randf_range(room.position.x, room.end.x), rng.randf_range(room.position.y, room.end.y))
		var safe := FuneralDirectorBehavior.crescendo_safe_spot(pipes, room, rng, feet)
		assert_true(room.has_point(safe), "seed %d: inside the room" % seed_value)
		var reaches := FuneralDirectorBehavior.crescendo_reaches(pipes, safe)
		var playing := 0
		for i in pipes.size():
			if reaches[i] < FuneralDirectorBehavior.PLAYS_FROM:
				continue
			playing += 1
			# Grown to its full reach, the band's outer edge still stops short of the spot.
			assert_true(pipes[i].distance_to(safe) > reaches[i] + PipeRing.WIDTH / 2.0, "seed %d pipe %d" % [seed_value, i])
			for step in 21:
				var radius := lerpf(PipeRing.FROM, reaches[i], step / 20.0)
				assert_false(Shockwave.band_hits(pipes[i], radius, PipeRing.WIDTH, safe), "seed %d pipe %d at %f" % [seed_value, i, radius])
		assert_true(playing > 0, "seed %d: the crescendo plays" % seed_value)


func test_the_safe_spot_is_near_him_when_it_can_be() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var room := ForemanBehavior.room_rect(Vector2i(20, 11))
	var pipes: Array[Vector2] = [Vector2(160, 32), Vector2(480, 320)]
	var feet := room.get_center()
	for i in 20:
		var safe := FuneralDirectorBehavior.crescendo_safe_spot(pipes, room, rng, feet)
		assert_true(safe.distance_to(feet) <= FuneralDirectorBehavior.SAFE_NEAR, str(safe))


func test_the_spray_follows_the_plan() -> void:
	assert_near(FuneralDirectorBehavior.SPRAY_WINDUP, 0.9)
	assert_near(FuneralDirectorBehavior.SPRAY_ANGLE, 50.0)
	assert_near(FuneralDirectorBehavior.SPRAY_LENGTH, 120.0)
	assert_near(FuneralDirectorBehavior.SPRAY_SLOW, 0.5)
	assert_near(FuneralDirectorBehavior.SPRAY_SLOW_TIME, 1.5)


func test_without_pipes_there_is_no_crescendo() -> void:
	for roll in [0.0, 0.3, 0.6, 0.99]:
		var attack := FuneralDirectorBehavior.choose_attack(60.0, FuneralDirectorBehavior.Attack.NONE, false, 99.0, roll)
		assert_true(attack != FuneralDirectorBehavior.Attack.CRESCENDO)
	var seen := {}
	for i in 100:
		seen[FuneralDirectorBehavior.choose_attack(60.0, FuneralDirectorBehavior.Attack.NONE, true, 99.0, i / 100.0)] = true
	assert_true(seen.has(FuneralDirectorBehavior.Attack.CRESCENDO), "with pipes it comes")


func test_the_safe_spot_stays_marked_until_the_last_ring_has_passed() -> void:
	var longest := FuneralDirectorBehavior.CRESCENDO_GLOW + 11 * FuneralDirectorBehavior.CRESCENDO_STAGGER
	var slowest_ring := PipeRing.GROW_TIME * FuneralDirectorBehavior.CRESCENDO_REACH / PipeRing.REACH
	assert_true(FuneralDirectorBehavior.safe_mark_time(longest) >= longest + slowest_ring)
	var mark := SafeSpotMark.new()
	mark.setup(FuneralDirectorBehavior.safe_mark_time(longest))
	assert_near(mark.time_left(), FuneralDirectorBehavior.safe_mark_time(longest))
	mark.free()


func test_phase_two_chains_the_coffin_charge() -> void:
	for attack in [CASKET, PROCESSION, SPRAY, CRESCENDO]:
		assert_eq(FuneralDirectorBehavior.followup(attack, true), CHARGE, "after %d" % attack)
		assert_eq(FuneralDirectorBehavior.followup(attack, false), FuneralDirectorBehavior.Attack.NONE)
	assert_eq(FuneralDirectorBehavior.followup(CHARGE, true), FuneralDirectorBehavior.Attack.NONE, "never two charges running")
	assert_near(FuneralDirectorBehavior.CHARGE_WINDUP, 0.9)
	assert_near(FuneralDirectorBehavior.windup_for(CHARGE, true), 0.9)
	assert_true(FuneralDirectorBehavior.windup_for(SPRAY, true) < FuneralDirectorBehavior.SPRAY_WINDUP, "his other windups quicken")
	assert_true(FuneralDirectorBehavior.is_phase_two(800.0, 1700.0))
	assert_false(FuneralDirectorBehavior.is_phase_two(900.0, 1700.0))


func test_mortimer_is_clearly_harder_than_matron_and_smokey() -> void:
	var def := _load("mortimer_grimsby")
	assert_true(def.is_boss)
	assert_true(absf(def.max_hp * PARLOUR_HEALTH - 1700.0) < 0.5, str(def.max_hp * PARLOUR_HEALTH))
	assert_near(def.speed, 75.0)
	assert_eq(def.pension_drop, 16)
	for id in ["matron_mercy", "old_smokey"]:
		assert_true(def.max_hp * PARLOUR_HEALTH >= _load(id).max_hp * FLOOR_TWO_HEALTH * 1.1, id)
	assert_true(FuneralDirectorBehavior.BASE_COOLDOWN < ChiefStokerBehavior.BASE_COOLDOWN)
	assert_true(FuneralDirectorBehavior.PHASE_TWO_COOLDOWN < ChiefStokerBehavior.PHASE_TWO_COOLDOWN)
	assert_true(FuneralDirectorBehavior.CASKET_DAMAGE > Enemy.HEAVY_DAMAGE)
