extends TestCase

const SEEDS := 300
const DIR := "res://data/rooms/floor_1/"


func _def() -> FloorDef:
	return load("res://data/floors/floor_1.tres")


func _pool() -> Array[RoomLayout]:
	return RoomCatalog.load_valid(DIR)


func _build(seed_value: int, pool: Array[RoomLayout], def: FloorDef = null) -> FloorMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return FloorBuilder.build_from_pool(rng, def if def != null else _def(), pool)


func _in_tree(node: Node2D, at := Vector2.ZERO) -> Node2D:
	node.position = at
	node._ready()
	return node


func _vaults(map: FloorMap) -> Array[FloorRoom]:
	var found: Array[FloorRoom] = []
	for room in map.rooms:
		if room.room_type == RoomLayout.TYPE_VAULT:
			found.append(room)
	return found


# --- the data on the floor definition ---

func test_the_vault_count_and_stone_level_live_in_the_floor_def() -> void:
	var def := _def()
	assert_eq(def.vault_count, 1)
	assert_eq(def.vault_stone_level, 3)
	assert_eq(FloorDef.new().vault_count, 1)
	assert_eq(FloorDef.new().vault_stone_level, 3)


# --- vault layouts ---

func test_vault_layouts_are_valid_rich_and_cover_every_size() -> void:
	var sizes := {}
	var found := 0
	for layout in _pool():
		if layout.room_type != RoomLayout.TYPE_VAULT:
			continue
		found += 1
		sizes[layout.size_class()] = true
		assert_eq(layout.validate().size(), 0)
		assert_true(layout.cells_of("I").size() >= 3, "a choice of items")
		assert_true(layout.cells_of("T").size() >= 3, "treasures to take")
		assert_eq(layout.cells_of("E").size(), 0, "a vault holds no fight")
		assert_eq(layout.cells_of("B").size(), 0)
	assert_eq(found, 3)
	assert_eq(sizes.size(), 3)


# Arriving on a door collects whatever lies on it, so a vault's open pickups stay clear of all four.
func test_vault_extras_stay_off_doors_rewards_and_each_other() -> void:
	var checked := 0
	for layout in _pool():
		if layout.room_type != RoomLayout.TYPE_VAULT:
			continue
		var cells := layout.vault_extra_cells(3)
		assert_eq(cells.size(), 3, layout.resource_path)
		for i in cells.size():
			assert_eq(layout.symbol_at(cells[i]), RoomLayout.SYMBOL_FLOOR, "%s %s" % [layout.resource_path, cells[i]])
			for side in RoomLayout.SIDES:
				var offset := cells[i] - layout.door_cell(side)
				assert_true(maxi(absi(offset.x), absi(offset.y)) > 1, "%s: %s touches a door" % [layout.resource_path, cells[i]])
			for j in i:
				var apart := cells[i] - cells[j]
				assert_true(maxi(absi(apart.x), absi(apart.y)) >= RoomLayout.PICKUP_SPACING, "%s: labels would overlap" % layout.resource_path)
		checked += 1
	assert_eq(checked, 3)


func test_a_vault_with_no_room_for_its_extras_fails_validation() -> void:
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_VAULT
	# Every cell away from the doors is taken, so nothing can be laid out in the open.
	layout.rows = PackedStringArray([
		"##########",
		"#IIIT.TIT#",
		"#IIIT.TIT#",
		"#IIIT.TIT#",
		"#........#",
		"#ITIT.TIT#",
		"#ITIT.TIT#",
		"##########",
	])
	assert_true(layout.vault_extra_cells(3).size() < 3)
	var told := false
	for error in layout.validate():
		told = told or error.contains("open pickups")
	assert_true(told, "validation names the missing room")


func test_a_vault_layout_without_its_rewards_fails() -> void:
	var rows := ["####################"]
	for y in range(1, 10):
		rows.append("#..................#")
	rows.append("####################")
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_VAULT
	layout.rows = PackedStringArray(rows)
	assert_true(layout.validate().size() > 0)


# --- vaults on a floor ---

