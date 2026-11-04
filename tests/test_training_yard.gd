extends TestCase


# Kept out of the tree, so _ready never runs, and tick is called by hand.
func _dummy() -> Enemy:
	var enemy := Enemy.new()
	enemy.setup(load("res://data/enemies/training_dummy.tres"), null, 0.5)
	return enemy


func test_the_dummy_never_dies() -> void:
	var enemy := _dummy()
	var died := [false]
	enemy.defeated.connect(func(_e: Enemy): died[0] = true)
	for i in 50:
		enemy.take_damage(999.0, Vector2.ZERO)
		DummyBehavior.new().tick(enemy, 0.016)
	assert_false(died[0])
	assert_near(enemy.hp, enemy.max_hp())
	enemy.free()


func test_the_dummy_pays_nothing() -> void:
	var def: EnemyDef = load("res://data/enemies/training_dummy.tres")
	assert_eq(def.pension_drop, 0)
	assert_false(def.is_boss)
	assert_true(def.wall_mounted, "nothing pushes it")


func test_a_hit_shows_its_damage() -> void:
	assert_eq(TrainingDummy.hit_amount(100000.0, 99982.0), 18)


func test_each_hit_shows_a_number_and_the_dummy_is_full_again() -> void:
	var enemy := _dummy()
	var numbers := TrainingDummy.new()
	numbers.watch(enemy)
	enemy.take_damage(18.0, Vector2.ZERO)
	enemy.take_damage(7.0, Vector2.ZERO)
	assert_eq(numbers.numbers_showing(), 2, "two hits in one frame show apart")
	assert_near(enemy.hp, enemy.max_hp())
	numbers.free()
	enemy.free()


func test_the_dummy_stands_on_open_yard_floor() -> void:
	var yard: RoomLayout = Departments.load_layouts()[Departments.TRAINING_YARD]
	assert_eq(yard.symbol_at(Departments.DUMMY_CELL), RoomLayout.SYMBOL_FLOOR)
	for side in RoomLayout.SIDES:
		assert_true(Vector2(Departments.DUMMY_CELL).distance_to(Vector2(yard.door_cell(side))) >= 3.0, str(side))


# Only the yard ever spawns an enemy in the Waiting Room, so its FloorDef stays enemy-free.
func test_the_waiting_room_floor_has_no_enemies() -> void:
	var def: FloorDef = load("res://data/floors/waiting_room.tres")
	assert_eq(def.enemies.size(), 0)


func _run() -> RunState:
	var empty: Array[UpgradeDef] = []
	return RunState.new(empty, {})


func test_the_rack_lists_every_found_recipe_crafted_or_not() -> void:
	var data := ProgressData.new()
	data.find_recipe("titanium_hip")
	data.find_recipe("bifocals")
	data.items_unlocked["titanium_hip"] = true
	var ids := ItemRackPanel.rack_items(data).map(func(i): return i.id)
	assert_eq(ids.size(), 2)
	assert_true(ids.has("titanium_hip") and ids.has("bifocals"))


func test_the_rack_never_lists_bounty_items() -> void:
	var data := ProgressData.new()
	data.items_unlocked["undertakers_gloves"] = true
	assert_eq(ItemRackPanel.rack_items(data).size(), 0)


func test_items_tried_in_the_yard_are_gone_on_leaving() -> void:
	var run := _run()
	var hip: ItemDef = load("res://data/items/titanium_hip.tres")
	run.add_item(hip)
	assert_true(run.stats.move_speed > PlayerStats.BASE_SPEED)
	run.clear_items()
	assert_eq(run.items.size(), 0)
	assert_near(run.stats.move_speed, PlayerStats.BASE_SPEED)


func test_items_raising_pills_give_them_back_on_leaving() -> void:
	var run := _run()
	run.add_item(load("res://data/items/alert_bracelet.tres"))
	run.clear_items()
	assert_eq(run.health.max_pills, PlayerStats.BASE_PILLS)
	assert_true(run.health.pills <= run.health.max_pills)


func test_the_yard_supply_is_the_most_a_pocket_holds() -> void:
	assert_eq(RunState.YARD_SUPPLY, RunState.MAX_CONSUMABLE)


