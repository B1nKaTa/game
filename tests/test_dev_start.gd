extends TestCase

const PROGRESS_SCRIPT := preload("res://scripts/autoload/progress.gd")
# Tests never write to user://, which is the real game's folder: every file here is in the temp folder.
var REAL_PATH := OS.get_temp_dir().path_join("grandpa_test_dev_real_save.json")
var DEV_PATH := OS.get_temp_dir().path_join("grandpa_test_dev_run_save.json")


func _dev_data() -> ProgressData:
	return DevStart.progress(Content.upgrades(), Content.recipes())


# A Progress of its own, outside the tree, whose "real" save is a test file.
func _progress_with_real_save(real: ProgressData) -> Node:
	var store := SaveStore.new(REAL_PATH)
	store.delete_all()
	store.save_progress(real)
	var progress: Node = PROGRESS_SCRIPT.new()
	progress._store = store
	progress.data = store.load_progress()
	return progress


func _real_save_text() -> String:
	return FileAccess.get_file_as_string(REAL_PATH)


func test_the_shortcut_exists_only_in_debug_builds() -> void:
	assert_true(DevStart.allowed(true))
	assert_false(DevStart.allowed(false), "a release export never offers it")
	assert_eq(DevStart.is_available(), OS.is_debug_build())


func test_every_upgrade_is_at_its_top_level() -> void:
	var data := _dev_data()
	var upgrades := Content.upgrades()
	assert_true(upgrades.size() >= 7)
	for def in upgrades:
		assert_eq(data.level_of(def.id), def.max_level(), def.id)
		assert_false(data.can_buy(def), "%s has nothing left to buy" % def.id)
	for id in ["denture_adhesive", "thermos_fuel", "prescription_glasses"]:
		assert_true(data.level_of(id) > 0, id)


func test_the_loadout_makes_a_strong_grandpa() -> void:
	var data := _dev_data()
	var run := RunState.new(Content.upgrades(), data.upgrades)
	var fresh := RunState.new(Content.upgrades(), {})
	assert_true(run.stats.max_pills > fresh.stats.max_pills, "bought pills raise his maximum")
	DevStart.apply_kit(run, Content.items())
	assert_eq(run.keys, DevStart.KEYS)
	assert_eq(run.bombs, DevStart.BOMBS)
	for id: String in DevStart.ITEMS:
		assert_true(run.has_item(id), id)
	assert_eq(run.health.pills, run.health.max_pills, "he starts with every pill")
	assert_eq(data.brewed_potion, DevStart.BREWED_POTION)
	assert_true(Content.potion(DevStart.BREWED_POTION) != null)
	assert_eq(data.pension, DevStart.PENSION)


func test_earlier_floors_count_as_cleared_and_both_third_floor_paths_open() -> void:
	var data := _dev_data()
	assert_eq(data.clears_at(1), 2)
	assert_eq(data.clears_at(2), 2)
	assert_eq(data.clears_at(3), 1)
	for path in ["floor_1", "cemetery", "sunset_shores", "furnace_works"]:
		assert_true(data.has_cleared_path(path), path)
	for path in ["res://data/floors/funeral_parlour.tres", "res://data/floors/flashback_cinema.tres"]:
		var def: FloorDef = load(path)
		assert_eq(def.depth, DevStart.START_DEPTH)
		assert_true(def.is_open_for(data), path)
	for item in Content.recipes():
		assert_true(data.is_unlocked(item.id), item.id)


# F3, F5 and F6 start at floors 3, 4 and 5. F4 stays the dev Waiting Room's.
func test_each_start_key_names_its_depth() -> void:
	assert_eq(DevStart.depth_for_key(KEY_F3), 3)
	assert_eq(DevStart.depth_for_key(KEY_F5), 4)
	assert_eq(DevStart.depth_for_key(KEY_F6), 5)
	assert_eq(DevStart.depth_for_key(KEY_F4), 0, "F4 starts no run")
	assert_eq(DevStart.depth_for_key(KEY_F7), 0)
	assert_eq(DevStart.START_DEPTH, 3, "F3 and the dev Waiting Room's run door still start at floor 3")
	assert_eq(DevStart.depth_for_key(KEY_F3), DevStart.START_DEPTH)


