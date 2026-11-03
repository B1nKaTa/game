extends TestCase


func _room_with(changes: Dictionary) -> RoomLayout:
	var rows := ["#".repeat(20)]
	for y in range(1, 10):
		rows.append("#" + ".".repeat(18) + "#")
	rows.append("#".repeat(20))
	rows[4] = rows[4].substr(0, 9) + "H" + rows[4].substr(10)
	for cell: Vector2i in changes:
		var row: String = rows[cell.y]
		rows[cell.y] = row.substr(0, cell.x) + changes[cell] + row.substr(cell.x + 1)
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_HEALING
	layout.rows = PackedStringArray(rows)
	return layout


func _vent() -> FloorVent:
	var vent := FloorVent.new()
	vent._ready()
	return vent


# --- the rhythm ---

func test_a_vent_warns_before_it_flares() -> void:
	var cycle := VentCycle.new(3.0, 0.8, 0.5, 0.0)
	assert_eq(cycle.state_at(0.1), VentCycle.IDLE)
	assert_eq(cycle.state_at(1.8), VentCycle.WARN)
	assert_eq(cycle.state_at(2.6), VentCycle.FLARE)
	assert_eq(cycle.state_at(3.1), VentCycle.IDLE, "and the cycle repeats")


func test_an_offset_shifts_the_whole_cycle() -> void:
	var cycle := VentCycle.new(3.0, 0.8, 0.5, 1.5)
	assert_eq(cycle.state_at(1.0), VentCycle.FLARE)


func test_the_glow_fills_over_the_warning() -> void:
	var cycle := VentCycle.new(3.0, 0.8, 0.5, 0.0)
	assert_near(cycle.warn_progress(1.0), 0.0, "no glow at rest")
	assert_near(cycle.warn_progress(1.7), 0.0)
	assert_near(cycle.warn_progress(2.1), 0.5)
	assert_near(cycle.warn_progress(2.6), 0.0, "the flare itself is no warning")


func test_room_vents_follow_the_spec_and_neighbours_take_turns() -> void:
	assert_near(FloorVent.PERIOD, 3.0)
	assert_near(FloorVent.WARN, 0.8)
	assert_near(FloorVent.FLARE, 0.5)
	assert_eq(FloorVent.PLAYER_DAMAGE, 1)
	assert_near(FloorVent.ENEMY_DAMAGE, 20.0)
	var here := FloorVent.offset_for(Vector2i(4, 4), FloorVent.PERIOD)
	for side in RoomLayout.SIDES:
		var there := FloorVent.offset_for(Vector2i(4, 4) + side, FloorVent.PERIOD)
		assert_near(absf(here - there), FloorVent.PERIOD / 2.0)
		var a := VentCycle.new(FloorVent.PERIOD, FloorVent.WARN, FloorVent.FLARE, here)
		var b := VentCycle.new(FloorVent.PERIOD, FloorVent.WARN, FloorVent.FLARE, there)
		for step in 30:
			var time := step * 0.1
			assert_false(a.state_at(time) == VentCycle.FLARE and b.state_at(time) == VentCycle.FLARE, "never both at once")


func test_a_warning_shows_long_enough_to_step_off() -> void:
	var walk := PlayerStats.BASE_SPEED * (FloorVent.WARN - 0.3)
	assert_true(walk > FloorVent.REACH * 2.0, "after reacting he can cross a whole vent, %f" % walk)


func test_a_flare_covers_its_own_cell_only() -> void:
	var center := RoomBackdrop.cell_center(Vector2i(5, 5))
	assert_true(FloorVent.covers(center, center + Vector2(10, -10)))
	assert_false(FloorVent.covers(center, RoomBackdrop.cell_center(Vector2i(6, 5))))
	assert_false(FloorVent.covers(center, center + Vector2(15, 0)), "grazing the edge does not count")
	assert_true(FloorVent.touches(center, Rect2(center + Vector2(8, 8), Vector2(20, 20))))
	assert_false(FloorVent.touches(center, Rect2(center + Vector2(16, 0), Vector2(20, 20))))


# --- a boss's pattern ---

func test_a_forced_flare_warns_flares_and_starts_the_rhythm_afresh() -> void:
	var vent := _vent()
	vent.force_flare(0.6, 0.4)
	assert_true(vent.is_warning())
	vent._physics_process(0.3)
	assert_near(vent.warn_progress(), 0.5)
	vent._physics_process(0.31)
	assert_true(vent.is_flaring())
	vent._physics_process(0.41)
	assert_eq(vent.state(), VentCycle.IDLE, "a forced flare is never followed by a second one at once")
	vent.free()


