extends TestCase


func _facts(over := {}) -> Dictionary:
	var f := {"fighting": false, "room_type": RoomLayout.TYPE_COMBAT, "rule_on": false, "announcing": false,
		"has_reel": false, "has_potion": false, "hurt": false, "has_bomb": false, "swings": 0, "cleared_one": false}
	f.merge(over, true)
	return f


func test_the_first_tip_is_walking() -> void:
	assert_eq(FirstRunTips.next_tip({}, _facts()), FirstRunTips.MOVE)


func test_a_fight_teaches_swing_then_dodge_then_charge_then_throw() -> void:
	var done := {FirstRunTips.MOVE: true}
	assert_eq(FirstRunTips.next_tip(done, _facts({"fighting": true})), FirstRunTips.SWING)
	done[FirstRunTips.SWING] = true
	assert_eq(FirstRunTips.next_tip(done, _facts({"fighting": true})), FirstRunTips.DODGE)
	done[FirstRunTips.DODGE] = true
	assert_eq(FirstRunTips.next_tip(done, _facts({"fighting": true})), FirstRunTips.CHARGE)
	done[FirstRunTips.CHARGE] = true
	assert_eq(FirstRunTips.next_tip(done, _facts({"fighting": true})), FirstRunTips.THROW)
	done[FirstRunTips.THROW] = true
	assert_eq(FirstRunTips.next_tip(done, _facts({"fighting": true})), "")


func test_charge_shows_without_the_throw_done() -> void:
	var done := {FirstRunTips.MOVE: true, FirstRunTips.SWING: true, FirstRunTips.DODGE: true}
	assert_false(done.has(FirstRunTips.THROW))
	assert_eq(FirstRunTips.next_tip(done, _facts({"fighting": true})), FirstRunTips.CHARGE)


func test_a_skipped_tip_is_passed_over_and_the_next_shows() -> void:
	var done := {FirstRunTips.MOVE: true}
	var skipped := {FirstRunTips.SWING: true}
	assert_eq(FirstRunTips.next_tip(done, _facts({"fighting": true}), skipped), FirstRunTips.DODGE, "the next in the chain follows a given-up swing tip")
	skipped[FirstRunTips.DODGE] = true
	assert_eq(FirstRunTips.next_tip(done, _facts({"fighting": true}), skipped), FirstRunTips.CHARGE)
	skipped[FirstRunTips.CHARGE] = true
	assert_eq(FirstRunTips.next_tip(done, _facts({"fighting": true}), skipped), FirstRunTips.THROW)


func test_the_rule_and_the_reel_come_first_when_they_happen() -> void:
	assert_eq(FirstRunTips.next_tip({}, _facts({"rule_on": true, "fighting": true})), FirstRunTips.RULE)
	assert_eq(FirstRunTips.next_tip({}, _facts({"rule_on": true, "announcing": true})), FirstRunTips.MOVE, "not over the notice")
	assert_eq(FirstRunTips.next_tip({}, _facts({"has_reel": true})), FirstRunTips.REEL)
	assert_eq(FirstRunTips.next_tip({}, _facts({"has_reel": true, "fighting": true})), FirstRunTips.MOVE, "a reel is used at a door, not mid-fight")


func test_the_rest_wait_for_their_moment() -> void:
	var basics := {}
	for id in [FirstRunTips.MOVE, FirstRunTips.SWING, FirstRunTips.DODGE, FirstRunTips.THROW, FirstRunTips.CHARGE]:
		basics[id] = true
	assert_eq(FirstRunTips.next_tip(basics, _facts()), "")
	assert_eq(FirstRunTips.next_tip(basics, _facts({"has_potion": true})), "", "a potion at full pills waits")
	assert_eq(FirstRunTips.next_tip(basics, _facts({"has_potion": true, "hurt": true})), FirstRunTips.POTION)
	assert_eq(FirstRunTips.next_tip(basics, _facts({"room_type": RoomLayout.TYPE_ITEM})), FirstRunTips.INTERACT)
	assert_eq(FirstRunTips.next_tip(basics, _facts({"has_bomb": true, "cleared_one": true})), FirstRunTips.THERMOS)
	basics[FirstRunTips.THERMOS] = true
	assert_eq(FirstRunTips.next_tip(basics, _facts({"cleared_one": true})), FirstRunTips.MAP)
	assert_eq(FirstRunTips.next_tip(basics, _facts({"cleared_one": true, "fighting": true})), "")


