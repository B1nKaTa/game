extends TestCase


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


# --- the Weeping Mourners ---

func test_mourners_come_in_packs_of_three_and_drift_slowly() -> void:
	var def := _load("weeping_mourner")
	assert_eq(def.group_size, 3)
	assert_near(def.speed, 40.0)
	assert_eq(MourningPack.SIZE, 3)
	assert_near(MourningPack.LUNGE_EVERY, 4.0)
	assert_near(MourningPack.WAIL_TIME, 0.8)
	assert_near(WeepingMournerBehavior.LUNGE_LENGTH, 70.0)


func test_each_mourner_lunges_down_its_own_lane_toward_him() -> void:
	var target := Vector2(200, 200)
	var spots: Array[Vector2] = [Vector2(100, 200), Vector2(200, 80), Vector2(260, 260)]
	var lanes := MourningPack.lunge_lanes(spots, target)
	assert_eq(lanes.size(), 3)
	for i in spots.size():
		assert_near(lanes[i].length(), 1.0)
		assert_true(lanes[i].is_equal_approx(spots[i].direction_to(target)), "lane %d points at him" % i)
	assert_true(lanes[0].is_equal_approx(Vector2.RIGHT))
	assert_false(lanes[0].is_equal_approx(lanes[1]), "every lane is its own")


func test_a_mourner_standing_on_him_still_has_a_lane() -> void:
	var spots: Array[Vector2] = [Vector2(50, 50)]
	var lanes := MourningPack.lunge_lanes(spots, Vector2(50, 50))
	assert_near(lanes[0].length(), 1.0)


func test_the_wail_leaves_time_to_step_out_of_a_lane() -> void:
	var walk := PlayerStats.BASE_SPEED * (MourningPack.WAIL_TIME - 0.3)
	assert_true(walk > WeepingMournerBehavior.LANE_WIDTH, "%f" % walk)


func test_a_pack_only_wails_from_its_first_living_member() -> void:
	var a := Enemy.new()
	a.setup(_load("weeping_mourner"), null, 0.5)
	var b := Enemy.new()
	b.setup(_load("weeping_mourner"), null, 0.5)
	var pack := MourningPack.new()
	pack.members.append(a)
	pack.members.append(b)
	assert_eq(pack.leader(), a)
	a.take_damage(INF, Vector2.ZERO)
	assert_eq(pack.leader(), b, "the next one takes over")
	a.free()
	b.free()


# --- the Florist ---

func test_the_florist_keeps_her_distance() -> void:
	assert_eq(FloristBehavior.step(60.0), FloristBehavior.BACK_OFF)
	assert_eq(FloristBehavior.step(129.0), FloristBehavior.BACK_OFF)
	assert_eq(FloristBehavior.step(160.0), FloristBehavior.HOLD)
	assert_eq(FloristBehavior.step(FloristBehavior.TOO_FAR + 1.0), FloristBehavior.CLOSE_IN)
	assert_true(FloristBehavior.TOO_CLOSE >= 130.0)


func test_a_wreath_lands_near_him() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var target := Vector2(300, 180)
	for i in 200:
		assert_true(FloristBehavior.wreath_spot(target, rng).distance_to(target) <= 40.0 + 0.001)


func test_her_wreaths_follow_the_plan() -> void:
	assert_near(FloristBehavior.THROW_EVERY, 3.2)
	assert_near(FloristBehavior.WREATH_WARNING, 0.9)
	assert_near(FloristBehavior.WREATH_RADIUS, 26.0)
	assert_near(FloristBehavior.THORN_TIME, 3.0)
	assert_near(GroundStrike.BURN_EVERY, 0.6, "thorns hurt at most once in 0.6 seconds")


func test_a_wreath_mark_leaves_time_to_walk_out() -> void:
	var walk := PlayerStats.BASE_SPEED * (FloristBehavior.WREATH_WARNING - 0.2)
	assert_true(walk > FloristBehavior.WREATH_RADIUS * 2.0, "%f" % walk)


