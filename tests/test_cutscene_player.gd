extends TestCase

const S := preload("res://scripts/core/cutscene_steps.gd")
const FRAME := 1.0 / 60.0


func _player(steps: Array, first_time := false) -> CutscenePlayer:
	var player := CutscenePlayer.new()
	player.setup(steps, first_time)
	player._ready()
	return player


# Steps the player for seconds of frames with nothing pressed, or until it is done.
func _run_for(player: CutscenePlayer, seconds: float, pressed := false, held := false) -> void:
	var left := seconds
	while left > 0.0001 and not player.is_done():
		player.advance(minf(FRAME, left), pressed, held)
		left -= FRAME


func _free(player: CutscenePlayer) -> void:
	player.free()


func test_a_wait_lasts_its_time() -> void:
	var player := _player([S.wait(1.0)])
	_run_for(player, 0.9)
	assert_false(player.is_done(), "not after 0.9 s")
	_run_for(player, 0.15)
	assert_true(player.is_done(), "done after 1.05 s")
	_free(player)


func test_a_line_shows_its_speaker_and_waits_its_time() -> void:
	var line := "Harold?! They said you were dead!"
	var player := _player([S.actor("gerald", Vector2(100, S.GROUND_Y)), S.say("gerald", line)])
	player.advance(FRAME, false, false)
	assert_eq(player.current_text(), line)
	assert_eq(player.current_speaker(), "Gerald")
	_run_for(player, S.say_time(line) - 0.1)
	assert_false(player.is_done(), "still showing just before its time")
	_run_for(player, 0.2)
	assert_true(player.is_done())
	assert_eq(player.current_text(), "", "the box is gone")
	_free(player)


func test_a_press_moves_a_line_on_but_not_in_its_first_moment() -> void:
	var player := _player([S.say("harold", "They were wrong."), S.say("harold", "Second."), S.wait(5.0)])
	player.advance(FRAME, false, false)
	player.advance(FRAME, true, false)
	assert_eq(player.current_text(), "They were wrong.", "a press in the first moment is the press that won the fight")
	_run_for(player, CutscenePlayer.MIN_SHOW_TIME)
	player.advance(FRAME, true, false)
	assert_eq(player.current_text(), "Second.", "a later press moves it on")
	# One press moves one line only, even though the next line starts on the same frame.
	assert_eq(player.step_index(), 1)
	_free(player)


func test_a_press_does_not_shorten_a_wait() -> void:
	var player := _player([S.wait(1.0)])
	_run_for(player, 0.5, true)
	assert_false(player.is_done())
	_free(player)


func test_a_card_shows_its_text_on_black() -> void:
	var player := _player([S.card("Cause of death: stairs. Again."), S.wait(0.5)])
	player.advance(FRAME, false, false)
	assert_eq(player.current_text(), "Cause of death: stairs. Again.")
	assert_eq(player.current_speaker(), "")
	assert_near(player.fade_alpha(), 1.0)
	_run_for(player, S.card_time("Cause of death: stairs. Again.") + 0.05)
	assert_eq(player.current_text(), "")
	assert_near(player.fade_alpha(), 1.0, "it stays black until a fade in")
	_free(player)


func test_a_walk_takes_its_distance_over_its_speed() -> void:
	var player := _player([S.actor("harold", Vector2(40, S.GROUND_Y)), S.walk("harold", Vector2(120, S.GROUND_Y), 40.0)])
	_run_for(player, 1.9)
	assert_false(player.is_done())
	assert_true(player.actor("harold").position.x > 100.0 and player.actor("harold").position.x < 120.0, str(player.actor("harold").position))
	_run_for(player, 0.2)
	assert_true(player.is_done())
	assert_eq(player.actor("harold").position, Vector2(120, S.GROUND_Y))
	assert_eq(player.actor("harold").facing, 1)
	_free(player)


func test_a_walk_that_does_not_wait_lets_the_next_step_start() -> void:
	var player := _player([
		S.actor("harold", Vector2(40, S.GROUND_Y)), S.actor("gerald", Vector2(200, S.GROUND_Y)),
		S.walk("harold", Vector2(120, S.GROUND_Y), 40.0, false), S.walk("gerald", Vector2(160, S.GROUND_Y), 40.0),
	])
	_run_for(player, 1.05)
	assert_true(player.is_done(), "the scene waits only for the second walk")
	assert_true(player.actor("harold").position.x > 70.0 and player.actor("harold").position.x < 90.0, "the first walk goes on")
	assert_eq(player.actor("gerald").facing, -1)
	_free(player)