func test_every_floor_hangs_one_vault_off_a_combat_room() -> void:
	var pool := _pool()
	var with_one := 0
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		var vaults := _vaults(map)
		assert_true(vaults.size() <= _def().vault_count, "seed %d" % seed_value)
		with_one += vaults.size()
		for vault in vaults:
			assert_true(vault.is_detour())
			assert_true(vault.needs_a_bomb())
			assert_eq(vault.doors.size(), 1, "a dead end, seed %d" % seed_value)
			var parent := map.room(vault.doors.values()[0])
			assert_eq(parent.room_type, RoomLayout.TYPE_COMBAT, "seed %d" % seed_value)
			assert_true(parent.id != map.boss_id)
	assert_true(with_one > 250, "most floors have one, had %d" % with_one)


func test_the_vault_count_comes_from_the_floor_def() -> void:
	var pool := _pool()
	var none := _def().duplicate() as FloorDef
	none.vault_count = 0
	var two := _def().duplicate() as FloorDef
	two.vault_count = 2
	var most := 0
	for seed_value in 100:
		assert_eq(_vaults(_build(seed_value, pool, none)).size(), 0)
		most = maxi(most, _vaults(_build(seed_value, pool, two)).size())
	assert_eq(most, 2)


func test_a_floor_with_no_vault_layouts_simply_has_none() -> void:
	var pool: Array[RoomLayout] = []
	for layout in _pool():
		if layout.room_type != RoomLayout.TYPE_VAULT:
			pool.append(layout)
	for seed_value in 30:
		var map := _build(seed_value, pool)
		assert_true(map != null)
		assert_eq(_vaults(map).size(), 0)


func test_nothing_the_floor_needs_sits_behind_a_vault_or_a_secret_wall() -> void:
	var pool := _pool()
	for seed_value in SEEDS:
		var map := _build(seed_value, pool)
		var reached := map.reached_without_bomb()
		assert_true(map.only_hidden_rooms_need_a_bomb(), "seed %d" % seed_value)
		assert_true(map.hidden_rooms_are_dead_ends(), "seed %d" % seed_value)
		# The whole main path, the bosses, every reward and the shop are walkable with no bomb.
		for id in map.main_path:
			assert_true(reached.has(id), "seed %d main path room %d" % [seed_value, id])
		for room in map.rooms:
			if room.needs_a_bomb():
				assert_false(map.main_path.has(room.id), "seed %d" % seed_value)
				assert_false(reached.has(room.id), "seed %d room %d" % [seed_value, room.id])
				assert_true(room.room_type in [RoomLayout.TYPE_VAULT, RoomLayout.TYPE_SECRET])
			else:
				assert_true(reached.has(room.id), "seed %d room %d (%s)" % [seed_value, room.id, room.room_type])


func test_blocking_every_vault_leaves_the_floor_winnable() -> void:
	var pool := _pool()
	for seed_value in 100:
		var map := _build(seed_value, pool)
		var vault_ids: Array[int] = []
		for vault in _vaults(map):
			vault_ids.append(vault.id)
		var reached := map.walk_from(map.start_id, vault_ids)
		assert_true(reached.has(map.boss_id), "seed %d: the floor boss" % seed_value)
		assert_true(reached.has(map.main_path[map.main_path.size() / 2]), "seed %d: the mini boss" % seed_value)
		for room in map.rooms:
			if room.room_type in [RoomLayout.TYPE_ITEM, RoomLayout.TYPE_HEALING, RoomLayout.TYPE_SHOP, RoomLayout.TYPE_TREASURE]:
				assert_true(reached.has(room.id), "seed %d: %s" % [seed_value, room.room_type])


func test_the_check_catches_a_required_room_behind_a_vault() -> void:
	var map := FloorMap.new()
	var types := [RoomLayout.TYPE_COMBAT, RoomLayout.TYPE_VAULT, RoomLayout.TYPE_ITEM]
	for i in 3:
		var room := FloorRoom.new()
		room.id = i
		room.room_type = types[i]
		room.cell = Vector2i(i, 0)
		map.rooms.append(room)
	map.join(map.room(0), map.room(1))
	map.join(map.room(1), map.room(2))
	assert_false(map.only_hidden_rooms_need_a_bomb(), "an item room past a vault must be refused")
	assert_false(map.hidden_rooms_are_dead_ends(), "and so must a vault with two doors")


func test_the_check_accepts_a_plain_dead_end_vault() -> void:
	var map := FloorMap.new()
	var types := [RoomLayout.TYPE_COMBAT, RoomLayout.TYPE_VAULT]
	for i in 2:
		var room := FloorRoom.new()
		room.id = i
		room.room_type = types[i]
		room.cell = Vector2i(i, 0)
		map.rooms.append(room)
	map.join(map.room(0), map.room(1))
	assert_true(map.only_hidden_rooms_need_a_bomb())
	assert_true(map.hidden_rooms_are_dead_ends())


