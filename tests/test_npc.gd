extends TestCase

const MERCHANT_PATH := "res://data/npcs/shop_merchant.tres"


func _lines(texts: Array) -> Array[String]:
	var lines: Array[String] = []
	lines.assign(texts)
	return lines


func _shops() -> Array[RoomLayout]:
	var shops: Array[RoomLayout] = []
	for folder in ["floor_1", "cemetery", "sunset_shores"]:
		for layout in RoomCatalog.load_valid("res://data/rooms/%s/" % folder):
			if layout.room_type == RoomLayout.TYPE_SHOP:
				shops.append(layout)
	return shops


# --- talking ---

func test_each_press_says_the_next_line_and_goes_round_again() -> void:
	var talk := NpcTalk.new(_lines(["One.", "Two.", "Three."]))
	assert_eq(talk.showing(), "", "nothing until he is asked")
	assert_eq(talk.talk(), "One.")
	assert_eq(talk.showing(), "One.")
	assert_eq(talk.talk(), "Two.", "a press while a line shows moves on")
	assert_eq(talk.talk(), "Three.")
	assert_eq(talk.talk(), "One.", "after the last comes the first")


func test_a_line_fades_after_a_few_seconds() -> void:
	var talk := NpcTalk.new(_lines(["Hello."]))
	talk.talk()
	talk.tick(NpcTalk.SHOW_TIME - 0.1)
	assert_eq(talk.showing(), "Hello.")
	talk.tick(0.2)
	assert_eq(talk.showing(), "")
	assert_true(NpcTalk.SHOW_TIME >= 2.0 and NpcTalk.SHOW_TIME <= 5.0, "a few seconds")


func test_someone_with_nothing_to_say_says_nothing() -> void:
	var talk := NpcTalk.new(_lines([]))
	assert_eq(talk.talk(), "")
	assert_eq(talk.showing(), "")


func test_talking_needs_him_in_reach() -> void:
	var none: Array[float] = []
	assert_true(NpcTalk.answers(30.0, 40.0, none))
	assert_false(NpcTalk.answers(41.0, 40.0, none))


func test_the_nearest_thing_answers_the_interact_key() -> void:
	var ware_near: Array[float] = [10.0]
	var ware_far: Array[float] = [35.0]
	assert_false(NpcTalk.answers(20.0, 40.0, ware_near), "a ware nearer than him takes the press")
	assert_true(NpcTalk.answers(20.0, 40.0, ware_far), "he is nearer than the ware")


# --- the merchant ---

func test_the_merchant_is_a_plain_placeholder_with_three_lines() -> void:
	var def: NpcDef = load(MERCHANT_PATH)
	assert_eq(def.id, "shop_merchant")
	assert_eq(def.display_name, "Shopkeeper")
	assert_eq(def.lines.size(), 3)
	for line in def.lines:
		assert_false(line.is_empty())
	assert_true(def.body_size.x > 0.0 and def.body_size.y > 0.0)
	assert_true(def.color.get_luminance() >= 0.3, "bright enough to read in a dim room")


func test_nothing_can_hit_the_merchant_or_bump_into_him() -> void:
	var npc := Npc.new()
	npc.setup(load(MERCHANT_PATH), null)
	npc._ready()
	# An Npc is a Node2D, never a body, so only its children could be solid.
	assert_false(npc.is_in_group("enemies"))
	assert_false(npc.is_in_group("breakable"))
	for child in npc.get_children():
		assert_false(child is CollisionObject2D or child is CollisionShape2D, "nothing solid")
	npc.free()


func test_the_merchant_talks_through_his_lines() -> void:
	var def: NpcDef = load(MERCHANT_PATH)
	var npc := Npc.new()
	npc.setup(def, null)
	assert_eq(npc.talk(), def.lines[0])
	assert_eq(npc.showing(), def.lines[0])
	assert_eq(npc.talk(), def.lines[1])
	npc.free()


# --- where he stands ---

func test_every_shop_has_a_spot_for_the_merchant_clear_of_everything_else() -> void:
	var shops := _shops()
	assert_true(shops.size() >= 3)
	for layout in shops:
		var cell := layout.merchant_cell()
		var placed: Array[Vector2i] = [cell]
		var rewards := layout.plan_reward_cells(ProgressData.RETIREMENT_TIERS.size(), placed)
		var name := layout.resource_path
		assert_eq(rewards.size(), ProgressData.RETIREMENT_TIERS.size(), "%s: every tier still has a spot" % name)
		assert_true(cell != Vector2i(-1, -1), name)
		assert_eq(layout.symbol_at(cell), RoomLayout.SYMBOL_FLOOR, name)
		var others: Array[Vector2i] = layout.cells_of("S")
		others.append_array(layout.cells_of("P"))
		others.append_array(rewards)
		for other in others:
			assert_true(maxi(absi(cell.x - other.x), absi(cell.y - other.y)) >= RoomLayout.PICKUP_SPACING, "%s: %s too near %s" % [name, str(cell), str(other)])
		for side in RoomLayout.SIDES:
			var offset := cell - layout.door_cell(side)
			assert_true(maxi(absi(offset.x), absi(offset.y)) > RoomLayout.MERCHANT_DOOR_CLEARANCE, "%s: too near a door" % name)


func test_reward_spots_keep_clear_of_whatever_they_must_avoid() -> void:
	var layout := RoomLayout.new()
	layout.rows = PackedStringArray([
		"############",
		"#..........#",
		"#.....P....#",
		"#..........#",
		"#..........#",
		"#..........#",
		"#..........#",
		"############"])
	var plain := layout.plan_reward_cells(1)
	var avoid: Array[Vector2i] = [plain[0]]
	var moved := layout.plan_reward_cells(1, avoid)
	assert_true(maxi(absi(moved[0].x - plain[0].x), absi(moved[0].y - plain[0].y)) >= RoomLayout.PICKUP_SPACING, str(moved))


func test_his_reach_never_meets_a_ware_the_plan_or_a_reward() -> void:
	# Three cells apart, his talk reach and any other press-to-use reach never overlap.
	var apart := RoomLayout.PICKUP_SPACING * RoomBackdrop.TILE
	assert_true(apart > Npc.TALK_RADIUS + RetirementStation.USE_RADIUS, "the plan")
	assert_true(apart > Npc.TALK_RADIUS + Pickup.COLLECT_RADIUS + absf(Player.FEET_OFFSET.y), "a ware or a reward")


func test_the_merchant_stands_near_the_middle_of_his_wares() -> void:
	var layout := RoomLayout.new()
	layout.rows = PackedStringArray([
		"################",
		"#..............#",
		"#..S.......S...#",
		"#..............#",
		"#..............#",
		"#..............#",
		"#.............P#",
		"################"])
	var cell := layout.merchant_cell()
	assert_true(cell.x >= 5 and cell.x <= 9, str(cell))
