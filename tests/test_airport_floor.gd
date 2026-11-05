extends TestCase

# Departures, Terminal Zero as a whole floor: its numbers, its own enemies and bosses, its look, its
# 33 rooms and whole floors built from them.
const SEEDS := 300
const DIR := "res://data/rooms/terminal_zero/"


func _def() -> FloorDef:
	return load("res://data/floors/terminal_zero.tres")


func _floor(id: String) -> FloorDef:
	return load("res://data/floors/%s.tres" % id)


func _basement() -> FloorDef:
	return _floor("floor_1")


func _pool() -> Array[RoomLayout]:
	return RoomCatalog.load_valid(_def().rooms_dir)


func _difference(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


func _barriers_in(layout: RoomLayout) -> int:
	return layout.cells_of(RoomLayout.SYMBOL_BARRIER).size()


# --- the path ---

func test_terminal_zero_is_the_open_fifth_floor_path_with_its_own_rooms() -> void:
	var def := _def()
	assert_eq(def.id, "terminal_zero")
	assert_eq(def.display_name, "Departures, Terminal Zero")
	assert_eq(def.depth, 5)
	assert_eq(def.clears_to_open, 0, "always open")
	assert_eq(def.open_after_depth, 4)
	assert_eq(def.danger, 7)
	assert_eq(def.rooms_dir, DIR, "no longer the Funeral Parlour's rooms")


func test_its_difficulty_follows_the_spec() -> void:
	var def := _def()
	assert_near(def.health_mult, 2.6)
	assert_near(def.pension_mult, 3.5)
	assert_eq(def.enemies_by_size, {"small": 8, "medium": 10, "large": 15})
	assert_eq(def.treasure_pension, ceili(_basement().treasure_pension * 3.0))
	assert_eq(def.clear_pension, _basement().clear_pension)
	assert_eq(def.prop_pension, _basement().prop_pension)
	assert_eq(def.vault_stone_level, _basement().vault_stone_level)
	assert_eq(def.chest_weights, {"lunchbox": 20, "locked": 20, "safe": 22, "urn": 19, "mimic": 19})


func test_its_own_enemies_and_bosses() -> void:
	var def := _def()
	var ids := {}
	for enemy: EnemyDef in def.enemies:
		ids[enemy.id] = true
	for id in ["tour_group", "baggage_handler", "lost_luggage", "airport_weeping_mourner", "airport_mall_cop"]:
		assert_true(ids.has(id), id)
	assert_eq(ids.size(), 5)
	assert_eq(def.enemy_weights.size(), 5)
	assert_eq(def.mini_boss.id, "sergeant_wanda")
	assert_eq(def.floor_boss.id, "augustine")
	assert_eq(def.mimic.id, "mimic")
	assert_eq(def.mini_boss.summon.id, "lost_luggage", "she calls the floor's own suitcases")
	assert_eq(def.floor_boss.summon.id, "tour_group", "he calls the floor's own tour groups")


func test_every_enemy_of_the_floor_can_be_told_apart() -> void:
	var defs: Array[EnemyDef] = []
	defs.assign(_def().enemies)
	for extra: EnemyDef in [_def().mini_boss, _def().floor_boss, _def().mini_boss.summon, _def().floor_boss.summon]:
		if not defs.has(extra):
			defs.append(extra)
	for i in defs.size():
		for j in range(i + 1, defs.size()):
			var a := SpriteVisual.readable(defs[i].color)
			var b := SpriteVisual.readable(defs[j].color)
			var size_gap := (defs[i].body_size - defs[j].body_size).length()
			assert_true(_difference(a, b) >= 0.25 or size_gap >= 12.0, "%s and %s look alike" % [defs[i].id, defs[j].id])


func test_every_enemy_stands_out_from_the_carpet() -> void:
	var palette := _def().room_palette()
	for enemy: EnemyDef in _def().enemies:
		var shown := SpriteVisual.readable(enemy.color)
		for tone in [palette.floor_a, palette.floor_b, palette.floor_c]:
			assert_true(_difference(shown, tone) >= 0.3, "%s on the carpet" % enemy.id)


# --- its look ---

func test_it_looks_like_no_other_floor() -> void:
	var mine := _def().room_palette()
	for id in ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "flashback_cinema"]:
		var theirs := _floor(id).room_palette()
		assert_true(_difference(mine.floor_a, theirs.floor_a) > 0.15, "floor against %s" % id)
		assert_true(_difference(mine.wall, theirs.wall) > 0.15, "walls against %s" % id)
	# The carpet's woven pattern is only small diamonds and dots, a shape the barrier lines' dashes and
	# post bases never use.
	assert_eq(mine.floor_pattern, 1, "a woven carpet")
	assert_eq(mine.wall_pattern, 0, "plain steel and glass")
	assert_true(mine.flicker < 0.06, "airport lights barely flicker")
	for kind in [RoomDecor.DEPARTURE_BOARD, RoomDecor.FLUORESCENT, RoomDecor.PLANT]:
		assert_true(mine.weight_of(kind) > 0.0, kind)
	for kind in [RoomDecor.GRASS, RoomDecor.BONES, RoomDecor.IV_STAND, RoomDecor.FURNACE, RoomDecor.GAUGE, RoomDecor.STAINED_GLASS, RoomDecor.COFFIN_STAND, RoomDecor.BENCH, RoomDecor.FOOD_TABLE]:
		assert_near(mine.weight_of(kind), 0.0, kind)


