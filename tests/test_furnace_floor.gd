extends TestCase

const SEEDS := 300
const DIR := "res://data/rooms/furnace_works/"


func _def() -> FloorDef:
	return load("res://data/floors/furnace_works.tres")


func _sunset() -> FloorDef:
	return load("res://data/floors/sunset_shores.tres")


func _cemetery() -> FloorDef:
	return load("res://data/floors/cemetery.tres")


func _basement() -> FloorDef:
	return load("res://data/floors/floor_1.tres")


func _pool() -> Array[RoomLayout]:
	return RoomCatalog.load_valid(_def().rooms_dir)


func _difference(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


# --- the path ---

func test_the_furnace_works_keeps_its_place_and_its_lock() -> void:
	var def := _def()
	assert_eq(def.id, "furnace_works")
	assert_eq(def.display_name, "The Furnace Works")
	assert_eq(def.depth, 2)
	assert_eq(def.open_after_depth, 2)
	assert_eq(def.clears_to_open, 1)
	assert_true(def.danger > _sunset().danger)
	assert_false(def.closed_hint.is_empty())
	assert_eq(def.rooms_dir, DIR)


func test_its_difficulty_follows_the_spec() -> void:
	var def := _def()
	assert_near(def.health_mult, 1.4)
	assert_near(def.pension_mult, 1.5)
	assert_eq(def.enemies_by_size, {"small": 5, "medium": 7, "large": 12})
	assert_eq(def.vault_stone_level, _basement().vault_stone_level)
	assert_eq(def.treasure_pension, _sunset().treasure_pension)
	assert_eq(def.clear_pension, _sunset().clear_pension)
	assert_eq(def.prop_pension, _sunset().prop_pension)


func test_its_own_enemies_and_bosses() -> void:
	var def := _def()
	var ids := {}
	for enemy: EnemyDef in def.enemies:
		ids[enemy.id] = true
	for id in ["stoker", "steam_valve", "soot_ghost", "furnace_intern_reaper", "furnace_burnt_out_auditor"]:
		assert_true(ids.has(id), id)
	assert_eq(ids.size(), 5)
	assert_eq(def.mini_boss.id, "foreman_klaus")
	assert_eq(def.floor_boss.id, "old_smokey")


func test_every_enemy_of_the_floor_can_be_told_apart() -> void:
	var defs: Array[EnemyDef] = []
	defs.assign(_def().enemies)
	defs.append(_def().mini_boss)
	defs.append(_def().floor_boss)
	for i in defs.size():
		for j in range(i + 1, defs.size()):
			var a := SpriteVisual.readable(defs[i].color)
			var b := SpriteVisual.readable(defs[j].color)
			var size_gap := (defs[i].body_size - defs[j].body_size).length()
			assert_true(_difference(a, b) >= 0.25 or size_gap >= 12.0, "%s and %s look alike" % [defs[i].id, defs[j].id])


# --- its look ---

func test_it_looks_like_no_other_floor() -> void:
	var mine := _def().room_palette()
	for theirs: RoomPalette in [_basement().room_palette(), _cemetery().room_palette(), _sunset().room_palette()]:
		assert_true(_difference(mine.floor_a, theirs.floor_a) > 0.15, "floor")
		assert_true(_difference(mine.wall, theirs.wall) > 0.15, "walls")
		assert_true(_difference(mine.darkness, theirs.darkness) > 0.0 or _difference(mine.ambient, theirs.ambient) > 0.1, "light")
	assert_true(mine.torch.r > mine.torch.b * 3.0 and mine.fill_light.r > mine.fill_light.b * 2.0, "orange firelight")
	assert_true(mine.flicker > 0.0 and mine.flicker <= 0.1, "a subtle flicker")
	assert_eq(mine.floor_pattern, 2, "iron grating")
	assert_eq(mine.wall_pattern, 1, "brick walls")
	for kind in [RoomDecor.FURNACE, RoomDecor.GAUGE, RoomDecor.PIPE, RoomDecor.COAL_DUST]:
		assert_true(mine.weight_of(kind) > 0.0, kind)
	for kind in [RoomDecor.GRASS, RoomDecor.BONES, RoomDecor.PLANT, RoomDecor.IV_STAND]:
		assert_near(mine.weight_of(kind), 0.0, kind)


func test_a_flicker_is_a_small_wobble_around_the_light() -> void:
	for step in 50:
		var factor := LightFlicker.factor(0.08, step * 0.07, 1.3)
		assert_true(factor >= 0.92 - 0.001 and factor <= 1.08 + 0.001, str(factor))
	assert_near(LightFlicker.factor(0.0, 3.0, 1.0), 1.0)


func test_a_furnace_glows_from_the_wall_like_a_lantern() -> void:
	assert_true(RoomDecor.is_light(RoomDecor.FURNACE))
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_HEALING
	var rows := PackedStringArray(["#".repeat(20)])
	for y in range(1, 10):
		rows.append("#" + ".".repeat(18) + "#")
	rows.append("#".repeat(20))
	rows[4] = rows[4].substr(0, 9) + "H" + rows[4].substr(10)
	layout.rows = rows
	var palette := _def().room_palette()
	for seed_value in 20:
		for item in RoomDecor.plan(layout, palette, seed_value):
			if item["kind"] == RoomDecor.FURNACE:
				assert_eq(layout.symbol_at(item["cell"]), RoomLayout.SYMBOL_WALL)


# --- its rooms ---

func test_every_layout_in_the_folder_is_valid() -> void:
	var count := 0
	for resource in Content.load_dir(DIR):
		count += 1
		assert_eq(resource.validate().size(), 0, "%s: %s" % [resource.resource_path, str(resource.validate())])
	assert_true(count >= 30, "found %d" % count)


func test_combat_rooms_hold_one_more_fighter_by_size() -> void:
	var sizes := {}
	for layout in _pool():
		if layout.room_type == RoomLayout.TYPE_COMBAT:
			sizes[layout.size_class()] = sizes.get(layout.size_class(), 0) + 1
			assert_eq(_def().room_size_errors(layout).size(), 0, "%s %s" % [layout.resource_path, str(_def().room_size_errors(layout))])
	assert_true(sizes.get(RoomLayout.SIZE_SMALL, 0) >= 3, str(sizes))
	assert_true(sizes.get(RoomLayout.SIZE_MEDIUM, 0) >= 6, str(sizes))
	assert_true(sizes.get(RoomLayout.SIZE_LARGE, 0) >= 3, str(sizes))


func test_every_room_type_a_floor_uses_is_covered() -> void:
	var types := {}
	for layout in _pool():
		types[layout.room_type] = true
	for room_type: String in RoomLayout.REQUIRED:
		if not room_type in [RoomLayout.TYPE_CROSSROADS, RoomLayout.TYPE_LANDING, RoomLayout.TYPE_ARCADE, RoomLayout.TYPE_DEPARTMENT]:
			assert_true(types.has(room_type), room_type)


func test_rooms_are_stocked_and_some_have_vents() -> void:
	var counts := {"L": 0, "R": 0, "M": 0, "p": 0}
	var vent_rooms := 0
	var boss_vents := 0
	for layout in _pool():
		for symbol: String in counts:
			counts[symbol] += layout.cells_of(symbol).size()
		if not layout.cells_of(RoomLayout.SYMBOL_VENT).is_empty():
			vent_rooms += 1
		if layout.room_type == RoomLayout.TYPE_FLOOR_BOSS:
			boss_vents = mini(boss_vents if boss_vents > 0 else 999, layout.cells_of(RoomLayout.SYMBOL_VENT).size())
		for symbol in ["A", "Y", "O", "Q", "g", "Z", "K", "D", "J", "F", "f", "W"]:
			assert_true(layout.cells_of(symbol).is_empty(), "no props of other floors, %s in %s" % [symbol, layout.resource_path])
	for symbol: String in counts:
		assert_true(counts[symbol] >= 6, "'%s' appears %d times" % [symbol, counts[symbol]])
	assert_true(vent_rooms >= 6, "vent rooms %d" % vent_rooms)
	assert_true(boss_vents >= 12, "every floor boss room has a vent grid, the smallest has %d" % boss_vents)


func test_boiler_hall_props_break_as_the_spec_says() -> void:
	for prop: BreakableBlock in [CoalSack.new(), FurnaceCrate.new()]:
		assert_true(prop.is_solid())
		for source in [BreakableBlock.SOURCE_CANE, BreakableBlock.SOURCE_BLAST, BreakableBlock.SOURCE_BOSS]:
			assert_true(prop.can_break_by(source), source)
		prop.free()
	var stub := PipeValve.new()
	assert_false(stub.is_solid())
	assert_true(stub.can_break_by(BreakableBlock.SOURCE_CANE))
	stub.free()
	var heap := CoalHeap.new()
	assert_true(heap.is_solid())
	assert_true(heap.can_break_by(BreakableBlock.SOURCE_BLAST))
	assert_true(heap.can_break_by(BreakableBlock.SOURCE_BOSS))
	assert_false(heap.can_break_by(BreakableBlock.SOURCE_CANE))
	heap.free()
	assert_true(RoomLayout.WALLS_AND_BOMB_ONLY.contains(RoomLayout.SYMBOL_COAL_HEAP))
	for symbol in [RoomLayout.SYMBOL_COAL_SACK, RoomLayout.SYMBOL_CRATE, RoomLayout.SYMBOL_COAL_HEAP]:
		assert_true(RoomLayout.SOLID_SYMBOLS.contains(symbol), symbol)
		assert_false(RoomLayout.WALLS.contains(symbol), symbol)
	assert_false(RoomLayout.SOLID_SYMBOLS.contains(RoomLayout.SYMBOL_PIPE_VALVE))
	assert_true(RoomLayout.DECOR_SYMBOLS.contains(RoomLayout.SYMBOL_PIPE_VALVE))


# --- whole floors ---

func test_every_built_floor_follows_the_same_rules_as_the_first() -> void:
	var pool := _pool()
	var vaults := 0
	var sizes := {}
	for seed_value in SEEDS:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var map := FloorBuilder.build_from_pool(rng, _def(), pool)
		assert_true(map != null, "seed %d" % seed_value)
		if map == null:
			continue
		for room in map.rooms:
			sizes[room.layout.size_class()] = true
			vaults += 1 if room.room_type == RoomLayout.TYPE_VAULT else 0
		assert_true(map.only_hidden_rooms_need_a_bomb(), "seed %d" % seed_value)
		assert_true(map.hidden_rooms_are_dead_ends(), "seed %d" % seed_value)
		assert_eq(map.room(map.boss_id).room_type, RoomLayout.TYPE_FLOOR_BOSS)
		assert_eq(map.room(map.main_path[map.main_path.size() / 2]).room_type, RoomLayout.TYPE_MINI_BOSS)
	assert_eq(sizes.size(), 3)
	assert_true(vaults > 250, "most floors have a vault, %d" % vaults)


func test_vault_extras_find_their_spots_here_too() -> void:
	for layout in _pool():
		if layout.room_type == RoomLayout.TYPE_VAULT:
			assert_eq(layout.vault_extra_cells(RoomLayout.VAULT_EXTRAS).size(), RoomLayout.VAULT_EXTRAS, layout.resource_path)