# A deeper start counts every path above it cleared and its own open path once, so both its paths
# are open, and nothing below it is counted.
func test_a_deeper_start_opens_both_paths_of_its_depth_with_every_upgrade_bought() -> void:
	for start_depth in [4, 5]:
		var data := DevStart.progress(Content.upgrades(), Content.recipes(), false, start_depth)
		for def in Content.upgrades():
			assert_eq(data.level_of(def.id), def.max_level(), "%s at depth %d" % [def.id, start_depth])
		assert_eq(data.clears_at(1), 2)
		for depth in range(2, start_depth):
			assert_eq(data.clears_at(depth), 2, "both paths of depth %d" % depth)
			for id: String in ProgressData.PATHS_AT_DEPTH[depth]:
				assert_true(data.has_cleared_path(id), id)
		assert_eq(data.clears_at(start_depth), 1)
		assert_true(data.has_cleared_path(ProgressData.FIRST_PATH_BY_DEPTH[start_depth]))
		assert_false(data.has_cleared_path(ProgressData.PATHS_AT_DEPTH[start_depth][1]), "the locked path is open, not cleared")
		for depth in range(start_depth + 1, 6):
			assert_eq(data.clears_at(depth), 0, "nothing below the start, depth %d" % depth)
		for id: String in ProgressData.PATHS_AT_DEPTH[start_depth]:
			var def: FloorDef = load("res://data/floors/%s.tres" % id)
			assert_eq(def.depth, start_depth)
			assert_true(def.is_open_for(data), id)


func test_the_floor_3_profile_is_as_it_was() -> void:
	assert_eq(DevStart.clears_by_depth(), {1: 2, 2: 2, 3: 1})
	var expected := ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour"]
	var cleared := DevStart.paths_cleared()
	assert_eq(cleared.size(), expected.size())
	for i in mini(cleared.size(), expected.size()):
		assert_eq(cleared[i], expected[i])


# The start depth rides on Progress for the run's scene and falls back to floor 3 when the run ends.
func test_progress_carries_the_start_depth_only_while_the_dev_run_lasts() -> void:
	var progress := _progress_with_real_save(ProgressData.new())
	assert_eq(progress.dev_start_depth, DevStart.START_DEPTH)
	progress.begin_dev_run(DevStart.progress(Content.upgrades(), Content.recipes(), false, 5), DEV_PATH, 5)
	assert_eq(progress.dev_start_depth, 5)
	progress.end_dev_run()
	assert_eq(progress.dev_start_depth, DevStart.START_DEPTH)
	progress.begin_dev_run(_waiting_data(), DEV_PATH)
	assert_eq(progress.dev_start_depth, DevStart.START_DEPTH, "the dev Waiting Room's run door starts at floor 3")
	progress.end_dev_run()
	progress.free()
	SaveStore.new(REAL_PATH).delete_all()


# The scene starts a dev run at the depth Progress carries, and the Waiting Room reads every start key.
func test_the_scene_and_the_waiting_room_use_the_chosen_depth() -> void:
	var scene := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	assert_true(scene.contains("_depth = Progress.dev_start_depth"))
	var room := FileAccess.get_file_as_string("res://scripts/scenes/waiting_room.gd")
	assert_true(room.contains("DevStart.depth_for_key(key.physical_keycode)"))
	var game := FileAccess.get_file_as_string("res://scripts/autoload/game.gd")
	var begin := game.substr(game.find("func begin_dev_run"), 120)
	assert_true(begin.contains("if not DevStart.is_available():"), "Game checks the gate first")


func _waiting_data() -> ProgressData:
	return DevStart.progress(Content.upgrades(), Content.recipes(), true)


func test_the_dev_waiting_room_profile_opens_every_department() -> void:
	var data := _waiting_data()
	for id in ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "flashback_cinema", "last_resort_cruise", "seance_hotline", "terminal_zero", "head_office"]:
		assert_true(data.has_cleared_path(id), id)
	assert_eq(DevStart.ALL_PATHS.size(), 10)
	assert_eq(BountyBoard.showing(data).size(), BountyBoard.all().size(), "every poster shows")
	for each: Dictionary in Departments.ALL:
		assert_true(Departments.is_open(each["id"], data), each["id"])
	assert_eq(data.clears_at(3), _dev_data().clears_at(3), "only path ids are added, not clears")
	assert_false(_dev_data().has_cleared_path("flashback_cinema"), "the Floor 3 run's profile leaves the Mall uncleared")
	assert_true(PROGRESS_SCRIPT.DEV_PATH != PROGRESS_SCRIPT.SAVE_PATH, "the dev profile has its own file")


