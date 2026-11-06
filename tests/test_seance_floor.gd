extends TestCase

const DIR := "res://data/rooms/seance_hotline/"
const SEEDS := 300
const BossSpawn := preload("res://tests/test_boss_spawn_room.gd")
# Madame Zara and Sister Celestine, who take the floor's boss rooms later in Task 5.
const ZARA_BODY := Vector2(44, 52)
const CELESTINE_BODY := Vector2(32, 40)
# Every symbol a hotline room may hold: walls and floor, what the rules place, wall lanterns, and the
# hotline's desks, tables, partitions, lamps, curtains and filing trays.
const HOTLINE_SYMBOLS := "#.EIHTBCSPl" + "dqzaey"
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
	defs.append(load("res://data/enemies/ectoplasm.tres"))
	for def in defs:
		var body := _lit(SpriteVisual.readable(def.color), palette)
		for tone in _tones(palette):
			assert_true(_difference(body, _lit(tone, palette)) >= 0.22, "%s against the carpet" % def.id)


# --- its enemies ---

func test_its_own_enemies() -> void:
	var def := _def()
	var ids: Array[String] = []
	for enemy: EnemyDef in def.enemies:
		ids.append(enemy.id)
	assert_eq(ids, ["phone_psychic", "crystal_gazer", "poltergeist", "seance_bingo_caller", "seance_soot_ghost"])
	assert_eq(def.enemy_weights, PackedInt32Array([3, 4, 3, 3, 2]), "the fourth floor's weights, by the golf roles")
	assert_eq(def.mimic.id, "mimic")
	assert_near(def.health_mult, 2.2)


# Its own mini boss holds the mini boss rooms, calling no one.
func test_its_own_mini_boss() -> void:
	var def := _def()
	assert_eq(def.mini_boss.id, "celestine")
	assert_eq(def.mini_boss.summon, null)
	assert_eq(def.mini_boss.art_id, "celestine")


# Its own floor boss holds the boss rooms, manifesting the floor's own summon, the Ectoplasm.
func test_its_own_floor_boss() -> void:
	var def := _def()
	assert_eq(def.floor_boss.id, "madame_zara")
	assert_eq(def.floor_boss.art_id, "madame_zara")
	assert_eq(def.floor_boss.summon.id, "ectoplasm")
	for gone in ["thaddeus_fairweather", "caddie"]:
		assert_false(ResourceLoader.exists("res://data/enemies/%s.tres" % gone), "%s is retired" % gone)


# Madame Zara's teal is her own: apart from every other body of the floor by colour as well as size,
# and from the warning red, the mint and the violet carpet.
func test_madame_zaras_colour_is_told_apart_from_the_floor() -> void:
	var zara := SpriteVisual.readable(_def().floor_boss.color)
	var others: Array[EnemyDef] = []
	others.assign(_def().enemies)
	others.append(_def().mini_boss)
	others.append(_def().floor_boss.summon)
	for other in others:
		assert_true(_difference(zara, SpriteVisual.readable(other.color)) >= 0.25, "apart from %s" % other.id)
	assert_true(_difference(zara, Enemy.WARNING_COLOR) >= 0.4, "far from the warning red")
	assert_true(_difference(zara, SafeSpotMark.COLOR) >= 0.3, "and the mint")
	assert_true(_hue_gap(zara.h, _def().room_palette().floor_a.h) >= 0.1, "and the carpet's violet")
	assert_true(_def().floor_boss.color.s >= 0.4, "not a second pale body")


# Its regulars, its bosses and their summons, each told apart from all the others by colour or size.
func test_every_enemy_of_the_floor_can_be_told_apart() -> void:
	var defs: Array[EnemyDef] = []
	defs.assign(_def().enemies)
	for boss in [_def().mini_boss, _def().floor_boss]:
		defs.append(boss)
		if boss.summon != null and not defs.has(boss.summon):
			defs.append(boss.summon)
	var ectoplasm: EnemyDef = load("res://data/enemies/ectoplasm.tres")
	if not defs.has(ectoplasm):
		defs.append(ectoplasm)
	for i in defs.size():
		for j in range(i + 1, defs.size()):
			var a := SpriteVisual.readable(defs[i].color)
			var b := SpriteVisual.readable(defs[j].color)
			var size_gap := (defs[i].body_size - defs[j].body_size).length()
			assert_true(_difference(a, b) >= 0.25 or size_gap >= 12.0, "%s and %s look alike" % [defs[i].id, defs[j].id])


