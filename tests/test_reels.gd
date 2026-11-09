extends TestCase


func test_the_two_prototype_eras_start_unlocked() -> void:
	assert_eq(Eras.STARTING, [Eras.FOOTBALL, Eras.BUS] as Array[String])
	assert_eq(ProgressData.new().eras_unlocked, Eras.STARTING)
	assert_eq(Eras.title(Eras.FOOTBALL), "Football on the Rec, 1960")
	assert_eq(Eras.title(Eras.BUS), "The No. 12 Bus, 1975")
	assert_near(Eras.speed_mult(Eras.FOOTBALL), 1.45)
	assert_near(Eras.speed_mult(Eras.BUS), 1.15)
	assert_near(Eras.speed_mult(""), 1.0)


func test_a_reel_picks_an_unlocked_era_by_the_seed() -> void:
	for i in 50:
		var era := Eras.pick(Eras.STARTING, str(i), 3)
		assert_true(Eras.STARTING.has(era))
		assert_eq(Eras.pick(Eras.STARTING, str(i), 3), era)
	assert_eq(Eras.pick([Eras.BUS], "9", 1), Eras.BUS)


func test_he_holds_one_reel_and_a_second_is_wasted() -> void:
	var run := RunState.new([] as Array[UpgradeDef], {})
	assert_true(run.give_reel(Eras.FOOTBALL))
	assert_false(run.give_reel(Eras.BUS), "already holding a memory")
	assert_eq(run.held_reel, Eras.FOOTBALL)
	assert_eq(run.take_reel(), Eras.FOOTBALL)
	assert_eq(run.held_reel, "")


func test_an_era_sets_his_pace() -> void:
	var run := RunState.new([] as Array[UpgradeDef], {})
	var plain := run.move_speed()
	run.era = Eras.FOOTBALL
	assert_near(run.move_speed(), plain * 1.45)
	run.era = ""
	assert_near(run.move_speed(), plain)


func test_the_held_reel_survives_the_checkpoint() -> void:
	var run := RunState.new([] as Array[UpgradeDef], {})
	run.give_reel(Eras.BUS)
	var copy := RunState.new([] as Array[UpgradeDef], {})
	RunCheckpoint.apply_run(copy, RunCheckpoint.run_to_dict(run), Content.items())
	assert_eq(copy.held_reel, Eras.BUS)
	var old := RunState.new([] as Array[UpgradeDef], {})
	RunCheckpoint.apply_run(old, {}, Content.items())
	assert_eq(old.held_reel, "")
	var odd := RunState.new([] as Array[UpgradeDef], {})
	RunCheckpoint.apply_run(odd, {"held_reel": "moon_landing_1969"}, Content.items())
	assert_eq(odd.held_reel, "", "a reel of an era this build doesn't know is dropped")


func test_unknown_saved_eras_are_dropped() -> void:
	var base := {"version": ProgressData.VERSION, "pension": 0, "upgrades": {}, "opening_seen": false}
	var raw := base.duplicate()
	raw["eras_unlocked"] = [Eras.BUS, "moon_landing_1969"]
	assert_eq(ProgressData.from_dict(raw).eras_unlocked, [Eras.BUS] as Array[String])
	assert_eq(ProgressData.from_dict(base).eras_unlocked, Eras.STARTING, "an older save starts with both")
	raw["eras_unlocked"] = ["moon_landing_1969"]
	assert_eq(ProgressData.from_dict(raw).eras_unlocked, Eras.STARTING, "nothing known left falls back")
	raw["eras_unlocked"] = "not a list"
	assert_eq(ProgressData.from_dict(raw).eras_unlocked, Eras.STARTING)
	var data := ProgressData.new()
	data.eras_unlocked = [Eras.BUS] as Array[String]
	assert_eq(ProgressData.from_dict(data.to_dict()).eras_unlocked, [Eras.BUS] as Array[String])


func test_the_flashback_action_is_f_and_pad_y() -> void:
	InputSetup.ensure()
	assert_true(InputMap.has_action("flashback"))
	var keys := InputMap.action_get_events("flashback").filter(func(e): return e is InputEventKey)
	assert_eq(keys[0].physical_keycode if keys[0].physical_keycode != 0 else keys[0].keycode, KEY_F)
	assert_eq(PadInput.DEFAULT_BUTTONS["flashback"], JOY_BUTTON_Y)
	assert_true(KeyBindings.ACTIONS.any(func(e): return e["action"] == "flashback"))
	var pads := InputMap.action_get_events("flashback").filter(func(e): return e is InputEventJoypadButton)
	assert_eq(pads[0].device, PadInput.ALL_DEVICES, "any pad, not only the first")


func test_a_door_knows_when_harold_is_near_it() -> void:
	var door := Door.new()
	var feet := Node2D.new()
	door.position = Vector2(100, 100)
	feet.position = Vector2(130, 100)
	door.debug_set_player(feet)
	assert_true(door.is_within(48.0))
	assert_false(door.is_within(20.0))
	door.free()
	feet.free()