func test_the_dev_waiting_room_has_its_own_key_and_hint() -> void:
	assert_false(DevStart.START_KEYS.has(DevStart.WAITING_KEY), "F3, F5 and F6 still start their runs")
	assert_false(DevStart.WAITING_HINT.is_empty())
	assert_false(DevStart.WAITING_HINT_ON.is_empty())
	assert_eq(DevStart.PROFILE_LABEL, "DEV PROFILE")


# Release exports are not debug builds, and both ways in check the gate before anything else.
func test_the_dev_waiting_room_is_gated_on_debug_builds() -> void:
	assert_false(DevStart.allowed(false))
	var game := FileAccess.get_file_as_string("res://scripts/autoload/game.gd")
	var toggle := game.substr(game.find("func toggle_dev_waiting_room"), 120)
	assert_true(toggle.contains("if not DevStart.is_available():"), "Game checks the gate first")
	var scene := FileAccess.get_file_as_string("res://scripts/scenes/waiting_room.gd")
	var keys := scene.substr(scene.find("func _unhandled_input"), 120)
	assert_true(keys.contains("if not DevStart.is_available()"), "the Waiting Room checks the gate before reading F4")


# Every way the Waiting Room's panels and arrival can touch the save, done under the dev profile.
func _use_the_waiting_room(progress: Node) -> void:
	progress.add_pension(500)
	progress.spend(20)
	progress.buy(Content.upgrades()[0])
	progress.refile(Content.upgrades()[0])
	progress.add_condolences(30)
	progress.spend_condolences(5)
	progress.mark_departments_seen(["back_room", "decor_office"])
	progress.mark_coach_met()
	progress.read_letter("floor_1")
	progress.retirement_deposit(50)
	progress.take_brewed_potion()
	progress.call_ticket()


func test_the_dev_waiting_room_never_writes_the_real_save() -> void:
	var real := ProgressData.new()
	real.pension = 17
	real.condolences = 4
	real.opening_seen = true
	var progress := _progress_with_real_save(real)
	var before := _real_save_text()
	var kept: Dictionary = progress.data.to_dict().duplicate(true)
	progress.begin_dev_run(_waiting_data(), DEV_PATH)
	assert_true(progress.is_dev_run())
	_use_the_waiting_room(progress)
	assert_eq(_real_save_text(), before, "the real save is untouched while the dev Waiting Room is on")
	# F4 again ends it, as Game.toggle_dev_waiting_room does.
	progress.end_dev_run()
	assert_false(progress.is_dev_run())
	assert_eq(_real_save_text(), before, "the real save is untouched after leaving")
	assert_false(FileAccess.file_exists(DEV_PATH), "the dev file is thrown away")
	assert_eq(progress.data.to_dict(), kept, "the real progress is back exactly as it was")
	assert_eq(progress.data.pension, 17, "Pension earned or spent there is thrown away")
	assert_eq(progress.data.condolences, 4, "Condolences earned or spent there are thrown away")
	progress.free()
	SaveStore.new(REAL_PATH).delete_all()


# F3 in the dev Waiting Room swaps its profile for the Floor 3 run's, and that run ends on return.
func test_starting_the_floor_3_run_from_the_dev_waiting_room_keeps_the_real_progress() -> void:
	var real := ProgressData.new()
	real.pension = 17
	var progress := _progress_with_real_save(real)
	var before := _real_save_text()
	var kept: Dictionary = progress.data.to_dict().duplicate(true)
	progress.begin_dev_run(_waiting_data(), DEV_PATH)
	progress.add_pension(40)
	progress.begin_dev_run(_dev_data(), DEV_PATH)
	assert_true(progress.is_dev_run())
	assert_false(progress.data.has_cleared_path("flashback_cinema"), "the Floor 3 run's own profile")
	progress.start_run()
	progress.end_dev_run()
	assert_eq(_real_save_text(), before)
	assert_eq(progress.data.to_dict(), kept, "the real progress waited, not the dev Waiting Room's")
	progress.free()
	SaveStore.new(REAL_PATH).delete_all()


