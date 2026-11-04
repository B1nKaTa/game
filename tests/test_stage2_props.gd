extends TestCase

const SEEDS := 40


func _root() -> Node:
	return Engine.get_main_loop().root


# Tests run before the tree starts, so a node is made ready by hand and kept out of it.
func _in_tree(node: Node2D, at := Vector2.ZERO) -> Node2D:
	node.position = at
	node._ready()
	return node


func _layout(changes: Dictionary = {}, type := RoomLayout.TYPE_COMBAT) -> RoomLayout:
	var rows := ["####################"]
	for y in range(1, 10):
		rows.append("#..................#")
	rows.append("####################")
	rows[5] = "#.......E..E.......#"
	for cell: Vector2i in changes:
		var row: String = rows[cell.y]
		rows[cell.y] = row.substr(0, cell.x) + changes[cell] + row.substr(cell.x + 1)
	var layout := RoomLayout.new()
	layout.room_type = type
	layout.rows = PackedStringArray(rows)
	return layout


# --- who breaks what ---

func test_a_crate_breaks_to_bombs_and_bosses_only() -> void:
	var crate := BreakableBlock.new()
	assert_true(crate.can_break_by(BreakableBlock.SOURCE_BLAST))
	assert_true(crate.can_break_by(BreakableBlock.SOURCE_BOSS))
	assert_false(crate.can_break_by(BreakableBlock.SOURCE_CANE))
	crate.free()


func test_a_rock_breaks_to_bombs_and_bosses_not_the_cane() -> void:
	var rock := RockBlock.new()
	assert_true(rock.can_break_by(BreakableBlock.SOURCE_BLAST))
	assert_true(rock.can_break_by(BreakableBlock.SOURCE_BOSS))
	assert_false(rock.can_break_by(BreakableBlock.SOURCE_CANE))
	assert_false(rock.hit_by(BreakableBlock.SOURCE_CANE), "a hit it ignores does nothing")
	assert_false(rock.is_queued_for_deletion())
	rock.free()


func test_a_barrel_breaks_to_everything() -> void:
	var barrel := Barrel.new()
	for source in [BreakableBlock.SOURCE_BLAST, BreakableBlock.SOURCE_BOSS, BreakableBlock.SOURCE_CANE]:
		assert_true(barrel.can_break_by(source), source)
	assert_true(barrel.is_solid())
	barrel.free()


func test_piles_and_grass_block_nothing_but_break_to_everything() -> void:
	for prop: BreakableBlock in [BonePile.new(), GrassTuft.new()]:
		assert_false(prop.is_solid())
		assert_true(prop.can_break_by(BreakableBlock.SOURCE_CANE))
		prop.free()


func test_the_secret_wall_and_the_plan_never_yield_to_bosses_or_the_cane() -> void:
	var wall := SecretWall.new()
	assert_true(wall.can_break_by(BreakableBlock.SOURCE_BLAST))
	assert_false(wall.can_break_by(BreakableBlock.SOURCE_BOSS))
	assert_false(wall.can_break_by(BreakableBlock.SOURCE_CANE))
	wall.free()
	var station := RetirementStation.new()
	for source in [BreakableBlock.SOURCE_BLAST, BreakableBlock.SOURCE_BOSS, BreakableBlock.SOURCE_CANE]:
		assert_false(station.can_break_by(source), source)
	station.free()


func test_only_the_players_thermos_opens_a_secret_wall() -> void:
	var wall := _in_tree(SecretWall.new(), Vector2(4000, 4000))
	BreakableBlock.smash_among([wall], Vector2(4000, 4000), 40.0, BreakableBlock.SOURCE_BLAST)
	assert_false(wall.is_queued_for_deletion(), "an Auditor's blast leaves the crack alone")
	assert_eq(SecretWall.blast_among([wall], Vector2(4200, 4000), 40.0), 0, "too far away")
	assert_eq(SecretWall.blast_among([wall], Vector2(4000, 4000), 40.0), 1)
	assert_true(wall.is_queued_for_deletion())
	wall.free()


