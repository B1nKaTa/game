extends TestCase

const SEEDS := 300
const DIR := "res://data/rooms/last_resort_cruise/"
# Every prop or hazard symbol of the other floors. The cruise lays none of them.
const OTHER_FLOORS := "XOQVZAYgJFKDfWLRMpUGojhrc><^vazdqe"


func _def() -> FloorDef:
	return load("res://data/floors/last_resort_cruise.tres")


func _floor(id: String) -> FloorDef:
	return load("res://data/floors/%s.tres" % id)


func _pool() -> Array[RoomLayout]:
	return RoomCatalog.load_valid(_def().rooms_dir)


func _difference(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


# --- the path ---

func test_the_cruise_is_the_open_fourth_floor_path_with_its_own_rooms() -> void:
	var def := _def()
	assert_eq(def.id, "last_resort_cruise")
	assert_eq(def.display_name, "The Last Resort Cruise")
	assert_eq(def.depth, 4)
	assert_eq(def.open_after_depth, 3)
	assert_eq(def.clears_to_open, 0)
	assert_eq(def.danger, 5)
	assert_eq(def.rooms_dir, DIR, "no longer the Funeral Parlour's rooms")


func test_its_difficulty_follows_the_spec() -> void:
	var def := _def()
	var basement := _floor("floor_1")
	assert_near(def.health_mult, 2.2)
	assert_near(def.pension_mult, 2.5)
	assert_eq(def.enemies_by_size, {"small": 7, "medium": 9, "large": 14})
	assert_eq(def.chest_weights, {"lunchbox": 26, "locked": 22, "safe": 20, "urn": 16, "mimic": 16})
	assert_eq(def.treasure_pension, 20)
	assert_eq(def.treasure_pension, ceili(basement.treasure_pension * 2.5))
	assert_eq(def.clear_pension, basement.clear_pension)
	assert_eq(def.prop_pension, basement.prop_pension)
	assert_eq(def.vault_stone_level, basement.vault_stone_level)


func test_its_own_enemies_and_bosses() -> void:
	var def := _def()
	var ids := {}
	for enemy: EnemyDef in def.enemies:
		ids[enemy.id] = true
	for id in ["early_bird_diner", "shuffleboard_shark", "sunburnt_sunbather", "cruise_orderly", "cruise_stoker"]:
		assert_true(ids.has(id), id)
	assert_eq(ids.size(), 5)
	assert_eq(def.enemy_weights, PackedInt32Array([4, 2, 2, 4, 1]))
	assert_eq(def.mini_boss.id, "lorraine")
	assert_eq(def.floor_boss.id, "commodore_wellington")
	assert_eq(def.mimic.id, "mimic")


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


# The string lights wash a pale body toward white on the planks, so two pale people read as one, as the
# first Early Bird Diners did beside the white Orderly.
func test_only_one_of_the_floors_people_is_pale() -> void:
	var defs: Array[EnemyDef] = []
	defs.assign(_def().enemies)
	defs.append(_def().mini_boss)
	defs.append(_def().floor_boss)
	var pale: Array[String] = []
	for enemy in defs:
		if enemy.color.s < 0.4:
			pale.append(enemy.id)
	assert_true(pale.size() <= 1, "pale bodies: %s" % str(pale))


# --- its look ---

func test_it_looks_like_no_other_floor() -> void:
	var mine := _def().room_palette()
	for id in ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "golden_years_mall"]:
		var theirs := _floor(id).room_palette()
		assert_true(_difference(mine.floor_a, theirs.floor_a) > 0.15, "floor against %s" % id)
		assert_true(_difference(mine.wall, theirs.wall) > 0.15, "walls against %s" % id)
		assert_true(theirs.floor_pattern != mine.floor_pattern, "%s has its own floor pattern" % id)
		assert_true(theirs.wall_pattern != mine.wall_pattern, "%s has its own walls" % id)
	assert_eq(mine.floor_pattern, RoomBackdrop.FLOOR_TEAK_DECK, "teak planks")
	assert_eq(mine.wall_pattern, RoomBackdrop.WALL_SHIP_RAIL, "a white ship's rail")
	assert_true(mine.wall.b > mine.wall.r * 2.0, "a navy hull")
	assert_true(mine.flicker > 0.0 and mine.flicker <= 0.08, "the string lights wobble a little")
	assert_true(mine.weight_of(RoomDecor.LANTERN) > 0.0, "string lights")
	for kind in [RoomDecor.GRASS, RoomDecor.BONES, RoomDecor.IV_STAND, RoomDecor.FURNACE, RoomDecor.GAUGE, RoomDecor.STAINED_GLASS, RoomDecor.COFFIN_STAND, RoomDecor.FLUORESCENT]:
		assert_near(mine.weight_of(kind), 0.0, kind)


func test_the_swabbed_deck_reads_on_the_planks() -> void:
	var mine := _def().room_palette()
	assert_true(mine.wet.a >= 0.45, "the Commodore's wet patches are not faint")
	assert_true(mine.wet.b > mine.floor_c.b + 0.4, "and bluer than the palest plank")