func test_every_done_tip_stays_quiet() -> void:
	var all := {}
	for id in FirstRunTips.ORDER:
		all[id] = true
	var busy := _facts({"fighting": true, "rule_on": true, "has_reel": true, "has_potion": true, "hurt": true,
		"has_bomb": true, "swings": 9, "cleared_one": true, "room_type": RoomLayout.TYPE_SHOP})
	assert_eq(FirstRunTips.next_tip(all, busy), "")


func test_every_tip_has_text_naming_its_key() -> void:
	for id in FirstRunTips.ORDER:
		var text := FirstRunTips.text_for(id, false, "")
		assert_false(text.is_empty(), id)
		var action: String = FirstRunTips.ACTIONS.get(id, "")
		if not action.is_empty():
			assert_true(text.begins_with(KeyBindings.label_for(action) + ": "), "%s: %s" % [id, text])
	assert_true(FirstRunTips.text_for(FirstRunTips.MOVE, false, "").ends_with(": Walk around the room."))


func test_a_new_save_has_no_tips_done_and_an_old_one_has_them_all() -> void:
	assert_true(ProgressData.new().tips_done.is_empty())
	var fresh := ProgressData.new().to_dict()
	assert_true(ProgressData.from_dict(fresh).tips_done.is_empty(), "a new save made by this build")
	var old := ProgressData.new().to_dict()
	old.erase("tips_done")
	old["run_count"] = 3
	var loaded := ProgressData.from_dict(old)
	for id in FirstRunTips.ORDER:
		assert_true(loaded.tips_done.has(id), id)
	old["run_count"] = 0
	assert_true(ProgressData.from_dict(old).tips_done.is_empty(), "an old save never played still learns")


func test_marking_and_resetting() -> void:
	var data := ProgressData.new()
	assert_true(data.mark_tip(FirstRunTips.DODGE))
	assert_false(data.mark_tip(FirstRunTips.DODGE), "once")
	assert_false(data.mark_tip("no_such_tip"))
	assert_true(ProgressData.from_dict(data.to_dict()).tips_done.has(FirstRunTips.DODGE))
	data.reset_tips()
	assert_true(data.tips_done.is_empty())


func test_the_hud_shows_one_tip() -> void:
	var hud := Hud.new()
	hud.setup(ItemKit.new().make_run())
	hud._ready()
	assert_eq(hud.tip_text(), "")
	hud.show_tip("Space: Dodge.")
	assert_eq(hud.tip_text(), "Space: Dodge.")
	hud.clear_tip()
	assert_eq(hud.tip_text(), "")
	assert_false(Hud.TIP_RECT.intersects(Rect2(Vector2.ZERO, Vector2(640, Hud.BAND_BOTTOM))), "clear of the top band")
	hud.free()


func test_the_coach_marks_what_he_does() -> void:
	var run := ItemKit.new().make_run()
	var player := Player.new()
	player.setup(run)
	var coach := TipCoach.new()
	var marked: Array[String] = []
	coach.mark = func(id: String) -> void: marked.append(id)
	coach.setup(player, null, run, null)
	player.dodge_started.emit()
	player.teeth_thrown.emit()
	player.swing_landed.emit(true, false)
	assert_eq(marked, [FirstRunTips.DODGE, FirstRunTips.THROW, FirstRunTips.CHARGE] as Array[String])
	player.swing_landed.emit(false, false)
	assert_eq(marked.size(), 3, "a plain swing is not a charge")
	coach.free()
	player.free()


func test_a_held_active_gets_a_use_tip_that_waits_for_it() -> void:
	var basics := {}
	for id in [FirstRunTips.MOVE, FirstRunTips.SWING, FirstRunTips.DODGE, FirstRunTips.THROW, FirstRunTips.CHARGE]:
		basics[id] = true
	assert_eq(FirstRunTips.next_tip(basics, _facts()), "", "no active, no tip")
	assert_eq(FirstRunTips.next_tip(basics, _facts({"has_active": true})), FirstRunTips.USE_ITEM)
	assert_true(FirstRunTips.text_for(FirstRunTips.USE_ITEM, false, "").ends_with(": Use the item in your top slot."))
	assert_eq(FirstRunTips.ACTIONS[FirstRunTips.USE_ITEM], "use_item")


func test_the_coach_marks_the_use_tip_when_the_item_is_used() -> void:
	var run := ItemKit.new().make_run()
	var player := Player.new()
	player.setup(run)
	var coach := TipCoach.new()
	var marked: Array[String] = []
	coach.mark = func(id: String) -> void: marked.append(id)
	coach.setup(player, null, run, null)
	player.active_used.emit(null)
	assert_eq(marked, [FirstRunTips.USE_ITEM] as Array[String])
	coach.free()
	player.free()