func test_a_held_vent_stays_cold_through_its_own_flare() -> void:
	var vent := _vent()
	vent.hold(3.0)
	for i in 28:
		vent._physics_process(0.1)
		assert_eq(vent.state(), VentCycle.IDLE)
	vent.free()


func test_a_shorter_period_flares_more_often() -> void:
	var vent := _vent()
	vent.set_period_scale(0.75)
	assert_near(vent.cycle.period, 2.25)
	assert_near(vent.cycle.warn, FloorVent.WARN, "the warning keeps its length")
	vent.free()


# --- burning ground ---

func test_burning_ground_lingers_after_it_lands() -> void:
	var strike := GroundStrike.new()
	strike.setup(null, 22.0, 0.8, 0.0, 0.0, -1, 2.5)
	assert_near(strike.linger(), 2.5)
	assert_false(strike.advance(0.5))
	assert_true(strike.advance(0.31), "it lands")
	assert_true(strike.is_burning())
	strike.tick_burn(2.4)
	assert_true(strike.is_burning())
	strike.tick_burn(0.11)
	assert_false(strike.is_burning(), "and burns out")
	strike.free()


func test_a_plain_strike_does_not_burn() -> void:
	var strike := GroundStrike.new()
	strike.setup(null, 22.0, 0.5)
	strike.advance(0.6)
	assert_false(strike.is_burning())
	strike.free()


func test_burning_ground_hurts_each_body_at_most_once_in_a_while() -> void:
	var strike := GroundStrike.new()
	strike.setup(null, 22.0, 0.1, 0.0, 0.0, -1, 3.0)
	strike.advance(0.2)
	assert_true(GroundStrike.burns(Vector2.ZERO, 22.0, Vector2(10, 0), strike.burn_wait_of(7)))
	strike.mark_burned(7)
	assert_false(GroundStrike.burns(Vector2.ZERO, 22.0, Vector2(10, 0), strike.burn_wait_of(7)), "just burned")
	assert_true(GroundStrike.burns(Vector2.ZERO, 22.0, Vector2(10, 0), strike.burn_wait_of(8)), "another body is its own")
	strike.tick_burn(GroundStrike.BURN_EVERY - 0.05)
	assert_false(GroundStrike.burns(Vector2.ZERO, 22.0, Vector2(10, 0), strike.burn_wait_of(7)))
	strike.tick_burn(0.06)
	assert_true(GroundStrike.burns(Vector2.ZERO, 22.0, Vector2(10, 0), strike.burn_wait_of(7)), "again after %f" % GroundStrike.BURN_EVERY)
	assert_false(GroundStrike.burns(Vector2.ZERO, 22.0, Vector2(30, 0), 0.0), "outside the fire")
	assert_near(GroundStrike.BURN_EVERY, 0.6)
	strike.free()


# --- vents in a room ---

func test_vents_are_a_known_symbol_that_blocks_nothing() -> void:
	assert_true(RoomLayout.ALLOWED.contains(RoomLayout.SYMBOL_VENT))
	assert_false(RoomLayout.SOLID_SYMBOLS.contains(RoomLayout.SYMBOL_VENT))
	assert_false(RoomLayout.WALLS_AND_BOMB_ONLY.contains(RoomLayout.SYMBOL_VENT))
	assert_false(RoomLayout.DECOR_SYMBOLS.contains(RoomLayout.SYMBOL_VENT))
	var layout := _room_with({Vector2i(9, 6): "U", Vector2i(10, 6): "U"})
	assert_eq(layout.validate().size(), 0, str(layout.validate()))


func test_vents_keep_two_cells_clear_of_every_door() -> void:
	var near := _room_with({Vector2i(3, 5): "U"})
	assert_true(near.validate().size() > 0, "two cells from the west door is too close")
	var clear := _room_with({Vector2i(4, 5): "U"})
	assert_eq(clear.validate().size(), 0, str(clear.validate()))


func test_nothing_extra_starts_or_drops_onto_a_vent() -> void:
	var layout := _room_with({Vector2i(9, 6): "U"})
	assert_false(layout.spare_fighter_cells().has(Vector2i(9, 6)))
	var wanted: Array[Vector2i] = [Vector2i(9, 6)]
	assert_false(layout.open_spots_near(wanted).has(Vector2i(9, 6)))