# No body of the floor is near the warning red or the safe-spot mint, and none sinks into the violet
# carpet: each keeps its own hue well away from the carpet's.
func test_no_body_is_red_mint_or_violet() -> void:
	var carpet := _def().room_palette().floor_a
	var defs: Array[EnemyDef] = []
	defs.assign(_def().enemies)
	defs.append(load("res://data/enemies/ectoplasm.tres"))
	for def in defs:
		var body := SpriteVisual.readable(def.color)
		assert_true(_difference(body, Enemy.WARNING_COLOR) >= 0.4, "%s is near the warning red" % def.id)
		assert_true(_difference(body, SafeSpotMark.COLOR) >= 0.3, "%s is near the mint" % def.id)
		assert_true(_hue_gap(body.h, carpet.h) >= 0.1 or body.s < 0.3, "%s is violet like the carpet" % def.id)


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


func _ready_alone(node: Node2D) -> void:
	node._ready()


func test_the_props_have_symbols_of_their_own() -> void:
	assert_eq(RoomLayout.SYMBOL_DESK + RoomLayout.SYMBOL_SEANCE_TABLE + RoomLayout.SYMBOL_PARTITION + RoomLayout.SYMBOL_LAVA_LAMP + RoomLayout.SYMBOL_BEADED_CURTAIN, "dqzae")
	for symbol in [RoomLayout.SYMBOL_DESK, RoomLayout.SYMBOL_SEANCE_TABLE, RoomLayout.SYMBOL_PARTITION]:
		assert_true(RoomLayout.ALLOWED.contains(symbol), symbol)
		assert_true(RoomLayout.SOLID_SYMBOLS.contains(symbol), symbol)
		assert_true(RoomLayout.WALLS_AND_BOMB_ONLY.contains(symbol), "%s needs more than the cane" % symbol)
		assert_false(RoomLayout.WALLS.contains(symbol), "%s can be blasted open" % symbol)
		assert_false(RoomLayout.WALL_LIKE.contains(symbol), symbol)
		assert_false(RoomLayout.DECOR_SYMBOLS.contains(symbol), symbol)
	for symbol in [RoomLayout.SYMBOL_LAVA_LAMP, RoomLayout.SYMBOL_BEADED_CURTAIN, RoomLayout.SYMBOL_IN_TRAY]:
		assert_true(RoomLayout.ALLOWED.contains(symbol), symbol)
		assert_true(RoomLayout.DECOR_SYMBOLS.contains(symbol), "%s blocks nothing" % symbol)
		assert_false(RoomLayout.SOLID_SYMBOLS.contains(symbol), symbol)
		assert_false(RoomLayout.WALLS_AND_BOMB_ONLY.contains(symbol), symbol)
	for symbol in "dqzae":
		assert_eq(RoomLayout.ALLOWED.count(symbol), 1, "%s is used once" % symbol)


# A desk, a table and a partition are cover, as the Cinema's seats are: solid on the wall layer, which
# stops walkers and every shot, broken only by blasts and bosses, and each can hide a coin.
func test_desks_tables_and_partitions_are_cover_that_can_hide_a_coin() -> void:
	for piece: RockBlock in [PsychicDesk.new(), SeanceTable.new(), SeancePartition.new()]:
		_ready_alone(piece)
		assert_true(piece.is_solid(), piece.art_id())
		assert_eq(piece.collision_layer, 1, "%s on the wall layer" % piece.art_id())
		assert_true(piece.get_child_count() > 0, "%s has a body" % piece.art_id())
		assert_false(piece.can_break_by(BreakableBlock.SOURCE_CANE), "the cane only bounces off %s" % piece.art_id())
		assert_true(piece.can_break_by(BreakableBlock.SOURCE_BLAST), piece.art_id())
		assert_true(piece.can_break_by(BreakableBlock.SOURCE_BOSS), piece.art_id())
		assert_false(BossDash.stops_at(piece), "a charge smashes through %s" % piece.art_id())
		piece.free()
	var partition := SeancePartition.new()
	var as_node: Node = partition
	assert_true(as_node is CubicleWall, "the office's partition in violet")
	assert_true(_difference(partition.debris_color(), CubicleWall.FABRIC) > 0.15, "a fabric of its own")
	partition.free()


