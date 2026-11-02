extends TestCase


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


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
