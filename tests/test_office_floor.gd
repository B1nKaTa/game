extends TestCase

# Head Office, Eternity Incorporated: the fifth floor's locked path and the game's last.

const SEEDS := 300
const DIR := "res://data/rooms/head_office/"


func _def() -> FloorDef:
	return load("res://data/floors/head_office.tres")


func _floor(id: String) -> FloorDef:
	return load("res://data/floors/%s.tres" % id)


func _pool() -> Array[RoomLayout]:
	return RoomCatalog.load_valid(_def().rooms_dir)


func _difference(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


# --- the path ---

func test_head_office_is_the_locked_fifth_floor_path_with_its_own_rooms() -> void:
	var def := _def()
	assert_eq(def.id, "head_office")
	assert_eq(def.display_name, "Head Office, Eternity Incorporated")
	assert_eq(def.depth, 5)
	assert_eq(def.open_after_depth, 5)
	assert_eq(def.clears_to_open, 1, "it opens after a fifth-floor clear")
	assert_eq(def.closed_hint, "Beat a fifth-floor boss first")
	assert_eq(def.danger, 8)
	assert_eq(def.rooms_dir, DIR, "no longer the Mall's rooms")


func test_its_difficulty_follows_the_spec() -> void:
	var def := _def()
	assert_near(def.health_mult, 2.6)
	assert_near(def.pension_mult, 3.0)
	assert_eq(def.enemies_by_size, {"small": 8, "medium": 10, "large": 15})
	assert_eq(def.treasure_pension, 24)
	assert_eq(def.chest_weights, {"lunchbox": 20, "locked": 20, "safe": 22, "urn": 19, "mimic": 19})
	assert_eq(def.clear_pension, _floor("floor_1").clear_pension)
	assert_eq(def.prop_pension, _floor("golden_years_mall").prop_pension)
	assert_eq(def.vault_stone_level, _floor("floor_1").vault_stone_level)


func test_its_own_enemies_and_bosses() -> void:
	var def := _def()
	var ids := {}
	for enemy: EnemyDef in def.enemies:
		ids[enemy.id] = true
	for id in ["yes_man", "paper_shredder", "hr_representative", "office_florist", "office_perfume_sprayer"]:
		assert_true(ids.has(id), id)
	assert_eq(ids.size(), 5)
	assert_eq(def.enemy_weights.size(), 5)
	assert_eq(def.mini_boss.id, "doreen")
	assert_eq(def.floor_boss.id, "chairman_of_the_board")
	assert_eq(def.mimic.id, "mimic")
	assert_true(def.mini_boss.is_boss and def.floor_boss.is_boss)
	assert_true(def.mini_boss.id != def.floor_boss.id, "first beats are paid once per boss")


func test_every_enemy_of_the_floor_can_be_told_apart() -> void:
	var defs: Array[EnemyDef] = []
	defs.assign(_def().enemies)
	defs.append(_def().mini_boss)
	defs.append(_def().floor_boss)
	if _def().floor_boss.summon != null:
		defs.append(_def().floor_boss.summon)
	for i in defs.size():
		for j in range(i + 1, defs.size()):
			var a := SpriteVisual.readable(defs[i].color)
			var b := SpriteVisual.readable(defs[j].color)
			var size_gap := (defs[i].body_size - defs[j].body_size).length()
			assert_true(_difference(a, b) >= 0.25 or size_gap >= 12.0, "%s and %s look alike" % [defs[i].id, defs[j].id])


# --- its look ---

func test_it_looks_like_no_other_floor() -> void:
	var mine := _def().room_palette()
	for id in ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "golden_years_mall"]:
		var theirs := _floor(id).room_palette()
		assert_true(_difference(mine.floor_a, theirs.floor_a) > 0.15, "floor against %s" % id)
		assert_true(_difference(mine.wall, theirs.wall) > 0.15, "walls against %s" % id)
	assert_eq(mine.floor_pattern, RoomBackdrop.FLOOR_OFFICE_CARPET, "carpet tiles")
	assert_eq(mine.wall_pattern, RoomBackdrop.WALL_OFFICE_PLASTER, "plaster over a dado")
	for kind in [RoomDecor.FICUS, RoomDecor.OFFICE_CHAIR, RoomDecor.FLUORESCENT]:
		assert_true(mine.weight_of(kind) > 0.0, kind)
	for kind in [RoomDecor.GRASS, RoomDecor.BONES, RoomDecor.COBWEB, RoomDecor.TORCH, RoomDecor.IV_STAND, RoomDecor.FURNACE, RoomDecor.GAUGE, RoomDecor.STAINED_GLASS, RoomDecor.COFFIN_STAND, RoomDecor.BENCH, RoomDecor.FOOD_TABLE]:
		assert_near(mine.weight_of(kind), 0.0, kind)


