extends TestCase

const SEEDS := 300
const DIR := "res://data/rooms/fairways_end/"
# The symbols the earlier floors' props and hazards use, none of which belong on the golf course.
const OTHER_FLOORS := ["A", "Y", "O", "Q", "Z", "K", "D", "J", "F", "f", "W", "L", "R", "M", "p", "U", "o", "h", "j", "r", "c", "a", "z", "d", "q", "e", ">", "<", "^", "v"]


func _def() -> FloorDef:
	return load("res://data/floors/fairways_end.tres")


func _floor(id: String) -> FloorDef:
	return load("res://data/floors/%s.tres" % id)


func _basement() -> FloorDef:
	return _floor("floor_1")


func _pool() -> Array[RoomLayout]:
	return RoomCatalog.load_valid(_def().rooms_dir)


func _difference(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


# --- the path ---

func test_fairways_end_is_the_locked_fourth_floor_path_with_its_own_rooms() -> void:
	var def := _def()
	assert_eq(def.id, "fairways_end")
	assert_eq(def.display_name, "Fairway's End Golf Club")
	assert_eq(def.depth, 4)
	assert_eq(def.open_after_depth, 4)
	assert_eq(def.clears_to_open, 1, "it opens after a fourth-floor clear")
	assert_eq(def.danger, 6)
	assert_eq(def.closed_hint, "Beat a fourth-floor boss first")
	assert_eq(def.rooms_dir, DIR, "no longer the Mall's rooms")


func test_its_difficulty_follows_the_spec() -> void:
	var def := _def()
	assert_near(def.health_mult, 2.2)
	assert_near(def.pension_mult, 2.5)
	assert_eq(def.enemies_by_size, {"small": 7, "medium": 9, "large": 14})
	assert_eq(def.treasure_pension, 20)
	assert_eq(def.clear_pension, _basement().clear_pension)
	assert_eq(def.prop_pension, _basement().prop_pension)
	assert_eq(def.vault_stone_level, _basement().vault_stone_level)
	assert_eq(def.chest_weights, {"lunchbox": 26, "locked": 22, "safe": 20, "urn": 16, "mimic": 16})


func test_its_own_enemies_and_bosses() -> void:
	var def := _def()
	var ids := {}
	for enemy: EnemyDef in def.enemies:
		ids[enemy.id] = true
	for id in ["caddie", "club_golfer", "gopher", "golf_bingo_caller", "golf_soot_ghost"]:
		assert_true(ids.has(id), id)
	assert_eq(ids.size(), 5)
	assert_eq(def.enemy_weights, PackedInt32Array([3, 4, 3, 3, 2]))
	assert_eq(def.mini_boss.id, "chip")
	assert_eq(def.floor_boss.id, "thaddeus_fairweather")
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


func test_enemies_stand_out_from_the_fairway() -> void:
	var palette := _def().room_palette()
	var defs: Array[EnemyDef] = []
	defs.assign(_def().enemies)
	defs.append(_def().mini_boss)
	defs.append(_def().floor_boss)
	for def in defs:
		var body := SpriteVisual.readable(def.color)
		for tone in [palette.floor_a, palette.floor_b, palette.floor_c]:
			assert_true(_difference(body, tone) >= 0.25, "%s against the grass" % def.id)


# --- its look ---

func test_it_looks_like_no_other_floor() -> void:
	var mine := _def().room_palette()
	for id in ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "golden_years_mall"]:
		var theirs := _floor(id).room_palette()
		assert_true(_difference(mine.floor_a, theirs.floor_a) > 0.15, "floor against %s" % id)
		assert_true(_difference(mine.wall, theirs.wall) > 0.15, "walls against %s" % id)
	assert_eq(mine.floor_pattern, GolfLook.FAIRWAY, "mown fairway")
	assert_eq(mine.wall_pattern, GolfLook.HEDGE_WALL, "clipped hedges")
	for kind in [RoomDecor.GRASS, RoomDecor.BENCH, RoomDecor.PLANT, RoomDecor.LANTERN, RoomDecor.FOG]:
		assert_true(mine.weight_of(kind) > 0.0, kind)
	for kind in [RoomDecor.BONES, RoomDecor.IV_STAND, RoomDecor.FURNACE, RoomDecor.GAUGE, RoomDecor.STAINED_GLASS, RoomDecor.COFFIN_STAND, RoomDecor.FLUORESCENT, RoomDecor.FOOD_TABLE, RoomDecor.COBWEB]:
		assert_near(mine.weight_of(kind), 0.0, kind)


