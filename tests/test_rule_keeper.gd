extends TestCase


func test_the_player_tells_when_a_swing_or_dodge_starts() -> void:
	var player := Player.new()
	assert_true(player.has_signal("swing_started"))
	assert_true(player.has_signal("dodge_started"))
	player.free()
	var source := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	var swing := source.substr(source.find("func _swing("), 700)
	assert_true(swing.contains("swing_started.emit()"), "every swing, combo or charged, starts in _swing")
	var dodge := source.substr(source.find("func start_dodge("), 900)
	assert_true(dodge.contains("dodge_started.emit()"))


func test_a_prop_knows_whether_harold_broke_it() -> void:
	var block := BreakableBlock.new()
	block.last_source = BreakableBlock.SOURCE_CANE
	assert_true(block.broken_by_harold())
	block.last_source = BreakableBlock.SOURCE_BOSS
	assert_false(block.broken_by_harold())
	block.last_source = BreakableBlock.SOURCE_BLAST
	assert_false(block.broken_by_harold(), "an enemy's blast is not his")
	BreakableBlock.blame_harold = true
	assert_true(block.broken_by_harold(), "his Thermos is")
	BreakableBlock.blame_harold = false
	block.free()


func test_the_thermos_blames_harold_only_for_its_own_blast() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/thermos.gd")
	var at := source.find("BreakableBlock.smash(")
	var window := source.substr(at - 120, 520)
	var flagged := window.find("BreakableBlock.blame_harold = true")
	var reset := window.find("BreakableBlock.blame_harold = false")
	assert_true(flagged >= 0 and flagged < window.find("BreakableBlock.smash("))
	assert_true(reset > window.find("ReinforcedRock.blast("), "the flag stays up for the rock blast")
	assert_true(reset > window.find("SecretWall.blast("), "and for the secret wall")


func test_a_rock_or_wall_his_thermos_opens_is_his() -> void:
	var rock := ReinforcedRock.new()
	rock.needed_level = 1
	var wall := SecretWall.new()
	BreakableBlock.blame_harold = true
	assert_true(rock.break_with_level(1))
	assert_true(wall.hit_by(BreakableBlock.SOURCE_BLAST))
	assert_true(rock.broken_by_harold())
	assert_true(wall.broken_by_harold())
	BreakableBlock.blame_harold = false
	assert_false(rock.broken_by_harold(), "the same blast from an enemy is not his")
	assert_false(wall.broken_by_harold())
	rock.free()
	wall.free()


func _keeper_with_rule(rule: String) -> Array:
	var keeper := RuleKeeper.new()
	var room := FloorRoom.new()
	room.id = 4
	keeper.set_watch(room.id, RuleWatch.new(rule))
	return [keeper, room]


func test_a_report_in_the_rule_room_breaks_it_once_and_calls_the_auditor() -> void:
	var parts := _keeper_with_rule(RoomRule.NO_HORSEPLAY)
	var keeper: RuleKeeper = parts[0]
	keeper.current_id = 4
	var calls := []
	keeper.rule_broken.connect(func(_view): calls.append(1))
	keeper.report(RoomRule.ACTION_DODGE)
	keeper.report(RoomRule.ACTION_DODGE)
	assert_eq(calls.size(), 1)
	assert_eq(keeper.watch_of(4).state, RuleWatch.State.BROKEN)
	keeper.free()


func test_a_broken_rule_is_counted_on_the_profile_once() -> void:
	var keeper := RuleKeeper.new()
	keeper.set_watch(4, RuleWatch.new(RoomRule.TEETH_IN))
	keeper.current_id = 4
	var recorded := []
	keeper._record_rule = func(kept: bool): recorded.append(kept)
	keeper.report(RoomRule.ACTION_SWING)
	assert_eq(recorded.size(), 0, "a swing does not break Keep Your Teeth In")
	keeper.report(RoomRule.ACTION_THROW)
	keeper.report(RoomRule.ACTION_THROW)
	assert_eq(recorded, [false])
	keeper.free()


func test_reports_outside_a_rule_room_do_nothing() -> void:
	var parts := _keeper_with_rule(RoomRule.NO_HORSEPLAY)
	var keeper: RuleKeeper = parts[0]
	keeper.current_id = 7
	keeper.report(RoomRule.ACTION_DODGE)
	assert_eq(keeper.watch_of(4).state, RuleWatch.State.ACTIVE)
	assert_true(keeper.watch_of(7) == null)
	keeper.free()


