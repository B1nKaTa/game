extends TestCase

const SEEDS := 1000
const FLOORS: Array[String] = [
	"res://data/floors/floor_1.tres",
	"res://data/floors/cemetery.tres",
	"res://data/floors/sunset_shores.tres",
	"res://data/floors/furnace_works.tres",
	"res://data/floors/funeral_parlour.tres",
	"res://data/floors/golden_years_mall.tres",
]


func _arcade_pool() -> Array[RoomLayout]:
	return RoomCatalog.load_valid(FloorBuilder.ARCADE_DIR)


func _build(seed_value: int, pool: Array[RoomLayout], def: FloorDef) -> FloorMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return FloorBuilder.build_from_pool(rng, def, pool)


func _arcades(map: FloorMap) -> Array[FloorRoom]:
	var found: Array[FloorRoom] = []
	for room in map.rooms:
		if room.room_type == RoomLayout.TYPE_ARCADE:
			found.append(room)
	return found


func _open_rows(width: int, height: int) -> Array:
	var rows := ["#".repeat(width)]
	for y in range(1, height - 1):
		rows.append("#" + ".".repeat(width - 2) + "#")
	rows.append("#".repeat(width))
	return rows


# --- the floor definition ---

func test_every_floor_rolls_an_arcade_one_time_in_four_by_default() -> void:
	assert_near(FloorDef.new().arcade_chance, 0.25)
	for path in FLOORS:
		var def: FloorDef = load(path)
		assert_near(def.arcade_chance, 0.25, path)


# --- arcade layouts ---

func test_arcade_layouts_are_valid_safe_and_hold_one_of_each_table() -> void:
	var sizes := {}
	var found := 0
	for layout in _arcade_pool():
		assert_eq(layout.room_type, RoomLayout.TYPE_ARCADE, layout.resource_path)
		found += 1
		sizes[layout.size_class()] = true
		assert_eq(layout.validate().size(), 0, "%s %s" % [layout.resource_path, str(layout.validate())])
		assert_eq(layout.cells_of(RoomLayout.SYMBOL_GAME).size(), ArcadeTable.GAMES.size(), "one table for each game, %s" % layout.resource_path)
		assert_true(layout.merchant_cell() != Vector2i(-1, -1), "a spot for the Dealer, %s" % layout.resource_path)
		assert_eq(layout.cells_of("E").size(), 0, "an arcade holds no fight")
		assert_eq(layout.cells_of("B").size(), 0)
		var dealer := layout.merchant_cell()
		for table in layout.cells_of(RoomLayout.SYMBOL_GAME):
			assert_true(maxi(absi(dealer.x - table.x), absi(dealer.y - table.y)) >= RoomLayout.PICKUP_SPACING, "the Dealer stands clear of the tables, %s" % layout.resource_path)
	assert_eq(found, 2)
	assert_true(sizes.has(RoomLayout.SIZE_SMALL) and sizes.has(RoomLayout.SIZE_MEDIUM), str(sizes))


func test_an_arcade_with_a_fight_or_too_few_tables_fails() -> void:
	var rows := _open_rows(20, 11)
	rows[7] = "#....G....G....G...#"
	rows[3] = "#...E..............#"
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_ARCADE
	layout.rows = PackedStringArray(rows)
	assert_true(layout.validate().size() > 0, "an enemy cell is refused")
	rows[3] = "#..................#"
	rows[7] = "#....G....G........#"
	layout.rows = PackedStringArray(rows)
	assert_true(layout.validate().size() > 0, "two tables are not enough")
	rows[7] = "#....G....G....G...#"
	layout.rows = PackedStringArray(rows)
	assert_eq(layout.validate().size(), 0, str(layout.validate()))


func test_game_tables_are_solid_and_must_be_reached() -> void:
	assert_true(RoomLayout.SOLID_SYMBOLS.contains(RoomLayout.SYMBOL_GAME))
	assert_true(RoomLayout.ALLOWED.contains(RoomLayout.SYMBOL_GAME))
	assert_true(RoomLayout.MUST_REACH_WITHOUT_BREAKING.contains(RoomLayout.SYMBOL_GAME))