func test_the_patterns_stand_clear_of_the_shared_ones() -> void:
	for value in [0, 1, 2, 3]:
		assert_true(GolfLook.FAIRWAY != value and GolfLook.HEDGE_WALL != value, str(value))


func test_the_fairway_is_striped_and_never_dotted_as_sand_is() -> void:
	# The stripes come two columns at a time, a light pair beside a dark pair.
	assert_true(GolfLook.is_light_stripe(Vector2i(0, 3)))
	assert_true(GolfLook.is_light_stripe(Vector2i(1, 3)))
	assert_false(GolfLook.is_light_stripe(Vector2i(2, 3)))
	assert_false(GolfLook.is_light_stripe(Vector2i(3, 3)))
	assert_true(GolfLook.is_light_stripe(Vector2i(4, 9)))
	assert_eq(GolfLook.is_light_stripe(Vector2i(5, 1)), GolfLook.is_light_stripe(Vector2i(5, 14)), "a stripe runs the room's height")
	var source := FileAccess.get_file_as_string("res://scripts/world/golf_look.gd")
	var floor_part := source.substr(source.find("func draw_floor_tile"), source.find("func draw_wall_tile") - source.find("func draw_floor_tile"))
	assert_false(floor_part.contains("draw_circle"), "no dots on the fairway")
	assert_false(floor_part.contains("speckle"), "no speckles either")
	assert_near(_def().room_palette().speckle.a, 0.0, "and the floor's speckle is clear")


func test_sand_reads_against_the_palest_fairway() -> void:
	var palette := _def().room_palette()
	for tone: Color in [palette.floor_a, palette.floor_b, palette.floor_c]:
		var stripe := tone.lerp(Color(palette.fairway_stripe, 1.0), palette.fairway_stripe.a)
		assert_true(_difference(palette.sand, stripe) > 0.3, "sand against %s" % str(stripe))
		assert_true(_difference(palette.sand, tone) > 0.3, "sand against %s" % str(tone))
	assert_true(_difference(palette.sand, palette.sand_grain) > 0.25, "the grains show on the sand")


# Under the old dusk light a warm sand turned salmon, so every red warning faded into a bunker. A sand
# with nearly as much blue as red stays pale under any light, and under the midnight blue it reads as
# moonlit, far from the warning's red.
func test_sand_is_cool_enough_that_red_warnings_show_on_it() -> void:
	var sand := _def().room_palette().sand
	assert_true(sand.b >= sand.r * 0.8, "sand %s is too warm" % str(sand))


# --- its midnight light ---

# A colour as the room's light leaves it: the ambient plus a fill light at its centre, clipped at
# white. Far from every fill it is darker still, and a wall light or lantern adds to it.
func _night_lit(color: Color, palette: RoomPalette) -> Color:
	var light := Color(palette.ambient.r + palette.fill_light.r * Lighting.FILL_ENERGY,
		palette.ambient.g + palette.fill_light.g * Lighting.FILL_ENERGY,
		palette.ambient.b + palette.fill_light.b * Lighting.FILL_ENERGY)
	return Color(minf(color.r * light.r, 1.0), minf(color.g * light.g, 1.0), minf(color.b * light.b, 1.0))