func test_breaking_announces_the_spot_once() -> void:
	var barrel := Barrel.new()
	var spots: Array[Vector2] = []
	barrel.broken.connect(func(at: Vector2): spots.append(at))
	_in_tree(barrel, Vector2(50, 60))
	assert_true(barrel.hit_by(BreakableBlock.SOURCE_CANE))
	assert_false(barrel.hit_by(BreakableBlock.SOURCE_CANE), "already breaking")
	assert_eq(spots.size(), 1)
	assert_eq(spots[0], Vector2(50, 60))
	barrel.free()


func test_a_bomb_blast_goes_through_take_blast_so_the_plan_stays_put() -> void:
	var station := RetirementStation.new()
	var blasts := [0]
	station.blasted.connect(func(): blasts[0] += 1)
	_in_tree(station, Vector2(10, 10))
	assert_eq(BreakableBlock.smash_among([station], Vector2(10, 10), 40.0, BreakableBlock.SOURCE_BLAST), 1)
	assert_eq(blasts[0], 1)
	assert_false(station.is_queued_for_deletion())
	assert_eq(BreakableBlock.smash_among([station], Vector2(10, 10), 40.0, BreakableBlock.SOURCE_BOSS), 0, "bosses leave the plan alone")
	station.free()


func test_a_boss_smash_breaks_what_it_reaches_and_no_more() -> void:
	var near_rock := _in_tree(RockBlock.new(), Vector2(3000, 3000))
	var near_barrel := _in_tree(Barrel.new(), Vector2(3050, 3000))
	var near_crate := _in_tree(BreakableBlock.new(), Vector2(3000, 3050))
	var far_rock := _in_tree(RockBlock.new(), Vector2(3500, 3000))
	var broke := BreakableBlock.smash_among([near_rock, near_barrel, near_crate, far_rock], Vector2(3020, 3020), 60.0, BreakableBlock.SOURCE_BOSS)
	assert_eq(broke, 3)
	assert_true(near_rock.is_queued_for_deletion())
	assert_true(near_barrel.is_queued_for_deletion())
	assert_true(near_crate.is_queued_for_deletion())
	assert_false(far_rock.is_queued_for_deletion())
	for node: Node in [near_rock, near_barrel, near_crate, far_rock]:
		node.free()


func test_cut_grass_stays_cut_and_leaves_the_breakable_group() -> void:
	var tuft := _in_tree(GrassTuft.new(), Vector2(4000, 4000)) as GrassTuft
	assert_true(tuft.is_in_group("breakable"))
	assert_true(tuft.hit_by(BreakableBlock.SOURCE_CANE))
	assert_true(tuft.cut)
	assert_false(tuft.is_in_group("breakable"))
	assert_false(tuft.hit_by(BreakableBlock.SOURCE_CANE), "cut once")
	assert_false(tuft.is_queued_for_deletion(), "the stubble stays")
	tuft.free()


# --- holes and layers ---

func test_a_hole_has_its_own_layer_that_walls_and_shots_do_not_use() -> void:
	assert_true(Hole.LAYER != 1)
	assert_eq(ThrownDentures.WALL_LAYER & Hole.LAYER, 0, "thrown dentures fly over holes")
	var hole := _in_tree(Hole.new(), Vector2(5000, 5000)) as Hole
	assert_eq(hole.collision_layer, Hole.LAYER)
	hole.free()


func test_grandpa_and_walking_enemies_collide_with_holes_but_ghosts_do_not() -> void:
	var player := Player.new()
	var no_upgrades: Array[UpgradeDef] = []
	player.setup(RunState.new(no_upgrades, {}))
	_in_tree(player, Vector2(6000, 6000))
	assert_true(player.collision_mask & Hole.LAYER != 0)
	assert_true(player.collision_mask & 1 != 0)
	player.free()
	var walker := Enemy.new()
	walker.setup(load("res://data/enemies/intern_reaper.tres"), null, 0.5)
	_in_tree(walker, Vector2(6000, 6100))
	assert_true(walker.collision_mask & Hole.LAYER != 0)
	walker.free()
	var ghost := Enemy.new()
	ghost.setup(load("res://data/enemies/debt_ghost.tres"), null, 0.5)
	_in_tree(ghost, Vector2(6000, 6200))
	assert_eq(ghost.collision_mask, 0, "ghosts ignore holes and walls")
	ghost.free()