# Each prop is drawn at the size of its art, so the pictures drop in later: the desk 64x48 over two
# cells, the table 64x64 over four, the partition a 32x48 half of its 64x48 strip, the lamp 32x48 and
# the curtain 48x64.
func test_each_prop_is_named_and_sized_for_its_art() -> void:
	var desk := PsychicDesk.new()
	assert_eq(desk.art_id(), "psychic_desk")
	assert_eq(desk.art_size(), Vector2(64, 48))
	assert_eq(desk.body_size(), Vector2(64, 32), "two cells wide")
	desk.wide = false
	assert_eq(desk.body_size(), Vector2(32, 32), "a narrow desk fills one cell")
	assert_true(desk.art_id() != "psychic_desk", "and never stretches the wide art")
	desk.free()
	var table := SeanceTable.new()
	assert_eq(table.art_id(), "seance_table")
	assert_eq(table.art_size(), Vector2(64, 64))
	assert_eq(table.body_size(), Vector2(64, 64), "four cells")
	table.large = false
	assert_eq(table.body_size(), Vector2(32, 32))
	assert_true(table.art_id() != "seance_table")
	table.free()
	var partition := SeancePartition.new()
	assert_eq(partition.art_id(), "cubicle_partition")
	assert_eq(SeancePartition.ART_SIZE, Vector2(32, 48))
	partition.free()
	var lamp := LavaLamp.new()
	assert_eq(lamp.art_id(), "lava_lamp")
	assert_eq(LavaLamp.ART_SIZE, Vector2(32, 48))
	lamp.free()
	var curtain := BeadedCurtain.new()
	assert_eq(curtain.art_id(), "beaded_curtain")
	assert_eq(BeadedCurtain.ART_SIZE, Vector2(48, 64))
	curtain.free()


func test_a_lava_lamp_blocks_nothing_breaks_to_anything_and_glows() -> void:
	var lamp := LavaLamp.new()
	_ready_alone(lamp)
	assert_false(lamp.is_solid())
	assert_eq(lamp.collision_layer, 0, "nothing bumps into it")
	for source in [BreakableBlock.SOURCE_CANE, BreakableBlock.SOURCE_BLAST, BreakableBlock.SOURCE_BOSS]:
		assert_true(lamp.can_break_by(source), source)
	var as_node: Node = lamp
	assert_false(as_node is RockBlock, "it hides no coin")
	var lights := 0
	for child: Variant in lamp.get_children():
		if child is PointLight2D:
			lights += 1
			assert_true(child.energy < 0.6 and child.texture_scale < 0.6, "a small soft light")
	assert_eq(lights, 1)
	lamp.free()


func test_a_seance_table_lights_its_candles() -> void:
	var table := SeanceTable.new()
	_ready_alone(table)
	var lit := false
	for child: Variant in table.get_children():
		lit = lit or child is PointLight2D
	assert_true(lit, "the candles light the carpet")
	table.free()


