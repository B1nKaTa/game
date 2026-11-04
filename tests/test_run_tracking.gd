extends TestCase


func _run() -> RunState:
	var upgrades: Array[UpgradeDef] = []
	return RunState.new(upgrades, {})


func _save(extra: Dictionary) -> Dictionary:
	var raw := {"version": ProgressData.VERSION, "pension": 0, "upgrades": {}, "opening_seen": true}
	raw.merge(extra, true)
	return raw


func test_a_fresh_run_tracks_nothing_yet() -> void:
	var run := _run()
	var snap := run.ending_snapshot()
	assert_eq(snap["play_time"], 0.0)
	assert_eq(snap["pension_earned"], 0)
	assert_eq(snap["items"], 0)
	assert_eq(snap["arcade_visits_won"], 0)
	assert_eq(snap["cursed"], false)
	assert_eq(snap["lost_pill_in_boss_room"], false)
	assert_eq(snap["paths"], {})
	assert_eq(snap["pills"], run.health.pills)


func test_the_snapshot_reads_the_run() -> void:
	var run := _run()
	run.play_time = 900.5
	run.pension_earned = 321
	run.cursed = true
	run.boss_room_pill_lost = true
	run.paths_taken[1] = "cemetery"
	run.items.append(ItemDef.new())
	var snap := run.ending_snapshot()
	assert_eq(snap["play_time"], 900.5)
	assert_eq(snap["pension_earned"], 321)
	assert_eq(snap["items"], 1)
	assert_eq(snap["cursed"], true)
	assert_eq(snap["lost_pill_in_boss_room"], true)
	assert_eq(snap["paths"], {1: "cemetery"})
	# A copy, so a later path never changes a snapshot already taken.
	run.paths_taken[2] = "furnace_works"
	assert_eq(snap["paths"].size(), 1)


func test_a_table_visit_counts_once_however_many_games_it_wins() -> void:
	var run := _run()
	run.note_arcade_win(1)
	run.note_arcade_win(1)
	run.note_arcade_win(1)
	assert_eq(run.arcade_visits_won(), 1)
	run.note_arcade_win(2)
	run.note_arcade_win(5)
	assert_eq(run.arcade_visits_won(), 3)
	run.extra_table_visits = 2
	assert_eq(run.arcade_visits_won(), 5, "Back Room visits won before the run count too")


func test_an_old_save_that_saw_the_card_has_found_briefly_alive() -> void:
	var data := ProgressData.from_dict(_save({"ending_seen": true}))
	assert_eq(data.endings_found, {"briefly_alive": true})
	assert_true(data.ending_seen)


func test_an_old_save_that_never_saw_it_has_found_nothing() -> void:
	var data := ProgressData.from_dict(_save({}))
	assert_eq(data.endings_found, {})
	assert_eq(data.last_repeat_death, 0)
	assert_eq(data.repeat_deaths_seen, {})


func test_found_endings_and_quick_deaths_survive_a_save() -> void:
	var data := ProgressData.new()
	data.record_ending("literally")
	data.record_repeat_death(3)
	var back := ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))
	assert_eq(back.endings_found, {"literally": true})
	assert_eq(back.last_repeat_death, 3)
	assert_eq(back.repeat_deaths_seen, {"3": true})
	assert_true(back.ending_seen, "still written for older builds")


func test_garbage_ending_fields_load_as_nothing() -> void:
	var data := ProgressData.from_dict(_save({"endings_found": "lots", "last_repeat_death": 99, "repeat_deaths_seen": [1, 2]}))
	assert_eq(data.endings_found, {})
	assert_eq(data.last_repeat_death, 0)
	assert_eq(data.repeat_deaths_seen, {})
	var unknown := ProgressData.from_dict(_save({"endings_found": {"literally": true, "made_up": true}, "repeat_deaths_seen": {"2": true, "9": true}}))
	assert_eq(unknown.endings_found, {"literally": true})
	assert_eq(unknown.repeat_deaths_seen, {"2": true})


func test_an_ending_pays_condolences_once() -> void:
	var data := ProgressData.new()
	assert_eq(data.record_ending("by_a_thread"), ProgressData.ENDING_CONDOLENCES)
	assert_eq(data.condolences, 15)
	assert_eq(data.record_ending("by_a_thread"), 0)
	assert_eq(data.condolences, 15)
	assert_eq(data.record_ending("not_an_ending"), 0)
	assert_false(data.endings_found.has("not_an_ending"))


func test_the_true_ending_gives_geralds_hat() -> void:
	var data := ProgressData.new()
	data.record_ending("scenic_route")
	assert_false(data.owns_cosmetic(ProgressData.GERALDS_HAT))
	data.record_ending("eternal_feud")
	assert_true(data.owns_cosmetic(ProgressData.GERALDS_HAT))
	assert_false(data.cosmetics_worn.has("hat"), "owned, not worn")


func test_geralds_hat_is_a_hat_never_sold() -> void:
	var hat := CosmeticDef.find(ProgressData.GERALDS_HAT, CosmeticDef.all())
	assert_true(hat != null)
	if hat == null:
		return
	assert_eq(hat.slot, CosmeticDef.SLOT_HAT)
	assert_false(hat.is_sold())
	assert_eq(hat.shape, "bucket")


func test_a_quick_death_is_remembered() -> void:
	var data := ProgressData.new()
	data.record_repeat_death(2)
	data.record_repeat_death(4)
	data.record_repeat_death(2)
	assert_eq(data.last_repeat_death, 2)
	assert_eq(data.repeat_deaths_seen.size(), 2)
	data.record_repeat_death(0)
	data.record_repeat_death(6)
	assert_eq(data.last_repeat_death, 2, "out of range is ignored")