func test_enemy_shots_ignore_holes() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/actors/projectile.gd")
	assert_true(source.contains("PhysicsRayQueryParameters2D.create(global_position, next, 1)"), "shots only look at the wall layer")


# --- drops ---

func test_most_barrels_hold_nothing_or_a_coin() -> void:
	var nothing := 0
	var coin := 0
	var kinds := {}
	for i in 1000:
		var drop := RoomRules.barrel_drop(i / 1000.0)
		kinds[drop] = true
		if drop == RoomRules.DROP_NONE:
			nothing += 1
		elif drop == RoomRules.DROP_COIN:
			coin += 1
	assert_true(nothing + coin >= 800, "nothing or coin: %d" % (nothing + coin))
	for kind in [RoomRules.DROP_KEY, RoomRules.DROP_BOMB, RoomRules.DROP_COIN, RoomRules.DROP_POTION, RoomRules.DROP_NONE]:
		assert_true(kinds.has(kind), "a barrel can drop '%s'" % kind)


func test_piles_and_rocks_rarely_hold_coins() -> void:
	assert_true(RoomRules.pile_drops_coin(0.0))
	assert_false(RoomRules.pile_drops_coin(0.5))
	assert_true(RoomRules.rock_hides_coin(0.0))
	assert_false(RoomRules.rock_hides_coin(0.9))
	assert_true(RoomRules.PILE_COIN_CHANCE < 0.25, "a small chance")


func test_a_drop_lands_on_open_floor_whatever_died_over() -> void:
	var layout := _layout({Vector2i(5, 3): "O", Vector2i(6, 3): "V", Vector2i(7, 3): "Q"})
	var room := FloorRoom.new()
	room.layout = layout
	var view := RoomView.new()
	view.setup(room, null, null, null, null, null, null, null)
	for x in [5, 6, 7]:
		var spot := view.clear_spot(RoomBackdrop.cell_center(Vector2i(x, 3)))
		var cell := Vector2i(floori(spot.x / RoomBackdrop.TILE), floori(spot.y / RoomBackdrop.TILE))
		assert_false(layout.is_solid_at(cell), "cell %d" % x)
	var open := RoomBackdrop.cell_center(Vector2i(10, 7))
	assert_eq(view.clear_spot(open), open, "open floor is left alone")
	view.free()


func test_the_third_floors_effects_are_cleared_from_a_stored_room() -> void:
	var effects: Array[Node] = [PerfumeCloud.new(), WetSplash.new(), DroppedCoffin.new(), PresentDrop.new(), ClosingRing.new(),
		# Head Office
		TapeSpread.new(), PaperTrail.new(), WriteUpMark.new(), LaneDrop.new(), HoldMusic.new(), TakeoverTether.new(), GavelStrike.new()]
	for effect in effects:
		assert_true(RoomView.is_passing_effect(effect), "%s is cleared" % effect.get_script().get_global_name())
		effect.free()
	var pickup := Pickup.new()
	assert_false(RoomView.is_passing_effect(pickup), "a lying pickup is remembered")
	pickup.free()


# --- decor ---

func test_the_same_seed_gives_the_same_decor() -> void:
	var layout := _layout()
	var palette := RoomPalette.new()
	assert_eq(RoomDecor.plan(layout, palette, 7), RoomDecor.plan(layout, palette, 7))


func test_a_repeated_layout_looks_different_in_another_room() -> void:
	var layout := _layout()
	var palette := RoomPalette.new()
	var different := 0
	for i in 10:
		if RoomDecor.plan(layout, palette, i) != RoomDecor.plan(layout, palette, i + 100):
			different += 1
	assert_eq(different, 10)


