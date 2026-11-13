extends TestCase

const EventEffect := preload("res://tests/support/event_effect.gd")


func _stat(id: String) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	return item


func _run_with_events(excuses := 0) -> RunState:
	var run := ItemKit.new().make_run()
	var item := _stat("events")
	var effect := EventEffect.new()
	effect.excuses = excuses
	item.effect = effect
	run.add_item(item)
	return run


func test_he_holds_as_many_reels_as_his_cap() -> void:
	var run := ItemKit.new().make_run()
	assert_eq(run.reel_cap(), 1)
	assert_true(run.give_reel(Eras.FOOTBALL))
	assert_false(run.give_reel(Eras.BUS), "one memory at a time")
	var album := _stat("album")
	album.extra_reels = 1
	run.add_item(album)
	assert_true(run.give_reel(Eras.BUS))
	assert_eq(run.held_reels.size(), 2)
	assert_eq(run.held_reel, Eras.FOOTBALL)
	assert_eq(run.take_reel(), Eras.FOOTBALL)
	assert_eq(run.held_reel, Eras.BUS)
	run.held_reel = ""
	assert_true(run.held_reels.is_empty())


func test_two_reels_survive_the_checkpoint_and_an_old_one_loads() -> void:
	var album := _stat("album")
	album.extra_reels = 1
	var run := ItemKit.new().make_run()
	run.add_item(album)
	run.give_reel(Eras.FOOTBALL)
	run.give_reel(Eras.BUS)
	var raw: Dictionary = JSON.parse_string(JSON.stringify(RunCheckpoint.run_to_dict(run)))
	var back := ItemKit.new().make_run()
	var shipped: Array[ItemDef] = [album]
	RunCheckpoint.apply_run(back, raw, shipped)
	assert_eq(back.held_reels, [Eras.FOOTBALL, Eras.BUS] as Array[String])
	var old := ItemKit.new().make_run()
	RunCheckpoint.apply_run(old, {"held_reel": Eras.BUS}, Content.items())
	assert_eq(old.held_reel, Eras.BUS)


func test_the_reel_slot_says_how_many() -> void:
	assert_eq(ReelSlot.text_for(Eras.BUS, "F"), "[F]")
	assert_eq(ReelSlot.text_for(Eras.BUS, "F", 2), "[F] x2")
	assert_eq(ReelSlot.text_for("", "F", 0), "")


func test_extra_rule_rooms_post_rules_deeper_too() -> void:
	assert_eq(RulePicker.rule_room_count(3, 6, 1, 0), 0)
	assert_eq(RulePicker.rule_room_count(3, 6, 1, 1), 1)
	assert_eq(RulePicker.rule_room_count(1, 6, 1, 1), 2)
	assert_eq(RulePicker.rule_room_count(1, 1, 1, 1), 1, "never more than the floor's combat rooms")


func test_rules_items_are_offered_on_every_floor() -> void:
	var run := ItemKit.new().make_run()
	var badge := _stat("badge_test")
	badge.build = "rules"
	var reel := _stat("reel_test")
	reel.build = "memory"
	var plain := _stat("plain_test")
	var all: Array[ItemDef] = [badge, reel, plain]
	run.floor_depth = 1
	assert_eq(RoomRules.offerable(all, run).size(), 3)
	run.floor_depth = 2
	assert_eq(RoomRules.offerable(all, run).size(), 3, "rules post on every floor now")
	run.floor_depth = 5
	assert_eq(RoomRules.offerable(all, run).size(), 3)
	var book := _stat("book")
	book.extra_rule_rooms = 1
	run.add_item(book)
	assert_true(run.rules_posted())
	assert_eq(RoomRules.offerable(all, run).size(), 3)


func test_a_broken_rule_counts_tells_the_items_and_can_be_let_off() -> void:
	var run := _run_with_events(1)
	var keeper := RuleKeeper.new()
	keeper._run = run
	keeper.set_watch(4, RuleWatch.new(RoomRule.NO_HORSEPLAY))
	keeper.current_id = 4
	var calls: Array = []
	keeper.rule_broken.connect(func(_view): calls.append(1))
	keeper.report(RoomRule.ACTION_DODGE)
	assert_eq(calls.size(), 0, "let off with a warning: no Auditor")
	assert_eq(run.rules_broken, 1, "it still counts as broken")
	assert_eq(run.effects.effect_of("events").events, [RunEffects.EVENT_RULE_BROKEN] as Array[String])
	keeper.set_watch(5, RuleWatch.new(RoomRule.NO_HORSEPLAY))
	keeper.current_id = 5
	keeper.report(RoomRule.ACTION_DODGE)
	assert_eq(calls.size(), 1)
	assert_eq(run.rules_broken, 2)
	keeper.free()


func test_a_kept_rule_counts_and_tells_the_items() -> void:
	var run := _run_with_events()
	var keeper := RuleKeeper.new()
	keeper._run = run
	keeper.set_watch(4, RuleWatch.new(RoomRule.NO_HORSEPLAY))
	var view := RoomView.new()
	keeper._on_room_finished(view, 4)
	assert_eq(run.rules_kept, 1)
	assert_true(run.effects.effect_of("events").events.has(RunEffects.EVENT_RULE_KEPT))
	view.free()
	keeper.free()


