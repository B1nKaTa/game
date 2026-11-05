extends TestCase

# The case file's history in the save: the run log, lifetime totals, best run and the catalogs. Every
# key is optional, so an older save loads unchanged with an empty history.

const FIXTURE := "res://tests/fixtures/save_v1_2026-11-04.json"


func _fixture_raw() -> Dictionary:
	var json := JSON.new()
	assert_eq(json.parse(FileAccess.get_file_as_string(FIXTURE)), OK, "the fixture is valid JSON")
	return json.data


func _entry(n: int, result := RunLog.DIED, kills := {"intern_reaper": 3}) -> Dictionary:
	return {
		"n": n, "date": "2026-11-05 10:00:00", "result": result, "depth": 2, "floor": "Sunset Shores",
		"room": "combat", "killer": "Matron Mercy", "time": 321.5, "seeds": ["abc"], "pension": 40,
		"kills": kills, "met": ["intern_reaper", "matron_mercy"], "found": ["kettle", "kettle"],
		"items": ["kettle", "kettle"], "hits": 4, "cursed": false,
	}


func test_an_old_save_loads_unchanged_with_an_empty_history() -> void:
	var raw := _fixture_raw()
	for key in ["run_log", "lifetime", "best_run", "items_seen", "enemies_seen"]:
		assert_false(raw.has(key), "the fixture predates %s" % key)
	var data := ProgressData.from_dict(raw)
	assert_true(data != null, "it loads")
	assert_eq(data.pension, 312)
	assert_eq(data.run_count, 23)
	assert_eq(data.run_log.size(), 0)
	assert_eq(data.total("kills"), 0)
	assert_eq(data.best("depth"), 0)
	for id in data.items_unlocked:
		assert_true(data.items_seen.has(id), "a crafted item counts as found: %s" % id)
	for id in data.bosses_beaten:
		assert_true(data.enemies_seen.has(id), "a beaten boss counts as met: %s" % id)


func test_the_history_survives_a_round_trip() -> void:
	var data := ProgressData.from_dict(_fixture_raw())
	data.record_run(_entry(24))
	data.record_run(_entry(25, RunLog.CLEARED))
	data.set_last_ending(EndingRules.BRIEFLY_ALIVE)
	var back := ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))
	assert_eq(back.run_log.size(), 2)
	assert_eq(int(back.run_log[0]["n"]), 25, "newest first")
	assert_eq(str(back.run_log[0]["ending"]), EndingRules.BRIEFLY_ALIVE)
	assert_eq(int(back.run_log[1]["kills"]["intern_reaper"]), 3)
	assert_eq(back.run_log[1]["seeds"], ["abc"])
	assert_eq(back.total("kills"), 6)
	assert_eq(back.total("deaths"), 1)
	assert_eq(back.total("hits"), 8)
	assert_eq(back.total("pension"), 80)
	assert_eq(back.total("items"), 4)
	assert_eq(back.best("time"), 321)
	assert_eq(back.best("items"), 2)
	assert_eq(int(back.items_seen["kettle"]), 4)
	assert_eq(int(back.enemies_seen["intern_reaper"]), 6)
	assert_true(back.enemies_seen.has("matron_mercy"), "met without a kill still shows")
	assert_eq(back.to_dict(), data.to_dict(), "nothing changes on a second trip")


func test_only_a_last_floor_clear_counts_as_a_win() -> void:
	var data := ProgressData.new()
	data.record_run(_entry(1, RunLog.CLEARED))
	assert_eq(data.total("wins"), 0, "a floor-2 clear is no win")
	var won := _entry(2, RunLog.CLEARED)
	won["depth"] = ProgressData.LAST_DEPTH
	data.record_run(won)
	assert_eq(data.total("wins"), 1)
	assert_eq(data.best("depth"), ProgressData.LAST_DEPTH)


