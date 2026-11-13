extends TestCase


func test_four_eras_start_unlocked() -> void:
	assert_eq(Eras.STARTING, [Eras.FOOTBALL, Eras.DANCE, Eras.BUS, Eras.ALLOTMENT] as Array[String])
	assert_eq(ProgressData.new().eras_unlocked, Eras.STARTING)
	assert_eq(Eras.title(Eras.FOOTBALL), "Football on the Rec, 1960")
	assert_eq(Eras.title(Eras.DANCE), "The Dance Hall, 1962")
	assert_eq(Eras.title(Eras.BUS), "The No. 12 Bus, 1975")
	assert_eq(Eras.title(Eras.ALLOTMENT), "The Allotment, 1988")
	assert_near(Eras.speed_mult(Eras.FOOTBALL), 1.25)
	assert_near(Eras.speed_mult(Eras.DANCE), 1.1)
	assert_near(Eras.speed_mult(Eras.BUS), 1.0)
	assert_near(Eras.speed_mult(Eras.ALLOTMENT), 1.0)
	assert_near(Eras.speed_mult(""), 1.0)


# Born 1942: every era's age is its year minus that.
func test_his_ages_agree_with_one_birth_year() -> void:
	assert_eq(Eras.BIRTH_YEAR, 1942)
	assert_eq(Eras.age(Eras.FOOTBALL), 18)
	assert_eq(Eras.age(Eras.DANCE), 20)
	assert_eq(Eras.age(Eras.BUS), 33)
	assert_eq(Eras.age(Eras.ALLOTMENT), 46)


# The starting eras are always held; other saved ids are kept only if this build knows them.
func test_an_older_save_gains_the_new_eras() -> void:
	var base := ProgressData.new().to_dict()
	var raw := base.duplicate(true)
	raw["eras_unlocked"] = [Eras.FOOTBALL, Eras.BUS]
	assert_eq(ProgressData.from_dict(raw).eras_unlocked, Eras.STARTING)
	raw["eras_unlocked"] = [Eras.BUS, "moon_landing_1969"]
	assert_eq(ProgressData.from_dict(raw).eras_unlocked, Eras.STARTING, "unknown ids drop")
	raw["eras_unlocked"] = "not a list"
	assert_eq(ProgressData.from_dict(raw).eras_unlocked, Eras.STARTING)
	base.erase("eras_unlocked")
	assert_eq(ProgressData.from_dict(base).eras_unlocked, Eras.STARTING)


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
	assert_near(run.move_speed(), plain * Eras.speed_mult(Eras.FOOTBALL))
	assert_true(run.move_speed() > plain, "the footballer is quicker than old Harold")
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
	assert_eq(ProgressData.from_dict(raw).eras_unlocked, Eras.STARTING, "the starting eras are always held")
	assert_eq(ProgressData.from_dict(base).eras_unlocked, Eras.STARTING, "an older save starts with all four")
	raw["eras_unlocked"] = ["moon_landing_1969"]
	assert_eq(ProgressData.from_dict(raw).eras_unlocked, Eras.STARTING, "nothing known left falls back")
	var data := ProgressData.new()
	data.eras_unlocked = [Eras.BUS] as Array[String]
	assert_eq(ProgressData.from_dict(data.to_dict()).eras_unlocked, Eras.STARTING)


func test_the_flashback_action_is_f_and_pad_y() -> void:
	InputSetup.ensure()
	assert_true(InputMap.has_action("flashback"))
	var keys := InputMap.action_get_events("flashback").filter(func(e): return e is InputEventKey)
	assert_eq(keys[0].physical_keycode if keys[0].physical_keycode != 0 else keys[0].keycode, KEY_F)
	assert_eq(PadInput.DEFAULT_BUTTONS["flashback"], JOY_BUTTON_Y)
	assert_true(KeyBindings.ACTIONS.any(func(e): return e["action"] == "flashback"))
	var pads := InputMap.action_get_events("flashback").filter(func(e): return e is InputEventJoypadButton)
	assert_eq(pads[0].device, PadInput.ALL_DEVICES, "any pad, not only the first")