func _darkest_grass(palette: RoomPalette) -> Color:
	var darkest := palette.floor_a
	for tone: Color in [palette.floor_b, palette.floor_c]:
		if tone.get_luminance() < darkest.get_luminance():
			darkest = tone
	return darkest


# Midnight: a blue-black sky, cold moonlight from the walls and a cold fill, and the lanterns the only
# warm light on the course.
func test_the_night_is_cold_and_only_the_lanterns_are_warm() -> void:
	var palette := _def().room_palette()
	for light: Color in [palette.ambient, palette.torch, palette.fill_light]:
		assert_true(light.b > light.r and light.b > light.g, "cold light %s" % str(light))
	assert_true(palette.darkness.get_luminance() < 0.05, "a blue-black sky")
	assert_true(palette.lantern_light.r > palette.lantern_light.b + 0.3, "a warm lantern")
	assert_true(palette.weight_of(RoomDecor.TORCH) <= 0.0, "no warm torches in the scatter")


# The palest tile is a light mown stripe right under a wall light, with the fill on it too (the Head
# Office rule). Moonlight must not burn it white, or the HUD and pale bodies vanish there.
func test_the_palest_fairway_under_the_moonlight_stays_below_white() -> void:
	var palette := _def().room_palette()
	var light := Color(palette.ambient.r + palette.torch.r + palette.fill_light.r * Lighting.FILL_ENERGY,
		palette.ambient.g + palette.torch.g + palette.fill_light.g * Lighting.FILL_ENERGY,
		palette.ambient.b + palette.torch.b + palette.fill_light.b * Lighting.FILL_ENERGY)
	for tone: Color in [palette.floor_a, palette.floor_b, palette.floor_c]:
		var stripe := tone.lerp(Color(palette.fairway_stripe, 1.0), palette.fairway_stripe.a)
		var peak := maxf(stripe.r * light.r, maxf(stripe.g * light.g, stripe.b * light.b))
		assert_true(peak < 1.0, "the stripe near a wall light burns to white (%.2f)" % peak)


# Every red warning on the course lies on sand or on grass, and the blue light takes most of its red.
# Lit as the room lights it, it must still stand apart from both.
func test_red_warnings_show_on_the_sand_and_the_darkest_grass_at_night() -> void:
	var palette := _def().room_palette()
	var warning := _night_lit(Enemy.WARNING_COLOR, palette)
	assert_true(_difference(warning, _night_lit(palette.sand, palette)) >= 0.4, "a warning on sand")
	assert_true(_difference(warning, _night_lit(_darkest_grass(palette), palette)) >= 0.3, "a warning on the darkest grass")


func test_enemies_stand_out_from_the_grass_under_the_night_light() -> void:
	var palette := _def().room_palette()
	var defs: Array[EnemyDef] = []
	defs.assign(_def().enemies)
	defs.append(_def().mini_boss)
	defs.append(_def().floor_boss)
	for def in defs:
		var body := _night_lit(SpriteVisual.readable(def.color), palette)
		for tone: Color in [palette.floor_a, palette.floor_b, palette.floor_c]:
			assert_true(_difference(body, _night_lit(tone, palette)) >= 0.22, "%s against the grass at night" % def.id)


# Two pale bodies read as one under a single light (the cruise's lesson), so only one of the course's
# people is pale: the Caddie in his whites.
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


# The fog is a thin veil: faint enough that nothing under it hides, no light of its own, and drawn only
# as level streaks, never with the dots and filled cells of the sand or a warned lane's outline.
func test_the_ground_fog_is_faint_and_shares_no_shape_with_the_sand() -> void:
	var palette := _def().room_palette()
	assert_true(palette.fog.a <= 0.2, "fog %s is too thick" % str(palette.fog))
	assert_false(RoomDecor.is_light(RoomDecor.FOG))
	var source := FileAccess.get_file_as_string("res://scripts/world/decor_layer.gd")
	var start := source.find("RoomDecor.FOG:")
	assert_true(start >= 0, "the decor layer draws fog")
	var fog_part := source.substr(start, source.find("TerminalDecor.draw_placeholder") - start)
	for shape in ["draw_circle", "draw_rect", "draw_arc", "draw_colored_polygon"]:
		assert_false(fog_part.contains(shape), "fog drawn with %s" % shape)
	for id in ["floor_1", "cemetery", "golden_years_mall"]:
		assert_near(_floor(id).room_palette().weight_of(RoomDecor.FOG), 0.0, "no fog on %s" % id)


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