func test_the_reel_slot_fits_the_top_row() -> void:
	var rect := Rect2(ReelSlot.AT, ReelSlot.SIZE)
	assert_true(rect.end.y <= Hud.BAND_BOTTOM)
	assert_true(rect.position.x >= Hud.ITEM_ROW_END)
	assert_false(rect.intersects(Rect2(Hud.POTION_SLOT_AT, PotionSlot.SIZE)))
	assert_false(rect.intersects(Rect2(Hud.TIMER_AT, Vector2(Hud.TIMER_WIDTH, 12))), "clear of the run timer")
	assert_false(rect.intersects(Hud.MAP_PANEL), "clear of the small map")
	assert_true(Hud.RIGHT_PANEL.encloses(rect), "inside the right panel")


func test_the_hud_shows_the_reel_only_while_he_holds_one() -> void:
	var run := RunState.new([] as Array[UpgradeDef], {})
	var hud := Hud.new()
	hud.setup(run)
	hud._ready()
	assert_eq(hud.reel_label(), "")
	run.give_reel(Eras.BUS)
	assert_eq(hud.reel_label(), "[%s]" % KeyBindings.prompt_label("flashback"))
	run.take_reel()
	assert_eq(hud.reel_label(), "")
	hud.free()


# A map of a cleared room 0 with a door 30 px from Harold into the fight room 1 he hasn't seen.
func _flashback_setup(target_type := RoomLayout.TYPE_COMBAT, gap := 30.0) -> Dictionary:
	var map := FloorMap.new()
	for i in 2:
		var room := FloorRoom.new()
		room.id = i
		room.room_type = RoomLayout.TYPE_CROSSROADS if i == 0 else target_type
		map.rooms.append(room)
	var progress := FloorProgress.new(map)
	progress.enter(0)
	var run := RunState.new([] as Array[UpgradeDef], {})
	var player := Player.new()
	player.setup(run)
	var keeper := RuleKeeper.new()
	keeper.setup(player, null, run, Callable())
	keeper.plan_floor(map, 1, "seed", progress)
	# No rule posted here, so these tests see the reel alone.
	keeper._rule_rooms.clear()
	var view := RoomView.new()
	var door := Door.new()
	var feet := Node2D.new()
	door.setup(1, "?", feet)
	feet.position = Vector2(gap, 0)
	view._doors.append(door)
	return {"map": map, "progress": progress, "run": run, "player": player, "keeper": keeper, "view": view, "door": door, "feet": feet}


func _free_setup(parts: Dictionary) -> void:
	for key in ["keeper", "view", "door", "feet", "player"]:
		if is_instance_valid(parts[key]):
			parts[key].free()


func test_a_reel_readies_at_a_door_into_an_unfought_room() -> void:
	var parts := _flashback_setup()
	var keeper: RuleKeeper = parts["keeper"]
	var run: RunState = parts["run"]
	assert_false(keeper.try_ready_reel(parts["view"], parts["progress"], parts["map"]), "no reel, nothing to ready")
	run.give_reel(Eras.FOOTBALL)
	assert_true(keeper.try_ready_reel(parts["view"], parts["progress"], parts["map"]))
	assert_eq(keeper.readied_door(), 1)
	assert_eq(run.held_reel, Eras.FOOTBALL, "readied, not spent: the door spends it")
	assert_true(parts["player"].has_sepia_glow())
	_free_setup(parts)


func test_a_reel_does_not_ready_far_from_a_door_or_at_a_room_already_seen() -> void:
	var parts := _flashback_setup(RoomLayout.TYPE_COMBAT, 80.0)
	var keeper: RuleKeeper = parts["keeper"]
	var run: RunState = parts["run"]
	run.give_reel(Eras.FOOTBALL)
	assert_false(keeper.try_ready_reel(parts["view"], parts["progress"], parts["map"]), "too far from the door")
	parts["feet"].position = Vector2(30, 0)
	parts["progress"].enter(1)
	assert_false(keeper.try_ready_reel(parts["view"], parts["progress"], parts["map"]), "that room's fight is over")
	assert_eq(keeper.readied_door(), -1)
	assert_eq(run.held_reel, Eras.FOOTBALL)
	assert_false(parts["player"].has_sepia_glow())
	_free_setup(parts)


func test_a_reel_does_not_ready_at_a_shop_door() -> void:
	var parts := _flashback_setup(RoomLayout.TYPE_SHOP)
	parts["run"].give_reel(Eras.BUS)
	assert_false(parts["keeper"].try_ready_reel(parts["view"], parts["progress"], parts["map"]))
	_free_setup(parts)