func test_a_beaded_curtain_blocks_nothing_never_breaks_and_parts_round_him() -> void:
	var curtain := BeadedCurtain.new()
	var as_node: Node = curtain
	assert_false(as_node is CollisionObject2D, "nothing bumps into it")
	assert_false(as_node is BreakableBlock, "nothing breaks it")
	_ready_alone(curtain)
	assert_true(curtain.z_index < 0, "under the bodies")
	assert_true(BeadedCurtain.ALPHA < 1.0, "nothing behind it hides")
	curtain.free()
	assert_true(BeadedCurtain.is_near(Vector2(10, 12)))
	assert_false(BeadedCurtain.is_near(Vector2(40, 0)))
	assert_true(BeadedCurtain.strand_shift(6.0, 0.0) > 0.0, "a strand east of him swings east")
	assert_true(BeadedCurtain.strand_shift(-6.0, 0.0) < 0.0, "and one west of him west")
	assert_true(BeadedCurtain.strand_shift(2.0, 0.0) > BeadedCurtain.strand_shift(12.0, 0.0), "the nearest swing most")
	assert_near(BeadedCurtain.strand_shift(30.0, 0.0), 0.0, "far strands hang still")


func test_desks_pair_up_along_a_row_and_tables_fill_a_square() -> void:
	var layout := _room({
		Vector2i(3, 3): "d", Vector2i(4, 3): "d", Vector2i(5, 3): "d", Vector2i(6, 3): "d",
		Vector2i(3, 6): "d", Vector2i(4, 6): "d", Vector2i(5, 6): "d",
		Vector2i(13, 3): "q", Vector2i(14, 3): "q", Vector2i(13, 4): "q", Vector2i(14, 4): "q", Vector2i(13, 5): "q",
	})
	var desks := SeanceProps.desk_groups(layout)
	assert_eq(desks.size(), 4)
	assert_eq(desks[0], [Vector2i(3, 3), Vector2i(4, 3)])
	assert_eq(desks[1], [Vector2i(5, 3), Vector2i(6, 3)])
	assert_eq(desks[2], [Vector2i(3, 6), Vector2i(4, 6)])
	assert_eq(desks[3], [Vector2i(5, 6)], "the odd cell at the row's end is a narrow desk")
	var tables := SeanceProps.table_groups(layout)
	assert_eq(tables.size(), 2)
	assert_eq(tables[0].size(), 4, "a square is one round table")
	assert_eq(tables[1], [Vector2i(13, 5)], "a cell left over is a small table")
	assert_eq(SeanceProps.middle_of(tables[0]), Vector2(14 * 32, 4 * 32), "the table stands at the square's middle")


func test_cover_needs_a_blast_and_stays_clear_of_doors() -> void:
	for symbol in ["d", "q", "z"]:
		var changes := {}
		for y in range(1, 10):
			changes[Vector2i(14, y)] = symbol
		assert_true(str(_room(changes).validate()).contains("needs a bomb"), "%s needs a bomb" % symbol)
		assert_true(_room({Vector2i(9, 2): symbol}).validate().size() > 0, "%s beside a door" % symbol)
	assert_eq(_room({Vector2i(6, 3): "d", Vector2i(7, 3): "d", Vector2i(6, 2): "z", Vector2i(7, 2): "z", Vector2i(13, 6): "a", Vector2i(4, 6): "e", Vector2i(15, 3): "y"}).validate().size(), 0, "a cubicle and its decor are fine")


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


func test_the_props_go_into_a_room_one_piece_each() -> void:
	var layout := _room({
		Vector2i(3, 3): "z", Vector2i(4, 3): "z", Vector2i(5, 3): "z", Vector2i(6, 3): "z",
		Vector2i(3, 4): "d", Vector2i(4, 4): "d", Vector2i(5, 4): "d", Vector2i(6, 4): "d",
		Vector2i(13, 6): "q", Vector2i(14, 6): "q", Vector2i(13, 7): "q", Vector2i(14, 7): "q",
		Vector2i(15, 3): "a", Vector2i(12, 3): "e", Vector2i(16, 3): "y",
	})
	var view := _bare_room(layout, RoomLayout.TYPE_HEALING)
	SeanceProps.build(view, layout, _def().room_palette())
	var counts := {}
	for child: Variant in view.get_children():
		var kind: String = child.get_script().get_global_name()
		counts[kind] = int(counts.get(kind, 0)) + 1
	assert_eq(int(counts.get("SeancePartition", 0)), 4, "one partition a cell")
	assert_eq(int(counts.get("PsychicDesk", 0)), 2, "two wide desks")
	assert_eq(int(counts.get("SeanceTable", 0)), 1, "one round table")
	assert_eq(int(counts.get("LavaLamp", 0)), 1)
	assert_eq(int(counts.get("BeadedCurtain", 0)), 1)
	for child: Variant in view.get_children():
		if child is PsychicDesk:
			assert_true(child.wide)
			var west := WalkGrid.cell_of(child.position - Vector2(16, 0))
			var east := WalkGrid.cell_of(child.position + Vector2(16, 0))
			assert_true(west != east and layout.symbol_at(west) == "d" and layout.symbol_at(east) == "d", "a desk stands over its two cells")
		if child is SeanceTable:
			assert_true(child.large)
			assert_eq(child.position, Vector2(14 * 32, 7 * 32))
	view.free()


