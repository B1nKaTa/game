extends TestCase

# What is left of the Golden Years Mall: its decor kinds and props, which Task 4 of the paths rework
# retires. The Cinema's own floor tests are in test_cinema_floor.gd.


func _def() -> FloorDef:
	return load("res://data/floors/flashback_cinema.tres")


func _floor(id: String) -> FloorDef:
	return load("res://data/floors/%s.tres" % id)


func _difference(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


# --- its look ---

func test_fluorescent_panels_are_lights_and_benches_are_not() -> void:
	assert_true(RoomDecor.is_light(RoomDecor.FLUORESCENT))
	assert_false(RoomDecor.is_light(RoomDecor.BENCH))
	assert_false(RoomDecor.is_light(RoomDecor.FOOD_TABLE))


func test_mall_props_break_as_the_spec_says() -> void:
	for prop: BreakableBlock in [ShoppingCart.new(), GumballMachine.new()]:
		assert_true(prop.is_solid())
		for source in [BreakableBlock.SOURCE_CANE, BreakableBlock.SOURCE_BLAST, BreakableBlock.SOURCE_BOSS]:
			assert_true(prop.can_break_by(source), source)
		prop.free()
	var sign := SaleSign.new()
	assert_false(sign.is_solid())
	assert_true(sign.can_break_by(BreakableBlock.SOURCE_CANE))
	sign.free()
	for prop: BreakableBlock in [MallPlanter.new(), MallFountain.new()]:
		assert_true(prop.is_solid())
		assert_false(prop.can_break_by(BreakableBlock.SOURCE_CANE), "solid")
		assert_true(prop.can_break_by(BreakableBlock.SOURCE_BLAST))
		assert_true(prop.can_break_by(BreakableBlock.SOURCE_BOSS))
		prop.free()
	for symbol in [RoomLayout.SYMBOL_CART, RoomLayout.SYMBOL_GUMBALL, RoomLayout.SYMBOL_PLANTER, RoomLayout.SYMBOL_FOUNTAIN]:
		assert_true(RoomLayout.SOLID_SYMBOLS.contains(symbol), symbol)
		assert_false(RoomLayout.WALLS.contains(symbol), symbol)
		assert_false(RoomLayout.DECOR_SYMBOLS.contains(symbol), symbol)
	for symbol in [RoomLayout.SYMBOL_PLANTER, RoomLayout.SYMBOL_FOUNTAIN]:
		assert_true(RoomLayout.WALLS_AND_BOMB_ONLY.contains(symbol), symbol)
	assert_false(RoomLayout.SOLID_SYMBOLS.contains(RoomLayout.SYMBOL_SALE_SIGN))
	assert_true(RoomLayout.DECOR_SYMBOLS.contains(RoomLayout.SYMBOL_SALE_SIGN))
