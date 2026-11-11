extends TestCase

# Golden Years Mall and Fairway's End became the Flashback Cinema and the Seance Hotline. A save and a
# run checkpoint from before carry their progress over to the new ids (PathMigration).

const OLD_SAVE := "res://tests/fixtures/old_save_mall_golf.json"
const ON_MALL := "res://tests/fixtures/checkpoint_on_mall.json"
const ON_GOLF := "res://tests/fixtures/checkpoint_on_golf.json"
const CROSSROADS_LAYOUT := "res://data/rooms/crossroads/crossroads.tres"
const OLD_IDS := ["golden_years_mall", "fairways_end", "pro_shop", "gloria", "mall_santa", "chip", "thaddeus_fairweather"]


func _raw(path: String) -> Dictionary:
	var json := JSON.new()
	assert_eq(json.parse(FileAccess.get_file_as_string(path)), OK, "%s is valid JSON" % path)
	return json.data if json.data is Dictionary else {}


func _old_save() -> ProgressData:
	var data := ProgressData.from_dict(_raw(OLD_SAVE))
	assert_true(data != null, "the old save loads")
	return data


func _through_json(data: ProgressData) -> ProgressData:
	return ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))


func test_cleared_paths_and_their_counts_move_to_the_new_ids() -> void:
	var data := _old_save()
	assert_true(data.has_cleared_path("flashback_cinema"))
	assert_true(data.has_cleared_path("seance_hotline"))
	assert_false(data.paths_cleared.has("golden_years_mall"))
	assert_false(data.paths_cleared.has("fairways_end"))
	assert_eq(data.clears_of_path("flashback_cinema"), 2)
	assert_eq(data.clears_of_path("seance_hotline"), 2)
	assert_false(data.path_clears.has("golden_years_mall"))
	assert_eq(data.clears_at(3), 4, "clears by depth are kept as they were")
	assert_eq(data.clears_at(4), 3)


func test_counts_kept_under_both_ids_are_added_together() -> void:
	var raw := _raw(OLD_SAVE)
	raw["path_clears"]["flashback_cinema"] = 3
	raw["paths_cleared"]["flashback_cinema"] = true
	var data := ProgressData.from_dict(raw)
	assert_eq(data.clears_of_path("flashback_cinema"), 5)
	assert_true(data.has_cleared_path("flashback_cinema"))


func test_letters_and_first_clear_item_news_move_to_the_new_ids() -> void:
	var data := _old_save()
	for id in ["flashback_cinema", "seance_hotline"]:
		assert_true(data.letters_read.has(id), id)
		assert_true(data.item_paths_seen.has(id), id)
	for id in ["golden_years_mall", "fairways_end"]:
		assert_false(data.letters_read.has(id), id)
		assert_false(data.item_paths_seen.has(id), id)
	assert_eq(LetterBook.unread(data).size(), LetterBook.arrived(data).size() - 4, "no letter comes back unread")
	var news := ItemUnlocks.unannounced(Content.items(), data)
	assert_false(news.has("flashback_cinema") or news.has("seance_hotline"), "their items are not announced again")


func test_posters_move_to_the_new_bosses() -> void:
	var data := _old_save()
	assert_eq(data.bounty_taken, "madame_zara")
	for id in ["crabtree", "projectionist", "celestine", "senior_adjuster"]:
		assert_true(data.bounties_retired.has(id), id)
	for id in ["gloria", "mall_santa", "chip"]:
		assert_false(data.bounties_retired.has(id), id)
	var ids := {}
	for def in BountyBoard.all():
		ids[def.id] = true
	assert_true(ids.has(data.bounty_taken), "the taken poster has a BountyDef")
	for id in data.bounties_retired:
		assert_true(ids.has(id), "%s has a BountyDef" % id)


func test_beaten_bosses_keep_the_old_ids_and_gain_the_new_ones() -> void:
	var data := _old_save()
	for id in ["gloria", "mall_santa", "chip", "thaddeus_fairweather", "crabtree", "projectionist", "celestine", "madame_zara"]:
		assert_true(data.bosses_beaten.has(id), id)
	var condolences := data.condolences
	assert_eq(data.record_boss_beaten("projectionist", true), 0, "no second first-beat pay for the same floor's boss")
	assert_eq(data.condolences, condolences)


