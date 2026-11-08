extends TestCase

const DIR := "res://data/rooms/flashback_cinema/"
const SEEDS := 300
const BossSpawn := preload("res://tests/test_boss_spawn_room.gd")
# The Projectionist and Cornelius Crabtree, who take the floor's boss rooms in Task 4.
const PROJECTIONIST_BODY := Vector2(44, 52)
const CRABTREE_BODY := Vector2(32, 40)
# Every symbol a Cinema room may hold: walls and floor, what the rules place, seats, pillars and cards.
const CINEMA_SYMBOLS := "#.EIHTBCSP-|i"
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
	for kind in [RoomDecor.GRASS, RoomDecor.BONES, RoomDecor.IV_STAND, RoomDecor.FURNACE, RoomDecor.GAUGE, RoomDecor.STAINED_GLASS, RoomDecor.COFFIN_STAND, RoomDecor.FLUORESCENT, RoomDecor.FOOD_TABLE, RoomDecor.BENCH, RoomDecor.PUDDLE]:
		assert_near(mine.weight_of(kind), 0.0, kind)


func test_the_patterns_stand_clear_of_every_other_one() -> void:
	for value in [0, 1, 2, 3, RoomBackdrop.FLOOR_TEAK_DECK, RoomBackdrop.FLOOR_OFFICE_CARPET]:
		assert_true(CinemaLook.CARPET != value, str(value))
	for value in [0, 1, 2, 3, RoomBackdrop.WALL_SHIP_RAIL, RoomBackdrop.WALL_OFFICE_PLASTER]:
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


# --- the path ---

func _basement() -> FloorDef:
	return _floor("floor_1")


func _pool() -> Array[RoomLayout]:
	return RoomCatalog.load_valid(_def().rooms_dir)


func _layouts() -> Array[RoomLayout]:
	var found: Array[RoomLayout] = []
	for resource in Content.load_dir(DIR):
		found.append(resource)
	return found


func _name(layout: RoomLayout) -> String:
	return layout.resource_path.get_file()


func test_the_cinema_is_the_locked_third_floor_path_with_its_own_rooms() -> void:
	var def := _def()
	assert_eq(def.id, "flashback_cinema")
	assert_eq(def.display_name, "The Flashback Cinema, Last Showing")
	assert_eq(def.depth, 3)
	assert_eq(def.clears_to_open, 1, "it opens after a third-floor clear")
	assert_eq(def.rooms_dir, DIR)


func test_its_difficulty_follows_the_third_floor() -> void:
	var def := _def()
	assert_near(def.health_mult, 1.8)
	assert_near(def.pension_mult, 2.0)
	assert_eq(def.enemies_by_size, {"small": 6, "medium": 8, "large": 13})
	assert_eq(def.treasure_pension, ceili(_basement().treasure_pension * 2.0))
	assert_eq(def.clear_pension, _basement().clear_pension)
	assert_eq(def.prop_pension, _basement().prop_pension)
	assert_eq(def.vault_stone_level, _basement().vault_stone_level)
	assert_eq(def.chest_weights, _floor("funeral_parlour").chest_weights, "the same chest odds as the other third floor")


# --- its enemies ---

func test_its_own_enemies_and_bosses() -> void:
	var def := _def()
	var ids: Array[String] = []
	for enemy: EnemyDef in def.enemies:
		ids.append(enemy.id)
	assert_eq(ids, ["film_reel", "usher", "popcorn_vendor", "cinema_intern_reaper", "cinema_notary_public"])
	assert_eq(def.enemy_weights, PackedInt32Array([3, 4, 3, 3, 2]), "the third floor's weights, by the Mall's roles")
	assert_eq(def.mimic.id, "mimic")