func test_scatter_keeps_off_doors_and_solid_cells() -> void:
	var layout := _layout({Vector2i(5, 3): "O", Vector2i(6, 3): "V", Vector2i(7, 3): "Q", Vector2i(9, 7): "Z", Vector2i(3, 3): "X"})
	var palette := RoomPalette.new()
	palette.decor_density = 0.4
	for seed_value in SEEDS:
		for item in RoomDecor.plan(layout, palette, seed_value):
			var cell: Vector2i = item["cell"]
			if item["kind"] == RoomDecor.LANTERN:
				assert_eq(layout.symbol_at(cell), "#")
				continue
			assert_eq(layout.symbol_at(cell), ".", "%s at %s" % [item["kind"], str(cell)])
			for side in RoomLayout.SIDES:
				var door := layout.door_cell(side)
				assert_true(absi(cell.x - door.x) > 1 or absi(cell.y - door.y) > 1, "decor beside a door at %s" % str(cell))


func test_lanterns_never_cover_a_crack_or_a_corner() -> void:
	var layout := _layout()
	var palette := RoomPalette.new()
	palette.decor_weights = {"lantern": 1.0}
	palette.scatter_lights = 50
	palette.decor_density = 1.0
	var seen := 0
	for seed_value in SEEDS:
		for item in RoomDecor.plan(layout, palette, seed_value):
			var cell: Vector2i = item["cell"]
			seen += 1
			for side in RoomLayout.SIDES:
				assert_true(cell != layout.wall_cell(side))
			assert_true((cell.x == 0 or cell.x == 19) != (cell.y == 0 or cell.y == 10), "not in a corner: %s" % str(cell))
	assert_true(seen > 0)


func test_the_light_scatter_is_capped() -> void:
	var layout := _layout()
	var palette := RoomPalette.new()
	palette.decor_weights = {"torch": 1.0, "lantern": 1.0, "grass": 1.0}
	palette.decor_density = 0.5
	palette.scatter_lights = 2
	for seed_value in SEEDS:
		var lights := 0
		for item in RoomDecor.plan(layout, palette, seed_value):
			if RoomDecor.is_light(item["kind"]):
				lights += 1
		assert_true(lights <= 2, "lights %d" % lights)


func test_layout_placed_decor_always_appears() -> void:
	var layout := _layout({Vector2i(4, 3): "g", Vector2i(6, 3): "n", Vector2i(8, 3): "t", Vector2i(10, 7): "u", Vector2i(12, 7): "k", Vector2i(14, 7): "w"})
	var palette := RoomPalette.new()
	palette.decor_density = 0.0
	var kinds := {}
	for item in RoomDecor.plan(layout, palette, 1):
		kinds[item["kind"]] = true
	for kind in [RoomDecor.GRASS, RoomDecor.BONES, RoomDecor.TORCH, RoomDecor.PUDDLE, RoomDecor.CRACK, RoomDecor.COBWEB]:
		assert_true(kinds.has(kind), kind)


func test_a_floor_palette_steers_the_scatter() -> void:
	var layout := _layout()
	var graveyard := RoomPalette.new()
	graveyard.decor_weights = {"grass": 5.0, "bones": 1.0}
	graveyard.decor_density = 0.3
	var kinds := {}
	for seed_value in 10:
		for item in RoomDecor.plan(layout, graveyard, seed_value):
			kinds[item["kind"]] = true
	assert_eq(kinds.keys().size(), 2, str(kinds.keys()))
	assert_true(kinds.has("grass") and kinds.has("bones"))


func test_a_larger_room_gets_more_scatter() -> void:
	var small := _layout()
	var big_rows := ["#".repeat(30)]
	for y in range(1, 16):
		big_rows.append("#" + ".".repeat(28) + "#")
	big_rows.append("#".repeat(30))
	var big := RoomLayout.new()
	big.rows = PackedStringArray(big_rows)
	var palette := RoomPalette.new()
	assert_true(RoomDecor.plan(big, palette, 3).size() > RoomDecor.plan(small, palette, 3).size())


