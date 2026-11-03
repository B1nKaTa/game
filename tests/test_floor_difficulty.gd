extends TestCase


func _def(hp: float, pays: int) -> EnemyDef:
	var def := EnemyDef.new()
	def.max_hp = hp
	def.pension_drop = pays
	return def


func test_a_floor_scales_health_and_pay() -> void:
	var enemy := Enemy.new()
	enemy.def = _def(50.0, 2)
	enemy.apply_floor(1.4, 1.5)
	assert_near(enemy.max_hp(), 70.0)
	assert_near(enemy.hp, 70.0, "he starts at full scaled health")
	assert_eq(enemy.coin_value(), 3, "1.5 times 2 is 3")
	enemy.free()


func test_pay_rounds_up() -> void:
	var enemy := Enemy.new()
	enemy.def = _def(10.0, 1)
	enemy.apply_floor(1.0, 1.5)
	assert_eq(enemy.coin_value(), 2)
	enemy.free()


func test_a_plain_floor_changes_nothing() -> void:
	var enemy := Enemy.new()
	enemy.def = _def(30.0, 10)
	enemy.apply_floor(1.0, 1.0)
	assert_near(enemy.max_hp(), 30.0)
	assert_eq(enemy.coin_value(), 10, "a whole number times one is never rounded up")
	var unscaled := Enemy.new()
	unscaled.def = _def(30.0, 0)
	unscaled.apply_floor(1.4, 1.5)
	assert_eq(unscaled.coin_value(), 0, "nothing scaled is still nothing")
	enemy.free()
	unscaled.free()


func test_summons_still_pay_nothing_on_a_deeper_floor() -> void:
	var enemy := Enemy.new()
	enemy.def = _def(10.0, 2)
	enemy.is_summon = true
	enemy.apply_floor(1.4, 1.5)
	assert_eq(enemy.coin_value(), 0)
	enemy.free()


func test_first_floors_keep_their_room_sizes() -> void:
	var def := FloorDef.new()
	assert_eq(def.enemies_by_size, {"small": 4, "medium": 6, "large": 11})
	assert_near(def.health_mult, 1.0)
	assert_near(def.pension_mult, 1.0)


func test_room_sizes_are_checked_against_the_floor() -> void:
	var cemetery: FloorDef = load("res://data/floors/cemetery.tres")
	for layout in RoomCatalog.load_valid(cemetery.rooms_dir):
		assert_eq(cemetery.room_size_errors(layout).size(), 0, layout.resource_path)
	var deeper := FloorDef.new()
	deeper.enemies_by_size = {"small": 5, "medium": 7, "large": 12}
	var failed := 0
	for layout in RoomCatalog.load_valid(cemetery.rooms_dir):
		if layout.room_type == RoomLayout.TYPE_COMBAT:
			failed += 1 if deeper.room_size_errors(layout).size() > 0 else 0
	assert_true(failed > 0, "a floor asking for one more enemy a room refuses first-floor rooms")


func test_room_sizes_fall_back_to_the_first_floor() -> void:
	assert_eq(RoomLayout.ENEMIES_BY_SIZE, {"small": 4, "medium": 6, "large": 11})


func test_an_attack_can_cost_two_pills() -> void:
	var enemy := Enemy.new()
	enemy.def = _def(10.0, 1)
	assert_eq(enemy.attack_damage(), enemy.def.damage, "an attack costs the enemy's damage unless it says otherwise")
	assert_eq(enemy.attack_damage(2), 2)
	var strike := GroundStrike.new()
	strike.setup(enemy, 20.0, 0.5, 0.0, 0.0, Enemy.HEAVY_DAMAGE)
	var health := Health.new(5)
	health.hit(enemy.attack_damage(strike.damage()))
	assert_eq(health.pills, 3, "a heavy ground strike takes two pills")
	var plain := GroundStrike.new()
	plain.setup(enemy, 20.0, 0.5)
	var other := Health.new(5)
	other.hit(enemy.attack_damage(plain.damage()))
	assert_eq(other.pills, 4)
	strike.free()
	plain.free()
	enemy.free()
