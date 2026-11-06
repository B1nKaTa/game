extends TestCase

# Every other path a palette must stand apart from.
const OTHER_PATHS := ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "flashback_cinema", "last_resort_cruise", "terminal_zero", "head_office"]


func _def() -> FloorDef:
	return load("res://data/floors/seance_hotline.tres")


func _floor(id: String) -> FloorDef:
	return load("res://data/floors/%s.tres" % id)


func _difference(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


func _tones(palette: RoomPalette) -> Array[Color]:
	return [palette.floor_a, palette.floor_b, palette.floor_c]


# A colour as the room's light leaves it: the ambient plus a fill light at its centre, plus a wall
# light when lit_by_wall, clipped at white.
func _lit(color: Color, palette: RoomPalette, lit_by_wall := false) -> Color:
	var wall := palette.torch if lit_by_wall else Color.BLACK
	var light := Color(palette.ambient.r + wall.r + palette.fill_light.r * Lighting.FILL_ENERGY,
		palette.ambient.g + wall.g + palette.fill_light.g * Lighting.FILL_ENERGY,
		palette.ambient.b + wall.b + palette.fill_light.b * Lighting.FILL_ENERGY)
	return Color(minf(color.r * light.r, 1.0), minf(color.g * light.g, 1.0), minf(color.b * light.b, 1.0))


func _hue_gap(a: float, b: float) -> float:
	var gap := absf(a - b)
	return minf(gap, 1.0 - gap)


# The room's large areas: the carpet, the walls and the cover that fills its rows.
func _large_areas(palette: RoomPalette) -> Array[Color]:
	return [palette.floor_a, palette.floor_b, palette.floor_c, palette.wall, palette.partition_fabric, palette.desk_wood, palette.desk_top, palette.table_cloth]


# --- its look ---

func test_it_looks_like_no_other_floor() -> void:
	var mine := _def().room_palette()
	for id in OTHER_PATHS:
		var theirs := _floor(id).room_palette()
		assert_true(_difference(mine.floor_a, theirs.floor_a) > 0.15, "floor against %s" % id)
		assert_true(_difference(mine.wall, theirs.wall) > 0.15, "walls against %s" % id)
	assert_eq(mine.floor_pattern, SeanceLook.CARPET, "violet carpet with faint stars")
	assert_eq(mine.wall_pattern, SeanceLook.STAR_WALL, "dark teal panels with stars")
	assert_false(mine.screen, "no film on the hotline")
	for kind in [RoomDecor.COBWEB, RoomDecor.OFFICE_CHAIR]:
		assert_true(mine.weight_of(kind) > 0.0, kind)
	for kind in [RoomDecor.GRASS, RoomDecor.FOG, RoomDecor.BONES, RoomDecor.IV_STAND, RoomDecor.FURNACE, RoomDecor.GAUGE, RoomDecor.STAINED_GLASS, RoomDecor.COFFIN_STAND, RoomDecor.FLUORESCENT, RoomDecor.FOOD_TABLE, RoomDecor.BENCH, RoomDecor.PUDDLE, RoomDecor.MOSS, RoomDecor.PLANT, RoomDecor.FICUS]:
		assert_near(mine.weight_of(kind), 0.0, kind)


func test_the_patterns_stand_clear_of_every_other_one() -> void:
	for value in [0, 1, 2, 3, RoomBackdrop.FLOOR_TEAK_DECK, RoomBackdrop.FLOOR_OFFICE_CARPET, GolfLook.FAIRWAY, CinemaLook.CARPET]:
		assert_true(SeanceLook.CARPET != value, str(value))
	for value in [0, 1, 2, 3, RoomBackdrop.WALL_SHIP_RAIL, RoomBackdrop.WALL_OFFICE_PLASTER, GolfLook.HEDGE_WALL, CinemaLook.DECO_WALL]:
		assert_true(SeanceLook.STAR_WALL != value, str(value))


# The ectoplasm lays a sticky trail of blobs, Madame Zara lays a letter grid (the Ouija board), a film
# strip is a dark band with holes and a wet floor shows bright diagonals, so the carpet has none of them:
# no filled shapes at all, no seams round its cells, only short upright and level strokes and thin arcs,
# faint, scattered by a roll rather than on a grid.
func test_the_carpet_shares_no_shape_with_any_hazard() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/seance_look.gd")
	var floor_part := source.substr(source.find("func draw_floor_tile"), source.find("func draw_wall_tile") - source.find("func draw_floor_tile"))
	assert_true(floor_part.length() > 100, "found the floor drawing")
	for shape in ["draw_circle", "draw_rect", "draw_colored_polygon", "draw_polygon", "speckle", "grout"]:
		assert_false(floor_part.contains(shape), "the carpet draws with %s" % shape)
	var palette := _def().room_palette()
	assert_near(palette.speckle.a, 0.0, "the floor's speckle is clear")
	assert_near(palette.grout.a, 0.0, "and no seams")
	assert_true(palette.carpet_motif.a <= 0.2, "the stars are faint")
	# The stars and moons never fall into rows or columns: in a large room no row or column of cells
	# carries more than a few, and they cover only a small share of the carpet.
	var marked := 0
	for y in range(1, 16):
		var in_row := 0
		for x in range(1, 29):
			if SeanceLook.motif_of(Vector2i(x, y)) != 0:
				in_row += 1
				marked += 1
		assert_true(in_row <= 14, "row %d has %d marks" % [y, in_row])
	assert_true(marked > 20 and marked < 28 * 15 / 2, "marks on %d cells" % marked)
	var offsets := {}
	for x in range(1, 29):
		offsets[SeanceLook.motif_offset(Vector2i(x, 5), RoomBackdrop.TILE)] = true
	assert_true(offsets.size() > 20, "each mark sits at a spot of its own in its cell")


# Warnings are #e4524f, so no large area of the hotline is red: the carpet, walls and cover keep their
# hue well away from red, or stay dark and grey.
func test_no_large_area_is_red() -> void:
	var palette := _def().room_palette()
	for area: Color in _large_areas(palette):
		var reddish := _hue_gap(area.h, 0.0) < 0.12 and area.s > 0.35
		assert_false(reddish, "a red area %s" % str(area))
		assert_true(_difference(area, Enemy.WARNING_COLOR) > 0.45, "%s is too near the warning red" % str(area))


# The safe-spot ring is mint (#7fe0a0), so nothing large is green near it, and the ectoplasm is a
# deeper, darker green that never reads as a safe spot.
func test_no_large_area_is_green_near_the_safe_spot_mint() -> void:
	var palette := _def().room_palette()
	var mint := SafeSpotMark.COLOR
	for area: Color in _large_areas(palette):
		assert_true(_difference(area, mint) > 0.45, "%s is too near the mint" % str(area))
		assert_false(_hue_gap(area.h, mint.h) < 0.1 and area.s > 0.3, "%s is green like the mint" % str(area))
	var goo := palette.ectoplasm
	assert_true(_hue_gap(goo.h, 1.0 / 3.0) < 0.12, "the ectoplasm is green %s" % str(goo))
	assert_true(goo.get_luminance() < mint.get_luminance() * 0.5, "far darker than the mint")
	assert_true(_difference(goo, mint) > 0.45, "and far from it")
	assert_true(_difference(palette.phone_glow, mint) > 0.25, "a phone display is a lime of its own")


func test_the_lights_are_violet_teal_and_candle_warm() -> void:
	var palette := _def().room_palette()
	assert_true(palette.ambient.b > palette.ambient.g and palette.ambient.r > palette.ambient.g, "a violet ambient")
	assert_true(palette.fill_light.b > palette.fill_light.r and palette.fill_light.g > palette.fill_light.r, "a cool teal fill")
	assert_true(palette.torch.r > palette.torch.b + 0.3, "candle-warm desk lights")
	assert_true(palette.lantern_light.r > palette.lantern_light.b + 0.3, "candle-warm lanterns")
	assert_true(palette.weight_of(RoomDecor.LANTERN) <= 0.0 and palette.weight_of(RoomDecor.TORCH) <= 0.0 and palette.scatter_lights == 0, "no scattered lights")
	assert_true(palette.flicker > 0.0 and palette.flicker < 0.1, "candles flicker a little")


# Head Office's lesson: the palest tile right under a wall light, with the fill on it, must not burn
# to white, or the HUD and pale bodies vanish there.
func test_the_palest_carpet_under_a_wall_light_stays_below_white() -> void:
	var palette := _def().room_palette()
	for tone in _tones(palette):
		var lit := _lit(tone, palette, true)
		assert_true(maxf(lit.r, maxf(lit.g, lit.b)) < 0.9, "%s burns near white (%s)" % [str(tone), str(lit)])


func test_red_warnings_show_on_the_lit_carpet() -> void:
	var palette := _def().room_palette()
	for tone in _tones(palette):
		for by_wall in [false, true]:
			var warning := _lit(Enemy.WARNING_COLOR, palette, by_wall)
			assert_true(_difference(warning, _lit(tone, palette, by_wall)) >= 0.4, "a warning on %s" % str(tone))


# The mint safe-spot ring must read on the carpet too, lit as the room lights it.
func test_the_safe_spot_mint_shows_on_the_lit_carpet() -> void:
	var palette := _def().room_palette()
	for tone in _tones(palette):
		assert_true(_difference(_lit(SafeSpotMark.COLOR, palette), _lit(tone, palette)) >= 0.4, "the mint on %s" % str(tone))


# Dark rooms hid dark bodies (the first floor's lesson), so every enemy of the floor, at its readable
# brightness, stands apart from the carpet under the fill light alone.
func test_enemies_stand_out_from_the_carpet_under_the_hotlines_light() -> void:
	var palette := _def().room_palette()
	var defs: Array[EnemyDef] = []
	defs.assign(_def().enemies)
	defs.append(_def().mini_boss)
	defs.append(_def().floor_boss)
	for def in defs:
		var body := _lit(SpriteVisual.readable(def.color), palette)
		for tone in _tones(palette):
			assert_true(_difference(body, _lit(tone, palette)) >= 0.22, "%s against the carpet" % def.id)