func test_a_prop_broken_in_another_room_does_not_count() -> void:
	var parts := _keeper_with_rule(RoomRule.EXHIBITS)
	var keeper: RuleKeeper = parts[0]
	keeper.current_id = 4
	keeper._on_prop_broken(true, 7)
	assert_eq(keeper.watch_of(4).state, RuleWatch.State.ACTIVE, "a report from a room he left")
	keeper._on_prop_broken(false, 4)
	assert_eq(keeper.watch_of(4).state, RuleWatch.State.ACTIVE, "an enemy broke it")
	keeper._on_prop_broken(true, 4)
	assert_eq(keeper.watch_of(4).state, RuleWatch.State.BROKEN)
	keeper.free()


func test_a_new_floor_forgets_the_last_floors_rules() -> void:
	var parts := _keeper_with_rule(RoomRule.NO_HORSEPLAY)
	var keeper: RuleKeeper = parts[0]
	keeper.plan_floor(FloorMap.new(), 1, "seed")
	assert_true(keeper.watch_of(4) == null, "room 4 of the next floor is another room")
	assert_eq(keeper.to_dict()["rooms"], [])
	keeper.free()


func test_the_rule_state_survives_the_checkpoint() -> void:
	var keeper := RuleKeeper.new()
	keeper.plan_floor(FloorMap.new(), 1, "floor seed 77")
	keeper.set_watch(4, RuleWatch.new(RoomRule.TEETH_IN))
	keeper.watch_of(4).announced = true
	var copy := RuleKeeper.new()
	copy.load_dict(keeper.to_dict())
	assert_eq(copy.watch_of(4).rule, RoomRule.TEETH_IN)
	assert_true(copy.watch_of(4).announced)
	assert_eq(copy._seed, "floor seed 77", "a resumed floor picks its rules from the same seed")
	copy.load_dict({})
	assert_true(copy.watch_of(4) == null, "an old checkpoint has no rules")
	assert_eq(copy._seed, "", "an old checkpoint has no seed")
	keeper.free()
	copy.free()


func test_the_profile_counts_rules_and_loads_old_saves() -> void:
	var data := ProgressData.new()
	data.rules_kept = 3
	data.rules_broken = 2
	var copy := ProgressData.from_dict(data.to_dict())
	assert_eq(copy.rules_kept, 3)
	assert_eq(copy.rules_broken, 2)
	var old := ProgressData.from_dict({"version": ProgressData.VERSION, "pension": 0, "upgrades": {}, "opening_seen": false})
	assert_eq(old.rules_kept, 0)
	assert_eq(old.rules_broken, 0)


func test_a_held_enemy_waits_without_looking_stunned() -> void:
	var enemy := Enemy.new()
	enemy.hold(RuleKeeper.HOLD_TIME)
	assert_false(enemy.is_stunned(), "no stun stars over a held enemy")
	assert_near(enemy._wake_left, RuleKeeper.HOLD_TIME)
	enemy.hold(0.5)
	assert_near(enemy._wake_left, RuleKeeper.HOLD_TIME, "a shorter hold never cuts one short")
	enemy.free()


func test_the_floor_scene_hands_entries_to_the_keeper() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	var enter := source.substr(source.find("func _enter_room("), 3000)
	assert_true(enter.contains("_rules.on_room_entered(_room_view, _map.room(target_id), first_visit)"))
	assert_true(source.contains("\"rules\": _rules.to_dict()"))
	var resume := source.substr(source.find("func _resume_map("), 3000)
	assert_true(resume.contains("_rules.load_dict("), "a resumed run gets its rules back before its first room")
	var choose := source.substr(source.find("func _choose_path("), 2000)
	assert_true(choose.contains("_rules.plan_floor(map, def.depth, seed_text, _progress)"))


func test_the_rules_stop_when_the_run_ends() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	var end := source.substr(source.find("func _end_run("), 1200)
	assert_true(end.contains("_rules.process_mode = Node.PROCESS_MODE_DISABLED"), "No Loitering cannot break, nor an Auditor come, after he dies")