func test_the_readied_door_plays_the_era_for_that_room_until_it_clears() -> void:
	var parts := _flashback_setup()
	var keeper: RuleKeeper = parts["keeper"]
	var run: RunState = parts["run"]
	var map: FloorMap = parts["map"]
	run.give_reel(Eras.BUS)
	keeper.try_ready_reel(parts["view"], parts["progress"], map)
	var fight := RoomView.new()
	fight._alive = 3
	var started := []
	var ended := []
	keeper.era_started.connect(func(era): started.append(era))
	keeper.era_ended.connect(func(era): ended.append(era))
	keeper.on_room_entered(fight, map.room(1), true)
	assert_eq(run.era, Eras.BUS)
	assert_eq(run.held_reel, "", "the reel is spent")
	assert_eq(started, [Eras.BUS])
	assert_false(parts["player"].has_sepia_glow())
	assert_eq(parts["player"].era(), Eras.BUS)
	# Coming back into the same view never hooks the clear twice.
	keeper.on_room_entered(fight, map.room(1), false)
	fight.finished.emit()
	assert_eq(run.era, "", "old Harold again once the room is clear")
	assert_eq(ended, [Eras.BUS])
	assert_eq(parts["player"].era(), "")
	fight.free()
	_free_setup(parts)


func test_another_door_cancels_the_readied_reel_and_keeps_it() -> void:
	var parts := _flashback_setup()
	var keeper: RuleKeeper = parts["keeper"]
	var run: RunState = parts["run"]
	var map: FloorMap = parts["map"]
	run.give_reel(Eras.FOOTBALL)
	keeper.try_ready_reel(parts["view"], parts["progress"], map)
	var start := RoomView.new()
	keeper.on_room_entered(start, map.room(0), false)
	assert_eq(keeper.readied_door(), -1)
	assert_eq(run.held_reel, Eras.FOOTBALL)
	assert_eq(run.era, "")
	assert_false(parts["player"].has_sepia_glow())
	start.free()
	_free_setup(parts)


func test_a_second_reel_while_holding_one_fades() -> void:
	var parts := _flashback_setup()
	var keeper: RuleKeeper = parts["keeper"]
	var run: RunState = parts["run"]
	keeper._reel_taken(Eras.FOOTBALL)
	keeper._reel_taken(Eras.BUS)
	assert_eq(run.held_reel, Eras.FOOTBALL)
	_free_setup(parts)


func test_the_sepia_glow_clears_back_to_his_own_look() -> void:
	var run := RunState.new([] as Array[UpgradeDef], {})
	var player := Player.new()
	player.setup(run)
	player._visual = SpriteVisual.new()
	player.add_child(player._visual)
	player.set_sepia_glow(true)
	assert_true(player.has_sepia_glow())
	assert_eq(player._visual._tint, Player.SEPIA_GLOW)
	player.set_sepia_glow(false)
	assert_eq(player._visual._tint, Color.WHITE)
	player.set_era(Eras.FOOTBALL)
	assert_eq(player.era(), Eras.FOOTBALL)
	assert_eq(run.era, "", "the RuleKeeper owns run.era")
	player.free()


func test_a_new_floor_ends_an_era_still_playing() -> void:
	var parts := _flashback_setup()
	var keeper: RuleKeeper = parts["keeper"]
	var run: RunState = parts["run"]
	var map: FloorMap = parts["map"]
	run.give_reel(Eras.FOOTBALL)
	keeper.try_ready_reel(parts["view"], parts["progress"], map)
	var fight := RoomView.new()
	fight._alive = 3
	keeper.on_room_entered(fight, map.room(1), true)
	assert_eq(run.era, Eras.FOOTBALL)
	var ended := []
	keeper.era_ended.connect(func(era): ended.append(era))
	keeper.plan_floor(map, 2, "next", parts["progress"])
	assert_eq(run.era, "", "a floor change ends it")
	assert_eq(parts["player"].era(), "")
	assert_eq(ended, [Eras.FOOTBALL])
	assert_eq(parts["player"].last_line, "", "quietly: no return line")
	# Clearing the old room later never ends anything again.
	fight.finished.emit()
	assert_eq(ended, [Eras.FOOTBALL])
	keeper.set_floor(map, parts["progress"])
	assert_eq(run.era, "")
	fight.free()
	_free_setup(parts)


func test_the_sepia_flicker_sits_under_the_hud_and_frees_itself() -> void:
	var hud := Hud.new()
	assert_true(SepiaFlicker.LAYER < hud.layer, "the HUD stays in colour")
	hud.free()
	var flicker := SepiaFlicker.new()
	flicker._ready()
	assert_eq(flicker.process_mode, Node.PROCESS_MODE_ALWAYS, "a pause mid-flicker never leaves the screen sepia")
	flicker._process(SepiaFlicker.TIME - 0.1)
	assert_false(flicker.is_queued_for_deletion())
	flicker._process(0.2)
	assert_true(flicker.is_queued_for_deletion())
	flicker.free()


func test_the_floor_scene_wires_the_reels() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	assert_true(source.contains("_rules.set_unlocked(Progress.data.eras_unlocked)"))
	var choose := source.substr(source.find("func _choose_path("), 2000)
	assert_true(choose.contains("_rules.plan_floor(map, def.depth, seed_text, _progress)"))
	var resume := source.substr(source.find("func _resume_map("), 3000)
	assert_true(resume.contains("_rules.set_floor(map, _progress)"), "a resumed floor can ready reels too")
	var keeper := FileAccess.get_file_as_string("res://scripts/world/rule_keeper.gd")
	assert_true(keeper.contains("Sfx.play(\"reel_flicker\")"))
	assert_true(DevStart.REEL_KEY == KEY_F7)