func test_floor_color_is_more_than_a_checkerboard() -> void:
	var palette := RoomPalette.new()
	var colors := {}
	for y in 11:
		for x in 20:
			colors[palette.floor_color(Vector2i(x, y), 9)] = true
	assert_true(colors.size() > 20, "distinct floor colors: %d" % colors.size())
	assert_eq(palette.floor_color(Vector2i(3, 4), 9), palette.floor_color(Vector2i(3, 4), 9), "stable")


func test_floor_colors_follow_the_palette() -> void:
	var moss := RoomPalette.new()
	moss.floor_a = Color.GREEN
	moss.floor_b = Color.GREEN
	moss.floor_c = Color.GREEN
	moss.floor_jitter = 0.0
	assert_eq(moss.floor_color(Vector2i(2, 2), 4), Color.GREEN)


func test_different_rooms_get_different_decor_seeds() -> void:
	var def: FloorDef = load("res://data/floors/floor_1.tres")
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var map := FloorBuilder.build(rng, def)
	var seeds := {}
	for room in map.rooms:
		seeds[room.decor_seed] = true
	assert_eq(seeds.size(), map.rooms.size())


# --- lighting and readability ---

func test_no_cell_of_any_room_is_far_from_a_light() -> void:
	for cells in [Vector2i(14, 9), Vector2i(20, 11), Vector2i(30, 17)]:
		var lights: Array[Vector2i] = Lighting.torch_cells(cells) + Lighting.fill_cells(cells)
		for y in cells.y:
			for x in cells.x:
				var nearest := INF
				for light in lights:
					nearest = minf(nearest, Vector2(x - light.x, y - light.y).length())
				assert_true(nearest <= 7.0, "%s cell %d,%d is %.1f cells from a light" % [str(cells), x, y, nearest])


func test_placeholders_are_never_too_dark_to_see() -> void:
	for id in ["intern_reaper", "filing_clerk", "debt_ghost", "senior_adjuster", "regional_reaper"]:
		var def: EnemyDef = load("res://data/enemies/%s.tres" % id)
		assert_true(SpriteVisual.readable(def.color).v >= SpriteVisual.MIN_BRIGHTNESS - 0.001, id)
	assert_eq(SpriteVisual.readable(Color.WHITE), Color.WHITE, "bright colors are left alone")


# --- shipped layouts ---

func test_shipped_rooms_have_character() -> void:
	var counts := {"O": 0, "Q": 0, "V": 0, "Z": 0, "g": 0, "t": 0, "l": 0}
	var rooms_with_props := 0
	var layouts := RoomCatalog.load_valid("res://data/rooms/floor_1/")
	for layout in layouts:
		var has_prop := false
		for symbol in counts:
			var n := layout.cells_of(symbol).size()
			counts[symbol] += n
			if n > 0 and "OQVZ".contains(symbol):
				has_prop = true
		if has_prop:
			rooms_with_props += 1
	for symbol in counts:
		assert_true(counts[symbol] >= 8, "'%s' appears %d times" % [symbol, counts[symbol]])
	assert_true(rooms_with_props >= layouts.size() * 3 / 4, "rooms with props: %d of %d" % [rooms_with_props, layouts.size()])


func test_every_shipped_prop_keeps_its_distance_from_every_door() -> void:
	for layout in RoomCatalog.load_valid("res://data/rooms/floor_1/"):
		for symbol in ["O", "Q", "V", "Z"]:
			for cell in layout.cells_of(symbol):
				for side in RoomLayout.SIDES:
					var door := layout.door_cell(side)
					assert_true(absi(cell.x - door.x) > 1 or absi(cell.y - door.y) > 1, "%s '%s' at %s" % [layout.resource_path, symbol, str(cell)])
