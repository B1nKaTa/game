extends TestCase

# The animated title screen's rules: the NOW SERVING board never reaching Harold's number, the ghosts'
# chatter, the ticket menu, the plaque's lettering, and seated Harold wearing what the save says.

const VIEW := Vector2(640, 360)


func _defs() -> Array[CosmeticDef]:
	return CosmeticDef.all()


# NOW SERVING

func test_the_board_never_reaches_harolds_number_over_hours() -> void:
	for seed_value in [1, 7, 42, 999, 31337]:
		var board := NowServing.new(42, seed_value)
		var highest := 0
		var skips := 0
		var t := 0.0
		while t < 3600.0:
			var event := board.tick(0.05)
			t += 0.05
			assert_true(board.shown != 42, "the board showed his number (seed %d)" % seed_value)
			assert_true(board.display(t) != "042", "the board read 042 (seed %d)" % seed_value)
			highest = maxi(highest, board.shown)
			if event == "skip":
				skips += 1
		assert_eq(highest, 41, "it gets one short")
		assert_true(skips > 20, "it drops back again and again, %d times" % skips)


func test_the_number_before_his_drops_back_and_others_count_up() -> void:
	assert_eq(NowServing.next_number(38, 42, 4), 39)
	assert_eq(NowServing.next_number(41, 42, 4), 37)
	assert_eq(NowServing.next_number(41, 42, 0), 41, "even a drop of nothing stays one short")
	assert_eq(NowServing.next_number(2, 3, 9), 0, "never below zero")


func test_it_ticks_up_every_few_seconds() -> void:
	var board := NowServing.new(42, 5)
	var start := board.shown
	assert_eq(board.tick(NowServing.STEP_MIN - 0.1), "", "nothing before the shortest wait")
	assert_eq(board.tick(NowServing.STEP_MAX), "advance")
	assert_eq(board.shown, start + 1)


func test_the_skip_flickers_with_a_dash_and_never_shows_his_last_digit() -> void:
	var board := NowServing.new(42, 3)
	board.shown = 41
	var event := ""
	while event != "skip":
		event = board.tick(0.1)
	assert_true(board.flicker_left > 0.0)
	var seen := {}
	for i in 30:
		seen[board.display(i * 0.03)] = true
	assert_true(seen.has("04-"), "his first digits and a dash")
	assert_false(seen.has("042"))
	board.tick(NowServing.FLICKER_TIME + 0.01)
	assert_eq(board.display(0.0), "%03d" % board.shown, "then the dropped number")
	assert_true(board.shown < 41)


# Ghost chatter

func test_there_are_at_least_twenty_short_distinct_lines() -> void:
	assert_true(GhostChatter.LINES.size() >= 20, "%d lines" % GhostChatter.LINES.size())
	var seen := {}
	for line in GhostChatter.LINES:
		assert_false(seen.has(line), "said twice in the list: " + line)
		seen[line] = true
		assert_true(line.length() <= GhostChatter.MAX_CHARS, "too long for a bubble: " + line)
		var rows := TitleBubble.wrap_line(line)
		assert_true(rows.size() <= 2, "more than two rows: " + line)
		for row in rows:
			assert_true(row.length() <= 22, "a row too wide: " + row)


func test_a_line_is_not_heard_again_until_others_have_been() -> void:
	var chatter := GhostChatter.new(11)
	var last_seen := {}
	for turn in 400:
		var line := chatter.pick_line()
		if last_seen.has(line):
			assert_true(turn - int(last_seen[line]) > GhostChatter.RECENT, "repeated after %d turns" % (turn - int(last_seen[line])))
		last_seen[line] = turn
	assert_eq(last_seen.size(), GhostChatter.LINES.size(), "every line gets said")


func test_nobody_speaks_twice_in_a_row_while_another_can() -> void:
	var chatter := GhostChatter.new(23)
	var able: Array[int] = [0, 1, 2]
	var positions := {0: 42.0, 1: 120.0, 2: 192.0}
	var last := -1
	var replies := 0
	var previous_listener := -1
	for turn in 300:
		var speaker := chatter.pick_speaker(able)
		assert_true(speaker != last, "the same ghost spoke twice in a row")
		if speaker == previous_listener:
			replies += 1
		var listener := GhostChatter.listener_for(speaker, positions)
		chatter.note_turn(speaker, listener)
		last = speaker
		previous_listener = listener
	assert_true(replies > 150, "the one spoken to usually answers (%d of 300)" % replies)


