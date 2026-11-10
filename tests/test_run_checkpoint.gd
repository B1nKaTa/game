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
	assert_true(RunCheckpoint.write(_path(), {"depth": 3, "path": "flashback_cinema"}))
	var read := RunCheckpoint.read(_path())
	assert_eq(int(read["depth"]), 3)
	assert_eq(read["path"], "flashback_cinema")
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


# Coins picked up after the last checkpoint are banked at once, and the fight they came from comes back
# on resume, so resuming puts the Pension back as the checkpoint saw it. Condolences are left alone.
func test_a_resume_gives_the_checkpoints_pension() -> void:
	_clean()
	var data := ProgressData.new()
	data.pension = 100
	data.condolences = 3
	assert_true(RunCheckpoint.write(_path(), {"depth": 2, "pension": RunCheckpoint.pension_to_save(data, 0)}))
	data.add_pension(25)
	data.add_condolences(4)
	assert_true(RunCheckpoint.apply_pension(data, RunCheckpoint.read(_path())))
	assert_eq(data.pension, 100, "the coins of the fight that comes back are not kept twice")
	assert_eq(data.condolences, 7, "a boss's Condolences stay paid")
	_clean()


# Saved mid-fight, the run comes back in the last cleared room, so that fight's coins come off.
func test_a_checkpoint_mid_fight_leaves_out_that_fights_pension() -> void:
	var data := ProgressData.new()
	data.pension = 130
	assert_eq(RunCheckpoint.pension_to_save(data, 30), 100)
	assert_eq(RunCheckpoint.pension_to_save(data, 500), 0, "never below nothing")


func test_an_older_checkpoint_without_pension_leaves_it() -> void:
	var data := ProgressData.new()
	data.pension = 40
	assert_false(RunCheckpoint.apply_pension(data, {"depth": 2}))
	assert_eq(data.pension, 40)


func test_the_floor_scene_saves_and_restores_the_pension() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	var write := source.substr(source.find("func write_checkpoint"), 2000)
	assert_true(write.contains("\"pension\": RunCheckpoint.pension_to_save(Progress.data"), "written with the checkpoint")
	var resume := source.substr(source.find("func _resume_run"), 1200)
	assert_true(resume.contains("Progress.restore_pension(resume)"), "put back on resume")
	var progress := FileAccess.get_file_as_string("res://scripts/autoload/progress.gd")
	var restore := progress.substr(progress.find("func restore_pension"), 300)
	assert_true(restore.contains("RunCheckpoint.apply_pension(data, checkpoint)"))
	assert_true(restore.contains("_save_pension()"), "and saved")


func _item(id: String) -> ItemDef:
	for item in Content.all_items():
		if item.id == id:
			return item
	return null


func _fresh_run() -> RunState:
	return RunState.new(Content.upgrades(), {}, {})


func test_a_run_round_trips() -> void:
	var run := _fresh_run()
	run.add_item(_item("bifocals"))
	run.add_item(_item("hospital_bracelet"))
	run.keys = 4
	run.bombs = 7
	run.give_potion(Content.potion("swift_tea"))
	run.cursed = true
	run.health.hit(1)
	run.promise(_item("spare_set"))
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
	assert_eq(back.items[1].id, "hospital_bracelet")
	assert_eq(back.health.pills, run.health.pills)
	assert_eq(back.health.max_pills, run.health.max_pills)
	assert_eq(back.keys, 4)
	assert_eq(back.bombs, 7)
	assert_eq(back.potion.id, "swift_tea")
	assert_true(back.cursed)
	assert_true(back.is_promised("spare_set"))
	assert_true(back.was_recipe_offered("bifocals"))
	assert_true(back.has_perk("some_perk"))
	assert_eq(back.stats.max_pills, run.stats.max_pills, "stats are worked out from the items again")


func test_a_checkpoint_mid_flashback_saves_the_reel_being_lived() -> void:
	var run := _fresh_run()
	run.era = Eras.FOOTBALL
	assert_eq(RunCheckpoint.run_to_dict(run)["held_reel"], Eras.FOOTBALL)
	run.held_reel = Eras.BUS
	assert_eq(RunCheckpoint.run_to_dict(run)["held_reel"], Eras.BUS, "a held reel wins")
	var back := _fresh_run()
	RunCheckpoint.apply_run(back, JSON.parse_string(JSON.stringify(RunCheckpoint.run_to_dict(run))), Content.items())
	assert_eq(back.held_reel, Eras.BUS)