# A piece over several cells opens every one of them when it breaks, so walkers path through the gap.
func test_a_broken_desk_or_table_opens_every_cell_it_stood_on() -> void:
	var layout := _room({
		Vector2i(3, 4): "d", Vector2i(4, 4): "d", Vector2i(5, 4): "d", Vector2i(6, 4): "d", Vector2i(7, 4): "d", Vector2i(8, 4): "d",
		Vector2i(13, 6): "q", Vector2i(14, 6): "q", Vector2i(13, 7): "q", Vector2i(14, 7): "q",
	})
	var view := _bare_room(layout, RoomLayout.TYPE_HEALING)
	SeanceProps.build(view, layout, _def().room_palette())
	var desk: PsychicDesk = null
	var table: SeanceTable = null
	for child: Variant in view.get_children():
		if child is PsychicDesk and not child.hides_coin and desk == null:
			desk = child
		if child is SeanceTable:
			table = child
	assert_true(desk != null, "a desk with no coin to drop")
	desk.broken.emit(desk.global_position)
	var desk_open := 0
	for cell in layout.cells_of("d"):
		desk_open += 1 if view._broken_cells.has(cell) else 0
	assert_eq(desk_open, 2, "both of the desk's cells, and no other")
	if not table.hides_coin:
		table.broken.emit(table.global_position)
		for cell in layout.cells_of("q"):
			assert_true(view._broken_cells.has(cell), "the table's cell %s" % str(cell))
	view.free()


func test_the_props_leave_no_lingering_effect_yet() -> void:
	var node := Node2D.new()
	assert_false(SeanceProps.is_passing_effect(node))
	node.free()
	var source := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	assert_true(source.contains("SeanceProps.is_passing_effect(child)"), "the room asks the hotline what lingers")
	assert_true(source.contains("SeanceProps.build(self, layout, palette)"), "and lets it lay its props")


# Debris is a few small dots, so each prop's must show on the carpet it falls on.
func test_every_props_debris_shows_on_the_carpet() -> void:
	var palette := _def().room_palette()
	for prop: BreakableBlock in [PsychicDesk.new(), SeanceTable.new(), SeancePartition.new(), LavaLamp.new()]:
		prop.palette = palette
		for tone in _tones(palette):
			assert_true(_difference(prop.debris_color(), tone) > 0.25, "%s debris against %s" % [prop.art_id(), str(tone)])
		prop.free()
	var tray := InTray.new()
	for tone in _tones(palette):
		assert_true(_difference(tray.debris_color(), tone) > 0.25, "filing tray debris")
	tray.free()


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


func test_the_hotline_is_the_locked_fourth_floor_path_with_its_own_rooms() -> void:
	var def := _def()
	assert_eq(def.id, "seance_hotline")
	assert_eq(def.display_name, "Beyond Calling Psychic Hotline, Night Shift")
	assert_eq(def.depth, 4)
	assert_eq(def.open_after_depth, 4)
	assert_eq(def.clears_to_open, 1, "it opens after a fourth-floor clear")
	assert_eq(def.danger, 6)
	assert_eq(def.closed_hint, "Beat a fourth-floor boss first")
	assert_eq(def.rooms_dir, DIR)