func test_holding_interact_for_a_second_skips_the_scene() -> void:
	var player := _player([S.say("harold", "One."), S.wait(30.0)])
	var done := [false]
	player.finished.connect(func() -> void: done[0] = true)
	_run_for(player, CutscenePlayer.SKIP_HOLD - 0.1, false, true)
	assert_false(player.is_done(), "not before the hold is long enough")
	_run_for(player, 0.15, false, true)
	assert_true(player.is_done())
	assert_true(done[0], "finished is sent")
	_free(player)


func test_letting_go_starts_the_hold_again() -> void:
	var player := _player([S.wait(30.0)])
	_run_for(player, 0.8, false, true)
	player.advance(FRAME, false, false)
	_run_for(player, 0.8, false, true)
	assert_false(player.is_done())
	assert_near(player.skip_progress(), 0.8 / CutscenePlayer.SKIP_HOLD)
	_free(player)


func test_the_first_time_the_skip_waits_for_the_first_text_box() -> void:
	var player := _player([S.wait(2.0), S.say("harold", "One."), S.wait(30.0)], true)
	assert_false(player.can_skip())
	_run_for(player, 1.5, false, true)
	assert_false(player.is_done(), "no skip before the first text box")
	_run_for(player, 0.6)
	assert_eq(player.current_text(), "One.")
	assert_false(player.can_skip(), "not while the first box shows")
	_run_for(player, S.say_time("One.") + 0.1)
	assert_true(player.can_skip(), "offered once the first box has gone")
	_run_for(player, CutscenePlayer.SKIP_HOLD + 0.05, false, true)
	assert_true(player.is_done())
	_free(player)


func test_a_scene_seen_before_can_be_skipped_at_once() -> void:
	var player := _player([S.wait(2.0), S.say("harold", "One.")], false)
	assert_true(player.can_skip())
	_free(player)


func test_fades_reach_black_and_back() -> void:
	var player := _player([S.fade_in(0.5), S.wait(0.5), S.fade_out(0.5)])
	assert_near(player.fade_alpha(), 1.0, "a scene starts black")
	_run_for(player, 0.25)
	assert_true(player.fade_alpha() > 0.4 and player.fade_alpha() < 0.6, str(player.fade_alpha()))
	_run_for(player, 0.3)
	assert_near(player.fade_alpha(), 0.0)
	_run_for(player, 1.0)
	assert_near(player.fade_alpha(), 1.0)
	assert_true(player.is_done())
	_free(player)


func test_a_fall_lays_an_actor_down_and_waits_its_time() -> void:
	var player := _player([S.actor("harold", Vector2(100, S.GROUND_Y)), S.anim("harold", "fall")])
	_run_for(player, S.ANIM_TIME["fall"] - 0.05)
	assert_false(player.is_done())
	_run_for(player, 0.1)
	assert_true(player.is_done())
	assert_near(absf(player.actor("harold").rotation), PI / 2.0)
	_free(player)


func test_the_stage_changes_and_actors_leave() -> void:
	var player := _player([S.stage("fence"), S.actor("gerald", Vector2(100, S.GROUND_Y)), S.hide("gerald"), S.stage("hospital")])
	_run_for(player, 0.1)
	assert_eq(player.stage_name(), "hospital")
	assert_true(player.actor("gerald") == null)
	_free(player)


func test_the_scene_length_is_worked_out_from_its_steps() -> void:
	var steps := [
		S.fade_in(0.5), S.actor("harold", Vector2(40, S.GROUND_Y)), S.walk("harold", Vector2(120, S.GROUND_Y), 40.0),
		S.say("harold", "Mine. All mine."), S.anim("harold", "fall"), S.zoom(1.5, 2.0), S.card("Cause of death: property tax."), S.fade_out(0.8),
	]
	var expected := 0.5 + 2.0 + S.say_time("Mine. All mine.") + S.ANIM_TIME["fall"] + S.card_time("Cause of death: property tax.") + 0.8
	assert_near(S.duration_of(steps), expected)
	var player := _player(steps)
	var frames := 0
	while not player.is_done() and frames < 10000:
		player.advance(FRAME, false, false)
		frames += 1
	assert_true(absf(frames * FRAME - expected) < 0.1, "stepped %f, expected %f" % [frames * FRAME, expected])
	_free(player)
