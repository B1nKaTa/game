extends TestCase

# The Flashback Cinema's lobby cards: their 40 lines, the once-a-run rule picked by the run's seed, the
# save's life_signs_seen, and the card that shows a line while Harold stands near it.

const SPEC_LINES := [
	"1974. The hedge went up. Gerald says it's on his side. It isn't.",
	"Biscuit, every morning at seven. Same bench. Same pigeon. Neither of them ever won.",
	"Forty-one years at the depot. One clock. He was never late. The clock was.",
]


func _texts() -> Array[String]:
	var texts: Array[String] = []
	for line in LifeSigns.ALL:
		texts.append(line["text"])
	return texts


# --- the writing ---

func test_there_are_forty_lines_each_its_own() -> void:
	assert_eq(LifeSigns.ALL.size(), 40)
	var ids := {}
	var texts := {}
	for line in LifeSigns.ALL:
		var id: String = line["id"]
		var text: String = line["text"]
		assert_false(ids.has(id), "%s twice" % id)
		assert_false(texts.has(text), "a line twice: %s" % text)
		ids[id] = true
		texts[text] = true
		assert_true(id.is_valid_identifier() and id == id.to_lower(), id)
		assert_true(text.length() >= 30 and text.length() <= 120, "%s: %d letters" % [id, text.length()])
		assert_eq(LifeSigns.text_of(id), text)
	assert_eq(LifeSigns.text_of("no_such_line"), "")


func test_the_specs_three_lines_are_there_word_for_word() -> void:
	var texts := _texts()
	for line in SPEC_LINES:
		assert_true(texts.has(line), line)


func test_the_lines_are_about_gerald_biscuit_the_depot_and_small_things() -> void:
	var counts := {"Gerald": 0, "Biscuit": 0, "work": 0}
	for text in _texts():
		for topic in ["Gerald", "Biscuit"]:
			if text.contains(topic):
				counts[topic] += 1
		for word in ["depot", "bus", "foreman", "retired", "number 12", "strike", "promotion"]:
			if text.containsn(word):
				counts["work"] += 1
				break
	assert_true(counts["Gerald"] >= 8, str(counts))
	assert_true(counts["Biscuit"] >= 8, str(counts))
	assert_true(counts["work"] >= 8, str(counts))


func test_no_line_tells_an_ending_or_points_to_his_house() -> void:
	for text in _texts():
		var lower := text.to_lower()
		for banned in ["house", "home", "ending", "funeral", "grave", "coffin", "heaven", "afterlife", "goodbye", "hospital", "died"]:
			assert_false(lower.contains(banned), "%s: %s" % [banned, text])


# --- once a run, by the run's seed ---

func test_a_run_shows_every_line_once_and_then_no_more() -> void:
	var data := ProgressData.new()
	var shown: Array[String] = []
	var taken := {}
	for i in 40:
		var id := LifeSigns.take("seed-1", data, shown)
		assert_false(id.is_empty(), "line %d" % i)
		assert_false(taken.has(id), "%s shown twice in a run" % id)
		taken[id] = true
	assert_eq(shown.size(), 40)
	assert_eq(LifeSigns.take("seed-1", data, shown), "", "nothing left this run")
	assert_eq(shown.size(), 40)


func test_the_runs_seed_sets_the_order() -> void:
	var seen := {}
	var first := LifeSigns.order("12345", seen)
	assert_eq(LifeSigns.order("12345", seen), first, "the same seed, the same order")
	assert_eq(first.size(), 40)
	var firsts := {}
	for seed_value in 30:
		firsts[LifeSigns.order(str(seed_value * 7919), seen)[0]] = true
	assert_true(firsts.size() >= 12, "different runs open on different lines (%d)" % firsts.size())


func test_lines_the_save_has_not_seen_come_first() -> void:
	var data := ProgressData.new()
	var ids := LifeSigns.ids()
	for i in 25:
		data.see_life_sign(ids[i])
	var shown: Array[String] = []
	for i in 15:
		var id := LifeSigns.take("777", data, shown)
		assert_true(ids.find(id) >= 25, "%s was already seen, while unseen lines were left" % id)
	var next := LifeSigns.take("777", data, shown)
	assert_true(ids.find(next) < 25, "then the seen ones")
	assert_eq(next, ids[0], "the one seen longest ago first")


