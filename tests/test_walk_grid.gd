extends TestCase

# A room 10 by 7 with a wall across its middle column, open only at the bottom row.
const WALLED := [
	"##########",
	"#....#...#",
	"#....#...#",
	"#....#...#",
	"#....#...#",
	"#........#",
	"##########",
]


func _grid(rows: Array) -> WalkGrid:
	return WalkGrid.from_rows(PackedStringArray(rows), RoomLayout.SOLID_SYMBOLS)


func _at(cell: Vector2i) -> Vector2:
	return RoomBackdrop.cell_center(cell)


func test_walls_and_solid_props_block_and_floor_does_not() -> void:
	var grid := _grid(["#####", "#.O.#", "#.f.#", "#####"])
	assert_true(grid.is_open(Vector2i(1, 1)))
	assert_false(grid.is_open(Vector2i(0, 1)), "wall")
	assert_false(grid.is_open(Vector2i(2, 1)), "a rock")
	assert_true(grid.is_open(Vector2i(2, 2)), "a vase blocks nothing")
	assert_false(grid.is_open(Vector2i(-1, 1)), "outside the room")


func test_a_clear_line_is_walked_straight() -> void:
	var grid := _grid(WALLED)
	assert_true(grid.line_is_clear(_at(Vector2i(1, 1)), _at(Vector2i(4, 4)), 10.0))
	assert_true(grid.line_is_clear(_at(Vector2i(1, 5)), _at(Vector2i(8, 5)), 10.0), "along the open bottom row")


func test_a_wall_between_blocks_the_line() -> void:
	var grid := _grid(WALLED)
	assert_false(grid.line_is_clear(_at(Vector2i(2, 2)), _at(Vector2i(7, 2)), 10.0))


func test_a_wide_body_cannot_scrape_past_a_corner() -> void:
	var grid := _grid(WALLED)
	# Along row 4 the thin line passes under nothing, but a body reaching 20 px up touches the wall.
	var from := _at(Vector2i(2, 5)) + Vector2(0, -8)
	var to := _at(Vector2i(8, 5)) + Vector2(0, -8)
	assert_true(grid.line_is_clear(from, to, 2.0))
	assert_false(grid.line_is_clear(from, to, 20.0))


func test_the_next_step_heads_for_the_gap() -> void:
	var grid := _grid(WALLED)
	var next := grid.next_cell(Vector2i(3, 2), Vector2i(7, 2))
	assert_eq(next.y, 3, "down toward the open row")
	assert_true(grid.steps_to_goal(next) < grid.steps_to_goal(Vector2i(3, 2)))


func test_following_the_steps_reaches_the_goal_around_the_wall() -> void:
	var grid := _grid(WALLED)
	var cell := Vector2i(2, 1)
	var goal := Vector2i(7, 1)
	var visited := [cell]
	for i in 30:
		if cell == goal:
			break
		cell = grid.next_cell(cell, goal)
		assert_true(grid.is_open(cell), str(cell))
		visited.append(cell)
	assert_eq(cell, goal)
	assert_true(visited.has(Vector2i(5, 5)), "it went through the gap")


func test_a_diagonal_step_never_cuts_a_blocked_corner() -> void:
	var grid := _grid(["#####", "#..##", "#.#.#", "#...#", "#####"])
	var next := grid.next_cell(Vector2i(1, 1), Vector2i(3, 3))
	assert_eq(next, Vector2i(1, 2), "down, since the way right ends at a shut corner")


func test_no_route_when_the_goal_is_shut_off() -> void:
	var grid := _grid(["#######", "#..#..#", "#..#..#", "#######"])
	assert_eq(grid.next_cell(Vector2i(1, 1), Vector2i(5, 1)), WalkGrid.NO_CELL)


func test_a_broken_prop_opens_a_shorter_way() -> void:
	var grid := _grid(["#######", "#..O..#", "#.###.#", "#.....#", "#######"])
	assert_eq(grid.next_cell(Vector2i(2, 1), Vector2i(4, 1)), Vector2i(1, 1), "the long way round, through the bottom")
	grid.open_cell(Vector2i(3, 1))
	assert_eq(grid.next_cell(Vector2i(2, 1), Vector2i(4, 1)), Vector2i(3, 1), "straight through where the rock was")


func test_standing_on_a_cell_counted_as_blocked_still_finds_a_way_off() -> void:
	var grid := _grid(["######", "#.O..#", "#....#", "######"])
	var next := grid.next_cell(Vector2i(2, 1), Vector2i(4, 1))
	assert_true(grid.is_open(next), str(next))
	assert_eq(next, Vector2i(3, 1))
