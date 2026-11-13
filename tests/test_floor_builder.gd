extends TestCase

const SEEDS := 300
const FLOOR_PATH := "res://data/floors/floor_1.tres"


func _def() -> FloorDef:
	return load(FLOOR_PATH)


func _pool() -> Array[RoomLayout]:
	return RoomCatalog.load_valid(_def().rooms_dir)


func _build(seed_value: int, pool: Array[RoomLayout], def: FloorDef = null) -> FloorMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return FloorBuilder.build_from_pool(rng, def if def != null else _def(), pool)


func _count_type(map: FloorMap, room_type: String) -> int:
	var found := 0
	for room in map.rooms:
		if room.room_type == room_type:
			found += 1
	return found


func test_regular_room_count_is_between_12_and_15() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var count := _build(seed_value, pool).main_rooms().size()
		assert_true(count >= 12 and count <= 15, "seed %d had %d rooms" % [seed_value, count])


func test_the_main_path_runs_from_the_start_to_the_boss_through_doors() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		assert_eq(map.main_path.size(), 7, "seed %d" % seed_value)
		assert_eq(map.main_path[0], map.start_id)
		assert_eq(map.main_path[-1], map.boss_id)
		for i in map.main_path.size() - 1:
			var side := map.room(map.main_path[i]).side_towards(map.main_path[i + 1])
			assert_true(side != Vector2i.ZERO, "seed %d step %d" % [seed_value, i])


func test_no_two_rooms_share_a_cell_and_all_fit_the_grid() -> void:
	var pool := _pool()
	var def := _def()
	var grid := Rect2i(Vector2i.ZERO, def.grid_size)
	for seed_value in SEEDS:
		var taken := {}
		for room in _build(seed_value, pool).rooms:
			assert_false(taken.has(room.cell), "seed %d cell %s" % [seed_value, str(room.cell)])
			assert_true(grid.has_point(room.cell), "seed %d cell %s" % [seed_value, str(room.cell)])
			taken[room.cell] = true


func test_every_door_joins_neighboring_cells_both_ways() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		for room in map.rooms:
			for side: Vector2i in room.doors:
				var other := map.room(room.doors[side])
				assert_eq(other.cell, room.cell + side, "seed %d room %d" % [seed_value, room.id])
				assert_eq(other.doors.get(-side), room.id, "seed %d room %d" % [seed_value, room.id])


func test_everything_is_reachable_without_a_bomb_except_secret_rooms_and_vaults() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		var reached := map.reached_without_bomb()
		for room in map.rooms:
			if room.room_type != RoomLayout.TYPE_SECRET and room.room_type != RoomLayout.TYPE_VAULT:
				assert_true(reached.has(room.id), "seed %d room %d (%s)" % [seed_value, room.id, room.room_type])


func test_every_room_can_be_walked_back_to_the_start() -> void:
	var pool := _pool()
	for seed_value in 50:
		var map := _build(seed_value, pool)
		for room in map.rooms:
			var at := room.id
			var steps := 0
			while at != map.start_id and steps < map.rooms.size():
				at = map.next_step(at, map.start_id)
				steps += 1
			assert_eq(at, map.start_id, "seed %d room %d" % [seed_value, room.id])


func test_the_boss_has_one_door_at_the_end_of_the_main_path() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		var boss := map.room(map.boss_id)
		assert_eq(boss.room_type, RoomLayout.TYPE_FLOOR_BOSS)
		assert_eq(boss.doors.size(), 1, "seed %d" % seed_value)
		assert_eq(boss.doors.values()[0], map.main_path[-2], "seed %d" % seed_value)


func test_the_mini_boss_sits_halfway_and_cannot_be_skipped() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		assert_eq(_count_type(map, RoomLayout.TYPE_MINI_BOSS), 1)
		var mini_id := map.main_path[map.main_path.size() / 2]
		assert_eq(map.room(mini_id).room_type, RoomLayout.TYPE_MINI_BOSS, "seed %d" % seed_value)
		assert_false(map.walk_from(map.start_id, [mini_id]).has(map.boss_id), "seed %d skipped it" % seed_value)


# The start keeps a combat layout but is quiet: no enemies, none added, and it is the only quiet room.
func test_the_start_is_a_quiet_combat_room() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		var start := map.room(map.start_id)
		assert_eq(start.room_type, RoomLayout.TYPE_COMBAT)
		assert_eq(start.layout.room_type, RoomLayout.TYPE_COMBAT, "seed %d keeps a combat layout" % seed_value)
		assert_true(start.quiet, "seed %d" % seed_value)
		assert_eq(start.extra_enemies, 0, "seed %d" % seed_value)
		for room in map.rooms:
			if room.id != map.start_id:
				assert_false(room.quiet, "seed %d room %d" % [seed_value, room.id])


