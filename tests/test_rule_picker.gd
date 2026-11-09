extends TestCase

const SEEDS := ["1", "42", "777", "90210", "123456789"]


func _floor_map(seed_text: String) -> FloorMap:
	return RunCheckpoint.build_floor(load("res://data/floors/floor_1.tres"), seed_text)


func test_every_rule_has_sign_text_an_action_and_a_button() -> void:
	assert_eq(RoomRule.ALL.size(), 7)
	for rule in RoomRule.ALL:
		assert_false(RoomRule.sign_text(rule).is_empty(), rule)
		assert_false(RoomRule.action_of(rule).is_empty(), rule)
	assert_eq(RoomRule.button_of(RoomRule.NO_CANE), "attack")
	assert_eq(RoomRule.button_of(RoomRule.NO_HORSEPLAY), "dodge")
	assert_eq(RoomRule.button_of(RoomRule.TEETH_IN), "throw")
	assert_eq(RoomRule.button_of(RoomRule.NO_EXPLOSIVES), "bomb")
	assert_eq(RoomRule.button_of(RoomRule.NO_FOOD), "potion")
	assert_eq(RoomRule.button_of(RoomRule.EXHIBITS), "")
	assert_eq(RoomRule.button_of(RoomRule.NO_LOITERING), "")


func test_a_rule_only_applies_where_it_can_matter() -> void:
	var bare := {"has_bomb": false, "has_potion": false, "has_breakables": false}
	assert_false(RoomRule.can_apply(RoomRule.NO_EXPLOSIVES, bare))
	assert_false(RoomRule.can_apply(RoomRule.NO_FOOD, bare))
	assert_false(RoomRule.can_apply(RoomRule.EXHIBITS, bare))
	assert_true(RoomRule.can_apply(RoomRule.NO_CANE, bare))
	var full := {"has_bomb": true, "has_potion": true, "has_breakables": true}
	for rule in RoomRule.ALL:
		assert_true(RoomRule.can_apply(rule, full), rule)


func test_floor_one_has_exactly_one_combat_rule_room() -> void:
	for seed_text in SEEDS:
		var map := _floor_map(seed_text)
		var ids := RulePicker.rule_rooms(map, 1, seed_text)
		assert_eq(ids.size(), 1, "seed %s" % seed_text)
		assert_eq(map.room(ids[0]).room_type, RoomLayout.TYPE_COMBAT, "seed %s" % seed_text)


func test_the_prototype_posts_no_rules_below_floor_one() -> void:
	for seed_text in SEEDS:
		assert_eq(RulePicker.rule_rooms(_floor_map(seed_text), 2, seed_text).size(), 0)


func test_the_counts_follow_the_depth_table() -> void:
	assert_eq(RulePicker.rule_room_count(1, 6, 99), 1)
	assert_eq(RulePicker.rule_room_count(2, 6, 99), 2)
	assert_eq(RulePicker.rule_room_count(3, 10, 99), 4, "40% of 10")
	assert_eq(RulePicker.rule_room_count(3, 3, 99), 2, "at least 2")
	assert_eq(RulePicker.rule_room_count(2, 1, 99), 1, "never more than the combat rooms")
	assert_eq(RulePicker.rule_room_count(2, 6, 1), 0, "above the enabled depth")


func test_the_same_seed_picks_the_same_rooms_and_rule() -> void:
	var ready := {"has_bomb": true, "has_potion": true, "has_breakables": true}
	for seed_text in SEEDS:
		var map := _floor_map(seed_text)
		var first := RulePicker.rule_rooms(map, 1, seed_text)
		assert_eq(RulePicker.rule_rooms(map, 1, seed_text), first)
		assert_eq(RulePicker.pick_rule(seed_text, first[0], ready), RulePicker.pick_rule(seed_text, first[0], ready))


func test_picking_never_returns_a_rule_that_cannot_apply() -> void:
	var bare := {"has_bomb": false, "has_potion": false, "has_breakables": false}
	for i in 200:
		var rule := RulePicker.pick_rule(str(i), i % 9, bare)
		assert_true(RoomRule.can_apply(rule, bare), rule)
