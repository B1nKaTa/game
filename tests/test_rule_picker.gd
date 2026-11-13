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


# Leave Canes at Reception only where a fight without the cane is fair (playtest 9, note 20).
func test_no_cane_posts_only_in_a_small_fight() -> void:
	assert_eq(RoomRule.MAX_NO_CANE_ENEMIES, 6)
	assert_true(RoomRule.can_apply(RoomRule.NO_CANE, {"enemy_count": 6}), "six enemies")
	assert_false(RoomRule.can_apply(RoomRule.NO_CANE, {"enemy_count": 7}), "seven enemies")
	assert_true(RoomRule.can_apply(RoomRule.NO_CANE, {}), "a ready dict without the count")
	var crowded := {"has_bomb": true, "has_potion": true, "has_breakables": true, "enemy_count": 30}
	for rule in RoomRule.ALL:
		if rule != RoomRule.NO_CANE:
			assert_true(RoomRule.can_apply(rule, crowded), "%s ignores the count" % rule)


# A room view with count bare enemies in it, fighting.
func _crowd(count: int) -> RoomView:
	var view := RoomView.new()
	for i in count:
		view.add_child(Enemy.new())
	view.debug_set_alive(count)
	return view


func test_a_room_counts_the_enemies_alive_in_it() -> void:
	var view := _crowd(3)
	assert_eq(view.enemy_count(), 3)
	var fallen: Enemy = view.get_child(0)
	fallen._dead = true
	assert_eq(view.enemy_count(), 2, "a fallen enemy does not count")
	view.free()


# The rule the keeper posts on first entry into room 0, the floor's one rule room.
func _posted(view: RoomView, seed_text: String, parts: Dictionary) -> String:
	var keeper := RuleKeeper.new()
	keeper.setup(parts["player"], parts["hud"], parts["run"], Callable())
	keeper.plan_floor(parts["map"], 1, seed_text, FloorProgress.new(parts["map"]))
	keeper.on_room_entered(view, parts["map"].room(0), true)
	var watch := keeper.watch_of(0)
	var rule := watch.rule if watch != null else ""
	keeper.free()
	return rule


func test_the_keeper_counts_the_room_before_posting_no_cane() -> void:
	var map := FloorMap.new()
	for i in 2:
		var room := FloorRoom.new()
		room.id = i
		room.room_type = RoomLayout.TYPE_COMBAT
		room.cell = Vector2i(i, 0)
		map.rooms.append(room)
	map.join(map.room(0), map.room(1))
	map.start_id = 1
	var run := RunState.new([] as Array[UpgradeDef], {})
	var player := Player.new()
	player.setup(run)
	var hud := Hud.new()
	hud.setup(run)
	hud._ready()
	var parts := {"map": map, "run": run, "player": player, "hud": hud}
	var small := _crowd(RoomRule.MAX_NO_CANE_ENEMIES)
	var crowded := _crowd(RoomRule.MAX_NO_CANE_ENEMIES + 1)
	var no_cane_seeds := 0
	for i in 80:
		var seed_text := "crowd%d" % i
		var bare := {"has_bomb": run.bombs > 0, "has_potion": run.potion != null, "has_breakables": false}
		if RulePicker.pick_rule(seed_text, 0, bare) != RoomRule.NO_CANE:
			continue
		no_cane_seeds += 1
		assert_eq(_posted(small, seed_text, parts), RoomRule.NO_CANE, "seed %s: six enemies keep it" % seed_text)
		var other := _posted(crowded, seed_text, parts)
		assert_true(not other.is_empty() and other != RoomRule.NO_CANE, "seed %s: seven enemies post %s" % [seed_text, other])
	assert_true(no_cane_seeds > 0, "some seeds would post No Cane")
	small.free()
	crowded.free()
	hud.free()
	player.free()


