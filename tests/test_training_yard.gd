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