func test_quitting_ends_the_dev_waiting_room() -> void:
	var real := ProgressData.new()
	real.pension = 17
	var progress := _progress_with_real_save(real)
	var before := _real_save_text()
	var kept: Dictionary = progress.data.to_dict().duplicate(true)
	progress.begin_dev_run(_waiting_data(), DEV_PATH)
	_use_the_waiting_room(progress)
	progress._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	assert_false(progress.is_dev_run(), "closing the window ends it")
	assert_false(FileAccess.file_exists(DEV_PATH))
	assert_eq(progress.data.to_dict(), kept)
	progress.begin_dev_run(_waiting_data(), DEV_PATH)
	progress.add_pension(40)
	progress._exit_tree()
	assert_false(progress.is_dev_run(), "the game tearing down ends it")
	assert_false(FileAccess.file_exists(DEV_PATH))
	assert_eq(progress.data.to_dict(), kept)
	assert_eq(_real_save_text(), before, "the real save is never written on the way out")
	progress.free()
	SaveStore.new(REAL_PATH).delete_all()


func test_a_dev_run_never_writes_the_real_save() -> void:
	var real := ProgressData.new()
	real.pension = 17
	real.opening_seen = true
	var progress := _progress_with_real_save(real)
	var before := _real_save_text()
	progress.begin_dev_run(_dev_data(), DEV_PATH)
	assert_true(progress.is_dev_run())
	progress.start_run()
	progress.add_pension(500)
	progress.buy(Content.upgrades()[0])
	progress.record_floor_cleared(3, "flashback_cinema")
	progress.find_recipe("anything")
	progress.retirement_deposit(50)
	progress.take_brewed_potion()
	assert_eq(_real_save_text(), before, "the real save is untouched during the run")
	assert_true(FileAccess.file_exists(DEV_PATH), "the dev run saves to its own file")
	progress.end_dev_run()
	assert_false(progress.is_dev_run())
	assert_eq(_real_save_text(), before, "the real save is untouched after the run")
	assert_false(FileAccess.file_exists(DEV_PATH), "the dev file is thrown away")
	assert_eq(progress.data.pension, 17, "Pension earned in the dev run is not kept")
	assert_eq(progress.data.clears_at(3), 0, "the dev run's clears are not kept")
	assert_eq(progress.data.run_count, 0)
	progress.add_pension(1)
	assert_true(_real_save_text() != before, "saving goes back to the real file afterwards")
	assert_eq(SaveStore.new(REAL_PATH).load_progress().pension, 18)
	progress.free()
	SaveStore.new(REAL_PATH).delete_all()


func test_ending_without_a_dev_run_changes_nothing() -> void:
	var real := ProgressData.new()
	real.pension = 5
	var progress := _progress_with_real_save(real)
	var kept: ProgressData = progress.data
	progress.end_dev_run()
	assert_true(progress.data == kept)
	assert_false(progress.is_dev_run())
	progress.free()
	SaveStore.new(REAL_PATH).delete_all()


# --- The tester panel: F9 in a run, in debug builds and playtest exports only ---

func test_cheats_exist_in_debug_builds_and_playtest_exports_only() -> void:
	assert_true(DevStart.cheats_allowed(true, false), "a debug build")
	assert_true(DevStart.cheats_allowed(false, true), "a playtest export")
	assert_true(DevStart.cheats_allowed(true, true))
	assert_false(DevStart.cheats_allowed(false, false), "a release export has none")
	assert_eq(DevStart.cheats_available(), OS.is_debug_build() or OS.has_feature("playtest"))
	assert_eq(DevStart.CHEAT_KEY, KEY_F9)
	for key: int in [DevStart.WAITING_KEY, DevStart.REEL_KEY]:
		assert_true(DevStart.CHEAT_KEY != key, "F9 is no other dev key")
	assert_false(DevStart.START_KEYS.has(DevStart.CHEAT_KEY))


func _preset(presets: ConfigFile, preset_name: String) -> String:
	for section in presets.get_sections():
		if not section.ends_with(".options") and str(presets.get_value(section, "name", "")) == preset_name:
			return section
	return ""


