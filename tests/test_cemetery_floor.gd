extends TestCase

const SEEDS := 300
const DIR := "res://data/rooms/cemetery/"


func _def() -> FloorDef:
	return load("res://data/floors/cemetery.tres")


func _first() -> FloorDef:
	return load("res://data/floors/floor_1.tres")


func _pool() -> Array[RoomLayout]:
	return RoomCatalog.load_valid(_def().rooms_dir)


func _build(seed_value: int, pool: Array[RoomLayout]) -> FloorMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return FloorBuilder.build_from_pool(rng, _def(), pool)


func _difference(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


# --- the path rule ---

func test_the_two_floors_are_named_for_display_only() -> void:
	assert_eq(_first().id, "floor_1")
	assert_eq(_first().display_name, "The Records Basement")
	assert_eq(_def().display_name, "The Unkempt Cemetery")


func test_the_records_basement_is_always_open() -> void:
	assert_true(_first().is_open(0))
	assert_true(_first().is_open(5))


func test_the_cemetery_opens_on_the_first_clear_of_any_path() -> void:
	assert_false(_def().is_open(0))
	assert_true(_def().is_open(1))
	assert_true(_def().is_open(4))
	assert_false(_def().closed_hint.is_empty(), "the chained sign says why")


func test_the_later_path_shows_more_danger() -> void:
	assert_true(_def().danger > _first().danger)


# --- what makes it its own floor ---

func test_the_floor_has_its_own_rooms_bosses_and_look() -> void:
	assert_true(_def().rooms_dir != _first().rooms_dir)
	assert_true(_def().mini_boss != _first().mini_boss)
	assert_true(_def().floor_boss != _first().floor_boss)
	var mine := _def().room_palette()
	var theirs := _first().room_palette()
	assert_true(_difference(mine.floor_a, theirs.floor_a) > 0.15, "floor")
	assert_true(_difference(mine.wall, theirs.wall) > 0.05, "walls")
	assert_true(_difference(mine.ambient, theirs.ambient) > 0.05, "light")
	assert_true(mine.floor_a.g > mine.floor_a.b, "mossy green")
	assert_true(mine.torch.b > mine.torch.r, "cold light, not torchlight")


func test_it_scatters_more_grass_stumps_and_moss() -> void:
	var mine := _def().room_palette()
	var theirs := _first().room_palette()
	assert_true(mine.decor_density > theirs.decor_density)
	assert_true(mine.weight_of(RoomDecor.GRASS) > theirs.weight_of(RoomDecor.GRASS))
	for kind in [RoomDecor.STUMP, RoomDecor.MOSS, RoomDecor.SAPLING]:
		assert_true(mine.weight_of(kind) > 0.0, kind)
		assert_near(theirs.weight_of(kind), 0.0, "the office has none, " + kind)
	assert_near(mine.weight_of(RoomDecor.COBWEB), 0.0, "no cobwebs outdoors")


func test_it_favors_the_newer_enemy_types() -> void:
	var def := _def()
	var ids := {}
	var total := 0
	var newer := 0
	for i in def.enemies.size():
		ids[def.enemies[i].id] = true
		total += def.enemy_weight(i)
		if def.enemies[i].id in ["seasonal_temp", "notary_public", "burnt_out_auditor", "denial_officer", "plot_holder"]:
			newer += def.enemy_weight(i)
	assert_true(ids.has("plot_holder"), "its own enemy")
	assert_true(newer * 4 >= total * 3, "%d of %d" % [newer, total])


func test_its_prices_match_the_first_floor() -> void:
	assert_eq(_def().clear_pension, _first().clear_pension)
	assert_eq(_def().treasure_pension, _first().treasure_pension)
	assert_eq(_def().prop_pension, _first().prop_pension)
	for def: EnemyDef in _def().enemies:
		assert_eq(def.pension_drop, 1, def.id)


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


# --- its rooms ---

func test_every_layout_in_the_folder_is_valid() -> void:
	var count := 0
	for resource in Content.load_dir(DIR):
		count += 1
		assert_eq(resource.validate().size(), 0, "%s: %s" % [resource.resource_path, str(resource.validate())])
	assert_true(count >= 30, "found %d" % count)


func test_combat_rooms_come_in_all_three_sizes() -> void:
	var sizes := {}
	for layout in _pool():
		if layout.room_type == RoomLayout.TYPE_COMBAT:
			sizes[layout.size_class()] = sizes.get(layout.size_class(), 0) + 1
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


func test_rooms_look_like_a_graveyard_with_as_many_fighters_as_the_first_floor() -> void:
	var counts := {RoomLayout.SYMBOL_GRAVESTONE: 0, RoomLayout.SYMBOL_DEAD_TREE: 0, RoomLayout.SYMBOL_GRASS: 0, RoomLayout.SYMBOL_STUMP: 0}
	var layouts := _pool()
	for layout in layouts:
		for symbol: String in counts:
			counts[symbol] += layout.cells_of(symbol).size()
		if layout.room_type == RoomLayout.TYPE_COMBAT:
			assert_eq(_def().room_size_errors(layout).size(), 0, layout.resource_path)
	for symbol: String in counts:
		assert_true(counts[symbol] >= 12, "'%s' appears %d times" % [symbol, counts[symbol]])


func test_new_props_keep_clear_of_doors_and_are_solid() -> void:
	for symbol in [RoomLayout.SYMBOL_GRAVESTONE, RoomLayout.SYMBOL_DEAD_TREE]:
		assert_true(RoomLayout.SOLID_SYMBOLS.contains(symbol), symbol)
		assert_true(RoomLayout.WALLS_AND_BOMB_ONLY.contains(symbol), symbol)
		assert_false(RoomLayout.WALL_LIKE.contains(symbol), symbol)
	assert_false(RoomLayout.SOLID_SYMBOLS.contains(RoomLayout.SYMBOL_STUMP), "a stump blocks nothing")
	for layout in _pool():
		for symbol in [RoomLayout.SYMBOL_GRAVESTONE, RoomLayout.SYMBOL_DEAD_TREE]:
			for cell in layout.cells_of(symbol):
				for side in RoomLayout.SIDES:
					var door := layout.door_cell(side)
					assert_true(absi(cell.x - door.x) > 1 or absi(cell.y - door.y) > 1, "%s %s" % [layout.resource_path, str(cell)])


func test_graveyard_props_break_like_rocks() -> void:
	for prop: BreakableBlock in [Gravestone.new(), DeadTree.new()]:
		assert_true(prop.is_solid())
		assert_true(prop.can_break_by(BreakableBlock.SOURCE_BLAST))
		assert_true(prop.can_break_by(BreakableBlock.SOURCE_BOSS))
		assert_false(prop.can_break_by(BreakableBlock.SOURCE_CANE))
		assert_true(prop.art_id() != RockBlock.new().art_id())
		prop.free()


# --- whole floors ---

func test_every_built_floor_follows_the_same_rules_as_the_first() -> void:
	var pool := _pool()
	var vaults := 0
	var sizes := {}
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		assert_true(map != null, "seed %d" % seed_value)
		var cells := {}
		for room in map.rooms:
			assert_false(cells.has(room.cell), "seed %d shares a cell" % seed_value)
			cells[room.cell] = true
			sizes[room.layout.size_class()] = true
			vaults += 1 if room.room_type == RoomLayout.TYPE_VAULT else 0
		assert_true(map.only_hidden_rooms_need_a_bomb(), "seed %d" % seed_value)
		assert_true(map.hidden_rooms_are_dead_ends(), "seed %d" % seed_value)
		assert_eq(map.room(map.boss_id).room_type, RoomLayout.TYPE_FLOOR_BOSS)
		assert_eq(map.room(map.boss_id).doors.size(), 1, "seed %d" % seed_value)
		assert_eq(map.room(map.main_path[map.main_path.size() / 2]).room_type, RoomLayout.TYPE_MINI_BOSS)
	assert_eq(sizes.size(), 3)
	assert_true(vaults > 250, "most floors have a vault, %d" % vaults)


func test_vault_extras_find_their_spots_here_too() -> void:
	for layout in _pool():
		if layout.room_type == RoomLayout.TYPE_VAULT:
			assert_eq(layout.vault_extra_cells(RoomLayout.VAULT_EXTRAS).size(), RoomLayout.VAULT_EXTRAS, layout.resource_path)


func test_decor_scatter_uses_the_new_kinds_and_stays_off_doors() -> void:
	var seen := {}
	for layout in _pool():
		for seed_value in 3:
			for item in RoomDecor.plan(layout, _def().room_palette(), seed_value):
				seen[item["kind"]] = true
				if not layout.rows[item["cell"].y][item["cell"].x] in RoomDecor.SYMBOL_KINDS:
					assert_eq(layout.symbol_at(item["cell"]) if item["kind"] != RoomDecor.LANTERN else ".", RoomLayout.SYMBOL_FLOOR)
	for kind in [RoomDecor.GRASS, RoomDecor.STUMP, RoomDecor.MOSS, RoomDecor.SAPLING]:
		assert_true(seen.has(kind), kind)


func test_a_gravestone_hides_a_coin_less_often_than_a_rock() -> void:
	assert_true(RoomRules.GRAVESTONE_COIN_CHANCE < RoomRules.ROCK_COIN_CHANCE)
	assert_true(RoomRules.gravestone_hides_coin(0.0))
	assert_false(RoomRules.gravestone_hides_coin(RoomRules.GRAVESTONE_COIN_CHANCE + 0.01))
