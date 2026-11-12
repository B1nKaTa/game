extends TestCase

# A melee enemy strikes only with nothing solid between it and Grandpa, and walks round a prop
# instead of swinging through it.
const ShieldBehavior := preload("res://scripts/actors/behaviors/shield_behavior.gd")
const MeleeBehavior := preload("res://scripts/actors/behaviors/melee_behavior.gd")
const ExtraBehavior := preload("res://scripts/actors/behaviors/extra_behavior.gd")
const PackBehavior := preload("res://scripts/actors/behaviors/pack_behavior.gd")
const ExploderBehavior := preload("res://scripts/actors/behaviors/exploder_behavior.gd")
const PallbearerBehavior := preload("res://scripts/actors/behaviors/pallbearer_behavior.gd")
const T := RoomBackdrop.TILE
# Both on open cells either side of the prop's corner (the prop is x 128-160, y 64-96), 22 px apart,
# so the straight line between them clips the prop and is inside every start range below.
const NEAR_ENEMY := Vector2(120, 88)
const NEAR_HAROLD := Vector2(140, 98)


# A room of open floor, with a one-cell prop in the middle of row 2 when `prop` is true.
func _grid(prop: bool) -> WalkGrid:
	var rows := PackedStringArray()
	for y in 5:
		rows.append("....#...." if prop and y == 2 else ".........")
	return WalkGrid.from_rows(rows, "#")


func _enemy_at(def_id: String, grid: WalkGrid, enemy_at: Vector2, harold_at: Vector2) -> Enemy:
	var enemy := Enemy.new()
	enemy.setup(load("res://data/enemies/%s.tres" % def_id), null, 0.5)
	enemy.target = Node2D.new()
	enemy.walk_grid = grid
	enemy.global_position = enemy_at
	enemy.target.global_position = harold_at
	return enemy


func _enemy(def_id: String, prop: bool) -> Enemy:
	return _enemy_at(def_id, _grid(prop), NEAR_ENEMY, NEAR_HAROLD)


func _free(enemy: Enemy) -> void:
	enemy.target.free()
	enemy.free()


func test_a_prop_between_them_blocks_the_strike() -> void:
	var enemy := _enemy("intern_reaper", true)
	assert_false(enemy.can_strike_target())
	_free(enemy)


func test_a_clear_line_allows_the_strike() -> void:
	var enemy := _enemy("intern_reaper", false)
	assert_true(enemy.can_strike_target())
	_free(enemy)


func test_no_grid_a_ghost_or_a_mound_always_may_strike() -> void:
	var enemy := _enemy("intern_reaper", true)
	assert_false(enemy.can_strike_target(), "the prop blocks it first")
	enemy.submerged = true
	assert_true(enemy.can_strike_target(), "underground")
	enemy.submerged = false
	enemy.def = enemy.def.duplicate()
	enemy.def.ignores_walls = true
	assert_true(enemy.can_strike_target(), "a ghost")
	enemy.def.ignores_walls = false
	enemy.walk_grid = null
	assert_true(enemy.can_strike_target(), "no grid")
	_free(enemy)


func test_harold_against_a_wall_can_still_be_struck_from_the_side() -> void:
	# His feet 6 px below a top wall, an enemy level with him 20 px away on open floor.
	var rows := PackedStringArray([".........", ".........", "........."])
	rows[0] = "#########"
	var grid := WalkGrid.from_rows(rows, "#")
	var enemy := _enemy_at("denial_officer", grid, Vector2(100, T + 6.0), Vector2(120, T + 6.0))
	assert_true(enemy.can_strike_target(), "a thin line, not the body's width, which would sample the wall")
	_free(enemy)


func test_no_windup_starts_through_a_prop_but_does_once_clear() -> void:
	var cases := {"shield": ShieldBehavior, "melee": MeleeBehavior, "extra": ExtraBehavior, "pack": PackBehavior}
	for id: String in ["denial_officer", "intern_reaper"]:
		for prop in [true, false]:
			var enemy := _enemy(id, prop)
			for script: GDScript in cases.values():
				var behavior: EnemyBehavior = script.new()
				behavior.tick(enemy, 2.0)
				assert_eq(enemy.is_winding_up(), not prop, "%s with prop=%s via %s" % [id, str(prop), str(script.resource_path)])
				enemy.clear_warning()
			_free(enemy)


func test_the_exploder_does_not_light_through_a_prop() -> void:
	var blocked := _enemy("intern_reaper", true)
	var fuse: EnemyBehavior = ExploderBehavior.new()
	fuse.tick(blocked, 2.0)
	assert_false(blocked.is_winding_up(), "a prop stands between")
	_free(blocked)
	var open := _enemy("intern_reaper", false)
	var open_fuse: EnemyBehavior = ExploderBehavior.new()
	open_fuse.tick(open, 2.0)
	assert_true(open.is_winding_up())
	_free(open)


func test_a_lone_pallbearer_does_not_swing_through_a_prop() -> void:
	for prop in [true, false]:
		var enemy := _enemy("intern_reaper", prop)
		var behavior: EnemyBehavior = PallbearerBehavior.new()
		behavior._fight_alone(enemy, 2.0)
		assert_eq(enemy.is_winding_up(), not prop, "prop=%s" % str(prop))
		_free(enemy)


func test_the_chairmans_desk_slam_is_out_of_reach_behind_a_prop() -> void:
	var near := ChairmanBehavior.SLAM_START - 10.0
	assert_eq(ChairmanBehavior.slam_distance(near, true), near)
	assert_true(ChairmanBehavior.slam_distance(near, false) > ChairmanBehavior.SLAM_START)
	assert_true(ChairmanBehavior.slam_distance(near, false) < ChairmanBehavior.TAKEOVER_START, "and not far enough for the takeover")
	assert_eq(ChairmanBehavior.slam_distance(200.0, false), 200.0, "far off, nothing changes")


func test_a_shield_enemy_walks_round_a_prop_not_straight_at_harold() -> void:
	var enemy := _enemy_at("denial_officer", _grid(true), Vector2(T * 2.5, T * 2.5), Vector2(T * 6.5, T * 2.5))
	enemy.facing = Vector2.RIGHT
	var behavior: EnemyBehavior = ShieldBehavior.new()
	for i in 20:
		behavior.tick(enemy, 0.05)
	assert_true(absf(enemy.desired_velocity.normalized().y) > 0.05, "it turns off the straight line: %s" % str(enemy.desired_velocity))
	_free(enemy)