func test_every_enemy_of_the_floor_can_be_told_apart() -> void:
	var defs: Array[EnemyDef] = []
	defs.assign(_def().enemies)
	for boss in [_def().mini_boss, _def().floor_boss]:
		defs.append(boss)
		if boss.summon != null:
			defs.append(boss.summon)
	for i in defs.size():
		for j in range(i + 1, defs.size()):
			var a := SpriteVisual.readable(defs[i].color)
			var b := SpriteVisual.readable(defs[j].color)
			var size_gap := (defs[i].body_size - defs[j].body_size).length()
			assert_true(_difference(a, b) >= 0.25 or size_gap >= 12.0, "%s and %s look alike" % [defs[i].id, defs[j].id])


# --- its rooms ---

func test_every_layout_in_the_folder_is_valid() -> void:
	var count := 0
	for layout in _layouts():
		count += 1
		assert_eq(layout.validate().size(), 0, "%s: %s" % [_name(layout), str(layout.validate())])
	assert_eq(count, 33)


func test_the_rooms_keep_the_old_paths_mix() -> void:
	var mix := {}
	for layout in _layouts():
		var key := "%s %s" % [layout.room_type, layout.size_class()]
		mix[key] = int(mix.get(key, 0)) + 1
	assert_eq(mix, {
		"combat medium": 7, "combat large": 3, "combat small": 3,
		"mini_boss medium": 1, "mini_boss large": 1, "floor_boss medium": 1, "floor_boss large": 1,
		"item medium": 1, "item large": 1, "item small": 1, "healing medium": 1, "healing small": 1,
		"treasure medium": 1, "treasure small": 1, "side medium": 1, "side large": 1, "side small": 1,
		"secret medium": 1, "secret small": 1, "vault medium": 1, "vault large": 1, "vault small": 1,
		"shop medium": 1})


func test_combat_rooms_hold_the_third_floors_numbers() -> void:
	for layout in _pool():
		if layout.room_type == RoomLayout.TYPE_COMBAT:
			assert_eq(_def().room_size_errors(layout).size(), 0, "%s %s" % [_name(layout), str(_def().room_size_errors(layout))])


func test_every_room_type_a_floor_uses_is_covered() -> void:
	var types := {}
	for layout in _pool():
		types[layout.room_type] = true
	for room_type: String in RoomLayout.REQUIRED:
		if not room_type in [RoomLayout.TYPE_CROSSROADS, RoomLayout.TYPE_LANDING, RoomLayout.TYPE_ARCADE, RoomLayout.TYPE_DEPARTMENT]:
			assert_true(types.has(room_type), room_type)


# The Cinema has seat rows, pillars and lobby cards, and no hazard laid in its floor.
func test_rooms_hold_seats_pillars_and_chests_and_nothing_of_the_mall() -> void:
	var seats := 0
	var pillars := 0
	var chest_rooms := 0
	for layout in _layouts():
		for row in layout.rows:
			for symbol in row:
				assert_true(CINEMA_SYMBOLS.contains(symbol), "'%s' in %s" % [symbol, _name(layout)])
		seats += layout.cells_of(RoomLayout.SYMBOL_SEAT).size()
		pillars += layout.cells_of(RoomLayout.SYMBOL_PILLAR).size()
		chest_rooms += 1 if not layout.cells_of("C").is_empty() else 0
		assert_false(layout.ship_rolls, _name(layout))
	# Fewer, bigger seats than the first cut's 785 small ones, still enough to be cover in every room.
	assert_true(seats >= 250 and seats <= 400, "seat cells %d" % seats)
	assert_true(pillars >= 20, "pillars %d" % pillars)
	assert_true(chest_rooms >= 3, "rooms with a chest %d" % chest_rooms)


func test_seat_rows_leave_the_runners_clear() -> void:
	for layout in _layouts():
		var size := layout.size_in_cells()
		for cell in layout.cells_of(RoomLayout.SYMBOL_SEAT) + layout.cells_of(RoomLayout.SYMBOL_PILLAR):
			assert_false(CinemaLook.is_runner(cell, size), "%s blocks a runner at %s" % [_name(layout), str(cell)])