func test_the_arcade_has_a_die_icon_a_color_and_counts_as_a_detour() -> void:
	assert_eq(RoomRules.door_icon(RoomLayout.TYPE_ARCADE), RoomRules.ARCADE_ICON)
	assert_true(FloorMapView.ROOM_COLORS.has(RoomLayout.TYPE_ARCADE))
	var room := FloorRoom.new()
	room.room_type = RoomLayout.TYPE_ARCADE
	assert_true(room.is_detour())
	assert_false(room.needs_a_bomb(), "a plain door leads in")


# --- arcades on a floor ---

func test_about_one_floor_in_four_hangs_an_arcade_off_a_combat_room() -> void:
	var arcade := _arcade_pool()
	for path in FLOORS:
		var def: FloorDef = load(path)
		var pool := RoomCatalog.load_valid(def.rooms_dir)
		pool.append_array(arcade)
		var with_one := 0
		for seed_value in SEEDS:
			var map := _build(seed_value, pool, def)
			if map == null:
				assert_true(false, "%s seed %d built nothing" % [path, seed_value])
				continue
			var found := _arcades(map)
			assert_true(found.size() <= 1, "%s seed %d" % [path, seed_value])
			with_one += found.size()
			for room in found:
				assert_false(map.main_path.has(room.id), "never on the main path, %s seed %d" % [path, seed_value])
				assert_eq(room.doors.size(), 1, "a dead end, %s seed %d" % [path, seed_value])
				var parent := map.room(room.doors.values()[0])
				assert_eq(parent.room_type, RoomLayout.TYPE_COMBAT, "%s seed %d" % [path, seed_value])
				assert_true(parent.id != map.boss_id)
		assert_true(with_one >= SEEDS * 0.2 and with_one <= SEEDS * 0.3, "%s had %d arcades in %d floors" % [path, with_one, SEEDS])


func test_a_floor_built_without_arcade_layouts_never_has_one() -> void:
	var def: FloorDef = load(FLOORS[0])
	var pool := RoomCatalog.load_valid(def.rooms_dir)
	for seed_value in 100:
		assert_eq(_arcades(_build(seed_value, pool, def)).size(), 0)


func test_the_floor_scene_pool_includes_the_arcade_layouts() -> void:
	var def: FloorDef = load(FLOORS[0])
	var types := {}
	for layout in FloorBuilder.pool_for(def):
		types[layout.room_type] = true
	assert_true(types.has(RoomLayout.TYPE_ARCADE))
	assert_true(types.has(RoomLayout.TYPE_COMBAT))


# --- the tables ---

func test_a_table_plays_three_pulls_or_one_hand_a_visit_and_refills() -> void:
	for game in ArcadeTable.GAMES:
		var table := ArcadeTable.new()
		table.setup(game, null)
		var wanted := 3 if game == ArcadeTable.SLOT else 1
		assert_eq(table.plays_left, wanted, game)
		for i in wanted:
			assert_true(table.use_play(), game)
		assert_eq(table.plays_left, 0, game)
		assert_false(table.use_play(), "no plays are left this visit, %s" % game)
		table.refill()
		assert_eq(table.plays_left, wanted, "coming back fills it again, %s" % game)
		table.free()


func test_nothing_breaks_a_table() -> void:
	var table := ArcadeTable.new()
	table.setup(ArcadeTable.POKER, null)
	for source in [BreakableBlock.SOURCE_BLAST, BreakableBlock.SOURCE_BOSS, BreakableBlock.SOURCE_CANE]:
		assert_false(table.hit_by(source), source)
	table.take_blast()
	assert_false(table.is_queued_for_deletion())
	table.free()


func test_the_arcade_palette_is_neon_and_leaves_the_floor_alone() -> void:
	var def: FloorDef = load(FLOORS[0])
	var base := def.room_palette()
	var before := base.fill_light
	var neon := RoomView.arcade_palette(base)
	assert_true(neon != base)
	assert_eq(base.fill_light, before, "the floor's own palette is untouched")
	assert_eq(neon.fill_light, RoomView.ARCADE_MAGENTA)
	assert_eq(neon.torch, RoomView.ARCADE_CYAN)
	assert_eq(neon.floor_pattern, 1)


func test_the_dealer_has_lines() -> void:
	assert_true(RoomView.DEALER.lines.size() >= 3)
	assert_eq(RoomView.DEALER.display_name, "Dealer")