func test_the_bestiary_keeps_the_old_enemies_as_history() -> void:
	var data := _old_save()
	for id in ["mall_santa", "gloria", "chip", "thaddeus_fairweather", "mall_cop", "club_golfer"]:
		assert_true(data.enemies_seen.has(id), id)
	assert_false(data.enemies_seen.has("projectionist"), "a boss never met is not met")
	var cells := CaseFileData.bestiary(CaseFileData.enemy_defs(), data.enemies_seen, null, CaseFileData.enemy_floors())
	assert_true(cells.size() >= CaseFileData.enemy_defs().size())


func test_an_old_save_with_no_bestiary_seeds_it_from_the_bosses_it_really_beat() -> void:
	var raw := _raw(OLD_SAVE)
	raw.erase("enemies_seen")
	var data := ProgressData.from_dict(raw)
	assert_true(data.enemies_seen.has("mall_santa"))
	assert_false(data.enemies_seen.has("projectionist"), "the replacement was never met")


func test_the_run_log_keeps_its_history() -> void:
	var data := _old_save()
	assert_eq(data.run_log.size(), 2)
	assert_eq(data.run_log[0]["killer"], "Club President Thaddeus Fairweather")
	assert_eq(int(data.run_log[0]["depth"]), 4)
	assert_true(data.run_log[1]["kills"].has("gloria"))
	var no_items: Array[ItemDef] = []
	var names := CaseFileData.names_by_id(no_items, CaseFileData.enemy_defs())
	assert_false(CaseFileData.log_detail(data.run_log[0], names).is_empty())
	assert_eq(data.total("deaths"), 40)
	assert_true(data.endings_found.has(EndingRules.BRIEFLY_ALIVE))


func test_the_waiting_room_opens_the_back_room_and_the_crystal_counter() -> void:
	var data := _old_save()
	var open := Departments.open_ids(data)
	assert_true(open.has(Departments.BACK_ROOM))
	assert_true(open.has(Departments.CRYSTAL_COUNTER))
	assert_true(data.departments_seen.has(Departments.CRYSTAL_COUNTER))
	assert_false(data.departments_seen.has("pro_shop"))
	assert_true(Departments.newly_opened(data).is_empty(), "nothing is announced again")
	var counter := Departments.merchant_entry("crystal_counter")
	assert_true(MerchantRules.is_open(counter, data))
	assert_false(Content.upgrades_for("crystal_counter").is_empty(), "the counter sells its form")
	assert_eq(data.level_of("golf_glove"), 2, "the form keeps its level")
	assert_eq(data.form_choices.get("golf_glove", ""), "b", "and its choice")


func test_the_mementos_hang_for_the_new_bosses() -> void:
	var data := _old_save()
	var hung := Mementos.hung(data).map(func(e): return e["boss"])
	assert_true(hung.has("projectionist"))
	assert_true(hung.has("madame_zara"))
	assert_eq(hung.size(), 8, "every cleared path's memento")
	var perks := Mementos.perks(data)
	assert_true(perks.has(Mementos.TREASURE_CHOICE_PERK))
	assert_true(perks.has(Mementos.CHARGE_PERK))


func test_a_migrated_save_round_trips_unchanged() -> void:
	var data := _old_save()
	var again := _through_json(data)
	assert_eq(again.to_dict(), data.to_dict())


func test_a_second_migration_changes_nothing() -> void:
	var once := PathMigration.migrate_save(_raw(OLD_SAVE))
	var twice := PathMigration.migrate_save(once)
	assert_eq(twice, once)
	var text := JSON.stringify(_old_save().to_dict())
	for id in ["golden_years_mall", "fairways_end", "pro_shop"]:
		assert_false(text.contains("\"%s\"" % id), "%s is gone from the save" % id)


func test_the_migration_leaves_the_raw_save_alone_and_skips_damaged_fields() -> void:
	var raw := _raw(OLD_SAVE)
	var before := raw.duplicate(true)
	PathMigration.migrate_save(raw)
	assert_eq(raw, before, "it works on a copy")
	var odd := {"version": 1, "pension": 0, "upgrades": {}, "opening_seen": true, "paths_cleared": "garbage", "path_clears": {"golden_years_mall": "x"}, "bounty_taken": 5, "bosses_beaten": []}
	var data := ProgressData.from_dict(odd)
	assert_true(data != null)
	assert_eq(data.paths_cleared, {})
	assert_eq(data.bounty_taken, "")


# --- the run checkpoint ---

func _checkpoint(path: String) -> Dictionary:
	var read := RunCheckpoint.read(path)
	assert_false(read.is_empty(), "%s reads" % path)
	return read


func _fresh_run() -> RunState:
	return RunState.new(Content.upgrades(), {}, {})


