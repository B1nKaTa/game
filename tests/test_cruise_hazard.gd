extends TestCase


func _room(rolls := true) -> RoomLayout:
	var rows := ["#".repeat(20)]
	for y in range(1, 10):
		rows.append("#" + ".".repeat(18) + "#")
	rows.append("#".repeat(20))
	rows[4] = rows[4].substr(0, 9) + "H" + rows[4].substr(10)
	rows[6] = rows[6].substr(0, 12) + "O" + rows[6].substr(13)
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_HEALING
	layout.rows = PackedStringArray(rows)
	layout.ship_rolls = rolls
	return layout


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


# A deck moved on until its own roll has started to slide.
func _sliding_deck(seed_value := 5) -> ShipDeck:
	var deck := ShipDeck.new()
	deck.setup(_room(), seed_value)
	for i in 400:
		if deck.state() == ShipRoll.SLIDE:
			break
		deck.advance(0.05)
	return deck


# --- the roll's timing ---

func test_the_deck_lies_quiet_then_the_horn_sounds_then_it_slides() -> void:
	var roll := ShipRoll.new(9.0, 1.5, 2.0, 0.0)
	assert_eq(roll.state_at(1.0), ShipRoll.QUIET)
	assert_eq(roll.state_at(5.4), ShipRoll.QUIET)
	assert_eq(roll.state_at(5.6), ShipRoll.HORN, "the horn first")
	assert_eq(roll.state_at(6.9), ShipRoll.HORN)
	assert_eq(roll.state_at(7.1), ShipRoll.SLIDE, "then the slide")
	assert_eq(roll.state_at(8.9), ShipRoll.SLIDE)
	assert_eq(roll.state_at(9.1), ShipRoll.QUIET, "and quiet again")
	assert_near(roll.horn_progress(5.5 + 0.75), 0.5)


func test_the_roll_follows_the_spec() -> void:
	assert_near(ShipRoll.PERIOD, 9.0)
	assert_near(ShipRoll.SLIDE_TIME, 2.0)
	assert_true(ShipRoll.HORN_TIME >= 1.0, "the horn leaves time to brace")
	assert_true(ShipRoll.SPEED < PlayerStats.BASE_SPEED * 0.75, "he can still walk against it")
	assert_true(ShipRoll.SPEED * ShipRoll.SLIDE_TIME >= RoomBackdrop.TILE * 3.0, "it carries him a real way")


func test_the_roll_repeats_and_an_offset_moves_it() -> void:
	var roll := ShipRoll.new(9.0, 1.5, 2.0, 0.0)
	for lap in 5:
		var start := lap * 9.0
		assert_eq(roll.state_at(start + 2.0), ShipRoll.QUIET, "lap %d" % lap)
		assert_eq(roll.state_at(start + 6.0), ShipRoll.HORN, "lap %d" % lap)
		assert_eq(roll.state_at(start + 8.0), ShipRoll.SLIDE, "lap %d" % lap)
		assert_eq(roll.roll_index(start + 6.0), roll.roll_index(start + 8.0), "the horn and its slide are one roll")
	var later := ShipRoll.new(9.0, 1.5, 2.0, 4.5)
	assert_eq(later.state_at(8.0), ShipRoll.QUIET, "half a period later it is quiet")
	assert_eq(later.state_at(12.5), ShipRoll.SLIDE)


func test_the_horn_always_sounds_before_each_slide() -> void:
	for offset in [0.0, 1.3, 4.5, 8.9]:
		var roll := ShipRoll.new(ShipRoll.PERIOD, ShipRoll.HORN_TIME, ShipRoll.SLIDE_TIME, offset)
		var last := roll.state_at(0.0)
		var time := 0.0
		for step in 2000:
			time += 0.02
			var now := roll.state_at(time)
			if now == ShipRoll.SLIDE and last != ShipRoll.SLIDE:
				assert_eq(last, ShipRoll.HORN, "offset %f at %f" % [offset, time])
			last = now


func test_each_horn_is_counted_once_however_the_frames_fall() -> void:
	var roll := ShipRoll.new(9.0, 1.5, 2.0, 0.0)
	var horns := 0
	var time := 0.0
	for frame in 3000:
		var step := 0.016 if frame % 3 != 0 else 0.041
		horns += roll.horns_between(time, time + step)
		time += step
	assert_eq(horns, floori((time - 5.5) / 9.0) + 1)
	assert_eq(roll.horns_between(5.0, 5.0), 0)


func test_the_deck_tips_only_to_port_or_starboard_and_both_come() -> void:
	for seed_value in [1, 7, 42, 900]:
		var seen := {}
		for index in 40:
			var side := ShipRoll.side_for(index, seed_value)
			assert_true(side == Vector2.LEFT or side == Vector2.RIGHT, str(side))
			assert_eq(side, ShipRoll.side_for(index, seed_value), "the seed fixes it")
			seen[side] = true
		assert_eq(seen.size(), 2, "seed %d rolls both ways" % seed_value)


func test_the_deck_only_moves_anyone_while_it_slides() -> void:
	assert_true(ShipRoll.slide_velocity(ShipRoll.QUIET, Vector2.LEFT, 70.0).is_zero_approx())
	assert_true(ShipRoll.slide_velocity(ShipRoll.HORN, Vector2.LEFT, 70.0).is_zero_approx(), "the horn only warns")
	assert_true(ShipRoll.slide_velocity(ShipRoll.SLIDE, Vector2.LEFT, 70.0).is_equal_approx(Vector2(-70, 0)))


# --- the deck in a room ---

