extends TestCase


func _run() -> RunState:
	var empty: Array[UpgradeDef] = []
	return RunState.new(empty, {})


func _data(paths: Array = []) -> ProgressData:
	var data := ProgressData.new()
	for id in paths:
		data.paths_cleared[id] = true
	return data


func test_the_bag_is_packed_only_while_the_pursers_office_is_open() -> void:
	assert_false(BonVoyage.is_packed(_data()))
	assert_false(BonVoyage.is_packed(_data(["floor_1", "sunset_shores", "funeral_parlour"])))
	assert_true(BonVoyage.is_packed(_data(["last_resort_cruise"])))


func test_a_low_roll_packs_a_potion_into_the_empty_slot() -> void:
	var run := _run()
	var potions := Content.potions_for_sale()
	var given := BonVoyage.pack(run, potions, 0.0, 0.0)
	assert_eq(given, potions[0].id)
	assert_true(run.potion != null and run.potion.id == given)
	assert_eq(run.bombs, RunState.STARTING_BOMBS, "one thing only")


func test_a_high_roll_packs_a_thermos() -> void:
	var run := _run()
	assert_eq(BonVoyage.pack(run, Content.potions_for_sale(), 0.99, 0.0), BonVoyage.THERMOS)
	assert_eq(run.bombs, RunState.STARTING_BOMBS + 1)
	assert_true(run.potion == null)


# A brew keeps its slot, and the bag holds a Thermos instead.
func test_a_full_slot_gets_a_thermos_instead() -> void:
	var run := _run()
	run.give_potion(Content.potion("swift_tea"))
	assert_eq(BonVoyage.pack(run, Content.potions_for_sale(), 0.0, 0.0), BonVoyage.THERMOS)
	assert_eq(run.potion.id, "swift_tea")
	assert_eq(run.bombs, RunState.STARTING_BOMBS + 1)


func test_every_potion_roll_picks_a_potion_for_sale() -> void:
	var potions := Content.potions_for_sale()
	for i in 20:
		var run := _run()
		var given := BonVoyage.pack(run, potions, 0.1, i / 20.0)
		assert_true(potions.any(func(def: PotionDef) -> bool: return def.id == given), given)


func test_the_notice_names_what_was_packed() -> void:
	var potions := Content.potions_for_sale()
	assert_eq(BonVoyage.notice(BonVoyage.THERMOS, potions), "Bon Voyage Bag: a Thermos")
	assert_eq(BonVoyage.notice(potions[0].id, potions), "Bon Voyage Bag: %s" % potions[0].display_name)
	assert_eq(BonVoyage.notice("", potions), "")


# The floor scene packs the bag after the brew and before a dev run's kit.
func test_the_floor_scene_packs_the_bag_between_the_brew_and_the_dev_kit() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	var brew := source.find("Progress.take_brewed_potion()")
	var bag := source.find("BonVoyage.pack(")
	var kit := source.find("DevStart.apply_kit(")
	assert_true(brew >= 0 and bag > brew and kit > bag, "%d %d %d" % [brew, bag, kit])
