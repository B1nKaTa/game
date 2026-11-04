extends TestCase


func _floors() -> Dictionary:
	var floors := {}
	for id in ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "golden_years_mall"]:
		floors[id] = load("res://data/floors/%s.tres" % id)
	return floors


func _poster(id: String) -> BountyDef:
	for def in BountyBoard.all():
		if def.id == id:
			return def
	return null


func _run() -> RunState:
	var empty: Array[UpgradeDef] = []
	return RunState.new(empty, {})


# A poster's id is its boss's EnemyDef id, which ProgressData.record_boss_beaten relies on.
func test_there_is_a_poster_for_every_mini_and_floor_boss() -> void:
	var floors := _floors()
	var wanted := {}
	for id in floors:
		wanted[(floors[id] as FloorDef).mini_boss.id] = id
		wanted[(floors[id] as FloorDef).floor_boss.id] = id
	assert_eq(BountyBoard.all().size(), 12)
	for def in BountyBoard.all():
		assert_eq(wanted.get(def.id, ""), def.floor_id, def.id)
		var floor_def: FloorDef = floors[def.floor_id]
		assert_eq(def.depth, floor_def.depth, def.id)
		assert_eq(def.floor_boss, floor_def.floor_boss.id == def.id, def.id)


func test_the_rewards_follow_the_depth() -> void:
	for def in BountyBoard.all():
		assert_eq(def.pension, (100 if def.floor_boss else 40) * def.depth, def.id)
		assert_eq(def.condolences, 20 if def.floor_boss else 10, def.id)


func test_the_extras_are_four_of_each_kind_and_all_real() -> void:
	var counts := {}
	for def in BountyBoard.all():
		counts[def.extra_kind] = counts.get(def.extra_kind, 0) + 1
		if def.extra_kind == BountyDef.EXTRA_RECIPE:
			assert_true(Content.recipes().any(func(i): return i.id == def.extra_id), def.id)
		if def.extra_kind == BountyDef.EXTRA_ITEM:
			assert_true(Content.items().any(func(i): return i.id == def.extra_id and i.from_bounty), def.id)
	assert_eq(counts, {BountyDef.EXTRA_ITEM: 4, BountyDef.EXTRA_RECIPE: 4, BountyDef.EXTRA_COSMETIC: 4})


func test_a_fresh_save_sees_only_the_first_floors_posters() -> void:
	var ids := BountyBoard.posters(BountyBoard.all(), _floors(), ProgressData.new()).map(func(d): return d.id)
	assert_eq(ids.size(), 2)
	assert_true(ids.has("senior_adjuster") and ids.has("regional_reaper"))


func test_a_first_clear_shows_the_cemetery_and_the_second_floor() -> void:
	var data := ProgressData.new()
	data.record_floor_cleared(1, "floor_1")
	var ids := BountyBoard.posters(BountyBoard.all(), _floors(), data).map(func(d): return d.id)
	assert_true(ids.has("head_groundskeeper"), "the Cemetery opens on one clear")
	assert_true(ids.has("matron_mercy"), "Sunset Shores is reachable")
	assert_false(ids.has("old_smokey"), "the Furnace Works waits for a second-floor clear")
	assert_false(ids.has("reverend"), "the third floor waits for a second-floor clear")


func test_one_poster_at_a_time_and_it_stays_through_runs() -> void:
	var data := ProgressData.new()
	assert_true(BountyBoard.take(_poster("senior_adjuster"), data))
	assert_false(BountyBoard.can_take(_poster("regional_reaper"), data))
	data.start_run()
	assert_eq(data.bounty_taken, "senior_adjuster")
	var again := ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))
	assert_eq(again.bounty_taken, "senior_adjuster", "survives a save")


func test_beating_the_boss_then_collecting_pays_and_retires() -> void:
	var data := ProgressData.new()
	var poster := _poster("senior_adjuster")
	BountyBoard.take(poster, data)
	assert_false(BountyBoard.can_collect(poster, data))
	data.record_boss_beaten("senior_adjuster", false)
	assert_true(BountyBoard.can_collect(poster, data))
	var paid := BountyBoard.collect(poster, data)
	assert_eq(paid["pension"], 40)
	assert_eq(data.pension, 40)
	assert_eq(data.condolences, ProgressData.FIRST_MINI_BOSS_CONDOLENCES + 10)
	assert_true(data.has_recipe("support_stockings"))
	assert_eq(data.bounty_taken, "")
	assert_false(BountyBoard.can_take(poster, data), "retired for good")
	assert_false(BountyBoard.posters(BountyBoard.all(), _floors(), data).has(poster))