func test_rooms_have_the_courses_props_sand_in_most_and_chests() -> void:
	var counts := {"3": 0, "4": 0, "5": 0, "s": 0, "C": 0}
	var sand_rooms := 0
	var carts := 0
	var hedgerows := 0
	var boss_sand := 999
	for layout in _pool():
		for symbol: String in counts:
			counts[symbol] += layout.cells_of(symbol).size()
		var sand := layout.cells_of(RoomLayout.SYMBOL_SAND).size()
		if sand > 0:
			sand_rooms += 1
		if layout.room_type == RoomLayout.TYPE_FLOOR_BOSS or layout.room_type == RoomLayout.TYPE_MINI_BOSS:
			boss_sand = mini(boss_sand, sand)
		for cell in layout.cells_of(RoomLayout.SYMBOL_HEDGE):
			if GolfProps.is_parked_cart(layout, cell):
				carts += 1
			else:
				hedgerows += 1
		for symbol: String in OTHER_FLOORS:
			assert_true(layout.cells_of(symbol).is_empty(), "no props of other floors, %s in %s" % [symbol, layout.resource_path])
	for symbol: String in ["3", "4", "5"]:
		assert_true(counts[symbol] >= 10, "'%s' appears %d times" % [symbol, counts[symbol]])
	assert_true(counts["C"] >= 2, "chest cells %d" % counts["C"])
	assert_true(sand_rooms >= 20, "sand in %d rooms" % sand_rooms)
	assert_true(sand_rooms < _pool().size(), "but not every one")
	assert_true(boss_sand >= 4, "every boss room has sand to fight around, the fewest is %d" % boss_sand)
	assert_true(carts >= 8, "parked carts %d" % carts)
	assert_true(hedgerows >= 100, "hedge cells %d" % hedgerows)


func test_a_hedge_cell_on_its_own_is_a_parked_cart() -> void:
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_HEALING
	layout.rows = PackedStringArray([
		"####################",
		"#..................#",
		"#..5.....555.......#",
		"#.........5........#",
		"#..........H.......#",
		"#..................#",
		"#...5.5............#",
		"#..................#",
		"#..................#",
		"#..................#",
		"####################",
	])
	assert_true(GolfProps.is_parked_cart(layout, Vector2i(3, 2)), "alone")
	assert_true(GolfProps.is_parked_cart(layout, Vector2i(4, 6)), "a gap between is still alone")
	assert_false(GolfProps.is_parked_cart(layout, Vector2i(9, 2)), "in a row")
	assert_false(GolfProps.is_parked_cart(layout, Vector2i(10, 3)), "joined from above")
	assert_false(GolfProps.is_parked_cart(layout, Vector2i(5, 5)), "plain floor is no cart")


