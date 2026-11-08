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


func test_a_deal_with_every_form_maxed_calls_nothing_but_sees_the_number() -> void:
	var data := ProgressData.new()
	for def in Content.upgrades():
		data.upgrades[def.id] = def.max_level()
	data.run_count = 5
	data.ticket_called = 4
	assert_eq(data.call_ticket(Content.upgrades(), 0.5), "")
	assert_eq(data.ticket_called, 5, "the number is seen all the same")


func test_the_other_events_and_plain_numbers_are_called_once() -> void:
	var data := ProgressData.new()
	data.run_count = 10
	data.ticket_called = 9
	assert_eq(data.call_ticket(Content.upgrades(), 0.0), TicketRules.NEW_ARRIVAL)
	assert_eq(data.call_ticket(Content.upgrades(), 0.0), "", "a number is called once")
	data.run_count = 16
	assert_eq(data.call_ticket(Content.upgrades(), 0.0), "", "16 is not a called number")


# --- the lobby's sign: NOW SERVING, and the served moment after an ending ---

# A run that reached an ending (FloorScene._play_ending records it before its scene plays).
func _finish_with_ending(data: ProgressData) -> void:
	data.start_run()
	data.record_ending(EndingRules.BRIEFLY_ALIVE)


func test_a_finished_run_is_served_exactly_once() -> void:
	var data := ProgressData.new()
	assert_false(data.serve_pending(), "a fresh save has nothing to serve")
	_finish_with_ending(data)
	assert_eq(data.run_count, 1)
	assert_true(data.serve_pending(), "an ending puts his number up")
	assert_true(data.take_serving(), "the first return serves it")
	assert_false(data.take_serving(), "and never again")
	var again := ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))
	assert_false(again.serve_pending(), "not after a reload either")
	assert_false(again.take_serving())


func test_a_found_ending_found_again_is_served_too() -> void:
	var data := ProgressData.new()
	_finish_with_ending(data)
	assert_true(data.take_serving())
	_finish_with_ending(data)
	assert_eq(data.record_ending(EndingRules.BRIEFLY_ALIVE), 0, "nothing paid the second time")
	assert_true(data.take_serving(), "every finished run is served once")


func test_a_death_is_never_served() -> void:
	var data := ProgressData.new()
	data.start_run()
	assert_false(data.serve_pending(), "a run that died reached no ending")
	assert_false(data.take_serving())
	_finish_with_ending(data)
	data.start_run()
	assert_false(data.serve_pending(), "a finished run not served before the next one started lapses")
	assert_false(data.take_serving())


# Quitting after the ending scene, before the Waiting Room loads, still serves it on the next load.
func test_a_pending_serving_survives_a_reload() -> void:
	var data := ProgressData.new()
	_finish_with_ending(data)
	var again := ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))
	assert_true(again.take_serving())


func test_an_old_save_has_nothing_to_serve() -> void:
	var data := ProgressData.from_dict({"version": 1, "pension": 0, "upgrades": {}, "opening_seen": true, "run_count": 15})
	assert_false(data.serve_pending())


# The scene names autoloads, so a test cannot load it. These pin that it serves through Progress, once,
# with a ding and the notice, and that the sign is drawn from that.
func test_the_waiting_room_serves_the_finished_run_with_a_ding() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/waiting_room.gd")
	var rule := source.substr(source.find("func _serve_finished_run"), 300)
	assert_true(rule.contains("Progress.take_serving()"))
	assert_true(rule.contains("Sfx.play_later(\"ticket_ding\""))
	assert_true(rule.contains("LobbyText.SERVED_NOTICE"))
	assert_true(source.contains("_lobby_text.show_text(Progress.data.run_count, hint, _served)"))
	assert_false(source.contains("NOT_CALLED"))
	assert_true(ResourceLoader.exists("res://audio/sfx/ticket_ding.wav"), "the ding is a sound already in the game")


# A new game counts from the beginning: a new slot, a slot deleted, or New Game on a slot that had
# runs, all through SaveSlots as Progress.clear_slot and Game.new_game use it.
func test_a_new_save_counts_from_the_beginning() -> void:
	var root := OS.get_temp_dir().path_join("grandpa_test_ticket_slots") + "/"
	SaveSlots.delete_slot(root, 2)
	var fresh := SaveStore.new(SaveSlots.save_path(root, 2)).load_progress()
	_assert_counts_from_start(fresh, "a new slot")
	var played := ProgressData.new()
	for _i in 41:
		played.start_run()
	played.record_ending(EndingRules.BRIEFLY_ALIVE)
	assert_true(SaveStore.new(SaveSlots.save_path(root, 2)).save_progress(played))
	assert_eq(SaveSlots.load_data(root, 2).run_count, 41, "the slot had runs")
	SaveSlots.delete_slot(root, 2)
	var restarted := SaveStore.new(SaveSlots.save_path(root, 2)).load_progress()
	_assert_counts_from_start(restarted, "a slot deleted and started again")
	assert_true(SaveSlots.summary(root, 2)["empty"])
	_assert_counts_from_start(ProgressData.new(), "a bare ProgressData")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSlots.slot_dir(root, 2)))
	DirAccess.remove_absolute(root)
	# New Game empties the slot (Progress.clear_slot -> SaveSlots.delete_slot) before selecting it.
	var game := FileAccess.get_file_as_string("res://scripts/autoload/game.gd")
	var new_game := game.substr(game.find("func new_game"), 200)
	assert_true(new_game.find("Progress.clear_slot(slot)") >= 0 and new_game.find("Progress.clear_slot(slot)") < new_game.find("Progress.select_slot(slot)"))
	var progress := FileAccess.get_file_as_string("res://scripts/autoload/progress.gd")
	assert_true(progress.substr(progress.find("func clear_slot"), 300).contains("SaveSlots.delete_slot(ROOT, number)"))