func test_a_checkpoint_on_a_retired_path_moves_to_its_replacement() -> void:
	for case in [[ON_MALL, "flashback_cinema", 3], [ON_GOLF, "seance_hotline", 4]]:
		var resume := _checkpoint(case[0])
		var floor_path := "res://data/floors/%s.tres" % case[1]
		assert_eq(resume["floor"], floor_path)
		assert_true(ResourceLoader.exists(floor_path))
		assert_eq(int(resume["depth"]), case[2])
		assert_true(resume.get(PathMigration.FLOOR_START, false), "it starts the floor again")
		assert_eq(resume["rooms"], {}, "no room of the old floor is kept")
		assert_false(resume["is_cleared"])
		var paths: Dictionary = resume["ending"]["paths"]
		assert_eq(paths[str(case[2])], case[1], "the run's route names the new path")
		for value in paths.values():
			assert_false(OLD_IDS.has(value), str(paths))
	var golf := _checkpoint(ON_GOLF)
	assert_eq(golf["ending"]["paths"]["3"], "flashback_cinema", "an earlier floor of the route moves too")


func test_a_checkpoint_on_a_retired_path_resumes_at_the_start_of_the_new_floor() -> void:
	for path in [ON_MALL, ON_GOLF]:
		var resume := _checkpoint(path)
		var def: FloorDef = load(resume["floor"])
		var map := RunCheckpoint.build_floor(def, str(resume["seed"]))
		assert_true(map != null, "%s builds from its seed" % def.id)
		if map == null:
			continue
		var side: Array = resume["exit_side"]
		var crossroads := map.attach_crossroads(load(CROSSROADS_LAYOUT), -Vector2i(int(side[0]), int(side[1])))
		assert_true(crossroads != null)
		RunCheckpoint.restart_floor(resume, map, crossroads.id)
		assert_eq(int(resume["room"]), map.start_id, "he stands in the floor's first room")
		assert_eq(int(resume["from"]), crossroads.id, "come in from the Crossroads")
		assert_eq(resume["visited"], [crossroads.id])
		assert_false(resume.has(PathMigration.FLOOR_START), "done once")


func test_a_resumed_run_on_the_new_path_keeps_its_items_pills_and_money() -> void:
	var cases := {ON_MALL: [["bifocals", "coupon_booklet"], 3, 5, 333], ON_GOLF: [["bifocals", "hospital_bracelet", "brass_topper"], 4, 6, 512]}
	for path in cases:
		var resume := _checkpoint(path)
		var want: Array = cases[path]
		var run := _fresh_run()
		RunCheckpoint.apply_run(run, resume["run"], Content.items())
		var held := run.items.map(func(i): return i.id)
		assert_eq(held, want[0], path)
		assert_eq(run.health.pills, want[1], path)
		assert_eq(run.health.max_pills, want[2], path)
		assert_eq(run.keys, 2)
		assert_eq(run.bombs, 3)
		assert_eq(run.potion.id, "swift_tea")
		var data := ProgressData.new()
		data.pension = 9999
		assert_true(RunCheckpoint.apply_pension(data, resume))
		assert_eq(data.pension, want[3], "the money is kept")
		RunCheckpoint.apply_ending(run, resume["ending"])
		assert_eq(run.pension_earned, 700)
		assert_false(run.paths_taken.values().has("golden_years_mall"))


func test_a_checkpoint_migrates_once_and_leaves_live_paths_alone() -> void:
	var once := PathMigration.migrate_checkpoint(_raw(ON_GOLF))
	assert_eq(PathMigration.migrate_checkpoint(once), once)
	var live := {"version": 1, "depth": 3, "floor": "res://data/floors/funeral_parlour.tres", "kind": "floor", "room": 4, "rooms": {"4": {"cleared": true}}, "ending": {"paths": {"3": "funeral_parlour"}}}
	assert_eq(PathMigration.migrate_checkpoint(live), live, "a live path's checkpoint resumes where it was")


func test_the_floor_scene_restarts_a_migrated_floor() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	var resume := source.substr(source.find("func _resume_map"), 2400)
	assert_true(resume.contains("PathMigration.FLOOR_START"))
	assert_true(resume.contains("RunCheckpoint.restart_floor(resume, map, crossroads.id)"))
	var checkpoint := FileAccess.get_file_as_string("res://scripts/core/run_checkpoint.gd")
	assert_true(checkpoint.contains("PathMigration.migrate_checkpoint(raw)"), "every reader of run.json gets the migrated run")
	var progress := FileAccess.get_file_as_string("res://scripts/core/progress_data.gd")
	assert_true(progress.contains("PathMigration.migrate_save(raw)"))
