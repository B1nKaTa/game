extends TestCase

const FLOOR_ONE := ["res://data/floors/floor_1.tres", "res://data/floors/cemetery.tres"]
const FLOOR_TWO := ["res://data/floors/sunset_shores.tres", "res://data/floors/furnace_works.tres"]
const RARE := [ChestRules.SAFE, ChestRules.URN, ChestRules.MIMIC]


func _share(odds: Dictionary, kinds: Array) -> float:
	var total := 0.0
	var part := 0.0
	for kind in ChestRules.KINDS:
		total += float(odds[kind])
		if kinds.has(kind):
			part += float(odds[kind])
	return part / total


func _counts(odds: Dictionary, rolls: int, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var counts := {}
	for kind in ChestRules.KINDS:
		counts[kind] = 0
	for i in rolls:
		var rolled := ChestRules.roll(odds, rng.randf())
		counts[rolled] += 1
	return counts


func _chest(kind: String) -> Chest:
	var chest := Chest.new()
	chest.kind = kind
	chest.setup(ChestRules.display_name(kind), Color.WHITE, null, kind != ChestRules.SAFE)
	return chest


# --- the odds, floor by floor ---

func test_every_floor_names_odds_for_every_kind() -> void:
	for path: String in FLOOR_ONE + FLOOR_TWO:
		var def: FloorDef = load(path)
		var odds := def.chest_odds()
		for kind in ChestRules.KINDS:
			assert_true(odds.has(kind), "%s has odds for %s" % [path, kind])
		assert_true(float(odds[ChestRules.LUNCHBOX]) > float(odds[ChestRules.URN]), "%s: lunchboxes are the common kind" % path)


func test_first_floors_never_roll_a_mimic() -> void:
	for path: String in FLOOR_ONE:
		var def: FloorDef = load(path)
		assert_near(float(def.chest_odds()[ChestRules.MIMIC]), 0.0, path)
		var counts := _counts(def.chest_odds(), 3000, 11)
		assert_eq(counts[ChestRules.MIMIC], 0, path)


func test_second_floors_roll_mimics_and_more_rare_chests() -> void:
	var first: FloorDef = load(FLOOR_ONE[0])
	for path: String in FLOOR_TWO:
		var def: FloorDef = load(path)
		assert_true(float(def.chest_odds()[ChestRules.MIMIC]) > 0.0, path)
		assert_true(_share(def.chest_odds(), RARE) > _share(first.chest_odds(), RARE), "%s: rare kinds likelier deeper" % path)
		var counts := _counts(def.chest_odds(), 3000, 12)
		assert_true(counts[ChestRules.MIMIC] > 0, "%s rolled a mimic" % path)


func test_a_first_floor_ignores_mimic_weight_in_its_data() -> void:
	var odds := ChestRules.odds_for_depth({"lunchbox": 1, "mimic": 50}, 1)
	assert_near(float(odds[ChestRules.MIMIC]), 0.0)
	assert_near(float(odds[ChestRules.LUNCHBOX]), 1.0)
	assert_near(float(odds[ChestRules.URN]), 0.0, "a missing kind counts as none")
	var deeper := ChestRules.odds_for_depth({"lunchbox": 1, "mimic": 50}, 2)
	assert_near(float(deeper[ChestRules.MIMIC]), 50.0)


func test_a_roll_walks_the_kinds_in_order() -> void:
	var odds := {"lunchbox": 50, "locked": 30, "safe": 12, "urn": 8, "mimic": 0}
	assert_eq(ChestRules.roll(odds, 0.0), ChestRules.LUNCHBOX)
	assert_eq(ChestRules.roll(odds, 0.49), ChestRules.LUNCHBOX)
	assert_eq(ChestRules.roll(odds, 0.51), ChestRules.LOCKED)
	assert_eq(ChestRules.roll(odds, 0.81), ChestRules.SAFE)
	assert_eq(ChestRules.roll(odds, 0.93), ChestRules.URN)
	assert_eq(ChestRules.roll(odds, 0.9999), ChestRules.URN, "a kind with no weight is never picked")


func test_rolls_follow_the_weights() -> void:
	var odds := {"lunchbox": 40, "locked": 26, "safe": 16, "urn": 10, "mimic": 8}
	var counts := _counts(odds, 20000, 3)
	for kind in ChestRules.KINDS:
		var expected := float(odds[kind]) / 100.0
		var seen := float(counts[kind]) / 20000.0
		assert_true(absf(seen - expected) < 0.02, "%s rolled %f, wanted about %f" % [kind, seen, expected])


func test_empty_odds_give_the_old_locked_chest() -> void:
	assert_eq(ChestRules.roll({}, 0.3), ChestRules.LOCKED)
	assert_eq(ChestRules.roll({"lunchbox": 0, "mimic": -4}, 0.3), ChestRules.LOCKED)


# --- opening rules and costs ---

func test_what_each_kind_costs_to_open() -> void:
	assert_true(ChestRules.can_open(ChestRules.LUNCHBOX, 0), "a lunchbox is free")
	assert_false(ChestRules.can_open(ChestRules.LOCKED, 0))
	assert_true(ChestRules.can_open(ChestRules.LOCKED, 1))
	assert_false(ChestRules.can_open(ChestRules.URN, 1), "an urn wants two Slips")
	assert_true(ChestRules.can_open(ChestRules.URN, 2))
	assert_eq(ChestRules.slips_needed(ChestRules.LOCKED), 1)
	assert_eq(ChestRules.slips_needed(ChestRules.URN), 2)
	assert_eq(ChestRules.slips_needed(ChestRules.SAFE), 0)


func test_no_key_opens_a_safe_or_a_mimic() -> void:
	for slips in [0, 1, 2, 99]:
		assert_false(ChestRules.can_open(ChestRules.SAFE, slips), "safe with %d Slips" % slips)
		assert_false(ChestRules.can_open(ChestRules.MIMIC, slips), "mimic with %d Slips" % slips)
	assert_true(ChestRules.opens_by_blast(ChestRules.SAFE))
	for kind in [ChestRules.LUNCHBOX, ChestRules.LOCKED, ChestRules.URN, ChestRules.MIMIC]:
		assert_false(ChestRules.opens_by_blast(kind), kind)


func test_a_mimic_passes_for_a_locked_chest() -> void:
	assert_eq(ChestRules.display_name(ChestRules.MIMIC), ChestRules.display_name(ChestRules.LOCKED))
	assert_eq(ChestRules.prompt_for(ChestRules.MIMIC), ChestRules.prompt_for(ChestRules.LOCKED))
	var names := {}
	for kind in [ChestRules.LUNCHBOX, ChestRules.LOCKED, ChestRules.SAFE, ChestRules.URN]:
		names[ChestRules.display_name(kind)] = true
	assert_eq(names.size(), 4, "every honest kind has its own name")


# --- what they hold ---

func test_a_lunchbox_holds_a_little_pension_and_sometimes_more() -> void:
	assert_eq(ChestRules.lunchbox_pension(8), 2)
	assert_eq(ChestRules.lunchbox_pension(12), 3)
	assert_eq(ChestRules.lunchbox_pension(1), 1, "never empty")
	assert_eq(ChestRules.lunchbox_extra(0.1), RoomRules.DROP_POTION)
	assert_eq(ChestRules.lunchbox_extra(0.25), RoomRules.DROP_BOMB)
	assert_eq(ChestRules.lunchbox_extra(0.5), RoomRules.DROP_NONE)


func test_a_safe_holds_a_big_pile_over_several_coins() -> void:
	assert_eq(ChestRules.safe_pension(8), 16)
	assert_eq(ChestRules.safe_pension(12), 24)
	assert_true(ChestRules.safe_pension(8) > ChestRules.lunchbox_pension(8) * 4)
	var coins := ChestRules.coin_split(ChestRules.safe_pension(8), ChestRules.SAFE_COINS)
	assert_eq(coins.size(), ChestRules.SAFE_COINS)
	var total := 0
	for coin in coins:
		total += coin
	assert_eq(total, 16)


func test_coins_split_evenly_and_never_into_nothing() -> void:
	var ten: Array[int] = [3, 3, 2, 2]
	var three: Array[int] = [1, 1, 1]
	assert_eq(ChestRules.coin_split(10, 4), ten)
	assert_eq(ChestRules.coin_split(3, 4), three)
	assert_eq(ChestRules.coin_split(0, 4).size(), 0)
	assert_eq(ChestRules.coin_split(5, 0).size(), 0)


func test_an_urn_offers_two_items_or_pays_when_none_are_left() -> void:
	assert_eq(ChestRules.URN_CHOICES, 2)
	assert_eq(ChestRules.urn_fallback_pension(8), 16)


func test_the_mimic_pays_well_drops_a_slip_and_warns_first() -> void:
	var mimic: EnemyDef = load("res://data/enemies/mimic.tres")
	assert_eq(mimic.id, "mimic")
	assert_true(mimic.drops_key)
	assert_false(mimic.is_boss)
	var intern: EnemyDef = load("res://data/enemies/intern_reaper.tres")
	assert_true(mimic.pension_drop >= intern.pension_drop * 4, "pays well against a regular enemy")
	assert_true(MimicBehavior.WINDUP >= 0.5, "its lunge is warned long enough to react")
	assert_true(MimicBehavior.lane_length() > 0.0, "and shows a lane")
	assert_false(MimicBehavior.should_lunge(30.0, 0.2), "rests first")
	assert_false(MimicBehavior.should_lunge(MimicBehavior.START_RANGE + 1.0, 0.0), "out of reach")
	assert_true(MimicBehavior.should_lunge(30.0, 0.0))


func test_floors_that_roll_mimics_name_them_and_one_naming_none_rolls_none() -> void:
	for path: String in FLOOR_TWO:
		var def: FloorDef = load(path)
		assert_true(def.mimic != null and def.mimic.id == "mimic", path)
	var unnamed := FloorDef.new()
	unnamed.depth = 2
	unnamed.chest_weights = {"lunchbox": 1, "mimic": 50}
	assert_near(float(unnamed.chest_odds()[ChestRules.MIMIC]), 0.0)


func test_a_mimic_shows_its_whole_warning_even_standing_on_him() -> void:
	var target := Node2D.new()
	var mimic := Enemy.new()
	mimic.setup(load("res://data/enemies/mimic.tres"), target, 0.5)
	mimic._behavior.tick(mimic, MimicBehavior.FIRST_LUNGE + 0.01)
	assert_true(mimic._warning != null, "it starts a lunge right on top of him")
	assert_near(mimic._warning_share(), 1.0, "the whole windup, not his stats' share")
	assert_true(mimic._warning.shows_warning(mimic._warning_share()), "from its very first moment")
	mimic.free()
	target.free()


func test_no_regular_enemy_drops_a_slip() -> void:
	for path: String in FLOOR_ONE + FLOOR_TWO:
		var def: FloorDef = load(path)
		for enemy: EnemyDef in def.enemies:
			assert_false(enemy.drops_key, enemy.id)


# --- the chest itself ---

func test_a_safe_ignores_the_key_and_opens_to_a_blast() -> void:
	var safe := _chest(ChestRules.SAFE)
	var opened := [0]
	safe.blasted_open.connect(func(_at: Vector2): opened[0] += 1)
	var taken := [0]
	safe.collected.connect(func(): taken[0] += 1)
	safe.collect()
	assert_eq(taken[0], 0, "the interact key does nothing")
	assert_false(safe.is_queued_for_deletion())
	assert_eq(Chest.blast_among([safe], Vector2(500, 500), 56.0), 0, "a far blast misses")
	assert_eq(Chest.blast_among([safe], Vector2(30, 0), 56.0), 1)
	assert_eq(opened[0], 1)
	assert_false(safe.blast_open(), "opens once")
	safe.free()


func test_a_mimic_wakes_when_reached_for() -> void:
	var mimic := _chest(ChestRules.MIMIC)
	var woke := [0]
	mimic.woke.connect(func(_at: Vector2): woke[0] += 1)
	var taken := [0]
	mimic.collected.connect(func(): taken[0] += 1)
	mimic.collect()
	assert_eq(woke[0], 1)
	assert_eq(taken[0], 0, "it gives nothing away by being opened")
	assert_true(mimic.is_queued_for_deletion())
	assert_false(mimic.wake(), "wakes once")
	mimic.free()


func test_a_blast_wakes_a_mimic_but_leaves_honest_chests() -> void:
	var mimic := _chest(ChestRules.MIMIC)
	var locked := _chest(ChestRules.LOCKED)
	var lunch := _chest(ChestRules.LUNCHBOX)
	assert_eq(Chest.blast_among([mimic, locked, lunch], Vector2.ZERO, 56.0), 1)
	assert_true(mimic.is_open())
	assert_false(locked.is_queued_for_deletion())
	assert_false(lunch.is_queued_for_deletion())
	mimic.free()
	locked.free()
	lunch.free()


func test_a_locked_chest_waits_for_its_slip() -> void:
	var locked := _chest(ChestRules.LOCKED)
	var slips := [0]
	locked.can_take = func(): return ChestRules.can_open(ChestRules.LOCKED, slips[0])
	var taken := [0]
	locked.collected.connect(func(): taken[0] += 1)
	locked.collect()
	assert_eq(taken[0], 0, "no Slip, no opening")
	assert_false(locked.is_queued_for_deletion())
	slips[0] = 1
	locked.collect()
	assert_eq(taken[0], 1)
	locked.free()


func test_a_lunchbox_opens_for_free() -> void:
	var lunch := _chest(ChestRules.LUNCHBOX)
	var taken := [0]
	lunch.collected.connect(func(): taken[0] += 1)
	lunch.collect()
	assert_eq(taken[0], 1)
	lunch.free()


func test_shipped_rooms_still_hold_chest_cells() -> void:
	var chests := 0
	for dir in ["res://data/rooms/floor_1/", "res://data/rooms/cemetery/", "res://data/rooms/sunset_shores/", "res://data/rooms/furnace_works/", "res://data/rooms/funeral_parlour/", "res://data/rooms/golden_years_mall/", "res://data/rooms/head_office/"]:
		for layout in RoomCatalog.load_valid(dir):
			chests += layout.cells_of("C").size()
	# The Last Resort Cruise
	for layout in RoomCatalog.load_valid("res://data/rooms/last_resort_cruise/"):
		chests += layout.cells_of("C").size()
	assert_true(chests >= 12, "had %d chest cells" % chests)