# Only the playtest preset carries the tag, so a Steam build made from the release preset has no cheats.
func test_only_the_playtest_preset_carries_the_playtest_tag() -> void:
	var presets := ConfigFile.new()
	assert_eq(presets.load("res://export_presets.cfg"), OK)
	var release := _preset(presets, "Windows Desktop")
	var playtest := _preset(presets, "Windows Playtest")
	assert_false(release.is_empty())
	assert_false(playtest.is_empty())
	if release.is_empty() or playtest.is_empty():
		return
	assert_eq(presets.get_value(release, "custom_features"), "", "the release preset has no tag")
	assert_eq(presets.get_value(release, "export_path"), "../build/Grandpa.exe")
	assert_eq(presets.get_value(playtest, "custom_features"), "playtest")
	assert_eq(presets.get_value(playtest, "export_path"), "../build-playtest/Grandpa.exe")
	# Godot keeps one runnable preset per platform, and the release one stays it.
	assert_eq(presets.get_value(release, "runnable"), true)
	assert_eq(presets.get_value(playtest, "runnable"), false)
	for key in presets.get_section_keys(release):
		if not (key in ["name", "custom_features", "export_path", "runnable"]):
			assert_eq(presets.get_value(playtest, key), presets.get_value(release, key), key)
	assert_eq(presets.get_section_keys(playtest).size(), presets.get_section_keys(release).size())
	for key in presets.get_section_keys(release + ".options"):
		assert_eq(presets.get_value(playtest + ".options", key), presets.get_value(release + ".options", key), key)
	assert_eq(presets.get_section_keys(playtest + ".options").size(), presets.get_section_keys(release + ".options").size())


# A playtest exe and zip never share a path or a name with a Steam build's.
func test_the_build_steps_keep_playtest_builds_apart_from_steam_builds() -> void:
	var steps := FileAccess.get_file_as_string("res://docs/release/build-steps.md")
	assert_true(steps.contains("--export-release \"Windows Playtest\" D:\\grandpa-build\\build-playtest\\Grandpa.exe"), "its own folder, as the preset's path")
	assert_false(steps.contains("--export-release \"Windows Playtest\" D:\\grandpa-build\\Grandpa.exe"), "never the release exe's path")
	assert_true(steps.contains("Grandpa-playtest-<commit>.zip"))
	assert_true(steps.contains("PLAYTEST"), "the corner check names the mark")


func _cheat_run() -> RunState:
	return RunState.new(Content.upgrades(), {})


func _pool_item(id: String) -> ItemDef:
	for item in Content.items():
		if item.id == id:
			return item
	return null


# How many cheats the panel under test has reported, and the progress a report marks, if any.
var _cheats := 0
var _marking: Node


func _on_cheat() -> void:
	_cheats += 1
	if _marking != null:
		DevStart.mark_tester_run(_marking, DEV_PATH)


# tester_run: the run is a tester run already, so no question is asked before a cheat.
func _panel(run: RunState, tester_run := true) -> TesterPanel:
	var panel := TesterPanel.new()
	panel.setup(run, Content.items(), Content.run_potions())
	panel.tester_run = tester_run
	_cheats = 0
	_marking = null
	panel.cheat_used.connect(_on_cheat)
	return panel


func test_the_panel_lists_every_pool_item_and_run_potion() -> void:
	var panel := TesterPanel.new()
	panel.setup(_cheat_run(), Content.items(), Content.run_potions())
	assert_eq(panel.item_list().size(), Content.items().size())
	assert_eq(panel.potion_list().size(), Content.run_potions().size())
	assert_true(panel.potion_list().size() > 1)
	var names: Array[String] = []
	for item in panel.item_list():
		names.append(item.display_name.to_lower())
	var sorted := names.duplicate()
	sorted.sort()
	assert_eq(names, sorted, "by name, for finding one")
	panel.free()


func test_the_panel_adds_ninety_nine_slips_and_thermoses_up_to_the_cap() -> void:
	var run := _cheat_run()
	run.keys = 3
	run.bombs = 1
	var panel := _panel(run)
	assert_true(panel.add_slips())
	assert_eq(run.keys, RunState.MAX_CONSUMABLE, "the keys")
	assert_eq(run.bombs, 1)
	assert_true(panel.add_thermoses())
	assert_eq(run.bombs, RunState.MAX_CONSUMABLE, "the bombs")
	assert_false(panel.add_slips(), "at the cap a press changes nothing")
	assert_false(panel.add_thermoses())
	assert_eq(run.keys, RunState.MAX_CONSUMABLE, "never past the cap")
	assert_eq(run.bombs, RunState.MAX_CONSUMABLE)
	assert_eq(_cheats, 2, "a press that changes nothing is no cheat")
	panel.free()