# Doors he can walk through from the start: a secret wall or a vault stone is no door until a bomb opens
# it, and nothing leads back to the Crossroads.
func _ways_on(map: FloorMap) -> int:
	var ways := 0
	for side: Vector2i in map.room(map.start_id).doors:
		var target := map.room(map.room(map.start_id).doors[side])
		if target.room_type != RoomLayout.TYPE_CROSSROADS and not target.needs_a_bomb():
			ways += 1
	return ways


func test_the_start_has_at_least_two_ways_on() -> void:
	var pool := _pool()
	var crossroads: RoomLayout = load("res://data/rooms/crossroads/crossroads.tres")
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		assert_true(_ways_on(map) >= 2, "seed %d has %d" % [seed_value, _ways_on(map)])
		assert_true(map.attach_crossroads(crossroads, Vector2i.LEFT) != null, "seed %d keeps a side for the Crossroads" % seed_value)
		assert_true(_ways_on(map) >= 2, "seed %d with its Crossroads" % seed_value)


# The two-ways check makes some attempts fail, so every floor must still build from every seed within
# FloorBuilder.MAX_ATTEMPTS, with two ways on from its quiet start.
func test_every_floor_builds_within_the_retry_budget() -> void:
	var seeds := RandomNumberGenerator.new()
	seeds.seed = 2026
	for path in ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "flashback_cinema", "last_resort_cruise", "seance_hotline", "terminal_zero", "head_office"]:
		var def: FloorDef = load("res://data/floors/%s.tres" % path)
		var pool := FloorBuilder.pool_for(def)
		for i in 300:
			var seed_value := seeds.randi()
			var map := _build(seed_value, pool, def)
			assert_true(map != null, "%s seed %d builds" % [path, seed_value])
			if map == null:
				return
			assert_true(map.room(map.start_id).quiet, "%s seed %d" % [path, seed_value])
			assert_true(_ways_on(map) >= 2, "%s seed %d has %d ways on" % [path, seed_value, _ways_on(map)])


# A checkpoint written before the quiet start rebuilds its floor by the old rule, so its room ids still
# name the same rooms; the start is quiet all the same.
func test_the_old_rule_still_builds_without_the_two_ways_check() -> void:
	var pool := _pool()
	var differs := 0
	for seed_value in SEEDS:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var old := FloorBuilder.build_from_pool(rng, _def(), pool, false)
		assert_true(old != null, "seed %d" % seed_value)
		assert_true(old.room(old.start_id).quiet, "seed %d" % seed_value)
		if RunCheckpoint.map_signature(old) != RunCheckpoint.map_signature(_build(seed_value, pool)):
			differs += 1
	assert_true(differs > 0, "the check changes some floors, so old checkpoints need the old rule")


func test_regular_rooms_hold_the_item_rooms_and_the_healing_room() -> void:
	var pool := _pool()
	var def := _def()
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		assert_eq(_count_type(map, RoomLayout.TYPE_ITEM), def.item_rooms, "seed %d" % seed_value)
		assert_eq(_count_type(map, RoomLayout.TYPE_HEALING), def.healing_rooms, "seed %d" % seed_value)


func test_rewards_are_mostly_on_branches_so_exploring_pays() -> void:
	var pool := _pool()
	var on_path := 0
	var total := 0
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		for room in map.main_rooms():
			if room.room_type in [RoomLayout.TYPE_ITEM, RoomLayout.TYPE_HEALING]:
				total += 1
				if map.main_path.has(room.id):
					on_path += 1
	assert_true(total > 0)
	assert_true(on_path * 4 < total, "%d of %d rewards are on the main path" % [on_path, total])


func test_layouts_match_room_types() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		for room in _build(seed_value, pool).rooms:
			assert_eq(room.layout.room_type, room.room_type)


func test_detours_are_dead_ends_off_regular_rooms() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		for room in map.rooms:
			if not room.is_detour():
				continue
			assert_eq(room.doors.size(), 1, "seed %d room %d" % [seed_value, room.id])
			var parent := map.room(room.doors.values()[0])
			assert_false(parent.is_detour(), "seed %d" % seed_value)
			assert_true(parent.id != map.boss_id, "seed %d: the boss must keep one door" % seed_value)