# Every fighting and boss room keeps its second row as wall, all but the north door's alcove, so the
# screen has a wall two cells deep, below the HUD's band, and never covers a door.
func test_every_fighting_room_keeps_its_north_wall_for_the_screen() -> void:
	var rooms := 0
	for layout in _layouts():
		if not CinemaScenes.shows_screen(layout.room_type):
			continue
		rooms += 1
		var size := layout.size_in_cells()
		var door := layout.door_cell(RoomLayout.NORTH)
		for x in range(1, size.x - 1):
			var wanted := RoomLayout.SYMBOL_FLOOR if x == door.x else RoomLayout.SYMBOL_WALL
			assert_eq(layout.rows[1][x], wanted, "%s row 1 at x %d" % [_name(layout), x])
		var wall := CinemaScreen.wall_rect(layout)
		assert_near(wall.size.y, RoomBackdrop.TILE * 2.0, "%s has a two-cell screen wall" % _name(layout))
		var picture := CinemaScreen.picture_rect_for(wall).grow(CinemaScreen.FRAME_WIDTH)
		assert_near(CinemaScreen.picture_rect_for(wall).size.x, float(CinemaScenes.FRAME_SIZE.x), _name(layout))
		var door_rect := Rect2(Vector2(door) * RoomBackdrop.TILE - Vector2(0, RoomBackdrop.TILE), Vector2(RoomBackdrop.TILE, RoomBackdrop.TILE * 2.0))
		assert_false(picture.intersects(door_rect), "%s: the screen covers the north door" % _name(layout))
		assert_true(picture.position.x >= RoomBackdrop.TILE and picture.end.y <= RoomBackdrop.TILE * 2.0, _name(layout))
	assert_eq(rooms, 17)


# A lobby card tells of the film on the screen, so it stands in the rooms with a screen only, one each,
# in the first row under the screen wall just west of the picture, clear of the doors and far from the
# small map in the top right.
func test_every_screen_room_has_one_lobby_card_beside_its_screen() -> void:
	var cards_seen := 0
	for layout in _layouts():
		var cards := layout.cells_of(RoomLayout.SYMBOL_LIFE_SIGN)
		if not CinemaScenes.shows_screen(layout.room_type):
			assert_eq(cards.size(), 0, "%s has no screen, so no card" % _name(layout))
			continue
		assert_eq(cards.size(), 1, _name(layout))
		var picture := CinemaScreen.picture_rect_for(CinemaScreen.wall_rect(layout))
		for cell in cards:
			cards_seen += 1
			assert_false(layout.touches_a_door(cell), "%s: the card at %s touches a door" % [_name(layout), str(cell)])
			assert_eq(cell.y, 2, "%s: the card stands right under the screen wall" % _name(layout))
			var x := RoomBackdrop.cell_center(cell).x
			assert_true(x <= picture.position.x and x >= picture.position.x - RoomBackdrop.TILE * 2.0, "%s: the card at %s stands just west of the picture" % [_name(layout), str(cell)])
	assert_eq(cards_seen, 17)


# The Projectionist (44x52) and Crabtree (32x40) take these rooms in Task 4, so their real collision
# boxes must start clear of seats and pillars, as test_boss_spawn_room checks for whoever holds them now.
func test_the_boss_rooms_fit_the_cinemas_own_bosses() -> void:
	var checked := 0
	for layout in _layouts():
		var body := Vector2.ZERO
		if layout.room_type == RoomLayout.TYPE_FLOOR_BOSS:
			body = PROJECTIONIST_BODY
		elif layout.room_type == RoomLayout.TYPE_MINI_BOSS:
			body = CRABTREE_BODY
		else:
			continue
		for cell in layout.cells_of("B"):
			checked += 1
			assert_eq(BossSpawn.solid_cells_under(layout, cell, body).size(), 0, "%s at %s" % [_name(layout), str(cell)])
			for offset in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]:
				assert_false(layout.is_solid_at(cell + offset), "%s: room round the boss at %s" % [_name(layout), str(cell + offset)])
	assert_eq(checked, 4)