func test_its_difficulty_follows_the_fourth_floor() -> void:
	var def := _def()
	assert_near(def.health_mult, 2.2)
	assert_near(def.pension_mult, 2.5)
	assert_eq(def.enemies_by_size, {"small": 7, "medium": 9, "large": 14})
	assert_eq(def.treasure_pension, 20)
	assert_eq(def.clear_pension, _basement().clear_pension)
	assert_eq(def.prop_pension, _basement().prop_pension)
	assert_eq(def.vault_stone_level, _basement().vault_stone_level)
	assert_eq(def.chest_weights, {"lunchbox": 26, "locked": 22, "safe": 20, "urn": 16, "mimic": 16})


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


func test_combat_rooms_hold_the_fourth_floors_numbers() -> void:
	var combat := 0
	for layout in _pool():
		if layout.room_type == RoomLayout.TYPE_COMBAT:
			combat += 1
			assert_eq(_def().room_size_errors(layout).size(), 0, "%s %s" % [_name(layout), str(_def().room_size_errors(layout))])
	assert_eq(combat, 13)


func test_every_room_type_a_floor_uses_is_covered() -> void:
	var types := {}
	for layout in _pool():
		types[layout.room_type] = true
	for room_type: String in RoomLayout.REQUIRED:
		if not room_type in [RoomLayout.TYPE_CROSSROADS, RoomLayout.TYPE_LANDING, RoomLayout.TYPE_ARCADE, RoomLayout.TYPE_DEPARTMENT]:
			assert_true(types.has(room_type), room_type)


# Cubicle rows of partitions and desks, filing trays, lava lamps and curtains, a seance table in every
# large room, chests in a few fighting rooms, and nothing of the golf course: no sand, flags, ball
# washers or hedges.
func test_rooms_hold_the_hotlines_props_and_nothing_of_the_golf_course() -> void:
	var counts := {}
	var chest_rooms := 0
	for layout in _layouts():
		for row in layout.rows:
			for symbol in row:
				assert_true(HOTLINE_SYMBOLS.contains(symbol), "'%s' in %s" % [symbol, _name(layout)])
				counts[symbol] = int(counts.get(symbol, 0)) + 1
		if layout.room_type == RoomLayout.TYPE_COMBAT and not layout.cells_of("C").is_empty():
			chest_rooms += 1
		assert_false(layout.ship_rolls, _name(layout))
	for symbol in [RoomLayout.SYMBOL_SAND, RoomLayout.SYMBOL_FLAG, RoomLayout.SYMBOL_BALL_WASHER, RoomLayout.SYMBOL_HEDGE]:
		assert_eq(int(counts.get(symbol, 0)), 0, "no %s" % symbol)
	assert_true(int(counts.get(RoomLayout.SYMBOL_PARTITION, 0)) >= 200, "partition cells %d" % int(counts.get("z", 0)))
	assert_true(int(counts.get(RoomLayout.SYMBOL_DESK, 0)) >= 150, "desk cells %d" % int(counts.get("d", 0)))
	assert_true(int(counts.get(RoomLayout.SYMBOL_LAVA_LAMP, 0)) >= 20, "lava lamps %d" % int(counts.get("a", 0)))
	assert_true(int(counts.get(RoomLayout.SYMBOL_BEADED_CURTAIN, 0)) >= 10, "curtains %d" % int(counts.get("e", 0)))
	assert_true(int(counts.get(RoomLayout.SYMBOL_IN_TRAY, 0)) >= 10, "filing trays %d" % int(counts.get("y", 0)))
	assert_true(chest_rooms >= 3, "fighting rooms with a chest %d" % chest_rooms)


# Desks pair up along a row and tables fill a square, so every piece is whole: no desk run of odd
# length, every table cell in a square, and a seance table in every large room and only there.
func test_every_desk_and_table_is_whole_and_every_large_room_has_a_table() -> void:
	for layout in _layouts():
		for desk: Array in SeanceProps.desk_groups(layout):
			assert_eq(desk.size(), 2, "%s: a narrow desk at %s" % [_name(layout), str(desk[0])])
		var tables := SeanceProps.table_groups(layout)
		for table: Array in tables:
			assert_eq(table.size(), 4, "%s: a small table at %s" % [_name(layout), str(table[0])])
		if layout.size_class() == RoomLayout.SIZE_LARGE:
			assert_true(tables.size() >= 1, "%s has a seance table" % _name(layout))
		else:
			assert_eq(tables.size(), 0, "%s is too small for a seance table" % _name(layout))


