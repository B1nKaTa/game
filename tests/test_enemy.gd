extends TestCase


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


func test_a_normal_enemy_is_worth_its_drop() -> void:
	var enemy := Enemy.new()
	enemy.setup(_load("intern_reaper"), null, 0.5)
	assert_true(enemy.coin_value() > 0)
	enemy.free()


func test_a_summoned_enemy_is_worth_nothing() -> void:
	var enemy := Enemy.new()
	enemy.setup(_load("intern_reaper"), null, 0.5)
	enemy.is_summon = true
	assert_eq(enemy.coin_value(), 0, "or a boss could be farmed forever")
	enemy.free()


func test_income_values_stay_at_the_reduced_level() -> void:
	var floor_def: FloorDef = load("res://data/floors/floor_1.tres")
	assert_eq(floor_def.clear_pension, 4)
	assert_eq(floor_def.treasure_pension, 12)
	assert_eq(floor_def.mini_boss.pension_drop, 15)
	assert_eq(floor_def.floor_boss.pension_drop, 30)
	for def: EnemyDef in floor_def.enemies:
		assert_true(def.pension_drop <= 3, def.id)


func test_regular_enemies_load_with_behaviors() -> void:
	for id in ["intern_reaper", "filing_clerk", "debt_ghost"]:
		var def := _load(id)
		assert_true(def != null, id)
		assert_true(def.max_hp > 0.0, id)
		assert_true(def.pension_drop > 0, id)
		assert_true(def.behavior_script != null, id)
		assert_true(def.behavior_script.new() is EnemyBehavior, id)


func test_only_the_ghost_ignores_walls() -> void:
	assert_false(_load("intern_reaper").ignores_walls)
	assert_false(_load("filing_clerk").ignores_walls)
	assert_true(_load("debt_ghost").ignores_walls)


func test_damage_defeats_once() -> void:
	var enemy := Enemy.new()
	enemy.setup(_load("intern_reaper"), null, 0.5)
	var defeats := [0]
	enemy.defeated.connect(func(_e): defeats[0] += 1)
	enemy.take_damage(1000.0, Vector2.ZERO)
	enemy.take_damage(1000.0, Vector2.ZERO)
	assert_eq(defeats[0], 1)
	enemy.free()


func test_damage_reduces_hp() -> void:
	var def := _load("intern_reaper")
	var enemy := Enemy.new()
	enemy.setup(def, null, 0.5)
	enemy.take_damage(5.0, Vector2.ZERO)
	assert_near(enemy.hp, def.max_hp - 5.0)
	enemy.free()


func test_clamp_inside_room_keeps_inner_points() -> void:
	assert_eq(Enemy.clamp_inside_room(Vector2(200, 150), Vector2i(20, 11)), Vector2(200, 150))


func test_clamp_inside_room_pulls_back_from_the_walls_of_any_size() -> void:
	var tile := float(RoomBackdrop.TILE)
	for cells: Vector2i in [Vector2i(14, 9), Vector2i(20, 11), Vector2i(30, 17)]:
		var far_corner := Vector2(cells.x - 1, cells.y - 1) * tile
		assert_eq(Enemy.clamp_inside_room(Vector2(-50, -50), cells), Vector2(tile, tile))
		assert_eq(Enemy.clamp_inside_room(Vector2(5000, 5000), cells), far_corner)


func test_health_bar_is_off_by_default() -> void:
	var enemy := Enemy.new()
	enemy.setup(_load("intern_reaper"), null, 0.5)
	assert_false(enemy.shows_health_bar())
	enemy.free()


func test_health_bar_shows_when_requested_for_regular_enemies() -> void:
	var enemy := Enemy.new()
	enemy.setup(_load("intern_reaper"), null, 0.5, true)
	assert_true(enemy.shows_health_bar())
	enemy.free()


func test_bosses_never_draw_a_bar_above_their_heads() -> void:
	var boss := Enemy.new()
	boss.setup(load("res://data/enemies/regional_reaper.tres"), null, 0.5, true)
	assert_false(boss.shows_health_bar())
	boss.free()


func test_damage_emits_health_changed() -> void:
	var def := _load("intern_reaper")
	var enemy := Enemy.new()
	enemy.setup(def, null, 0.5)
	var seen := []
	enemy.health_changed.connect(func(hp: float): seen.append(hp))
	enemy.take_damage(5.0, Vector2.ZERO)
	assert_eq(seen.size(), 1)
	assert_near(seen[0], def.max_hp - 5.0)
	enemy.free()
