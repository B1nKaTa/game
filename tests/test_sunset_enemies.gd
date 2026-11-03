extends TestCase


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


# --- the bingo caller ---

func test_bingo_marks_land_near_him_and_apart() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 50:
		var marks := BingoCallerBehavior.bingo_marks(Vector2(100, 100), 3, rng)
		assert_eq(marks.size(), 3)
		for a in marks.size():
			assert_true(marks[a].distance_to(Vector2(100, 100)) <= 48.0)
			for b in range(a + 1, marks.size()):
				assert_true(marks[a].distance_to(marks[b]) >= 28.0)


func test_a_crowded_room_gets_fewer_marks() -> void:
	assert_eq(BingoCallerBehavior.mark_count(0), 3)
	assert_eq(BingoCallerBehavior.mark_count(1), 3)
	assert_eq(BingoCallerBehavior.mark_count(2), 2)


func test_a_mark_leaves_time_to_walk_out() -> void:
	var walk := PlayerStats.BASE_SPEED * BingoCallerBehavior.MARK_WARNING
	assert_true(walk > BingoCallerBehavior.MARK_RADIUS * 2.0 + 20.0, "he can cross a mark and more, %f" % walk)


func test_a_call_names_a_bingo_number() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	for i in 20:
		var called := BingoCallerBehavior.call_name(rng)
		assert_true("BINGO".contains(called[0]) and called.ends_with("!"), called)


# --- the cart nurse ---

func test_a_stunned_nurse_takes_double_damage() -> void:
	assert_near(CartNurseBehavior.damage_taken(10.0, true), 20.0)
	assert_near(CartNurseBehavior.damage_taken(10.0, false), 10.0)


func test_a_real_nurse_only_takes_double_while_stunned() -> void:
	var nurse := Enemy.new()
	nurse.setup(_load("cart_nurse"), null, 0.5)
	var hp := nurse.hp
	nurse.take_damage(5.0, Vector2.ZERO)
	assert_near(nurse.hp, hp - 5.0)
	nurse._behavior._stun_left = 1.0
	nurse.take_damage(5.0, Vector2.ZERO)
	assert_near(nurse.hp, hp - 15.0)
	nurse.free()


# --- the orderly ---

func test_an_orderly_dart_slows_and_costs_one_pill() -> void:
	assert_near(OrderlyBehavior.SLOW, 0.5)
	assert_near(OrderlyBehavior.SLOW_TIME, 1.5)
	assert_near(OrderlyBehavior.LANE_WIDTH, 10.0)
	assert_near(OrderlyBehavior.WINDUP, 0.6)
	assert_eq(_load("orderly").damage, 1)
	var dart := Projectile.new()
	dart.setup(Vector2.RIGHT, 100.0, null, 1)
	assert_false(dart.is_dart())
	dart.make_dart(OrderlyBehavior.SLOW, OrderlyBehavior.SLOW_TIME)
	assert_true(dart.is_dart())
	dart.free()


# --- the numbers ---

func test_new_enemies_match_the_first_floor_role_they_fill() -> void:
	var pairs := {"orderly": "notary_public", "cart_nurse": "debt_ghost", "bingo_caller": "filing_clerk"}
	for id: String in pairs:
		var def := _load(id)
		var theirs := _load(pairs[id])
		assert_false(def.is_boss, id)
		assert_false(def.display_name.is_empty(), id)
		assert_eq(def.pension_drop, theirs.pension_drop, id)
		assert_true(absf(def.max_hp - theirs.max_hp) <= 4.0, id)
		assert_true(def.behavior_script.new() is EnemyBehavior, id)


func test_returning_enemies_keep_their_numbers_and_take_the_floors_colors() -> void:
	for id in ["seasonal_temp", "denial_officer"]:
		var mine := _load("shores_" + id)
		var theirs := _load(id)
		assert_near(mine.max_hp, theirs.max_hp, id)
		assert_eq(mine.pension_drop, theirs.pension_drop, id)
		assert_eq(mine.behavior_script, theirs.behavior_script, id)
		assert_eq(mine.display_name, theirs.display_name, id)
		assert_true(mine.id != theirs.id and mine.color != theirs.color, id)
