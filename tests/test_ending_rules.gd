extends TestCase


# A run that meets no ending's condition: it lost a pill to the Chairman, took its time, earned little,
# carried little, played no tables, was not cursed, had pills to spare and took the west path.
func _plain() -> Dictionary:
	return {
		"pills": 3,
		"lost_pill_in_boss_room": true,
		"play_time": EndingRules.FAST_RUN_SECONDS + 600.0,
		"pension_earned": 100,
		"items": 2,
		"arcade_visits_won": 0,
		"cursed": false,
		"paths": {1: "floor_1", 2: "sunset_shores", 3: "funeral_parlour", 4: "last_resort_cruise", 5: "head_office"},
	}


func _with(key: String, value: Variant) -> Dictionary:
	var snap := _plain()
	snap[key] = value
	return snap


func _found(ids: Array) -> Dictionary:
	var found := {}
	for id in ids:
		found[id] = true
	return found


func test_a_plain_run_is_briefly_alive() -> void:
	assert_eq(EndingRules.choose(_plain(), {}), EndingRules.BRIEFLY_ALIVE)


func test_no_pill_lost_to_the_chairman_is_new_management() -> void:
	assert_eq(EndingRules.choose(_with("lost_pill_in_boss_room", false), {}), EndingRules.NEW_MANAGEMENT)


func test_a_fast_run_crashes_the_funeral() -> void:
	assert_eq(EndingRules.choose(_with("play_time", EndingRules.FAST_RUN_SECONDS), {}), EndingRules.CRASHING_THE_FUNERAL)
	assert_eq(EndingRules.choose(_with("play_time", EndingRules.FAST_RUN_SECONDS + 0.5), {}), EndingRules.BRIEFLY_ALIVE)


func test_a_rich_run_is_fortune_and_glory() -> void:
	assert_eq(EndingRules.choose(_with("pension_earned", EndingRules.FORTUNE_PENSION), {}), EndingRules.FORTUNE_AND_GLORY)
	assert_eq(EndingRules.choose(_with("pension_earned", EndingRules.FORTUNE_PENSION - 1), {}), EndingRules.BRIEFLY_ALIVE)


func test_a_full_bag_is_excess_baggage() -> void:
	assert_eq(EndingRules.choose(_with("items", EndingRules.BAGGAGE_ITEMS), {}), EndingRules.EXCESS_BAGGAGE)
	assert_eq(EndingRules.choose(_with("items", EndingRules.BAGGAGE_ITEMS - 1), {}), EndingRules.BRIEFLY_ALIVE)


func test_three_won_table_visits_are_the_house_always_wins() -> void:
	assert_eq(EndingRules.choose(_with("arcade_visits_won", EndingRules.TABLE_VISITS), {}), EndingRules.HOUSE_ALWAYS_WINS)
	assert_eq(EndingRules.choose(_with("arcade_visits_won", EndingRules.TABLE_VISITS - 1), {}), EndingRules.BRIEFLY_ALIVE)


func test_a_cursed_ticket_is_literally() -> void:
	assert_eq(EndingRules.choose(_with("cursed", true), {}), EndingRules.LITERALLY)


func test_one_pill_left_is_by_a_thread() -> void:
	assert_eq(EndingRules.choose(_with("pills", 1), {}), EndingRules.BY_A_THREAD)
	assert_eq(EndingRules.choose(_with("pills", 2), {}), EndingRules.BRIEFLY_ALIVE)


func test_the_east_path_at_every_depth_is_the_scenic_route() -> void:
	assert_eq(EndingRules.choose(_with("paths", EndingRules.SCENIC_PATHS.duplicate()), {}), EndingRules.SCENIC_ROUTE)
	var nearly: Dictionary = EndingRules.SCENIC_PATHS.duplicate()
	nearly[3] = "funeral_parlour"
	assert_eq(EndingRules.choose(_with("paths", nearly), {}), EndingRules.BRIEFLY_ALIVE)
	assert_eq(EndingRules.choose(_with("paths", {}), {}), EndingRules.BRIEFLY_ALIVE, "a snapshot with no paths")


func test_the_table_order_decides_among_several() -> void:
	var snap := _plain()
	snap["pills"] = 1
	snap["cursed"] = true
	snap["items"] = EndingRules.BAGGAGE_ITEMS
	assert_eq(EndingRules.choose(snap, {}), EndingRules.EXCESS_BAGGAGE)
	snap["lost_pill_in_boss_room"] = false
	assert_eq(EndingRules.choose(snap, {}), EndingRules.NEW_MANAGEMENT)


func test_an_ending_not_yet_found_wins_over_one_found() -> void:
	var snap := _plain()
	snap["pills"] = 1
	snap["cursed"] = true
	assert_eq(EndingRules.choose(snap, _found([EndingRules.LITERALLY])), EndingRules.BY_A_THREAD)
	assert_eq(EndingRules.choose(snap, _found([EndingRules.LITERALLY, EndingRules.BY_A_THREAD])), EndingRules.BRIEFLY_ALIVE)


func test_when_all_that_hold_are_found_the_first_plays_again() -> void:
	var snap := _plain()
	snap["pills"] = 1
	snap["cursed"] = true
	var found := _found([EndingRules.LITERALLY, EndingRules.BY_A_THREAD, EndingRules.BRIEFLY_ALIVE])
	assert_eq(EndingRules.choose(snap, found), EndingRules.LITERALLY)
	assert_eq(EndingRules.choose(_plain(), _found([EndingRules.BRIEFLY_ALIVE])), EndingRules.BRIEFLY_ALIVE)