func test_a_thrown_wreath_marks_its_spot_then_leaves_thorns() -> void:
	var florist := Enemy.new()
	florist.setup(_load("florist"), null, 0.5)
	var strike := GroundStrike.new()
	strike.setup(florist, FloristBehavior.WREATH_RADIUS, FloristBehavior.WREATH_WARNING, 0.0, 0.0, -1, FloristBehavior.THORN_TIME)
	strike.set_look(GroundStrike.LOOK_THORNS)
	assert_eq(strike.look(), GroundStrike.LOOK_THORNS)
	assert_false(strike.advance(FloristBehavior.WREATH_WARNING - 0.1))
	assert_true(strike.advance(0.2))
	assert_true(strike.is_burning(), "the thorns stay")
	strike.tick_burn(FloristBehavior.THORN_TIME + 0.1)
	assert_false(strike.is_burning(), "and wither")
	strike.free()
	florist.free()


# --- the Pallbearers ---

func test_pallbearers_come_in_pairs() -> void:
	var def := _load("pallbearer")
	assert_eq(def.group_size, 2)


func test_a_bearer_fights_alone_only_once_its_partner_is_gone() -> void:
	assert_false(PallbearerBehavior.alone(true))
	assert_true(PallbearerBehavior.alone(false))


func test_the_ram_follows_the_plan() -> void:
	assert_near(PallbearerBehavior.WINDUP, 0.9)
	assert_near(PallbearerBehavior.LANE_WIDTH, 36.0)
	assert_near(PallbearerBehavior.RAM_LENGTH, 240.0)
	assert_near(PallbearerBehavior.RAM_SPEED, 300.0)
	assert_near(PallbearerBehavior.COFFIN_TIME, 6.0)


func test_the_coffin_between_them_hits_too() -> void:
	var leader := Vector2(100, 100)
	var follower := Vector2(100, 130)
	assert_true(PallbearerBehavior.ram_hits(leader, follower, Vector2(110, 115)), "the coffin")
	assert_true(PallbearerBehavior.ram_hits(leader, follower, Vector2(100, 85)), "a bearer")
	assert_false(PallbearerBehavior.ram_hits(leader, follower, Vector2(140, 115)), "beside the lane")


func test_a_dropped_coffin_never_lands_solid_on_grandpa() -> void:
	var size := Vector2(DroppedCoffin.LONG, DroppedCoffin.SHORT)
	assert_true(DroppedCoffin.lands_on(Vector2(100, 100), size, Vector2(110, 104)))
	assert_false(DroppedCoffin.lands_on(Vector2(100, 100), size, Vector2(100, 160)))
	var coffin := DroppedCoffin.new()
	assert_true(coffin.is_solid())
	assert_false(coffin.can_break_by(BreakableBlock.SOURCE_CANE), "a cane does not move it")
	assert_true(coffin.can_break_by(BreakableBlock.SOURCE_BOSS))
	coffin.free()


# --- the returning enemies ---

func test_returning_enemies_keep_their_numbers_and_take_the_floors_colors() -> void:
	for id in ["plot_holder", "seasonal_temp"]:
		var mine := _load("parlour_" + id)
		var theirs := _load(id)
		assert_near(mine.max_hp, theirs.max_hp, id)
		assert_near(mine.speed, theirs.speed, id)
		assert_eq(mine.pension_drop, theirs.pension_drop, id)
		assert_eq(mine.behavior_script, theirs.behavior_script, id)
		assert_eq(mine.display_name, theirs.display_name, id)
		assert_eq(mine.max_per_room, theirs.max_per_room, id)
		assert_eq(mine.group_size, theirs.group_size, id)
		assert_true(mine.id != theirs.id and mine.color != theirs.color, id)


# --- the numbers ---

func test_new_enemies_match_the_first_floor_role_they_fill() -> void:
	var pairs := {"weeping_mourner": "seasonal_temp", "florist": "filing_clerk", "pallbearer": "debt_ghost"}
	for id: String in pairs:
		var def := _load(id)
		var theirs := _load(pairs[id])
		assert_false(def.is_boss, id)
		assert_false(def.display_name.is_empty(), id)
		assert_false(def.mark.is_empty(), id)
		assert_eq(def.pension_drop, theirs.pension_drop, id)
		assert_true(absf(def.max_hp - theirs.max_hp) <= 4.0, id)
		assert_true(def.behavior_script.new() is EnemyBehavior, id)