func test_props_and_the_screen_go_into_a_fighting_room() -> void:
	var layout: RoomLayout = load(DIR + "combat_01.tres")
	var view := _bare_room(layout, RoomLayout.TYPE_COMBAT)
	CinemaProps.build(view, layout, _def().room_palette())
	var counts := {}
	for child in view.get_children():
		var kind: String = child.get_script().get_global_name()
		counts[kind] = int(counts.get(kind, 0)) + 1
	assert_eq(int(counts.get("CinemaSeat", 0)), layout.cells_of(RoomLayout.SYMBOL_SEAT).size())
	assert_eq(int(counts.get("CinemaScreen", 0)), 1, "one screen")
	assert_eq(int(counts.get("CinemaBeam", 0)), 1, "and its beam")
	assert_eq(int(counts.get("LifeSign", 0)), 1, "one lobby card")
	assert_true(int(counts.get("AisleLight", 0)) > 0, "aisle lights at the row ends")
	var film := CinemaScreen.in_room(view).scene_id
	assert_true(CinemaScenes.ids().has(film))
	# The card's lines are the film's: each it picks belongs to the film the screen plays.
	for child in view.get_children():
		if child is LifeSign:
			for i in LifeSigns.lines_of(film).size():
				var id: String = child.pick.call()
				assert_eq(LifeSigns.scene_of(id), film, "the card tells of %s" % film)
	view.free()


func test_a_shop_has_neither_card_nor_screen() -> void:
	var layout: RoomLayout = load(DIR + "shop_01.tres")
	var view := _bare_room(layout, RoomLayout.TYPE_SHOP)
	CinemaProps.build(view, layout, _def().room_palette())
	assert_true(CinemaScreen.in_room(view) == null, "no screen in a shop")
	var cards := 0
	for child in view.get_children():
		if child is LifeSign:
			cards += 1
	assert_eq(cards, 0)
	view.free()


# One chunky seat a cell, sized beside Harold (about 42 px tall): it fills its cell's height, where the
# first cut drew two or three small seats in a 30x15 strip.
func test_a_seat_is_one_big_seat_a_cell() -> void:
	PropArt.art_set = "flashback_cinema"
	var art := PropArt.texture("seat_row")
	PropArt.art_set = ""
	assert_true(art != null)
	assert_eq(Vector2i(art.get_size()), CinemaSeat.ART_SIZE)
	assert_true(CinemaSeat.ART_SIZE.y >= 28 and CinemaSeat.ART_SIZE.y <= RoomBackdrop.TILE, "as tall as a cell, no taller")
	assert_true(CinemaSeat.ART_SIZE.x <= RoomBackdrop.TILE, "within its cell, so a row's seats stand apart")


func test_another_floors_palette_never_hangs_a_screen() -> void:
	var layout: RoomLayout = load(DIR + "combat_01.tres")
	var view := _bare_room(layout, RoomLayout.TYPE_COMBAT)
	CinemaProps.build(view, layout, _floor("funeral_parlour").room_palette())
	assert_true(CinemaScreen.in_room(view) == null)
	view.free()


func _bare_room(layout: RoomLayout, type: String) -> RoomView:
	var room := FloorRoom.new()
	room.layout = layout
	room.room_type = type
	room.decor_seed = 12
	var no_upgrades: Array[UpgradeDef] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var view := RoomView.new()
	view.setup(room, null, _def(), RunState.new(no_upgrades, {}), null, rng, null, null)
	return view


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
			assert_eq(layout.vault_extra_cells(RoomLayout.VAULT_EXTRAS).size(), RoomLayout.VAULT_EXTRAS, _name(layout))