# --- its rooms ---

func test_every_layout_in_the_folder_is_valid() -> void:
	var count := 0
	for resource in Content.load_dir(DIR):
		count += 1
		assert_eq(resource.validate().size(), 0, "%s: %s" % [resource.resource_path, str(resource.validate())])
	assert_true(count >= 30, "found %d" % count)


func test_combat_rooms_hold_the_fourth_floors_numbers() -> void:
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


func test_rooms_have_the_deck_props_a_pool_and_chests() -> void:
	var counts := {"b": 0, "0": 0, "1": 0, "2": 0, "C": 0}
	var pool_rooms := 0
	for layout in _pool():
		for symbol: String in counts:
			counts[symbol] += layout.cells_of(symbol).size()
		if not layout.cells_of(RoomLayout.SYMBOL_POOL).is_empty():
			pool_rooms += 1
		for symbol in OTHER_FLOORS:
			assert_true(layout.cells_of(symbol).is_empty(), "no props of other floors, %s in %s" % [symbol, layout.resource_path])
	for symbol: String in ["b", "0", "1", "2"]:
		assert_true(counts[symbol] >= 6, "'%s' appears %d times" % [symbol, counts[symbol]])
	assert_true(counts["C"] >= 2, "chest cells %d" % counts["C"])
	assert_true(pool_rooms >= 6, "pool rooms %d" % pool_rooms)


func test_about_two_thirds_of_the_rooms_roll() -> void:
	var pool := _pool()
	var rolling := 0
	for layout in pool:
		if layout.ship_rolls:
			rolling += 1
		if layout.room_type == RoomLayout.TYPE_FLOOR_BOSS:
			assert_true(layout.ship_rolls, "the Commodore can always turn the helm, %s" % layout.resource_path)
	var share := float(rolling) / float(pool.size())
	assert_true(share >= 0.55 and share <= 0.8, "%d of %d roll" % [rolling, pool.size()])


func test_the_cruise_props_break_as_the_spec_says() -> void:
	var chair := DeckChair.new()
	assert_true(chair.is_solid())
	for source in [BreakableBlock.SOURCE_CANE, BreakableBlock.SOURCE_BLAST, BreakableBlock.SOURCE_BOSS]:
		assert_true(chair.can_break_by(source), source)
	chair.free()
	var tray := BuffetTray.new()
	assert_false(tray.is_solid())
	assert_true(tray.can_break_by(BreakableBlock.SOURCE_CANE))
	tray.free()
	var davit := LifeboatDavit.new()
	assert_true(davit.is_solid())
	assert_true(davit.can_break_by(BreakableBlock.SOURCE_BLAST))
	assert_true(davit.can_break_by(BreakableBlock.SOURCE_BOSS))
	assert_false(davit.can_break_by(BreakableBlock.SOURCE_CANE))
	davit.free()
	var water: Node = PoolWater.new()
	assert_true(water is Hole, "the pool is crossed by nobody who walks, and shots fly over")
	assert_false(water is BreakableBlock, "and nothing breaks it")
	water.free()
	for symbol in [RoomLayout.SYMBOL_DECK_CHAIR, RoomLayout.SYMBOL_BUFFET_TRAY, RoomLayout.SYMBOL_POOL, RoomLayout.SYMBOL_DAVIT]:
		assert_true(RoomLayout.ALLOWED.contains(symbol), symbol)
	for symbol in [RoomLayout.SYMBOL_DECK_CHAIR, RoomLayout.SYMBOL_POOL, RoomLayout.SYMBOL_DAVIT]:
		assert_true(RoomLayout.SOLID_SYMBOLS.contains(symbol), symbol)
		assert_false(RoomLayout.DECOR_SYMBOLS.contains(symbol), symbol)
	assert_false(RoomLayout.WALLS.contains(RoomLayout.SYMBOL_DECK_CHAIR))
	assert_false(RoomLayout.WALLS_AND_BOMB_ONLY.contains(RoomLayout.SYMBOL_DECK_CHAIR), "the cane clears a chair")
	assert_true(RoomLayout.WALLS.contains(RoomLayout.SYMBOL_POOL), "no route needs the pool")
	assert_true(RoomLayout.WALLS_AND_BOMB_ONLY.contains(RoomLayout.SYMBOL_DAVIT))
	assert_false(RoomLayout.WALLS.contains(RoomLayout.SYMBOL_DAVIT))
	assert_false(RoomLayout.WALL_LIKE.contains(RoomLayout.SYMBOL_POOL), "the pool is not drawn as wall")
	assert_false(RoomLayout.SOLID_SYMBOLS.contains(RoomLayout.SYMBOL_BUFFET_TRAY))
	assert_true(RoomLayout.DECOR_SYMBOLS.contains(RoomLayout.SYMBOL_BUFFET_TRAY))
	assert_true(RoomLayout.SYMBOL_DECK_CHAIR != "B", "a deck chair is never read as a boss")


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