func test_the_reel_slot_fits_the_top_row() -> void:
	var rect := Rect2(ReelSlot.AT, ReelSlot.SIZE)
	assert_true(rect.end.y <= Hud.BAND_BOTTOM)
	assert_true(rect.position.x >= Hud.ITEM_ROW_END)
	assert_false(rect.intersects(Rect2(Hud.POTION_SLOT_AT, PotionSlot.SIZE)))
	assert_false(rect.intersects(Rect2(Hud.TIMER_AT, Vector2(Hud.TIMER_WIDTH, 12))), "clear of the run timer")
	assert_false(rect.intersects(Hud.MAP_PANEL), "clear of the small map")
	assert_true(Hud.RIGHT_PANEL.encloses(rect), "inside the right panel")


# The first real-window shot clipped "[Triangle]" to "[Triangle". Every default flashback label, keys and
# each pad family, fits the slot's text room in the HUD's small font.
func test_every_default_flashback_label_fits_the_reel_slot() -> void:
	var room := ReelSlot.SIZE.x - ReelSlot.TEXT_AT.x
	var labels: Array[String] = [KeyBindings.label_for("flashback")]
	for family in [PadInput.XBOX, PadInput.PLAYSTATION, PadInput.PLAYSTATION_4]:
		labels.append(KeyBindings.pad_label_for("flashback", family))
	for label in labels:
		var text := ReelSlot.text_for(Eras.BUS, label)
		var width := HudStyle.font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, HudStyle.SMALL).x
		assert_true(width <= room, "%s is %.0f px in %.0f" % [text, width, room])


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


# The first real-window shot showed "Reel: Football on the Rec, 1960" running off the east wall, since the
# reel lay where the last enemy fell. It lands as near there as its centred name fits, off the doors
# (it is taken by walking over it), in every floor-1 fight room and from every wall.
func test_a_reel_lands_where_its_name_fits_and_off_the_doors() -> void:
	for layout in RoomCatalog.load_valid("res://data/rooms/floor_1/"):
		if layout.room_type != RoomLayout.TYPE_COMBAT:
			continue
		var size := layout.size_in_cells()
		for wanted in [Vector2i(1, size.y / 2), Vector2i(size.x - 2, size.y / 2), Vector2i(size.x / 2, 1), layout.door_cell(RoomLayout.EAST)]:
			var cell: Vector2i = layout.label_spot_near(wanted)
			assert_eq(layout.symbol_at(cell), RoomLayout.SYMBOL_FLOOR, "%s: %s is plain floor" % [layout.resource_path, cell])
			assert_true(cell.x >= RoomLayout.LABEL_CELLS and cell.x + RoomLayout.LABEL_CELLS < size.x, "%s: name fits at %s" % [layout.resource_path, cell])
			assert_true(cell.y > RoomLayout.UNDER_THE_HUD, "%s: under the HUD row at %s" % [layout.resource_path, cell])
			assert_false(layout.touches_a_door(cell), "%s: off the doors at %s" % [layout.resource_path, cell])
			# Another labelled pickup there already: the reel keeps its distance.
			var taken: Array[Vector2i] = [cell]
			var apart: Vector2i = layout.label_spot_near(wanted, taken)
			assert_true(maxi(absi(apart.x - cell.x), absi(apart.y - cell.y)) >= RoomLayout.PICKUP_SPACING, "%s: spaced from %s at %s" % [layout.resource_path, cell, apart])
	assert_true(FileAccess.get_file_as_string("res://scripts/world/room_view.gd").contains("label_spot_near(_cell_of(at), taken)"), "drop_reel uses it")