func test_floor_one_has_exactly_one_combat_rule_room() -> void:
	for seed_text in SEEDS:
		var map := _floor_map(seed_text)
		var ids := RulePicker.rule_rooms(map, 1, seed_text)
		assert_eq(ids.size(), 1, "seed %s" % seed_text)
		assert_eq(map.room(ids[0]).room_type, RoomLayout.TYPE_COMBAT, "seed %s" % seed_text)


func test_every_floor_posts_rules() -> void:
	assert_eq(RulePicker.rule_room_count(2, 6), 2, "depth 2 by the default enabled depth")
	assert_eq(RulePicker.rule_room_count(4, 10), 4, "deep floors: 40%")
	assert_eq(RulePicker.rule_room_count(5, 3), 2, "at least 2")
	for seed_text in SEEDS:
		var map := _floor_map(seed_text)
		var ids := RulePicker.rule_rooms(map, 2, seed_text)
		assert_eq(ids.size(), mini(2, _combat_count(map)), "seed %s" % seed_text)
		for id in ids:
			assert_eq(map.room(id).room_type, RoomLayout.TYPE_COMBAT)
			assert_true(id != map.start_id)


func _combat_count(map: FloorMap) -> int:
	var n := 0
	for room in map.rooms:
		if room.room_type == RoomLayout.TYPE_COMBAT and room.id != map.start_id:
			n += 1
	return n


# FloorMap.main_path holds room ids in order from the start.
func test_a_first_run_meets_its_rule_in_the_first_three_fights() -> void:
	for seed_text in SEEDS:
		var map := _floor_map(seed_text)
		var early := RulePicker.early_candidates(map)
		assert_true(early.size() >= 1 and early.size() <= RulePicker.EARLY_ROOMS, "seed %s" % seed_text)
		var on_path := map.main_path.filter(func(id): return map.room(id).room_type == RoomLayout.TYPE_COMBAT and id != map.start_id)
		for i in early.size():
			assert_eq(early[i], on_path[i], "in main-path order")
		var ids := RulePicker.rule_rooms(map, 1, seed_text, 0, true)
		assert_eq(ids.size(), 1)
		assert_true(early.has(ids[0]), "seed %s: room %d" % [seed_text, ids[0]])
		assert_eq(RulePicker.rule_rooms(map, 1, seed_text, 0, true), ids, "same seed, same room")


# The quiet first room has no fight to keep a rule in: no rule, early or late, ever posts there, even when
# a floor asks for a rule in every combat room it has.
func test_no_rule_ever_posts_in_the_quiet_first_room() -> void:
	for path in ["floor_1", "cemetery", "sunset_shores", "furnace_works", "funeral_parlour", "flashback_cinema", "last_resort_cruise", "seance_hotline", "terminal_zero", "head_office"]:
		var def: FloorDef = load("res://data/floors/%s.tres" % path)
		for i in 40:
			var seed_text := str(1000 + i)
			var map := RunCheckpoint.build_floor(def, seed_text)
			var quiet_ids: Array[int] = []
			for room in map.rooms:
				if room.quiet:
					quiet_ids.append(room.id)
			assert_eq(quiet_ids, [map.start_id] as Array[int], "%s seed %s" % [path, seed_text])
			var picked: Array[int] = RulePicker.early_candidates(map)
			picked.append_array(RulePicker.rule_rooms(map, def.depth, seed_text, 99, true))
			picked.append_array(RulePicker.rule_rooms(map, def.depth, seed_text, 99, false))
			for id in picked:
				assert_false(map.room(id).quiet, "%s seed %s room %d" % [path, seed_text, id])


func test_later_runs_place_rules_as_before() -> void:
	# The old draw: the default (not early) picks are unchanged by this round, so a seed replays the same.
	for seed_text in SEEDS:
		var map := _floor_map(seed_text)
		assert_eq(RulePicker.rule_rooms(map, 1, seed_text), RulePicker.rule_rooms(map, 1, seed_text, 0, false))


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