func _assert_counts_from_start(data: ProgressData, what: String) -> void:
	assert_eq(data.run_count, 0, what)
	assert_false(data.serve_pending(), what)
	var text := LobbyText.new()
	text.show_text(data.run_count, "", data.serve_pending())
	assert_eq(text.ticket_line(), "YOUR TICKET: 001   NOW SERVING: 000", what)
	text.free()


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


# --- letters ---

func test_a_letter_arrives_with_each_floors_first_clear() -> void:
	var data := ProgressData.new()
	assert_eq(LetterBook.arrived(data).size(), 0)
	data.record_floor_cleared(1, "floor_1")
	assert_eq(LetterBook.arrived(data).size(), 1)
	data.record_floor_cleared(1, "floor_1")
	assert_eq(LetterBook.arrived(data).size(), 1, "one per floor, not per clear")


func test_reading_a_letter_marks_it() -> void:
	var data := ProgressData.new()
	data.record_floor_cleared(1, "floor_1")
	assert_eq(LetterBook.unread(data).size(), 1)
	assert_true(NoticeboardPanel.row_text(LetterBook.arrived(data)[0], data).begins_with(NoticeboardPanel.NEW_MARK))
	data.read_letter("floor_1")
	assert_eq(LetterBook.unread(data).size(), 0)
	assert_false(NoticeboardPanel.row_text(LetterBook.arrived(data)[0], data).begins_with(NoticeboardPanel.NEW_MARK))


func test_every_path_has_a_letter() -> void:
	var paths := LetterBook.LETTERS.map(func(l): return l["path"])
	assert_eq(paths.size(), 10)
	for id in ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "flashback_cinema", "last_resort_cruise", "seance_hotline", "terminal_zero", "head_office"]:
		assert_true(paths.has(id), id)


func test_letters_read_survive_a_save() -> void:
	var data := ProgressData.new()
	data.record_floor_cleared(1, "floor_1")
	data.read_letter("floor_1")
	var again := ProgressData.from_dict(data.to_dict())
	assert_eq(LetterBook.unread(again).size(), 0)


# --- the ticket machine ---

func test_the_machine_shows_the_next_number_and_the_deal() -> void:
	var data := ProgressData.new()
	data.run_count = 4
	var lines := TicketPanel.lines_for(data, Content.upgrades())
	assert_eq(lines[0], "Your ticket: 5")
	assert_eq(lines.size(), 2)
	data.clerk_deal = "reinforced_cane"
	data.cursed_offer = true
	lines = TicketPanel.lines_for(data, Content.upgrades())
	assert_true(lines.has("Deal of the visit: Reinforced Cane 25% off"), str(lines))
	assert_true(lines.has(TicketPanel.CURSED_TEXT))


func test_the_ticket_machine_and_noticeboard_stand_in_the_lobby() -> void:
	for id in ["ticket_machine", "noticeboard"]:
		assert_eq(Departments.station_entry(id).get("department", ""), Departments.LOBBY, id)


func test_the_arrival_speakers_stand_in_real_departments() -> void:
	for id in TicketRules.ARRIVAL_DEPARTMENTS:
		assert_true(Departments.index_of(id) >= 0, id)


# An old save counts its past tickets as called, so a run_count on a called number fires nothing.
func test_an_old_save_on_a_called_number_fires_nothing() -> void:
	var data := ProgressData.from_dict({"version": 1, "pension": 0, "upgrades": {}, "opening_seen": true, "run_count": 15})
	assert_eq(TicketRules.event_for(15), TicketRules.CURSED_OFFER, "15 is a called number")
	assert_eq(data.call_ticket(Content.upgrades(), 0.0), "")
	assert_false(data.cursed_offer)


func test_a_called_ticket_stays_called_through_a_save() -> void:
	var data := ProgressData.new()
	data.run_count = 15
	data.ticket_called = 14
	assert_eq(data.call_ticket(Content.upgrades(), 0.0), TicketRules.CURSED_OFFER)
	var again := ProgressData.from_dict(JSON.parse_string(JSON.stringify(data.to_dict())))
	assert_eq(again.call_ticket(Content.upgrades(), 0.0), "", "not called again after a reload")
	assert_true(again.cursed_offer)