func test_tips_only_run_where_a_real_player_plays() -> void:
	assert_true(FirstRunTips.should_coach(false, 0, false, false))
	assert_true(FirstRunTips.should_coach(false, FirstRunTips.ORDER.size() - 1, false, false))
	assert_false(FirstRunTips.should_coach(false, FirstRunTips.ORDER.size(), false, false), "all done")
	assert_false(FirstRunTips.should_coach(true, 0, false, false), "a dev run")
	assert_false(FirstRunTips.should_coach(false, 0, true, false), "a script run")
	assert_false(FirstRunTips.should_coach(false, 0, false, true), "the full loop")


func _every_label_set() -> Array:
	InputSetup.ensure()
	var sets: Array = [[false, PadInput.XBOX]]
	for family in [PadInput.XBOX, PadInput.PLAYSTATION, PadInput.PLAYSTATION_4]:
		sets.append([true, family])
	return sets


func test_the_longest_tip_fits_its_line_on_every_device() -> void:
	var font := HudStyle.font()
	var widest := 0.0
	for pair in _every_label_set():
		for id in FirstRunTips.ORDER:
			var text := FirstRunTips.text_for(id, pair[0], pair[1])
			var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, Hud.TIP_FONT).x
			widest = maxf(widest, width)
			assert_true(width <= Hud.TIP_RECT.size.x - 8.0, "%s on %s is %f wide" % [id, str(pair), width])
	assert_true(widest > 100.0, "the check measured real text")


func test_the_tip_line_overlaps_no_other_hud_piece() -> void:
	var run := ItemKit.new().make_run()
	var hud := Hud.new()
	hud.setup(run)
	hud._ready()
	var tip := Hud.TIP_RECT
	var others := {
		"top band": Rect2(Vector2.ZERO, Vector2(640, Hud.BAND_BOTTOM)),
		"left panel": hud.left_panel_rect(),
		"right panel": Hud.RIGHT_PANEL,
		"map panel": Hud.MAP_PANEL,
		"small map": FloorMapView.MINI_RECT,
		"reel slot": Rect2(ReelSlot.AT, ReelSlot.SIZE),
		"active slot": ActiveSlot.slot_rect(hud.left_panel_rect().end.x),
		"rule icon": Rect2(RuleIcon.AT, Vector2(RulePictogram.SIZE + 4, RulePictogram.SIZE + 4)),
		"rule card": Rect2(RuleStamp.CENTER - RuleStamp.CARD / 2.0, RuleStamp.CARD),
		"notice": Rect2(0, Hud.NOTICE_TOP, 640, 20),
		"combo banner": Rect2(0, Hud.BANNER_TOP, 640, 24),
		"boss name": Rect2(0, Hud.BOSS_NAME_TOP, 640, 20),
		"boss bar": Rect2(Vector2((640.0 - Hud.BOSS_BAR_SIZE.x) / 2.0 - 4.0, Hud.BOSS_BAR_TOP - 4.0), Hud.BOSS_BAR_SIZE + Vector2(8, 8)),
		"cutscene hint": Rect2(CutscenePlayer.BOX.position - Vector2(0, 16), Vector2(640, 16)),
	}
	for name in others:
		assert_false(tip.intersects(others[name]), "the tip line overlaps the %s" % name)
	# Clear of the south door's opening, which sits in the bottom wall row.
	assert_true(tip.end.y <= 360.0 - 36.0, "above the south wall row")
	hud.free()


func test_the_opening_hint_names_the_device_in_use() -> void:
	InputSetup.ensure()
	ActiveDevice.reset()
	var script: GDScript = load("res://scripts/scenes/opening.gd")
	var keys: String = script.hint_text()
	assert_true(keys.contains(KeyBindings.label_for("dodge")))
	ActiveDevice.using_pad = true
	ActiveDevice.family = PadInput.PLAYSTATION
	var pad: String = script.hint_text()
	ActiveDevice.reset()
	assert_true(pad.contains(KeyBindings.pad_label_for("dodge", PadInput.PLAYSTATION)), pad)
	assert_true(pad.contains(KeyBindings.pad_label_for("pause", PadInput.PLAYSTATION)), pad)
	assert_ne_text(pad, keys)


func assert_ne_text(a: String, b: String) -> void:
	assert_false(a == b, "the two hints differ")