func test_the_courses_props_break_as_the_spec_says() -> void:
	var flag := FlagPin.new()
	assert_false(flag.is_solid(), "a flag pin blocks nothing")
	for source in [BreakableBlock.SOURCE_CANE, BreakableBlock.SOURCE_BLAST, BreakableBlock.SOURCE_BOSS]:
		assert_true(flag.can_break_by(source), source)
	flag.free()
	var washer := BallWasher.new()
	assert_true(washer is Barrel, "a ball washer holds what a barrel holds")
	assert_true(washer.is_solid())
	for source in [BreakableBlock.SOURCE_CANE, BreakableBlock.SOURCE_BLAST, BreakableBlock.SOURCE_BOSS]:
		assert_true(washer.can_break_by(source), source)
	washer.free()
	for prop: BreakableBlock in [Hedge.new(), ParkedCart.new()]:
		assert_true(prop is RockBlock, "it can hide a coin as furniture does")
		assert_true(prop.is_solid())
		assert_false(prop.can_break_by(BreakableBlock.SOURCE_CANE), "solid")
		assert_true(prop.can_break_by(BreakableBlock.SOURCE_BLAST))
		assert_true(prop.can_break_by(BreakableBlock.SOURCE_BOSS))
		prop.free()
	for symbol in [RoomLayout.SYMBOL_BALL_WASHER, RoomLayout.SYMBOL_HEDGE]:
		assert_true(RoomLayout.SOLID_SYMBOLS.contains(symbol), symbol)
		assert_false(RoomLayout.WALLS.contains(symbol), symbol)
		assert_false(RoomLayout.DECOR_SYMBOLS.contains(symbol), symbol)
	assert_true(RoomLayout.WALLS_AND_BOMB_ONLY.contains(RoomLayout.SYMBOL_HEDGE), "a hedge needs a bomb")
	assert_false(RoomLayout.WALLS_AND_BOMB_ONLY.contains(RoomLayout.SYMBOL_BALL_WASHER), "a ball washer breaks to the cane")
	assert_false(RoomLayout.SOLID_SYMBOLS.contains(RoomLayout.SYMBOL_FLAG))
	assert_true(RoomLayout.DECOR_SYMBOLS.contains(RoomLayout.SYMBOL_FLAG))
	for symbol in [RoomLayout.SYMBOL_SAND, RoomLayout.SYMBOL_FLAG, RoomLayout.SYMBOL_BALL_WASHER, RoomLayout.SYMBOL_HEDGE]:
		assert_true(RoomLayout.ALLOWED.contains(symbol), symbol)
	assert_eq(RoomLayout.SYMBOL_FLAG + RoomLayout.SYMBOL_BALL_WASHER + RoomLayout.SYMBOL_HEDGE, "345", "only the path's own symbols")


# Debris is a few small dots, so it must stand well apart from the grass it falls on.
func test_every_props_debris_shows_on_the_fairway() -> void:
	var palette := _def().room_palette()
	for prop: BreakableBlock in [FlagPin.new(), BallWasher.new(), Hedge.new(), ParkedCart.new()]:
		prop.palette = palette
		for tone: Color in [palette.floor_a, palette.floor_b, palette.floor_c]:
			assert_true(_difference(prop.debris_color(), tone) > 0.4, "%s debris against %s" % [prop.art_id(), str(tone)])
		prop.free()


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


func test_every_floor_keeps_a_free_cell_beside_its_start_for_the_crossroads() -> void:
	var crossroads: RoomLayout = load("res://data/rooms/crossroads/crossroads.tres")
	var pool := _pool()
	for seed_value in 100:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var map := FloorBuilder.build_from_pool(rng, _def(), pool)
		var room := map.attach_crossroads(crossroads, RoomLayout.EAST)
		assert_true(room != null, "seed %d" % seed_value)


func test_vault_extras_find_their_spots_here_too() -> void:
	for layout in _pool():
		if layout.room_type == RoomLayout.TYPE_VAULT:
			assert_eq(layout.vault_extra_cells(RoomLayout.VAULT_EXTRAS).size(), RoomLayout.VAULT_EXTRAS, layout.resource_path)


func test_every_shop_plan_tier_has_a_spot() -> void:
	for layout in _pool():
		if layout.room_type == RoomLayout.TYPE_SHOP:
			assert_eq(layout.plan_reward_cells(ProgressData.RETIREMENT_TIERS.size()).size(), ProgressData.RETIREMENT_TIERS.size(), layout.resource_path)
			assert_true(layout.merchant_cell() != Vector2i(-1, -1), layout.resource_path)