func test_a_win_before_taking_the_poster_does_not_count() -> void:
	var data := ProgressData.new()
	data.record_boss_beaten("senior_adjuster", false)
	BountyBoard.take(_poster("senior_adjuster"), data)
	assert_false(BountyBoard.can_collect(_poster("senior_adjuster"), data))


# record_boss_beaten returns early for a boss already beaten, and the win must be marked before that.
func test_a_poster_for_a_boss_beaten_before_can_still_be_won() -> void:
	var data := ProgressData.new()
	data.record_boss_beaten("senior_adjuster", false)
	var poster := _poster("senior_adjuster")
	BountyBoard.take(poster, data)
	assert_eq(data.record_boss_beaten("senior_adjuster", false), 0, "no second first-beat payment")
	assert_true(BountyBoard.can_collect(poster, data))


func test_beating_another_boss_does_not_win_the_poster() -> void:
	var data := ProgressData.new()
	var poster := _poster("senior_adjuster")
	BountyBoard.take(poster, data)
	data.record_boss_beaten("regional_reaper", true)
	assert_false(BountyBoard.can_collect(poster, data))


func test_a_recipe_already_found_pays_half_again_instead() -> void:
	var data := ProgressData.new()
	data.find_recipe("support_stockings")
	var poster := _poster("senior_adjuster")
	BountyBoard.take(poster, data)
	data.record_boss_beaten("senior_adjuster", false)
	var paid := BountyBoard.collect(poster, data)
	assert_false(paid["extra_was_new"])
	assert_eq(paid["pension"], 60)


func test_collecting_an_item_poster_unlocks_the_item() -> void:
	var data := ProgressData.new()
	var poster := _poster("tired_undertaker")
	BountyBoard.take(poster, data)
	data.record_boss_beaten("tired_undertaker", true)
	var paid := BountyBoard.collect(poster, data)
	assert_true(paid["extra_was_new"])
	assert_true(data.is_unlocked("undertakers_gloves"))


func test_collecting_a_cosmetic_poster_owns_the_cosmetic() -> void:
	var data := ProgressData.new()
	var poster := _poster("regional_reaper")
	BountyBoard.take(poster, data)
	data.record_boss_beaten("regional_reaper", true)
	BountyBoard.collect(poster, data)
	assert_true(data.cosmetics_owned.has("reaper_hood"))


func test_a_won_item_joins_the_pool_only_once_won() -> void:
	var gloves: ItemDef = load("res://data/items/undertakers_gloves.tres")
	var run := _run()
	assert_false(run.can_offer(gloves))
	run.unlocked_items = {"undertakers_gloves": true}
	assert_true(run.can_offer(gloves))


func test_the_extra_text_names_what_the_poster_pays() -> void:
	assert_eq(BountyPanel.extra_text(_poster("senior_adjuster")), "a recipe for Agnes")
	assert_eq(BountyPanel.extra_text(_poster("tired_undertaker")), "a unique item")
	assert_eq(BountyPanel.extra_text(_poster("regional_reaper")), "something to wear")


func test_a_row_names_the_boss_and_the_whole_reward() -> void:
	assert_eq(BountyPanel.row_text(_poster("senior_adjuster")), "WANTED: Senior Adjuster  40 Pension, 10 Condolences, + a recipe for Agnes")


func test_each_poster_button_says_what_it_does() -> void:
	var data := ProgressData.new()
	var adjuster := _poster("senior_adjuster")
	var reaper := _poster("regional_reaper")
	assert_eq(BountyPanel.button_text(adjuster, data), BountyPanel.TAKE)
	BountyBoard.take(adjuster, data)
	assert_eq(BountyPanel.button_text(adjuster, data), BountyPanel.TAKEN)
	assert_eq(BountyPanel.button_text(reaper, data), BountyPanel.ONE_AT_A_TIME)
	data.record_boss_beaten("senior_adjuster", false)
	assert_eq(BountyPanel.button_text(adjuster, data), BountyPanel.COLLECT)


func test_the_paid_notice_names_the_extra() -> void:
	var paid := {"pension": 40, "condolences": 10, "extra_kind": BountyDef.EXTRA_RECIPE, "extra_id": "support_stockings", "extra_was_new": true}
	assert_eq(BountyPanel.paid_text(_poster("senior_adjuster"), paid), "Paid: 40 Pension, 10 Condolences, and a recipe for Agnes")


func test_the_board_shows_what_the_fresh_save_can_reach() -> void:
	assert_eq(BountyBoard.showing(ProgressData.new()).size(), 2)