func test_side_rooms_hang_off_combat_rooms() -> void:
	var pool := _pool()
	var found := 0
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		for room in map.rooms:
			if room.room_type != RoomLayout.TYPE_SIDE:
				continue
			found += 1
			assert_eq(map.room(room.doors.values()[0]).room_type, RoomLayout.TYPE_COMBAT)
	assert_true(found > 0, "some floors have side rooms")


func test_every_floor_has_one_treasure_room_off_a_middle_room() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		assert_eq(_count_type(map, RoomLayout.TYPE_TREASURE), 1, "seed %d" % seed_value)
		for room in map.rooms:
			if room.room_type == RoomLayout.TYPE_TREASURE:
				assert_true(room.is_detour())
				var parent_id: int = room.doors.values()[0]
				assert_true(parent_id != map.start_id and parent_id != map.boss_id, "seed %d" % seed_value)


func test_the_slip_for_the_treasure_door_can_always_be_earned_first() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		var treasure_id := -1
		var mini_id := map.main_path[map.main_path.size() / 2]
		for room in map.rooms:
			if room.room_type == RoomLayout.TYPE_TREASURE:
				treasure_id = room.id
		assert_true(map.walk_from(map.start_id, [treasure_id]).has(mini_id), "seed %d" % seed_value)


func test_detours_do_not_count_as_regular_rooms() -> void:
	for room in _build(3, _pool()).main_rooms():
		assert_false(room.is_detour())


func test_same_seed_gives_same_floor() -> void:
	var pool := _pool()
	for seed_value in 20:
		var first := _build(seed_value, pool)
		var second := _build(seed_value, pool)
		assert_eq(first.rooms.size(), second.rooms.size())
		assert_eq(first.main_path, second.main_path)
		for i in first.rooms.size():
			assert_eq(first.rooms[i].layout, second.rooms[i].layout)
			assert_eq(first.rooms[i].cell, second.rooms[i].cell)
			assert_eq(first.rooms[i].doors, second.rooms[i].doors)


func test_different_seeds_give_different_floors() -> void:
	var pool := _pool()
	var shapes := {}
	for seed_value in 20:
		var cells := []
		for room in _build(seed_value, pool).rooms:
			cells.append(room.cell)
		shapes[str(cells)] = true
	assert_true(shapes.size() > 10, "%d shapes" % shapes.size())


func test_missing_room_type_returns_null() -> void:
	var pool: Array[RoomLayout] = []
	for layout in _pool():
		if layout.room_type != RoomLayout.TYPE_FLOOR_BOSS:
			pool.append(layout)
	assert_true(_build(1, pool) == null)


func test_counts_come_from_the_floor_def() -> void:
	var def := FloorDef.new()
	def.main_path_rooms = 5
	def.min_rooms = 8
	def.max_rooms = 9
	def.item_rooms = 1
	def.healing_rooms = 0
	def.grid_size = Vector2i(7, 7)
	var pool := _pool()
	for seed_value in 50:
		var map := _build(seed_value, pool, def)
		assert_eq(map.main_path.size(), 5)
		assert_eq(map.room(map.main_path[2]).room_type, RoomLayout.TYPE_MINI_BOSS)
		var count := map.main_rooms().size()
		assert_true(count >= 8 and count <= 9, "seed %d had %d" % [seed_value, count])
		assert_eq(_count_type(map, RoomLayout.TYPE_ITEM), 1)
		assert_eq(_count_type(map, RoomLayout.TYPE_HEALING), 0)


func test_rooms_come_from_the_floor_def() -> void:
	var def := _def().duplicate() as FloorDef
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	assert_true(FloorBuilder.build(rng, def) != null, "builds from the rooms the def names")
	def.rooms_dir = "res://tests/support/"
	var other_rng := RandomNumberGenerator.new()
	other_rng.seed = 7
	assert_true(FloorBuilder.build(other_rng, def) == null, "a def naming no rooms builds nothing")


func test_a_grid_too_small_for_the_floor_returns_null_instead_of_hanging() -> void:
	var def := FloorDef.new()
	def.grid_size = Vector2i(2, 2)
	assert_true(_build(1, _pool(), def) == null)


func test_floor_data_loads() -> void:
	var def := _def()
	assert_eq(def.enemies.size(), 7)
	assert_eq(def.mini_boss.id, "senior_adjuster")
	assert_eq(def.floor_boss.id, "regional_reaper")
	assert_eq(def.main_path_rooms, 7)
	assert_eq(def.min_rooms, 12)
	assert_eq(def.max_rooms, 15)
