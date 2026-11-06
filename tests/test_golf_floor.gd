extends TestCase

# What still holds of Fairway's End while its enemies, bosses, props and looks wait to be retired: the
# floor's rooms, palette and whole-floor rules now live in test_seance_floor.gd.


func _def() -> FloorDef:
	return load("res://data/floors/seance_hotline.tres")


func _floor(id: String) -> FloorDef:
	return load("res://data/floors/%s.tres" % id)


func _difference(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


# --- its bosses ---

# The hotline's own regulars and Sister Celestine hold the floor now (test_seance_floor.gd); the Club
# President keeps its floor boss room, with the Caddie as his summon, until his phase retires him.
func test_the_golf_floor_boss_still_holds_its_boss_room() -> void:
	var def := _def()
	assert_eq(def.floor_boss.id, "thaddeus_fairweather")
	assert_eq(def.floor_boss.summon.id, "caddie")


# --- its look ---

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


# The Club President still spreads his bunkers on the hotline's carpet until the floor's own bosses
# take his room, so the sand must read there.
func test_sand_reads_against_the_hotlines_carpet() -> void:
	var palette := _def().room_palette()
	for tone: Color in [palette.floor_a, palette.floor_b, palette.floor_c]:
		assert_true(_difference(palette.sand, tone) > 0.3, "sand against %s" % str(tone))
	assert_true(_difference(palette.sand, palette.sand_grain) > 0.25, "the grains show on the sand")


# Under the old dusk light a warm sand turned salmon, so every red warning faded into a bunker. A sand
# with nearly as much blue as red stays pale under any light, and under the midnight blue it reads as
# moonlit, far from the warning's red.
func test_sand_is_cool_enough_that_red_warnings_show_on_it() -> void:
	var sand := _def().room_palette().sand
	assert_true(sand.b >= sand.r * 0.8, "sand %s is too warm" % str(sand))


# --- sand under the hotline's light ---

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


# A red warning over spread sand, lit as the room lights it, must still stand apart from it, and from
# the darkest carpet round it.
func test_red_warnings_show_on_the_sand_and_the_darkest_carpet() -> void:
	var palette := _def().room_palette()
	var warning := _night_lit(Enemy.WARNING_COLOR, palette)
	assert_true(_difference(warning, _night_lit(palette.sand, palette)) >= 0.4, "a warning on sand")
	assert_true(_difference(warning, _night_lit(_darkest_grass(palette), palette)) >= 0.3, "a warning on the darkest grass")


# The dusk sand left under the moonlight glowed near white at a wall light (luminance 0.96), more snow
# than bunker. Lit by a wall light and a fill together it must stay a dim moonlit grey, and the
# warning red must still stand apart from it there.
func test_the_sand_under_a_wall_light_stays_dim_and_warnings_show_on_it() -> void:
	var palette := _def().room_palette()
	var light := Color(palette.ambient.r + palette.torch.r + palette.fill_light.r * Lighting.FILL_ENERGY,
		palette.ambient.g + palette.torch.g + palette.fill_light.g * Lighting.FILL_ENERGY,
		palette.ambient.b + palette.torch.b + palette.fill_light.b * Lighting.FILL_ENERGY)
	var sand := palette.sand * light
	var clipped := Color(minf(sand.r, 1.0), minf(sand.g, 1.0), minf(sand.b, 1.0))
	assert_true(clipped.get_luminance() < 0.7, "the sand glows at a wall light (%.2f)" % clipped.get_luminance())
	var warning := Enemy.WARNING_COLOR * light
	var warning_clipped := Color(minf(warning.r, 1.0), minf(warning.g, 1.0), minf(warning.b, 1.0))
	assert_true(_difference(warning_clipped, clipped) >= 0.4, "a warning on sand at a wall light")
	assert_true(_night_lit(palette.sand, palette).get_luminance() < 0.4, "the sand at a fill stays dim")


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
	for id in ["floor_1", "cemetery", "flashback_cinema"]:
		assert_near(_floor(id).room_palette().weight_of(RoomDecor.FOG), 0.0, "no fog on %s" % id)


# --- its props ---

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
