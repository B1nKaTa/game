extends TestCase


func _run() -> RunState:
	var upgrades: Array[UpgradeDef] = []
	return RunState.new(upgrades, {})


func _item(id: String) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	return item


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	return rng


func test_door_icons_cover_all_room_types() -> void:
	assert_eq(RoomRules.door_icon(RoomLayout.TYPE_COMBAT), "C")
	assert_eq(RoomRules.door_icon(RoomLayout.TYPE_ITEM), "I")
	assert_eq(RoomRules.door_icon(RoomLayout.TYPE_HEALING), "H")
	assert_eq(RoomRules.door_icon(RoomLayout.TYPE_SIDE), "?")
	assert_eq(RoomRules.door_icon(RoomLayout.TYPE_MINI_BOSS), "M")
	assert_eq(RoomRules.door_icon(RoomLayout.TYPE_FLOOR_BOSS), "B")


func test_pick_items_skips_owned_items() -> void:
	var run := _run()
	var owned := _item("owned")
	run.add_item(owned)
	var all: Array[ItemDef] = [owned, _item("a"), _item("b")]
	var picked := RoomRules.pick_items(all, run, 2, _rng())
	assert_eq(picked.size(), 2)
	for item in picked:
		assert_true(item.id != "owned")


func test_pick_items_gives_distinct_items() -> void:
	var all: Array[ItemDef] = [_item("a"), _item("b"), _item("c")]
	var picked := RoomRules.pick_items(all, _run(), 2, _rng())
	assert_true(picked[0].id != picked[1].id)


func test_pick_items_returns_fewer_when_running_out() -> void:
	var run := _run()
	var only := _item("only")
	run.add_item(only)
	var all: Array[ItemDef] = [only, _item("last")]
	assert_eq(RoomRules.pick_items(all, run, 2, _rng()).size(), 1)
