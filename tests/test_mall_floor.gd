extends TestCase

const SEEDS := 300
const DIR := "res://data/rooms/flashback_cinema/"


func _def() -> FloorDef:
	return load("res://data/floors/flashback_cinema.tres")


func _floor(id: String) -> FloorDef:
	return load("res://data/floors/%s.tres" % id)


func _basement() -> FloorDef:
	return _floor("floor_1")


func _pool() -> Array[RoomLayout]:
	return RoomCatalog.load_valid(_def().rooms_dir)


func _difference(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


# --- the path ---

func test_the_mall_is_the_unlocked_third_floor_path_with_its_own_rooms() -> void:
	var def := _def()
	assert_eq(def.id, "flashback_cinema")
	assert_eq(def.depth, 3)
	assert_eq(def.clears_to_open, 1, "it opens after a third-floor clear")
	assert_eq(def.rooms_dir, DIR, "no longer Sunset Shores' rooms")


func test_its_difficulty_follows_the_spec() -> void:
	var def := _def()
	assert_near(def.health_mult, 1.8)
	assert_near(def.pension_mult, 2.0)
	assert_eq(def.enemies_by_size, {"small": 6, "medium": 8, "large": 13})
	assert_eq(def.treasure_pension, ceili(_basement().treasure_pension * 2.0))
	assert_eq(def.clear_pension, _basement().clear_pension)
	assert_eq(def.prop_pension, _basement().prop_pension)
	assert_eq(def.vault_stone_level, _basement().vault_stone_level)
	assert_eq(def.chest_weights, _floor("funeral_parlour").chest_weights, "the same chest odds as the other third floor")


func test_its_own_enemies_and_bosses() -> void:
	var def := _def()
	var ids := {}
	for enemy: EnemyDef in def.enemies:
		ids[enemy.id] = true
	for id in ["mall_walker", "mall_cop", "perfume_sprayer", "mall_intern_reaper", "mall_notary_public"]:
		assert_true(ids.has(id), id)
	assert_eq(ids.size(), 5)
	assert_eq(def.enemy_weights.size(), 5)
	assert_eq(def.mini_boss.id, "gloria")
	assert_eq(def.floor_boss.id, "mall_santa")
	assert_eq(def.mimic.id, "mimic")


func test_every_enemy_of_the_floor_can_be_told_apart() -> void:
	var defs: Array[EnemyDef] = []
	defs.assign(_def().enemies)
	defs.append(_def().mini_boss)
	defs.append(_def().floor_boss)
	defs.append(_def().floor_boss.summon)
	for i in defs.size():
		for j in range(i + 1, defs.size()):
			var a := SpriteVisual.readable(defs[i].color)
			var b := SpriteVisual.readable(defs[j].color)
			var size_gap := (defs[i].body_size - defs[j].body_size).length()
			assert_true(_difference(a, b) >= 0.25 or size_gap >= 12.0, "%s and %s look alike" % [defs[i].id, defs[j].id])


# --- its look ---

func test_fluorescent_panels_are_lights_and_benches_are_not() -> void:
	assert_true(RoomDecor.is_light(RoomDecor.FLUORESCENT))
	assert_false(RoomDecor.is_light(RoomDecor.BENCH))
	assert_false(RoomDecor.is_light(RoomDecor.FOOD_TABLE))


# --- its rooms ---

func test_every_layout_in_the_folder_is_valid() -> void:
	var count := 0
	for resource in Content.load_dir(DIR):
		count += 1
		assert_eq(resource.validate().size(), 0, "%s: %s" % [resource.resource_path, str(resource.validate())])
	assert_true(count >= 30, "found %d" % count)


func test_combat_rooms_hold_the_third_floors_numbers() -> void:
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


func test_rooms_have_mall_props_strips_in_some_and_chests() -> void:
	var counts := {"a": 0, "z": 0, "e": 0, "d": 0, "q": 0, "C": 0}
	var strip_rooms := 0
	var reversing := 0
	var boss_strips := 999
	for layout in _pool():
		for symbol: String in counts:
			counts[symbol] += layout.cells_of(symbol).size()
		var strips := 0
		for symbol in RoomLayout.STRIP_SYMBOLS:
			strips += layout.cells_of(symbol).size()
		if strips > 0:
			strip_rooms += 1
			reversing += 1 if layout.strips_reverse else 0
		if layout.room_type == RoomLayout.TYPE_FLOOR_BOSS:
			boss_strips = mini(boss_strips, strips)
		for symbol in ["A", "Y", "O", "Q", "g", "Z", "K", "D", "J", "F", "f", "W", "L", "R", "M", "p", "U", "o", "h", "j", "r", "c"]:
			assert_true(layout.cells_of(symbol).is_empty(), "no props of other floors, %s in %s" % [symbol, layout.resource_path])
	for symbol: String in ["a", "z", "e", "d", "q"]:
		assert_true(counts[symbol] >= 4, "'%s' appears %d times" % [symbol, counts[symbol]])
	assert_true(counts["C"] >= 2, "chest cells %d" % counts["C"])
	assert_true(strip_rooms >= 8, "strip rooms %d" % strip_rooms)
	assert_true(reversing >= 3, "rooms whose strips reverse %d" % reversing)
	assert_true(reversing < strip_rooms, "but not every one")
	assert_true(boss_strips >= 4, "every floor boss room has strips for his conveyor control, the fewest is %d" % boss_strips)


func test_mall_props_break_as_the_spec_says() -> void:
	for prop: BreakableBlock in [ShoppingCart.new(), GumballMachine.new()]:
		assert_true(prop.is_solid())
		for source in [BreakableBlock.SOURCE_CANE, BreakableBlock.SOURCE_BLAST, BreakableBlock.SOURCE_BOSS]:
			assert_true(prop.can_break_by(source), source)
		prop.free()
	var sign := SaleSign.new()
	assert_false(sign.is_solid())
	assert_true(sign.can_break_by(BreakableBlock.SOURCE_CANE))
	sign.free()
	for prop: BreakableBlock in [MallPlanter.new(), MallFountain.new()]:
		assert_true(prop.is_solid())
		assert_false(prop.can_break_by(BreakableBlock.SOURCE_CANE), "solid")
		assert_true(prop.can_break_by(BreakableBlock.SOURCE_BLAST))
		assert_true(prop.can_break_by(BreakableBlock.SOURCE_BOSS))
		prop.free()
	for symbol in [RoomLayout.SYMBOL_CART, RoomLayout.SYMBOL_GUMBALL, RoomLayout.SYMBOL_PLANTER, RoomLayout.SYMBOL_FOUNTAIN]:
		assert_true(RoomLayout.SOLID_SYMBOLS.contains(symbol), symbol)
		assert_false(RoomLayout.WALLS.contains(symbol), symbol)
		assert_false(RoomLayout.DECOR_SYMBOLS.contains(symbol), symbol)
	for symbol in [RoomLayout.SYMBOL_PLANTER, RoomLayout.SYMBOL_FOUNTAIN]:
		assert_true(RoomLayout.WALLS_AND_BOMB_ONLY.contains(symbol), symbol)
	assert_false(RoomLayout.SOLID_SYMBOLS.contains(RoomLayout.SYMBOL_SALE_SIGN))
	assert_true(RoomLayout.DECOR_SYMBOLS.contains(RoomLayout.SYMBOL_SALE_SIGN))


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
