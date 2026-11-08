extends TestCase


func test_a_door_arms_once_the_player_is_out_of_range() -> void:
	assert_true(Door.next_armed(false, false))
	assert_false(Door.next_armed(false, true), "still standing in the doorway")
	assert_true(Door.next_armed(true, true), "stays armed when walking back in")


func test_an_armed_open_door_is_entered_when_in_range() -> void:
	assert_true(Door.should_enter(false, false, false, true, true))


func test_arriving_on_a_door_does_not_enter_it() -> void:
	assert_false(Door.should_enter(false, false, false, false, true))


func test_a_locked_door_is_not_entered() -> void:
	assert_false(Door.should_enter(true, false, false, true, true))


func test_a_door_needing_a_slip_is_not_entered() -> void:
	assert_false(Door.should_enter(false, true, false, true, true))


func test_a_used_door_is_not_entered_twice() -> void:
	assert_false(Door.should_enter(false, false, true, true, true))


func test_out_of_range_is_not_entered() -> void:
	assert_false(Door.should_enter(false, false, false, true, false))


func test_a_slip_can_only_be_spent_on_an_open_door_in_range() -> void:
	assert_true(Door.can_spend_key(true, false, true, true))
	assert_false(Door.can_spend_key(false, false, true, true), "already unlocked")
	assert_false(Door.can_spend_key(true, true, true, true), "room still in combat")
	assert_false(Door.can_spend_key(true, false, false, true), "too far away")
	assert_false(Door.can_spend_key(true, false, true, false), "no slip")


func test_rearming_lets_a_door_be_used_after_returning() -> void:
	var door := Door.new()
	door._used = true
	door._armed = true
	door.rearm()
	assert_false(door._used)
	assert_false(door._armed, "must be left before it can fire again")
	door.free()


func test_a_prompt_on_an_east_door_stays_inside_the_room() -> void:
	assert_true(Door.prompt_x(50.0, RoomLayout.EAST) + 50.0 < 0.0, "drawn to the left of the door")
	for side: Vector2i in [RoomLayout.NORTH, RoomLayout.SOUTH, RoomLayout.WEST]:
		assert_true(Door.prompt_x(50.0, side) > 0.0, "drawn to the right of the door")


# The way down is a cage lift: shut, half folded and open pictures, each there in the props, as tall as
# a wall face and wider than Grandpa.
func test_the_lift_shows_shut_half_and_open_gates() -> void:
	assert_eq(Door.lift_state(0.0), "closed")
	assert_eq(Door.lift_state(0.5), "half")
	assert_eq(Door.lift_state(1.0), "open")
	for state in ["closed", "half", "open"]:
		var art := PropArt.state_texture(Door.LIFT_ART, state)
		assert_true(art != null, state)
		if art != null:
			assert_true(art.get_width() >= 40 and art.get_height() >= 64, "%s is %s" % [state, art.get_size()])


# A lift that comes with the boss's fall starts shut and folds open over LIFT_TIME; the trigger stays
# the door's own.
func test_a_lift_arriving_open_folds_its_gates_open() -> void:
	var door := Door.new()
	door.lift = true
	door.lift_opens_on_arrival = true
	door.locked = false
	door._update_gate(0.0)
	assert_eq(door.gate(), 0.0, "shut as it appears")
	door._update_gate(Door.LIFT_TIME / 2.0)
	assert_eq(Door.lift_state(door.gate()), "half")
	door._update_gate(Door.LIFT_TIME)
	assert_eq(door.gate(), 1.0)
	assert_eq(Door.ENTER_RADIUS, 18.0, "the same trigger as before")
	door.free()


# The stairwell and the Waiting Room's run door are lifts; doors in walls stay openings.
func test_the_ways_down_are_lifts() -> void:
	var view := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	var stairwell := view.substr(view.find("func add_stairwell("), 900)
	assert_true(stairwell.contains("door.lift = true") and stairwell.contains("door.lift_opens_on_arrival = true"))
	var wall := view.substr(view.find("func _add_door("), 500)
	assert_false(wall.contains("lift"))
	var room := FileAccess.get_file_as_string("res://scripts/scenes/waiting_room.gd")
	assert_true(room.substr(room.find("func _add_run_door("), 400).contains("door.lift = true"))
	assert_true(view.substr(view.find("func add_stairwell("), 900).contains("layout.lift_cell(_choice_cells)"))


# In every floor's boss rooms the lift stands against the north wall, clear of the north door and of
# the boss's items, not free in the middle of the room.
func test_the_lift_stands_against_the_north_wall() -> void:
	var rooms := 0
	for floor_dir in DirAccess.get_directories_at("res://data/rooms/"):
		var dir := "res://data/rooms/%s/" % floor_dir
		for file in DirAccess.get_files_at(dir):
			if not file.begins_with("floor_boss") or not file.ends_with(".tres"):
				continue
			var layout: RoomLayout = load(dir + file)
			var size := layout.size_in_cells()
			var middle := Vector2i(size.x / 2, size.y / 2)
			var items: Array[Vector2i] = [layout.nearest_floor_cell(middle)]
			var cell := layout.lift_cell(items)
			var name := floor_dir + "/" + file
			rooms += 1
			assert_eq(layout.symbol_at(cell), RoomLayout.SYMBOL_FLOOR, name + ": on plain floor")
			assert_eq(layout.symbol_at(cell + RoomLayout.NORTH), RoomLayout.SYMBOL_WALL, name + ": the north wall right above it")
			assert_true(absi(cell.x - layout.door_cell(RoomLayout.NORTH).x) >= RoomLayout.LIFT_DOOR_GAP, name + ": clear of the north door")
			assert_false(layout.touches_a_door(cell), name + ": off the door cells")
			assert_true(Vector2(cell - items[0]).length() >= RoomLayout.PICKUP_SPACING, name + ": clear of the boss's items")
	assert_true(rooms >= 10, "every floor has boss rooms: %d" % rooms)