var _paid: Array[int] = []


func _on_paid(amount: int) -> void:
	_paid.append(amount)


# Pension pays as an item's does, through the run's own pay hook (the scene's _on_pension_earned).
func test_the_panel_pays_pension_through_the_runs_pay_hook() -> void:
	var run := _cheat_run()
	_paid.clear()
	run.effects.ctx.pay_pension = _on_paid
	var panel := _panel(run)
	assert_true(panel.add_pension())
	assert_eq(_paid, [TesterPanel.PENSION_AMOUNT] as Array[int])
	assert_eq(TesterPanel.PENSION_AMOUNT, 999)
	assert_eq(_cheats, 1)
	var bankless := _panel(_cheat_run())
	assert_false(bankless.add_pension(), "a run with no bank pays nothing")
	assert_eq(_cheats, 0)
	panel.free()
	bankless.free()


func test_give_item_puts_it_in_the_run_as_a_pickup_does() -> void:
	var run := _cheat_run()
	var panel := _panel(run)
	var shoes := _pool_item("velcro_shoes")
	assert_true(panel.give_item(shoes))
	assert_true(run.has_item("velcro_shoes"))
	assert_true(run.found.has("velcro_shoes"), "found, as a picked-up item is")
	assert_false(panel.give_item(shoes), "one already held is refused, as its pickup is")
	assert_eq(run.items.size(), 1)
	var desk := _pool_item("exchange_desk")
	assert_true(desk.is_active())
	assert_true(panel.give_item(desk))
	assert_true(run.active == desk, "an active goes to the active slot")
	assert_eq(_cheats, 2, "only what was given counts")
	panel.free()


func test_give_all_gives_every_passive_not_held_and_no_active() -> void:
	var run := _cheat_run()
	var panel := _panel(run)
	var passives: Array[String] = ["pill_organizer", "velcro_shoes", "afterimage"]
	var some: Array[ItemDef] = []
	for id: String in passives:
		some.append(_pool_item(id))
		assert_false(some.back().is_active(), id)
	for id: String in ["hearing_aid_feedback", "exchange_desk"]:
		some.append(_pool_item(id))
		assert_true(some.back().is_active(), id)
	panel.give_item(some[0])
	_cheats = 0
	assert_eq(TesterPanel.give_all_list(some, run).size(), 2, "the passives not held")
	assert_eq(panel.give_all(some), 2)
	for id: String in passives:
		assert_true(run.has_item(id), id)
	assert_true(run.active == null, "an active would swap the last one out, so none is given")
	assert_eq(TesterPanel.give_all_list(some, run).size(), 0, "nothing left to give")
	assert_eq(panel.give_all(some), 0)
	assert_eq(_cheats, 1, "only a press that gave something counts")
	var actives := 0
	for item in Content.items():
		actives += 1 if item.is_active() else 0
	var everything := TesterPanel.give_all_list(Content.items(), _cheat_run())
	assert_eq(everything.size(), Content.items().size() - actives, "the whole passive pool")
	assert_true(actives > 0)
	panel.free()


func test_give_potion_fills_or_replaces_the_potion_slot() -> void:
	var run := _cheat_run()
	var panel := _panel(run)
	var potions := Content.run_potions()
	assert_true(panel.give_potion(potions[0]))
	assert_true(run.potion == potions[0])
	assert_true(panel.give_potion(potions[1]))
	assert_true(run.potion == potions[1], "a carried potion is replaced")
	assert_false(panel.give_potion(potions[1]), "the one carried changes nothing")
	assert_eq(_cheats, 2)
	panel.free()


func test_god_mode_blocks_every_hit_while_on() -> void:
	var run := _cheat_run()
	var panel := _panel(run)
	var player := Player.new()
	player.setup(run)
	var pills := run.health.pills
	assert_true(panel.set_god_mode(true))
	assert_true(panel.god_mode())
	assert_false(run.health.hit(1))
	assert_false(player.take_hit(5), "an enemy's hit")
	assert_false(player.take_fire_hit(1))
	for i in 4:
		run.health.lose_half(false)
	assert_eq(run.health.pills, pills, "no pill lost")
	assert_false(run.health.is_dead())
	assert_true(panel.set_god_mode(false))
	assert_false(panel.god_mode())
	assert_true(player.take_hit(1), "hits land again once it is off")
	assert_eq(run.health.pills, pills - 1)
	assert_eq(_cheats, 2)
	player.free()
	panel.free()