func test_a_resumed_run_gets_its_items_effects_and_combos_back() -> void:
	var combo := ComboDef.new()
	combo.id = "test_pair"
	combo.item_a = "casserole_dish"
	combo.item_b = "tea_cosy"
	var combos: Array[ComboDef] = [combo]
	var run := _fresh_run()
	run.effects.set_combos(combos)
	run.add_item(_item("casserole_dish"))
	run.add_item(_item("tea_cosy"))
	var raw: Dictionary = JSON.parse_string(JSON.stringify(RunCheckpoint.run_to_dict(run)))
	var back := _fresh_run()
	back.effects.set_combos(combos)
	RunCheckpoint.apply_run(back, raw, Content.items())
	assert_true(back.effects.effect_of("casserole_dish") != null, "the item's effect is held again")
	assert_true(back.effects.has_combo("test_pair"), "the combo forms again")
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
	for path in ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "flashback_cinema", "last_resort_cruise", "seance_hotline", "terminal_zero", "head_office"]:
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


# start_run has already used up the brew, the crafted item, a cursed ticket and the Bon Voyage pack when
# he stands at the first Crossroads, so Save and Quit there must keep the run: a start checkpoint is
# written on arrival, and resuming rebuilds the lone Crossroads.
func test_the_first_crossroads_writes_and_resumes_a_start_checkpoint() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	var write := source.substr(source.find("func write_checkpoint"), 300)
	assert_false(write.contains("MAP_START"), "the first Crossroads is no longer refused")
	var ready := source.substr(source.find("func _ready"), 3000)
	var start := ready.find("_enter_room(_map.start_id)")
	assert_true(start > 0)
	assert_true(ready.find("_write_checkpoint_soon()", start) > start, "written on arriving at the first Crossroads")
	var resume := source.substr(source.find("func _resume_map"), 1600)
	assert_true(resume.contains("kind == MAP_START"), "a start checkpoint is rebuilt")
	assert_true(resume.contains("FloorMap.with_only_crossroads(load(CROSSROADS_LAYOUT))"))
	var map := FloorMap.with_only_crossroads(load("res://data/rooms/crossroads/crossroads.tres"))
	assert_true(map != null)
	assert_eq(map.rooms.size(), 1, "the first Crossroads is a map of one room")
	assert_eq(map.start_id, 0)


# A checkpoint this build cannot rebuild starts a new run instead, and must not stay to be offered again.
func test_a_failed_resume_deletes_the_checkpoint() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	var ready := source.substr(source.find("func _ready"), 1200)
	var tried := ready.find("_resume_map(resume)")
	var cleared := ready.find("Progress.clear_checkpoint()")
	var fresh := ready.find("_start_run()")
	assert_true(tried > 0 and cleared > tried, "cleared after the rebuild fails")
	assert_true(cleared < fresh, "before the new run starts")
	assert_true(ready.substr(tried, cleared - tried).contains("not _resumed"), "only when the resume failed")


# write deletes the old run.json and then renames the temp file, so a kill between the two leaves only a
# complete run.json.tmp: that is the run.
func test_a_complete_temp_file_stands_in_for_a_missing_run_file() -> void:
	_clean()
	var file := FileAccess.open(_path() + ".tmp", FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": RunCheckpoint.VERSION, "depth": 4}))
	file.close()
	assert_eq(int(RunCheckpoint.read(_path()).get("depth", 0)), 4, "the temp file is read")
	_write_text(JSON.stringify({"version": RunCheckpoint.VERSION, "depth": 2}))
	assert_eq(int(RunCheckpoint.read(_path()).get("depth", 0)), 2, "run.json wins while it is there")
	_clean()


# Abandoning pays the Golden Parachute into the save at once, so a kill after the pay but before the
# clear would leave the run to abandon, and pay, again: the checkpoint goes first.
func test_abandoning_clears_the_checkpoint_before_the_parachute_pays() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/autoload/game.gd")
	var abandon := source.substr(source.find("func abandon_and_load"), 900)
	var cleared := abandon.find("Progress.clear_checkpoint()")
	var paid := abandon.find("Progress.add_pension(parachute)")
	assert_true(cleared > 0 and paid > 0)
	assert_true(cleared < paid, "cleared before the pay")
	assert_true(abandon.find("run.parachute_pay(") < cleared, "the pay is worked out from the checkpoint first")
