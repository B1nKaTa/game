extends TestCase

# The checkpoint file, a RunState through it, and that a floor rebuilds the same from its seed.


func _path() -> String:
	return OS.get_temp_dir().path_join("grandpa_test_run.json")


func _clean() -> void:
	for path in [_path(), _path() + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _write_text(text: String) -> void:
	var file := FileAccess.open(_path(), FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_the_file_round_trips() -> void:
	_clean()
	assert_true(RunCheckpoint.write(_path(), {"depth": 3, "path": "golden_years_mall"}))
	var read := RunCheckpoint.read(_path())
	assert_eq(int(read["depth"]), 3)
	assert_eq(read["path"], "golden_years_mall")
	assert_eq(int(read["version"]), RunCheckpoint.VERSION)
	assert_false(FileAccess.file_exists(_path() + ".tmp"), "the temp file is renamed into place")
	_clean()


func test_a_missing_file_is_no_run() -> void:
	_clean()
	assert_true(RunCheckpoint.read(_path()).is_empty())


func test_a_damaged_file_is_no_run() -> void:
	_write_text("{\"version\": 1, \"depth\": ")
	assert_true(RunCheckpoint.read(_path()).is_empty())
	_write_text("[1, 2, 3]")
	assert_true(RunCheckpoint.read(_path()).is_empty())
	_clean()


func test_another_version_is_no_run() -> void:
	_write_text(JSON.stringify({"version": RunCheckpoint.VERSION + 1, "depth": 2}))
	assert_true(RunCheckpoint.read(_path()).is_empty())
	_write_text(JSON.stringify({"depth": 2}))
	assert_true(RunCheckpoint.read(_path()).is_empty(), "no version at all")
	_clean()


func test_a_leftover_temp_file_never_counts() -> void:
	_clean()
	var file := FileAccess.open(_path() + ".tmp", FileAccess.WRITE)
	file.store_string("{\"version\": 1, \"dep")
	file.close()
	assert_true(RunCheckpoint.read(_path()).is_empty(), "a kill mid-write leaves only the temp file")
	assert_true(RunCheckpoint.write(_path(), {"depth": 1}))
	assert_eq(int(RunCheckpoint.read(_path())["depth"]), 1)
	_clean()


func test_delete() -> void:
	RunCheckpoint.write(_path(), {"depth": 1})
	RunCheckpoint.delete(_path())
	assert_false(FileAccess.file_exists(_path()))


func _item(id: String) -> ItemDef:
	for item in Content.items():
		if item.id == id:
			return item
	return null


func _fresh_run() -> RunState:
	return RunState.new(Content.upgrades(), {}, {})


func test_a_run_round_trips() -> void:
	var run := _fresh_run()
	run.add_item(_item("bifocals"))
	run.add_item(_item("alert_bracelet"))
	run.keys = 4
	run.bombs = 7
	run.give_potion(Content.potion("swift_tea"))
	run.cursed = true
	run.health.hit(1)
	run.promise(_item("dentures"))
	run.offer_recipe("bifocals")
	run.perks = {"some_perk": true}
	var raw := RunCheckpoint.run_to_dict(run)
	# Through the file's JSON, as a real resume reads it.
	raw = JSON.parse_string(JSON.stringify(raw))
	var back := _fresh_run()
	RunCheckpoint.apply_run(back, raw, Content.items())
	assert_eq(RunCheckpoint.run_to_dict(back), RunCheckpoint.run_to_dict(run))
	assert_eq(back.items.size(), 2)
	assert_eq(back.items[0].id, "bifocals", "items keep their order")
	assert_eq(back.items[1].id, "alert_bracelet")
	assert_eq(back.health.pills, run.health.pills)
	assert_eq(back.health.max_pills, run.health.max_pills)
	assert_eq(back.keys, 4)
	assert_eq(back.bombs, 7)
	assert_eq(back.potion.id, "swift_tea")
	assert_true(back.cursed)
	assert_true(back.is_promised("dentures"))
	assert_true(back.was_recipe_offered("bifocals"))
	assert_true(back.has_perk("some_perk"))
	assert_eq(back.stats.max_pills, run.stats.max_pills, "stats are worked out from the items again")


func test_a_resumed_run_gets_its_items_effects_and_combos_back() -> void:
	var run := _fresh_run()
	run.effects.set_combos(Content.combos())
	run.add_item(_item("bingo_card"))
	run.add_item(_item("bingo_dabber"))
	var raw: Dictionary = JSON.parse_string(JSON.stringify(RunCheckpoint.run_to_dict(run)))
	var back := _fresh_run()
	back.effects.set_combos(Content.combos())
	RunCheckpoint.apply_run(back, raw, Content.items())
	assert_true(back.effects.effect_of("bingo_card") != null, "the item's effect is held again")
	assert_true(back.effects.has_combo("bingo_night"), "the combo forms again")
	assert_eq(back.items.size(), 2)


func test_the_ending_tracking_round_trips_through_the_checkpoint() -> void:
	var run := _fresh_run()
	run.play_time = 812.34
	run.pension_earned = 1460
	run.boss_room_pill_lost = true
	run.paths_taken = {1: "cemetery", 2: "furnace_works"}
	run.extra_table_visits = 1
	run.note_arcade_win(3)
	run.note_arcade_win(3)
	run.note_arcade_win(7)
	var raw: Dictionary = JSON.parse_string(JSON.stringify(RunCheckpoint.ending_to_dict(run)))
	var back := _fresh_run()
	RunCheckpoint.apply_ending(back, raw)
	assert_true(absf(back.play_time - 812.3) < 0.01, str(back.play_time))
	assert_eq(back.pension_earned, 1460)
	assert_true(back.boss_room_pill_lost)
	assert_eq(back.paths_taken, {1: "cemetery", 2: "furnace_works"})
	assert_eq(back.arcade_visits_won(), 3)
	# A visit won after the resume adds to them, whatever its number.
	back.note_arcade_win(1)
	assert_eq(back.arcade_visits_won(), 4)
	var snap := back.ending_snapshot()
	assert_eq(snap["pension_earned"], 1460)
	assert_eq(snap["paths"], {1: "cemetery", 2: "furnace_works"})


func test_a_checkpoint_without_ending_tracking_starts_it_empty() -> void:
	var back := _fresh_run()
	RunCheckpoint.apply_ending(back, {"paths": "garbage", "play_time": -5})
	assert_eq(back.play_time, 0.0)
	assert_eq(back.paths_taken, {})
	assert_eq(back.arcade_visits_won(), 0)


func test_a_run_with_an_unknown_item_skips_it() -> void:
	var run := _fresh_run()
	RunCheckpoint.apply_run(run, {"items": ["no_such_item"], "pills": 3, "max_pills": 4, "potion": "nope"}, Content.items())
	assert_eq(run.items.size(), 0)
	assert_true(run.potion == null)
	assert_eq(run.health.pills, 3)


func test_the_rng_state_round_trips() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	rng.randi()
	var raw: Dictionary = JSON.parse_string(JSON.stringify(RunCheckpoint.rng_to_dict(rng)))
	var expected := rng.randi()
	var back := RandomNumberGenerator.new()
	RunCheckpoint.apply_rng(back, raw)
	assert_eq(back.randi(), expected, "big numbers survive JSON as text")


func test_every_path_rebuilds_the_same_map_from_its_seed() -> void:
	var defs: Array[FloorDef] = []
	for path in ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "golden_years_mall", "last_resort_cruise", "fairways_end", "terminal_zero", "head_office"]:
		defs.append(load("res://data/floors/%s.tres" % path))
	var seeds := RandomNumberGenerator.new()
	seeds.seed = 77
	for def in defs:
		var pool := FloorBuilder.pool_for(def)
		for i in 100:
			var seed_text := RunCheckpoint.new_seed(seeds)
			var first := RunCheckpoint.build_floor(def, seed_text, pool)
			var again := RunCheckpoint.build_floor(def, seed_text, pool)
			assert_true(first != null, "%s builds from seed %s" % [def.id, seed_text])
			if first == null or again == null:
				continue
			var a := RunCheckpoint.map_signature(first)
			var b := RunCheckpoint.map_signature(again)
			if a != b:
				assert_eq(b, a, "%s seed %s rebuilds the same" % [def.id, seed_text])
				break


func test_different_seeds_make_different_floors() -> void:
	var def: FloorDef = load("res://data/floors/floor_1.tres")
	var pool := FloorBuilder.pool_for(def)
	var a := RunCheckpoint.map_signature(RunCheckpoint.build_floor(def, "1", pool))
	var b := RunCheckpoint.map_signature(RunCheckpoint.build_floor(def, "2", pool))
	assert_true(a != b, "the signature can tell floors apart")