func test_the_log_keeps_the_last_fifty_runs() -> void:
	var data := ProgressData.new()
	for n in RunLog.CAP + 7:
		data.record_run(_entry(n + 1))
	assert_eq(data.run_log.size(), RunLog.CAP)
	assert_eq(int(data.run_log[0]["n"]), RunLog.CAP + 7)
	assert_eq(int(data.run_log[RunLog.CAP - 1]["n"]), 8, "the oldest dropped off")
	assert_eq(data.total("kills"), 3 * (RunLog.CAP + 7), "totals still count every run")
	var raw := data.to_dict()
	for n in 10:
		raw["run_log"].append(_entry(100 + n))
	assert_eq(ProgressData.from_dict(raw).run_log.size(), RunLog.CAP, "a longer saved log is cut on load")


func test_damaged_history_reads_as_empty_not_as_a_broken_save() -> void:
	var raw := _fixture_raw()
	raw["run_log"] = ["junk", 4, {"n": "x", "kills": {"a": "b"}, "items": [1, "kettle"]}]
	raw["lifetime"] = "nope"
	raw["items_seen"] = {"kettle": "many", "rolling_pin": 2}
	var data := ProgressData.from_dict(raw)
	assert_true(data != null, "the save still loads")
	assert_eq(data.run_log.size(), 1)
	assert_eq(data.run_log[0]["items"], ["kettle"])
	assert_eq(data.run_log[0]["kills"], {})
	assert_eq(data.total("kills"), 0)
	assert_false(data.items_seen.has("kettle"), "a count that is no number is dropped")
	assert_eq(int(data.items_seen["rolling_pin"]), 2)


func _plain_run() -> RunState:
	var none: Array[UpgradeDef] = []
	return RunState.new(none, {})


func test_a_run_tallies_its_kills_finds_and_hits_and_the_checkpoint_keeps_them() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	run.note_met("mall_cop")
	run.note_kill("intern_reaper")
	run.note_kill("intern_reaper")
	run.hits_taken = 3
	run.seeds.append("seed-1")
	run.add_item(ItemKit.item(Content.items()[0].id))
	assert_eq(run.kill_count(), 2)
	assert_true(run.met.has("mall_cop") and run.met.has("intern_reaper"))
	assert_eq(run.found, [Content.items()[0].id] as Array[String])
	var back := _plain_run()
	RunCheckpoint.apply_ending(back, JSON.parse_string(JSON.stringify(RunCheckpoint.ending_to_dict(run))))
	assert_eq(back.kills, {"intern_reaper": 2})
	assert_true(back.met.has("mall_cop"))
	assert_eq(back.found, run.found)
	assert_eq(back.hits_taken, 3)
	assert_eq(back.seeds, ["seed-1"] as Array[String])
	var entry := RunLog.entry(run, {"n": 9, "result": RunLog.DIED, "depth": 1, "killer": "Filing Clerk"})
	assert_eq(RunLog.kill_total(entry), 2)
	assert_eq(entry["items"], [Content.items()[0].id])
	assert_true(RunLog.headline(entry).contains("Run 9"))
	assert_true(RunLog.outcome(entry).contains("Filing Clerk"))


func test_an_older_checkpoint_without_a_tally_resumes_with_an_empty_one() -> void:
	var run := _plain_run()
	RunCheckpoint.apply_ending(run, {"play_time": 12.0, "pension_earned": 5})
	assert_eq(run.kills, {})
	assert_eq(run.found.size(), 0)
	assert_eq(run.hits_taken, 0)


func test_every_outcome_reads_in_plain_words() -> void:
	var entry := RunLog.clean({"n": 3, "result": RunLog.CLEARED, "depth": 5, "ending": EndingRules.BRIEFLY_ALIVE})
	assert_eq(RunLog.outcome(entry), "Ending: Briefly Alive")
	assert_eq(RunLog.outcome(RunLog.clean({"result": RunLog.ABANDONED, "depth": 3})), "Abandoned on floor 3")
	assert_eq(RunLog.outcome(RunLog.clean({"result": RunLog.DIED, "depth": 2})), "Died on floor 2")
	assert_eq(RunLog.outcome(RunLog.clean({})), "Ended on floor 1")