func test_the_speaker_turns_to_the_nearest_ghost() -> void:
	var positions := {0: 18.0, 1: 66.0, 2: 192.0}
	assert_eq(GhostChatter.listener_for(0, positions), 1)
	assert_eq(GhostChatter.listener_for(2, positions), 1)
	assert_eq(GhostChatter.listener_for(0, {0: 18.0}), -1, "alone, nobody to turn to")


func test_a_lone_able_ghost_may_speak_and_nobody_gives_minus_one() -> void:
	var chatter := GhostChatter.new(5)
	var lone: Array[int] = [2]
	var nobody: Array[int] = []
	chatter.note_turn(2, -1)
	assert_eq(chatter.pick_speaker(lone), 2)
	assert_eq(chatter.pick_speaker(nobody), -1)


# The ticket menu

func test_every_menu_item_has_a_ticket_label() -> void:
	for with_progress in [0, 1, 2, 3]:
		var ids := TitleMenu.ids(with_progress)
		assert_eq(ids, SaveSlots.menu_items(with_progress))
		for id in ids:
			assert_true(TitleMenu.LABELS.has(id), "no label for " + id)
	assert_eq(TitleMenu.label("new"), "New Game")
	assert_eq(TitleMenu.label("quit"), "Quit Game")


func test_tickets_hang_in_order_inside_the_view_and_never_overlap() -> void:
	var count := TitleMenu.ids(3).size()
	assert_eq(count, 6)
	var view := Rect2(Vector2.ZERO, VIEW)
	for index in count:
		var rect := TitleMenu.ticket_rect(index)
		var out := TitleMenu.ticket_rect(index, true)
		assert_true(view.encloses(rect) and view.encloses(out), "ticket %d leaves the view" % index)
		assert_eq(out.position - rect.position, Vector2(TitleMenu.STICK_OUT, 0), "the selected ticket slides out")
		assert_eq(rect.position.x + rect.size.x / 2.0, TitleMenu.SLOT.x, "centred under the slot")
		if index > 0:
			var above := TitleMenu.ticket_rect(index - 1)
			assert_false(above.intersects(rect), "tickets %d and %d overlap" % [index - 1, index])
			assert_true(rect.position.y > above.position.y)
	assert_true(TitleMenu.ticket_rect(0).position.y >= TitleMenu.SLOT.y, "the first hangs from the slot")


func test_the_strip_clears_the_corner_labels() -> void:
	var last := TitleMenu.ticket_rect(TitleMenu.ids(3).size() - 1, true)
	# The version (bottom left) and build id (bottom right) sit on the view's last 16 rows.
	assert_true(last.position.x > 120.0 and last.end.x < 520.0)


func test_a_point_on_a_ticket_maps_back_to_its_item() -> void:
	var count := TitleMenu.ids(1).size()
	for index in count:
		assert_eq(TitleMenu.index_at(TitleMenu.ticket_rect(index).get_center(), count), index)
		assert_eq(TitleMenu.index_at(TitleMenu.ticket_rect(index, true).get_center(), count), index, "slid out too")
	assert_eq(TitleMenu.index_at(Vector2(5, 5), count), -1)


func test_moving_wraps_round_the_strip() -> void:
	assert_eq(TitleMenu.step(0, -1, 5), 4)
	assert_eq(TitleMenu.step(4, 1, 5), 0)
	assert_eq(TitleMenu.step(2, 1, 5), 3)
	assert_eq(TitleMenu.step(0, 1, 0), -1)


func test_a_torn_ticket_jerks_falls_and_fades_before_the_action() -> void:
	var start := TitleMenu.tear(0.0)
	var jerk := TitleMenu.tear(TitleMenu.TEAR_TIME * 0.25)
	var end := TitleMenu.tear(TitleMenu.TEAR_TIME)
	assert_eq(start["offset"], Vector2.ZERO)
	assert_near(start["alpha"], 1.0)
	assert_true(jerk["offset"].x > 0.0 and is_zero_approx(jerk["offset"].y), "first it jerks sideways off the seam")
	assert_true(end["offset"].y > 20.0, "then it falls")
	assert_near(end["alpha"], 0.0)