func test_once_all_are_seen_the_oldest_come_first() -> void:
	var data := ProgressData.new()
	var ids := LifeSigns.ids()
	for i in range(39, -1, -1):
		data.see_life_sign(ids[i])
	var order := LifeSigns.order("anything", data.life_signs_seen)
	assert_eq(order[0], ids[39], "seen first, offered first")
	assert_eq(order[39], ids[0], "seen last, offered last")
	# Seeing one again moves it to the back.
	data.see_life_sign(ids[39])
	assert_eq(LifeSigns.order("anything", data.life_signs_seen)[39], ids[39])


func test_a_line_keeps_its_place_while_others_are_seen() -> void:
	var data := ProgressData.new()
	var before := LifeSigns.order("42", data.life_signs_seen)
	data.see_life_sign(before[0])
	var after := LifeSigns.order("42", data.life_signs_seen)
	assert_eq(after[0], before[1], "the next unseen line moves up")
	assert_eq(after[38], before[39])


# --- the save ---

func test_shown_lines_are_saved_as_seen_in_order() -> void:
	var data := ProgressData.new()
	var shown: Array[String] = []
	var first := LifeSigns.take("9", data, shown)
	var second := LifeSigns.take("9", data, shown)
	assert_eq(data.life_signs_seen.size(), 2)
	assert_true(int(data.life_signs_seen[first]) < int(data.life_signs_seen[second]), "stamped in the order seen")
	var loaded := ProgressData.from_dict(data.to_dict())
	assert_eq(loaded.life_signs_seen, data.life_signs_seen, "kept through a save")
	data.see_life_sign("")
	assert_eq(data.life_signs_seen.size(), 2, "an empty id is no line")


func test_an_older_save_without_the_key_has_seen_none() -> void:
	var raw := ProgressData.new().to_dict()
	raw.erase("life_signs_seen")
	var loaded := ProgressData.from_dict(raw)
	assert_true(loaded != null, "an older save still loads")
	assert_eq(loaded.life_signs_seen, {})
	raw["life_signs_seen"] = {"hedge_1974": 3, "broken": "not a stamp", "biscuit_seven": -2}
	var odd := ProgressData.from_dict(raw)
	assert_eq(odd.life_signs_seen, {"hedge_1974": 3, "biscuit_seven": 0}, "a damaged entry is dropped")


func test_the_old_save_fixture_loads_with_none_seen() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/old_save_mall_golf.json"))
	assert_true(raw is Dictionary and not raw.has("life_signs_seen"), "the fixture predates the key")
	var loaded := ProgressData.from_dict(raw)
	assert_true(loaded != null)
	assert_eq(loaded.life_signs_seen, {})


func test_the_checkpoint_keeps_the_lines_this_run_has_shown() -> void:
	var no_upgrades: Array[UpgradeDef] = []
	var run := RunState.new(no_upgrades, {})
	run.life_signs_shown.append("gerald_gnome")
	run.life_signs_shown.append("depot_tea")
	var raw := RunCheckpoint.tally_to_dict(run)
	var back := RunState.new(no_upgrades, {})
	RunCheckpoint.apply_tally(back, JSON.parse_string(JSON.stringify(raw)))
	assert_eq(back.life_signs_shown, run.life_signs_shown)
	var old := RunState.new(no_upgrades, {})
	RunCheckpoint.apply_tally(old, {"kills": {}, "met": []})
	assert_true(old.life_signs_shown.is_empty(), "an older checkpoint has shown none")


func test_the_cards_take_the_floors_seed() -> void:
	var no_upgrades: Array[UpgradeDef] = []
	var run := RunState.new(no_upgrades, {})
	var room := FloorRoom.new()
	room.decor_seed = 31
	assert_eq(CinemaProps.life_sign_seed(run, room), "31", "with no floor yet, the room's own")
	run.seeds.append("111")
	run.seeds.append("222")
	assert_eq(CinemaProps.life_sign_seed(run, room), "222", "the floor he is on")