func test_the_coach_has_a_tip_for_every_recipe() -> void:
	var none: Array[ItemDef] = []
	for item in Content.recipes():
		assert_true(CoachTips.TIPS.has(item.id), item.id)
	assert_eq(CoachTips.lines_for(none, true), CoachTips.FIRST_VISIT)
	var fallback: Array[String] = [CoachTips.DEFAULT_TIP]
	assert_eq(CoachTips.lines_for(none, false), fallback)


func test_the_coach_gives_one_tip_per_held_item_in_order() -> void:
	var held: Array[ItemDef] = [load("res://data/items/titanium_hip.tres"), load("res://data/items/bifocals.tres")]
	var expected: Array[String] = [CoachTips.TIPS["titanium_hip"], CoachTips.TIPS["bifocals"]]
	assert_eq(CoachTips.lines_for(held, false), expected)


func test_new_lines_start_again_at_the_first() -> void:
	var npc := Npc.new()
	var first: Array[String] = ["one", "two"]
	npc.setup(load("res://data/npcs/coach_bertram.tres"), null)
	npc.set_lines(first)
	assert_eq(npc.talk(), "one")
	var second: Array[String] = ["three"]
	npc.set_lines(second)
	assert_eq(npc.talk(), "three")
	npc.free()


# --- forms filed during the visit ---

func _form(id: String) -> UpgradeDef:
	for def in Content.upgrades():
		if def.id == id:
			return def
	return null


# The Waiting Room's run, made as Progress.make_run makes it, from the save's own dictionaries.
func _visit_run(data: ProgressData) -> RunState:
	return RunState.new(Content.upgrades(), data.upgrades, data.form_choices)


func test_a_form_filed_during_the_visit_counts_in_the_yard() -> void:
	var data := ProgressData.new()
	data.pension = 1000
	var run := _visit_run(data)
	run.add_item(load("res://data/items/titanium_hip.tres"))
	var pills_before := run.health.max_pills
	assert_true(data.buy(_form("black_market_pills")))
	run.refresh_stats()
	assert_eq(run.stats.max_pills, pills_before + 1, "the filed level adds its pill")
	assert_eq(run.health.max_pills, pills_before + 1)
	assert_eq(run.health.pills, run.health.max_pills, "the new pill is his to use at once")
	assert_true(run.has_item("titanium_hip"), "refreshing keeps the items tried in the yard")
	assert_true(run.stats.move_speed > PlayerStats.BASE_SPEED)


func test_a_form_refiled_during_the_visit_counts_in_the_yard() -> void:
	var data := ProgressData.new()
	data.pension = 1000
	var cane := _form("reinforced_cane")
	var run := _visit_run(data)
	assert_true(data.buy(cane))
	assert_true(data.buy(cane, UpgradeDef.OPTION_A))
	run.refresh_stats()
	var with_a := run.stats.damage_mult
	assert_near(with_a, PlayerStats.compute(Content.upgrades(), {"reinforced_cane": 2}, run.items, {"reinforced_cane": "a"}).damage_mult)
	assert_true(data.refile(cane))
	run.refresh_stats()
	assert_near(run.stats.damage_mult, PlayerStats.compute(Content.upgrades(), {"reinforced_cane": 2}, run.items, {"reinforced_cane": "b"}).damage_mult)
	assert_true(run.stats.damage_mult < with_a, "Lightweight trades cane damage for speed")


func test_refreshing_never_leaves_more_pills_than_the_maximum() -> void:
	var data := ProgressData.new()
	data.upgrades["black_market_pills"] = 1
	var run := _visit_run(data)
	assert_eq(run.health.max_pills, PlayerStats.BASE_PILLS + 1)
	data.upgrades.erase("black_market_pills")
	run.refresh_stats()
	assert_eq(run.health.max_pills, PlayerStats.BASE_PILLS)
	assert_true(run.health.pills <= run.health.max_pills)


# The scene refreshes the run on entering the yard and after every panel, which is where forms are filed.
func test_the_waiting_room_refreshes_stats_on_entering_the_yard_and_closing_a_panel() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/waiting_room.gd")
	var yard_rules := source.substr(source.find("func _set_yard_rules"), 400)
	assert_true(yard_rules.contains("_run.refresh_stats()"), "entering the yard")
	var close_panel := source.substr(source.find("func _close_panel"), 700)
	assert_true(close_panel.contains("\n\t_refresh_run_stats()"), "closing a panel calls it, not only declares it")
