extends TestCase

const NEW_TYPES := ["seasonal_temp", "notary_public", "burnt_out_auditor", "denial_officer"]
const BEHAVIORS := [
	"charger_behavior", "melee_behavior", "thrower_behavior", "pack_behavior", "burst_shooter_behavior",
	"exploder_behavior", "shield_behavior", "floor_boss_behavior", "mini_boss_behavior"]
const ExploderBehavior := preload("res://scripts/actors/behaviors/exploder_behavior.gd")
const PackBehavior := preload("res://scripts/actors/behaviors/pack_behavior.gd")


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


func _floor() -> FloorDef:
	return load("res://data/floors/floor_1.tres")


func test_every_new_type_is_data_plus_a_behavior_and_in_the_floor_mix() -> void:
	var ids := []
	for def: EnemyDef in _floor().enemies:
		ids.append(def.id)
	for id in NEW_TYPES:
		var def := _load(id)
		assert_true(def != null, id)
		assert_false(def.display_name.is_empty(), id)
		assert_true(def.behavior_script.new() is EnemyBehavior, id)
		assert_true(ids.has(id), "%s is in the floor mix" % id)


func test_regular_enemies_are_tougher_and_faster_than_before() -> void:
	for entry in [["intern_reaper", 28.0, 65.0], ["filing_clerk", 20.0, 50.0], ["debt_ghost", 24.0, 40.0]]:
		var def := _load(entry[0])
		assert_true(def.max_hp >= entry[1] * 1.4, "%s health" % entry[0])
		assert_true(def.speed >= entry[2] * 1.3, "%s speed" % entry[0])


func test_the_pack_is_fast_fragile_and_comes_in_groups() -> void:
	var temp := _load("seasonal_temp")
	assert_true(temp.group_size >= 3)
	assert_true(temp.max_hp <= 15.0, "dies to two plain hits")
	assert_true(temp.speed >= 100.0)
	for id in ["intern_reaper", "notary_public", "denial_officer"]:
		assert_eq(_load(id).group_size, 1, id)


func test_the_shielded_one_is_slow_and_tough_and_the_others_have_no_shield() -> void:
	var officer := _load("denial_officer")
	assert_true(officer.shield_half_angle > 0.0)
	assert_true(officer.speed < 50.0)
	assert_true(officer.max_hp > _load("intern_reaper").max_hp * 2.0)
	for id in ["seasonal_temp", "notary_public", "burnt_out_auditor", "intern_reaper"]:
		assert_near(_load(id).shield_half_angle, 0.0, id)


func test_every_enemy_can_be_told_apart_by_color_or_size() -> void:
	var defs: Array[EnemyDef] = []
	defs.assign(_floor().enemies)
	defs.append(_floor().mini_boss)
	defs.append(_floor().floor_boss)
	for i in defs.size():
		for j in range(i + 1, defs.size()):
			var a := SpriteVisual.readable(defs[i].color)
			var b := SpriteVisual.readable(defs[j].color)
			var color_gap := Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()
			var size_gap := (defs[i].body_size - defs[j].body_size).length()
			assert_true(color_gap >= 0.25 or size_gap >= 12.0, "%s and %s look alike" % [defs[i].id, defs[j].id])


# The warning shows for only part of each windup, so a windup sets how long a player can read it.
func test_every_attack_warning_shows_long_enough_to_read() -> void:
	for behavior: String in BEHAVIORS:
		var script: Script = load("res://scripts/actors/behaviors/%s.gd" % behavior)
		var found := 0
		var constants := script.get_script_constant_map()
		for key: String in constants:
			if key.contains("WINDUP") or key == "FUSE":
				found += 1
				assert_true(constants[key] * PlayerStats.BASE_WARNING >= 0.2, "%s.%s" % [behavior, key])
		assert_true(found > 0, behavior)


func test_a_shield_covers_only_the_front() -> void:
	assert_true(Enemy.shield_covers(Vector2.RIGHT, Vector2.RIGHT, 70.0), "straight ahead")
	assert_true(Enemy.shield_covers(Vector2.RIGHT, Vector2.from_angle(deg_to_rad(60.0)), 70.0), "to one side of the front")
	assert_false(Enemy.shield_covers(Vector2.RIGHT, Vector2.UP, 70.0), "from the side")
	assert_false(Enemy.shield_covers(Vector2.RIGHT, Vector2.LEFT, 70.0), "from behind")
	assert_false(Enemy.shield_covers(Vector2.RIGHT, Vector2.RIGHT, 0.0), "no shield at all")


func _officer() -> Enemy:
	var enemy := Enemy.new()
	enemy.setup(_load("denial_officer"), null, 0.5)
	enemy.facing = Vector2.RIGHT
	return enemy


func test_a_strike_from_the_front_is_blocked_and_from_behind_lands() -> void:
	var enemy := _officer()
	var hp := enemy.hp
	var blocks := [0]
	enemy.hit_blocked.connect(func(): blocks[0] += 1)
	assert_false(enemy.take_strike(20.0, Vector2.ZERO, Vector2.RIGHT), "from the front")
	assert_near(enemy.hp, hp)
	assert_eq(blocks[0], 1)
	assert_true(enemy.take_strike(20.0, Vector2.ZERO, Vector2.LEFT), "from behind")
	assert_near(enemy.hp, hp - 20.0)
	enemy.free()


func test_a_thrown_cane_or_blast_ignores_the_shield() -> void:
	var enemy := _officer()
	var hp := enemy.hp
	enemy.take_damage(14.0, Vector2.ZERO)
	assert_near(enemy.hp, hp - 14.0, "throwing over it uses plain damage")
	enemy.free()


func test_followers_of_a_group_pay_nothing_and_a_leader_pays() -> void:
	var leader := Enemy.new()
	leader.setup(_load("seasonal_temp"), null, 0.5)
	assert_true(leader.coin_value() > 0)
	leader.is_group_follower = true
	assert_eq(leader.coin_value(), 0)
	leader.free()


func test_an_enemy_that_blows_itself_up_pays_nothing() -> void:
	var enemy := Enemy.new()
	enemy.setup(_load("burnt_out_auditor"), null, 0.5)
	assert_true(enemy.coin_value() > 0)
	enemy.self_destruct()
	assert_eq(enemy.coin_value(), 0)
	enemy.free()


func test_the_auditor_only_blows_when_killed_once_its_fuse_is_lit() -> void:
	assert_false(ExploderBehavior.blows_when_killed(false))
	assert_true(ExploderBehavior.blows_when_killed(true))


func test_the_blast_reaches_by_the_nearest_part_of_a_body() -> void:
	var body := Rect2(Vector2(50, -10), Vector2(20, 20))
	assert_true(EnemyBlast.reaches(Vector2.ZERO, body, 56.0))
	assert_false(EnemyBlast.reaches(Vector2.ZERO, body, 40.0))


func test_a_pack_spreads_around_its_target() -> void:
	var seen := {}
	for i in 4:
		seen[snappedf(PackBehavior.flank_angle(i, 4), 0.01)] = true
	assert_eq(seen.size(), 4, "each member takes its own side")


func test_income_values_stay_low_enough_for_many_more_enemies() -> void:
	var floor_def := _floor()
	assert_true(floor_def.prop_pension < floor_def.treasure_pension, "a barrel is not a treasure")
	for def: EnemyDef in floor_def.enemies:
		assert_eq(def.pension_drop, 1, def.id)