# OptionsPanel names the Progress autoload, so tests cannot build it; its button calls Progress.reset_tips,
# which this runs on a Progress of its own with a test save file.
func test_the_options_button_reaches_a_progress_that_clears_and_saves() -> void:
	var path := "user://test_tips_save.json"
	var store := SaveStore.new(path)
	store.delete_all()
	var progress: Node = load("res://scripts/autoload/progress.gd").new()
	progress._store = store
	progress.data = ProgressData.new()
	progress.mark_tip_done(FirstRunTips.DODGE)
	assert_true(store.load_progress().tips_done.has(FirstRunTips.DODGE), "saved the moment it is done")
	progress.reset_tips()
	assert_true(progress.data.tips_done.is_empty())
	assert_true(store.load_progress().tips_done.is_empty(), "and the reset is saved")
	store.delete_all()
	progress.free()


func test_the_options_panel_has_the_tips_button() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/options_panel.gd")
	assert_true(source.contains("tr(SHOW_TIPS_TEXT)") and source.contains("Progress.reset_tips()") and source.contains("tr(TIPS_RESET_TEXT)"))


func test_the_coach_goes_quiet_when_the_run_ends() -> void:
	var run := ItemKit.new().make_run()
	var hud := Hud.new()
	hud.setup(run)
	hud._ready()
	var player := Player.new()
	player.setup(run)
	var coach := TipCoach.new()
	coach.setup(player, hud, run, null)
	coach._process(0.1)
	assert_eq(hud.tip_text(), FirstRunTips.text_for(FirstRunTips.MOVE, false, ""), "the first tip shows")
	player.process_mode = Node.PROCESS_MODE_DISABLED
	coach._process(0.1)
	assert_eq(hud.tip_text(), "", "the run is over")
	coach.free()
	player.free()
	hud.free()


# A coach on a real player, HUD, room and rule keeper, with the marked ids collected in "marked".
func _rig() -> Dictionary:
	InputSetup.ensure()
	ActiveDevice.reset()
	var run := ItemKit.new().make_run()
	var hud := Hud.new()
	hud.setup(run)
	hud._ready()
	var player := Player.new()
	player.setup(run)
	var view := RoomView.new()
	var rules := RuleKeeper.new()
	var coach := TipCoach.new()
	var marked: Array[String] = []
	coach.mark = func(id: String) -> void: marked.append(id)
	coach.setup(player, hud, run, rules)
	coach.set_room(view, RoomLayout.TYPE_COMBAT)
	return {"coach": coach, "hud": hud, "player": player, "view": view, "rules": rules, "marked": marked, "run": run}


func _free_rig(rig: Dictionary) -> void:
	ActiveDevice.reset()
	for key in ["coach", "hud", "player", "view", "rules"]:
		rig[key].free()


func _run_for(coach: TipCoach, seconds: float) -> void:
	for i in int(seconds):
		coach._process(1.0)


func test_a_tip_shown_too_long_is_given_up_for_the_run_and_not_saved() -> void:
	var rig := _rig()
	var coach: TipCoach = rig["coach"]
	var hud: Hud = rig["hud"]
	var marked: Array[String] = rig["marked"]
	rig["view"]._alive = 1
	coach._process(0.1)
	assert_eq(hud.tip_text(), FirstRunTips.text_for(FirstRunTips.MOVE, false, ""))
	_run_for(coach, TipCoach.GIVE_UP_TIME - 1.0)
	assert_eq(hud.tip_text(), FirstRunTips.text_for(FirstRunTips.MOVE, false, ""), "still up just before the limit")
	_run_for(coach, 2.0)
	assert_true(coach.is_skipped(FirstRunTips.MOVE))
	assert_false(coach.done.has(FirstRunTips.MOVE), "given up is not done")
	assert_true(marked.is_empty(), "and nothing is saved")
	assert_eq(hud.tip_text(), FirstRunTips.text_for(FirstRunTips.SWING, false, ""), "the next tip shows")
	_free_rig(rig)


func test_a_tip_stays_its_minimum_time_before_another_replaces_it() -> void:
	var rig := _rig()
	var coach: TipCoach = rig["coach"]
	var hud: Hud = rig["hud"]
	coach._process(0.1)
	var move := FirstRunTips.text_for(FirstRunTips.MOVE, false, "")
	assert_eq(hud.tip_text(), move)
	var keeper: RuleKeeper = rig["rules"]
	keeper.set_watch(0, RuleWatch.new("x"))
	keeper.current_id = 0
	rig["view"]._alive = 1
	coach._process(0.1)
	assert_eq(hud.tip_text(), move, "the rule tip waits for the minimum time")
	coach._process(TipCoach.MIN_SHOW_TIME)
	assert_eq(hud.tip_text(), FirstRunTips.text_for(FirstRunTips.RULE, false, ""))
	_free_rig(rig)


