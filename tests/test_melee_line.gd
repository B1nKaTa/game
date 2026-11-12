extends TestCase

# A melee enemy strikes only with nothing solid between it and Grandpa, and walks round a prop
# instead of swinging through it.
const ShieldBehavior := preload("res://scripts/actors/behaviors/shield_behavior.gd")
const MeleeBehavior := preload("res://scripts/actors/behaviors/melee_behavior.gd")
const ExtraBehavior := preload("res://scripts/actors/behaviors/extra_behavior.gd")
const PackBehavior := preload("res://scripts/actors/behaviors/pack_behavior.gd")
const ExploderBehavior := preload("res://scripts/actors/behaviors/exploder_behavior.gd")
const T := RoomBackdrop.TILE


# A room of open floor, with a one-cell prop in the middle of row 2 when `prop` is true.
func _grid(prop: bool) -> WalkGrid:
	var rows := PackedStringArray()
	for y in 5:
		rows.append("....#...." if prop and y == 2 else ".........")
	return WalkGrid.from_rows(rows, "#")


func _enemy(def_id: String, prop: bool, gap: float) -> Enemy:
	var enemy := Enemy.new()
	enemy.setup(load("res://data/enemies/%s.tres" % def_id), null, 0.5)
	var harold := Node2D.new()
	enemy.target = harold
	enemy.walk_grid = _grid(prop)
	var row := T * 2.5
	enemy.global_position = Vector2(T * 4.5 - gap / 2.0, row)
	harold.global_position = Vector2(T * 4.5 + gap / 2.0, row)
	return enemy


func _free(enemy: Enemy) -> void:
	enemy.target.free()
	enemy.free()


func test_a_prop_between_them_blocks_the_strike() -> void:
	var enemy := _enemy("intern_reaper", true, 20.0)
	assert_false(enemy.can_strike_target())
	_free(enemy)


func test_a_clear_line_allows_the_strike() -> void:
	var enemy := _enemy("intern_reaper", false, 20.0)
	assert_true(enemy.can_strike_target())
	_free(enemy)


func test_no_grid_or_a_ghost_always_may_strike() -> void:
	var enemy := _enemy("intern_reaper", true, 20.0)
	enemy.walk_grid = null
	assert_true(enemy.can_strike_target())
	_free(enemy)


func test_no_windup_starts_through_a_prop_but_does_once_clear() -> void:
	var cases := {"shield": ShieldBehavior, "melee": MeleeBehavior, "extra": ExtraBehavior, "pack": PackBehavior}
	for id: String in ["denial_officer", "intern_reaper"]:
		for prop in [true, false]:
			var enemy := _enemy(id, prop, 20.0)
			for script: GDScript in cases.values():
				var behavior: EnemyBehavior = script.new()
				behavior.tick(enemy, 2.0)
				var started: bool = enemy.is_winding_up()
				assert_eq(started, not prop, "%s with prop=%s via %s" % [id, str(prop), str(script.resource_path)])
				enemy.clear_warning()
			_free(enemy)


func test_the_exploder_does_not_light_through_a_prop() -> void:
	var blocked := _enemy("intern_reaper", true, 20.0)
	var fuse: EnemyBehavior = ExploderBehavior.new()
	fuse.tick(blocked, 2.0)
	assert_false(fuse._lit, "a prop stands between")
	_free(blocked)
	var open := _enemy("intern_reaper", false, 20.0)
	var open_fuse: EnemyBehavior = ExploderBehavior.new()
	open_fuse.tick(open, 2.0)
	assert_true(open_fuse._lit)
	_free(open)


func test_a_shield_enemy_walks_round_a_prop_not_straight_at_harold() -> void:
	var enemy := _enemy("denial_officer", true, 4.0 * T)
	enemy.global_position = Vector2(T * 2.5, T * 2.5)
	enemy.target.global_position = Vector2(T * 6.5, T * 2.5)
	enemy.facing = Vector2.RIGHT
	var behavior: EnemyBehavior = ShieldBehavior.new()
	for i in 20:
		behavior.tick(enemy, 0.05)
	assert_true(absf(enemy.desired_velocity.normalized().y) > 0.05, "it turns off the straight line: %s" % str(enemy.desired_velocity))
	_free(enemy)