# A partition, a desk or a table can hide a coin at the furniture rate, so the floor holds no more such
# pieces than the Cinema has seats (lesson: count a coin prop across the folder before wiring it).
func test_the_coin_props_are_counted_against_the_cinemas_seats() -> void:
	var pieces := 0
	for layout in _layouts():
		pieces += layout.cells_of(RoomLayout.SYMBOL_PARTITION).size()
		pieces += SeanceProps.desk_groups(layout).size() + SeanceProps.table_groups(layout).size()
	var seats := 0
	for resource in Content.load_dir("res://data/rooms/flashback_cinema/"):
		seats += resource.cells_of(RoomLayout.SYMBOL_SEAT).size()
	assert_true(pieces >= 200, "coin pieces %d" % pieces)
	assert_true(pieces <= seats, "%d coin pieces against the Cinema's %d seats" % [pieces, seats])


# Celestine (32x40) and Madame Zara (44x52) take these rooms later, so their real collision boxes must
# start clear of every desk, table and partition, with the cells all round the B open, as
# test_boss_spawn_room checks for whoever holds them now.
func test_the_boss_rooms_fit_the_hotlines_own_bosses() -> void:
	var checked := 0
	for layout in _layouts():
		if layout.room_type != RoomLayout.TYPE_FLOOR_BOSS and layout.room_type != RoomLayout.TYPE_MINI_BOSS:
			continue
		for cell in layout.cells_of("B"):
			checked += 1
			for body in [CELESTINE_BODY, ZARA_BODY]:
				assert_eq(BossSpawn.solid_cells_under(layout, cell, body).size(), 0, "%s at %s for %s" % [_name(layout), str(cell), str(body)])
			for offset in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]:
				assert_false(layout.is_solid_at(cell + offset), "%s: room round the boss at %s" % [_name(layout), str(cell + offset)])
	assert_eq(checked, 4)


func test_props_go_into_a_fighting_room() -> void:
	var layout: RoomLayout = load(DIR + "combat_large_01.tres")
	var view := _bare_room(layout, RoomLayout.TYPE_COMBAT)
	SeanceProps.build(view, layout, _def().room_palette())
	var counts := {}
	for child: Variant in view.get_children():
		var kind: String = child.get_script().get_global_name()
		counts[kind] = int(counts.get(kind, 0)) + 1
	assert_eq(int(counts.get("SeancePartition", 0)), layout.cells_of(RoomLayout.SYMBOL_PARTITION).size())
	assert_eq(int(counts.get("PsychicDesk", 0)), layout.cells_of(RoomLayout.SYMBOL_DESK).size() / 2)
	assert_eq(int(counts.get("SeanceTable", 0)), layout.cells_of(RoomLayout.SYMBOL_SEANCE_TABLE).size() / 4)
	assert_eq(int(counts.get("LavaLamp", 0)), layout.cells_of(RoomLayout.SYMBOL_LAVA_LAMP).size())
	assert_eq(int(counts.get("BeadedCurtain", 0)), layout.cells_of(RoomLayout.SYMBOL_BEADED_CURTAIN).size())
	view.free()


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
			assert_eq(layout.vault_extra_cells(RoomLayout.VAULT_EXTRAS).size(), RoomLayout.VAULT_EXTRAS, _name(layout))


func test_every_shop_plan_tier_has_a_spot() -> void:
	for layout in _pool():
		if layout.room_type == RoomLayout.TYPE_SHOP:
			assert_eq(layout.plan_reward_cells(ProgressData.RETIREMENT_TIERS.size()).size(), ProgressData.RETIREMENT_TIERS.size(), _name(layout))
			assert_true(layout.merchant_cell() != Vector2i(-1, -1), _name(layout))
