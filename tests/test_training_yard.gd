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