# --- the stone ---

func test_the_stone_sits_in_the_wall_cell_every_door_side_offers() -> void:
	var checked := 0
	for layout in _pool():
		if layout.room_type != RoomLayout.TYPE_COMBAT:
			continue
		for side in RoomLayout.SIDES:
			var wall := layout.wall_cell(side)
			assert_eq(layout.rows[wall.y][wall.x], "#", "a plain wall for the stone on every side")
			assert_eq(layout.wall_cell(side) - side, layout.door_cell(side))
			checked += 1
	assert_true(checked > 40)


func test_nothing_but_a_strong_enough_thermos_breaks_the_stone() -> void:
	var stone := ReinforcedRock.new()
	for source in [BreakableBlock.SOURCE_BLAST, BreakableBlock.SOURCE_BOSS, BreakableBlock.SOURCE_CANE]:
		assert_false(stone.can_break_by(source), source)
	assert_true(stone.is_solid())
	stone.free()


func test_an_ordinary_blast_or_a_boss_leaves_the_stone_standing() -> void:
	var stone := _in_tree(ReinforcedRock.new(), Vector2(6000, 6000)) as ReinforcedRock
	assert_eq(BreakableBlock.smash_among([stone], Vector2(6000, 6000), 60.0, BreakableBlock.SOURCE_BLAST), 1)
	assert_false(stone.is_queued_for_deletion(), "an Auditor's blast or a plain Thermos does nothing")
	assert_eq(BreakableBlock.smash_among([stone], Vector2(6000, 6000), 60.0, BreakableBlock.SOURCE_BOSS), 0)
	assert_false(stone.is_queued_for_deletion(), "bosses cannot break it")
	assert_eq(BreakableBlock.smash_among([stone], Vector2(6000, 6000), 60.0, BreakableBlock.SOURCE_CANE), 0)
	assert_false(stone.is_queued_for_deletion())
	stone.free()


func test_a_thermos_below_the_needed_level_only_makes_the_stone_resist() -> void:
	for level in [0, 1, 2]:
		var stone := _in_tree(ReinforcedRock.new(), Vector2(7000, 7000)) as ReinforcedRock
		var resisted := [0]
		stone.resisted.connect(func(): resisted[0] += 1)
		assert_eq(ReinforcedRock.blast_among([stone], Vector2(7000, 7000), 56.0, level), 0, "level %d" % level)
		assert_false(stone.is_queued_for_deletion())
		assert_eq(resisted[0], 1, "it says so, level %d" % level)
		stone.free()


func test_a_max_level_thermos_breaks_the_stone_once() -> void:
	var stone := _in_tree(ReinforcedRock.new(), Vector2(8000, 8000)) as ReinforcedRock
	var broken := [0]
	stone.broken.connect(func(_at: Vector2): broken[0] += 1)
	assert_eq(ReinforcedRock.blast_among([stone], Vector2(8000, 8000), 56.0, 3), 1)
	assert_true(stone.is_queued_for_deletion())
	assert_eq(ReinforcedRock.blast_among([stone], Vector2(8000, 8000), 56.0, 3), 0, "already going")
	assert_eq(broken[0], 1)
	stone.free()


func test_the_floor_decides_which_level_breaks_its_stones() -> void:
	var stone := _in_tree(ReinforcedRock.new(), Vector2(9000, 9000)) as ReinforcedRock
	stone.needed_level = 1
	assert_eq(ReinforcedRock.blast_among([stone], Vector2(9000, 9000), 56.0, 1), 1)
	stone.free()


func test_a_blast_out_of_reach_does_nothing_to_the_stone() -> void:
	var stone := _in_tree(ReinforcedRock.new(), Vector2(9500, 9500)) as ReinforcedRock
	var resisted := [0]
	stone.resisted.connect(func(): resisted[0] += 1)
	assert_eq(ReinforcedRock.blast_among([stone], Vector2(9500, 9500) + Vector2(200, 0), 56.0, 3), 0)
	assert_false(stone.is_queued_for_deletion())
	assert_eq(resisted[0], 0)
	stone.free()


