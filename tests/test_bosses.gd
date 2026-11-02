extends TestCase

const FloorBossBehavior := preload("res://scripts/actors/behaviors/floor_boss_behavior.gd")


func test_bosses_are_flagged() -> void:
	for id in ["senior_adjuster", "regional_reaper"]:
		var def: EnemyDef = load("res://data/enemies/%s.tres" % id)
		assert_true(def.is_boss, id)
		assert_true(def.max_hp >= 150.0, id)
		assert_true(def.behavior_script.new() is EnemyBehavior, id)


func test_mini_boss_summons_interns() -> void:
	var def: EnemyDef = load("res://data/enemies/senior_adjuster.tres")
	assert_eq(def.summon.id, "intern_reaper")


func test_floor_boss_changes_phase_at_half_health() -> void:
	assert_false(FloorBossBehavior.is_phase_two(51.0, 100.0))
	assert_true(FloorBossBehavior.is_phase_two(50.0, 100.0))