# A map of a cleared room 0 (where he stands) and the fight room 1 and cleared room 2 beside it, with a
# HUD for the notices.
func _flashback_setup() -> Dictionary:
	var map := FloorMap.new()
	for i in 3:
		var room := FloorRoom.new()
		room.id = i
		room.room_type = RoomLayout.TYPE_COMBAT if i == 1 else RoomLayout.TYPE_CROSSROADS
		map.rooms.append(room)
	var progress := FloorProgress.new(map)
	progress.enter(0)
	var run := RunState.new([] as Array[UpgradeDef], {})
	var player := Player.new()
	player.setup(run)
	var hud := Hud.new()
	hud.setup(run)
	hud._ready()
	var keeper := RuleKeeper.new()
	keeper.setup(player, hud, run, Callable())
	keeper.plan_floor(map, 1, "seed", progress)
	# No rule posted here, so these tests see the reel alone.
	keeper._rule_rooms.clear()
	var calm := RoomView.new()
	var fight := RoomView.new()
	fight._alive = 3
	var other := RoomView.new()
	keeper.on_room_entered(calm, map.room(0), false)
	return {"map": map, "progress": progress, "run": run, "player": player, "hud": hud, "keeper": keeper, "calm": calm, "fight": fight, "other": other}


func _free_setup(parts: Dictionary) -> void:
	for key in ["keeper", "calm", "fight", "other", "player", "hud"]:
		if is_instance_valid(parts[key]):
			parts[key].free()


func _notice_of(parts: Dictionary) -> String:
	return parts["hud"]._notice.text


func test_the_reel_notices_are_the_shared_names() -> void:
	assert_eq(RuleKeeper.NO_REEL_NOTICE, "No memory to play")
	assert_eq(RuleKeeper.BUSY_NOTICE, "Already remembering")
	assert_eq(RuleKeeper.SAVE_NOTICE, "Save it for a fight")
	assert_eq(RuleKeeper.HELD_NOTICE, "Already holding a memory")


func test_f_mid_fight_plays_the_era_at_once_for_the_room() -> void:
	var parts := _flashback_setup()
	var keeper: RuleKeeper = parts["keeper"]
	var run: RunState = parts["run"]
	var map: FloorMap = parts["map"]
	run.give_reel(Eras.BUS)
	var started := []
	keeper.era_started.connect(func(era): started.append(era))
	keeper.on_room_entered(parts["fight"], map.room(1), true)
	assert_eq(run.era, "", "walking in plays nothing")
	assert_true(keeper.try_play_reel())
	assert_eq(run.era, Eras.BUS)
	assert_eq(run.held_reel, "", "the reel is spent")
	assert_eq(started, [Eras.BUS])
	assert_eq(parts["player"].era(), Eras.BUS)
	assert_eq(keeper._era_room, 1, "for the room he stands in")
	assert_eq(run.flashbacks_played, 1)
	_free_setup(parts)


func test_f_in_a_room_with_no_fight_keeps_the_reel() -> void:
	var parts := _flashback_setup()
	var keeper: RuleKeeper = parts["keeper"]
	var run: RunState = parts["run"]
	run.give_reel(Eras.FOOTBALL)
	for i in 2:
		parts["hud"]._notice.text = ""
		assert_false(keeper.try_play_reel())
		assert_eq(_notice_of(parts), RuleKeeper.SAVE_NOTICE, "press %d" % i)
	assert_eq(run.held_reel, Eras.FOOTBALL)
	assert_eq(run.era, "")
	# A fight room whose fight is over is the same.
	parts["fight"]._alive = 0
	keeper.on_room_entered(parts["fight"], parts["map"].room(1), true)
	assert_false(keeper.try_play_reel())
	assert_eq(_notice_of(parts), RuleKeeper.SAVE_NOTICE)
	assert_eq(run.held_reel, Eras.FOOTBALL)
	_free_setup(parts)