func test_it_closes_the_loop_with_the_records_basement_without_looking_like_it() -> void:
	var mine := _def().room_palette()
	var basement := _floor("floor_1").room_palette()
	assert_true(_difference(mine.floor_a, basement.floor_a) > 0.25, "beige carpet, not the basement's grey")
	assert_true(mine.floor_pattern != basement.floor_pattern)
	assert_true(mine.wall_pattern != basement.wall_pattern)
	assert_true(mine.fill_light.get_luminance() > basement.fill_light.get_luminance(), "bright office light, not a basement's gloom")


func test_new_decor_is_scatter_and_never_a_light_but_the_panels() -> void:
	assert_false(RoomDecor.is_light(RoomDecor.FICUS))
	assert_false(RoomDecor.is_light(RoomDecor.OFFICE_CHAIR))
	assert_true(RoomDecor.is_light(RoomDecor.FLUORESCENT))


# --- how it reads under its own bright light ---

# A colour as a strong light leaves it: brightened, and clipped at white.
func _lit(color: Color, light: float) -> Color:
	return Color(minf(color.r * light, 1.0), minf(color.g * light, 1.0), minf(color.b * light, 1.0))


func test_the_palest_carpet_under_a_wall_light_and_the_fill_stays_below_white() -> void:
	var palette := _def().room_palette()
	var light := Color(palette.ambient.r + palette.torch.r + palette.fill_light.r * Lighting.FILL_ENERGY,
		palette.ambient.g + palette.torch.g + palette.fill_light.g * Lighting.FILL_ENERGY,
		palette.ambient.b + palette.torch.b + palette.fill_light.b * Lighting.FILL_ENERGY)
	for tile: Color in [palette.floor_a, palette.floor_b, palette.floor_c]:
		var peak := maxf(tile.r * light.r, maxf(tile.g * light.g, tile.b * light.b))
		assert_true(peak < 1.0, "the carpet near a wall light burns to white (%.2f)" % peak)


func test_no_enemy_of_the_floor_washes_out_to_white_in_the_light() -> void:
	var defs: Array[EnemyDef] = []
	defs.assign(_def().enemies)
	defs.append(_def().mini_boss)
	defs.append(_def().floor_boss)
	defs.append(_def().mini_boss.summon)
	for def in defs:
		var lit := _lit(SpriteVisual.readable(def.color), 1.5)
		assert_true(minf(lit.r, minf(lit.g, lit.b)) < 0.85, "%s turns white in the office light" % def.id)


func test_the_bar_charts_gap_mark_stays_green_however_brightly_it_is_lit() -> void:
	for light: float in [1.0, 1.5, 2.0]:
		var lit := _lit(GapMark.GAP_COLOR, light)
		assert_true(lit.g - maxf(lit.r, lit.b) > 0.25, "green at %.1f" % light)
	var source := FileAccess.get_file_as_string("res://scripts/actors/behaviors/chairman_behavior.gd")
	assert_true(source.contains("GapMark.new()"), "the projections mark their gap with it")


# --- its rooms ---

func test_every_layout_in_the_folder_is_valid() -> void:
	var count := 0
	for resource in Content.load_dir(DIR):
		count += 1
		assert_eq(resource.validate().size(), 0, "%s: %s" % [resource.resource_path, str(resource.validate())])
	assert_true(count >= 30, "found %d" % count)


func test_combat_rooms_hold_the_fifth_floors_numbers() -> void:
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