# The first cheat of a run that is not a tester run asks first. No changes nothing and reports nothing;
# a press that would change nothing never asks.
func test_the_first_cheat_asks_and_no_changes_nothing() -> void:
	var run := _cheat_run()
	var panel := _panel(run, false)
	var shoes := _pool_item("velcro_shoes")
	assert_false(panel.give_item(shoes), "not given yet")
	assert_true(panel.asking())
	assert_false(run.has_item("velcro_shoes"))
	assert_eq(_cheats, 0, "nothing is marked before the answer")
	panel.answer(false)
	assert_false(panel.asking())
	assert_false(run.has_item("velcro_shoes"), "No gives nothing")
	assert_eq(_cheats, 0, "and marks nothing")
	assert_false(panel.tester_run)
	run.keys = RunState.MAX_CONSUMABLE
	assert_false(panel.add_slips())
	assert_false(panel.asking(), "a press at the cap asks nothing")
	assert_true(panel.set_god_mode(true) == false and panel.asking())
	panel.answer(true)
	assert_true(panel.god_mode(), "Yes runs the cheat")
	assert_eq(_cheats, 1)
	assert_true(panel.tester_run, "asked once a run")
	assert_true(panel.give_item(shoes), "the next cheat runs at once")
	assert_false(panel.asking())
	assert_eq(_cheats, 2)
	panel.free()


func _slip_buttons(panel: TesterPanel) -> Dictionary:
	var found := {}
	for node in panel.confirm_layer().get_children():
		var button := node as Button
		if button != null:
			found[button.text] = button
	return found


# A double-click on a list row must not land its second click on Yes, and hover must not move the
# focus off No, so Enter cannot answer Yes by accident.
func test_the_confirm_slip_ignores_presses_at_first_and_hover_keeps_the_focus_on_no() -> void:
	var run := _cheat_run()
	var panel := _panel(run, false)
	var shoes := _pool_item("velcro_shoes")
	panel.give_item(shoes)
	assert_true(panel.asking())
	# The test run has no live tree, so the slip is built by hand.
	panel.call("_show_confirm")
	var buttons := _slip_buttons(panel)
	assert_eq(buttons.size(), 2, "No and Yes")
	var no: Button = buttons.get(panel.tr(TesterPanel.NO))
	var yes: Button = buttons.get(panel.tr(TesterPanel.YES))
	assert_true(no != null and yes != null)
	if no == null or yes == null:
		panel.free()
		return
	yes.pressed.emit()
	no.pressed.emit()
	panel.press_slip(true)
	assert_true(panel.asking(), "a click or Enter within 0.25 s does nothing")
	assert_false(run.has_item("velcro_shoes"))
	for button in [no, yes]:
		for link in button.mouse_entered.get_connections():
			assert_false((link["callable"] as Callable).get_method() == &"grab_focus", "hover never moves the focus")
	OS.delay_msec(300)
	panel.press_slip(true)
	assert_false(panel.asking(), "after the pause Yes answers")
	assert_true(run.has_item("velcro_shoes"))
	panel.free()


# The run is a tester run before the first cheat touches it, so a cheat that pays Pension on gain
# (Inheritance Letter) pays the throwaway copy, never the real save.
func test_the_first_cheat_lands_on_the_tester_copy_not_the_real_save() -> void:
	var real := ProgressData.new()
	real.pension = 17
	real.opening_seen = true
	var progress := _progress_with_real_save(real)
	var before := _real_save_text()
	var run := _cheat_run()
	run.effects.ctx.pay_pension = Callable(progress, "add_pension")
	var panel := _panel(run, false)
	_marking = progress
	var letter := _pool_item("inheritance_letter")
	assert_true(letter != null)
	panel.give_item(letter)
	assert_eq(_real_save_text(), before, "asking changes nothing")
	panel.answer(true)
	assert_true(run.has_item("inheritance_letter"))
	assert_true(progress.is_dev_run(), "a tester run now")
	assert_eq(progress.data.pension, 17 + 75, "the letter paid the copy")
	assert_eq(_real_save_text(), before, "the real save never saw the letter's Pension")
	assert_true(panel.add_pension())
	assert_eq(_real_save_text(), before)
	progress.end_dev_run()
	assert_eq(progress.data.pension, 17, "the real save's Pension is as it was")
	_marking = null
	panel.free()
	progress.free()
	SaveStore.new(REAL_PATH).delete_all()