# --- the card ---

func test_the_layout_symbol_is_a_card_that_blocks_nothing() -> void:
	var symbol := RoomLayout.SYMBOL_LIFE_SIGN
	assert_true(RoomLayout.ALLOWED.contains(symbol))
	assert_true(RoomLayout.DECOR_SYMBOLS.contains(symbol))
	assert_false(RoomLayout.SOLID_SYMBOLS.contains(symbol))
	assert_false(RoomLayout.WALLS_AND_BOMB_ONLY.contains(symbol))
	var rows := PackedStringArray(["#".repeat(20)])
	for y in range(1, 10):
		rows.append("#" + ".".repeat(18) + "#")
	rows.append("#".repeat(20))
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_ITEM
	layout.rows = rows
	layout.rows[6] = "#....I.....I....i..#"
	assert_eq(layout.validate().size(), 0, str(layout.validate()))
	layout.rows[6] = "#....I.....I......i#"
	assert_true(str(layout.validate()).contains("lobby card"), "a card touching the east door")


func _card(lines: Array) -> LifeSign:
	var card := LifeSign.new()
	var queue := lines.duplicate()
	card.setup(null, func() -> String: return queue.pop_front() if not queue.is_empty() else "")
	card.position = Vector2(200, 200)
	card._ready()
	return card


func test_walking_near_shows_a_line_and_walking_away_hides_it() -> void:
	var card := _card(["gerald_tape", "depot_tea"])
	card.update_for(Vector2(200, 200) + Vector2(LifeSign.NEAR + 20.0, 0))
	assert_false(card.is_showing(), "too far")
	assert_eq(card.line_id, "", "nothing picked before he comes near")
	card.update_for(Vector2(200, 230))
	assert_true(card.is_showing())
	assert_eq(card.showing_text(), LifeSigns.text_of("gerald_tape"))
	card.update_for(Vector2(200, 200 + LifeSign.NEAR + 8.0))
	assert_true(card.is_showing(), "a step back still shows it")
	card.update_for(Vector2(200, 200 + LifeSign.FAR + 1.0))
	assert_false(card.is_showing(), "walking away hides it")
	card.update_for(Vector2(205, 205))
	assert_eq(card.showing_text(), LifeSigns.text_of("gerald_tape"), "and coming back shows the same line, picking no other")
	card.free()


func test_a_card_with_nothing_left_to_show_stays_blank() -> void:
	var card := _card([])
	card.update_for(Vector2(200, 200))
	assert_false(card.is_showing())
	card.free()


func test_the_card_never_pauses_the_game() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/life_sign.gd")
	assert_false(source.contains("paused"), "nothing pauses")
	assert_false(source.contains("time_scale"))


func test_every_line_fits_its_card_and_stays_out_of_the_hud() -> void:
	for text in _texts():
		var rows := LifeSign.wrap_text(text)
		assert_true(rows.size() >= 1 and rows.size() <= 4, "%d rows: %s" % [rows.size(), text])
		assert_eq(" ".join(rows), text, "nothing lost in wrapping")
		var size := LifeSign.box_size_for(rows)
		assert_true(size.x <= LifeSign.LINE_WIDTH + LifeSign.PAD.x * 2.0 + 1.0, text)
		# A card near the top of the screen, and one at its far right: the bubble stays on screen and
		# below the HUD's band.
		for at: Vector2 in [Vector2(320, 70), Vector2(630, 120), Vector2(8, 300)]:
			var box := Npc.bubble_box(at, Vector2.ONE, LifeSign.CARD_HEIGHT, size, Vector2(RoomBackdrop.VIEW_SIZE))
			var on_screen := Rect2(at + box.position, box.size)
			assert_true(on_screen.position.y >= Hud.BAND_BOTTOM, "%s reaches into the HUD at %s" % [text, str(at)])
			assert_true(on_screen.position.x >= 0.0 and on_screen.end.x <= RoomBackdrop.VIEW_SIZE.x, "%s runs off screen at %s" % [text, str(at)])
			assert_true(on_screen.end.y <= RoomBackdrop.VIEW_SIZE.y, "%s runs off the bottom at %s" % [text, str(at)])
