extends TestCase

# A resumed run gets its items back without a second on_gain, and each effect's own run state comes
# back through the checkpoint (ItemEffect.save_state / load_state).


# A run through the checkpoint's JSON, as a real resume reads it, onto a fresh run wired to the kit.
func _resume(run: RunState, kit: ItemKit) -> RunState:
	var raw: Dictionary = JSON.parse_string(JSON.stringify(RunCheckpoint.run_to_dict(run)))
	var back := kit.make_run()
	back.effects.set_combos(Content.combos())
	RunCheckpoint.apply_run(back, raw, Content.all_items())
	return back


# An effect copy, untyped, so a test can read the members of its own script.
func _fx(run: RunState, id: String) -> Variant:
	return run.effects.effect_of(id)


func test_an_effect_keeps_nothing_by_default() -> void:
	var plain := ItemEffect.new()
	assert_eq(plain.save_state(), {})
	plain.load_state({"anything": 3})
	assert_eq(plain.save_state(), {}, "loading does nothing either")


func test_a_resume_never_runs_on_gain_again() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["inheritance_letter", "flask_holster"])
	assert_eq(kit.paid, 75, "paid once when taken")
	var bombs := run.bombs
	var back_kit := ItemKit.new()
	var back := _resume(run, back_kit)
	assert_eq(back_kit.paid, 0, "the Inheritance Letter does not pay again")
	assert_eq(back.bombs, bombs, "the Strap gives no more Thermoses")
	assert_true(back.effects.effect_of("inheritance_letter") != null, "the effects are held again")
	assert_true(back.effects.effect_of("flask_holster") != null)


func test_a_resumed_run_keeps_the_warranty_used() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["eternal_warranty"])
	assert_true(run.effects.lethal(), "the first lethal hit is saved")
	var back := _resume(run, ItemKit.new())
	assert_true(_fx(back, "eternal_warranty").used)
	assert_false(back.effects.lethal(), "and never again in the same run")


func test_a_resumed_run_keeps_the_stamps_recharge() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["bureaucrats_stamp"])
	var stamp = run.effects.effect_of("bureaucrats_stamp")
	stamp.ready = false
	stamp.left = 12.5
	var back := _resume(run, ItemKit.new())
	var again = back.effects.effect_of("bureaucrats_stamp")
	assert_false(again.ready, "still recharging")
	assert_near(again.left, 12.5)


func test_a_resumed_run_keeps_counters_and_floor_flags() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["pill_organizer", "bottomless_flask", "glass_hip", "fine_print"])
	_fx(run, "pill_organizer").stored = 2
	_fx(run, "bottomless_flask").cleared = 3
	_fx(run, "glass_hip")._halves = 1
	_fx(run, "fine_print").used = true
	var back := _resume(run, ItemKit.new())
	assert_eq(_fx(back, "pill_organizer").stored, 2)
	assert_eq(_fx(back, "bottomless_flask").cleared, 3)
	assert_eq(_fx(back, "glass_hip")._halves, 1)
	assert_true(_fx(back, "fine_print").used)
	# Values come back as the type each member has, never as JSON's floats.
	assert_eq(typeof(_fx(back, "bottomless_flask").cleared), TYPE_INT)


func test_a_resume_shuffles_the_dice_of_effects_that_shuffled_on_gain() -> void:
	var seeds := {}
	for i in 3:
		var back := _resume(ItemKit.new().run_with(["lottery_scratcher"]), ItemKit.new())
		seeds[_fx(back, "lottery_scratcher").rng.seed] = true
	assert_eq(seeds.size(), 3, "each resume rolls its own dice")


func test_the_checkpoint_round_trip_still_matches_with_effect_state() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["eternal_warranty", "bureaucrats_stamp", "fine_print", "bottomless_flask"])
	run.effects.lethal()
	run.effects.floor_start()
	run.effects.room_clear(null)
	var back := _resume(run, ItemKit.new())
	assert_eq(RunCheckpoint.run_to_dict(back), RunCheckpoint.run_to_dict(run))


func test_the_save_pension_is_put_back_after_the_items_return() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	var resume := source.substr(source.find("func _resume_run"), 1400)
	assert_true(resume.find("RunCheckpoint.apply_run(") >= 0)
	assert_true(resume.find("RunCheckpoint.apply_run(") < resume.find("Progress.restore_pension(resume)"))
	var checkpoint := FileAccess.get_file_as_string("res://scripts/core/run_checkpoint.gd")
	assert_true(checkpoint.contains("run.restore_item(item)"), "items come back without on_gain")
	assert_false(checkpoint.contains("run.add_item(item)"))
