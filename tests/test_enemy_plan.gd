extends TestCase


func _rng(seed_value := 1) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _def(id: String, group := 1, cap := 0) -> EnemyDef:
	var def := EnemyDef.new()
	def.id = id
	def.group_size = group
	def.max_per_room = cap
	return def


func _floor_with(defs: Array, weights := PackedInt32Array()) -> FloorDef:
	var floor_def := FloorDef.new()
	floor_def.enemies = defs
	floor_def.enemy_weights = weights
	return floor_def


func _room(enemy_row := "#.......E..E.......#") -> RoomLayout:
	var rows := ["#".repeat(20)]
	for y in range(1, 10):
		rows.append(enemy_row if y == 5 else "#" + ".".repeat(18) + "#")
	rows.append("#".repeat(20))
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_COMBAT
	layout.rows = PackedStringArray(rows)
	return layout


func _doors_clear(layout: RoomLayout, cell: Vector2i) -> bool:
	for side in RoomLayout.SIDES:
		if Vector2(cell - layout.door_cell(side)).length() < RoomLayout.MIN_FIGHTER_DOOR_DISTANCE:
			return false
	return true


func test_each_enemy_cell_gets_one_enemy() -> void:
	var plan := EnemyPlan.plan(_room(), _floor_with([_def("a")]), 0, _rng())
	assert_eq(plan.size(), 2)
	assert_eq(plan[0]["def"].id, "a")
	assert_true(plan[0]["leader"])


func test_extra_enemies_take_free_cells_away_from_doors() -> void:
	var layout := _room()
	var plan := EnemyPlan.plan(layout, _floor_with([_def("a")]), 2, _rng())
	assert_eq(plan.size(), 4)
	var cells := {}
	for entry in plan:
		cells[entry["cell"]] = true
		assert_true(_doors_clear(layout, entry["cell"]), str(entry["cell"]))
		assert_false(layout.is_solid_at(entry["cell"]), str(entry["cell"]))
	assert_eq(cells.size(), 4, "no two share a cell")


func test_a_group_spawns_around_its_cell_and_only_one_pays() -> void:
	var layout := _room()
	var plan := EnemyPlan.plan(layout, _floor_with([_def("pack", 4)]), 0, _rng())
	assert_eq(plan.size(), 8, "two cells of four")
	var leaders := 0
	for entry in plan:
		if entry["leader"]:
			leaders += 1
		assert_false(layout.is_solid_at(entry["cell"]))
		assert_true(_doors_clear(layout, entry["cell"]), str(entry["cell"]))
	assert_eq(leaders, 2)


func test_a_group_near_walls_and_doors_stays_on_good_cells() -> void:
	var layout := _room()
	var rows := Array(layout.rows)
	rows[7] = "#...E..............#"
	rows[8] = "#...###............#"
	rows[5] = "#..................#"
	layout.rows = PackedStringArray(rows)
	var plan := EnemyPlan.plan(layout, _floor_with([_def("pack", 5)]), 0, _rng())
	assert_eq(plan.size(), 5)
	for entry in plan:
		assert_false(layout.is_solid_at(entry["cell"]))
		assert_true(_doors_clear(layout, entry["cell"]), str(entry["cell"]))


func test_a_capped_type_never_passes_its_cap() -> void:
	var capped := _def("capped", 1, 1)
	var other := _def("other")
	for seed_value in 30:
		var plan := EnemyPlan.plan(_room("#...E..E..E..E.....#"), _floor_with([capped, other], PackedInt32Array([50, 1])), 0, _rng(seed_value))
		var count := 0
		for entry in plan:
			if entry["def"] == capped:
				count += 1
		assert_true(count <= 1, str(count))


func test_when_every_type_is_capped_the_room_still_fills() -> void:
	var plan := EnemyPlan.plan(_room("#...E..E..E..E.....#"), _floor_with([_def("a", 1, 1)]), 0, _rng())
	assert_eq(plan.size(), 4, "a cell never stays empty")


func test_weights_shape_the_mix() -> void:
	var common := _def("common")
	var rare := _def("rare")
	var floor_def := _floor_with([common, rare], PackedInt32Array([9, 1]))
	var rng := _rng()
	var picks := {common: 0, rare: 0}
	for i in 1000:
		picks[EnemyPlan.pick(floor_def, {}, rng)] += 1
	assert_true(picks[common] > picks[rare] * 4, str(picks[common]))
	assert_true(picks[rare] > 0)


func test_missing_weights_count_as_one() -> void:
	assert_eq(_floor_with([_def("a"), _def("b")]).enemy_weight(1), 1)
	assert_eq(_floor_with([_def("a"), _def("b")], PackedInt32Array([4])).enemy_weight(0), 4)


func test_same_seed_gives_the_same_plan() -> void:
	var floor_def: FloorDef = load("res://data/floors/floor_1.tres")
	var layout: RoomLayout = load("res://data/rooms/floor_1/combat_large_01.tres")
	var a := EnemyPlan.plan(layout, floor_def, 2, _rng(9))
	var b := EnemyPlan.plan(layout, floor_def, 2, _rng(9))
	assert_eq(a.size(), b.size())
	for i in a.size():
		assert_eq(a[i]["cell"], b[i]["cell"])
		assert_true(a[i]["def"] == b[i]["def"])


func test_later_main_path_rooms_add_extra_enemies_by_the_floor_data() -> void:
	var floor_def: FloorDef = load("res://data/floors/floor_1.tres")
	assert_eq(floor_def.extra_enemies_at(1, 7), 0)
	assert_true(floor_def.extra_enemies_at(5, 7) >= 1)
	assert_true(floor_def.extra_enemies_at(5, 7) <= 2)
	var none := FloorDef.new()
	assert_eq(none.extra_enemies_at(6, 7), 0, "a floor without the data adds nothing")


func test_the_builder_marks_only_combat_rooms_on_the_main_path() -> void:
	var def: FloorDef = load("res://data/floors/floor_1.tres")
	var pool := RoomCatalog.load_valid("res://data/rooms/floor_1/")
	var saw_extra := false
	for seed_value in 40:
		var map := FloorBuilder.build_from_pool(_rng(seed_value), def, pool)
		for room in map.rooms:
			var step := map.main_path.find(room.id)
			if room.extra_enemies > 0:
				saw_extra = true
				assert_eq(room.room_type, RoomLayout.TYPE_COMBAT)
				assert_true(step >= 0)
				assert_eq(room.extra_enemies, def.extra_enemies_at(step, map.main_path.size()))
	assert_true(saw_extra)


func test_combat_rooms_hold_more_the_bigger_they_are() -> void:
	var least := {RoomLayout.SIZE_SMALL: 4, RoomLayout.SIZE_MEDIUM: 6, RoomLayout.SIZE_LARGE: 10}
	var layouts := RoomCatalog.load_valid("res://data/rooms/floor_1/")
	for layout in layouts:
		if layout.room_type != RoomLayout.TYPE_COMBAT:
			continue
		var count := layout.cells_of("E").size()
		var wanted: int = least[layout.size_class()]
		assert_true(count >= wanted, "%s has %d" % [layout.resource_path, count])


func test_behaviors_and_rooms_name_no_floor() -> void:
	for path in ["res://scripts/actors/behaviors/floor_boss_behavior.gd", "res://scripts/actors/behaviors/mini_boss_behavior.gd", "res://scripts/core/enemy_plan.gd", "res://scripts/world/room_view.gd"]:
		var source := FileAccess.get_file_as_string(path)
		assert_false(source.contains("floor_1"), path)
		assert_false(source.contains("data/enemies"), path)