func test_rooms_have_office_props_tape_in_many_and_chests() -> void:
	var counts := {"9": 0, "N": 0, "y": 0, "C": 0}
	var tape_rooms := 0
	for layout in _pool():
		for symbol: String in counts:
			counts[symbol] += layout.cells_of(symbol).size()
		if not layout.cells_of(RoomLayout.SYMBOL_RED_TAPE).is_empty():
			tape_rooms += 1
		for symbol in ["A", "Y", "O", "Q", "V", "g", "Z", "K", "D", "J", "F", "f", "W", "L", "R", "M", "p", "U", "o", "h", "j", "r", "c", ">", "<", "^", "v", "a", "z", "d", "q", "e"]:
			assert_true(layout.cells_of(symbol).is_empty(), "no props of other floors, %s in %s" % [symbol, layout.resource_path])
	for symbol: String in ["9", "N", "y"]:
		assert_true(counts[symbol] >= 4, "'%s' appears %d times" % [symbol, counts[symbol]])
	assert_true(counts["C"] >= 2, "chest cells %d" % counts["C"])
	assert_true(tape_rooms >= 10, "rooms with red tape %d" % tape_rooms)


func test_every_floor_boss_room_leaves_rows_for_the_chairmans_tape() -> void:
	for layout in _pool():
		if layout.room_type != RoomLayout.TYPE_FLOOR_BOSS:
			continue
		var grid := WalkGrid.from_layout(layout)
		var is_open := func(spot: Vector2) -> bool: return grid.is_open(WalkGrid.cell_of(spot))
		var boss := layout.cells_of("B")[0]
		var cells := ChairmanBehavior.tape_cells(layout.size_in_cells(), boss, is_open)
		assert_true(cells.size() >= 20, "%s tapes %d cells" % [layout.resource_path, cells.size()])


func test_office_props_break_as_the_spec_says() -> void:
	var cooler := WaterCooler.new()
	assert_true(cooler.is_solid())
	for source in [BreakableBlock.SOURCE_CANE, BreakableBlock.SOURCE_BLAST, BreakableBlock.SOURCE_BOSS]:
		assert_true(cooler.can_break_by(source), source)
	cooler.free()
	var tray := InTray.new()
	assert_false(tray.is_solid())
	assert_true(tray.can_break_by(BreakableBlock.SOURCE_CANE))
	tray.free()
	var partition := CubicleWall.new()
	assert_true(partition.is_solid())
	assert_false(partition.can_break_by(BreakableBlock.SOURCE_CANE), "solid")
	assert_true(partition.can_break_by(BreakableBlock.SOURCE_BLAST))
	assert_true(partition.can_break_by(BreakableBlock.SOURCE_BOSS))
	assert_true(partition is RockBlock, "it can hide a coin at the furniture rate")
	partition.free()
	for symbol in [RoomLayout.SYMBOL_WATER_COOLER, RoomLayout.SYMBOL_CUBICLE]:
		assert_true(RoomLayout.SOLID_SYMBOLS.contains(symbol), symbol)
		assert_false(RoomLayout.WALLS.contains(symbol), symbol)
		assert_false(RoomLayout.DECOR_SYMBOLS.contains(symbol), symbol)
	assert_true(RoomLayout.WALLS_AND_BOMB_ONLY.contains(RoomLayout.SYMBOL_CUBICLE))
	assert_false(RoomLayout.WALLS_AND_BOMB_ONLY.contains(RoomLayout.SYMBOL_WATER_COOLER), "the cane breaks a cooler")
	assert_false(RoomLayout.SOLID_SYMBOLS.contains(RoomLayout.SYMBOL_IN_TRAY))
	assert_true(RoomLayout.DECOR_SYMBOLS.contains(RoomLayout.SYMBOL_IN_TRAY))
	for symbol in [RoomLayout.SYMBOL_WATER_COOLER, RoomLayout.SYMBOL_CUBICLE, RoomLayout.SYMBOL_IN_TRAY, RoomLayout.SYMBOL_RED_TAPE]:
		assert_true(RoomLayout.ALLOWED.contains(symbol), symbol)
		assert_true("x9Ny".contains(symbol), "only the office's own symbols")


func test_the_floor_pattern_shares_no_shape_with_red_tape() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/room_backdrop.gd")
	var start := source.find("if _palette.floor_pattern == FLOOR_OFFICE_CARPET:")
	assert_true(start >= 0, "carpet tiles are drawn")
	var block := source.substr(start, source.find("continue", start) - start)
	assert_false(block.contains("draw_line"), "the carpet draws no lines, so no stripe or diagonal like the tape's")


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
