extends TestCase

# Feedback 13: a door took Harold into the boss room while he walked Left past it. A door's trigger was a
# circle of ENTER_RADIUS round the middle of the floor cell in front of the wall, so it filled that whole
# floor row beside the opening: walking along the row, sideways past the door, went through it, while the
# opening and its sign are drawn in the wall below and his body stands 20 to 40 px above his feet. A door
# in a wall now enters only once his feet reach its opening, pressed toward the wall's face.

const LAYOUT := "res://data/rooms/floor_1/combat_large_02.tres"
const SIDES: Array[Vector2i] = [RoomLayout.NORTH, RoomLayout.SOUTH, RoomLayout.WEST, RoomLayout.EAST]


# A door of a large floor-1 room on that side, as RoomView makes it, armed (he stepped away first), and
# the marker it watches as his feet.
func _door(side: Vector2i, hits: Array) -> Array:
	# Door._process asks whether interact was pressed (a Slip), which needs the game's actions.
	InputSetup.ensure()
	var layout: RoomLayout = load(LAYOUT)
	var door := Door.new()
	var feet := Marker2D.new()
	door.setup(7, "!", feet, side)
	door.locked = false
	door.position = RoomBackdrop.cell_center(layout.door_cell(side))
	door.entered.connect(func(id: int): hits.append(id))
	feet.position = door.position - Vector2(side if side != Vector2i.ZERO else Vector2i.DOWN) * 80.0
	door._process(0.016)
	return [door, feet]


# Along the wall: to the right of a north or south door, down beside a west or east one.
static func _along(side: Vector2i) -> Vector2:
	return Vector2(absi(side.y), absi(side.x))


# Walks his feet in 1 px steps from one spot to another, as holding a direction does, and says whether
# the door took him.
func _walk(door: Door, feet: Marker2D, from: Vector2, to: Vector2, hits: Array) -> bool:
	var steps := int(ceilf(from.distance_to(to)))
	for i in steps + 1:
		feet.position = from.lerp(to, float(i) / float(maxi(steps, 1)))
		door._process(0.016)
		if not hits.is_empty():
			return true
	return false


func _free(pair: Array) -> void:
	pair[0].free()
	pair[1].free()


# The report: he stood a little beside and above the bottom door, in its floor row, and held Left.
func test_walking_left_along_the_row_past_the_bottom_door_does_not_enter_it() -> void:
	var hits: Array = []
	var pair := _door(RoomLayout.SOUTH, hits)
	var door: Door = pair[0]
	var start := door.position + Vector2(70, 0)
	assert_false(_walk(door, pair[1], start, start + Vector2(-240, 0), hits), "walked past the boss door, row middle")
	_free(pair)


# Anywhere across the door's floor row short of the wall's face, on every side, both ways.
func test_walking_along_the_wall_past_any_door_does_not_enter_it() -> void:
	for side in SIDES:
		for depth in range(-16, int(Door.OPENING_DEPTH)):
			for way: float in [1.0, -1.0]:
				var hits: Array = []
				var pair := _door(side, hits)
				var door: Door = pair[0]
				var across := _along(side) * 70.0 * way
				var level := door.position + Vector2(side) * float(depth)
				var entered := _walk(door, pair[1], level + across, level - across, hits)
				assert_false(entered, "side %s, feet %d px past the door's middle toward the wall, walking %s" % [str(side), depth, "back" if way < 0.0 else "on"])
				_free(pair)


# Walking straight into the opening still takes him through, from the middle and from a little aside.
func test_walking_into_the_opening_enters_it() -> void:
	for side in SIDES:
		for aside: float in [0.0, 8.0, -8.0]:
			var hits: Array = []
			var pair := _door(side, hits)
			var door: Door = pair[0]
			var lane := door.position + _along(side) * aside
			var into := lane + Vector2(side) * Door.OPENING_REACH
			assert_true(_walk(door, pair[1], lane - Vector2(side) * 60.0, into, hits), "side %s, %.0f px aside" % [str(side), aside])
			assert_eq(hits, [7], "into room 7")
			_free(pair)


# Where the full loop stands his feet to go through a door is in its opening.
func test_the_opening_spot_is_in_the_opening() -> void:
	for side in SIDES:
		var hits: Array = []
		var pair := _door(side, hits)
		var door: Door = pair[0]
		var feet: Marker2D = pair[1]
		feet.position = door.opening_spot()
		door._process(0.016)
		assert_eq(hits, [7], "side %s" % str(side))
		_free(pair)


# His shoes reach 9 px (west, east) and 10 px (north, south) past the door cell's middle toward the
# wall, so the opening's spot is one he can stand on.
func test_his_feet_can_reach_the_opening() -> void:
	var reach_across: float = RoomBackdrop.TILE / 2.0 - Player.FEET_BOX_SIZE.x / 2.0
	var reach_down: float = RoomBackdrop.TILE / 2.0 - Player.FEET_BOX_SIZE.y / 2.0
	assert_true(Door.OPENING_DEPTH <= Door.OPENING_REACH, "the spot is inside the opening")
	assert_true(Door.OPENING_REACH < minf(reach_across, reach_down), "%.1f within his reach %.1f" % [Door.OPENING_REACH, minf(reach_across, reach_down)])


# The guard: whatever the side, a door never takes him while his feet are further than ENTER_RADIUS from it.
func test_a_door_never_enters_with_his_feet_beyond_its_radius() -> void:
	for side: Vector2i in [RoomLayout.NORTH, RoomLayout.SOUTH, RoomLayout.WEST, RoomLayout.EAST, Vector2i.ZERO]:
		for x in range(-40, 41, 2):
			for y in range(-40, 41, 2):
				var hits: Array = []
				var pair := _door(side, hits)
				var door: Door = pair[0]
				var feet: Marker2D = pair[1]
				feet.position = door.position + Vector2(x, y)
				door._process(0.016)
				if not hits.is_empty():
					var dist := door.position.distance_to(feet.position)
					assert_true(dist <= Door.ENTER_RADIUS, "side %s entered with feet %.1f px away at %s" % [str(side), dist, str(Vector2(x, y))])
				_free(pair)


# A door standing on the floor (the stairwell's lift, the run door) has no wall: it still takes him
# anywhere within ENTER_RADIUS, from any side.
func test_a_lift_still_enters_from_any_side_within_its_radius() -> void:
	for at: Vector2 in [Vector2(0, 12), Vector2(0, -12), Vector2(12, 0), Vector2(-12, 0)]:
		var hits: Array = []
		var pair := _door(Vector2i.ZERO, hits)
		var door: Door = pair[0]
		door.lift = true
		var feet: Marker2D = pair[1]
		feet.position = door.position + at
		door._process(0.016)
		assert_eq(hits, [7], "feet at %s" % str(at))
		_free(pair)