func test_other_props_ignore_the_stone_rules_and_the_stone_ignores_them() -> void:
	var rock := _in_tree(RockBlock.new(), Vector2(9800, 9800)) as RockBlock
	assert_eq(ReinforcedRock.blast_among([rock], Vector2(9800, 9800), 56.0, 3), 0, "a plain rock is not a stone")
	assert_false(rock.is_queued_for_deletion())
	rock.free()


func test_the_stone_looks_nothing_like_a_rock() -> void:
	var stone := ReinforcedRock.new()
	var rock := RockBlock.new()
	assert_true(stone.art_id() != rock.art_id())
	assert_true(stone.debris_color() != rock.debris_color())
	var palette := RoomPalette.new()
	assert_true(palette.reinforced != palette.rock)
	assert_true(palette.reinforced.b > palette.reinforced.r, "cold steel blue")
	stone.free()
	rock.free()


# --- the bomb merchant's upgrade ---

func _fuel() -> UpgradeDef:
	for upgrade in Content.upgrades_for("bomb_merchant"):
		if upgrade.id == "thermos_fuel":
			return upgrade
	return null


func test_the_bomb_merchant_sells_three_levels_of_thermos_damage() -> void:
	var fuel := _fuel()
	assert_true(fuel != null)
	assert_eq(fuel.max_level(), 3)
	assert_eq(fuel.merchant, "bomb_merchant")
	assert_true(fuel.thermos_damage_bonus > 0.0)
	assert_eq(Content.upgrades_for("bomb_merchant").size(), 1)


func test_thermos_fuel_costs_less_than_the_cane_upgrade() -> void:
	# A Thermos is a limited tool and the cane is used all run, so its damage is the cheaper line.
	var fuel := _fuel()
	var cane_total := 0
	for upgrade in Content.upgrades_for("black_market"):
		if upgrade.id == "reinforced_cane":
			for level in upgrade.max_level():
				cane_total += upgrade.price_at(level)
	var fuel_total := 0
	for level in fuel.max_level():
		fuel_total += fuel.price_at(level)
	assert_true(fuel_total < cane_total, "%d against %d" % [fuel_total, cane_total])
	assert_eq(fuel_total, 380)


func test_stats_follow_the_thermos_levels() -> void:
	var fuel := _fuel()
	var upgrades: Array[UpgradeDef] = [fuel]
	var items: Array[ItemDef] = []
	var expected := [1.0, 1.3, 1.6, 1.9]
	for level in 4:
		var stats := PlayerStats.compute(upgrades, {fuel.id: level}, items)
		assert_near(stats.thermos_damage_mult, expected[level], "level %d" % level)
		assert_eq(stats.thermos_level, level)
		assert_eq(stats.thermos_maxed, level == 3, "only the last level is max")
		assert_near(stats.damage_mult, 1.0, "the cane is untouched")


func test_no_fuel_means_a_plain_thermos() -> void:
	var upgrades: Array[UpgradeDef] = []
	var items: Array[ItemDef] = []
	var stats := PlayerStats.compute(upgrades, {}, items)
	assert_near(stats.thermos_damage_mult, 1.0)
	assert_eq(stats.thermos_level, 0)
	assert_false(stats.thermos_maxed)


func test_a_stronger_thermos_hits_enemies_harder_but_not_grandpa_harder() -> void:
	var plain := Thermos.new()
	assert_near(plain.blast_damage(), Thermos.DAMAGE)
	var strong := Thermos.new()
	strong.damage_mult = 1.9
	assert_near(strong.blast_damage(), Thermos.DAMAGE * 1.9)
	assert_eq(Thermos.PLAYER_DAMAGE, 1, "the blast costs Grandpa 1 pill however strong it is")
	plain.free()
	strong.free()


func test_the_blast_shows_each_level() -> void:
	var colors := {}
	for level in 4:
		colors[Thermos.blast_color(level)] = true
	assert_eq(colors.size(), 4, "a different color for every level")
	assert_eq(Thermos.blast_color(-3), Thermos.blast_color(0))
	assert_eq(Thermos.blast_color(9), Thermos.blast_color(3))


func test_every_upgrade_total_is_known() -> void:
	# 2055 before this stage. The Thermos fuel adds 380, and nothing else may change quietly.
	var total := 0
	for upgrade in Content.upgrades():
		for level in upgrade.max_level():
			total += upgrade.price_at(level)
	assert_eq(total, 2055 + 380)
