extends TestCase

# The deep floors' poster rewards: the Life Jacket, the Neck Pillow, the Lucky Tee and the Golden
# Parachute.


func _item(id: String) -> ItemDef:
	for item in Content.items():
		if item.id == id:
			return item
	return null


func _run() -> RunState:
	var empty: Array[UpgradeDef] = []
	return RunState.new(empty, {})


func test_the_new_rewards_are_shipped_as_the_posters_need() -> void:
	assert_true(_item("life_jacket").from_bounty)
	assert_true(_item("neck_pillow").from_bounty)
	assert_true(_item("lucky_tee").needs_recipe())
	assert_true(_item("golden_parachute").needs_recipe())
	for id in ["life_jacket", "neck_pillow", "lucky_tee", "golden_parachute"]:
		assert_true(CoachTips.TIPS.has(id), "the coach has a tip for %s" % id)


func test_a_life_jacket_turns_a_lethal_hit_into_one_pill_once_per_floor() -> void:
	var run := _run()
	run.add_item(_item("life_jacket"))
	assert_eq(run.health.lethal_saves, 1)
	assert_true(run.health.hit(99))
	assert_eq(run.health.pills, 1)
	assert_false(run.health.is_dead())
	run.health.tick(Health.INVULN_TIME + 0.1)
	assert_true(run.health.hit(1))
	assert_true(run.health.is_dead(), "only once a floor")


func test_a_new_floor_fills_the_life_jacket_again() -> void:
	var run := _run()
	run.add_item(_item("life_jacket"))
	run.health.hit(99)
	assert_eq(run.health.lethal_saves, 0)
	run.start_floor()
	assert_eq(run.health.lethal_saves, 1)


func test_a_hit_that_leaves_pills_never_spends_the_life_jacket() -> void:
	var run := _run()
	run.add_item(_item("life_jacket"))
	run.health.hit(1)
	assert_eq(run.health.lethal_saves, 1)
	assert_eq(run.health.pills, PlayerStats.BASE_PILLS - 1)


func test_a_rescue_says_so() -> void:
	var health := Health.new(2)
	health.lethal_saves = 1
	var heard := {"rescued": 0, "died": 0}
	health.rescued.connect(func() -> void: heard["rescued"] += 1)
	health.died.connect(func() -> void: heard["died"] += 1)
	health.hit(5)
	assert_eq(heard, {"rescued": 1, "died": 0})


func test_without_a_life_jacket_a_lethal_hit_kills() -> void:
	var run := _run()
	assert_eq(run.health.lethal_saves, 0)
	run.health.hit(99)
	assert_true(run.health.is_dead())


# The Training Yard drops what was tried there, and a jacket tried there leaves nothing behind.
func test_dropping_the_jacket_drops_its_save() -> void:
	var run := _run()
	run.add_item(_item("life_jacket"))
	run.clear_items()
	assert_eq(run.health.lethal_saves, 0)


func test_the_neck_pillow_adds_a_pill() -> void:
	var run := _run()
	run.add_item(_item("neck_pillow"))
	assert_eq(run.health.max_pills, PlayerStats.BASE_PILLS + 1)


func test_a_lucky_roll_doubles_a_swing() -> void:
	assert_near(PlayerStats.lucky_damage(10.0, 0.1, 0.05), 20.0)
	assert_near(PlayerStats.lucky_damage(10.0, 0.1, 0.5), 10.0)
	assert_near(PlayerStats.lucky_damage(10.0, 0.0, 0.0), 10.0, "no tee, no luck")
	var run := _run()
	run.add_item(_item("lucky_tee"))
	assert_near(run.stats.lucky_swing_chance, 0.1)


func test_the_golden_parachute_pays_a_quarter_of_the_run_again_on_a_death() -> void:
	assert_eq(_run().parachute_pay(100), 0, "no parachute, no pay")
	var run := _run()
	run.add_item(_item("golden_parachute"))
	assert_near(run.stats.death_pension_bonus, 0.25)
	assert_eq(run.parachute_pay(100), 25)
	assert_eq(run.parachute_pay(10), 3, "rounded up")
	assert_eq(run.parachute_pay(0), 0)
	var source := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	var died := source.substr(source.find("func _on_player_died"), 400)
	assert_true(died.contains("_run.parachute_pay(_run.pension_earned)"))


func test_the_floor_scene_fills_the_jacket_on_each_floor_and_counts_what_the_run_earns() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	var choose := source.substr(source.find("func _choose_path"), 900)
	assert_true(choose.contains("_run.start_floor()"))
	assert_true(source.contains("view.pension_earned.connect(_on_pension_earned)"))
	assert_true(source.contains("_run.health.rescued.connect(_on_rescued)"))