func test_swing_is_done_on_the_third_swing_of_a_combo() -> void:
	var rig := _rig()
	var player: Player = rig["player"]
	var marked: Array[String] = rig["marked"]
	player.swing_started.emit()
	player.swing_started.emit()
	assert_true(marked.is_empty(), "two swings do not finish the combo tip")
	player.swing_started.emit()
	assert_eq(marked, [FirstRunTips.SWING] as Array[String])
	_free_rig(rig)


func test_slow_clicks_never_make_a_combo() -> void:
	var rig := _rig()
	var player: Player = rig["player"]
	var coach: TipCoach = rig["coach"]
	var marked: Array[String] = rig["marked"]
	for i in 4:
		player.swing_started.emit()
		coach._process(TipCoach.COMBO_GAP + 0.1)
	assert_true(marked.is_empty())
	_free_rig(rig)


func test_a_press_with_nothing_to_interact_with_marks_nothing() -> void:
	var rig := _rig()
	var coach: TipCoach = rig["coach"]
	var marked: Array[String] = rig["marked"]
	Input.action_press("interact")
	coach._process(0.1)
	Input.action_release("interact")
	assert_false(marked.has(FirstRunTips.INTERACT))
	_free_rig(rig)


func test_a_real_interaction_marks_the_interact_tip() -> void:
	var rig := _rig()
	var coach: TipCoach = rig["coach"]
	var marked: Array[String] = rig["marked"]
	coach._enter_tree()
	FirstRunTips.interacted(null)
	coach._exit_tree()
	FirstRunTips.interacted(null)
	assert_eq(marked, [FirstRunTips.INTERACT] as Array[String])
	_free_rig(rig)


func test_opening_the_big_map_marks_the_map_tip() -> void:
	var rig := _rig()
	var coach: TipCoach = rig["coach"]
	var marked: Array[String] = rig["marked"]
	var map := FloorMapView.new()
	coach.watch_map(map)
	map.opened_changed.emit(false)
	assert_true(marked.is_empty(), "closing is not opening")
	map.opened_changed.emit(true)
	assert_eq(marked, [FirstRunTips.MAP] as Array[String])
	map.free()
	_free_rig(rig)


func test_a_fight_counts_as_cleared_only_when_its_room_finishes() -> void:
	var rig := _rig()
	var coach: TipCoach = rig["coach"]
	var view: RoomView = rig["view"]
	view._alive = 1
	assert_true(coach.facts()["fighting"])
	view._alive = 0
	coach._process(0.1)
	assert_false(coach.facts()["cleared_one"], "a gap between waves is no clear")
	var other := RoomView.new()
	view._alive = 1
	coach._process(0.1)
	coach.set_room(other, RoomLayout.TYPE_COMBAT)
	coach._process(0.1)
	assert_false(coach.facts()["cleared_one"], "leaving a room mid-fight is no clear")
	other.finished.emit()
	assert_true(coach.facts()["cleared_one"], "the room he is in finishing is a clear")
	other.free()
	_free_rig(rig)


func test_the_rule_tip_is_done_when_the_rule_closes_and_never_shows_once_broken() -> void:
	var rig := _rig()
	var coach: TipCoach = rig["coach"]
	var hud: Hud = rig["hud"]
	var marked: Array[String] = rig["marked"]
	var keeper: RuleKeeper = rig["rules"]
	var watch := RuleWatch.new("x")
	keeper.set_watch(0, watch)
	keeper.current_id = 0
	rig["view"]._alive = 1
	coach._process(0.1)
	assert_eq(hud.tip_text(), FirstRunTips.text_for(FirstRunTips.RULE, false, ""))
	watch.finish()
	coach._process(0.1)
	assert_eq(marked, [FirstRunTips.RULE] as Array[String])
	_free_rig(rig)
	var again := _rig()
	var broken := RuleWatch.new("x")
	broken.state = RuleWatch.State.BROKEN
	again["rules"].set_watch(0, broken)
	again["rules"].current_id = 0
	again["view"]._alive = 1
	again["coach"]._process(0.1)
	assert_false(again["coach"].facts()["rule_on"], "the Auditor is already there")
	assert_ne_text(again["hud"].tip_text(), FirstRunTips.text_for(FirstRunTips.RULE, false, ""))
	_free_rig(again)


func test_the_tip_words_follow_the_device_in_use() -> void:
	var rig := _rig()
	var coach: TipCoach = rig["coach"]
	var hud: Hud = rig["hud"]
	coach._process(0.1)
	assert_true(hud.tip_text().begins_with(KeyBindings.label_for("move_up")))
	ActiveDevice.using_pad = true
	coach._process(0.1)
	assert_true(hud.tip_text().begins_with(FirstRunTips.PAD_MOVE), hud.tip_text())
	_free_rig(rig)
