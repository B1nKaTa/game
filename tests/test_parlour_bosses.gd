extends TestCase

const Reverend := preload("res://scripts/actors/behaviors/reverend_behavior.gd")
# The Funeral Parlour scales health by this, and its bosses hold their final health divided by it.
const PARLOUR_HEALTH := 1.8
# The second floors scale by this, so their bosses' final health is their .tres health times it.
const FLOOR_TWO_HEALTH := 1.4


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
