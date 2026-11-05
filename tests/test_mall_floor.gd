extends TestCase

# What is left of the Golden Years Mall on the Flashback Cinema floor: its enemies, bosses and props,
# which Task 4 of the paths rework retires. The Cinema's own floor tests are in test_cinema_floor.gd.


func _def() -> FloorDef:
	return load("res://data/floors/flashback_cinema.tres")


func _floor(id: String) -> FloorDef:
	return load("res://data/floors/%s.tres" % id)


func _difference(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


# --- the Mall's enemies and bosses, which still hold the floor until Task 4 swaps them ---

func test_its_own_enemies_and_bosses() -> void:
	var def := _def()
	var ids := {}
	for enemy: EnemyDef in def.enemies:
		ids[enemy.id] = true
	for id in ["mall_walker", "mall_cop", "perfume_sprayer", "mall_intern_reaper", "mall_notary_public"]:
		assert_true(ids.has(id), id)
	assert_eq(ids.size(), 5)
	assert_eq(def.enemy_weights.size(), 5)
	assert_eq(def.mini_boss.id, "gloria")
	assert_eq(def.floor_boss.id, "mall_santa")
	assert_eq(def.mimic.id, "mimic")


func test_every_enemy_of_the_floor_can_be_told_apart() -> void:
	var defs: Array[EnemyDef] = []
	defs.assign(_def().enemies)
	defs.append(_def().mini_boss)
	defs.append(_def().floor_boss)
	defs.append(_def().floor_boss.summon)
	for i in defs.size():
		for j in range(i + 1, defs.size()):
			var a := SpriteVisual.readable(defs[i].color)
			var b := SpriteVisual.readable(defs[j].color)
			var size_gap := (defs[i].body_size - defs[j].body_size).length()
			assert_true(_difference(a, b) >= 0.25 or size_gap >= 12.0, "%s and %s look alike" % [defs[i].id, defs[j].id])


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