func test_eternal_feud_is_due_at_five_of_endings_two_to_nine() -> void:
	var four := _found([EndingRules.NEW_MANAGEMENT, EndingRules.LITERALLY, EndingRules.BY_A_THREAD, EndingRules.SCENIC_ROUTE, EndingRules.BRIEFLY_ALIVE])
	assert_eq(EndingRules.choose(_plain(), four), EndingRules.BRIEFLY_ALIVE, "Briefly Alive does not count")
	var five := four.duplicate()
	five[EndingRules.EXCESS_BAGGAGE] = true
	assert_eq(EndingRules.choose(_plain(), five), EndingRules.ETERNAL_FEUD)
	# It outranks an unfound ending that also holds.
	assert_eq(EndingRules.choose(_with("pills", 1).merged({"cursed": false}), five), EndingRules.ETERNAL_FEUD)


func test_eternal_feud_plays_once() -> void:
	var found := _found([EndingRules.NEW_MANAGEMENT, EndingRules.LITERALLY, EndingRules.BY_A_THREAD, EndingRules.SCENIC_ROUTE, EndingRules.EXCESS_BAGGAGE, EndingRules.ETERNAL_FEUD])
	assert_false(EndingRules.holds(EndingRules.ETERNAL_FEUD, _plain(), found))
	assert_true(EndingRules.choose(_plain(), found) != EndingRules.ETERNAL_FEUD)


func test_after_the_feud_repeat_customer_replaces_briefly_alive() -> void:
	var found := _found([EndingRules.NEW_MANAGEMENT, EndingRules.LITERALLY, EndingRules.BY_A_THREAD, EndingRules.SCENIC_ROUTE, EndingRules.EXCESS_BAGGAGE, EndingRules.ETERNAL_FEUD])
	assert_eq(EndingRules.choose(_plain(), found), EndingRules.REPEAT_CUSTOMER)
	assert_false(EndingRules.holds(EndingRules.BRIEFLY_ALIVE, _plain(), found))
	# An unfound ending 2 to 9 still wins first.
	assert_eq(EndingRules.choose(_with("arcade_visits_won", 3), found), EndingRules.HOUSE_ALWAYS_WINS)
	# A found one gives way to the quick death, found or not.
	assert_eq(EndingRules.choose(_with("pills", 1), found), EndingRules.REPEAT_CUSTOMER)
	found[EndingRules.REPEAT_CUSTOMER] = true
	assert_eq(EndingRules.choose(_with("pills", 1), found), EndingRules.REPEAT_CUSTOMER)


func test_repeat_customer_never_holds_before_the_feud() -> void:
	assert_false(EndingRules.holds(EndingRules.REPEAT_CUSTOMER, _plain(), {}))


func test_a_quick_death_never_comes_twice_in_a_row() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var seen := {}
	var last := 0
	for i in 1000:
		var next := EndingRules.pick_repeat_death(last, rng.randf())
		assert_true(next >= 1 and next <= EndingRules.REPEAT_DEATHS, "in range: %d" % next)
		assert_true(next != last, "not twice in a row")
		seen[next] = true
		last = next
	assert_eq(seen.size(), EndingRules.REPEAT_DEATHS, "every death comes up")
	for last_death in range(0, EndingRules.REPEAT_DEATHS + 1):
		for roll: float in [0.0, 0.5, 0.999999]:
			var picked := EndingRules.pick_repeat_death(last_death, roll)
			assert_true(picked >= 1 and picked <= EndingRules.REPEAT_DEATHS and picked != last_death, "%d %f" % [last_death, roll])


func test_the_archive_lists_eleven_numbered_endings() -> void:
	assert_eq(EndingRules.ALL.size(), EndingRules.TOTAL)
	assert_eq(EndingRules.TOTAL, 11)
	for i in EndingRules.ALL.size():
		var entry: Dictionary = EndingRules.ALL[i]
		assert_eq(int(entry["number"]), i + 1)
		assert_true(str(entry["title"]).length() > 0 and str(entry["cause"]).begins_with("Cause of death"), entry["id"])
		assert_true(EndingRules.ORDER.has(entry["id"]), entry["id"])
	assert_eq(EndingRules.ORDER.size(), EndingRules.TOTAL)
	assert_eq(EndingRules.entry(EndingRules.LITERALLY)["cause"], "Cause of death: pest control.")
	assert_eq(EndingRules.entry(EndingRules.ETERNAL_FEUD)["hint"], "Find five other files.")


func test_the_found_count_counts_only_real_endings() -> void:
	assert_eq(EndingRules.found_count({}), 0)
	assert_eq(EndingRules.found_count(_found([EndingRules.BRIEFLY_ALIVE, EndingRules.REPEAT_CUSTOMER, "nonsense"])), 2)


func test_a_quick_death_has_its_own_card() -> void:
	var cards := {}
	for n in range(1, EndingRules.REPEAT_DEATHS + 1):
		var card := EndingRules.repeat_cause(n)
		assert_true(card.begins_with("Cause of death: "), card)
		cards[card] = true
	assert_eq(cards.size(), EndingRules.REPEAT_DEATHS)
	assert_eq(EndingRules.repeat_cause(5), "Cause of death: daytime television.")
