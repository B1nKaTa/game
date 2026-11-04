extends TestCase


func _run() -> RunState:
	var empty: Array[UpgradeDef] = []
	return RunState.new(empty, {})


# --- the queue ticket ---

func test_every_fifth_ticket_is_called_and_the_events_cycle() -> void:
	assert_eq(TicketRules.event_for(0), "")
	assert_eq(TicketRules.event_for(4), "")
	assert_eq(TicketRules.event_for(5), TicketRules.CLERK_DEAL)
	assert_eq(TicketRules.event_for(10), TicketRules.NEW_ARRIVAL)
	assert_eq(TicketRules.event_for(15), TicketRules.CURSED_OFFER)
	assert_eq(TicketRules.event_for(20), TicketRules.CLERK_DEAL)
	assert_eq(TicketRules.event_for(30), TicketRules.CURSED_OFFER)


func test_a_ticket_is_called_once() -> void:
	var data := ProgressData.new()
	data.run_count = 5
	data.ticket_called = 4
	assert_eq(data.call_ticket(Content.upgrades(), 0.0), TicketRules.CLERK_DEAL)
	assert_false(data.clerk_deal.is_empty())
	assert_eq(data.ticket_called, 5)
	assert_eq(data.call_ticket(Content.upgrades(), 0.0), "")


func test_a_number_not_called_sets_nothing() -> void:
	var data := ProgressData.new()
	data.run_count = 7
	data.ticket_called = 6
	assert_eq(data.call_ticket(Content.upgrades(), 0.0), "")
	assert_eq(data.ticket_called, 7, "counted as seen all the same")
	assert_eq(data.clerk_deal, "")
	assert_false(data.cursed_offer)


func test_an_old_save_counts_every_past_ticket_as_called() -> void:
	var data := ProgressData.from_dict({"version": 1, "pension": 0, "upgrades": {}, "opening_seen": true, "run_count": 15})
	assert_eq(data.ticket_called, 15)
	assert_eq(data.call_ticket(Content.upgrades(), 0.0), "", "nothing fires back-dated")


func test_the_deal_takes_a_quarter_off_one_form_for_one_visit() -> void:
	var data := ProgressData.new()
	var cane: UpgradeDef = null
	for def in Content.upgrades():
		if def.id == "reinforced_cane":
			cane = def
	var full := data.price_of(cane)
	data.clerk_deal = "reinforced_cane"
	assert_eq(data.price_of(cane), ceili(full * (1.0 - ProgressData.CLERK_DEAL_CUT)))
	data.start_run()
	assert_eq(data.clerk_deal, "")
	assert_eq(data.price_of(cane), full)


func test_the_deal_never_picks_a_maxed_form() -> void:
	var data := ProgressData.new()
	for def in Content.upgrades():
		data.upgrades[def.id] = def.max_level()
	assert_eq(TicketRules.deal_form(Content.upgrades(), data, 0.5), "")
	data.run_count = 5
	assert_eq(data.call_ticket(Content.upgrades(), 0.5), "", "no deal to call with every form filed")


func test_the_deal_picks_among_the_forms_still_open() -> void:
	var data := ProgressData.new()
	var upgrades := Content.upgrades()
	for def in upgrades:
		data.upgrades[def.id] = def.max_level()
	data.upgrades[upgrades[2].id] = 0
	assert_eq(TicketRules.deal_form(upgrades, data, 0.0), upgrades[2].id)
	assert_eq(TicketRules.deal_form(upgrades, data, 0.99), upgrades[2].id)


func test_the_cursed_ticket_is_opt_in_and_lasts_one_run() -> void:
	var data := ProgressData.new()
	assert_false(data.accept_cursed_ticket(), "only when offered")
	data.cursed_offer = true
	assert_true(data.accept_cursed_ticket())
	assert_false(data.cursed_offer)
	assert_true(data.take_cursed_run())
	assert_false(data.take_cursed_run())


func test_a_cursed_offer_lasts_one_visit() -> void:
	var data := ProgressData.new()
	data.run_count = 15
	data.ticket_called = 14
	assert_eq(data.call_ticket(Content.upgrades(), 0.0), TicketRules.CURSED_OFFER)
	assert_true(data.cursed_offer)
	data.start_run()
	assert_false(data.cursed_offer)
	assert_false(data.cursed_next_run, "an offer not taken curses nothing")


func test_a_declined_offer_is_gone() -> void:
	var data := ProgressData.new()
	data.cursed_offer = true
	data.decline_cursed_ticket()
	assert_false(data.accept_cursed_ticket())


func test_a_cursed_run_is_tougher_and_pays_more() -> void:
	var run := _run()
	run.cursed = true
	assert_near(run.enemy_health_mult(), 1.25)
	assert_near(run.enemy_pension_mult(), 1.5)
	assert_near(_run().enemy_health_mult(), 1.0)
	assert_near(_run().enemy_pension_mult(), 1.0)


func test_a_new_arrival_speaks_only_from_an_open_department() -> void:
	assert_eq(TicketRules.ARRIVAL_LINES.size(), TicketRules.ARRIVAL_DEPARTMENTS.size())
	var lobby_only := [Departments.LOBBY, Departments.HALLWAY]
	for i in 10:
		var line := TicketRules.arrival_line(lobby_only, i / 10.0)
		assert_false(line.begins_with("Deputy Dolores") or line.begins_with("Coach Bertram"), line)
		assert_false(line.is_empty())
	assert_eq(TicketRules.arrival_line([], 0.5), "")
	assert_true(TicketRules.arrival_line([Departments.TRAINING_YARD], 0.0).begins_with("Coach Bertram"))
