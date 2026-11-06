extends TestCase


func _floors() -> Dictionary:
	var floors := {}
	for id in ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "flashback_cinema", "last_resort_cruise", "seance_hotline", "terminal_zero", "head_office"]:
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
	assert_eq(BountyBoard.all().size(), 20)
	for def in BountyBoard.all():
		assert_eq(wanted.get(def.id, ""), def.floor_id, def.id)
		var floor_def: FloorDef = floors[def.floor_id]
		assert_eq(def.depth, floor_def.depth, def.id)
		assert_eq(def.floor_boss, floor_def.floor_boss.id == def.id, def.id)


func test_the_rewards_follow_the_depth() -> void:
	for def in BountyBoard.all():
		assert_eq(def.pension, (100 if def.floor_boss else 40) * def.depth, def.id)
		assert_eq(def.condolences, 20 if def.floor_boss else 10, def.id)


func test_the_extras_are_six_items_six_recipes_and_eight_cosmetics_and_all_real() -> void:
	var counts := {}
	for def in BountyBoard.all():
		counts[def.extra_kind] = counts.get(def.extra_kind, 0) + 1
		if def.extra_kind == BountyDef.EXTRA_RECIPE:
			assert_true(Content.recipes().any(func(i): return i.id == def.extra_id), def.id)
		if def.extra_kind == BountyDef.EXTRA_ITEM:
			assert_true(Content.items().any(func(i): return i.id == def.extra_id and i.from_bounty), def.id)
		if def.extra_kind == BountyDef.EXTRA_COSMETIC:
			assert_true(CosmeticDef.find(def.extra_id, CosmeticDef.all()) != null, def.id)
	assert_eq(counts, {BountyDef.EXTRA_ITEM: 12, BountyDef.EXTRA_RECIPE: 6, BountyDef.EXTRA_COSMETIC: 2})


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
	var poster := _poster("old_smokey")
	BountyBoard.take(poster, data)
	data.record_boss_beaten("old_smokey", true)
	BountyBoard.collect(poster, data)
	assert_true(data.cosmetics_owned.has("sooty_cane"))


func test_the_regional_reaper_pays_his_other_scythe_and_his_hood_is_sold() -> void:
	var poster := _poster("regional_reaper")
	assert_eq(poster.extra_kind, BountyDef.EXTRA_ITEM)
	assert_eq(poster.extra_id, "reapers_scythe")
	var hood := CosmeticDef.find("reaper_hood", CosmeticDef.all())
	assert_true(hood.is_sold(), "the hood moved to the Decor Office for Condolences")
	var data := ProgressData.new()
	BountyBoard.take(poster, data)
	data.record_boss_beaten("regional_reaper", true)
	BountyBoard.collect(poster, data)
	assert_true(data.is_unlocked("reapers_scythe"))


func test_a_poster_retired_before_it_paid_an_item_gives_the_item_on_load() -> void:
	var data := ProgressData.new()
	data.bounties_retired = {"regional_reaper": true, "senior_adjuster": true}
	data.cosmetics_owned = {"reaper_hood": true}
	assert_true(BountyBoard.grant_retired_items(BountyBoard.all(), data))
	assert_true(data.is_unlocked("reapers_scythe"))
	assert_true(data.cosmetics_owned.has("reaper_hood"), "the hood he won stays his")
	assert_false(data.is_unlocked("support_stockings"), "a recipe poster unlocks nothing by itself")
	assert_false(BountyBoard.grant_retired_items(BountyBoard.all(), data), "once only")
	var progress := FileAccess.get_file_as_string("res://scripts/autoload/progress.gd")
	assert_true(progress.contains("BountyBoard.grant_retired_items(BountyBoard.all(), data)"), "every load checks")


func test_a_won_item_joins_the_pool_only_once_won() -> void:
	var gloves: ItemDef = load("res://data/items/undertakers_gloves.tres")
	var run := _run()
	assert_false(run.can_offer(gloves))
	run.unlocked_items = {"undertakers_gloves": true}
	assert_true(run.can_offer(gloves))


func test_the_extra_text_names_what_the_poster_pays() -> void:
	assert_eq(BountyPanel.extra_text(_poster("senior_adjuster")), "a recipe for Agnes")
	assert_eq(BountyPanel.extra_text(_poster("tired_undertaker")), "a unique item")
	assert_eq(BountyPanel.extra_text(_poster("old_smokey")), "something to wear")


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


# A save's poster id is any string, and while one is taken no other can be, so an id that matches no
# poster would lock the board for good.
func test_a_taken_poster_with_no_def_is_dropped() -> void:
	var data := ProgressData.new()
	data.bounty_taken = "a_poster_that_is_gone"
	data.bounty_won = true
	assert_true(BountyBoard.drop_unknown_taken(BountyBoard.all(), data))
	assert_eq(data.bounty_taken, "")
	assert_false(data.bounty_won)
	assert_true(BountyBoard.can_take(_poster("regional_reaper"), data), "the board takes posters again")
	data.bounty_taken = "regional_reaper"
	data.bounty_won = true
	assert_false(BountyBoard.drop_unknown_taken(BountyBoard.all(), data), "a real poster stays taken")
	assert_eq(data.bounty_taken, "regional_reaper")
	assert_true(data.bounty_won)


func test_progress_drops_an_unknown_poster_on_load() -> void:
	var path := "user://test_unknown_poster_save.json"
	var store := SaveStore.new(path)
	store.delete_all()
	var saved := ProgressData.new()
	saved.opening_seen = true
	saved.bounty_taken = "a_poster_that_is_gone"
	saved.bounty_won = true
	store.save_progress(saved)
	var progress: Node = load("res://scripts/autoload/progress.gd").new()
	progress._store = store
	progress.reload()
	assert_eq(progress.data.bounty_taken, "")
	assert_false(progress.data.bounty_won)
	progress.free()
	store.delete_all()


# Mini bosses' posters pay a look and floor bosses' an item or a recipe, on the deep floors as above.
func test_the_deep_floors_posters_pay_what_the_spec_says() -> void:
	var wanted := {
		"lorraine": "gravity_boots", "commodore_wellington": "life_jacket",
		"celestine": "lawyers_card", "madame_zara": "lucky_tee",
		"sergeant_wanda": "complaint_form", "augustine": "neck_pillow",
		"doreen": "bureaucrats_stamp", "chairman_of_the_board": "golden_parachute",
	}
	# These mini bosses' posters pay an item now, and the looks they paid moved to the Decor Office.
	var item_posters := ["lorraine", "celestine", "sergeant_wanda", "doreen"]
	for id in wanted:
		var def := _poster(id)
		assert_true(def != null, id)
		if def == null:
			continue
		assert_eq(def.extra_id, wanted[id], id)
		if not item_posters.has(id):
			assert_eq(def.extra_kind == BountyDef.EXTRA_COSMETIC, not def.floor_boss, id)


# The board holds every poster at once, so twenty papers fit it with the taken one marked.
func test_the_cork_board_fits_every_poster() -> void:
	assert_true(PosterBoard.MAX_PAPERS >= BountyBoard.all().size())
	var last := PosterBoard.paper_rect(PosterBoard.MAX_PAPERS - 1)
	var box := Rect2(-PosterBoard.BOARD_SIZE / 2.0, PosterBoard.BOARD_SIZE)
	assert_true(box.encloses(last), str(last))