func test_a_rolling_deck_slides_the_middle_of_the_room_but_never_by_a_door() -> void:
	var layout := _room()
	var deck := _sliding_deck()
	assert_eq(deck.state(), ShipRoll.SLIDE)
	var middle := RoomBackdrop.cell_center(Vector2i(5, 3))
	var slide := ShipDeck.slide_from([deck], middle)
	assert_near(slide.length(), ShipRoll.SPEED)
	assert_true(absf(slide.y) < 0.001, "port or starboard only")
	for side in RoomLayout.SIDES:
		var door := RoomBackdrop.cell_center(layout.door_cell(side))
		assert_true(ShipDeck.slide_from([deck], door).is_zero_approx(), "steady at the door %s" % str(side))
		assert_true(ShipDeck.slide_from([deck], door + Vector2(side) * -40.0).is_zero_approx(), "and just inside it")
	assert_true(ShipDeck.slide_at(null, middle).is_zero_approx(), "no tree, no deck")
	deck.free()


func test_a_room_rolls_only_when_its_layout_says_so() -> void:
	assert_false(RoomLayout.new().ship_rolls, "old layouts never roll")
	assert_true(_room().ship_rolls)


func test_a_boss_order_sounds_the_horn_first_then_slides_harder() -> void:
	var deck := ShipDeck.new()
	deck.setup(_room(), 3)
	deck.force_roll(Vector2.LEFT, 1.2, 2.5, ShipRoll.SPEED * 2.0)
	assert_true(deck.is_forced())
	assert_eq(deck.state(), ShipRoll.HORN, "warned as the ship's own roll is")
	assert_true(deck.slide().is_zero_approx())
	deck.advance(0.6)
	assert_near(deck.horn_progress(), 0.5)
	deck.advance(0.7)
	assert_eq(deck.state(), ShipRoll.SLIDE)
	assert_true(deck.slide().is_equal_approx(Vector2.LEFT * ShipRoll.SPEED * 2.0))
	deck.advance(2.6)
	assert_false(deck.is_forced(), "and then the ship rolls as before")
	deck.free()


func test_the_roll_never_costs_a_pill() -> void:
	var empty: Array[UpgradeDef] = []
	var run := RunState.new(empty, {})
	var pills := run.health.pills
	var deck := ShipDeck.new()
	deck.setup(_room(), 9)
	for i in 800:
		deck.advance(0.05)
	deck.force_roll(Vector2.RIGHT, 1.0, 2.0, 200.0)
	deck.advance(4.0)
	assert_eq(run.health.pills, pills)
	assert_false(deck.has_method("hit_target") or deck.has_method("damage"), "a deck has no way to hurt")
	deck.free()


func test_walkers_slide_but_bosses_and_running_charges_never_do() -> void:
	var orderly := Enemy.new()
	orderly.setup(_load("orderly"), null, 0.5)
	assert_true(orderly.slides_with_roll(), "a walker slides")
	orderly.hold_lane()
	assert_false(orderly.slides_with_roll(), "a running charge holds its lane")
	orderly.free()
	for id in ["mortimer_grimsby", "reverend", "projectionist"]:
		var boss := Enemy.new()
		boss.setup(_load(id), null, 0.5)
		assert_false(boss.slides_with_roll(), "%s keeps his footing" % id)
		boss.free()
	var ghost := Enemy.new()
	ghost.setup(_load("soot_ghost"), null, 0.5)
	if ghost.def.ignores_walls:
		assert_false(ghost.slides_with_roll(), "a ghost floats over the deck")
	ghost.free()


func test_a_dodge_holds_grandpa_and_only_his_walk_slides() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	var dodge := source.find("velocity = _dodge_direction * DODGE_SPEED")
	var slide := source.find("ShipDeck.slide_at(")
	var push := source.find("if _push_left > 0.0:\r\n\t\tvelocity += _push")
	if push < 0:
		push = source.find("if _push_left > 0.0:\n\t\tvelocity += _push")
	assert_true(dodge > 0 and slide > dodge, "the slide is added in the walk, after the dodge's own branch")
	assert_true(push > slide, "and inside the walk, before any gust")


func test_loose_pickups_never_come_to_rest_on_a_door_or_a_solid_cell() -> void:
	var layout := _room()
	var deck := ShipDeck.new()
	deck.setup(layout, 1)
	assert_true(deck.pickup_can_rest(RoomBackdrop.cell_center(Vector2i(6, 3))))
	assert_false(deck.pickup_can_rest(RoomBackdrop.cell_center(Vector2i(12, 6))), "a rock")
	assert_false(deck.pickup_can_rest(RoomBackdrop.cell_center(Vector2i(0, 3))), "a wall")
	for side in RoomLayout.SIDES:
		assert_false(deck.pickup_can_rest(RoomBackdrop.cell_center(layout.door_cell(side))), "a door")
		assert_false(deck.pickup_can_rest(RoomBackdrop.cell_center(layout.door_cell(side) - side)), "beside a door")
	var open_everywhere := func(at: Vector2) -> Vector2: return at
	var solid_everywhere := func(at: Vector2) -> Vector2: return at + Vector2(32, 0)
	deck.setup(layout, 1, open_everywhere)
	assert_true(deck.pickup_can_rest(RoomBackdrop.cell_center(Vector2i(12, 6))), "a broken rock opens its cell")
	deck.setup(layout, 1, solid_everywhere)
	assert_false(deck.pickup_can_rest(RoomBackdrop.cell_center(Vector2i(6, 3))))
	deck.free()