func test_f_with_no_reel_or_during_an_era_says_why_every_time() -> void:
	var parts := _flashback_setup()
	var keeper: RuleKeeper = parts["keeper"]
	var run: RunState = parts["run"]
	keeper.on_room_entered(parts["fight"], parts["map"].room(1), true)
	for i in 3:
		parts["hud"]._notice.text = ""
		assert_false(keeper.try_play_reel())
		assert_eq(_notice_of(parts), RuleKeeper.NO_REEL_NOTICE, "press %d" % i)
	run.give_reel(Eras.DANCE)
	assert_true(keeper.try_play_reel())
	# A second reel (Photo Album) waits while the first plays.
	run.held_reels.append(Eras.BUS)
	for i in 3:
		parts["hud"]._notice.text = ""
		assert_false(keeper.try_play_reel())
		assert_eq(_notice_of(parts), RuleKeeper.BUSY_NOTICE, "press %d" % i)
	assert_eq(run.era, Eras.DANCE)
	assert_eq(run.held_reel, Eras.BUS, "the second reel waits")
	_free_setup(parts)


# During an era F says it is busy, whether or not a reel is left to play.
func test_f_during_an_era_with_no_reel_left_says_busy() -> void:
	var parts := _flashback_setup()
	var keeper: RuleKeeper = parts["keeper"]
	var run: RunState = parts["run"]
	keeper.on_room_entered(parts["fight"], parts["map"].room(1), true)
	run.give_reel(Eras.FOOTBALL)
	assert_true(keeper.try_play_reel())
	assert_true(run.held_reels.is_empty())
	for i in 2:
		parts["hud"]._notice.text = ""
		assert_false(keeper.try_play_reel())
		assert_eq(_notice_of(parts), RuleKeeper.BUSY_NOTICE, "press %d" % i)
	assert_eq(run.era, Eras.FOOTBALL)
	_free_setup(parts)


# A reel picked up mid-era fills his pocket; a save then keeps the era's reel too, one over the cap.
func test_a_save_mid_era_with_a_full_pocket_keeps_both_reels() -> void:
	var run := RunState.new([] as Array[UpgradeDef], {})
	assert_eq(run.reel_cap(), 1)
	run.era = Eras.BUS
	run.give_reel(Eras.FOOTBALL)
	var raw: Dictionary = JSON.parse_string(JSON.stringify(RunCheckpoint.run_to_dict(run)))
	var back := RunState.new([] as Array[UpgradeDef], {})
	RunCheckpoint.apply_run(back, raw, Content.items())
	assert_eq(back.held_reels, [Eras.FOOTBALL, Eras.BUS] as Array[String])
	assert_false(back.give_reel(Eras.DANCE), "no third while over the cap")
	assert_eq(back.take_reel(), Eras.FOOTBALL)
	assert_eq(back.take_reel(), Eras.BUS)
	# An empty pocket mid-era keeps the era's reel as before.
	var lone := RunState.new([] as Array[UpgradeDef], {})
	lone.era = Eras.DANCE
	var again := RunState.new([] as Array[UpgradeDef], {})
	RunCheckpoint.apply_run(again, RunCheckpoint.run_to_dict(lone), Content.items())
	assert_eq(again.held_reels, [Eras.DANCE] as Array[String])


func test_clearing_the_room_does_not_end_the_era_but_leaving_does() -> void:
	var parts := _flashback_setup()
	var keeper: RuleKeeper = parts["keeper"]
	var run: RunState = parts["run"]
	var map: FloorMap = parts["map"]
	var fight: RoomView = parts["fight"]
	run.give_reel(Eras.ALLOTMENT)
	keeper.on_room_entered(fight, map.room(1), true)
	keeper.try_play_reel()
	var ended := []
	keeper.era_ended.connect(func(era): ended.append(era))
	fight._alive = 0
	fight.finished.emit()
	keeper._on_room_finished(fight, 1)
	assert_eq(run.era, Eras.ALLOTMENT, "a cleared room keeps the era while he stays")
	assert_eq(ended, [])
	keeper.on_room_entered(parts["other"], map.room(2), false)
	assert_eq(run.era, "", "old Harold again once he leaves")
	assert_eq(ended, [Eras.ALLOTMENT])
	assert_eq(parts["player"].era(), "")
	assert_false(parts["player"].last_line.is_empty(), "with the return line")
	# Walking back in does not bring it back.
	keeper.on_room_entered(fight, map.room(1), false)
	assert_eq(run.era, "")
	assert_eq(ended, [Eras.ALLOTMENT])
	_free_setup(parts)