func test_the_title_screen_runs_the_action_after_the_tear() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/title_screen.gd")
	assert_true(source.contains("ticket.pressed.connect(_tear.bind(ticket))"))
	assert_true(source.contains("create_timer(TitleMenu.TEAR_TIME).timeout.connect(_torn"))
	assert_true(source.contains("func _choose(id: String)"), "probes still choose directly")


# The plaque

func test_the_plaque_can_letter_the_name_and_subtitle() -> void:
	for character in TitleBrand.NAME.to_upper():
		assert_true(character == " " or PixelGlyphs.BIG.has(character), "no plaque letter for " + character)
	for character in TitleBrand.SUBTITLE.to_upper():
		assert_true(character == " " or PixelGlyphs.SMALL.has(character), "no small letter for " + character)
	for character in "NOW SERVING TAKE 1":
		assert_true(character == " " or PixelGlyphs.SMALL.has(character))


# A small piece hanging off its letter by one corner reads as a stray dot at the plaque's size (an R's
# diagonal leg did). A rounded corner, joined at both ends, is fine.
func test_no_letter_of_the_name_has_a_piece_hanging_by_one_corner() -> void:
	for character in TitleBrand.NAME.to_upper():
		if character == " ":
			continue
		var cells := PixelGlyphs.cells(PixelGlyphs.BIG, character)
		var group := {}
		var groups := 0
		for start_cell in cells:
			if group.has(start_cell):
				continue
			var todo: Array[Vector2i] = [start_cell]
			group[start_cell] = groups
			while not todo.is_empty():
				var cell: Vector2i = todo.pop_back()
				for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					if cells.has(cell + step) and not group.has(cell + step):
						group[cell + step] = groups
						todo.append(cell + step)
			groups += 1
		for index in groups:
			var piece: Array[Vector2i] = []
			for cell: Vector2i in group:
				if group[cell] == index:
					piece.append(cell)
			if piece.size() >= 3 or groups == 1:
				continue
			var contacts := {}
			for cell in piece:
				for step: Vector2i in [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
					if group.has(cell + step) and group[cell + step] != index:
						contacts[cell + step] = true
			assert_true(contacts.size() >= 2, "%s has a piece hanging by one corner" % character)


func test_every_glyph_has_its_font_size() -> void:
	for font: Dictionary in [PixelGlyphs.BIG, PixelGlyphs.SMALL]:
		var width := PixelGlyphs.glyph_width(font)
		var height := PixelGlyphs.glyph_height(font)
		for key: String in font:
			assert_eq(font[key].size(), height, key)
			for row: String in font[key]:
				assert_eq(row.length(), width, key)


func test_the_name_lives_in_one_place() -> void:
	assert_true(FileAccess.get_file_as_string("res://scripts/ui/title_plaque.gd").contains("TitleBrand.NAME"))
	assert_true(FileAccess.get_file_as_string("res://scripts/ui/title_plaque.gd").contains("TitleBrand.SUBTITLE"))
	assert_true(FileAccess.get_file_as_string("res://scripts/scenes/title_screen.gd").contains("TitleBrand.TAGLINE"))
	assert_false(FileAccess.get_file_as_string("res://scripts/scenes/title_screen.gd").contains("GRANDPA"))
	assert_true(FileAccess.get_file_as_string("res://scripts/ui/credits_card.gd").contains("TitleBrand.FULL_NAME"))
	assert_eq(TitleBrand.FULL_NAME, "RIP: Retirement in Progress")


# Seated Harold's look

func test_nothing_worn_shows_his_own_look() -> void:
	for worn: Dictionary in [{}, {"hat": "no_such_hat"}, {"cardigan": "flat_cap"}]:
		var look := SeatedLook.from_worn(worn, _defs())
		assert_eq(look["art"], "res://art/title/harold.png")
		assert_eq(look["hat"], "", "bare-headed")
		assert_false(look["tie"])
		assert_false(look["cane"], "his own cane")


func test_a_cap_alone() -> void:
	var cap := CosmeticDef.find("flat_cap", _defs())
	var look := SeatedLook.from_worn({"hat": "flat_cap"}, _defs())
	assert_eq(look["hat"], "flat_cap")
	assert_true((look["hat_color"] as Color).is_equal_approx(cap.color))
	assert_eq(look["art"], "res://art/title/harold.png", "his own cardigan")
	assert_false(look["cane"])


func test_a_cardigan_alone() -> void:
	var look := SeatedLook.from_worn({"cardigan": "mustard_cardigan"}, _defs())
	assert_eq(look["art"], "res://art/title/harold_mustard_cardigan.png")
	assert_true(FileAccess.file_exists(look["art"]))
	assert_eq(look["hat"], "")
	assert_false(look["cane"])


func test_the_power_tie_is_drawn_over_his_own_cardigan() -> void:
	var tie := CosmeticDef.find("power_tie", _defs())
	var look := SeatedLook.from_worn({"cardigan": "power_tie"}, _defs())
	assert_true(look["tie"])
	assert_true((look["tie_color"] as Color).is_equal_approx(tie.color))
	assert_eq(look["art"], "res://art/title/harold.png")


func test_a_cane_alone() -> void:
	var stripe := SeatedLook.from_worn({"cane": "candy_stripe"}, _defs())
	assert_true(stripe["cane"])
	assert_true(stripe["stripes"], "the candy stripe keeps its red bands")
	assert_true((stripe["cane_color"] as Color).is_equal_approx(CosmeticDef.find("candy_stripe", _defs()).color))
	var oak := SeatedLook.from_worn({"cane": "polished_oak"}, _defs())
	assert_true(oak["cane"])
	assert_false(oak["stripes"])
	assert_eq(stripe["hat"], "")
	assert_eq(stripe["art"], "res://art/title/harold.png")


func test_all_three_worn_together() -> void:
	var look := SeatedLook.from_worn({"hat": "flat_cap", "cardigan": "mustard_cardigan", "cane": "candy_stripe"}, _defs())
	assert_eq(look["hat"], "flat_cap")
	assert_eq(look["art"], "res://art/title/harold_mustard_cardigan.png")
	assert_true(look["cane"] and look["stripes"])


func test_every_worn_cosmetic_has_its_seated_look() -> void:
	var hat_source := FileAccess.get_file_as_string("res://scripts/world/grandpa_look.gd")
	for def in _defs():
		match def.slot:
			CosmeticDef.SLOT_HAT:
				assert_true(hat_source.contains("\"%s\":" % def.shape), "GrandpaLook.draw_hat cannot draw " + def.id)
			CosmeticDef.SLOT_CARDIGAN:
				var look := SeatedLook.describe({def.slot: def})
				if def.shape == "tie":
					assert_true(look["tie"], def.id)
				else:
					assert_true(TitleFrames.OUTFITS.has(def.id), "no seated outfit for " + def.id)
					assert_true(FileAccess.file_exists(look["art"]), def.id)
			CosmeticDef.SLOT_CANE:
				assert_true(SeatedLook.describe({def.slot: def})["cane"], def.id)


func test_seated_strips_and_anchors_line_up() -> void:
	assert_eq(TitleFrames.HAROLD_HEAD.size(), TitleFrames.HAROLD_FRAMES)
	assert_eq(TitleFrames.HAROLD_TIE.size(), TitleFrames.HAROLD_FRAMES)
	var frame := Rect2(0, 0, TitleFrames.HAROLD_SIZE, TitleFrames.HAROLD_SIZE)
	for i in TitleFrames.HAROLD_FRAMES:
		var head := TitleFrames.HAROLD_HEAD[i]
		assert_true(frame.has_point(head) and frame.has_point(TitleFrames.HAROLD_TIE[i]), "frame %d" % i)
		assert_true(TitleFrames.HAROLD_TIE[i].y > head.y + 5.0, "the tie hangs under his head in frame %d" % i)
	for art in ["harold", "harold_cane"] + Array(TitleFrames.OUTFITS).map(func(id: String) -> String: return "harold_" + id):
		var image := Image.load_from_file(ProjectSettings.globalize_path("res://art/title/%s.png" % art))
		assert_eq(image.get_size(), Vector2i(TitleFrames.HAROLD_SIZE * TitleFrames.HAROLD_FRAMES, TitleFrames.HAROLD_SIZE), art)
	for ghost: String in TitleFrames.GHOST_ROWS:
		var image := Image.load_from_file(ProjectSettings.globalize_path("res://art/title/%s.png" % ghost))
		assert_eq(image.get_size(), Vector2i(TitleFrames.GHOST_SIZE * TitleFrames.GHOST_FRAMES, TitleFrames.GHOST_SIZE), ghost)


func test_every_seated_frame_has_a_cane_to_recolour() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://art/title/harold_cane.png"))
	for i in TitleFrames.HAROLD_FRAMES:
		var count := 0
		for y in TitleFrames.HAROLD_SIZE:
			for x in TitleFrames.HAROLD_SIZE:
				if image.get_pixel(i * TitleFrames.HAROLD_SIZE + x, y).a > 0.5:
					count += 1
		assert_true(count >= 6, "frame %d's cane has %d pixels" % [i, count])


func test_the_title_reads_the_save_and_never_writes_it() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/title_screen.gd")
	assert_true(source.contains("SeatedLook.from_worn(_worn(), CosmeticDef.all())"))
	assert_true(source.contains("Progress.data.cosmetics_worn"))
	for writer in ["Progress.save", "Progress.wear", "Progress.take_off", "cosmetics_worn[", "cosmetics_worn ="]:
		assert_false(source.contains(writer), "the title screen writes the save: " + writer)


# Seats: one sitter per chair, everyone on the seat

func test_a_chair_never_takes_two_sitters() -> void:
	var anchors: Array[Vector2] = [Vector2(10, 98), Vector2(40, 98), Vector2(70, 98), Vector2(100, 98)]
	var seats := TitleSeats.new(anchors)
	assert_true(seats.claim(0, 1))
	assert_false(seats.claim(0, 2), "a taken chair refuses another")
	assert_true(seats.claim(0, 1), "its own sitter may claim it again")
	assert_true(seats.claim(2, 1), "moving on lets go of the old chair")
	assert_eq(seats.seat_of(1), 2)
	assert_eq(seats.sitter(0), -1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var allowed: Array[int] = [0, 1, 2, 3]
	for who in 3:
		seats.claim(who, who)
	for step in 2000:
		var who := rng.randi_range(0, 2)
		var open := seats.open_seats(allowed)
		if open.is_empty():
			continue
		assert_true(seats.claim(open[rng.randi() % open.size()], who))
		var held := {}
		for sitter in 3:
			var seat := seats.seat_of(sitter)
			assert_true(seat >= 0, "everyone holds a chair")
			assert_false(held.has(seat), "two sitters on chair %d" % seat)
			held[seat] = true


func test_the_room_starts_everyone_on_their_own_chair() -> void:
	var taken := {TitleRoom.HAROLD_SEAT: true}
	for seat in TitleRoom.GHOST_SEATS:
		assert_false(taken.has(seat), "chair %d given twice" % seat)
		assert_true(TitleRoom.OPEN_SEATS.has(seat))
		taken[seat] = true
	assert_false(TitleRoom.OPEN_SEATS.has(TitleRoom.HAROLD_SEAT), "nobody moves into Harold's chair")
	assert_true(TitleRoom.OPEN_SEATS.size() > TitleRoom.GHOST_SEATS.size(), "a chair is free to move to")


func test_a_ghost_stays_on_its_seat_through_every_pose_and_move() -> void:
	for art in ["ghost_a", "ghost_b"]:
		var ghost := TitleGhost.new()
		ghost.setup(load("res://art/title/%s.png" % art), Color.WHITE, art)
		ghost._ready()
		ghost.position = Vector2(44, 98)
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		var moves := 0
		var target := 44.0
		for step in 3000:
			if ghost.is_free():
				match rng.randi() % 40:
					0:
						ghost.fidget()
					1:
						ghost.talk(1.0, [-1, 1][rng.randi() % 2])
					2:
						ghost.face(rng.randi_range(-1, 1))
					3:
						target = 152.0 if ghost.position.x < 100.0 else 44.0
						ghost.move_to(target, 0)
						moves += 1
			ghost._process(0.05)
			if ghost.is_seated():
				var expected := TitleSeats.frame_offset(TitleFrames.GHOST_SIT[art][ghost.frame], TitleFrames.GHOST_SIZE, ghost.is_mirrored())
				assert_eq(ghost.sprite_offset(), expected, "%s frame %d off its seat" % [art, ghost.frame])
				assert_eq(ghost.position.y, 98.0)
				assert_near(ghost.position.x, target)
		assert_true(moves >= 3, "%s changed chairs %d times" % [art, moves])
		ghost.free()


func test_harold_stays_on_his_seat_through_every_idle() -> void:
	var harold := TitleHarold.new()
	harold._ready()
	for anim: String in TitleFrames.HAROLD_ANIMS:
		harold.play(anim)
		for step in 40:
			harold._process(0.05)
			var sit: Vector2 = TitleFrames.HAROLD_SIT[harold.frame]
			assert_eq(harold.sprite_offset(), TitleHarold.expected_offset(harold.frame))
			assert_eq(harold.sprite_offset().y + sit.y, 0.0, "his thighs sit on the seat line in frame %d" % harold.frame)
			assert_eq(harold.sprite_offset().x + sit.x, 0.0, "his body's middle sits on the seat's middle in frame %d" % harold.frame)
	harold.free()


func test_sit_points_are_measured_inside_each_frame_and_he_reaches_the_floor() -> void:
	assert_eq(TitleFrames.HAROLD_SIT.size(), TitleFrames.HAROLD_FRAMES)
	for sit in TitleFrames.HAROLD_SIT:
		assert_true(absf(sit.y - TitleFrames.HAROLD_SIT[0].y) <= 3.0, "his seat holds within 3 px through his idles")
		assert_true(absf(sit.x - TitleFrames.HAROLD_SIT[0].x) <= 2.0, "he never slides sideways on his seat")
	# Seated, he stands as tall over his seat as the ghosts do (31 to 34 px from seat to the top of the head).
	var harold_art := Image.load_from_file(ProjectSettings.globalize_path("res://art/title/harold.png"))
	var harold_top := _top_row(harold_art, 0, TitleFrames.HAROLD_SIZE)
	var harold_height := TitleFrames.HAROLD_SIT[0].y - harold_top
	for art: String in TitleFrames.GHOST_SIT:
		var image := Image.load_from_file(ProjectSettings.globalize_path("res://art/title/%s.png" % art))
		var ghost_height: float = TitleFrames.GHOST_SIT[art][0].y - _top_row(image, 0, TitleFrames.GHOST_SIZE)
		assert_true(absf(harold_height - ghost_height) <= 2.0, "Harold %d px seated against %s's %d" % [harold_height, art, ghost_height])
	for art: String in TitleFrames.GHOST_SIT:
		assert_eq(TitleFrames.GHOST_SIT[art].size(), TitleFrames.GHOST_FRAMES)
		for sit: Vector2 in TitleFrames.GHOST_SIT[art]:
			assert_true(sit.y > 20.0 and sit.y < TitleFrames.GHOST_SIZE, art)
	# Seated on the chair, his soles come down to the floor, a pixel or two either way.
	var seat_height := TitleFrames.CHAIR_FEET_ROW - TitleFrames.CHAIR_SEAT_ROW
	var leg := TitleFrames.HAROLD_FEET_ROW - TitleFrames.HAROLD_SIT[0].y
	assert_true(absf(leg - seat_height) <= 2.0, "seat %d px over the floor, his legs %d" % [seat_height, leg])


func _top_row(image: Image, frame: int, frame_size: int) -> int:
	for y in frame_size:
		for x in frame_size:
			if image.get_pixel(frame * frame_size + x, y).a > 0.0:
				return y
	return frame_size


func _top_row(image: Image, frame: int, frame_size: int) -> int:
	for y in frame_size:
		for x in frame_size:
			if image.get_pixel(frame * frame_size + x, y).a > 0.0:
				return y
	return frame_size


func test_the_ticket_strip_hangs_from_the_slot_on_the_rooms_grid() -> void:
	assert_eq(TitleMenu.SLOT, TitleRoom.to_view(TitleRoom.slot()), "the strip comes out of the machine's slot")
	assert_eq(TitleMenu.TICKET_SIZE, Vector2(TicketButton.CELLS) * TicketButton.CELL)
	for index in TitleMenu.ids(3).size():
		for selected in [false, true]:
			var rect := TitleMenu.ticket_rect(index, selected)
			assert_eq(posmod(int(rect.position.x) + 4, 3), 0, "ticket %d off the grid across" % index)
			assert_eq(posmod(int(rect.position.y), 3), 0, "ticket %d off the grid down" % index)
		if index > 0:
			assert_eq(TitleMenu.ticket_rect(index).position.y, TitleMenu.ticket_rect(index - 1).end.y, "each ticket hangs from the one above")