# Stands in for Progress, so the tester-run switch can be checked without any checkpoint file.
class FakeProgress extends Node:
	var calls: Array[String] = []
	var data := ProgressData.new()
	var dev_start_depth := DevStart.START_DEPTH
	var dev := false

	func is_dev_run() -> bool:
		return dev

	func clear_checkpoint() -> void:
		calls.append("clear")

	func begin_dev_run(dev_data: ProgressData, dev_path: String, start_depth: int) -> void:
		calls.append("begin %s %d" % [dev_path, start_depth])
		data = dev_data
		dev = true


func test_the_tester_switch_clears_the_checkpoint_before_the_dev_run_begins() -> void:
	var progress := FakeProgress.new()
	progress.data.pension = 17
	var real := progress.data
	assert_true(DevStart.mark_tester_run(progress, DEV_PATH))
	assert_eq(progress.calls, ["clear", "begin %s %d" % [DEV_PATH, DevStart.START_DEPTH]] as Array[String], "a dev run keeps no checkpoint, so the real one goes first")
	assert_true(progress.data != real, "a copy")
	assert_eq(progress.data.pension, 17, "of the save as it stood")
	assert_false(DevStart.mark_tester_run(progress, DEV_PATH), "once is enough")
	assert_eq(progress.calls.size(), 2)
	progress.free()


# A run a cheat touched is a tester run: a dev run on a copy of the save as it stood, so nothing from
# it reaches the real save.
func test_a_tester_run_never_reaches_the_real_save() -> void:
	var real := ProgressData.new()
	real.pension = 17
	real.opening_seen = true
	var progress := _progress_with_real_save(real)
	var before := _real_save_text()
	var log_size: int = progress.data.run_log.size()
	assert_true(DevStart.mark_tester_run(progress, DEV_PATH))
	assert_true(progress.is_dev_run(), "flagged as dev runs are")
	assert_eq(progress.data.pension, 17, "it goes on from the save as it stood")
	progress.add_pension(500)
	progress.record_floor_cleared(1, "floor_1")
	progress.data.run_log.append({"n": 99})
	progress.data.items_unlocked["anything"] = true
	assert_eq(_real_save_text(), before, "the real save is untouched")
	progress.end_dev_run()
	assert_false(progress.is_dev_run())
	assert_eq(progress.data.pension, 17, "nothing it earned is kept")
	assert_eq(progress.data.clears_at(1), 0, "no clear is kept")
	assert_eq(progress.data.run_log.size(), log_size, "the copy shared nothing with the real save")
	assert_false(progress.data.items_unlocked.has("anything"))
	assert_false(FileAccess.file_exists(DEV_PATH))
	progress.free()
	SaveStore.new(REAL_PATH).delete_all()


# Once a run is a tester run, the pause menu never offers to save it.
func test_the_pause_menu_says_a_tester_run_is_not_saved() -> void:
	assert_eq(PauseMenu.quit_text(true, false), "Save and Quit to Title")
	assert_eq(PauseMenu.quit_text(false, false), "Quit to Title")
	assert_eq(PauseMenu.quit_text(true, true), PauseMenu.QUIT_NOT_SAVED)
	assert_false(PauseMenu.QUIT_NOT_SAVED.contains("Save"))
	assert_true(PauseMenu.NOT_SAVED_NOTE.contains("not saved"))
	var scene := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	assert_true(scene.contains("_pause.setup(true, Progress.is_dev_run())"))
	assert_true(scene.contains("_tester.tester_run = Progress.is_dev_run()"), "a tester run asks no more")


# Nothing of the panel exists without cheats: the scene's only listener checks the gate first.
func test_the_scene_opens_the_panel_only_when_cheats_are_available() -> void:
	var scene := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	var listener := scene.substr(scene.find("func _unhandled_input"), 120)
	assert_true(listener.contains("if not DevStart.cheats_available():"), "the gate first")
	assert_true(scene.contains("DevStart.CHEAT_KEY"))
	assert_true(scene.contains("DevStart.mark_tester_run(Progress, Progress.DEV_PATH)"))
	assert_eq(scene.count("TesterPanel.new()"), 1, "one place makes it")