func test_an_old_projector_keeps_the_era_into_one_more_room() -> void:
	var run := _run_with_events()
	var projector := _stat("projector")
	projector.extra_era_rooms = 1
	run.add_item(projector)
	var keeper := RuleKeeper.new()
	keeper._run = run
	var view := RoomView.new()
	keeper._start_era(Eras.FOOTBALL, 4)
	assert_eq(run.flashbacks_played, 1)
	keeper._on_room_finished(view, 4)
	assert_eq(run.era, Eras.FOOTBALL, "a clear never ends it")
	var next := FloorRoom.new()
	next.id = 9
	keeper.on_room_entered(view, next, true)
	assert_eq(run.era, Eras.FOOTBALL, "it goes on into the next room")
	var after := FloorRoom.new()
	after.id = 10
	keeper.on_room_entered(view, after, true)
	assert_eq(run.era, "", "it ends after one more room")
	var events: Array[String] = run.effects.effect_of("events").events
	assert_eq(events, [RunEffects.EVENT_FLASHBACK_START, RunEffects.EVENT_FLASHBACK_END] as Array[String])
	view.free()
	keeper.free()


func test_the_warning_stamp_reads_warning() -> void:
	assert_eq(RuleStamp.text_of(RuleStamp.KIND_WARNING), "WARNING")
	assert_true(RuleStamp.KIND_COLORS.has(RuleStamp.KIND_WARNING))


func test_the_ally_auditor_walks_up_and_swings_on_his_own_time() -> void:
	var kit := ItemKit.new()
	var run := kit.make_run()
	var ally := AllyAuditor.make(run.effects.ctx)
	var near := kit.enemy()
	near.position = Vector2(20, 0)
	var before := near.hp
	ally.step(0.1)
	assert_near(before - near.hp, AllyAuditor.DAMAGE)
	ally.step(0.1)
	assert_near(before - near.hp, AllyAuditor.DAMAGE, "he swings every 1.2 s")
	ally.step(AllyAuditor.SWING_EVERY)
	assert_near(before - near.hp, AllyAuditor.DAMAGE * 2.0)
	near.position = Vector2(400, 0)
	ally.step(1.0)
	assert_near(ally.position.x, AllyAuditor.SPEED, "he walks toward the nearest enemy")
	ally.free()
	kit.free_enemies()


func test_the_ally_auditor_is_due_once_after_the_usual_wait() -> void:
	var view := RoomView.new()
	view.call_ally_auditor(null)
	assert_false(view._tick_ally(1.0))
	assert_true(view._tick_ally(RoomView.AUDIT_DELAY - 0.9), "due after the hostile one's wait")
	assert_false(view._tick_ally(5.0), "once")
	view.call_ally_auditor(null)
	assert_false(view._tick_ally(5.0), "a room calls one Auditor, either kind")
	view.free()


func test_the_scene_and_room_wire_the_auditor_items() -> void:
	var scene := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	assert_true(scene.contains("_run.effects.sides_with_you()"))
	assert_true(scene.contains("view.call_ally_auditor("))
	var room := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	assert_true(room.contains("_run.effects.auditor(auditor)"))
	var keeper := FileAccess.get_file_as_string("res://scripts/world/rule_keeper.gd")
	assert_true(keeper.contains("RulePicker.rule_rooms(map, depth, seed_text, _run.stats.extra_rule_rooms if _run != null else 0, first_run)"))


func test_a_flashback_end_is_told_once_whether_leaving_or_the_floor_ends_it() -> void:
	var run := _run_with_events()
	var keeper := RuleKeeper.new()
	keeper._run = run
	var view := RoomView.new()
	keeper._start_era(Eras.FOOTBALL, 4)
	var next := FloorRoom.new()
	next.id = 5
	keeper.on_room_entered(view, next, true)
	assert_eq(run.era, "")
	keeper.set_floor(null, null)
	var ends: Array = run.effects.effect_of("events").events.filter(func(e): return e == RunEffects.EVENT_FLASHBACK_END)
	assert_eq(ends.size(), 1, "leaving the room, then a floor change with no era: once")
	keeper._start_era(Eras.BUS, 5)
	keeper.set_floor(null, null)
	assert_eq(run.era, "")
	ends = run.effects.effect_of("events").events.filter(func(e): return e == RunEffects.EVENT_FLASHBACK_END)
	assert_eq(ends.size(), 2, "the floor ending an era tells the items too")
	view.free()
	keeper.free()


func test_the_ally_auditor_does_not_walk_into_a_cleared_room() -> void:
	var view := RoomView.new()
	view._finished = true
	view._spawn_ally()
	assert_eq(view.get_child_count(), 0)
	view.free()


func test_the_let_off_and_the_ally_are_not_asked_while_the_loop_counts() -> void:
	var run := _run_with_events(1)
	var item := _stat("sider")
	var sider := EventEffect.new()
	sider.sides = true
	item.effect = sider
	run.add_item(item)
	run.effects.ctx.counting_exact = true
	assert_false(run.effects.excuses_rule_break())
	assert_false(run.effects.sides_with_you())
	run.effects.ctx.counting_exact = false
	assert_true(run.effects.excuses_rule_break(), "not spent while counting")
	assert_true(run.effects.sides_with_you())


func test_a_rules_recipe_is_not_offered_where_no_rules_are_posted() -> void:
	var run := ItemKit.new().make_run()
	var badge := _stat("badge_recipe")
	badge.build = "rules"
	badge.craft_price = 10
	var all: Array[ItemDef] = [badge]
	var rng := RandomNumberGenerator.new()
	run.floor_depth = RulePicker.ENABLED_DEPTH + 1
	assert_true(RoomRules.pick_recipe(all, {}, run, rng) == null)
	run.floor_depth = 1
	assert_eq(RoomRules.pick_recipe(all, {}, run, rng), badge)