func test_leaving_mid_fight_ends_the_era_too() -> void:
	var parts := _flashback_setup()
	var keeper: RuleKeeper = parts["keeper"]
	var run: RunState = parts["run"]
	var map: FloorMap = parts["map"]
	run.give_reel(Eras.FOOTBALL)
	keeper.on_room_entered(parts["fight"], map.room(1), true)
	keeper.try_play_reel()
	keeper.on_room_entered(parts["calm"], map.room(0), false)
	assert_eq(run.era, "")
	_free_setup(parts)


func test_an_old_projector_carries_the_era_one_room_further() -> void:
	var parts := _flashback_setup()
	var keeper: RuleKeeper = parts["keeper"]
	var run: RunState = parts["run"]
	var map: FloorMap = parts["map"]
	run.stats.extra_era_rooms = 1
	run.give_reel(Eras.DANCE)
	keeper.on_room_entered(parts["fight"], map.room(1), true)
	keeper.try_play_reel()
	var ended := []
	keeper.era_ended.connect(func(era): ended.append(era))
	keeper.on_room_entered(parts["other"], map.room(2), true)
	assert_eq(run.era, Eras.DANCE, "into the next room he enters")
	assert_eq(keeper._era_room, 2)
	keeper.on_room_entered(parts["fight"], map.room(1), false)
	assert_eq(run.era, "", "and ends when he leaves that one")
	assert_eq(ended, [Eras.DANCE])
	_free_setup(parts)


func test_a_second_reel_while_holding_one_fades() -> void:
	var parts := _flashback_setup()
	var keeper: RuleKeeper = parts["keeper"]
	var run: RunState = parts["run"]
	keeper._reel_taken(Eras.FOOTBALL)
	keeper._reel_taken(Eras.BUS)
	assert_eq(run.held_reel, Eras.FOOTBALL)
	_free_setup(parts)


func test_an_era_is_his_own_look_and_the_keeper_owns_run_era() -> void:
	var run := RunState.new([] as Array[UpgradeDef], {})
	var player := Player.new()
	player.setup(run)
	player._visual = SpriteVisual.new()
	player.add_child(player._visual)
	player.set_era(Eras.FOOTBALL)
	assert_eq(player.era(), Eras.FOOTBALL)
	assert_eq(run.era, "", "the RuleKeeper owns run.era")
	player.free()


func test_a_keeper_with_no_run_still_takes_a_new_floor() -> void:
	var keeper := RuleKeeper.new()
	keeper._era_room = 3
	keeper.set_floor(FloorMap.new(), null)
	assert_eq(keeper._era_room, -1, "the stale era room is forgotten, with no run to read")
	keeper.free()


func test_a_new_floor_ends_an_era_still_playing() -> void:
	var parts := _flashback_setup()
	var keeper: RuleKeeper = parts["keeper"]
	var run: RunState = parts["run"]
	var map: FloorMap = parts["map"]
	var fight: RoomView = parts["fight"]
	run.give_reel(Eras.FOOTBALL)
	keeper.on_room_entered(fight, map.room(1), true)
	keeper.try_play_reel()
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
	assert_true(resume.contains("_rules.set_floor(map, _progress)"), "a resumed floor ends an era too")
	var keeper := FileAccess.get_file_as_string("res://scripts/world/rule_keeper.gd")
	assert_true(keeper.contains("Sfx.play(\"reel_flicker\")"))
	assert_true(DevStart.REEL_KEY == KEY_F7)
