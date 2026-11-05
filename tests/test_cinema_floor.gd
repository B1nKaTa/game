extends TestCase

const DIR := "res://data/rooms/flashback_cinema/"
# Every other path a palette must stand apart from.
const OTHER_PATHS := ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "last_resort_cruise", "seance_hotline", "terminal_zero", "head_office"]


func _def() -> FloorDef:
	return load("res://data/floors/flashback_cinema.tres")


func _floor(id: String) -> FloorDef:
	return load("res://data/floors/%s.tres" % id)


func _difference(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


func _tones(palette: RoomPalette) -> Array[Color]:
	return [palette.floor_a, palette.floor_b, palette.floor_c, palette.carpet_runner]


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


# --- its look ---

func test_it_looks_like_no_other_floor() -> void:
	var mine := _def().room_palette()
	for id in OTHER_PATHS:
		var theirs := _floor(id).room_palette()
		assert_true(_difference(mine.floor_a, theirs.floor_a) > 0.15, "floor against %s" % id)
		assert_true(_difference(mine.wall, theirs.wall) > 0.15, "walls against %s" % id)
	assert_eq(mine.floor_pattern, CinemaLook.CARPET, "teal carpet with runners")
	assert_eq(mine.wall_pattern, CinemaLook.DECO_WALL, "deco panels with gold trim")
	assert_true(mine.screen, "its fighting rooms show a film")
	for kind in [RoomDecor.GRASS, RoomDecor.BONES, RoomDecor.IV_STAND, RoomDecor.FURNACE, RoomDecor.GAUGE, RoomDecor.STAINED_GLASS, RoomDecor.COFFIN_STAND, RoomDecor.FLUORESCENT, RoomDecor.FOOD_TABLE, RoomDecor.BENCH, RoomDecor.FOG, RoomDecor.PUDDLE]:
		assert_near(mine.weight_of(kind), 0.0, kind)


func test_the_patterns_stand_clear_of_every_other_one() -> void:
	for value in [0, 1, 2, 3, RoomBackdrop.FLOOR_TEAK_DECK, RoomBackdrop.FLOOR_OFFICE_CARPET, GolfLook.FAIRWAY]:
		assert_true(CinemaLook.CARPET != value, str(value))
	for value in [0, 1, 2, 3, RoomBackdrop.WALL_SHIP_RAIL, RoomBackdrop.WALL_OFFICE_PLASTER, GolfLook.HEDGE_WALL]:
		assert_true(CinemaLook.DECO_WALL != value, str(value))


func test_the_runners_cross_the_room_through_its_doors() -> void:
	var layout: RoomLayout = RoomLayout.new()
	layout.rows = PackedStringArray(["#".repeat(20)])
	for y in 9:
		layout.rows.append("#" + ".".repeat(18) + "#")
	layout.rows.append("#".repeat(20))
	var size := layout.size_in_cells()
	for side in RoomLayout.SIDES:
		assert_true(CinemaLook.is_runner(layout.door_cell(side), size), "a runner reaches the door at %s" % str(side))
	assert_false(CinemaLook.is_runner(Vector2i(3, 2), size), "and most of the carpet is plain")


# A Runaway Film Reel lays a dark strip with sprocket holes, and a wet floor shows bright streaks, so the
# carpet has neither: no dots or small squares, no speckle, and runners lighter than the carpet, never
# a dark band.
func test_the_carpet_shares_no_shape_with_the_film_strip_or_a_wet_floor() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/cinema_look.gd")
	var floor_part := source.substr(source.find("func draw_floor_tile"), source.find("func draw_wall_tile") - source.find("func draw_floor_tile"))
	assert_true(floor_part.length() > 100, "found the floor drawing")
	assert_false(floor_part.contains("draw_circle"), "no dots on the carpet")
	assert_false(floor_part.contains("speckle"), "no speckles")
	assert_eq(floor_part.count("draw_rect("), 2, "only the runner's fill and its crossing's square")
	var palette := _def().room_palette()
	assert_near(palette.speckle.a, 0.0, "the floor's speckle is clear")
	for tone: Color in [palette.floor_a, palette.floor_b, palette.floor_c]:
		assert_true(palette.carpet_runner.get_luminance() > tone.get_luminance(), "a runner is lighter than the carpet")
	assert_true(palette.carpet_motif.a <= 0.2, "the fans are faint")


# Warnings are #e4524f and the Funeral Parlour next door is wine red, so no large area of the Cinema is
# red: the carpet, runners, walls and seats keep their hue well away from red, or stay dark and grey.
func test_no_large_area_is_red() -> void:
	var palette := _def().room_palette()
	for area: Color in [palette.floor_a, palette.floor_b, palette.floor_c, palette.carpet_runner, palette.wall, palette.seat_velvet, palette.pillar]:
		var reddish := _hue_gap(area.h, 0.0) < 0.12 and area.s > 0.35
		assert_false(reddish, "a red area %s" % str(area))
		assert_true(_difference(area, Enemy.WARNING_COLOR) > 0.45, "%s is too near the warning red" % str(area))
	assert_true(_difference(palette.wall, _floor("funeral_parlour").room_palette().wall) > 0.15, "not the Parlour's walls")


func test_the_house_lights_are_dim_and_the_trim_is_gold() -> void:
	var palette := _def().room_palette()
	assert_true(palette.ambient.get_luminance() < 0.45, "dim house lights")
	assert_true(palette.torch.r > palette.torch.b + 0.3, "warm wall lights")
	assert_true(palette.projector_beam.r > palette.projector_beam.b, "a warm projector beam")
	assert_true(palette.screen_glow.b > palette.screen_glow.r, "a cool screen glow")
	assert_true(palette.deco_gold.r > palette.deco_gold.b + 0.3 and palette.deco_gold.g > palette.deco_gold.b, "gold trim")
	assert_true(palette.weight_of(RoomDecor.LANTERN) <= 0.0 and palette.scatter_lights == 0, "no scattered lanterns over the dim house")


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


# Dark rooms hid dark bodies (the first floor's lesson), so every enemy of the floor, at its readable
# brightness, stands apart from the carpet under the fill light alone.
func test_enemies_stand_out_from_the_carpet_under_the_house_lights() -> void:
	var palette := _def().room_palette()
	var defs: Array[EnemyDef] = []
	defs.assign(_def().enemies)
	defs.append(_def().mini_boss)
	defs.append(_def().floor_boss)
	for def in defs:
		var body := _lit(SpriteVisual.readable(def.color), palette)
		for tone in _tones(palette):
			assert_true(_difference(body, _lit(tone, palette)) >= 0.22, "%s against the carpet" % def.id)


# --- its props ---

func _room(changes: Dictionary = {}, type := RoomLayout.TYPE_HEALING) -> RoomLayout:
	var rows := PackedStringArray(["#".repeat(20)])
	for y in range(1, 10):
		rows.append("#" + ".".repeat(18) + "#")
	rows.append("#".repeat(20))
	for cell: Vector2i in changes:
		var row := rows[cell.y]
		rows[cell.y] = row.substr(0, cell.x) + changes[cell] + row.substr(cell.x + 1)
	var layout := RoomLayout.new()
	layout.room_type = type
	layout.rows = rows
	if type == RoomLayout.TYPE_HEALING:
		var row := layout.rows[8]
		layout.rows[8] = row.substr(0, 4) + "H" + row.substr(5)
	return layout


func test_the_props_have_symbols_of_their_own() -> void:
	for symbol in [RoomLayout.SYMBOL_SEAT, RoomLayout.SYMBOL_PILLAR]:
		assert_true(RoomLayout.ALLOWED.contains(symbol), symbol)
		assert_true(RoomLayout.SOLID_SYMBOLS.contains(symbol), symbol)
		assert_true(RoomLayout.WALLS_AND_BOMB_ONLY.contains(symbol), "%s needs more than the cane" % symbol)
		assert_false(RoomLayout.DECOR_SYMBOLS.contains(symbol), symbol)
		assert_false(RoomLayout.WALL_LIKE.contains(symbol), "%s is a prop, not a wall tile" % symbol)
	assert_false(RoomLayout.WALLS.contains(RoomLayout.SYMBOL_SEAT), "a seat row can be blasted open")
	assert_true(RoomLayout.WALLS.contains(RoomLayout.SYMBOL_PILLAR), "no route may need a pillar")
	assert_true(RoomLayout.SYMBOL_SEAT != RoomLayout.SYMBOL_PILLAR)


# A row of seats is cover, as crates are: solid on the wall layer, which stops walkers and every shot
# (Projectile looks only at layer 1), and only blasts and bosses break it.
func test_seats_are_cover_that_stops_walkers_and_shots() -> void:
	var seat := CinemaSeat.new()
	_ready_alone(seat)
	assert_true(seat.is_solid())
	assert_eq(seat.collision_layer, 1, "on the wall layer")
	assert_true(seat.get_child_count() > 0, "with a body")
	assert_false(seat.can_break_by(BreakableBlock.SOURCE_CANE), "the cane only bounces off")
	assert_true(seat.can_break_by(BreakableBlock.SOURCE_BLAST))
	assert_true(seat.can_break_by(BreakableBlock.SOURCE_BOSS))
	var seat_node: Node = seat
	assert_true(seat_node is RockBlock, "it can hide a coin, as furniture does")
	seat.free()
	var source := FileAccess.get_file_as_string("res://scripts/actors/projectile.gd")
	assert_true(source.contains("PhysicsRayQueryParameters2D.create(global_position, next, 1)"), "shots stop on layer 1")


func test_pillars_are_solid_and_never_break() -> void:
	var pillar := CinemaPillar.new()
	_ready_alone(pillar)
	assert_eq(pillar.collision_layer, 1)
	var as_node: Node = pillar
	assert_false(as_node is BreakableBlock, "nothing breaks a pillar")
	var seat := CinemaSeat.new()
	assert_false(BossDash.stops_at(seat), "a charge smashes through seats")
	seat.free()
	assert_true(BossDash.stops_at(pillar), "but stops at a pillar")
	pillar.free()


func _ready_alone(node: Node2D) -> void:
	node._ready()


func test_a_seat_row_needs_a_blast_and_a_pillar_can_never_be_a_way_through() -> void:
	# A column of seats cutting the room from top to bottom shuts its east half off without a bomb.
	var changes := {}
	for y in range(1, 10):
		changes[Vector2i(14, y)] = RoomLayout.SYMBOL_SEAT
	assert_true(str(_room(changes).validate()).contains("needs a bomb"), "seats need a bomb")
	var walls := {}
	for y in range(1, 10):
		walls[Vector2i(14, y)] = RoomLayout.SYMBOL_PILLAR
	assert_true(str(_room(walls).validate()).contains("cannot be reached"), "a pillar row walls it off")
	assert_eq(_room({Vector2i(6, 3): "-", Vector2i(7, 3): "-", Vector2i(12, 6): "|"}).validate().size(), 0, "loose rows and pillars are fine")
	assert_true(_room({Vector2i(9, 2): "-"}).validate().size() > 0, "but not beside a door")


func test_aisle_lights_stand_at_the_open_ends_of_seat_rows() -> void:
	var layout := _room({Vector2i(5, 3): "-", Vector2i(6, 3): "-", Vector2i(7, 3): "-", Vector2i(3, 7): "-", Vector2i(2, 7): "|"})
	var ends := CinemaProps.aisle_light_cells(layout)
	var cells := []
	for end in ends:
		cells.append(end["cell"])
	assert_true(cells.has(Vector2i(4, 3)) and cells.has(Vector2i(8, 3)), "both ends of the row %s" % str(cells))
	assert_true(cells.has(Vector2i(4, 7)), "the open end beside a pillar")
	assert_false(cells.has(Vector2i(2, 7)), "never on the pillar")
	assert_eq(cells.size(), 3)
	var spot: Vector2 = CinemaProps.aisle_light_spots(layout)[0]
	assert_true(spot.distance_to(RoomBackdrop.cell_center(ends[0]["cell"])) < RoomBackdrop.TILE, "a spot in its cell")
	assert_true(spot.x > RoomBackdrop.cell_center(ends[0]["cell"]).x, "leaning towards the row it lights")
	assert_true(CinemaProps.aisle_light_spots(_room({})).is_empty(), "no rows, no lights")


func test_a_room_never_has_more_than_a_few_aisle_lights() -> void:
	var changes := {}
	for x in range(3, 17, 2):
		for y in [3, 5, 7]:
			changes[Vector2i(x, y)] = RoomLayout.SYMBOL_SEAT
	var layout := _room(changes)
	assert_true(CinemaProps.aisle_light_cells(layout).size() > CinemaProps.MAX_AISLE_LIGHTS)
	assert_eq(CinemaProps.aisle_light_spots(layout).size(), CinemaProps.MAX_AISLE_LIGHTS)