func test_departure_boards_are_decor_and_not_lights() -> void:
	assert_eq(RoomDecor.DEPARTURE_BOARD, "departure_board")
	assert_false(RoomDecor.is_light(RoomDecor.DEPARTURE_BOARD))


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


func test_rooms_have_terminal_props_barriers_in_most_and_chests() -> void:
	var counts := {"6": 0, "7": 0, "8": 0, "C": 0}
	var barrier_rooms := 0
	var boss_barriers := 999
	for layout in _pool():
		for symbol: String in counts:
			counts[symbol] += layout.cells_of(symbol).size()
		if _barriers_in(layout) > 0:
			barrier_rooms += 1
		if layout.room_type == RoomLayout.TYPE_FLOOR_BOSS:
			boss_barriers = mini(boss_barriers, _barriers_in(layout))
		for symbol in ["A", "Y", "O", "Q", "g", "Z", "K", "D", "J", "F", "f", "W", "L", "R", "M", "p", "U", "o", "h", "j", "r", "c", "a", "z", "e", "d", "q", ">", "<", "^", "v"]:
			assert_true(layout.cells_of(symbol).is_empty(), "no props of other floors, %s in %s" % [symbol, layout.resource_path])
	for symbol: String in ["6", "7", "8"]:
		assert_true(counts[symbol] >= 4, "'%s' appears %d times" % [symbol, counts[symbol]])
	assert_true(counts["C"] >= 2, "chest cells %d" % counts["C"])
	assert_true(barrier_rooms >= 16, "barrier rooms %d" % barrier_rooms)
	assert_true(barrier_rooms < _pool().size(), "but not every one")
	assert_true(boss_barriers >= 12, "every floor boss room has barriers for his gate change, the fewest is %d" % boss_barriers)


func test_terminal_props_break_as_the_spec_says() -> void:
	var trolley := LuggageTrolley.new()
	assert_true(trolley.is_solid())
	for source in [BreakableBlock.SOURCE_CANE, BreakableBlock.SOURCE_BLAST, BreakableBlock.SOURCE_BOSS]:
		assert_true(trolley.can_break_by(source), source)
	trolley.free()
	var stack := SuitcaseStack.new()
	assert_false(stack.is_solid(), "a stack of suitcases blocks nothing")
	assert_true(stack.can_break_by(BreakableBlock.SOURCE_CANE))
	stack.free()
	var seats := DepartureSeats.new()
	assert_true(seats.is_solid())
	assert_false(seats.can_break_by(BreakableBlock.SOURCE_CANE), "solid")
	assert_true(seats.can_break_by(BreakableBlock.SOURCE_BLAST))
	assert_true(seats.can_break_by(BreakableBlock.SOURCE_BOSS))
	assert_true(seats is RockBlock, "a row of seats can hide a coin at the furniture rate")
	seats.free()
	for symbol in [RoomLayout.SYMBOL_LUGGAGE_TROLLEY, RoomLayout.SYMBOL_SEATS]:
		assert_true(RoomLayout.SOLID_SYMBOLS.contains(symbol), symbol)
		assert_false(RoomLayout.WALLS.contains(symbol), symbol)
		assert_false(RoomLayout.DECOR_SYMBOLS.contains(symbol), symbol)
	assert_true(RoomLayout.WALLS_AND_BOMB_ONLY.contains(RoomLayout.SYMBOL_SEATS))
	assert_false(RoomLayout.WALLS_AND_BOMB_ONLY.contains(RoomLayout.SYMBOL_LUGGAGE_TROLLEY))
	assert_false(RoomLayout.SOLID_SYMBOLS.contains(RoomLayout.SYMBOL_SUITCASES))
	assert_true(RoomLayout.DECOR_SYMBOLS.contains(RoomLayout.SYMBOL_SUITCASES))
	for symbol in [RoomLayout.SYMBOL_BARRIER, RoomLayout.SYMBOL_LUGGAGE_TROLLEY, RoomLayout.SYMBOL_SUITCASES, RoomLayout.SYMBOL_SEATS]:
		assert_true(RoomLayout.ALLOWED.contains(symbol), symbol)


func test_a_boss_fits_where_it_starts() -> void:
	# tests/test_boss_spawn_room.gd checks every floor, this one included. Here, a reminder of why the
	# boss rooms leave the cells round B open: Augustine is wider and taller than a cell.
	var augustine := _def().floor_boss
	assert_true(augustine.body_size.x * 0.8 > RoomBackdrop.TILE and augustine.body_size.y * 0.8 > RoomBackdrop.TILE)
	for layout in _pool():
		if layout.room_type != RoomLayout.TYPE_FLOOR_BOSS:
			continue
		var cell := layout.cells_of("B")[0]
		for y in range(-1, 2):
			for x in range(-1, 2):
				assert_false(layout.is_solid_at(cell + Vector2i(x, y)), "%s round B" % layout.resource_path)


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
