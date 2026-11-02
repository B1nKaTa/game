extends TestCase


func _layout(rows: Array) -> RoomLayout:
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_COMBAT
	layout.rows = PackedStringArray(rows)
	return layout


# A plain 20 by 11 combat room with two enemies, changed by putting symbols at cells.
func _room(changes: Dictionary = {}) -> Array:
	var rows := ["####################"]
	for y in range(1, 10):
		rows.append("#..................#")
	rows.append("####################")
	rows[5] = "#.......E..E.......#"
	for cell: Vector2i in changes:
		var row: String = rows[cell.y]
		rows[cell.y] = row.substr(0, cell.x) + changes[cell] + row.substr(cell.x + 1)
	return rows


func _valid(changes: Dictionary) -> bool:
	return _layout(_room(changes)).validate().is_empty()


# A line of one symbol down column 14, from top to bottom, except the gap row.
func _line(symbol: String, gap_row := -1) -> Dictionary:
	var changes := {}
	for y in range(1, 10):
		if y != gap_row:
			changes[Vector2i(14, y)] = symbol
	return changes


func test_new_symbols_are_allowed() -> void:
	var changes := {Vector2i(4, 3): "O", Vector2i(7, 3): "Q", Vector2i(10, 3): "V", Vector2i(13, 3): "Z", Vector2i(16, 3): "g",
		Vector2i(4, 7): "n", Vector2i(7, 7): "w", Vector2i(10, 7): "u", Vector2i(13, 7): "k", Vector2i(16, 7): "t"}
	assert_eq(_layout(_room(changes)).validate().size(), 0, str(_layout(_room(changes)).validate()))


func test_a_rock_line_cannot_be_what_leads_to_a_door() -> void:
	assert_false(_valid(_line("O")), "the east door would need a bomb")


func test_a_rock_line_with_a_gap_is_fine() -> void:
	assert_true(_valid(_line("O", 3)))


func test_a_hole_line_fails_because_nothing_breaks_a_hole() -> void:
	assert_false(_valid(_line("V")))
	assert_false(_valid(_line("V", -1)), "a bomb does not help")


func test_a_hole_line_with_a_gap_is_fine() -> void:
	assert_true(_valid(_line("V", 8)))


func test_a_line_of_barrels_is_fine_because_the_cane_breaks_them() -> void:
	assert_true(_valid(_line("Q")))


func test_a_floor_cell_ringed_by_holes_is_unreachable() -> void:
	var ring := {Vector2i(5, 2): "V", Vector2i(4, 3): "V", Vector2i(6, 3): "V", Vector2i(5, 4): "V", Vector2i(5, 3): "I"}
	assert_false(_valid(ring))


func test_a_hole_may_not_touch_a_door_cell() -> void:
	assert_false(_valid({Vector2i(11, 2): "V"}), "diagonal to the north door")
	assert_false(_valid({Vector2i(11, 1): "Q"}), "beside the north door")
	assert_false(_valid({Vector2i(10, 2): "O"}), "in front of the north door")
	assert_false(_valid({Vector2i(2, 5): "Z"}), "in front of the west door")


func test_a_prop_on_a_door_cell_fails() -> void:
	assert_false(_valid({Vector2i(10, 1): "O"}))
	assert_false(_valid({Vector2i(1, 5): "V"}))
	assert_false(_valid({Vector2i(18, 5): "Q"}))
	assert_false(_valid({Vector2i(10, 9): "Z"}))


func test_a_prop_two_cells_from_a_door_is_fine() -> void:
	assert_true(_valid({Vector2i(10, 3): "Q"}))
	assert_true(_valid({Vector2i(10, 3): "V"}))
	assert_true(_valid({Vector2i(10, 3): "O"}))


func test_lanterns_hang_in_the_border_wall_only() -> void:
	var rows := _room()
	rows[0] = "####l###############"
	assert_true(_layout(rows).validate().is_empty(), "a lantern on the north wall")
	assert_false(_valid({Vector2i(5, 2): "l"}), "not inside the room")
	var corner := _room()
	corner[0] = "l###################"
	assert_false(_layout(corner).validate().is_empty(), "not in a corner")
	var crack := _room()
	crack[0] = "##########l#########"
	assert_false(_layout(crack).validate().is_empty(), "not where a secret crack goes")


func test_decor_may_lie_beside_a_door() -> void:
	assert_true(_valid({Vector2i(11, 1): "g", Vector2i(9, 2): "n", Vector2i(10, 2): "w"}))


func test_solid_cells_are_known() -> void:
	var layout := _layout(_room({Vector2i(4, 3): "O", Vector2i(7, 3): "Q", Vector2i(10, 3): "V", Vector2i(13, 3): "Z", Vector2i(16, 3): "g"}))
	assert_true(layout.is_solid_at(Vector2i(4, 3)), "rock")
	assert_true(layout.is_solid_at(Vector2i(7, 3)), "barrel")
	assert_true(layout.is_solid_at(Vector2i(10, 3)), "hole")
	assert_false(layout.is_solid_at(Vector2i(13, 3)), "a pile blocks nothing")
	assert_false(layout.is_solid_at(Vector2i(16, 3)), "grass")
	assert_true(layout.is_solid_at(Vector2i(-1, 3)), "off the grid counts as wall")


func test_summons_and_drops_never_land_on_the_new_solids() -> void:
	var layout := _layout(_room({Vector2i(5, 5): "O", Vector2i(6, 5): "Q", Vector2i(7, 5): "V"}))
	for x in [5, 6, 7]:
		var landed := layout.nearest_floor_cell(Vector2i(x, 5))
		assert_false(layout.is_solid_at(landed), "cell %d" % x)


func test_a_coin_in_a_closed_pocket_does_not_fly() -> void:
	var layout := _layout(_room({Vector2i(1, 1): "T", Vector2i(2, 1): "O", Vector2i(1, 2): "O"}))
	assert_false(layout.coin_can_fly_from(Vector2i(1, 1)), "walled in by rocks")
	assert_true(layout.coin_can_fly_from(Vector2i(5, 3)), "open floor")


func test_a_rock_on_open_floor_lets_its_coin_fly() -> void:
	var layout := _layout(_room({Vector2i(4, 3): "O"}))
	assert_true(layout.coin_can_fly_from(Vector2i(4, 3)))


func test_pockets_made_of_holes_hold_their_coins_too() -> void:
	var layout := _layout(_room({Vector2i(1, 1): "T", Vector2i(2, 1): "V", Vector2i(1, 2): "V"}))
	assert_false(layout.coin_can_fly_from(Vector2i(1, 1)))
